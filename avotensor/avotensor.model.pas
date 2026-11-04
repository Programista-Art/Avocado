{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.model;
interface

uses
  SysUtils, Classes, Math, Types,
  avotensor.core,
  avotensor.nn,
  avotensor.ops,
  avotensor.init,
  avotensor.embed,
  avotensor.attention,
  avotensor.transformer;

const
  AVO_MODEL_LAYOUT_VERSION = 1019;
  MAGIC_ENDIAN: Cardinal = $A1B2C3D4;
  FLOAT_PRECISION_FLAG: Integer = SizeOf(Single);

type
  TAvoModelConfig = record
    VocabSize:  Integer;
    EmbDim:     Integer;
    NumHeads:   Integer;
    NumLayers:  Integer;
    MaxSeqLen:  Integer;

    PadTokenID: Integer;
    UnkTokenID: Integer;
    BosTokenID: Integer;
    EosTokenID: Integer;
    NewlineTokenID: Integer;
    TabTokenID:     Integer;
    IndentTokenID:  Integer;
    DedentTokenID:  Integer;
  end;

  // Globalny Optymalizator ADAM (Zarządca stanu uczenia)

  TAvoOptimizerAdam = class
  private
    FParams: TAvoTensorArray;
    FM: array of TSingleArray;
    FV: array of TSingleArray;
    FBeta1, FBeta2, FEps: Single;
    FT: Integer;
    FLearningRate: Single;

    function CalculateStateHash: Cardinal;
  public
    property LearningRate: Single read FLearningRate write FLearningRate;
    property Params: TAvoTensorArray read FParams;
    property T: Integer read FT write FT;

    constructor Create(ALearningRate: Single; const AParams: TAvoTensorArray;
                       ABeta1: Single = 0.9; ABeta2: Single = 0.999; AEps: Single = 1e-8);
    procedure Step;
    procedure ZeroGrad;

    procedure SaveState(S: TStream);
    procedure LoadState(S: TStream);
    procedure ResetMoments;
  end;


  // Model Językowy (AvoLanguageModel)
  TAvoLanguageModel = class
  private
    FConfig:    TAvoModelConfig;
    FOptimizer: TAvoOptimizerAdam;
    FDebugMode: Boolean;

    // Execution Arena (Zarządzanie stanem Forward)
    FLastIDs:    TIntegerDynArray;
    FEmbOut:     TAvoTensor;
    FBlockOuts: array of TAvoTensor;
    FLNOut:      TAvoTensor;

    procedure FreeCache;
    procedure SaveTensor(S: TStream; T: TAvoTensor);
    procedure LoadTensor(S: TStream; T: TAvoTensor);
    function  GatherParameters: TAvoTensorArray;

    procedure ValidateTensor(ATensor: TAvoTensor; const Context: string);
    function  CalculateWeightsHash: Cardinal;
    function  DetachTensor(Source: TAvoTensor): TAvoTensor;

    procedure SyncGradients;

  public
    Embed:   TAvoEmbeddingLayer;
    PE:      TAvoPositionalEncoding;
    Blocks:  array of TAvoTransformerBlock;
    LNFinal: TAvoLayerNorm;
    Head:    TAvoLinearLayer;

    constructor Create(const AConfig: TAvoModelConfig);
    destructor  Destroy; override;

    function Forward(const IDs: TIntegerDynArray): TAvoTensor;
    function Backward(DOut: TAvoTensor): TAvoTensor;

    procedure ZeroGrad;
    procedure Step(LearningRate: Single);
    procedure ClipGradients(MaxNorm: Single);

    procedure SaveWeights(const FileName: String);
    procedure LoadWeights(const FileName: String);

    function CountParams: Integer;

    property Config: TAvoModelConfig read FConfig;
    property DebugMode: Boolean read FDebugMode write FDebugMode;
  end;

function MakeConfig(
  AVocabSize, AEmbDim, ANumHeads, ANumLayers, AMaxSeqLen: Integer;
  APad: Integer = 0; AUnk: Integer = 1; ABos: Integer = 2; AEos: Integer = 3;
  ANewline: Integer = 4; ATab: Integer = 5; AIndent: Integer = 6; ADedent: Integer = 7
): TAvoModelConfig;

function FNV1a_Hash_Step(Data: PByte; Len: Integer; CurrentHash: Cardinal): Cardinal;

implementation

type
  TSingleOverlay = record
    case Integer of
      0: (f: Single);
      1: (u: Cardinal);
  end;

function MakeConfig(
  AVocabSize, AEmbDim, ANumHeads, ANumLayers, AMaxSeqLen: Integer;
  APad: Integer = 0; AUnk: Integer = 1; ABos: Integer = 2; AEos: Integer = 3;
  ANewline: Integer = 4; ATab: Integer = 5; AIndent: Integer = 6; ADedent: Integer = 7
): TAvoModelConfig;
begin
  Result.VocabSize := AVocabSize;
  Result.EmbDim    := AEmbDim;
  Result.NumHeads  := ANumHeads;
  Result.NumLayers := ANumLayers;
  Result.MaxSeqLen := AMaxSeqLen;
  Result.PadTokenID := APad;
  Result.UnkTokenID := AUnk;
  Result.BosTokenID := ABos;
  Result.EosTokenID := AEos;
  Result.NewlineTokenID := ANewline;
  Result.TabTokenID := ATab;
  Result.IndentTokenID := AIndent;
  Result.DedentTokenID := ADedent;
end;

function FNV1a_Hash_Step(Data: PByte; Len: Integer; CurrentHash: Cardinal): Cardinal;
const
  FNV_PRIME = 16777619;
var
  i: Integer;
begin
  Result := CurrentHash;
  for i := 0 to Len - 1 do
  begin
    Result := Result xor Data[i];
    Result := Result * FNV_PRIME;
  end;
end;

// TAvoOptimizerAdam

constructor TAvoOptimizerAdam.Create(ALearningRate: Single; const AParams: TAvoTensorArray;
                                     ABeta1: Single = 0.9; ABeta2: Single = 0.999; AEps: Single = 1e-8);
begin
  FLearningRate := ALearningRate;
  FBeta1 := ABeta1;
  FBeta2 := ABeta2;
  FEps := AEps;
  FT := 0;
  FParams := AParams;
  SetLength(FM, Length(FParams));
  SetLength(FV, Length(FParams));
  ResetMoments;
end;

procedure TAvoOptimizerAdam.ResetMoments;
var
  i, Len: Integer;
begin
  for i := 0 to High(FParams) do
  begin
    Len := FParams[i].NumEl;
    SetLength(FM[i], Len);
    SetLength(FV[i], Len);
    if Len > 0 then
    begin
      FillChar(FM[i][0], Len * SizeOf(Single), 0);
      FillChar(FV[i][0], Len * SizeOf(Single), 0);
    end;
  end;
end;

function TAvoOptimizerAdam.CalculateStateHash: Cardinal;
const
  FNV_OFFSET_BASIS = 2166136261;
var
  i: Integer;
  HashVal: Cardinal;
begin
  HashVal := FNV_OFFSET_BASIS;
  for i := 0 to High(FM) do
  begin
    if Length(FM[i]) > 0 then
    begin
      HashVal := FNV1a_Hash_Step(PByte(@FM[i][0]), Length(FM[i]) * SizeOf(Single), HashVal);
      HashVal := FNV1a_Hash_Step(PByte(@FV[i][0]), Length(FV[i]) * SizeOf(Single), HashVal);
    end;
  end;
  Result := HashVal;
end;

procedure TAvoOptimizerAdam.Step;
var
  i, j: Integer;
  ParamTensor: TAvoTensor;
  G, M_hat, V_hat: Single;
  Denom, B1_pow, B2_pow, B1_corr, B2_corr: Single;
begin
  Inc(FT);
  B1_pow := Power(FBeta1, FT);
  B2_pow := Power(FBeta2, FT);

  B1_corr := Max(1e-7, 1.0 - B1_pow);
  B2_corr := Max(1e-7, 1.0 - B2_pow);

  for i := 0 to High(FParams) do
  begin
    ParamTensor := FParams[i];
    for j := 0 to High(ParamTensor.Data) do
    begin
      G := ParamTensor.Grad[j];

      if IsNaN(G) or IsInfinite(G) then G := 0.0;

      FM[i][j] := FBeta1 * FM[i][j] + (1.0 - FBeta1) * G;
      FV[i][j] := FBeta2 * FV[i][j] + (1.0 - FBeta2) * G * G;

      M_hat := FM[i][j] / B1_corr;
      V_hat := FV[i][j] / B2_corr;

      Denom := Sqrt(V_hat) + FEps;
      ParamTensor.Data[j] := ParamTensor.Data[j] - FLearningRate * (M_hat / Denom);

      if IsNaN(ParamTensor.Data[j]) then ParamTensor.Data[j] := 0.0;
    end;
  end;
end;

procedure TAvoOptimizerAdam.ZeroGrad;
var
  i, j: Integer;
begin
  for i := 0 to High(FParams) do
    for j := 0 to High(FParams[i].Grad) do
      FParams[i].Grad[j] := 0.0;
end;

procedure TAvoOptimizerAdam.SaveState(S: TStream);
var
  i, Len, ParamCount, AdamVer: Integer;
  Check: Cardinal;
begin
  AdamVer := 8;
  ParamCount := Length(FParams);
  Check := CalculateStateHash;

  S.Write(AdamVer, SizeOf(Integer));
  S.Write(ParamCount, SizeOf(Integer));
  S.Write(Check, SizeOf(Cardinal));
  S.Write(FT, SizeOf(Integer));

  for i := 0 to ParamCount - 1 do
  begin
    Len := Length(FM[i]);
    S.Write(Len, SizeOf(Integer));
    if Len > 0 then
    begin
      S.Write(FM[i][0], Len * SizeOf(Single));
      S.Write(FV[i][0], Len * SizeOf(Single));
    end;
  end;
end;

procedure TAvoOptimizerAdam.LoadState(S: TStream);
var
  i, Len, AdamVer, FileParamCount, CurrentParamCount, FileLen: Integer;
  FileHash, CalcHash: Cardinal;
begin
  if S.Size - S.Position < (3 * SizeOf(Integer) + SizeOf(Cardinal)) then
    raise Exception.Create('Adam Load Error: Zbyt mały rozmiar strumienia danych.');

  S.Read(AdamVer, SizeOf(Integer));
  S.Read(FileParamCount, SizeOf(Integer));
  S.Read(FileHash, SizeOf(Cardinal));

  CurrentParamCount := Length(FParams);
  if FileParamCount <> CurrentParamCount then
    raise Exception.Create('Adam Inconsistency: Plik stanu nie pasuje do architektury modelu.');

  S.Read(FT, SizeOf(Integer));
  for i := 0 to CurrentParamCount - 1 do
  begin
    if S.Position >= S.Size then raise Exception.Create('Adam EOF Error.');
    S.Read(FileLen, SizeOf(Integer));
    Len := Length(FM[i]);
    if FileLen <> Len then raise Exception.Create('Adam Integrity Failure: Mismatch w rozmiarach momentów.');

    if Len > 0 then
    begin
      if S.Size - S.Position < (Len * SizeOf(Single) * 2) then
        raise Exception.Create('Adam EOF Error: Ucięte dane momentów.');
      S.Read(FM[i][0], Len * SizeOf(Single));
      S.Read(FV[i][0], Len * SizeOf(Single));
    end;
  end;

  if AdamVer >= 5 then
  begin
    CalcHash := CalculateStateHash;
    if CalcHash <> FileHash then
      raise Exception.Create('!!! KRYTYCZNY BLAD: Hash FNV-1a stanu optymalizatora odrzucil integralnosc! !!!');
  end;
end;


// TAvoLanguageModel

function TAvoLanguageModel.GatherParameters: TAvoTensorArray;
var
  i, Ptr, TotalNeeded: Integer;
begin
  TotalNeeded := 1 + (FConfig.NumLayers * 16) + 4;
  SetLength(Result, TotalNeeded);
  Ptr := 0;

  Result[Ptr] := Embed.Wagi; Inc(Ptr);
  for i := 0 to FConfig.NumLayers - 1 do
  begin
    Result[Ptr] := Blocks[i].LN1.Gamma; Inc(Ptr); Result[Ptr] := Blocks[i].LN1.Beta; Inc(Ptr);

    Result[Ptr] := Blocks[i].MHA.Wq.Wagi; Inc(Ptr); Result[Ptr] := Blocks[i].MHA.Wq.Bias; Inc(Ptr);
    Result[Ptr] := Blocks[i].MHA.Wk.Wagi; Inc(Ptr); Result[Ptr] := Blocks[i].MHA.Wk.Bias; Inc(Ptr);
    Result[Ptr] := Blocks[i].MHA.Wv.Wagi; Inc(Ptr); Result[Ptr] := Blocks[i].MHA.Wv.Bias; Inc(Ptr);
    Result[Ptr] := Blocks[i].MHA.Wo.Wagi; Inc(Ptr); Result[Ptr] := Blocks[i].MHA.Wo.Bias; Inc(Ptr);

    Result[Ptr] := Blocks[i].LN2.Gamma; Inc(Ptr); Result[Ptr] := Blocks[i].LN2.Beta; Inc(Ptr);
    Result[Ptr] := Blocks[i].FFN.W1; Inc(Ptr);    Result[Ptr] := Blocks[i].FFN.B1; Inc(Ptr);
    Result[Ptr] := Blocks[i].FFN.W2; Inc(Ptr);    Result[Ptr] := Blocks[i].FFN.B2; Inc(Ptr);
  end;
  Result[Ptr] := LNFinal.Gamma; Inc(Ptr); Result[Ptr] := LNFinal.Beta; Inc(Ptr);
  Result[Ptr] := Head.Wagi; Inc(Ptr);     Result[Ptr] := Head.Bias; Inc(Ptr);
  SetLength(Result, Ptr);
end;

procedure TAvoLanguageModel.ValidateTensor(ATensor: TAvoTensor; const Context: string);
var i: Integer;
begin
  if ATensor = nil then
    raise Exception.Create('Safety Error: Wykryto Nil tensor w ' + Context);
  if ATensor.NumEl <> Length(ATensor.Data) then
    raise Exception.Create('Safety Error: Mismatch kształu i pamięci (Shape/Data) w ' + Context);

  if FDebugMode then
  begin
    for i := 0 to High(ATensor.Data) do
      if IsNaN(ATensor.Data[i]) or IsInfinite(ATensor.Data[i]) then
        raise Exception.Create('FPU Error: Wykryto NaN/Inf po operacji w ' + Context);
  end;
end;

function TAvoLanguageModel.DetachTensor(Source: TAvoTensor): TAvoTensor;
begin
  ValidateTensor(Source, 'DetachTensor Source');
  Result := TAvoTensor.Create(Source.Shape);
  if Source.NumEl > 0 then
    Move(Source.Data[0], Result.Data[0], Source.NumEl * SizeOf(Single));
end;

function TAvoLanguageModel.CalculateWeightsHash: Cardinal;
const
  FNV_OFFSET_BASIS = 2166136261;
var
  i: Integer;
  Params: TAvoTensorArray;
  HashVal: Cardinal;
begin
  HashVal := FNV_OFFSET_BASIS;
  Params := FOptimizer.Params;
  for i := 0 to High(Params) do
  begin
    if Params[i].NumEl > 0 then
      HashVal := FNV1a_Hash_Step(PByte(@Params[i].Data[0]), Params[i].NumEl * SizeOf(Single), HashVal);
  end;
  Result := HashVal;
end;

constructor TAvoLanguageModel.Create(const AConfig: TAvoModelConfig);
var
  i, HiddenDim: Integer;
begin
  FConfig  := AConfig;
  FDebugMode := False;

  if FConfig.PadTokenID <> 0 then raise Exception.Create('Contract: PAD must be 0.');
  if FConfig.UnkTokenID <> 1 then raise Exception.Create('Contract: UNK must be 1.');

  Embed := TAvoEmbeddingLayer.Create(AConfig.VocabSize, AConfig.EmbDim);
  PE := TAvoPositionalEncoding.Create(AConfig.MaxSeqLen, AConfig.EmbDim);
  HiddenDim := AConfig.EmbDim * 4;

  SetLength(Blocks,    AConfig.NumLayers);
  SetLength(FBlockOuts, AConfig.NumLayers);
  for i := 0 to AConfig.NumLayers - 1 do
  begin
    Blocks[i] := TAvoTransformerBlock.Create(AConfig.EmbDim, AConfig.NumHeads, HiddenDim, AConfig.MaxSeqLen);
    FBlockOuts[i] := nil;
  end;

  LNFinal := TAvoLayerNorm.Create(AConfig.EmbDim);

  Head := TAvoLinearLayer.Create;
  if Head.Wagi <> nil then Head.Wagi.Free;
  if Head.Bias <> nil then Head.Bias.Free;
  Head.Wagi := TAvoTensor.Create([AConfig.EmbDim, AConfig.VocabSize]);
  Head.Bias := TAvoTensor.Create([AConfig.VocabSize]);
  InitXavierUniform(Head.Wagi, AConfig.EmbDim, AConfig.VocabSize);
  InitConstant(Head.Bias, 0.0);

  FOptimizer := TAvoOptimizerAdam.Create(0.001, GatherParameters);
end;

procedure TAvoLanguageModel.FreeCache;
var i: Integer;
begin
  if FEmbOut <> nil then begin FEmbOut.Free; FEmbOut := nil; end;
  if FLNOut <> nil then begin FLNOut.Free; FLNOut := nil; end;
  for i := 0 to High(FBlockOuts) do
    if FBlockOuts[i] <> nil then begin FBlockOuts[i].Free; FBlockOuts[i] := nil; end;
  SetLength(FLastIDs, 0);
end;

destructor TAvoLanguageModel.Destroy;
var i: Integer;
begin
  FreeCache;
  FOptimizer.Free; Embed.Free; PE.Free;
  for i := 0 to High(Blocks) do Blocks[i].Free;
  LNFinal.Free; Head.Free;
  inherited Destroy;
end;

function TAvoLanguageModel.Forward(const IDs: TIntegerDynArray): TAvoTensor;
var
  i: Integer;
  Prev, RawEmb, TempOut: TAvoTensor;
begin
  if Length(IDs) = 0 then raise Exception.Create('Forward: empty sequence.');

  FreeCache;
  FLastIDs := Copy(IDs);

  RawEmb := Embed.Forward(IDs);
  try
    FEmbOut := PE.Apply(RawEmb);
  finally
    if FEmbOut <> RawEmb then RawEmb.Free;
  end;

  ValidateTensor(FEmbOut, 'Embedded Layer');
  Prev := FEmbOut;

  for i := 0 to FConfig.NumLayers - 1 do
  begin
    // Mask jest nil, MHA zastosuje własną maskę kauzalną. Flow jest natywnie 2D.
    FBlockOuts[i] := Blocks[i].Forward(Prev, nil);
    Prev := FBlockOuts[i];
    ValidateTensor(Prev, 'Transformer Block ' + IntToStr(i));
  end;

  FLNOut := LNFinal.Forward(Prev);
  ValidateTensor(FLNOut, 'Layer Norm Final');

  TempOut := Head.Forward(FLNOut);
  try
    ValidateTensor(TempOut, 'Linear Head Output');
    Result := DetachTensor(TempOut);
  finally
    TempOut.Free;
  end;
end;

procedure TAvoLanguageModel.SyncGradients;
var
  i, j: Integer;
  B: TAvoTransformerBlock;
begin
  if LNFinal.GammaGrad <> nil then
    for j := 0 to High(LNFinal.Gamma.Grad) do LNFinal.Gamma.Grad[j] := LNFinal.GammaGrad.Data[j];
  if LNFinal.BetaGrad <> nil then
    for j := 0 to High(LNFinal.Beta.Grad) do LNFinal.Beta.Grad[j] := LNFinal.BetaGrad.Data[j];

  for i := 0 to FConfig.NumLayers - 1 do
  begin
    B := Blocks[i];

    if B.LN1.GammaGrad <> nil then
      for j := 0 to High(B.LN1.Gamma.Grad) do B.LN1.Gamma.Grad[j] := B.LN1.GammaGrad.Data[j];
    if B.LN1.BetaGrad <> nil then
      for j := 0 to High(B.LN1.Beta.Grad) do B.LN1.Beta.Grad[j] := B.LN1.BetaGrad.Data[j];

    if B.LN2.GammaGrad <> nil then
      for j := 0 to High(B.LN2.Gamma.Grad) do B.LN2.Gamma.Grad[j] := B.LN2.GammaGrad.Data[j];
    if B.LN2.BetaGrad <> nil then
      for j := 0 to High(B.LN2.Beta.Grad) do B.LN2.Beta.Grad[j] := B.LN2.BetaGrad.Data[j];

    if B.FFN.W1Grad <> nil then
      for j := 0 to High(B.FFN.W1.Grad) do B.FFN.W1.Grad[j] := B.FFN.W1Grad.Data[j];
    if B.FFN.B1Grad <> nil then
      for j := 0 to High(B.FFN.B1.Grad) do B.FFN.B1.Grad[j] := B.FFN.B1Grad.Data[j];
    if B.FFN.W2Grad <> nil then
      for j := 0 to High(B.FFN.W2.Grad) do B.FFN.W2.Grad[j] := B.FFN.W2Grad.Data[j];
    if B.FFN.B2Grad <> nil then
      for j := 0 to High(B.FFN.B2.Grad) do B.FFN.B2.Grad[j] := B.FFN.B2Grad.Data[j];
  end;
end;

function TAvoLanguageModel.Backward(DOut: TAvoTensor): TAvoTensor;
var
  i: Integer;
  DHead, DCurrent, DTemp: TAvoTensor;
begin
  ValidateTensor(DOut, 'Backward DOut Entry');

  DHead := nil; DCurrent := nil; DTemp := nil; Result := nil;
  try
    DHead := Head.Backward(DOut);
    ValidateTensor(DHead, 'Backward Head');

    DCurrent := LNFinal.Backward(DHead);
    ValidateTensor(DCurrent, 'Backward LNFinal');
    DHead.Free; DHead := nil;

    for i := FConfig.NumLayers - 1 downto 0 do
    begin
      DTemp := Blocks[i].Backward(DCurrent);
      ValidateTensor(DTemp, 'Backward Block ' + IntToStr(i));
      DCurrent.Free;
      DCurrent := DTemp;
      DTemp := nil;
    end;

    Embed.Backward(DCurrent, FLastIDs);
    Result := DCurrent;
    DCurrent := nil;

    SyncGradients;
  finally
    if DHead <> nil then DHead.Free;
    if DCurrent <> nil then DCurrent.Free;
    if DTemp <> nil then DTemp.Free;
  end;
end;

procedure TAvoLanguageModel.ZeroGrad;
var
  i: Integer;
begin
  FOptimizer.ZeroGrad;
  LNFinal.ZeroGrad;

  for i := 0 to FConfig.NumLayers - 1 do
    Blocks[i].ZeroGrad;
end;

procedure TAvoLanguageModel.Step(LearningRate: Single);
begin
  FOptimizer.LearningRate := LearningRate;
  FOptimizer.Step;
end;

procedure TAvoLanguageModel.ClipGradients(MaxNorm: Single);
var
  i, j: Integer;
  TotalNorm, Scale: Single;
  P: TAvoTensor;
begin
  TotalNorm := 0.0;
  for i := 0 to High(FOptimizer.Params) do
  begin
    P := FOptimizer.Params[i];
    for j := 0 to High(P.Grad) do
    begin
      if IsNaN(P.Grad[j]) or IsInfinite(P.Grad[j]) then P.Grad[j] := 0.0;
      TotalNorm := TotalNorm + Sqr(P.Grad[j]);
    end;
  end;
  TotalNorm := Sqrt(TotalNorm + 1e-9);
  if TotalNorm > MaxNorm then
  begin
    Scale := MaxNorm / TotalNorm;
    for i := 0 to High(FOptimizer.Params) do
      for j := 0 to High(FOptimizer.Params[i].Grad) do
        FOptimizer.Params[i].Grad[j] := FOptimizer.Params[i].Grad[j] * Scale;
  end;
end;

function TAvoLanguageModel.CountParams: Integer;
var i: Integer;
begin
  Result := Embed.VocabSize * Embed.EmbDim;
  for i := 0 to FConfig.NumLayers - 1 do
  begin
    // MHA: 4x Linear (W: E*E, B: E) => 4E^2 + 4E
    // LN1 + LN2: 2x (Gamma: E, Beta: E) => 4E
    // FFN: W1(E*4E) + B1(4E) + W2(4E*E) + B2(E) => 8E^2 + 5E
    // Suma na blok: 12E^2 + 13E
    Result := Result + 12 * (FConfig.EmbDim * FConfig.EmbDim) + 13 * FConfig.EmbDim;
  end;
  // LNFinal: Gamma + Beta => 2E
  Result := Result + 2 * FConfig.EmbDim;
  // Head: Wagi(E*Vocab) + Bias(Vocab)
  Result := Result + FConfig.EmbDim * FConfig.VocabSize + FConfig.VocabSize;
end;

procedure TAvoLanguageModel.SaveTensor(S: TStream; T: TAvoTensor);
var N: Integer;
begin
  N := T.NumEl;
  S.Write(N, SizeOf(Integer));
  if N > 0 then S.Write(T.Data[0], N * SizeOf(Single));
end;

procedure TAvoLanguageModel.LoadTensor(S: TStream; T: TAvoTensor);
var N, NExpected: Integer;
begin
  if S.Position >= S.Size then raise Exception.Create('LoadTensor EOF Error.');
  S.Read(N, SizeOf(Integer));
  NExpected := T.NumEl;
  if N <> NExpected then raise Exception.Create('Critical Structure Fail: Rozmiar wagi nie pasuje do modelu!');

  if N > 0 then
  begin
    if S.Size - S.Position < (N * SizeOf(Single)) then raise Exception.Create('LoadTensor EOF Error: Ucięte dane tensora.');
    S.Read(T.Data[0], N * SizeOf(Single));
  end;
  ValidateTensor(T, 'LoadTensor');
end;

procedure TAvoLanguageModel.SaveWeights(const FileName: String);
var
  S: TFileStream;
  SL: TStringList;
  HeadStr: String;
  i, ParamCount: Integer;
  Check: Cardinal;
  HasAdamState: Integer;
begin
  S := TFileStream.Create(FileName, fmCreate);
  SL := TStringList.Create;
  try
    ParamCount := Length(FOptimizer.Params);
    Check := CalculateWeightsHash;
    SL.Add('AVOMODEL v2.6-NATIVE-SYNC');
    SL.Add(Format('LayoutVersion=%d', [AVO_MODEL_LAYOUT_VERSION]));
    SL.Add(Format('ArchitectureHash=%u', [Check]));
    SL.Add(Format('ParamCount=%d',    [ParamCount]));
    SL.Add('---');
    HeadStr := SL.Text;

    HasAdamState := 1;

    S.Write(MAGIC_ENDIAN, SizeOf(Cardinal));
    S.Write(FLOAT_PRECISION_FLAG, SizeOf(Integer));
    S.Write(HasAdamState, SizeOf(Integer));
    S.Write(HeadStr[1], Length(HeadStr));

    for i := 0 to ParamCount - 1 do
      SaveTensor(S, FOptimizer.Params[i]);

    FOptimizer.SaveState(S);
  finally
    SL.Free; S.Free;
  end;
end;

procedure TAvoLanguageModel.LoadWeights(const FileName: String);
var
  S: TFileStream;
  Line: String;
  Ch: Char;
  i, FileParamCount, CurrentParamCount, FileLayout: Integer;
  FileHash, CalcHash, ReadEndian: Cardinal;
  ReadPrecision, HasAdamState: Integer;
  function ReadLine: String;
  begin
    Result := '';
    repeat
      if S.Position >= S.Size then Break;
      S.Read(Ch, 1);
      if Ch <> #10 then Result := Result + Ch;
    until (Ch = #10);
    Result := Trim(Result);
  end;
begin
  if not FileExists(FileName) then Exit;
  S := TFileStream.Create(FileName, fmOpenRead);
  try
    if S.Size < (SizeOf(Cardinal) + 2 * SizeOf(Integer)) then raise Exception.Create('File Error: Plik jest pusty lub uszkodzony.');

    S.Read(ReadEndian, SizeOf(Cardinal));
    if ReadEndian <> MAGIC_ENDIAN then
      raise Exception.Create('Binary Error: Niezgodnosc Endianness lub uszkodzony plik!');

    S.Read(ReadPrecision, SizeOf(Integer));
    if ReadPrecision <> FLOAT_PRECISION_FLAG then
      raise Exception.CreateFmt('Precision Drift Error: Oczekiwano %d bajtow na Float, otrzymano %d.', [FLOAT_PRECISION_FLAG, ReadPrecision]);

    S.Read(HasAdamState, SizeOf(Integer));

    Line := ReadLine;
    if Pos('AVOMODEL', Line) = 0 then raise Exception.Create('Format Error: Nieprawidlowy plik modelu.');

    FileParamCount := -1; FileLayout := -1; FileHash := 0;
    repeat
      Line := ReadLine;
      if Pos('LayoutVersion=', Line) > 0 then FileLayout := StrToIntDef(Copy(Line, 15, 10), -1);
      if Pos('ParamCount=', Line) > 0 then FileParamCount := StrToIntDef(Copy(Line, 12, 10), -1);
      if Pos('ArchitectureHash=', Line) > 0 then FileHash := Cardinal(StrToInt64Def(Copy(Line, 18, 20), 0));
    until (Line = '---') or (S.Position >= S.Size);

    CurrentParamCount := Length(FOptimizer.Params);
    if (FileLayout <> AVO_MODEL_LAYOUT_VERSION) then raise Exception.Create('Version Fail: Plik pochodzi z innej wersji silnika.');
    if (FileParamCount <> CurrentParamCount) then raise Exception.Create('Integrity Fail: Liczba parametrów nie zgadza się.');

    for i := 0 to CurrentParamCount - 1 do
      LoadTensor(S, FOptimizer.Params[i]);

    CalcHash := CalculateWeightsHash;
    if CalcHash <> FileHash then
      raise Exception.Create('!!! KRYTYCZNY BLAD: Hash wag FNV-1a wskazuje na korupcje na poziomie bitow! !!!');

    if HasAdamState = 1 then FOptimizer.LoadState(S);
  finally
    S.Free;
  end;
end;

end.


{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.transformer;
interface

uses
  SysUtils, Math,
  avotensor.core,
  avotensor.nn,
  avotensor.ops,
  avotensor.init,
  avotensor.attention;

type
  TAvoLayerNorm = class
  private
    Dim: Integer;
    Eps: Single;
    FInput: TAvoTensor;
    FMean: array of Single;
    FInvStd: array of Single;
    FNorm: TAvoTensor;
  public
    Gamma, Beta: TAvoTensor;
    GammaGrad, BetaGrad: TAvoTensor;

    constructor Create(ADim: Integer; AEps: Single = 1e-5);
    destructor Destroy; override;

    function Forward(Input: TAvoTensor): TAvoTensor;
    function Backward(DOut: TAvoTensor): TAvoTensor;
    procedure ZeroGrad;
    procedure Step(LearningRate: Single);
  end;

  TAvoFeedForward = class
  private
    EmbedDim: Integer;
    HiddenDim: Integer;

    FFlatInput: TAvoTensor;
    FL1Out: TAvoTensor;
    FActOut: TAvoTensor;
    FWas3D: Boolean;
    FOrigShape: TShapeArray;
    procedure ClearSaved;
  public
    W1, B1: TAvoTensor;
    W2, B2: TAvoTensor;
    W1Grad, B1Grad: TAvoTensor;
    W2Grad, B2Grad: TAvoTensor;

    constructor Create(AEmbedDim, AHiddenDim: Integer);
    destructor Destroy; override;

    function Forward(Input: TAvoTensor): TAvoTensor;
    function Backward(DOut: TAvoTensor): TAvoTensor;
    procedure ZeroGrad;
    procedure Step(LearningRate: Single);
  end;


  TAvoTransformerBlock = class
  private
    FInput: TAvoTensor;
    FLN1Out: TAvoTensor;
    FAttnOut: TAvoTensor;
    FRes1: TAvoTensor;
    FLN2Out: TAvoTensor;
    FFFNOut: TAvoTensor;
    procedure ClearSaved;
  public
    MHA: TAvoMultiHeadAttention;
    FFN: TAvoFeedForward;
    LN1, LN2: TAvoLayerNorm;

    constructor Create(EmbedDim, NumHeads, HiddenDim, SeqLen: Integer);
    destructor Destroy; override;

    function Forward(Input: TAvoTensor; Mask: TAvoTensor = nil): TAvoTensor;
    function Backward(DOut: TAvoTensor): TAvoTensor;
    procedure ZeroGrad;
    procedure Step(LearningRate: Single);
  end;

function GELU(X: Single): Single;
function GELUDerivative(X: Single): Single;

implementation

function GELU(X: Single): Single;
const
  C1 = 0.7978845608;
  C2 = 0.044715;
var Inner: Single;
begin
  Inner  := C1 * (X + C2 * X * X * X);
  Result := 0.5 * X * (1.0 + Tanh(Inner));
end;

function GELUDerivative(X: Single): Single;
const
  C1 = 0.7978845608;
  C2 = 0.044715;
var TanhVal, SechSq, Inner: Single;
begin
  Inner   := C1 * (X + C2 * X * X * X);
  TanhVal := Tanh(Inner);
  SechSq  := 1.0 - TanhVal * TanhVal;
  Result  := 0.5 * (1.0 + TanhVal)
           + 0.5 * X * SechSq * C1 * (1.0 + 3.0 * C2 * X * X);
end;


function CloneReshape(Source: TAvoTensor; const NewShape: TShapeArray): TAvoTensor;
begin
  Result := TAvoTensor.Create(NewShape);
  if Result.NumEl <> Source.NumEl then
  begin
    Result.Free;
    raise Exception.CreateFmt('CloneReshape: liczba elementow sie nie zgadza (Old=%d, New=%d)',
                              [Source.NumEl, Result.NumEl]);
  end;
  if Source.NumEl > 0 then
    Move(Source.Data[0], Result.Data[0], Source.NumEl * SizeOf(Single));
end;


constructor TAvoLayerNorm.Create(ADim: Integer; AEps: Single = 1e-5);
var i: Integer;
begin
  Dim := ADim;
  Eps := AEps;

  Gamma     := TAvoTensor.Create([Dim]);
  Beta      := TAvoTensor.Create([Dim]);
  GammaGrad := TAvoTensor.Create([Dim]);
  BetaGrad  := TAvoTensor.Create([Dim]);

  for i := 0 to Dim - 1 do
  begin
    Gamma.Data[i]     := 1.0;
    Beta.Data[i]      := 0.0;
    GammaGrad.Data[i] := 0.0;
    BetaGrad.Data[i]  := 0.0;
  end;

  FNorm := nil;
end;

destructor TAvoLayerNorm.Destroy;
begin
  Gamma.Free; Beta.Free;
  GammaGrad.Free; BetaGrad.Free;
  if FNorm <> nil then FNorm.Free;
  inherited Destroy;
end;

function TAvoLayerNorm.Forward(Input: TAvoTensor): TAvoTensor;
var
  i, j, N, D: Integer;
  Sum, Mean, VarSum, Variance: Single;
begin
  if Input = nil then
    raise Exception.Create('LayerNorm.Forward: Input = nil');

  if Dim <= 0 then
    raise Exception.Create('LayerNorm.Forward: Dim <= 0');

  if (Input.NumEl mod Dim) <> 0 then
    raise Exception.CreateFmt(
      'LayerNorm.Forward: Input.NumEl (%d) nie dzieli sie przez Dim (%d)',
      [Input.NumEl, Dim]
    );

  FInput := Input;
  D := Dim;
  N := Input.NumEl div D;

  SetLength(FMean,   N);
  SetLength(FInvStd, N);

  if FNorm <> nil then FreeAndNil(FNorm);
  FNorm  := TAvoTensor.Create(Input.Shape);
  Result := TAvoTensor.Create(Input.Shape);

  for i := 0 to N - 1 do
  begin
    Sum := 0.0;
    for j := 0 to D - 1 do
      Sum := Sum + Input.Data[i * D + j];
    Mean     := Sum / D;
    FMean[i] := Mean;

    VarSum := 0.0;
    for j := 0 to D - 1 do
      VarSum := VarSum + Sqr(Input.Data[i * D + j] - Mean);
    Variance    := VarSum / D;
    FInvStd[i]  := 1.0 / Sqrt(Variance + Eps);

    for j := 0 to D - 1 do
    begin
      FNorm.Data[i * D + j]  := (Input.Data[i * D + j] - Mean) * FInvStd[i];
      Result.Data[i * D + j] := FNorm.Data[i * D + j] * Gamma.Data[j] + Beta.Data[j];
    end;
  end;
end;

function TAvoLayerNorm.Backward(DOut: TAvoTensor): TAvoTensor;
var
  i, j, N, D: Integer;
  DXNorm, DGamma, DBeta, SumDXNorm, SumDXNormX: Single;
begin
  if DOut = nil then
    raise Exception.Create('LayerNorm.Backward: DOut = nil');

  if FNorm = nil then
    raise Exception.Create('LayerNorm.Backward: FNorm = nil, Forward nie zostal wykonany');

  if Dim <= 0 then
    raise Exception.Create('LayerNorm.Backward: Dim <= 0');

  if (DOut.NumEl mod Dim) <> 0 then
    raise Exception.CreateFmt(
      'LayerNorm.Backward: DOut.NumEl (%d) nie dzieli sie przez Dim (%d)',
      [DOut.NumEl, Dim]
    );

  D := Dim;
  N := DOut.NumEl div D;
  Result := TAvoTensor.Create(DOut.Shape);

  for j := 0 to D - 1 do
  begin
    DGamma := 0.0; DBeta := 0.0;
    for i := 0 to N - 1 do
    begin
      DGamma := DGamma + DOut.Data[i * D + j] * FNorm.Data[i * D + j];
      DBeta  := DBeta  + DOut.Data[i * D + j];
    end;
    GammaGrad.Data[j] := GammaGrad.Data[j] + DGamma;
    BetaGrad.Data[j]  := BetaGrad.Data[j]  + DBeta;
  end;

  for i := 0 to N - 1 do
  begin
    SumDXNorm := 0.0; SumDXNormX := 0.0;
    for j := 0 to D - 1 do
    begin
      DXNorm     := DOut.Data[i * D + j] * Gamma.Data[j];
      SumDXNorm  := SumDXNorm  + DXNorm;
      SumDXNormX := SumDXNormX + DXNorm * FNorm.Data[i * D + j];
    end;
    for j := 0 to D - 1 do
    begin
      DXNorm := DOut.Data[i * D + j] * Gamma.Data[j];
      Result.Data[i * D + j] := FInvStd[i] / D *
        (D * DXNorm - SumDXNorm - FNorm.Data[i * D + j] * SumDXNormX);
    end;
  end;
end;

procedure TAvoLayerNorm.ZeroGrad;
var i: Integer;
begin
  for i := 0 to Dim - 1 do
  begin
    GammaGrad.Data[i] := 0.0;
    BetaGrad.Data[i]  := 0.0;
  end;
end;

procedure TAvoLayerNorm.Step(LearningRate: Single);
var i: Integer;
begin
  for i := 0 to Dim - 1 do
  begin
    Gamma.Data[i] := Gamma.Data[i] - LearningRate * GammaGrad.Data[i];
    Beta.Data[i]  := Beta.Data[i]  - LearningRate * BetaGrad.Data[i];
  end;
end;


constructor TAvoFeedForward.Create(AEmbedDim, AHiddenDim: Integer);
var i: Integer;
begin
  EmbedDim  := AEmbedDim;
  HiddenDim := AHiddenDim;

  W1 := TAvoTensor.Create([EmbedDim, HiddenDim]);
  B1 := TAvoTensor.Create([HiddenDim]);
  W2 := TAvoTensor.Create([HiddenDim, EmbedDim]);
  B2 := TAvoTensor.Create([EmbedDim]);

  W1Grad := TAvoTensor.Create([EmbedDim, HiddenDim]);
  B1Grad := TAvoTensor.Create([HiddenDim]);
  W2Grad := TAvoTensor.Create([HiddenDim, EmbedDim]);
  B2Grad := TAvoTensor.Create([EmbedDim]);

  InitXavierUniform(W1, EmbedDim, HiddenDim);
  InitXavierUniform(W2, HiddenDim, EmbedDim);

  for i := 0 to High(B1.Data) do begin B1.Data[i] := 0.0; B1Grad.Data[i] := 0.0; end;
  for i := 0 to High(B2.Data) do begin B2.Data[i] := 0.0; B2Grad.Data[i] := 0.0; end;
  for i := 0 to High(W1Grad.Data) do W1Grad.Data[i] := 0.0;
  for i := 0 to High(W2Grad.Data) do W2Grad.Data[i] := 0.0;

  FFlatInput := nil; FL1Out := nil; FActOut := nil;
  FWas3D := False;
end;

destructor TAvoFeedForward.Destroy;
begin
  W1.Free; B1.Free; W2.Free; B2.Free;
  W1Grad.Free; B1Grad.Free; W2Grad.Free; B2Grad.Free;
  ClearSaved;
  inherited Destroy;
end;

procedure TAvoFeedForward.ClearSaved;
begin
  if FFlatInput <> nil then FreeAndNil(FFlatInput);
  if FL1Out     <> nil then FreeAndNil(FL1Out);
  if FActOut    <> nil then FreeAndNil(FActOut);
end;

function TAvoFeedForward.Forward(Input: TAvoTensor): TAvoTensor;
var
  Rows, i, j: Integer;
  L2Out: TAvoTensor;
begin
  if Input = nil then
    raise Exception.Create('FeedForward.Forward: Input = nil');

  if not ((Length(Input.Shape) = 2) or (Length(Input.Shape) = 3)) then
    raise Exception.Create('FeedForward.Forward: oczekiwano tensora 2D lub 3D');

  if Input.Shape[High(Input.Shape)] <> EmbedDim then
    raise Exception.CreateFmt(
      'FeedForward.Forward: ostatni wymiar (%d) != EmbedDim (%d)',
      [Input.Shape[High(Input.Shape)], EmbedDim]
    );

  ClearSaved;
  FOrigShape := Copy(Input.Shape);

  FWas3D := (Length(Input.Shape) = 3);
  if FWas3D then
  begin
    Rows := Input.Shape[0] * Input.Shape[1];
    FFlatInput := CloneReshape(Input, [Rows, EmbedDim]);
  end
  else
  begin
    Rows := Input.Shape[0];
    FFlatInput := CloneReshape(Input, [Rows, EmbedDim]);
  end;

  FL1Out := DotProduct(FFlatInput, W1);
  for i := 0 to Rows - 1 do
    for j := 0 to HiddenDim - 1 do
      FL1Out.Data[i * HiddenDim + j] := FL1Out.Data[i * HiddenDim + j] + B1.Data[j];

  FActOut := TAvoTensor.Create(FL1Out.Shape);
  for i := 0 to High(FL1Out.Data) do
    FActOut.Data[i] := Max(0.0, FL1Out.Data[i]);

  L2Out := DotProduct(FActOut, W2);
  try
    for i := 0 to Rows - 1 do
      for j := 0 to EmbedDim - 1 do
        L2Out.Data[i * EmbedDim + j] := L2Out.Data[i * EmbedDim + j] + B2.Data[j];

    // [A] Bezpieczne klonowanie gwarantujące Deep Copy
    Result := CloneReshape(L2Out, FOrigShape);
  finally
    if L2Out <> nil then L2Out.Free;
  end;
end;

function TAvoFeedForward.Backward(DOut: TAvoTensor): TAvoTensor;
var
  Rows, i, j: Integer;
  FlatDOut, dW2, ActOut_T, dActOut, W2_T, dL1: TAvoTensor;
  dW1, FlatInp_T, dInputFlat, W1_T: TAvoTensor;
  Sum: Single;
begin
  if DOut = nil then
    raise Exception.Create('FeedForward.Backward: DOut = nil');

  // [B] Guardy weryfikujące, czy aktywacje pośrednie z Forward są nienaruszone
  if FFlatInput = nil then
    raise Exception.Create('FeedForward.Backward: FFlatInput = nil, Forward nie zostal wykonany');
  if FL1Out = nil then
    raise Exception.Create('FeedForward.Backward: FL1Out = nil, Forward nie zostal wykonany');
  if FActOut = nil then
    raise Exception.Create('FeedForward.Backward: FActOut = nil, Forward nie zostal wykonany');

  if not ((Length(DOut.Shape) = 2) or (Length(DOut.Shape) = 3)) then
    raise Exception.Create('FeedForward.Backward: oczekiwano tensora 2D lub 3D');

  if DOut.Shape[High(DOut.Shape)] <> EmbedDim then
    raise Exception.CreateFmt(
      'FeedForward.Backward: ostatni wymiar DOut (%d) != EmbedDim (%d)',
      [DOut.Shape[High(DOut.Shape)], EmbedDim]
    );

  FlatDOut := nil; dW2 := nil; ActOut_T := nil; dActOut := nil;
  W2_T := nil; dL1 := nil; dW1 := nil; FlatInp_T := nil;
  dInputFlat := nil; W1_T := nil;

  try
    if FWas3D then
    begin
      Rows    := DOut.Shape[0] * DOut.Shape[1];
      FlatDOut := CloneReshape(DOut, [Rows, EmbedDim]);
    end
    else
    begin
      Rows    := DOut.Shape[0];
      FlatDOut := CloneReshape(DOut, [Rows, EmbedDim]);
    end;

    ActOut_T := Transpose(FActOut);
    dW2      := DotProduct(ActOut_T, FlatDOut);
    for i := 0 to High(W2Grad.Data) do W2Grad.Data[i] := W2Grad.Data[i] + dW2.Data[i];

    for j := 0 to EmbedDim - 1 do
    begin
      Sum := 0.0;
      for i := 0 to Rows - 1 do Sum := Sum + FlatDOut.Data[i * EmbedDim + j];
      B2Grad.Data[j] := B2Grad.Data[j] + Sum;
    end;

    W2_T    := Transpose(W2);
    dActOut := DotProduct(FlatDOut, W2_T);

    dL1 := TAvoTensor.Create(dActOut.Shape);
    for i := 0 to High(dActOut.Data) do
    begin
      if FL1Out.Data[i] > 0 then dL1.Data[i] := dActOut.Data[i]
      else                       dL1.Data[i] := 0.0;
    end;

    FlatInp_T := Transpose(FFlatInput);
    dW1       := DotProduct(FlatInp_T, dL1);
    for i := 0 to High(W1Grad.Data) do W1Grad.Data[i] := W1Grad.Data[i] + dW1.Data[i];

    for j := 0 to HiddenDim - 1 do
    begin
      Sum := 0.0;
      for i := 0 to Rows - 1 do Sum := Sum + dL1.Data[i * HiddenDim + j];
      B1Grad.Data[j] := B1Grad.Data[j] + Sum;
    end;

    W1_T       := Transpose(W1);
    dInputFlat := DotProduct(dL1, W1_T);
    Result := CloneReshape(dInputFlat, FOrigShape);

  finally
    if FlatDOut <> nil then FlatDOut.Free;
    if dW2 <> nil then dW2.Free;
    if ActOut_T <> nil then ActOut_T.Free;
    if dActOut <> nil then dActOut.Free;
    if W2_T <> nil then W2_T.Free;
    if dL1 <> nil then dL1.Free;
    if dW1 <> nil then dW1.Free;
    if FlatInp_T <> nil then FlatInp_T.Free;
    if dInputFlat <> nil then dInputFlat.Free;
    if W1_T <> nil then W1_T.Free;
  end;
end;

procedure TAvoFeedForward.ZeroGrad;
var i: Integer;
begin
  for i := 0 to High(W1Grad.Data) do W1Grad.Data[i] := 0.0;
  for i := 0 to High(B1Grad.Data) do B1Grad.Data[i] := 0.0;
  for i := 0 to High(W2Grad.Data) do W2Grad.Data[i] := 0.0;
  for i := 0 to High(B2Grad.Data) do B2Grad.Data[i] := 0.0;
end;

procedure TAvoFeedForward.Step(LearningRate: Single);
var i: Integer;
begin
  for i := 0 to High(W1.Data) do W1.Data[i] := W1.Data[i] - LearningRate * W1Grad.Data[i];
  for i := 0 to High(B1.Data) do B1.Data[i] := B1.Data[i] - LearningRate * B1Grad.Data[i];
  for i := 0 to High(W2.Data) do W2.Data[i] := W2.Data[i] - LearningRate * W2Grad.Data[i];
  for i := 0 to High(B2.Data) do B2.Data[i] := B2.Data[i] - LearningRate * B2Grad.Data[i];
end;


constructor TAvoTransformerBlock.Create(EmbedDim, NumHeads, HiddenDim, SeqLen: Integer);
begin
  MHA := TAvoMultiHeadAttention.Create(EmbedDim, NumHeads, SeqLen);
  FFN := TAvoFeedForward.Create(EmbedDim, HiddenDim);
  LN1 := TAvoLayerNorm.Create(EmbedDim);
  LN2 := TAvoLayerNorm.Create(EmbedDim);

  FLN1Out := nil; FAttnOut := nil;
  FRes1   := nil; FLN2Out  := nil; FFFNOut := nil;
end;

destructor TAvoTransformerBlock.Destroy;
begin
  MHA.Free; FFN.Free; LN1.Free; LN2.Free;
  ClearSaved;
  inherited Destroy;
end;

procedure TAvoTransformerBlock.ClearSaved;
begin
  if FLN1Out <> nil then FreeAndNil(FLN1Out);
  if FAttnOut <> nil then FreeAndNil(FAttnOut);
  if FRes1   <> nil then FreeAndNil(FRes1);
  if FLN2Out <> nil then FreeAndNil(FLN2Out);
  if FFFNOut <> nil then FreeAndNil(FFFNOut);
end;

function TAvoTransformerBlock.Forward(Input: TAvoTensor; Mask: TAvoTensor = nil): TAvoTensor;
var i: Integer;
begin
  if Input = nil then raise Exception.Create('TransformerBlock.Forward: Input = nil');

  ClearSaved;
  FInput := Input;

  FLN1Out := LN1.Forward(Input);

  // Świadomie ignorujemy ewentualny parametr Mask z zewnątrz,
  // ponieważ TAvoMultiHeadAttention zarządza własną maską kauzalną.
  FAttnOut := MHA.Forward(FLN1Out);

  if FAttnOut = nil then
    raise Exception.Create('TransformerBlock.Forward: MHA output = nil');

  if FAttnOut.NumEl <> Input.NumEl then
    raise Exception.CreateFmt(
      'TransformerBlock.Forward: MHA output size mismatch. Input=%d, Attn=%d',
      [Input.NumEl, FAttnOut.NumEl]
    );

  FRes1 := TAvoTensor.Create(Input.Shape);
  for i := 0 to High(Input.Data) do
    FRes1.Data[i] := Input.Data[i] + FAttnOut.Data[i];

  FLN2Out := LN2.Forward(FRes1);
  FFFNOut := FFN.Forward(FLN2Out);

  if FFFNOut = nil then
    raise Exception.Create('TransformerBlock.Forward: FFN output = nil');

  if FFFNOut.NumEl <> FRes1.NumEl then
    raise Exception.CreateFmt(
      'TransformerBlock.Forward: FFN output size mismatch. Res1=%d, FFN=%d',
      [FRes1.NumEl, FFFNOut.NumEl]
    );

  Result := TAvoTensor.Create(FRes1.Shape);
  for i := 0 to High(FRes1.Data) do
    Result.Data[i] := FRes1.Data[i] + FFFNOut.Data[i];
end;

function TAvoTransformerBlock.Backward(DOut: TAvoTensor): TAvoTensor;
var
  DFfn, DLn2, DRes1, DAttn, DLn1: TAvoTensor;
  i: Integer;
begin
  if DOut = nil then raise Exception.Create('TransformerBlock.Backward: DOut = nil');

  DFfn := nil; DLn2 := nil; DRes1 := nil; DAttn := nil; DLn1 := nil;

  try
    DFfn  := FFN.Backward(DOut);
    DLn2  := LN2.Backward(DFfn);

    DRes1 := TAvoTensor.Create(DOut.Shape);
    for i := 0 to High(DOut.Data) do
      DRes1.Data[i] := DOut.Data[i] + DLn2.Data[i];

    DAttn := MHA.Backward(DRes1);
    DLn1  := LN1.Backward(DAttn);

    Result := TAvoTensor.Create(DOut.Shape);
    for i := 0 to High(DOut.Data) do
      Result.Data[i] := DRes1.Data[i] + DLn1.Data[i];

  finally
    if DFfn <> nil then DFfn.Free;
    if DLn2 <> nil then DLn2.Free;
    if DRes1 <> nil then DRes1.Free;
    if DAttn <> nil then DAttn.Free;
    if DLn1 <> nil then DLn1.Free;
  end;
end;

procedure TAvoTransformerBlock.ZeroGrad;
begin
  MHA.ZeroGrad; FFN.ZeroGrad; LN1.ZeroGrad; LN2.ZeroGrad;
end;

procedure TAvoTransformerBlock.Step(LearningRate: Single);
begin
  MHA.Step(LearningRate); FFN.Step(LearningRate);
  LN1.Step(LearningRate); LN2.Step(LearningRate);
end;

end.



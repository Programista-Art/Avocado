{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.attention;
// avotensor.attention — Scaled Dot-Product Attention + Multi-Head Attention

interface

uses
  SysUtils, Math, Types,
  avotensor.core,
  avotensor.ops,
  avotensor.nn,
  avotensor.init;

type
  TAvoScaledDotAttention = class
  private
    FSeqLen:      Integer;
    FDimK:        Integer;
    FCausal:      Boolean;
    FQ, FK, FV:   TAvoTensor;
    FAttnWeights: TAvoTensor;
  public
    constructor Create(ASeqLen, ADimK: Integer; ACausal: Boolean = True);
    destructor  Destroy; override;

    function Forward(Q, K, V: TAvoTensor): TAvoTensor;
    procedure Backward(
      DOut:   TAvoTensor;
      out DQ: TAvoTensor;
      out DK: TAvoTensor;
      out DV: TAvoTensor
    );

    property AttnWeights: TAvoTensor read FAttnWeights;
    property Causal: Boolean read FCausal;
  end;

  TAvoMultiHeadAttention = class
  private
    FEmbDim:   Integer;
    FNumHeads: Integer;
    FHeadDim:  Integer;
    FSeqLen:   Integer;
    FCausal:   Boolean;

    FQFull:    TAvoTensor;
    FKFull:    TAvoTensor;
    FVFull:    TAvoTensor;
    FConcatWo: TAvoTensor;


    FQHeads:   array of TAvoTensor;
    FKHeads:   array of TAvoTensor;
    FVHeads:   array of TAvoTensor;

    FAttnList: array of TAvoScaledDotAttention;
    FHeadOuts: array of TAvoTensor;

    procedure FreeForwardCache;

  public
    Wq, Wk, Wv, Wo: TAvoLinearLayer;

    constructor Create(AEmbDim, ANumHeads, ASeqLen: Integer; ACausal: Boolean = True);
    destructor  Destroy; override;

    function Forward(X: TAvoTensor): TAvoTensor;
    function Backward(DOut: TAvoTensor): TAvoTensor;

    procedure ZeroGrad;
    procedure Step(LearningRate: Single);

    property EmbDim:   Integer read FEmbDim;
    property NumHeads: Integer read FNumHeads;
    property HeadDim:  Integer read FHeadDim;
  end;

implementation


// Pomocnicze

procedure ApplyCausalMask(Attn: TAvoTensor; SeqLen: Integer);
var
  i, j: Integer;
begin
  if Attn = nil then Exit;
  for i := 0 to SeqLen - 1 do
    for j := i + 1 to SeqLen - 1 do
      Attn.Data[i * SeqLen + j] := -1.0e9;
end;

function SliceHead(X: TAvoTensor; HeadIdx, HeadDim: Integer): TAvoTensor;
var
  SeqLen, EmbDim, i, j, Offset: Integer;
begin
  if X = nil then
    raise Exception.Create('Attention.SliceHead: X = nil.');

  if Length(X.Shape) <> 2 then
    raise Exception.Create('Attention.SliceHead: oczekiwano tensora 2D [SeqLen, EmbDim].');

  SeqLen := X.Shape[0];
  EmbDim := X.Shape[1];
  Offset := HeadIdx * HeadDim;

  if (HeadIdx < 0) or (HeadDim <= 0) or (Offset + HeadDim > EmbDim) then
    raise Exception.Create('Attention.SliceHead: nieprawidlowy HeadIdx/HeadDim.');

  Result := TAvoTensor.Create([SeqLen, HeadDim]);
  for i := 0 to SeqLen - 1 do
    for j := 0 to HeadDim - 1 do
      Result.Data[i * HeadDim + j] := X.Data[i * EmbDim + Offset + j];
end;

procedure WriteHead(Dst, Src: TAvoTensor; HeadIdx, HeadDim: Integer);
var
  SeqLen, EmbDim, i, j, Offset: Integer;
begin
  if (Dst = nil) or (Src = nil) then
    raise Exception.Create('Attention.WriteHead: Dst lub Src to nil.');

  if Length(Dst.Shape) <> 2 then
    raise Exception.Create('Attention.WriteHead: Dst musi byc 2D.');

  if Length(Src.Shape) <> 2 then
    raise Exception.Create('Attention.WriteHead: Src musi byc 2D.');

  if Src.Shape[1] <> HeadDim then
    raise Exception.Create('Attention.WriteHead: Src.Shape[1] != HeadDim.');

  if Src.Shape[0] <> Dst.Shape[0] then
    raise Exception.Create('Attention.WriteHead: SeqLen mismatch.');

  if (HeadIdx < 0) or (HeadIdx * HeadDim + HeadDim > Dst.Shape[1]) then
    raise Exception.Create('Attention.WriteHead: zakres glowy wychodzi poza EmbDim.');

  SeqLen := Src.Shape[0];
  EmbDim := Dst.Shape[1];
  Offset := HeadIdx * HeadDim;

  for i := 0 to SeqLen - 1 do
    for j := 0 to HeadDim - 1 do
      Dst.Data[i * EmbDim + Offset + j] := Src.Data[i * HeadDim + j];
end;


// TAvoScaledDotAttention

constructor TAvoScaledDotAttention.Create(ASeqLen, ADimK: Integer; ACausal: Boolean);
begin
  FSeqLen      := ASeqLen;
  FDimK        := ADimK;
  FCausal      := ACausal;
  FQ           := nil;
  FK           := nil;
  FV           := nil;
  FAttnWeights := nil;
end;

destructor TAvoScaledDotAttention.Destroy;
begin
  if FAttnWeights <> nil then FAttnWeights.Free;
  inherited Destroy;
end;

function TAvoScaledDotAttention.Forward(Q, K, V: TAvoTensor): TAvoTensor;
var
  Scale:  Single;
  KT:     TAvoTensor;
  Scores: TAvoTensor;
  i:      Integer;
begin
  if (Q = nil) or (K = nil) or (V = nil) then
    raise Exception.Create('ScaledDotAttention.Forward: Q, K lub V to nil.');

  if (Length(Q.Shape) <> 2) or (Length(K.Shape) <> 2) or (Length(V.Shape) <> 2) then
    raise Exception.Create('ScaledDotAttention.Forward: Q/K/V musza byc 2D.');

  if (Q.Shape[1] <> FDimK) or (K.Shape[1] <> FDimK) or (V.Shape[1] <> FDimK) then
    raise Exception.Create('ScaledDotAttention.Forward: HeadDim mismatch.');

  if (Q.Shape[0] <> K.Shape[0]) or (Q.Shape[0] <> V.Shape[0]) then
    raise Exception.Create('ScaledDotAttention.Forward: SeqLen mismatch.');

  Scale := 1.0 / Sqrt(FDimK);

  FQ := Q;
  FK := K;
  FV := V;

  KT     := nil;
  Scores := nil;
  try
    KT     := Transpose(K);
    Scores := DotProduct(Q, KT);

    for i := 0 to High(Scores.Data) do
      Scores.Data[i] := Scores.Data[i] * Scale;

    if FCausal then
      ApplyCausalMask(Scores, Q.Shape[0]);

    if FAttnWeights <> nil then FAttnWeights.Free;
    FAttnWeights := Softmax(Scores);
  finally
    KT.Free;
    Scores.Free;
  end;

  Result := DotProduct(FAttnWeights, V);
end;

procedure TAvoScaledDotAttention.Backward(
  DOut:   TAvoTensor;
  out DQ: TAvoTensor;
  out DK: TAvoTensor;
  out DV: TAvoTensor
);
var
  Scale:   Single;
  AttnT:   TAvoTensor;
  VT:      TAvoTensor;
  DAttn:   TAvoTensor;
  DScores: TAvoTensor;
  QT:      TAvoTensor;
  i:       Integer;
begin
  if DOut = nil then raise Exception.Create('ScaledDotAttention.Backward: DOut to nil.');
  if FAttnWeights = nil then raise Exception.Create('ScaledDotAttention.Backward: FAttnWeights to nil. Uruchom Forward najpierw.');

  Scale   := 1.0 / Sqrt(FDimK);
  AttnT   := nil; VT := nil;
  DAttn   := nil; DScores := nil; QT := nil;
  DQ := nil; DK := nil; DV := nil;

  try
    AttnT := Transpose(FAttnWeights);
    DV    := DotProduct(AttnT, DOut);

    VT    := Transpose(FV);
    DAttn := DotProduct(DOut, VT);

    DScores := SoftmaxBackward(FAttnWeights, DAttn);
    for i := 0 to High(DScores.Data) do
      DScores.Data[i] := DScores.Data[i] * Scale;

    DQ := DotProduct(DScores, FK);

    QT := Transpose(DScores);
    DK := DotProduct(QT, FQ);

  finally
    if AttnT <> nil then AttnT.Free;
    if VT <> nil then VT.Free;
    if DAttn <> nil then DAttn.Free;
    if DScores <> nil then DScores.Free;
    if QT <> nil then QT.Free;
  end;
end;


// TAvoMultiHeadAttention


constructor TAvoMultiHeadAttention.Create(
  AEmbDim, ANumHeads, ASeqLen: Integer; ACausal: Boolean);
var
  i: Integer;
begin
  if AEmbDim <= 0 then
    raise Exception.Create('MultiHeadAttention: EmbDim musi byc > 0.');

  if ANumHeads <= 0 then
    raise Exception.Create('MultiHeadAttention: NumHeads musi byc > 0.');

  if ASeqLen <= 0 then
    raise Exception.Create('MultiHeadAttention: SeqLen musi byc > 0.');

  if AEmbDim mod ANumHeads <> 0 then
    raise Exception.CreateFmt(
      'MultiHeadAttention: EmbDim=%d musi byc podzielne przez NumHeads=%d.',
      [AEmbDim, ANumHeads]);

  FEmbDim   := AEmbDim;
  FNumHeads := ANumHeads;
  FHeadDim  := AEmbDim div ANumHeads;
  FSeqLen   := ASeqLen;
  FCausal   := ACausal;

  FQFull    := nil; FKFull := nil; FVFull := nil; FConcatWo := nil;

  Wq := TAvoLinearLayer.Create;
  Wq.Wagi := TAvoTensor.Create([AEmbDim, AEmbDim]);
  Wq.Bias := TAvoTensor.Create([AEmbDim]);
  InitXavierUniform(Wq.Wagi, AEmbDim, AEmbDim);

  Wk := TAvoLinearLayer.Create;
  Wk.Wagi := TAvoTensor.Create([AEmbDim, AEmbDim]);
  Wk.Bias := TAvoTensor.Create([AEmbDim]);
  InitXavierUniform(Wk.Wagi, AEmbDim, AEmbDim);

  Wv := TAvoLinearLayer.Create;
  Wv.Wagi := TAvoTensor.Create([AEmbDim, AEmbDim]);
  Wv.Bias := TAvoTensor.Create([AEmbDim]);
  InitXavierUniform(Wv.Wagi, AEmbDim, AEmbDim);

  Wo := TAvoLinearLayer.Create;
  Wo.Wagi := TAvoTensor.Create([AEmbDim, AEmbDim]);
  Wo.Bias := TAvoTensor.Create([AEmbDim]);
  InitXavierUniform(Wo.Wagi, AEmbDim, AEmbDim);

  SetLength(FAttnList, ANumHeads);
  SetLength(FHeadOuts, ANumHeads);
  SetLength(FQHeads,   ANumHeads);
  SetLength(FKHeads,   ANumHeads);
  SetLength(FVHeads,   ANumHeads);
  for i := 0 to ANumHeads - 1 do
  begin
    FAttnList[i] := TAvoScaledDotAttention.Create(ASeqLen, FHeadDim, ACausal);
    FHeadOuts[i] := nil;
    FQHeads[i]   := nil;
    FKHeads[i]   := nil;
    FVHeads[i]   := nil;
  end;
end;

procedure TAvoMultiHeadAttention.FreeForwardCache;
var i: Integer;
begin
  if FQFull <> nil then FreeAndNil(FQFull);
  if FKFull <> nil then FreeAndNil(FKFull);
  if FVFull <> nil then FreeAndNil(FVFull);
  if FConcatWo <> nil then FreeAndNil(FConcatWo);

  for i := 0 to FNumHeads - 1 do
  begin
    if FHeadOuts[i] <> nil then FreeAndNil(FHeadOuts[i]);
    if FQHeads[i] <> nil then FreeAndNil(FQHeads[i]);
    if FKHeads[i] <> nil then FreeAndNil(FKHeads[i]);
    if FVHeads[i] <> nil then FreeAndNil(FVHeads[i]);
  end;
end;

destructor TAvoMultiHeadAttention.Destroy;
var i: Integer;
begin
  FreeForwardCache;
  Wq.Free; Wk.Free; Wv.Free; Wo.Free;
  for i := 0 to High(FAttnList) do
    FAttnList[i].Free;
  inherited Destroy;
end;

function TAvoMultiHeadAttention.Forward(X: TAvoTensor): TAvoTensor;
var
  SeqLen, h: Integer;
begin
  if X = nil then raise Exception.Create('MultiHeadAttention.Forward: Input X is nil');
  if Length(X.Shape) <> 2 then raise Exception.Create('MultiHeadAttention.Forward: Wymagany tensor 2D [SeqLen, EmbDim]');
  if X.Shape[1] <> FEmbDim then raise Exception.CreateFmt('MultiHeadAttention.Forward: EmbDim mismatch. Oczekiwano %d', [FEmbDim]);

  SeqLen := X.Shape[0];

  FreeForwardCache;

  FQFull := Wq.Forward(X);
  FKFull := Wk.Forward(X);
  FVFull := Wv.Forward(X);

  FConcatWo := TAvoTensor.Create([SeqLen, FEmbDim]);

  for h := 0 to FNumHeads - 1 do
  begin
    FQHeads[h] := SliceHead(FQFull, h, FHeadDim);
    FKHeads[h] := SliceHead(FKFull, h, FHeadDim);
    FVHeads[h] := SliceHead(FVFull, h, FHeadDim);

    FHeadOuts[h] := FAttnList[h].Forward(FQHeads[h], FKHeads[h], FVHeads[h]);
    WriteHead(FConcatWo, FHeadOuts[h], h, FHeadDim);
  end;

  Result := Wo.Forward(FConcatWo);
end;

function TAvoMultiHeadAttention.Backward(DOut: TAvoTensor): TAvoTensor;
var
  SeqLen, h, i:        Integer;
  DConcat:             TAvoTensor;
  DQFull, DKFull, DVFull: TAvoTensor;
  DQH, DKH, DVH:       TAvoTensor;
  DHeadSlice:          TAvoTensor;
  DQProj, DKProj, DVProj: TAvoTensor;
begin
  if DOut = nil then raise Exception.Create('MultiHeadAttention.Backward: DOut to nil.');

  if FConcatWo = nil then
    raise Exception.Create('MultiHeadAttention.Backward: Forward nie zostal wykonany albo cache jest pusty (FConcatWo=nil).');
  if FQFull = nil then
    raise Exception.Create('MultiHeadAttention.Backward: FQFull = nil.');
  if FKFull = nil then
    raise Exception.Create('MultiHeadAttention.Backward: FKFull = nil.');
  if FVFull = nil then
    raise Exception.Create('MultiHeadAttention.Backward: FVFull = nil.');

  SeqLen  := DOut.Shape[0];
  DConcat := nil;
  DQFull  := nil; DKFull := nil; DVFull := nil;
  DQH     := nil; DKH    := nil; DVH    := nil;
  DHeadSlice := nil;
  DQProj  := nil; DKProj := nil; DVProj := nil;
  Result  := nil;

  try
    DConcat := Wo.Backward(DOut);

    DQFull := TAvoTensor.Create([SeqLen, FEmbDim]);
    DKFull := TAvoTensor.Create([SeqLen, FEmbDim]);
    DVFull := TAvoTensor.Create([SeqLen, FEmbDim]);

    for h := 0 to FNumHeads - 1 do
    begin
      DHeadSlice := SliceHead(DConcat, h, FHeadDim);
      try
        FAttnList[h].Backward(DHeadSlice, DQH, DKH, DVH);
        try
          WriteHead(DQFull, DQH, h, FHeadDim);
          WriteHead(DKFull, DKH, h, FHeadDim);
          WriteHead(DVFull, DVH, h, FHeadDim);
        finally
          if DQH <> nil then FreeAndNil(DQH);
          if DKH <> nil then FreeAndNil(DKH);
          if DVH <> nil then FreeAndNil(DVH);
        end;
      finally
        if DHeadSlice <> nil then FreeAndNil(DHeadSlice);
      end;
    end;

    DQProj := Wq.Backward(DQFull);
    DKProj := Wk.Backward(DKFull);
    DVProj := Wv.Backward(DVFull);

    Result := TAvoTensor.Create([SeqLen, FEmbDim]);
    for i := 0 to High(Result.Data) do
      Result.Data[i] := DQProj.Data[i] + DKProj.Data[i] + DVProj.Data[i];

  finally
    if DConcat <> nil then DConcat.Free;
    if DQFull <> nil then DQFull.Free;
    if DKFull <> nil then DKFull.Free;
    if DVFull <> nil then DVFull.Free;
    if DQProj <> nil then DQProj.Free;
    if DKProj <> nil then DKProj.Free;
    if DVProj <> nil then DVProj.Free;
  end;
end;

procedure TAvoMultiHeadAttention.ZeroGrad;
begin
  Wq.ZeroGrad; Wk.ZeroGrad; Wv.ZeroGrad; Wo.ZeroGrad;
end;

procedure TAvoMultiHeadAttention.Step(LearningRate: Single);
var
  Opt: TAvoOptimizerSGD;
begin
  Opt := TAvoOptimizerSGD.Create(LearningRate);
  try
    Opt.Step(Wq); Opt.Step(Wk); Opt.Step(Wv); Opt.Step(Wo);
  finally
    Opt.Free;
  end;
end;

end.


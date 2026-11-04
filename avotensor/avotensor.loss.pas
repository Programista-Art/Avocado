{$mode objfpc}{$H+}
unit avotensor.loss;
// avotensor.loss — funkcje straty: MSE, CrossEntropy, NLLLoss

interface

uses
  SysUtils, Math,
  avotensor.core;

// MSE: mean((Pred - Target)^2)
// Grad: 2*(Pred - Target) / N
procedure LossMSE(
  Pred, Target: TAvoTensor;
  out Loss: Single;
  out Grad: TAvoTensor
);

// NLLLoss (Negative Log Likelihood) — wejście to LogSoftmax
// Target: wektor int indeksow klas [M] zakodowany jako Single
// Loss: -mean(LogSoftOut[i, Target[i]])
// Grad: -1/M w pozycji Target[i], 0 reszta
procedure LossNLL(
  LogSoftOut: TAvoTensor; // [M, NumClasses] — wynik LogSoftmax
  Target:     TAvoTensor; // [M] — indeksy klas (jako Single, np. 2.0 = klasa 2)
  out Loss: Single;
  out Grad: TAvoTensor    // [M, NumClasses]
);

// CrossEntropyLoss = LogSoftmax + NLLLoss (wygodne polaczenie)
// Wejście: logity [M, NumClasses] (PRZED softmax)
procedure LossCrossEntropy(
  Logits: TAvoTensor;  // [M, NumClasses]
  Target: TAvoTensor;  // [M] — indeksy klas
  out Loss: Single;
  out Grad: TAvoTensor // [M, NumClasses] — gradient wzgledem logitow
);

implementation

uses
  MTProcs;


// workery wątków (map-reduce dla funkcji straty)

type
  TLossThreadData = record
    Logits, Target, Grad: TAvoTensor;
    RowLosses: TSingleArray;
    RowStatus: array of Byte; // 0 = OK, 1 = błąd targetu, 2 = błąd numeryczny (SumExp)
    NumClasses: Integer;
    Scale: Single;
  end;
  PLossThreadData = ^TLossThreadData;

  TMSEThreadData = record
    Pred, Target, Grad: TAvoTensor;
    PartialLosses: TSingleArray;
    Scale: Single;
    BlockSize: Integer;
  end;
  PMSEThreadData = ^TMSEThreadData;

procedure ParallelMSERow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PMSEThreadData;
  i, StartIdx, EndIdx: PtrInt;
  LocalLoss: Single;
begin
  PD := PMSEThreadData(Data);
  Item.CalcBlock(Index, PD^.BlockSize, PD^.Pred.NumEl, StartIdx, EndIdx);

  if StartIdx < 0 then StartIdx := 0;
  if EndIdx >= PD^.Pred.NumEl then EndIdx := PD^.Pred.NumEl - 1;
  if StartIdx > EndIdx then Exit;

  LocalLoss := 0.0;
  for i := StartIdx to EndIdx do
  begin
    LocalLoss := LocalLoss + Sqr(PD^.Pred.Data[i] - PD^.Target.Data[i]);
    PD^.Grad.Data[i] := (PD^.Pred.Data[i] - PD^.Target.Data[i]) * PD^.Scale;
  end;
  PD^.PartialLosses[Index] := LocalLoss;
end;

procedure ParallelNLLRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PLossThreadData;
  ClassIdx: Integer;
  TargetVal: Single;
begin
  PD := PLossThreadData(Data);
  TargetVal := PD^.Target.Data[Index];

  if IsNaN(TargetVal) or IsInfinite(TargetVal) then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  ClassIdx := Trunc(TargetVal);

  if Abs(TargetVal - ClassIdx) > 0.001 then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  if (ClassIdx < 0) or (ClassIdx >= PD^.NumClasses) then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  PD^.RowLosses[Index] := -PD^.Logits.Data[Index * PD^.NumClasses + ClassIdx];
  PD^.Grad.Data[Index * PD^.NumClasses + ClassIdx] := -PD^.Scale;
end;

procedure ParallelCrossEntropyRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PLossThreadData;
  j, ClassIdx, RowOffset: Integer;
  MaxLogit, SumExp, ExpVal, TargetVal: Single;
begin
  PD := PLossThreadData(Data);
  RowOffset := Index * PD^.NumClasses;

  TargetVal := PD^.Target.Data[Index];
  if IsNaN(TargetVal) or IsInfinite(TargetVal) then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  ClassIdx := Trunc(TargetVal);
  if Abs(TargetVal - ClassIdx) > 0.001 then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  if (ClassIdx < 0) or (ClassIdx >= PD^.NumClasses) then
  begin
    PD^.RowStatus[Index] := 1;
    Exit;
  end;

  MaxLogit := PD^.Logits.Data[RowOffset];
  for j := 1 to PD^.NumClasses - 1 do
    if PD^.Logits.Data[RowOffset + j] > MaxLogit then
      MaxLogit := PD^.Logits.Data[RowOffset + j];

  SumExp := 0.0;
  for j := 0 to PD^.NumClasses - 1 do
  begin
    ExpVal := Exp(PD^.Logits.Data[RowOffset + j] - MaxLogit);
    PD^.Grad.Data[RowOffset + j] := ExpVal; // Zapis tymczasowy przed normalizacją
    SumExp := SumExp + ExpVal;
  end;

  // Raportowanie błędu matematycznego do wątku głównego (zamiast cichego ignorowania)
  if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
  begin
    PD^.RowStatus[Index] := 2;
    PD^.RowLosses[Index] := 0.0;
    for j := 0 to PD^.NumClasses - 1 do
      PD^.Grad.Data[RowOffset + j] := 0.0;
    Exit;
  end;

  PD^.RowLosses[Index] := Ln(SumExp) + MaxLogit - PD^.Logits.Data[RowOffset + ClassIdx];

  for j := 0 to PD^.NumClasses - 1 do
    PD^.Grad.Data[RowOffset + j] := (PD^.Grad.Data[RowOffset + j] / SumExp) * PD^.Scale;

  PD^.Grad.Data[RowOffset + ClassIdx] := PD^.Grad.Data[RowOffset + ClassIdx] - PD^.Scale;
end;

// MSE

procedure LossMSE(
  Pred, Target: TAvoTensor;
  out Loss: Single;
  out Grad: TAvoTensor
);
var
  i, N:      Integer;
  Scale:     Single;
  MSEData:   TMSEThreadData;
  BlocksCount, BlkSize: PtrInt;
begin
  Loss := 0.0;
  Grad := nil;

  if Pred = nil then raise Exception.Create('LossMSE: Tensor Pred = nil.');
  if Target = nil then raise Exception.Create('LossMSE: Tensor Target = nil.');

  if Pred.NumEl <> Length(Pred.Data) then raise Exception.Create('LossMSE: Korupcja tensora Pred (NumEl mismatch).');
  if Target.NumEl <> Length(Target.Data) then raise Exception.Create('LossMSE: Korupcja tensora Target (NumEl mismatch).');

  if Length(Pred.Data) <> Length(Target.Data) then
    raise Exception.CreateFmt('LossMSE: Niezgodna liczba elementow (Pred=%d, Target=%d).', [Length(Pred.Data), Length(Target.Data)]);

  if not SameShape(Pred, Target) then
    raise Exception.Create('LossMSE: Niezgodne ksztalty miedzy Pred a Target.');

  N := Length(Pred.Data);
  if N <= 0 then raise Exception.Create('LossMSE: Wymiar N musi byc > 0.');

  Scale := 2.0 / N;
  Grad  := TAvoTensor.Create(Pred.Shape);

  try
    // Akceleracja wielordzeniowa
    if (N > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
    begin
      ProcThreadPool.CalcBlockSize(N, BlocksCount, BlkSize, 1024);
      SetLength(MSEData.PartialLosses, BlocksCount);
      MSEData.Pred := Pred;
      MSEData.Target := Target;
      MSEData.Grad := Grad;
      MSEData.Scale := Scale;
      MSEData.BlockSize := BlkSize;

      ProcThreadPool.DoParallel(@ParallelMSERow, 0, BlocksCount - 1, @MSEData, ProcThreadPool.MaxThreadCount);

      // Sumowanie częściowych strat z wszystkich rdzeni procesora
      for i := 0 to BlocksCount - 1 do
        Loss := Loss + MSEData.PartialLosses[i];
    end
    else
    begin
      for i := 0 to N - 1 do
      begin
        Loss          := Loss + Sqr(Pred.Data[i] - Target.Data[i]);
        Grad.Data[i]  := (Pred.Data[i] - Target.Data[i]) * Scale;
      end;
    end;

    Loss := Loss / N;

    if IsNaN(Loss) or IsInfinite(Loss) then
      raise Exception.Create('LossMSE: Loss = NaN/Inf.');

  except
    if Grad <> nil then FreeAndNil(Grad);
    raise;
  end;
end;

// NLLLoss

procedure LossNLL(
  LogSoftOut: TAvoTensor;
  Target:     TAvoTensor;
  out Loss: Single;
  out Grad: TAvoTensor
);
var
  i, M, NumClasses, ClassIdx: Integer;
  Scale, TargetVal: Single;
  ThreadData: TLossThreadData;
begin
  Loss := 0.0;
  Grad := nil;

  // enterprise guards
  if LogSoftOut = nil then raise Exception.Create('LossNLL: Tensor LogSoftOut = nil.');
  if Target = nil then raise Exception.Create('LossNLL: Tensor Target = nil.');

  if LogSoftOut.NumEl <> Length(LogSoftOut.Data) then raise Exception.Create('LossNLL: Korupcja tensora LogSoftOut (NumEl mismatch).');
  if Target.NumEl <> Length(Target.Data) then raise Exception.Create('LossNLL: Korupcja tensora Target (NumEl mismatch).');

  if Length(LogSoftOut.Shape) <> 2 then
    raise Exception.CreateFmt('LossNLL: LogSoftOut musi byc 2D [M, NumClasses], otrzymano %dD.', [Length(LogSoftOut.Shape)]);
  if Length(Target.Shape) <> 1 then
    raise Exception.CreateFmt('LossNLL: Target musi byc 1D [M], otrzymano %dD.', [Length(Target.Shape)]);

  M          := LogSoftOut.Shape[0];
  NumClasses := LogSoftOut.Shape[1];

  if M <= 0 then raise Exception.Create('LossNLL: Batch Size (M) musi byc > 0.');
  if NumClasses <= 0 then raise Exception.Create('LossNLL: NumClasses musi byc > 0.');

  if Target.Shape[0] <> M then
    raise Exception.CreateFmt(
      'LossNLL: Niezgodny batch — LogSoftOut.M=%d, Target.M=%d.', [M, Target.Shape[0]]);

  if LogSoftOut.NumEl <> M * NumClasses then
    raise Exception.Create('LossNLL: LogSoftOut ma niespojny Shape/Data.');

  Scale := 1.0 / M;
  Grad  := TAvoTensor.Create(LogSoftOut.Shape); // zerowy na starcie

  try
    if (M >= 8) and ((Int64(M) * NumClasses) > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
    begin
      ThreadData.Logits := LogSoftOut;
      ThreadData.Target := Target;
      ThreadData.Grad := Grad;
      ThreadData.NumClasses := NumClasses;
      ThreadData.Scale := Scale;
      SetLength(ThreadData.RowLosses, M);
      SetLength(ThreadData.RowStatus, M);

      for i := 0 to M - 1 do ThreadData.RowStatus[i] := 0; // Inicjalizacja statusów

      ProcThreadPool.DoParallel(@ParallelNLLRow, 0, M - 1, @ThreadData, ProcThreadPool.MaxThreadCount);

      // Faza "Reduce" ze zwalidowanymi wskaźnikami błędów
      for i := 0 to M - 1 do
      begin
        if ThreadData.RowStatus[i] <> 0 then
          raise Exception.CreateFmt('LossNLL: Blad targetu w wierszu %d.', [i]);

        Loss := Loss + ThreadData.RowLosses[i];
      end;
    end
    else
    begin
      for i := 0 to M - 1 do
      begin
        TargetVal := Target.Data[i];
        if IsNaN(TargetVal) or IsInfinite(TargetVal) then
          raise Exception.CreateFmt('LossNLL: Target[%d] = NaN/Inf.', [i]);

        ClassIdx := Trunc(TargetVal);

        if Abs(TargetVal - ClassIdx) > 0.001 then
          raise Exception.CreateFmt('LossNLL: Target[%d]=%.6f nie jest poprawnym ID klasy.', [i, TargetVal]);

        if (ClassIdx < 0) or (ClassIdx >= NumClasses) then
          raise Exception.CreateFmt('LossNLL: Indeks klasy %d poza zakresem [0, %d).', [ClassIdx, NumClasses]);

        Loss := Loss - LogSoftOut.Data[i * NumClasses + ClassIdx];
        Grad.Data[i * NumClasses + ClassIdx] := -Scale;
      end;
    end;

    Loss := Loss * Scale;

    if IsNaN(Loss) or IsInfinite(Loss) then
      raise Exception.Create('LossNLL: Loss = NaN/Inf.');

  except
    if Grad <> nil then FreeAndNil(Grad);
    raise;
  end;
end;

// CrossEntropyLoss

procedure LossCrossEntropy(
  Logits: TAvoTensor;
  Target: TAvoTensor;
  out Loss: Single;
  out Grad: TAvoTensor
);
var
  i, j, M, NumClasses, ClassIdx: Integer;
  MaxLogit, SumExp, ExpVal, Scale, TargetVal: Single;
  Offset: Integer;
  ThreadData: TLossThreadData;
begin
  Loss := 0.0;
  Grad := nil;

  if Logits = nil then raise Exception.Create('LossCrossEntropy: Tensor Logits = nil.');
  if Target = nil then raise Exception.Create('LossCrossEntropy: Tensor Target = nil.');

  if Logits.NumEl <> Length(Logits.Data) then
    raise Exception.Create('LossCrossEntropy: Korupcja tensora Logits (NumEl mismatch).');

  if Target.NumEl <> Length(Target.Data) then
    raise Exception.Create('LossCrossEntropy: Korupcja tensora Target (NumEl mismatch).');

  if Length(Logits.Shape) <> 2 then
    raise Exception.CreateFmt('LossCrossEntropy: Logits musi byc 2D [M, NumClasses], otrzymano %dD.', [Length(Logits.Shape)]);

  if Length(Target.Shape) <> 1 then
    raise Exception.CreateFmt('LossCrossEntropy: Target musi byc 1D [M], otrzymano %dD.', [Length(Target.Shape)]);

  M := Logits.Shape[0];
  NumClasses := Logits.Shape[1];

  if M <= 0 then raise Exception.Create('LossCrossEntropy: Batch Size / SeqLen musi byc > 0.');
  if NumClasses <= 0 then raise Exception.Create('LossCrossEntropy: NumClasses musi byc > 0.');

  if Logits.NumEl <> M * NumClasses then
    raise Exception.Create('LossCrossEntropy: Logits ma niespojny Shape/Data.');

  if Target.Shape[0] <> M then
    raise Exception.CreateFmt('LossCrossEntropy: Niezgodny batch — Logits.M=%d, Target.M=%d.', [M, Target.Shape[0]]);

  Scale := 1.0 / M;
  Grad := TAvoTensor.Create(Logits.Shape);

  try
    // Akceleracja Multi-Core (Hybryda)
    if (M >= 8) and ((Int64(M) * NumClasses) > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
    begin
      ThreadData.Logits := Logits;
      ThreadData.Target := Target;
      ThreadData.Grad := Grad;
      ThreadData.NumClasses := NumClasses;
      ThreadData.Scale := Scale;
      SetLength(ThreadData.RowLosses, M);
      SetLength(ThreadData.RowStatus, M);

      for i := 0 to M - 1 do ThreadData.RowStatus[i] := 0; // Inicjalizacja statusów

      ProcThreadPool.DoParallel(@ParallelCrossEntropyRow, 0, M - 1, @ThreadData, ProcThreadPool.MaxThreadCount);

      // Reduce z asynchronicznymi Guardami
      for i := 0 to M - 1 do
      begin
        if ThreadData.RowStatus[i] = 1 then
          raise Exception.CreateFmt('LossCrossEntropy: Blad targetu w wierszu %d.', [i])
        else if ThreadData.RowStatus[i] = 2 then
          raise Exception.CreateFmt('LossCrossEntropy: Blad numeryczny SumExp (NaN/Inf) w wierszu %d.', [i]);

        Loss := Loss + ThreadData.RowLosses[i];
      end;
    end
    else
    begin
      // Pojedynczy wątek dla małych partii danych
      for i := 0 to M - 1 do
      begin
        TargetVal := Target.Data[i];
        if IsNaN(TargetVal) or IsInfinite(TargetVal) then
          raise Exception.CreateFmt('LossCrossEntropy: Target[%d] = NaN/Inf.', [i]);

        ClassIdx := Trunc(TargetVal);

        if Abs(TargetVal - ClassIdx) > 0.001 then
          raise Exception.CreateFmt('LossCrossEntropy: Target[%d]=%.6f nie jest poprawnym ID klasy.', [i, TargetVal]);

        if (ClassIdx < 0) or (ClassIdx >= NumClasses) then
          raise Exception.CreateFmt('LossCrossEntropy: Indeks klasy %d poza zakresem [0, %d).', [ClassIdx, NumClasses]);

        Offset := i * NumClasses;

        MaxLogit := Logits.Data[Offset];
        for j := 1 to NumClasses - 1 do
          if Logits.Data[Offset + j] > MaxLogit then
            MaxLogit := Logits.Data[Offset + j];

        SumExp := 0.0;
        for j := 0 to NumClasses - 1 do
        begin
          ExpVal := Exp(Logits.Data[Offset + j] - MaxLogit);
          Grad.Data[Offset + j] := ExpVal;
          SumExp := SumExp + ExpVal;
        end;

        if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
          raise Exception.Create('LossCrossEntropy: SumExp uszkodzone (NaN/Inf/zero).');

        Loss := Loss + (Ln(SumExp) + MaxLogit - Logits.Data[Offset + ClassIdx]);

        for j := 0 to NumClasses - 1 do
          Grad.Data[Offset + j] := (Grad.Data[Offset + j] / SumExp) * Scale;

        Grad.Data[Offset + ClassIdx] := Grad.Data[Offset + ClassIdx] - Scale;
      end;
    end;

    Loss := Loss * Scale;

    if IsNaN(Loss) or IsInfinite(Loss) then
      raise Exception.Create('LossCrossEntropy: Loss = NaN/Inf.');

  except
    if Grad <> nil then FreeAndNil(Grad);
    raise;
  end;
end;

end.


{$mode objfpc}{$H+}
unit avotensor.ops;
// avotensor.ops — operacje na tensorach: Transpose, Reshape, Softmax, LogSoftmax
interface

uses
  SysUtils,
  avotensor.core;

function Transpose(A: TAvoTensor): TAvoTensor;
function Reshape(A: TAvoTensor; NewShape: TShapeArray): TAvoTensor;
function Softmax(A: TAvoTensor): TAvoTensor;
function LogSoftmax(A: TAvoTensor): TAvoTensor;
function SoftmaxBackward(SoftOut, DOut: TAvoTensor): TAvoTensor;

implementation

uses
  Math,    // Wymagane dla IsNaN i IsInfinite
  MTProcs; // Podpinamy obsługę wątków po stronie implementacji

// struktury i workery dla wątków (o(m * n) multi-core)

type
  TOpsThreadData = record
    A, Res, DOut: TAvoTensor;
    N: Integer;
    RowStatus: array of Byte; // 0 = OK, 2 = błąd numeryczny (NaN/Inf)
  end;
  POpsThreadData = ^TOpsThreadData;

procedure ParallelSoftmaxRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: POpsThreadData;
  j, RowOffset: Integer;
  MaxVal, SumExp, E: Single;
begin
  PD := POpsThreadData(Data);
  RowOffset := Index * PD^.N;

  MaxVal := PD^.A.Data[RowOffset];
  for j := 1 to PD^.N - 1 do
    if PD^.A.Data[RowOffset + j] > MaxVal then MaxVal := PD^.A.Data[RowOffset + j];

  SumExp := 0.0;
  for j := 0 to PD^.N - 1 do
  begin
    E := Exp(PD^.A.Data[RowOffset + j] - MaxVal);
    PD^.Res.Data[RowOffset + j] := E;
    SumExp := SumExp + E;
  end;

  if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
  begin
    PD^.RowStatus[Index] := 2; // Raportujemy błąd do wątku głównego
    for j := 0 to PD^.N - 1 do PD^.Res.Data[RowOffset + j] := 0.0;
    Exit;
  end;

  for j := 0 to PD^.N - 1 do
    PD^.Res.Data[RowOffset + j] := PD^.Res.Data[RowOffset + j] / SumExp;
end;

procedure ParallelLogSoftmaxRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: POpsThreadData;
  j, RowOffset: Integer;
  MaxVal, SumExp, LogSumExp: Single;
begin
  PD := POpsThreadData(Data);
  RowOffset := Index * PD^.N;

  MaxVal := PD^.A.Data[RowOffset];
  for j := 1 to PD^.N - 1 do
    if PD^.A.Data[RowOffset + j] > MaxVal then MaxVal := PD^.A.Data[RowOffset + j];

  SumExp := 0.0;
  for j := 0 to PD^.N - 1 do
    SumExp := SumExp + Exp(PD^.A.Data[RowOffset + j] - MaxVal);

  if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
  begin
    PD^.RowStatus[Index] := 2;
    for j := 0 to PD^.N - 1 do PD^.Res.Data[RowOffset + j] := 0.0;
    Exit;
  end;

  LogSumExp := MaxVal + Ln(SumExp);

  for j := 0 to PD^.N - 1 do
    PD^.Res.Data[RowOffset + j] := PD^.A.Data[RowOffset + j] - LogSumExp;
end;

procedure ParallelSoftmaxBackwardRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: POpsThreadData;
  j, RowOffset: Integer;
  DotProd: Single;
begin
  PD := POpsThreadData(Data);
  RowOffset := Index * PD^.N;

  DotProd := 0.0;
  for j := 0 to PD^.N - 1 do
    DotProd := DotProd + PD^.DOut.Data[RowOffset + j] * PD^.A.Data[RowOffset + j]; // A to SoftOut

  if IsNaN(DotProd) or IsInfinite(DotProd) then
  begin
    PD^.RowStatus[Index] := 2; // Raportujemy błąd do wątku głównego
    for j := 0 to PD^.N - 1 do PD^.Res.Data[RowOffset + j] := 0.0;
    Exit;
  end;

  for j := 0 to PD^.N - 1 do
    PD^.Res.Data[RowOffset + j] := PD^.A.Data[RowOffset + j] * (PD^.DOut.Data[RowOffset + j] - DotProd);
end;


// główne operacje


function Transpose(A: TAvoTensor): TAvoTensor;
var
  i, j, M, N: Integer;
begin
  if A = nil then raise Exception.Create('Transpose: Tensor A = nil.');
  if A.NumEl <> Length(A.Data) then raise Exception.Create('Transpose: Korupcja tensora A.');
  if Length(A.Shape) <> 2 then raise Exception.CreateFmt('Transpose: Tensor musi byc 2D, otrzymano %dD.', [Length(A.Shape)]);

  M := A.Shape[0];
  N := A.Shape[1];

  if (M <= 0) or (N <= 0) then raise Exception.Create('Transpose: Wymiary musza byc > 0.');
  if A.NumEl <> M * N then raise Exception.Create('Transpose: Tensor ma niespojny Shape/Data.');

  Result := TAvoTensor.Create([N, M]);
  SetLength(Result.Dzieci, 1);
  Result.Dzieci[0] := A;

  for i := 0 to M - 1 do
    for j := 0 to N - 1 do
      Result.Data[j * M + i] := A.Data[i * N + j];
end;

function Reshape(A: TAvoTensor; NewShape: TShapeArray): TAvoTensor;
var
  i, OldSize, NewSize: Integer;
begin
  if A = nil then raise Exception.Create('Reshape: Tensor A = nil.');
  if A.NumEl <> Length(A.Data) then raise Exception.Create('Reshape: Korupcja tensora A.');

  if Length(NewShape) = 0 then raise Exception.Create('Reshape: NewShape nie moze byc pusty.');

  OldSize := A.NumEl;
  NewSize := 1;
  for i := 0 to High(NewShape) do
  begin
    if NewShape[i] <= 0 then raise Exception.Create('Reshape: Nowy wymiar musi byc > 0.');
    if NewSize > High(Integer) div NewShape[i] then raise Exception.Create('Reshape: Overflow w nowym ksztalcie.');
    NewSize := NewSize * NewShape[i];
  end;

  if OldSize <> NewSize then raise Exception.CreateFmt('Reshape: niezgodna liczba elementow (%d vs %d).', [OldSize, NewSize]);

  Result := TAvoTensor.Create(NewShape);
  SetLength(Result.Dzieci, 1);
  Result.Dzieci[0] := A;

  for i := 0 to OldSize - 1 do Result.Data[i] := A.Data[i];
end;

function Softmax(A: TAvoTensor): TAvoTensor;
var
  i, j, M, N: Integer;
  MaxVal, SumExp, E: Single;
  OpData: TOpsThreadData;
begin
  Result := nil;
  if A = nil then raise Exception.Create('Softmax: Tensor A = nil.');
  if A.NumEl <> Length(A.Data) then raise Exception.Create('Softmax: Korupcja tensora A.');
  if (Length(A.Shape) <> 1) and (Length(A.Shape) <> 2) then raise Exception.Create('Softmax: Wymagane 1D lub 2D.');

  Result := TAvoTensor.Create(A.Shape);
  try
    SetLength(Result.Dzieci, 1);
    Result.Dzieci[0] := A;

    if Length(A.Shape) = 1 then
    begin
      N := A.Shape[0];
      if N <= 0 then raise Exception.Create('Softmax: Wymiar musi byc > 0.');

      MaxVal := A.Data[0];
      for i := 1 to N - 1 do if A.Data[i] > MaxVal then MaxVal := A.Data[i];

      SumExp := 0.0;
      for i := 0 to N - 1 do
      begin
        E := Exp(A.Data[i] - MaxVal);
        Result.Data[i] := E;
        SumExp := SumExp + E;
      end;

      if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
        raise Exception.Create('Softmax: SumExp uszkodzone (NaN/Inf/zero).');

      for i := 0 to N - 1 do Result.Data[i] := Result.Data[i] / SumExp;
    end
    else
    begin
      M := A.Shape[0];
      N := A.Shape[1];

      if (M <= 0) or (N <= 0) then raise Exception.Create('Softmax: Wymiary M i N musza byc > 0.');
      if A.NumEl <> M * N then raise Exception.Create('Softmax: Tensor ma niespojny Shape/Data.');

      // Akceleracja wielordzeniowa (Hybryda)
      if (M >= 8) and ((Int64(M) * N) > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
      begin
        OpData.A := A; OpData.Res := Result; OpData.N := N;
        SetLength(OpData.RowStatus, M);
        for i := 0 to M - 1 do OpData.RowStatus[i] := 0;

        ProcThreadPool.DoParallel(@ParallelSoftmaxRow, 0, M - 1, @OpData, ProcThreadPool.MaxThreadCount);

        for i := 0 to M - 1 do
          if OpData.RowStatus[i] = 2 then
            raise Exception.CreateFmt('Softmax: Blad numeryczny SumExp (NaN/Inf) w wierszu %d.', [i]);
      end
      else
      begin
        for i := 0 to M - 1 do
        begin
          MaxVal := A.Data[i * N];
          for j := 1 to N - 1 do if A.Data[i * N + j] > MaxVal then MaxVal := A.Data[i * N + j];

          SumExp := 0.0;
          for j := 0 to N - 1 do
          begin
            E := Exp(A.Data[i * N + j] - MaxVal);
            Result.Data[i * N + j] := E;
            SumExp := SumExp + E;
          end;

          if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
            raise Exception.CreateFmt('Softmax: SumExp uszkodzone (NaN/Inf/zero) w wierszu %d.', [i]);

          for j := 0 to N - 1 do Result.Data[i * N + j] := Result.Data[i * N + j] / SumExp;
        end;
      end;
    end;
  except
    if Result <> nil then FreeAndNil(Result);
    raise;
  end;
end;

function LogSoftmax(A: TAvoTensor): TAvoTensor;
var
  i, j, M, N: Integer;
  MaxVal, LogSumExp, SumExp: Single;
  OpData: TOpsThreadData;
begin
  Result := nil;
  if A = nil then raise Exception.Create('LogSoftmax: Tensor A = nil.');
  if A.NumEl <> Length(A.Data) then raise Exception.Create('LogSoftmax: Korupcja tensora A.');
  if (Length(A.Shape) <> 1) and (Length(A.Shape) <> 2) then raise Exception.Create('LogSoftmax: Wymagane 1D lub 2D.');

  Result := TAvoTensor.Create(A.Shape);
  try
    SetLength(Result.Dzieci, 1);
    Result.Dzieci[0] := A;

    if Length(A.Shape) = 1 then
    begin
      N := A.Shape[0];
      if N <= 0 then raise Exception.Create('LogSoftmax: Wymiar musi byc > 0.');

      MaxVal := A.Data[0];
      for i := 1 to N - 1 do if A.Data[i] > MaxVal then MaxVal := A.Data[i];

      SumExp := 0.0;
      for i := 0 to N - 1 do SumExp := SumExp + Exp(A.Data[i] - MaxVal);

      if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
        raise Exception.Create('LogSoftmax: SumExp uszkodzone (NaN/Inf/zero).');

      LogSumExp := MaxVal + Ln(SumExp);
      for i := 0 to N - 1 do Result.Data[i] := A.Data[i] - LogSumExp;
    end
    else
    begin
      M := A.Shape[0];
      N := A.Shape[1];

      if (M <= 0) or (N <= 0) then raise Exception.Create('LogSoftmax: Wymiary M i N musza byc > 0.');
      if A.NumEl <> M * N then raise Exception.Create('LogSoftmax: Tensor ma niespojny Shape/Data.');

      // Akceleracja wielordzeniowa
      if (M >= 8) and ((Int64(M) * N) > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
      begin
        OpData.A := A; OpData.Res := Result; OpData.N := N;
        SetLength(OpData.RowStatus, M);
        for i := 0 to M - 1 do OpData.RowStatus[i] := 0;

        ProcThreadPool.DoParallel(@ParallelLogSoftmaxRow, 0, M - 1, @OpData, ProcThreadPool.MaxThreadCount);

        for i := 0 to M - 1 do
          if OpData.RowStatus[i] = 2 then
            raise Exception.CreateFmt('LogSoftmax: Blad numeryczny SumExp (NaN/Inf) w wierszu %d.', [i]);
      end
      else
      begin
        for i := 0 to M - 1 do
        begin
          MaxVal := A.Data[i * N];
          for j := 1 to N - 1 do if A.Data[i * N + j] > MaxVal then MaxVal := A.Data[i * N + j];

          SumExp := 0.0;
          for j := 0 to N - 1 do SumExp := SumExp + Exp(A.Data[i * N + j] - MaxVal);

          if (SumExp <= 0.0) or IsNaN(SumExp) or IsInfinite(SumExp) then
            raise Exception.CreateFmt('LogSoftmax: SumExp uszkodzone (NaN/Inf/zero) w wierszu %d.', [i]);

          LogSumExp := MaxVal + Ln(SumExp);
          for j := 0 to N - 1 do Result.Data[i * N + j] := A.Data[i * N + j] - LogSumExp;
        end;
      end;
    end;
  except
    if Result <> nil then FreeAndNil(Result);
    raise;
  end;
end;

function SoftmaxBackward(SoftOut, DOut: TAvoTensor): TAvoTensor;
var
  i, j, M, N: Integer;
  DotProd: Single;
  OpData: TOpsThreadData;
begin
  Result := nil;
  if SoftOut = nil then raise Exception.Create('SoftmaxBackward: Tensor SoftOut = nil.');
  if DOut = nil then raise Exception.Create('SoftmaxBackward: Tensor DOut = nil.');
  if not SameShape(SoftOut, DOut) then raise Exception.Create('SoftmaxBackward: Niezgodne ksztalty.');

  if (Length(SoftOut.Shape) <> 1) and (Length(SoftOut.Shape) <> 2) then
    raise Exception.Create('SoftmaxBackward: Wymagane 1D lub 2D.');

  if SoftOut.NumEl <> Length(SoftOut.Data) then
    raise Exception.Create('SoftmaxBackward: Korupcja tensora SoftOut.');

  if DOut.NumEl <> Length(DOut.Data) then
    raise Exception.Create('SoftmaxBackward: Korupcja tensora DOut.');

  Result := TAvoTensor.Create(SoftOut.Shape);
  try
    if Length(SoftOut.Shape) = 1 then
    begin
      N := SoftOut.Shape[0];
      if N <= 0 then raise Exception.Create('SoftmaxBackward: Wymiar musi byc > 0.');

      DotProd := 0.0;
      for i := 0 to N - 1 do DotProd := DotProd + DOut.Data[i] * SoftOut.Data[i];

      if IsNaN(DotProd) or IsInfinite(DotProd) then
        raise Exception.Create('SoftmaxBackward: DotProd = NaN/Inf.');

      for i := 0 to N - 1 do Result.Data[i] := SoftOut.Data[i] * (DOut.Data[i] - DotProd);
    end
    else
    begin
      M := SoftOut.Shape[0];
      N := SoftOut.Shape[1];

      if (M <= 0) or (N <= 0) then raise Exception.Create('SoftmaxBackward: Wymiary musza byc > 0.');
      if SoftOut.NumEl <> M * N then raise Exception.Create('SoftmaxBackward: SoftOut ma niespojny Shape/Data.');
      if DOut.NumEl <> M * N then raise Exception.Create('SoftmaxBackward: DOut ma niespojny Shape/Data.');

      // Akceleracja wielordzeniowa
      if (M >= 8) and ((Int64(M) * N) > 50000) and (ProcThreadPool <> nil) and (ProcThreadPool.MaxThreadCount > 1) then
      begin
        OpData.A := SoftOut; OpData.DOut := DOut; OpData.Res := Result; OpData.N := N;
        SetLength(OpData.RowStatus, M);
        for i := 0 to M - 1 do OpData.RowStatus[i] := 0;

        ProcThreadPool.DoParallel(@ParallelSoftmaxBackwardRow, 0, M - 1, @OpData, ProcThreadPool.MaxThreadCount);

        for i := 0 to M - 1 do
          if OpData.RowStatus[i] = 2 then
            raise Exception.CreateFmt('SoftmaxBackward: DotProd = NaN/Inf w wierszu %d.', [i]);
      end
      else
      begin
        for i := 0 to M - 1 do
        begin
          DotProd := 0.0;
          for j := 0 to N - 1 do DotProd := DotProd + DOut.Data[i * N + j] * SoftOut.Data[i * N + j];

          if IsNaN(DotProd) or IsInfinite(DotProd) then
            raise Exception.CreateFmt('SoftmaxBackward: DotProd = NaN/Inf w wierszu %d.', [i]);

          for j := 0 to N - 1 do Result.Data[i * N + j] := SoftOut.Data[i * N + j] * (DOut.Data[i * N + j] - DotProd);
        end;
      end;
    end;
  except
    if Result <> nil then FreeAndNil(Result);
    raise;
  end;
end;

end.


{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.core;

interface

uses
  SysUtils, Classes, MTProcs;

const
  // Próg dla CPU multi-thread. 300k ogranicza narzut wątków przy małych macierzach.
  DOT_PARALLEL_THRESHOLD = 300000;
  ADD_PARALLEL_THRESHOLD = 50000;

  // GPU/OpenCL opłaca się dopiero dla dużych mnożeń, bo transfer RAM <-> VRAM kosztuje.
  GPU_DOT_THRESHOLD = 50000000;

type
  TShapeArray  = array of Integer;
  TSingleArray = array of Single;

  TAvoTensor = class;
  TAvoTensorArray = array of TAvoTensor;

  TAvoTensor = class
  public
    Data:   TSingleArray;
    Grad:   TSingleArray;
    Shape:  TShapeArray;
    Dzieci: TAvoTensorArray;

    constructor Create(AShape: TShapeArray);
    destructor  Destroy; override;
    function    NumEl: Integer;
  end;

  TAvoDotProductFunc = function(A, B: TAvoTensor): TAvoTensor;

  TDotProductData = record
    A, B, Res: TAvoTensor;
    P, N: Integer;
  end;
  PDotProductData = ^TDotProductData;

  TAddVectorsData = record
    A, B, Res: TAvoTensor;
    N: Integer;
    BlockSize: Integer;
    TotalEl: Integer;
  end;
  PAddVectorsData = ^TAddVectorsData;

// Wskaźnik podpinany przez avotensor.gpu po InitAvoGPU.
var
  AvoGPUDotProductFallback: TAvoDotProductFunc = nil;

function DotProduct(A, B: TAvoTensor): TAvoTensor;
function AddVectors(A, B: TAvoTensor): TAvoTensor;
function SameShape(A, B: TAvoTensor): Boolean;
procedure SetAvoTensorThreadCount(AThreadCount: PtrInt);
function GetAvoTensorThreadCount: PtrInt;

implementation

function MakeShape1D(A0: Integer): TShapeArray;
begin
  SetLength(Result, 1);
  Result[0] := A0;
end;

function MakeShape2D(A0, A1: Integer): TShapeArray;
begin
  SetLength(Result, 2);
  Result[0] := A0;
  Result[1] := A1;
end;

function CalcShapeNumEl(const AShape: TShapeArray; const Context: string): Integer;
var
  i: Integer;
  Prod: Int64;
begin
  if Length(AShape) = 0 then
    raise Exception.Create(Context + ': Shape nie moze byc pusty.');

  Prod := 1;
  for i := 0 to High(AShape) do
  begin
    if AShape[i] <= 0 then
      raise Exception.CreateFmt('%s: Nieprawidlowy wymiar Shape[%d]=%d.', [Context, i, AShape[i]]);

    Prod := Prod * AShape[i];
    if Prod > High(Integer) then
      raise Exception.Create(Context + ': Liczba elementow tensora przekracza zakres Integer.');
  end;

  Result := Integer(Prod);
end;

procedure ValidateTensorData(T: TAvoTensor; const Context: string);
var
  Expected: Integer;
begin
  if T = nil then
    raise Exception.Create(Context + ': Tensor = nil.');

  Expected := CalcShapeNumEl(T.Shape, Context);

  if Length(T.Data) <> Expected then
    raise Exception.CreateFmt('%s: Data ma %d elementow, oczekiwano %d.', [Context, Length(T.Data), Expected]);

  if Length(T.Grad) <> Expected then
    raise Exception.CreateFmt('%s: Grad ma %d elementow, oczekiwano %d.', [Context, Length(T.Grad), Expected]);
end;

procedure SetAvoTensorThreadCount(AThreadCount: PtrInt);
begin
  if ProcThreadPool = nil then
    raise Exception.Create('SetAvoTensorThreadCount: ProcThreadPool = nil.');

  if AThreadCount < 1 then
    AThreadCount := 1;

  ProcThreadPool.MaxThreadCount := AThreadCount;
end;

function GetAvoTensorThreadCount: PtrInt;
begin
  if ProcThreadPool = nil then
    Result := 1
  else
    Result := ProcThreadPool.MaxThreadCount;
end;

function SameShape(A, B: TAvoTensor): Boolean;
var
  i: Integer;
begin
  Result := False;

  if (A = nil) or (B = nil) then Exit;
  if Length(A.Shape) <> Length(B.Shape) then Exit;

  for i := 0 to High(A.Shape) do
    if A.Shape[i] <> B.Shape[i] then Exit;

  Result := True;
end;

// =============================================================================
// Workery MTProcs
// =============================================================================

procedure ParallelDotRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PDotProductData;
  j, k: Integer;
  Aik: Single;
  RowOffsetA, RowOffsetRes: Integer;
begin
  PD := PDotProductData(Data);

  RowOffsetA := Index * PD^.P;
  RowOffsetRes := Index * PD^.N;

  // Każdy worker zeruje i zapisuje wyłącznie swój wiersz wyniku.
  for j := 0 to PD^.N - 1 do
    PD^.Res.Data[RowOffsetRes + j] := 0.0;

  // Cache-friendly: B[k*N + j] jest czytane liniowo po j.
  for k := 0 to PD^.P - 1 do
  begin
    Aik := PD^.A.Data[RowOffsetA + k];
    if Aik <> 0.0 then
      for j := 0 to PD^.N - 1 do
        PD^.Res.Data[RowOffsetRes + j] :=
          PD^.Res.Data[RowOffsetRes + j] + Aik * PD^.B.Data[k * PD^.N + j];
  end;
end;

procedure ParallelAddFlat(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PAddVectorsData;
  i, StartIdx, EndIdx: Integer;
begin
  PD := PAddVectorsData(Data);

  StartIdx := Index * PD^.BlockSize;
  EndIdx := StartIdx + PD^.BlockSize - 1;

  if StartIdx >= PD^.TotalEl then Exit;
  if EndIdx >= PD^.TotalEl then EndIdx := PD^.TotalEl - 1;
  if StartIdx > EndIdx then Exit;

  for i := StartIdx to EndIdx do
    PD^.Res.Data[i] := PD^.A.Data[i] + PD^.B.Data[i];
end;

procedure ParallelAddBroadcast(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PAddVectorsData;
  j, RowOffset: Integer;
begin
  PD := PAddVectorsData(Data);
  RowOffset := Index * PD^.N;

  for j := 0 to PD^.N - 1 do
    PD^.Res.Data[RowOffset + j] := PD^.A.Data[RowOffset + j] + PD^.B.Data[j];
end;

// =============================================================================
// Tensor
// =============================================================================

constructor TAvoTensor.Create(AShape: TShapeArray);
var
  i, Count: Integer;
begin
  inherited Create;

  Count := CalcShapeNumEl(AShape, 'TAvoTensor.Create');

  SetLength(Shape, Length(AShape));
  for i := 0 to High(AShape) do
    Shape[i] := AShape[i];

  SetLength(Data, Count);
  SetLength(Grad, Count);
  SetLength(Dzieci, 0);

  if Count > 0 then
  begin
    FillChar(Data[0], Count * SizeOf(Single), 0);
    FillChar(Grad[0], Count * SizeOf(Single), 0);
  end;
end;

destructor TAvoTensor.Destroy;
begin
  SetLength(Data, 0);
  SetLength(Grad, 0);
  SetLength(Shape, 0);
  SetLength(Dzieci, 0);
  inherited Destroy;
end;

function TAvoTensor.NumEl: Integer;
begin
  Result := CalcShapeNumEl(Shape, 'TAvoTensor.NumEl');
end;

// =============================================================================
// Operacje główne
// =============================================================================

function DotProduct(A, B: TAvoTensor): TAvoTensor;
var
  i, j, k: Integer;
  M, P, N: Integer;
  Ops: Int64;
  DPData: TDotProductData;
  Aik: Single;
  UseParallel: Boolean;
  GPUResult: TAvoTensor;
begin
  Result := nil;

  ValidateTensorData(A, 'DotProduct(A)');
  ValidateTensorData(B, 'DotProduct(B)');

  if (Length(A.Shape) <> 1) and (Length(A.Shape) <> 2) then
    raise Exception.CreateFmt('DotProduct: Tensor A musi byc 1D albo 2D, otrzymano %dD.', [Length(A.Shape)]);

  if (Length(B.Shape) <> 1) and (Length(B.Shape) <> 2) then
    raise Exception.CreateFmt('DotProduct: Tensor B musi byc 1D albo 2D, otrzymano %dD.', [Length(B.Shape)]);

  if Length(A.Shape) = 1 then
  begin
    M := 1;
    P := A.Shape[0];
  end
  else
  begin
    M := A.Shape[0];
    P := A.Shape[1];
  end;

  if B.Shape[0] <> P then
    raise Exception.CreateFmt('DotProduct: Shape mismatch. A.P=%d, B.Shape[0]=%d.', [P, B.Shape[0]]);

  if Length(B.Shape) = 1 then
    N := 1
  else
    N := B.Shape[1];

  Ops := Int64(M) * Int64(P) * Int64(N);

  // Opcjonalny backend GPU. Jeśli GPU rzuci wyjątek, spadamy bezpiecznie na CPU.
  if Assigned(AvoGPUDotProductFallback) and (Ops > GPU_DOT_THRESHOLD) then
  begin
    GPUResult := nil;
    try
       //WriteLn('[CORE] DotProduct: probuje GPU/OpenCL...');  log
      GPUResult := AvoGPUDotProductFallback(A, B);
      if GPUResult <> nil then
        Exit(GPUResult);
    except
      on E: Exception do
      begin
        if GPUResult <> nil then GPUResult.Free;
        // Fallback CPU bez przerywania treningu. Do debugowania można tu dodać Writeln.
        //log dla debuga
        //WriteLn('[CORE] DotProduct: GPU nieudane, fallback CPU: ', E.Message);
      end;
    end;
  end;

  if Length(A.Shape) = 1 then
    Result := TAvoTensor.Create(MakeShape1D(N))
  else
    Result := TAvoTensor.Create(MakeShape2D(M, N));

  try
    SetLength(Result.Dzieci, 2);
    Result.Dzieci[0] := A;
    Result.Dzieci[1] := B;

    UseParallel :=
      (M >= 8) and
      (Ops > DOT_PARALLEL_THRESHOLD) and
      (ProcThreadPool <> nil) and
      (ProcThreadPool.MaxThreadCount > 1);

    if UseParallel then
    begin
      DPData.A := A;
      DPData.B := B;
      DPData.Res := Result;
      DPData.P := P;
      DPData.N := N;

      ProcThreadPool.DoParallel(@ParallelDotRow, 0, M - 1, @DPData, ProcThreadPool.MaxThreadCount);
    end
    else
    begin
      for i := 0 to M - 1 do
        for k := 0 to P - 1 do
        begin
          Aik := A.Data[i * P + k];
          if Aik <> 0.0 then
            for j := 0 to N - 1 do
              Result.Data[i * N + j] :=
                Result.Data[i * N + j] + Aik * B.Data[k * N + j];
        end;
    end;
  except
    if Result <> nil then
    begin
      Result.Free;
      Result := nil;
    end;
    raise;
  end;
end;

function AddVectors(A, B: TAvoTensor): TAvoTensor;
var
  i, j: Integer;
  N, Rows: Integer;
  ThreadCount, BlocksCount: Integer;
  AddData: TAddVectorsData;
  UseParallel: Boolean;
begin
  Result := nil;

  ValidateTensorData(A, 'AddVectors(A)');
  ValidateTensorData(B, 'AddVectors(B)');

  if SameShape(A, B) then
  begin
    Result := TAvoTensor.Create(A.Shape);
    try
      SetLength(Result.Dzieci, 2);
      Result.Dzieci[0] := A;
      Result.Dzieci[1] := B;

      UseParallel :=
        (A.NumEl > ADD_PARALLEL_THRESHOLD) and
        (ProcThreadPool <> nil) and
        (ProcThreadPool.MaxThreadCount > 1);

      if UseParallel then
      begin
        ThreadCount := ProcThreadPool.MaxThreadCount;
        if ThreadCount < 1 then ThreadCount := 1;
        if ThreadCount > A.NumEl then ThreadCount := A.NumEl;

        AddData.A := A;
        AddData.B := B;
        AddData.Res := Result;
        AddData.N := 0;
        AddData.TotalEl := A.NumEl;
        AddData.BlockSize := (A.NumEl + ThreadCount - 1) div ThreadCount;

        BlocksCount := (A.NumEl + AddData.BlockSize - 1) div AddData.BlockSize;
        ProcThreadPool.DoParallel(@ParallelAddFlat, 0, BlocksCount - 1, @AddData, ProcThreadPool.MaxThreadCount);
      end
      else
      begin
        for i := 0 to A.NumEl - 1 do
          Result.Data[i] := A.Data[i] + B.Data[i];
      end;
    except
      if Result <> nil then
      begin
        Result.Free;
        Result := nil;
      end;
      raise;
    end;
    Exit;
  end;

  // Broadcasting biasu/wektora po ostatnim wymiarze: A[..., N] + B[N]
  if (Length(B.Shape) = 1) and (Length(A.Shape) >= 1) and
     (A.Shape[High(A.Shape)] = B.Shape[0]) then
  begin
    N := B.Shape[0];

    if N <= 0 then
      raise Exception.Create('AddVectors: Broadcast N musi byc > 0.');

    if (A.NumEl mod N) <> 0 then
      raise Exception.Create('AddVectors: A.NumEl nie dzieli sie przez rozmiar broadcastu.');

    Rows := A.NumEl div N;
    if Rows <= 0 then
      raise Exception.Create('AddVectors: Liczba wierszy broadcastu musi byc > 0.');

    Result := TAvoTensor.Create(A.Shape);
    try
      SetLength(Result.Dzieci, 2);
      Result.Dzieci[0] := A;
      Result.Dzieci[1] := B;

      UseParallel :=
        (A.NumEl > ADD_PARALLEL_THRESHOLD) and
        (Rows >= 2) and
        (ProcThreadPool <> nil) and
        (ProcThreadPool.MaxThreadCount > 1);

      if UseParallel then
      begin
        AddData.A := A;
        AddData.B := B;
        AddData.Res := Result;
        AddData.N := N;
        AddData.BlockSize := 0;
        AddData.TotalEl := A.NumEl;

        ProcThreadPool.DoParallel(@ParallelAddBroadcast, 0, Rows - 1, @AddData, ProcThreadPool.MaxThreadCount);
      end
      else
      begin
        for i := 0 to Rows - 1 do
          for j := 0 to N - 1 do
            Result.Data[i * N + j] := A.Data[i * N + j] + B.Data[j];
      end;
    except
      if Result <> nil then
      begin
        Result.Free;
        Result := nil;
      end;
      raise;
    end;
    Exit;
  end;

  raise Exception.Create('AddVectors: Shape mismatch. Dozwolone: identyczny Shape albo broadcast A[...,N] + B[N].');
end;

end.


{{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.core;

interface

uses
  SysUtils, Classes, MTProcs;

const
  DOT_PARALLEL_THRESHOLD = 10000;
  ADD_PARALLEL_THRESHOLD = 50000;

type
  TShapeArray  = array of Integer;
  TSingleArray = array of Single;

  TAvoTensor = class;
  TAvoTensorArray = array of TAvoTensor;

  TAvoTensor = class
  public
    Data:   TSingleArray;
    Grad:   TSingleArray;
    Shape:  TShapeArray;
    Dzieci: TAvoTensorArray;

    constructor Create(AShape: TShapeArray);
    destructor  Destroy; override;
    function    NumEl: Integer;
  end;

// Struktury dla wątków
type
  TDotProductData = record
    A, B, Res: TAvoTensor;
    P, N: Integer;
  end;
  PDotProductData = ^TDotProductData;

  TAddVectorsData = record
    A, B, Res: TAvoTensor;
    N: Integer;
    BlockSize: Integer;
    TotalEl: Integer;
  end;
  PAddVectorsData = ^TAddVectorsData;

// Wskaźnik na funkcję akceleracji GPU
var
  AvoGPUDotProductFallback: function(A, B: TAvoTensor): TAvoTensor = nil;

function DotProduct(A, B: TAvoTensor): TAvoTensor;
function AddVectors(A, B: TAvoTensor): TAvoTensor;
function SameShape(A, B: TAvoTensor): Boolean;
procedure SetAvoTensorThreadCount(AThreadCount: PtrInt);

implementation

procedure SetAvoTensorThreadCount(AThreadCount: PtrInt);
begin
  if ProcThreadPool = nil then
    raise Exception.Create('SetAvoTensorThreadCount: ProcThreadPool = nil.');
  if AThreadCount < 1 then AThreadCount := 1;
  ProcThreadPool.MaxThreadCount := AThreadCount;
end;

function SameShape(A, B: TAvoTensor): Boolean;
var
  i: Integer;
begin
  Result := False;
  if (A = nil) or (B = nil) then Exit;
  if Length(A.Shape) <> Length(B.Shape) then Exit;
  for i := 0 to High(A.Shape) do
    if A.Shape[i] <> B.Shape[i] then Exit;
  Result := True;
end;

// --- WORKERY ---

procedure ParallelDotRow(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PDotProductData;
  j, k: Integer;
  Aik: Single;
  RowOffsetA, RowOffsetRes: Integer;
begin
  PD := PDotProductData(Data);
  RowOffsetA := Index * PD^.P;
  RowOffsetRes := Index * PD^.N;

  for j := 0 to PD^.N - 1 do PD^.Res.Data[RowOffsetRes + j] := 0.0;

  for k := 0 to PD^.P - 1 do
  begin
    Aik := PD^.A.Data[RowOffsetA + k];
    if Aik <> 0.0 then
      for j := 0 to PD^.N - 1 do
        PD^.Res.Data[RowOffsetRes + j] := PD^.Res.Data[RowOffsetRes + j] + Aik * PD^.B.Data[k * PD^.N + j];
  end;
end;

procedure ParallelAddFlat(Index: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
var
  PD: PAddVectorsData;
  i, StartIdx, EndIdx: Integer;
begin
  PD := PAddVectorsData(Data);

  StartIdx := Index * PD^.BlockSize;
  EndIdx := StartIdx + PD^.BlockSize - 1;

  // Zabezpieczenie przed wyjściem poza zakres tablicy
  if StartIdx >= PD^.TotalEl then Exit;
  if EndIdx >= PD^.TotalEl then
    EndIdx := PD^.TotalEl - 1;

  // Pętla wykonująca operację na danym bloku
  for i := StartIdx to EndIdx do
  begin
    PD^.Res.Data[i] := PD^.A.Data[i] + PD^.B.Data[i];
  end;
  {
  PD := PAddVectorsData(Data);
  StartIdx := Index * PD^.BlockSize;
  EndIdx := Min(StartIdx + PD^.BlockSize - 1, PD^.TotalEl - 1);
  for i := StartIdx to EndIdx do
    PD^.Res.Data[i] := PD^.A.Data[i] + PD^.B.Data[i];
  }
end;

// --- GŁÓWNE ---

function DotProduct(A, B: TAvoTensor): TAvoTensor;
var
  i, j, k, M, P, N: Integer;
  DPData: TDotProductData;
  Aik: Single;
begin
  if (A = nil) or (B = nil) then raise Exception.Create('DotProduct: Tensor nil.');
  if Length(A.Shape[Length(A.Shape) - 1]) <> Length(B.Shape[0]) then
     raise Exception.Create('DotProduct: Shape mismatch.');

  if Length(A.Shape) = 1 then begin M := 1; P := A.Shape[0]; end
  else begin M := A.Shape[0]; P := A.Shape[1]; end;
  N := ifthen(Length(B.Shape) = 1, 1, B.Shape[1]);

  if Assigned(AvoGPUDotProductFallback) and ((Int64(M) * P * N) > 50000000) then
    Exit(AvoGPUDotProductFallback(A, B));

  Result := TAvoTensor.Create(ifthen(Length(A.Shape) = 1, [N], [M, N]));

  if (M >= 8) and ((Int64(M) * P * N) > DOT_PARALLEL_THRESHOLD) and (ProcThreadPool.MaxThreadCount > 1) then
  begin
    DPData.A := A; DPData.B := B; DPData.Res := Result; DPData.P := P; DPData.N := N;
    ProcThreadPool.DoParallel(@ParallelDotRow, 0, M - 1, @DPData, ProcThreadPool.MaxThreadCount);
  end
  else
  begin
    for i := 0 to M - 1 do
      for k := 0 to P - 1 do
      begin
        Aik := A.Data[i * P + k];
        if Aik <> 0.0 then
          for j := 0 to N - 1 do
            Result.Data[i * N + j] := Result.Data[i * N + j] + Aik * B.Data[k * N + j];
      end;
  end;
end;

constructor TAvoTensor.Create(AShape: TShapeArray);
begin
  Shape := Copy(AShape, 0, Length(AShape));
  SetLength(Data, NumEl);
  SetLength(Grad, NumEl);
  FillChar(Data[0], Length(Data) * SizeOf(Single), 0);
  FillChar(Grad[0], Length(Grad) * SizeOf(Single), 0);
end;

destructor TAvoTensor.Destroy;
begin
  SetLength(Dzieci, 0);
  inherited Destroy;
end;

function TAvoTensor.NumEl: Integer;
var i: Integer;
begin
  Result := 1;
  for i := 0 to High(Shape) do Result := Result * Shape[i];
end;

end.
}

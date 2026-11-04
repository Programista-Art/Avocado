{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.gpu;

// =============================================================================
// avotensor.gpu — backend GPU/OpenCL dla AvoTensor
//
// Wersja RAW OpenCL:
// - Usunięto zależność od DelphiCL w module GPU.
// - Backend używa bezpośrednio funkcji z CL.pas.
// - Dzięki temu nie ma problemu z AvoDevice.Context = nil.
// - Dodano pełną diagnostykę: etap inicjalizacji, nazwa urządzenia, build log.
// - DotProductGPU obsługuje tensory 1D/2D tak samo jak DotProduct z core.
// =============================================================================

interface

uses
  SysUtils,
  avotensor.core,
  CL,CL_Platform;

var
  GPUEnabled: Boolean = False;

procedure InitAvoGPU;
procedure FreeAvoGPU;
function DotProductGPU(A, B: TAvoTensor): TAvoTensor;

implementation

var
  AvoCLPlatform: PCL_platform_id = nil;
  AvoCLDevice: PCL_device_id = nil;
  AvoCLContext: PCL_context = nil;
  AvoCLQueue: PCL_command_queue = nil;
  AvoCLProgram: PCL_program = nil;
  AvoCLKernel_MatMul: PCL_kernel = nil;
  AvoCLDeviceName: AnsiString = '';

const
  KERNEL_MATMUL_SRC: AnsiString =
    '__kernel void matMul(__global const float* A,' + #10 +
    '                     __global const float* B,' + #10 +
    '                     __global float* C,' + #10 +
    '                     const int M, const int P, const int N) {' + #10 +
    '    int row = get_global_id(0);' + #10 +
    '    int col = get_global_id(1);' + #10 +
    '    if (row < M && col < N) {' + #10 +
    '        float sum = 0.0f;' + #10 +
    '        for (int k = 0; k < P; ++k) {' + #10 +
    '            sum += A[row * P + k] * B[k * N + col];' + #10 +
    '        }' + #10 +
    '        C[row * N + col] = sum;' + #10 +
    '    }' + #10 +
    '}';

procedure CheckCL(Status: TCL_int; const Context: string);
begin
  if Status <> CL_SUCCESS then
    raise Exception.CreateFmt('%s failed: %s (%d)', [Context, GetString(Status), Status]);
end;

procedure RequireProc(Ptr: Pointer; const Name: string);
begin
  if Ptr = nil then
    raise Exception.Create('OpenCL: brak funkcji ' + Name + '. Sprawdz OpenCL.dll / CL.pas.');
end;

procedure ValidateOpenCLFunctions;
begin
  RequireProc(Pointer(clGetPlatformIDs), 'clGetPlatformIDs');
  RequireProc(Pointer(clGetPlatformInfo), 'clGetPlatformInfo');
  RequireProc(Pointer(clGetDeviceIDs), 'clGetDeviceIDs');
  RequireProc(Pointer(clGetDeviceInfo), 'clGetDeviceInfo');
  RequireProc(Pointer(clCreateContext), 'clCreateContext');
  RequireProc(Pointer(clReleaseContext), 'clReleaseContext');
  RequireProc(Pointer(clCreateCommandQueue), 'clCreateCommandQueue');
  RequireProc(Pointer(clReleaseCommandQueue), 'clReleaseCommandQueue');
  RequireProc(Pointer(clCreateBuffer), 'clCreateBuffer');
  RequireProc(Pointer(clReleaseMemObject), 'clReleaseMemObject');
  RequireProc(Pointer(clCreateProgramWithSource), 'clCreateProgramWithSource');
  RequireProc(Pointer(clBuildProgram), 'clBuildProgram');
  RequireProc(Pointer(clGetProgramBuildInfo), 'clGetProgramBuildInfo');
  RequireProc(Pointer(clReleaseProgram), 'clReleaseProgram');
  RequireProc(Pointer(clCreateKernel), 'clCreateKernel');
  RequireProc(Pointer(clSetKernelArg), 'clSetKernelArg');
  RequireProc(Pointer(clReleaseKernel), 'clReleaseKernel');
  RequireProc(Pointer(clEnqueueNDRangeKernel), 'clEnqueueNDRangeKernel');
  RequireProc(Pointer(clEnqueueReadBuffer), 'clEnqueueReadBuffer');
  RequireProc(Pointer(clFinish), 'clFinish');
end;

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

procedure ValidateTensorForGPU(T: TAvoTensor; const Context: string);
begin
  if T = nil then
    raise Exception.Create(Context + ': Tensor = nil.');

  if Length(T.Shape) = 0 then
    raise Exception.Create(Context + ': Shape jest pusty.');

  if (Length(T.Shape) <> 1) and (Length(T.Shape) <> 2) then
    raise Exception.CreateFmt('%s: wymagany tensor 1D albo 2D, otrzymano %dD.',
      [Context, Length(T.Shape)]);

  if T.NumEl <= 0 then
    raise Exception.Create(Context + ': NumEl <= 0.');

  if Length(T.Data) <> T.NumEl then
    raise Exception.CreateFmt('%s: Data ma %d elementow, oczekiwano %d.',
      [Context, Length(T.Data), T.NumEl]);

  if Length(T.Grad) <> T.NumEl then
    raise Exception.CreateFmt('%s: Grad ma %d elementow, oczekiwano %d.',
      [Context, Length(T.Grad), T.NumEl]);
end;

function TensorBytes(T: TAvoTensor; const Context: string): TSize_t;
var
  MaxElements: UInt64;
begin
  ValidateTensorForGPU(T, Context);

  MaxElements := UInt64(High(TSize_t)) div UInt64(SizeOf(Single));
  if UInt64(T.NumEl) > MaxElements then
    raise Exception.CreateFmt('%s: tensor za duzy dla TSize_t. NumEl=%d.',
      [Context, T.NumEl]);

  Result := TSize_t(UInt64(T.NumEl) * UInt64(SizeOf(Single)));
  if Result = 0 then
    raise Exception.Create(Context + ': rozmiar bufora = 0.');
end;

procedure GetMatDims(A, B: TAvoTensor; out M, P, N: Integer);
begin
  ValidateTensorForGPU(A, 'DotProductGPU(A)');
  ValidateTensorForGPU(B, 'DotProductGPU(B)');

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
    raise Exception.CreateFmt(
      'DotProductGPU: Shape mismatch. A.P=%d, B.Shape[0]=%d.',
      [P, B.Shape[0]]
    );

  if Length(B.Shape) = 1 then
    N := 1
  else
    N := B.Shape[1];

  if (M <= 0) or (P <= 0) or (N <= 0) then
    raise Exception.CreateFmt('DotProductGPU: nieprawidlowe wymiary M=%d P=%d N=%d.',
      [M, P, N]);
end;

function CLGetDeviceString(Device: PCL_device_id; ParamName: TCL_device_info): AnsiString;
var
  Status: TCL_int;
  Size: TSize_t;
begin
  Result := '';
  Size := 0;

  Status := clGetDeviceInfo(Device, ParamName, 0, nil, @Size);
  CheckCL(Status, 'clGetDeviceInfo(size)');

  if Size = 0 then Exit;

  SetLength(Result, Size);
  Status := clGetDeviceInfo(Device, ParamName, Size, @Result[1], nil);
  CheckCL(Status, 'clGetDeviceInfo(value)');

  if (Length(Result) > 0) and (Result[Length(Result)] = #0) then
    SetLength(Result, Length(Result) - 1);
end;

function GetBuildLog(ProgramObj: PCL_program; Device: PCL_device_id): AnsiString;
var
  Status: TCL_int;
  Size: TSize_t;
begin
  Result := '';
  Size := 0;

  if (ProgramObj = nil) or (Device = nil) then Exit;

  Status := clGetProgramBuildInfo(ProgramObj, Device, CL_PROGRAM_BUILD_LOG, 0, nil, @Size);
  if Status <> CL_SUCCESS then
  begin
    Result := 'Nie udalo sie pobrac build log. Status=' + IntToStr(Status);
    Exit;
  end;

  if Size = 0 then Exit;

  SetLength(Result, Size);
  Status := clGetProgramBuildInfo(ProgramObj, Device, CL_PROGRAM_BUILD_LOG, Size, @Result[1], nil);
  if Status <> CL_SUCCESS then
  begin
    Result := 'Nie udalo sie pobrac build log value. Status=' + IntToStr(Status);
    Exit;
  end;

  if (Length(Result) > 0) and (Result[Length(Result)] = #0) then
    SetLength(Result, Length(Result) - 1);
end;

function SelectOpenCLDevice(out OutPlatform: PCL_platform_id; out OutDevice: PCL_device_id): Boolean;
var
  Status: TCL_int;
  PlatformCount, DeviceCount: TCL_uint;
  Platforms: array of PCL_platform_id;
  Devices: array of PCL_device_id;
  i: Integer;
begin
  Result := False;
  OutPlatform := nil;
  OutDevice := nil;

  PlatformCount := 0;
  Status := clGetPlatformIDs(0, nil, @PlatformCount);
  CheckCL(Status, 'clGetPlatformIDs(count)');

  if PlatformCount = 0 then
    raise Exception.Create('OpenCL: brak platform OpenCL.');

  SetLength(Platforms, PlatformCount);
  Status := clGetPlatformIDs(PlatformCount, @Platforms[0], nil);
  CheckCL(Status, 'clGetPlatformIDs(list)');

  // Najpierw szukamy GPU.
  for i := 0 to Integer(PlatformCount) - 1 do
  begin
    DeviceCount := 0;
    Status := clGetDeviceIDs(Platforms[i], CL_DEVICE_TYPE_GPU, 0, nil, @DeviceCount);

    if (Status = CL_SUCCESS) and (DeviceCount > 0) then
    begin
      SetLength(Devices, DeviceCount);
      Status := clGetDeviceIDs(Platforms[i], CL_DEVICE_TYPE_GPU, DeviceCount, @Devices[0], nil);
      CheckCL(Status, 'clGetDeviceIDs(GPU list)');

      OutPlatform := Platforms[i];
      OutDevice := Devices[0];
      Exit(True);
    end;
  end;

  // Fallback: jak nie ma GPU, bierzemy pierwsze urządzenie OpenCL.
  for i := 0 to Integer(PlatformCount) - 1 do
  begin
    DeviceCount := 0;
    Status := clGetDeviceIDs(Platforms[i], CL_DEVICE_TYPE_ALL, 0, nil, @DeviceCount);

    if (Status = CL_SUCCESS) and (DeviceCount > 0) then
    begin
      SetLength(Devices, DeviceCount);
      Status := clGetDeviceIDs(Platforms[i], CL_DEVICE_TYPE_ALL, DeviceCount, @Devices[0], nil);
      CheckCL(Status, 'clGetDeviceIDs(ALL list)');

      OutPlatform := Platforms[i];
      OutDevice := Devices[0];
      Exit(True);
    end;
  end;
end;

procedure ResetAvoGPUState;
begin
  AvoGPUDotProductFallback := nil;
  GPUEnabled := False;

  if AvoCLKernel_MatMul <> nil then
  begin
    clReleaseKernel(AvoCLKernel_MatMul);
    AvoCLKernel_MatMul := nil;
  end;

  if AvoCLProgram <> nil then
  begin
    clReleaseProgram(AvoCLProgram);
    AvoCLProgram := nil;
  end;

  if AvoCLQueue <> nil then
  begin
    clReleaseCommandQueue(AvoCLQueue);
    AvoCLQueue := nil;
  end;

  if AvoCLContext <> nil then
  begin
    clReleaseContext(AvoCLContext);
    AvoCLContext := nil;
  end;

  AvoCLDevice := nil;
  AvoCLPlatform := nil;
  AvoCLDeviceName := '';
end;

procedure InitAvoGPU;
var
  Status, ErrCode: TCL_int;
  SourcePtr: PAnsiChar;
  BuildLog: AnsiString;
begin
  if GPUEnabled then Exit;

  try
    ResetAvoGPUState;

    WriteLn('[GPU] InitOpenCL...');
    if not InitOpenCL then
      raise Exception.Create('OpenCL: nie udalo sie zaladowac OpenCL.dll/libOpenCL.');

    ValidateOpenCLFunctions;

    WriteLn('[GPU] Szukam urzadzenia OpenCL...');
    if not SelectOpenCLDevice(AvoCLPlatform, AvoCLDevice) then
      raise Exception.Create('OpenCL: nie znaleziono zadnego urzadzenia.');

    if AvoCLDevice = nil then
      raise Exception.Create('OpenCL: wybrane urzadzenie = nil.');

    AvoCLDeviceName := CLGetDeviceString(AvoCLDevice, CL_DEVICE_NAME);
    WriteLn('[GPU] Wybrano urzadzenie: ', AvoCLDeviceName);

    ErrCode := CL_SUCCESS;
    AvoCLContext := clCreateContext(nil, 1, @AvoCLDevice, nil, nil, @ErrCode);
    CheckCL(ErrCode, 'clCreateContext');
    if AvoCLContext = nil then
      raise Exception.Create('clCreateContext: zwrocono nil.');

    ErrCode := CL_SUCCESS;
    AvoCLQueue := clCreateCommandQueue(AvoCLContext, AvoCLDevice, 0, @ErrCode);
    CheckCL(ErrCode, 'clCreateCommandQueue');
    if AvoCLQueue = nil then
      raise Exception.Create('clCreateCommandQueue: zwrocono nil.');

    SourcePtr := PAnsiChar(KERNEL_MATMUL_SRC);
    ErrCode := CL_SUCCESS;
    AvoCLProgram := clCreateProgramWithSource(AvoCLContext, 1, @SourcePtr, nil, @ErrCode);
    CheckCL(ErrCode, 'clCreateProgramWithSource');
    if AvoCLProgram = nil then
      raise Exception.Create('clCreateProgramWithSource: zwrocono nil.');

    Status := clBuildProgram(AvoCLProgram, 1, @AvoCLDevice, nil, nil, nil);
    if Status <> CL_SUCCESS then
    begin
      BuildLog := GetBuildLog(AvoCLProgram, AvoCLDevice);
      raise Exception.CreateFmt('clBuildProgram failed: %s (%d). Log: %s',
        [GetString(Status), Status, BuildLog]);
    end;

    ErrCode := CL_SUCCESS;
    AvoCLKernel_MatMul := clCreateKernel(AvoCLProgram, 'matMul', @ErrCode);
    CheckCL(ErrCode, 'clCreateKernel(matMul)');
    if AvoCLKernel_MatMul = nil then
      raise Exception.Create('clCreateKernel(matMul): zwrocono nil.');

    GPUEnabled := True;
    AvoGPUDotProductFallback := @DotProductGPU;

    WriteLn('[SYSTEM] GPU OpenCL AKTYWNE: ', AvoCLDeviceName);
  except
    on E: Exception do
    begin
      WriteLn('[SYSTEM] Blad ladowania OpenCL: ', E.Message);
      ResetAvoGPUState;
    end;
  end;
end;

procedure FreeAvoGPU;
begin
  ResetAvoGPUState;
end;

function DotProductGPU(A, B: TAvoTensor): TAvoTensor;
var
  M, P, N: Integer;
  BufA, BufB, BufC: PCL_mem;
  GlobalWorkSize: array[0..1] of TSize_t;
  BytesA, BytesB, BytesC: TSize_t;
  Status: TCL_int;
begin
  Result := nil;
  BufA := nil;
  BufB := nil;
  BufC := nil;

  if not GPUEnabled then
    raise Exception.Create('DotProductGPU: OpenCL nie jest zainicjalizowany.');

  if (AvoCLContext = nil) or (AvoCLQueue = nil) or (AvoCLKernel_MatMul = nil) then
    raise Exception.Create('DotProductGPU: backend OpenCL nie jest kompletny.');

  GetMatDims(A, B, M, P, N);
  //sprawdzanie log
  //WriteLn('[GPU] DotProductGPU: M=', M, ' P=', P, ' N=', N,
  //      ' ops=', Int64(M) * P * N);

  if Length(A.Shape) = 1 then
    Result := TAvoTensor.Create(MakeShape1D(N))
  else
    Result := TAvoTensor.Create(MakeShape2D(M, N));

  try
    try
      SetLength(Result.Dzieci, 2);
      Result.Dzieci[0] := A;
      Result.Dzieci[1] := B;

      BytesA := TensorBytes(A, 'DotProductGPU(A)');
      BytesB := TensorBytes(B, 'DotProductGPU(B)');
      BytesC := TensorBytes(Result, 'DotProductGPU(Result)');

      BufA := clCreateBuffer(AvoCLContext, CL_MEM_READ_ONLY or CL_MEM_COPY_HOST_PTR, BytesA, @A.Data[0], @Status);
      CheckCL(Status, 'clCreateBuffer(A)');
      if BufA = nil then
        raise Exception.Create('clCreateBuffer(A): nil.');

      BufB := clCreateBuffer(AvoCLContext, CL_MEM_READ_ONLY or CL_MEM_COPY_HOST_PTR, BytesB, @B.Data[0], @Status);
      CheckCL(Status, 'clCreateBuffer(B)');
      if BufB = nil then
        raise Exception.Create('clCreateBuffer(B): nil.');

      BufC := clCreateBuffer(AvoCLContext, CL_MEM_WRITE_ONLY, BytesC, nil, @Status);
      CheckCL(Status, 'clCreateBuffer(C)');
      if BufC = nil then
        raise Exception.Create('clCreateBuffer(C): nil.');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 0, SizeOf(PCL_mem), @BufA);
      CheckCL(Status, 'clSetKernelArg(0)');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 1, SizeOf(PCL_mem), @BufB);
      CheckCL(Status, 'clSetKernelArg(1)');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 2, SizeOf(PCL_mem), @BufC);
      CheckCL(Status, 'clSetKernelArg(2)');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 3, SizeOf(Integer), @M);
      CheckCL(Status, 'clSetKernelArg(3)');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 4, SizeOf(Integer), @P);
      CheckCL(Status, 'clSetKernelArg(4)');

      Status := clSetKernelArg(AvoCLKernel_MatMul, 5, SizeOf(Integer), @N);
      CheckCL(Status, 'clSetKernelArg(5)');

      GlobalWorkSize[0] := TSize_t(M);
      GlobalWorkSize[1] := TSize_t(N);

      Status := clEnqueueNDRangeKernel(
        AvoCLQueue,
        AvoCLKernel_MatMul,
        2,
        nil,
        @GlobalWorkSize[0],
        nil,
        0,
        nil,
        nil
      );
      CheckCL(Status, 'clEnqueueNDRangeKernel(matMul)');

      Status := clFinish(AvoCLQueue);
      CheckCL(Status, 'clFinish');

      Status := clEnqueueReadBuffer(
        AvoCLQueue,
        BufC,
        CL_TRUE,
        0,
        BytesC,
        @Result.Data[0],
        0,
        nil,
        nil
      );
      CheckCL(Status, 'clEnqueueReadBuffer(C)');

    except
      if Result <> nil then
      begin
        Result.Free;
        Result := nil;
      end;
      raise;
    end;
  finally
    if BufA <> nil then clReleaseMemObject(BufA);
    if BufB <> nil then clReleaseMemObject(BufB);
    if BufC <> nil then clReleaseMemObject(BufC);
  end;
end;

end.








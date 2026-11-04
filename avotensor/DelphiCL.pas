(********************************************)
(* *)
(* DelphiCL                  *)
(* *)
(* created by      : Maksym Tymkovych  *)
(* (niello)       *)
(* *)
(* headers versions: 0.07              *)
(* file name       : DelphiCL.pas      *)
(* last modify     : 10.12.11          *)
(* license         : BSD               *)
(* *)
(* Site            : www.niello.org.ua *)
(* e-mail          : muxamed13@ukr.net *)
(* ICQ             : 446-769-253       *)
(* *)
(*********Copyright (c) niello 2008-2011*****)

unit DelphiCL;

interface

{$INCLUDE OpenCL.inc}
{$INCLUDE DelphiCL.inc}

uses
  CL,
  Windows,
  SysUtils,
  CL_Platform;

const
  DCL_BUILD_OPTION_SINGLE_PRECISION_CONSTANT = '-cl-single-precision-constant ';
  DCL_BUILD_OPTION_DENORMS_ARE_ZERO          = '-cl-denorms-are-zero ';
  DCL_BUILD_OPTION_OPT_DISABLE               = '-cl-opt-disable ';
  DCL_BUILD_OPTION_STRICT_ALIASING           = '-cl-strict-aliasing ';
  DCL_BUILD_OPTION_MAD_ENABLE                = '-cl-mad-enable ';
  DCL_BUILD_OPTION_NO_SIGNED_ZEROS           = '-cl-no-signed-zeros ';
  DCL_BUILD_OPTION_UNSAFE_MATH_OPTIMIZATIONS = '-cl-unsafe-math-optimizations ';
  DCL_BUILD_OPTION_FINITE_MATH_ONLY          = '-cl-finite-math-only ';
  DCL_BUILD_OPTION_FAST_RELAXED_MATH         = '-cl-fast-relaxed-math ';
  DCL_BUILD_OPTION_W                         = '-w ';
  DCL_BUILD_OPTION_WERROR                    = '-Werror ';
  DCL_BUILD_OPTION_STD                       = '-cl-std=';

{$IFDEF LOGGING}
var
  DCLFileLOG: TextFile;
  procedure WriteLog(const Str: AnsiString);
{$ENDIF}

type

  TDCLMemFlags = (mfReadWrite, mfWriteOnly, mfReadOnly, mfUseHostPtr, mfAllocHostPtr, mfCopyHostPtr);
  TDCLMemFlagsSet = set of TDCLMemFlags;

  PDCLBuffer = ^TDCLBuffer;
  TDCLBuffer = class
  private
    FMem: PCL_mem;
    FStatus: TCL_int;
    FSize: TSize_t;
  protected
    constructor Create(const Context: PCL_context; const Flags: TDCLMemFlagsSet; const Size: TSize_t; const Data: Pointer=nil);
  public
    destructor Destroy();override;
    property Size: TSize_t read FSize;
    property Status: TCL_int read FStatus;
  end;

  PDCLImage2D = ^TDCLImage2D;
  TDCLImage2D = class
  private
    FMem: PCL_mem;
    FStatus: TCL_int;
    FFormat: TCL_image_format;
    FRowPitch: TSize_t;
    FWidth,
    FHeight: TSize_t;
  protected
    constructor Create(const Context: PCL_context; const Flags: TDCLMemFlagsSet; const Format: PCL_image_format; const Width, Height: TSize_t; const RowPitch: TSize_t = 0; const Data: Pointer = nil);
  public
    destructor Destroy(); override;
    property Width: TSize_t read FWidth;
    property Height: TSize_t read FHeight;
    property RowPitch: TSize_t read FRowPitch;
    property Status: TCL_int read FStatus;
  end;

  TDCLCommandQueueProperties = (cqpOutOfOrderExecModeEnable);
  TDCLCommandQueuePropertiesSet = set of TDCLCommandQueueProperties;

  PDCLKernel = ^TDCLKernel;
  TDCLKernel = class
  private
    FKernel: PCL_kernel;
    FStatus: TCL_int;
  protected
    constructor Create(const Program_: PCL_program; const KernelName: PAnsiChar);
    function GetFunctionName(): AnsiString;
    function GetNumArgs(): TCL_uint;
  public
    property Status: TCL_int read FStatus;
    property FunctionName: AnsiString read GetFunctionName;
    property NumArgs: TCL_uint read GetNumArgs;
    procedure SetArg(const Index: TCL_uint; const Size: TSize_t; const Value: Pointer); overload;
    procedure SetArg(const Index: TCL_uint; const Value: TDCLBuffer); overload;
    procedure SetArg(const Index: TCL_uint; const Value: TDCLImage2D); overload;
    destructor Destroy(); override;
  end;

  PDCLCommandQueue = ^TDCLCommandQueue;
  TDCLCommandQueue = class
  private
    FCommandQueue: PCL_command_queue;
    FStatus: TCL_int;
    FProperties: TDCLCommandQueuePropertiesSet;
    {$IFDEF PROFILING}
    FExecuteTime: TCL_ulong;
    {$ENDIF}
    constructor Create(const Device_Id: PCL_device_id; const Context: PCL_context; const Properties: TDCLCommandQueuePropertiesSet = []);
  public
    procedure ReadBuffer(const Buffer: TDCLBuffer; const Size: TSize_t; const Data: Pointer);
    procedure WriteBuffer(const Buffer: TDCLBuffer; const Size: TSize_t; const Data: Pointer);
    procedure ReadImage2D(const Image: TDCLImage2D; const Data: Pointer);
    procedure WriteImage2D(const Image: TDCLImage2D; const Width, Height: TSize_t; const Data: Pointer);
    procedure Execute(const Kernel: TDCLKernel; const Size: TSize_t); overload;
    procedure Execute(const Kernel: TDCLKernel; const Size: array of TSize_t);overload;

    property Status: TCL_int read FStatus;
    property Properties: TDCLCommandQueuePropertiesSet read FProperties;
    {$IFDEF PROFILING}
    property ExecuteTime: TCL_ulong read FExecuteTime;
    {$ENDIF}
    destructor Destroy(); override;
  end;

  TArraySize_t = array of TSize_t;

  PDCLProgram = ^TDCLProgram;
  TDCLProgram = class
  private
    FProgram: PCL_program;
    FStatus: TCL_int;
    FSource: PAnsiChar;
    FLog: AnsiString;
    FBinarySizes: TSize_t;
    FBinaries: array of array of AnsiChar;
  protected
    constructor Create(const Device: PCL_device_id; const Context: PCL_context; const Source: PPAnsiChar; const Options: PAnsiChar = nil);
  public
    property BinarySizes: TSize_t read FBinarySizes;
    property Source: PAnsiChar read FSource;
    property Status: TCL_int read FStatus;
    property Log: AnsiString read FLog;
    function CreateKernel(const KernelName: PAnsiChar): TDCLKernel;
    procedure SaveToFile(const FileName: AnsiString);
    destructor Destroy(); override;
  end;

  PDCLContext = ^TDCLContext;
  TDCLContext = class
  private
    FContext: PCL_context;
    FStatus: TCL_int;
    FNumDevices: TCL_uint;
  public
    constructor Create(Device_id: PCL_device_id);
    property Status: TCL_int read FStatus;
    property NumDevices: TCL_uint read FNumDevices;
    destructor Destroy(); override;
  end;

  TDCLDeviceFPConfig = ({$IFDEF CL_VERSION_1_0}
                        dfpcDenorm, dfpcInfNan, dfpcRoundToNearest, dfpcRoundToZero,
                        dfpcRoundToInf, dfpcFMA
                        {$ENDIF}
                        {$IFDEF CL_VERSION_1_1}
                        , dfpcSoftFloat
                        {$ENDIF}
                        {$IFDEF CL_VERSION_1_2}
                        , dfpcCorrectlyRoundedDivideSqrt
                        {$ENDIF}
                        );
  TDCLDeviceFPConfigSet = Set of TDCLDeviceFPConfig;

  TDCLDeviceExecutionCapabilities = ({$IFDEF CL_VERSION_1_0}decExecKernel, decExecNativeKernel{$ENDIF});
  TDCLDeviceExecutionCapabilitiesSet = set of TDCLDeviceExecutionCapabilities;

  TDCLDeviceMemCacheType = ({$IFDEF CL_VERSION_1_0}
                            dmctNone, dmctReadOnlyCache, dmctWriteOnlyCache
                            {$ENDIF});
  TDCLDeviceLocalMemType = ({$IFDEF CL_VERSION_1_0}
                            dlmtLocal, dlmtGlobal
                            {$ENDIF});

  PDCLDevice = ^TDCLDevice;
  TDCLDevice = class
  private
    FDevice_id: PCL_device_id;
    FStatus: TCL_int;

    FName: AnsiString;
    FVendor: AnsiString;
    FVersion: AnsiString;
    FProfile: AnsiString;

    FIsCPU: Boolean;
    FIsGPU: Boolean;
    FIsAccelerator: Boolean;
    FIsDefault: Boolean;

    FMaxWorkGroupSize: TSize_t;

    FNativeVectorPreferredChar: TCL_uint;
    FNativeVectorPreferredShort: TCL_uint;
    FNativeVectorPreferredInt: TCL_uint;
    FNativeVectorPreferredLong: TCL_uint;
    FNativeVectorPreferredFloat: TCL_uint;
    FNativeVectorPreferredDouble: TCL_uint;
    FNativeVectorPreferredHalf: TCL_uint;
    FNativeVectorWidthChar: TCL_uint;
    FNativeVectorWidthShort: TCL_uint;
    FNativeVectorWidthInt: TCL_uint;
    FNativeVectorWidthLong: TCL_uint;
    FNativeVectorWidthFloat: TCL_uint;
    FNativeVectorWidthDouble: TCL_uint;
    FNativeVectorWidthHalf: TCL_uint;

    FMaxClockFrequency: TCL_uint;
    FAddressBits: TCL_uint;
    FMaxMemAllocSize: TCL_ulong;

    FIsImageSupport: Boolean;

    FMaxReadImageArgs: TCL_uint;
    FMaxWriteImageArgs: TCL_uint;
    FImage2DMaxWidth: TSize_t;
    FImage2DMaxHeight: TSize_t;
    FImage3DMaxWidth: TSize_t;
    FImage3DMaxHeight: TSize_t;
    FImage3DMaxDepth: TSize_t;
    FMaxSamplers: TCL_uint;
    FMaxParameterSize: TSize_t;
    FMemBaseAddrAlign: TCL_uint;
    FMinDataTypeAlignSize: TCL_uint;

    FGlobalMemCacheLineSize: TCL_uint;
    FGlobalMemCacheSize: TCL_ulong;
    FGlobalMemSize: TCL_ulong;
    FMaxConstantBufferSize: TCL_ulong;
    FMaxConstantArgs: TCL_uint;

    FLocalMemSize: TCL_ulong;
    FIsErrorCorrectionSupport: Boolean;
    FIsHostUnifiedMemory: Boolean;
    FProfilingTimerResolution: TSize_t;
    FIsEndianLittle: Boolean;
    FIsAvailable: Boolean;
    FIsCompilerAvailable: Boolean;

    FVendorId: TCL_uint;
    FMaxComputeUnits: TCL_uint;
    FMaxWorkItemDimensions: TCL_uint;
    FExtensionsString: AnsiString;
    FOpenCLCVersion: AnsiString;
    FDriverVersion: AnsiString;

    FExtensionsCount: TSize_t;
    FExtensions: array of AnsiString;

    FContext: TDCLContext;

    FFPConfigSet: TDCLDeviceFPConfigSet;
    FExecutionCapabilities: TDCLDeviceExecutionCapabilitiesSet;
    FGlobalMemCacheType: TDCLDeviceMemCacheType;

    FLocalMemType: TDCLDeviceLocalMemType;

    function GetExtensions(const Index: TSize_t): AnsiString;
    function IsPresentExtension(const ExtensionName: AnsiString): Boolean;
    function IsPresentInFPConfig(const FPConfig: TDCLDeviceFPConfig): Boolean;
  protected
    constructor Create(Device_id: PCL_device_id);
    property Device_id: PCL_device_id read FDevice_id;
  public
    property Status: TCL_int read FStatus;

    property Name: AnsiString read FName;
    property Vendor: AnsiString read FVendor;
    property Version: AnsiString read FVersion;
    property Profile: AnsiString read FProfile;

    property IsCPU: Boolean read FIsCPU;
    property IsGPU: Boolean read FIsGPU;
    property IsAccelerator: Boolean read FIsAccelerator;
    property IsDefault: Boolean read FIsDefault;

    property MaxWorkGroupSize: TSize_t read FMaxWorkGroupSize;

    property NativeVectorPreferredChar: TCL_uint read FNativeVectorPreferredChar;
    property NativeVectorPreferredShort: TCL_uint read FNativeVectorPreferredShort;
    property NativeVectorPreferredInt: TCL_uint read FNativeVectorPreferredInt;
    property NativeVectorPreferredLong: TCL_uint read FNativeVectorPreferredLong;
    property NativeVectorPreferredFloat: TCL_uint read FNativeVectorPreferredFloat;
    property NativeVectorPreferredDouble: TCL_uint read FNativeVectorPreferredDouble;
    property NativeVectorPreferredHalf: TCL_uint read FNativeVectorPreferredHalf;
    property NativeVectorWidthChar: TCL_uint read FNativeVectorWidthChar;
    property NativeVectorWidthShort: TCL_uint read FNativeVectorWidthShort;
    property NativeVectorWidthInt: TCL_uint read FNativeVectorWidthInt;
    property NativeVectorWidthLong: TCL_uint read FNativeVectorWidthLong;
    property NativeVectorWidthFloat: TCL_uint read FNativeVectorWidthFloat;
    property NativeVectorWidthDouble: TCL_uint read FNativeVectorWidthDouble;
    property NativeVectorWidthHalf: TCL_uint read FNativeVectorWidthHalf;

    property MaxClockFrequency: TCL_uint  read FMaxClockFrequency;
    property AddressBits: TCL_uint  read FAddressBits;
    property MaxMemAllocSize: TCL_ulong  read FMaxMemAllocSize;

    property IsImageSupport: Boolean read FIsImageSupport;

    property MaxReadImageArgs: TCL_uint read FMaxReadImageArgs;
    property MaxWriteImageArgs: TCL_uint read FMaxWriteImageArgs;
    property Image2DMaxWidth: TSize_t read FImage2DMaxWidth;
    property Image2DMaxHeight: TSize_t read FImage2DMaxHeight;
    property Image3DMaxWidth: TSize_t read FImage3DMaxWidth;
    property Image3DMaxHeight: TSize_t read FImage3DMaxHeight;
    property Image3DMaxDepth: TSize_t read FImage3DMaxDepth;
    property MaxSamplers: TCL_uint read FMaxSamplers;
    property MaxParameterSize: TSize_t read FMaxParameterSize;
    property MemBaseAddrAlign: TCL_uint read FMemBaseAddrAlign;
    property MinDataTypeAlignSize: TCL_uint read FMinDataTypeAlignSize;

    property GlobalMemCacheLineSize: TCL_uint read FGlobalMemCacheLineSize;
    property GlobalMemCacheSize: TCL_ulong read FGlobalMemCacheSize;
    property GlobalMemSize: TCL_ulong read FGlobalMemSize;
    property MaxConstantBufferSize: TCL_ulong read FMaxConstantBufferSize;
    property MaxConstantArgs: TCL_uint read FMaxConstantArgs;

    property LocalMemSize: TCL_ulong read FLocalMemSize;
    property IsErrorCorrectionSupport: Boolean read FIsErrorCorrectionSupport;
    property IsHostUnifiedMemory: Boolean read FIsHostUnifiedMemory;
    property ProfilingTimerResolution: TSize_t read FProfilingTimerResolution;
    property IsEndianLittle: Boolean read FIsEndianLittle;
    property IsAvailable: Boolean read FIsAvailable;
    property IsCompilerAvailable: Boolean read FIsCompilerAvailable;

    property VendorId: TCL_uint read FVendorId;
    property MaxComputeUnits: TCL_uint read FMaxComputeUnits;
    property MaxWorkItemDimensions: TCL_uint read FMaxWorkItemDimensions;

    property DriverVersion: AnsiString read FDriverVersion;
    property OpenCLCVersion: AnsiString read FOpenCLCVersion;
    property ExtensionsString: AnsiString read FExtensionsString;

    property Context: TDCLContext read FContext;
    function CreateContext(): TDCLContext;
    function CreateCommandQueue(const properties: TDCLCommandQueuePropertiesSet = []): TDCLCommandQueue;overload;
    function CreateCommandQueue(const context: TDCLContext; const properties: TDCLCommandQueuePropertiesSet = []): TDCLCommandQueue;overload;
    function CreateBuffer(const Size: TSize_t; const Data: Pointer = nil; const flags: TDCLMemFlagsSet = [mfReadWrite]): TDCLBuffer;

    function CreateImage2D(const Format: PCL_image_format; const Width, Height, RowPitch: TSize_t; const Data: Pointer = nil; const flags: TDCLMemFlagsSet = [mfReadWrite]): TDCLImage2D;

    function CreateProgram(const Source: PPAnsiChar; const Options: PAnsiChar = nil): TDCLProgram; overload;
    function CreateProgram(const FileName: String; const Options: PAnsiChar = nil): TDCLProgram; overload;

    property ExtensionsCount: TSize_t read FExtensionsCount;
    property Extensions[const Index: TSize_t]: AnsiString read GetExtensions;
    property IsSupportedExtension[const Index: AnsiString]: Boolean read IsPresentExtension;

    property FPConfig[const Index: TDCLDeviceFPConfig]: Boolean read IsPresentInFPConfig;
    property GlobalMemCacheType: TDCLDeviceMemCacheType read FGlobalMemCacheType;
    destructor Destroy(); override;
  end;

  PDCLPlatform = ^TDCLPlatform;
  TDCLPlatform = class
  private
    FPlatform_id: PCL_platform_id;
    FProfile: AnsiString;
    FVersion: AnsiString;
    FName: AnsiString;
    FVendor: AnsiString;
    FExtensionsString: AnsiString;
    FStatus: TCL_int;
    FDevices: array of TDCLDevice;
    FDeviceCount: TCL_uint;

    FCPUs,
    FGPUs,
    FAccelerators: array of TCL_uint;
    FCPUCount,
    FGPUCount,
    FAcceleratorCount: TCL_uint;

    FExtensionsCount: TSize_t;
    FExtensions: array of AnsiString;
    function GetDevice(Index: TCL_uint): PDCLDevice;
    function GetCPU(Index: TCL_uint): PDCLDevice;
    function GetGPU(Index: TCL_uint): PDCLDevice;
    function GetAccelerator(Index: TCL_uint): PDCLDevice;
    function GetExtensions(Index: TSize_t): AnsiString;
    function IsPresentExtension(const ExtensionName: AnsiString): Boolean;

    function GetDeviceWithMaxClockFrequency(): PDCLDevice;
    function GetDeviceWithMaxComputeUnits(): PDCLDevice;

    function GetDeviceWithMaxGlobalMemCacheLineSize(): PDCLDevice;
    function GetDeviceWithMaxGlobalMemCacheSize(): PDCLDevice;
    function GetDeviceWithMaxGlobalMemSize(): PDCLDevice;

    function GetDeviceWithMaxImage2DWidth(): PDCLDevice;
    function GetDeviceWithMaxImage2DHeight(): PDCLDevice;
    function GetDeviceWithMaxImage3DWidth(): PDCLDevice;
    function GetDeviceWithMaxImage3DHeight(): PDCLDevice;
    function GetDeviceWithMaxImage3DDepth(): PDCLDevice;

    function GetDeviceWithMaxLocalMemSize(): PDCLDevice;
    function GetDeviceWithMaxConstantArgs(): PDCLDevice;
    function GetDeviceWithMaxConstantBufferSize(): PDCLDevice;
    function GetDeviceWithMaxMemAllocSize(): PDCLDevice;
    function GetDeviceWithMaxParameterSize(): PDCLDevice;
    function GetDeviceWithMaxReadImageArgs(): PDCLDevice;
    function GetDeviceWithMaxSamplers(): PDCLDevice;
    function GetDeviceWithMaxWorkGroupSize(): PDCLDevice;
    function GetDeviceWithMaxWorkItemDimensions(): PDCLDevice;
    function GetDeviceWithMaxWriteImageArgs(): PDCLDevice;
  public
    constructor Create(Platform_id: PCL_platform_id);
    property Profile: AnsiString read FProfile;
    property Version: AnsiString read FVersion;
    property Name: AnsiString read FName;
    property Vendor: AnsiString read FVendor;
    property ExtensionsString: AnsiString read FExtensionsString;

    property DeviceCount: TCL_uint read FDeviceCount;
    property CPUCount: TCL_uint read FCPUCount;
    property GPUCount: TCL_uint read FGPUCount;
    property AcceleratorCount: TCL_uint read FAcceleratorCount;

    property Status: TCL_int read FStatus;
    property Devices[Index: TCL_uint]: PDCLDevice read GetDevice;
    property CPUs[Index: TCL_uint]: PDCLDevice read GetCPU;
    property GPUs[Index: TCL_uint]: PDCLDevice read GetGPU;
    property Accelerators[Index: TCL_uint]: PDCLDevice read GetAccelerator;
    property ExtensionsCount: TSize_t read FExtensionsCount;
    property Extensions[Index: TSize_t]: AnsiString read GetExtensions;
    property IsSupportedExtension[const Index: AnsiString]: Boolean read IsPresentExtension;

    property DeviceWithMaxClockFrequency: PDCLDevice read GetDeviceWithMaxClockFrequency;
    property DeviceWithMaxComputeUnits: PDCLDevice read GetDeviceWithMaxComputeUnits;
    property DeviceWithMaxGlobalMemCacheLineSize: PDCLDevice read GetDeviceWithMaxGlobalMemCacheLineSize;
    property DeviceWithMaxGlobalMemCacheSize: PDCLDevice read GetDeviceWithMaxGlobalMemCacheSize;
    property DeviceWithMaxGlobalMemSize: PDCLDevice read GetDeviceWithMaxGlobalMemSize;
    property DeviceWithMaxImage2DWidth: PDCLDevice read GetDeviceWithMaxImage2DWidth;
    property DeviceWithMaxImage2DHeight: PDCLDevice read GetDeviceWithMaxImage2DHeight;
    property DeviceWithMaxImage3DWidth: PDCLDevice read GetDeviceWithMaxImage3DWidth;
    property DeviceWithMaxImage3DHeight: PDCLDevice read GetDeviceWithMaxImage3DHeight;
    property DeviceWithMaxImage3DDepth: PDCLDevice read GetDeviceWithMaxImage3DDepth;
    property DeviceWithMaxLocalMemSize: PDCLDevice read GetDeviceWithMaxLocalMemSize;
    property DeviceWithMaxConstantArgs: PDCLDevice read GetDeviceWithMaxConstantArgs;
    property DeviceWithMaxConstantBufferSize: PDCLDevice read GetDeviceWithMaxConstantBufferSize;
    property DeviceWithMaxMemAllocSize: PDCLDevice read GetDeviceWithMaxMemAllocSize;
    property DeviceWithMaxParameterSize: PDCLDevice read GetDeviceWithMaxParameterSize;
    property DeviceWithMaxReadImageArgs: PDCLDevice read GetDeviceWithMaxReadImageArgs;
    property DeviceWithMaxSamplers: PDCLDevice read GetDeviceWithMaxSamplers;
    property DeviceWithMaxWorkGroupSize: PDCLDevice read GetDeviceWithMaxWorkGroupSize;
    property DeviceWithMaxWorkItemDimensions: PDCLDevice read GetDeviceWithMaxWorkItemDimensions;
    property DeviceWithMaxWriteImageArgs: PDCLDevice read GetDeviceWithMaxWriteImageArgs;
    destructor Destroy(); override;
  end;

  PDCLPlatforms = ^TDCLPlatforms;
  TDCLPlatforms = class
  private
    FPlatforms: array of TDCLPlatform;
    FPlatformCount: TCL_uint;
    FStatus: TCL_int;
    function GetPlatform(Index: TCL_uint): PDCLPlatform;
  public
    constructor Create();
    property PlatformCount: TCL_uint read FPlatformCount;
    property Status: TCL_int read FStatus;
    property Platforms[Index: TCL_uint]: PDCLPlatform read GetPlatform;
    destructor Destroy(); override;
  end;


implementation

function UpperCase(const S: AnsiString): AnsiString;
var
  Ch: AnsiChar;
  L: Integer;
  Source, Dest: PAnsiChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

{$IFDEF LOGGING}
procedure WriteLog(const Str: AnsiString);
begin
  Writeln(DCLFileLOG, Str);
  Flush(DCLFileLOG);
end;
{$ENDIF}

procedure DCLFail(const Where: AnsiString; const Status: TCL_int);
begin
  raise Exception.Create(String(Where) + ': ' + String(GetString(Status)) + ' (' + IntToStr(Status) + ')');
end;

procedure DCLCheck(const Where: AnsiString; const Status: TCL_int);
begin
  if Status <> CL_SUCCESS then
    DCLFail(Where, Status);
end;

procedure DCLCheckAssigned(Ptr: Pointer; const Name: AnsiString);
begin
  if Ptr = nil then
    raise Exception.Create(String(Name) + ' = nil. OpenCL.dll nie zostal poprawnie zaladowany albo wrapper CL.pas nie zaladowal funkcji.');
end;

procedure DCLCheckCoreFunctions;
begin
  if SizeOf(TSize_t) < SizeOf(Pointer) then
    raise Exception.Create('CL.pas: TSize_t ma zly rozmiar dla Win64. Ustaw TSize_t = PtrUInt / SizeUInt oraz TIntPtr_t = PtrInt / NativeInt.');

  if OCL_LibHandle = nil then
  begin
    if not InitOpenCL then
      raise Exception.Create('InitOpenCL: nie udalo sie zaladowac OpenCL.dll / libOpenCL.so.');
  end;

  if not Assigned(clGetPlatformIDs) then DCLCheckAssigned(nil, 'clGetPlatformIDs');
  if not Assigned(clGetPlatformInfo) then DCLCheckAssigned(nil, 'clGetPlatformInfo');
  if not Assigned(clGetDeviceIDs) then DCLCheckAssigned(nil, 'clGetDeviceIDs');
  if not Assigned(clGetDeviceInfo) then DCLCheckAssigned(nil, 'clGetDeviceInfo');
  if not Assigned(clCreateContext) then DCLCheckAssigned(nil, 'clCreateContext');
  if not Assigned(clReleaseContext) then DCLCheckAssigned(nil, 'clReleaseContext');
  if not Assigned(clCreateCommandQueue) then DCLCheckAssigned(nil, 'clCreateCommandQueue');
  if not Assigned(clReleaseCommandQueue) then DCLCheckAssigned(nil, 'clReleaseCommandQueue');
  if not Assigned(clCreateBuffer) then DCLCheckAssigned(nil, 'clCreateBuffer');
  if not Assigned(clReleaseMemObject) then DCLCheckAssigned(nil, 'clReleaseMemObject');
  if not Assigned(clCreateProgramWithSource) then DCLCheckAssigned(nil, 'clCreateProgramWithSource');
  if not Assigned(clBuildProgram) then DCLCheckAssigned(nil, 'clBuildProgram');
  if not Assigned(clCreateKernel) then DCLCheckAssigned(nil, 'clCreateKernel');
  if not Assigned(clSetKernelArg) then DCLCheckAssigned(nil, 'clSetKernelArg');
  if not Assigned(clEnqueueNDRangeKernel) then DCLCheckAssigned(nil, 'clEnqueueNDRangeKernel');
  if not Assigned(clEnqueueReadBuffer) then DCLCheckAssigned(nil, 'clEnqueueReadBuffer');
  if not Assigned(clEnqueueWriteBuffer) then DCLCheckAssigned(nil, 'clEnqueueWriteBuffer');
  if not Assigned(clFinish) then DCLCheckAssigned(nil, 'clFinish');
end;

function DCLTrimNull(const S: AnsiString): AnsiString;
var
  P: Integer;
begin
  Result := S;
  P := Pos(#0, Result);
  if P > 0 then
    SetLength(Result, P - 1);
end;

function DCLGetPlatformString(Platform: PCL_platform_id; Param: TCL_platform_info; const Name: AnsiString): AnsiString;
var
  Status: TCL_int;
  Size: TSize_t;
begin
  Result := '';
  Size := 0;
  Status := clGetPlatformInfo(Platform, Param, 0, nil, @Size);
  DCLCheck('clGetPlatformInfo size ' + Name, Status);
  if Size = 0 then Exit;
  SetLength(Result, Size);
  Status := clGetPlatformInfo(Platform, Param, Size, @Result[1], nil);
  DCLCheck('clGetPlatformInfo data ' + Name, Status);
  Result := DCLTrimNull(Result);
end;

function DCLGetDeviceString(Device: PCL_device_id; Param: TCL_device_info; const Name: AnsiString): AnsiString;
var
  Status: TCL_int;
  Size: TSize_t;
begin
  Result := '';
  Size := 0;
  Status := clGetDeviceInfo(Device, Param, 0, nil, @Size);
  DCLCheck('clGetDeviceInfo size ' + Name, Status);
  if Size = 0 then Exit;
  SetLength(Result, Size);
  Status := clGetDeviceInfo(Device, Param, Size, @Result[1], nil);
  DCLCheck('clGetDeviceInfo data ' + Name, Status);
  Result := DCLTrimNull(Result);
end;

function DCLGetDeviceUInt(Device: PCL_device_id; Param: TCL_device_info; DefaultValue: TCL_uint = 0): TCL_uint;
var
  Status: TCL_int;
begin
  Result := DefaultValue;
  Status := clGetDeviceInfo(Device, Param, SizeOf(Result), @Result, nil);
  if Status <> CL_SUCCESS then Result := DefaultValue;
end;

function DCLGetDeviceULong(Device: PCL_device_id; Param: TCL_device_info; DefaultValue: TCL_ulong = 0): TCL_ulong;
var
  Status: TCL_int;
begin
  Result := DefaultValue;
  Status := clGetDeviceInfo(Device, Param, SizeOf(Result), @Result, nil);
  if Status <> CL_SUCCESS then Result := DefaultValue;
end;

function DCLGetDeviceSize(Device: PCL_device_id; Param: TCL_device_info; DefaultValue: TSize_t = 0): TSize_t;
var
  Status: TCL_int;
begin
  Result := DefaultValue;
  Status := clGetDeviceInfo(Device, Param, SizeOf(Result), @Result, nil);
  if Status <> CL_SUCCESS then Result := DefaultValue;
end;

function DCLGetDeviceBool(Device: PCL_device_id; Param: TCL_device_info; DefaultValue: Boolean = False): Boolean;
var
  Status: TCL_int;
  B: TCL_bool;
begin
  B := 0;
  Status := clGetDeviceInfo(Device, Param, SizeOf(B), @B, nil);
  if Status <> CL_SUCCESS then Result := DefaultValue else Result := B <> 0;
end;

function DCLGetDeviceBitfield(Device: PCL_device_id; Param: TCL_device_info): TCL_bitfield;
var
  Status: TCL_int;
begin
  Result := 0;
  Status := clGetDeviceInfo(Device, Param, SizeOf(Result), @Result, nil);
  if Status <> CL_SUCCESS then Result := 0;
end;

function TDCLPlatforms.GetPlatform(Index: TCL_uint): PDCLPlatform;
begin
  if Index < FPlatformCount then Result := @FPlatforms[Index] else Result := nil;
end;

constructor TDCLPlatforms.Create;
var
  Platforms: array of PCL_platform_id;
  I: Integer;
begin
  inherited Create;
  FPlatformCount := 0;
  FStatus := CL_SUCCESS;
  DCLCheckCoreFunctions;

  FStatus := clGetPlatformIDs(0, nil, @FPlatformCount);
  DCLCheck('clGetPlatformIDs count', FStatus);
  if FPlatformCount = 0 then
    raise Exception.Create('OpenCL: brak platform OpenCL w systemie. Sprawdz sterownik GPU / AMD Adrenalin / clinfo.');

  SetLength(Platforms, FPlatformCount);
  SetLength(FPlatforms, FPlatformCount);
  FStatus := clGetPlatformIDs(FPlatformCount, @Platforms[0], nil);
  DCLCheck('clGetPlatformIDs list', FStatus);

  for I := 0 to Integer(FPlatformCount) - 1 do
    FPlatforms[I] := TDCLPlatform.Create(Platforms[I]);
end;

destructor TDCLPlatforms.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FPlatforms) do
    FreeAndNil(FPlatforms[I]);
  SetLength(FPlatforms, 0);
  inherited Destroy;
end;

constructor TDCLPlatform.Create(Platform_id: PCL_platform_id);
var
  Devices: array of PCL_device_id;
  I: Integer;
  Ext, Token: AnsiString;
  P, StartPos: Integer;
begin
  inherited Create;
  if Platform_id = nil then
    raise Exception.Create('TDCLPlatform.Create: Platform_id = nil.');

  FPlatform_id := Platform_id;
  FStatus := CL_SUCCESS;
  FProfile := DCLGetPlatformString(FPlatform_id, CL_PLATFORM_PROFILE, 'CL_PLATFORM_PROFILE');
  FVersion := DCLGetPlatformString(FPlatform_id, CL_PLATFORM_VERSION, 'CL_PLATFORM_VERSION');
  FName := DCLGetPlatformString(FPlatform_id, CL_PLATFORM_NAME, 'CL_PLATFORM_NAME');
  FVendor := DCLGetPlatformString(FPlatform_id, CL_PLATFORM_VENDOR, 'CL_PLATFORM_VENDOR');
  FExtensionsString := DCLGetPlatformString(FPlatform_id, CL_PLATFORM_EXTENSIONS, 'CL_PLATFORM_EXTENSIONS');

  Ext := FExtensionsString + ' ';
  StartPos := 1;
  FExtensionsCount := 0;
  SetLength(FExtensions, 0);
  for P := 1 to Length(Ext) do
  begin
    if (Ext[P] = ' ') or (Ext[P] = #0) then
    begin
      Token := Copy(Ext, StartPos, P - StartPos);
      if Token <> '' then
      begin
        Inc(FExtensionsCount);
        SetLength(FExtensions, FExtensionsCount);
        FExtensions[FExtensionsCount - 1] := UpperCase(Token);
      end;
      StartPos := P + 1;
    end;
  end;

  FStatus := clGetDeviceIDs(FPlatform_id, CL_DEVICE_TYPE_ALL, 0, nil, @FDeviceCount);
  if FStatus = CL_DEVICE_NOT_FOUND then
  begin
    FDeviceCount := 0;
    Exit;
  end;
  DCLCheck('clGetDeviceIDs count', FStatus);

  if FDeviceCount > 0 then
  begin
    SetLength(Devices, FDeviceCount);
    FStatus := clGetDeviceIDs(FPlatform_id, CL_DEVICE_TYPE_ALL, FDeviceCount, @Devices[0], nil);
    DCLCheck('clGetDeviceIDs list', FStatus);
    SetLength(FDevices, FDeviceCount);
    for I := 0 to Integer(FDeviceCount) - 1 do
    begin
      FDevices[I] := TDCLDevice.Create(Devices[I]);
      if FDevices[I].IsCPU then
      begin
        Inc(FCPUCount);
        SetLength(FCPUs, FCPUCount);
        FCPUs[FCPUCount - 1] := I;
      end;
      if FDevices[I].IsGPU then
      begin
        Inc(FGPUCount);
        SetLength(FGPUs, FGPUCount);
        FGPUs[FGPUCount - 1] := I;
      end;
      if FDevices[I].IsAccelerator then
      begin
        Inc(FAcceleratorCount);
        SetLength(FAccelerators, FAcceleratorCount);
        FAccelerators[FAcceleratorCount - 1] := I;
      end;
    end;
  end;
end;

destructor TDCLPlatform.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FDevices) do FreeAndNil(FDevices[I]);
  SetLength(FDevices, 0);
  SetLength(FCPUs, 0);
  SetLength(FGPUs, 0);
  SetLength(FAccelerators, 0);
  SetLength(FExtensions, 0);
  inherited Destroy;
end;

function TDCLPlatform.GetDevice(Index: TCL_uint): PDCLDevice;
begin
  if Index < FDeviceCount then Result := @FDevices[Index] else Result := nil;
end;

function TDCLPlatform.GetCPU(Index: TCL_uint): PDCLDevice;
begin
  if Index < FCPUCount then Result := @FDevices[FCPUs[Index]] else Result := nil;
end;

function TDCLPlatform.GetGPU(Index: TCL_uint): PDCLDevice;
begin
  if Index < FGPUCount then Result := @FDevices[FGPUs[Index]] else Result := nil;
end;

function TDCLPlatform.GetAccelerator(Index: TCL_uint): PDCLDevice;
begin
  if Index < FAcceleratorCount then Result := @FDevices[FAccelerators[Index]] else Result := nil;
end;

function TDCLPlatform.GetExtensions(Index: TSize_t): AnsiString;
begin
  if Index < FExtensionsCount then Result := FExtensions[Index] else Result := '';
end;

function TDCLPlatform.IsPresentExtension(const ExtensionName: AnsiString): Boolean;
var
  I: Integer;
  Name: AnsiString;
begin
  Result := False;
  Name := UpperCase(ExtensionName);
  for I := 0 to High(FExtensions) do
    if FExtensions[I] = Name then Exit(True);
end;

function TDCLPlatform.GetDeviceWithMaxClockFrequency: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxClockFrequency;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxClockFrequency; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxComputeUnits: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxComputeUnits;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxComputeUnits; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxConstantArgs: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxConstantArgs;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxConstantArgs; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxConstantBufferSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_ulong;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxConstantBufferSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxConstantBufferSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxGlobalMemCacheLineSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].GlobalMemCacheLineSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].GlobalMemCacheLineSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxGlobalMemCacheSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_ulong;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].GlobalMemCacheSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].GlobalMemCacheSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxGlobalMemSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_ulong;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].GlobalMemSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].GlobalMemSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxImage2DWidth: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].Image2DMaxWidth;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].Image2DMaxWidth; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxImage2DHeight: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].Image2DMaxHeight;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].Image2DMaxHeight; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxImage3DWidth: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].Image3DMaxWidth;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].Image3DMaxWidth; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxImage3DHeight: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].Image3DMaxHeight;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].Image3DMaxHeight; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxImage3DDepth: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].Image3DMaxDepth;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].Image3DMaxDepth; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxLocalMemSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_ulong;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].LocalMemSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].LocalMemSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxMemAllocSize: PDCLDevice;
var I, Best: Integer; V, M: TCL_ulong;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxMemAllocSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxMemAllocSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxParameterSize: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxParameterSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxParameterSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxReadImageArgs: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxReadImageArgs;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxReadImageArgs; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxSamplers: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxSamplers;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxSamplers; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxWorkGroupSize: PDCLDevice;
var I, Best: Integer; V, M: TSize_t;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxWorkGroupSize;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxWorkGroupSize; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxWorkItemDimensions: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxWorkItemDimensions;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxWorkItemDimensions; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

function TDCLPlatform.GetDeviceWithMaxWriteImageArgs: PDCLDevice;
var I, Best: Integer; V, M: TCL_uint;
begin
  Result := nil; if FDeviceCount = 0 then Exit; Best := 0; M := FDevices[0].MaxWriteImageArgs;
  for I := 1 to Integer(FDeviceCount)-1 do begin V := FDevices[I].MaxWriteImageArgs; if V > M then begin M := V; Best := I; end; end;
  Result := @FDevices[Best];
end;

constructor TDCLDevice.Create(Device_id: PCL_device_id);
var
  DeviceType: TCL_device_type;
  FPConfig: TCL_device_fp_config;
  ExecCaps: TCL_device_exec_capabilities;
  CacheType: TCL_device_mem_cache_type;
  LocalType: TCL_device_local_mem_type;
  Ext, Token: AnsiString;
  P, StartPos: Integer;
begin
  inherited Create;
  if Device_id = nil then
    raise Exception.Create('TDCLDevice.Create: Device_id = nil.');

  FDevice_id := Device_id;
  FStatus := CL_SUCCESS;

  FName := DCLGetDeviceString(FDevice_id, CL_DEVICE_NAME, 'CL_DEVICE_NAME');
  FVendor := DCLGetDeviceString(FDevice_id, CL_DEVICE_VENDOR, 'CL_DEVICE_VENDOR');
  FVersion := DCLGetDeviceString(FDevice_id, CL_DEVICE_VERSION, 'CL_DEVICE_VERSION');
  FProfile := DCLGetDeviceString(FDevice_id, CL_DEVICE_PROFILE, 'CL_DEVICE_PROFILE');
  FDriverVersion := DCLGetDeviceString(FDevice_id, CL_DRIVER_VERSION, 'CL_DRIVER_VERSION');
  FOpenCLCVersion := DCLGetDeviceString(FDevice_id, CL_DEVICE_OPENCL_C_VERSION, 'CL_DEVICE_OPENCL_C_VERSION');
  FExtensionsString := DCLGetDeviceString(FDevice_id, CL_DEVICE_EXTENSIONS, 'CL_DEVICE_EXTENSIONS');

  DeviceType := DCLGetDeviceBitfield(FDevice_id, CL_DEVICE_TYPE);
  FIsCPU := (DeviceType and CL_DEVICE_TYPE_CPU) <> 0;
  FIsGPU := (DeviceType and CL_DEVICE_TYPE_GPU) <> 0;
  FIsAccelerator := (DeviceType and CL_DEVICE_TYPE_ACCELERATOR) <> 0;
  FIsDefault := (DeviceType and CL_DEVICE_TYPE_DEFAULT) <> 0;

  FMaxWorkGroupSize := DCLGetDeviceSize(FDevice_id, CL_DEVICE_MAX_WORK_GROUP_SIZE);
  FNativeVectorPreferredChar := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR);
  FNativeVectorPreferredShort := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT);
  FNativeVectorPreferredInt := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT);
  FNativeVectorPreferredLong := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG);
  FNativeVectorPreferredFloat := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT);
  FNativeVectorPreferredDouble := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE);
  FNativeVectorPreferredHalf := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF);
  FNativeVectorWidthChar := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR);
  FNativeVectorWidthShort := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT);
  FNativeVectorWidthInt := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_INT);
  FNativeVectorWidthLong := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG);
  FNativeVectorWidthFloat := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT);
  FNativeVectorWidthDouble := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE);
  FNativeVectorWidthHalf := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF);
  FMaxClockFrequency := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_CLOCK_FREQUENCY);
  FAddressBits := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_ADDRESS_BITS);
  FMaxMemAllocSize := DCLGetDeviceULong(FDevice_id, CL_DEVICE_MAX_MEM_ALLOC_SIZE);
  FIsImageSupport := DCLGetDeviceBool(FDevice_id, CL_DEVICE_IMAGE_SUPPORT);
  FMaxReadImageArgs := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_READ_IMAGE_ARGS);
  FMaxWriteImageArgs := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_WRITE_IMAGE_ARGS);
  FImage2DMaxWidth := DCLGetDeviceSize(FDevice_id, CL_DEVICE_IMAGE2D_MAX_WIDTH);
  FImage2DMaxHeight := DCLGetDeviceSize(FDevice_id, CL_DEVICE_IMAGE2D_MAX_HEIGHT);
  FImage3DMaxWidth := DCLGetDeviceSize(FDevice_id, CL_DEVICE_IMAGE3D_MAX_WIDTH);
  FImage3DMaxHeight := DCLGetDeviceSize(FDevice_id, CL_DEVICE_IMAGE3D_MAX_HEIGHT);
  FImage3DMaxDepth := DCLGetDeviceSize(FDevice_id, CL_DEVICE_IMAGE3D_MAX_DEPTH);
  FMaxSamplers := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_SAMPLERS);
  FMaxParameterSize := DCLGetDeviceSize(FDevice_id, CL_DEVICE_MAX_PARAMETER_SIZE);
  FMemBaseAddrAlign := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MEM_BASE_ADDR_ALIGN);
  FMinDataTypeAlignSize := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MIN_DATA_TYPE_ALIGN_SIZE);
  FGlobalMemCacheLineSize := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE);
  FGlobalMemCacheSize := DCLGetDeviceULong(FDevice_id, CL_DEVICE_GLOBAL_MEM_CACHE_SIZE);
  FGlobalMemSize := DCLGetDeviceULong(FDevice_id, CL_DEVICE_GLOBAL_MEM_SIZE);
  FMaxConstantBufferSize := DCLGetDeviceULong(FDevice_id, CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE);
  FMaxConstantArgs := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_CONSTANT_ARGS);
  FLocalMemSize := DCLGetDeviceULong(FDevice_id, CL_DEVICE_LOCAL_MEM_SIZE);
  FIsErrorCorrectionSupport := DCLGetDeviceBool(FDevice_id, CL_DEVICE_ERROR_CORRECTION_SUPPORT);
  FIsHostUnifiedMemory := DCLGetDeviceBool(FDevice_id, CL_DEVICE_HOST_UNIFIED_MEMORY);
  FProfilingTimerResolution := DCLGetDeviceSize(FDevice_id, CL_DEVICE_PROFILING_TIMER_RESOLUTION);
  FIsEndianLittle := DCLGetDeviceBool(FDevice_id, CL_DEVICE_ENDIAN_LITTLE);
  FIsAvailable := DCLGetDeviceBool(FDevice_id, CL_DEVICE_AVAILABLE);
  FIsCompilerAvailable := DCLGetDeviceBool(FDevice_id, CL_DEVICE_COMPILER_AVAILABLE);
  FVendorId := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_VENDOR_ID);
  FMaxComputeUnits := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_COMPUTE_UNITS);
  FMaxWorkItemDimensions := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS);

  FPConfig := DCLGetDeviceBitfield(FDevice_id, CL_DEVICE_SINGLE_FP_CONFIG);
  FFPConfigSet := [];
  if (FPConfig and CL_FP_DENORM) <> 0 then Include(FFPConfigSet, dfpcDenorm);
  if (FPConfig and CL_FP_INF_NAN) <> 0 then Include(FFPConfigSet, dfpcInfNan);
  if (FPConfig and CL_FP_ROUND_TO_NEAREST) <> 0 then Include(FFPConfigSet, dfpcRoundToNearest);
  if (FPConfig and CL_FP_ROUND_TO_ZERO) <> 0 then Include(FFPConfigSet, dfpcRoundToZero);
  if (FPConfig and CL_FP_ROUND_TO_INF) <> 0 then Include(FFPConfigSet, dfpcRoundToInf);
  if (FPConfig and CL_FP_FMA) <> 0 then Include(FFPConfigSet, dfpcFMA);
  {$IFDEF CL_VERSION_1_1}
  if (FPConfig and CL_FP_SOFT_FLOAT) <> 0 then Include(FFPConfigSet, dfpcSoftFloat);
  {$ENDIF}
  {$IFDEF CL_VERSION_1_2}
  if (FPConfig and CL_FP_CORRECTLY_ROUNDED_DIVIDE_SQRT) <> 0 then Include(FFPConfigSet, dfpcCorrectlyRoundedDivideSqrt);
  {$ENDIF}

  ExecCaps := DCLGetDeviceBitfield(FDevice_id, CL_DEVICE_EXECUTION_CAPABILITIES);
  FExecutionCapabilities := [];
  if (ExecCaps and CL_EXEC_KERNEL) <> 0 then Include(FExecutionCapabilities, decExecKernel);
  if (ExecCaps and CL_EXEC_NATIVE_KERNEL) <> 0 then Include(FExecutionCapabilities, decExecNativeKernel);

  CacheType := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_GLOBAL_MEM_CACHE_TYPE);
  case CacheType of
    CL_READ_ONLY_CACHE: FGlobalMemCacheType := dmctReadOnlyCache;
    CL_READ_WRITE_CACHE: FGlobalMemCacheType := dmctWriteOnlyCache;
  else
    FGlobalMemCacheType := dmctNone;
  end;

  LocalType := DCLGetDeviceUInt(FDevice_id, CL_DEVICE_LOCAL_MEM_TYPE);
  if LocalType = CL_GLOBAL then FLocalMemType := dlmtGlobal else FLocalMemType := dlmtLocal;

  Ext := FExtensionsString + ' ';
  StartPos := 1;
  FExtensionsCount := 0;
  SetLength(FExtensions, 0);
  for P := 1 to Length(Ext) do
  begin
    if (Ext[P] = ' ') or (Ext[P] = #0) then
    begin
      Token := Copy(Ext, StartPos, P - StartPos);
      if Token <> '' then
      begin
        Inc(FExtensionsCount);
        SetLength(FExtensions, FExtensionsCount);
        FExtensions[FExtensionsCount - 1] := UpperCase(Token);
      end;
      StartPos := P + 1;
    end;
  end;
end;

destructor TDCLDevice.Destroy;
begin
  if FContext <> nil then FreeAndNil(FContext);
  SetLength(FExtensions, 0);
  inherited Destroy;
end;

function TDCLDevice.GetExtensions(const Index: TSize_t): AnsiString;
begin
  if Index < FExtensionsCount then Result := FExtensions[Index] else Result := '';
end;

function TDCLDevice.IsPresentExtension(const ExtensionName: AnsiString): Boolean;
var
  I: Integer;
  Name: AnsiString;
begin
  Result := False;
  Name := UpperCase(ExtensionName);
  for I := 0 to High(FExtensions) do
    if FExtensions[I] = Name then Exit(True);
end;

function TDCLDevice.IsPresentInFPConfig(const FPConfig: TDCLDeviceFPConfig): Boolean;
begin
  Result := FPConfig in FFPConfigSet;
end;

function TDCLDevice.CreateContext: TDCLContext;
begin
  if FContext <> nil then FreeAndNil(FContext);
  FContext := TDCLContext.Create(FDevice_id);
  Result := FContext;
end;

function TDCLDevice.CreateCommandQueue(const properties: TDCLCommandQueuePropertiesSet): TDCLCommandQueue;
begin
  if FContext = nil then CreateContext;
  Result := TDCLCommandQueue.Create(FDevice_id, FContext.FContext, properties);
end;

function TDCLDevice.CreateCommandQueue(const Context: TDCLContext; const properties: TDCLCommandQueuePropertiesSet): TDCLCommandQueue;
begin
  if Context = nil then raise Exception.Create('TDCLDevice.CreateCommandQueue: Context = nil.');
  Result := TDCLCommandQueue.Create(FDevice_id, Context.FContext, properties);
end;

function TDCLDevice.CreateBuffer(const Size: TSize_t; const Data: Pointer; const flags: TDCLMemFlagsSet): TDCLBuffer;
begin
  if FContext = nil then CreateContext;
  Result := TDCLBuffer.Create(FContext.FContext, flags, Size, Data);
end;

function TDCLDevice.CreateImage2D(const Format: PCL_image_format; const Width, Height, RowPitch: TSize_t; const Data: Pointer; const flags: TDCLMemFlagsSet): TDCLImage2D;
begin
  if FContext = nil then CreateContext;
  Result := TDCLImage2D.Create(FContext.FContext, flags, Format, Width, Height, RowPitch, Data);
end;

function TDCLDevice.CreateProgram(const Source: PPAnsiChar; const Options: PAnsiChar): TDCLProgram;
begin
  if FContext = nil then CreateContext;
  Result := TDCLProgram.Create(FDevice_id, FContext.FContext, Source, Options);
end;

function TDCLDevice.CreateProgram(const FileName: String; const Options: PAnsiChar): TDCLProgram;
var
  S: AnsiString;
  F: File;
  Size: Integer;
  P: PAnsiChar;
begin
  if not FileExists(FileName) then
    raise Exception.Create('TDCLDevice.CreateProgram: plik nie istnieje: ' + FileName);
  AssignFile(F, FileName);
  Reset(F, 1);
  try
    Size := FileSize(F);
    SetLength(S, Size);
    if Size > 0 then BlockRead(F, S[1], Size);
  finally
    CloseFile(F);
  end;
  P := PAnsiChar(S);
  Result := CreateProgram(@P, Options);
end;

constructor TDCLContext.Create(Device_id: PCL_device_id);
begin
  inherited Create;
  if Device_id = nil then raise Exception.Create('TDCLContext.Create: Device_id = nil.');
  if not Assigned(clCreateContext) then DCLCheckAssigned(nil, 'clCreateContext');
  FContext := clCreateContext(nil, 1, @Device_id, nil, nil, @FStatus);
  DCLCheck('clCreateContext', FStatus);
  if FContext = nil then raise Exception.Create('clCreateContext zwrocil nil.');
  if Assigned(clGetContextInfo) then
  begin
    FStatus := clGetContextInfo(FContext, CL_CONTEXT_NUM_DEVICES, SizeOf(FNumDevices), @FNumDevices, nil);
    DCLCheck('clGetContextInfo(CL_CONTEXT_NUM_DEVICES)', FStatus);
  end;
end;

destructor TDCLContext.Destroy;
begin
  if (FContext <> nil) and Assigned(clReleaseContext) then
  begin
    FStatus := clReleaseContext(FContext);
    FContext := nil;
  end;
  inherited Destroy;
end;

constructor TDCLCommandQueue.Create(const Device_Id: PCL_device_id; const Context: PCL_context; const Properties: TDCLCommandQueuePropertiesSet);
var
  Props: TCL_command_queue_properties;
begin
  inherited Create;
  if Device_Id = nil then raise Exception.Create('TDCLCommandQueue.Create: Device_Id = nil.');
  if Context = nil then raise Exception.Create('TDCLCommandQueue.Create: Context = nil.');
  Props := 0;
  if cqpOutOfOrderExecModeEnable in Properties then Props := Props or CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE;
  {$IFDEF PROFILING}
  Props := Props or CL_QUEUE_PROFILING_ENABLE;
  {$ENDIF}
  FCommandQueue := clCreateCommandQueue(Context, Device_Id, Props, @FStatus);
  DCLCheck('clCreateCommandQueue', FStatus);
  if FCommandQueue = nil then raise Exception.Create('clCreateCommandQueue zwrocil nil.');
  FProperties := Properties;
end;

destructor TDCLCommandQueue.Destroy;
begin
  if (FCommandQueue <> nil) and Assigned(clReleaseCommandQueue) then
  begin
    FStatus := clReleaseCommandQueue(FCommandQueue);
    FCommandQueue := nil;
  end;
  inherited Destroy;
end;

constructor TDCLBuffer.Create(const Context: PCL_context; const Flags: TDCLMemFlagsSet; const Size: TSize_t; const Data: Pointer);
var
  Fgs: TCL_mem_flags;
begin
  inherited Create;
  if Context = nil then raise Exception.Create('TDCLBuffer.Create: Context = nil.');
  if Size = 0 then raise Exception.Create('TDCLBuffer.Create: Size = 0.');
  Fgs := 0;
  if mfReadWrite in Flags then Fgs := Fgs or CL_MEM_READ_WRITE;
  if mfWriteOnly in Flags then Fgs := Fgs or CL_MEM_WRITE_ONLY;
  if mfReadOnly in Flags then Fgs := Fgs or CL_MEM_READ_ONLY;
  if mfUseHostPtr in Flags then Fgs := Fgs or CL_MEM_USE_HOST_PTR;
  if mfAllocHostPtr in Flags then Fgs := Fgs or CL_MEM_ALLOC_HOST_PTR;
  if mfCopyHostPtr in Flags then Fgs := Fgs or CL_MEM_COPY_HOST_PTR;
  if ((mfUseHostPtr in Flags) or (mfCopyHostPtr in Flags)) and (Data = nil) then
    raise Exception.Create('TDCLBuffer.Create: flags wymagaja Data <> nil.');
  FMem := clCreateBuffer(Context, Fgs, Size, Data, @FStatus);
  DCLCheck('clCreateBuffer', FStatus);
  if FMem = nil then raise Exception.Create('clCreateBuffer zwrocil nil.');
  FSize := Size;
end;

destructor TDCLBuffer.Destroy;
begin
  if (FMem <> nil) and Assigned(clReleaseMemObject) then
  begin
    FStatus := clReleaseMemObject(FMem);
    FMem := nil;
  end;
  inherited Destroy;
end;

procedure TDCLCommandQueue.Execute(const Kernel: TDCLKernel; const Size: TSize_t);
{$IFDEF PROFILING}
var
  TimingEvent: PCL_event;
{$ENDIF}
begin
  if Kernel = nil then raise Exception.Create('TDCLCommandQueue.Execute: Kernel = nil.');
  if Kernel.FKernel = nil then raise Exception.Create('TDCLCommandQueue.Execute: Kernel.FKernel = nil.');
  if Size = 0 then raise Exception.Create('TDCLCommandQueue.Execute: Size = 0.');
  {$IFDEF PROFILING}TimingEvent := nil;{$ENDIF}
  FStatus := clEnqueueNDRangeKernel(FCommandQueue, Kernel.FKernel, 1, nil, @Size, nil, 0, nil, {$IFDEF PROFILING}@TimingEvent{$ELSE}nil{$ENDIF});
  DCLCheck('clEnqueueNDRangeKernel(1D)', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
  {$IFDEF PROFILING}
  if (TimingEvent <> nil) and Assigned(clReleaseEvent) then clReleaseEvent(TimingEvent);
  {$ENDIF}
end;

procedure TDCLCommandQueue.Execute(const Kernel: TDCLKernel; const Size: array of TSize_t);
{$IFDEF PROFILING}
var
  TimingEvent: PCL_event;
{$ENDIF}
begin
  if Kernel = nil then raise Exception.Create('TDCLCommandQueue.Execute: Kernel = nil.');
  if Kernel.FKernel = nil then raise Exception.Create('TDCLCommandQueue.Execute: Kernel.FKernel = nil.');
  if Length(Size) = 0 then raise Exception.Create('TDCLCommandQueue.Execute: puste wymiary NDRange.');
  {$IFDEF PROFILING}TimingEvent := nil;{$ENDIF}
  FStatus := clEnqueueNDRangeKernel(FCommandQueue, Kernel.FKernel, TCL_uint(Length(Size)), nil, @Size[0], nil, 0, nil, {$IFDEF PROFILING}@TimingEvent{$ELSE}nil{$ENDIF});
  DCLCheck('clEnqueueNDRangeKernel(ND)', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
  {$IFDEF PROFILING}
  if (TimingEvent <> nil) and Assigned(clReleaseEvent) then clReleaseEvent(TimingEvent);
  {$ENDIF}
end;

procedure TDCLCommandQueue.ReadBuffer(const Buffer: TDCLBuffer; const Size: TSize_t; const Data: Pointer);
begin
  if Buffer = nil then raise Exception.Create('TDCLCommandQueue.ReadBuffer: Buffer = nil.');
  if Buffer.FMem = nil then raise Exception.Create('TDCLCommandQueue.ReadBuffer: Buffer.FMem = nil.');
  if (Size > 0) and (Data = nil) then raise Exception.Create('TDCLCommandQueue.ReadBuffer: Data = nil.');
  if Size > Buffer.Size then raise Exception.Create('TDCLCommandQueue.ReadBuffer: Size > Buffer.Size.');
  FStatus := clEnqueueReadBuffer(FCommandQueue, Buffer.FMem, CL_TRUE, 0, Size, Data, 0, nil, nil);
  DCLCheck('clEnqueueReadBuffer', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
end;

procedure TDCLCommandQueue.WriteBuffer(const Buffer: TDCLBuffer; const Size: TSize_t; const Data: Pointer);
begin
  if Buffer = nil then raise Exception.Create('TDCLCommandQueue.WriteBuffer: Buffer = nil.');
  if Buffer.FMem = nil then raise Exception.Create('TDCLCommandQueue.WriteBuffer: Buffer.FMem = nil.');
  if (Size > 0) and (Data = nil) then raise Exception.Create('TDCLCommandQueue.WriteBuffer: Data = nil.');
  if Size > Buffer.Size then raise Exception.Create('TDCLCommandQueue.WriteBuffer: Size > Buffer.Size.');
  FStatus := clEnqueueWriteBuffer(FCommandQueue, Buffer.FMem, CL_TRUE, 0, Size, Data, 0, nil, nil);
  DCLCheck('clEnqueueWriteBuffer', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
end;

procedure TDCLCommandQueue.ReadImage2D(const Image: TDCLImage2D; const Data: Pointer);
var
  Origin, Region: TSizet;
begin
  if Image = nil then raise Exception.Create('TDCLCommandQueue.ReadImage2D: Image = nil.');
  if Image.FMem = nil then raise Exception.Create('TDCLCommandQueue.ReadImage2D: Image.FMem = nil.');
  if Data = nil then raise Exception.Create('TDCLCommandQueue.ReadImage2D: Data = nil.');
  FillChar(Origin, SizeOf(Origin), 0);
  FillChar(Region, SizeOf(Region), 0);
  Region[0] := Image.Width; Region[1] := Image.Height; Region[2] := 1;
  FStatus := clEnqueueReadImage(FCommandQueue, Image.FMem, CL_TRUE, @Origin, @Region, 0, 0, Data, 0, nil, nil);
  DCLCheck('clEnqueueReadImage', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
end;

procedure TDCLCommandQueue.WriteImage2D(const Image: TDCLImage2D; const Width, Height: TSize_t; const Data: Pointer);
var
  Origin, Region: TSizet;
begin
  if Image = nil then raise Exception.Create('TDCLCommandQueue.WriteImage2D: Image = nil.');
  if Image.FMem = nil then raise Exception.Create('TDCLCommandQueue.WriteImage2D: Image.FMem = nil.');
  if Data = nil then raise Exception.Create('TDCLCommandQueue.WriteImage2D: Data = nil.');
  FillChar(Origin, SizeOf(Origin), 0);
  FillChar(Region, SizeOf(Region), 0);
  Region[0] := Width; Region[1] := Height; Region[2] := 1;
  FStatus := clEnqueueWriteImage(FCommandQueue, Image.FMem, CL_TRUE, @Origin, @Region, 0, 0, Data, 0, nil, nil);
  DCLCheck('clEnqueueWriteImage', FStatus);
  FStatus := clFinish(FCommandQueue);
  DCLCheck('clFinish', FStatus);
end;

constructor TDCLProgram.Create(const Device: PCL_device_id; const Context: PCL_context; const Source: PPAnsiChar; const Options: PAnsiChar);
var
  Size: TSize_t;
  BinaryPtr: PAnsiChar;
begin
  inherited Create;
  if Device = nil then raise Exception.Create('TDCLProgram.Create: Device = nil.');
  if Context = nil then raise Exception.Create('TDCLProgram.Create: Context = nil.');
  if Source = nil then raise Exception.Create('TDCLProgram.Create: Source = nil.');
  FProgram := clCreateProgramWithSource(Context, 1, Source, nil, @FStatus);
  DCLCheck('clCreateProgramWithSource', FStatus);
  if FProgram = nil then raise Exception.Create('clCreateProgramWithSource zwrocil nil.');

  FStatus := clBuildProgram(FProgram, 1, @Device, Options, nil, nil);

  Size := 0;
  if Assigned(clGetProgramBuildInfo) then
  begin
    if clGetProgramBuildInfo(FProgram, Device, CL_PROGRAM_BUILD_LOG, 0, nil, @Size) = CL_SUCCESS then
    begin
      SetLength(FLog, Size);
      if Size > 0 then clGetProgramBuildInfo(FProgram, Device, CL_PROGRAM_BUILD_LOG, Size, @FLog[1], nil);
      FLog := DCLTrimNull(FLog);
    end;
  end;

  if FStatus <> CL_SUCCESS then
    raise Exception.Create('clBuildProgram failed: ' + String(GetString(FStatus)) + ' (' + IntToStr(FStatus) + ')' + sLineBreak + String(FLog));

  Size := 0;
  if Assigned(clGetProgramInfo) and (clGetProgramInfo(FProgram, CL_PROGRAM_SOURCE, 0, nil, @Size) = CL_SUCCESS) and (Size > 0) then
  begin
    FSource := GetMemory(Size + 1);
    FillChar(FSource^, Size + 1, 0);
    FStatus := clGetProgramInfo(FProgram, CL_PROGRAM_SOURCE, Size, FSource, nil);
    DCLCheck('clGetProgramInfo(CL_PROGRAM_SOURCE)', FStatus);
  end;

  FBinarySizes := 0;
  if Assigned(clGetProgramInfo) and (clGetProgramInfo(FProgram, CL_PROGRAM_BINARY_SIZES, SizeOf(FBinarySizes), @FBinarySizes, nil) = CL_SUCCESS) and (FBinarySizes > 0) then
  begin
    SetLength(FBinaries, 1, FBinarySizes);
    BinaryPtr := @FBinaries[0][0];
    FStatus := clGetProgramInfo(FProgram, CL_PROGRAM_BINARIES, SizeOf(BinaryPtr), @BinaryPtr, nil);
    if FStatus <> CL_SUCCESS then
    begin
      FBinarySizes := 0;
      SetLength(FBinaries, 0, 0);
    end;
  end;
end;

destructor TDCLProgram.Destroy;
begin
  if (FProgram <> nil) and Assigned(clReleaseProgram) then
  begin
    FStatus := clReleaseProgram(FProgram);
    FProgram := nil;
  end;
  if FSource <> nil then
  begin
    FreeMem(FSource);
    FSource := nil;
  end;
  FBinarySizes := 0;
  SetLength(FBinaries, 0, 0);
  inherited Destroy;
end;

function TDCLProgram.CreateKernel(const KernelName: PAnsiChar): TDCLKernel;
begin
  Result := TDCLKernel.Create(FProgram, KernelName);
end;

procedure TDCLProgram.SaveToFile(const FileName: AnsiString);
var
  F: File;
begin
  if (FBinarySizes = 0) or (Length(FBinaries) = 0) or (Length(FBinaries[0]) = 0) then
    raise Exception.Create('TDCLProgram.SaveToFile: brak binarki programu OpenCL.');
  AssignFile(F, String(FileName));
  Rewrite(F, 1);
  try
    BlockWrite(F, FBinaries[0][0], FBinarySizes);
  finally
    CloseFile(F);
  end;
end;

constructor TDCLKernel.Create(const Program_: PCL_program; const KernelName: PAnsiChar);
begin
  inherited Create;
  if Program_ = nil then raise Exception.Create('TDCLKernel.Create: Program = nil.');
  if KernelName = nil then raise Exception.Create('TDCLKernel.Create: KernelName = nil.');
  FKernel := clCreateKernel(Program_, KernelName, @FStatus);
  DCLCheck('clCreateKernel(' + AnsiString(KernelName) + ')', FStatus);
  if FKernel = nil then raise Exception.Create('clCreateKernel zwrocil nil.');
end;

destructor TDCLKernel.Destroy;
begin
  if (FKernel <> nil) and Assigned(clReleaseKernel) then
  begin
    FStatus := clReleaseKernel(FKernel);
    FKernel := nil;
  end;
  inherited Destroy;
end;

function TDCLKernel.GetFunctionName: AnsiString;
var
  Size: TSize_t;
begin
  Result := '';
  if FKernel = nil then Exit;
  Size := 0;
  FStatus := clGetKernelInfo(FKernel, CL_KERNEL_FUNCTION_NAME, 0, nil, @Size);
  DCLCheck('clGetKernelInfo(CL_KERNEL_FUNCTION_NAME size)', FStatus);
  if Size = 0 then Exit;
  SetLength(Result, Size);
  FStatus := clGetKernelInfo(FKernel, CL_KERNEL_FUNCTION_NAME, Size, @Result[1], nil);
  DCLCheck('clGetKernelInfo(CL_KERNEL_FUNCTION_NAME data)', FStatus);
  Result := DCLTrimNull(Result);
end;

function TDCLKernel.GetNumArgs: TCL_uint;
begin
  Result := 0;
  if FKernel = nil then Exit;
  FStatus := clGetKernelInfo(FKernel, CL_KERNEL_NUM_ARGS, SizeOf(Result), @Result, nil);
  DCLCheck('clGetKernelInfo(CL_KERNEL_NUM_ARGS)', FStatus);
end;

procedure TDCLKernel.SetArg(const Index: TCL_uint; const Size: TSize_t; const Value: Pointer);
begin
  if FKernel = nil then raise Exception.Create('TDCLKernel.SetArg: FKernel = nil.');
  if (Size > 0) and (Value = nil) then raise Exception.Create('TDCLKernel.SetArg: Value = nil.');
  FStatus := clSetKernelArg(FKernel, Index, Size, Value);
  DCLCheck('clSetKernelArg(' + IntToStr(Index) + ')', FStatus);
end;

procedure TDCLKernel.SetArg(const Index: TCL_uint; const Value: TDCLBuffer);
begin
  if Value = nil then raise Exception.Create('TDCLKernel.SetArg(Buffer): Buffer = nil.');
  if Value.FMem = nil then raise Exception.Create('TDCLKernel.SetArg(Buffer): Buffer.FMem = nil.');
  SetArg(Index, SizeOf(Value.FMem), @Value.FMem);
end;

procedure TDCLKernel.SetArg(const Index: TCL_uint; const Value: TDCLImage2D);
begin
  if Value = nil then raise Exception.Create('TDCLKernel.SetArg(Image2D): Image = nil.');
  if Value.FMem = nil then raise Exception.Create('TDCLKernel.SetArg(Image2D): Image.FMem = nil.');
  SetArg(Index, SizeOf(Value.FMem), @Value.FMem);
end;

constructor TDCLImage2D.Create(const Context: PCL_context; const Flags: TDCLMemFlagsSet; const Format: PCL_image_format; const Width, Height, RowPitch: TSize_t; const Data: Pointer);
var
  Fgs: TCL_mem_flags;
begin
  inherited Create;
  if Context = nil then raise Exception.Create('TDCLImage2D.Create: Context = nil.');
  if Format = nil then raise Exception.Create('TDCLImage2D.Create: Format = nil.');
  if (Width = 0) or (Height = 0) then raise Exception.Create('TDCLImage2D.Create: Width/Height = 0.');
  Fgs := 0;
  if mfReadWrite in Flags then Fgs := Fgs or CL_MEM_READ_WRITE;
  if mfWriteOnly in Flags then Fgs := Fgs or CL_MEM_WRITE_ONLY;
  if mfReadOnly in Flags then Fgs := Fgs or CL_MEM_READ_ONLY;
  if mfUseHostPtr in Flags then Fgs := Fgs or CL_MEM_USE_HOST_PTR;
  if mfAllocHostPtr in Flags then Fgs := Fgs or CL_MEM_ALLOC_HOST_PTR;
  if mfCopyHostPtr in Flags then Fgs := Fgs or CL_MEM_COPY_HOST_PTR;
  FFormat := Format^;
  FWidth := Width;
  FHeight := Height;
  FRowPitch := RowPitch;
  {$IFDEF CL_USE_DEPRECATED_OPENCL_1_1_APIS}
  if not Assigned(clCreateImage2D) then DCLCheckAssigned(nil, 'clCreateImage2D');
  FMem := clCreateImage2D(Context, Fgs, @FFormat, Width, Height, RowPitch, Data, @FStatus);
  DCLCheck('clCreateImage2D', FStatus);
  if FMem = nil then raise Exception.Create('clCreateImage2D zwrocil nil.');
  {$ELSE}
  raise Exception.Create('TDCLImage2D.Create: clCreateImage2D jest deprecated i nie jest wlaczone w OpenCL.inc. Do AvoTensor nie jest potrzebne.');
  {$ENDIF}
end;

destructor TDCLImage2D.Destroy;
begin
  if (FMem <> nil) and Assigned(clReleaseMemObject) then
  begin
    FStatus := clReleaseMemObject(FMem);
    FMem := nil;
  end;
  inherited Destroy;
end;

{$IFDEF LOGGING}
initialization
  AssignFile(DCLFileLOG, ExtractFilePath(ParamStr(0)) + 'DELPHI_LOG.log');
  Rewrite(DCLFileLOG);
finalization
  CloseFile(DCLFileLOG);
{$ENDIF}
end.


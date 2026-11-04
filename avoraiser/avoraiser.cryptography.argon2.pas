unit avoraiser.cryptography.argon2;
{$mode objfpc}{$H+}

interface

uses
  SysUtils, Windows;

type
  TArgon2Params = record
    TimeCost:    Cardinal;
    MemoryCost:  Cardinal;
    Parallelism: Cardinal;
    HashLength:  Cardinal;
    SaltLength:  Cardinal;
  end;

  TArgon2Config = record
    Params: TArgon2Params;
    Pepper: TBytes;
  end;

  TVerifyResult = record
    IsValid:     Boolean;
    NeedsRehash: Boolean;
    NewHash:     string;
  end;

  TMemLockMode = (
    mlmBestEffort,   // domyślny: błąd VirtualLock ignorowany (fallback = SecureZero)
    mlmStrict        // błąd VirtualLock = wyjątek (środowiska wysokiego bezpieczeństwa)
  );

const
  ARGON2_OK              =  0;
  ARGON2_ID              =  2;
  ARGON2_VERIFY_MISMATCH = -35;

  MIN_TIME_COST    = 2;      MAX_TIME_COST    = 100;
  MIN_MEMORY_COST  = 65536;  MAX_MEMORY_COST  = 262144;
  MIN_PARALLELISM  = 1;      MAX_PARALLELISM  = 16;
  MIN_HASH_LENGTH  = 16;     MAX_HASH_LENGTH  = 128;
  MIN_SALT_LENGTH  = 16;     MAX_SALT_LENGTH  = 64;
  MAX_PASSWORD_LENGTH = 1024;

procedure Argon2_LoadPepperFromEnv(var Config: TArgon2Config; const EnvVarName: string);
procedure Argon2_ClearPepper(var Config: TArgon2Config);

function  Argon2_DefaultParams: TArgon2Params;
function  Argon2_DefaultConfig: TArgon2Config;
function  HashPassword(const Password: string; const Config: TArgon2Config; MemLock: TMemLockMode = mlmBestEffort): string;
function  VerifyPassword(const Password, EncodedHash: string; const Config: TArgon2Config; MemLock: TMemLockMode = mlmBestEffort): TVerifyResult;
procedure GenerateSalt(var Salt: TBytes; Len: Integer);

procedure SecureZeroAnsi(var S: AnsiString);
procedure SecureZeroBytes(var B: TBytes);
implementation

//  IMPORT: libargon2
function argon2id_hash_encoded(
  t_cost, m_cost, parallelism: UInt32;
  pwd: PAnsiChar; pwdlen: SizeUInt;
  salt: PByte;    saltlen: SizeUInt;
  hashlen: SizeUInt;
  encoded: PAnsiChar; encodedlen: SizeUInt
): Integer; cdecl; external 'argon2';

function argon2id_verify(
  encoded, pwd: PAnsiChar;
  pwdlen: SizeUInt
): Integer; cdecl; external 'argon2';

function argon2_encodedlen(
  t_cost, m_cost, parallelism: UInt32;
  saltlen, hashlen: UInt32;
  atype: Integer
): SizeUInt; cdecl; external 'argon2';


//  IMPORT: Windows BCryptGenRandom
const
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;

function BCryptGenRandom(
  hAlgorithm: Pointer;
  pbBuffer:   PByte;
  cbBuffer:   ULONG;
  dwFlags:    ULONG
): DWORD; stdcall; external 'bcrypt.dll';



//  Funkcje wewnętrzne (szczegóły implementacyjne)
var
  GlobalEmptyByte: Byte = 0;

function GetBytesPtrSafe(const B: TBytes): PByte;
begin
  if Length(B) > 0 then
    Result := @B[0]
  else
    Result := @GlobalEmptyByte;
end;

{$OPTIMIZATION OFF}
procedure SecureZeroAnsi(var S: AnsiString);
begin
  if Length(S) > 0 then FillChar(S[1], Length(S), 0);
end;

procedure SecureZeroBytes(var B: TBytes);
begin
  if Length(B) > 0 then FillChar(B[0], Length(B), 0);
end;
{$OPTIMIZATION ON}

procedure LockMemory(P: Pointer; Len: Integer; Mode: TMemLockMode);
var
  Ok: Boolean;
begin
  if (P = nil) or (Len <= 0) then Exit;

  Ok := VirtualLock(P, Len);

  if not Ok then
  begin
    {$IFDEF DEBUG}
    WriteLn(StdErr, '[Argon2] WARNING: VirtualLock failed (Len=', Len, ')');
    {$ENDIF}
    if Mode = mlmStrict then
      raise Exception.CreateFmt('LockMemory failed — tryb strict wymaga VirtualLock (rozmiar=%d)', [Len]);
  end;
end;

procedure UnlockMemory(P: Pointer; Len: Integer);
begin
  if (P = nil) or (Len <= 0) then Exit;
  VirtualUnlock(P, Len);
end;

// Walidacja i parametry domyślne
procedure ValidateParams(const Params: TArgon2Params);
  procedure CheckRange(const Name: string; Val, Lo, Hi: Cardinal);
  begin
    if Val < Lo then raise Exception.CreateFmt('%s zbyt niski: %d (min: %d)', [Name, Val, Lo]);
    if Val > Hi then raise Exception.CreateFmt('%s zbyt wysoki: %d (max: %d)', [Name, Val, Hi]);
  end;
begin
  CheckRange('TimeCost',    Params.TimeCost,    MIN_TIME_COST,    MAX_TIME_COST);
  CheckRange('MemoryCost',  Params.MemoryCost,  MIN_MEMORY_COST,  MAX_MEMORY_COST);
  CheckRange('Parallelism', Params.Parallelism, MIN_PARALLELISM,  MAX_PARALLELISM);
  CheckRange('HashLength',  Params.HashLength,  MIN_HASH_LENGTH,  MAX_HASH_LENGTH);
  CheckRange('SaltLength',  Params.SaltLength,  MIN_SALT_LENGTH,  MAX_SALT_LENGTH);
end;

function Argon2_DefaultParams: TArgon2Params;
begin
  Result.TimeCost    := 3;
  Result.MemoryCost  := 65536;
  Result.Parallelism := 2;
  Result.HashLength  := 32;
  Result.SaltLength  := 16;
end;

function Argon2_DefaultConfig: TArgon2Config;
begin
  Result.Params := Argon2_DefaultParams;
  SetLength(Result.Pepper, 0);
end;

procedure Argon2_ClearPepper(var Config: TArgon2Config);
begin
  if Length(Config.Pepper) > 0 then
  begin
    UnlockMemory(GetBytesPtrSafe(Config.Pepper), Length(Config.Pepper));
    SecureZeroBytes(Config.Pepper);
    SetLength(Config.Pepper, 0);
  end;
end;

procedure Argon2_LoadPepperFromEnv(var Config: TArgon2Config; const EnvVarName: string);
var
  Raw: string;
  A:   AnsiString;
begin
  Argon2_ClearPepper(Config);
  Raw := SysUtils.GetEnvironmentVariable(EnvVarName);
  if Raw = '' then
    raise Exception.CreateFmt('Pepper env var "%s" is empty or not set', [EnvVarName]);

  A := AnsiString(Raw);
  try
    SetLength(Config.Pepper, Length(A));
    Move(A[1], Config.Pepper[0], Length(A));
    LockMemory(GetBytesPtrSafe(Config.Pepper), Length(Config.Pepper), mlmBestEffort);
  finally
    SecureZeroAnsi(A);
  end;
end;


// Generowanie soli (tylko windows api)

procedure GenerateSalt(var Salt: TBytes; Len: Integer);
begin
  if Len <= 0 then
    raise Exception.Create('Salt length must be > 0');
  SetLength(Salt, Len);

  if BCryptGenRandom(nil, @Salt[0], Len, BCRYPT_USE_SYSTEM_PREFERRED_RNG) <> 0 then
    raise Exception.Create('BCryptGenRandom failed');
end;


// Ekstrakcja parametrów z hashu

function TryExtractParams(const Hash: string; out Params: TArgon2Params): Boolean;
var
  M, T, P, DollarPos: Integer;
begin
  Result := False;
  Params := Argon2_DefaultParams;

  M := Pos('m=', Hash);   T := Pos(',t=', Hash);
  P := Pos(',p=', Hash);
  if (M = 0) or (T = 0) or (P = 0) then Exit;

  DollarPos := Pos('$', Hash, P + 1);
  if DollarPos = 0 then Exit;

  Params.MemoryCost  := StrToIntDef(Copy(Hash, M+2, T-M-2),         0);
  Params.TimeCost    := StrToIntDef(Copy(Hash, T+3, P-T-3),         0);
  Params.Parallelism := StrToIntDef(Copy(Hash, P+3, DollarPos-P-3), 0);

  Result := (Params.MemoryCost > 0) and (Params.TimeCost > 0) and (Params.Parallelism > 0);
end;

function AnsiBufferToString(const Buf: AnsiString): string;
var
  NullPos: Integer;
begin
  if Length(Buf) = 0 then Exit('');

  NullPos := Pos(AnsiChar(#0), Buf);
  if NullPos > 0 then
    Result := string(Copy(Buf, 1, NullPos - 1))
  else
    Result := string(Buf);
end;

//  Główne operacje kryptograficzne

procedure BuildPwdBuffer(const Password: string; const Pepper: TBytes; var Buf: TBytes; Mode: TMemLockMode);
var
  PwdAnsi: AnsiString;
  PwdLen:  Integer;
begin
  if Length(Password) > MAX_PASSWORD_LENGTH then
    raise Exception.CreateFmt('Password too long: %d (max: %d)', [Length(Password), MAX_PASSWORD_LENGTH]);

  PwdAnsi := AnsiString(Password);
  PwdLen  := Length(PwdAnsi);

  SetLength(Buf, PwdLen + Length(Pepper));
  if PwdLen > 0 then         Move(PwdAnsi[1],  Buf[0],      PwdLen);
  if Length(Pepper) > 0 then Move(Pepper[0],   Buf[PwdLen], Length(Pepper));

  SecureZeroAnsi(PwdAnsi);

  if Length(Buf) > 0 then
    LockMemory(@Buf[0], Length(Buf), Mode);
end;

function InternalHash(const Password: string; const Config: TArgon2Config; Mode: TMemLockMode): string;
var
  Salt:       TBytes;
  Encoded:    AnsiString;
  PwdBuf:     TBytes;
  EncodedLen: SizeUInt;
  Res:        Integer;
begin
  ValidateParams(Config.Params);
  BuildPwdBuffer(Password, Config.Pepper, PwdBuf, Mode);
  try
    GenerateSalt(Salt, Config.Params.SaltLength);
    try
      EncodedLen := argon2_encodedlen(
        Config.Params.TimeCost, Config.Params.MemoryCost,
        Config.Params.Parallelism, Config.Params.SaltLength,
        Config.Params.HashLength, ARGON2_ID);
      if EncodedLen = 0 then
        raise Exception.Create('argon2_encodedlen returned 0');

      SetLength(Encoded, EncodedLen);

      Res := argon2id_hash_encoded(
        Config.Params.TimeCost, Config.Params.MemoryCost,
        Config.Params.Parallelism,
        PAnsiChar(GetBytesPtrSafe(PwdBuf)), Length(PwdBuf),
        @Salt[0],                           Length(Salt),
        Config.Params.HashLength,
        PAnsiChar(Encoded),                 EncodedLen);

      if Res <> ARGON2_OK then
        raise Exception.CreateFmt('Argon2 hashing failed. Code: %d', [Res]);

      Result := AnsiBufferToString(Encoded);
      SecureZeroAnsi(Encoded);

    finally
      SecureZeroBytes(Salt);
    end;
  finally
    if Length(PwdBuf) > 0 then
      UnlockMemory(@PwdBuf[0], Length(PwdBuf));
    SecureZeroBytes(PwdBuf);
  end;
end;

function HashPassword(const Password: string; const Config: TArgon2Config; MemLock: TMemLockMode): string;
begin
  Result := InternalHash(Password, Config, MemLock);
end;

function VerifyPassword(const Password, EncodedHash: string; const Config: TArgon2Config; MemLock: TMemLockMode): TVerifyResult;
var
  PwdBuf:        TBytes;
  HashAnsi:      AnsiString;
  Res:           Integer;
  CurrentParams: TArgon2Params;
begin
  Result.IsValid     := False;
  Result.NeedsRehash := False;
  Result.NewHash     := '';

  BuildPwdBuffer(Password, Config.Pepper, PwdBuf, MemLock);
  HashAnsi := AnsiString(EncodedHash);
  try
    Res := argon2id_verify(
      PAnsiChar(HashAnsi),
      PAnsiChar(GetBytesPtrSafe(PwdBuf)),
      Length(PwdBuf));
  finally
    SecureZeroAnsi(HashAnsi);
    if Length(PwdBuf) > 0 then
      UnlockMemory(@PwdBuf[0], Length(PwdBuf));
    SecureZeroBytes(PwdBuf);
  end;

  if Res = ARGON2_OK then
    Result.IsValid := True
  else if Res = ARGON2_VERIFY_MISMATCH then
    Result.IsValid := False
  else
    raise Exception.CreateFmt('Argon2 verify error (corrupted hash?). Code: %d', [Res]);

  if Result.IsValid and TryExtractParams(EncodedHash, CurrentParams) then
    if (CurrentParams.MemoryCost  < Config.Params.MemoryCost)  or
       (CurrentParams.TimeCost    < Config.Params.TimeCost)    or
       (CurrentParams.Parallelism < Config.Params.Parallelism) then
    begin
      Result.NeedsRehash := True;
      Result.NewHash     := InternalHash(Password, Config, MemLock);
    end;
end;

end.

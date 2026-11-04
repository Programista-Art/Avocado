unit avoraiser.cryptography;
{$mode ObjFPC}{$H+}

// OCHRONA ENDIANNESS: Format pliku i rzutowanie struktur opierają się na Little-Endian
{$IFDEF FPC_BIG_ENDIAN}
  {$FATAL 'Security Error: This module strictly requires a Little-Endian architecture.'}
{$ENDIF}

interface

uses
  Windows, SysUtils, Classes;

procedure encrypt_file_gcm(const input_path, output_path, password: string);
procedure decrypt_file_gcm(const input_path, output_path, password: string);

implementation

//NATYWNE TYPY I STRUKTURY CNG
type
  nt_status = LongInt;
  bcrypt_alg_handle = PVOID;
  bcrypt_key_handle = PVOID;

  //Wyrównanie struktury zgodne z ABI Windowsa (C-style) dla bezpieczeństwa na x64
  {$PUSH}
  {$PACKRECORDS C}
  TBCryptAuthenticatedCipherModeInfo = record
    cbSize: ULONG;
    dwInfoVersion: ULONG;
    pbNonce: PByte;
    cbNonce: ULONG;
    pbAuthData: PByte;
    cbAuthData: ULONG;
    pbTag: PByte;
    cbTag: ULONG;
    pbMacContext: PByte;
    cbMacContext: ULONG;
    cbAAD: ULONG;
    cbData: UInt64;
    dwFlags: ULONG;
  end;

  TBCryptAuthTagLengthsStruct = record
    dwMinLength: ULONG;
    dwMaxLength: ULONG;
    dwIncrement: ULONG;
  end;
  {$POP}

  // Wersjonowany, sztywny nagłówek pliku (46 bajtów)
  {$PACKRECORDS 1}
  TAvoHeader = packed record
    magic: array[0..3] of AnsiChar; // 'AVO1'
    algo_id: UInt8;                 // 1 = AES-256-GCM
    flags: UInt8;                   // Rezerwa na rozszerzenia (0 = domyślnie)
    kdf_iters: UInt32;              // PBKDF2 iterations
    chunk_size: UInt32;             // Rozmiar strumieniowania
    original_size: UInt64;          // Ochrona przed atakiem Truncation
    salt: array[0..15] of Byte;     // 16-byte KDF Salt
    base_iv: array[0..7] of Byte;   // 8-byte Base for GCM Nonce
  end;

const
  STATUS_SUCCESS = nt_status(0);
  STATUS_AUTH_TAG_MISMATCH = nt_status($C000A002);

  BCRYPT_AES_ALGORITHM = 'AES';
  BCRYPT_SHA256_ALGORITHM = 'SHA256';
  BCRYPT_CHAINING_MODE = 'ChainingMode';
  BCRYPT_CHAIN_MODE_GCM = 'ChainingModeGCM';
  BCRYPT_OBJECT_LENGTH = 'ObjectLength';
  BCRYPT_AUTH_TAG_LENGTH = 'AuthTagLength';
  BCRYPT_ALG_HANDLE_HMAC_FLAG = $00000008;
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;

  EXPECTED_MAGIC: array[0..3] of AnsiChar = 'AVO1';
  ALGO_ID_AES256_GCM = $01;
  DEFAULT_PBKDF2_ITERS = 500000;
  DEFAULT_CHUNK_SIZE = 4 * 1024 * 1024; // 4 MB
  MAX_CHUNK_SIZE = 64 * 1024 * 1024;    // 64 MB
  TAG_SIZE = 16;
  IV_SIZE = 12;

//IMPORT BCRYPT.DLL
function BCryptOpenAlgorithmProvider(var phAlgorithm: bcrypt_alg_handle; pszAlgId: PWideChar; pszImplementation: PWideChar; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptCloseAlgorithmProvider(hAlgorithm: bcrypt_alg_handle; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptSetProperty(hObject: PVOID; pszProperty: PWideChar; pbInput: PByte; cbInput: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptGetProperty(hObject: PVOID; pszProperty: PWideChar; pbOutput: PByte; cbOutput: ULONG; var pcbResult: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptGenerateSymmetricKey(hAlgorithm: bcrypt_alg_handle; var phKey: bcrypt_key_handle; pbKeyObject: PByte; cbKeyObject: ULONG; pbSecret: PByte; cbSecret: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptDestroyKey(hKey: bcrypt_key_handle): nt_status; stdcall; external 'bcrypt.dll';
function BCryptEncrypt(hKey: bcrypt_key_handle; pbInput: PByte; cbInput: ULONG; pPaddingInfo: PVOID; pbIV: PByte; cbIV: ULONG; pbOutput: PByte; cbOutput: ULONG; var pcbResult: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptDecrypt(hKey: bcrypt_key_handle; pbInput: PByte; cbInput: ULONG; pPaddingInfo: PVOID; pbIV: PByte; cbIV: ULONG; pbOutput: PByte; cbOutput: ULONG; var pcbResult: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptDeriveKeyPBKDF2(hPrf: bcrypt_alg_handle; pbPassword: PByte; cbPassword: ULONG; pbSalt: PByte; cbSalt: ULONG; cIterations: UInt64; pbDerivedKey: PByte; cbDerivedKey: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';
function BCryptGenRandom(hAlgorithm: bcrypt_alg_handle; pbBuffer: PByte; cbBuffer: ULONG; dwFlags: ULONG): nt_status; stdcall; external 'bcrypt.dll';

// LOGIKA POMOCNICZA

procedure check_status(status: nt_status; const error_msg: string);
begin
  if status <> STATUS_SUCCESS then
    raise Exception.Create(error_msg + ' (NTSTATUS: 0x' + IntToHex(status, 8) + ')');
end;

procedure construct_iv(const base_iv: array of Byte; chunk_idx: UInt32; var iv: TBytes);
begin
  SetLength(iv, IV_SIZE);
  Move(base_iv[0], iv[0], 8);
  iv[8]  := Byte(chunk_idx);
  iv[9]  := Byte(chunk_idx shr 8);
  iv[10] := Byte(chunk_idx shr 16);
  iv[11] := Byte(chunk_idx shr 24);
end;

procedure derive_key_pbkdf2(const password: string; const salt: array of Byte; iters: UInt32; var key: TBytes);
var
  hmac_alg: bcrypt_alg_handle;
  pass_bytes: TBytes;
begin
  pass_bytes := TEncoding.UTF8.GetBytes(password);
  SetLength(key, 32);
  try
    check_status(BCryptOpenAlgorithmProvider(hmac_alg, PWideChar(WideString(BCRYPT_SHA256_ALGORITHM)), nil, BCRYPT_ALG_HANDLE_HMAC_FLAG), 'HMAC provider failed');
    try
      check_status(BCryptDeriveKeyPBKDF2(hmac_alg, PByte(pass_bytes), Length(pass_bytes), PByte(@salt[0]), Length(salt), iters, PByte(key), Length(key), 0), 'PBKDF2 failed');
    finally
      BCryptCloseAlgorithmProvider(hmac_alg, 0);
    end;
  finally
    if Length(pass_bytes) > 0 then FillChar(pass_bytes[0], Length(pass_bytes), 0);
  end;
end;

// GŁÓWNE FUNKCJE DOSTĘPOWE

procedure encrypt_file_gcm(const input_path, output_path, password: string);
var
  header: TAvoHeader;
  alg_handle: bcrypt_alg_handle;
  key_handle: bcrypt_key_handle;
  auth_info: TBCryptAuthenticatedCipherModeInfo;
  tag_lengths: TBCryptAuthTagLengthsStruct;
  key, iv, tag, key_object, in_buf, out_buf, aad_buf: TBytes;
  in_stream, out_stream: TFileStream;
  bytes_read, enc_size, obj_len, res_len, chunk_idx: UInt32;
  mode_gcm: WideString;
  operation_ok: Boolean;
begin
  if Length(password) < 8 then raise Exception.Create('Security Policy: Password must be at least 8 characters long.');

  operation_ok := False;
  out_stream := nil;
  in_stream := TFileStream.Create(input_path, fmOpenRead or fmShareDenyWrite);
  try
    try
      out_stream := TFileStream.Create(output_path, fmCreate);

      FillChar(header, SizeOf(header), 0);
      header.magic[0] := 'A'; header.magic[1] := 'V'; header.magic[2] := 'O'; header.magic[3] := '1';
      header.algo_id := ALGO_ID_AES256_GCM;
      header.flags := 0;
      header.kdf_iters := DEFAULT_PBKDF2_ITERS;
      header.chunk_size := DEFAULT_CHUNK_SIZE;
      header.original_size := in_stream.Size;

      check_status(BCryptGenRandom(nil, @header.salt[0], 16, BCRYPT_USE_SYSTEM_PREFERRED_RNG), 'RNG Salt failed');
      check_status(BCryptGenRandom(nil, @header.base_iv[0], 8, BCRYPT_USE_SYSTEM_PREFERRED_RNG), 'RNG BaseIV failed');

      derive_key_pbkdf2(password, header.salt, header.kdf_iters, key);

      check_status(BCryptOpenAlgorithmProvider(alg_handle, PWideChar(WideString(BCRYPT_AES_ALGORITHM)), nil, 0), 'AES open failed');
      try
        mode_gcm := BCRYPT_CHAIN_MODE_GCM;
        check_status(BCryptSetProperty(alg_handle, PWideChar(WideString(BCRYPT_CHAINING_MODE)), PByte(PWideChar(mode_gcm)), (Length(mode_gcm) + 1) * SizeOf(WideChar), 0), 'GCM mode failed');

        check_status(BCryptGetProperty(alg_handle, PWideChar(WideString(BCRYPT_AUTH_TAG_LENGTH)), PByte(@tag_lengths), SizeOf(tag_lengths), res_len, 0), 'AuthTag length failed');
        if (TAG_SIZE < tag_lengths.dwMinLength) or (TAG_SIZE > tag_lengths.dwMaxLength) then raise Exception.Create('System does not support 16-byte GCM tags.');

        check_status(BCryptGetProperty(alg_handle, PWideChar(WideString(BCRYPT_OBJECT_LENGTH)), PByte(@obj_len), SizeOf(obj_len), res_len, 0), 'ObjectLength failed');
        SetLength(key_object, obj_len);

        check_status(BCryptGenerateSymmetricKey(alg_handle, key_handle, PByte(key_object), Length(key_object), PByte(key), Length(key), 0), 'Key gen failed');
        try
          SetLength(tag, TAG_SIZE);
          SetLength(in_buf, header.chunk_size);
          SetLength(out_buf, header.chunk_size);
          SetLength(aad_buf, SizeOf(TAvoHeader) + SizeOf(UInt32));

          out_stream.WriteBuffer(header, SizeOf(header));

          chunk_idx := 0;
          while in_stream.Position < in_stream.Size do
          begin
            if chunk_idx = $FFFFFFFF then raise Exception.Create('Security Error: Maximum chunk limit reached (IV Reuse Prevention).');

            bytes_read := in_stream.Read(in_buf[0], header.chunk_size);
            if bytes_read = 0 then raise Exception.Create('Security/IO Error: Unexpected zero bytes read.');

            construct_iv(header.base_iv, chunk_idx, iv);

            Move(header, aad_buf[0], SizeOf(TAvoHeader));
            Move(chunk_idx, aad_buf[SizeOf(TAvoHeader)], SizeOf(UInt32));

            FillChar(auth_info, SizeOf(auth_info), 0);
            auth_info.cbSize := SizeOf(auth_info);
            auth_info.dwInfoVersion := 1;
            auth_info.pbNonce := PByte(iv);
            auth_info.cbNonce := Length(iv);
            auth_info.pbTag := PByte(tag);
            auth_info.cbTag := Length(tag);
            auth_info.pbAuthData := PByte(aad_buf);
            auth_info.cbAuthData := Length(aad_buf);

            check_status(BCryptEncrypt(key_handle, PByte(in_buf), bytes_read, @auth_info, nil, 0, PByte(out_buf), bytes_read, enc_size, 0), 'Encryption failed');
            if enc_size <> bytes_read then raise Exception.Create('Security Error: Unexpected encryption size mismatch!');

            out_stream.WriteBuffer(bytes_read, SizeOf(bytes_read));
            out_stream.WriteBuffer(tag[0], Length(tag));
            out_stream.WriteBuffer(out_buf[0], enc_size);

            Inc(chunk_idx);
          end;

          operation_ok := True;
        finally
          BCryptDestroyKey(key_handle);
        end;
      finally
        BCryptCloseAlgorithmProvider(alg_handle, 0);
        if Length(key) > 0 then FillChar(key[0], Length(key), 0);
        if Length(key_object) > 0 then FillChar(key_object[0], Length(key_object), 0);
        if Length(in_buf) > 0 then FillChar(in_buf[0], Length(in_buf), 0);
        if Length(out_buf) > 0 then FillChar(out_buf[0], Length(out_buf), 0);
        if Length(iv) > 0 then FillChar(iv[0], Length(iv), 0);
        if Length(tag) > 0 then FillChar(tag[0], Length(tag), 0);
        if Length(aad_buf) > 0 then FillChar(aad_buf[0], Length(aad_buf), 0);
      end;
    finally
       if Assigned(out_stream) then out_stream.Free;
       if not operation_ok then SysUtils.DeleteFile(output_path);
    end;
  finally
    in_stream.Free;
  end;
end;

procedure decrypt_file_gcm(const input_path, output_path, password: string);
var
  header: TAvoHeader;
  alg_handle: bcrypt_alg_handle;
  key_handle: bcrypt_key_handle;
  auth_info: TBCryptAuthenticatedCipherModeInfo;
  key, iv, tag, key_object, in_buf, out_buf, aad_buf: TBytes;
  in_stream, out_stream: TFileStream;
  dec_size, obj_len, res_len, chunk_data_size, chunk_idx: UInt32;
  total_decrypted: UInt64;
  mode_gcm: WideString;
  status: nt_status;
  operation_ok: Boolean;
begin
  if Length(password) < 8 then raise Exception.Create('Security Policy: Password must be at least 8 characters long.');

  operation_ok := False;
  out_stream := nil;
  in_stream := TFileStream.Create(input_path, fmOpenRead or fmShareDenyWrite);
  try
    if in_stream.Size <= SizeOf(TAvoHeader) then raise Exception.Create('File too small to be valid.');
    in_stream.ReadBuffer(header, SizeOf(header));

    if not CompareMem(@header.magic[0], @EXPECTED_MAGIC[0], 4) then raise Exception.Create('Invalid Magic Header. Not an AVO file.');
    if header.algo_id <> ALGO_ID_AES256_GCM then raise Exception.Create('Unsupported Algorithm Version!');

    if header.flags <> 0 then raise Exception.Create('Unsupported file flags - newer format version?');

    if (header.chunk_size = 0) or (header.chunk_size > MAX_CHUNK_SIZE) then
      raise Exception.Create('Security Error: Invalid chunk size (OOM protection).');
    if (header.kdf_iters < 10000) or (header.kdf_iters > 10000000) then
      raise Exception.Create('Security Error: Invalid PBKDF2 iterations count (Tampering detected).');

    if (header.original_size > 0) and (header.original_size >= (UInt64(in_stream.Size) - SizeOf(TAvoHeader))) then
      raise Exception.Create('Security Error: Unrealistic original size.');

    try
      out_stream := TFileStream.Create(output_path, fmCreate);

      derive_key_pbkdf2(password, header.salt, header.kdf_iters, key);

      check_status(BCryptOpenAlgorithmProvider(alg_handle, PWideChar(WideString(BCRYPT_AES_ALGORITHM)), nil, 0), 'AES open failed');
      try
        mode_gcm := BCRYPT_CHAIN_MODE_GCM;
        check_status(BCryptSetProperty(alg_handle, PWideChar(WideString(BCRYPT_CHAINING_MODE)), PByte(PWideChar(mode_gcm)), (Length(mode_gcm) + 1) * SizeOf(WideChar), 0), 'GCM mode failed');

        check_status(BCryptGetProperty(alg_handle, PWideChar(WideString(BCRYPT_OBJECT_LENGTH)), PByte(@obj_len), SizeOf(obj_len), res_len, 0), 'ObjectLength failed');
        SetLength(key_object, obj_len);

        check_status(BCryptGenerateSymmetricKey(alg_handle, key_handle, PByte(key_object), Length(key_object), PByte(key), Length(key), 0), 'Key gen failed');
        try
          SetLength(tag, TAG_SIZE);
          SetLength(in_buf, header.chunk_size);
          SetLength(out_buf, header.chunk_size);
          SetLength(aad_buf, SizeOf(TAvoHeader) + SizeOf(UInt32));

          chunk_idx := 0;
          total_decrypted := 0;

          while in_stream.Position < in_stream.Size do
          begin
            if chunk_idx = $FFFFFFFF then raise Exception.Create('Security Error: Maximum chunk limit reached.');
            if chunk_idx > (header.original_size div header.chunk_size + 1) then
              raise Exception.Create('Security Error: Too many chunks for the stated original file size.');

            in_stream.ReadBuffer(chunk_data_size, SizeOf(chunk_data_size));

            // Odrzucenie uszkodzonych lub celowo spreparowanych chuncków o rozmiarze 0
            if (chunk_data_size = 0) or (chunk_data_size > header.chunk_size) then
              raise Exception.Create('Security Error: Corrupted chunk data size detected!');

            in_stream.ReadBuffer(tag[0], Length(tag));
            in_stream.ReadBuffer(in_buf[0], chunk_data_size);

            construct_iv(header.base_iv, chunk_idx, iv);

            Move(header, aad_buf[0], SizeOf(TAvoHeader));
            Move(chunk_idx, aad_buf[SizeOf(TAvoHeader)], SizeOf(UInt32));

            FillChar(auth_info, SizeOf(auth_info), 0);
            auth_info.cbSize := SizeOf(auth_info);
            auth_info.dwInfoVersion := 1;
            auth_info.pbNonce := PByte(iv);
            auth_info.cbNonce := Length(iv);
            auth_info.pbTag := PByte(tag);
            auth_info.cbTag := Length(tag);
            auth_info.pbAuthData := PByte(aad_buf);
            auth_info.cbAuthData := Length(aad_buf);

            status := BCryptDecrypt(key_handle, PByte(in_buf), chunk_data_size, @auth_info, nil, 0, PByte(out_buf), chunk_data_size, dec_size, 0);
            if status = STATUS_AUTH_TAG_MISMATCH then
              raise Exception.Create('Decryption blocked! Incorrect password or corrupted chunk data.')
            else if status <> STATUS_SUCCESS then
              raise Exception.Create('Decryption failed (NTSTATUS: 0x' + IntToHex(status, 8) + ')');

            if dec_size <> chunk_data_size then
              raise Exception.Create('Security Error: Decrypted size mismatch!');

            out_stream.WriteBuffer(out_buf[0], dec_size);
            Inc(total_decrypted, dec_size);
            Inc(chunk_idx);
          end;

          if total_decrypted <> header.original_size then
            raise Exception.Create('Security Error: Truncation detected! The file was maliciously shortened.');

          if in_stream.Position <> in_stream.Size then
            raise Exception.Create('Security Error: Extra data detected at end of file (Trailing Garbage Attack).');

          operation_ok := True;
        finally
          BCryptDestroyKey(key_handle);
        end;
      finally
        BCryptCloseAlgorithmProvider(alg_handle, 0);
        if Length(key) > 0 then FillChar(key[0], Length(key), 0);
        if Length(key_object) > 0 then FillChar(key_object[0], Length(key_object), 0);
        if Length(in_buf) > 0 then FillChar(in_buf[0], Length(in_buf), 0);
        if Length(out_buf) > 0 then FillChar(out_buf[0], Length(out_buf), 0);
        if Length(iv) > 0 then FillChar(iv[0], Length(iv), 0);
        if Length(tag) > 0 then FillChar(tag[0], Length(tag), 0);
        if Length(aad_buf) > 0 then FillChar(aad_buf[0], Length(aad_buf), 0);
        FillChar(header, SizeOf(header), 0);
      end;
    finally
      if Assigned(out_stream) then out_stream.Free;
      if not operation_ok then SysUtils.DeleteFile(output_path);
    end;
  finally
    in_stream.Free;
  end;
end;
end.


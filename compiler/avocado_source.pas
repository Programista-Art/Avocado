unit avocado_source;

{$mode objfpc}{$H+}

{ Source text container, byte offsets, and Unicode-aware line/column mapping.
  Independent of Lazarus / LCL. }

interface

uses
  SysUtils, Classes;

type
  { 1-based line and column. Column counts Unicode codepoints (not bytes),
    matching Lazarus SynEdit caret columns. }
  TAvocadoSourcePos = record
    Offset: Integer;   // 0-based byte offset into UTF-8 source
    Line: Integer;     // 1-based
    Col: Integer;      // 1-based codepoint column
  end;

  TAvocadoSourceSpan = record
    StartPos: TAvocadoSourcePos;
    EndPos: TAvocadoSourcePos; // exclusive end offset
  end;

  TAvocadoSource = class
  private
    FFileName: string;
    FText: string;            // UTF-8, no BOM
    FLineStarts: array of Integer; // byte offset of each line start (0-based line index)
    function OffsetToPos(AOffset: Integer): TAvocadoSourcePos;
  public
    constructor Create(const AFileName, AText: string);

    { Load from file, converting legacy encodings to UTF-8 when needed. }
    class function LoadFromFile(const AFileName: string): TAvocadoSource;

    property FileName: string read FFileName;
    property Text: string read FText;
    function Len: Integer;
    function GetSpan(AStartOffset, AEndOffset: Integer): TAvocadoSourceSpan;
    function PosAt(AOffset: Integer): TAvocadoSourcePos;
    function LineCount: Integer;
    function LineText(ALine: Integer): string; // 1-based
  end;

function MakeSourcePos(AOffset, ALine, ACol: Integer): TAvocadoSourcePos;
function MakeSpan(const AStart, AEnd: TAvocadoSourcePos): TAvocadoSourceSpan;
function EmptySpan: TAvocadoSourceSpan;

{ Strip UTF-8 BOM if present. }
function StripBom(const S: string): string;

{ Detect whether S is valid UTF-8 (heuristic). }
function LooksLikeUtf8(const S: string): Boolean;

{ Convert CP1250 bytes to UTF-8. }
function Cp1250ToUtf8(const S: string): string;

{ UTF-8 aware lower-case for ASCII + Polish diacritics. }
function AvocadoLowerCase(const S: string): string;

{ Count Unicode codepoints in UTF-8 string S[1..ByteLen]. }
function Utf8CodepointCount(const S: string): Integer;

implementation

function MakeSourcePos(AOffset, ALine, ACol: Integer): TAvocadoSourcePos;
begin
  Result.Offset := AOffset;
  Result.Line := ALine;
  Result.Col := ACol;
end;

function MakeSpan(const AStart, AEnd: TAvocadoSourcePos): TAvocadoSourceSpan;
begin
  Result.StartPos := AStart;
  Result.EndPos := AEnd;
end;

function EmptySpan: TAvocadoSourceSpan;
begin
  Result.StartPos := MakeSourcePos(0, 1, 1);
  Result.EndPos := Result.StartPos;
end;

function StripBom(const S: string): string;
begin
  if (Length(S) >= 3) and (S[1] = #$EF) and (S[2] = #$BB) and (S[3] = #$BF) then
    Result := Copy(S, 4, MaxInt)
  else
    Result := S;
end;

function LooksLikeUtf8(const S: string): Boolean;
var
  I, N, C: Integer;
begin
  Result := True;
  I := 1;
  N := Length(S);
  while I <= N do
  begin
    C := Ord(S[I]);
    if C < $80 then
      Inc(I)
    else if (C >= $C2) and (C <= $DF) then
    begin
      if (I + 1 > N) or ((Ord(S[I+1]) and $C0) <> $80) then Exit(False);
      Inc(I, 2);
    end
    else if (C >= $E0) and (C <= $EF) then
    begin
      if (I + 2 > N) or ((Ord(S[I+1]) and $C0) <> $80) or ((Ord(S[I+2]) and $C0) <> $80) then
        Exit(False);
      Inc(I, 3);
    end
    else if (C >= $F0) and (C <= $F4) then
    begin
      if (I + 3 > N) or ((Ord(S[I+1]) and $C0) <> $80) or
         ((Ord(S[I+2]) and $C0) <> $80) or ((Ord(S[I+3]) and $C0) <> $80) then
        Exit(False);
      Inc(I, 4);
    end
    else
      Exit(False);
  end;
end;

function Cp1250ToUtf8(const S: string): string;
const
  // CP1250 -> Unicode for 0x80..0xFF (Polish-relevant subset expanded)
  Map: array[$80..$FF] of Word = (
    $20AC, $0081, $201A, $0083, $201E, $2026, $2020, $2021,
    $0088, $2030, $0160, $2039, $015A, $0164, $017D, $0179,
    $0090, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $0098, $2122, $0161, $203A, $015B, $0165, $017E, $017A,
    $00A0, $02C7, $02D8, $0141, $00A4, $0104, $00A6, $00A7,
    $00A8, $00A9, $015E, $00AB, $00AC, $00AD, $00AE, $017B,
    $00B0, $00B1, $02DB, $0142, $00B4, $00B5, $00B6, $00B7,
    $00B8, $0105, $015F, $00BB, $013D, $02DD, $013E, $017C,
    $0154, $00C1, $00C2, $0102, $00C4, $0139, $0106, $00C7,
    $010C, $00C9, $0118, $00CB, $011A, $00CD, $00CE, $010E,
    $0110, $0143, $0147, $00D3, $00D4, $0150, $00D6, $00D7,
    $0158, $016E, $00DA, $0170, $00DC, $00DD, $0162, $00DF,
    $0155, $00E1, $00E2, $0103, $00E4, $013A, $0107, $00E7,
    $010D, $00E9, $0119, $00EB, $011B, $00ED, $00EE, $010F,
    $0111, $0144, $0148, $00F3, $00F4, $0151, $00F6, $00F7,
    $0159, $016F, $00FA, $0171, $00FC, $00FD, $0163, $02D9
  );
var
  I: Integer;
  U: Word;
  B: Byte;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    B := Ord(S[I]);
    if B < $80 then
      Result := Result + S[I]
    else
    begin
      U := Map[B];
      if U < $800 then
        Result := Result + Char($C0 or (U shr 6)) + Char($80 or (U and $3F))
      else
        Result := Result + Char($E0 or (U shr 12)) +
          Char($80 or ((U shr 6) and $3F)) + Char($80 or (U and $3F));
    end;
  end;
end;

function Utf8CodepointCount(const S: string): Integer;
var
  I, N: Integer;
begin
  Result := 0;
  I := 1;
  N := Length(S);
  while I <= N do
  begin
    Inc(Result);
    if Ord(S[I]) < $80 then Inc(I)
    else if (Ord(S[I]) >= $C0) and (Ord(S[I]) < $E0) then Inc(I, 2)
    else if (Ord(S[I]) >= $E0) and (Ord(S[I]) < $F0) then Inc(I, 3)
    else Inc(I, 4);
    if I > N + 1 then Break;
  end;
end;

function AvocadoLowerCase(const S: string): string;
var
  I, N, C: Integer;
begin
  Result := '';
  I := 1;
  N := Length(S);
  while I <= N do
  begin
    C := Ord(S[I]);
    if C < $80 then
    begin
      if (C >= Ord('A')) and (C <= Ord('Z')) then
        Result := Result + Char(C + 32)
      else
        Result := Result + S[I];
      Inc(I);
    end
    else if (C >= $C0) and (I < N) then
    begin
      // 2-byte UTF-8; fold Polish pairs
      // ą U+0105 = C4 85, Ą U+0104 = C4 84
      if (C = $C4) and (Ord(S[I+1]) = $84) then
        Result := Result + #$C4#$85
      else if (C = $C4) and (Ord(S[I+1]) = $86) then
        Result := Result + #$C4#$87  // Ć->ć
      else if (C = $C4) and (Ord(S[I+1]) = $98) then
        Result := Result + #$C4#$99  // Ę->ę
      else if (C = $C5) and (Ord(S[I+1]) = $81) then
        Result := Result + #$C5#$82  // Ł->ł (U+0141 -> U+0142)
      else if (C = $C5) and (Ord(S[I+1]) = $83) then
        Result := Result + #$C5#$84  // Ń->ń (U+0143 -> U+0144)
      else if (C = $C3) and (Ord(S[I+1]) = $93) then
        Result := Result + #$C3#$B3  // Ó->ó
      else if (C = $C5) and (Ord(S[I+1]) = $9A) then
        Result := Result + #$C5#$9B  // Ś->ś
      else if (C = $C5) and (Ord(S[I+1]) = $B9) then
        Result := Result + #$C5#$BA  // Ź->ź
      else if (C = $C5) and (Ord(S[I+1]) = $BB) then
        Result := Result + #$C5#$BC  // Ż->ż
      else if (C = $C3) and (Ord(S[I+1]) >= $80) and (Ord(S[I+1]) <= $9E) and
              (Ord(S[I+1]) <> $97) then // A..Z Latin-1 except ×
        Result := Result + Char(C) + Char(Ord(S[I+1]) + $20)
      else
        Result := Result + S[I] + S[I+1];
      Inc(I, 2);
    end
    else
    begin
      Result := Result + S[I];
      Inc(I);
    end;
  end;
end;

{ TAvocadoSource }

constructor TAvocadoSource.Create(const AFileName, AText: string);
var
  I, N: Integer;
  Starts: array of Integer;
  Cnt: Integer;
begin
  inherited Create;
  FFileName := AFileName;
  FText := StripBom(AText);
  N := Length(FText);
  Cnt := 1;
  SetLength(Starts, N + 2);
  Starts[0] := 1; // 1-based string indexing: line 1 starts at offset 1
  for I := 1 to N do
    if FText[I] = #10 then
    begin
      Starts[Cnt] := I + 1;
      Inc(Cnt);
    end;
  SetLength(Starts, Cnt);
  SetLength(FLineStarts, Cnt);
  for I := 0 to Cnt - 1 do
    FLineStarts[I] := Starts[I];
end;

class function TAvocadoSource.LoadFromFile(const AFileName: string): TAvocadoSource;
var
  Raw: TStringList;
  S, Enc: string;
begin
  Raw := TStringList.Create;
  try
    Raw.LoadFromFile(AFileName);
    S := Raw.Text;
  finally
    Raw.Free;
  end;
  // TStringList.Text may already have normalized line endings; keep content.
  S := StripBom(S);
  if not LooksLikeUtf8(S) then
  begin
    // treat as CP1250 (legacy Polish ANSI)
    S := Cp1250ToUtf8(S);
    Enc := 'cp1250';
  end
  else
    Enc := 'utf8';
  Result := TAvocadoSource.Create(AFileName, S);
  // encoding recorded only for diagnostics; text is always UTF-8 here
  if Enc = 'cp1250' then
    { nothing further; conversion already applied };
end;

function TAvocadoSource.Len: Integer;
begin
  Result := Length(FText);
end;

function TAvocadoSource.LineCount: Integer;
begin
  Result := Length(FLineStarts);
end;

function TAvocadoSource.LineText(ALine: Integer): string;
var
  StartOff, StopOff: Integer;
begin
  if (ALine < 1) or (ALine > Length(FLineStarts)) then
    Exit('');
  StartOff := FLineStarts[ALine - 1];
  if ALine < Length(FLineStarts) then
    StopOff := FLineStarts[ALine] - 1 // up to but not including next line start
  else
    StopOff := Length(FText) + 1;
  // exclude trailing CR
  if (StopOff > StartOff) and (FText[StopOff - 1] = #10) then
    Dec(StopOff);
  if (StopOff > StartOff) and (FText[StopOff - 1] = #13) then
    Dec(StopOff);
  Result := Copy(FText, StartOff, StopOff - StartOff);
end;

function TAvocadoSource.OffsetToPos(AOffset: Integer): TAvocadoSourcePos;
var
  Lo, Hi, Mid, LineIdx, I, Col, Limit: Integer;
begin
  if AOffset < 1 then AOffset := 1;
  if AOffset > Length(FText) + 1 then AOffset := Length(FText) + 1;
  // binary search line
  Lo := 0;
  Hi := Length(FLineStarts) - 1;
  LineIdx := 0;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FLineStarts[Mid] <= AOffset then
    begin
      LineIdx := Mid;
      Lo := Mid + 1;
    end
    else
      Hi := Mid - 1;
  end;
  Col := 1;
  I := FLineStarts[LineIdx];
  Limit := AOffset;
  while I < Limit do
  begin
    if Ord(FText[I]) < $80 then Inc(I)
    else if (Ord(FText[I]) >= $C0) and (Ord(FText[I]) < $E0) then Inc(I, 2)
    else if (Ord(FText[I]) >= $E0) and (Ord(FText[I]) < $F0) then Inc(I, 3)
    else Inc(I, 4);
    Inc(Col);
  end;
  Result.Offset := AOffset - 1; // store 0-based byte offset
  Result.Line := LineIdx + 1;
  Result.Col := Col;
end;

function TAvocadoSource.PosAt(AOffset: Integer): TAvocadoSourcePos;
begin
  Result := OffsetToPos(AOffset);
end;

function TAvocadoSource.GetSpan(AStartOffset, AEndOffset: Integer): TAvocadoSourceSpan;
begin
  Result.StartPos := OffsetToPos(AStartOffset);
  Result.EndPos := OffsetToPos(AEndOffset);
end;

end.

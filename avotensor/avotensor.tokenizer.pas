{$mode objfpc}{$H+}
unit avotensor.tokenizer;
interface

uses
  SysUtils, Classes, Types;

const
  TOKEN_PAD     = 0;
  TOKEN_UNK     = 1;
  TOKEN_BOS     = 2;
  TOKEN_EOS     = 3;
  TOKEN_NEWLINE = 4;
  TOKEN_TAB     = 5;
  TOKEN_INDENT  = 6;
  TOKEN_DEDENT  = 7;

type
  TBatchIntegerDynArray = array of TIntegerDynArray;
  TUnicodeStringArray = array of UnicodeString;

  // TAvoTokenHashMap - Autorska mapa O(1) z Load Factor = 0.7

  TTokenHashEntry = record
    Key: UnicodeString;
    Value: Integer;
    Next: Integer;
  end;

  TAvoTokenHashMap = class
  public
    FBuckets: array of Integer;
    FEntries: array of TTokenHashEntry;
    FCount: Integer;

    function HashStr(const S: UnicodeString): Cardinal;
    procedure Rehash;
  public
    constructor Create(InitialCapacity: Integer = 65536);
    procedure Clear;
    procedure AddOrUpdate(const Key: UnicodeString; Value: Integer);
    function TryGetValue(const Key: UnicodeString; out Value: Integer): Boolean;

    property Count: Integer read FCount;
  end;


  // TAvoTokenizer
  TAvoTokenizer = class
  private
    FVocabSize: Integer;
    FMap: TAvoTokenHashMap;
    FIdToWord: array of UnicodeString;
    FCaseSensitive: Boolean;

    procedure Clear;
    procedure AddSpecialTokens;
    procedure RegisterToken(const Word: UnicodeString; ID: Integer);

    function IsPunctuation(C: WideChar): Boolean;
    function IsWhitespace(C: WideChar): Boolean;
    function IsMultiCharOp3(C1, C2, C3: WideChar): Boolean;
    function IsMultiCharOp2(C1, C2: WideChar): Boolean;

    // SINGLE SOURCE OF TRUTH: Główny motor napędowy (Lexer)
    function ScanText(const Text: UnicodeString): TUnicodeStringArray;

    // Prywatne metody pomocnicze do optymalizacji pamięci
    procedure FeedText(const Text: UnicodeString; TempFreq: TAvoTokenHashMap);
    procedure ApplyPruning(TempFreq: TAvoTokenHashMap; MinFreq: Integer);

  public
    constructor Create;
    destructor Destroy; override;

    property VocabSize: Integer read FVocabSize;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive;

    // Budowanie słownika
    procedure BuildFromText(const Text: UnicodeString; MinFreq: Integer = 1);
    procedure BuildFromFile(const FileName: String; MinFreq: Integer = 1);
    procedure BuildFromDirectory(const Dir: String; MinFreq: Integer = 1);

    // Kodowanie i Dekodowanie
    function Encode(const Text: UnicodeString; AddSpecial: Boolean = False): TIntegerDynArray;
    function EncodeBatch(const Texts: array of UnicodeString; AddSpecial: Boolean = False): TBatchIntegerDynArray;
    function Decode(const IDs: TIntegerDynArray; SkipSpecial: Boolean = True): UnicodeString;

    // Obsługa plików
    procedure SaveVocab(const FileName: String);
    procedure LoadVocab(const FileName: String);
    procedure SaveVocabBin(const FileName: String);
    procedure LoadVocabBin(const FileName: String);
  end;

function ReadRawUTF8File(const FileName: String): UnicodeString;

implementation


// Funkcje pomocnicze

function ReadRawUTF8File(const FileName: String): UnicodeString;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName, TEncoding.UTF8);
    Result := UnicodeString(SL.Text);
  finally
    SL.Free;
  end;
end;

// TAvoTokenHashMap

constructor TAvoTokenHashMap.Create(InitialCapacity: Integer);
begin
  SetLength(FBuckets, InitialCapacity);
  SetLength(FEntries, InitialCapacity);
  Clear;
end;

procedure TAvoTokenHashMap.Clear;
begin
  if Length(FBuckets) > 0 then
    FillChar(FBuckets[0], Length(FBuckets) * SizeOf(Integer), 0);
  FCount := 0;
end;

function TAvoTokenHashMap.HashStr(const S: UnicodeString): Cardinal;
var i: Integer;
begin
  Result := 5381;
  for i := 1 to Length(S) do
    Result := ((Result shl 5) + Result) xor Ord(S[i]);
end;

procedure TAvoTokenHashMap.Rehash;
var
  NewCap, i: Integer;
  BIdx: Cardinal;
  OldEntries: array of TTokenHashEntry;
begin
  NewCap := Length(FBuckets) * 2;
  if NewCap = 0 then NewCap := 8192;

  SetLength(OldEntries, FCount);
  for i := 0 to FCount - 1 do
    OldEntries[i] := FEntries[i];

  SetLength(FBuckets, NewCap);
  SetLength(FEntries, NewCap);
  FillChar(FBuckets[0], NewCap * SizeOf(Integer), 0);

  for i := 0 to FCount - 1 do
  begin
    FEntries[i] := OldEntries[i];
    BIdx := HashStr(FEntries[i].Key) mod Cardinal(NewCap);
    FEntries[i].Next := FBuckets[BIdx];
    FBuckets[BIdx] := i + 1;
  end;
end;

procedure TAvoTokenHashMap.AddOrUpdate(const Key: UnicodeString; Value: Integer);
var
  BIdx: Cardinal;
  EntryIdx: Integer;
begin
  if Length(FBuckets) = 0 then Rehash;

  BIdx := HashStr(Key) mod Cardinal(Length(FBuckets));
  EntryIdx := FBuckets[BIdx];

  while EntryIdx > 0 do
  begin
    if FEntries[EntryIdx - 1].Key = Key then
    begin
      FEntries[EntryIdx - 1].Value := Value;
      Exit;
    end;
    EntryIdx := FEntries[EntryIdx - 1].Next;
  end;

  if FCount >= (Length(FEntries) * 7) div 10 then
  begin
    Rehash;
    BIdx := HashStr(Key) mod Cardinal(Length(FBuckets));
  end;

  FEntries[FCount].Key := Key;
  FEntries[FCount].Value := Value;
  FEntries[FCount].Next := FBuckets[BIdx];
  FBuckets[BIdx] := FCount + 1;
  Inc(FCount);
end;

function TAvoTokenHashMap.TryGetValue(const Key: UnicodeString; out Value: Integer): Boolean;
var
  BIdx: Cardinal;
  EntryIdx: Integer;
begin
  if FCount = 0 then Exit(False);

  BIdx := HashStr(Key) mod Cardinal(Length(FBuckets));
  EntryIdx := FBuckets[BIdx];

  while EntryIdx > 0 do
  begin
    if FEntries[EntryIdx - 1].Key = Key then
    begin
      Value := FEntries[EntryIdx - 1].Value;
      Exit(True);
    end;
    EntryIdx := FEntries[EntryIdx - 1].Next;
  end;
  Result := False;
end;

// TAvoTokenizer

constructor TAvoTokenizer.Create;
begin
  FMap := TAvoTokenHashMap.Create;
  FCaseSensitive := True;
  Clear;
end;

destructor TAvoTokenizer.Destroy;
begin
  FMap.Free;
  SetLength(FIdToWord, 0);
  inherited Destroy;
end;

procedure TAvoTokenizer.Clear;
begin
  FMap.Clear;
  SetLength(FIdToWord, 0);
  FVocabSize := 0;
  AddSpecialTokens;
end;

procedure TAvoTokenizer.RegisterToken(const Word: UnicodeString; ID: Integer);
var Dummy: Integer;
begin
  if not FMap.TryGetValue(Word, Dummy) then
  begin
    FMap.AddOrUpdate(Word, ID);
    if ID >= Length(FIdToWord) then SetLength(FIdToWord, ID + 5000);
    FIdToWord[ID] := Word;
    if ID >= FVocabSize then FVocabSize := ID + 1;
  end;
end;

procedure TAvoTokenizer.AddSpecialTokens;
begin
  RegisterToken('<PAD>',     TOKEN_PAD);
  RegisterToken('<UNK>',     TOKEN_UNK);
  RegisterToken('<BOS>',     TOKEN_BOS);
  RegisterToken('<EOS>',     TOKEN_EOS);
  RegisterToken('<NEWLINE>', TOKEN_NEWLINE);
  RegisterToken('<TAB>',     TOKEN_TAB);
  RegisterToken('<INDENT>',  TOKEN_INDENT);
  RegisterToken('<DEDENT>',  TOKEN_DEDENT);
end;

function TAvoTokenizer.IsWhitespace(C: WideChar): Boolean;
begin
  Result := (C = ' ') or (C = #13) or (C = #10) or (C = #9);
end;

function TAvoTokenizer.IsPunctuation(C: WideChar): Boolean;
begin
  Result := (C = '.') or (C = ',') or (C = '!') or (C = '?') or
            (C = ':') or (C = ';') or (C = '"') or (C = '''') or
            (C = '(') or (C = ')') or (C = '[') or (C = ']') or
            (C = '{') or (C = '}') or (C = '-') or (C = '*') or
            (C = '/') or (C = '\') or (C = '<') or (C = '>') or
            (C = '=') or (C = '+') or (C = '_') or (C = '@') or
            (C = '#') or (C = '%') or (C = '^') or (C = '&') or
            (C = '|') or (C = '~') or (C = '`');
end;

function TAvoTokenizer.IsMultiCharOp3(C1, C2, C3: WideChar): Boolean;
begin
  if C1 = '=' then Result := (C2 = '=') and (C3 = '=')      // ===
  else if C1 = '!' then Result := (C2 = '=') and (C3 = '=') // !==
  else if C1 = '<' then Result := (C2 = '<') and (C3 = '=') // <<=
  else if C1 = '>' then Result := (C2 = '>') and (C3 = '=') // >>=
  else Result := False;
end;

function TAvoTokenizer.IsMultiCharOp2(C1, C2: WideChar): Boolean;
begin
  if C1 = '=' then Result := (C2 = '=') or (C2 = '>')            // ==, =>
  else if C1 = '!' then Result := (C2 = '=')                     // !=
  else if C1 = '<' then Result := (C2 = '=') or (C2 = '<')       // <=, <<
  else if C1 = '>' then Result := (C2 = '=') or (C2 = '>')       // >=, >>
  else if C1 = '+' then Result := (C2 = '+') or (C2 = '=')       // ++, +=
  else if C1 = '-' then Result := (C2 = '-') or (C2 = '=') or (C2 = '>') // --, -=, ->
  else if C1 = '*' then Result := (C2 = '=') or (C2 = '*')       // *=, **
  else if C1 = '/' then Result := (C2 = '=')                     // /=
  else if C1 = '&' then Result := (C2 = '&')                     // &&
  else if C1 = '|' then Result := (C2 = '|')                     // ||
  else if C1 = ':' then Result := (C2 = '=') or (C2 = ':')       // :=, ::
  else if C1 = '.' then Result := (C2 = '.')                     // ..
  else Result := False;
end;


// GŁÓWNY LEXER (SINGLE SOURCE OF TRUTH)
function TAvoTokenizer.ScanText(const Text: UnicodeString): TUnicodeStringArray;
var
  i, StartIdx, Len, DotCount, Count, Capacity: Integer;
  C: WideChar;
  WorkText: UnicodeString;

  procedure Push(const S: UnicodeString);
  begin
    if Count >= Capacity then
    begin
      Capacity := Capacity + (Capacity div 2) + 10000;
      SetLength(Result, Capacity);
    end;
    Result[Count] := S;
    Inc(Count);
  end;

begin
  Count := 0;
  Capacity := Length(Text) div 4;
  if Capacity < 1000 then Capacity := 1000;
  SetLength(Result, Capacity);

  if not FCaseSensitive then WorkText := WideLowerCase(Text)
  else WorkText := Text;

  Len := Length(WorkText);
  i := 1;

  while i <= Len do
  begin
    C := WorkText[i];
    // 0. Specjalne tokeny muszą być czytane jako jeden token
    if (C = '<') then
    begin
      if Copy(WorkText, i, 5) = '<PAD>' then
      begin
        Push('<PAD>');
        Inc(i, 5);
        Continue;
      end
      else if Copy(WorkText, i, 5) = '<UNK>' then
      begin
        Push('<UNK>');
        Inc(i, 5);
        Continue;
      end
      else if Copy(WorkText, i, 5) = '<BOS>' then
      begin
        Push('<BOS>');
        Inc(i, 5);
        Continue;
      end
      else if Copy(WorkText, i, 5) = '<EOS>' then
      begin
        Push('<EOS>');
        Inc(i, 5);
        Continue;
      end
      else if Copy(WorkText, i, 9) = '<NEWLINE>' then
      begin
        Push('<NEWLINE>');
        Inc(i, 9);
        Continue;
      end
      else if Copy(WorkText, i, 5) = '<TAB>' then
      begin
        Push('<TAB>');
        Inc(i, 5);
        Continue;
      end
      else if Copy(WorkText, i, 8) = '<INDENT>' then
      begin
        Push('<INDENT>');
        Inc(i, 8);
        Continue;
      end
      else if Copy(WorkText, i, 8) = '<DEDENT>' then
      begin
        Push('<DEDENT>');
        Inc(i, 8);
        Continue;
      end;
    end;
    // 1. Whitespace
    if IsWhitespace(C) then
    begin
      if C = #10 then Push('<NEWLINE>')
      else if C = #9 then Push('<TAB>');
      Inc(i);
      Continue;
    end;

    // 2. Komentarze jednoliniowe (//)
    if (C = '/') and (i < Len) and (WorkText[i+1] = '/') then
    begin
      StartIdx := i;
      while (i <= Len) and (WorkText[i] <> #10) and (WorkText[i] <> #13) do Inc(i);
      Push(Copy(WorkText, StartIdx, i - StartIdx));
      Continue;
    end;

    // 2b. Komentarze wieloliniowe (/* ... */)
    if (C = '/') and (i < Len) and (WorkText[i+1] = '*') then
    begin
      StartIdx := i;
      Inc(i, 2);
      while i <= Len do
      begin
        if (i < Len) and (WorkText[i] = '*') and (WorkText[i+1] = '/') then
        begin
          Inc(i, 2);
          Break;
        end;
        Inc(i);
      end;
      Push(Copy(WorkText, StartIdx, i - StartIdx));
      Continue;
    end;

    // 3. Stringi ("..." lub '...') z obsługą znaku ucieczki (\)
    if (C = '"') or (C = '''') then
    begin
      StartIdx := i;
      Inc(i);
      while i <= Len do
      begin
        if (WorkText[i] = '\') and (i < Len) then
          Inc(i, 2)
        else if WorkText[i] = C then
        begin
          Inc(i);
          Break;
        end
        else
          Inc(i);
      end;
      Push(Copy(WorkText, StartIdx, i - StartIdx));
      Continue;
    end;

    // 4. Operatory 3-Znakowe
    if (i <= Len - 2) and IsMultiCharOp3(WorkText[i], WorkText[i+1], WorkText[i+2]) then
    begin
      Push(Copy(WorkText, i, 3));
      Inc(i, 3);
      Continue;
    end;

    // 5. Operatory 2-Znakowe
    if (i <= Len - 1) and IsMultiCharOp2(WorkText[i], WorkText[i+1]) then
    begin
      Push(Copy(WorkText, i, 2));
      Inc(i, 2);
      Continue;
    end;

    // 6. Liczby (Max 1 kropka)
    if (C >= '0') and (C <= '9') then
    begin
      StartIdx := i;
      DotCount := 0;
      while i <= Len do
      begin
        if (WorkText[i] >= '0') and (WorkText[i] <= '9') then
          Inc(i)
        else if (WorkText[i] = '.') and (DotCount = 0) and (i < Len) and
                (WorkText[i+1] >= '0') and (WorkText[i+1] <= '9') then
        begin
          Inc(DotCount);
          Inc(i);
        end
        else
          Break;
      end;
      Push(Copy(WorkText, StartIdx, i - StartIdx));
      Continue;
    end;

    // 7. Pojedyncza Interpunkcja
    if IsPunctuation(C) then
    begin
      Push(UnicodeString(C));
      Inc(i);
      Continue;
    end;

    // 8. Słowa / Identyfikatory
    StartIdx := i;
    while (i <= Len) and not IsWhitespace(WorkText[i]) and not IsPunctuation(WorkText[i]) do
      Inc(i);

    if i > StartIdx then
    begin
      Push(Copy(WorkText, StartIdx, i - StartIdx));
      Continue;
    end;

    Inc(i); // Fallback
  end;

  SetLength(Result, Count);
end;


// METODY PRYWATNE OPTYMALIZUJĄCE PAMIĘĆ RAM PODCZAS BUDOWY VOCAB

procedure TAvoTokenizer.FeedText(const Text: UnicodeString; TempFreq: TAvoTokenHashMap);
var
  Tokens: TUnicodeStringArray;
  i, Freq: Integer;
begin
  // Lexer tnie dany fragment tekstu
  Tokens := ScanText(Text);

  // Zliczamy częstotliwość wystąpień każdego tokenu
  for i := 0 to High(Tokens) do
  begin
    if TempFreq.TryGetValue(Tokens[i], Freq) then
      TempFreq.AddOrUpdate(Tokens[i], Freq + 1)
    else
      TempFreq.AddOrUpdate(Tokens[i], 1);
  end;
end;

procedure TAvoTokenizer.ApplyPruning(TempFreq: TAvoTokenHashMap; MinFreq: Integer);
var
  i, Freq: Integer;
begin
  // Odrzucamy szum, akceptujemy tokeny o odpowiedniej częstotliwości
  // oraz strukturalnie ważne (długość <= 3, co obejmuje interpunkcję i operatory)
  for i := 0 to TempFreq.Count - 1 do
  begin
    Freq := TempFreq.FEntries[i].Value;
    if (Freq >= MinFreq) or (Length(TempFreq.FEntries[i].Key) <= 3) then
      RegisterToken(TempFreq.FEntries[i].Key, FVocabSize);
  end;
end;


// METODY PUBLICZNE OPISUJĄCE SIĘ NA GŁÓWNYM LEXERZE
procedure TAvoTokenizer.BuildFromText(const Text: UnicodeString; MinFreq: Integer = 1);
var
  TempFreq: TAvoTokenHashMap;
begin
  Clear;
  TempFreq := TAvoTokenHashMap.Create;
  try
    FeedText(Text, TempFreq);
    ApplyPruning(TempFreq, MinFreq);
  finally
    TempFreq.Free;
  end;
end;

procedure TAvoTokenizer.BuildFromFile(const FileName: String; MinFreq: Integer = 1);
begin
  BuildFromText(ReadRawUTF8File(FileName), MinFreq);
end;

procedure TAvoTokenizer.BuildFromDirectory(const Dir: String; MinFreq: Integer = 1);
var
  SR: TSearchRec;
  TempFreq: TAvoTokenHashMap;
begin
  if not DirectoryExists(Dir) then
    raise Exception.CreateFmt('BuildFromDirectory: katalog nie istnieje: %s', [Dir]);

  Clear;
  TempFreq := TAvoTokenHashMap.Create;

  try
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*.avocado', faAnyFile, SR) = 0 then
    begin
      try
        repeat
          // Wczytujemy, liczymy słowa i zwalniamy pamięć od razu – plik po pliku!
          FeedText(ReadRawUTF8File(IncludeTrailingPathDelimiter(Dir) + SR.Name), TempFreq);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;

    // Zliczanie zakończone dla wszystkich plików, czas na wpisanie do słownika
    ApplyPruning(TempFreq, MinFreq);
  finally
    TempFreq.Free;
  end;
end;

function TAvoTokenizer.Encode(const Text: UnicodeString; AddSpecial: Boolean = False): TIntegerDynArray;
var
  Tokens: TUnicodeStringArray;
  i, ID, Count: Integer;
begin
  // Lexer tnie identycznie jak w fazie budowy
  Tokens := ScanText(Text);

  if AddSpecial then Count := Length(Tokens) + 2
  else Count := Length(Tokens);

  SetLength(Result, Count);
  Count := 0;

  if AddSpecial then
  begin
    if FMap.TryGetValue('<BOS>', ID) then Result[Count] := ID else Result[Count] := TOKEN_UNK;
    Inc(Count);
  end;

  for i := 0 to High(Tokens) do
  begin
    if FMap.TryGetValue(Tokens[i], ID) then Result[Count] := ID
    else Result[Count] := TOKEN_UNK;
    Inc(Count);
  end;

  if AddSpecial then
  begin
    if FMap.TryGetValue('<EOS>', ID) then Result[Count] := ID else Result[Count] := TOKEN_UNK;
    Inc(Count);
  end;
end;

function TAvoTokenizer.EncodeBatch(const Texts: array of UnicodeString; AddSpecial: Boolean = False): TBatchIntegerDynArray;
var i: Integer;
begin
  SetLength(Result, Length(Texts));
  for i := 0 to High(Texts) do Result[i] := Encode(Texts[i], AddSpecial);
end;

function TAvoTokenizer.Decode(const IDs: TIntegerDynArray; SkipSpecial: Boolean = True): UnicodeString;
var
  i, ID: Integer;
  W: UnicodeString;
  PrevNoSpace, IsPunctStart, IsPunctEnd: Boolean;
begin
  Result := '';
  PrevNoSpace := False;

  for i := 0 to High(IDs) do
  begin
    ID := IDs[i];
    if (ID >= 0) and (ID < FVocabSize) then W := FIdToWord[ID]
    else W := '<UNK>';

    if ID < 8 then
    begin
      if W = '<NEWLINE>' then
      begin
        Result := TrimRight(Result) + #13#10;
        PrevNoSpace := True;
      end
      else if W = '<TAB>' then
      begin
        Result := Result + #9;
        PrevNoSpace := True;
      end
      else if not SkipSpecial then
        Result := Result + W + ' ';
      Continue;
    end;

    IsPunctStart := (Length(W) = 1) and ((W = '.') or (W = ',') or (W = ';') or (W = ':') or (W = '!') or (W = '?') or (W = ')') or (W = ']') or (W = '}'));
    IsPunctEnd := (Length(W) = 1) and ((W = '(') or (W = '[') or (W = '{'));

    if IsPunctStart and not PrevNoSpace then
      Result := TrimRight(Result);

    Result := Result + W;

    if IsPunctEnd then PrevNoSpace := True
    else
    begin
      Result := Result + ' ';
      PrevNoSpace := False;
    end;
  end;
  Result := TrimRight(Result);
end;

procedure TAvoTokenizer.SaveVocab(const FileName: String);
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    SL.Add('# AvoTokenizer v8 (Code-Aware Lexer Edition, MemOpt)');
    for i := 0 to FMap.FCount - 1 do
      SL.Add(IntToStr(FMap.FEntries[i].Value) + #9 + UTF8Encode(FMap.FEntries[i].Key));
    SL.SaveToFile(FileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

procedure TAvoTokenizer.LoadVocab(const FileName: String);
var
  SL, Parts: TStringList;
  i, ID: Integer;
  Line: String;
begin
  Clear;
  SL := TStringList.Create;
  Parts := TStringList.Create;
  Parts.Delimiter := #9;
  Parts.StrictDelimiter := True;

  try
    SL.LoadFromFile(FileName, TEncoding.UTF8);
    for i := 0 to SL.Count - 1 do
    begin
      Line := Trim(SL[i]);
      if (Line = '') or (Line[1] = '#') then Continue;

      Parts.DelimitedText := Line;
      if Parts.Count >= 2 then
      begin
        ID := StrToIntDef(Parts[0], -1);
        if ID >= 0 then RegisterToken(UTF8Decode(Parts[1]), ID);
      end;
    end;
  finally
    SL.Free;
    Parts.Free;
  end;
end;

procedure TAvoTokenizer.SaveVocabBin(const FileName: String);
var
  FS: TFileStream;
  i, L, ID: Integer;
  UTF8Key: String;
  Magic: array[0..3] of Byte;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    Magic[0] := Ord('A'); Magic[1] := Ord('V'); Magic[2] := Ord('O'); Magic[3] := Ord('V');
    FS.WriteBuffer(Magic[0], 4);
    FS.WriteBuffer(FMap.FCount, SizeOf(Integer));
    for i := 0 to FMap.FCount - 1 do
    begin
      ID := FMap.FEntries[i].Value;
      FS.WriteBuffer(ID, SizeOf(Integer));

      UTF8Key := UTF8Encode(FMap.FEntries[i].Key);
      L := Length(UTF8Key);
      FS.WriteBuffer(L, SizeOf(Integer));
      if L > 0 then FS.WriteBuffer(UTF8Key[1], L);
    end;
  finally
    FS.Free;
  end;
end;

procedure TAvoTokenizer.LoadVocabBin(const FileName: String);
var
  FS: TFileStream;
  i, L, ID, Cnt: Integer;
  UTF8Key: String;
  Magic: array[0..3] of Byte;
begin
  Clear;
  FS := TFileStream.Create(FileName, fmOpenRead);
  try
    FS.ReadBuffer(Magic[0], 4);
    if (Magic[0] <> Ord('A')) or (Magic[1] <> Ord('V')) or (Magic[2] <> Ord('O')) or (Magic[3] <> Ord('V')) then
      raise Exception.Create('TAvoTokenizer: Błędny lub uszkodzony format pliku .vocabbin');

    FS.ReadBuffer(Cnt, SizeOf(Integer));
    for i := 0 to Cnt - 1 do
    begin
      FS.ReadBuffer(ID, SizeOf(Integer));
      FS.ReadBuffer(L, SizeOf(Integer));
      SetLength(UTF8Key, L);
      if L > 0 then FS.ReadBuffer(UTF8Key[1], L);

      RegisterToken(UTF8Decode(UTF8Key), ID);
    end;
  finally
    FS.Free;
  end;
end;

end.


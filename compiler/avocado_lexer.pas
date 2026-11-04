unit avocado_lexer;

{$mode objfpc}{$H+}

{ Single lexer (tokenizer) for Avocado.
  Recognizes identifiers, keywords, numbers, strings, comments, operators,
  separators and raw Pascal/assembler escape blocks.
  Tracks byte offset, line and codepoint column for every token. }

interface

uses
  SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens, avocado_language;

type
  TAvocadoLexer = class
  private
    FSrc: TAvocadoSource;
    FLang: TAvocadoLanguage;
    FDiags: TAvocadoDiagnosticList;
    FText: string;
    FPos: Integer;          // 1-based byte position in FText
    FTokens: TAvocadoTokenArray;
    FCount: Integer;
    FPendingNewline: Boolean;
    procedure AddToken(const ATok: TAvocadoToken);
    function Peek(AOff: Integer = 0): Char;
    function AtEnd: Boolean;
    procedure SkipWhitespaceAndComments;
    procedure LexLineComment;
    procedure LexBlockComment;
    function LexIdentifierOrKeyword: TAvocadoToken;
    function LexNumber: TAvocadoToken;
    function LexString: TAvocadoToken;
    function LexEscapeBlock(const AKind: TAvocadoTokenKind): TAvocadoToken;
    function MakeToken(AKind: TAvocadoTokenKind; AStart: Integer): TAvocadoToken;
    function IsIdentStart(C: Char): Boolean;
    function IsIdentPart(C: Char): Boolean;
  public
    constructor Create(ASrc: TAvocadoSource; ALang: TAvocadoLanguage;
      ADiags: TAvocadoDiagnosticList);
    function Tokenize: TAvocadoTokenArray;
    property Tokens: TAvocadoTokenArray read FTokens;
  end;

implementation

constructor TAvocadoLexer.Create(ASrc: TAvocadoSource; ALang: TAvocadoLanguage;
  ADiags: TAvocadoDiagnosticList);
begin
  inherited Create;
  FSrc := ASrc;
  FLang := ALang;
  FDiags := ADiags;
  FText := ASrc.Text;
  FPos := 1;
  FCount := 0;
  FPendingNewline := False;
  SetLength(FTokens, 0);
end;

function TAvocadoLexer.AtEnd: Boolean;
begin
  Result := FPos > Length(FText);
end;

function TAvocadoLexer.Peek(AOff: Integer): Char;
begin
  if FPos + AOff <= Length(FText) then
    Result := FText[FPos + AOff]
  else
    Result := #0;
end;

function TAvocadoLexer.IsIdentStart(C: Char): Boolean;
begin
  Result := (C = '_') or ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
    (Ord(C) >= $80); // any non-ASCII byte may start a UTF-8 identifier char
end;

function TAvocadoLexer.IsIdentPart(C: Char): Boolean;
begin
  Result := IsIdentStart(C) or ((C >= '0') and (C <= '9'));
end;

procedure TAvocadoLexer.AddToken(const ATok: TAvocadoToken);
var
  T: TAvocadoToken;
begin
  T := ATok;
  T.NewlineBefore := FPendingNewline;
  FPendingNewline := False;
  if FCount >= Length(FTokens) then
    SetLength(FTokens, (FCount + 8) * 2);
  FTokens[FCount] := T;
  Inc(FCount);
end;

function TAvocadoLexer.MakeToken(AKind: TAvocadoTokenKind; AStart: Integer): TAvocadoToken;
var
  Span: TAvocadoSourceSpan;
begin
  Span := FSrc.GetSpan(AStart, FPos);
  Result.Kind := AKind;
  Result.Spelling := Copy(FText, AStart, FPos - AStart);
  Result.Text := Result.Spelling;
  Result.IntValue := 0;
  Result.FloatValue := 0.0;
  Result.HasValue := False;
  Result.StartOffset := AStart - 1;
  Result.EndOffset := FPos - 1;
  Result.Line := Span.StartPos.Line;
  Result.Col := Span.StartPos.Col;
  Result.NewlineBefore := False;
  Result.NewlineAfter := False;
end;

procedure TAvocadoLexer.LexLineComment;
begin
  // at '//'
  while (not AtEnd) and (Peek <> #10) do
    Inc(FPos);
end;

procedure TAvocadoLexer.LexBlockComment;
var
  Depth: Integer;
  Start: Integer;
begin
  Start := FPos - 2;
  Depth := 1;
  while not AtEnd do
  begin
    if (Peek = '(') and (Peek(1) = '*') then
    begin
      Inc(Depth);
      Inc(FPos, 2);
    end
    else if (Peek = '*') and (Peek(1) = ')') then
    begin
      Dec(Depth);
      Inc(FPos, 2);
      if Depth = 0 then Exit;
    end
    else
      Inc(FPos);
  end;
  FDiags.AddError(AVOK_LexUnterminatedComment,
    'Nie zamknięty komentarz (* ... *)',
    FSrc.GetSpan(Start, FPos), FSrc.FileName);
end;

procedure TAvocadoLexer.SkipWhitespaceAndComments;
begin
  while not AtEnd do
  begin
    case Peek of
      #10:
        begin
          FPendingNewline := True;
          Inc(FPos);
        end;
      #13:
        begin
          Inc(FPos); // CR of CRLF or lone CR
          if Peek = #10 then
          begin
            FPendingNewline := True;
            Inc(FPos);
          end
          else
            FPendingNewline := True;
        end;
      #9, #32, #11, #12:
        Inc(FPos);
      '/':
        if Peek(1) = '/' then
          LexLineComment
        else
          Break;
      '(':
        if Peek(1) = '*' then
        begin
          Inc(FPos, 2);
          LexBlockComment;
        end
        else
          Break;
    else
      Break;
    end;
  end;
end;

function TAvocadoLexer.LexIdentifierOrKeyword: TAvocadoToken;
var
  Start, SavedPos: Integer;
  Word: string;
  Kind: TAvocadoTokenKind;
  Lower: string;
begin
  Start := FPos;
  while (not AtEnd) and IsIdentPart(Peek) do
  begin
    // consume whole UTF-8 sequence
    if Ord(Peek) >= $80 then
    begin
      if (Ord(Peek) >= $C0) and (Ord(Peek) < $E0) then Inc(FPos, 2)
      else if (Ord(Peek) >= $E0) and (Ord(Peek) < $F0) then Inc(FPos, 3)
      else if (Ord(Peek) >= $F0) then Inc(FPos, 4)
      else Inc(FPos);
    end
    else
      Inc(FPos);
  end;
  Word := Copy(FText, Start, FPos - Start);
  Lower := AvocadoLowerCase(Word);

  // escape blocks: pascal{, pascal_linia{, pascal_line{, asm{ (allowing optional whitespace before {)
  if (Lower = 'pascal') or (Lower = 'pascal_linia') or (Lower = 'pascal_line') or (Lower = 'asm') then
  begin
    SavedPos := FPos;
    while (Peek in [#9, #32]) do Inc(FPos);
    if Peek = '{' then
    begin
      Inc(FPos); // consume {
      if Lower = 'pascal' then
        Result := LexEscapeBlock(tkPascalBlock)
      else if (Lower = 'pascal_linia') or (Lower = 'pascal_line') then
        Result := LexEscapeBlock(tkPascalLine)
      else
        Result := LexEscapeBlock(tkAsmBlock);
      Exit;
    end
    else
      FPos := SavedPos;
  end;

  Kind := KeywordKindFor(Lower);
  Result := MakeToken(Kind, Start);
  Result.Text := Word;
  Result.Spelling := Word;
end;

function TAvocadoLexer.LexEscapeBlock(const AKind: TAvocadoTokenKind): TAvocadoToken;
var
  Start: Integer;
  Depth: Integer;
  Raw: string;
begin
  // FPos is just after '{'
  Start := FPos;
  Depth := 1;
  while not AtEnd do
  begin
    if Peek = '{' then
    begin
      Inc(Depth);
      Inc(FPos);
    end
    else if Peek = '}' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Raw := Copy(FText, Start, FPos - Start);
        Inc(FPos); // consume }
        Result := MakeToken(AKind, Start);
        Result.Text := Raw;
        Result.Spelling := Raw;
        Exit;
      end;
      Inc(FPos);
    end
    else if Peek = #13 then
    begin
      FPendingNewline := True;
      Inc(FPos);
      if Peek = #10 then Inc(FPos);
    end
    else if Peek = #10 then
    begin
      FPendingNewline := True;
      Inc(FPos);
    end
    else
      Inc(FPos);
  end;
  Raw := Copy(FText, Start, FPos - Start);
  Result := MakeToken(AKind, Start);
  Result.Text := Raw;
  Result.Spelling := Raw;
  FDiags.AddError(AVOK_LexUnterminatedEscape,
    'Nie zamknięty blok escape (brak znaku })',
    FSrc.GetSpan(Start - 1, FPos), FSrc.FileName);
end;

function TAvocadoLexer.LexNumber: TAvocadoToken;
var
  Start: Integer;
  IsFloat: Boolean;
  S: string;
  V: Int64;
  F: Double;
  Code: Integer;
begin
  Start := FPos;
  IsFloat := False;
  if Peek = '$' then
  begin
    Inc(FPos);
    while (not AtEnd) and (Peek in ['0'..'9', 'A'..'F', 'a'..'f']) do
      Inc(FPos);
    S := Copy(FText, Start + 1, FPos - Start - 1);
    Result := MakeToken(tkHex, Start);
    Val('$' + S, V, Code);
    if Code = 0 then
    begin
      Result.IntValue := V;
      Result.HasValue := True;
    end
    else
      FDiags.AddError(AVOK_LexBadNumber, 'Nieprawidłowa liczba szesnastkowa: ' + Result.Spelling,
        FSrc.GetSpan(Start, FPos), FSrc.FileName);
    Exit;
  end;
  while (not AtEnd) and (Peek in ['0'..'9']) do
    Inc(FPos);
  if (Peek = '.') and (Peek(1) in ['0'..'9']) then
  begin
    IsFloat := True;
    Inc(FPos);
    while (not AtEnd) and (Peek in ['0'..'9']) do
      Inc(FPos);
  end;
  if (Peek = 'e') or (Peek = 'E') then
  begin
    IsFloat := True;
    Inc(FPos);
    if (Peek = '+') or (Peek = '-') then Inc(FPos);
    while (not AtEnd) and (Peek in ['0'..'9']) do
      Inc(FPos);
  end;
  S := Copy(FText, Start, FPos - Start);
  if IsFloat then
  begin
    Result := MakeToken(tkFloat, Start);
    Val(S, F, Code);
    if Code = 0 then
    begin
      Result.FloatValue := F;
      Result.HasValue := True;
    end
    else
      FDiags.AddError(AVOK_LexBadNumber, 'Nieprawidłowa liczba: ' + S,
        FSrc.GetSpan(Start, FPos), FSrc.FileName);
  end
  else
  begin
    Result := MakeToken(tkInteger, Start);
    Val(S, V, Code);
    if Code = 0 then
    begin
      Result.IntValue := V;
      Result.HasValue := True;
    end
    else
      FDiags.AddError(AVOK_LexBadNumber, 'Nieprawidłowa liczba: ' + S,
        FSrc.GetSpan(Start, FPos), FSrc.FileName);
  end;
end;

function TAvocadoLexer.LexString: TAvocadoToken;
var
  Start: Integer;
  Value: string;
  Quote: Char;
  Closed: Boolean;
begin
  Start := FPos;
  Quote := Peek; // ' or "
  Inc(FPos);
  Value := '';
  Closed := False;
  while not AtEnd do
  begin
    if Peek = Quote then
    begin
      if Peek(1) = Quote then
      begin
        // doubled quote escape
        Value := Value + Quote;
        Inc(FPos, 2);
      end
      else
      begin
        Inc(FPos);
        Closed := True;
        Break;
      end;
    end
    else if Peek = '\' then
    begin
      Inc(FPos);
      if not AtEnd then
      begin
        case Peek of
          'n': Value := Value + #10;
          'r': Value := Value + #13;
          't': Value := Value + #9;
          '\': Value := Value + '\';
          '''': Value := Value + '''';
          '"': Value := Value + '"';
        else
          Value := Value + '\' + Peek;
        end;
        Inc(FPos);
      end;
    end
    else if (Peek = #10) or (Peek = #13) then
    begin
      // strings do not span lines in Avocado examples
      Break;
    end
    else
    begin
      Value := Value + Peek;
      Inc(FPos);
    end;
  end;
  if not Closed then
    FDiags.AddError(AVOK_LexUnterminatedString, 'Nie zamknięty napis',
      FSrc.GetSpan(Start, FPos), FSrc.FileName);
  Result := MakeToken(tkString, Start);
  Result.Text := Value;
  Result.HasValue := True;
end;

function TAvocadoLexer.Tokenize: TAvocadoTokenArray;
var
  C: Char;
  Start: Integer;
  T: TAvocadoToken;
begin
  FPos := 1;
  FCount := 0;
  FPendingNewline := False;
  SetLength(FTokens, 64);

  while True do
  begin
    SkipWhitespaceAndComments;
    if AtEnd then Break;

    C := Peek;
    Start := FPos;

    if IsIdentStart(C) then
    begin
      T := LexIdentifierOrKeyword;
      AddToken(T);
      Continue;
    end;

    if (C >= '0') and (C <= '9') then
    begin
      T := LexNumber;
      AddToken(T);
      Continue;
    end;

    if C = '$' then
    begin
      T := LexNumber;
      AddToken(T);
      Continue;
    end;

    if (C = '''') or (C = '"') then
    begin
      T := LexString;
      AddToken(T);
      Continue;
    end;

    case C of
      '+': begin Inc(FPos); AddToken(MakeToken(tkPlus, Start)); end;
      '-': begin Inc(FPos); AddToken(MakeToken(tkMinus, Start)); end;
      '*': begin Inc(FPos); AddToken(MakeToken(tkStar, Start)); end;
      '/': begin Inc(FPos); AddToken(MakeToken(tkSlash, Start)); end;
      '@': begin Inc(FPos); AddToken(MakeToken(tkAt, Start)); end;
      '^': begin Inc(FPos); AddToken(MakeToken(tkCaret, Start)); end;
      '#': begin Inc(FPos); AddToken(MakeToken(tkHash, Start)); end;
      ':':
        begin
          Inc(FPos);
          // allow := as assign-like (Pascal embed / rare)
          if Peek = '=' then
          begin
            Inc(FPos);
            AddToken(MakeToken(tkAssign, Start));
          end
          else
            AddToken(MakeToken(tkColon, Start));
        end;
      ';': begin Inc(FPos); AddToken(MakeToken(tkSemi, Start)); end;
      ',': begin Inc(FPos); AddToken(MakeToken(tkComma, Start)); end;
      '(':
        begin
          Inc(FPos);
          AddToken(MakeToken(tkLParen, Start));
        end;
      ')': begin Inc(FPos); AddToken(MakeToken(tkRParen, Start)); end;
      '[': begin Inc(FPos); AddToken(MakeToken(tkLBracket, Start)); end;
      ']': begin Inc(FPos); AddToken(MakeToken(tkRBracket, Start)); end;
      '=': begin Inc(FPos); AddToken(MakeToken(tkAssign, Start)); end;
      '.':
        begin
          Inc(FPos);
          if Peek = '.' then
          begin
            Inc(FPos);
            AddToken(MakeToken(tkDotDot, Start));
          end
          else
            AddToken(MakeToken(tkDot, Start));
        end;
      '<':
        begin
          Inc(FPos);
          if Peek = '=' then
          begin
            Inc(FPos);
            AddToken(MakeToken(tkLessEqual, Start));
          end
          else if Peek = '>' then
          begin
            Inc(FPos);
            AddToken(MakeToken(tkNotEqual, Start));
          end
          else
            AddToken(MakeToken(tkLess, Start));
        end;
      '>':
        begin
          Inc(FPos);
          if Peek = '=' then
          begin
            Inc(FPos);
            AddToken(MakeToken(tkGreaterEqual, Start));
          end
          else
            AddToken(MakeToken(tkGreater, Start));
        end;
    else
      begin
        FDiags.AddError(AVOK_LexInvalidChar,
          Format('Nieznany znak %s', [IntToHex(Ord(C), 2)]),
          FSrc.GetSpan(FPos, FPos + 1), FSrc.FileName);
        Inc(FPos);
      end;
    end;
  end;

  // EOF token
  Start := FPos;
  T := MakeToken(tkEndOfFile, Start);
  T.Text := '';
  T.Spelling := '';
  AddToken(T);
  SetLength(FTokens, FCount);
  Result := FTokens;
end;

end.

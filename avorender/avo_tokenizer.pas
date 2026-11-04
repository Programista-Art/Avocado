unit avo_tokenizer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, avo_types;

type
  tokenizer_t = record
    source: string;
    pos: integer;
    len: integer;
    line: integer;
    column: integer;
  end;

procedure tokenizer_init(var t: tokenizer_t; const source: string);
function tokenizer_next_token(var t: tokenizer_t): token_t;
function is_keyword(const s: string): boolean;

implementation

procedure tokenizer_init(var t: tokenizer_t; const source: string);
begin
  t.source := source;
  t.pos := 1;
  t.len := Length(source);
  t.line := 1;
  t.column := 1;
end;

function is_whitespace(c: char): boolean;
begin
  Result := (c = ' ') or (c = #9) or (c = #10) or (c = #13);
end;

function is_alpha(c: char): boolean;
begin
  // To naively support Polish characters in a byte-by-byte iteration, 
  // we check if the char code is > 127 or within standard ranges.
  Result := (c in ['a'..'z', 'A'..'Z', '_']) or (Ord(c) > 127);
end;

function is_digit(c: char): boolean;
begin
  Result := c in ['0'..'9'];
end;

function is_keyword(const s: string): boolean;
var
  lower_s: string;
begin
  lower_s := LowerCase(s);
  Result := (lower_s = 'zmienna') or
            (lower_s = 'stworz_element') or
            (lower_s = 'ustaw_styl') or
            (lower_s = 'dodaj_dziecko') or
            (lower_s = 'funkcja') or
            (lower_s = 'ustaw_tekst') or
            (lower_s = 'ustaw_atrybut') or
            (lower_s = 'nasluchuj_zdarzenia') or
            (lower_s = 'start') or
            (lower_s = 'początek') or
            (lower_s = 'poczatek') or
            (lower_s = 'end') or
            (lower_s = 'koniec') or
            (lower_s = 'pobierz_cialo') or
            (lower_s = 'stala') or
            (lower_s = 'jesli') or
            (lower_s = 'powtarzaj') or
            (lower_s = 'wyslij_sygnal') or
            (lower_s = 'pobierz_wartosc') or
            (lower_s = 'pobierz_z_sieci') or
            (lower_s = 'parsuj_json') or
            (lower_s = 'pobierz_pole') or
            (lower_s = 'za_czas') or
            (lower_s = 'wykonuj_co') or
            (lower_s = 'wyszukaj_element') or
            (lower_s = 'wyslij_do_sieci') or
            (lower_s = 'bezpieczny_tekst') or
            (lower_s = 'w_przeciwnym_razie') or
            (lower_s = 'ustaw_wartosc') or
            (lower_s = 'zatrzymaj_wykonywanie') or
            (lower_s = 'usun_element') or
            (lower_s = 'losuj_liczbe') or
            (lower_s = 'zapisz_lokalnie') or
            (lower_s = 'odczytaj_lokalnie') or
            (lower_s = 'dodaj_do_listy') or
            (lower_s = 'rozmiar_listy');
end;

procedure advance(var t: tokenizer_t);
begin
  if t.pos <= t.len then
  begin
    if t.source[t.pos] = #10 then
    begin
      Inc(t.line);
      t.column := 1;
    end
    else
      Inc(t.column);
    Inc(t.pos);
  end;
end;

function tokenizer_next_token(var t: tokenizer_t): token_t;
var
  start_col, start_line: integer;
  value: string;
  c: char;
begin
  while t.pos <= t.len do
  begin
    if is_whitespace(t.source[t.pos]) then
      advance(t)
    // Single-line comment: //
    else if (t.source[t.pos] = '/') and (t.pos < t.len) and (t.source[t.pos + 1] = '/') then
    begin
      advance(t); // skip first '/'
      advance(t); // skip second '/'
      while (t.pos <= t.len) and (t.source[t.pos] <> #10) and (t.source[t.pos] <> #13) do
        advance(t);
    end
    // Multi-line comment block: (* ... *)
    else if (t.source[t.pos] = '(') and (t.pos < t.len) and (t.source[t.pos + 1] = '*') then
    begin
      advance(t); // skip '('
      advance(t); // skip '*'
      while t.pos <= t.len do
      begin
        if (t.source[t.pos] = '*') and (t.pos < t.len) and (t.source[t.pos + 1] = ')') then
        begin
          advance(t); // skip '*'
          advance(t); // skip ')'
          Break;
        end;
        advance(t);
      end;
    end
    else
      Break;
  end;

  if t.pos > t.len then
    Exit(create_token(tk_eof, '', t.line, t.column));

  start_col := t.column;
  start_line := t.line;
  c := t.source[t.pos];

  // Identifiers and Keywords
  if is_alpha(c) then
  begin
    value := '';
    while (t.pos <= t.len) and (is_alpha(t.source[t.pos]) or is_digit(t.source[t.pos])) do
    begin
      value := value + t.source[t.pos];
      advance(t);
    end;

    if is_keyword(value) then
      Result := create_token(tk_keyword, value, start_line, start_col)
    else
      Result := create_token(tk_identifier, value, start_line, start_col);
    Exit;
  end;

  // Numbers
  if is_digit(c) then
  begin
    value := '';
    while (t.pos <= t.len) and is_digit(t.source[t.pos]) do
    begin
      value := value + t.source[t.pos];
      advance(t);
    end;
    Result := create_token(tk_number, value, start_line, start_col);
    Exit;
  end;

  // Strings
  if (c = '"') or (c = '''') then
  begin
    advance(t); // Skip opening quote
    value := '';
    while (t.pos <= t.len) and (t.source[t.pos] <> c) do
    begin
      value := value + t.source[t.pos];
      advance(t);
    end;
    if t.pos <= t.len then advance(t); // Skip closing quote
    Result := create_token(tk_string, value, start_line, start_col);
    Exit;
  end;

  // Operators
  if c in ['=', '>', '<', '+', '-', '*', '/', '!'] then
  begin
    value := c;
    advance(t);
    if (t.pos <= t.len) and (t.source[t.pos] = '=') and ((value = '=') or (value = '<') or (value = '>') or (value = '!')) then
    begin
       value := value + '=';
       advance(t);
    end;
    Result := create_token(tk_operator, value, start_line, start_col);
    Exit;
  end;

  // Symbols
  if c in [';', '(', ')', '.', ',', '{', '}'] then
  begin
    value := c;
    advance(t);
    Result := create_token(tk_symbol, value, start_line, start_col);
    Exit;
  end;

  // Unknown character
  value := c;
  advance(t);
  Result := create_token(tk_symbol, value, start_line, start_col);
end;

end.

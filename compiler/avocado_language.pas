unit avocado_language;

{$mode objfpc}{$H+}

{ Central language definition: keyword aliases, type aliases, built-in function
  registry (including avoraiser_translate.ini mappings), and auto-import rules.
  Keywords stay distinct from built-in function aliases. }

interface

uses
  SysUtils, Classes, avocado_source, avocado_tokens, avocado_avoraiser_api;

type
  TAvocadoBuiltinKind = (
    abkFunction,     // normal call -> Pascal call
    abkProcedure,    // statement call
    abkType,         // type name
    abkConstant,     // identifier that maps to a Pascal constant
    abkSpecial       // needs custom lowering (print, read, ...)
  );

  TAvocadoBuiltin = record
    AvocadoName: string;   // lowercased alias as written in Avocado
    PascalName: string;    // name emitted in Pascal
    Kind: TAvocadoBuiltinKind;
    RequiredUnit: string;  // unit to add to uses (optional)
    MinArgs: Integer;
    MaxArgs: Integer;      // -1 = unbounded
  end;

  TAvocadoLanguage = class
  private
    FKeywords: TStringList;   // lowercased spelling -> token kind ordinal
    FTypeAliases: TStringList; // lowercased avocado type -> Pascal type
    FBuiltins: array of TAvocadoBuiltin;
    FFunctionMap: TStringList; // avoraiser_translate.ini
    procedure RegisterKeywords;
    procedure RegisterTypes;
    procedure RegisterBuiltins;
    procedure RegisterAvoraiserApi;
    procedure AddBuiltin(const AAvocado, APascal: string; AKind: TAvocadoBuiltinKind;
      const ARequiredUnit: string; AMinArgs, AMaxArgs: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFunctionMap(const AFileName: string);

    function IsKeyword(const AName: string; out AKind: TAvocadoTokenKind): Boolean;
    function IsTypeName(const AName: string): Boolean;
    function ResolveType(const AName: string): string; // '' if unknown
    function FindBuiltin(const AName: string; out ABuiltin: TAvocadoBuiltin): Boolean;
    function LookupFunctionMap(const AName: string): string; // '' if none

    { Map an identifier spelling to a keyword kind if it is a keyword. }
    function ClassifyWord(const AName: string): TAvocadoTokenKind;

    property FunctionMap: TStringList read FFunctionMap;
  end;

function KeywordKindFor(const ALowerWord: string): TAvocadoTokenKind;

implementation

function KeywordKindFor(const ALowerWord: string): TAvocadoTokenKind;
begin
  // header
  if (ALowerWord = 'program') then Exit(tkKwProgram);
  if (ALowerWord = 'program_ui') then Exit(tkKwProgramUi);
  if (ALowerWord = 'import') or (ALowerWord = 'importuj') then Exit(tkKwImport);
  if (ALowerWord = 'moduły_pas') or (ALowerWord = 'moduly_pas') then Exit(tkKwModulePas);

  // blocks
  if (ALowerWord = 'początek') or (ALowerWord = 'poczatek') or
     (ALowerWord = 'start') or (ALowerWord = 'główny') or (ALowerWord = 'glowny') or
     (ALowerWord = 'main') then Exit(tkKwMainOpen);
  if (ALowerWord = 'koniec') or (ALowerWord = 'end') then Exit(tkKwBlockEnd);

  // subroutines
  if (ALowerWord = 'procedura') or (ALowerWord = 'procedure') then Exit(tkKwProcedure);
  if (ALowerWord = 'funkcja') or (ALowerWord = 'function') then Exit(tkKwFunction);
  if (ALowerWord = 'zwróć') or (ALowerWord = 'zwroc') or (ALowerWord = 'return') then
    Exit(tkKwReturn);

  // conditionals
  if (ALowerWord = 'jeżeli') or (ALowerWord = 'jezeli') or (ALowerWord = 'if') then
    Exit(tkKwIf);
  if (ALowerWord = 'wtedy') or (ALowerWord = 'then') then Exit(tkKwThen);
  if (ALowerWord = 'inaczej') or (ALowerWord = 'else') then Exit(tkKwElse);

  // loops
  if (ALowerWord = 'dla') or (ALowerWord = 'for') then Exit(tkKwFor);
  if (ALowerWord = 'malejąco') or (ALowerWord = 'malejaco') or (ALowerWord = 'downto') then
    Exit(tkKwDownto);
  if (ALowerWord = 'w') or (ALowerWord = 'in') then Exit(tkKwIn);
  if (ALowerWord = 'wykonaj') or (ALowerWord = 'wykonać') or (ALowerWord = 'wykonac') or
     (ALowerWord = 'make') or (ALowerWord = 'do') then Exit(tkKwDo);
  if (ALowerWord = 'dopóki') or (ALowerWord = 'dopoki') or (ALowerWord = 'while') then
    Exit(tkKwWhile);
  if (ALowerWord = 'repeat') then Exit(tkKwRepeat);
  if (ALowerWord = 'until') or (ALowerWord = 'aż') or (ALowerWord = 'az') then Exit(tkKwUntil);

  // control
  if (ALowerWord = 'przerwij') or (ALowerWord = 'break') then Exit(tkKwBreak);
  if (ALowerWord = 'kontynuuj') or (ALowerWord = 'continue') then Exit(tkKwContinue);
  if (ALowerWord = 'exit') or (ALowerWord = 'wyjście') or (ALowerWord = 'wyjscie') then
    Exit(tkKwExit);

  // literals / operators
  if (ALowerWord = 'prawda') or (ALowerWord = 'true') then Exit(tkKwTrue);
  if (ALowerWord = 'fałsz') or (ALowerWord = 'falsz') or (ALowerWord = 'false') then
    Exit(tkKwFalse);
  if (ALowerWord = 'not') then Exit(tkKwNot);
  // Polish 'i' (= and) is intentionally NOT a keyword: it is the standard
  // loop-variable name in examples (dla i = 1 do 5). Use 'and' instead.
  if (ALowerWord = 'and') then Exit(tkKwAnd);
  if (ALowerWord = 'or') or (ALowerWord = 'lub') then Exit(tkKwOr);
  if (ALowerWord = 'div') then Exit(tkKwDiv);
  if (ALowerWord = 'mod') then Exit(tkKwMod);
  if (ALowerWord = 'nil') or (ALowerWord = '_n_') then Exit(tkKwNil);

  // English 'to' is the for-loop upper bound marker; Polish uses 'do'
  // which is already tkKwDo. The parser accepts tkKwDo as 'to' in for-loops.
  if (ALowerWord = 'to') then Exit(tkKwTo);

  Result := tkIdentifier;
end;

{ TAvocadoLanguage }

constructor TAvocadoLanguage.Create;
begin
  inherited Create;
  FKeywords := TStringList.Create;
  FKeywords.CaseSensitive := False;
  FTypeAliases := TStringList.Create;
  FTypeAliases.CaseSensitive := False;
  FFunctionMap := TStringList.Create;
  FFunctionMap.CaseSensitive := False;
  RegisterKeywords;
  RegisterTypes;
  RegisterBuiltins;
  RegisterAvoraiserApi;
end;

procedure TAvocadoLanguage.RegisterAvoraiserApi;
var
  T: TAvoApiTable;
  I: Integer;
begin
  T := AvoraiserApiTable;
  for I := 0 to High(T) do
  begin
    AddBuiltin(T[I].Avo, T[I].Pascal, abkFunction, T[I].UnitName, T[I].MinArgs, T[I].MaxArgs);
    if (T[I].Pascal <> '') and (T[I].Pascal <> T[I].Avo) then
      AddBuiltin(T[I].Pascal, T[I].Pascal, abkFunction, T[I].UnitName, T[I].MinArgs, T[I].MaxArgs);
  end;
end;

destructor TAvocadoLanguage.Destroy;
begin
  FKeywords.Free;
  FTypeAliases.Free;
  FFunctionMap.Free;
  inherited Destroy;
end;

procedure TAvocadoLanguage.RegisterKeywords;
begin
  // keywords are classified via KeywordKindFor; the list is kept for lookup
  FKeywords.Add('program');
  FKeywords.Add('program_ui');
  FKeywords.Add('import');
  FKeywords.Add('importuj');
end;

procedure TAvocadoLanguage.RegisterTypes;
begin
  FTypeAliases.Values['liczba_całkowita'] := 'Integer';
  FTypeAliases.Values['liczba_calkowita'] := 'Integer';
  FTypeAliases.Values['lc'] := 'Integer';
  FTypeAliases.Values['int'] := 'Integer';
  FTypeAliases.Values['integer'] := 'Integer';

  FTypeAliases.Values['liczba_krótka'] := 'ShortInt';
  FTypeAliases.Values['liczba_krotka'] := 'ShortInt';
  FTypeAliases.Values['int8'] := 'ShortInt';
  FTypeAliases.Values['shortint'] := 'ShortInt';

  FTypeAliases.Values['liczba_mała'] := 'SmallInt';
  FTypeAliases.Values['liczba_mala'] := 'SmallInt';
  FTypeAliases.Values['int16'] := 'SmallInt';
  FTypeAliases.Values['smallint'] := 'SmallInt';

  FTypeAliases.Values['liczba_długa'] := 'LongInt';
  FTypeAliases.Values['liczba_dluga'] := 'LongInt';
  FTypeAliases.Values['int32'] := 'LongInt';
  FTypeAliases.Values['longint'] := 'LongInt';

  FTypeAliases.Values['bajt'] := 'Byte';
  FTypeAliases.Values['byte'] := 'Byte';
  FTypeAliases.Values['liczba16'] := 'Word';
  FTypeAliases.Values['word'] := 'Word';
  FTypeAliases.Values['uint16'] := 'Word';
  FTypeAliases.Values['liczba32'] := 'LongWord';
  FTypeAliases.Values['longword'] := 'LongWord';
  FTypeAliases.Values['uint32'] := 'LongWord';
  FTypeAliases.Values['liczba64'] := 'Int64';
  FTypeAliases.Values['int64'] := 'Int64';
  FTypeAliases.Values['qliczba'] := 'QWord';
  FTypeAliases.Values['qword'] := 'QWord';
  FTypeAliases.Values['dslowo'] := 'DWord';
  FTypeAliases.Values['dsłowo'] := 'DWord';
  FTypeAliases.Values['dword'] := 'DWord';

  FTypeAliases.Values['liczba_pojedyncza'] := 'Single';
  FTypeAliases.Values['single'] := 'Single';
  FTypeAliases.Values['liczba_zm'] := 'Real';
  FTypeAliases.Values['lzm'] := 'Real';
  FTypeAliases.Values['real'] := 'Real';
  FTypeAliases.Values['liczba_podwójna'] := 'Double';
  FTypeAliases.Values['liczba_podwojna'] := 'Double';
  FTypeAliases.Values['double'] := 'Double';
  FTypeAliases.Values['float'] := 'Double';
  FTypeAliases.Values['liczba_rozszerzona'] := 'Extended';
  FTypeAliases.Values['extended'] := 'Extended';
  FTypeAliases.Values['float80'] := 'Extended';
  FTypeAliases.Values['liczba_waluta'] := 'Currency';
  FTypeAliases.Values['currency'] := 'Currency';
  FTypeAliases.Values['liczba_zgodna_delphi'] := 'Comp';
  FTypeAliases.Values['comp'] := 'Comp';

  FTypeAliases.Values['logiczny'] := 'Boolean';
  FTypeAliases.Values['bool'] := 'Boolean';
  FTypeAliases.Values['boolean'] := 'Boolean';
  FTypeAliases.Values['logiczny_bajt'] := 'ByteBool';
  FTypeAliases.Values['byte_bool'] := 'ByteBool';
  FTypeAliases.Values['logiczne_słowo'] := 'WordBool';
  FTypeAliases.Values['logiczne_slowo'] := 'WordBool';
  FTypeAliases.Values['word_bool'] := 'WordBool';
  FTypeAliases.Values['logiczny_długi'] := 'LongBool';
  FTypeAliases.Values['logiczny_dlugi'] := 'LongBool';
  FTypeAliases.Values['long_bool'] := 'LongBool';

  FTypeAliases.Values['tekst'] := 'String';
  FTypeAliases.Values['string'] := 'String';
  FTypeAliases.Values['tekst_ansi'] := 'AnsiString';
  FTypeAliases.Values['ansi_string'] := 'AnsiString';
  FTypeAliases.Values['tekst_unicode'] := 'UnicodeString';
  FTypeAliases.Values['unicode_string'] := 'UnicodeString';
  FTypeAliases.Values['tekst_systemowy'] := 'WideString';
  FTypeAliases.Values['wide_string'] := 'WideString';
  FTypeAliases.Values['tekst255'] := 'ShortString';
  FTypeAliases.Values['shortstring'] := 'ShortString';
  FTypeAliases.Values['string255'] := 'ShortString';

  FTypeAliases.Values['znak'] := 'Char';
  FTypeAliases.Values['char'] := 'Char';
  FTypeAliases.Values['znak_unicode'] := 'WideChar';
  FTypeAliases.Values['widechar'] := 'WideChar';
  FTypeAliases.Values['char32'] := 'WideChar';

  FTypeAliases.Values['plik'] := 'File';
  FTypeAliases.Values['file'] := 'File';
  FTypeAliases.Values['plik_tekstowy'] := 'TextFile';
  FTypeAliases.Values['textfile'] := 'TextFile';
  FTypeAliases.Values['text_file'] := 'TextFile';
  FTypeAliases.Values['plik_binarny'] := 'BinaryFile';
  FTypeAliases.Values['binaryfile'] := 'BinaryFile';
  FTypeAliases.Values['binary_file'] := 'BinaryFile';

  FTypeAliases.Values['wskaźnik'] := 'Pointer';
  FTypeAliases.Values['wskaznik'] := 'Pointer';
  FTypeAliases.Values['pointer'] := 'Pointer';

  FTypeAliases.Values['informacje_o_wyszukaniu'] := 'TSearchRec';
  FTypeAliases.Values['search_record'] := 'TSearchRec';
  FTypeAliases.Values['lista_tekstów'] := 'TStringList';
  FTypeAliases.Values['lista_tekstow'] := 'TStringList';
  FTypeAliases.Values['string_list'] := 'TStringList';
  FTypeAliases.Values['strumień_pliku'] := 'TFileStream';
  FTypeAliases.Values['strumien_pliku'] := 'TFileStream';
  FTypeAliases.Values['file_stream'] := 'TFileStream';

  FTypeAliases.Values['uchwyt_okna'] := 'HWND';
  FTypeAliases.Values['hwnd'] := 'HWND';
  FTypeAliases.Values['uchwyt_plotna'] := 'HDC';
  FTypeAliases.Values['hdc'] := 'HDC';
  FTypeAliases.Values['parametry_ui'] := 'TAvocadoWindowParams';
  FTypeAliases.Values['ui_parameters'] := 'TAvocadoWindowParams';
  FTypeAliases.Values['ui_params'] := 'TAvocadoWindowParams';
  FTypeAliases.Values['dialog_komunikatu'] := 'TMsg';
  FTypeAliases.Values['msg'] := 'TMsg';

  FTypeAliases.Values['wariant'] := 'Variant';
  FTypeAliases.Values['variant'] := 'Variant';
  FTypeAliases.Values['wariant_ole'] := 'OleVariant';
  FTypeAliases.Values['olevariant'] := 'OleVariant';
  FTypeAliases.Values['ole_variant'] := 'OleVariant';
  FTypeAliases.Values['avoraiser_event'] := 'TAvocadoEvent';
  FTypeAliases.Values['avoraiser_zdarzenie'] := 'TAvocadoEvent';
end;

procedure TAvocadoLanguage.AddBuiltin(const AAvocado, APascal: string;
  AKind: TAvocadoBuiltinKind; const ARequiredUnit: string; AMinArgs, AMaxArgs: Integer);
var
  N: Integer;
begin
  N := Length(FBuiltins);
  SetLength(FBuiltins, N + 1);
  FBuiltins[N].AvocadoName := AvocadoLowerCase(AAvocado);
  FBuiltins[N].PascalName := APascal;
  FBuiltins[N].Kind := AKind;
  FBuiltins[N].RequiredUnit := ARequiredUnit;
  FBuiltins[N].MinArgs := AMinArgs;
  FBuiltins[N].MaxArgs := AMaxArgs;
end;

procedure TAvocadoLanguage.RegisterBuiltins;
begin
  // I/O
  AddBuiltin('pisz_linie', 'WriteLn', abkSpecial, '', 0, -1);
  AddBuiltin('print_line', 'WriteLn', abkSpecial, '', 0, -1);
  AddBuiltin('pisz', 'Write', abkSpecial, '', 0, -1);
  AddBuiltin('print', 'Write', abkSpecial, '', 0, -1);
  AddBuiltin('czytaj_linie', 'ReadLn', abkSpecial, '', 0, -1);
  AddBuiltin('read_lines', 'ReadLn', abkSpecial, '', 0, -1);
  AddBuiltin('czytaj', 'Read', abkSpecial, '', 0, -1);
  AddBuiltin('read', 'Read', abkSpecial, '', 0, -1);
  AddBuiltin('czytaj_klawisz', 'ReadKey', abkSpecial, 'Crt', 0, 0);
  AddBuiltin('read_key', 'ReadKey', abkSpecial, 'Crt', 0, 0);

  // Crt
  AddBuiltin('kolor_tekstu', 'TextColor', abkProcedure, 'Crt', 1, 1);
  AddBuiltin('text_color', 'TextColor', abkProcedure, 'Crt', 1, 1);
  AddBuiltin('tło_tekstu', 'TextBackground', abkProcedure, 'Crt', 1, 1);
  AddBuiltin('tlo_tekstu', 'TextBackground', abkProcedure, 'Crt', 1, 1);
  AddBuiltin('text_background', 'TextBackground', abkProcedure, 'Crt', 1, 1);
  AddBuiltin('pozycja_kursora', 'GotoXY', abkProcedure, 'Crt', 2, 2);
  AddBuiltin('cursor_position', 'GotoXY', abkProcedure, 'Crt', 2, 2);
  AddBuiltin('klawisz_wcisniety', 'KeyPressed', abkFunction, 'Crt', 0, 0);
  AddBuiltin('klawisz_wciśnięty', 'KeyPressed', abkFunction, 'Crt', 0, 0);
  AddBuiltin('key_pressed', 'KeyPressed', abkFunction, 'Crt', 0, 0);

  // conversions / common Pascal RTL (kept as name mapping)
  AddBuiltin('liczba_na_tekst', 'IntToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('int_str', 'IntToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('inttostr', 'IntToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('strtoint', 'StrToInt', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('strtofloat', 'StrToFloat', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('floattostr', 'FloatToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('strtointdef', 'StrToIntDef', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('format', 'Format', abkFunction, 'SysUtils', 1, -1);
  AddBuiltin('writeln', 'WriteLn', abkSpecial, '', 0, -1);
  AddBuiltin('write', 'Write', abkSpecial, '', 0, -1);
  AddBuiltin('readln', 'ReadLn', abkSpecial, '', 0, -1);
  AddBuiltin('readkey', 'ReadKey', abkSpecial, 'Crt', 0, 0);
  AddBuiltin('tekst_na_liczbe', 'StrToInt', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('tekst_na_liczbę', 'StrToInt', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('str_int', 'StrToInt', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('tekst_na_zmiennoprzecinkowa', 'StrToFloat', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('tekst_na_zmiennoprzecinkową', 'StrToFloat', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('str_float', 'StrToFloat', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('zmiennoprzecinkowa_na_tekst', 'FloatToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('float_str', 'FloatToStr', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('zaokrąglij', 'Round', abkFunction, 'Math', 1, 1);
  AddBuiltin('zaokraglij', 'Round', abkFunction, 'Math', 1, 1);
  AddBuiltin('round', 'Round', abkFunction, 'Math', 1, 1);
  AddBuiltin('obetnij', 'Trunc', abkFunction, 'Math', 1, 1);
  AddBuiltin('trunc', 'Trunc', abkFunction, 'Math', 1, 1);
  AddBuiltin('losuj', 'Random', abkSpecial, '', 0, 1);
  AddBuiltin('random', 'Random', abkSpecial, '', 0, 1);
  AddBuiltin('randomize', 'Randomize', abkProcedure, '', 0, 0);
  AddBuiltin('losuj_ziarno', 'Randomize', abkProcedure, '', 0, 0);

  // strings
  AddBuiltin('długość', 'Length', abkFunction, 'System', 1, 1);
  AddBuiltin('dlugosc', 'Length', abkFunction, 'System', 1, 1);
  AddBuiltin('length', 'Length', abkFunction, 'System', 1, 1);
  AddBuiltin('kopiuj', 'Copy', abkFunction, 'System', 3, 3);
  AddBuiltin('copy', 'Copy', abkFunction, 'System', 3, 3);
  AddBuiltin('wstaw', 'Insert', abkProcedure, 'System', 3, 3);
  AddBuiltin('insert', 'Insert', abkProcedure, 'System', 3, 3);
  AddBuiltin('usuń', 'Delete', abkProcedure, 'System', 3, 3);
  AddBuiltin('usun', 'Delete', abkProcedure, 'System', 3, 3);
  AddBuiltin('delete', 'Delete', abkProcedure, 'System', 3, 3);
  AddBuiltin('szukaj', 'Pos', abkFunction, 'System', 2, 2);
  AddBuiltin('pos', 'Pos', abkFunction, 'System', 2, 2);
  AddBuiltin('powtórz_znak', 'StringOfChar', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('powtorz_znak', 'StringOfChar', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('repeat_char', 'StringOfChar', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('porównaj_tekst', 'CompareStr', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('porownaj_tekst', 'CompareStr', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('compare_text', 'CompareStr', abkFunction, 'SysUtils', 2, 2);
  AddBuiltin('przytnij', 'Trim', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('trim', 'Trim', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('duże_litery', 'UpperCase', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('duze_litery', 'UpperCase', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('małe_litery', 'LowerCase', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('male_litery', 'LowerCase', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('upper_case', 'UpperCase', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('lower_case', 'LowerCase', abkFunction, 'SysUtils', 1, 1);

  // lists
  AddBuiltin('twórz_lista_tekstów', 'TStringList.Create', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('tworz_lista_tekstow', 'TStringList.Create', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('create_string_list', 'TStringList.Create', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('dodaj_lista', 'Add', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('add_to_list', 'Add', abkSpecial, 'Classes', 2, 2);

  // files
  AddBuiltin('przypisz_plik', 'AssignFile', abkProcedure, 'SysUtils', 2, 2);
  AddBuiltin('assign_file', 'AssignFile', abkProcedure, 'SysUtils', 2, 2);
  AddBuiltin('otwórz_do_zapisu', 'Rewrite', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('otworz_do_zapisu', 'Rewrite', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('otwórz_do_odczytu', 'Reset', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('otworz_do_odczytu', 'Reset', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('zamknij_plik', 'CloseFile', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('close_file', 'CloseFile', abkProcedure, 'SysUtils', 1, 1);
  AddBuiltin('czy_istnieje_plik', 'FileExists', abkFunction, 'SysUtils', 1, 1);
  AddBuiltin('file_exists', 'FileExists', abkFunction, 'SysUtils', 1, 1);

  // misc
  AddBuiltin('zwiększ', 'Inc', abkProcedure, 'System', 1, 2);
  AddBuiltin('zwieksz', 'Inc', abkProcedure, 'System', 1, 2);
  AddBuiltin('inc', 'Inc', abkProcedure, 'System', 1, 2);
  AddBuiltin('zwolnij', 'Free', abkSpecial, '', 0, 0);
  AddBuiltin('free', 'Free', abkSpecial, '', 0, 0);
  AddBuiltin('halt', 'Halt', abkProcedure, 'System', 0, 1);
  AddBuiltin('gettickcount64', 'GetTickCount64', abkFunction, '', 0, 0);

  // Cryptography (avoraiser.cryptography / .argon2)
  AddBuiltin('szyfruj_plik_gcm', 'encrypt_file_gcm', abkProcedure, 'avoraiser.cryptography', 3, 3);
  AddBuiltin('encrypt_file_gcm', 'encrypt_file_gcm', abkProcedure, 'avoraiser.cryptography', 3, 3);
  AddBuiltin('odszyfruj_plik_gcm', 'decrypt_file_gcm', abkProcedure, 'avoraiser.cryptography', 3, 3);
  AddBuiltin('decrypt_file_gcm', 'decrypt_file_gcm', abkProcedure, 'avoraiser.cryptography', 3, 3);
  AddBuiltin('hasluj_haslo', 'HashPassword', abkFunction, 'avoraiser.cryptography.argon2', 2, 3);
  AddBuiltin('hash_password', 'HashPassword', abkFunction, 'avoraiser.cryptography.argon2', 2, 3);
  AddBuiltin('weryfikuj_haslo', 'VerifyPassword', abkFunction, 'avoraiser.cryptography.argon2', 2, 3);
  AddBuiltin('verify_password', 'VerifyPassword', abkFunction, 'avoraiser.cryptography.argon2', 2, 3);
  AddBuiltin('generuj_sol', 'GenerateSalt', abkProcedure, 'avoraiser.cryptography.argon2', 1, 2);
  AddBuiltin('generate_salt', 'GenerateSalt', abkProcedure, 'avoraiser.cryptography.argon2', 1, 2);
  AddBuiltin('domyślne_parametry_argon2', 'Argon2_DefaultParams', abkFunction, 'avoraiser.cryptography.argon2', 0, 0);
  AddBuiltin('domyslne_parametry_argon2', 'Argon2_DefaultParams', abkFunction, 'avoraiser.cryptography.argon2', 0, 0);
  AddBuiltin('argon2_default_params', 'Argon2_DefaultParams', abkFunction, 'avoraiser.cryptography.argon2', 0, 0);

  // Clipboard
  AddBuiltin('kopiuj_do_schowka', 'copy_to_clipboard', abkProcedure, 'avoraiser.clipboard', 1, 1);
  AddBuiltin('wytnij_do_schowka', 'cut_to_clipboard', abkProcedure, 'avoraiser.clipboard', 1, 1);
  AddBuiltin('wklej_ze_schowka', 'paste_from_clipboard', abkProcedure, 'avoraiser.clipboard', 1, 1);
  AddBuiltin('cofnij_ostatnia_akcje', 'undo_last_action', abkProcedure, 'avoraiser.clipboard', 1, 1);
  AddBuiltin('czy_mozna_cofnac', 'can_undo', abkFunction, 'avoraiser.clipboard', 1, 1);

  // Printer
  AddBuiltin('drukarka_pokaz_okno', 'printer_show_dialog', abkFunction, 'avoraiser.printer', 1, 2);
  AddBuiltin('drukarka_rozpocznij_dokument', 'printer_begin_doc', abkProcedure, 'avoraiser.printer', 1, 2);
  AddBuiltin('drukarka_zakoncz_dokument', 'printer_end_doc', abkProcedure, 'avoraiser.printer', 1, 1);
  AddBuiltin('drukarka_eksportuj_do_pdf', 'printer_export_to_pdf', abkFunction, 'avoraiser.printer', 1, 2);
  AddBuiltin('drukarka_ustaw_czcionke', 'printer_set_font', abkProcedure, 'avoraiser.printer', 1, 3);

  // System extras
  AddBuiltin('otworz_url', 'open_url', abkProcedure, 'avoraiser.system', 1, 1);
  AddBuiltin('czytaj_plik_do_tekstu', 'read_file_to_string', abkFunction, 'avoraiser.system', 1, 1);
  AddBuiltin('zapisz_tekst_do_pliku', 'write_string_to_file', abkProcedure, 'avoraiser.system', 2, 2);
  AddBuiltin('przetwarzaj_komunikaty', 'process_messages', abkProcedure, 'avoraiser.system', 0, 0);

  // Pascal compiler intrinsics (type-valued or type arguments)
  AddBuiltin('default', 'Default', abkFunction, '', 1, 1);
  AddBuiltin('domyslne', 'Default', abkFunction, '', 1, 1);
  AddBuiltin('domyślne', 'Default', abkFunction, '', 1, 1);
  AddBuiltin('domyslne_parametry_okna', 'window_get_default_params', abkFunction, 'avoraiser.window', 0, 0);
  AddBuiltin('domyślne_parametry_okna', 'window_get_default_params', abkFunction, 'avoraiser.window', 0, 0);
  AddBuiltin('default_window_params', 'window_get_default_params', abkFunction, 'avoraiser.window', 0, 0);
  AddBuiltin('typeinfo', 'TypeInfo', abkFunction, 'TypInfo', 1, 1);
  AddBuiltin('sizeof', 'SizeOf', abkFunction, '', 1, 1);
  AddBuiltin('high', 'High', abkFunction, '', 1, 1);
  AddBuiltin('low', 'Low', abkFunction, '', 1, 1);
  AddBuiltin('pred', 'Pred', abkFunction, '', 1, 1);
  AddBuiltin('succ', 'Succ', abkFunction, '', 1, 1);
  AddBuiltin('assigned', 'Assigned', abkFunction, '', 1, 1);
  AddBuiltin('zmniejsz', 'Dec', abkProcedure, 'System', 1, 2);
  AddBuiltin('dec', 'Dec', abkProcedure, 'System', 1, 2);
  AddBuiltin('decs', 'Dec', abkProcedure, 'System', 1, 2);
  AddBuiltin('new', 'New', abkProcedure, '', 1, 1);
  AddBuiltin('dispose', 'Dispose', abkProcedure, '', 1, 1);
  AddBuiltin('get_current_dir', 'GetCurrentDir', abkFunction, 'SysUtils', 0, 0);
  AddBuiltin('pobierz_katalog_biezacy', 'GetCurrentDir', abkFunction, 'SysUtils', 0, 0);
  AddBuiltin('pobierz_katalog_bieżący', 'GetCurrentDir', abkFunction, 'SysUtils', 0, 0);

  // stream creation / modes
  AddBuiltin('twórz_strumień_pliku', 'TFileStream.Create', abkSpecial, 'Classes', 3, 3);
  AddBuiltin('tworz_strumien_pliku', 'TFileStream.Create', abkSpecial, 'Classes', 3, 3);
  AddBuiltin('create_file_stream', 'TFileStream.Create', abkSpecial, 'Classes', 3, 3);
  AddBuiltin('tylko_odczyt', 'fmOpenRead', abkConstant, 'Classes', 0, 0);
  AddBuiltin('tylko_zapis', 'fmOpenWrite', abkConstant, 'Classes', 0, 0);
  AddBuiltin('odczyt_i_zapis', 'fmOpenReadWrite', abkConstant, 'Classes', 0, 0);
  AddBuiltin('stwórz_nowy', 'fmCreate', abkConstant, 'Classes', 0, 0);
  AddBuiltin('stworz_nowy', 'fmCreate', abkConstant, 'Classes', 0, 0);
  AddBuiltin('wspólny', 'fmShareDenyNone', abkConstant, 'Classes', 0, 0);
  AddBuiltin('wspolny', 'fmShareDenyNone', abkConstant, 'Classes', 0, 0);
  AddBuiltin('blokuj_odczyt', 'fmShareDenyRead', abkConstant, 'Classes', 0, 0);
  AddBuiltin('blokuj_zapis', 'fmShareDenyWrite', abkConstant, 'Classes', 0, 0);
  AddBuiltin('wyłączny', 'fmShareExclusive', abkConstant, 'Classes', 0, 0);
  AddBuiltin('wylaczny', 'fmShareExclusive', abkConstant, 'Classes', 0, 0);

  // list helpers (legacy names)
  AddBuiltin('teksty', 'Strings', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('strings', 'Strings', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('ilosc', 'Count', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('ilość', 'Count', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('count', 'Count', abkSpecial, 'Classes', 1, 1);
  AddBuiltin('załaduj_z_pliku', 'LoadFromFile', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('zaladuj_z_pliku', 'LoadFromFile', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('load_from_file', 'LoadFromFile', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('zapisz_do_pliku', 'SaveToFile', abkSpecial, 'Classes', 2, 2);
  AddBuiltin('save_to_file', 'SaveToFile', abkSpecial, 'Classes', 2, 2);

  // colors (bare identifiers -> Pascal color constants)
  AddBuiltin('czarny', 'Black', abkConstant, 'Crt', 0, 0);
  AddBuiltin('biały', 'White', abkConstant, 'Crt', 0, 0);
  AddBuiltin('bialy', 'White', abkConstant, 'Crt', 0, 0);
  AddBuiltin('niebieski', 'Blue', abkConstant, 'Crt', 0, 0);
  AddBuiltin('zielony', 'Green', abkConstant, 'Crt', 0, 0);
  AddBuiltin('czerwony', 'Red', abkConstant, 'Crt', 0, 0);
  AddBuiltin('żółty', 'Yellow', abkConstant, 'Crt', 0, 0);
  AddBuiltin('zolty', 'Yellow', abkConstant, 'Crt', 0, 0);
  AddBuiltin('cyjan', 'Cyan', abkConstant, 'Crt', 0, 0);
  AddBuiltin('magenta', 'Magenta', abkConstant, 'Crt', 0, 0);
  AddBuiltin('brązowy', 'Brown', abkConstant, 'Crt', 0, 0);
  AddBuiltin('brazowy', 'Brown', abkConstant, 'Crt', 0, 0);
  AddBuiltin('jasnoszary', 'LightGray', abkConstant, 'Crt', 0, 0);
  AddBuiltin('ciemnoszary', 'DarkGray', abkConstant, 'Crt', 0, 0);
  AddBuiltin('black', 'Black', abkConstant, 'Crt', 0, 0);
  AddBuiltin('white', 'White', abkConstant, 'Crt', 0, 0);
  AddBuiltin('blue', 'Blue', abkConstant, 'Crt', 0, 0);
  AddBuiltin('green', 'Green', abkConstant, 'Crt', 0, 0);
  AddBuiltin('red', 'Red', abkConstant, 'Crt', 0, 0);
  AddBuiltin('yellow', 'Yellow', abkConstant, 'Crt', 0, 0);
  AddBuiltin('cyan', 'Cyan', abkConstant, 'Crt', 0, 0);

  // GUI / avoraiser (resolved names after alias map)
  AddBuiltin('create_window', 'create_window', abkFunction, 'avoraiser.window', 1, 1);
  AddBuiltin('run_app', 'run_app', abkProcedure, 'avoraiser.window', 0, 0);
  AddBuiltin('uruchom_aplikacje', 'run_app', abkProcedure, 'avoraiser.window', 0, 0);
  AddBuiltin('center_window', 'center_window', abkProcedure, 'avoraiser.layout', 1, 1);
  AddBuiltin('show_message', 'show_message', abkProcedure, 'avoraiser.dialogs', 1, -1);
end;

procedure TAvocadoLanguage.LoadFunctionMap(const AFileName: string);
begin
  if FileExists(AFileName) then
    FFunctionMap.LoadFromFile(AFileName);
end;

function TAvocadoLanguage.IsKeyword(const AName: string; out AKind: TAvocadoTokenKind): Boolean;
begin
  AKind := KeywordKindFor(AvocadoLowerCase(AName));
  Result := AKind <> tkIdentifier;
end;

function TAvocadoLanguage.ClassifyWord(const AName: string): TAvocadoTokenKind;
begin
  Result := KeywordKindFor(AvocadoLowerCase(AName));
end;

function TAvocadoLanguage.IsTypeName(const AName: string): Boolean;
begin
  Result := FTypeAliases.IndexOfName(AvocadoLowerCase(AName)) >= 0;
end;

function TAvocadoLanguage.ResolveType(const AName: string): string;
var
  Key: string;
  I: Integer;
begin
  Key := AvocadoLowerCase(AName);
  Result := FTypeAliases.Values[Key];
  if Result <> '' then Exit;
  // already a Pascal type name (e.g. Default(TAvocadoWindowParams))
  for I := 0 to FTypeAliases.Count - 1 do
    if AvocadoLowerCase(FTypeAliases.ValueFromIndex[I]) = Key then
      Exit(FTypeAliases.ValueFromIndex[I]);
  Result := '';
end;

function TAvocadoLanguage.FindBuiltin(const AName: string; out ABuiltin: TAvocadoBuiltin): Boolean;
var
  Key: string;
  I: Integer;
begin
  Key := AvocadoLowerCase(AName);
  for I := 0 to High(FBuiltins) do
    if FBuiltins[I].AvocadoName = Key then
    begin
      ABuiltin := FBuiltins[I];
      Exit(True);
    end;
  ABuiltin := Default(TAvocadoBuiltin);
  Result := False;
end;

function TAvocadoLanguage.LookupFunctionMap(const AName: string): string;
var
  Key: string;
  I: Integer;
begin
  Key := AvocadoLowerCase(AName);
  for I := 0 to FFunctionMap.Count - 1 do
    if AvocadoLowerCase(FFunctionMap.Names[I]) = Key then
      Exit(FFunctionMap.ValueFromIndex[I]);
  Result := '';
end;

end.


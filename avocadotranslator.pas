unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils,fpexprpars,Crt,LazUTF8,Graphics,Variants,IniFiles,DefaultTranslator,LCLTranslator;

type
  TStringArray = array of string;
  TAvocadoVariable = record
  Name, VarType: string;
  VarName: string;
  NoAssign: Boolean; // nowa flaga
  end;

  { TAvocadoTranslator }

  TAvocadoTranslator = class
  private
    FVariables: array of TAvocadoVariable;
    constructor Create;
    destructor Destroy; override;

    procedure ProcessForLoop(const Line: string; PascalCode: TStringList);
    //dotyczy petli while
    procedure ProcessWhileLoop(const Line: string; PascalCode: TStringList);
   // procedure AddVariable(const Name, VarType: string);
    function TranslateExpression(const Expr: string): string;
    procedure ProcessDeclaration(const Line: string);
    procedure ProcessLine(const Line: string; PascalCode: TStringList);
    function JesliWtedyInaczej(const Warunek, WartoscJesliPrawda, WartoscJesliFalsz: string): string;
    function PrzetworzBlok(const Blok: string): string;
    //Otrzumuje nazwy modulów i wstawia do sekcji Interface
    function GetImportedModules(const Code: string): string;
    //Otrzumuje nazwy modulów i wstawia do sekcji Implementation
    function GetImplementationModules(const Code: string): string;

  public
    function Translate(const AvocadoCode: TStrings): TStringList;
    function duze_litery_ansi(const S: string): string;
    function male_litery_ansi(const S: string): string;
    function IsKnownType(const S: string): Boolean;
    procedure SplitStringByChar(const AString: string; const ASeparator: Char; AResultList: TStrings);
    function SplitArguments(const ASource: string; AStrings: TStrings): Boolean;
    procedure AddVariable(const VarName, VarType: string; NoAssign: Boolean = False);
    //Aliasy
    function ResolveAlias(const AName: string): string;
    procedure ProcessFileDeclaration(const Line: string);
  end;
var
Moduly: String;

resourcestring
  InvalidVariableDeclaration = 'Nieprawidłowa deklaracja zmiennej: ';
  ErrorPrint = 'Błędna składnia funkcji wstaw. Oczekiwano: wstaw(source, target, index)';
  FunctionInsert = 'Funkcja wstaw wymaga trzech argumentów: source, target, index';
  FunctionTrim = 'Błędna składnia funkcji przytnij. Oczekiwano: przytnij(s)';
  FunctionTrimRight = 'Błędna składnia funkcji przytnij_z_prawa. Oczekiwano: przytnij_z_prawa(s)';
  FunctionTrimLeft = 'Błędna składnia funkcji przytnij_z_lewa. Oczekiwano: przytnij_z_lewa(s)';
implementation
uses
  unit1;

{ TAvocadoTranslator }

procedure TAvocadoTranslator.AddVariable(const VarName, VarType: string; NoAssign: Boolean = False);
var
  j: Integer;
begin
    // Sprawdź, czy zmienna już istnieje
    for j := 0 to High(FVariables) do
      if FVariables[j].VarName = VarName then Exit;

    // Dodaj nowy element
    SetLength(FVariables, Length(FVariables) + 1);
    FVariables[High(FVariables)].VarName := VarName;
    FVariables[High(FVariables)].VarType := VarType;

    // Dodaj flagę NoAssign do struktury zmiennej
    FVariables[High(FVariables)].NoAssign := NoAssign;
end;

function TAvocadoTranslator.ResolveAlias(const AName: string): string;
begin
  case LowerCase(AName) of
    // liczby całkowite
    'liczba_całkowita', 'int', 'integer', 'ganzzahl', 'entier':
      Exit('Integer');

    'liczba_krótka', 'int8', 'shortint', 'kurz', 'court':
      Exit('ShortInt');

    'liczba_mała', 'int16', 'smallint', 'klein', 'petit':
      Exit('SmallInt');

    'liczba_długa', 'int32', 'longint', 'lang', 'long':
      Exit('LongInt');

    'liczba64', 'int64', 'sehrlang', 'trèslong':
      Exit('Int64');

    // liczby zmiennoprzecinkowe
    'liczba_pojedyncza', 'single', 'float', 'einfach', 'flottant':
      Exit('Single');

    'liczba_zm', 'real', 'reell', 'réel':
      Exit('Real');

    'liczba_podwójna', 'double', 'float64', 'doppelt':
      Exit('Double');

    'liczba_rozszerzona', 'extended', 'float80', 'erweitert', 'étendu':
      Exit('Extended');

    'liczba_waluta', 'currency', 'währung', 'monnaie':
      Exit('Currency');

    // logiczne
    'logiczny', 'bool', 'boolean', 'boolesch', 'booléen':
      Exit('Boolean');

    // teksty
    'tekst', 'string', 'chaine', 'zeichenkette':
      Exit('String');

    'tekst_ansi', 'ansistring', 'chaine_ansi':
      Exit('AnsiString');

    'tekst_unicode', 'unicodestring', 'chaine_unicode':
      Exit('UnicodeString');

    'tekst_systemowy', 'widestring', 'chaine_large':
      Exit('WideString');

    'tekst255', 'shortstring', 'chaîne_courte':
      Exit('ShortString');

    // znaki
    'znak', 'char', 'caractère':
      Exit('Char');

    'znak_unicode', 'widechar', 'caractère_large':
      Exit('WideChar');

    // pliki
    'plik', 'file', 'datei', 'fichier':
      Exit('File');

    'plik_tekstowy', 'textfile', 'textdatei', 'fichiertexte':
      Exit('TextFile');

    'plik_binarny', 'binaryfile', 'binärdatei', 'fichierbinaire':
      Exit('BinaryFile');

    'plik_struktur', 'typedfile', 'strukturdatei', 'fichiertypé':
      Exit('TypedFile');

    // wskaźniki
    'wskaźnik', 'pointer', 'zeiger', 'pointeur':
      Exit('Pointer');

    'wskaźnik_na', 'pointerto', '^type', 'zeigerauf':
      Exit('^Type');

    // inne
    'wariant', 'variant', 'variante':
      Exit('Variant');

    'wariant_ole', 'olevariant':
      Exit('OleVariant');
  else
    raise Exception.Create('Nieznany alias typu: ' + AName);
  end;
end;

procedure TAvocadoTranslator.ProcessFileDeclaration(const Line: string);
var
  Parts: TStringArray;
  VarDecl, VarValue: string;
  VarParts: TStringArray;
  VarType, VarName: string;
  TrimmedLine: string;
begin
  TrimmedLine := Trim(Line);
    if TrimmedLine = '' then Exit;

    // Pomijamy instrukcje sterujące
    if LowerCase(TrimmedLine).StartsWith('jeśli') then Exit;
    if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
    if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
    if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;

    // --- Obsługa deklaracji BEZ wartości ---
    if Pos(':', Line) = 0 then
    begin
      VarParts := TrimmedLine.Split([' '], 2);
      if Length(VarParts) < 2 then Exit;

      VarType := LowerCase(Trim(VarParts[0]));
      VarName := Trim(VarParts[1]);

      if (VarType = 'plik') or (VarType = 'plik_tekstowy') or
         (VarType = 'file') or (VarType = 'text_file') then
      begin
        AddVariable(VarName, VarType, True); // sama deklaracja
        Exit;
      end;

      raise Exception.Create('Nieznany typ zmiennej plikowej: ' + VarType);
    end;

    // --- Obsługa deklaracji Z wartością (po ':') ---
    Parts := Line.Split([':'], 2);
    if Length(Parts) < 2 then Exit;

    VarDecl := Trim(Parts[0]);   // np. "plik f"
    VarValue := Trim(Parts[1]);  // np. "nil" albo ścieżka do pliku

    VarParts := VarDecl.Split([' '], 2);
    if Length(VarParts) < 2 then
      raise Exception.Create(InvalidVariableDeclaration + Line);

    VarType := LowerCase(Trim(VarParts[0]));
    VarName := Trim(VarParts[1]);

    if (VarType = 'plik') or (VarType = 'plik_tekstowy') or
       (VarType = 'file') or (VarType = 'text_file') then
    begin
      if (LowerCase(VarValue) = 'nil') or (LowerCase(VarValue) = 'nic') then
        AddVariable(VarName, VarType, True)  // deklaracja bez inicjalizacji
      else
        AddVariable(VarName, VarType, False); // deklaracja z przypisaniem
      Exit;
    end;

    raise Exception.Create('Nieznany typ zmiennej plikowej: ' + VarType);
end;

// Prosta funkcja do sprawdzania, czy łańcuch jest literałem string
function IsQuotedString(const S: string): Boolean;
begin
  Result := (Length(S) >= 2) and
            ((S[1] = '''') and (S[Length(S)] = '''') or
             (S[1] = '"') and (S[Length(S)] = '"'));
end;

//Konwersje
function TAvocadoTranslator.TranslateExpression(const Expr: string): string;
begin
  Result := Expr;
  Result := StringReplace(Result, ' i ', ' and ', [rfReplaceAll]);
  Result := StringReplace(Result, ' lub ', ' or ', [rfReplaceAll]);
  Result := StringReplace(Result, 'prawda', 'True', [rfReplaceAll]);
  Result := StringReplace(Result, 'falsz', 'False', [rfReplaceAll]);
  Result := StringReplace(Result, 'tekst_w_liczbe_cal(', 'StrToInt(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWLiczbar(', 'StrToFloat(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacWTekst(', 'IntToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbarWTekst(', 'FloatToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacWr(', 'Real(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbarWc(', 'Trunc(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LogicznyWTekst(', 'BoolToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'BajtWTekst(', 'ByteBool(Ord(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Liczba_mała(', 'Shortint(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstLD(', 'StrToIntDef(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Zaokrąglij(', 'Round(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Słowo(', 'Word(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Liczba_dc(','LongInt(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Kard(','Cardinal(', [rfReplaceAll]);
  Result := StringReplace(Result, 'FormatLiczby(','FloatToStrF(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWLzm(','FloatToStrF(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbarWR(','Double(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Liczba_rozszerzonaWPojedynczą(','Extended(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Liczba_pojedynczaWZm(','Single(', [rfReplaceAll]);
  //Konwersje między typami znakowymi i stringami:
  Result := StringReplace(Result, 'ZnakwASCII(','Chr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ord(','Ord(', [rfReplaceAll]);
  Result := StringReplace(Result, 'ZnakWTekst(','Char(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWZnak(','String(', [rfReplaceAll]);
  // Konwersje między typami logicznymi:
  Result := StringReplace(Result, 'LogicznyWTekst(','BoolToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWLogiczny(','StrToBool(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWLogicznyDom(','StrToBoolDef(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LogicznyZliczby(','Boolean(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacZLogicznego(','Integer(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacZWyliczenia(','Ord(', [rfReplaceAll]);
  Result := StringReplace(Result, 'ZwróćNazwęTekst(','GetEnumName(', [rfReplaceAll]);
  Result := StringReplace(Result, 'ZwróćLiczbac(','GetEnumValue(', [rfReplaceAll]);
  //Konwersje związane z datą i czasem:
  Result := StringReplace(Result, 'DataWTekst(','DateToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'CzasWTekst(','TimeToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'DataCzasWTekst(','DateTimeToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'DataCzasWTekstF(','FormatDateTime(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWDatę(','StrToDate(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWCzas(','StrToTime(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWDatęCzas(','StrToDateTime(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWDatęDom(','StrToDateDef(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWCzasDom(','StrToTimeDef(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWDatęCzasDom(','StrToDateTimeDef(', [rfReplaceAll]);
  Result := StringReplace(Result, 'DataCzasZ(','EncodeDate(', [rfReplaceAll]);
  Result := StringReplace(Result, 'CzasZ(','EncodeTime(', [rfReplaceAll]);
  Result := StringReplace(Result, 'RozłóżDatę(','DecodeDate(', [rfReplaceAll]);
  Result := StringReplace(Result, 'RozłóżCzas(','DecodeTime(', [rfReplaceAll]);
  //Konwersje wskaźników:
  Result := StringReplace(Result, 'NiebezpiecznyWskaźnikZAdresu(','Ptr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'NiebezpiecznyAdresZWskaźnika(','Integer(', [rfReplaceAll]);
  Result := StringReplace(Result, '@(','@(', [rfReplaceAll]);
  Result := StringReplace(Result, 'klawisz_wciśnięty', 'KeyPressed', [rfReplaceAll, rfIgnoreCase]);
  //kolory
  Result := StringReplace(Result, 'czarny', 'Black', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'biały', 'White', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'niebieski', 'Blue', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'zielony', 'Green', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'czerwony', 'Red', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Żółty', 'Yellow', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'cyjan', 'Cyan', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'magenta', 'Magenta', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'brązowy', 'Brown', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnoszary', 'LightGray', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ciemnoszary', 'DarkGray', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ciemnoszary', 'DarkGray', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnoniebieski', 'LightBlue', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnozielony', 'LightGreen', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnoniebieski', 'LightCyan', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnoczerwony', 'LightRed', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'jasnoróżowy', 'LightMagenta', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'migotanie', 'Blink', [rfReplaceAll, rfIgnoreCase]);
  //funkcje string
  Result := StringReplace(Result, 'kopiuj', 'Copy', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'wstaw', 'Insert', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'szukaj', 'Pos', [rfReplaceAll, rfIgnoreCase]);
  //nil, free
  Result := StringReplace(Result, 'nic', 'nil', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '.tekst', '.Text', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'zwolnij', 'free', [rfReplaceAll, rfIgnoreCase]);


end;


procedure TAvocadoTranslator.ProcessDeclaration(const Line: string);
var
  TrimmedLine: string;
  Parts: TStringArray;
  VarDecl, VarValue: string;
  VarParts: TStringArray;
  VarType, VarName: string;
begin
  TrimmedLine := Trim(Line);
  if TrimmedLine = '' then Exit;

  // Pomijamy linie zaczynające się od instrukcji sterujących
  if LowerCase(TrimmedLine).StartsWith('jeśli') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
  if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;

  // --- Przekazanie do obsługi plików ---
  if LowerCase(TrimmedLine).StartsWith('plik') or
     LowerCase(TrimmedLine).StartsWith('plik_tekstowy') or
     LowerCase(TrimmedLine).StartsWith('file') or
     LowerCase(TrimmedLine).StartsWith('text_file') then
  begin
    ProcessFileDeclaration(Line);
    Exit;
  end;

  // --- Tu reszta Twojej starej obsługi typów (tekst, liczba_całkowita itd.) ---
  // np. Split po '=' i AddVariable(...)
  // --- Obsługa deklaracji Z wartością (=) ---
  if Pos('=', Line) = 0 then Exit; // brak przypisania → nie przetwarzamy tu

  Parts := Line.Split(['='], 2);
  if Length(Parts) < 2 then Exit;

  VarDecl := Trim(Parts[0]);   // np. "tekst s"
  VarValue := Trim(Parts[1]);  // np. "'siema'" albo "42"

  VarParts := VarDecl.Split([' '], 2);
  if Length(VarParts) < 2 then
    raise Exception.Create(InvalidVariableDeclaration + Line);

  VarType := LowerCase(Trim(VarParts[0]));
  VarName := Trim(VarParts[1]);

  // --- Obsługa zwykłych typów ---
  if (VarType = 'tekst') or
     (VarType = 'liczba_całkowita') or
     (VarType = 'lc') or
     (VarType = 'liczba_zm') or
     (VarType = 'lzm') or
     (VarType = 'logiczny') or
     (VarType = 'znak') or
     (VarType = 'liczba_krótka') or
     (VarType = 'liczba_mała') or
     (VarType = 'liczba_długa') or
     (VarType = 'liczba64') or
     (VarType = 'bajt') or
     (VarType = 'liczba16') or
     (VarType = 'liczba32') or
     (VarType = 'tablicaliczb') or
     (VarType = 'liczba_pojedyncza') or
     (VarType = 'liczba_podwójna') or
     (VarType = 'liczba_rozszerzona') or
     (VarType = 'liczba_zgodna_delphi') or
     (VarType = 'liczba_waluta') or
     (VarType = 'logiczny_bajt') or
     (VarType = 'logiczne_słowo') or
     (VarType = 'logiczny_długi') or
     (VarType = 'znak_unicode') or
     (VarType = 'tekst255') or
     (VarType = 'tekst_ansi') or
     (VarType = 'tekst_unicode') or
     (VarType = 'tekst_systemowy') or
     (VarType = 'tablica_stała') or
     (VarType = 'tablica_dynamiczna') or
     (VarType = 'rekord') or
     (VarType = 'kolekcja') or
     (VarType = 'plik_binarny') or
     (VarType = 'plik_struktur') or
     (VarType = 'wskaźnik') or
     (VarType = 'wskaźnik_na') or
     (VarType = 'wariant') or
     (VarType = 'wariant_ole') or
     (VarType = 'tablicatekstów') or
     (VarType = 'lista_tekstów') or
     (VarType = 'stała') or
     (VarType = 'tekstld') or
     // angielskie odpowiedniki
     (VarType = 'int') or
     (VarType = 'int8') or
     (VarType = 'int16') or
     (VarType = 'int32') or
     (VarType = 'int64') or
     (VarType = 'real') or
     (VarType = 'byte') or
     (VarType = 'uint16') or
     (VarType = 'uint32') or
     (VarType = 'float') or
     (VarType = 'float80') or
     (VarType = 'decimal') or
     (VarType = 'bool') or
     (VarType = 'char') or
     (VarType = 'char32') or
     (VarType = 'string255') or
     (VarType = 'string') or
     (VarType = 'ansi_string') or
     (VarType = 'unicode_string') or
     (VarType = 'dynamic_array') or
     (VarType = 'set') or
     (VarType = 'binary_file') or
     (VarType = 'file_struct') or
     (VarType = 'pointer') or
     (VarType = 'pointer_to') or
     (VarType = 'any') or
     (VarType = 'ole_variant')
  then
  begin
    AddVariable(VarName, VarType, False); // deklaracja z przypisaniem
    Exit;
  end;

  raise Exception.Create('Nieznany typ zmiennej: ' + VarType);
end;


//Deklaracja nowych typów zmienncyh
{procedure TAvocadoTranslator.ProcessDeclaration(const Line: string);
var
    Parts: TStringArray;
    VarDecl, VarValue: string;
    VarParts: TStringArray;
    VarType, VarName: string;
    TrimmedLine: string;
begin
   TrimmedLine := Trim(Line);
   if TrimmedLine = '' then Exit;

  // Pomijamy linie zaczynające się od "jeśli"
  if LowerCase(TrimmedLine).StartsWith('jeśli') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
  if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;

  // Pomijamy linie, które nie zawierają '='
  if Pos('=', Line) = 0 then Exit;

  // Rozdzielamy linię na deklarację i wartość
  Parts := Line.Split(['='], 2);
  if Length(Parts) < 2 then Exit;

  VarDecl := Trim(Parts[0]);   // np. "tekst s" lub "plik f"
  VarValue := Trim(Parts[1]);  // np. "'siema'" lub "nil"

  // Rozdzielamy typ i nazwę zmiennej
  VarParts := VarDecl.Split([' '], 2);
  if Length(VarParts) < 2 then
    raise Exception.Create(InvalidVariableDeclaration + Line);

  VarType := LowerCase(Trim(VarParts[0]));
  VarName := Trim(VarParts[1]);

  // Obsługa plików
  if (VarType = 'plik') or (VarType = 'plik_tekstowy') then
  begin
    if (LowerCase(VarValue) = 'nil') or (LowerCase(VarValue) = 'nic') then
      AddVariable(VarName, VarType, True)  // tylko deklaracja
    else
      AddVariable(VarName, VarType, False); // z przypisaniem później
    Exit;
  end;

  // Obsługa zwykłych typów
  if (VarType = 'tekst') or
     (VarType = 'liczba_całkowita') or
     (VarType = 'lc') or
     (VarType = 'liczba_zm')or
     (VarType = 'lzm') or
     (VarType = 'logiczny')or
     (VarType = 'znak')or
     (VarType = 'liczba_krótka') or
     (VarType = 'liczba_mała') or
     (VarType = 'liczba_długa') or
     (VarType = 'liczba64') or
     (VarType = 'bajt') or
     (VarType = 'liczba16') or
     (VarType = 'liczba32') or
     (VarType = 'tablicaliczb') or
     (VarType = 'liczba_pojedyncza') or
     (VarType = 'liczba_podwójna') or
     (VarType = 'liczba_rozszerzona') or
     (VarType = 'liczba_zgodna_delphi') or
     (VarType = 'liczba_waluta') or
     (VarType = 'logiczny_bajt') or
     (VarType = 'logiczne_słowo') or
     (VarType = 'logiczny_długi') or
     (VarType = 'znak_unicode') or
     (VarType = 'tekst255') or
     (VarType = 'tekst_ansi') or
     (VarType = 'tekst_unicode') or
     (VarType = 'tekst_systemowy') or
     (VarType = 'tablica_stała') or
     (VarType = 'tablica_dynamiczna') or
     (VarType = 'rekord') or
     (VarType = 'kolekcja') or
     (VarType = 'plik_binarny') or
     (VarType = 'plik_struktur') or
     (VarType = 'wskaźnik') or
     (VarType = 'wskaźnik_na') or
     (VarType = 'wariant') or
     (VarType = 'wariant_ole') or
     (VarType = 'tablicatekstów') or
     (VarType = 'lista_tekstów') or
     (VarType = 'stała') or
     (VarType = 'TekstLD') or
      //angielskie nazwy
     (VarType = 'int') or
     (VarType = 'int8') or //shortint
     (VarType = 'int16') or //SmallInt
     (VarType = 'int32') or //LongInt
     (VarType = 'int64') or //Int64
     (VarType = 'ubyte') or //Single
     (VarType = 'ubyte') or //Single
     (VarType = 'real') or //Real
     (VarType = 'byte') or //Byte
     (VarType = 'uint16') or //Word
     (VarType = 'uint32') or //LongWord
     (VarType = 'float') or //Double
     (VarType = 'float80') or //Extended
     (VarType = 'decimal') or //Currency
     (VarType = 'bool') or //Boolean
     (VarType = 'char') or //Char
     (VarType = 'char32') or //WideChar
     (VarType = 'string255') or //ShortString
     (VarType = 'string') or //String
     (VarType = 'ansi_string') or //AnsiString
     (VarType = 'unicode_string') or //UnicodeString
     (VarType = 'dynamic_array') or //UnicodeString
     (VarType = 'set') or //Set of type
     (VarType = 'file') or //File
     (VarType = 'text_file') or //TextFile
     (VarType = 'binary_file') or //BinaryFile
     (VarType = 'file_struct') or //Typed File
     (VarType = 'pointer') or //pointer
     (VarType = 'pointer_to') or //^type
     (VarType = 'binary_file') or //BinaryFile
     (VarType = 'any') or //Variant
     (VarType = 'ole_variant')  //OleVariant



     then
  begin
    AddVariable(VarName, VarType, False); // standardowe zmienne z inicjalizacją
    Exit;
  end;
    raise Exception.Create('Nieznany typ zmiennej: ' + VarType);
end;
}


// Zaawansowana funkcja do parsowania argumentów, która uwzględnia cudzysłowy
function SplitArguments(const ASource: string; AStrings: TStrings): Boolean;
var
  I: Integer;
  InQuote: Boolean;
  StartPos: Integer;
  QuoteChar: Char;
begin
  Result := True;
  AStrings.Clear;
  InQuote := False;
  StartPos := 1;
  QuoteChar := #0;

  for I := 1 to Length(ASource) do
  begin
    if (ASource[I] = '''') or (ASource[I] = '"') then
    begin
      if not InQuote then
      begin
        InQuote := True;
        QuoteChar := ASource[I];
      end
      else if ASource[I] = QuoteChar then
      begin
        InQuote := False;
      end;
    end
    else if (ASource[I] = ',') and not InQuote then
    begin
      AStrings.Add(Copy(ASource, StartPos, I - StartPos));
      StartPos := I + 1;
    end;
  end;

  // Dodaj ostatni argument
  if StartPos <= Length(ASource) then
    AStrings.Add(Copy(ASource, StartPos, Length(ASource) - StartPos + 1));
end;

constructor TAvocadoTranslator.Create;
begin
  inherited Create;
end;

destructor TAvocadoTranslator.Destroy;
begin
  inherited Destroy;
end;



{ Przetwarzanie pętli for w formacie:
  dla <zmienna> od <początek> do <koniec> { <ciało> } }
procedure TAvocadoTranslator.ProcessForLoop(const Line: string; PascalCode: TStringList);
var
  WithoutFor, Header, Body: string;
  VarName, StartValue, EndValue: string;
  OpenBracketPos, CloseBracketPos: Integer;
  HeaderParts: TStringArray;
  BodyStatements: TStringArray;
  i: Integer;
begin
  // Usuwamy słowo "dla " (4 znaki) i przycinamy
  WithoutFor := Trim(Copy(Line, 5, Length(Line)));
  // Znajdź otwierający nawias klamrowy '{'
  OpenBracketPos := Pos('{', WithoutFor);
  if OpenBracketPos = 0 then
    raise Exception.Create('Brak otwierającego nawiasu { w pętli for.');
  // Znajdź zamykający nawias klamrowy '}'
  CloseBracketPos := Pos('}', WithoutFor);
  if CloseBracketPos = 0 then
    raise Exception.Create('Brak zamykającego nawiasu } w pętli for.');
  // Header: wszystko przed '{'
  Header := Trim(Copy(WithoutFor, 1, OpenBracketPos - 1));
  // Body: zawartość między '{' i '}'
  Body := Trim(Copy(WithoutFor, OpenBracketPos + 1, CloseBracketPos - OpenBracketPos - 1));

  // Nagłówek oczekiwany w formacie: "<zmienna> od <początek> do <koniec>"
  HeaderParts := SplitString(Header, ' ');
  if Length(HeaderParts) < 5 then
    raise Exception.Create('Nieprawidłowy format nagłówka pętli for.');
  VarName := HeaderParts[0];
  if LowerCase(HeaderParts[1]) <> 'od' then
    raise Exception.Create('Oczekiwano słowa "od" w pętli for.');
  StartValue := HeaderParts[2];
  if LowerCase(HeaderParts[3]) <> 'do' then
    raise Exception.Create('Oczekiwano słowa "do" w pętli for.');
  EndValue := HeaderParts[4];

  // Generujemy kod pętli for w Pascalu
  PascalCode.Add(Format('for %s := %s to %s do', [VarName, TranslateExpression(StartValue), TranslateExpression(EndValue)]));
  PascalCode.Add('begin');

  // Przetwarzamy ciało pętli – instrukcje oddzielone średnikami
  BodyStatements := SplitString(Body, ';');
  for i := 0 to High(BodyStatements) do
    if Trim(BodyStatements[i]) <> '' then
      ProcessLine(Trim(BodyStatements[i]), PascalCode);

  PascalCode.Add('end;');
end;

procedure TAvocadoTranslator.ProcessWhileLoop(const Line: string;
  PascalCode: TStringList);
var
StartBrace, EndBrace: Integer;
LoopContent, Condition, Body: string;
Statements: TStringArray;
stmt: string;
begin
  // Szukamy nawiasów klamrowych { ... }
    StartBrace := Pos('{', Line);
    EndBrace := RPos('}', Line);
    if (StartBrace = 0) or (EndBrace = 0) or (EndBrace <= StartBrace) then
      raise Exception.Create('Błędna składnia pętli dopóki: ' + Line);

    LoopContent := Trim(Copy(Line, StartBrace + 1, EndBrace - StartBrace - 1));

    // Wyciągamy warunek (pierwsza część w nawiasach) i ciało pętli
    if (LoopContent[1] <> '(') then
      raise Exception.Create('Brak warunku w pętli dopóki: ' + Line);

    // Szukamy końca warunku
    EndBrace := Pos(')', LoopContent);
    if EndBrace = 0 then
      raise Exception.Create('Brak zamykającego nawiasu warunku w dopóki: ' + Line);

    Condition := Trim(Copy(LoopContent, 2, EndBrace - 2));
    Body := Trim(Copy(LoopContent, EndBrace + 1, MaxInt));

    PascalCode.Add('while ' + TranslateExpression(Condition) + ' do begin');

    //// Rozbijamy ciało na pojedyncze instrukcje (np. po spacji lub średniku)
    //Statements := Body.Split([';']);
    //for stmt in Statements do
    //begin
    //  stmt := Trim(stmt);
    //  if stmt = '' then Continue;
    //  ProcessLine(stmt, PascalCode); // przetwórz każdą instrukcję normalnie
    //end;

    PascalCode.Add('end;');
end;



function TAvocadoTranslator.JesliWtedyInaczej(const Warunek, WartoscJesliPrawda, WartoscJesliFalsz: string): string;
var
  WtedyLines, InaczejLines: TStringList;
  i: Integer;
begin
  WtedyLines := TStringList.Create;
    InaczejLines := TStringList.Create;
    try
      WtedyLines.Text := WartoscJesliPrawda;
      InaczejLines.Text := WartoscJesliFalsz;

      Result := 'if ' + TranslateExpression(Warunek) + ' then' + LineEnding +
                'begin' + LineEnding;

      // Dodajemy blok THEN
      for i := 0 to WtedyLines.Count - 1 do
        Result := Result + '  ' + WtedyLines[i] + LineEnding;
      Result := Result + 'end';

      // Dodajemy blok ELSE jeśli istnieje
      if WartoscJesliFalsz <> '' then
      begin
        Result := Result + LineEnding + 'else' + LineEnding + 'begin' + LineEnding;
        for i := 0 to InaczejLines.Count - 1 do
          Result := Result + '  ' + InaczejLines[i] + LineEnding;
        Result := Result + 'end;';
      end
      else
        Result := Result + ';';

    finally
      WtedyLines.Free;
      InaczejLines.Free;
    end;
end;

function TAvocadoTranslator.PrzetworzBlok(const Blok: string): string;
var
  TempList: TStringList;
  Statements: TStringArray;
  Statement: string;
begin
  Result := '';
    TempList := TStringList.Create;
    try
      Statements := SplitString(Blok, ';');
      for Statement in Statements do
        if Trim(Statement) <> '' then
          ProcessLine(Trim(Statement), TempList);
      Result := Trim(TempList.Text);
    finally
      TempList.Free;
    end;
end;

function TAvocadoTranslator.GetImportedModules(const Code: string): string;
var
  Lines: TStringList;
  i: Integer;
  Line, ModulesList: string;

begin

  ModulesList := ''; // Pusta lista modułów
    Lines := TStringList.Create;
    try
      Lines.Text := Code; // Podziel kod na linie

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[i]); // Usuń zbędne spacje

        // Sprawdzenie, czy linia zaczyna się od "Importuj"
        if Pos('importuj', Line) = 1 then
        begin
          Delete(Line, 1, Length('importuj')); // Usuń słowo "importuj"
          Line := Trim(Line); // Usuń spacje przed nazwami modułów

          // Dodanie do listy modułów
          if ModulesList = '' then
            ModulesList := Line
          else
            ModulesList := ModulesList + ', ' + Line;
        end;
      end;

    // Dodaj 'Crt' jeśli wykryto slowa kluczowe w kodzie
    if (Pos('czytaj_klawisz', LowerCase(Code)) > 0) or
     (Pos('tło_tekstu', LowerCase(Code)) > 0) or
     (Pos('kolor_tekstu', LowerCase(Code)) > 0) or
     (Pos('pozycja_kursora', LowerCase(Code)) > 0) or
     (Pos('przypisz_plik', LowerCase(Code)) > 0) or
     (Pos('klawisz_wciśnięty', LowerCase(Code)) > 0) then

    begin
      if ModulesList <> '' then
        ModulesList := ModulesList + ', Crt'
      else
        ModulesList := 'Crt';
    end;

    //modul LazUTF8
    if (Pos('duże_litery_ansi', LowerCase(Code)) > 0)then

    begin
      if ModulesList <> '' then
        ModulesList := ModulesList + ', LazUTF8'
      else
        ModulesList := 'LazUTF8';
    end;
    //usuwam LazUTF8 jesli jest duże_litery
    // Sprawdzenie, czy linia zaczyna się od "Importuj"
       if Pos('duże_litery', Line) = 1 then
       begin
         Delete(Line, 1, Length('LazUTF8')); // Usuń słowo "LazUTF8"
         Line := Trim(Line); // Usuń spacje przed nazwami modułów

         // Dodanie do listy modułów
         if ModulesList = '' then
           ModulesList := Line
         else
           ModulesList := ModulesList + ', ' + Line;
       end;


       //Jesli potzrebny modul internet
        if (Pos('pobierz_plik(', LowerCase(Code)) > 0)then
        begin
          if ModulesList <> '' then
            ModulesList := ModulesList + ', internet'
          else
            ModulesList := 'internet';
        end;

        //Jesli potzrebny modul ChatGPT
        if (Pos('ZapytajChatGPT(', LowerCase(Code)) > 0)then
        begin
          if ModulesList <> '' then
            ModulesList := ModulesList + ', chatgptavocado'
          else
            ModulesList := 'chatgptavocado';
        end;


     //inne
      Result := ModulesList; // Zwrócenie wynikowej listy modułów
    finally
      Lines.Free;
    end;

end;

function TAvocadoTranslator.GetImplementationModules(const Code: string
  ): string;
const
  ImplementationKeyword = 'ModułyPas';
var
  Lines: TStringList;
  i: Integer;
  Line, ModulesList: string;
begin
  ModulesList := ''; // Pusta lista modułów na start
  Lines := TStringList.Create;
  try
    Lines.Text := Code; // Załaduj kod do listy linii

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]); // Usuń białe znaki z początku i końca linii

      // Sprawdź, czy linia zaczyna się od zdefiniowanego słowa kluczowego (ignorując wielkość liter)
      if AnsiStartsText(ImplementationKeyword, Line) then
      begin
        // Usuń słowo kluczowe z początku linii i ewentualne dodatkowe spacje po nim
        Line := Trim(Copy(Line, Length(ImplementationKeyword) + 1, MaxInt));

        // Dodaj znalezione moduły do listy wynikowej, tylko jeśli coś zostało po usunięciu słowa kluczowego
        if Line <> '' then
        begin
          if ModulesList = '' then
            ModulesList := Line // Pierwszy moduł/grupa modułów
          else
            ModulesList := ModulesList + ', ' + Line; // Kolejne moduły/grupy, oddzielone przecinkiem i spacją
        end;
      end;
    end;

    Result := ModulesList; // Zwróć finalną listę modułów jako string
  finally
    Lines.Free; // Zawsze zwolnij pamięć po TStringList
  end;
end;

function TAvocadoTranslator.duze_litery_ansi(const S: string): string;
begin
  // AnsiUpperCase jest zdefiniowane w SysUtils, więc musisz mieć je w sekcji 'uses'
  Result := AnsiUpperCase(S);
end;

function TAvocadoTranslator.male_litery_ansi(const S: string): string;
begin
  // AnsiLowerCase jest zdefiniowane w SysUtils, więc musisz mieć je w sekcji 'uses'
  Result := AnsiLowerCase(S);
end;

function TAvocadoTranslator.IsKnownType(const S: string): Boolean;
begin
   Result :=
    (S = 'liczba_całkowita') or (S = 'lc') or
    (S = 'liczba_zm') or (S = 'lzm') or
    (S = 'logiczny') or (S = 'znak') or
    (S = 'liczba_krótka') or (S = 'liczba_mała') or
    (S = 'liczba_długa') or (S = 'liczba64') or
    (S = 'bajt') or (S = 'liczba16') or (S = 'liczba32') or
    (S = 'tekst') or (S = 'tablicaliczb') or
    (S = 'liczba_pojedyncza') or (S = 'liczba_podwójna') or
    (S = 'liczba_rozszerzona') or (S = 'liczba_zgodna_delphi') or
    (S = 'liczba_waluta') or (S = 'logiczny_bajt') or
    (S = 'logiczne_słowo') or (S = 'logiczny_długi') or
    (S = 'znak_unicode') or (S = 'tekst255') or
    (S = 'tekst_ansi') or (S = 'tekst_unicode') or
    (S = 'tekst_systemowy') or
    (S = 'tablica_stała') or (S = 'tablica_dynamiczna') or
    (S = 'rekord') or (S = 'kolekcja') or
    (S = 'plik') or (S = 'plik_tekstowy') or
    (S = 'plik_binarny') or (S = 'plik_struktur') or
    (S = 'wskaźnik') or (S = 'wskaźnik_na') or
    (S = 'wariant') or (S = 'wariant_ole') or
    (S = 'tablicatekstów') or
    (S = 'stała') or (S = 'tekstld');
end;

procedure TAvocadoTranslator.SplitStringByChar(const AString: string;
  const ASeparator: Char; AResultList: TStrings);
var
  CurrentPos: Integer;
  StartPos: Integer;
begin
    AResultList.Clear;
      if AString = '' then
        Exit;

      CurrentPos := 1;
      StartPos := 1;
      while CurrentPos <= Length(AString) do
      begin
        if AString[CurrentPos] = ASeparator then
        begin
          AResultList.Add(Copy(AString, StartPos, CurrentPos - StartPos));
          StartPos := CurrentPos + 1;
        end;
        Inc(CurrentPos);
      end;
      // Dodanie ostatniego fragmentu po pętli
      AResultList.Add(Copy(AString, StartPos, Length(AString) - StartPos + 1));
end;

function TAvocadoTranslator.SplitArguments(const ASource: string;
  AStrings: TStrings): Boolean;
var
    I: Integer;
    InQuote: Boolean;
    StartPos: Integer;
    QuoteChar: Char;
begin
   Result := True;
  AStrings.Clear;
  InQuote := False;
  StartPos := 1;
  QuoteChar := #0;
  I := 1;

  while I <= Length(ASource) do
  begin
    if (ASource[I] = '''') or (ASource[I] = '"') then
    begin
      if not InQuote then
      begin
        InQuote := True;
        QuoteChar := ASource[I];
      end
      else if ASource[I] = QuoteChar then
      begin
        // Upewnij się, że ten cudzysłów nie jest zdublowany ('')
        if (I < Length(ASource)) and (ASource[I+1] = QuoteChar) then
        begin
          // To jest zdublowany cudzysłów w stringu, zignoruj go
          Inc(I);
        end
        else
        begin
          // To jest prawdziwy cudzysłów zamykający
          InQuote := False;
        end;
      end;
    end
    else if (ASource[I] = ',') and not InQuote then
    begin
      AStrings.Add(Copy(ASource, StartPos, I - StartPos));
      StartPos := I + 1;
    end;
    Inc(I);
  end;

  // Dodaj ostatni argument. Jest to kluczowy fragment.
  if StartPos <= Length(ASource) then
    AStrings.Add(Copy(ASource, StartPos, Length(ASource) - StartPos + 1));

  // Dodatkowo, aby mieć pewność, że wszystko jest czyste,
  // przejdź przez listę i przytnij spacje z brzegów
  for I := 0 to AStrings.Count - 1 do
    AStrings[I] := Trim(AStrings[I]);
end;




//przetwarzanie zagnieżdżonych instrukcji.
procedure TAvocadoTranslator.ProcessLine(const Line: string; PascalCode: TStringList);
var
  Parts: TStringArray;
   VarType, VarName, Value, TrimmedLine: string;
   InstrukcjaWarunkowa: TStringArray;
   KodWtedy, KodInaczej,LowerTrimmedLine: string;
   TempList: TStringList;
   Statements: TStringArray;
   Statement: string;
   Start,EndPos: Integer;
   pisznfStart,pisznfEndPos:Integer;
   //Param: string;
   //TranslatedParam: String;
   // Do przechowywania argumentów pisznf
   FullArgs: String;
   // Do przechowywania wyodrębnionego stringu formatującego
   FormatStringArg:String;
   //Do przechowywania wyodrębnionej listy zmiennych jako string
   VarListStringArg : String;
   //Do przechowywania pozycji ostatniego przecinka
   LastCommaPos:Integer;
     // Nowe zmienne dla zapytaj z 3 argumentami
  ApiKeyArg, ModelArg, QuestionArg: string;
  TranslatedApiKey, TranslatedModel: string;
  Args: TStringArray;
  TargetVar: string;
  ArgStr: string; // <<< DEKLARACJA JEST TUTAJ
  ProcessedArgs: string;
  StartPos, EndPoss,VarParts: Integer;
  Param: string;
  Partss,ParamParts: TStringArray;
  SExpr, StartExpr, CountExpr: string;
  SubstringExpr,InsertSource: string;
  InsertTarget: string;
  InsertIndex: string;

 StartPosInsert, EndPosInsert: Integer;
 ParamInsert, TrimmedPart: string;
 ParamPartsInsert, TempParamParts: array of string;
 InsertSourceIn, InsertTargetIn, InsertIndexIn: string;
 Part: string; // for-in loop variable
  //zmienne dla funkcji usun()
  StartPosDelete, EndPosDelete: Integer;
  ParamDelete, StringExprDelete, IndexExprDelete, CountExprDelete: string;
  ParamPartsDelete: TStringArray;
  //zmienne dla funkcji duże_litery()
  StartPosUpper, EndPosUpper: Integer;
  ParamUpper: string;
  TranslatedParamUpper: string;
  //zmienne dla funkcji małe_litery()
  StartPosLower, EndPosLower: Integer;
  ParamLower: string;
  TranslatedParamLower: string;
  //zmienne dla funkcji przytnij()
  StartPosTrim, EndPosTrim: Integer;
  ParamTrim: string;
  TranslatedParamTrim: string;
  // Nowe zmienne dla funkcji przytnij_z_lewa() i przytnij_z_prawa()
  StartPosTrimLeft, EndPosTrimLeft: Integer;
  ParamTrimLeft: string;
  TranslatedParamTrimLeft: string;
  StartPosTrimRight, EndPosTrimRight: Integer;
  ParamTrimRight: string;
  TranslatedParamTrimRight: string;
  // zmienne dla funkcji powtórz_znak()
  StartPosStringOfChar, EndPosStringOfChar: Integer;
  ParamStringOfChar: string;
  ParamPartsStringOfChar: TStringArray;
  TranslatedCharArg, TranslatedCountArg: string;
  //zmienne dla funkcji porównaj_tekst()
  StartPosCompareStr, EndPosCompareStr: Integer;
  ParamCompareStr: string;
  ParamPartsCompareStr: TStringArray;
  TranslatedS1Arg, TranslatedS2Arg: string;
  //Zamień
  ZamienTekst_ParamParts, ZamienTekst_AssignParts: TStringArray;
  ZamienTekst_Param, ZamienTekst_TextArg, ZamienTekst_FromArg, ZamienTekst_ToArg, ZamienTekst_ResultVar: string;
  ZamienTekst_StartPos, ZamienTekst_EndPos: Integer;
  //Ansi
  DLAnsi_Param, DLAnsi_VarName, DLAnsi_Value: string;
  DLAnsi_FuncPos, DLAnsi_LParenPos, DLAnsi_RParenPos: Integer;
  DLAnsi_AssignParts:TStringArray;
  //Pliki
  AssignStartPos, AssignEndPos: Integer;
  AssignParamStr: string;
  AssignParams: TStringList;
  AssignTranslatedParam1, AssignTranslatedParam2: string;
  Result_plik: string;
  //Intrenet
  PartsPobierz: TStringArray;               // do rozdzielania linii (np. Split)
  InstrukcjaWarunkowaPobierz: TStringArray; // do przechowania [URL, plik]
  LineRest: string;                  // pozostała część linii po "pobierz "
  URLtekst: string;                  // adres URL
  FileName: string;                  // nazwa pliku do zapisania
  //Chat GPT
  ArgList: TStringList;
  ArgStrz, TranslatedApiKeyz, TranslatedModelz, QuestionArgz: string;
  StartPosz, EndPosz: Integer;
  //Ping
  Site: String;
  //While petla
  TranslatedParamTrimWhile, BodyWhile:  String;
  LinesWhile: TStringArray;
  k: Integer;
  StartPosTrimWhile: Integer;
  EndPosTrimWhile: Integer;
  ParamTrimWhile: string;
  //
  OpenPos: Integer;
  //Value: string;
begin
  TrimmedLine := Trim(Line);
  LowerTrimmedLine := LowerCase(TrimmedLine); // <<< POPRAWIONA LINIA

  // Obsługa funkcji wstaw() → Insert()
  if Pos('wstaw(', LowerTrimmedLine) > 0 then
  begin
    StartPosInsert := Pos('(', TrimmedLine);
    EndPosInsert   := RPos(')', TrimmedLine);

    if (StartPosInsert = 0) or (EndPosInsert = 0) then
      raise Exception.Create(ErrorPrint);

    if StartPosInsert > EndPosInsert then
      raise Exception.Create(ErrorPrint);

    ParamInsert := Trim(Copy(TrimmedLine, StartPosInsert + 1, EndPosInsert - StartPosInsert - 1));
    ParamPartsInsert := ParamInsert.Split([',']);

    SetLength(TempParamParts, 0);
    for Part in ParamPartsInsert do
    begin
      TrimmedPart := Trim(Part);
      if TrimmedPart <> '' then
      begin
        SetLength(TempParamParts, Length(TempParamParts) + 1);
        TempParamParts[High(TempParamParts)] := TrimmedPart;
      end;
    end;
    ParamPartsInsert := TempParamParts;

    if Length(ParamPartsInsert) <> 3 then
      raise Exception.Create(FunctionInsert);

    InsertSourceIn := TranslateExpression(ParamPartsInsert[0]);
    InsertTargetIn := TranslateExpression(ParamPartsInsert[1]);
    InsertIndexIn  := TranslateExpression(ParamPartsInsert[2]);

    PascalCode.Add('Insert(' + InsertSourceIn + ', ' + InsertTargetIn + ', ' + InsertIndexIn + ');');
    Exit;
  end;
  // Nowa obsługa funkcji przytnij() -> Trim()
  if Pos('przytnij(', LowerTrimmedLine) > 0 then
  begin
    StartPosTrim := Pos('(', TrimmedLine);
    EndPosTrim := RPos(')', TrimmedLine);

    if (StartPosTrim = 0) or (EndPosTrim = 0) then
      raise Exception.Create(FunctionTrim);

    if StartPosTrim > EndPosTrim then
      raise Exception.Create(FunctionTrim);

    ParamTrim := Trim(Copy(TrimmedLine, StartPosTrim + 1, EndPosTrim - StartPosTrim - 1));
    TranslatedParamTrim := TranslateExpression(ParamTrim);

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := Trim(' + TranslatedParamTrim + ');');
    end
    else
    begin
      PascalCode.Add('Trim(' + TranslatedParamTrim + ');');
    end;
    Exit;
  end;
  // Obsługa funkcji przytnij_z_lewa() -> TrimLeft()
  if Pos('przytnij_z_lewa(', LowerTrimmedLine) > 0 then
  begin
    StartPosTrimLeft := Pos('(', TrimmedLine);
    EndPosTrimLeft := RPos(')', TrimmedLine);

    if (StartPosTrimLeft = 0) or (EndPosTrimLeft = 0) then
      raise Exception.Create(FunctionTrimRight);

    if StartPosTrimLeft > EndPosTrimLeft then
      raise Exception.Create(FunctionTrimLeft);

    ParamTrimLeft := Trim(Copy(TrimmedLine, StartPosTrimLeft + 1, EndPosTrimLeft - StartPosTrimLeft - 1));
    TranslatedParamTrimLeft := TranslateExpression(ParamTrimLeft);

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := TrimLeft(' + TranslatedParamTrimLeft + ');');
    end
    else
    begin
      PascalCode.Add('TrimLeft(' + TranslatedParamTrimLeft + ');');
    end;
    Exit;
  end;

  // Obsługa funkcji przytnij_z_prawa() -> TrimRight()
  if Pos('przytnij_z_prawa(', LowerTrimmedLine) > 0 then
  begin
    StartPosTrimRight := Pos('(', TrimmedLine);
    EndPosTrimRight := RPos(')', TrimmedLine);

    if (StartPosTrimRight = 0) or (EndPosTrimRight = 0) then
      raise Exception.Create(FunctionTrimRight);

    if StartPosTrimRight > EndPosTrimRight then
      raise Exception.Create(FunctionTrimRight);

    ParamTrimRight := Trim(Copy(TrimmedLine, StartPosTrimRight + 1, EndPosTrimRight - StartPosTrimRight - 1));
    TranslatedParamTrimRight := TranslateExpression(ParamTrimRight);

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := TrimRight(' + TranslatedParamTrimRight + ');');
    end
    else
    begin
      PascalCode.Add('TrimRight(' + TranslatedParamTrimRight + ');');
    end;
    Exit;
  end;

  //Obsługa pętli for
  if LowerTrimmedLine.StartsWith('dla ') then
  begin
    ProcessForLoop(TrimmedLine, PascalCode);
    Exit;
  end;
  // Obsługa funkcji usun() -> Delete()
  if Pos('usuń(', LowerTrimmedLine) > 0 then
  begin
    StartPosDelete := Pos('(', TrimmedLine);
    EndPosDelete   := RPos(')', TrimmedLine);

    if (StartPosDelete = 0) or (EndPosDelete = 0) then
      raise Exception.Create('Błędna składnia funkcji usuń. Oczekiwano: usuń(s, index, count)');

    if StartPosDelete > EndPosDelete then
      raise Exception.Create('Błędna składnia funkcji usuń. Oczekiwano: usuń(s, index, count)');

    ParamDelete := Trim(Copy(TrimmedLine, StartPosDelete + 1, EndPosDelete - StartPosDelete - 1));
    ParamPartsDelete := ParamDelete.Split([',']);

    if Length(ParamPartsDelete) <> 3 then
      raise Exception.Create('Funkcja usuń wymaga trzech argumentów: s, index, count');

    StringExprDelete := TranslateExpression(Trim(ParamPartsDelete[0]));
    IndexExprDelete  := TranslateExpression(Trim(ParamPartsDelete[1]));
    CountExprDelete  := TranslateExpression(Trim(ParamPartsDelete[2]));

    PascalCode.Add('Delete(' + StringExprDelete + ', ' + IndexExprDelete + ', ' + CountExprDelete + ');');
    Exit;
  end;

  // Obsługa funkcji duże_litery() -> UpperCase()
  if Pos('duże_litery(', LowerTrimmedLine) > 0 then
  begin
    StartPosUpper := Pos('(', TrimmedLine);
    EndPosUpper := RPos(')', TrimmedLine);

    if (StartPosUpper = 0) or (EndPosUpper = 0) then
      raise Exception.Create('Błędna składnia funkcji duże_litery. Oczekiwano: duże_litery(s)');

    if StartPosUpper > EndPosUpper then
      raise Exception.Create('Błędna składnia funkcji duże_litery. Oczekiwano: duże_litery(s)');

    ParamUpper := Trim(Copy(TrimmedLine, StartPosUpper + 1, EndPosUpper - StartPosUpper - 1));
    TranslatedParamUpper := TranslateExpression(ParamUpper);

    // Sprawdzamy, czy to przypisanie do zmiennej, czy samodzielne wywołanie
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := UpperCase(' + TranslatedParamUpper + ');');
    end
    else
    begin
      // Samodzielne wywołanie - nie ma sensu, ale transpilator musi to obsłużyć
      PascalCode.Add('UpperCase(' + TranslatedParamUpper + ');');
    end;
    Exit;
  end;

  // Nowa obsługa funkcji małe_litery() -> LowerCase()
  if Pos('małe_litery(', LowerTrimmedLine) > 0 then
  begin
    StartPosLower := Pos('(', TrimmedLine);
    EndPosLower := RPos(')', TrimmedLine);

    if (StartPosLower = 0) or (EndPosLower = 0) then
      raise Exception.Create('Błędna składnia funkcji małe_litery. Oczekiwano: małe_litery(s)');

    if StartPosLower > EndPosLower then
      raise Exception.Create('Błędna składnia funkcji małe_litery. Oczekiwano: małe_litery(s)');

    ParamLower := Trim(Copy(TrimmedLine, StartPosLower + 1, EndPosLower - StartPosLower - 1));
    TranslatedParamLower := TranslateExpression(ParamLower);

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := LowerCase(' + TranslatedParamLower + ');');
    end
    else
    begin
      PascalCode.Add('LowerCase(' + TranslatedParamLower + ');');
    end;
    Exit;
  end;

   // Obsługa funkcji powtórz_znak() -> StringOfChar()
  if Pos('powtórz_znak(', LowerTrimmedLine) > 0 then
  begin
    StartPosStringOfChar := Pos('(', TrimmedLine);
    EndPosStringOfChar := RPos(')', TrimmedLine);

    if (StartPosStringOfChar = 0) or (EndPosStringOfChar = 0) then
      raise Exception.Create('Błędna składnia funkcji powtórz_znak. Oczekiwano: powtórz_znak(char, count)');

    if StartPosStringOfChar > EndPosStringOfChar then
      raise Exception.Create('Błędna składnia funkcji powtórz_znak. Oczekiwano: powtórz_znak(char, count)');

    ParamStringOfChar := Trim(Copy(TrimmedLine, StartPosStringOfChar + 1, EndPosStringOfChar - StartPosStringOfChar - 1));
    ParamPartsStringOfChar := ParamStringOfChar.Split([',']);

    if Length(ParamPartsStringOfChar) <> 2 then
      raise Exception.Create('Funkcja powtórz_znak wymaga dwóch argumentów: char i count');

    TranslatedCharArg := TranslateExpression(Trim(ParamPartsStringOfChar[0]));
    TranslatedCountArg := TranslateExpression(Trim(ParamPartsStringOfChar[1]));

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := StringOfChar(' + TranslatedCharArg + ', ' + TranslatedCountArg + ');');
    end
    else
    begin
      PascalCode.Add('StringOfChar(' + TranslatedCharArg + ', ' + TranslatedCountArg + ');');
    end;
    Exit;
  end;
     // Nowa obsługa funkcji porównaj_tekst() -> CompareStr()
  if Pos('porównaj_tekst(', LowerTrimmedLine) > 0 then
  begin
    StartPosCompareStr := Pos('(', TrimmedLine);
    EndPosCompareStr := RPos(')', TrimmedLine);

    if (StartPosCompareStr = 0) or (EndPosCompareStr = 0) then
      raise Exception.Create('Błędna składnia funkcji porównaj_tekst. Oczekiwano: porównaj_tekst(s1, s2)');

    if StartPosCompareStr > EndPosCompareStr then
      raise Exception.Create('Błędna składnia funkcji porównaj_tekst. Oczekiwano: porównaj_tekst(s1, s2)');

    ParamCompareStr := Trim(Copy(TrimmedLine, StartPosCompareStr + 1, EndPosCompareStr - StartPosCompareStr - 1));
    ParamPartsCompareStr := ParamCompareStr.Split([',']);

    if Length(ParamPartsCompareStr) <> 2 then
      raise Exception.Create('Funkcja porównaj_tekst wymaga dwóch argumentów: s1 i s2');

    TranslatedS1Arg := TranslateExpression(Trim(ParamPartsCompareStr[0]));
    TranslatedS2Arg := TranslateExpression(Trim(ParamPartsCompareStr[1]));

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := CompareStr(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    end
    else
    begin
      PascalCode.Add('CompareStr(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    end;
    Exit;
  end;

  // Obsługa funkcji zamień_tekst
  if Pos('zamień_tekst(', LowerTrimmedLine) > 0 then
  begin
    ZamienTekst_StartPos := Pos('(', TrimmedLine);
    ZamienTekst_EndPos   := RPos(')', TrimmedLine);

    if (ZamienTekst_StartPos = 0) or (ZamienTekst_EndPos = 0) then
      raise Exception.Create('Błędna składnia zamień_tekst. Oczekiwano: zamień_tekst(text, from, to)');

    ZamienTekst_Param := Trim(Copy(TrimmedLine, ZamienTekst_StartPos + 1, ZamienTekst_EndPos - ZamienTekst_StartPos - 1));
    ZamienTekst_ParamParts := ZamienTekst_Param.Split([',']);

    if Length(ZamienTekst_ParamParts) <> 3 then
      raise Exception.Create('Funkcja zamień_tekst wymaga trzech argumentów: text, from, to');

    ZamienTekst_TextArg := TranslateExpression(Trim(ZamienTekst_ParamParts[0])); // AText
    ZamienTekst_FromArg := TranslateExpression(Trim(ZamienTekst_ParamParts[1])); // AFromText
    ZamienTekst_ToArg   := TranslateExpression(Trim(ZamienTekst_ParamParts[2])); // AToText

    // Sprawdzenie czy jest przypisanie
    if Pos('=', TrimmedLine) > 0 then
    begin
      ZamienTekst_AssignParts := TrimmedLine.Split(['='], 2);
      ZamienTekst_ResultVar := Trim(ZamienTekst_AssignParts[0]);
      PascalCode.Add(ZamienTekst_ResultVar + ' := ReplaceStr(' + ZamienTekst_TextArg + ', ' + ZamienTekst_FromArg + ', ' + ZamienTekst_ToArg + ');');
    end
    else
    begin
      PascalCode.Add('ReplaceStr(' + ZamienTekst_TextArg + ', ' + ZamienTekst_FromArg + ', ' + ZamienTekst_ToArg + ');');
    end;

    Exit;
  end


  //Ansi

    // Obsługa funkcji duże_litery_ansi
    else if Pos('duże_litery_ansi', LowerTrimmedLine) > 0 then
    begin
      DLAnsi_FuncPos := Pos('duże_litery_ansi', LowerTrimmedLine);
      if (DLAnsi_FuncPos = 1) or ((Pos('=', LowerTrimmedLine) > 0) and (DLAnsi_FuncPos > Pos('=', LowerTrimmedLine))) then
      begin
        DLAnsi_LParenPos := Pos('(', TrimmedLine);
        DLAnsi_RParenPos := RPos(')', TrimmedLine);
        if (DLAnsi_LParenPos = 0) or (DLAnsi_RParenPos = 0) then
          raise Exception.Create('Błędna składnia duże_litery_ansi. Oczekiwano: duże_litery_ansi(tekst)');

        DLAnsi_Param := Trim(Copy(TrimmedLine, DLAnsi_LParenPos + 1, DLAnsi_RParenPos - DLAnsi_LParenPos - 1));

        // z przypisaniem (b = duże_litery_ansi(...))
        if (Pos('=', TrimmedLine) > 0) and (DLAnsi_FuncPos > Pos('=', LowerTrimmedLine)) then
        begin
          DLAnsi_AssignParts := TrimmedLine.Split(['='], 2);
          DLAnsi_VarName := Trim(DLAnsi_AssignParts[0]);
          //PascalCode.Add(DLAnsi_VarName + ' := AnsiUpperCase(' + TranslateExpression(DLAnsi_Param) + ');');
          PascalCode.Add(DLAnsi_VarName + ' := UTF8UpperCase(' + TranslateExpression(DLAnsi_Param) + ');');
        end
        else
        begin
          // bez przypisania – samodzielne wywołanie
          PascalCode.Add('AnsiUpperCase(' + TranslateExpression(DLAnsi_Param) + ');');
        end;

        Exit; // kluczowe: nie leć dalej do zwykłego przypisania
      end;
      // jeśli warunki wyżej nie spełnione, nie przechwytujemy — pozwól obsłużyć innym gałęziom
    end;


     // Nowa obsługa funkcji przypisz_plik() -> AssignFile()
if AnsiStartsText('przypisz_plik(', TrimmedLine) then
begin
  AssignStartPos := Pos('(', TrimmedLine);
  AssignEndPos := RPos(')', TrimmedLine);

  if (AssignStartPos = 0) or (AssignEndPos = 0) then
    raise Exception.Create('Błędna składnia funkcji przypisz_plik. Oczekiwano: przypisz_plik(zmienna_plikowa, nazwa_pliku)');

  if AssignStartPos > AssignEndPos then
    raise Exception.Create('Błędna składnia funkcji przypisz_plik. Oczekiwano: przypisz_plik(zmienna_plikowa, nazwa_pliku)');

  AssignParamStr := Copy(TrimmedLine, AssignStartPos + 1, AssignEndPos - AssignStartPos - 1);
  AssignParams := TStringList.Create;
  try
    // Podziel parametry na podstawie przecinków
    SplitStringByChar(AssignParamStr, ',', AssignParams);


    if AssignParams.Count <> 2 then
      raise Exception.Create('Błędna liczba argumentów dla funkcji przypisz_plik. Oczekiwano 2 argumenty.');

    if (Trim(AssignParams[0]) = '') or (Trim(AssignParams[1]) = '') then
      raise Exception.Create('Argumenty funkcji przypisz_plik nie mogą być puste.');

    // Przetłumacz każdy z parametrów
    AssignTranslatedParam1 := TranslateExpression(AssignParams[0]);
    AssignTranslatedParam2 := TranslateExpression(AssignParams[1]);

    // Generowanie kodu Pascala
    PascalCode.Add('AssignFile(' + AssignTranslatedParam1 + ', ' + AssignTranslatedParam2 + ');');
    Exit;
  finally
    AssignParams.Free;
  end;
end;

//halt kończy program
if Pos('zakończ(', LowerTrimmedLine) > 0 then
begin
  StartPosTrim := Pos('(', TrimmedLine);
  EndPosTrim := RPos(')', TrimmedLine);

  if (StartPosTrim = 0) or (EndPosTrim = 0) then
    raise Exception.Create('Błędna składnia funkcji zakończ. Oczekiwano: zakończ(2)');

  if StartPosTrim > EndPosTrim then
    raise Exception.Create('Błędna składnia funkcji zakończ. Oczekiwano: zakończ(2)');

  ParamTrim := Trim(Copy(TrimmedLine, StartPosTrim + 1, EndPosTrim - StartPosTrim - 1));
  TranslatedParamTrim := TranslateExpression(ParamTrim);

  if Pos('=', TrimmedLine) > 0 then
  begin
    Parts := TrimmedLine.Split(['='], 2);
    VarName := Trim(Parts[0]);
    PascalCode.Add(VarName + ' := Halt(' + TranslatedParamTrim + ');');
  end
  else
  begin
    PascalCode.Add('Halt(' + TranslatedParamTrim + ');');
  end;
  Exit;
end;

  //Exit: Kończy bieżącą procedurę lub funkcję. Jeśli użyte w programie głównym, kończy program.
// Obsługa "wyjść" (Exit)
if Pos('wyjść', LowerTrimmedLine) = 1 then
begin
  StartPosTrim := Pos('(', TrimmedLine);
  EndPosTrim   := RPos(')', TrimmedLine);

  if (StartPosTrim = 0) or (EndPosTrim = 0) then
  begin
    // brak nawiasów -> zwykłe "Exit;"
    PascalCode.Add('Exit;');
  end
  else
  begin
    if StartPosTrim > EndPosTrim then
      raise Exception.Create('Błędna składnia funkcji wyjść. Oczekiwano: wyjść(param)');

    ParamTrim := Trim(Copy(TrimmedLine, StartPosTrim + 1, EndPosTrim - StartPosTrim - 1));
    if ParamTrim = '' then
      PascalCode.Add('Exit;')  // puste parametry -> Exit bez argumentu
    else
    begin
      TranslatedParamTrim := TranslateExpression(ParamTrim);
      PascalCode.Add('Exit(' + TranslatedParamTrim + ');');
    end;
  end;

  Exit; // kończymy tłumaczenie tej linii
end;

// Zwraca liczbę parametrów przekazanych do programu z linii poleceń. (z SysUtils)
if Pos('ilość_parametrów', LowerTrimmedLine) = 1 then
begin
  StartPosTrim := Pos('(', TrimmedLine);
  EndPosTrim   := RPos(')', TrimmedLine);
  begin
    if StartPosTrim > EndPosTrim then
      raise Exception.Create('Błędna składnia funkcji ilość_parametrów. Oczekiwano: ilość_parametrów()');

    ParamTrim := Trim(Copy(TrimmedLine, StartPosTrim + 1, EndPosTrim - StartPosTrim - 1));
    //if ParamTrim = '' then
    //  PascalCode.Add('ParamCount;')
    //else
    begin
      TranslatedParamTrim := TranslateExpression(ParamTrim);
      PascalCode.Add('ParamCount(' + TranslatedParamTrim + ');');
    end;
  end;

  Exit; // kończymy tłumaczenie tej linii
end;

//Petla while
// Obsługa pętli dopóki { (warunek) ... }
if LowerCase(TrimmedLine).StartsWith('dopóki') then
begin
  ProcessWhileLoop(TrimmedLine, PascalCode);
  Exit;
end;


{INTERNET BLOK KODU}
if LowerCase(TrimmedLine).StartsWith('ftp_pobierz ') then
begin
  Parts := TrimmedLine.Split([' do '], 2);
  if Length(Parts) = 2 then
    PascalCode.Add('DownloadFTP(' + Parts[0].Substring(12) + ', ' + Parts[1] + ');');
   PascalCode.Add('DownloadFileToDisk(URL, SavePath, ErrorMsg);');
  Exit;
end;


//ping
if LowerCase(TrimmedLine).StartsWith('ping ') then
begin
  Parts := TrimmedLine.Split([' '], 2); // rozdzielamy na "ping" i adres
  if Length(Parts) = 2 then
  begin
    Site := Parts[1]; // zapisujemy stronę do zmiennej

    PascalCode.Add('if Ping(''' + Site + ''') then');
    PascalCode.Add('begin');
    PascalCode.Add('  WriteLn(''Strona ' + Site + ' odpowiada!'');');
    PascalCode.Add('end');
    PascalCode.Add('else');
    PascalCode.Add('begin');
    PascalCode.Add('  WriteLn(''Nie można nawiązać połączenia z ' + Site + ''');');
    PascalCode.Add('end;');
  end;
  Exit;
end;


// Obsługa pobierania pliku
  if LowerCase(TrimmedLine).StartsWith('pobierz_plik(') then
  begin
    PascalCode.Add(TrimmedLine + ';');  // przepisz dokładnie jak jest
    Exit;

  end;

  // Obsługa pobierania strony
  if LowerCase(TrimmedLine).StartsWith('pobierz_strone(') then
  begin
    PascalCode.Add(TrimmedLine + ';');  // przepisz dokładnie jak jest
    Exit;

  end;
     {OBSŁUGA PLIKI}
    //Dotyczy plików
    // przypisz_plik(f, 'plik.txt') -> AssignFile(f, 'plik.txt');
    if AnsiStartsText('przypisz_plik(', TrimmedLine) or
       AnsiStartsText('assign_file(', TrimmedLine)
       then
    begin
      AssignStartPos := Pos('(', TrimmedLine);
      AssignEndPos   := RPos(')', TrimmedLine);
      if (AssignStartPos = 0) or (AssignEndPos = 0) then
        raise Exception.Create('Błędna składnia przypisz_plik(zmienna_plikowa, nazwa_pliku)');

      AssignParamStr := Copy(TrimmedLine, AssignStartPos + 1, AssignEndPos - AssignStartPos - 1);

      AssignParams := TStringList.Create;
      try
        // rozdziel po przecinku (użyj Twojej funkcji pomocniczej)
        SplitStringByChar(AssignParamStr, ',', AssignParams);
        if AssignParams.Count <> 2 then
          raise Exception.Create('przypisz_plik wymaga 2 argumentów: (f, nazwa_pliku)');

        AssignTranslatedParam1 := TranslateExpression(Trim(AssignParams[0]));
        AssignTranslatedParam2 := TranslateExpression(Trim(AssignParams[1]));

        PascalCode.Add('AssignFile(' + AssignTranslatedParam1 + ', ' + AssignTranslatedParam2 + ');');
        Exit;
      finally
        AssignParams.Free;
      end;
    end;

    // otwórz_do_odczytu(f) -> Reset(f);
    if AnsiStartsText('otwórz_do_odczytu(', TrimmedLine) or
       AnsiStartsText('open_read(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia wczytaj_plik(f)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('Reset(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    //Otwórz_do_zapisu(f) -> Rewrite(f);
    if AnsiStartsText('otwórz_do_zapisu(', TrimmedLine) or
       AnsiStartsText('open_save(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia otwórz_do_zapisu(f)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('Rewrite(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    // dopisz(f) -> Append(f);
    if AnsiStartsText('otwórz_do_dopisywania(', TrimmedLine) or
       AnsiStartsText('dopisz(', TrimmedLine)  or
       AnsiStartsText('append(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia dopisz(f)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('Append(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    // zamknij_plik(f) -> CloseFile(f);
    if AnsiStartsText('zamknij_plik(', TrimmedLine) or
       AnsiStartsText('close_file(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia zamknij_plik(f)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('CloseFile(' + TranslateExpression(Param) + ');');
      Exit;
    end;


    //  koniec_pliku(f) -> Eof(f) także w wyrażeniach/warunkach   ;
    if AnsiStartsText('koniec_pliku(', TrimmedLine) or
       AnsiStartsText('Eof(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia koniec_pliku(f)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('Eof(' + TranslateExpression(Param) + ');');
      Exit;
    end;
    {// koniec_pliku(f) -> Eof(f) także w wyrażeniach/warunkach
    if Pos('koniec_pliku(', LowerTrimmedLine) > 0 then
    begin
      PascalCode.Add(
        StringReplace(TrimmedLine, 'koniec_pliku', 'Eof', [rfReplaceAll, rfIgnoreCase]) + ';'
      );
      Exit;
    end;
    }

    // czytaj_linie(f, x, y, ...) -> ReadLn(f, x, y, ...)
    // (działa także dla konsoli: czytaj_linie(x, y, ...))
    if AnsiStartsText('czytaj_linie(', TrimmedLine) then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia czytaj_linie(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('ReadLn(' + TranslateExpression(Param) + ');');
      Exit;
    end;



  // 0. Obsługa pętli for
      if LowerCase(TrimmedLine).StartsWith('dla ') then
      begin
        ProcessForLoop(TrimmedLine, PascalCode);
        Exit;
      end;
    // 1. Najpierw obsługujemy instrukcje warunkowe
    if Pos('jeśli ', LowerCase(TrimmedLine)) = 1 then
    begin
      InstrukcjaWarunkowa := TrimmedLine.Split(['wtedy'], 2);
      if Length(InstrukcjaWarunkowa) = 2 then
      begin
        Parts := InstrukcjaWarunkowa[1].Split(['inaczej'], 2);

        // Przetwarzanie bloku 'wtedy'
        KodWtedy := '';
        TempList := TStringList.Create;
        try
          Statements := SplitString(Trim(Parts[0]), ';');
          for Statement in Statements do
            if Trim(Statement) <> '' then
              ProcessLine(Trim(Statement), TempList);
          KodWtedy := Trim(TempList.Text);
        finally
          TempList.Free;
        end;

        // Przetwarzanie bloku 'inaczej'
        KodInaczej := '';
        if Length(Parts) = 2 then
        begin
          TempList := TStringList.Create;
          try
            Statements := SplitString(Trim(Parts[1]), ';');
            for Statement in Statements do
              if Trim(Statement) <> '' then
                ProcessLine(Trim(Statement), TempList);
            KodInaczej := Trim(TempList.Text);
          finally
            TempList.Free;
          end;
        end;

        PascalCode.Add(JesliWtedyInaczej(Trim(Copy(InstrukcjaWarunkowa[0], 7)), KodWtedy, KodInaczej));
        Exit;
      end;
    end
    // Obsługa funkcji długość (Length)
    else if Pos('długość(', LowerCase(TrimmedLine)) > 0 then

    begin
      // Znajdź pozycje nawiasów
      StartPos := Pos('(', TrimmedLine);
      EndPos := Pos(')', TrimmedLine);

      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia długość. Oczekiwano: długość(tekst)');

      // Wyciągnij parametr wewnątrz nawiasów
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

      // Sprawdź czy to przypisanie do zmiennej
      if Pos('=', TrimmedLine) > 0 then
      begin
        // Przypisanie typu: liczba_całkowita x = długość(tekst)
        Parts := TrimmedLine.Split(['='], 2);
        VarName := Trim(Parts[0]);
        VarType := '';
        PascalCode.Add(VarName + ' := Length(' + TranslateExpression(Param) + ');');
      end
      else
      begin
        // Samodzielne wywołanie funkcji: długość(tekst)
        PascalCode.Add('Length(' + TranslateExpression(Param) + ');');
      end;
    end

  //3. Funkcja kopiuj()

    else if Pos('kopiuj(', LowerTrimmedLine) > 0 then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);

      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia kopiuj. Oczekiwano: kopiuj(tekst, start, ile)');

      { pobieramy argumenty }
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      ParamParts := Param.Split([',']);

      if Length(ParamParts) <> 3 then
        raise Exception.Create('Funkcja kopiuj wymaga trzech argumentów: tekst, start, ile');

      SExpr     := TranslateExpression(Trim(ParamParts[0]));
      StartExpr := TranslateExpression(Trim(ParamParts[1]));
      CountExpr := TranslateExpression(Trim(ParamParts[2]));

      { przypisanie czy wywołanie samodzielne? }
      if Pos('=', TrimmedLine) > 0 then
      begin
        Parts   := TrimmedLine.Split(['='], 2);
        VarName := Trim(Parts[0]);
        PascalCode.Add(VarName + ' := Copy(' + SExpr + ', ' + StartExpr + ', ' + CountExpr + ');');
      end
      else
        PascalCode.Add('Copy(' + SExpr + ', ' + StartExpr + ', ' + CountExpr + ');');

      Exit;
    end

    {funkcja pos tzn szukaj}
    {Pos(substring, s): Zwraca pozycję pierwszego wystąpienia substring w stringu s, lub 0 jeśli nie znaleziono.}
        else if Pos('szukaj(', LowerTrimmedLine) > 0 then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine); // wymaga StrUtils

      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia szukaj. Oczekiwano: szukaj(substring, tekst)');

      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      ParamParts := Param.Split([',']);

      if Length(ParamParts) <> 2 then
        raise Exception.Create('Funkcja szukaj wymaga dwóch argumentów: substring, tekst');

      SExpr := TranslateExpression(Trim(ParamParts[1]));
      SubstringExpr := TranslateExpression(Trim(ParamParts[0]));

      if Pos('=', LowerTrimmedLine) > 0 then
      begin
        Parts := TrimmedLine.Split(['='], 2);
        VarName := Trim(Parts[0]);
        PascalCode.Add(VarName + ' := Pos(' + SubstringExpr + ', ' + SExpr + ');');
      end
      else
        PascalCode.Add('Pos(' + SubstringExpr + ', ' + SExpr + ');');

      Exit;
    end

    //GotoXY - > PozycjaKursora
    //Funkcja z modułu Crt do ustawiania kursora w określonej pozycji w oknie konsoli.
    else if LowerCase(TrimmedLine).StartsWith('pozycja_kursora(') then
    begin
       // Pobieramy zawartość między "druk(" a ostatnim znakiem
      Value := Copy(TrimmedLine, 17, Length(TrimmedLine) - 17);
      PascalCode.Add('GotoXY(' + TranslateExpression(Value) + ');');
    end

    //KolorTekstu  TextColor
    else if LowerCase(TrimmedLine).StartsWith('kolor_tekstu(') then
    begin
      Value := Copy(TrimmedLine, 14, Length(TrimmedLine) - 14);
      PascalCode.Add('TextColor(' + TranslateExpression(Value) + ');');
    end


    else if LowerCase(TrimmedLine).StartsWith('tło_tekstu(') then
    begin
       // Pobieramy zawartość między "pisz(" a ostatnim znakiem
      Value := Copy(TrimmedLine, 13, Length(TrimmedLine) - 13);
      PascalCode.Add('TextBackground(' + TranslateExpression(Value) + ');');
    end

    //czytaj klawisze czytaj_klawisz ReadKey
   { else if LowerCase(TrimmedLine).StartsWith('czytaj_klawisz') then
    begin
      Value := Copy(TrimmedLine, 14, Length(TrimmedLine) - 14);
      PascalCode.Add('ReadKey' + TranslateExpression(Value) + ';');
      //Exit;
    end
    }

    //czytaj klawisze czytaj_klawisz ReadKey
    // czytaj_klawisz / read_key
    else if (LowerCase(TrimmedLine).StartsWith('czytaj_klawisz')) or
            (LowerCase(TrimmedLine).StartsWith('read_key')) then
    begin
      // Znajdź pozycję pierwszego '(' jeśli istnieje
      OpenPos := Pos('(', TrimmedLine);
      if OpenPos = 0 then
      begin
        // brak nawiasów — zwykłe wywołanie funkcji bez parametrów
        PascalCode.Add('ReadKey;');
      end
      else
      begin
        // znajdź pozycję ostatniego ')'
        EndPos := LastDelimiter(')', TrimmedLine);
        if (EndPos > OpenPos) then
        begin
          // wyciągnij zawartość nawiasów bez zewnętrznych spacji
          Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

          // jeśli pusty argument => traktuj jak bez parametrów
          if Value = '' then
            PascalCode.Add('ReadKey;')
          else
            // jeśli są argumenty -> przepuść przez TranslateExpression
            PascalCode.Add('ReadKey(' + TranslateExpression(Value) + ');');
        end
        else
          raise Exception.Create('Błędna składnia: brak nawiasu zamykającego w wywołaniu czytaj_klawisz/read_key');
      end;
    end
  //
   {else if Pos('czytaj_klawisz', LowerCase(TrimmedLine)) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      if Length(Parts) <> 2 then
        raise Exception.Create('Błędna składnia czytaj_klawisz. Oczekiwano: zmienna = czytaj_klawisz');

      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

    // Sprawdź czy wartość po = to odczytajklucz
    if LowerCase(Value) <> 'czytaj_klawisz' then
      raise Exception.Create('Błędna prawa strona przypisania. Oczekiwano: czytaj_klawisz');

    // Przetwórz deklarację zmiennej (jeśli istnieje)
    if Pos(' ', VarName) > 0 then
    begin
      Parts := VarName.Split([' '], 2);
      if Length(Parts) < 2 then
        raise Exception.Create('Błędna deklaracja zmiennej dla czytaj_klawisz');

      VarType := Parts[0];
      VarName := Parts[1];
      AddVariable(VarName, VarType, False);
    end;

    // Sprawdź typ zmiennej
    if LowerCase(VarType) <> 'znak' then
      raise Exception.Create('czytaj_klawisz wymaga typu "znak"');

    // Wygeneruj kod Pascala
    PascalCode.Add(VarName + ' := ReadKey;');
  end
  }
     else if (Pos('czytaj_klawisz', LowerCase(TrimmedLine)) > 0) or
           (Pos('read_key', LowerCase(TrimmedLine)) > 0) then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      if Length(Parts) <> 2 then
        raise Exception.Create('Błędna składnia czytaj_klawisz. Oczekiwano: zmienna = czytaj_klawisz');

      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

    // Sprawdź czy wartość po = to odczytajklucz
   if not ((LowerCase(Value) = 'czytaj_klawisz') or (LowerCase(Value) = 'read_key')) then
    raise Exception.Create('Błędna prawa strona przypisania. Oczekiwano: czytaj_klawisz lub read_key');

    // Przetwórz deklarację zmiennej (jeśli istnieje)
    if Pos(' ', VarName) > 0 then
    begin
      Parts := VarName.Split([' '], 2);
      if Length(Parts) < 2 then
        raise Exception.Create('Błędna deklaracja zmiennej dla czytaj_klawisz');

      VarType := Parts[0];
      VarName := Parts[1];
      AddVariable(VarName, VarType, False);
    end;

    // Sprawdź typ zmiennej
     if not ((LowerCase(VarType) = 'znak') or (LowerCase(VarType) = 'char')) then
     raise Exception.Create('czytaj_klawisz wymaga typu "znak" lub "char"');

    // Wygeneruj kod Pascala
    PascalCode.Add(VarName + ' := ReadKey;');
  end


    // 2. Obsługa funkcji pisznl
    else if (LowerCase(TrimmedLine).StartsWith('pisz_linie(')) or
            (LowerCase(TrimmedLine).StartsWith('print_line(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      if OpenPos > 0 then
      begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
       // Pobieramy zawartość między "pisznl(" a ostatnim znakiem
     // Value := Copy(TrimmedLine, 8, Length(TrimmedLine) - 8);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
      //Exit;
    end;
    end

    // Obsługa funkcji random
    else if (LowerCase(TrimmedLine).StartsWith('losowy(')) or
            (LowerCase(TrimmedLine).StartsWith('random(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      if OpenPos > 0 then
      begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
      PascalCode.Add('Random(' + TranslateExpression(Value) + ');');
      //Exit;
    end;
    end

    // Obsługa funkcji randomize
    else if (LowerCase(TrimmedLine).StartsWith('losuj(')) or
            (LowerCase(TrimmedLine).StartsWith('randomize(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      if OpenPos > 0 then
      begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
      PascalCode.Add('Randomize' + TranslateExpression(Value) + ';');
      //Exit;
    end;
    end

    // 2. Obsługa funkcji pisz
   { else if LowerCase(TrimmedLine).StartsWith('pisz(') then
    begin
      Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
      //Exit;
    end
   }
    //Nowa funkcja pisz ulepsozna
        // 2. Obsługa funkcji pisz
    else if (LowerCase(TrimmedLine).StartsWith('pisz(')) or
            (LowerCase(TrimmedLine).StartsWith('print(')) then
    begin
     OpenPos := Pos('(', TrimmedLine);
     if OpenPos > 0 then
     begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
      //Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
    end;
   end

     //oblicza wyrazenie
    { else if LowerCase(TrimmedLine).StartsWith('oblicz(') then
     begin
       // Pobieramy zawartość między "oblicz(" a ostatnim znakiem
       Value := Copy(TrimmedLine, 8, Length(TrimmedLine) - 8);

       // Generowanie poprawnego kodu Free Pascala
       PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
     end
    } //

     // oblicza wyrażenie
     else
     begin
       // Lista słów-kluczy, które mają działać jak "oblicz"
       if (LowerCase(TrimmedLine).StartsWith('oblicz(')) or
          (LowerCase(TrimmedLine).StartsWith('calc(')) then
       begin
         // znajdź pierwsze wystąpienie '('
         OpenPos := Pos('(', TrimmedLine);
         if OpenPos > 0 then
         begin
           // wytnij to, co jest w środku nawiasów
           Value := Copy(TrimmedLine, OpenPos + 1,
                         Length(TrimmedLine) - OpenPos - 1);
           PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
         end;
       end



    // Obsługa 'zapytaj' 3 argumenty

else if LowerCase(TrimmedLine).StartsWith('ZapytajChatGPT(') then
begin


  // Znajdź pozycję otwierającego i zamykającego nawiasu
  StartPos := Pos('(', TrimmedLine);
  EndPos := RPos(')', TrimmedLine);

 if (StartPos > 0) and (EndPos > StartPos) then
  begin
    // Wyodrębnij string z argumentami, usuwając zewnętrzne nawiasy
    ArgStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

    // Stwórz listę do przechowywania sparsowanych argumentów
    ArgList := TStringList.Create;
    try
      // Użyj naszej nowej, niezawodnej funkcji do parsowania
      if SplitArguments(ArgStr, ArgList) then
      begin
        // Sprawdź, czy są dokładnie 3 argumenty
        if ArgList.Count = 3 then
        begin
          TranslatedApiKey := TranslateExpression(ArgList[0]);
          TranslatedModel := TranslateExpression(ArgList[1]);
          QuestionArg := ArgList[2];

          // Walidacja pytania
          if not IsQuotedString(QuestionArg) then
            raise Exception.Create('Błąd: Ostatni argument musi być literałem string w apostrofach lub cudzysłowach. Otrzymano: ' + QuestionArg);

          // Generowanie kodu Pascala
          PascalCode.Add('ZapytajChatGPT(' +
                            TranslatedApiKey + ', ' +
                            TranslatedModel + ', ' +
                            QuestionArg + ', ' +
                            '@GlobalResponseCallback);');
        end
        else
        begin
          raise Exception.Create('Błąd składni zapytaj: Oczekiwano 3 argumentów (klucz, model, pytanie), otrzymano ' + IntToStr(ArgList.Count));
        end;
      end
      else
        raise Exception.Create('Błąd parsowania argumentów w linii: ' + TrimmedLine);
    finally
      ArgList.Free;
    end;
  end
  else
    raise Exception.Create('Błąd składni zapytaj (nawiasy): ' + TrimmedLine);

  //Exit;
end

// 3. Obsługa instrukcji czytaj()
else if Pos('czytaj(', LowerCase(TrimmedLine)) > 0 then
begin
  // Sprawdź, czy linia zawiera znak '=' (czy jest to przypisanie z czytaj)
  if Pos('=', TrimmedLine) > 0 then
  begin
    // Przypadek: zmienna = czytaj(prompt)
    Parts := TrimmedLine.Split(['='], 2);
    VarName := Trim(Parts[0]);
    Value := Trim(Parts[1]);

    // Sprawdź, czy zmienna jest deklarowana w tej samej linii (z typem)
    if Pos(' ', VarName) > 0 then
    begin
      Parts := VarName.Split([' '], 2);
      //VarType := Parts[0];
      VarType := ResolveAlias(Parts[0]);
      VarName := Parts[1];
      AddVariable(VarName, VarType, False);
    end;

    // Wyodrębnij argument z czytaj()
    Value := Copy(Value, 7, Length(Value) - 6); // Usuń 'czytaj('
    if (Length(Value) > 0) and (Value[1] = '(') then
      Value := Copy(Value, 2, Length(Value) - 1);
    if (Length(Value) > 0) and (Value[Length(Value)] = ')') then
      Value := Copy(Value, 1, Length(Value) - 1);

    // Jeśli argument nie jest pusty, potraktuj go jako prompt
    if Value <> '' then
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
    PascalCode.Add('Read(' + VarName + ');');
  end
  else
  begin
    // Przypadek: czytaj(zmienna) bez przypisania
    // Wyodrębnij nazwę zmiennej z nawiasów
    Value := TrimmedLine;
    Value := Copy(Value, 7, Length(Value) - 6); // Usuń 'czytaj('
    if (Length(Value) > 0) and (Value[1] = '(') then
      Value := Copy(Value, 2, Length(Value) - 1);
    if (Length(Value) > 0) and (Value[Length(Value)] = ')') then
      Value := Copy(Value, 1, Length(Value) - 1);

    //// Sprawdź, czy zmienna jest już zadeklarowana
    //if not VariableExists(Value) then
    //  AddVariable(Value, 'znak', False); // Domyślnie zakładamy typ 'znak'

    PascalCode.Add('Read(' + Value + ');');
  end;
end



// 4. Obsługa instrukcji czytaj_linie ()
else if Pos('czytaj_linie(', LowerCase(TrimmedLine)) > 0 then
begin
  // Sprawdź, czy linia zawiera znak '=' (czy jest to przypisanie z czytaj)
  if Pos('=', TrimmedLine) > 0 then
  begin
    // Przypadek: zmienna = czytaj(prompt)
    Parts := TrimmedLine.Split(['='], 2);
    VarName := Trim(Parts[0]);
    Value := Trim(Parts[1]);

    // Sprawdź, czy zmienna jest deklarowana w tej samej linii (z typem)
    if Pos(' ', VarName) > 0 then
    begin
      Parts := VarName.Split([' '], 2);
      VarType := Parts[0];
      VarName := Parts[1];
      AddVariable(VarName, VarType, False);
    end;

    // Wyodrębnij argument z wczytaj_linie ()
    Value := Copy(Value, 13, Length(Value) - 13); // Usuń 'czytaj('
    if (Length(Value) > 0) and (Value[1] = '(') then
      Value := Copy(Value, 2, Length(Value) - 1);
    if (Length(Value) > 0) and (Value[Length(Value)] = ')') then
      Value := Copy(Value, 1, Length(Value) - 1);

    // Jeśli argument nie jest pusty, potraktuj go jako prompt
    if Value <> '' then
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
    PascalCode.Add('ReadLn(' + VarName + ');');
  end
  else
  begin
    // Przypadek: wczytaj_linie (zmienna) bez przypisania
    // Wyodrębnij nazwę zmiennej z nawiasów
    Value := TrimmedLine;
    Value := Copy(Value, 13, Length(Value) - 13); // Usuń 'wczytaj_linie ('
    if (Length(Value) > 0) and (Value[1] = '(') then
      Value := Copy(Value, 2, Length(Value) - 1);
    if (Length(Value) > 0) and (Value[Length(Value)] = ')') then
      Value := Copy(Value, 1, Length(Value) - 1);

    //// Sprawdź, czy zmienna jest już zadeklarowana
    //if not VariableExists(Value) then
    //  AddVariable(Value, 'znak', False); // Domyślnie zakładamy typ 'znak'

    PascalCode.Add('ReadLn(' + Value + ');');
  end;
end

   //Ustawieni długośći w tablice
    else if (LowerCase(TrimmedLine).StartsWith('ustaw_długość(')) or
            (LowerCase(TrimmedLine).StartsWith('set_length(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      if OpenPos > 0 then
      begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);

      // Wycinamy zawartość nawiasów.
      // Długość frazy "ustaw długość(" wynosi: Length('ustaw długość(')
     // Value := Copy(TrimmedLine, Length('ustaw_długość(') + 1, Length(TrimmedLine) - Length('ustaw długość(') - 1);
      //Value := Trim(Value);
      // Generujemy kod: SetLength( <argumenty> );
      PascalCode.Add('SetLength(' + TranslateExpression(Value) + ');');
      //Exit;
    end;
    end

    // 4. Obsługa zwykłych przypisań
    else if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

      if Pos(' ', VarName) > 0 then
      begin
        Parts := VarName.Split([' '], 2);
        VarType := Parts[0];
        VarName := Parts[1];
        AddVariable(VarName, VarType,False);
      end;

      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value) + ';');
    end


    // 5. Obsługa pozostałych linii
    else if TrimmedLine <> '' then
    begin
      PascalCode.Add(TrimmedLine + ';');
    end;
  end;

end;


function TAvocadoTranslator.Translate(const AvocadoCode: TStrings): TStringList;
var
  PascalCode: TStringList;
  i: Integer;
  trimmedLine, ModulesStr: string;
  ModulPascalowy: string;
  DetectedProgramName: string; // Do przechowania finalnej nazwy programu
  UsesList: TStringList;     // Pomocnicza lista do budowania 'uses'
  UName: string;             // Pomocnicza do sprawdzania duplikatów i w pętlach
  ExistingUnits: TStringList;  // Do sprawdzania duplikatów
begin
  SetLength(FVariables, 0); // Czyści listę zmiennych
    PascalCode := TStringList.Create;
    UsesList := TStringList.Create; // Inicjalizacja listy uses
    ExistingUnits := TStringList.Create; // Do śledzenia dodanych unitów

    // --- Skanowanie dla standardowego 'program' ---
    NameProgram := ''; // Resetuj zmienną globalną/pole
    DetectedProgramName := 'programbeznazwy'; // Domyślna nazwa

    for i := 0 to AvocadoCode.Count - 1 do
    begin
      trimmedLine := Trim(AvocadoCode[i]);
      // Szukaj tylko standardowego 'program'
      if LowerCase(trimmedLine).StartsWith('program ') then
      begin
        NameProgram := Trim(Copy(trimmedLine, Length('program ') + 1, MaxInt));
        if NameProgram = '' then NameProgram := 'programbeznazwy';
        DetectedProgramName := NameProgram;
        Break; // Znaleziono deklarację, przerwij skanowanie
      end;
    end;
    // --- KONIEC SKANOWANIA ---

    try

      PascalCode.Add('{$codepage utf8}');
      PascalCode.Add('{$mode objfpc}');
      PascalCode.Add('{$H+}');
      PascalCode.Add('program ' + DetectedProgramName + ';'); // Użyj wykrytej nazwy

      // --- UPROSZCZONA SEKCJA 'uses' ---
      ModulesStr := GetImportedModules(AvocadoCode.Text);
      ModulPascalowy := GetImplementationModules(AvocadoCode.Text);

      // Podstawowe moduły + Classes + Windows (dla konsoli). LCL użytkownik musi dodać sam przez Importuj.
      UsesList.Add('SysUtils');
      UsesList.Add('Classes');
      UsesList.Add('Windows'); // Zawsze dodawaj dla konsoli Windows
      UsesList.Add('StrUtils');
      UsesList.Add('Dialogs');

      //UsesList.Add('LazUTF8'); //Aby nie bylo krzaków w konsoli
      //UsesList.Add('Utf8Process');



      //UsesList.Add('Crt');

      // Dodaj moduły użytkownika z 'Importuj'
      if ModulesStr <> '' then
      begin
         for UName in ModulesStr.Split([',']) do UsesList.Add(Trim(UName));
      end;


      // Dodaj moduły z 'ModułyPas'
      if ModulPascalowy <> '' then
      begin
         for UName in ModulPascalowy.Split([',']) do UsesList.Add(Trim(UName));
      end;

      // Generuj finalną klauzulę uses, usuwając duplikaty
      PascalCode.Add('uses');
      ExistingUnits.Clear;
      ExistingUnits.CaseSensitive := False;
      ExistingUnits.Sorted := True;

      for i := 0 to UsesList.Count - 1 do
      begin
         UName := Trim(UsesList[i]);
         if (UName <> '') and (ExistingUnits.IndexOf(UName) = -1) then
         begin
            if ExistingUnits.Count = 0 then
               PascalCode.Add('  ' + UName)
            else
               PascalCode.Strings[PascalCode.Count - 1] := PascalCode.Strings[PascalCode.Count - 1] + ', ' + UName;
            ExistingUnits.Add(UName);
         end;
      end;

      if ExistingUnits.Count > 0 then
         PascalCode.Strings[PascalCode.Count - 1] := PascalCode.Strings[PascalCode.Count - 1] + ';'
      else
         PascalCode.Delete(PascalCode.Count - 1); // Usuń pustą linię 'uses'
      PascalCode.Add('');
      // --- KONIEC SEKCJI 'uses' ---

      // Wykryj deklaracje zmiennych
      for i := 0 to AvocadoCode.Count - 1 do
        ProcessDeclaration(Trim(AvocadoCode[i]));
      //// Generuj sekcję 'const' (PRZYWRÓCONO PEŁNĄ OBSŁUGĘ TYPÓW)
      //if Length(FVariables) > 0 then
      //begin
      //  PascalCode.Add('var');
      //  for i := 0 to High(FVariables) do
      //  begin
      // Generuj sekcję 'var'
      if Length(FVariables) > 0 then
      begin
        PascalCode.Add('var');
        for i := 0 to High(FVariables) do
        begin
        if FVariables[i].VarName = '' then Continue; // pomiń brakujące nazwy
          // deklaracja zmiennych
        if LowerCase(FVariables[i].VarType) = 'liczba_całkowita' then
          PascalCode.Add('  ' + FVariables[i].VarName + ': Integer;')
          //nowe
          else if LowerCase(FVariables[i].VarType) = 'plik' then
          begin
            PascalCode.Add('  ' + FVariables[i].VarName + ': File;');
            // jeśli NoAssign = True, nie generujemy przypisania
          end
          else if LowerCase(FVariables[i].VarType) = 'plik_tekstowy' then
          begin
            PascalCode.Add('  ' + FVariables[i].VarName + ': TextFile;');
            // jeśli NoAssign = True, pomiń przypisanie
          end
          //koniec
          else if LowerCase(FVariables[i].VarType) = 'lc' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Integer;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_zm' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Real;')
          else if LowerCase(FVariables[i].VarType) = 'lzm' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Real;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Boolean;')

          else if LowerCase(FVariables[i].VarType) = 'znak' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Char;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_krótka' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ShortInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_mała' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': SmallInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_długa' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba64' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Int64;')
          else if LowerCase(FVariables[i].VarType) = 'bajt' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Byte;')
          else if LowerCase(FVariables[i].VarType) = 'liczba16' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Word;')
          else if LowerCase(FVariables[i].VarType) = 'liczba32' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongWord;')
          else if LowerCase(FVariables[i].VarType) = 'tekst' then
             PascalCode.Add('  ' + FVariables[i].VarName + ': String;') // Dodano obsługę 'tekst'
          else if LowerCase(FVariables[i].VarType) = 'tablicaliczb' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': array of Integer;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_pojedyncza' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Single;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_podwójna' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Double;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_rozszerzona' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Extended;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_zgodna_delphi' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Comp;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_waluta' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Currency;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny_bajt' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ByteBool;')
          else if LowerCase(FVariables[i].VarType) = 'logiczne_słowo' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': WordBool;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny_długi' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongBool;')
          else if LowerCase(FVariables[i].VarType) = 'znak_unicode' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': WideChar;')
          else if LowerCase(FVariables[i].VarType) = 'tekst255' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ShortString;')
          else if LowerCase(FVariables[i].VarType) = 'tekst_ansi' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': AnsiString;')
          else if LowerCase(FVariables[i].VarType) = 'tekst_unicode' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': UnicodeString;')
          // Poniższe typy mogą wymagać bardziej złożonej obsługi niż prosta deklaracja
          else if LowerCase(FVariables[i].VarType) = 'tablica_dynamiczna' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Array of Variant;') // Przykład: tablica wariantów
          else if LowerCase(FVariables[i].VarType) = 'rekord' then
            PascalCode.Add('  { TODO: Zdefiniuj typ rekordu dla ' + FVariables[i].Name + ' }')
          else if LowerCase(FVariables[i].VarType) = 'kolekcja' then
             PascalCode.Add('  ' + FVariables[i].VarName + ': Set of Byte;') // Przykład: set of byte
          //else if LowerCase(FVariables[i].VarType) = 'plik' then
          //  PascalCode.Add('  ' + FVariables[i].VarName + ': File;')
          //else if LowerCase(FVariables[i].VarType) = 'plik_tekstowy' then
          //  PascalCode.Add('  ' + FVariables[i].VarName + ': TextFile;')
          else if LowerCase(FVariables[i].VarType) = 'plik_binarny' then
             PascalCode.Add('  ' + FVariables[i].VarName + ': File;') // Lub File of Byte
          else if LowerCase(FVariables[i].VarType) = 'plik_struktur' then
             PascalCode.Add('  { TODO: Zdefiniuj typ pliku dla ' + FVariables[i].Name + ': File of ... }')
          else if LowerCase(FVariables[i].VarType) = 'wskaźnik' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Pointer;')
          else if LowerCase(FVariables[i].VarType) = 'wskaźnik_na' then
             PascalCode.Add('  { TODO: Zdefiniuj typ wskazywany dla ' + FVariables[i].Name + ': ^... }')
          else if LowerCase(FVariables[i].VarType) = 'wariant' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Variant;')
          else if LowerCase(FVariables[i].VarType) = 'wariant_ole' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': OleVariant;')
          else if LowerCase(FVariables[i].VarType) = 'tablicatekstów' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TStringArray;') // Użyj zdefiniowanego typu
          //nowe
           else if LowerCase(FVariables[i].VarType) = 'lista_tekstów' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TStringList;') // Użyj zdefiniowanego typu
          else if LowerCase(FVariables[i].VarType) = 'stała' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Const;')
          //Tu drodzy panstwo beda zmienne po angielsku
          else if LowerCase(FVariables[i].VarType) = 'int' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Integer;')
          else if LowerCase(FVariables[i].VarType) = 'int8' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ShortIn;')
          else if LowerCase(FVariables[i].VarType) = 'int16' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': SmallInt;')
             else if LowerCase(FVariables[i].VarType) = 'int32' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongInt;')
             else if LowerCase(FVariables[i].VarType) = 'int64' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Int64;')
             else if LowerCase(FVariables[i].VarType) = 'ubyte' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Single;')
             else if LowerCase(FVariables[i].VarType) = 'real' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Real;')
             else if LowerCase(FVariables[i].VarType) = 'byte' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Byte;')
            else if LowerCase(FVariables[i].VarType) = 'uint16' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Word;')
            else if LowerCase(FVariables[i].VarType) = 'uint32' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongWord;')
            else if LowerCase(FVariables[i].VarType) = 'float' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Double;')
            else if LowerCase(FVariables[i].VarType) = 'float80' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Extended;')
            else if LowerCase(FVariables[i].VarType) = 'decimal' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Currency;')
            else if LowerCase(FVariables[i].VarType) = 'bool' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Boolean;')
            else if LowerCase(FVariables[i].VarType) = 'char' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Char;')
            else if LowerCase(FVariables[i].VarType) = 'char32' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': WideChar;')
            else if LowerCase(FVariables[i].VarType) = 'string255' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ShortString;')
            else if LowerCase(FVariables[i].VarType) = 'string' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': String;')
            else if LowerCase(FVariables[i].VarType) = 'ansi_string' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': AnsiString;')
            else if LowerCase(FVariables[i].VarType) = 'unicode_string' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': UnicodeString;')
            else if LowerCase(FVariables[i].VarType) = 'dynamic_array' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Array of type;')
            else if LowerCase(FVariables[i].VarType) = 'set' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Set of type;')
            else if LowerCase(FVariables[i].VarType) = 'file' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': File;')
            else if LowerCase(FVariables[i].VarType) = 'text_file' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TextFile;')
            else if LowerCase(FVariables[i].VarType) = 'binary_file' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': BinaryFile;')
            else if LowerCase(FVariables[i].VarType) = 'file_struct' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Typed File;')
            else if LowerCase(FVariables[i].VarType) = 'pointer' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Pointer;')
            else if LowerCase(FVariables[i].VarType) = 'pointer_to' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ^type;')
            else if LowerCase(FVariables[i].VarType) = 'any' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Variant;')
            else if LowerCase(FVariables[i].VarType) = 'ole_variant' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': OleVariant File;')

          else
           begin
              PascalCode.Add('  { ERROR: Nieznany typ: ' + FVariables[i].VarType + ' }');
              PascalCode.Add('  ' + FVariables[i].VarName + ': Variant; // Unknown type: ' + FVariables[i].VarType);
           end;
             //PascalCode.Add('  ' + FVariables[i].VarName + ': String;');
           //PascalCode.Add('  ' + FVariables[i].VarName + ';');

        end;
        PascalCode.Add('');
      end;
      {
      //Alternatywne dodanie zmienncyh
      if Length(FVariables) > 0 then
      begin
        PascalCode.Add('var');
        for i := 0 to High(FVariables) do
        begin
        if FVariables[i].VarName = '' then Continue; // pomiń brakujące nazwy
          // deklaracja zmiennych
        if LowerCase(FVariables[i].VarType) = 'plik' then
          PascalCode.Add('  ' + FVariables[i].VarName + ': File;')
          else if LowerCase(FVariables[i].VarType) = 'plik_tekstowy' then
          begin
            PascalCode.Add('  ' + FVariables[i].VarName + ': TextFile;');
            // jeśli NoAssign = True, pomiń przypisanie
          end
         else
           begin
              PascalCode.Add('  { ERROR: Nieznany typ: ' + FVariables[i].VarType + ' }');
              PascalCode.Add('  ' + FVariables[i].VarName + ': Variant; // Unknown type: ' + FVariables[i].VarType);
           end;
        end;
        PascalCode.Add('');
      end;
      }
      //koniec

      // Dodaj główny blok programu
      PascalCode.Add('begin');
      // Zawsze dodawaj ustawienia konsoli
      //PascalCode.Add('  SetConsoleOutputCP(CP_UTF8);');
      //PascalCode.Add('  SetConsoleCP(CP_UTF8);');
      PascalCode.Add('  {$IFDEF WINDOWS}');
      PascalCode.Add('  SetConsoleOutputCP(CP_UTF8);');
      PascalCode.Add('  SetConsoleCP(CP_UTF8);');
      PascalCode.Add('  {$ENDIF}');

      // --- inicjalizacje zmiennych (tylko gdy NoAssign = False) ---
    for i := 0 to High(FVariables) do
    begin
      if FVariables[i].VarName = '' then Continue;

      // dla plików z przypisaniem
      if (LowerCase(FVariables[i].VarType) = 'plik') or
         (LowerCase(FVariables[i].VarType) = 'plik_tekstowy') then
      begin
        if not FVariables[i].NoAssign then
        begin
          PascalCode.Add('  AssignFile(' + FVariables[i].VarName + ', ''plik.txt'');');
          PascalCode.Add('  Rewrite(' + FVariables[i].VarName + ');');
        end;
      end;
    end;

      // Przetwarzaj linie kodu wykonywalnego
      for i := 0 to AvocadoCode.Count - 1 do
      begin
        trimmedLine := Trim(AvocadoCode[i]);
        if trimmedLine = '' then Continue;

        // Pomiń linie 'program', 'importuj', 'ModułyPas'
        if AnsiStartsText('program ', trimmedLine) or
           AnsiStartsText('importuj', trimmedLine) or
           AnsiStartsText('plik ', LowerCase(trimmedLine)) or
           AnsiStartsText('plik_tekstowy ', LowerCase(trimmedLine)) or
           AnsiStartsText('ModułyPas', trimmedLine) then
        begin
          Continue;
        end
        else
        begin
          ProcessLine(trimmedLine, PascalCode);
        end;
      end;




      PascalCode.Add('  Readln;');
      PascalCode.Add('end.');

      Result := PascalCode;
    finally
      UsesList.Free;
      ExistingUnits.Free;
    end;
  end;



end.

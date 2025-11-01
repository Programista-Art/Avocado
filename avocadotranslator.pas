unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils,fpexprpars,Crt,LazUTF8,Graphics,Variants,DefaultTranslator,LCLTranslator;

type
  TReplaceRule = record
    FromText: string;
    ToText: string;
    Flags: TReplaceFlags;
    IsPrefix: Boolean;
  end;
type
  TStringArray = array of string;
  TAvocadoVariable = record
  Name, VarType: string;
  VarName: string;
  NoAssign: Boolean;
  end;

type
  TStringArrayLabels = array of string;
  TAvocadoLabel = record
  Name, LabelType: string;
  LabelName: string;
  //NoAssign: Boolean;
end;

  { TAvocadoTranslator }

  TAvocadoTranslator = class
  private
    FVariables: array of TAvocadoVariable;
    FInRepeatBlock: Boolean;
    FInMultiLineComment: Boolean;
    FLabels: array of TAvocadoLabel;
    destructor Destroy; override;
    constructor Create;


    //dotyczy petli while
    procedure ProcessWhileLoop(const Line: string; PascalCode: TStringList);
    procedure ProcessForLoop(const Line: string; PascalCode: TStringList);
    procedure ProcessForInLoop(const Line: string; PascalCode: TStringList);
    // procedure AddVariable(const Name, VarType: string);
    function TranslateExpression(const Expr: string): string;
    procedure ProcessDeclaration(const Line: string);

    //procedure ProcessLine(const Line: string; PascalCode: TStringList);
    procedure ProcessLine(const Line: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);

    function PrzetworzBlok(const Blok: string): string;
    //Otrzumuje nazwy modulów i wstawia do sekcji Interface
    function GetImportedModules(const Code: string): string;
    //Otrzumuje nazwy stykiet i wstawia do sekcji Interface
    function GetLabels(const Code: string): string;
    //Otrzumuje nazwy modulów i wstawia do sekcji Implementation
    function GetImplementationModules(const Code: string): string;
    //Centralizacja Logiki Parsowania 10.10.2025
    function ExtractFunctionCall(const Line: string; var VarName: string; var Params: TStringArray): string;

  public
    //Ustawienia dyrektyw kompilatora
    procedure AddCompilerDirective(PascalCode: TStringList);
    function Translate(const AvocadoCode: TStrings): TStringList;


    function duze_litery_ansi(const S: string): string;
    function male_litery_ansi(const S: string): string;
   // function IsKnownType(const S: string): Boolean;
    procedure SplitStringByChar(const AString: string; const ASeparator: Char; AResultList: TStrings);
    function SplitArguments(const ASource: string; AStrings: TStrings): Boolean;
    procedure AddVariable(const VarName, VarType: string; NoAssign: Boolean = False);
    //Aliasy
    function ResolveAlias(const AName: string): string;
    procedure ProcessFileDeclaration(const Line: string);
  end;

const
  //Conversions / Konwersje
  REPLACE_RULES: array of TReplaceRule = (
    //Polish aliases
   // (FromText: ' i '; ToText: ' and '; Flags: [rfReplaceAll]; IsPrefix: False),
   // (FromText: ' lub '; ToText: ' or '; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'prawda'; ToText: 'True'; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'falsz'; ToText: 'False'; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_w_liczbe_cal('; ToText: 'StrToInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_zmiennoprzecinkową('; ToText: 'StrToFloat('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_na_tekst('; ToText: 'IntToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zmiennoprzecinkowa_na_tekst('; ToText: 'FloatToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rzeczywista('; ToText: 'Real('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'obetnij('; ToText: 'Trunc('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'logiczny_na_tekst('; ToText: 'BoolToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'bajt_na_logiczny('; ToText: 'ByteBool(Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_liczbę_lub_domyślną('; ToText: 'StrToIntDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zaokrąglij('; ToText: 'Round('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'na_całkowitą_16('; ToText: 'Word('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_32('; ToText: 'LongInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczebnik('; ToText: 'Cardinal('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zmiennoprzecinkowa_na_tekst_formatowany('; ToText: 'FloatToStrF('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'podwójna_precyzja('; ToText: 'Double('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'Liczba_rozszerzonaWPojedynczą('; ToText: 'Extended('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'Liczba_pojedyncza_na_zm('; ToText: 'Single('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
    (FromText: ' and '; ToText: ' and '; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: ' or '; ToText: ' or '; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'true'; ToText: 'True'; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'false'; ToText: 'False'; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_int('; ToText: 'StrToInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_float('; ToText: 'StrToFloat('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'int_str('; ToText: 'IntToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'float_str('; ToText: 'FloatToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'real('; ToText: 'Real('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'trunc('; ToText: 'Trunc('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'bool_str('; ToText: 'BoolToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'byte_bool(Ord('; ToText: 'ByteBool(Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_int_def('; ToText: 'StrToIntDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'round('; ToText: 'Round('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'word('; ToText: 'Word('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'long_int('; ToText: 'LongInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'cardinal('; ToText: 'Cardinal('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'float_strf('; ToText: 'FloatToStrF('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'double('; ToText: 'Double('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'extended('; ToText: 'Extended('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'single('; ToText: 'Single('; Flags: [rfReplaceAll]; IsPrefix: False),
    // character and string conversions / konwersje znaków i string
    //Polish aliases
    (FromText: 'liczba_na_znak('; ToText: 'Chr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'znak_na_liczbę('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'znak_na_tekst('; ToText: 'Char('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_znak('; ToText: 'String('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
    (FromText: 'chr('; ToText: 'Chr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'ord('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'char('; ToText: 'Char('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'string('; ToText: 'String('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'repeat_char('; ToText: 'StringOfChar('; Flags: [rfReplaceAll]; IsPrefix: False),
    // logical conversions / konwersje logiczne
    //Polish aliases
    (FromText: 'tekst_na_logiczny('; ToText: 'StrToBool('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_logiczny_dom('; ToText: 'StrToBoolDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'logiczny_z_liczby('; ToText: 'Boolean('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_z_logicznego('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_z_wyliczenia('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_nazwę_tekstu('; ToText: 'GetEnumName('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_wartość_wyliczenia('; ToText: 'GetEnumValue('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
    (FromText: 'str_bool('; ToText: 'StrToBool('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_bool_def('; ToText: 'StrToBoolDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'bool('; ToText: 'Boolean('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'Int('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'get_enum_name('; ToText: 'GetEnumName('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'get_enum_value('; ToText: 'GetEnumValue('; Flags: [rfReplaceAll]; IsPrefix: False),
    // date and time / data i czas
    //Polish aliases
    (FromText: 'data_na_tekst('; ToText: 'DateToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'czas_na_tekst('; ToText: 'TimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'data_czas_na_tekst('; ToText: 'DateTimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'formatuj_data_czas_na_tekst('; ToText: 'FormatDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę('; ToText: 'StrToDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_czas('; ToText: 'StrToTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_czas('; ToText: 'StrToDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_dom('; ToText: 'StrToDateDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_czas_dom('; ToText: 'StrToTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_czas_dom('; ToText: 'StrToDateTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utwórz_datę('; ToText: 'EncodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utwórz_czas('; ToText: 'EncodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozłóż_datę('; ToText: 'DecodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozłóż_czas('; ToText: 'DecodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
    (FromText: 'date_str('; ToText: 'DateToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'time_str('; ToText: 'TimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'date_time_str('; ToText: 'DateTimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'format_date_time('; ToText: 'FormatDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date('; ToText: 'StrToDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_to_time('; ToText: 'StrToTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date_time('; ToText: 'StrToDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date_def('; ToText: 'StrToDateDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_time_def('; ToText: 'StrToTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_datetime_def('; ToText: 'StrToDateTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'encode_date('; ToText: 'EncodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'encode_time('; ToText: 'EncodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'decode_date('; ToText: 'DecodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'decode_time('; ToText: 'DecodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    // indicators
    //Polish aliases
    (FromText: 'adres_zmiennej('; ToText: 'Ptr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'adres_zmiennej_z_wskażnika('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: '@('; ToText: '@('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'klawisz_wciśnięty'; ToText: 'KeyPressed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'ptr('; ToText: 'Ptr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'int_ptr('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: '@('; ToText: '@('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'key_pressed'; ToText: 'KeyPressed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // colors
    //Polish aliases
    (FromText: 'czarny'; ToText: 'Black'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'biały'; ToText: 'White'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'niebieski'; ToText: 'Blue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'zielony'; ToText: 'Green'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'czerwony'; ToText: 'Red'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'żółty'; ToText: 'Yellow'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'cyjan'; ToText: 'Cyan'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'magenta'; ToText: 'Magenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'brązowy'; ToText: 'Brown'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'jasnoszary'; ToText: 'LightGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'ciemnoszary'; ToText: 'DarkGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'jasnoniebieski'; ToText: 'LightBlue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'jasnozielony'; ToText: 'LightGreen'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'jasnoczerwony'; ToText: 'LightRed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'jasnoróżowy'; ToText: 'LightMagenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'migotanie'; ToText: 'Blink'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'black'; ToText: 'Black'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'white'; ToText: 'White'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'blue'; ToText: 'Blue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'green'; ToText: 'Green'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'red'; ToText: 'Red'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'yellow'; ToText: 'Yellow'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'cyan'; ToText: 'Cyan'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    //(FromText: 'magenta'; ToText: 'Magenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'brown'; ToText: 'Brown'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'light_gray'; ToText: 'LightGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'dark_gray'; ToText: 'DarkGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'light_blue'; ToText: 'LightBlue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'light_green'; ToText: 'LightGreen'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'light_red'; ToText: 'LightRed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'light_magenta'; ToText: 'LightMagenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'blink'; ToText: 'Blink'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // funkcje string
    //Polish aliases
    (FromText: 'powtórz_znak('; ToText: 'StringOfChar('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'kopiuj'; ToText: 'Copy'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'wstaw'; ToText: 'Insert'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'szukaj'; ToText: 'Pos'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'copy'; ToText: 'Copy'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'insert'; ToText: 'Insert'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'pos'; ToText: 'Pos'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // nil i free
    //Polish aliases
    (FromText: 'nic'; ToText: 'nil'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '.tekst'; ToText: '.Text'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'zwolnij'; ToText: 'free'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
     (FromText: 'zwiększ'; ToText: 'inc'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'nil'; ToText: 'nil'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '.text'; ToText: '.Text'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'free'; ToText: 'free'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // prefix aliases / aliasy prefiksowe
    //Polish aliases
    (FromText: 'czy_istnieje_plik'; ToText: 'FileExists'; Flags: []; IsPrefix: True),
    (FromText: 'czy_istnieje_katalog'; ToText: 'DirectoryExists'; Flags: []; IsPrefix: True),
    (FromText: 'pobierz_zmienną_środowiskową'; ToText: 'GetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'ustaw_zmienną_środowiskową'; ToText: 'SetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'pobierz_katalog_bieżący'; ToText: 'GetCurrentDir'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'file_exists'; ToText: 'FileExists'; Flags: []; IsPrefix: True),
    (FromText: 'directory_exists'; ToText: 'DirectoryExists'; Flags: []; IsPrefix: True),
    (FromText: 'get_env'; ToText: 'GetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'set_env('; ToText: 'SetEnvironmentVariable('; Flags: []; IsPrefix: True),
    (FromText: 'get_current_dir'; ToText: 'GetCurrentDir'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False)

    );
var
Moduly: String;
//Dot. bloku kodu w pascalu
InPurePascalBlock: Boolean = False;
NeedsAsmIntel: Boolean;
FPascalMode: Boolean;
FAsmMode: Boolean;

resourcestring
  //Przetlumaczone wyjatki na rózne jezyki
  InvalidVariableDeclaration = 'Incorrect variable declaration: ';
  ErrorPrint = 'Incorrect syntax of the insert function. Expected: insert(source, target, index)';
  FunctionInsert = 'The insert function requires three arguments: source, target, index.';
  FunctionTrim = 'Incorrect syntax of the trim function. Expected: trim(s)';
  FunctionTrimRight = 'Incorrect syntax of the trim_right function. Expected: trim_right(s)';
  FunctionTrimLeft = 'Incorrect syntax of the function trim_from_left. Expected: trim_left(s)';
  TranslateUnknownFileType = 'Unknown file variable type: ';
  TranslateUnknownVariableType = 'Unknown variable type: ';
implementation
uses
  unit1;

{ TAvocadoTranslator }

procedure TAvocadoTranslator.AddVariable(const VarName, VarType: string; NoAssign: Boolean = False);
var
  j: Integer;
begin
    //Check whether the variable already exists
    // Sprawdź, czy zmienna już istnieje
    for j := 0 to High(FVariables) do
      if FVariables[j].VarName = VarName then Exit;

    // Add a new item
    SetLength(FVariables, Length(FVariables) + 1);
    FVariables[High(FVariables)].VarName := VarName;
    FVariables[High(FVariables)].VarType := VarType;
    // Add the NoAssign flag to the variable structure
    // Dodaj flagę NoAssign do struktury zmiennej
    FVariables[High(FVariables)].NoAssign := NoAssign;
end;

//Trzeba to usunac

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
    //We skip the control instructions.
    // Pomijamy instrukcje sterujące

    if LowerCase(TrimmedLine).StartsWith('jeżeli') then Exit;
    if LowerCase(TrimmedLine).StartsWith('if') then Exit;
    if LowerCase(TrimmedLine).StartsWith('then') then Exit;
    if LowerCase(TrimmedLine).StartsWith('else') then Exit;
    if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
    if LowerCase(TrimmedLine).StartsWith('podczas') then Exit;
    if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
    if LowerCase(TrimmedLine).StartsWith('exit') then Exit;
    if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;
    if LowerCase(TrimmedLine).StartsWith('halt') then Exit;

    //Handling declarations WITHOUT value
    // Obsługa deklaracji BEZ wartości
    if Pos(':', Line) = 0 then
    begin
      VarParts := TrimmedLine.Split([' '], 2);
      if Length(VarParts) < 2 then Exit;

      VarType := LowerCase(Trim(VarParts[0]));
      VarName := Trim(VarParts[1]);

      if (VarType = 'plik') or (VarType = 'plik_tekstowy') or
         (VarType = 'file') or (VarType = 'text_file') then
      begin
        // the declaration itself
        AddVariable(VarName, VarType, True);
        Exit;
      end;

      raise Exception.Create(TranslateUnknownFileType + VarType);
    end;

    // Handling declarations with a value (after “:”)
    // Obsługa deklaracji Z wartością (po ':')
    Parts := Line.Split([':'], 2);
    if Length(Parts) < 2 then Exit;

    VarDecl := Trim(Parts[0]);   // example. "plik f"
    VarValue := Trim(Parts[1]);  // example. "nil" albo ścieżka do pliku

    VarParts := VarDecl.Split([' '], 2);
    if Length(VarParts) < 2 then
      raise Exception.Create(InvalidVariableDeclaration + Line);

    VarType := LowerCase(Trim(VarParts[0]));
    VarName := Trim(VarParts[1]);

    if (VarType = 'plik') or (VarType = 'plik_tekstowy') or
       (VarType = 'file') or (VarType = 'text_file') then
    begin
      if (LowerCase(VarValue) = 'nil') or (LowerCase(VarValue) = 'nic') then
        AddVariable(VarName, VarType, True)  // declaration without initialisation / deklaracja bez inicjalizacji
      else
        AddVariable(VarName, VarType, False); // declaration with attribution / deklaracja z przypisaniem
      Exit;
    end;

    raise Exception.Create(TranslateUnknownFileType + VarType);
end;

function IsInsideAnotherFunction(const Line, FuncName: string): Boolean;
var
  FuncPos, OpenParenBefore, CloseParenAfter: Integer;
begin
  FuncPos := Pos(FuncName + '(', Line);
    if FuncPos = 0 then
      Exit(False);

    // Sprawdź czy przed funkcją jest inna funkcja
    OpenParenBefore := Pos('(', Copy(Line, 1, FuncPos - 1));
    CloseParenAfter := Pos(')', Copy(Line, FuncPos, Length(Line)));

    // Jeśli przed naszą funkcją jest '(' i po niej jest ')', to jest wewnątrz innej funkcji
    Result := (OpenParenBefore > 0) and (CloseParenAfter > 0);
end;

function ReplaceFunctionCall(const Line, FuncName, Replacement: string): string;
var
  StartPos, EndPos, ParenCount, i: Integer;
begin
   Result := Line;
  StartPos := Pos(FuncName + '(', Result);

  if StartPos > 0 then
  begin
    // Znajdź odpowiadający zamykający nawias
    EndPos := StartPos + Length(FuncName);
    ParenCount := 1;
    i := EndPos + 1;

    while (i <= Length(Result)) and (ParenCount > 0) do
    begin
      if Result[i] = '(' then
        Inc(ParenCount)
      else if Result[i] = ')' then
        Dec(ParenCount);

      if ParenCount = 0 then
        Break;

      Inc(i);
    end;

    if ParenCount = 0 then
    begin
      // Zamień całe wywołanie funkcji
      Delete(Result, StartPos, i - StartPos + 1);
      Insert(Replacement, Result, StartPos);
    end;
  end;
end;

//function to check whether a string is a string literal
// funkcja do sprawdzania, czy łańcuch jest literałem string
function IsQuotedString(const S: string): Boolean;
begin
  Result := (Length(S) >= 2) and
            ((S[1] = '''') and (S[Length(S)] = '''') or
             (S[1] = '"') and (S[Length(S)] = '"'));
end;

//Conversions / Konwersje
function TAvocadoTranslator.TranslateExpression(const Expr: string): string;
var
i: Integer;
R: TReplaceRule;
P: Integer;
begin
  Result := Expr;
  for i := Low(REPLACE_RULES) to High(REPLACE_RULES) do
  begin
    R := REPLACE_RULES[i];
    if R.IsPrefix then
    begin
      if AnsiStartsText(R.FromText, Trim(Result)) then
      begin
        P := Pos('(', Result);
        if P > 0 then
          Result := R.ToText + Copy(Result, P, MaxInt);
      end;
    end
    else
    begin
      Result := StringReplace(Result, R.FromText, R.ToText, R.Flags);
    end;
  end;
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

  //We skip lines beginning with control statements.
  // Pomijamy linie zaczynające się od instrukcji sterujących
  if FPascalMode then
  begin
    // sprawdź czy to koniec bloku
    if TrimmedLine = '}' then
      FPascalMode := False;
    Exit; // ignorujemy całą resztę
  end;

  // blok Pascala
  if LowerCase(TrimmedLine).StartsWith('pascal{') then
  begin
    FPascalMode := True;
    Exit;
  end;

  //Pomija kod assemblera
  if FAsmMode then
  begin
    // sprawdź czy to koniec bloku
    if TrimmedLine = '}' then
      FAsmMode := False;
    Exit; // ignorujemy całą resztę
  end;

  // blok assemblera asm
  if LowerCase(TrimmedLine).StartsWith('asm{') then
  begin
    FAsmMode := True;
    Exit;
  end;


  if LowerCase(TrimmedLine).StartsWith('jeżeli') then Exit;
  if LowerCase(TrimmedLine).StartsWith('while') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('podczas') then Exit;

  if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
  if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dla') then Exit;
  if LowerCase(TrimmedLine).StartsWith('jeżeli ') then Exit;

  if LowerCase(TrimmedLine).StartsWith('if') then Exit;
  if LowerCase(TrimmedLine).StartsWith('then') then Exit;
  if LowerCase(TrimmedLine).StartsWith('else') then Exit;
  if LowerCase(TrimmedLine).StartsWith('exit') then Exit;

   if LowerCase(TrimmedLine).StartsWith('repeat') then Exit;
   if LowerCase(TrimmedLine).StartsWith('until') then Exit;
   if LowerCase(TrimmedLine).StartsWith('powtarzaj') then Exit;
   if LowerCase(TrimmedLine).StartsWith('aż') then Exit;


  if LowerCase(TrimmedLine).StartsWith('halt') then Exit;
   if LowerCase(TrimmedLine).StartsWith('for') then Exit;
  //Transfer to file handling
  // Przekazanie do obsługi plików
  if LowerCase(TrimmedLine).StartsWith('plik') or
     LowerCase(TrimmedLine).StartsWith('plik_tekstowy') or
     LowerCase(TrimmedLine).StartsWith('file') or
     LowerCase(TrimmedLine).StartsWith('text_file') then
  begin
    ProcessFileDeclaration(Line);
    Exit;
  end;

  //Declaration handling With value (=)
  // Obsługa deklaracji Z wartością (=)
  if Pos('=', Line) = 0 then Exit;

  Parts := Line.Split(['='], 2);
  if Length(Parts) < 2 then Exit;

  VarDecl := Trim(Parts[0]);
  VarValue := Trim(Parts[1]);

  VarParts := VarDecl.Split([' '], 2);
  if Length(VarParts) < 2 then
  exit;
    //raise Exception.Create(InvalidVariableDeclaration + Line);

  VarType := LowerCase(Trim(VarParts[0]));
  VarName := Trim(VarParts[1]);

  // Support for common types
  // Obsługa zwykłych typów
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
     (VarType = 'qliczba') or


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
     (VarType = 'byte_bool') or
     (VarType = 'long_bool') or
     (VarType = 'wide_string') or
     (VarType = 'comp') or
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
     (VarType = 'ole_variant') or
     (VarType = 'informacje_o_wyszukaniu') or
     (VarType = 'qWord') or
     (VarType = 'search_record')
  then
  begin
    // declaration with attribution  / deklaracja z przypisaniem
    AddVariable(VarName, VarType, False);
    Exit;
  end;

  raise Exception.Create(TranslateUnknownVariableType + VarType);
end;

// Advanced argument parsing feature that takes quotation marks into account
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
  // Add the last argument
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


procedure TAvocadoTranslator.ProcessWhileLoop(const Line: string;
  PascalCode: TStringList);
var
TrimmedLine, LowerTrimmedLine: string;
TranslatedLine: string;
begin
  TrimmedLine := Trim(Line);
  LowerTrimmedLine := AnsiLowerCase(TrimmedLine);
  if not (LowerTrimmedLine.StartsWith('podczas ') or LowerTrimmedLine.StartsWith('while ')) then
  begin
    Exit;
  end;

  // pętla while.
  TranslatedLine := TrimmedLine;
  TranslatedLine := ReplaceText(TranslatedLine, 'podczas', 'while');
  TranslatedLine := ReplaceText(TranslatedLine, 'Podczas', 'while');

  // 2.'wykonać' -> 'do'
  TranslatedLine := StringReplace(TranslatedLine, 'wykonać', 'do', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'make', 'do', [rfReplaceAll, rfIgnoreCase]);
  PascalCode.Add(TranslatedLine);
end;

procedure TAvocadoTranslator.ProcessForLoop(const Line: string;
  PascalCode: TStringList);
var
  TranslatedLine: string;
begin
  TranslatedLine := Trim(Line);
    TranslatedLine := StringReplace(TranslatedLine, 'dla', 'for', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'malejąco', 'downto', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'descending', 'downto', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, ' == ', '=', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, '==', '=', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, ' = ', ' := ', [rfReplaceAll]);
    TranslatedLine := StringReplace(TranslatedLine, 'wykonać', 'do', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'make', 'do', [rfReplaceAll, rfIgnoreCase]);


    TranslatedLine := StringReplace(TranslatedLine, ' do ', ' to ', [rfReplaceAll, rfIgnoreCase]);
    PascalCode.Add(TranslatedLine);
end;

procedure TAvocadoTranslator.ProcessForInLoop(const Line: string;
  PascalCode: TStringList);
var
  TranslatedLine: string;
begin
    TranslatedLine := Trim(Line);
    TranslatedLine := StringReplace(TranslatedLine, 'dla', 'for', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, ' w ', ' in ', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'wykonać', 'do', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'make', 'do', [rfReplaceAll, rfIgnoreCase]);

    PascalCode.Add(TranslatedLine);
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
      Statements := SplitString(Blok, '#10');
      for Statement in Statements do
        if Trim(Statement) <> '' then
        // ProcessLine(Trim(Statement), TempList);

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
  ModulesList := '';
  Lines := TStringList.Create;
  try
    Lines.Text := Code;

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);

      // Czy linia zaczyna się od 'importuj' lub 'import'
      if AnsiStartsText('importuj', LowerCase(Line)) then
      begin
        Delete(Line, 1, Length('importuj'));
      end
      else if AnsiStartsText('import', LowerCase(Line)) then
      begin
        Delete(Line, 1, Length('import'));
      end
      else
        Continue; // Nie pasuje, lecimy dalej

      Line := Trim(Line);

      // Dodaj do listy modułów
      if Line <> '' then
      begin
        if ModulesList = '' then
          ModulesList := Line
        else
          ModulesList := ModulesList + ', ' + Line;
      end;
    end;

    Result := ModulesList;


    // Add “Crt” if keywords are detected in the code
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
      //other / inne
      // Returning the resulting list of modules
      // Zwrócenie wynikowej listy modułów
      Result := ModulesList;
    finally
      Lines.Free;
    end;

end;

function TAvocadoTranslator.GetLabels(const Code: string): string;
var
Lines: TStringList;
i: Integer;
Line, LabelList: string;
begin
  LabelList := '';
    Lines := TStringList.Create;
    try
      Lines.Text := Code;

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[i]);

        // Czy linia zaczyna się od 'importuj' lub 'import'
        if AnsiStartsText('label', LowerCase(Line)) then
        begin
          Delete(Line, 1, Length('label'));
        end
        else if AnsiStartsText('etykieta', LowerCase(Line)) then
        begin
          Delete(Line, 1, Length('etykieta'));
        end
        else
          Continue; // Nie pasuje, lecimy dalej

        Line := Trim(Line);

        // Dodaj do listy modułów
        if Line <> '' then
        begin
          if LabelList = '' then
            LabelList := Line
          else
            LabelList := LabelList + ', ' + Line;
        end;
      end;

      Result := LabelList;

        // Zwrócenie wynikowej listy etykiet
       // Result := LabelList;
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

    Result := ModulesList;
  finally
    Lines.Free;
  end;
end;

function TAvocadoTranslator.ExtractFunctionCall(const Line: string;
  var VarName: string; var Params: TStringArray): string;
var
  Call: string;
  StartPos, EndPos: Integer;
  ParamStr: string;
begin
  Result := '';
    VarName := '';
    Params := nil;

    // 1. Sprawdzenie i rozbicie przypisania
    Call := Line;
    if Pos('=', Line) > 0 then
    begin
      VarName := Trim(Copy(Line, 1, Pos('=', Line) - 1));
      Call := Trim(Copy(Line, Pos('=', Line) + 1, MaxInt));

      // Uproszczenie VarName (usuń typ, np. 'string b' -> 'b')
      if Pos(' ', VarName) > 0 then
        VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
    end;

    // 2. Znalezienie nazwy funkcji i argumentów
    StartPos := Pos('(', Call);
    if StartPos = 0 then
    begin
      // Nie jest to wywołanie funkcji, ale może być instrukcją (np. 'wyjść')
      Result := LowerCase(Call);
      Exit;
    end;

    // Pobierz nazwę funkcji (np. 'trim_left')
    Result := LowerCase(Trim(Copy(Call, 1, StartPos - 1)));

    // 3. Parsowanie argumentów
    EndPos := LastDelimiter(')', Call);
    if (EndPos = 0) or (EndPos < StartPos) then
      raise Exception.Create('Błąd parsowania: nieprawidłowe nawiasy w funkcji ' + Result + '.');

    ParamStr := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
    VarName := ParamStr;
end;


procedure TAvocadoTranslator.AddCompilerDirective(PascalCode: TStringList);
var
  DirectIndex, i: Integer;

begin
  DirectIndex := -1;
    for i := 0 to PascalCode.Count - 1 do
    begin
      if Trim(LowerCase(PascalCode[i])).StartsWith('program ') then
      begin
        DirectIndex := i;
        Break;
      end;
    end;

    // Jeśli znaleziono "program"
    if DirectIndex <> -1 then
    begin
      PascalCode.Insert(DirectIndex, '{$H+}');
      PascalCode.Insert(DirectIndex, '{$mode objfpc}');
      PascalCode.Insert(DirectIndex, '{$codepage utf8}');

      // Opcjonalnie asm:
      if NeedsAsmIntel then
        PascalCode.Insert(DirectIndex, '{$ASMMODE intel}');
    end
    else
    begin
      // Gdyby z jakiegoś powodu "program" nie było:
      PascalCode.Insert(0, '{$H+}');
      PascalCode.Insert(0, '{$mode objfpc}');
      PascalCode.Insert(0, '{$codepage utf8}');
      if NeedsAsmIntel then
        PascalCode.Insert(0, '{$ASMMODE intel}');
    end;
end;

function TAvocadoTranslator.duze_litery_ansi(const S: string): string;
begin
  Result := AnsiUpperCase(S);
end;

function TAvocadoTranslator.male_litery_ansi(const S: string): string;
begin
  Result := AnsiLowerCase(S);
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
        // Make sure this quotation mark is not doubled ('')
        // Upewnij się, że ten cudzysłów nie jest zdublowany ('')
        if (I < Length(ASource)) and (ASource[I+1] = QuoteChar) then
        begin
          // This is a double quote in the string, ignore it
          // To jest zdublowany cudzysłów w stringu, zignoruj go
          Inc(I);
        end
        else
        begin
          // This is a real closing quotation mark
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
  if StartPos <= Length(ASource) then
    AStrings.Add(Copy(ASource, StartPos, Length(ASource) - StartPos + 1));
    for I := 0 to AStrings.Count - 1 do
    AStrings[I] := Trim(AStrings[I]);
end;




//processing nested statements.
//przetwarzanie zagnieżdżonych instrukcji.

//procedure TAvocadoTranslator.ProcessLine(const Line: string;
//procedure TAvocadoTranslator.ProcessLine(const Line: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);
//const Ln: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);
////PascalCode: TStringList);
procedure TAvocadoTranslator.ProcessLine(const Line: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);
var
  Parts: TStringArray;
   VarType, VarName, Value, TrimmedLine,LowerLine: string;

   InstrukcjaWarunkowa: TStringArray;
   KodWtedy, KodInaczej,LowerTrimmedLine: string;
   TempList: TStringList;
   Statements: TStringArray;
   Statement: string;
   Start,EndPos: Integer;
   pisznfStart,pisznfEndPos:Integer;
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
  ArgStr: string;
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
  Expression,Call: string;
  StartPosTrim, EndPosTrim: Integer;
  ParamTrim: string;
  TranslatedParam: string;
  // zmienne dla funkcji powtórz_znak()

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
  // to separate lines (e.g. Split) / do rozdzielania linii (np. Split)
  PartsPobierz: TStringArray;
  //Ping
  Site: String;
  //While loop
  OpenPos: Integer;
  //Value: string;
  //EqualPos: Integer;
  CodePascal: String;
  ParamStr: string;
  TranslatedLine: string;
  NeedsSemicolon: Boolean;
 // NextTrimmedLowerLine: String;
    LabelName: string;
  SpacePos: Integer;
 //dla repeat until
  ConditionStr: String;
  TranslatedCondition: String;
  LowerLineRepeat: String;
  CleanLowerLine: string;
  //StartPos, EndPos: Integer;
  LineBefore, LineAfter: string;

begin

  TrimmedLine := Trim(Line);
  LowerTrimmedLine := LowerCase(TrimmedLine);

  //POCZĄTEK GLOBALNEJ OBSŁUGI KOMENTARZY

  // 1. Sprawdź, czy jesteśmy W ŚRODKU komentarza z poprzedniej linii
  if FInMultiLineComment then
  begin
    EndPos := Pos('*)', TrimmedLine);
    if EndPos > 0 then
    begin
      // Komentarz się tutaj KOŃCZY
      FInMultiLineComment := False;
      // Bierzemy tylko tekst PO komentarzu
      TrimmedLine := Trim(Copy(TrimmedLine, EndPos + 2, MaxInt));
    end
    else
    begin
      // Komentarz nadal trwa, zignoruj całą tę linię
      Exit;
    end;
  end;

  // 2. Pętla wycinająca komentarze (* ... *) z wnętrza linii
  //    (np. kod (* komentarz *) kod )
  while Pos('(*', TrimmedLine) > 0 do
  begin
    StartPos := Pos('(*', TrimmedLine);
    EndPos := Pos('*)', TrimmedLine);

    if (EndPos > StartPos) then
    begin
      // Przypadek 1: Komentarz zamyka się w tej samej linii
      LineBefore := Copy(TrimmedLine, 1, StartPos - 1);
      LineAfter := Copy(TrimmedLine, EndPos + 2, MaxInt);
      TrimmedLine := Trim(LineBefore + ' ' + LineAfter);
    end
    else
    begin
      // Przypadek 2: Komentarz (*... ROZPOCZYNA SIĘ tutaj
      FInMultiLineComment := True;
      // Bierzemy tylko kod PRZED komentarzem
      TrimmedLine := Trim(Copy(TrimmedLine, 1, StartPos - 1));
      Break; // Przerwij pętlę while, przetworzymy to, co zostało
    end;
  end;

  // 3. Wytnij komentarze jednoliniowe //
  // (Ten blok musi być PO bloku 2)
  if Pos('//', TrimmedLine) > 0 then
  begin
    TrimmedLine := Trim(Copy(TrimmedLine, 1, Pos('//', TrimmedLine) - 1));
  end;

  // 4. Jeśli po wycięciu wszystkich komentarzy nic nie zostało, zakończ
  if TrimmedLine = '' then
    Exit;
  // --- KONIEC BRAKUJĄCEJ LOGIKI ---

  // 5. Dopiero teraz ustawiamy zmienne robocze
  LowerTrimmedLine := LowerCase(TrimmedLine);
  LowerLine := AnsiLowerCase(TrimmedLine);



  // 1. Zignoruj puste linie i komentarze
  if (TrimmedLine = '') or TrimmedLine.StartsWith('//') then Exit;

  // Używamy tylko JEDNEJ znormalizowanej wersji
 LowerTrimmedLine := LowerCase(TrimmedLine);




  // 2. Grupujemy wszystkie słowa kluczowe w jeden 'case'
  case LowerTrimmedLine of
    'początek',
    'start':
    begin
      PascalCode.Add('begin');
      Exit;
    end;

    'koniec',
    'end':
    begin
      // To jest implementacja Twojego pomysłu:
      if (NextTrimmedLowerLine = 'inaczej') or (NextTrimmedLowerLine = 'else') then
        PascalCode.Add('end') // Bez średnika
      else
        PascalCode.Add('end;'); // Ze średnikiem
      Exit;
    end;

    'koniec.',
    'end.':
    begin
      PascalCode.Add('end.');
      Exit;
    end;
  end;



     //warunek If then else
    NeedsSemicolon := (NextTrimmedLowerLine <> 'inaczej');
    if (LowerTrimmedLine.StartsWith('jeżeli ')) or (LowerTrimmedLine.StartsWith('if ')) or
      (LowerTrimmedLine.StartsWith('inaczej')) or (LowerTrimmedLine.StartsWith('else')) then
    begin
      TranslatedLine := TrimmedLine;
      TranslatedLine := StringReplace(TranslatedLine, 'inaczej jeżeli', 'else if', [rfReplaceAll, rfIgnoreCase]);
      TranslatedLine := StringReplace(TranslatedLine, 'jeżeli', 'if', [rfReplaceAll, rfIgnoreCase]);
      TranslatedLine := StringReplace(TranslatedLine, 'wtedy', 'then', [rfReplaceAll, rfIgnoreCase]);
      TranslatedLine := StringReplace(TranslatedLine, 'inaczej', 'else', [rfReplaceAll, rfIgnoreCase]);

      PascalCode.Add(TranslatedLine);
      Exit;
    end;

    //break / continue w petlach
    CleanLowerLine := LowerTrimmedLine;
    if CleanLowerLine.EndsWith(';') then
      CleanLowerLine := CleanLowerLine.Substring(0, CleanLowerLine.Length - 1);
    if (CleanLowerLine = 'przerwać') or (CleanLowerLine = 'break') then
    begin
      PascalCode.Add('break;');
      Exit;
    end;
    if (CleanLowerLine = 'kontynuować') or (CleanLowerLine = 'continue') then
    begin
      PascalCode.Add('continue;');
      Exit;
    end;

    //Petle
    //petal for ('dla ... do ... wykonać')
     NeedsSemicolon := (NextTrimmedLowerLine <> 'dla');
     NeedsSemicolon := (NextTrimmedLowerLine <> 'for');

    if (LowerTrimmedLine.StartsWith('dla ')) or (LowerTrimmedLine.StartsWith('for ')) then
     begin
      // Sprawdzamy, CZY TO JEST PĘTLA FOR...IN
      // Sprawdzamy obecność ' w ' lub ' in ' (ze spacjami)
        if (Pos(' w ', LowerTrimmedLine) > 0) or (Pos(' in ', LowerTrimmedLine) > 0) then
        begin
          // Tak, to pętla FOR...IN
          ProcessForInLoop(TrimmedLine, PascalCode);
          Exit;
        end
        else
        begin
          // Nie, to jest zwykła pętla FOR...TO/DOWNTO
          ProcessForLoop(TrimmedLine, PascalCode);
          Exit;
        end;
    end;

    {NeedsSemicolon := (NextTrimmedLowerLine <> 'dla');
    NeedsSemicolon := (NextTrimmedLowerLine <> 'for');
    if (LowerTrimmedLine.StartsWith('dla ')) or (LowerTrimmedLine.StartsWith('for ')) then
     begin
      ProcessForLoop(TrimmedLine, PascalCode);
      Exit;
    end;
   }

    //Petla while do
    NeedsSemicolon := (NextTrimmedLowerLine <> 'while');
    NeedsSemicolon := (NextTrimmedLowerLine <> 'podczas');

    if (LowerTrimmedLine.StartsWith('podczas ')) or (LowerTrimmedLine.StartsWith('while ')) then
    begin
      ProcessWhileLoop(TrimmedLine, PascalCode);
      Exit;
    end;



    //etykieta label goto
    // Obsługa polecenia SKOCZ_DO (goto)
  if LowerTrimmedLine.StartsWith('jump') or
     LowerTrimmedLine.StartsWith('skocz') then
  begin

    // 1. Znajdź pierwszą spację, aby wyciąć nazwę etykiety
    SpacePos := Pos(' ', TrimmedLine);
    if SpacePos = 0 then
      raise Exception.Create('Brak nazwy etykiety po poleceniu skocz / jump');

    // 2. Wyodrębnij nazwę etykiety
    LabelName := Trim(TrimmedLine.Substring(SpacePos ));

    // 3. Usuń ewentualny średnik z końca (jeśli użytkownik go dodał)
    if LabelName.EndsWith(';') then
      LabelName := LabelName.Substring(0, Length(LabelName) - 1);

    // 4. Dodaj poprawny kod Pascala ZE ŚREDNIKIEM
    PascalCode.Add('goto ' + LabelName + ';');

    Exit;
  end;


  // Obsługa petli repeat until
  //Obsługa POCZĄTKU pętli (repeat / powtarzaj)
  if (LowerLine = 'powtarzaj') or (LowerLine = 'repeat') then
  begin
    // Sprawdzenie, czy nie jesteśmy już w bloku
    if FInRepeatBlock then
      raise Exception.Create('Błąd: Znaleziono "powtarzaj" wewnątrz innego "powtarzaj"');

    PascalCode.Add('repeat');
    FInRepeatBlock := True; // Ustawiamy pole KLASY
    Exit;                   // Przechodzimy do następnej linii
  end;

  // Obsługa KOŃCA pętli (until / aż)
  // Sprawdzamy, czy linia ZACZYNA SIĘ od słów kluczowych ZE SPACJĄ
  if LowerLine.StartsWith('aż ') or LowerLine.StartsWith('until ') then
  begin
    // Sprawdzenie, czy na pewno byliśmy w bloku
    if not FInRepeatBlock then
      raise Exception.Create('Błąd: Znaleziono "aż" lub "until" bez pasującego "powtarzaj"');

    // Wyciągamy sam warunek (string po słowie kluczowym)
    if LowerLine.StartsWith('aż ') then
      // Kopiuje wszystko PO "aż " (długość 3 + spacja = 4)
      ConditionStr := Trim(Copy(TrimmedLine, 4, Length(TrimmedLine)))
    else
      // Kopiuje wszystko PO "until " (długość 6 + spacja = 7)
      ConditionStr := Trim(Copy(TrimmedLine, 7, Length(TrimmedLine)));

    if ConditionStr = '' then
      raise Exception.Create('Błąd: Brak warunku po "aż" / "until"');

    // Tłumaczymy wyrażenie warunku
    TranslatedCondition := TranslateExpression(ConditionStr);

    PascalCode.Add('until ' + TranslatedCondition + ';');
    FInRepeatBlock := False; // Zerujemy flagę (pole KLASY)
    Exit;                    // Przechodzimy do następnej linii
  end;


  //Insert() function support
  // Obsługa funkcji wstaw() → Insert()
   if (AnsiLowerCase(TrimmedLine).StartsWith('wstaw(')) or
          (AnsiLowerCase(TrimmedLine).StartsWith('insert(')) then
  begin
    StartPosInsert := Pos('(', TrimmedLine);
    EndPosInsert   := RPos(')', TrimmedLine);

    if (StartPosInsert <= 0) or (EndPosInsert <= StartPosInsert) then
      raise Exception.Create(ErrorPrint);  // Nieprawidłowe nawiasy

    ParamInsert := Trim(Copy(TrimmedLine, StartPosInsert + 1, EndPosInsert - StartPosInsert - 1));
    ParamPartsInsert := ParamInsert.Split([',']);

    if Length(ParamPartsInsert) <> 3 then
      raise Exception.Create(FunctionInsert); // Błąd: Insert wymaga 3 argumentów

    InsertSourceIn := TranslateExpression(Trim(ParamPartsInsert[0]));
    InsertTargetIn := TranslateExpression(Trim(ParamPartsInsert[1]));
    InsertIndexIn  := TranslateExpression(Trim(ParamPartsInsert[2]));

    PascalCode.Add('Insert(' + InsertSourceIn + ', ' + InsertTargetIn + ', ' + InsertIndexIn + ');');
    Exit;
  end


   // obsługa funkcji przytnij() -> Trim()
   // Funkcja przytnij('') / trim('')
   else if Pos('=', TrimmedLine) > 0 then
   begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then
       VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
   end;
   Call := Expression;
   if StartsText('przytnij(', Call) or
      StartsText('trim(', Call) then
   begin
     StartPos := Pos('(', Call);
     EndPos := LastDelimiter(')', Call);
      // Walidacja nawiasów
     if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create('Brak nawiasów w funkcji przytnij / trim.');

     if StartPos > EndPos then
       raise Exception.Create('Nieprawidłowa kolejność nawiasów w przytnij / trim().');
     ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
     TranslatedParam := TranslateExpression(ParamTrim );
     if VarName <> '' then
     begin
       PascalCode.Add(VarName + ' := Trim(' + TranslatedParam + ');');
     end
     else
     begin
       PascalCode.Add('Trim(' + TranslatedParam + ');');
     end;
     Exit;
   end;

   // Funkcja przytnij_z_lewa('') / trim_left('')
   if Pos('=', TrimmedLine) > 0 then
   begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then
       VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
   end;
   Call := Expression;

   // Sprawdzamy, czy wyrażenie zawiera docelową funkcję
   if StartsText('przytnij_z_lewa(', Call) or
      StartsText('trim_left(', Call) then
   begin
     StartPos := Pos('(', Call);
     // Używamy LastDelimiter dla znalezienia ostatniego nawiasu ')'
     EndPos := LastDelimiter(')', Call);
      // Walidacja nawiasów
     if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create('Brak nawiasów w funkcji przytnij_z_lewa / trim_left.');

     if StartPos > EndPos then
       raise Exception.Create('Nieprawidłowa kolejność nawiasów w trim_left().');
     // Parsowanie parametru
     ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
     TranslatedParam := TranslateExpression(ParamTrim );
     if VarName <> '' then
     begin
       // Jeśli mamy nazwę zmiennej, generujemy przypisanie
       PascalCode.Add(VarName + ' := TrimLeft(' + TranslatedParam + ');');
     end
     else
     begin
       // W przeciwnym razie, generujemy samo wywołanie
       PascalCode.Add('TrimLeft(' + TranslatedParam + ');');
     end;
     Exit;
   end;

   //Obsługa funkcji przytnij_z_prawa() / TrimRight()
   if Pos('=', TrimmedLine) > 0 then
   begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then
       VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
   end;
   Call := Expression;

   // Sprawdzamy, czy wyrażenie zawiera docelową funkcję
   if StartsText('przytnij_z_prawa(', Call) or
      StartsText('trim_right(', Call) then
   begin
     StartPos := Pos('(', Call);
     // Używamy LastDelimiter dla znalezienia ostatniego nawiasu ')'
     EndPos := LastDelimiter(')', Call);
      // Walidacja nawiasów
     if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create('Brak nawiasów w funkcji przytnij_z_prawa / trim_right.');

     if StartPos > EndPos then
       raise Exception.Create('Nieprawidłowa kolejność nawiasów w przytnij_z_prawa() / trim_right');

     // Parsowanie parametru
     ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));

     // Tłumaczenie parametru (zakładamy, że funkcja TranslateExpression działa poprawnie)
     TranslatedParam := TranslateExpression(ParamTrim);

     // 3. Generowanie kodu Pascala
     if VarName <> '' then
     begin
       // Jeśli mamy nazwę zmiennej, generujemy przypisanie
       PascalCode.Add(VarName + ' := TrimRight(' + TranslatedParam + ');');
     end
     else
     begin
       // W przeciwnym razie, generujemy samo wywołanie
       PascalCode.Add('TrimRight(' + TranslatedParam + ');');
     end;
     Exit;
   end;

     if AnsiStartsText('pascal_line', TrimmedLine) or
       AnsiStartsText('pascal_linia{', TrimmedLine) then
    begin
      if AnsiStartsText('pascal_line', TrimmedLine) then
        CodePascal := Trim(Copy(TrimmedLine, Length('pascal_line') + 1, MaxInt))
      else
        CodePascal := Trim(Copy(TrimmedLine, Length('pascal_linia{') + 1, MaxInt));

      if CodePascal.StartsWith('{') then
        CodePascal := CodePascal.Substring(1).Trim;

      // Usuń opcjonalną klamrę zamykającą
      if CodePascal.EndsWith('}') then
        CodePascal := CodePascal.Substring(0, CodePascal.Length - 1).Trim;

      PascalCode.Add(CodePascal);
      Exit;
    end;


    //pascal code blok kodu
    if not InPurePascalBlock then
    begin
      if AnsiStartsText('pascal {', TrimmedLine) or
         AnsiStartsText('pascal{', TrimmedLine) then
      begin
        InPurePascalBlock := True;
        Exit;
      end;
    end
    else
    begin
      if Trim(TrimmedLine) = '}' then
      begin
        InPurePascalBlock := False;
        Exit;
      end;
      // Linia wewnątrz bloku, kopiujemy bez zmian
      PascalCode.Add(TrimmedLine);
      Exit;
    end;


    //kod assemblera blok kodu
    if not InPurePascalBlock then
    begin
      if AnsiStartsText('asm {', TrimmedLine) or
         AnsiStartsText('asm{', TrimmedLine) then
      begin
        InPurePascalBlock := True;
        //Dodaje do dyrektywy kompilatora {$ASMMODE intel}
        NeedsAsmIntel := True;
        Exit;
      end;
    end
    else
    begin
      if Trim(TrimmedLine) = '}' then
      begin
        InPurePascalBlock := False;
        Exit;
      end;
      PascalCode.Add(TrimmedLine);
      Exit;
    end;


//
//  //Obsługa pętli for
//  if LowerTrimmedLine.StartsWith('dla ') then
//  begin
//    ProcessForLoop(TrimmedLine, PascalCode);
//    Exit;
//  end;

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


   // Obsługa funkcji powtórz_znak() -> StringOfChar()    nowa
  if (Pos('powtórz_znak(', LowerTrimmedLine) > 0) or (Pos('repeat_char(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create('Błędna składnia funkcji powtórz_znak/repeat_char. Oczekiwano: powtórz_znak(znak, liczba) lub repeat_char(znak, liczba)');

    if StartPos > EndPos then
      raise Exception.Create('Błędna składnia funkcji powtórz_znak/repeat_char. Oczekiwano: powtórz_znak(znak, liczba) lub repeat_char(znak, liczba)');

    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    ParamParts := ParamStr.Split([',']);

    if Length(ParamParts) <> 2 then
      raise Exception.Create('Funkcja powtórz_znak/repeat_char wymaga dwóch argumentów: znak i liczba');

    TranslatedCharArg := TranslateExpression(Trim(ParamParts[0]));
    TranslatedCountArg := TranslateExpression(Trim(ParamParts[1]));

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
  TranslatedParam := TranslateExpression(ParamTrim);

  if Pos('=', TrimmedLine) > 0 then
  begin
    Parts := TrimmedLine.Split(['='], 2);
    VarName := Trim(Parts[0]);
    PascalCode.Add(VarName + ' := Halt(' + TranslatedParam + ');');
  end
  else
  begin
    PascalCode.Add('Halt(' + TranslatedParam + ');');
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
      TranslatedParam := TranslateExpression(ParamTrim);
      PascalCode.Add('Exit(' + TranslatedParam + ');');
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
      TranslatedParam := TranslateExpression(ParamTrim);
      PascalCode.Add('ParamCount(' + TranslatedParam + ');');
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
       AnsiStartsText('open_save(', TrimmedLine) or
       AnsiStartsText('открыть_сохранить(', TrimmedLine)
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

    //czy isnieje plik
    if AnsiStartsText('czy_istnieje_plik(', TrimmedLine) or
       AnsiStartsText('file_exists(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia czy_istnieje_plik(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('FileExists(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    {Operacje na katalogach}

     //zmiena katalog
    if AnsiStartsText('zmień_katalog(', TrimmedLine) or
       AnsiStartsText('change_dir(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia zmień_katalog(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('ChDir(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    //Tworzy katalog
    if AnsiStartsText('utwórz_katalog(', TrimmedLine) or
       AnsiStartsText('create_dir(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia utwórz_katalog(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('MkDir(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    //Usuwa katalog
    if AnsiStartsText('usuń_katalog(', TrimmedLine) or
       AnsiStartsText('remove_dir(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia usuń_katalog(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('RmDir(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    // Zwraca ścieżkę do bieżącego katalogu.
    if AnsiStartsText('pobierz_katalog_bieżący(', TrimmedLine) or
       AnsiStartsText('get_current_dir(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia pobierz_katalog_bieżący(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('GetCurrentDir(' + TranslateExpression(Param) + ');');
      Exit;
    end;

    // DirectoryExists(path): Sprawdza, czy katalog istnieje. (z SysUtils)
    if AnsiStartsText('czy_istnieje_katalog(', TrimmedLine) or
       AnsiStartsText('directory_exists(', TrimmedLine)
       then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos   := RPos(')', TrimmedLine);
      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia czy_istnieje_katalog(...)');
      Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      PascalCode.Add('DirectoryExists(' + TranslateExpression(Param) + ');');
      Exit;
    end;


    // Obsługa funkcji długość (Length)
      if Pos('długość(', LowerCase(TrimmedLine)) > 0 then

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

     else if (Pos('czytaj_klawisz', LowerCase(TrimmedLine)) > 0) or
           (Pos('read_key', LowerCase(TrimmedLine)) > 0) then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      if Length(Parts) <> 2 then
        raise Exception.Create('Błędna składnia czytaj_klawisz. Oczekiwano: zmienna = czytaj_klawisz');

      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

    // Sprawdź czy wartość po = to czytaj_klawisz
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


    // Obsługa funkcji pisz_linie
    else if (LowerCase(TrimmedLine).StartsWith('pisz_linie(')) or
            (LowerCase(TrimmedLine).StartsWith('print_line(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine); // Użyj RPos, aby znaleźć ostatni nawias

      if (OpenPos > 0) and (EndPos > OpenPos) then
      begin
        // Kopiuj tylko tekst POMIĘDZY nawiasami
        Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
        PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
        Exit; // Dodaj Exit, aby zakończyć przetwarzanie
      end;
    end

    {else if (LowerCase(TrimmedLine).StartsWith('pisz_linie(')) or
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
    }

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


    {funkcja pisz}
    else if (LowerCase(TrimmedLine).StartsWith('pisz(')) or
            (LowerCase(TrimmedLine).StartsWith('print(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine); // Użyj RPos, aby znaleźć ostatni nawias

      if (OpenPos > 0) and (EndPos > OpenPos) then
      begin
        // Kopiuj tylko tekst POMIĘDZY nawiasami
        Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
        PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
        Exit; // Dodaj Exit, aby zakończyć przetwarzanie
      end;
    end


    //ParamStr(index): Zwraca parametr o numerze index przekazany do programu z linii poleceń.
    else if (LowerCase(TrimmedLine).StartsWith('parametr_programu(')) or
            (LowerCase(TrimmedLine).StartsWith('get_argument(')) then
    begin
     OpenPos := Pos('(', TrimmedLine);
     if OpenPos > 0 then
     begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
       PascalCode.Add('ParamStr(' + TranslateExpression(Value) + ');');
    end;
   end

    //GetEnvironmentVariable(name): Zwraca wartość zmiennej środowiskowej o podanej nazwie. (z SysUtils)
    else if (LowerCase(TrimmedLine).StartsWith('pobierz_zmienną_środowiskową(')) or
            (LowerCase(TrimmedLine).StartsWith('get_environment_variable(')) then
    begin
     OpenPos := Pos('(', TrimmedLine);
     if OpenPos > 0 then
     begin
       Value := Copy(TrimmedLine, OpenPos + 1,
       Length(TrimmedLine) - OpenPos - 1);
       PascalCode.Add('GetEnvironmentVariable(' + TranslateExpression(Value) + ');');
    end;
   end

   // oblicza wyrażenie
   else
   begin
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

 // oblicza wyrażenie
 else
 begin
   if (LowerCase(TrimmedLine).StartsWith('oblicz_formatuj(')) or
      (LowerCase(TrimmedLine).StartsWith('calc_format(')) then
   begin
     // znajdź pierwsze wystąpienie '('
     OpenPos := Pos('(', TrimmedLine);
     if OpenPos > 0 then
     begin
       // wytnij to, co jest w środku nawiasów
       Value := Copy(TrimmedLine, OpenPos + 1,
                     Length(TrimmedLine) - OpenPos - 1);
       //PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
       PascalCode.Add('format(ObliczWyrazenie(' + Value + ');');
     end;
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

    // Dodaje średnik tylko warunkowo
    if NeedsSemicolon then
      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value) + ';')
    else
      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value)); // Bez średnika
    end
    end;


        // --- BLOK OBSŁUGI DEFINICJI ETYKIETY (np. test:) ---
      // Musi być PRZED domyślną obsługą na końcu
      if (TrimmedLine.EndsWith(':')) and (Pos(' ', TrimmedLine) = 0) then
      begin
        PascalCode.Add(TrimmedLine); // Dodaj etykietę (np. "test:") bez średnika
        Exit;
      end

      // --- BLOK DOMYŚLNY (zwykłe przypisania lub inne linie) ---
      else if Pos('=', TrimmedLine) > 0 then
      begin
        // ... (twoja logika dla a = a + 1)
      end

      // --- OSTATNI BLOK (jeśli nic innego nie pasowało) ---
      else if TrimmedLine <> '' then
      begin
        // ... (twoja logika dla pozostałych linii)
      end


    else if TrimmedLine <> '' then
    begin
      TranslatedLine := TranslateExpression(TrimmedLine);
      if NeedsSemicolon then
        PascalCode.Add(TranslatedLine + ';')
      else
        PascalCode.Add(TranslatedLine);
     end;
     end;
 end;




function TAvocadoTranslator.Translate(const AvocadoCode: TStrings): TStringList;
var
  PascalCode: TStringList;
  i: Integer;
  trimmedLine, ModulesStr, LabelStr: string;
  ModulPascalowy: string;
  DetectedProgramName: string; // Do przechowania finalnej nazwy programu
  UsesList: TStringList;     // Pomocnicza lista do budowania 'uses'
  LabelList: TStringList;
  UName: string;             // Pomocnicza do sprawdzania duplikatów i w pętlach
  ExistingUnits: TStringList;  // Do sprawdzania duplikatów
  ExistingLabes: TStringList;  // Do sprawdzania duplikatów dla label
  LabelName: string; // Pomocnicza do sprawdzania duplikatów i w pętlach dla label
  NextTrimmedLowerLine: string;
begin
    SetLength(FVariables, 0); // Czyści listę zmiennych
    FInRepeatBlock := False;
    PascalCode := TStringList.Create;
    UsesList := TStringList.Create; // Inicjalizacja listy uses
    LabelList := TStringList.Create;
    ExistingUnits := TStringList.Create; // Do śledzenia dodanych unitów
    ExistingLabes := TStringList.Create;  // Do śledzenia dodanych w label / etykietach
    // --- Skanowanie dla standardowego 'program' ---
    NameProgram := ''; // Resetuj zmienną globalną/pole
    DetectedProgramName := 'untitledprogram'; // Domyślna nazwa

    for i := 0 to AvocadoCode.Count - 1 do
    begin
      trimmedLine := Trim(AvocadoCode[i]);
      // Szukaj tylko standardowego 'program'
      if LowerCase(trimmedLine).StartsWith('program ') then
      begin
        NameProgram := Trim(Copy(trimmedLine, Length('program ') + 1, MaxInt));
        if NameProgram = '' then NameProgram := 'untitledprogram';
        DetectedProgramName := NameProgram;
        Break; // Znaleziono deklarację, przerwij skanowanie
      end;
    end;


    try
      AddCompilerDirective(PascalCode);
      (*
      PascalCode.Add('{$codepage utf8}');
      PascalCode.Add('{$mode objfpc}');
      PascalCode.Add('{$H+}');
      *)

      //Nazwa programu
      PascalCode.Add('program ' + DetectedProgramName + ';');

      // --- UPROSZCZONA SEKCJA 'uses' ---
      ModulesStr := GetImportedModules(AvocadoCode.Text);



      ModulPascalowy := GetImplementationModules(AvocadoCode.Text);

      // Podstawowe moduły + Classes + Windows (dla konsoli). LCL użytkownik musi dodać sam przez Importuj.
      UsesList.Add('SysUtils');
      UsesList.Add('Classes');
      UsesList.Add('Windows');
      UsesList.Add('StrUtils');
      UsesList.Add('Dialogs');

      //UsesList.Add('LazUTF8');
      //UsesList.Add('Utf8Process');

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
           else if LowerCase(FVariables[i].VarType) = 'lista_tekstów' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TStringList;') // Użyj zdefiniowanego typu
          else if LowerCase(FVariables[i].VarType) = 'stała' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Const;')
          else if LowerCase(FVariables[i].VarType) = 'qliczba' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': QWord;')

          //Tu drodzy panstwo beda zmienne po angielsku
          else if LowerCase(FVariables[i].VarType) = 'int' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Integer;')
          else if LowerCase(FVariables[i].VarType) = 'string_list' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TStringList;')
          else if LowerCase(FVariables[i].VarType) = 'comp' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': Comp;')
          else if LowerCase(FVariables[i].VarType) = 'byte_bool' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': ByteBool;')
          else if LowerCase(FVariables[i].VarType) = 'long_bool' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': LongBool;')
          else if LowerCase(FVariables[i].VarType) = 'wide_string' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': WideString;')
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
          else if LowerCase(FVariables[i].VarType) = 'informacje_o_wyszukaniu' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TSearchRec;')
          else if LowerCase(FVariables[i].VarType) = 'search_record' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': TSearchRec;')
          else if LowerCase(FVariables[i].VarType) = 'qword' then
            PascalCode.Add('  ' + FVariables[i].VarName + ': QWord;')
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

      //label etykieta
      LabelStr := GetLabels(AvocadoCode.Text);

      if LabelStr <> '' then
      begin
         for LabelName in LabelStr.Split([',']) do LabelList.Add(Trim(LabelName));
      end;

      PascalCode.Add('label');
      ExistingLabes.Clear;
      ExistingLabes.CaseSensitive := False;
      ExistingLabes.Sorted := True;


      for i := 0 to LabelList.Count - 1 do
      begin
         LabelName := Trim(LabelList[i]);
         if (LabelName <> '') and (ExistingLabes.IndexOf(LabelName) = -1) then
         begin
            if ExistingLabes.Count = 0 then
               PascalCode.Add('  ' + LabelName)
            else
               PascalCode.Strings[PascalCode.Count - 1] := PascalCode.Strings[PascalCode.Count - 1] + ', ' + LabelName;
               ExistingLabes.Add(LabelName);
         end;
      end;
        if ExistingLabes.Count > 0 then
         PascalCode.Strings[PascalCode.Count - 1] := PascalCode.Strings[PascalCode.Count - 1] + ';'
      else
         PascalCode.Delete(PascalCode.Count - 1); // Usuń pustą linię 'uses'
      PascalCode.Add('');
      //koniec sekcji label

      // główny blok programu
      PascalCode.Add('begin');
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
         (LowerCase(FVariables[i].VarType) = 'plik_tekstowy')
         then
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

        // --- NOWA LOGIKA: Pobierz następną linię ---
        if i + 1 < AvocadoCode.Count then
          NextTrimmedLowerLine := LowerCase(Trim(AvocadoCode[i+1]))
        else
          NextTrimmedLowerLine := ''; // Jesteśmy na końcu pliku
        // --- KONIEC NOWEJ LOGIKI ---

        // ... (logika pomijania linii - zostaje bez zmian) ...
        if AnsiStartsText('program ', trimmedLine) or
           // ... (cała reszta warunków) ...
           AnsiStartsText('ModułyPas', trimmedLine) then
        begin
          Continue;
        end
        else
        begin
          // Wywołanie nowej procedury z dodatkowym parametrem
          ProcessLine(trimmedLine, PascalCode, NextTrimmedLowerLine);
        end;


        // Pomiń linie 'program', 'importuj', 'ModułyPas'
        if AnsiStartsText('program ', trimmedLine) or
           AnsiStartsText('importuj', trimmedLine) or
           AnsiStartsText('import', trimmedLine) or
           AnsiStartsText('label', trimmedLine) or
           AnsiStartsText('etykieta', trimmedLine) or
           AnsiStartsText('plik ', LowerCase(trimmedLine)) or
           AnsiStartsText('file ', LowerCase(trimmedLine)) or
            AnsiStartsText('text_file ', LowerCase(trimmedLine)) or

           AnsiStartsText('plik_tekstowy ', LowerCase(trimmedLine)) or
           AnsiStartsText('informacje_o_wyszukaniu ', LowerCase(trimmedLine)) or
           AnsiStartsText('search_record ', LowerCase(trimmedLine)) or
           AnsiStartsText('ModułyPas', trimmedLine) then

        begin
          Continue;
        end
        else
        begin

        end;
      end;
      PascalCode.Add('  Readln;');
      PascalCode.Add('end.');
      Result := PascalCode;
    finally
      UsesList.Free;
      LabelList.Free;
      ExistingUnits.Free;
      ExistingLabes.Free
    end;
  end;

end.

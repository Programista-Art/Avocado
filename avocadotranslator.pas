unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, Math, SysUtils, StrUtils,fpexprpars,Crt,LazUTF8,Graphics,Variants,DefaultTranslator,LCLTranslator;

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
  InitialValue: string;
  end;

type
  TAvocadoModuleKind = (
    amkNone,
    amkProgramConsole,
    amkProgramGUI,
    amkUnit
);


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
    FLocalVariables: array of TAvocadoVariable;
    FInRepeatBlock: Boolean;
    // Słownik do tłumaczenia funkcji
    FFunctionMap: TStringList;
    FInProcedureBody: Boolean;
    FInMultiLineComment: Boolean;
    FreeCodeBuffer: TStringList;
    FLabels: array of TAvocadoLabel;

    // Tworzy procedury
    function TranslateProcedureHeader(const Line: string): string;
    //dotyczy petli while
    procedure ProcessWhileLoop(const Line: string; PascalCode: TStringList);
    procedure ProcessForLoop(const Line: string; PascalCode: TStringList);
    procedure ProcessForInLoop(const Line: string; PascalCode: TStringList);
    function TranslateExpression(const Expr: string): string;
    procedure ProcessDeclaration(const Line: string);

    {Najwazneisza funkcja transpilacji}
    procedure ProcessLine(const Line: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);

    {Skrocona funkcja aby zmniejszyc ilosc kodu w processline}
    function TryTranslateGeneric(const Line: string; PascalCode: TStringList; Aliases: array of string; RequiredArgs: Integer; PascalTemplate: string; SyntaxErrorMsg: string; ArgCountErrorMsg: String): Boolean;

    function PrzetworzBlok(const Blok: string): string;
    //Otrzymuje nazwy modulów i wstawia do sekcji Interface
    function GetImportedModules(const Code: string): string;
    //Otrzymuje nazwy modulów i wstawia do sekcji Implementation
    function GetImplementationModules(const Code: string): string;
    //Centralizacja Logiki Parsowania 10.10.2025
    function ExtractFunctionCall(const Line: string; var VarName: string; var Params: TStringArray): string;
    function SafeResolveAlias(const AName: string): string;
    //Lokalne zmienne w procedurach
    procedure AnalyzeLocalVariables(StartIndex: Integer; Source: TStrings);
    procedure AddLocalVariable(const VarName, VarType: string; NoAssign: Boolean = False; const AInitialValue: string = '');
    function TryParseDeclaration(const Line: string; out VarName, VarType, InitValue: string): Boolean;

    function GetWindowsCP(const DetectedName: string): string;

  public

    IsGUIProject: Boolean;
    destructor Destroy; override;
    constructor Create;
    //Ustawienia dyrektyw kompilatora
    procedure AddCompilerDirective(PascalCode: TStringList; IsGUI: Boolean);
        // Deklaracja funkcji tłumaczącej
    function TranslateFunctions(const CodeLine: string): string;
    function Translate(const AvocadoCode: TStrings): TStringList;
    function DetectCodePage(const Source: string): string;
    procedure InsertCodePageDirective(PascalCode: TStringList);
    function duze_litery_ansi(const S: string): string;
    function male_litery_ansi(const S: string): string;
   // function IsKnownType(const S: string): Boolean;
    procedure SplitStringByChar(const AString: string; const ASeparator: Char; AResultList: TStrings);
    function SplitArguments(const ASource: string; AStrings: TStrings): Boolean;
    //Dodaje zmienne
   procedure AddVariable(const VarName, VarType: string; NoAssign: Boolean = False; const AInitialValue: string = '');
    //Aliasy
    function ResolveAlias(const AName: string): string;
    procedure ProcessFileDeclaration(const Line: string);

    // Sprawdza, czy kod zawiera którąkolwiek z przekazanych nazw funkcji
    function ContainsFunction(const CodeLine: string; const Functions: array of string): Boolean;
    // Bezpiecznie dodaje moduł do sekcji uses, zapobiegając duplikatom
    procedure AddModule(var ModulesList: string; const ModuleName: string);
  end;

const
  //Conversions / Konwersje
  REPLACE_RULES: array of TReplaceRule = (
    //Polish aliases
   // (FromText: ' i '; ToText: ' and '; Flags: [rfReplaceAll]; IsPrefix: False),
   // (FromText: ' lub '; ToText: ' or '; Flags: [rfReplaceAll]; IsPrefix: False),
    //Dotyczy TFileStream
   (FromText: '[tylko_odczyt]'; ToText: 'fmOpenRead'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[tylko_zapis]'; ToText: 'fmOpenWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[odczyt_i_zapis]'; ToText: 'fmOpenReadWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[stwórz_nowy]'; ToText: 'fmCreate'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[stworz_nowy]'; ToText: 'fmCreate'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[wspolny]'; ToText: 'fmShareDenyNone'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[wspólny]'; ToText: 'fmShareDenyNone'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[blokuj_odczyt]'; ToText: 'fmShareDenyRead'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[blokuj_zapis]'; ToText: 'fmShareDenyWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[wyłączny]'; ToText: 'fmShareExclusive'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[wylaczny]'; ToText: 'fmShareExclusive'; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
   (FromText: '[open_read]'; ToText: 'fmOpenRead'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[open_write]'; ToText: 'fmOpenWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[open_read_write]'; ToText: 'fmOpenReadWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[create_new]'; ToText: 'fmCreate'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[common]'; ToText: 'fmShareDenyNone'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[block_read]'; ToText: 'fmShareDenyRead'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[block_write]'; ToText: 'fmShareDenyWrite'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: '[exclusive]'; ToText: 'fmShareExclusive'; Flags: [rfReplaceAll]; IsPrefix: False),
   (FromText: 'Int('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
     //
    (FromText: 'prawda'; ToText: 'True'; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'falsz'; ToText: 'False'; Flags: [rfReplaceAll]; IsPrefix: False),
    //(FromText: 'tekst_w_liczbe_cal('; ToText: 'StrToInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_zmiennoprzecinkową('; ToText: 'StrToFloat('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_zmiennoprzecinkowa('; ToText: 'StrToFloat('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_na_tekst('; ToText: 'IntToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zmiennoprzecinkowa_na_tekst('; ToText: 'FloatToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rzeczywista('; ToText: 'Real('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'obetnij('; ToText: 'Trunc('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'logiczny_na_tekst('; ToText: 'BoolToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'bajt_na_logiczny('; ToText: 'ByteBool(Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_liczbę_lub_domyślną('; ToText: 'StrToIntDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_liczbe_lub_domyslna('; ToText: 'StrToIntDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zaokrąglij('; ToText: 'Round('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zaokraglij('; ToText: 'Round('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'na_całkowitą_16('; ToText: 'Word('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'na_calkowita_16('; ToText: 'Word('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_32('; ToText: 'LongInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_calkowita_32('; ToText: 'LongInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczebnik('; ToText: 'Cardinal('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'zmiennoprzecinkowa_na_tekst_formatowany('; ToText: 'FloatToStrF('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'podwójna_precyzja('; ToText: 'Double('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'podwojna_precyzja('; ToText: 'Double('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_rozszerzona_na_pojedyńczą('; ToText: 'Extended('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_rozszerzona_na_pojedyncza('; ToText: 'Extended('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'Liczba_pojedyncza_na_zm('; ToText: 'Single('; Flags: [rfReplaceAll]; IsPrefix: False),


    // character and string conversions / konwersje znaków i string
    //Polish aliases
    (FromText: 'liczba_na_znak('; ToText: 'Chr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'znak_na_liczbę('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'znak_na_liczbe('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'znak_na_tekst('; ToText: 'Char('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_znak('; ToText: 'String('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases

    (FromText: 'chr('; ToText: 'Chr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'ord('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'char('; ToText: 'Char('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'string('; ToText: 'String('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'repeat_char('; ToText: 'StringOfChar('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_bool_def('; ToText: 'StrToBoolDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_bool('; ToText: 'StrToBool('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'bool('; ToText: 'Boolean('; Flags: [rfReplaceAll]; IsPrefix: False),
    // logical conversions / konwersje logiczne
    //Polish aliases
    (FromText: 'tekst_na_logiczny('; ToText: 'StrToBool('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_logiczny_dom('; ToText: 'StrToBoolDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'logiczny_z_liczby('; ToText: 'Boolean('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_z_logicznego('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_calkowita_z_logicznego('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_całkowita_z_wyliczenia('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'liczba_calkowita_z_wyliczenia('; ToText: 'Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_nazwę_tekstu('; ToText: 'GetEnumName('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_wartość_wyliczenia('; ToText: 'GetEnumValue('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_nazwe_tekstu('; ToText: 'GetEnumName('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'pobierz_wartosc_wyliczenia('; ToText: 'GetEnumValue('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases



    (FromText: 'get_enum_name('; ToText: 'GetEnumName('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'get_enum_value('; ToText: 'GetEnumValue('; Flags: [rfReplaceAll]; IsPrefix: False),
    // date and time / data i czas
    //Polish aliases


    (FromText: 'formatuj_data_czas_na_tekst('; ToText: 'FormatDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'data_czas_na_tekst('; ToText: 'DateTimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_czas('; ToText: 'StrToDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_date_czas('; ToText: 'StrToDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_dom('; ToText: 'StrToDateDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_date_dom('; ToText: 'StrToDateDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_czas_dom('; ToText: 'StrToTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę_czas_dom('; ToText: 'StrToDateTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_date_czas_dom('; ToText: 'StrToDateTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utwórz_datę('; ToText: 'EncodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utworz_date('; ToText: 'EncodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utwórz_czas('; ToText: 'EncodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'utworz_czas('; ToText: 'EncodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozłóż_datę('; ToText: 'DecodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozloz_date('; ToText: 'DecodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozłóż_czas('; ToText: 'DecodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'rozloz_czas('; ToText: 'DecodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_liczbę('; ToText: 'StrToInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_liczbe('; ToText: 'StrToInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_datę('; ToText: 'StrToDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_date('; ToText: 'StrToDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'tekst_na_czas('; ToText: 'StrToTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'data_na_tekst('; ToText: 'DateToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'czas_na_tekst('; ToText: 'TimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    // English aliases
    (FromText: 'format_date_time('; ToText: 'FormatDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'date_time_str('; ToText: 'DateTimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_datetime_def('; ToText: 'StrToDateTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_to_time('; ToText: 'StrToTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date_time('; ToText: 'StrToDateTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date_def('; ToText: 'StrToDateDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_time_def('; ToText: 'StrToTimeDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'encode_date('; ToText: 'EncodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'encode_time('; ToText: 'EncodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'decode_date('; ToText: 'DecodeDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'decode_time('; ToText: 'DecodeTime('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'date_str('; ToText: 'DateToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'time_str('; ToText: 'TimeToStr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_date('; ToText: 'StrToDate('; Flags: [rfReplaceAll]; IsPrefix: False),
    // indicators
    //Polish aliases
    (FromText: 'adres_zmiennej('; ToText: 'Ptr('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'adres_zmiennej_z_wskażnika('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'adres_zmiennej_z_wskaznika('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: '@('; ToText: '@('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'klawisz_wciśnięty'; ToText: 'KeyPressed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'klawisz_wcisniety'; ToText: 'KeyPressed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'int_ptr('; ToText: 'Integer('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'ptr('; ToText: 'Ptr('; Flags: [rfReplaceAll]; IsPrefix: False),

    (FromText: '@('; ToText: '@('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'key_pressed'; ToText: 'KeyPressed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),

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
    (FromText: 'byte_bool_Ord('; ToText: 'ByteBool(Ord('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'str_int_def('; ToText: 'StrToIntDef('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'round('; ToText: 'Round('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'word('; ToText: 'Word('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'long_int('; ToText: 'LongInt('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'cardinal('; ToText: 'Cardinal('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'float_strf('; ToText: 'FloatToStrF('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'double('; ToText: 'Double('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'extended('; ToText: 'Extended('; Flags: [rfReplaceAll]; IsPrefix: False),
    (FromText: 'single('; ToText: 'Single('; Flags: [rfReplaceAll]; IsPrefix: False),
    // colors
    //Polish aliases
    (FromText: '*czarny'; ToText: 'Black'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*biały'; ToText: 'White'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*bialy'; ToText: 'White'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*niebieski'; ToText: 'Blue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*zielony'; ToText: 'Green'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*czerwony'; ToText: 'Red'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*żółty'; ToText: 'Yellow'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*zolty'; ToText: 'Yellow'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*cyjan'; ToText: 'Cyan'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*magenta'; ToText: 'Magenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*brązowy'; ToText: 'Brown'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*brazowy'; ToText: 'Brown'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnoszary'; ToText: 'LightGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*ciemnoszary'; ToText: 'DarkGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnoniebieski'; ToText: 'LightBlue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnozielony'; ToText: 'LightGreen'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnoczerwony'; ToText: 'LightRed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnoróżowy'; ToText: 'LightMagenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*jasnorozowy'; ToText: 'LightMagenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*migotanie'; ToText: 'Blink'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: '*black'; ToText: 'Black'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*white'; ToText: 'White'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*blue'; ToText: 'Blue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*green'; ToText: 'Green'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*red'; ToText: 'Red'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*yellow'; ToText: 'Yellow'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*cyan'; ToText: 'Cyan'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    //(FromText: 'magenta'; ToText: 'Magenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*brown'; ToText: 'Brown'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*light_gray'; ToText: 'LightGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*dark_gray'; ToText: 'DarkGray'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*light_blue'; ToText: 'LightBlue'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*light_green'; ToText: 'LightGreen'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*light_red'; ToText: 'LightRed'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*light_magenta'; ToText: 'LightMagenta'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '*blink'; ToText: 'Blink'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),


    // funkcje string
    //Polish aliases
    (FromText: 'porównaj_tekst('; ToText: 'CompareStr('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'porownaj_tekst('; ToText: 'CompareStr('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'długość('; ToText: 'Length('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'dlugosc('; ToText: 'Length('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'usuń('; ToText: 'Delete('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'usun('; ToText: 'Delete('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'powtórz_znak('; ToText: 'StringOfChar('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'powtorz_znak('; ToText: 'StringOfChar('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),

    (FromText: 'kopiuj'; ToText: 'Copy'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'wstaw'; ToText: 'Insert'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'szukaj'; ToText: 'Pos'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),

    // English aliases
    (FromText: 'compare_text('; ToText: 'CompareStr('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'length('; ToText: 'Length('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'delete('; ToText: 'Delete('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'repeat_char('; ToText: 'StringOfChar('; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'copy'; ToText: 'Copy'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'insert'; ToText: 'Insert'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'pos'; ToText: 'Pos'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // nil i free
    //Polish aliases
    (FromText: '_n_'; ToText: 'nil'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '.tekst'; ToText: '.Text'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'zwolnij'; ToText: 'free'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'zwiększ'; ToText: 'inc'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'zwieksz'; ToText: 'inc'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'nil'; ToText: 'nil'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: '.text'; ToText: '.Text'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'free'; ToText: 'free'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),

    // prefix aliases / aliasy prefiksowe
    //Polish aliases
    (FromText: 'czy_istnieje_plik'; ToText: 'FileExists'; Flags: []; IsPrefix: True),
    (FromText: 'czy_istnieje_katalog'; ToText: 'DirectoryExists'; Flags: []; IsPrefix: True),
    (FromText: 'pobierz_zmienną_środowiskową'; ToText: 'SysUtils.GetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'pobierz_zmienna_srodowiskowa'; ToText: 'SysUtils.GetEnvironmentVariable'; Flags: []; IsPrefix: True),


    (FromText: 'ustaw_zmienną_środowiskową'; ToText: 'SysUtils.SetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'ustaw_zmienna_srodowiskowa'; ToText: 'SysUtils.SetEnvironmentVariable'; Flags: []; IsPrefix: True),
    (FromText: 'pobierz_katalog_bieżący'; ToText: 'GetCurrentDir'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    (FromText: 'pobierz_katalog_biezacy'; ToText: 'GetCurrentDir'; Flags: [rfReplaceAll, rfIgnoreCase]; IsPrefix: False),
    // English aliases
    (FromText: 'file_exists'; ToText: 'FileExists'; Flags: []; IsPrefix: True),
    (FromText: 'directory_exists'; ToText: 'DirectoryExists'; Flags: []; IsPrefix: True),
    (FromText: 'get_env'; ToText: 'SysUtils.GetEnvironmentVariable'; Flags: []; IsPrefix: True),
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
NameProgram: String;

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
  TranslateErrFoundRepeatInsideAnotherRepeat = 'Error: Found "repeat" inside another "repeat"';
  TranslateAzorUntil = 'Error: "aż / az" or "until" found without a matching "repeat"';
  TranslateErrMissingConditionAfteuntil = 'Error: Missing condition after "aż / az" / "until"';
  TranslateNoBracketsTrimFunction = 'No brackets in the trim function.';
  TranslateIncorrectOrderBracketsTrim = 'Incorrect order of brackets in trim().';
  TranslateNobracketsTrimleftfunction = 'No brackets in the trim_left function.';
  IncorrectOrderBracketsTrimLeft = 'Incorrect order of brackets in trim_left().';
  TranslateNoBracketsTrimRightFunction = 'No brackets in the trim_right function.';
  TranslateIncorrectOrderBracketsTrimRight = 'Incorrect order of brackets in trim_right() / trim_right';
  TranslateIncorrectSyntaxRemovefunction = 'Incorrect syntax of the remove/delete function. Expected: remove(s, index, count)';
  TranslateDeleteFunctionRequires = 'The delete function requires three arguments: s, index, count.';
  TranslateIncorrectSyntaxUppercaseFunction = 'Incorrect syntax of the uppercase function. Expected: duże_litery(s) or duze_litery(s) or upper_case(s)';
  TranslateIncorrectSyntaxLowercaseFunction = 'Incorrect syntax of the lowercase function. Expected: małe_litery(s) / male_litery(s) / lower_case(s)';
  TranslateLowercaseFunctionSyntaxError = 'Incorrect syntax of the lowercase function. Expected: małe_litery(s) / male_litery(s) / lower_case(s)';
  TranslateIncorrectSyntaxRepeatCharacterFunction = 'Incorrect syntax of the repeat_character function.';
  TranslateClosingBracketBeforeOpening = 'Incorrect syntax: closing bracket before opening bracket';
  TranslateRepeatCharacterFunctionRequiresTwoArguments ='The repeat_char function requires two arguments.';
  TranslateIncorrectSyntaxCompareTextFunction = 'Incorrect syntax of the compare_text function. Expected: compare_text(s1, s2)';
  TranslateCompareTextFunctionRequiresTwoArguments = 'The compare_text function requires two arguments: s1 and s2.';
  TranslateIncorrectSyntaxReplaceTextFunction = 'Incorrect syntax for replace_text. Expected: replace_text(text, from, to';
  TranslateReplaceTextFunctionRequiresThreeArguments = 'The replace_text function requires three arguments: text, from, to.';
  TranslateIncorrectSyntaxUtf8UppercaseAnsiFunction = 'Incorrect syntax of the utf8_upper_case function.';
  TranslateIncorrectSyntaxUtf8LowerCaseFunction = 'Incorrect syntax of the utf8_lower_case function.';
  TranslateIncorrectSyntaxAssignFileFunction = 'Incorrect syntax assign_file(file_variable, file_name)';
  TranslateIncorrectSyntaxAssignFileFunctionExpected = 'Incorrect syntax of the assign_file function. Expected: assign_file(file_variable, file_name)';
  TranslateAssignFileFunctionIncorrectNumberOfArguments = 'Incorrect number of arguments for the assign_file function. Two arguments were expected.';
  TranslateAssignFileFunctionArgumentsCannotBeEmpty = 'The arguments of the assign_file function cannot be empty.';
  TranslateIncorrectSyntaxLoadFileFunction = 'Incorrect syntax load_file(f)';
  TranslateIncorrectSyntaxOpenSaveFunction = 'Incorrect syntax open_save(f)';
  TranslateIncorrectSyntaxAppendFunction = 'Incorrect syntax append(f)';
  TranslateIncorrectSyntaxCloseFileFunction = 'Incorrect syntax close_file(f)';
  TranslateIncorrectSyntaxEofFunction = 'Incorrect syntax eof(f)';
  TranslateIncorrectSyntaxFileExistsFunction = 'Incorrect syntax of file_exists(...)';
  TranslateIncorrectSyntaxChangeDirFunction = 'Incorrect syntax change_dir(...)';
  TranslateIncorrectSyntaxCreateDirFunction = 'Incorrect syntax create_dir(...)';
  TranslateIncorrectSyntaxRemoveDirFunction = 'Incorrect syntax remove_dir(...)';
  TranslateIncorrectSyntaxGetCurrentDirFunction = 'Incorrect syntax get_current_dir(...)';
  TranslateIncorrectSyntaxDirectoryExistsFunction = 'Incorrect syntax directory_exists(...)';
  TranslateIncorrectSyntaxLengthFunction = 'Incorrect syntax length. Expected: length(text)';
  TranslateIncorrectSyntaxCopyFunction = 'Incorrect syntax for copy. Expected: copy(text, start, how many)';
  TranslateCopyFunctionRequiresThreeArguments = 'The copy function requires three arguments: text, start, how many';
  TranslateIncorrectSyntaxSearchFunction = 'Incorrect syntax for search. Expected: search(substring, text)';
  TranslateSearchFunctionRequiresTwoArguments = 'The search function requires two arguments: substring, text';
  TranslateMissingBracketsCursorPositionFunction = 'Syntax error: Missing brackets in the cursor_position function.';
  TranslateCursorPositionFunctionRequiresTwoArguments = 'The cursor_position function requires exactly 2 arguments (X, Y). Found:';
  TranslateMissingClosingBracketReadKeyFunction = 'Syntax error: Missing closing bracket in the read_key function.';
  TranslateIncorrectOrderOfBrackets = 'Syntax error: Incorrect order of brackets.';
  TranslateAssignmentExpectedReadKey = 'Syntax error: Assignment expected (variable = read_key).';
  TranslateIncompleteAssignment = 'Syntax error: Incomplete assignment.';
  TranslateParenthesesErrorReadKeyFunction = 'Syntax error in parentheses in read_key.';
  TranslateMissingBracketsPiszLinieFunction = 'Syntax error: The pisz_linie function requires brackets, e.g. pisz_linie(''text'')';
  TranslateClosingBracketBeforeOpeningBracket = 'Syntax error: The closing bracket appears before the opening bracket.';
  TranslateErrorProcessingArgumentsWriteLines = 'Error processing arguments for write_lines: ';
  TranslateMissingBracketsWritePrintFunction = 'Syntax error: The write/print function requires brackets, e.g. write(''text'')';
  TranslateErrorProcessingArgumentsWriteFunction = 'Error while processing function arguments write: ';
  TranslateMissingParenthesesRandomFunction = 'Syntax error: The random function requires parentheses, e.g. random(100) or random().';
  TranslateRandomiseFunctionDoesNotAcceptBrackets = 'Syntax error: The ‘randomise’ function does not accept brackets or arguments. Use just the word ‘randomise’.';
  TranslateMissingBracketsGetArgumentFunction = 'Syntax error: The get_argument function requires brackets, e.g. programme_parameter(1)';
  TranslateGetArgumentFunctionRequiresIndex = 'Error: The get_argument function requires an index (number) to be specified.';
  TranslateErrorProcessingGetArgumentFunction = 'Error while processing the get_argument function: ';
  TranslateMissingParenthesesGetEnvironmentVariableFunction = 'Syntax error: The function requires parentheses, e.g. get_environment_variable(''PATH'')';
  TranslateGetEnvironmentVariableRequiresName = 'Error: The function requires an environment variable name to be specified.';
  TranslateErrorProcessingGetEnvironmentVariableFunction = 'Error while processing the get_environment_variable function: ';
  TranslateMissingParenthesesCalculateFunction = 'Syntax error: The calculate/calc function requires parentheses, e.g. calculate(2 + 2)';
  TranslateCalculateFunctionRequiresExpression = 'Error: The calculate/calc function must contain a mathematical expression, e.g. calculate(2 * 5).';
  TranslateErrorProcessingCalculateFunction = 'Error during processing of the calculate function: ';
  TranslateMissingParenthesesCalculateFormatFunction = 'Syntax error: The function requires parentheses, e.g. calculate_format("''2+2"'', 2)';
  TranslateCalcFormatFunctionRequiresOneOrTwoArguments = 'Error: The calc_format function requires 1 or 2 arguments.';
  TranslateSyntaxErrorReadFunctionAssignment = 'Syntax error in the assignment in the read function.';
  TranslateMissingBracketsReadFunction = 'Syntax error: The read function requires brackets.';
  TranslateReadFunctionRequiresVariableName = 'Error: The read function requires a variable name to be specified.';
  TranslateErrorProcessingReadFunction = 'Error during processing of the read function: ';
  TranslateSetLengthRequiresParentheses = 'Syntax error: The set_length function requires parentheses, e.g., set_length(Array, 10).';
  TranslateSetLengthRequiresTwoArguments ='Error: The set_length function requires EXACTLY TWO arguments (variable, new length).';
  TranslateFirstArgumentCannotBeEmpty = 'Error: The first argument (variable name) cannot be empty.';
  TranslateErrorProcessingSetLengthFunction = 'Error while processing the set_length function: ';
  TranslateSyntaxErrorAssignmentReadLine = 'Syntax error in assignment in read_line.';
  TranslateReadLinesRequiresParentheses = 'Syntax error: The read_lines function requires parentheses.';
  TranslateReadLinesParenthesesRequired = 'Syntax error: The read_lines function requires parentheses.';
  TranslateErrorProcessingReadLinesFunction = 'Error while processing the read_lines function: ';
  TranslatePingCommandRequiresUrlOrVariable = 'Syntax error: The PING command requires a URL or variable, e.g. ping "google.com"';
  TranslateErrorProcessingPingCommand = 'Error while processing the PING command: ';
  TranslatePingFunctionRequiresBrackets = 'Syntax error: The PING function requires brackets, e.g. ping(''google.com'', ''OK!'').';
  TranslatePingFunctionRequiresTwoArguments = 'Error: The PING function requires EXACTLY TWO arguments (address, success message).';
  TranslateErrorProcessingPingFunction = 'Error while processing the PING function: ';
  TranslateUnknownAliasType = 'Unknown alias type: ';
  TranslateIncorrectBracketsInFunction = 'Error: incorrect brackets in the function.';
  TranslateDownloadFileFunctionRequiresTwoArguments = 'Error: The download_file function requires EXACTLY TWO arguments (URL, Save Path).';
  TranslateErrorProcessingGetFileFunction = 'Error while processing the GET_FILE function: ';
  TranslatePobierzStroneRequiresParentheses = 'Syntax error: The pobierz_strone function requires parentheses, e.g., pobierz_strone(''url'', ResultVariable).';
  TranslatePobierzStroneRequiresTwoArguments = 'Error: The pobierz_strone function requires EXACTLY TWO arguments (URL, Result variable).';
  TranslateAliasTypeIsUnknown = 'Unknown alias type: " ';
  TranslateReplacedVariant = '". Replaced "Variant".';
  TranslateTextsStringsRequiresParentheses = 'SYNTAX ERROR: The function texts / strings requires parentheses.';
  TranslateTextsStringsRequiresTwoArguments = 'ARGUMENT ERROR: The function texts / strings requires 2 arguments. The following was given: ';
  TranslateInsertToListRequiresParentheses = 'SYNTAX ERROR: The insert_to_list function requires parentheses.';
  TranslateInsertToListRequiresThreeArguments = 'ARGUMENT ERROR: The insert_to_list function requires 3 arguments (list, index, value). The following was given: ';
  TranslateRemoveFromListRequiresParentheses = 'SYNTAX ERROR: The remove_from_list function requires parentheses.';
  TranslateDeleteFromToListRequiresListAndIndex = 'ARGUMENT ERROR: The delete_from_list / delete_to_list function requires a list name and an index.';
  TranslateDeleteFromToListIdRequiresParentheses = 'SYNTAX ERROR: The function delete_from_list_id / delete_to_list_id requires parentheses.';
  TranslateProvideListNameAndValueToRemove = 'ARGUMENT ERROR: Provide a list name and a value to remove.';
  TranslateClearListRequiresParentheses = 'SYNTAX ERROR: The clear list function must have parentheses, e.g. clear list(s)';
  TranslateClearListRequiresOneArgument = 'ARGUMENT ERROR: The clearlist function accepts exactly 1 list name.';
  TranslateSetTextRequiresParentheses = 'SYNTAX ERROR: The set_text / set_text function requires parentheses.';
  TranslateSetTextRequiresThreeArguments = 'ARGUMENT ERROR: The set_text / set_text function requires 3 arguments (list, index, "newvalue").';
  TranslateFFunctionMapNotInitialized = 'The FFunctionMap dictionary has not been initialized!';
implementation

uses
  unit1;

{ TAvocadoTranslator }

function TAvocadoTranslator.DetectCodePage(const Source: string): string;
var
i: Integer;
b: Byte;
ScorePL, ScoreCZ, ScoreHU, ScoreDE, ScoreCYR, ScoreTR, ScoreAR, ScoreUTF8: Integer;
Utf8Sequence: Integer;
begin
  ScorePL := 0;
  ScoreCZ := 0;
  ScoreHU := 0;
  ScoreDE := 0;
  ScoreCYR := 0;
  ScoreTR := 0;
  ScoreAR := 0;
  ScoreUTF8 := 0;
  Utf8Sequence := 0;

  // 1. Najpierw analiza UTF-8 (sprawdzamy poprawność sekwencji bajtów)
  for i := 1 to Length(Source) do
  begin
    b := Ord(Source[i]);
    if Utf8Sequence > 0 then
    begin
      if (b and $C0) = $80 then // Bajt kontynuacji (10xxxxxx)
      begin
        Dec(Utf8Sequence);
        if Utf8Sequence = 0 then Inc(ScoreUTF8); // Pełna sekwencja znaleziona
      end
      else Utf8Sequence := 0; // Błąd sekwencji
    end
    else
    begin
      if (b and $E0) = $C0 then Utf8Sequence := 1      // 2 bajty
      else if (b and $F0) = $E0 then Utf8Sequence := 2 // 3 bajty
      else if (b and $F8) = $F0 then Utf8Sequence := 3;// 4 bajty
    end;
  end;

  // Jeśli znaleźliśmy dużo poprawnych sekwencji UTF-8 i nie było błędów, to UTF-8
  if (ScoreUTF8 > 0) and (Utf8Sequence = 0) then Exit('utf8');


  // 2. Analiza statystyczna dla stron kodowych 8-bitowych (Heurystyka)
  for i := 1 to Length(Source) do
  begin
    b := Ord(Source[i]);

    // Ignorujemy ASCII (< 128), interesują nas tylko "ogonki"
    if b < 128 then Continue;

    // CP1250 (Polska) - Szukamy znaków, które są literami w PL,
    // a rzadkimi symbolami w CP1252 (np. Ą to ¥ w 1252)
    // $A5(Ą), $B9(ą), $8C(Ś), $9C(ś), $8F(Ź), $9F(ź), $AF(Ż), $BF(ż)
    if b in [$A5, $B9, $8C, $9C, $8F, $9F, $AF, $BF] then Inc(ScorePL, 5);
    // $E6(ć), $EA(ę), $B3(ł) - te też punktujemy
    if b in [$E6, $EA, $B3] then Inc(ScorePL, 1);

    // CP1250 (Czechy/Słowacja) - charakterystyczne: Š, š, Ž, ž
    if b in [$8A, $9A, $8E, $9E] then Inc(ScoreCZ, 5);

    // CP1250 (Węgry) - Ő, ő, Ű, ű
    if b in [$8A, $8B, $FB, $D5, $DB] then Inc(ScoreHU, 5);

    // CP1252 (Niemiecki/Zachodni)
    // Szukamy znaków, które w CP1250 są "śmieciami" lub rzadkie
    // $C4(Ä), $D6(Ö), $DC(Ü), $DF(ß)
    // Uwaga: $DF w CP1250 to też ß, ale $F6(ö) w CP1250 to znak dzielenia (÷)
    if b in [$C4, $D6, $DC, $DF] then Inc(ScoreDE, 2);
    if b = $F6 then Inc(ScoreDE, 5); // ö (bardzo częste w DE, w PL to znak dzielenia)

    // CP1251 (Cyrylica)
    // Rosyjski tekst jest gęsty w zakresie $C0-$FF.
    if (b >= $C0) and (b <= $FF) then Inc(ScoreCYR, 1);
    // Specyficzne znaki rzadko używane w łacińskich CP
    if b in [$A8, $B8] then Inc(ScoreCYR, 10); // Ё, ё

    // CP1254 (Turecki) - Ğ, Ş
    if b in [$D0, $DD, $DE, $F0, $FD, $FE] then Inc(ScoreTR, 5);

    // CP1256 (Arabski)
    // Znaki arabskie są mapowane na wysokie bajty, ale trudno je odróżnić od cyrylicy
    // bez analizy słownikowej. Dajemy punkty za specyficzne znaki łączące.
    if b in [$81, $8D, $8E, $90, $98] then Inc(ScoreAR, 3);
  end;

  // 3. Wybieramy zwycięzcę
  Result := 'cp1252'; // Domyślnie

  // Prosta drabinka - kto ma najwięcej punktów
  if (ScoreCYR > ScorePL) and (ScoreCYR > ScoreDE) and (ScoreCYR > ScoreTR) then Exit('cp1251');
  if (ScorePL > ScoreDE) and (ScorePL > ScoreCZ) and (ScorePL > ScoreHU) then Exit('cp1250');
  if (ScoreCZ > ScorePL) and (ScoreCZ > ScoreHU) then Exit('cp1250'); // CZ też używa 1250
  if (ScoreHU > ScorePL) then Exit('cp1250'); // HU też używa 1250
  if (ScoreTR > ScoreDE) and (ScoreTR > ScorePL) then Exit('cp1254');
  if (ScoreAR > ScoreCYR) and (ScoreAR > ScorePL) then Exit('cp1256');
  if ScoreDE >= ScorePL then Result := 'cp1252';
end;

procedure TAvocadoTranslator.InsertCodePageDirective(PascalCode: TStringList);
var
  CP: string;
  WholeText: string;
  i: Integer;
begin
    for i := 0 to Min(10, PascalCode.Count - 1) do
    begin
      if Pos('{$codepage', LowerCase(PascalCode[i])) > 0 then Exit;
      if Pos('{$mode', LowerCase(PascalCode[i])) > 0 then
      begin
         Break;
      end;
    end;

    WholeText := PascalCode.Text;
    CP := DetectCodePage(WholeText);

    PascalCode.Insert(0, '{$codepage ' + CP + '}');
end;


function TAvocadoTranslator.TranslateProcedureHeader(const Line: string): string;
var
TrimmedLine, LowerLine, Header: string;
ProcName, ParamStr, FinalParams, ReturnTypeDecl: string;
ParenStart, ParenEnd, KeywordLen, ColonPos: Integer;
Param, TypeName, VarName: string;
ParamsList: TStringList;
i: Integer;
IsFunc: Boolean;
begin
  TrimmedLine := Trim(Line);
  LowerLine := AnsiLowerCase(TrimmedLine);
  IsFunc := False;

  if LowerLine.StartsWith('procedura ') then
    KeywordLen := Length('procedura')
  else if LowerLine.StartsWith('procedure ') then
    KeywordLen := Length('procedure')
  else if LowerLine.StartsWith('funkcja ') then
    begin
      KeywordLen := Length('funkcja');
      IsFunc := True;
    end
    else if LowerLine.StartsWith('function ') then
    begin
      KeywordLen := Length('function');
      IsFunc := True;
    end
    else
    begin
      Exit;
    end;

 // Wytnij cały nagłówek (np. "przywitajsie(imie: tekst)")
  Header := Trim(Copy(TrimmedLine, KeywordLen + 1, MaxInt));
  if Header.EndsWith(';') then
    Delete(Header, Length(Header), 1);

  // Obsługa typu zwracanego dla funkcji (po ostatnim dwukropku lub nawiasie)
  ReturnTypeDecl := '';
  ParenEnd := RPos(')', Header);

  if IsFunc then
  begin
    // Sprawdź czy jest dwukropek po nawiasach zamykających
    // np. funkcja Suma(a: lc): lc
    if ParenEnd > 0 then
    begin
       // Szukamy dwukropka PO nawiasach
       ColonPos := Pos(':', Copy(Header, ParenEnd + 1, MaxInt));
       if ColonPos > 0 then
       begin
         // Skoryguj pozycję względem całego stringa
         ColonPos := ParenEnd + ColonPos;
         // Pobierz typ zwracany
         ReturnTypeDecl := Trim(Copy(Header, ColonPos + 1, MaxInt));
         ReturnTypeDecl := ResolveAlias(ReturnTypeDecl); // Tłumacz typ (np. lc -> Integer)

         // Utnij Header tak, by zawierał tylko "Nazwa(args)"
         Header := Trim(Copy(Header, 1, ColonPos - 1));
       end;
    end;
  end;

  ParenStart := Pos('(', Header);
  ParenEnd := RPos(')', Header);

  // Sprawdź, czy ma parametry
  if (ParenStart = 0) or (ParenEnd <= ParenStart) then
  begin
    // Brak parametrów
    if IsFunc then
      Result := 'function ' + Header + ': ' + ReturnTypeDecl + ';'
    else
      Result := 'procedure ' + Header + ';';
    Exit;
  end;

  // Podziel na nazwę i parametry.
  ProcName := Trim(Copy(Header, 1, ParenStart - 1));
  ParamStr := Trim(Copy(Header, ParenStart + 1, ParenEnd - ParenStart - 1));

  FinalParams := '';
  ParamsList := TStringList.Create;
  try
    // Dzielimy parametry po średniku, np. "imie: tekst; wiek: lc"
    SplitStringByChar(ParamStr, ';', ParamsList);

    for i := 0 to ParamsList.Count - 1 do
    begin
      Param := Trim(ParamsList[i]);
      if Pos(':', Param) = 0 then Continue; // Błędny format, pomiń

      // Podziel "imie: tekst" na "imie" i "tekst"
      VarName := Trim(Copy(Param, 1, Pos(':', Param) - 1));
      TypeName := Trim(Copy(Param, Pos(':', Param) + 1, MaxInt));
      TypeName := ResolveAlias(TypeName);


      if FinalParams = '' then
        FinalParams := VarName + ': ' + TypeName
      else
        FinalParams := FinalParams + '; ' + VarName + ': ' + TypeName;
    end;
  finally
    ParamsList.Free;
  end;

  if IsFunc then
      Result := 'function ' + ProcName + '(' + FinalParams + '): ' + ReturnTypeDecl + ';'
  else
      Result := 'procedure ' + ProcName + '(' + FinalParams + ');';
end;


procedure TAvocadoTranslator.AddVariable(const VarName, VarType: string; NoAssign: Boolean = False; const AInitialValue: string = '');
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
    FVariables[High(FVariables)].InitialValue := AInitialValue;
end;


//Dozlwolone zmienne
function TAvocadoTranslator.ResolveAlias(const AName: string): string;
begin
  case LowerCase(AName) of
   // Liczby całkowite
    'liczba_całkowita','liczba_calkowita', 'lc', 'int', 'integer':
      Exit('Integer');

    'liczba_krótka','liczba_krotka','int8', 'shortint':
      Exit('ShortInt');

    'liczba_mała','liczba_mala', 'int16', 'smallint':
      Exit('SmallInt');

    'liczba_długa', 'liczba_dluga', 'int32', 'longint':
      Exit('LongInt');

    'bajt', 'byte':
      Exit('Byte');

    'liczba16', 'word', 'uint16':
      Exit('Word');

    'liczba32', 'longword', 'uint32':
      Exit('LongWord');

    'liczba64', 'int64':
      Exit('int64');

    'qliczba', 'qword':
      Exit('QWord');

    // Liczby zmiennoprzecinkowe
    'liczba_pojedyncza', 'single':
      Exit('Single');

    'liczba_zm', 'lzm', 'real':
      Exit('Real');

    'liczba_podwójna','liczba_podwojna', 'double', 'float':
      Exit('Double');

    'liczba_rozszerzona', 'extended', 'float80':
      Exit('Extended');

    'liczba_waluta', 'currency':
      Exit('Currency');

    'liczba_zgodna_delphi', 'comp':
      Exit('Comp');

    // Logiczne
    'logiczny', 'bool', 'boolean':
      Exit('Boolean');

    'logiczny_bajt', 'byte_bool':
      Exit('ByteBool');

    'logiczne_słowo','logiczne_slowo', 'word_bool':
      Exit('WordBool');

    'logiczny_długi', 'logiczny_dlugi', 'long_bool':
      Exit('LongBool');

    // Teksty
    'tekst', 'string':
      Exit('String');

    'tekst_ansi', 'ansi_string':
      Exit('AnsiString');

    'tekst_unicode', 'unicode_string':
      Exit('UnicodeString');

    'tekst_systemowy', 'wide_string':
      Exit('WideString');

    'tekst255', 'shortstring', 'string255':
      Exit('ShortString');

    // Znaki
    'znak', 'char':
      Exit('Char');

    'znak_unicode', 'widechar', 'char32':
      Exit('WideChar');

    // Pliki
    'plik', 'file':
      Exit('File');

    'plik_tekstowy', 'textfile','text_file':
      Exit('TextFile');

    'plik_binarny', 'binaryfile','binary_file':
      Exit('BinaryFile');

    'plik_struktur', 'typedfile', 'file_struct':
      Exit('TypedFile');

    // Wskaźniki
    'wskaźnik','wskaznik', 'pointer':
      Exit('Pointer');

    'wskaźnik_na','wskaznik_na','^type', 'pointer_to':
      Exit('^Type');

    // Struktury
    'informacje_o_wyszukaniu', 'search_record':
      Exit('TSearchRec');

    'lista_tekstów', 'lista_tekstow', 'string_list':
      Exit('TStringList');

    'strumień_pliku', 'strumien_pliku', 'file_stream':
      Exit('TFileStream');

    'dslowo', 'dsłowo', 'dword':
      Exit('DWord');

     //UI windows

     //uchwyt
    'uchwyt_okna', 'hwnd':
      Exit('HWND');
    'uchwyt_plotna', 'hdc':
      Exit('HDC');
    //rekord
    'parametry_ui', 'ui_parameters':
      Exit('TAvocadoWindowParams');
    //Wiadomosc Msg
    'dialog_komunikatu', 'msg':
      Exit('TMsg');

    // Inne
    'wariant', 'variant':
      Exit('Variant');

    'avoraiser_event','avoraiser_zdarzenie' :
      Exit('TAvocadoEvent');

    'wariant_ole', 'olevariant', 'ole_variant':
      Exit('OleVariant');
  else
    raise Exception.Create(TranslateUnknownAliasType + AName);
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
    if LowerCase(TrimmedLine).StartsWith('jezeli') then Exit;
    if LowerCase(TrimmedLine).StartsWith('wtedy') then Exit;
    if LowerCase(TrimmedLine).StartsWith('inaczej') then Exit;
    if LowerCase(TrimmedLine).StartsWith('if') then Exit;
    if LowerCase(TrimmedLine).StartsWith('then') then Exit;
    if LowerCase(TrimmedLine).StartsWith('else') then Exit;
    if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
    if LowerCase(TrimmedLine).StartsWith('dopoki') then Exit;
    if LowerCase(TrimmedLine).StartsWith('while') then Exit;
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

      if (VarType = 'plik') or
         (VarType = 'plik_tekstowy') or
         (VarType = 'file') or
         (VarType = 'lista_tekstów') or
         (VarType = 'lista_tekstow') or
         (VarType = 'string_list') or
         (VarType = 'strumień_pliku') or
         (VarType = 'strumien_pliku') or
         (VarType = 'file_stream') or
         (VarType = 'uchwyt_okna') or
         (VarType = 'hwnd') or
         (VarType = 'parametry_ui') or
         (VarType = 'ui_parameters') or
         (VarType = 'msg') or
         (VarType = 'dialog_komunikatu') or
         (VarType = 'text_file') then
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

    if (VarType = 'plik') or
       (VarType = 'plik_tekstowy') or
       (VarType = 'file') or
       (VarType = 'lista_tekstów') or
       (VarType = 'lista_tekstow') or
       (VarType = 'string_list') or
        (VarType = 'strumień_pliku') or
        (VarType = 'strumien_pliku') or
        (VarType = 'file_stream') or
       (VarType = 'text_file') then
    begin
      if (LowerCase(VarValue) = 'nil') or (LowerCase(VarValue) = 'nic') then
        AddVariable(VarName, VarType, True)  // declaration without initialisation / deklaracja bez inicjalizacji
      else
        AddVariable(VarName, VarType, False); // declaration with attribution / deklaracja z przypisaniem
      Exit;
    end;

    raise Exception.Create(TranslateUnknownFileType + VarType);
end;

function TAvocadoTranslator.ContainsFunction(const CodeLine: string;
  const Functions: array of string): Boolean;
var
  i: Integer;
begin
  Result := False;
    for i := Low(Functions) to High(Functions) do
    begin
      if Pos(Functions[i], CodeLine) > 0 then
        Exit(True);
    end;
end;

procedure TAvocadoTranslator.AddModule(var ModulesList: string;
  const ModuleName: string);
begin
  if Pos(ModuleName, ModulesList) = 0 then
  begin
    if ModulesList <> '' then
      ModulesList := ModulesList + ', ' + ModuleName
    else
      ModulesList := ModuleName;
  end;
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
CleanExpr: string;
Args: TStringArray;
OpenPos, EndPos: Integer;
ParamStr: string;
ParamPartsList: TStringList; // Lista do przechowywania argumentów
TranslatedS1Arg: string; // Tłumaczenie argumentu
begin
  // teksty
  Result := Expr;
  CleanExpr := Trim(Result);

  if (AnsiStartsText('teksty(', CleanExpr)) or
     (AnsiStartsText('strings(', CleanExpr)) then
  begin
    OpenPos := Pos('(', CleanExpr);
    EndPos := RPos(')', CleanExpr);

    if (OpenPos > 0) and (EndPos > OpenPos) then
    begin

      CleanExpr := Copy(CleanExpr, OpenPos + 1, EndPos - OpenPos - 1);
      Args := CleanExpr.Split([','], 2);

      if Length(Args) = 2 then
      begin
        Result := Format('%s.Strings[%s]', [Trim(Args[0]), Trim(Args[1])]);
        Exit;
      end;
    end;
  end;

  //  ilość(Lista) -> Lista.Count
  if AnsiStartsText('ilość(', CleanExpr) or
     AnsiStartsText('ilosc(', CleanExpr) or
     AnsiStartsText('count(', CleanExpr) then
  begin
    // 1. Znajdź i wydziel argumenty
    OpenPos := Pos('(', CleanExpr);
    EndPos := RPos(')', CleanExpr);

    // Walidacja nawiasów
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create('Brak nawiasów w funkcji ilość/count.');

    ParamStr := Trim(Copy(CleanExpr, OpenPos + 1, EndPos - OpenPos - 1));

    // 2. Walidacja liczby argumentów
    ParamPartsList := TStringList.Create;
    try
      // SplitArguments to musi być Twoja funkcja dzieląca parametry (np. 'h' z 'ilość(h)')
      SplitArguments(ParamStr, ParamPartsList);

      if ParamPartsList.Count <> 1 then
        raise Exception.Create(Format('Funkcja ilość/count wymaga dokładnie 1 argumentu, podano: %d', [ParamPartsList.Count]));

      // 3. Tłumaczenie: Tłumaczymy argument (nazwę listy)
      TranslatedS1Arg := TranslateExpression(Trim(ParamPartsList[0]));

      // 4. ZWROT WYNIKU: Zamiast dodawać do PascalCode, zwracamy przetłumaczony string.
      Result := TranslatedS1Arg + '.Count';
      Exit; // Kończymy funkcję
    finally
      ParamPartsList.Free;
    end;
  end;


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
  VName, VType, VInit: string;
begin
  TrimmedLine := Trim(Line);
  if TrimmedLine = '' then Exit;
  if FInProcedureBody then
  begin

    if (LowerCase(TrimmedLine) = 'koniec') or (LowerCase(TrimmedLine) = 'end') then
      FInProcedureBody := False;
    Exit;
  end;

  if (LowerCase(TrimmedLine).StartsWith('procedura ')) or
       (LowerCase(TrimmedLine).StartsWith('procedure ')) or
       (LowerCase(TrimmedLine).StartsWith('funkcja ')) or
       (LowerCase(TrimmedLine).StartsWith('function ')) then
  begin
    FInProcedureBody := True;
    Exit;
  end;

  //We skip lines beginning with control statements.
  // Pomijamy linie zaczynające się od instrukcji sterujących
  if FPascalMode then
  begin
    if TrimmedLine = '}' then
      FPascalMode := False;
    Exit;
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
  if LowerCase(TrimmedLine).StartsWith('jezeli ') then Exit;
  if LowerCase(TrimmedLine).StartsWith('while') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopoki') then Exit;


  if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
  if LowerCase(TrimmedLine).StartsWith('zakończ') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dla') then Exit;


  if LowerCase(TrimmedLine).StartsWith('if') then Exit;
  if LowerCase(TrimmedLine).StartsWith('then') then Exit;
  if LowerCase(TrimmedLine).StartsWith('else') then Exit;
  if LowerCase(TrimmedLine).StartsWith('exit') then Exit;

   if LowerCase(TrimmedLine).StartsWith('repeat') then Exit;
   if LowerCase(TrimmedLine).StartsWith('until') then Exit;

   if LowerCase(TrimmedLine).StartsWith('aż') then Exit;


  if LowerCase(TrimmedLine).StartsWith('halt') then Exit;
   if LowerCase(TrimmedLine).StartsWith('for') then Exit;
  //Transfer to file handling
  // Przekazanie do obsługi plików
  if LowerCase(TrimmedLine).StartsWith('plik') or
     LowerCase(TrimmedLine).StartsWith('plik_tekstowy') or
     LowerCase(TrimmedLine).StartsWith('lista_tekstów') or
     LowerCase(TrimmedLine).StartsWith('lista_tekstow') or
     LowerCase(TrimmedLine).StartsWith('string_list') or
     LowerCase(TrimmedLine).StartsWith('file') or
     LowerCase(TrimmedLine).StartsWith('strumień_pliku') or
     LowerCase(TrimmedLine).StartsWith('strumien_pliku') or
     LowerCase(TrimmedLine).StartsWith('file_stream') or
     //ui
     LowerCase(TrimmedLine).StartsWith('uchwyt_okna') or
     LowerCase(TrimmedLine).StartsWith('hwnd') or
     LowerCase(TrimmedLine).StartsWith('parametry_ui') or
     LowerCase(TrimmedLine).StartsWith('ui_parameters') or
     LowerCase(TrimmedLine).StartsWith('msg') or
     LowerCase(TrimmedLine).StartsWith('dialog_komunikatu') or

     LowerCase(TrimmedLine).StartsWith('text_file') then
  begin
    ProcessFileDeclaration(Line);
    Exit;
  end;

  if TryParseDeclaration(TrimmedLine, VName, VType, VInit) then
  begin
    AddVariable(VName, VType, VInit = '', VInit);
  end;
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
var
  AppDir, DictionaryPath: string;
begin
  // Wywołanie konstruktora klasy bazowej
  inherited Create;
  FFunctionMap := TStringList.Create;

  // Pobieramy ścieżkę do folderu, w którym znajduje się nasz program
  AppDir := ExtractFilePath(ParamStr(0));
  DictionaryPath := AppDir + 'avoraiser_translate.ini';

  // Bezpieczne wczytanie pliku - jeśli istnieje, ładujemy, jeśli nie, zostaje pusta lista
  if FileExists(DictionaryPath) then
  begin
    FFunctionMap.LoadFromFile(DictionaryPath);
  end
  else
  begin
     WriteLn('Ostrzeżenie: Nie znaleziono pliku słownika: avoraiser_translate.ini ', DictionaryPath);
  end;
  FVariables := nil;
  FInRepeatBlock := False;
  FInMultiLineComment := False;
end;



destructor TAvocadoTranslator.Destroy;
begin
    if Assigned(FFunctionMap) then
      FFunctionMap.Free;
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
  if not (LowerTrimmedLine.StartsWith('dopóki ') or
  (LowerTrimmedLine.StartsWith('dopoki ') or (LowerTrimmedLine.StartsWith('while '))))
  then
  begin
    Exit;
  end;

  // pętla while.
  TranslatedLine := TrimmedLine;
  TranslatedLine := ReplaceText(TranslatedLine, 'dopóki', 'while');
  TranslatedLine := ReplaceText(TranslatedLine, 'dopoki', 'while');

  // 2.'wykonaj' -> 'do'
  TranslatedLine := StringReplace(TranslatedLine, 'wykonaj', 'do', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'wykonaj ', 'do ', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'make', 'do', [rfReplaceAll, rfIgnoreCase]);
  PascalCode.Add(TranslatedLine);
end;

procedure TAvocadoTranslator.ProcessForLoop(const Line: string; PascalCode: TStringList);
var
  TranslatedLine: string;
  Parts: TStringArray;
  EndExpr, TranslatedEndExpr, StartPart: string;
  ToKeyword: string;
  EqPos, LastDoPos: Integer;
  DeclarationPart: string;
begin
  TranslatedLine := Trim(Line);

  TranslatedLine := StringReplace(TranslatedLine, 'dla', 'for', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'malejąco', 'downto', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'malejaco', 'downto', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'wykonaj', 'do', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'wykonaj ', 'do ', [rfReplaceAll, rfIgnoreCase]);
  TranslatedLine := StringReplace(TranslatedLine, 'make', 'do', [rfReplaceAll, rfIgnoreCase]);

  TranslatedLine := StringReplace(TranslatedLine, '==', '=', [rfReplaceAll]);

  if Pos(':=', TranslatedLine) = 0 then
  begin
    EqPos := Pos('=', TranslatedLine);
    if EqPos > 0 then
    begin
      Delete(TranslatedLine, EqPos, 1);
      Insert(':=', TranslatedLine, EqPos);
    end;
  end;

  if not EndsText(' do', TranslatedLine) then
     TranslatedLine := TranslatedLine + ' do';

  LastDoPos := RPos(' do', LowerCase(TranslatedLine));

  if LastDoPos > 0 then
  begin

    DeclarationPart := Copy(TranslatedLine, 1, LastDoPos - 1);

    if Pos(' downto ', LowerCase(DeclarationPart)) = 0 then
    begin
       DeclarationPart := StringReplace(DeclarationPart, ' do ', ' to ', [rfReplaceAll, rfIgnoreCase]);
    end;

    TranslatedLine := DeclarationPart + Copy(TranslatedLine, LastDoPos, MaxInt);
  end;

  if Pos(' downto ', LowerCase(TranslatedLine)) > 0 then
  begin
     ToKeyword := ' downto ';
     Parts := TranslatedLine.Split([' downto '], 2);
  end
  else
  begin
     ToKeyword := ' to ';
     Parts := TranslatedLine.Split([' to '], 2);
  end;

  if Length(Parts) >= 2 then
  begin
    StartPart := Trim(Parts[0]);
    EndExpr := Trim(Parts[1]);

    if EndsText(' do', EndExpr) then
      EndExpr := Copy(EndExpr, 1, Length(EndExpr) - 3);

    EndExpr := Trim(EndExpr);
    TranslatedEndExpr := TranslateExpression(EndExpr);

    if (ToKeyword = ' to ') and (Pos(':= 0', StartPart) > 0) then
    begin
       if (Pos('.Count', TranslatedEndExpr) > 0) or (Pos('Length(', TranslatedEndExpr) > 0) then
       begin
         if Pos('-1', TranslatedEndExpr) = 0 then
            TranslatedEndExpr := TranslatedEndExpr + ' - 1';
       end;
    end;

    TranslatedLine := Format('%s%s%s do', [StartPart, ToKeyword, TranslatedEndExpr]);
    PascalCode.Add(TranslatedLine);
  end
  else
  begin
    PascalCode.Add(TranslatedLine);
  end;
end;

function TAvocadoTranslator.TryTranslateGeneric(const Line: string;
  PascalCode: TStringList; Aliases: array of string; RequiredArgs: Integer;
  PascalTemplate: string; SyntaxErrorMsg: string; ArgCountErrorMsg: String
  ): Boolean;
var
  ParamPartsList: TStringList;
  Args: array of string;
  StartPos, EndPos, i: Integer;
  ParamStr, TrimmedLine, LowerLine: string;
  IsFound: Boolean;
  FinalCode: string;
begin
    Result := False;
    TrimmedLine := Trim(Line);
    LowerLine := LowerCase(TrimmedLine);

    IsFound := False;
    for i := Low(Aliases) to High(Aliases) do
    begin
      if LowerLine.StartsWith(LowerCase(Aliases[i]) + '(') then
        begin
          IsFound := True;
          Break;
        end;
    end;

    if not IsFound then Exit;

    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) or (StartPos > EndPos) then
      raise Exception.Create(SyntaxErrorMsg + Aliases[0]);

    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);

      //if ParamPartsList.Count <> RequiredArgs then
      //  raise Exception.Create(ErrorMsg + ' (Oczekiwano ' + IntToStr(RequiredArgs) + ')');
      if ParamPartsList.Count <> RequiredArgs then
      raise Exception.Create(ArgCountErrorMsg + ' (Oczekiwano: ' +
          IntToStr(RequiredArgs) + ', otrzymano: ' +
          IntToStr(ParamPartsList.Count) + ')');

      // Tłumaczenie argumentów
      SetLength(Args, RequiredArgs);
      for i := 0 to RequiredArgs - 1 do
        Args[i] := TranslateExpression(Trim(ParamPartsList[i]));

      FinalCode := PascalTemplate;
      {// Składanie kodu Pascala przy użyciu szablonu
      case RequiredArgs of
        1: PascalCode.Add(Format(PascalTemplate + ';', [Args[0]]));
        2: PascalCode.Add(Format(PascalTemplate + ';', [Args[0], Args[1]]));
        3: PascalCode.Add(Format(PascalTemplate + ';', [Args[0], Args[1], Args[2]]));
      end;
      }
    for i := 0 to RequiredArgs - 1 do
    begin
      FinalCode := StringReplace(FinalCode, '%' + IntToStr(i), Args[i], [rfReplaceAll]);
    end;
    if not FinalCode.EndsWith(';') then FinalCode := FinalCode + ';';
        PascalCode.Add(FinalCode);
      Result := True;
    finally
      ParamPartsList.Free;
    end;
end;


procedure TAvocadoTranslator.ProcessForInLoop(const Line: string;
  PascalCode: TStringList);
var
  TranslatedLine: string;
begin
    TranslatedLine := Trim(Line);
    TranslatedLine := StringReplace(TranslatedLine, 'dla', 'for', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, ' dla ', ' for ', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'dla ', 'for ', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, ' w ', ' in ', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'wykonaj', 'do', [rfReplaceAll, rfIgnoreCase]);
    TranslatedLine := StringReplace(TranslatedLine, 'wykonaj ', 'do ', [rfReplaceAll, rfIgnoreCase]);
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
  LowerCode: string;
begin
  ModulesList := '';
  Lines := TStringList.Create;
  try
    Lines.Text := Code;

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if AnsiStartsText('importuj', LowerCase(Line)) then
      begin
        Delete(Line, 1, Length('importuj'));
      end
      else if AnsiStartsText('import', LowerCase(Line)) then
      begin
        Delete(Line, 1, Length('import'));
      end
      else
        Continue;

      Line := Trim(Line);
      // Dodaj bezpośrednio zaimportowany moduł do listy
      if Line <> '' then
        AddModule(ModulesList, Line);
    end;

    LowerCode := LowerCase(Code);

    // Crt
    if ContainsFunction(LowerCode, [
      'czytaj_klawisz', 'read_key', 'tło_tekstu', 'tlo_tekstu', 'text_background',
      'kolor_tekstu', 'text_color', 'pozycja_kursora', 'cursor_position',
      'przypisz_plik', 'klawisz_wciśnięty', 'key pressed'
    ]) then
      AddModule(ModulesList, 'Crt');

    // Internet
    if ContainsFunction(LowerCode, ['pobierz_plik(']) then
      AddModule(ModulesList, 'internet');

    // AVORAISER Kontrolki (Pojedyncze)
    if ContainsFunction(LowerCode, ['create_window(']) then AddModule(ModulesList, 'avoraiser.window');
    if ContainsFunction(LowerCode, ['create_edit(']) then AddModule(ModulesList, 'avoraiser.edit');
    if ContainsFunction(LowerCode, ['create_trackbar(']) then AddModule(ModulesList, 'avoraiser.trackbar');

    if ContainsFunction(LowerCode, ['create_memo(']) then AddModule(ModulesList, 'avoraiser.memo');
    if ContainsFunction(LowerCode, ['create_rich_edit(']) then AddModule(ModulesList, 'avoraiser.richedit');
    if ContainsFunction(LowerCode, ['create_label(']) then AddModule(ModulesList, 'avoraiser.labels');
    if ContainsFunction(LowerCode, ['getpropint(']) then AddModule(ModulesList, 'avoraiser.shape');
    if ContainsFunction(LowerCode, ['create_combo_box(']) then AddModule(ModulesList, 'avoraiser.combobox');
    if ContainsFunction(LowerCode, ['create_listbox(']) then AddModule(ModulesList, 'avoraiser.listbox');
    if ContainsFunction(LowerCode, ['create_checkbox(']) then AddModule(ModulesList, 'avoraiser.chekbox');
    if ContainsFunction(LowerCode, ['create_radio_button(']) then AddModule(ModulesList, 'avoraiser.radiobutton');
    if ContainsFunction(LowerCode, ['create_group_box(']) then AddModule(ModulesList, 'avoraiser.groupbutton');
    if ContainsFunction(LowerCode, ['create_progressbar(']) then AddModule(ModulesList, 'avoraiser.progressbar');
    if ContainsFunction(LowerCode, ['create_spin_edit(']) then AddModule(ModulesList, 'avoraiser.spinedit');

    // AVORAISER Moduły zbiorcze
    if ContainsFunction(LowerCode, [
      'set_on_time_change(', 'set_on_init_popup(', 'clear_timepicker_props('
    ]) then
      AddModule(ModulesList, 'avoraiser.timepicker');

    if ContainsFunction(LowerCode, [
      'set_on_context_menu(', 'set_on_init_menu_popup(', 'set_on_menu_select(', 'set_on_menu_command('
    ]) then
      AddModule(ModulesList, 'avoraiser.menu');

    if ContainsFunction(LowerCode, [
      'center_window(', 'set_position(', 'set_size(', 'get_x(', 'get_y(',
      'get_width(', 'get_height(', 'get_client_area(', 'create_frame('
    ]) then
      AddModule(ModulesList, 'avoraiser.layout');

    if ContainsFunction(LowerCode, [
      'show_message(', 'ask_question(', 'show_warning(', 'show_custom_dialog(', 'set_dialog_language(',
      'input_box(', 'password_box(', 'show_toast(', 'show_action_sheet(' ,'show_progress_dialog(',
      'update_progress(','get_file_name_from_user('
    ]) then
      AddModule(ModulesList, 'avoraiser.dialogs');


    if ContainsFunction(LowerCode, [
      'copy_to_clipboard(', 'cut_to_clipboard(', 'paste_from_clipboard(', 'undo_last_action(', 'can_undo(',
      'show_context_menu('
    ]) then
      AddModule(ModulesList, 'avoraiser.clipboard');

    //Przyciski
    if ContainsFunction(LowerCode, [
    'create_button(','create_image_button(','set_button_colors(','set_button_radius(','set_button_id('

    ])then
    AddModule(ModulesList, 'avoraiser.button');


    // Zwrócenie wynikowej listy modułów
    Result := ModulesList;
  finally
    Lines.Free;
  end;
end;

function TAvocadoTranslator.GetImplementationModules(const Code: string
  ): string;
const
  ImplementationKeyword = 'moduły_pas';
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
      if AnsiStartsText(ImplementationKeyword, Line) then
      begin
        Line := Trim(Copy(Line, Length(ImplementationKeyword) + 1, MaxInt));
        if Line <> '' then
        begin
          if ModulesList = '' then
            ModulesList := Line
          else
            ModulesList := ModulesList + ', ' + Line;
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

    Call := Line;
    if Pos('=', Line) > 0 then
    begin
      VarName := Trim(Copy(Line, 1, Pos('=', Line) - 1));
      Call := Trim(Copy(Line, Pos('=', Line) + 1, MaxInt));

      if Pos(' ', VarName) > 0 then
        VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
    end;


    StartPos := Pos('(', Call);
    if StartPos = 0 then
    begin
      Result := LowerCase(Call);
      Exit;
    end;

    Result := LowerCase(Trim(Copy(Call, 1, StartPos - 1)));

    EndPos := LastDelimiter(')', Call);
    if (EndPos = 0) or (EndPos < StartPos) then
      raise Exception.Create(TranslateIncorrectBracketsInFunction + Result + '.');

    ParamStr := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
    VarName := ParamStr;
end;

function TAvocadoTranslator.SafeResolveAlias(const AName: string): string;
begin
  try
    Result := ResolveAlias(AName);
  except
    on E: Exception do
    begin
      Writeln(TranslateAliasTypeIsUnknown, AName, TranslateReplacedVariant);
      Result := 'Variant';
    end;
  end;
end;

procedure TAvocadoTranslator.AnalyzeLocalVariables(StartIndex: Integer;
  Source: TStrings);
var
  i, Depth: Integer;
  Line, LLine: string;
  VName, VType, VInit: string;
  HasStartedBlock: Boolean;
  // do obsługi komentarzy
  IsInComment: Boolean;
  pStart, pEnd: Integer;
  LineBefore, LineAfter: string;
begin
    LLine := AnsiLowerCase(Line);
    SetLength(FLocalVariables, 0);
    Depth := 0;
    HasStartedBlock := False;
    IsInComment := False;

    if (LLine = 'start') or
       (LLine = 'początek') or
       (LLine = 'poczatek')or
       (LLine = 'begin') or
       (LLine = 'main') or
       (LLine = 'glowny') or
       (LLine = 'główny')then
    begin
      Inc(Depth);
      HasStartedBlock := True;
    end
    else if (LLine = 'koniec') or (LLine = 'end') or (LLine = 'koniec;') or (LLine = 'end;') then
    begin
      Dec(Depth);
    end;


    for i := StartIndex to Source.Count - 1 do
    begin
    Line := Trim(Source[i]);

   // Jeśli jesteśmy w trakcie komentarza wielowierszowego z poprzedniej linii
    if IsInComment then
    begin
      pEnd := Pos('*)', Line);
      if pEnd > 0 then
      begin
        // Znaleziono koniec komentarza, ucinamy początek linii
        Line := Copy(Line, pEnd + 2, MaxInt);
        IsInComment := False;
      end
      else
      begin
        // Cała linia jest komentarzem
        Continue;
      end;
    end;

    // Obsługa komentarzy otwieranych i zamykanych w tej samej linii
    // lub otwieranych w tej linii
    while Pos('(*', Line) > 0 do
    begin
      pStart := Pos('(*', Line);
      pEnd := Pos('*)', Line);

      if (pEnd > pStart) then
      begin
        // Komentarz jest w całości w tej linii: kod (* kom *) kod
        LineBefore := Copy(Line, 1, pStart - 1);
        LineAfter := Copy(Line, pEnd + 2, MaxInt);
        Line := LineBefore + ' ' + LineAfter;
      end
      else
      begin
        // Komentarz zaczyna się tutaj, ale nie kończy: kod (* ...
        Line := Copy(Line, 1, pStart - 1);
        IsInComment := True;
        Break; // Przerywamy pętlę while, reszta linii to komentarz
      end;
    end;

    // Obsługa komentarzy jednoliniowych //
    if Pos('//', Line) > 0 then
      Line := Copy(Line, 1, Pos('//', Line) - 1);

    Line := Trim(Line);
    if Line = '' then Continue;

    LLine := AnsiLowerCase(Line);

    // Wykrywamy początek bloku
    if (LLine = 'start') or
       (LLine = 'początek') or
       (LLine = 'poczatek') or
       (LLine = 'begin') or
       (LLine = 'glowny') or
       (LLine = 'główny') or
       (LLine = 'main') then
    begin
      Inc(Depth);
      HasStartedBlock := True;
    end
    // Wykrywamy koniec bloku
    else if (LLine = 'koniec') or (LLine = 'end') or (LLine = 'koniec;') or (LLine = 'end;') then
    begin
      Dec(Depth);
    end;

    // Sprawdzamy, czy to deklaracja zmiennej
    if TryParseDeclaration(Line, VName, VType, VInit) then
    begin
      AddLocalVariable(VName, VType, VInit = '', VInit);
    end;

    // Warunek wyjścia Jeśli weszliśmy do bloku i wyszliśmy z niego (głębokość <= 0)
    if HasStartedBlock and (Depth <= 0) then
      Break;
  end;
end;

procedure TAvocadoTranslator.AddLocalVariable(const VarName, VarType: string;
  NoAssign: Boolean; const AInitialValue: string);
var
  j: Integer;
begin
  for j := 0 to High(FLocalVariables) do
      if FLocalVariables[j].VarName = VarName then Exit;
  SetLength(FLocalVariables, Length(FLocalVariables) + 1);
  FLocalVariables[High(FLocalVariables)].VarName := VarName;
  FLocalVariables[High(FLocalVariables)].VarType := VarType;
  FLocalVariables[High(FLocalVariables)].NoAssign := NoAssign;
  FLocalVariables[High(FLocalVariables)].InitialValue := AInitialValue;
end;

function TAvocadoTranslator.TryParseDeclaration(const Line: string; out
  VarName, VarType, InitValue: string): Boolean;
var
  TrimmedLine: string;
  Parts, VarParts: TStringArray;
begin
  Result := False;
  VarName := '';
  VarType := '';
  InitValue := '';
  TrimmedLine := Trim(Line);

  if TrimmedLine = '' then Exit;
  // Ignoruj słowa kluczowe
  if LowerCase(TrimmedLine).StartsWith('jeżeli') then Exit;
  if LowerCase(TrimmedLine).StartsWith('jezeli') then Exit;
  if LowerCase(TrimmedLine).StartsWith('if') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopóki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dopoki') then Exit;
  if LowerCase(TrimmedLine).StartsWith('while') then Exit;
  if LowerCase(TrimmedLine).StartsWith('dla') then Exit;
  if LowerCase(TrimmedLine).StartsWith('for') then Exit;
  if LowerCase(TrimmedLine).StartsWith('wyjść') then Exit;
  if LowerCase(TrimmedLine).StartsWith('wyjsc') then Exit;
  if LowerCase(TrimmedLine).StartsWith('exit') then Exit;

  // Sprawdź przypadek z przypisaniem: typ nazwa = wartość
  if Pos('=', TrimmedLine) > 0 then
  begin
    Parts := TrimmedLine.Split(['='], 2);
    if Length(Parts) >= 2 then
    begin
      VarParts := Trim(Parts[0]).Split([' '], 2);
      if Length(VarParts) >= 2 then
      begin
        // Sprawdź czy pierwsze słowo to typ
        try
           if ResolveAlias(VarParts[0]) <> '' then
           begin
             VarType := LowerCase(Trim(VarParts[0]));
             VarName := Trim(VarParts[1]);
             InitValue := Trim(Parts[1]);
             Result := True;
             Exit;
           end;
        except
          // Nieznany typ
        end;
      end;
    end;
  end
  else
  begin
    // bez przypisania: typ nazwa
    VarParts := TrimmedLine.Split([' '], 2);
    if Length(VarParts) >= 2 then
    begin
      try
         if ResolveAlias(VarParts[0]) <> '' then
         begin
           VarType := LowerCase(Trim(VarParts[0]));
           VarName := Trim(VarParts[1]);
           Result := True;
           Exit;
         end;
      except
      end;
    end;
  end;
end;

function TAvocadoTranslator.GetWindowsCP(const DetectedName: string): string;
var
  LowerName: string;
begin
  LowerName := LowerCase(DetectedName);

    // 1. UTF-8 (Najważniejszy standard)
    if (LowerName = 'utf8') or (LowerName = 'utf-8') then
      Exit('65001'); // 65001 to identyfikator UTF-8 w Windows Console

    // 2. Rozpoznawanie konkretnych stron kodowych (Windows ANSI)
    case LowerName of
      // Europa Środkowa (Polska, Czechy, Słowacja, Węgry, Słowenia)
      'cp1250', 'windows-1250', '1250': Exit('1250');

      // Cyrylica (Rosja, Ukraina, Białoruś, Bułgaria)
      'cp1251', 'windows-1251', '1251': Exit('1251');

      // Europa Zachodnia (Anglia, Niemcy, Francja, Hiszpania, Włochy)
      'cp1252', 'windows-1252', '1252': Exit('1252');

      // Grecki
      'cp1253', 'windows-1253', '1253': Exit('1253');

      // Turecki
      'cp1254', 'windows-1254', '1254': Exit('1254');

      // Hebrajski
      'cp1255', 'windows-1255', '1255': Exit('1255');

      // Arabski
      'cp1256', 'windows-1256', '1256': Exit('1256');

      // Kraje Bałtyckie (Litwa, Łotwa, Estonia)
      'cp1257', 'windows-1257', '1257': Exit('1257');

      // Wietnamski
      'cp1258', 'windows-1258', '1258': Exit('1258');

      // Tajski
      'cp874',  'windows-874',  '874':  Exit('874');
    end;

    // 3. Logika ogólna (Fallback)
    // Jeśli funkcja wykrywająca zwróciła coś w stylu "cp932" (japoński),
    // a nie ma tego w 'case', wycinamy "cp" i zwracamy numer.
    if AnsiStartsText('cp', LowerName) then
    begin
      Result := Copy(LowerName, 3, MaxInt);
      // Proste zabezpieczenie: kodowanie musi być liczbą
      if StrToIntDef(Result, -1) = -1 then
        Result := '1252'; // Jeśli to nie liczba, wracamy do domyślnego
    end
    else
    begin
      // 4. Ostateczna wartość domyślna (Europa Zachodnia / USA)
      Result := '1252';
    end;
end;

function TAvocadoTranslator.TranslateFunctions(const CodeLine: string): string;
var
  i: Integer;
  PolishName, EnglishName: string;
begin
  Result := CodeLine;
  if Trim(Result) = '' then Exit;

  // tlumaczenia
  for i := 0 to FFunctionMap.Count - 1 do
  begin
    PolishName := FFunctionMap.Names[i];
    EnglishName := FFunctionMap.ValueFromIndex[i];

    // Szukamy polskiej nazwy z nawiasem, np. "pokaz_okno("
    if Pos(PolishName + '(', Result) > 0 then
    begin
      Result := StringReplace(Result, PolishName + '(', EnglishName + '(', [rfReplaceAll, rfIgnoreCase]);
    end;
  end;
  Result := StringReplace(Result, '()', '', [rfReplaceAll]);
end;


procedure TAvocadoTranslator.AddCompilerDirective(PascalCode: TStringList; IsGUI: Boolean);
var
DirectIndex, i: Integer;
begin
  DirectIndex := -1;
  // Szukamy linii "program ...", którą dodała funkcja Translate
  for i := 0 to PascalCode.Count - 1 do
  begin
    if Trim(LowerCase(PascalCode[i])).StartsWith('program ') then
    begin
      DirectIndex := i;
      Break;
    end;
  end;

  if DirectIndex <> -1 then
  begin
    PascalCode.Insert(DirectIndex, '{$mode objfpc}');
    PascalCode.Insert(DirectIndex + 1, '{$H+}');

    // Jeśli to aplikacja UI, dodajemy APPTYPE GUI
    if IsGUI then
      PascalCode.Insert(DirectIndex + 2, '{$APPTYPE GUI}');

    // Obsługa ASM (opcjonalnie)
    if NeedsAsmIntel then
      PascalCode.Insert(DirectIndex + 3, '{$ASMMODE intel}');
  end
  else
  begin
    // gdyby nie znaleziono "program"
    PascalCode.Insert(0, '{$mode objfpc}');
    PascalCode.Insert(1, '{$H+}');

    if IsGUI then
      PascalCode.Insert(2, '{$APPTYPE GUI}');

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

procedure TAvocadoTranslator.ProcessLine(const Line: string; PascalCode: TStringList; const NextTrimmedLowerLine: string);
var
  // Deklaracje zmiennych
  Parts: TStringArray;
  VarType, VarName, Value, TrimmedLine, LowerTrimmedLine, LowerLine: string;
  TranslatedLine, CleanLowerLine: string;
  StartPos, EndPos, OpenPos: Integer;
  StartPosTrim, EndPosTrim: Integer;
  ParamTrim, TranslatedParam: string;
  NeedsSemicolon: Boolean;
  ConditionStr, TranslatedCondition: string;
  AssignPos: Integer;
  LineBefore, LineAfter: string;
  VName, VType, VInit: string;
  ParamPartsList: TStringList;
  ParamStr: string;
  TranslatedCharArg, TranslatedCountArg: string;
  StartPosInsert, EndPosInsert: Integer;
  ParamInsert: string;
  ParamPartsInsert: TStringArray;
  InsertSourceIn, InsertTargetIn, InsertIndexIn: string;
  StartPosDelete, EndPosDelete: Integer;
  ParamDelete: string;
  ParamPartsDelete: TStringArray;
  StringExprDelete, IndexExprDelete, CountExprDelete: string;
  StartPosUpper, EndPosUpper: Integer;
  ParamUpper, TranslatedParamUpper: string;
  StartPosLower, EndPosLower: Integer;
  ParamLower, TranslatedParamLower: string;
  StartPosCompareStr, EndPosCompareStr: Integer;
  ParamCompareStr, TranslatedS1Arg, TranslatedS3Arg, TranslatedS2Arg: string;
  ParamPartsCompareStr: TStringArray;
  ZamienTekst_StartPos, ZamienTekst_EndPos: Integer;
  ZamienTekst_Param: string;
  ZamienTekst_ParamParts, ZamienTekst_AssignParts: TStringArray;
  ZamienTekst_TextArg, ZamienTekst_FromArg, ZamienTekst_ToArg, ZamienTekst_ResultVar: string;
  DLAnsi_Param, DLAnsi_VarName: string;
  DLAnsi_FuncPos, DLAnsi_LParenPos, DLAnsi_RParenPos: Integer;
  DLAnsi_AssignParts: TStringArray;
  AssignStartPos, AssignEndPos: Integer;
  AssignParamStr, AssignTranslatedParam1, AssignTranslatedParam2: string;
  AssignParams: TStringList;
  CodePascal: string;
  Site: string;
  Param, Expression, Call: string;
  SExpr, StartExpr, CountExpr, SubstringExpr: string;
  FullArgs,LengthExpr,SiteExpression,TranslatedSite: String;
  SuccessMessage: string ;
  URL_Expression: string;
  SavePath_Expression: string;
  URL, Target: string;
  CommaPos,I: Integer;
  InQuotes: Boolean;
  ResultLine: string;
  CommentDepth: Integer;
  DotPos: Integer;
  ObjectName, PropName: string;
begin
  TrimmedLine := Trim(Line);

 TrimmedLine := Trim(Line);

  //zaawansowana obsługa komentarzy (lexer z zagnieżdżaniem)
  ResultLine := '';
  InQuotes := False;
  I := 1;

  // Przenosimy stan z klasy do lokalnego licznika zagnieżdżeń
  CommentDepth := 0;
  if FInMultiLineComment then CommentDepth := 1;

  while I <= Length(TrimmedLine) do
  begin
    // Jesteśmy wewnątrz komentarza (* ... *)
    if CommentDepth > 0 then
    begin
      // 1. Wykrywamy KOLEJNE otwarcie komentarza (zagnieżdżenie)
      if (I < Length(TrimmedLine)) and (TrimmedLine[I] = '(') and (TrimmedLine[I+1] = '*') then
      begin
        Inc(CommentDepth); // Wchodzimy głębiej
        Inc(I, 2);
      end
      // 2. Wykrywamy zamknięcie komentarza
      else if (I < Length(TrimmedLine)) and (TrimmedLine[I] = '*') and (TrimmedLine[I+1] = ')') then
      begin
        Dec(CommentDepth); // Wychodzimy płycej
        Inc(I, 2);

        // Jeśli zeszliśmy do zera, ostatecznie wychodzimy z komentarza
        if CommentDepth = 0 then
        begin
          FInMultiLineComment := False;
          ResultLine := ResultLine + ' '; // Dodajemy spację, by nie skleić kodu
        end;
      end
      else
      begin
        Inc(I); // Ignorujemy zawartość komentarza
      end;
    end
    else
    begin
      //Jesteśmy w "normalnym" kodzie:

      //Sprawdzamy, czy wchodzimy/wychodzimy ze stringa
      if TrimmedLine[I] = '''' then
      begin
        InQuotes := not InQuotes;
        ResultLine := ResultLine + TrimmedLine[I];
        Inc(I);
        Continue;
      end;

      //Jeśli NIE jesteśmy w stringu, łapiemy początki komentarzy
      if not InQuotes then
      begin
        // Początek komentarza jednolinijkowego //
        if (I < Length(TrimmedLine)) and (TrimmedLine[I] = '/') and (TrimmedLine[I+1] = '/') then
        begin
          Break; // Ucinamy wszystko do końca linii i przerywamy pętlę
        end;

        // Początek komentarza wielolinijkowego (*
        if (I < Length(TrimmedLine)) and (TrimmedLine[I] = '(') and (TrimmedLine[I+1] = '*') then
        begin
          Inc(CommentDepth);
          FInMultiLineComment := True;
          Inc(I, 2);
          Continue;
        end;
      end;

      // Zwykły znak - przepisujemy do wyniku
      ResultLine := ResultLine + TrimmedLine[I];
      Inc(I);
    end;
  end;

  // Zabezpieczenie: jeśli po przejściu linii wciąż jesteśmy głęboko w komentarzach,
  // informujemy o tym klasę, by pamiętała to przy czytaniu następnej linijki!
  if CommentDepth > 0 then FInMultiLineComment := True;
  TrimmedLine := Trim(ResultLine);
  if TrimmedLine = '' then Exit;


  // Bezpieczne usuwanie komentarzy '//' z ignorowaniem tekstów wewnątrz stringów
  InQuotes := False;
  for I := 1 to Length(TrimmedLine) do
  begin
    // Sprawdzamy, czy wchodzimy/wychodzimy ze stringa (apostrofy)
    if TrimmedLine[I] = '''' then
      InQuotes := not InQuotes;

    // Jeśli NIE jesteśmy wewnątrz stringa i widzimy '//', ucinamy linię
    if (not InQuotes) and (I < Length(TrimmedLine)) and (TrimmedLine[I] = '/') and (TrimmedLine[I+1] = '/') then
    begin
      TrimmedLine := Trim(Copy(TrimmedLine, 1, I - 1));
      Break; // Koniec szukania w tej linii
    end;
  end;
  LowerTrimmedLine := LowerCase(TrimmedLine);
  LowerLine := AnsiLowerCase(TrimmedLine);

  // --- 2. OBSŁUGA DEKLARACJI ZMIENNYCH (Wewnątrz procedur) ---
  if TryParseDeclaration(TrimmedLine, VName, VType, VInit) then
  begin
    if VInit <> '' then
    begin
      if (NextTrimmedLowerLine <> 'inaczej') and (NextTrimmedLowerLine <> 'else') then
        PascalCode.Add(VName + ' := ' + TranslateExpression(VInit) + ';')
      else
        PascalCode.Add(VName + ' := ' + TranslateExpression(VInit));
    end;
    Exit;
  end;

  // --- 3. SŁOWA KLUCZOWE ---
  case LowerTrimmedLine of
    'początek', 'poczatek', 'główny', 'glowny', 'start', 'main':
    begin
      PascalCode.Add('begin');
      Exit;
    end;

    'koniec', 'end':
    begin
      if (NextTrimmedLowerLine = 'inaczej') or (NextTrimmedLowerLine = 'else') then
        PascalCode.Add('end')
      else
        PascalCode.Add('end;');
      Exit;
    end;

    'koniec.', 'end.':
    begin
      PascalCode.Add('Readln;');
      PascalCode.Add('end.');
      Exit;
    end;
  end;

  // Obsługa zwróć / return
  if (Pos('zwróć', LowerTrimmedLine) = 1) or
     (Pos('zwroc', LowerTrimmedLine) = 1) or
     (Pos('return', LowerTrimmedLine) = 1) then
  begin
    StartPosTrim := Pos(' ', TrimmedLine);
    if StartPosTrim = 0 then
    begin
       PascalCode.Add('Exit;');
    end
    else
    begin
      ParamTrim := Trim(Copy(TrimmedLine, StartPosTrim + 1, MaxInt));
      if ParamTrim.EndsWith(';') then Delete(ParamTrim, Length(ParamTrim), 1);
      TranslatedParam := TranslateExpression(ParamTrim);
      PascalCode.Add('Result := ' + TranslatedParam + ';');
      PascalCode.Add('Exit;');
    end;
    Exit;
  end;

  // Warunek IF / ELSE
  NeedsSemicolon := (NextTrimmedLowerLine <> 'inaczej');
  if (LowerTrimmedLine.StartsWith('jeżeli ')) or
     (LowerTrimmedLine.StartsWith('jezeli ')) or
     (LowerTrimmedLine.StartsWith('if ')) or
     (LowerTrimmedLine.StartsWith('inaczej')) or
     (LowerTrimmedLine.StartsWith('else')) then
  begin
     TranslatedLine := TrimmedLine;
     TranslatedLine := StringReplace(TranslatedLine, 'inaczej jeżeli', 'else if', [rfReplaceAll, rfIgnoreCase]);
     TranslatedLine := StringReplace(TranslatedLine, 'inaczej jezeli', 'else if', [rfReplaceAll, rfIgnoreCase]);
     TranslatedLine := StringReplace(TranslatedLine, 'jeżeli', 'if', [rfReplaceAll, rfIgnoreCase]);
     TranslatedLine := StringReplace(TranslatedLine, 'jezeli', 'if', [rfReplaceAll, rfIgnoreCase]);
     TranslatedLine := StringReplace(TranslatedLine, 'wtedy', 'then', [rfReplaceAll, rfIgnoreCase]);
     TranslatedLine := StringReplace(TranslatedLine, 'inaczej', 'else', [rfReplaceAll, rfIgnoreCase]);
     PascalCode.Add(TranslatedLine);
     Exit;
  end;

  // Break / Continue
  if (LowerTrimmedLine = 'przerwij')or
     (LowerTrimmedLine = 'break') or
     (LowerTrimmedLine = 'break;')then
  begin PascalCode.Add('break;');
    Exit;
  end;
  if (LowerTrimmedLine = 'kontynuuj') or
     (LowerTrimmedLine = 'continue') then
  begin PascalCode.Add('continue;');
    Exit;
  end;

  // Pętle
  // POPRAWKA: Dodano sprawdzanie 'dla(' i 'for(' oraz zabezpieczenie przed nazwą zmiennej "w"
  if (LowerTrimmedLine = 'dla') or (LowerTrimmedLine = 'for') or
     (LowerTrimmedLine.StartsWith('dla ')) or (LowerTrimmedLine.StartsWith('dla(')) or
     (LowerTrimmedLine.StartsWith('for ')) or (LowerTrimmedLine.StartsWith('for(')) then
  begin
     // Sprawdzenie czy to pętla 'foreach' (dla zmienna w kolekcja)
     // Zabezpieczenie: upewnij się, że " w " to nie jest część "w dół" (downto)
     // oraz że " w " nie jest po prostu nazwą zmiennej w pętli liczbowej (np. dla w = 1 do 10)
    if ( (Pos(' w ', LowerTrimmedLine) > 0) and (Pos(' w dół', LowerTrimmedLine) = 0) and (Pos(' w dol', LowerTrimmedLine) = 0) and (Pos(' do ', LowerTrimmedLine) = 0) ) or
       (Pos(' in ', LowerTrimmedLine) > 0) then
      ProcessForInLoop(TrimmedLine, PascalCode)
    else
      ProcessForLoop(TrimmedLine, PascalCode);
    Exit;
  end;

  {
  if (LowerTrimmedLine.StartsWith('dla ')) or
     (LowerTrimmedLine.StartsWith('for ')) then
  begin
    if (Pos(' w ', LowerTrimmedLine) > 0) or
       (Pos(' in ', LowerTrimmedLine) > 0) then
      ProcessForInLoop(TrimmedLine, PascalCode)
    else
      ProcessForLoop(TrimmedLine, PascalCode);
    Exit;
  end;
  }

  if (LowerTrimmedLine.StartsWith('dopóki ')) or
     (LowerTrimmedLine.StartsWith('dopoki ')) or
     (LowerTrimmedLine.StartsWith('while ')) then
  begin ProcessWhileLoop(TrimmedLine, PascalCode);
    Exit;
  end;

  if (LowerLine = 'powtarzaj') or
     (LowerLine = 'repeat') then
  begin
    if FInRepeatBlock then
      raise Exception.Create(TranslateErrFoundRepeatInsideAnotherRepeat);
    PascalCode.Add('repeat');
    FInRepeatBlock := True;
    Exit;
  end;

  if LowerLine.StartsWith('aż ') or
     LowerLine.StartsWith('az ') or LowerLine.StartsWith('until ') then
  begin
    if not FInRepeatBlock then
      raise Exception.Create(TranslateAzorUntil);
    if LowerLine.StartsWith('aż ') or
       LowerLine.StartsWith('az ') then
         ConditionStr := Trim(Copy(TrimmedLine, 4, Length(TrimmedLine)))
    else
      ConditionStr := Trim(Copy(TrimmedLine, 7, Length(TrimmedLine)));
    if ConditionStr = '' then
      raise Exception.Create(TranslateErrMissingConditionAfteuntil);
    TranslatedCondition := TranslateExpression(ConditionStr);
    PascalCode.Add('until ' + TranslatedCondition + ';');
    FInRepeatBlock := False; Exit;
  end;

  // 4. FUNKCJE SPECJALNE (PRIORYTETOWE)

  // powtórz_znak / repeat_char
  if (Pos('powtórz_znak(', LowerTrimmedLine) > 0) or
     (Pos('powtorz_znak(', LowerTrimmedLine) > 0) or
     (Pos('repeat_char(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or
       (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxRepeatCharacterFunction);
    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpening);

    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create(TranslateRepeatCharacterFunctionRequiresTwoArguments);
      TranslatedCharArg := TranslateExpression(Trim(ParamPartsList[0]));
      TranslatedCountArg := TranslateExpression(Trim(ParamPartsList[1]));
    finally ParamPartsList.Free;
    end;

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      if Pos(' ', VarName) > 0 then
        VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));
      PascalCode.Add(VarName + ' := StringOfChar(' + TranslatedCharArg + ', ' + TranslatedCountArg + ');');
    end
    else
    PascalCode.Add('StringOfChar(' + TranslatedCharArg + ', ' + TranslatedCountArg + ');');
    Exit;
  end;

  // Insert
  if (AnsiLowerCase(TrimmedLine).StartsWith('wstaw(')) or
     (AnsiLowerCase(TrimmedLine).StartsWith('insert(')) then
  begin
    StartPosInsert := Pos('(', TrimmedLine);
    EndPosInsert := RPos(')', TrimmedLine);
    if (StartPosInsert <= 0) or
       (EndPosInsert <= StartPosInsert) then
         raise Exception.Create(ErrorPrint);
    ParamInsert := Trim(Copy(TrimmedLine, StartPosInsert + 1, EndPosInsert - StartPosInsert - 1));
    ParamPartsInsert := ParamInsert.Split([',']);
    if Length(ParamPartsInsert) <> 3 then
      raise Exception.Create(FunctionInsert);
    InsertSourceIn := TranslateExpression(Trim(ParamPartsInsert[0]));
    InsertTargetIn := TranslateExpression(Trim(ParamPartsInsert[1]));
    InsertIndexIn  := TranslateExpression(Trim(ParamPartsInsert[2]));
    PascalCode.Add('Insert(' + InsertSourceIn + ', ' + InsertTargetIn + ', ' + InsertIndexIn + ');');
    Exit;
  end;

  // Trim (z przypisaniem lub bez)
  if (Pos('=', TrimmedLine) > 0) and ((Pos('przytnij(', LowerTrimmedLine) > 0) or
  (Pos('trim(', LowerTrimmedLine) > 0)) then
  begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then
       VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
     Call := Expression;
     if StartsText('przytnij(', Call) or
        StartsText('trim(', Call) then
     begin
        StartPos := Pos('(', Call);
        EndPos := LastDelimiter(')', Call);
        if (StartPos = 0) or
           (EndPos = 0) then
           raise Exception.Create(TranslateNoBracketsTrimFunction);
        if StartPos > EndPos then
          raise Exception.Create(TranslateIncorrectOrderBracketsTrim);
        ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
        TranslatedParam := TranslateExpression(ParamTrim);
        if VarName <> '' then
          PascalCode.Add(VarName + ' := Trim(' + TranslatedParam + ');')
        else
          PascalCode.Add('Trim(' + TranslatedParam + ');');
        Exit;
     end;
  end;

  // TrimLeft
  if (Pos('=', TrimmedLine) > 0) and ((Pos('przytnij_z_lewa(', LowerTrimmedLine) > 0) or
  (Pos('trim_left(', LowerTrimmedLine) > 0)) then
  begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then
       VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
     Call := Expression;
     if StartsText('przytnij_z_lewa(', Call) or
        StartsText('trim_left(', Call) then
     begin
        StartPos := Pos('(', Call); EndPos := LastDelimiter(')', Call);
        if (StartPos = 0) or (EndPos = 0) then
          raise Exception.Create(TranslateNobracketsTrimleftfunction);
        if StartPos > EndPos then
          raise Exception.Create(IncorrectOrderBracketsTrimLeft);
        ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
        TranslatedParam := TranslateExpression(ParamTrim);
        if VarName <> '' then
          PascalCode.Add(VarName + ' := TrimLeft(' + TranslatedParam + ');')
        else
          PascalCode.Add('TrimLeft(' + TranslatedParam + ');');
        Exit;
     end;
  end;

  // TrimRight
  if (Pos('=', TrimmedLine) > 0) and ((Pos('przytnij_z_prawa(', LowerTrimmedLine) > 0) or
  (Pos('trim_right(', LowerTrimmedLine) > 0)) then
  begin
     VarName := Trim(Copy(TrimmedLine, 1, Pos('=', TrimmedLine) - 1));
     Expression := Trim(Copy(TrimmedLine, Pos('=', TrimmedLine) + 1, MaxInt));
     if Pos(' ', VarName) > 0 then VarName := Trim(Copy(VarName, Pos(' ', VarName) + 1, MaxInt));
     Call := Expression;
     if StartsText('przytnij_z_prawa(', Call) or
        StartsText('trim_right(', Call) then
     begin
        StartPos := Pos('(', Call); EndPos := LastDelimiter(')', Call);
        if (StartPos = 0) or (EndPos = 0) then
          raise Exception.Create(TranslateNoBracketsTrimRightFunction);
        if StartPos > EndPos then
          raise Exception.Create(TranslateIncorrectOrderBracketsTrimRight);
        ParamTrim := Trim(Copy(Call, StartPos + 1, EndPos - StartPos - 1));
        TranslatedParam := TranslateExpression(ParamTrim);
        if VarName <> '' then
          PascalCode.Add(VarName + ' := TrimRight(' + TranslatedParam + ');')
        else
          PascalCode.Add('TrimRight(' + TranslatedParam + ');');
        Exit;
     end;
  end;

  // Pascal Line (wstawka)
  if AnsiStartsText('pascal_line', TrimmedLine) or
     AnsiStartsText('pascal_linia{', TrimmedLine) then
  begin
    if AnsiStartsText('pascal_line', TrimmedLine) then
      CodePascal := Trim(Copy(TrimmedLine, Length('pascal_line') + 1, MaxInt))
    else
      CodePascal := Trim(Copy(TrimmedLine, Length('pascal_linia{') + 1, MaxInt));
    if CodePascal.StartsWith('{') then
      CodePascal := CodePascal.Substring(1).Trim;
    if CodePascal.EndsWith('}') then
      CodePascal := CodePascal.Substring(0, CodePascal.Length - 1).Trim;
    PascalCode.Add(CodePascal);
    Exit;
  end;

  // Bloki kodu (Pascal / ASM)
  if not InPurePascalBlock then
  begin
    if AnsiStartsText('pascal {', TrimmedLine) or
       AnsiStartsText('pascal{', TrimmedLine) then
       begin
         InPurePascalBlock := True;
         Exit;
       end;

    if AnsiStartsText('asm {', TrimmedLine) or
       AnsiStartsText('asm{', TrimmedLine) then
          begin
            InPurePascalBlock := True; NeedsAsmIntel := True;
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
      PascalCode.Add(TrimmedLine); Exit;
    end;

  // Delete
  if (Pos('usuń(', LowerTrimmedLine) > 0) or
     (Pos('delete(', LowerTrimmedLine) > 0) or
     (Pos('usun(', LowerTrimmedLine) > 0) then
  begin
      StartPosDelete := Pos('(', TrimmedLine);
      EndPosDelete := RPos(')', TrimmedLine);
      if (StartPosDelete = 0) or
         (EndPosDelete = 0) then
           raise Exception.Create(TranslateIncorrectSyntaxRemovefunction);
      ParamDelete := Trim(Copy(TrimmedLine, StartPosDelete + 1, EndPosDelete - StartPosDelete - 1));
      ParamPartsDelete := ParamDelete.Split([',']);
      if Length(ParamPartsDelete) <> 3 then
        raise Exception.Create(TranslateDeleteFunctionRequires);
      StringExprDelete := TranslateExpression(Trim(ParamPartsDelete[0]));
      IndexExprDelete := TranslateExpression(Trim(ParamPartsDelete[1]));
      CountExprDelete := TranslateExpression(Trim(ParamPartsDelete[2]));

      AssignPos := Pos('=', TrimmedLine);
      if (AssignPos > 0) and (AssignPos < StartPosDelete) then
      begin
          VarName := Trim(Copy(TrimmedLine, 1, AssignPos - 1));
          if Pos(' ', VarName) > 0 then VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));
          PascalCode.Add(VarName + ' := ' + StringExprDelete + ';');
          PascalCode.Add('Delete(' + VarName + ', ' + IndexExprDelete + ', ' + CountExprDelete + ');');
      end
      else PascalCode.Add('Delete(' + StringExprDelete + ', ' + IndexExprDelete + ', ' + CountExprDelete + ');');
      Exit;
  end;

  // UpperCase
  if (Pos('duże_litery(', LowerTrimmedLine) > 0) or
     (Pos('duze_litery(', LowerTrimmedLine) > 0) or
     (Pos('upper_case(', LowerTrimmedLine) > 0) then
  begin
    StartPosUpper := Pos('(', TrimmedLine);
    EndPosUpper := RPos(')', TrimmedLine);
    if (StartPosUpper = 0) or
       (EndPosUpper = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxUppercaseFunction);
    if StartPosUpper > EndPosUpper then
       raise Exception.Create(TranslateIncorrectSyntaxUppercaseFunction);
    ParamUpper := Trim(Copy(TrimmedLine, StartPosUpper + 1, EndPosUpper - StartPosUpper - 1));
    TranslatedParamUpper := TranslateExpression(ParamUpper);
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2); VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := UpperCase(' + TranslatedParamUpper + ');');
    end
    else PascalCode.Add('UpperCase(' + TranslatedParamUpper + ');');
    Exit;
  end;

  // LowerCase
  if (Pos('małe_litery(', LowerTrimmedLine) > 0) or
     (Pos('male_litery(', LowerTrimmedLine) > 0) or
     (Pos('lower_case(', LowerTrimmedLine) > 0) then
  begin
    StartPosLower := Pos('(', TrimmedLine);
    EndPosLower := RPos(')', TrimmedLine);
    if (StartPosLower = 0) or (EndPosLower = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxLowercaseFunction);
    if StartPosLower > EndPosLower then
      raise Exception.Create(TranslateLowercaseFunctionSyntaxError);
    ParamLower := Trim(Copy(TrimmedLine, StartPosLower + 1, EndPosLower - StartPosLower - 1));
    TranslatedParamLower := TranslateExpression(ParamLower);
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := LowerCase(' + TranslatedParamLower + ');');
    end
    else PascalCode.Add('LowerCase(' + TranslatedParamLower + ');');
    Exit;
  end;

  // CompareStr
  if (Pos('porównaj_tekst(', LowerTrimmedLine) > 0) or
     (Pos('porownaj_tekst(', LowerTrimmedLine) > 0) or
     (Pos('compare_text(', LowerTrimmedLine) > 0) then
  begin
    StartPosCompareStr := Pos('(', TrimmedLine);
    EndPosCompareStr := RPos(')', TrimmedLine);
    if (StartPosCompareStr = 0) or
       (EndPosCompareStr = 0) then
      raise
      Exception.Create(TranslateIncorrectSyntaxCompareTextFunction);
    if StartPosCompareStr > EndPosCompareStr then
      raise
      Exception.Create(TranslateIncorrectSyntaxCompareTextFunction);
    ParamCompareStr := Trim(Copy(TrimmedLine, StartPosCompareStr + 1, EndPosCompareStr - StartPosCompareStr - 1));
    ParamPartsCompareStr := ParamCompareStr.Split([',']);
    if Length(ParamPartsCompareStr) <> 2 then
      raise
      Exception.Create(TranslateCompareTextFunctionRequiresTwoArguments);
    TranslatedS1Arg := TranslateExpression(Trim(ParamPartsCompareStr[0]));
    TranslatedS2Arg := TranslateExpression(Trim(ParamPartsCompareStr[1]));
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2); VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := CompareStr(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    end
    else PascalCode.Add('CompareStr(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    Exit;
  end;

  // ReplaceStr
  // Obsługa funkcji zamień_tekst / zamien_tekst / replace_text -> ReplaceStr
  if (Pos('zamień_tekst(', LowerTrimmedLine) > 0) or
     (Pos('zamien_tekst(', LowerTrimmedLine) > 0) or
     (Pos('replace_text(', LowerTrimmedLine) > 0) then
  begin
    ZamienTekst_StartPos := Pos('(', TrimmedLine);
    ZamienTekst_EndPos := RPos(')', TrimmedLine);

    if (ZamienTekst_StartPos = 0) or (ZamienTekst_EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxReplaceTextFunction);
    ZamienTekst_Param := Trim(Copy(TrimmedLine, ZamienTekst_StartPos + 1, ZamienTekst_EndPos - ZamienTekst_StartPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ZamienTekst_Param, ParamPartsList);

      if ParamPartsList.Count <> 3 then
        raise Exception.Create(TranslateReplaceTextFunctionRequiresThreeArguments);

      // Tłumaczenie argumentów
      ZamienTekst_TextArg := TranslateExpression(Trim(ParamPartsList[0]));
      ZamienTekst_FromArg := TranslateExpression(Trim(ParamPartsList[1]));
      ZamienTekst_ToArg   := TranslateExpression(Trim(ParamPartsList[2]));
    finally
      ParamPartsList.Free;
    end;
    if Pos('=', TrimmedLine) > 0 then
    begin
      ZamienTekst_AssignParts := TrimmedLine.Split(['='], 2);
      ZamienTekst_ResultVar := Trim(ZamienTekst_AssignParts[0]);
      // np. "tekst s" -> "s"
      if Pos(' ', ZamienTekst_ResultVar) > 0 then
         ZamienTekst_ResultVar := Trim(Copy(ZamienTekst_ResultVar, RPos(' ', ZamienTekst_ResultVar) + 1, MaxInt));

      PascalCode.Add(ZamienTekst_ResultVar + ' := ReplaceStr(' + ZamienTekst_TextArg + ', ' + ZamienTekst_FromArg + ', ' + ZamienTekst_ToArg + ');');
    end
    else
    begin
      // Wywołanie bez przypisania
      PascalCode.Add('ReplaceStr(' + ZamienTekst_TextArg + ', ' + ZamienTekst_FromArg + ', ' + ZamienTekst_ToArg + ');');
    end;
    Exit;
  end;


  // UTF8UpperCase (duże_litery_ansi)
  // Obsługa duże_litery_ansi / utf8_upper_case -> WideUpperCase (SysUtils)
    // Zmieniamy na standardowe funkcje FPC, aby nie wymagać biblioteki LazUTF8
    if (Pos('duże_litery_ansi(', LowerTrimmedLine) > 0) or
       (Pos('duze_litery_ansi(', LowerTrimmedLine) > 0) or
       (Pos('utf8_upper_case(', LowerTrimmedLine) > 0) then
    begin
      StartPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine);

      if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create(TranslateIncorrectSyntaxUtf8UppercaseAnsiFunction);

      if StartPos > EndPos then
        raise Exception.Create(TranslateClosingBracketBeforeOpening);

      ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
      TranslatedParam := TranslateExpression(ParamStr);

      // FORMULA: UTF8Encode(WideUpperCase(UTF8Decode( ... )))
      // To pozwala obsłużyć polskie znaki używając tylko modułu SysUtils/System.
      if Pos('=', TrimmedLine) > 0 then
      begin
        Parts := TrimmedLine.Split(['='], 2);
        VarName := Trim(Parts[0]);
        if Pos(' ', VarName) > 0 then
           VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));

        PascalCode.Add(VarName + ' := UTF8Encode(WideUpperCase(UTF8Decode(' + TranslatedParam + ')));');
      end
      else
      begin
        PascalCode.Add('UTF8Encode(WideUpperCase(UTF8Decode(' + TranslatedParam + ')));');
      end;
      Exit;
    end;

    // Obsługa małe_litery_ansi / lower_case -> WideLowerCase (SysUtils)
  if (Pos('małe_litery_ansi(', LowerTrimmedLine) > 0) or
     (Pos('male_litery_ansi(', LowerTrimmedLine) > 0) or
     (Pos('utf8_lower_case(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxUtf8LowerCaseFunction);

    ParamLower := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    TranslatedParamLower := TranslateExpression(ParamLower);

    // FORMULA: UTF8Encode(WideLowerCase(UTF8Decode( ... )))
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      if Pos(' ', VarName) > 0 then
         VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));

      PascalCode.Add(VarName + ' := UTF8Encode(WideLowerCase(UTF8Decode(' + TranslatedParamLower + ')));');
    end
    else
    begin
      PascalCode.Add('UTF8Encode(WideLowerCase(UTF8Decode(' + TranslatedParamLower + ')));');
    end;
    Exit;
  end;


  // 5. OBSŁUGA PLIKÓW
  if AnsiStartsText('przypisz_plik(', TrimmedLine) or
     AnsiStartsText('assign_file(', TrimmedLine) then
  begin
    AssignStartPos := Pos('(', TrimmedLine); AssignEndPos := RPos(')', TrimmedLine);
    if (AssignStartPos = 0) or (AssignEndPos = 0) then raise Exception.Create(TranslateIncorrectSyntaxAssignFileFunction);
    if AssignStartPos > AssignEndPos then raise Exception.Create(TranslateIncorrectSyntaxAssignFileFunctionExpected);
    AssignParamStr := Copy(TrimmedLine, AssignStartPos + 1, AssignEndPos - AssignStartPos - 1);
    AssignParams := TStringList.Create;
    try
      SplitStringByChar(AssignParamStr, ',', AssignParams);
      if AssignParams.Count <> 2 then raise Exception.Create(TranslateAssignFileFunctionIncorrectNumberOfArguments);
      if (Trim(AssignParams[0]) = '') or (Trim(AssignParams[1]) = '') then raise Exception.Create(TranslateAssignFileFunctionArgumentsCannotBeEmpty);
      AssignTranslatedParam1 := TranslateExpression(Trim(AssignParams[0]));
      AssignTranslatedParam2 := TranslateExpression(Trim(AssignParams[1]));
      PascalCode.Add('AssignFile(' + AssignTranslatedParam1 + ', ' + AssignTranslatedParam2 + ');');
      Exit;
    finally AssignParams.Free; end;
  end;

  if AnsiStartsText('otwórz_do_odczytu(', TrimmedLine) or
     AnsiStartsText('otworz_do_odczytu(', TrimmedLine) or
     AnsiStartsText('open_read(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxLoadFileFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('Reset(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('otwórz_do_zapisu(', TrimmedLine) or
     AnsiStartsText('open_save(', TrimmedLine) or
     AnsiStartsText('otworz_do_zapisu(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxOpenSaveFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('Rewrite(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('otwórz_do_dopisywania(', TrimmedLine) or
     AnsiStartsText('dopisz(', TrimmedLine) or
     AnsiStartsText('append(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then raise Exception.Create(TranslateIncorrectSyntaxAppendFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('Append(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('zamknij_plik(', TrimmedLine) or
     AnsiStartsText('close_file(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxCloseFileFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('CloseFile(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('koniec_pliku(', TrimmedLine) or
     AnsiStartsText('eof(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create('TranslateIncorrectSyntaxEofFunction');
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('Eof(' + TranslateExpression(Param) + ');');
    Exit;
  end;
  {
  if AnsiStartsText('czytaj_linie(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then raise Exception.Create('Błędna składnia czytaj_linie(...)');
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('ReadLn(' + TranslateExpression(Param) + ');');
    Exit;
  end;
  }

  if AnsiStartsText('czy_istnieje_plik(', TrimmedLine) or
     AnsiStartsText('file_exists(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxFileExistsFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('FileExists(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  //szukaj(var f: TextFile; pos: integer);
  {if (AnsiStartsText('czytaj_od_pozycji_wskaźnika(', TrimmedLine)) or
     (AnsiStartsText('read_from_pointer_position(', TrimmedLine)) or
     (AnsiStartsText('czytaj_pw(', TrimmedLine)) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxFileExistsFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('Seek(' + TranslateExpression(Param) + ');');
    Exit;
  end;
  }

    //ustawia wskaźnik pliku.
    if (Pos('czytaj_od_pozycji_wskaźnika(', LowerTrimmedLine) > 0) or
     (Pos('czytaj_od_pozycji_wskaznika(', LowerTrimmedLine) > 0) or
     (Pos('read_from_pointer_position(', LowerTrimmedLine) > 0) or
     (Pos('czytaj_pw(', LowerTrimmedLine) > 0) or
     (Pos('seek(', LowerTrimmedLine) > 0)then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);


    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create('Błąd składni: Brak nawiasów w funkcji czytaj_od_pozycji_wskaźnika / czytaj_pw / read_from_pointer_position, seek');

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpening);
    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));


    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create('Błąd tłumaczenia: Funkcja czytaj_od_pozycji_wskaźnika / czytaj_pw / seek / read_from_pointer_position / wymaga dokładnie 2 argumentów (zmienna plikowa, pozycja). Znaleziono: ' + IntToStr(ParamPartsList.Count));
      TranslatedS1Arg := TranslateExpression(Trim(ParamPartsList[0]));
      TranslatedS2Arg := TranslateExpression(Trim(ParamPartsList[1]));
      PascalCode.Add('Seek(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    finally
      ParamPartsList.Free;
    end;
    Exit;
  end;



  //6. INNE FUNKCJE SYSTEMOWE
  if AnsiStartsText('zmień_katalog(', TrimmedLine) or
     AnsiStartsText('zmien_katalog(', TrimmedLine) or
     AnsiStartsText('change_dir(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxChangeDirFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('ChDir(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('utwórz_katalog(', TrimmedLine) or
     AnsiStartsText('utworz_katalog(', TrimmedLine) or
     AnsiStartsText('create_dir(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxCreateDirFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('MkDir(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('usuń_katalog(', TrimmedLine) or
     AnsiStartsText('usun_katalog(', TrimmedLine) or
     AnsiStartsText('remove_dir(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxRemoveDirFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('RmDir(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('pobierz_katalog_bieżący(', TrimmedLine) or
     AnsiStartsText('pobierz_katalog_biezacy(', TrimmedLine) or
     AnsiStartsText('get_current_dir(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxGetCurrentDirFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('GetCurrentDir(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if AnsiStartsText('czy_istnieje_katalog(', TrimmedLine) or
     AnsiStartsText('directory_exists(', TrimmedLine) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create(TranslateIncorrectSyntaxDirectoryExistsFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    PascalCode.Add('DirectoryExists(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if (Pos('długość(', LowerCase(TrimmedLine)) > 0) or
     (Pos('dlugosc(', LowerCase(TrimmedLine)) > 0) or
     (Pos('length(', LowerCase(TrimmedLine)) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := Pos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
       raise Exception.Create(TranslateIncorrectSyntaxLengthFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2); VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := Length(' + TranslateExpression(Param) + ');');
    end
    else PascalCode.Add('Length(' + TranslateExpression(Param) + ');');
    Exit;
  end;

  if (Pos('kopiuj(', LowerTrimmedLine) > 0) or
     (Pos('copy(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
        raise Exception.Create(TranslateIncorrectSyntaxCopyFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(Param, ParamPartsList);
      if ParamPartsList.Count <> 3 then
        raise Exception.Create(TranslateCopyFunctionRequiresThreeArguments);
      SExpr := TranslateExpression(Trim(ParamPartsList[0]));
      StartExpr := TranslateExpression(Trim(ParamPartsList[1]));
      CountExpr := TranslateExpression(Trim(ParamPartsList[2]));
    finally ParamPartsList.Free; end;

    if Pos('=', TrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2); VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := Copy(' + SExpr + ', ' + StartExpr + ', ' + CountExpr + ');');
    end
    else PascalCode.Add('Copy(' + SExpr + ', ' + StartExpr + ', ' + CountExpr + ');');
    Exit;
  end;

  if (Pos('szukaj(', LowerTrimmedLine) > 0) or
     (Pos('search(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine); EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateIncorrectSyntaxSearchFunction);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(Param, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create(TranslateSearchFunctionRequiresTwoArguments);
      SubstringExpr := TranslateExpression(Trim(ParamPartsList[0]));
      SExpr := TranslateExpression(Trim(ParamPartsList[1]));
    finally ParamPartsList.Free; end;

    if Pos('=', LowerTrimmedLine) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2); VarName := Trim(Parts[0]);
      PascalCode.Add(VarName + ' := Pos(' + SubstringExpr + ', ' + SExpr + ');');
    end
    else PascalCode.Add('Pos(' + SubstringExpr + ', ' + SExpr + ');');
    Exit;
  end;

  // Obsługa PozycjaKursora / GotoXY (cursor_position)
  if (Pos('pozycja_kursora(', LowerTrimmedLine) > 0) or
     (Pos('cursor_position(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 1. Walidacja nawiasów
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingBracketsCursorPositionFunction);

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpening);
    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

    //  Walidacja argumentów musi być x i y
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create(TranslateCursorPositionFunctionRequiresTwoArguments + IntToStr(ParamPartsList.Count));
      TranslatedS1Arg := TranslateExpression(Trim(ParamPartsList[0])); // X
      TranslatedS2Arg := TranslateExpression(Trim(ParamPartsList[1])); // Y
      PascalCode.Add('GotoXY(' + TranslatedS1Arg + ', ' + TranslatedS2Arg + ');');
    finally
      ParamPartsList.Free;
    end;
    Exit;
  end;

    // Obsługa KolorTekstu / TextColor  poprawka 17.04.2026
    if (LowerCase(TrimmedLine).StartsWith('kolor_tekstu(')) or
       (LowerCase(TrimmedLine).StartsWith('text_color(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine);

      if (OpenPos > 0) and (EndPos > OpenPos) then
      begin
        Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));
        Value := TranslateExpression(Value);

        Value := StringReplace(Value, '''', '', [rfReplaceAll]);
        Value := StringReplace(Value, '"', '', [rfReplaceAll]);

        //PascalCode.Add('TextColor(' + TranslateExpression(Value) + ');');
        PascalCode.Add('TextColor(' + Value + ');');
        Exit;
      end;
    end;

    // Obsługa tło_tekstu / text_background  poprawka 17.04.2026
    if (LowerCase(TrimmedLine).StartsWith('tło_tekstu(')) or
       (LowerCase(TrimmedLine).StartsWith('tlo_tekstu(')) or
       (LowerCase(TrimmedLine).StartsWith('text_background(')) then
    begin
      OpenPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine);

      if (OpenPos > 0) and (EndPos > OpenPos) then
      begin
        Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));
        Value := TranslateExpression(Value);

        Value := StringReplace(Value, '''', '', [rfReplaceAll]);
        Value := StringReplace(Value, '"', '', [rfReplaceAll]);

        //PascalCode.Add('TextBackground(' + TranslateExpression(Value) + ');');
         PascalCode.Add('TextBackground(' + Value + ');');

        Exit;
      end;
    end;

    // Obsługa: czytaj_klawisz / read_key (jako samodzielna instrukcja)
      if (LowerCase(TrimmedLine).StartsWith('czytaj_klawisz')) or
         (LowerCase(TrimmedLine).StartsWith('read_key')) then
      begin
        OpenPos := Pos('(', TrimmedLine);

        // Przypadek bez nawiasów: czytaj_klawisz
        if OpenPos = 0 then
        begin
          PascalCode.Add('ReadKey;');
        end
        else
        begin
          EndPos := LastDelimiter(')', TrimmedLine);
          if EndPos = 0 then
            raise Exception.Create(TranslateMissingClosingBracketReadKeyFunction);

          if EndPos <= OpenPos then
            raise Exception.Create(TranslateIncorrectOrderOfBrackets);

          Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

          if Value = '' then
            PascalCode.Add('ReadKey;')
          else
            PascalCode.Add('ReadKey(' + TranslateExpression(Value) + ');');
        end;
        Exit;
      end;

      // Obsługa: zmienna = czytaj_klawisz (jako przypisanie)
      if (Pos('czytaj_klawisz', LowerCase(TrimmedLine)) > 0) or
         (Pos('read_key', LowerCase(TrimmedLine)) > 0) then
      begin
        // Sprawdzamy czy to faktycznie przypisanie
        if Pos('=', TrimmedLine) = 0 then
          raise Exception.Create(TranslateAssignmentExpectedReadKey);

        Parts := TrimmedLine.Split(['='], 2);

        // Zabezpieczenie przed błędem podziału
        if Length(Parts) < 2 then
          raise Exception.Create(TranslateIncompleteAssignment);

        VarName := Trim(Parts[0]);
        Value := Trim(Parts[1]);

        // Sprawdź, czy po prawej stronie faktycznie jest funkcja (a nie np. komentarz z nazwą)
        if (LowerCase(Value) <> 'czytaj_klawisz') and (LowerCase(Value) <> 'read_key') and
           (Pos('czytaj_klawisz(', LowerCase(Value)) = 0) and (Pos('read_key(', LowerCase(Value)) = 0) then
        begin

        end
        else
        begin
          // Obsługa deklaracji typu: "znak k = czytaj_klawisz"
          if Pos(' ', VarName) > 0 then
          begin
            Parts := VarName.Split([' '], 2);
            if Length(Parts) >= 2 then
            begin
              VarType := Parts[0];
              VarName := Parts[1];
              AddVariable(VarName, VarType, False);
            end;
          end;

          // Sprawdzenie czy funkcja ma argumenty w przypisaniu (rzadkie dla ReadKey, ale możliwe w Twoim dialekcie)
          if Pos('(', Value) > 0 then
          begin
             OpenPos := Pos('(', Value);
             EndPos := LastDelimiter(')', Value);
             if (EndPos > OpenPos) then
             begin
                Value := Trim(Copy(Value, OpenPos + 1, EndPos - OpenPos - 1));
                if Value <> '' then
                   PascalCode.Add(VarName + ' := ReadKey(' + TranslateExpression(Value) + ');')
                else
                   PascalCode.Add(VarName + ' := ReadKey;');
             end
             else
                raise Exception.Create(TranslateParenthesesErrorReadKeyFunction);
          end
          else
          begin
             PascalCode.Add(VarName + ' := ReadKey;');
          end;
          Exit;
        end;
      end;


  // Obsługa funkcji pisz_linie / print_line -> Writeln
  if (LowerCase(TrimmedLine).StartsWith('pisz_linie(')) or
     (LowerCase(TrimmedLine).StartsWith('print_line(')) then
  begin
    // 1. Szukamy nawiasów
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 2. Walidacja błędów składni
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingBracketsPiszLinieFunction);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);

    // Używam try..except na wypadek błędu przy kopiowaniu pamięci (rzadkie, ale możliwe)
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingArgumentsWriteLines + E.Message);
    end;
    Exit;
  end;


    // Obsługa funkcji pisz / print -> Write
  if (LowerCase(TrimmedLine).StartsWith('pisz(')) or
     (LowerCase(TrimmedLine).StartsWith('print(')) then
  begin
    // 1. Szukamy nawiasów
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 2. Walidacja błędów składni
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingBracketsWritePrintFunction);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingArgumentsWriteFunction + E.Message);
    end;
    Exit;
  end;

      // Obsługa funkcji piszf / print -> Write
  if (LowerCase(TrimmedLine).StartsWith('piszf(')) or
     (LowerCase(TrimmedLine).StartsWith('printf(')) then
  begin
    // 1. Szukamy nawiasów
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 2. Walidacja błędów składni
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingBracketsWritePrintFunction);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      PascalCode.Add('WriteLnF(' + TranslateExpression(Value) + ');');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingArgumentsWriteFunction + E.Message);
    end;
    Exit;
  end;


  // Obsługa funkcji losowy / random -> Random
  if (Pos('losowy(', LowerTrimmedLine) > 0) or
     (Pos('random(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingParenthesesRandomFunction);

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    Param := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));
    TranslatedParam := TranslateExpression(Param);
    AssignPos := Pos('=', TrimmedLine);
    if (AssignPos > 0) and (AssignPos < StartPos) then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      if Pos(' ', VarName) > 0 then
         VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));
      if TranslatedParam = '' then
         PascalCode.Add(VarName + ' := Random;') // Wersja bez argumentu (0.0 do 1.0)
      else
         PascalCode.Add(VarName + ' := Random(' + TranslatedParam + ');');
    end
    else
    begin
      // Wywołanie samodzielne (bez przypisania)
      if TranslatedParam = '' then
         PascalCode.Add('Random;')
      else
         PascalCode.Add('Random(' + TranslatedParam + ');');
    end;

    Exit;
  end;

  // Obsługa funkcji losuj / randomize
    // ZMIANA: Używamy StartsWith, żeby wykryć też błędne "losuj()"
    if (LowerCase(TrimmedLine).StartsWith('losuj')) or
       (LowerCase(TrimmedLine).StartsWith('randomize')) then
    begin
      // 1. Sprawdzamy, czy są nawiasy (BŁĄD)
      if (Pos('(', TrimmedLine) > 0) or (Pos(')', TrimmedLine) > 0) then
      begin
         // Sprawdzamy, czy to na pewno ta funkcja (a nie np. losuj_liczbe(x))
         // Błąd rzucamy tylko, jeśli po "losuj" jest nawias lub spacja i nawias
         if (Pos('losuj(', LowerCase(TrimmedLine)) > 0) or
            (Pos('losuj (', LowerCase(TrimmedLine)) > 0) or
            (Pos('randomize(', LowerCase(TrimmedLine)) > 0) or
            (Pos('randomize (', LowerCase(TrimmedLine)) > 0) then
         begin
           raise Exception.Create(TranslateRandomiseFunctionDoesNotAcceptBrackets);
         end;
      end;

      // 2. Sprawdzamy, czy to poprawne wywołanie (dokładnie samo słowo)
      if (LowerCase(TrimmedLine) = 'losuj') or
         (LowerCase(TrimmedLine) = 'randomize') then
      begin
        PascalCode.Add('Randomize;');
        Exit;
      end;
    end;

      //STRINGLIST OBJECT

  if (LowerCase(TrimmedLine).StartsWith('twórz_listę_tekstów(')) or
  (LowerCase(TrimmedLine).StartsWith('tworz_liste_tekstow(')) or
  (LowerCase(TrimmedLine).StartsWith('create_string_list(')) then
  begin
    // 1. Szukamy nawiasów
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 2. Walidacja błędów składni
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create('Błąd: Brak nawiasów w funkcji twórz_listę_tekstów / tworz_liste_tekstow / create_string_list ');

    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      PascalCode.Add(TranslateExpression(Value) + ' := TStringList.Create;');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingArgumentsWriteFunction + E.Message);
    end;
    Exit;
  end;

  // DODAWANIE DO STRINGLIST
  if (Pos('dodaj_do_listy(', LowerTrimmedLine) > 0) or
     (Pos('add_to_list(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 1. Walidacja nawiasów
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create('Błąd: Brak nawiasów w funkcji dodaj_do_listy / add_to_list');

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpening);
    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

    //  Walidacja argumentów musi być x i y
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create(TranslateCursorPositionFunctionRequiresTwoArguments + IntToStr(ParamPartsList.Count));
      TranslatedS1Arg := TranslateExpression(Trim(ParamPartsList[0])); // X
      TranslatedS2Arg := TranslateExpression(Trim(ParamPartsList[1])); // Y
      PascalCode.Add(TranslatedS1Arg + '.Add(''' + TranslatedS2Arg + ''');');
    finally
      ParamPartsList.Free;
    end;
    Exit;
  end;

    // Ilosc elementów w STRINGLIST
  if (Pos('count(', LowerTrimmedLine) > 0) or
     (Pos('ilość(', LowerTrimmedLine) > 0) or
     (Pos('ilosc(', LowerTrimmedLine) > 0) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    // 1. Walidacja nawiasów
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create('Błąd: Brak nawiasów w funkcji ilość / ilosc / count');

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpening);
    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 1 then
        raise Exception.Create(TranslateCursorPositionFunctionRequiresTwoArguments + IntToStr(ParamPartsList.Count));
      TranslatedS1Arg := TranslateExpression(Trim(ParamPartsList[0])); // X
      PascalCode.Add(TranslatedS1Arg + '.Count');
    finally
      ParamPartsList.Free;
    end;
    Exit;
  end;



  // Wypisanie pojedynczo elementow z listy STRINGLIST
  //Writeln(h.Strings[1]);
  if TryTranslateGeneric(Line, PascalCode,
    ['teksty', 'strings'],
    2,
    //'%0:s.Strings[%1:s]',
    '%0.Strings[%1]',
    TranslateTextsStringsRequiresParentheses,
    TranslateTextsStringsRequiresTwoArguments) then
  Exit;

  // Wstawianie na konkretną pozycję: List.Insert(2, 'nowy tekst');
  if TryTranslateGeneric(Line, PascalCode,
    ['wstaw_do_listy', 'insert_to_list'],
    3,
    //'%0:s.Insert(%1:s, %2:s)',
    '%0.Insert(%1, %2)',
    TranslateInsertToListRequiresParentheses,
    TranslateInsertToListRequiresThreeArguments) then
  Exit;


  //Usuwanie elementu po indeksie: List.Delete(3);
  if TryTranslateGeneric(Line, PascalCode,
    ['usuń_z_listy', 'usun_z_listy', 'delete_from_list'], // Aliasy
    2,                                                 // 2 argumenty: lista i indeks
    //'%s.Delete(%s)',                                   // SZABLON (lista.Delete(indeks))
    '%0.Delete(%1)',
    TranslateRemoveFromListRequiresParentheses,
    TranslateDeleteFromToListRequiresListAndIndex) then
  Exit;

  //Usuwanie elementu po wartości: List.Delete(List.IndexOf('tekst'));
  if TryTranslateGeneric(Line, PascalCode,
    ['usuń_z_listy_id', 'usun_z_listy_id', 'delete_from_list_id'],
    2,
    //'%0:s.Delete(%0:s.IndexOf(%1:s))',
    '%0.Delete(%0.IndexOf(%1))',
    TranslateDeleteFromToListIdRequiresParentheses,
    TranslateProvideListNameAndValueToRemove) then
  Exit;

  //Czyszczenie całej listy: List.Clear;
  if TryTranslateGeneric(Line, PascalCode,
    ['wyczyść_listę', 'wyczysc_liste', 'clear_list'],
    1,
    //'%s.Clear',
    '%0.Clear',
     TranslateClearListRequiresParentheses,
     TranslateClearListRequiresOneArgument)then
  Exit;

  //ustawienie elementu listy:
  if TryTranslateGeneric(Line, PascalCode,
    ['ustaw_tekst', 'set_text'],
    3,
    //'%0:s[%1:s] := %2:s',
    '%0[%1] := %2',
     TranslateSetTextRequiresParentheses,
     TranslateSetTextRequiresThreeArguments) then
  Exit;
  //21.12.2025
  //List.Sorted := True;
    if TryTranslateGeneric(Line, PascalCode,
    ['sortuj_liste', 'sortuj_listę', 'sort_list'],
    2,
    //'%0:s.Sorted := %1:s',
     '%0.Sorted := %1',
     'BŁĄD SKŁADNI: Funkcja sortuj_liste / sort_list wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja sortuj_liste / sort_list wymaga 2 argumentów (lista, prawda lub falsz).') then
  Exit;

   //Ręczne sortowanie: List.Sort;
   if TryTranslateGeneric(Line, PascalCode,
    ['ręcznie_sortuj_listę', 'recznie_sortuj_liste', 'manually_sort_list'],
    1,
    //'%0:s.Sort',
    '%0.Sort',
     'BŁĄD SKŁADNI: Funkcja ręcznie_sortuj_listę / manually_sort_list wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja ręcznie_sortuj_listę / manually_sort_list wymaga 1 argumentu (lista).') then
  Exit;

   //Znajdowanie indeksu tekstu: i := List.IndexOf('szukany');
   if TryTranslateGeneric(Line, PascalCode,
    ['znajdź_indeks_lista', 'znajdz_indeks_lista', 'find_index_list'],
    3,
   // '%0:s := %1:s.IndexOf(%2:s)',
    '%0 := %1.IndexOf(%2)',
     'BŁĄD SKŁADNI: Funkcja znajdź_indeks_lista / find_index_list wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja znajdź_indeks_lista / find_index_list wymaga 3 argumentów (zmienna, lista, "wartosc").') then
  Exit;

   //List.Find('tekst', i)
   if TryTranslateGeneric(Line, PascalCode,
    ['szukaj_wartość_w_liście', 'szukaj_wartosc_w_liscie', 'search_value_in_list'],
    3,
    //'%0:s.Find(%1:s,%2:s)',
    '%0.Find(%1,%2)',
     'BŁĄD SKŁADNI: Funkcja szukaj_wartość_w_liście / search_value_in_list wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja szukaj_wartość_w_liście / search_value_in_list wymaga 3 argumentów (lista, ''wartosc szukana'', zmienna integer).') then
  Exit;

   //Wczytanie z pliku: List.LoadFromFile('plik.txt');
   if TryTranslateGeneric(Line, PascalCode,
    ['załaduj_z_pliku', 'zaladuj_z_pliku', 'load_from_file'],
    2,
    //'%0:s.LoadFromFile(%1:s)',
     '%0.LoadFromFile(%1)',
     'BŁĄD SKŁADNI: Funkcja załaduj_z_pliku / load_from_file wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja załaduj_z_pliku / load_from_file wymaga 2 argumentów (lista, ''nazwa pliku z rozszerzeniem'').') then
  Exit;

  //Zapisywanie z listy do pliku: List.SaveToFile('plik.txt');
   if TryTranslateGeneric(Line, PascalCode,
    ['zapisz_do_pliku', 'save_to_file'],
    2,
     '%0.SaveToFile(%1)',
     'BŁĄD SKŁADNI: Funkcja zapisz_do_pliku / save_to_file wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja zapisz_do_pliku / save_to_file wymaga 2 argumentów (lista, ''nazwa pliku z rozszerzeniem'').') then
  Exit;


  //oznacza, że porównywanie tekstów w TStringList będzie rozróżniać wielkość liter.
  //List.CaseSensitive := True;
   if TryTranslateGeneric(Line, PascalCode,
    ['uwzględnia_wielkość_liter','uwzglednia_wielkosc_liter', 'case_sensitive'],
    2,
     '%0.CaseSensitive := %1',
     'BŁĄD SKŁADNI: Funkcja uwzględnia_wielkość_liter / uwzglednia_wielkosc_liter / case_sensitive wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja uwzględnia_wielkość_liter / uwzglednia_wielkosc_liter / case_sensitive wymaga 2 argumentów (lista, ''Prawda / Falsz'').') then
  Exit;

  //co zrobić z duplikatami w StringList
  {
    List.Duplicates := dupIgnore;   // ignoruj
    List.Duplicates := dupAccept;   // akceptuj
    List.Duplicates := dupError;    // błąd
  }
  //List.Duplicates := dupIgnore;   // ignoruj
   if TryTranslateGeneric(Line, PascalCode,
    ['ignoruj_duplikaty','ignore_duplicates'],
    1,
     '%0.Duplicates := dupIgnore',
     'BŁĄD SKŁADNI: Funkcja igrnoruj_duplikaty / ignore_duplicates wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja igrnoruj_duplikaty / ignore_duplicates wymaga 1 argumentu (Nazwa listy).') then
  Exit;

  // List.Duplicates := dupAccept;   // akceptuj
   if TryTranslateGeneric(Line, PascalCode,
    ['akceptuj_duplikaty','accept_duplicates'],
    1,
     '%0.Duplicates := dupAccept',
     'BŁĄD SKŁADNI: Funkcja akceptuj_duplikaty / accept_duplicates  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja akceptuj_duplikaty / accept_duplicates wymaga 1 argumentu (Nazwa listy).') then
  Exit;

   //List.Duplicates := dupError;    // błąd
   if TryTranslateGeneric(Line, PascalCode,
    ['błąd_duplikaty','blad_duplikaty','error_duplicates'],
    1,
     '%0.Duplicates := dupError',
     'BŁĄD SKŁADNI: Funkcja błąd_duplikaty / blad_duplikaty / error_duplicates  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja błąd_duplikaty / blad_duplikaty / error_duplicates wymaga 1 argumentu (Nazwa listy).') then
  Exit;


  //FS := TFileStream.Create('test.txt', fmOpenRead);
  if TryTranslateGeneric(Line, PascalCode,
    ['twórz_strumień_pliku','tworz_strumien_pliku','create_file_stream'],
    3,
     '%0 := TFileStream.Create(%1,%2)',
     'BŁĄD SKŁADNI: Funkcja twórz_strumień_pliku / tworz_strumien_pliku / create_file_stream  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja twórz_strumień_pliku / tworz_strumien_pliku / create_file_stream wymaga 3 argumentów (Nazwa listy,''Nazwa pliku z rozszerzeniem '',Tryb odczytu).') then
  Exit;

   //ReadByte: Byte;  odczyt 1 bajtu
  if TryTranslateGeneric(Line, PascalCode,
    ['czytaj_bajt','read_byte'],
    2,
     '%0 := %1.ReadByte',
     'BŁĄD SKŁADNI: Funkcja czytaj_bajt  / read_byte  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja czytaj_bajt / read_byte  wymaga 2 argumentów (zmienna dword / dslowo,''strumień_pliku.'').') then
  Exit;

  //ReadWord: Word; - odczyt 2 bajtów (UInt16)
  if TryTranslateGeneric(Line, PascalCode,
    ['czytaj_słowo','czytaj_slowo','read_word'],
    2,
     '%0 := %1.ReadWord',
     'BŁĄD SKŁADNI: Funkcja czytaj_słowo  / read_word  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja czytaj_słowo / read_word  wymaga 2 argumentów (zmienna dword / dslowo,''strumień_pliku.'').') then
  Exit;

  //ReadDWord: DWord; - odczyt 4 bajtów (UInt32)
  if TryTranslateGeneric(Line, PascalCode,
    ['czytaj_dsłowo','read_dword'],
    2,
     '%0 := %1.ReadDWord',
     'BŁĄD SKŁADNI: Funkcja czytaj_dsłowo / czytaj_dslowo /  read_dword  wymaga nawiasów.',
     'BŁĄD ARGUMENTÓW: Funkcja czytaj_dsłowo / czytaj_dslowo / read_dword  wymaga 2 argumentów (zmienna dword / dslowo,''strumień_pliku.'').') then
  Exit;


  // Obsługa funkcji parametr_programu / get_argument -> ParamStr
  if (LowerCase(TrimmedLine).StartsWith('parametr_programu(')) or
     (LowerCase(TrimmedLine).StartsWith('get_argument(')) then
  begin
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingBracketsGetArgumentFunction);
    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      // ParamStr wymaga argumentu (indeksu), więc puste nawiasy to błąd
      if Trim(Value) = '' then
        raise Exception.Create(TranslateGetArgumentFunctionRequiresIndex);
      PascalCode.Add('ParamStr(' + TranslateExpression(Value) + ');');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingGetArgumentFunction + E.Message);
    end;
    Exit;
  end;


 // Obsługa: pobierz_zmienną_środowiskową -> SysUtils.GetEnvironmentVariable
  if (LowerCase(TrimmedLine).StartsWith('pobierz_zmienną_środowiskową(')) or
     (LowerCase(TrimmedLine).StartsWith('pobierz_zmienna_srodowiskowa(')) or
     (LowerCase(TrimmedLine).StartsWith('get_environment_variable(')) then
  begin
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingParenthesesGetEnvironmentVariableFunction);
    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1);
      if Trim(Value) = '' then
        raise Exception.Create(TranslateGetEnvironmentVariableRequiresName);
      if Pos('=', TrimmedLine) > 0 then
      begin
        Parts := TrimmedLine.Split(['='], 2);
        VarName := Trim(Parts[0]);
        if Pos(' ', VarName) > 0 then
           VarName := Trim(Copy(VarName, RPos(' ', VarName) + 1, MaxInt));
        PascalCode.Add(VarName + ' := SysUtils.GetEnvironmentVariable(' + TranslateExpression(Value) + ');');
      end
      else
      begin
        // Wywołanie samodzielne
        PascalCode.Add('SysUtils.GetEnvironmentVariable(' + TranslateExpression(Value) + ');');
      end;
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingGetEnvironmentVariableFunction + E.Message);
    end;

    Exit;
  end;


  // Obsługa funkcji oblicz / calc
  if (LowerCase(TrimmedLine).StartsWith('oblicz(')) or
     (LowerCase(TrimmedLine).StartsWith('calc(')) then
  begin
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine); // RPos znajduje ostatni nawias
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingParenthesesCalculateFunction);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    try
      Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

      // Walidacja pustej zawartości
      if Value = '' then
        raise Exception.Create(TranslateCalculateFunctionRequiresExpression);
      PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingCalculateFunction + E.Message);
    end;
    Exit;
  end;

  // Obsługa funkcji oblicz_formatuj / calc_format
  // Użycie: oblicz_formatuj('2+2', 2) -> Wypisze 4.00
  if (LowerCase(TrimmedLine).StartsWith('oblicz_formatuj(')) or
     (LowerCase(TrimmedLine).StartsWith('calc_format(')) then
  begin
    StartPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (StartPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateMissingParenthesesCalculateFormatFunction);

    if StartPos > EndPos then
      raise Exception.Create(TranslateClosingBracketBeforeOpeningBracket);
    ParamStr := Trim(Copy(TrimmedLine, StartPos + 1, EndPos - StartPos - 1));

    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count = 1 then
      begin
        // Jeden argument -> Domyślne formatowanie (2 miejsca po przecinku)
        Value := TranslateExpression(Trim(ParamPartsList[0]));
        PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
      end
      else if ParamPartsList.Count = 2 then
      begin
        // Dwa argumenty  Wyrażenie i Precyzja
        Value := TranslateExpression(Trim(ParamPartsList[0]));     // np. '2+2'
        CountExpr := TranslateExpression(Trim(ParamPartsList[1])); // np. 4
        PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:' + CountExpr + ');');
      end
      else
      begin
        raise Exception.Create(TranslateCalcFormatFunctionRequiresOneOrTwoArguments);
      end;
    finally
      ParamPartsList.Free;
    end;

    Exit;
  end;

   // 3. Obsługa instrukcji czytaj() -> Read / Write+Read
  if (Pos('czytaj(', LowerCase(TrimmedLine)) > 0) or
     (Pos('read(', LowerCase(TrimmedLine)) > 0) then
  begin
    try
      // Przypadek A: Przypisanie (zmienna = czytaj(prompt))
      if Pos('=', TrimmedLine) > 0 then
      begin
        Parts := TrimmedLine.Split(['='], 2);
        if Length(Parts) < 2 then
          raise Exception.Create(TranslateSyntaxErrorReadFunctionAssignment);
        VarName := Trim(Parts[0]);
        Value := Trim(Parts[1]);
        if Pos(' ', VarName) > 0 then
        begin
          Parts := VarName.Split([' '], 2);
          if Length(Parts) >= 2 then
          begin
            VarType := ResolveAlias(Parts[0]);
            VarName := Parts[1];
            AddVariable(VarName, VarType, False);
          end;
        end;
        OpenPos := Pos('(', Value);
        EndPos := RPos(')', Value);

        if (OpenPos = 0) or (EndPos = 0) then
           raise Exception.Create(TranslateMissingBracketsReadFunction);

        if OpenPos > EndPos then
           raise Exception.Create(TranslateIncorrectOrderOfBrackets);
        ParamStr := Trim(Copy(Value, OpenPos + 1, EndPos - OpenPos - 1));
        if ParamStr <> '' then
          PascalCode.Add('Write(' + TranslateExpression(ParamStr) + ');');
        PascalCode.Add('Read(' + VarName + ');');
      end
      else
      begin
        OpenPos := Pos('(', TrimmedLine);
        EndPos := RPos(')', TrimmedLine);

        if (OpenPos = 0) or (EndPos = 0) then
           raise Exception.Create(TranslateMissingBracketsReadFunction);
        Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));
        if Value = '' then
           raise Exception.Create(TranslateReadFunctionRequiresVariableName);
        PascalCode.Add('Read(' + Value + ');');
      end;
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingReadFunction + E.Message);
    end;

    Exit;
  end;

  // 4. Obsługa instrukcji czytaj_linie() -> ReadLn / Write+ReadLn
  if (Pos('czytaj_linie(', LowerCase(TrimmedLine)) > 0) or
     (Pos('read_lines(', LowerCase(TrimmedLine)) > 0) then
  begin
    try
      // Przypadek A: Przypisanie (zmienna = czytaj_linie(prompt))
      if Pos('=', TrimmedLine) > 0 then
      begin
        Parts := TrimmedLine.Split(['='], 2);
        if Length(Parts) < 2 then
          raise Exception.Create(TranslateSyntaxErrorAssignmentReadLine);
        VarName := Trim(Parts[0]);
        Value := Trim(Parts[1]);
        if Pos(' ', VarName) > 0 then
        begin
          Parts := VarName.Split([' '], 2);
          if Length(Parts) >= 2 then
          begin
            VarType := ResolveAlias(Parts[0]);
            VarName := Parts[1];
            AddVariable(VarName, VarType, False);
          end;
        end;
        OpenPos := Pos('(', Value);
        EndPos := RPos(')', Value);
        if (OpenPos = 0) or (EndPos = 0) then
           raise Exception.Create(TranslateReadLinesRequiresParentheses);

        if OpenPos > EndPos then
           raise Exception.Create(TranslateIncorrectOrderOfBrackets);
        ParamStr := Trim(Copy(Value, OpenPos + 1, EndPos - OpenPos - 1));
        if ParamStr <> '' then
          PascalCode.Add('Write(' + TranslateExpression(ParamStr) + ');');

        PascalCode.Add('ReadLn(' + VarName + ');');
      end
      // Samodzielne wywołanie (czytaj_linie(zmienna))
      else
      begin
        OpenPos := Pos('(', TrimmedLine);
        EndPos := RPos(')', TrimmedLine);

        if (OpenPos = 0) or (EndPos = 0) then
           raise Exception.Create(TranslateReadLinesParenthesesRequired);
        Value := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

        if Value = '' then
           PascalCode.Add('ReadLn;')
        else
           PascalCode.Add('ReadLn(' + Value + ');');
      end;
    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingReadLinesFunction + E.Message);
    end;

    Exit;
  end;



  //  Obsługa funkcji ustaw_długość / set_length -> SetLength
  if (LowerCase(TrimmedLine).StartsWith('ustaw_długość(')) or
     (LowerCase(TrimmedLine).StartsWith('ustaw_dlugosc(')) or
     (LowerCase(TrimmedLine).StartsWith('set_length(')) then
  begin
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);
    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslateSetLengthRequiresParentheses);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateIncorrectOrderOfBrackets);
    ParamStr := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));
    ParamPartsList := TStringList.Create;
    try
      SplitArguments(ParamStr, ParamPartsList);
      if ParamPartsList.Count <> 2 then
        raise Exception.Create(TranslateSetLengthRequiresTwoArguments);
      VarName := Trim(ParamPartsList[0]);
      LengthExpr := TranslateExpression(Trim(ParamPartsList[1]));
      if VarName = '' then
        raise Exception.Create(TranslateFirstArgumentCannotBeEmpty);
      PascalCode.Add('SetLength(' + VarName + ', ' + LengthExpr + ');');
    except
      on E: Exception do
      begin
        ParamPartsList.Free;
        raise Exception.Create(TranslateErrorProcessingSetLengthFunction + E.Message);
      end;
    end;
    ParamPartsList.Free;
    Exit;
  end;



  if (TrimmedLine.EndsWith(':')) and (Pos(' ', TrimmedLine) = 0) then
  begin
    PascalCode.Add(TrimmedLine);
    Exit;
  end;
 {

 // 7. Obsługa instrukcji ftp_pobierz 'plik' do 'lokalizacja'
   if LowerCase(TrimmedLine).StartsWith('ftp_pobierz ') then
   begin
     try
       // Dzielenie linii na dwie części za pomocą ' do '
       Parts := TrimmedLine.Split([' do '], 2);

       // Walidacja liczby argumentów
       if Length(Parts) <> 2 then
         raise Exception.Create('Błąd składni: ftp_pobierz wymaga formatu: ftp_pobierz [URL] do [ŚcieżkaZapisu].');

       // Wyciąganie adresu URL (usuwamy "ftp_pobierz " - 12 znaków + spacja)
       URL_Expression := Trim(Parts[0].Substring(12));

       // Wyciąganie ścieżki zapisu
       SavePath_Expression := Trim(Parts[1]);

       // Walidacja czy URL i ścieżka nie są puste
       if (URL_Expression = '') or (SavePath_Expression = '') then
         raise Exception.Create('Błąd: Zarówno URL pliku, jak i ścieżka zapisu muszą być podane.');
       PascalCode.Add('DownloadFTP(' + TranslateExpression(URL_Expression) + ', ' + TranslateExpression(SavePath_Expression) + ');');


     except
       on E: Exception do
         raise Exception.Create('Błąd podczas przetwarzania instrukcji FTP_POBIERZ: ' + E.Message);
     end;
     Exit;
   end;
   }



  // Obsługa instrukcji ping adres (np. ping "google.com")
  if LowerCase(TrimmedLine).StartsWith('ping ') then
  begin
    try
      // Wyciągamy resztę linii po "ping " (długość 'ping ' to 5)
      SiteExpression := Trim(Copy(TrimmedLine, 5, Length(TrimmedLine) - 4));

      // Walidacja
      if SiteExpression = '' then
        raise Exception.Create(TranslatePingCommandRequiresUrlOrVariable);

      // Tłumaczymy wyrażenie
      TranslatedSite := TranslateExpression(SiteExpression);

      // Generowanie kodu dla warunku IF i domyślnych komunikatów
      // START: if ping('www.google.com') then
      PascalCode.Add('if ping(' + TranslatedSite + ') then');
      PascalCode.Add('begin');

      // Obsługa sukcesu (domyślny komunikat)
      PascalCode.Add('  WriteLn(''Strona '' + ' + TranslatedSite + ' + '' odpowiada!'');');
      PascalCode.Add('end');

      // Obsługa błędu (domyślny komunikat)
      PascalCode.Add('else');
      PascalCode.Add('begin');
      PascalCode.Add('  WriteLn(''Nie można nawiązać połączenia z '' + ' + TranslatedSite + ');');
      PascalCode.Add('end;');

    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingPingCommand + E.Message);
    end;

    Exit;
  end;

  // Obsługa instrukcji ping(adres, komunikat).
  if LowerCase(TrimmedLine).StartsWith('ping(') then
  begin
    // ... walidacja i parsowanie nawiasów ...
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslatePingFunctionRequiresBrackets);

    if OpenPos > EndPos then
      raise Exception.Create(TranslateIncorrectOrderOfBrackets);

    ParamStr := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

    ParamPartsList := TStringList.Create;
    try
      try
        SplitArguments(ParamStr, ParamPartsList);

        if ParamPartsList.Count <> 2 then
           raise Exception.Create(TranslatePingFunctionRequiresTwoArguments);
           SiteExpression := TranslateExpression(Trim(ParamPartsList[0]));
           SuccessMessage := TranslateExpression(Trim(ParamPartsList[1]));

          PascalCode.Add('if ping(' + SiteExpression + ') then');
          PascalCode.Add('begin');
          PascalCode.Add('  WriteLn(' + SuccessMessage + ');');
          PascalCode.Add('end');
          PascalCode.Add('else');
          PascalCode.Add('begin');
          PascalCode.Add('  WriteLn(''Nie można nawiązać połączenia z '' + ' + SiteExpression + ');');
          PascalCode.Add('end;');

        finally
          ParamPartsList.Free;
        end;

        except
          on E: Exception do
          begin
            // Czyścimy PRZED podniesieniem wyjątku
            ParamPartsList.Free;
            raise Exception.Create(TranslateErrorProcessingPingFunction + E.Message);
          end;
        end;
    Exit;
  end;

  // Funkcja pobierz_plik / download_file
  if (LowerCase(TrimmedLine).StartsWith('pobierz_plik(')) or
     (LowerCase(TrimmedLine).StartsWith('download_file(')) then
  begin
    CommaPos := 0;
    InQuotes := False;

    try
      OpenPos := Pos('(', TrimmedLine);
      EndPos := RPos(')', TrimmedLine);

      if (OpenPos = 0) or (EndPos = 0) then
        raise Exception.Create('Błędna składnia funkcji pobierz_plik().');

      if OpenPos > EndPos then
        raise Exception.Create(TranslateIncorrectOrderOfBrackets);

      // Wyciągnięcie parametrów
      ParamStr := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

      // Znalezienie przecinka poza cudzysłowami
      for I := 1 to Length(ParamStr) do
      begin
        if ParamStr[I] = '''' then
          InQuotes := not InQuotes;

        if (ParamStr[I] = ',') and (not InQuotes) then
        begin
          CommaPos := I;
          Break;
        end;
      end;

      if CommaPos = 0 then
        raise Exception.Create(TranslateDownloadFileFunctionRequiresTwoArguments);

      // Parametr 1 = URL
      URL := TranslateExpression(Trim(Copy(ParamStr, 1, CommaPos - 1)));

      // Parametr 2 = ścieżka zapisu
      Target := TranslateExpression(Trim(Copy(ParamStr, CommaPos + 1, Length(ParamStr) - CommaPos)));

      PascalCode.Add('try');
      PascalCode.Add('  if DownloadFileToDisk(' + URL + ', ' + Target + ') then');
      PascalCode.Add('    Writeln(''Plik zapisany w: '' + ' + Target + ')');
      PascalCode.Add('  else');
      PascalCode.Add('    Writeln(''Błąd pobierania pliku z URL: '' + ' + URL + ');');
      PascalCode.Add('except');
      PascalCode.Add('  on E: Exception do');
      PascalCode.Add('    Writeln(''Wyjątek podczas pobierania: '' + E.Message);');
      PascalCode.Add('end;');

    except
      on E: Exception do
        raise Exception.Create(TranslateErrorProcessingGetFileFunction + ' ' + E.Message);
    end;

    Exit;
  end;


// Obsługa funkcji pobierz_strone(URL, zmienna_wynikowa)
if (LowerCase(TrimmedLine).StartsWith('pobierz_strone(')) or
   (LowerCase(TrimmedLine).StartsWith('download_page(')) then
begin
  try
    // --- 1. Parsowanie i walidacja ---
    OpenPos := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine);

    if (OpenPos = 0) or (EndPos = 0) then
      raise Exception.Create(TranslatePobierzStroneRequiresParentheses);

    ParamStr := Trim(Copy(TrimmedLine, OpenPos + 1, EndPos - OpenPos - 1));

    ParamPartsList := TStringList.Create;
    SplitArguments(ParamStr, ParamPartsList);

    if ParamPartsList.Count <> 2 then
      raise Exception.Create(TranslatePobierzStroneRequiresTwoArguments);

    URL := TranslateExpression(Trim(ParamPartsList[0]));
    Target := TranslateExpression(Trim(ParamPartsList[1])); // Zmienna wynikowa

    // --- 2. Generowanie kodu Pascala z obsługą wyjątków (try...except) ---
    PascalCode.Add('try');
    PascalCode.Add('  pobierz_strone(' + URL + ', ' + Target + ');'); // Właściwe wywołanie
    PascalCode.Add('except');
    PascalCode.Add('  on E: Exception do');
    PascalCode.Add('  begin');
    PascalCode.Add('    Writeln(''Błąd pobierania strony z '' + ' + URL + ' + '': '' + E.Message);');
    PascalCode.Add('  end;');
    PascalCode.Add('end;');

  finally
    ParamPartsList.Free;
  end;
  Exit;
end;

  //Nowy poprawiony kod 29.03.2026
  AssignPos := 0;
  InQuotes := False;
  // Szukamy znaku '=' ignorując wnętrza stringów
  for I := 1 to Length(TrimmedLine) do
  begin
    if TrimmedLine[I] = '''' then
      InQuotes := not InQuotes;

    if (not InQuotes) and (TrimmedLine[I] = '=') then
    begin
      // Omijamy operator porównania (jeśli używasz ==, <=, >=, !=)
      if (I < Length(TrimmedLine)) and (TrimmedLine[I+1] = '=') then Continue;
      if (I > 1) and (TrimmedLine[I-1] in ['!', '>', '<', '=']) then Continue;

      AssignPos := I;
      Break;
    end;
  end;

  // Jeśli to jest operacja przypisania (np. ui.tytul = 'okno')
  if AssignPos > 0 then
  begin
    VarName := Trim(Copy(TrimmedLine, 1, AssignPos - 1));
    Value := Trim(Copy(TrimmedLine, AssignPos + 1, MaxInt));

    // tłumaczenie właściwości obiektów
    DotPos := Pos('.', VarName);
    if DotPos > 0 then
    begin
      ObjectName := Trim(Copy(VarName, 1, DotPos - 1));
      PropName := LowerCase(Trim(Copy(VarName, DotPos + 1, MaxInt)));


      if PropName = 'tytul' then PropName := 'title'
      else if PropName = 'szerokosc' then PropName := 'width'
      else if PropName = 'wysokosc' then PropName := 'height'
      else if PropName = 'widoczne' then PropName := 'visible'
      else if PropName = 'maksymalizacja' then PropName := 'allowmaximize'
      else if PropName = 'kolor_tla' then PropName := 'BackgroundColor'
      else if PropName = 'przeciaganie' then PropName := 'AllowDrag'
      else if PropName = 'bezramkowe' then PropName := 'Frameless';
      // Polskie znaki
      if PropName = 'tytuł' then PropName := 'title'
      else if PropName = 'szerokość' then PropName := 'width'
      else if PropName = 'wysokość' then PropName := 'height'
      else if PropName = 'tytuł' then PropName := 'title'
      else if PropName = 'kolor_tła' then PropName := 'BackgroundColor'
      else if PropName = 'przeciąganie' then PropName := 'AllowDrag';

      VarName := ObjectName + '.' + PropName;
    end;

    // Generowanie czystego kodu
    if NeedsSemicolon then
      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value) + ';')
    else
      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value));

    Exit;
  end;

  //POZOSTAŁE (Catch-all wywołań funkcji)
  if TrimmedLine <> '' then
  begin
    TranslatedLine := TranslateExpression(TrimmedLine);
    if Trim(TranslatedLine) = '' then Exit;

    if NeedsSemicolon then PascalCode.Add(TranslatedLine + ';')
    else PascalCode.Add(TranslatedLine);
    Exit;
  end;
 { // ZWYKŁE PRZYPISANIA ---
  if Pos('=', TrimmedLine) > 0 then
  begin
    Parts := TrimmedLine.Split(['='], 2);
    VarName := Trim(Parts[0]);
    Value := Trim(Parts[1]);
    if NeedsSemicolon then PascalCode.Add(VarName + ' := ' + TranslateExpression(Value) + ';')
    else PascalCode.Add(VarName + ' := ' + TranslateExpression(Value));
    Exit;
  end;


  //POZOSTAŁE (Catch-all) ---
  if TrimmedLine <> '' then
  begin
    TranslatedLine := TranslateExpression(TrimmedLine);

    if Trim(TranslatedLine) = '' then Exit;

    if NeedsSemicolon then PascalCode.Add(TranslatedLine + ';')
    else PascalCode.Add(TranslatedLine);
    Exit;
  end;
  }
end;




function TAvocadoTranslator.Translate(const AvocadoCode: TStrings): TStringList;
var
PascalCode: TStringList;
i: Integer;
trimmedLine, ModulesStr : string;
ModulPascalowy: string;
DetectedProgramName: string;
UsesList: TStringList;
UName: string;
ExistingUnits: TStringList;
NextTrimmedLowerLine: string;
LowerLine: string;
ProcedureDepth: Integer;
j: integer;
DetectedCodePage: string;
WinCP: string;
IsGUI: Boolean;
TranslateCode: TStringList;

begin
  TranslateCode := TStringList.Create;
  PascalCode := TStringList.Create;
  UsesList := TStringList.Create;
  ExistingUnits := TStringList.Create;

  SetLength(FVariables, 0);
  FInRepeatBlock := False;
  FInMultiLineComment := False;
  FInProcedureBody := False; // Używane tylko przez Pętlę 1



    // SPRAWDZENIE: Czy słownik został utworzony w Create?
    if FFunctionMap = nil then
       raise Exception.Create(TranslateFFunctionMapNotInitialized);

    // FAZA PREPROCESORA - Tłumaczenie
    if AvocadoCode <> nil then
    begin
      for i := 0 to AvocadoCode.Count - 1 do
      begin
        // Tłumaczymy każdą linię i dodajemy do nowej listy
        TranslateCode.Add(TranslateFunctions(AvocadoCode[i]));
      end;
    end;

    // Usuwanie BOM na przetłumaczonym kodzie
    if (TranslateCode.Count > 0) and (Length(TranslateCode[0]) >= 3) then
    begin
      if (TranslateCode[0][1] = #$EF) and (TranslateCode[0][2] = #$BB) and (TranslateCode[0][3] = #$BF) then
        TranslateCode[0] := Copy(TranslateCode[0], 4, MaxInt);
    end;
   IsGUI := False; // Domyślnie konsola
   self.IsGUIProject := False;

  //Wykrywam kodowanie na podstawie calego kodu źródłowego
  DetectedCodePage := DetectCodePage(TranslateCode.Text);
  WinCP := GetWindowsCP(DetectedCodePage);

  PascalCode := TStringList.Create;
  UsesList := TStringList.Create;
  ExistingUnits := TStringList.Create;

  // Skanowanie nazwy programu
  NameProgram := '';
  DetectedProgramName := 'untitledprogram';

  for i := 0 to TranslateCode.Count - 1 do
  begin
    trimmedLine := Trim(TranslateCode[i]);
    if trimmedLine = '' then Continue;
    LowerLine := LowerCase(trimmedLine);

   // Sprawdzamy czy to program okienkowy
    if LowerLine.StartsWith('program_ui ') then
    begin
      IsGUI := True;
      self.IsGUIProject := True;
      //if NameProgram = '' then NameProgram := 'AvocadoApp';
      DetectedProgramName := Trim(Copy(trimmedLine, 12, MaxInt));
       //UsesList.AddStrings(['SysUtils', 'Classes', 'StrUtils', 'Dialogs']);
      {$IFDEF WINDOWS}
      UsesList.Add('Windows');
      {$ENDIF}

      Break;
    end
    // Sprawdzamy czy to zwykły program
    else if LowerLine.StartsWith('program ') then
    begin
      IsGUI := False;
      self.IsGUIProject := False;
      DetectedProgramName := Trim(Copy(trimmedLine, 9, MaxInt));
      UsesList.AddStrings(['SysUtils', 'Classes', 'StrUtils', 'Dialogs']);
      {$IFDEF WINDOWS}
      UsesList.Add('Windows');
      {$ENDIF}
      Break;
    end;
  end;

  try
    //AddCompilerDirective(PascalCode);
    PascalCode.Add('program ' + DetectedProgramName + ';');
    // Wywołujemy funkcję z nowym parametrem IsGUI
    AddCompilerDirective(PascalCode, IsGUI);

    //Sekcja 'uses'
    ModulesStr := GetImportedModules(TranslateCode.Text);
    ModulPascalowy := GetImplementationModules(TranslateCode.Text);

    //UsesList.AddStrings(['SysUtils', 'Classes', 'StrUtils', 'Dialogs']);
    //{$IFDEF WINDOWS}
    //UsesList.Add('Windows');
    //{$ENDIF}

    if ModulesStr <> '' then
      for UName in ModulesStr.Split([',']) do UsesList.Add(Trim(UName));
    if ModulPascalowy <> '' then
      for UName in ModulPascalowy.Split([',']) do UsesList.Add(Trim(UName));
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
  	    PascalCode.Delete(PascalCode.Count - 1);
  	 PascalCode.Add('');

    // 4. PĘTLA 1: Skanowanie dla 'var'
    FInProcedureBody := False;
    for i := 0 to TranslateCode.Count - 1 do
      ProcessDeclaration(Trim(TranslateCode[i]));

         // 5. Generowanie sekcji 'var'
  	 if Length(FVariables) > 0 then
  	 begin
  	   PascalCode.Add('var');
  	   for i := 0 to High(FVariables) do
  	   begin
  	     if FVariables[i].VarName = '' then Continue;
  	     PascalCode.Add('  ' + FVariables[i].VarName + ': ' + SafeResolveAlias(FVariables[i].VarType) + ';');
  	   end;
  	   PascalCode.Add('');
  	 end;


    // 7. PĘTLA 2: Tłumaczenie Procedur
    ProcedureDepth := 0;
    FInRepeatBlock := False;
    PascalCode.Add('');
    for i := 0 to TranslateCode.Count - 1 do
    begin
      trimmedLine := Trim(TranslateCode[i]);
      if trimmedLine = '' then Continue;
      LowerLine := AnsiLowerCase(trimmedLine);

      //if (LowerLine.StartsWith('procedura ')) or (LowerLine.StartsWith('procedure ')) then
      if (LowerLine.StartsWith('procedura ')) or (LowerLine.StartsWith('procedure ')) or
     (LowerLine.StartsWith('funkcja ')) or (LowerLine.StartsWith('function ')) then
      begin
        PascalCode.Add( TranslateProcedureHeader(trimmedLine) );
        AnalyzeLocalVariables(i + 1, TranslateCode);
        if Length(FLocalVariables) > 0 then
        begin
          PascalCode.Add('var');
          for j := 0 to High(FLocalVariables) do
          begin
             PascalCode.Add('  ' + FLocalVariables[j].VarName + ': ' + SafeResolveAlias(FLocalVariables[j].VarType) + ';');
          end;
        end;
        ProcedureDepth := 1;
        Continue;
      end;

      // Jeśli jesteśmy w procedurze, tłumacz jej ciało
      if ProcedureDepth > 0 then
      begin
        if (LowerLine = 'start') or
           (LowerLine = 'początek') or
           (LowerLine = 'poczatek')
           //(LowerLine = 'main')or
           //(LowerLine = 'główny') or
           //(LowerLine = 'glowny')
           then
          Inc(ProcedureDepth)
        else if (LowerLine = 'koniec') or (LowerLine = 'end') then
          Dec(ProcedureDepth);

        // Jeśli licznik spadł do 0, to jest koniec procedury
        if ProcedureDepth = 0 then
        begin
          PascalCode.Add('end;');
          PascalCode.Add('');
          Continue;
        end;

        // Pobierz następną linię
        if i + 1 < TranslateCode.Count then
    	     NextTrimmedLowerLine := LowerCase(Trim(TranslateCode[i+1]))
    	else
    	    NextTrimmedLowerLine := '';
        ProcessLine(trimmedLine, PascalCode, NextTrimmedLowerLine);
      end;
    end;

         // Główny blok 'begin' (wstawki)
  	 PascalCode.Add('begin');

          if not IsGUI then
          begin
            PascalCode.Add('{$IFDEF WINDOWS}');
            PascalCode.Add('  SetConsoleCP(' + WinCP + ');');
            PascalCode.Add('  SetConsoleOutputCP(' + WinCP + ');');
            PascalCode.Add('{$ENDIF}');
            PascalCode.Add('  SetTextCodePage(Output, ' + WinCP + ');');
            PascalCode.Add('  SetTextCodePage(Input, ' + WinCP + ');');
          end;

         {PascalCode.Add('{$IFDEF WINDOWS}');
           //dynamiczne kodowanie
           PascalCode.Add('  SetConsoleCP(' + WinCP + ');');
           PascalCode.Add('  SetConsoleOutputCP(' + WinCP + ');');
         PascalCode.Add('{$ENDIF}');
         // Ustawienie strony kodowej dla standardowego wyjścia (ważne dla FPC RTL)
          PascalCode.Add('  SetTextCodePage(Output, ' + WinCP + ');');
          PascalCode.Add('  SetTextCodePage(Input, ' + WinCP + ');');
          }

  	 // 9. Inicjalizacja zmiennych
  	 for i := 0 to High(FVariables) do
  	 begin
  	   if (FVariables[i].VarName <> '') and (FVariables[i].InitialValue <> '') then
  	   begin
  	 	 PascalCode.Add('  ' + FVariables[i].VarName + ' := ' + TranslateExpression(FVariables[i].InitialValue) + ';');
  	   end;
  	 end;
         PascalCode.Add('');

  	 // 10. PĘTLA 3: Tłumaczenie kodu głównego
  	 ProcedureDepth := 0;
         FInRepeatBlock := False;


  	 for i := 0 to TranslateCode.Count - 1 do
  	 begin
  	   trimmedLine := Trim(TranslateCode[i]);
  	   if trimmedLine = '' then Continue;
           LowerLine := AnsiLowerCase(trimmedLine);

          // ignoruje procedury i funkcje
          if (LowerLine.StartsWith('procedura ')) or (LowerLine.StartsWith('procedure ')) or
             (LowerLine.StartsWith('funkcja ')) or (LowerLine.StartsWith('function ')) then
          begin
            ProcedureDepth := 1;
            Continue;
          end;
          if ProcedureDepth > 0 then
          begin
            if (LowerLine = 'start') or (LowerLine = 'początek') or (LowerLine = 'poczatek')
               or (LowerLine = 'main') or (LowerLine = 'główny') or (LowerLine = 'glowny') then
               Inc(ProcedureDepth)
            else if (LowerLine = 'koniec') or (LowerLine = 'end') then Dec(ProcedureDepth);
            Continue;
          end;

     // Ignoruj linie globalne ORAZ deklaracje zmiennych
     if AnsiStartsText('program ', LowerLine) or
        AnsiStartsText('program_ui ', LowerLine) or
  	AnsiStartsText('importuj', LowerLine) or
  	AnsiStartsText('import', LowerLine) or
  	AnsiStartsText('ModułyPas', LowerLine) or
         // Ignoruj deklaracje zmiennych (użyjemy ResolveAlias do sprawdzenia)
       (SafeResolveAlias(LowerLine.Split([' '])[0]) <> 'Variant') or
       // IGNORUJEMY główny 'start' i 'koniec.'
       (LowerLine = 'main') or
       (LowerLine = 'główny') or
       (LowerLine = 'glowny') or
       (LowerLine = 'start') or
       (LowerLine = 'początek') or
       (LowerLine = 'poczatek') or
       (LowerLine = 'koniec.') or
       (LowerLine = 'end.') then
       begin
         Continue;
       end
       else
  	 begin
         if i + 1 < TranslateCode.Count then
       	   NextTrimmedLowerLine := LowerCase(Trim(TranslateCode[i+1]))
      	 else
	   NextTrimmedLowerLine := '';

  	 // Tłumaczymy kod główny (TYLKO wnętrze bloku)
   	 ProcessLine(trimmedLine, PascalCode, NextTrimmedLowerLine);
  	 end;
  	 end;
         // Koniec Pętli 3


          if not IsGUI then
          begin
             // Tylko dla konsoli dodajemy czekanie na klawisz
             PascalCode.Add('  Readln;');
          end;

  	 PascalCode.Add('end.');

         PascalCode.Insert(0, '{$codepage ' + DetectedCodePage + '}');
         //Line := TranslateFunctions(Line);

  	 Result := PascalCode;
  finally
   UsesList.Free;
   ExistingUnits.Free;
   TranslateCode.Free;
  end;

end;

end.

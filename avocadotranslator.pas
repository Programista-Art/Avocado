unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils,fpexprpars,Crt,formatowanie;

type
  TStringArray = array of string;
  TAvocadoVariable = record
  Name, VarType: string;
  end;

  { TAvocadoTranslator }

  TAvocadoTranslator = class
  private
    FVariables: array of TAvocadoVariable;
    procedure ProcessForLoop(const Line: string; PascalCode: TStringList);
    procedure AddVariable(const Name, VarType: string);
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
  end;
var
Moduly: String;

implementation
uses
  unit1;

{ TAvocadoTranslator }

procedure TAvocadoTranslator.AddVariable(const Name, VarType: string);
var
  j: Integer;
begin
  for j := 0 to High(FVariables) do
    if FVariables[j].Name = Name then Exit;
  SetLength(FVariables, Length(FVariables) + 1);
  FVariables[High(FVariables)].Name := Name;
  FVariables[High(FVariables)].VarType := VarType;
end;

//KOnwersje
function TAvocadoTranslator.TranslateExpression(const Expr: string): string;
begin
  Result := Expr;
  Result := StringReplace(Result, ' i ', ' and ', [rfReplaceAll]);
  Result := StringReplace(Result, ' lub ', ' or ', [rfReplaceAll]);
  Result := StringReplace(Result, 'prawda', 'True', [rfReplaceAll]);
  Result := StringReplace(Result, 'falsz', 'False', [rfReplaceAll]);

  Result := StringReplace(Result, 'TekstWLiczbac(', 'StrToInt(', [rfReplaceAll]);
  Result := StringReplace(Result, 'TekstWLiczbar(', 'StrToFloat(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacWTekst(', 'IntToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbarWTekst(', 'FloatToStr(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbacWr(', 'Real(', [rfReplaceAll]);
  Result := StringReplace(Result, 'LiczbarWc(', 'Trunc(', [rfReplaceAll]);
  //nowe
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
  Result := StringReplace(Result, 'migotanie', 'Blink', [rfReplaceAll, rfIgnoreCase]);

end;

//Deklaracja nowych typów zmienncyh
procedure TAvocadoTranslator.ProcessDeclaration(const Line: string);
var
  Parts: TStringArray;
  VarType, VarName: string;
begin
    if Trim(Line) = '' then Exit;
      // Jeśli linia nie zawiera znaku "=", to nie jest deklaracją zmiennej
      if Pos('=', Line) = 0 then Exit;
      // Pomijamy linie zaczynające się od instrukcji, których nie chcemy traktować jako deklaracje
      if (LowerCase(Trim(Line)).StartsWith('jeśli')) //or
         //(LowerCase(Trim(Line)).StartsWith('pisz(')) //or
         //(Pos('wpr(', LowerCase(Line)) > 0)
         then Exit;

      Parts := Line.Split(['='], 2);
      VarName := Trim(Parts[0]);
      if Pos(' ', VarName) > 0 then
      begin
        Parts := VarName.Split([' '], 2);
        if Length(Parts) < 2 then Exit;
        VarType := LowerCase(Trim(Parts[0]));
        VarName := Trim(Parts[1]);
        // Dozwolone typy zmiennych
        if (VarType = 'liczba_całkowita') or
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
           (VarType = 'tekst') or
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
           (VarType = 'plik') or
           (VarType = 'plik_tekstowy') or
           (VarType = 'plik_binarny') or
           (VarType = 'plik_struktur') or
           (VarType = 'wskaźnik') or
           (VarType = 'wskaźnik_na') or
           (VarType = 'wariant') or
           (VarType = 'wariant_ole') or
           (VarType = 'tablicatekstów') or
           (VarType = 'stała') or
           //Konwersje
           (VarType = 'TekstLD') then
        begin
          AddVariable(VarName, VarType);
        end
        else
          raise Exception.Create('Nieznany typ zmiennej: ' + VarType);
      end;
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
        if Pos('Importuj', Line) = 1 then
        begin
          Delete(Line, 1, Length('Importuj')); // Usuń słowo "Importuj"
          Line := Trim(Line); // Usuń spacje przed nazwami modułów

          // Dodanie do listy modułów
          if ModulesList = '' then
            ModulesList := Line
          else
            ModulesList := ModulesList + ', ' + Line;
        end;
      end;

    // Dodaj 'Crt' jeśli wykryto slowa kluczowe w kodzie
    if (Pos('odczytajklucz', LowerCase(Code)) > 0) or
     (Pos('tło_tekstu', LowerCase(Code)) > 0) or
     (Pos('kolor_tekstu', LowerCase(Code)) > 0) or
     (Pos('pozycja_kursora', LowerCase(Code)) > 0) or
     //(Pos('długość', LowerCase(Code)) > 0) or
     (Pos('klawisz_wciśnięty', LowerCase(Code)) > 0) then

    begin
      if ModulesList <> '' then
        ModulesList := ModulesList + ', Crt'
      else
        ModulesList := 'Crt';
    end;
    {
    //modul StrUtils
    if (Pos('długość', LowerCase(Code)) > 0) or
     (Pos('dd', LowerCase(Code)) > 0) then

    begin
      if ModulesList <> '' then
        ModulesList := ModulesList + ', StrUtils'
      else
        ModulesList := 'StrUtils';
    end;
    }

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


begin
  TrimmedLine := Trim(Line);
  LowerTrimmedLine := LowerCase(TrimmedLine); // <<< POPRAWIONA LINIA

  // Obsługa funkcji wstaw() → Insert()
  if Pos('wstaw(', LowerTrimmedLine) > 0 then
  begin
    StartPosInsert := Pos('(', TrimmedLine);
    EndPosInsert   := RPos(')', TrimmedLine);

    if (StartPosInsert = 0) or (EndPosInsert = 0) then
      raise Exception.Create('Błędna składnia funkcji wstaw. Oczekiwano: wstaw(source, target, index)');

    if StartPosInsert > EndPosInsert then
      raise Exception.Create('Błędna składnia funkcji wstaw. Oczekiwano: wstaw(source, target, index)');

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
      raise Exception.Create('Funkcja wstaw wymaga trzech argumentów: source, target, index');

    InsertSourceIn := TranslateExpression(ParamPartsInsert[0]);
    InsertTargetIn := TranslateExpression(ParamPartsInsert[1]);
    InsertIndexIn  := TranslateExpression(ParamPartsInsert[2]);

    PascalCode.Add('Insert(' + InsertSourceIn + ', ' + InsertTargetIn + ', ' + InsertIndexIn + ');');
    Exit; // <<< DODANE
  end;

  // 0. Obsługa pętli for
  if LowerTrimmedLine.StartsWith('dla ') then
  begin
    ProcessForLoop(TrimmedLine, PascalCode);
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

    //czytaj klawisze ReadKey
    else if LowerCase(TrimmedLine).StartsWith('ReadKey') then
    begin
      Value := Copy(TrimmedLine, 7, Length(TrimmedLine) - 7);
      PascalCode.Add('ReadKey' + TranslateExpression(Value) + ';');
      //Exit;
    end

   else if Pos('ReadKey', LowerCase(TrimmedLine)) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      if Length(Parts) <> 2 then
        raise Exception.Create('Błędna składnia odczytajklucz. Oczekiwano: zmienna = odczytajklucz');

      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

    // Sprawdź czy wartość po = to odczytajklucz
    if LowerCase(Value) <> 'ReadKey' then
      raise Exception.Create('Błędna prawa strona przypisania. Oczekiwano: odczytajklucz');

    // Przetwórz deklarację zmiennej (jeśli istnieje)
    if Pos(' ', VarName) > 0 then
    begin
      Parts := VarName.Split([' '], 2);
      if Length(Parts) < 2 then
        raise Exception.Create('Błędna deklaracja zmiennej dla ReadKey');

      VarType := Parts[0];
      VarName := Parts[1];
      AddVariable(VarName, VarType);
    end;

    // Sprawdź typ zmiennej
    if LowerCase(VarType) <> 'znak' then
      raise Exception.Create('ReadKey wymaga typu "znak"');

    // Wygeneruj kod Pascala
    PascalCode.Add(VarName + ' := ReadKey;');
  end

    // 2. Obsługa funkcji pisznl
    else if LowerCase(TrimmedLine).StartsWith('pisznl(') then
    begin
       // Pobieramy zawartość między "pisznl(" a ostatnim znakiem
      Value := Copy(TrimmedLine, 8, Length(TrimmedLine) - 8);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
      //Exit;
    end

    // 2. Obsługa funkcji pisz
    else if LowerCase(TrimmedLine).StartsWith('pisz(') then
    begin
      Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
      //Exit;
    end

     //oblicza wyrazenie
     else if LowerCase(TrimmedLine).StartsWith('oblicz(') then
     begin
       // Pobieramy zawartość między "oblicz(" a ostatnim znakiem
       Value := Copy(TrimmedLine, 8, Length(TrimmedLine) - 8);

       // Generowanie poprawnego kodu Free Pascala
       PascalCode.Add('Writeln(ObliczWyrazenie(' + Value + '):0:2);');
     end

     // --- Obsługa 'zapytaj' (NOWA WERSJA - 3 argumenty) ---
  else if LowerCase(TrimmedLine).StartsWith('zapytaj(') then
  begin
    Start := Pos('(', TrimmedLine);
    EndPos := RPos(')', TrimmedLine); // Znajdź ostatni nawias zamykający
    if (Start > 0) and (EndPos > Start) then
    begin
       // Wyodrębnij string z argumentami
       ArgStr := Trim(Copy(TrimmedLine, Start + 1, EndPos - Start - 1));

       // Rozdziel argumenty przecinkami
       // UWAGA: Proste rozdzielanie, nie obsługuje przecinków wewnątrz argumentów (poza literałami string)!
       // Wymaga bardziej zaawansowanego parsera dla pełnej funkcjonalności.
       Args := ArgStr.Split([',']);

       // Sprawdź, czy są dokładnie 3 argumenty
       if Length(Args) = 3 then
       begin
          ApiKeyArg := Trim(Args[0]);      // Pierwszy argument: klucz API (może być zmienną lub literałem)
          ModelArg := Trim(Args[1]);       // Drugi argument: model (może być zmienną lub literałem)
          QuestionArg := Trim(Args[2]);    // Trzeci argument: pytanie (zakładamy literał string w apostrofach)

          // Przetłumacz klucz i model (mogą być zmiennymi), pytanie przekaż bezpośrednio
          // Jeśli klucz/model są zawsze literałami, można pominąć TranslateExpression
          TranslatedApiKey := TranslateExpression(ApiKeyArg);
          TranslatedModel := TranslateExpression(ModelArg);

          // Generuj kod Pascala z czterema argumentami
          // Zakładamy, że QuestionArg ma już apostrofy z kodu Avocado
          // Zakładamy, że GlobalResponseCallback to globalnie dostępna procedura
          PascalCode.Add('ZapytajChatGPT(' + TranslatedApiKey + ', ' + TranslatedModel + ', ' + QuestionArg + ', @GlobalResponseCallback);');

          // Zakładamy sygnaturę: procedure ZapytajChatGPT(const ApiKey, Model, UserQuestion: string; Callback: TResponseCallback);
       end
       else
         raise Exception.Create('Błąd składni zapytaj: Oczekiwano 3 argumentów (klucz, model, pytanie), otrzymano ' + IntToStr(Length(Args)) + ' w "' + ArgStr + '"');
    end
    else
       raise Exception.Create('Błąd składni zapytaj (nawiasy): ' + TrimmedLine);
    Exit; // Zakończ przetwarzanie
  end

    // 3. Obsługa deklaracji zmiennych z czytaj()
    else if Pos('czytaj(', LowerCase(TrimmedLine)) > 0 then
    begin
      Parts := TrimmedLine.Split(['='], 2);
      VarName := Trim(Parts[0]);
      Value := Trim(Parts[1]);

      if Pos(' ', VarName) > 0 then
      begin
        Parts := VarName.Split([' '], 2);
        VarType := Parts[0];
        VarName := Parts[1];
        AddVariable(VarName, VarType);
      end;
        // Usuwamy prefiks "czytaj(" – zakładamy, że bez nawiasu otwierającego wyrażenie zaczyna się dopiero po 6 znakach
      Value := Copy(Value, 7, Length(Value) - 6);
        // Jeśli pierwszy znak wyniku to nawias otwierający, usuń go
      if (Length(Value) > 0) and (Value[1] = '(') then
        Value := Copy(Value, 2, Length(Value) - 1);
      // Jeśli ostatni znak wyniku to nawias zamykający, usuń go
      if (Length(Value) > 0) and (Value[Length(Value)] = ')') then
        Value := Copy(Value, 1, Length(Value) - 1);
      PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
      PascalCode.Add('Read(' + VarName + ');');
    end

    // Blok obsługi "czytajnl(...)"
     else if Pos('czytajnl(', LowerCase(TrimmedLine)) > 0 then
     begin
       Parts := TrimmedLine.Split(['='], 2);
       VarName := Trim(Parts[0]);
       Value := Trim(Parts[1]);

       if Pos(' ', VarName) > 0 then
       begin
         Parts := VarName.Split([' '], 2);
         VarType := Parts[0];
         VarName := Parts[1];
         AddVariable(VarName, VarType);
       end;
       // Znajdź nawias otwierający i zamykający w Value dla czytajnl
       Start := Pos('(', Value);
       if Start = 0 then
         raise Exception.Create('Brak otwierającego nawiasu w czytajnl');
       EndPos := Length(Value);
       while (EndPos > 0) and (Value[EndPos] <> ')') do
         Dec(EndPos);
       if EndPos = 0 then
         raise Exception.Create('Brak zamykającego nawiasu w czytajnl');
       // Wyciągnij parametr wewnątrz nawiasów
       Value := Trim(Copy(Value, Start + 1, EndPos - Start - 1));

       PascalCode.Add('Write(' + TranslateExpression(Value) + ');');
       PascalCode.Add('Readln(' + VarName + ');');
     end

   //Ustawieni długośći w tablice
    else if LowerCase(TrimmedLine).StartsWith('ustaw długość(') then
    begin
      // Wycinamy zawartość nawiasów.
      // Długość frazy "ustaw długość(" wynosi: Length('ustaw długość(')
      Value := Copy(TrimmedLine, Length('ustaw długość(') + 1, Length(TrimmedLine) - Length('ustaw długość(') - 1);
      Value := Trim(Value);
      // Generujemy kod: SetLength( <argumenty> );
      PascalCode.Add('SetLength(' + TranslateExpression(Value) + ');');
      //Exit;
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
        AddVariable(VarName, VarType);
      end;

      PascalCode.Add(VarName + ' := ' + TranslateExpression(Value) + ';');
    end


    // 5. Obsługa pozostałych linii
    else if TrimmedLine <> '' then
    begin
      PascalCode.Add(TrimmedLine + ';');
    end;
  end;
//end;


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
    DetectedProgramName := 'ProgramBezNazwy'; // Domyślna nazwa

    for i := 0 to AvocadoCode.Count - 1 do
    begin
      trimmedLine := Trim(AvocadoCode[i]);
      // Szukaj tylko standardowego 'program'
      if LowerCase(trimmedLine).StartsWith('program ') then
      begin
        NameProgram := Trim(Copy(trimmedLine, Length('program ') + 1, MaxInt));
        if NameProgram = '' then NameProgram := 'ProgramBezNazwy';
        DetectedProgramName := NameProgram;
        Break; // Znaleziono deklarację, przerwij skanowanie
      end;
    end;
    // --- KONIEC SKANOWANIA ---

    try
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
      // Generuj sekcję 'var' (PRZYWRÓCONO PEŁNĄ OBSŁUGĘ TYPÓW)
      if Length(FVariables) > 0 then
      begin
        PascalCode.Add('var');
        for i := 0 to High(FVariables) do
        begin
          // deklaracja zmiennych
          if LowerCase(FVariables[i].VarType) = 'liczba_całkowita' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Integer;')
          else if LowerCase(FVariables[i].VarType) = 'lc' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Integer;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_zm' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Real;')
          else if LowerCase(FVariables[i].VarType) = 'lzm' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Real;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Boolean;')

          else if LowerCase(FVariables[i].VarType) = 'znak' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Char;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_krótka' then
            PascalCode.Add('  ' + FVariables[i].Name + ': ShortInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_mała' then
            PascalCode.Add('  ' + FVariables[i].Name + ': SmallInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_długa' then
            PascalCode.Add('  ' + FVariables[i].Name + ': LongInt;')
          else if LowerCase(FVariables[i].VarType) = 'liczba64' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Int64;')
          else if LowerCase(FVariables[i].VarType) = 'bajt' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Byte;')
          else if LowerCase(FVariables[i].VarType) = 'liczba16' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Word;')
          else if LowerCase(FVariables[i].VarType) = 'liczba32' then
            PascalCode.Add('  ' + FVariables[i].Name + ': LongWord;')
          else if LowerCase(FVariables[i].VarType) = 'tekst' then
             PascalCode.Add('  ' + FVariables[i].Name + ': String;') // Dodano obsługę 'tekst'
          else if LowerCase(FVariables[i].VarType) = 'tablicaliczb' then
            PascalCode.Add('  ' + FVariables[i].Name + ': array of Integer;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_pojedyncza' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Single;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_podwójna' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Double;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_rozszerzona' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Extended;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_zgodna_delphi' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Comp;')
          else if LowerCase(FVariables[i].VarType) = 'liczba_waluta' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Currency;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny_bajt' then
            PascalCode.Add('  ' + FVariables[i].Name + ': ByteBool;')
          else if LowerCase(FVariables[i].VarType) = 'logiczne_słowo' then
            PascalCode.Add('  ' + FVariables[i].Name + ': WordBool;')
          else if LowerCase(FVariables[i].VarType) = 'logiczny_długi' then
            PascalCode.Add('  ' + FVariables[i].Name + ': LongBool;')
          else if LowerCase(FVariables[i].VarType) = 'znak_unicode' then
            PascalCode.Add('  ' + FVariables[i].Name + ': WideChar;')
          else if LowerCase(FVariables[i].VarType) = 'tekst255' then
            PascalCode.Add('  ' + FVariables[i].Name + ': ShortString;')
          else if LowerCase(FVariables[i].VarType) = 'tekst_ansi' then
            PascalCode.Add('  ' + FVariables[i].Name + ': AnsiString;')
          else if LowerCase(FVariables[i].VarType) = 'tekst_unicode' then
            PascalCode.Add('  ' + FVariables[i].Name + ': UnicodeString;')
          // Poniższe typy mogą wymagać bardziej złożonej obsługi niż prosta deklaracja
          else if LowerCase(FVariables[i].VarType) = 'tablica_dynamiczna' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Array of Variant;') // Przykład: tablica wariantów
          else if LowerCase(FVariables[i].VarType) = 'rekord' then
            PascalCode.Add('  { TODO: Zdefiniuj typ rekordu dla ' + FVariables[i].Name + ' }')
          else if LowerCase(FVariables[i].VarType) = 'kolekcja' then
             PascalCode.Add('  ' + FVariables[i].Name + ': Set of Byte;') // Przykład: set of byte
          else if LowerCase(FVariables[i].VarType) = 'plik' then
            PascalCode.Add('  ' + FVariables[i].Name + ': File;')
          else if LowerCase(FVariables[i].VarType) = 'plik_tekstowy' then
            PascalCode.Add('  ' + FVariables[i].Name + ': TextFile;')
          else if LowerCase(FVariables[i].VarType) = 'plik_binarny' then
             PascalCode.Add('  ' + FVariables[i].Name + ': File;') // Lub File of Byte
          else if LowerCase(FVariables[i].VarType) = 'plik_struktur' then
             PascalCode.Add('  { TODO: Zdefiniuj typ pliku dla ' + FVariables[i].Name + ': File of ... }')
          else if LowerCase(FVariables[i].VarType) = 'wskaźnik' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Pointer;')
          else if LowerCase(FVariables[i].VarType) = 'wskaźnik_na' then
             PascalCode.Add('  { TODO: Zdefiniuj typ wskazywany dla ' + FVariables[i].Name + ': ^... }')
          else if LowerCase(FVariables[i].VarType) = 'wariant' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Variant;')
          else if LowerCase(FVariables[i].VarType) = 'wariant_ole' then
            PascalCode.Add('  ' + FVariables[i].Name + ': OleVariant;')
          else if LowerCase(FVariables[i].VarType) = 'tablicatekstów' then
            PascalCode.Add('  ' + FVariables[i].Name + ': TStringArray;') // Użyj zdefiniowanego typu
          else if LowerCase(FVariables[i].VarType) = 'stała' then
            PascalCode.Add('  ' + FVariables[i].Name + ': Const;')
          else // Domyślnie lub jeśli typ nie został rozpoznany (choć nie powinien, jeśli IsValidAvocadoType działa)
             PascalCode.Add('  ' + FVariables[i].Name + ': String;');
        end;
        PascalCode.Add('');
      end;

      // Dodaj główny blok programu
      PascalCode.Add('begin');
      // Zawsze dodawaj ustawienia konsoli
      PascalCode.Add('  SetConsoleOutputCP(CP_UTF8);');
      PascalCode.Add('  SetConsoleCP(CP_UTF8);');

      // Przetwarzaj linie kodu wykonywalnego
      for i := 0 to AvocadoCode.Count - 1 do
      begin
        trimmedLine := Trim(AvocadoCode[i]);
        if trimmedLine = '' then Continue;

        // Pomiń linie 'program', 'importuj', 'ModułyPas'
        if AnsiStartsText('program ', trimmedLine) or
           AnsiStartsText('importuj', trimmedLine) or
           AnsiStartsText('ModułyPas', trimmedLine) then
        begin
          Continue;
        end
        else
        begin
          ProcessLine(trimmedLine, PascalCode);
        end;
      end;

      // Zawsze dodawaj Readln
      PascalCode.Add('  Readln;');
      PascalCode.Add('end.');

      Result := PascalCode;
    finally
      UsesList.Free;
      ExistingUnits.Free;
    end;
  end;



end.

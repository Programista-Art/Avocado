unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

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
  public
    function Translate(const AvocadoCode: TStrings): TStringList;
  end;


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
           (VarType = 'liczba_zm') or
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

//przetwarzanie zagnieżdżonych instrukcji.
procedure TAvocadoTranslator.ProcessLine(const Line: string; PascalCode: TStringList);
var
  Parts: TStringArray;
   VarType, VarName, Value, TrimmedLine: string;
   InstrukcjaWarunkowa: TStringArray;
   KodWtedy, KodInaczej: string;
   TempList: TStringList;
   Statements: TStringArray;
   Statement: string;
begin
  TrimmedLine := Trim(Line);

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


    // 2. Obsługa funkcji pisz
    else if LowerCase(TrimmedLine).StartsWith('pisz(') then
    begin
       // Pobieramy zawartość między "druk(" a ostatnim znakiem
      Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
      //Exit;
    end

    // 3. Obsługa deklaracji zmiennych z wpr()
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
      PascalCode.Add('Readln(' + VarName + ');');

     // PascalCode.Add('Write(' + TranslateExpression(Value) + ');');

      //PascalCode.Add('Readln(' + VarName + ');');
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

function TAvocadoTranslator.Translate(const AvocadoCode: TStrings): TStringList;
var
  PascalCode: TStringList;
  i: Integer;
  trimmedLine: string;
begin
 SetLength(FVariables, 0);  // Czyści listę zmiennych
  PascalCode := TStringList.Create;
  try
    PascalCode.Add('{$mode objfpc}');
    PascalCode.Add('{$H+}');// Domyślnie w Lazarusa: String = AnsiString
    PascalCode.Add('program ' + NameProgram + ';');

    //PascalCode.Add('{$codepage UTF8}');
    //if SaveFileProject <> '' then
    //  PascalCode.Add('program ' + NameProgram + ';')
    //else if OpenFileProject <> '' then
    //  PascalCode.Add('program ' + NameProgram + ';')
    //else

    {
    if SaveFileProject = '' then
      PascalCode.Add('program ' + OpenFileProject + ';')
    else if
      PascalCode.Add('program ' + SaveFileProject + ';') then
    else
      PascalCode.Add('program ' + NameProgram + ';');
      }

    // Dodajemy moduły
    PascalCode.Add('uses Windows, SysUtils;');
    PascalCode.Add('');

    // Najpierw wykrywamy deklaracje zmiennych!
    for i := 0 to AvocadoCode.Count - 1 do
      ProcessDeclaration(Trim(AvocadoCode[i]));
    // Dodajemy sekcję var
        if Length(FVariables) > 0 then
    begin
      PascalCode.Add('var');
      for i := 0 to High(FVariables) do
      begin
        if LowerCase(FVariables[i].VarType) = 'liczba_całkowita' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Integer;')
        else if LowerCase(FVariables[i].VarType) = 'liczba_zm' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Real;')
        else if LowerCase(FVariables[i].VarType) = 'liczba_krótka' then
          PascalCode.Add('  ' + FVariables[i].Name + ': ShortInt;')
        else if LowerCase(FVariables[i].VarType) = 'logiczny' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Boolean;')
        else if LowerCase(FVariables[i].VarType) = 'znak' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Char;')
        else if LowerCase(FVariables[i].VarType) = 'tablicaliczb' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of Integer;')
        else if LowerCase(FVariables[i].VarType) = 'tablicatekstów' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of String;')
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
        else if LowerCase(FVariables[i].VarType) = 'tablica_dynamiczna' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Array of typ;')
        else if LowerCase(FVariables[i].VarType) = 'rekord' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Record ... end;')
        else if LowerCase(FVariables[i].VarType) = 'kolekcja' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Set of typ;')
        else if LowerCase(FVariables[i].VarType) = 'plik' then
          PascalCode.Add('  ' + FVariables[i].Name + ': File;')
        else if LowerCase(FVariables[i].VarType) = 'plik_tekstowy' then
          PascalCode.Add('  ' + FVariables[i].Name + ': TextFile;')
        else if LowerCase(FVariables[i].VarType) = 'plik_binarny' then
          PascalCode.Add('  ' + FVariables[i].Name + ': BinaryFile;')
        else if LowerCase(FVariables[i].VarType) = 'plik_struktur' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Typed File;')
        else if LowerCase(FVariables[i].VarType) = 'wskaźnik' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Pointer;')
        else if LowerCase(FVariables[i].VarType) = 'wskaźnik_na' then
          PascalCode.Add('  ' + FVariables[i].Name + ': ^typ;')
        else if LowerCase(FVariables[i].VarType) = 'wariant' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Variant;')
        else if LowerCase(FVariables[i].VarType) = 'wariant_ole' then
          PascalCode.Add('  ' + FVariables[i].Name + ': OleVariant;')

        else
          PascalCode.Add('  ' + FVariables[i].Name + ': String;');


        {
        if FVariables[i].VarType = 'Liczbac' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Integer;')
        else if FVariables[i].VarType = 'Liczbar' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Real;')
        else if FVariables[i].VarType = 'Logika' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Boolean;')
        else if FVariables[i].VarType = 'Znak' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Char;')
        else if FVariables[i].VarType = 'TablicaLiczb' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of Integer;')
        else if FVariables[i].VarType = 'TablicaTekstów' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of String;')
        else
        }
          //PascalCode.Add('  ' + FVariables[i].Name + ': String;');
      end;
      PascalCode.Add('');
    end;

    // Dodajemy kod programu
    PascalCode.Add('begin');
    // Ustaw konsolę na UTF-8 (tylko Windows)
    PascalCode.Add('SetConsoleOutputCP(CP_UTF8);');
    PascalCode.Add('SetConsoleCP(CP_UTF8);');

     // Przetwarzamy linie kodu wejściowego
    for i := 0 to AvocadoCode.Count - 1 do
    begin
      trimmedLine := Trim(AvocadoCode[i]);
      // Jeśli linia zaczyna się od "program " (bez względu na wielkość liter), pomijamy ją
      if Copy(LowerCase(trimmedLine), 1, 8) = 'program ' then
        Continue;
      ProcessLine(trimmedLine, PascalCode);
    end;

    {for i := 0 to AvocadoCode.Count - 1 do
      ProcessLine(Trim(AvocadoCode[i]), PascalCode);  }



    PascalCode.Add('Readln;');
    PascalCode.Add('end.');

    Result := PascalCode;
  except
    PascalCode.Free;
    raise;
  end;
end;

end.

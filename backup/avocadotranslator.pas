unit AvocadoTranslator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

type
  TStringArray = array of string;

  { TAvocadoTranslator }

  TAvocadoTranslator = class
  private
    FVariables: array of record
      Name, VarType: string;
    end;
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
  Result := StringReplace(Result, 'LiczbacWlk(', 'Shortint(', [rfReplaceAll]);
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
         //(LowerCase(Trim(Line)).StartsWith('druk(')) //or
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
        // Dozwolone typy: liczbac, liczbar, logika, znak, tekst, tablicaliczb, tablicatekstów
        if (VarType = 'liczbac') or (VarType = 'liczbar') or
           (VarType = 'logika') or (VarType = 'znak') or
           (VarType = 'tekst') or (VarType = 'tablicaliczb') or (VarType = 'tablicatekstów') then
        begin
          AddVariable(VarName, VarType);
        end
        else
          raise Exception.Create('Nieznany typ zmiennej: ' + VarType);
      end;
end;


{ Przetwarzanie pętli for w formacie: }
{   dla <zmienna> od <początek> do <koniec> { <ciało> } }
procedure TAvocadoTranslator.ProcessForLoop(const Line: string; PascalCode: TStringList);
var
  WithoutFor, Header, Body: string;
  VarName, StartValue, EndValue: string;
  OpenBracketPos, CloseBracketPos: Integer;
  HeaderParts: TArray<string>;
  BodyStatements: TArray<string>;
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
  HeaderParts := Header.Split([' ']);
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
  BodyStatements := Body.Split([';']);
  for var i := 0 to High(BodyStatements) do
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


    // 2. Obsługa funkcji druk
    else if LowerCase(TrimmedLine).StartsWith('druk(') then
    begin
       // Pobieramy zawartość między "druk(" a ostatnim znakiem
      Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
      //Exit;
    end

    // 3. Obsługa deklaracji zmiennych z wpr()
    else if Pos('wpr(', LowerCase(TrimmedLine)) > 0 then
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

      Value := Copy(Value, 5, Length(Value) - 5);
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

function TAvocadoTranslator.Translate(const AvocadoCode: TStrings): TStringList;
var
  PascalCode: TStringList;
  i: Integer;
begin
 SetLength(FVariables, 0);  // Czyści listę zmiennych
  PascalCode := TStringList.Create;
  try
    if SaveFileProject = '' then
      PascalCode.Add('program ' + OpenFileProject + ';')
    else
      PascalCode.Add('program ' + SaveFileProject + ';');

    // Dodajemy moduły
    PascalCode.Add('uses SysUtils;');
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
        if LowerCase(FVariables[i].VarType) = 'liczbac' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Integer;')
        else if LowerCase(FVariables[i].VarType) = 'liczbar' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Real;')
        else if LowerCase(FVariables[i].VarType) = 'logika' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Boolean;')
        else if LowerCase(FVariables[i].VarType) = 'znak' then
          PascalCode.Add('  ' + FVariables[i].Name + ': Char;')
        else if LowerCase(FVariables[i].VarType) = 'tablicaliczb' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of Integer;')
        else if LowerCase(FVariables[i].VarType) = 'tablicatekstów' then
          PascalCode.Add('  ' + FVariables[i].Name + ': array of String;')
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

    for i := 0 to AvocadoCode.Count - 1 do
      ProcessLine(Trim(AvocadoCode[i]), PascalCode);

    PascalCode.Add('Readln;');
    PascalCode.Add('end.');

    Result := PascalCode;
  except
    PascalCode.Free;
    raise;
  end;
end;

end.

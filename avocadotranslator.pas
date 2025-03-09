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
end;

procedure TAvocadoTranslator.ProcessDeclaration(const Line: string);
var
  Parts: TStringArray;
  VarType, VarName: string;
begin
  Parts := Line.Split(['='], 2);
  VarName := Trim(Parts[0]);

  if Pos(' ', VarName) > 0 then
  begin
    Parts := VarName.Split([' '], 2);
    VarType := Trim(Parts[0]);
    VarName := Trim(Parts[1]);
    AddVariable(VarName, VarType);
  end;
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
    if Pos('jesli ', LowerCase(TrimmedLine)) = 1 then
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
      Value := Copy(TrimmedLine, 6, Length(TrimmedLine) - 6);
      Value := StringReplace(Value, ')', '', [rfReplaceAll]);
      PascalCode.Add('Writeln(' + TranslateExpression(Value) + ');');
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
  SetLength(FVariables, 0);
  PascalCode := TStringList.Create;
  try
    PascalCode.Add('program ' + SaveFileProject + ';');
    PascalCode.Add('uses SysUtils;');
    PascalCode.Add('var');

    for i := 0 to AvocadoCode.Count - 1 do
      ProcessDeclaration(Trim(AvocadoCode[i]));

    for i := 0 to High(FVariables) do
      PascalCode.Add('  ' + FVariables[i].Name + ': ' +
        IfThen(FVariables[i].VarType = 'Liczbac', 'Integer',
          IfThen(FVariables[i].VarType = 'Liczbar', 'Real',
            IfThen(FVariables[i].VarType = 'Logika', 'Boolean', 'String'))) + ';');

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

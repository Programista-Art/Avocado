unit avocado_codegen;

{$mode objfpc}{$H+}

{ Deterministic Pascal code generation from the Avocado AST.
  Preserves statement order, initialization order, console/GUI behavior.
  Derives automatic imports from actually resolved operations. }

interface

uses
  SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_ast,
  avocado_language, avocado_sourcemap;

type
  TAvocadoCodeGenerator = class
  private
    FLang: TAvocadoLanguage;
    FDiags: TAvocadoDiagnosticList;
    FSrc: TAvocadoSource;
    FOut: TStringList;
    FMap: TAvocadoSourceMap;
    FUses: TStringList;
    FIsGui: Boolean;
    FCodePage: string;
    FWinCp: string;
    procedure AddLine(const S: string; const ASpan: TAvocadoSourceSpan;
      AIsScaffold: Boolean = False);
    procedure AddScaffold(const S: string);
    procedure EnsureUnit(const AName: string);
    function GenExpr(AExpr: TAvocadoExpr): string;
    procedure GenStmt(AStmt: TAvocadoStmt; AIndent: Integer);
    procedure GenBlock(ABlock: TAvocadoBlockStmt; AIndent: Integer);
    procedure GenRoutine(ARoutine: TAvocadoRoutine);
    procedure GenVarSection(ANodes: TAvocadoNodeArray; AIndent: Integer);
    procedure GenInitAssignments(ANodes: TAvocadoNodeArray; AIndent: Integer);
    function EmitString(const S: string): string;
    function Ind(AIndent: Integer): string;
    procedure GenRoutineHeader(ARoutine: TAvocadoRoutine; AIsForward: Boolean);
  public
    constructor Create(ALang: TAvocadoLanguage; ADiags: TAvocadoDiagnosticList;
      ASrc: TAvocadoSource; AMap: TAvocadoSourceMap);
    destructor Destroy; override;
    function Generate(AProg: TAvocadoProgram): TStringList;
  end;

implementation

constructor TAvocadoCodeGenerator.Create(ALang: TAvocadoLanguage;
  ADiags: TAvocadoDiagnosticList; ASrc: TAvocadoSource; AMap: TAvocadoSourceMap);
begin
  inherited Create;
  FLang := ALang;
  FDiags := ADiags;
  FSrc := ASrc;
  FMap := AMap;
  FOut := TStringList.Create;
  FUses := TStringList.Create;
  FUses.CaseSensitive := False;
  FCodePage := 'utf8';
  FWinCp := '65001';
end;

destructor TAvocadoCodeGenerator.Destroy;
begin
  FOut.Free;
  FUses.Free;
  inherited Destroy;
end;

function TAvocadoCodeGenerator.Ind(AIndent: Integer): string;
begin
  Result := StringOfChar(' ', AIndent * 2);
end;

procedure TAvocadoCodeGenerator.AddLine(const S: string;
  const ASpan: TAvocadoSourceSpan; AIsScaffold: Boolean);
begin
  FOut.Add(S);
  if AIsScaffold then
    FMap.MapScaffold(FOut.Count)
  else
    FMap.Map(FOut.Count, ASpan, False);
end;

procedure TAvocadoCodeGenerator.AddScaffold(const S: string);
begin
  FOut.Add(S);
  FMap.MapScaffold(FOut.Count);
end;

procedure TAvocadoCodeGenerator.EnsureUnit(const AName: string);
begin
  if (AName <> '') and (FUses.IndexOf(AName) < 0) then
    FUses.Add(AName);
end;

function TAvocadoCodeGenerator.EmitString(const S: string): string;
var
  I: Integer;
  InQuote: Boolean;
  C: Char;
begin
  if S = '' then Exit('''''');
  Result := '';
  InQuote := False;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (C < #32) then
    begin
      if InQuote then
      begin
        Result := Result + '''';
        InQuote := False;
      end;
      Result := Result + '#' + IntToStr(Ord(C));
    end
    else
    begin
      if not InQuote then
      begin
        Result := Result + '''';
        InQuote := True;
      end;
      if C = '''' then
        Result := Result + ''''''
      else
        Result := Result + C;
    end;
  end;
  if InQuote then
    Result := Result + '''';
end;

function TAvocadoCodeGenerator.GenExpr(AExpr: TAvocadoExpr): string;
var
  Call: TAvocadoCallExpr;
  B: TAvocadoBuiltin;
  I: Integer;
  Args: string;
  Name: string;
  Mapped: string;
  Resolved: string;
  S: TAvocadoSetExpr;
begin
  Result := '';
  if AExpr = nil then Exit('');

  if AExpr is TAvocadoIntegerLit then
    Exit(IntToStr(TAvocadoIntegerLit(AExpr).Value));
  if AExpr is TAvocadoFloatLit then
    Exit(StringReplace(FloatToStr(TAvocadoFloatLit(AExpr).Value), ',', '.', [rfReplaceAll]));
  if AExpr is TAvocadoStringLit then
    Exit(EmitString(TAvocadoStringLit(AExpr).Value));
  if AExpr is TAvocadoBoolLit then
  begin
    if TAvocadoBoolLit(AExpr).Value then Exit('True') else Exit('False');
  end;
  if AExpr is TAvocadoNilLit then
    Exit('nil');
  if AExpr is TAvocadoIdentExpr then
  begin
    Name := TAvocadoIdentExpr(AExpr).Name;
    // constants / member names stay as written; builtins mapped
    if FLang.FindBuiltin(Name, B) then
    begin
      if B.Kind = abkConstant then
        Exit(B.PascalName);
      if B.RequiredUnit <> '' then
        EnsureUnit(B.RequiredUnit);
      // parameterless builtin used without parentheses
      if (B.Kind in [abkFunction, abkProcedure]) and (B.MaxArgs = 0) then
        Exit(B.PascalName + '()');
    end;
    Mapped := FLang.LookupFunctionMap(Name);
    if Mapped <> '' then
      Exit(Mapped);
    Exit(Name);
  end;

  if AExpr is TAvocadoUnaryExpr then
  begin
    if TAvocadoUnaryExpr(AExpr).Op = 'not' then
      Exit('not (' + GenExpr(TAvocadoUnaryExpr(AExpr).Operand) + ')');
    Exit(TAvocadoUnaryExpr(AExpr).Op + ' (' + GenExpr(TAvocadoUnaryExpr(AExpr).Operand) + ')');
  end;

  if AExpr is TAvocadoBinaryExpr then
  begin
    Result := '(' + GenExpr(TAvocadoBinaryExpr(AExpr).Left) + ' ' +
      TAvocadoBinaryExpr(AExpr).Op + ' ' +
      GenExpr(TAvocadoBinaryExpr(AExpr).Right) + ')';
    Exit;
  end;

  if AExpr is TAvocadoCallExpr then
  begin
    Call := TAvocadoCallExpr(AExpr);
    if (Call.CalleeName = '') and (Call.ArgCount > 0) then
    begin
      Name := GenExpr(TAvocadoExpr(Call.Args[0]));
      Args := '';
      for I := 1 to High(Call.Args) do
      begin
        if I > 1 then Args := Args + ', ';
        Args := Args + GenExpr(TAvocadoExpr(Call.Args[I]));
      end;
      Result := Name + '(' + Args + ')';
      Exit;
    end;
    Name := Call.CalleeName;
    Mapped := FLang.LookupFunctionMap(Name);
    if FLang.FindBuiltin(Name, B) then
    begin
      if B.RequiredUnit <> '' then
        EnsureUnit(B.RequiredUnit);
      Name := B.PascalName;

      // special lowerings
      if (B.AvocadoName = 'twórz_lista_tekstów') or (B.AvocadoName = 'tworz_lista_tekstow') or
         (B.AvocadoName = 'create_string_list') then
      begin
        // create list: arg is the variable being created
        if Call.ArgCount >= 1 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + ' := TStringList.Create'
        else
          Result := 'TStringList.Create';
        Exit;
      end;
      if (B.AvocadoName = 'twórz_strumień_pliku') or (B.AvocadoName = 'tworz_strumien_pliku') or
         (B.AvocadoName = 'create_file_stream') then
      begin
        if Call.ArgCount >= 3 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + ' := TFileStream.Create(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ', ' + GenExpr(TAvocadoExpr(Call.Args[2])) + ')'
        else if Call.ArgCount >= 2 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + ' := TFileStream.Create(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ', fmOpenRead)'
        else
          Result := 'TFileStream.Create';
        Exit;
      end;
      if (B.AvocadoName = 'dodaj_lista') or (B.AvocadoName = 'add_to_list') then
      begin
        if Call.ArgCount >= 2 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.Add(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ')'
        else
          Result := Name;
        Exit;
      end;
      if (B.AvocadoName = 'zwolnij') or (B.AvocadoName = 'free') then
      begin
        if Call.ArgCount >= 1 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.Free'
        else
          Result := 'Free';
        Exit;
      end;
      if (B.AvocadoName = 'teksty') or (B.AvocadoName = 'strings') then
      begin
        if Call.ArgCount >= 2 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.Strings[' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ']'
        else
          Result := 'Strings';
        Exit;
      end;
      if (B.AvocadoName = 'ilosc') or (B.AvocadoName = 'ilość') or (B.AvocadoName = 'count') then
      begin
        if Call.ArgCount >= 1 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.Count'
        else
          Result := 'Count';
        Exit;
      end;
      if (B.AvocadoName = 'załaduj_z_pliku') or (B.AvocadoName = 'zaladuj_z_pliku') or
         (B.AvocadoName = 'load_from_file') then
      begin
        if Call.ArgCount >= 2 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.LoadFromFile(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ')'
        else
          Result := 'LoadFromFile';
        Exit;
      end;
      if (B.AvocadoName = 'zapisz_do_pliku') or (B.AvocadoName = 'save_to_file') then
      begin
        if Call.ArgCount >= 2 then
          Result := GenExpr(TAvocadoExpr(Call.Args[0])) + '.SaveToFile(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ')'
        else
          Result := 'SaveToFile';
        Exit;
      end;
    end
    else if Mapped <> '' then
      Name := Mapped
    else
      Name := Call.ResolvedName;

    Args := '';
    for I := 0 to High(Call.Args) do
    begin
      if I > 0 then Args := Args + ', ';
      // Default(T) / SizeOf(T) / High(T): argument is a type name
      if ((AvocadoLowerCase(Name) = 'default') or (AvocadoLowerCase(Name) = 'sizeof') or
          (AvocadoLowerCase(Name) = 'high') or (AvocadoLowerCase(Name) = 'low') or
          (AvocadoLowerCase(Name) = 'typeinfo')) and
         (Call.Args[I] is TAvocadoIdentExpr) then
      begin
        Resolved := FLang.ResolveType(TAvocadoIdentExpr(Call.Args[I]).Name);
        if Resolved = '' then
          Resolved := TAvocadoIdentExpr(Call.Args[I]).Name;
        Args := Args + Resolved;
      end
      else
        Args := Args + GenExpr(TAvocadoExpr(Call.Args[I]));
    end;
    // parameterless calls keep empty parens only when written with them;
    // we always emit parens for calls with a name (Pascal style)
    Result := Name + '(' + Args + ')';
    Exit;
  end;

  if AExpr is TAvocadoIndexExpr then
    Exit(GenExpr(TAvocadoIndexExpr(AExpr).Base) + '[' +
      GenExpr(TAvocadoIndexExpr(AExpr).Index) + ']');

  if AExpr is TAvocadoMemberExpr then
  begin
    // member name aliases (Polish property names)
    Name := TAvocadoMemberExpr(AExpr).MemberName;
    if AvocadoLowerCase(Name) = 'tekst' then Name := 'Text'
    else if AvocadoLowerCase(Name) = 'zwolnij' then Name := 'Free'
    else if AvocadoLowerCase(Name) = 'ilosc' then Name := 'Count'
    else if AvocadoLowerCase(Name) = 'ilość' then Name := 'Count';
    Exit(GenExpr(TAvocadoMemberExpr(AExpr).Base) + '.' + Name);
  end;

  if AExpr is TAvocadoFormatExpr then
  begin
    Result := GenExpr(TAvocadoFormatExpr(AExpr).Value);
    if TAvocadoFormatExpr(AExpr).HasWidth then
      Result := Result + ':' + IntToStr(TAvocadoFormatExpr(AExpr).Width);
    if TAvocadoFormatExpr(AExpr).HasDecimals then
      Result := Result + ':' + IntToStr(TAvocadoFormatExpr(AExpr).Decimals);
    Exit;
  end;

  if AExpr is TAvocadoSetExpr then
  begin
    S := TAvocadoSetExpr(AExpr);
    Result := '[';
    for I := 0 to High(S.Items) do
    begin
      if I > 0 then Result := Result + ', ';
      Result := Result + GenExpr(TAvocadoExpr(S.Items[I]));
    end;
    Result := Result + ']';
  end;
end;

procedure TAvocadoCodeGenerator.GenStmt(AStmt: TAvocadoStmt; AIndent: Integer);
var
  Call: TAvocadoCallExpr;
  B: TAvocadoBuiltin;
  Name, Args: string;
  I: Integer;
  Esc: string;
begin
  if AStmt = nil then Exit;

  if AStmt is TAvocadoBlockStmt then
  begin
    AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
    GenBlock(TAvocadoBlockStmt(AStmt), AIndent + 1);
    AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
    Exit;
  end;

  if AStmt is TAvocadoVarDecl then
  begin
    // local decl inside a statement list: emit as assignment if it has init
    if TAvocadoVarDecl(AStmt).InitValue <> nil then
      AddLine(Ind(AIndent) + TAvocadoVarDecl(AStmt).VarName + ' := ' +
        GenExpr(TAvocadoVarDecl(AStmt).InitValue) + ';', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoAssignStmt then
  begin
    AddLine(Ind(AIndent) + GenExpr(TAvocadoAssignStmt(AStmt).Target) + ' := ' +
      GenExpr(TAvocadoAssignStmt(AStmt).Value) + ';', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoCallStmt then
  begin
    Call := TAvocadoCallStmt(AStmt).Call;
    // bare member/index statement (h.zwolnij, a.tekst)
    if (Call.CalleeName = '') and (Call.ArgCount = 1) then
    begin
      AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) + ';', AStmt.Span);
      Exit;
    end;
    if (Call.CalleeName = '') and (Call.ArgCount > 1) then
    begin
      Name := GenExpr(TAvocadoExpr(Call.Args[0]));
      Args := '';
      for I := 1 to High(Call.Args) do
      begin
        if I > 1 then Args := Args + ', ';
        Args := Args + GenExpr(TAvocadoExpr(Call.Args[I]));
      end;
      AddLine(Ind(AIndent) + Name + '(' + Args + ');', AStmt.Span);
      Exit;
    end;
    Name := Call.CalleeName;
    if FLang.FindBuiltin(Name, B) then
    begin
      if B.RequiredUnit <> '' then
        EnsureUnit(B.RequiredUnit);
      Name := B.PascalName;
      if (B.AvocadoName = 'twórz_lista_tekstów') or (B.AvocadoName = 'tworz_lista_tekstow') or
         (B.AvocadoName = 'create_string_list') then
      begin
        if Call.ArgCount >= 1 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) +
            ' := TStringList.Create;', AStmt.Span)
        else
          AddLine(Ind(AIndent) + 'TStringList.Create;', AStmt.Span);
        Exit;
      end;
      if (B.AvocadoName = 'twórz_strumień_pliku') or (B.AvocadoName = 'tworz_strumien_pliku') or
         (B.AvocadoName = 'create_file_stream') then
      begin
        if Call.ArgCount >= 3 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) +
            ' := TFileStream.Create(' + GenExpr(TAvocadoExpr(Call.Args[1])) + ', ' +
            GenExpr(TAvocadoExpr(Call.Args[2])) + ');', AStmt.Span)
        else if Call.ArgCount >= 2 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) +
            ' := TFileStream.Create(' + GenExpr(TAvocadoExpr(Call.Args[1])) + ', fmOpenRead);', AStmt.Span)
        else
          AddLine(Ind(AIndent) + 'TFileStream.Create;', AStmt.Span);
        Exit;
      end;
      if (B.AvocadoName = 'dodaj_lista') or (B.AvocadoName = 'add_to_list') then
      begin
        if Call.ArgCount >= 2 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) + '.Add(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ');', AStmt.Span)
        else
          AddLine(Ind(AIndent) + 'Add;', AStmt.Span);
        Exit;
      end;
      if (B.AvocadoName = 'zwolnij') or (B.AvocadoName = 'free') then
      begin
        if Call.ArgCount >= 1 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) + '.Free;',
            AStmt.Span)
        else
          AddLine(Ind(AIndent) + 'Free;', AStmt.Span);
        Exit;
      end;
      if (B.AvocadoName = 'załaduj_z_pliku') or (B.AvocadoName = 'zaladuj_z_pliku') or
         (B.AvocadoName = 'load_from_file') then
      begin
        if Call.ArgCount >= 2 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) + '.LoadFromFile(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ');', AStmt.Span);
        Exit;
      end;
      if (B.AvocadoName = 'zapisz_do_pliku') or (B.AvocadoName = 'save_to_file') then
      begin
        if Call.ArgCount >= 2 then
          AddLine(Ind(AIndent) + GenExpr(TAvocadoExpr(Call.Args[0])) + '.SaveToFile(' +
            GenExpr(TAvocadoExpr(Call.Args[1])) + ');', AStmt.Span);
        Exit;
      end;
    end
    else
    begin
      Name := Call.ResolvedName;
      if FLang.LookupFunctionMap(Call.CalleeName) <> '' then
        Name := FLang.LookupFunctionMap(Call.CalleeName);
    end;

    Args := '';
    for I := 0 to High(Call.Args) do
    begin
      if I > 0 then Args := Args + ', ';
      Args := Args + GenExpr(TAvocadoExpr(Call.Args[I]));
    end;
    AddLine(Ind(AIndent) + Name + '(' + Args + ');', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoIfStmt then
  begin
    AddLine(Ind(AIndent) + 'if ' + GenExpr(TAvocadoIfStmt(AStmt).Condition) + ' then',
      AStmt.Span);
    if TAvocadoIfStmt(AStmt).ThenBranch is TAvocadoBlockStmt then
    begin
      AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
      GenBlock(TAvocadoBlockStmt(TAvocadoIfStmt(AStmt).ThenBranch), AIndent + 1);
      if TAvocadoIfStmt(AStmt).ElseBranch <> nil then
        AddLine(Ind(AIndent) + 'end', AStmt.Span, True)
      else
        AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
    end
    else
    begin
      GenStmt(TAvocadoIfStmt(AStmt).ThenBranch, AIndent + 1);
      if (TAvocadoIfStmt(AStmt).ElseBranch <> nil) and
         (not (TAvocadoIfStmt(AStmt).ThenBranch is TAvocadoBlockStmt)) then
      begin
        // remove trailing semicolon of then-statement for else
        if FOut.Count > 0 then
        begin
          Esc := TrimRight(FOut[FOut.Count - 1]);
          if (Esc <> '') and (Esc[Length(Esc)] = ';') then
            FOut[FOut.Count - 1] := Copy(Esc, 1, Length(Esc) - 1);
        end;
      end;
    end;
    if TAvocadoIfStmt(AStmt).ElseBranch <> nil then
    begin
      AddLine(Ind(AIndent) + 'else', AStmt.Span);
      if TAvocadoIfStmt(AStmt).ElseBranch is TAvocadoBlockStmt then
      begin
        AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
        GenBlock(TAvocadoBlockStmt(TAvocadoIfStmt(AStmt).ElseBranch), AIndent + 1);
        AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
      end
      else
        GenStmt(TAvocadoIfStmt(AStmt).ElseBranch, AIndent + 1);
    end;
    Exit;
  end;

  if AStmt is TAvocadoForStmt then
  begin
    if TAvocadoForStmt(AStmt).IsDownto then
      AddLine(Ind(AIndent) + 'for ' + TAvocadoForStmt(AStmt).VarName + ' := ' +
        GenExpr(TAvocadoForStmt(AStmt).StartExpr) + ' downto ' +
        GenExpr(TAvocadoForStmt(AStmt).StopExpr) + ' do', AStmt.Span)
    else
      AddLine(Ind(AIndent) + 'for ' + TAvocadoForStmt(AStmt).VarName + ' := ' +
        GenExpr(TAvocadoForStmt(AStmt).StartExpr) + ' to ' +
        GenExpr(TAvocadoForStmt(AStmt).StopExpr) + ' do', AStmt.Span);
    if TAvocadoForStmt(AStmt).Body is TAvocadoBlockStmt then
    begin
      AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
      GenBlock(TAvocadoBlockStmt(TAvocadoForStmt(AStmt).Body), AIndent + 1);
      AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
    end
    else
      GenStmt(TAvocadoForStmt(AStmt).Body, AIndent + 1);
    Exit;
  end;

  if AStmt is TAvocadoForInStmt then
  begin
    AddLine(Ind(AIndent) + 'for ' + TAvocadoForInStmt(AStmt).VarName + ' in ' +
      GenExpr(TAvocadoForInStmt(AStmt).Collection) + ' do', AStmt.Span);
    if TAvocadoForInStmt(AStmt).Body is TAvocadoBlockStmt then
    begin
      AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
      GenBlock(TAvocadoBlockStmt(TAvocadoForInStmt(AStmt).Body), AIndent + 1);
      AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
    end
    else
      GenStmt(TAvocadoForInStmt(AStmt).Body, AIndent + 1);
    Exit;
  end;

  if AStmt is TAvocadoWhileStmt then
  begin
    AddLine(Ind(AIndent) + 'while ' + GenExpr(TAvocadoWhileStmt(AStmt).Condition) +
      ' do', AStmt.Span);
    if TAvocadoWhileStmt(AStmt).Body is TAvocadoBlockStmt then
    begin
      AddLine(Ind(AIndent) + 'begin', AStmt.Span, True);
      GenBlock(TAvocadoBlockStmt(TAvocadoWhileStmt(AStmt).Body), AIndent + 1);
      AddLine(Ind(AIndent) + 'end;', AStmt.Span, True);
    end
    else
      GenStmt(TAvocadoWhileStmt(AStmt).Body, AIndent + 1);
    Exit;
  end;

  if AStmt is TAvocadoRepeatStmt then
  begin
    AddLine(Ind(AIndent) + 'repeat', AStmt.Span);
    GenBlock(TAvocadoBlockStmt(TAvocadoRepeatStmt(AStmt).Body), AIndent + 1);
    AddLine(Ind(AIndent) + 'until ' + GenExpr(TAvocadoRepeatStmt(AStmt).Condition) + ';',
      AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoReturnStmt then
  begin
    if TAvocadoReturnStmt(AStmt).Value <> nil then
    begin
      AddLine(Ind(AIndent) + 'Result := ' + GenExpr(TAvocadoReturnStmt(AStmt).Value) + ';',
        AStmt.Span);
      AddLine(Ind(AIndent) + 'Exit;', AStmt.Span);
    end
    else
      AddLine(Ind(AIndent) + 'Exit;', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoBreakStmt then
  begin
    AddLine(Ind(AIndent) + 'Break;', AStmt.Span);
    Exit;
  end;
  if AStmt is TAvocadoContinueStmt then
  begin
    AddLine(Ind(AIndent) + 'Continue;', AStmt.Span);
    Exit;
  end;
  if AStmt is TAvocadoExitStmt then
  begin
    AddLine(Ind(AIndent) + 'Exit;', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoPascalBlockStmt then
  begin
    Esc := TAvocadoPascalBlockStmt(AStmt).RawCode;
    if TAvocadoPascalBlockStmt(AStmt).IsSingleLine then
      AddLine(Ind(AIndent) + Esc, AStmt.Span)
    else
    begin
      // emit raw lines
      with TStringList.Create do
      try
        Text := Esc;
        for I := 0 to Count - 1 do
          AddLine(Ind(AIndent) + Strings[I], AStmt.Span);
      finally
        Free;
      end;
    end;
    Exit;
  end;

  if AStmt is TAvocadoAsmBlockStmt then
  begin
    Esc := TAvocadoAsmBlockStmt(AStmt).RawCode;
    with TStringList.Create do
    try
      Text := Esc;
      for I := 0 to Count - 1 do
        AddLine(Ind(AIndent) + Strings[I], AStmt.Span);
    finally
      Free;
    end;
    EnsureUnit(''); // asm needs no unit
    // ASMMODE is emitted in directives when needed
  end;
end;

procedure TAvocadoCodeGenerator.GenBlock(ABlock: TAvocadoBlockStmt; AIndent: Integer);
var
  I: Integer;
begin
  if ABlock = nil then Exit;
  for I := 0 to High(ABlock.Stmts) do
    GenStmt(TAvocadoStmt(ABlock.Stmts[I]), AIndent);
end;

procedure TAvocadoCodeGenerator.GenVarSection(ANodes: TAvocadoNodeArray; AIndent: Integer);
var
  I: Integer;
  V: TAvocadoVarDecl;
  T: string;
begin
  for I := 0 to High(ANodes) do
  begin
    V := TAvocadoVarDecl(ANodes[I]);
    T := V.ResolvedTypeName;
    if T = '' then
      T := V.TypeName;
    AddLine(Ind(AIndent) + V.VarName + ': ' + T + ';', V.Span);
  end;
end;

procedure TAvocadoCodeGenerator.GenInitAssignments(ANodes: TAvocadoNodeArray; AIndent: Integer);
var
  I: Integer;
  V: TAvocadoVarDecl;
begin
  for I := 0 to High(ANodes) do
  begin
    V := TAvocadoVarDecl(ANodes[I]);
    if V.InitValue <> nil then
      AddLine(Ind(AIndent) + V.VarName + ' := ' + GenExpr(V.InitValue) + ';', V.Span);
  end;
end;

procedure TAvocadoCodeGenerator.GenRoutineHeader(ARoutine: TAvocadoRoutine; AIsForward: Boolean);
var
  Header: string;
  I, J: Integer;
  P: TAvocadoParam;
  T: string;
  First: Boolean;
begin
  if ARoutine.IsFunction then
    Header := 'function '
  else
    Header := 'procedure ';
  Header := Header + ARoutine.Name;
  First := True;
  if Length(ARoutine.Params) > 0 then
  begin
    Header := Header + '(';
    for I := 0 to High(ARoutine.Params) do
    begin
      P := TAvocadoParam(ARoutine.Params[I]);
      T := P.ResolvedTypeName;
      if T = '' then T := P.TypeName;
      for J := 0 to P.Names.Count - 1 do
      begin
        if not First then Header := Header + '; ';
        First := False;
        Header := Header + P.Names[J] + ': ' + T;
      end;
    end;
    Header := Header + ')';
  end;
  if ARoutine.IsFunction and (ARoutine.ReturnTypeName <> '') then
  begin
    T := ARoutine.ResolvedReturnTypeName;
    if T = '' then T := ARoutine.ReturnTypeName;
    Header := Header + ': ' + T;
  end;
  if AIsForward then
    Header := Header + '; forward;'
  else
    Header := Header + ';';
  AddLine(Header, ARoutine.Span);
end;

procedure TAvocadoCodeGenerator.GenRoutine(ARoutine: TAvocadoRoutine);
begin
  GenRoutineHeader(ARoutine, False);

  if Length(ARoutine.LocalVars) > 0 then
  begin
    AddLine('var', ARoutine.Span, True);
    GenVarSection(ARoutine.LocalVars, 1);
  end;

  AddLine('begin', ARoutine.Span, True);
  GenInitAssignments(ARoutine.LocalVars, 1);
  GenBlock(ARoutine.Body, 1);
  AddLine('end;', ARoutine.Span, True);
  AddScaffold('');
end;

function TAvocadoCodeGenerator.Generate(AProg: TAvocadoProgram): TStringList;
var
  I, K: Integer;
  U: string;
  UsesLine: string;
  HasAsm: Boolean;

  procedure ScanAsm(AStmt: TAvocadoStmt);
  var
    K: Integer;
  begin
    if AStmt = nil then Exit;
    if AStmt is TAvocadoAsmBlockStmt then
    begin
      HasAsm := True;
      Exit;
    end;
    if AStmt is TAvocadoBlockStmt then
      for K := 0 to High(TAvocadoBlockStmt(AStmt).Stmts) do
        ScanAsm(TAvocadoStmt(TAvocadoBlockStmt(AStmt).Stmts[K]));
    if AStmt is TAvocadoIfStmt then
    begin
      ScanAsm(TAvocadoIfStmt(AStmt).ThenBranch);
      ScanAsm(TAvocadoIfStmt(AStmt).ElseBranch);
    end;
    if AStmt is TAvocadoForStmt then
      ScanAsm(TAvocadoForStmt(AStmt).Body);
    if AStmt is TAvocadoForInStmt then
      ScanAsm(TAvocadoForInStmt(AStmt).Body);
    if AStmt is TAvocadoWhileStmt then
      ScanAsm(TAvocadoWhileStmt(AStmt).Body);
    if AStmt is TAvocadoRepeatStmt then
      ScanAsm(TAvocadoRepeatStmt(AStmt).Body);
  end;

  procedure ScanExpr(E: TAvocadoExpr);
  var
    J: Integer;
    CE: TAvocadoCallExpr;
    BT: TAvocadoBuiltin;
  begin
    if E = nil then Exit;
    if E is TAvocadoIdentExpr then
    begin
      if FLang.FindBuiltin(TAvocadoIdentExpr(E).Name, BT) and (BT.RequiredUnit <> '') then
        EnsureUnit(BT.RequiredUnit);
    end
    else if E is TAvocadoCallExpr then
    begin
      CE := TAvocadoCallExpr(E);
      if FLang.FindBuiltin(CE.CalleeName, BT) and (BT.RequiredUnit <> '') then
        EnsureUnit(BT.RequiredUnit);
      for J := 0 to High(CE.Args) do
        ScanExpr(TAvocadoExpr(CE.Args[J]));
    end
    else if E is TAvocadoUnaryExpr then
      ScanExpr(TAvocadoUnaryExpr(E).Operand)
    else if E is TAvocadoBinaryExpr then
    begin
      ScanExpr(TAvocadoBinaryExpr(E).Left);
      ScanExpr(TAvocadoBinaryExpr(E).Right);
    end
    else if E is TAvocadoIndexExpr then
    begin
      ScanExpr(TAvocadoIndexExpr(E).Base);
      ScanExpr(TAvocadoIndexExpr(E).Index);
    end
    else if E is TAvocadoMemberExpr then
      ScanExpr(TAvocadoMemberExpr(E).Base)
    else if E is TAvocadoSetExpr then
    begin
      for J := 0 to High(TAvocadoSetExpr(E).Items) do
        ScanExpr(TAvocadoExpr(TAvocadoSetExpr(E).Items[J]));
    end
    else if E is TAvocadoFormatExpr then
      ScanExpr(TAvocadoFormatExpr(E).Value);
  end;

  procedure ScanUses(AStmt: TAvocadoStmt);
  var
    K: Integer;
  begin
    if AStmt = nil then Exit;
    if AStmt is TAvocadoCallStmt then
      ScanExpr(TAvocadoCallStmt(AStmt).Call);
    if AStmt is TAvocadoAssignStmt then
    begin
      ScanExpr(TAvocadoAssignStmt(AStmt).Target);
      ScanExpr(TAvocadoAssignStmt(AStmt).Value);
    end;
    if AStmt is TAvocadoBlockStmt then
      for K := 0 to High(TAvocadoBlockStmt(AStmt).Stmts) do
        ScanUses(TAvocadoStmt(TAvocadoBlockStmt(AStmt).Stmts[K]));
    if AStmt is TAvocadoIfStmt then
    begin
      ScanExpr(TAvocadoIfStmt(AStmt).Condition);
      ScanUses(TAvocadoIfStmt(AStmt).ThenBranch);
      ScanUses(TAvocadoIfStmt(AStmt).ElseBranch);
    end;
    if AStmt is TAvocadoForStmt then
    begin
      ScanExpr(TAvocadoForStmt(AStmt).StartExpr);
      ScanExpr(TAvocadoForStmt(AStmt).StopExpr);
      ScanUses(TAvocadoForStmt(AStmt).Body);
    end;
    if AStmt is TAvocadoForInStmt then
    begin
      ScanExpr(TAvocadoForInStmt(AStmt).Collection);
      ScanUses(TAvocadoForInStmt(AStmt).Body);
    end;
    if AStmt is TAvocadoWhileStmt then
    begin
      ScanExpr(TAvocadoWhileStmt(AStmt).Condition);
      ScanUses(TAvocadoWhileStmt(AStmt).Body);
    end;
    if AStmt is TAvocadoRepeatStmt then
    begin
      ScanUses(TAvocadoRepeatStmt(AStmt).Body);
      ScanExpr(TAvocadoRepeatStmt(AStmt).Condition);
    end;
    if AStmt is TAvocadoReturnStmt then
      ScanExpr(TAvocadoReturnStmt(AStmt).Value);
    if AStmt is TAvocadoVarDecl then
      ScanExpr(TAvocadoVarDecl(AStmt).InitValue);
  end;

begin
  FOut.Clear;
  FUses.Clear;
  FIsGui := AProg.IsGui;
  HasAsm := False;

  // base units (keep console programs free of LCL/Dialogs)
  EnsureUnit('SysUtils');
  EnsureUnit('Classes');
  EnsureUnit('StrUtils');
  // HWND / HDC / WinAPI types and console codepage setup need Windows.
  // Do not add LCL Dialogs: GUI uses avoraiser.dialogs, console uses RTL.
  EnsureUnit('Windows');

  // imports written by the user
  for I := 0 to AProg.Imports.Count - 1 do
    EnsureUnit(AProg.Imports[I]);
  for I := 0 to AProg.ImplementationUnits.Count - 1 do
    EnsureUnit(AProg.ImplementationUnits[I]);

  // scan global var inits
  for I := 0 to High(AProg.GlobalVars) do
    ScanExpr(TAvocadoVarDecl(AProg.GlobalVars[I]).InitValue);

  // scan routines and main for builtin units / asm
  if AProg.MainBlock <> nil then
  begin
    ScanAsm(AProg.MainBlock);
    ScanUses(AProg.MainBlock);
  end;
  for I := 0 to High(AProg.Routines) do
  begin
    if TAvocadoRoutine(AProg.Routines[I]).Body <> nil then
    begin
      ScanAsm(TAvocadoRoutine(AProg.Routines[I]).Body);
      ScanUses(TAvocadoRoutine(AProg.Routines[I]).Body);
    end;
    for K := 0 to High(TAvocadoRoutine(AProg.Routines[I]).LocalVars) do
      ScanExpr(TAvocadoVarDecl(TAvocadoRoutine(AProg.Routines[I]).LocalVars[K]).InitValue);
  end;

  if HasAsm then
    EnsureUnit('');

  // directives
  AddScaffold('{$codepage ' + FCodePage + '}');
  AddScaffold('{$mode objfpc}');
  AddScaffold('{$H+}');
  if FIsGui then
    AddScaffold('{$APPTYPE GUI}');
  if HasAsm then
    AddScaffold('{$ASMMODE intel}');

  if AProg.ProgramName = '' then
    AddScaffold('program untitledprogram;')
  else
    AddScaffold('program ' + AProg.ProgramName + ';');

  // uses
  if FUses.Count > 0 then
  begin
    UsesLine := 'uses';
    for I := 0 to FUses.Count - 1 do
    begin
      U := FUses[I];
      if U = '' then Continue;
      if I = 0 then
        UsesLine := UsesLine + ' ' + U
      else
        UsesLine := UsesLine + ', ' + U;
    end;
    UsesLine := UsesLine + ';';
    AddScaffold(UsesLine);
  end;
  AddScaffold('');

  // global var
  if Length(AProg.GlobalVars) > 0 then
  begin
    AddScaffold('var');
    GenVarSection(AProg.GlobalVars, 1);
    AddScaffold('');
  end;

  // forward declarations for all routines to allow arbitrary call order
  for I := 0 to High(AProg.Routines) do
    GenRoutineHeader(TAvocadoRoutine(AProg.Routines[I]), True);
  if Length(AProg.Routines) > 0 then
    AddScaffold('');

  // routines definition
  for I := 0 to High(AProg.Routines) do
    GenRoutine(TAvocadoRoutine(AProg.Routines[I]));

  // main
  AddScaffold('begin');
  if not FIsGui then
  begin
    AddScaffold('{$IFDEF WINDOWS}');
    AddScaffold('  SetConsoleCP(' + FWinCp + ');');
    AddScaffold('  SetConsoleOutputCP(' + FWinCp + ');');
    AddScaffold('{$ENDIF}');
    AddScaffold('  SetTextCodePage(Output, ' + FWinCp + ');');
    AddScaffold('  SetTextCodePage(Input, ' + FWinCp + ');');
    EnsureUnit('');
  end;

  GenInitAssignments(AProg.GlobalVars, 1);
  GenBlock(AProg.MainBlock, 1);

  if not FIsGui then
    AddScaffold('  Readln;');
  AddScaffold('end.');

  Result := FOut;
end;

end.

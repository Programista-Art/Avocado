unit avocado_semantics;

{$mode objfpc}{$H+}

{ Semantic analysis: symbol tables, scopes, type checks, call checks.
  Foreign Pascal units: names that match a known builtin or declared symbol are
  checked here; otherwise, if the program imports a foreign unit the name is
  delegated to FPC (warning-level note). Unknown types are NOT silently
  converted to Variant. }

interface

uses
  SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_ast,
  avocado_language, avocado_symbols;

type
  TAvocadoSemanticAnalyzer = class
  private
    FLang: TAvocadoLanguage;
    FDiags: TAvocadoDiagnosticList;
    FSrc: TAvocadoSource;
    FSyms: TAvocadoSymbolTable;
    FCurrentRoutine: TAvocadoRoutine;
    FCurrentProg: TAvocadoProgram;
    FInLoop: Integer;
    FHasImports: Boolean;
    procedure Error(const ACode, AMsg: string; const ASpan: TAvocadoSourceSpan);
    procedure AnalyzeProgram(AProg: TAvocadoProgram);
    procedure CollectGlobals(AProg: TAvocadoProgram);
    procedure CollectRoutines(AProg: TAvocadoProgram);
    procedure AnalyzeRoutine(ARoutine: TAvocadoRoutine);
    procedure AnalyzeStmt(AStmt: TAvocadoStmt);
    procedure AnalyzeBlock(ABlock: TAvocadoBlockStmt);
    function AnalyzeExpr(AExpr: TAvocadoExpr): string; // returns resolved type name or ''
    function ResolveTypeName(const ARaw: string; const ASpan: TAvocadoSourceSpan): string;
    procedure CheckAssign(const ATarget, AValue: TAvocadoExpr);
  public
    constructor Create(ALang: TAvocadoLanguage; ADiags: TAvocadoDiagnosticList;
      ASrc: TAvocadoSource);
    destructor Destroy; override;
    procedure Analyze(AProg: TAvocadoProgram);
  end;

implementation

constructor TAvocadoSemanticAnalyzer.Create(ALang: TAvocadoLanguage;
  ADiags: TAvocadoDiagnosticList; ASrc: TAvocadoSource);
begin
  inherited Create;
  FLang := ALang;
  FDiags := ADiags;
  FSrc := ASrc;
  FSyms := TAvocadoSymbolTable.Create;
end;

destructor TAvocadoSemanticAnalyzer.Destroy;
begin
  FSyms.Free;
  inherited Destroy;
end;

procedure TAvocadoSemanticAnalyzer.Error(const ACode, AMsg: string;
  const ASpan: TAvocadoSourceSpan);
begin
  FDiags.AddError(ACode, AMsg, ASpan, FSrc.FileName);
end;

function TAvocadoSemanticAnalyzer.ResolveTypeName(const ARaw: string;
  const ASpan: TAvocadoSourceSpan): string;
begin
  Result := FLang.ResolveType(ARaw);
  if Result = '' then
  begin
    // Foreign / user type: keep as written, do not invent Variant
    if FHasImports then
      FDiags.AddWarning(AVOK_SemUnknownType,
        'Typ "' + ARaw + '" nie jest typem Avocado — przekazano do FPC',
        ASpan, FSrc.FileName)
    else
      Error(AVOK_SemUnknownType,
        'Nieznany typ "' + ARaw + '"', ASpan);
    Result := ARaw;
  end;
end;

procedure TAvocadoSemanticAnalyzer.CollectGlobals(AProg: TAvocadoProgram);
var
  I: Integer;
  V: TAvocadoVarDecl;
  Sym: TAvocadoSymbol;
begin
  for I := 0 to High(AProg.GlobalVars) do
  begin
    V := TAvocadoVarDecl(AProg.GlobalVars[I]);
    V.ResolvedTypeName := ResolveTypeName(V.TypeName, V.Span);
    Sym := TAvocadoSymbol.Create(V.VarName, askVariable, V.ResolvedTypeName);
    Sym.RawTypeName := V.TypeName;
    Sym.DeclNode := V;
    if not FSyms.DeclareGlobal(Sym) then
      Error(AVOK_SemDuplicateName,
        'Powtórzona deklaracja "' + V.VarName + '"', V.Span);
    // resolve initializer (calls, names) so codegen has ResolvedName
    if V.InitValue <> nil then
      AnalyzeExpr(V.InitValue);
  end;
end;

procedure TAvocadoSemanticAnalyzer.CollectRoutines(AProg: TAvocadoProgram);
var
  I: Integer;
  R: TAvocadoRoutine;
  Sym: TAvocadoSymbol;
begin
  // collect callable declarations first so they can be used before definition
  for I := 0 to High(AProg.Routines) do
  begin
    R := TAvocadoRoutine(AProg.Routines[I]);
    if R.IsFunction then
      Sym := TAvocadoSymbol.Create(R.Name, askFunction, R.ResolvedReturnTypeName)
    else
      Sym := TAvocadoSymbol.Create(R.Name, askProcedure, '');
    Sym.DeclNode := R;
    if not FSyms.DeclareGlobal(Sym) then
      Error(AVOK_SemDuplicateName,
        'Powtórzona deklaracja "' + R.Name + '"', R.Span);
  end;
end;

procedure TAvocadoSemanticAnalyzer.AnalyzeRoutine(ARoutine: TAvocadoRoutine);
var
  I, J: Integer;
  P: TAvocadoParam;
  Sym: TAvocadoSymbol;
  V: TAvocadoVarDecl;
begin
  FCurrentRoutine := ARoutine;
  FSyms.PushScope;
  try
    for I := 0 to High(ARoutine.Params) do
    begin
      P := TAvocadoParam(ARoutine.Params[I]);
      P.ResolvedTypeName := ResolveTypeName(P.TypeName, P.Span);
      for J := 0 to P.Names.Count - 1 do
      begin
        Sym := TAvocadoSymbol.Create(P.Names[J], askParameter, P.ResolvedTypeName);
        Sym.RawTypeName := P.TypeName;
        Sym.DeclNode := P;
        if not FSyms.Declare(Sym) then
          Error(AVOK_SemDuplicateName,
            'Powtórzony parametr "' + P.Names[J] + '"', P.Span);
      end;
    end;

    for I := 0 to High(ARoutine.LocalVars) do
    begin
      V := TAvocadoVarDecl(ARoutine.LocalVars[I]);
      V.ResolvedTypeName := ResolveTypeName(V.TypeName, V.Span);
      Sym := TAvocadoSymbol.Create(V.VarName, askVariable, V.ResolvedTypeName);
      Sym.RawTypeName := V.TypeName;
      Sym.DeclNode := V;
      if not FSyms.Declare(Sym) then
        Error(AVOK_SemDuplicateName,
          'Powtórzona deklaracja "' + V.VarName + '"', V.Span);
    end;

    if ARoutine.Body <> nil then
      AnalyzeBlock(ARoutine.Body);
  finally
    FSyms.PopScope;
    FCurrentRoutine := nil;
  end;
end;

function TAvocadoSemanticAnalyzer.AnalyzeExpr(AExpr: TAvocadoExpr): string;
var
  Sym: TAvocadoSymbol;
  B: TAvocadoBuiltin;
  Call: TAvocadoCallExpr;
  Name: string;
  I: Integer;
  Mapped: string;
begin
  Result := '';
  if AExpr = nil then Exit;

  if AExpr is TAvocadoIntegerLit then Exit('Integer');
  if AExpr is TAvocadoFloatLit then Exit('Double');
  if AExpr is TAvocadoStringLit then Exit('String');
  if AExpr is TAvocadoBoolLit then Exit('Boolean');
  if AExpr is TAvocadoNilLit then Exit('Pointer');

  if AExpr is TAvocadoIdentExpr then
  begin
    Name := TAvocadoIdentExpr(AExpr).Name;
    Sym := FSyms.Lookup(Name);
    if Sym <> nil then
      Exit(Sym.TypeName);
    if FLang.FindBuiltin(Name, B) then
    begin
      // 0-arg builtin used without parentheses (get_current_dir, randomize, ...)
      if B.Kind = abkConstant then
        Exit('');
      Exit('');
    end;
    if FHasImports then
    begin
      // foreign name; delegate to FPC
      Result := '';
      Exit;
    end;
    Error(AVOK_SemUnknownName, 'Nieznana nazwa "' + Name + '"', AExpr.Span);
    Exit;
  end;

  if AExpr is TAvocadoUnaryExpr then
  begin
    AnalyzeExpr(TAvocadoUnaryExpr(AExpr).Operand);
    if TAvocadoUnaryExpr(AExpr).Op = 'not' then Exit('Boolean');
    Result := '';
    Exit;
  end;

  if AExpr is TAvocadoBinaryExpr then
  begin
    AnalyzeExpr(TAvocadoBinaryExpr(AExpr).Left);
    AnalyzeExpr(TAvocadoBinaryExpr(AExpr).Right);
    if TAvocadoBinaryExpr(AExpr).Op = '=' then
      // equality in expressions (assignment handled separately)
      Result := 'Boolean'
    else if (TAvocadoBinaryExpr(AExpr).Op = '<') or (TAvocadoBinaryExpr(AExpr).Op = '>') or
            (TAvocadoBinaryExpr(AExpr).Op = '<=') or (TAvocadoBinaryExpr(AExpr).Op = '>=') or
            (TAvocadoBinaryExpr(AExpr).Op = '<>') then
      Result := 'Boolean'
    else if (TAvocadoBinaryExpr(AExpr).Op = 'and') or (TAvocadoBinaryExpr(AExpr).Op = 'or') then
      Result := 'Boolean'
    else
      Result := '';
    Exit;
  end;

  if AExpr is TAvocadoCallExpr then
  begin
    Call := TAvocadoCallExpr(AExpr);
    Name := Call.CalleeName;
    // alias map first (avoraiser_translate.ini)
    Mapped := FLang.LookupFunctionMap(Name);
    if Mapped <> '' then
      Call.ResolvedName := Mapped
    else if FLang.FindBuiltin(Name, B) then
      Call.ResolvedName := B.PascalName
    else
      Call.ResolvedName := Name;

    Sym := FSyms.Lookup(Name);
    if Sym <> nil then
    begin
      if not (Sym.Kind in [askFunction, askProcedure, askBuiltin]) then
        Error(AVOK_SemCallNotCallable,
          '"' + Name + '" nie jest funkcją ani procedurą', AExpr.Span);
      Result := Sym.TypeName;
    end
    else if FLang.FindBuiltin(Name, B) or (Mapped <> '') then
    begin
      Result := '';
      if FLang.FindBuiltin(Name, B) then
      begin
        if (B.MinArgs >= 0) and (Call.ArgCount < B.MinArgs) then
          Error(AVOK_SemArgCount,
            Format('Za mało argumentów dla %s (oczekiwano min. %d, jest %d)',
              [Name, B.MinArgs, Call.ArgCount]), AExpr.Span);
        if (B.MaxArgs >= 0) and (Call.ArgCount > B.MaxArgs) then
          Error(AVOK_SemArgCount,
            Format('Za dużo argumentów dla %s (oczekiwano max. %d, jest %d)',
              [Name, B.MaxArgs, Call.ArgCount]), AExpr.Span);
      end;
    end
    else
    begin
      // Unknown call: may be a Pascal RTL / foreign function.
      // Delegate to FPC; do not hard-fail (legacy passes these through).
      FDiags.AddWarning(AVOK_SemUnknownName,
        'Nieznana funkcja "' + Name + '" — przekazano do FPC', AExpr.Span, FSrc.FileName);
      Result := '';
    end;

    // Default(Type) / TypeInfo(Type) / SizeOf(Type) take a type name, not a value
    if (AvocadoLowerCase(Name) = 'default') or (AvocadoLowerCase(Name) = 'typeinfo') or
       (AvocadoLowerCase(Name) = 'sizeof') or (AvocadoLowerCase(Name) = 'high') or
       (AvocadoLowerCase(Name) = 'low') then
    begin
      // type argument: accept known type aliases or foreign type names
      for I := 0 to High(Call.Args) do
        if Call.Args[I] is TAvocadoIdentExpr then
        begin
          if FLang.ResolveType(TAvocadoIdentExpr(Call.Args[I]).Name) = '' then
            FDiags.AddWarning(AVOK_SemUnknownType,
              'Typ "' + TAvocadoIdentExpr(Call.Args[I]).Name + '" przekazany do ' + Name +
              ' — zweryfikuje FPC', Call.Args[I].Span, FSrc.FileName);
        end;
      Result := '';
      Exit;
    end;

    for I := 0 to High(Call.Args) do
      AnalyzeExpr(TAvocadoExpr(Call.Args[I]));
    Exit;
  end;

  if AExpr is TAvocadoIndexExpr then
  begin
    AnalyzeExpr(TAvocadoIndexExpr(AExpr).Base);
    AnalyzeExpr(TAvocadoIndexExpr(AExpr).Index);
    Exit;
  end;

  if AExpr is TAvocadoMemberExpr then
  begin
    AnalyzeExpr(TAvocadoMemberExpr(AExpr).Base);
    // member names are validated by FPC (foreign records / objects)
    Exit;
  end;

  if AExpr is TAvocadoSetExpr then
  begin
    for I := 0 to High(TAvocadoSetExpr(AExpr).Items) do
      AnalyzeExpr(TAvocadoExpr(TAvocadoSetExpr(AExpr).Items[I]));
    Result := '';
  end;

  if AExpr is TAvocadoFormatExpr then
  begin
    AnalyzeExpr(TAvocadoFormatExpr(AExpr).Value);
    Result := '';
  end;
end;

procedure TAvocadoSemanticAnalyzer.CheckAssign(const ATarget, AValue: TAvocadoExpr);
var
  TType, VType: string;
begin
  TType := AnalyzeExpr(ATarget);
  VType := AnalyzeExpr(AValue);
  // only check when both sides have a known type
  if (TType <> '') and (VType <> '') then
  begin
    if (TType = 'String') and (VType = 'String') then Exit;
    if (TType = 'Boolean') and (VType = 'Boolean') then Exit;
    // numeric compatibility is loose; FPC will still check hard errors
  end;
end;

procedure TAvocadoSemanticAnalyzer.AnalyzeStmt(AStmt: TAvocadoStmt);
var
  Call: TAvocadoCallExpr;
  Sym: TAvocadoSymbol;
  AutoVar: TAvocadoVarDecl;
  CollType, ElemType: string;
begin
  if AStmt = nil then Exit;

  if AStmt is TAvocadoBlockStmt then
  begin
    AnalyzeBlock(TAvocadoBlockStmt(AStmt));
    Exit;
  end;

  if AStmt is TAvocadoVarDecl then
  begin
    with TAvocadoVarDecl(AStmt) do
    begin
      ResolvedTypeName := ResolveTypeName(TypeName, Span);
      if InitValue <> nil then
        AnalyzeExpr(InitValue);
      Sym := TAvocadoSymbol.Create(VarName, askVariable, ResolvedTypeName);
      if not FSyms.Declare(Sym) then
        Error(AVOK_SemDuplicateName, 'Powtórzona deklaracja "' + VarName + '"', Span);
    end;
    Exit;
  end;

  if AStmt is TAvocadoAssignStmt then
  begin
    CheckAssign(TAvocadoAssignStmt(AStmt).Target, TAvocadoAssignStmt(AStmt).Value);
    Exit;
  end;

  if AStmt is TAvocadoCallStmt then
  begin
    Call := TAvocadoCallStmt(AStmt).Call;
    AnalyzeExpr(Call);
    Exit;
  end;

  if AStmt is TAvocadoIfStmt then
  begin
    AnalyzeExpr(TAvocadoIfStmt(AStmt).Condition);
    AnalyzeStmt(TAvocadoIfStmt(AStmt).ThenBranch);
    AnalyzeStmt(TAvocadoIfStmt(AStmt).ElseBranch);
    Exit;
  end;

  if AStmt is TAvocadoForStmt then
  begin
    AnalyzeExpr(TAvocadoForStmt(AStmt).StartExpr);
    AnalyzeExpr(TAvocadoForStmt(AStmt).StopExpr);
    // for-loop variable may reuse an existing name or be auto-declared (Pascal style)
    Sym := FSyms.Lookup(TAvocadoForStmt(AStmt).VarName);
    if Sym = nil then
    begin
      AutoVar := TAvocadoVarDecl.Create(AStmt.Span);
      AutoVar.VarName := TAvocadoForStmt(AStmt).VarName;
      AutoVar.TypeName := 'Integer';
      AutoVar.ResolvedTypeName := 'Integer';
      AutoVar.InitValue := nil;
      AutoVar.IsLocal := FCurrentRoutine <> nil;
      if FCurrentRoutine <> nil then
        FCurrentRoutine.AddLocalVar(AutoVar)
      else if FCurrentProg <> nil then
        FCurrentProg.AddGlobalVar(AutoVar);

      Sym := TAvocadoSymbol.Create(TAvocadoForStmt(AStmt).VarName, askVariable, 'Integer');
      FSyms.Declare(Sym);
    end;
    Inc(FInLoop);
    try
      AnalyzeStmt(TAvocadoForStmt(AStmt).Body);
    finally
      Dec(FInLoop);
    end;
    Exit;
  end;

  if AStmt is TAvocadoForInStmt then
  begin
    CollType := AnalyzeExpr(TAvocadoForInStmt(AStmt).Collection);
    Sym := FSyms.Lookup(TAvocadoForInStmt(AStmt).VarName);
    if Sym = nil then
    begin
      if CollType = 'String' then
        ElemType := 'Char'
      else
        ElemType := 'String';
      AutoVar := TAvocadoVarDecl.Create(AStmt.Span);
      AutoVar.VarName := TAvocadoForInStmt(AStmt).VarName;
      AutoVar.TypeName := ElemType;
      AutoVar.ResolvedTypeName := ElemType;
      AutoVar.InitValue := nil;
      AutoVar.IsLocal := FCurrentRoutine <> nil;
      if FCurrentRoutine <> nil then
        FCurrentRoutine.AddLocalVar(AutoVar)
      else if FCurrentProg <> nil then
        FCurrentProg.AddGlobalVar(AutoVar);

      Sym := TAvocadoSymbol.Create(TAvocadoForInStmt(AStmt).VarName, askVariable, ElemType);
      FSyms.Declare(Sym);
    end;
    Inc(FInLoop);
    try
      AnalyzeStmt(TAvocadoForInStmt(AStmt).Body);
    finally
      Dec(FInLoop);
    end;
    Exit;
  end;

  if AStmt is TAvocadoWhileStmt then
  begin
    AnalyzeExpr(TAvocadoWhileStmt(AStmt).Condition);
    Inc(FInLoop);
    try
      AnalyzeStmt(TAvocadoWhileStmt(AStmt).Body);
    finally
      Dec(FInLoop);
    end;
    Exit;
  end;

  if AStmt is TAvocadoRepeatStmt then
  begin
    Inc(FInLoop);
    try
      AnalyzeStmt(TAvocadoRepeatStmt(AStmt).Body);
    finally
      Dec(FInLoop);
    end;
    AnalyzeExpr(TAvocadoRepeatStmt(AStmt).Condition);
    Exit;
  end;

  if AStmt is TAvocadoReturnStmt then
  begin
    if FCurrentRoutine = nil then
      Error(AVOK_SemReturnOutsideFunc, 'Zwróć/return poza funkcją', AStmt.Span)
    else if (not FCurrentRoutine.IsFunction) and
            (TAvocadoReturnStmt(AStmt).Value <> nil) then
      Error(AVOK_SemReturnValueMissing,
        'Procedura nie może zwracać wartości', AStmt.Span);
    if TAvocadoReturnStmt(AStmt).Value <> nil then
      AnalyzeExpr(TAvocadoReturnStmt(AStmt).Value);
    Exit;
  end;

  if AStmt is TAvocadoBreakStmt then
  begin
    if FInLoop = 0 then
      Error(AVOK_SemBreakOutsideLoop, 'Przerwij/break poza pętlą', AStmt.Span);
    Exit;
  end;

  if AStmt is TAvocadoContinueStmt then
  begin
    if FInLoop = 0 then
      Error(AVOK_SemContinueOutsideLoop, 'Kontynuuj/continue poza pętlą', AStmt.Span);
    Exit;
  end;

  // exit / pascal / asm: no structural checks
end;

procedure TAvocadoSemanticAnalyzer.AnalyzeBlock(ABlock: TAvocadoBlockStmt);
var
  I: Integer;
begin
  if ABlock = nil then Exit;
  for I := 0 to High(ABlock.Stmts) do
    AnalyzeStmt(TAvocadoStmt(ABlock.Stmts[I]));
end;

procedure TAvocadoSemanticAnalyzer.AnalyzeProgram(AProg: TAvocadoProgram);
var
  I: Integer;
begin
  FHasImports := (AProg.Imports.Count > 0) or (AProg.ImplementationUnits.Count > 0);
  CollectGlobals(AProg);
  CollectRoutines(AProg);

  if AProg.MainBlock <> nil then
  begin
    FSyms.PushScope;
    try
      AnalyzeBlock(AProg.MainBlock);
    finally
      FSyms.PopScope;
    end;
  end;

  for I := 0 to High(AProg.Routines) do
    AnalyzeRoutine(TAvocadoRoutine(AProg.Routines[I]));
end;

procedure TAvocadoSemanticAnalyzer.Analyze(AProg: TAvocadoProgram);
begin
  FInLoop := 0;
  FCurrentRoutine := nil;
  FCurrentProg := AProg;
  try
    if AProg <> nil then
      AnalyzeProgram(AProg);
  finally
    FCurrentProg := nil;
  end;
end;

end.

unit avocado_parser;

{$mode objfpc}{$H+}

{ Recursive-descent parser for declarations/statements and Pratt parser for
  expressions. Builds a typed AST. Polish and English aliases produce the
  same AST structure. }

interface

uses
  SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens,
  avocado_language, avocado_ast;

type
  TAvocadoParser = class
  private
    FTokens: TAvocadoTokenArray;
    FPos: Integer;
    FLang: TAvocadoLanguage;
    FDiags: TAvocadoDiagnosticList;
    FSrc: TAvocadoSource;
    function Cur: TAvocadoToken;
    function PeekToken(AOff: Integer = 1): TAvocadoToken;
    function AtEnd: Boolean;
    function Check(AKind: TAvocadoTokenKind): Boolean;
    function CheckAny(const AKinds: array of TAvocadoTokenKind): Boolean;
    function Match(AKind: TAvocadoTokenKind): Boolean;
    procedure Advance;
    function Expect(AKind: TAvocadoTokenKind; const AWhat: string): Boolean;
    procedure ErrorAt(const ATok: TAvocadoToken; const ACode, AMsg: string);
    function SpanOf(const ATok: TAvocadoToken): TAvocadoSourceSpan;
    function SpanFrom(const ATok: TAvocadoToken): TAvocadoSourceSpan;

    { helpers }
    function IsWordToken(const ATok: TAvocadoToken; const AWord: string): Boolean;
    function CheckWord(const AWord: string): Boolean;
    function MatchWord(const AWord: string): Boolean;
    function SkipSemis: Boolean;

    { expressions - Pratt }
    function ParseExpr: TAvocadoExpr;
    function ParseExprPrec(APrec: Integer): TAvocadoExpr;
    function ParseUnary: TAvocadoExpr;
    function ParsePostfix(AExpr: TAvocadoExpr): TAvocadoExpr;
    function ParsePrimary: TAvocadoExpr;
    function ParseCallArg: TAvocadoExpr;
    function InfixPrec(AKind: TAvocadoTokenKind): Integer;

    { statements }
    function ParseStatement: TAvocadoStmt;
    function ParseBlock: TAvocadoBlockStmt;
    function ParseStmtOrBlock: TAvocadoStmt;
    function ParseDeclarationOrStatement: TAvocadoStmt;
    function TryParseVarDecl(out ADecl: TAvocadoVarDecl): Boolean;
    function ParseIf: TAvocadoStmt;
    function ParseFor: TAvocadoStmt;
    function ParseWhile: TAvocadoStmt;
    function ParseRepeat: TAvocadoStmt;
    function ParseReturn: TAvocadoStmt;
    function ParseStatementListUntil(AEndKind: TAvocadoTokenKind;
      AStopAtElse: Boolean): TAvocadoBlockStmt;

    { top level }
    function ParseHeader(AProgram: TAvocadoProgram): Boolean;
    procedure ParseImports(AProgram: TAvocadoProgram);
    function ParseParams: TAvocadoNodeArray;
    function ParseRoutine: TAvocadoRoutine;
    procedure RecoverToStatementBoundary;
  public
    constructor Create(ATokens: TAvocadoTokenArray; ALang: TAvocadoLanguage;
      ADiags: TAvocadoDiagnosticList; ASrc: TAvocadoSource);
    function ParseProgram: TAvocadoProgram;
  end;

implementation

constructor TAvocadoParser.Create(ATokens: TAvocadoTokenArray; ALang: TAvocadoLanguage;
  ADiags: TAvocadoDiagnosticList; ASrc: TAvocadoSource);
begin
  inherited Create;
  FTokens := ATokens;
  FPos := 0;
  FLang := ALang;
  FDiags := ADiags;
  FSrc := ASrc;
end;

function TAvocadoParser.Cur: TAvocadoToken;
begin
  if FPos <= High(FTokens) then
    Result := FTokens[FPos]
  else
    Result := FTokens[High(FTokens)];
end;

function TAvocadoParser.PeekToken(AOff: Integer): TAvocadoToken;
var
  Idx: Integer;
begin
  Idx := FPos + AOff;
  if Idx > High(FTokens) then
    Idx := High(FTokens);
  if Idx < 0 then Idx := 0;
  Result := FTokens[Idx];
end;

function TAvocadoParser.AtEnd: Boolean;
begin
  Result := Cur.Kind = tkEndOfFile;
end;

function TAvocadoParser.Check(AKind: TAvocadoTokenKind): Boolean;
begin
  Result := Cur.Kind = AKind;
end;

function TAvocadoParser.CheckAny(const AKinds: array of TAvocadoTokenKind): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(AKinds) do
    if Cur.Kind = AKinds[I] then Exit(True);
  Result := False;
end;

function TAvocadoParser.Match(AKind: TAvocadoTokenKind): Boolean;
begin
  Result := Cur.Kind = AKind;
  if Result then Advance;
end;

procedure TAvocadoParser.Advance;
begin
  if FPos < High(FTokens) then Inc(FPos);
end;

function TAvocadoParser.Expect(AKind: TAvocadoTokenKind; const AWhat: string): Boolean;
begin
  if Cur.Kind = AKind then
  begin
    Advance;
    Exit(True);
  end;
  ErrorAt(Cur, AVOK_ParseExpectedToken,
    Format('Oczekiwano %s, napotkano %s', [AWhat, TokenKindName(Cur.Kind)]));
  Result := False;
end;

procedure TAvocadoParser.ErrorAt(const ATok: TAvocadoToken; const ACode, AMsg: string);
begin
  FDiags.AddError(ACode, AMsg, SpanOf(ATok), FSrc.FileName);
end;

function TAvocadoParser.SpanOf(const ATok: TAvocadoToken): TAvocadoSourceSpan;
begin
  Result := FSrc.GetSpan(ATok.StartOffset + 1, ATok.EndOffset + 1);
end;

function TAvocadoParser.SpanFrom(const ATok: TAvocadoToken): TAvocadoSourceSpan;
var
  EndTok: TAvocadoToken;
begin
  if FPos > 0 then
    EndTok := FTokens[FPos - 1]
  else
    EndTok := ATok;
  Result.StartPos := FSrc.PosAt(ATok.StartOffset + 1);
  Result.EndPos := FSrc.PosAt(EndTok.EndOffset + 1);
end;

function TAvocadoParser.IsWordToken(const ATok: TAvocadoToken; const AWord: string): Boolean;
begin
  Result := (ATok.Kind = tkIdentifier) and (AvocadoLowerCase(ATok.Text) = AvocadoLowerCase(AWord));
end;

function TAvocadoParser.CheckWord(const AWord: string): Boolean;
begin
  Result := IsWordToken(Cur, AWord);
end;

function TAvocadoParser.MatchWord(const AWord: string): Boolean;
begin
  Result := CheckWord(AWord);
  if Result then Advance;
end;

function TAvocadoParser.SkipSemis: Boolean;
begin
  Result := False;
  while Match(tkSemi) do
    Result := True;
end;

{ ---------- Expressions (Pratt) ---------- }

function TAvocadoParser.InfixPrec(AKind: TAvocadoTokenKind): Integer;
begin
  case AKind of
    tkKwOr: Result := 10;
    tkKwAnd: Result := 20;
    tkAssign, tkNotEqual, tkLess, tkGreater, tkLessEqual, tkGreaterEqual: Result := 30;
    tkPlus, tkMinus: Result := 40;
    tkStar, tkSlash, tkKwDiv, tkKwMod: Result := 50;
  else
    Result := 0;
  end;
end;

function TAvocadoParser.ParseExpr: TAvocadoExpr;
begin
  Result := ParseExprPrec(0);
end;

function TAvocadoParser.ParseExprPrec(APrec: Integer): TAvocadoExpr;
var
  Left, Right: TAvocadoExpr;
  OpTok: TAvocadoToken;
  Op: string;
  Prec: Integer;
  Bin: TAvocadoBinaryExpr;
begin
  Left := ParseUnary;
  if Left = nil then Exit(nil);
  while True do
  begin
    Prec := InfixPrec(Cur.Kind);
    if (Prec = 0) or (Prec < APrec) then Break;
    OpTok := Cur;
    case OpTok.Kind of
      tkKwOr: Op := 'or';
      tkKwAnd: Op := 'and';
      tkAssign: Op := '=';
      tkNotEqual: Op := '<>';
      tkLess: Op := '<';
      tkGreater: Op := '>';
      tkLessEqual: Op := '<=';
      tkGreaterEqual: Op := '>=';
      tkPlus: Op := '+';
      tkMinus: Op := '-';
      tkStar: Op := '*';
      tkSlash: Op := '/';
      tkKwDiv: Op := 'div';
      tkKwMod: Op := 'mod';
    else
      Op := OpTok.Spelling;
    end;
    Advance;
    Right := ParseExprPrec(Prec + 1);
    if Right = nil then
    begin
      ErrorAt(OpTok, AVOK_ParseExpectedExpr, 'Oczekiwano wyrażenia po operatorze ' + Op);
      Left.Free;
      Exit(nil);
    end;
    Bin := TAvocadoBinaryExpr.Create(SpanFrom(OpTok));
    Bin.Op := Op;
    Bin.Left := Left;
    Bin.Right := Right;
    Left := Bin;
  end;
  Result := Left;
end;

function TAvocadoParser.ParseUnary: TAvocadoExpr;
var
  OpTok: TAvocadoToken;
  U: TAvocadoUnaryExpr;
  Operand: TAvocadoExpr;
  Op: string;
  IsUnary: Boolean;
begin
  Result := nil;
  IsUnary := (Cur.Kind = tkMinus) or (Cur.Kind = tkPlus) or
             (Cur.Kind = tkKwNot) or (Cur.Kind = tkAt);
  if IsUnary then
  begin
    OpTok := Cur;
    case OpTok.Kind of
      tkMinus: Op := '-';
      tkPlus: Op := '+';
      tkKwNot: Op := 'not';
      tkAt: Op := '@';
    else
      Op := '?';
    end;
    Advance;
    // parse operand as a full unary/postfix chain
    if (Cur.Kind = tkMinus) or (Cur.Kind = tkPlus) or
       (Cur.Kind = tkKwNot) or (Cur.Kind = tkAt) then
      Operand := ParseUnary
    else
      Operand := ParsePostfix(ParsePrimary);
    if Operand = nil then
    begin
      ErrorAt(OpTok, AVOK_ParseExpectedExpr, 'Oczekiwano wyrażenia po operatorze jednoargumentowym');
      Result := nil;
      Exit;
    end;
    U := TAvocadoUnaryExpr.Create(SpanFrom(OpTok));
    U.Op := Op;
    U.Operand := Operand;
    Result := U;
    Exit;
  end;
  Result := ParsePostfix(ParsePrimary);
end;

function TAvocadoParser.ParsePostfix(AExpr: TAvocadoExpr): TAvocadoExpr;
var
  IndexE: TAvocadoIndexExpr;
  Mem: TAvocadoMemberExpr;
  Call: TAvocadoCallExpr;
  Name: string;
  Arg: TAvocadoExpr;
  StartSpan: TAvocadoSourceSpan;
begin
  Result := AExpr;
  if Result = nil then Exit;
  while True do
  begin
    if Check(tkLParen) then
    begin
      // call on an identifier or member expression (obj.method(...))
      if (Result is TAvocadoIdentExpr) or (Result is TAvocadoMemberExpr) then
      begin
        StartSpan := Result.Span;
        if Result is TAvocadoIdentExpr then
        begin
          Name := TAvocadoIdentExpr(Result).Name;
          Result.Free;
          Call := TAvocadoCallExpr.Create(StartSpan);
          Call.CalleeName := Name;
        end
        else
        begin
          Name := '';
          Call := TAvocadoCallExpr.Create(StartSpan);
          Call.CalleeName := '';
          Call.AddArg(Result); // first arg is the member expression
        end;
        Advance; // (
        if not Check(tkRParen) then
        begin
          repeat
            Arg := ParseCallArg;
            if Arg = nil then Break;
            Call.AddArg(Arg);
          until not Match(tkComma);
        end;
        Expect(tkRParen, ')');
        Call.Span.StartPos := StartSpan.StartPos;
        if FPos > 0 then
          Call.Span.EndPos := FSrc.PosAt(FTokens[FPos - 1].EndOffset + 1);
        Result := Call;
      end
      else
      begin
        ErrorAt(Cur, AVOK_ParseUnexpectedToken, 'Wywołanie tylko dla nazw (identyfikatorów)');
        Break;
      end;
    end
    else if Check(tkLBracket) then
    begin
      Advance;
      IndexE := TAvocadoIndexExpr.Create(SpanFrom(FTokens[FPos - 1]));
      IndexE.Base := Result;
      IndexE.Index := ParseExpr;
      Expect(tkRBracket, ']');
      Result := IndexE;
    end
    else if Check(tkDot) then
    begin
      Advance;
      if Cur.Kind = tkIdentifier then
      begin
        Mem := TAvocadoMemberExpr.Create(SpanFrom(FTokens[FPos - 1]));
        Mem.Base := Result;
        Mem.MemberName := Cur.Text;
        Advance;
        Result := Mem;
      end
      else
      begin
        ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy pola po kropce');
        Break;
      end;
    end
    else
      Break;
  end;
end;

function TAvocadoParser.ParseCallArg: TAvocadoExpr;
var
  Inner: TAvocadoExpr;
  Fmt: TAvocadoFormatExpr;
  StartTok: TAvocadoToken;
  W, D: Integer;
  HasW, HasD: Boolean;
begin
  StartTok := Cur;
  Inner := ParseExpr;
  if (Inner <> nil) and Check(tkColon) then
  begin
    // Pascal format: expr:width[:decimals]
    Advance;
    W := 0;
    D := 0;
    HasW := False;
    HasD := False;
    if Cur.Kind in [tkInteger, tkHex] then
    begin
      W := Cur.IntValue;
      HasW := True;
      Advance;
      if Check(tkColon) then
      begin
        Advance;
        if Cur.Kind in [tkInteger, tkHex] then
        begin
          D := Cur.IntValue;
          HasD := True;
          Advance;
        end;
      end;
    end;
    Fmt := TAvocadoFormatExpr.Create(SpanFrom(StartTok));
    Fmt.Value := Inner;
    Fmt.Width := W;
    Fmt.Decimals := D;
    Fmt.HasWidth := HasW;
    Fmt.HasDecimals := HasD;
    Result := Fmt;
  end
  else
    Result := Inner;
end;

function TAvocadoParser.ParsePrimary: TAvocadoExpr;
var
  T: TAvocadoToken;
  IdE: TAvocadoIdentExpr;
  IL: TAvocadoIntegerLit;
  FL: TAvocadoFloatLit;
  SL: TAvocadoStringLit;
  BL: TAvocadoBoolLit;
  SetE: TAvocadoSetExpr;
  Inner: TAvocadoExpr;
begin
  T := Cur;
  case T.Kind of
    tkInteger, tkHex:
      begin
        IL := TAvocadoIntegerLit.Create(SpanOf(T));
        IL.Value := T.IntValue;
        Advance;
        Exit(IL);
      end;
    tkFloat:
      begin
        FL := TAvocadoFloatLit.Create(SpanOf(T));
        FL.Value := T.FloatValue;
        Advance;
        Exit(FL);
      end;
    tkString:
      begin
        SL := TAvocadoStringLit.Create(SpanOf(T));
        SL.Value := T.Text;
        Advance;
        Exit(SL);
      end;
    tkKwTrue:
      begin
        BL := TAvocadoBoolLit.Create(SpanOf(T));
        BL.Value := True;
        Advance;
        Exit(BL);
      end;
    tkKwFalse:
      begin
        BL := TAvocadoBoolLit.Create(SpanOf(T));
        BL.Value := False;
        Advance;
        Exit(BL);
      end;
    tkKwNil:
      begin
        Advance;
        Exit(TAvocadoNilLit.Create(SpanOf(T)));
      end;
    tkIdentifier:
      begin
        IdE := TAvocadoIdentExpr.Create(SpanOf(T));
        IdE.Name := T.Text;
        Advance;
        Exit(IdE);
      end;
    tkLParen:
      begin
        Advance;
        Inner := ParseExpr;
        if not Expect(tkRParen, ')') then
        begin
          Inner.Free;
          Exit(nil);
        end;
        Exit(Inner);
      end;
    tkLBracket:
      begin
        // set literal [a, b, c] or [tylko_odczyt]
        Advance;
        SetE := TAvocadoSetExpr.Create(SpanOf(T));
        if not Check(tkRBracket) then
        begin
          repeat
            Inner := ParseExpr;
            if Inner = nil then Break;
            SetE.AddItem(Inner);
          until not Match(tkComma);
        end;
        Expect(tkRBracket, ']');
        Exit(SetE);
      end;
    tkAt:
      begin
        // handled by unary; fallback
      end;
  end;
  ErrorAt(T, AVOK_ParseExpectedExpr,
    Format('Oczekiwano wyrażenia, napotkano %s', [TokenKindName(T.Kind)]));
  if not AtEnd then Advance;
  Result := nil;
end;

{ ---------- Statements ---------- }

function TAvocadoParser.TryParseVarDecl(out ADecl: TAvocadoVarDecl): Boolean;
var
  TypeTok, NameTok: TAvocadoToken;
  TypeName, VarName: string;
  Init: TAvocadoExpr;
  StartTok: TAvocadoToken;
  HasInit: Boolean;
begin
  ADecl := nil;
  Result := False;
  if not Check(tkIdentifier) then Exit;
  if not FLang.IsTypeName(Cur.Text) then Exit;
  // Lookahead: variable declaration requires an identifier name following the type
  if PeekToken(1).Kind <> tkIdentifier then Exit;

  StartTok := Cur;
  TypeTok := Cur;
  Advance;
  NameTok := Cur;
  TypeName := TypeTok.Text;
  VarName := NameTok.Text;
  Advance;

  HasInit := Check(tkAssign);
  Init := nil;
  if HasInit then
  begin
    Advance;
    Init := ParseExpr;
    if Init = nil then
    begin
      ErrorAt(NameTok, AVOK_ParseExpectedExpr, 'Oczekiwano wartości początkowej po =');
      Exit(False);
    end;
  end;

  ADecl := TAvocadoVarDecl.Create(SpanFrom(StartTok));
  ADecl.TypeName := TypeName;
  ADecl.ResolvedTypeName := FLang.ResolveType(TypeName);
  ADecl.VarName := VarName;
  ADecl.InitValue := Init;
  Result := True;
end;

function TAvocadoParser.ParseBlock: TAvocadoBlockStmt;
var
  StartTok: TAvocadoToken;
  Stmts: TAvocadoBlockStmt;
  St: TAvocadoStmt;
begin
  StartTok := Cur;
  if not Check(tkKwMainOpen) then
  begin
    ErrorAt(Cur, AVOK_ParseExpectedToken, 'Oczekiwano początku bloku (początek/start)');
    Exit(TAvocadoBlockStmt.Create(SpanOf(Cur)));
  end;
  Advance;
  Stmts := TAvocadoBlockStmt.Create(SpanOf(StartTok));
  while (not AtEnd) and (not Check(tkKwBlockEnd)) do
  begin
    SkipSemis;
    if Check(tkKwBlockEnd) then Break;
    if AtEnd then Break;
    St := ParseStatement;
    if St <> nil then
      Stmts.Add(St)
    else
      RecoverToStatementBoundary;
  end;
  // consume koniec/end (optional if at program end handled by caller)
  if Check(tkKwBlockEnd) then
    Advance
  else if not AtEnd then
    ErrorAt(Cur, AVOK_ParseUnclosedBlock, 'Oczekiwano zamknięcia bloku (koniec/end)');
  Result := Stmts;
end;

function TAvocadoParser.ParseStmtOrBlock: TAvocadoStmt;
begin
  if Check(tkKwMainOpen) then
    Exit(ParseBlock);
  // allow a block-end to mean empty body (compat: 'if x then end')
  Result := ParseStatement;
end;

function TAvocadoParser.ParseIf: TAvocadoStmt;
var
  StartTok: TAvocadoToken;
  Cond: TAvocadoExpr;
  ThenB, ElseB: TAvocadoStmt;
  IfS: TAvocadoIfStmt;
begin
  StartTok := Cur;
  Advance; // if / jeżeli
  Cond := ParseExpr;
  if Cond = nil then
  begin
    ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano warunku po if/jeżeli');
    Exit(nil);
  end;
  if not (Match(tkKwThen) or MatchWord('wtedy')) then
    ErrorAt(Cur, AVOK_ParseExpectedToken, 'Oczekiwano wtedy/then');
  ThenB := ParseStmtOrBlock;
  ElseB := nil;
  // else may be separated by newline; keyword itself is enough
  if Check(tkKwElse) or CheckWord('inaczej') then
  begin
    Advance;
    if Check(tkKwIf) or CheckWord('jeżeli') or CheckWord('jezeli') then
      ElseB := ParseIf
    else
      ElseB := ParseStmtOrBlock;
  end;
  IfS := TAvocadoIfStmt.Create(SpanFrom(StartTok));
  IfS.Condition := Cond;
  IfS.ThenBranch := ThenB;
  IfS.ElseBranch := ElseB;
  Result := IfS;
end;

function TAvocadoParser.ParseFor: TAvocadoStmt;
var
  StartTok: TAvocadoToken;
  VarName: string;
  StartE, StopE: TAvocadoExpr;
  IsDownto: Boolean;
  Body: TAvocadoStmt;
  ForS: TAvocadoForStmt;
  ForInS: TAvocadoForInStmt;
  Coll: TAvocadoExpr;
begin
  StartTok := Cur;
  Advance; // for / dla
  if not Check(tkIdentifier) then
  begin
    ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy zmiennej pętli for');
    Exit(nil);
  end;
  VarName := Cur.Text;
  Advance;

  // for-in: for x in coll ...
  if Check(tkKwIn) or CheckWord('w') then
  begin
    Advance;
    Coll := ParseExpr;
    if Coll = nil then
    begin
      ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano kolekcji w for-in');
      Exit(nil);
    end;
    Match(tkKwDo); // wykonaj / do
    Body := ParseStmtOrBlock;
    ForInS := TAvocadoForInStmt.Create(SpanFrom(StartTok));
    ForInS.VarName := VarName;
    ForInS.Collection := Coll;
    ForInS.Body := Body;
    Exit(ForInS);
  end;

  // for i = start to/downto stop ...
  if not Expect(tkAssign, '=') then Exit(nil);
  StartE := ParseExpr;
  if StartE = nil then
  begin
    ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano wartości początkowej pętli for');
    Exit(nil);
  end;
  IsDownto := Check(tkKwDownto);
  if IsDownto then
    Advance
  else if Check(tkKwTo) then
    Advance
  else if Check(tkKwDo) then
    // Polish uses 'do' as the "to" marker; if next is another do it's the body marker
    // Distinguish: for i = 1 do 5 wykonaj  → first 'do' is "to"
    //              for i = 1 to 5 do      → tkKwTo then tkKwDo
    Advance
  else
    ErrorAt(Cur, AVOK_ParseExpectedToken, 'Oczekiwano do/to/malejąco w pętli for');

  StopE := ParseExpr;
  if StopE = nil then
  begin
    ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano wartości końcowej pętli for');
    StartE.Free;
    Exit(nil);
  end;
  // body marker
  Match(tkKwDo); // wykonaj / do
  Body := ParseStmtOrBlock;
  ForS := TAvocadoForStmt.Create(SpanFrom(StartTok));
  ForS.VarName := VarName;
  ForS.StartExpr := StartE;
  ForS.StopExpr := StopE;
  ForS.IsDownto := IsDownto;
  ForS.Body := Body;
  Result := ForS;
end;

function TAvocadoParser.ParseWhile: TAvocadoStmt;
var
  StartTok: TAvocadoToken;
  Cond: TAvocadoExpr;
  Body: TAvocadoStmt;
  WS: TAvocadoWhileStmt;
begin
  StartTok := Cur;
  Advance;
  Cond := ParseExpr;
  if Cond = nil then
  begin
    ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano warunku pętli while');
    Exit(nil);
  end;
  Match(tkKwDo); // wykonaj / do / make
  Body := ParseStmtOrBlock;
  WS := TAvocadoWhileStmt.Create(SpanFrom(StartTok));
  WS.Condition := Cond;
  WS.Body := Body;
  Result := WS;
end;

function TAvocadoParser.ParseRepeat: TAvocadoStmt;
var
  StartTok: TAvocadoToken;
  Body: TAvocadoBlockStmt;
  Cond: TAvocadoExpr;
  RS: TAvocadoRepeatStmt;
  St: TAvocadoStmt;
begin
  StartTok := Cur;
  Advance; // repeat
  Body := TAvocadoBlockStmt.Create(SpanOf(StartTok));
  while (not AtEnd) and (not Check(tkKwUntil)) do
  begin
    SkipSemis;
    if Check(tkKwUntil) then Break;
    St := ParseStatement;
    if St <> nil then
      Body.Add(St)
    else
      RecoverToStatementBoundary;
  end;
  if not Expect(tkKwUntil, 'until/aż') then
  begin
    Body.Free;
    Exit(nil);
  end;
  Cond := ParseExpr;
  if Cond = nil then
  begin
    ErrorAt(StartTok, AVOK_ParseExpectedExpr, 'Oczekiwano warunku po until/aż');
    Body.Free;
    Exit(nil);
  end;
  RS := TAvocadoRepeatStmt.Create(SpanFrom(StartTok));
  RS.Body := Body;
  RS.Condition := Cond;
  Result := RS;
end;

function TAvocadoParser.ParseReturn: TAvocadoStmt;
var
  StartTok: TAvocadoToken;
  Val: TAvocadoExpr;
  RS: TAvocadoReturnStmt;
begin
  StartTok := Cur;
  Advance;
  Val := nil;
  // return value is optional; if the next token starts an expression on the same line
  if (not Cur.NewlineBefore) and (not CheckAny([tkSemi, tkKwBlockEnd, tkKwElse, tkEndOfFile])) then
    Val := ParseExpr;
  RS := TAvocadoReturnStmt.Create(SpanFrom(StartTok));
  RS.Value := Val;
  Result := RS;
end;

function TAvocadoParser.ParseDeclarationOrStatement: TAvocadoStmt;
var
  Decl: TAvocadoVarDecl;
  Target, Value: TAvocadoExpr;
  AssignS: TAvocadoAssignStmt;
  CallS: TAvocadoCallStmt;
  Call: TAvocadoCallExpr;
  StartTok: TAvocadoToken;
  Name: string;
  Esc: TAvocadoPascalBlockStmt;
  AsmS: TAvocadoAsmBlockStmt;
begin
  // escape blocks
  if Cur.Kind in [tkPascalBlock, tkPascalLine] then
  begin
    StartTok := Cur;
    Esc := TAvocadoPascalBlockStmt.Create(SpanOf(Cur));
    Esc.RawCode := Cur.Text;
    Esc.IsSingleLine := Cur.Kind = tkPascalLine;
    Advance;
    Exit(Esc);
  end;
  if Cur.Kind = tkAsmBlock then
  begin
    StartTok := Cur;
    AsmS := TAvocadoAsmBlockStmt.Create(SpanOf(Cur));
    AsmS.RawCode := Cur.Text;
    Advance;
    Exit(AsmS);
  end;

  if TryParseVarDecl(Decl) then
  begin
    Exit(Decl);
  end;

  // assignment / call / bare identifier statement
  if Check(tkIdentifier) then
  begin
    StartTok := Cur;
    // Parse only postfix (call/index/member) so that '=' stays for assignment,
    // not as a binary equality operator.
    Target := ParsePostfix(ParsePrimary);
    if Target = nil then Exit(nil);

    if Check(tkAssign) then
    begin
      Advance;
      Value := ParseExpr;
      if Value = nil then
      begin
        ErrorAt(Cur, AVOK_ParseExpectedExpr, 'Oczekiwano wartości po =');
        Target.Free;
        Exit(nil);
      end;
      AssignS := TAvocadoAssignStmt.Create(SpanFrom(StartTok));
      AssignS.Target := Target;
      AssignS.Value := Value;
      Exit(AssignS);
    end;

    // expression statement: only a call is valid
    if Target is TAvocadoCallExpr then
    begin
      CallS := TAvocadoCallStmt.Create(SpanFrom(StartTok));
      CallS.Call := TAvocadoCallExpr(Target);
      Exit(CallS);
    end;
    if Target is TAvocadoIdentExpr then
    begin
      // bare identifier => parameterless call
      Name := TAvocadoIdentExpr(Target).Name;
      Call := TAvocadoCallExpr.Create(Target.Span);
      Call.CalleeName := Name;
      Target.Free;
      CallS := TAvocadoCallStmt.Create(Call.Span);
      CallS.Call := Call;
      Exit(CallS);
    end;
    if (Target is TAvocadoMemberExpr) or (Target is TAvocadoIndexExpr) then
    begin
      // bare member/index used as a parameterless method call (e.g. h.zwolnij)
      CallS := TAvocadoCallStmt.Create(SpanFrom(StartTok));
      Call := TAvocadoCallExpr.Create(Target.Span);
      // wrap: represent as member call via CalleeName = special
      // simpler: keep as a call with CalleeName set to a marker and store target
      // Instead, emit as CallStmt whose Call has no name and Args[0] = target.
      Call.CalleeName := '';
      Call.AddArg(TAvocadoExpr(Target)); // argument is the member expr itself
      CallS.Call := Call;
      Exit(CallS);
    end;
    Target.Free;
    ErrorAt(StartTok, AVOK_ParseUnexpectedToken,
      'Nieprawidłowa instrukcja — oczekiwano przypisania lub wywołania');
    Exit(nil);
  end;

  ErrorAt(Cur, AVOK_ParseExpectedStmt,
    Format('Nieoczekiwane %s w instrukcji', [TokenKindName(Cur.Kind)]));
  if not AtEnd then Advance;
  Result := nil;
end;

function TAvocadoParser.ParseStatement: TAvocadoStmt;
begin
  SkipSemis;
  case Cur.Kind of
    tkKwIf: Exit(ParseIf);
    tkKwFor: Exit(ParseFor);
    tkKwWhile: Exit(ParseWhile);
    tkKwRepeat: Exit(ParseRepeat);
    tkKwReturn: Exit(ParseReturn);
    tkKwBreak:
      begin
        Result := TAvocadoBreakStmt.Create(SpanOf(Cur));
        Advance;
        Exit;
      end;
    tkKwContinue:
      begin
        Result := TAvocadoContinueStmt.Create(SpanOf(Cur));
        Advance;
        Exit;
      end;
    tkKwExit:
      begin
        Result := TAvocadoExitStmt.Create(SpanOf(Cur));
        Advance;
        Exit;
      end;
    tkKwMainOpen:
      Exit(ParseBlock);
    tkKwBlockEnd:
      Exit(nil); // caller consumes
  end;
  Result := ParseDeclarationOrStatement;
end;

function TAvocadoParser.ParseStatementListUntil(AEndKind: TAvocadoTokenKind;
  AStopAtElse: Boolean): TAvocadoBlockStmt;
begin
  Result := TAvocadoBlockStmt.Create(SpanOf(Cur));
  while (not AtEnd) and (Cur.Kind <> AEndKind) do
  begin
    if AStopAtElse and (Cur.Kind = tkKwElse) then Break;
    // subroutines start at top level only
    if CheckAny([tkKwProcedure, tkKwFunction]) then Break;
    SkipSemis;
    if (Cur.Kind = AEndKind) or (AStopAtElse and (Cur.Kind = tkKwElse)) then Break;
    if AtEnd then Break;
    // fallthrough to next section only at top level - inside main we allow routines? no
    Result.Add(ParseStatement);
    RecoverToStatementBoundary;
  end;
end;

procedure TAvocadoParser.RecoverToStatementBoundary;
var
  Guard: Integer;
begin
  Guard := 0;
  while (not AtEnd) and (Guard < 10000) do
  begin
    Inc(Guard);
    if Check(tkKwBlockEnd) or Check(tkKwElse) or Check(tkKwUntil) or
       CheckAny([tkKwProcedure, tkKwFunction, tkKwProgram, tkKwProgramUi]) then
      Exit;
    if Cur.NewlineBefore and (FPos > 0) then
      Exit;
    Advance;
  end;
end;

{ ---------- Top level ---------- }

function TAvocadoParser.ParseHeader(AProgram: TAvocadoProgram): Boolean;
begin
  Result := False;
  // allow imports before program header (observed in some examples)
  while Check(tkKwImport) do
    ParseImports(AProgram);

  if Check(tkKwProgramUi) then
  begin
    Advance;
    AProgram.IsGui := True;
    if Check(tkIdentifier) then
    begin
      AProgram.ProgramName := Cur.Text;
      Advance;
    end
    else
      ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy programu');
    Match(tkSemi);
    Exit(True);
  end;
  if Check(tkKwProgram) then
  begin
    Advance;
    AProgram.IsGui := False;
    if Check(tkIdentifier) then
    begin
      AProgram.ProgramName := Cur.Text;
      Advance;
    end
    else
      ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy programu');
    Match(tkSemi);
    Exit(True);
  end;
  ErrorAt(Cur, AVOK_ParseUnexpectedToken, 'Oczekiwano program lub program_ui');
end;

procedure TAvocadoParser.ParseImports(AProgram: TAvocadoProgram);
var
  Name: string;
begin
  // one import statement; may list comma-separated modules
  while Check(tkKwImport) do
  begin
    Advance;
    repeat
      Name := '';
      if Check(tkIdentifier) then
      begin
        Name := Cur.Text;
        Advance;
        while Check(tkDot) do
        begin
          Advance;
          if Check(tkIdentifier) then
          begin
            Name := Name + '.' + Cur.Text;
            Advance;
          end
          else
          begin
            ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy modułu po kropce');
            Break;
          end;
        end;
        if Name <> '' then
          AProgram.Imports.Add(Name);
      end
      else if Check(tkKwModulePas) then
        Break
      else
        Break;
    until not Match(tkComma);
    Match(tkSemi);
  end;

  // moduły_pas a, b
  while Check(tkKwModulePas) do
  begin
    Advance;
    repeat
      if Check(tkIdentifier) then
      begin
        AProgram.ImplementationUnits.Add(Cur.Text);
        Advance;
        while Check(tkDot) do
        begin
          Advance;
          if Check(tkIdentifier) then
          begin
            AProgram.ImplementationUnits[AProgram.ImplementationUnits.Count - 1] :=
              AProgram.ImplementationUnits[AProgram.ImplementationUnits.Count - 1] + '.' + Cur.Text;
            Advance;
          end
          else
            Break;
        end;
      end
      else
        Break;
    until not Match(tkComma);
    Match(tkSemi);
  end;
end;

function TAvocadoParser.ParseParams: TAvocadoNodeArray;
var
  Param: TAvocadoParam;
  TypeTok: TAvocadoToken;
  Shared: TStringList;
  I: Integer;
  StartTok: TAvocadoToken;
begin
  Result := nil;
  // parameterless routines omit parentheses entirely
  if not Check(tkLParen) then Exit;
  if not Expect(tkLParen, '(') then Exit;
  if Check(tkRParen) then
  begin
    Advance;
    Exit;
  end;
  Shared := TStringList.Create;
  try
    repeat
      StartTok := Cur;
      Shared.Clear;
      // one or more names
      if Check(tkIdentifier) then
      begin
        Shared.Add(Cur.Text);
        Advance;
        while Match(tkComma) do
        begin
          if Check(tkIdentifier) then
          begin
            Shared.Add(Cur.Text);
            Advance;
          end
          else
            Break;
        end;
      end
      else
      begin
        ErrorAt(Cur, AVOK_ParseBadParameter, 'Oczekiwano nazwy parametru');
        Break;
      end;
      if not Expect(tkColon, ':') then Break;
      if not Check(tkIdentifier) then
      begin
        ErrorAt(Cur, AVOK_ParseBadParameter, 'Oczekiwano typu parametru');
        Break;
      end;
      TypeTok := Cur;
      Advance;
      Param := TAvocadoParam.Create(SpanFrom(StartTok));
      Param.TypeName := TypeTok.Text;
      Param.ResolvedTypeName := FLang.ResolveType(TypeTok.Text);
      for I := 0 to Shared.Count - 1 do
        Param.Names.Add(Shared[I]);
      I := Length(Result);
      SetLength(Result, I + 1);
      Result[I] := Param;
    until not Match(tkSemi);
  finally
    Shared.Free;
  end;
  Expect(tkRParen, ')');
end;

function TAvocadoParser.ParseRoutine: TAvocadoRoutine;
var
  StartTok: TAvocadoToken;
  IsFunc: Boolean;
  Name: string;
  Params: TAvocadoNodeArray;
  RetType: string;
  Body: TAvocadoBlockStmt;
  R: TAvocadoRoutine;
  St: TAvocadoStmt;
  VD: TAvocadoVarDecl;
begin
  StartTok := Cur;
  IsFunc := Cur.Kind = tkKwFunction;
  Advance;
  if not Check(tkIdentifier) then
  begin
    ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano nazwy procedury/funkcji');
    Exit(nil);
  end;
  Name := Cur.Text;
  Advance;
  Params := ParseParams;
  RetType := '';
  if Match(tkColon) then
  begin
    if Check(tkIdentifier) then
    begin
      RetType := Cur.Text;
      Advance;
    end
    else
      ErrorAt(Cur, AVOK_ParseExpectedIdent, 'Oczekiwano typu wynikowego funkcji');
  end;

  R := TAvocadoRoutine.Create(SpanFrom(StartTok));
  R.Name := Name;
  R.IsFunction := IsFunc or (RetType <> '');
  R.Params := Params;
  R.ReturnTypeName := RetType;
  if RetType <> '' then
    R.ResolvedReturnTypeName := FLang.ResolveType(RetType);

  // body: main-open ... block-end
  if Check(tkKwMainOpen) then
  begin
    Advance;
    Body := TAvocadoBlockStmt.Create(SpanOf(Cur));
    while (not AtEnd) and (not Check(tkKwBlockEnd)) do
    begin
      SkipSemis;
      if Check(tkKwBlockEnd) then Break;
      if CheckAny([tkKwProcedure, tkKwFunction, tkKwProgram, tkKwProgramUi]) then
      begin
        ErrorAt(Cur, AVOK_ParseUnclosedBlock, 'Brak koniec/end przed deklaracją ' + Cur.Text);
        Break;
      end;
      St := ParseStatement;
      if St <> nil then
      begin
        if St is TAvocadoVarDecl then
        begin
          // Locals are owned by LocalVars only; codegen emits var + init.
          VD := TAvocadoVarDecl(St);
          VD.IsLocal := True;
          R.AddLocalVar(VD);
        end
        else
          Body.Add(St);
      end
      else
        RecoverToStatementBoundary;
    end;
    if Check(tkKwBlockEnd) then
      Advance
    else
      ErrorAt(Cur, AVOK_ParseUnclosedBlock, 'Brak zamknięcia procedury/funkcji (koniec/end)');
  end
  else
  begin
    ErrorAt(Cur, AVOK_ParseExpectedToken, 'Oczekiwano początku ciała (początek/start)');
    Body := TAvocadoBlockStmt.Create(SpanOf(Cur));
  end;
  R.Body := Body;
  Result := R;
end;

function TAvocadoParser.ParseProgram: TAvocadoProgram;
var
  Prog: TAvocadoProgram;
  StartTok: TAvocadoToken;
  MainBlk: TAvocadoBlockStmt;
  St: TAvocadoStmt;
  VD: TAvocadoVarDecl;
  R: TAvocadoRoutine;
  Closed: Boolean;
  OpenBlocks: Integer;
begin
  StartTok := Cur;
  Prog := TAvocadoProgram.Create(SpanOf(StartTok));
  Prog.MainBlock := nil;

  if not ParseHeader(Prog) then
  begin
    // still try to continue
  end;
  ParseImports(Prog);

  MainBlk := TAvocadoBlockStmt.Create(SpanOf(Cur));
  Prog.MainBlock := MainBlk;

  // Global decls + main block + trailing routines
  // Structure: decls* MAIN_OPEN stmts MAIN_END '.' routine*
  Closed := False;
  OpenBlocks := 0;

  while not AtEnd do
  begin
    SkipSemis;
    if AtEnd then Break;

    if Check(tkKwImport) then
    begin
      ParseImports(Prog);
      Continue;
    end;

    if CheckAny([tkKwProcedure, tkKwFunction]) then
    begin
      R := ParseRoutine;
      if R <> nil then
        Prog.AddRoutine(R);
      Continue;
    end;

    if Check(tkKwProgram) or Check(tkKwProgramUi) then
    begin
      ErrorAt(Cur, AVOK_ParseUnexpectedToken, 'Druga deklaracja programu');
      Advance;
      Continue;
    end;

    if Check(tkKwMainOpen) and (OpenBlocks = 0) and (not Closed) then
    begin
      // main block starts
      Advance;
      OpenBlocks := 1;
      while (not AtEnd) and (OpenBlocks > 0) do
      begin
        SkipSemis;
        if AtEnd then Break;
        if Check(tkKwBlockEnd) then
        begin
          Advance;
          Dec(OpenBlocks);
          if OpenBlocks = 0 then
          begin
            // expect '.' for program end
            if Check(tkDot) then
            begin
              Advance;
              Closed := True;
            end
            else
            begin
              ErrorAt(Cur, AVOK_ParseMissingProgramEnd,
                'Oczekiwano kropki po koniec/end programu');
              Closed := True;
            end;
            Break;
          end;
          // nested block closed; 'koniec.' may follow on the same token stream
          if Check(tkDot) then
          begin
            // compatibility: koniec. closes remaining blocks (e.g. hello.avocado)
            FDiags.AddWarning(AVOK_ParseBlockClosedAtEof,
              'Zamknięto otwarte bloki przy końcu programu (brak koniec)',
              SpanOf(Cur), FSrc.FileName);
            Advance;
            OpenBlocks := 0;
            Closed := True;
            Break;
          end;
          Continue;
        end;
        if CheckAny([tkKwProcedure, tkKwFunction]) then
        begin
          // routines after main body without proper close
          if OpenBlocks > 1 then
            ErrorAt(Cur, AVOK_ParseUnclosedBlock, 'Brak koniec/end przed procedurą');
          OpenBlocks := 0;
          Closed := True;
          Break;
        end;
        if Check(tkDot) then
        begin
          FDiags.AddWarning(AVOK_ParseBlockClosedAtEof,
            'Zamknięto otwarte bloki przy końcu programu (brak koniec)',
            SpanOf(Cur), FSrc.FileName);
          Advance;
          OpenBlocks := 0;
          Closed := True;
          Break;
        end;
        if Check(tkKwMainOpen) then
        begin
          Advance;
          Inc(OpenBlocks);
          Continue;
        end;
        St := ParseStatement;
        if St <> nil then
        begin
          if (St is TAvocadoVarDecl) and (OpenBlocks = 1) then
          begin
            VD := TAvocadoVarDecl(St);
            // decl at main level = global
            Prog.AddGlobalVar(VD);
          end
          else
            MainBlk.Add(St);
        end
        else
          RecoverToStatementBoundary;
      end;
      Continue;
    end;

    // declarations before main block
    if TryParseVarDecl(VD) then
    begin
      Prog.AddGlobalVar(VD);
      Continue;
    end;

    if Check(tkKwBlockEnd) then
    begin
      Advance;
      Continue;
    end;

    if Check(tkDot) then
    begin
      Advance;
      Closed := True;
      Continue;
    end;

    // leftover statements before main: put into main block (lenient)
    St := ParseStatement;
    if St <> nil then
    begin
      if St is TAvocadoVarDecl then
        Prog.AddGlobalVar(TAvocadoVarDecl(St))
      else
        MainBlk.Add(St);
    end
    else
      RecoverToStatementBoundary;
  end;

  if not Closed then
    ErrorAt(Cur, AVOK_ParseMissingProgramEnd, 'Brak kończącego koniec./end. programu');

  Result := Prog;
end;

end.

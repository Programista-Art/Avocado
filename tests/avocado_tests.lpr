program avocado_tests;

{$mode objfpc}{$H+}

{ Unit tests for the Avocado compiler frontend. No LCL dependency. }

uses
  SysUtils, Classes,
  avocado_source, avocado_diagnostics, avocado_tokens, avocado_language,
  avocado_lexer, avocado_ast, avocado_parser, avocado_semantics,
  avocado_codegen, avocado_sourcemap, avocado_compiler;

var
  GPassed, GFailed: Integer;

procedure Check(ACond: Boolean; const AName: string);
begin
  if ACond then
  begin
    Inc(GPassed);
    WriteLn('  PASS  ', AName);
  end
  else
  begin
    Inc(GFailed);
    WriteLn('  FAIL  ', AName);
  end;
end;

procedure Section(const AName: string);
begin
  WriteLn;
  WriteLn('== ', AName, ' ==');
end;

function CompileText(const AText: string): TAvocadoCompileResult;
var
  C: TAvocadoCompiler;
begin
  C := TAvocadoCompiler.Create;
  try
    Result := C.CompileSource('test.avocado', AText);
  finally
    C.Free;
  end;
end;

procedure TestLexerBasics;
var
  Src: TAvocadoSource;
  Lang: TAvocadoLanguage;
  Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer;
  Toks: TAvocadoTokenArray;
  I, IdentCount: Integer;
begin
  Section('Lexer');
  Src := TAvocadoSource.Create('t.avocado',
    'program x' + #10 + 'lc a = 1' + #10 + 'początek' + #10 + 'pisz_linie(''he'')' + #10);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  try
    Toks := Lex.Tokenize;
    Check(Length(Toks) > 5, 'lexer produces tokens');
    Check(Toks[0].Kind = tkKwProgram, 'first token is program');
    Check(Toks[0].Line = 1, 'first token line = 1');
    IdentCount := 0;
    for I := 0 to High(Toks) do
      if Toks[I].Kind = tkIdentifier then Inc(IdentCount);
    Check(IdentCount >= 2, 'identifiers found');
    Check(not Diags.HasErrors, 'no lexer errors on valid input');
  finally
    Lex.Free;
    Diags.Free;
    Lang.Free;
    Src.Free;
  end;
end;

procedure TestLexerPolishAndPositions;
var
  Src: TAvocadoSource;
  Lang: TAvocadoLanguage;
  Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer;
  Toks: TAvocadoTokenArray;
  I: Integer;
  Found: Boolean;
begin
  Src := TAvocadoSource.Create('t.avocado', 'początek' + #10 + 'zwróć 1' + #10);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  try
    Toks := Lex.Tokenize;
    Found := False;
    for I := 0 to High(Toks) do
      if Toks[I].Kind = tkKwMainOpen then
      begin
        Found := True;
        Check(Toks[I].Line = 1, 'początek on line 1');
        Check(Toks[I].Col = 1, 'początek col 1');
      end;
    Check(Found, 'początek lexed as keyword');
    Found := False;
    for I := 0 to High(Toks) do
      if Toks[I].Kind = tkKwReturn then
        Found := True;
    Check(Found, 'zwróć lexed as return keyword');
  finally
    Lex.Free;
    Diags.Free;
    Lang.Free;
    Src.Free;
  end;
end;

procedure TestLexerStringsWithKeywords;
var
  Src: TAvocadoSource;
  Lang: TAvocadoLanguage;
  Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer;
  Toks: TAvocadoTokenArray;
  I: Integer;
  Ok: Boolean;
begin
  // keyword inside string must stay a string
  Src := TAvocadoSource.Create('t.avocado',
    'tekst s = ''koniec początek if''' + #10);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  try
    Toks := Lex.Tokenize;
    Ok := False;
    for I := 0 to High(Toks) do
      if Toks[I].Kind = tkString then
      begin
        Ok := True;
        Check(Toks[I].Text = 'koniec początek if', 'string content preserved');
      end;
    Check(Ok, 'string token present');
  finally
    Lex.Free;
    Diags.Free;
    Lang.Free;
    Src.Free;
  end;
end;

procedure TestLexerEscapeBlock;
var
  Src: TAvocadoSource;
  Lang: TAvocadoLanguage;
  Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer;
  Toks: TAvocadoTokenArray;
  I: Integer;
  Ok: Boolean;
begin
  Src := TAvocadoSource.Create('t.avocado',
    'pascal{' + #10 + 'WriteLn(''end.'');' + #10 + '}' + #10);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  try
    Toks := Lex.Tokenize;
    Ok := False;
    for I := 0 to High(Toks) do
      if Toks[I].Kind = tkPascalBlock then
      begin
        Ok := True;
        Check(Pos('WriteLn', Toks[I].Text) > 0, 'pascal block content kept');
      end;
    Check(Ok, 'pascal{ recognized');
    Check(not Diags.HasErrors, 'no errors on closed pascal block');
  finally
    Lex.Free;
    Diags.Free;
    Lang.Free;
    Src.Free;
  end;
end;

procedure TestParserHello;
var
  Res: TAvocadoCompileResult;
begin
  Section('Parser / Codegen');
  Res := CompileText(
    'program mojrogram' + #10 +
    'liczba_całkowita i' + #10 +
    'początek' + #10 +
    '  pisz_linie(''Witaj w Avocado!'')' + #10 +
    '  dla i = 1 do 5 wykonaj' + #10 +
    '  początek' + #10 +
    '    pisz_linie(''Numer: '', i)' + #10 +
    '  koniec' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'hello translates without errors');
    Check(Pos('program mojrogram', Res.GeneratedPascal.Text) > 0, 'program name emitted');
    Check(Pos('WriteLn', Res.GeneratedPascal.Text) > 0, 'WriteLn emitted');
    Check(Pos('for i := 1 to 5 do', Res.GeneratedPascal.Text) > 0, 'for loop emitted');
    Check(Pos('end.', Res.GeneratedPascal.Text) > 0, 'program end emitted');
  finally
    Res.Free;
  end;
end;

procedure TestParserNestedCalls;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  pisz_linie(f(g(1, 2), 3), h(4))' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'nested calls compile');
    Check(Pos('WriteLn(f(g(1, 2), 3), h(4))', Res.GeneratedPascal.Text) > 0,
      'nested call commas preserved');
  finally
    Res.Free;
  end;
end;

procedure TestParserEmptyCall;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  randomize' + #10 +
    '  randomize()' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'empty and bare calls compile');
  finally
    Res.Free;
  end;
end;

procedure TestParserPolishEnglishSameAst;
var
  A, B: TAvocadoCompileResult;
  PA, PB: string;
begin
  A := CompileText(
    'program p' + #10 + 'start' + #10 +
    '  jeżeli 1 = 1 wtedy' + #10 + '  początek' + #10 +
    '    pisz_linie(''x'')' + #10 + '  koniec' + #10 +
    'koniec.' + #10);
  B := CompileText(
    'program p' + #10 + 'start' + #10 +
    '  if 1 = 1 then' + #10 + '  start' + #10 +
    '    print_line(''x'')' + #10 + '  end' + #10 +
    'koniec.' + #10);
  try
    PA := StringReplace(A.GeneratedPascal.Text, 'WriteLn', 'W', [rfReplaceAll]);
    PB := StringReplace(B.GeneratedPascal.Text, 'WriteLn', 'W', [rfReplaceAll]);
    PA := StringReplace(PA, 'p', 'P', [rfReplaceAll]);
    PB := StringReplace(PB, 'p', 'P', [rfReplaceAll]);
    // both should contain if-then and WriteLn
    Check(A.Success and B.Success, 'PL and EN variants both compile');
    Check(Pos('if (1 = 1) then', A.GeneratedPascal.Text) > 0, 'PL if -> Pascal if');
    Check(Pos('if (1 = 1) then', B.GeneratedPascal.Text) > 0, 'EN if -> Pascal if');
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TestParserPrecedence;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 + 'start' + #10 +
    '  lc x = 1 + 2 * 3' + #10 +
    '  lc y = (1 + 2) * 3' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'precedence compiles');
    Check(Pos('1 + (2 * 3)', Res.GeneratedPascal.Text) > 0, 'mul binds tighter');
    Check(Pos('((1 + 2) * 3)', Res.GeneratedPascal.Text) > 0, 'parens preserved');
  finally
    Res.Free;
  end;
end;

procedure TestParserProceduresAfterMain;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  hello' + #10 +
    'koniec.' + #10 +
    #10 +
    'procedura hello' + #10 +
    'start' + #10 +
    '  pisz_linie(''hi'')' + #10 +
    'koniec' + #10);
  try
    Check(Res.Success, 'procedure after main compiles');
    Check(Pos('procedure hello', Res.GeneratedPascal.Text) > 0, 'procedure emitted');
    // procedure must appear BEFORE main begin
    Check(Pos('procedure hello', Res.GeneratedPascal.Text) <
          Pos('begin', Res.GeneratedPascal.Text), 'procedure before main block');
  finally
    Res.Free;
  end;
end;

procedure TestParserMalformed;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText('program p' + #10 + 'start' + #10 + '  jeżeli' + #10 + 'koniec.' + #10);
  try
    Check(not Res.Success, 'malformed if reports error');
    Check(Res.Diagnostics.Count > 0, 'diagnostics produced');
  finally
    Res.Free;
  end;
end;

procedure TestRepeatedCompilation;
var
  C: TAvocadoCompiler;
  R1, R2: TAvocadoCompileResult;
begin
  Section('Isolation');
  C := TAvocadoCompiler.Create;
  try
    R1 := C.CompileSource('a.avocado',
      'program a' + #10 + 'start' + #10 + '  lc x = 1' + #10 + 'koniec.' + #10);
    R2 := C.CompileSource('b.avocado',
      'program b' + #10 + 'start' + #10 + '  pisz_linie(1)' + #10 + 'koniec.' + #10);
    try
      Check(R1.Success and R2.Success, 'two compilations succeed');
      Check(Pos('program a', R1.GeneratedPascal.Text) > 0, 'first result has program a');
      Check(Pos('program b', R2.GeneratedPascal.Text) > 0, 'second result has program b');
      Check(Pos('program a', R2.GeneratedPascal.Text) = 0, 'no state leak from first');
      Check(Pos('x:', R2.GeneratedPascal.Text) = 0, 'no variable leak from first');
    finally
      R1.Free;
      R2.Free;
    end;
  finally
    C.Free;
  end;
end;

procedure TestFunctionReturn;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  lc r = dodaj(5, 10)' + #10 +
    'koniec.' + #10 +
    #10 +
    'funkcja dodaj(a: lc; b: lc): lc' + #10 +
    'start' + #10 +
    '  zwróć a + b' + #10 +
    'koniec' + #10);
  try
    Check(Res.Success, 'function compiles');
    Check(Pos('function dodaj(a: Integer; b: Integer): Integer', Res.GeneratedPascal.Text) > 0,
      'function header emitted');
    Check(Pos('Result := (a + b)', Res.GeneratedPascal.Text) > 0, 'return emitted as Result');
  finally
    Res.Free;
  end;
end;

procedure TestPascalBlockNotTranslated;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    'pascal{' + #10 +
    '  pisz_linie(''should stay'');' + #10 +
    '}' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'pascal block compiles');
    Check(Pos('pysz_linie', Res.GeneratedPascal.Text) = 0, 'no bogus rewrite');
    // raw content is preserved (pysz_linie would be a bad rewrite of pisz_linie)
    Check(Pos('should stay', Res.GeneratedPascal.Text) > 0, 'pascal content preserved');
  finally
    Res.Free;
  end;
end;

procedure TestCommentsNotTranslated;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  // pisz_linie(''in comment'')' + #10 +
    '  lc a = 1' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'comments ignored');
    Check(Pos('in comment', Res.GeneratedPascal.Text) = 0, 'comment text not emitted');
  finally
    Res.Free;
  end;
end;

procedure TestAssignmentVsEquality;
var
  Res: TAvocadoCompileResult;
begin
  Section('Assignment vs equality');
  Res := CompileText(
    'program p' + #10 +
    'start' + #10 +
    '  lc a = 1' + #10 +
    '  a = 2' + #10 +
    '  jeżeli a = 2 wtedy' + #10 +
    '  początek' + #10 +
    '    a = 3' + #10 +
    '  koniec' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'assignment and equality compile');
    Check(Pos('a := 2', Res.GeneratedPascal.Text) > 0, 'a = 2 is assignment');
    Check(Pos('if (a = 2) then', Res.GeneratedPascal.Text) > 0, 'a = 2 in if is equality');
    Check(Pos('a := 3', Res.GeneratedPascal.Text) > 0, 'nested assignment');
  finally
    Res.Free;
  end;
end;

procedure TestForVarReusesGlobal;
var
  Res: TAvocadoCompileResult;
begin
  Res := CompileText(
    'program p' + #10 +
    'lc i' + #10 +
    'start' + #10 +
    '  dla i = 1 do 3 wykonaj' + #10 +
    '  początek' + #10 +
    '    pisz_linie(i)' + #10 +
    '  koniec' + #10 +
    'koniec.' + #10);
  try
    Check(Res.Success, 'for-loop reusing global i compiles');
    Check(Pos('for i := 1 to 3 do', Res.GeneratedPascal.Text) > 0, 'for uses existing i');
  finally
    Res.Free;
  end;
end;

procedure TestAvoraiserApiNames;
var
  Res: TAvocadoCompileResult;
begin
  Section('Avoraiser API');
  Res := CompileText(
    'program_ui okno' + #10 +
    'import avoraiser.window' + #10 +
    'hwnd my_window' + #10 +
    'main' + #10 +
    '  my_win' + #10 +
    '  uruchom_aplikacje' + #10 +
    'end.' + #10 +
    #10 +
    'procedure my_win' + #10 +
    'start' + #10 +
    '  ui_parameters ui' + #10 +
    '  ui.tytul = ''Hello''' + #10 +
    '  my_window = utworz_okno(ui)' + #10 +
    '  wysrodkuj_okno(my_window)' + #10 +
    '  ustaw_tytul(my_window, ''Tytul'')' + #10 +
    '  pokaz(my_window)' + #10 +
    '  reaguj_na_klikniecie(my_window, @handler)' + #10 +
    '  przegladarka_stworz(my_window)' + #10 +
    'end' + #10);
  try
    Check(Res.Success, 'avoraiser API program compiles');
    Check(Pos('create_window', Res.GeneratedPascal.Text) > 0, 'utworz_okno -> create_window');
    Check(Pos('center_window', Res.GeneratedPascal.Text) > 0, 'wysrodkuj_okno -> center_window');
    Check(Pos('set_title', Res.GeneratedPascal.Text) > 0, 'ustaw_tytul -> set_title');
    Check(Pos('run_app', Res.GeneratedPascal.Text) > 0, 'uruchom_aplikacje -> run_app');
    Check(Pos('set_on_click', Res.GeneratedPascal.Text) > 0, 'reaguj_na_klikniecie -> set_on_click');
    Check(Pos('webview_create', Res.GeneratedPascal.Text) > 0, 'przegladarka_stworz -> webview_create');
    Check(Pos('avoraiser.window', Res.GeneratedPascal.Text) > 0, 'auto-import avoraiser.window');
    Check(Pos('avoraiser.webview', Res.GeneratedPascal.Text) > 0, 'auto-import avoraiser.webview');
    Check(Res.IsGui, 'program_ui detected as GUI');
  finally
    Res.Free;
  end;
end;

procedure TestDefaultIntrinsic;
var
  Res: TAvocadoCompileResult;
begin
  Section('Pascal intrinsics');
  Res := CompileText(
    'program_ui okno' + #10 +
    'main' + #10 +
    '  test' + #10 +
    'end.' + #10 +
    'procedure test' + #10 +
    'start' + #10 +
    '  ui_parameters ui' + #10 +
    '  ui = Default(TAvocadoWindowParams)' + #10 +
    '  ui = default(parametry_ui)' + #10 +
    'end' + #10);
  try
    Check(Res.Success, 'Default(T) compiles');
    Check(Pos('ui := Default(TAvocadoWindowParams)', Res.GeneratedPascal.Text) > 0,
      'Default emits Pascal type name');
    Check(Pos('Default(', Res.GeneratedPascal.Text) > 0, 'Default call present');
    // no "unknown name TAvocadoWindowParams" error
    Check(Res.Diagnostics.ErrorCount = 0, 'no errors for Default(T)');
  finally
    Res.Free;
  end;
end;

begin
  GPassed := 0;
  GFailed := 0;
  WriteLn('Avocado compiler frontend tests');
  TestLexerBasics;
  TestLexerPolishAndPositions;
  TestLexerStringsWithKeywords;
  TestLexerEscapeBlock;
  TestParserHello;
  TestParserNestedCalls;
  TestParserEmptyCall;
  TestParserPolishEnglishSameAst;
  TestParserPrecedence;
  TestParserProceduresAfterMain;
  TestParserMalformed;
  TestFunctionReturn;
  TestPascalBlockNotTranslated;
  TestCommentsNotTranslated;
  TestAssignmentVsEquality;
  TestForVarReusesGlobal;
  TestAvoraiserApiNames;
  TestDefaultIntrinsic;
  TestRepeatedCompilation;
  WriteLn;
  WriteLn(Format('Passed: %d  Failed: %d', [GPassed, GFailed]));
  if GFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.

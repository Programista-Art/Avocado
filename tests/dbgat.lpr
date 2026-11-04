program dbgat;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens,
  avocado_language, avocado_lexer, avocado_ast, avocado_parser;
var
  Src: TAvocadoSource; Lang: TAvocadoLanguage; Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer; P: TAvocadoParser; Prog: TAvocadoProgram; Toks: TAvocadoTokenArray;
  I: Integer;
  C: TAvocadoCallExpr;
begin
  Src := TAvocadoSource.Create('t.avocado',
    'program p' + LineEnding + 'start' + LineEnding +
    '  foo(@bar)' + LineEnding + 'koniec.' + LineEnding);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  Toks := Lex.Tokenize;
  for I := 0 to High(Toks) do
    WriteLn(I, ': kind=', Ord(Toks[I].Kind), ' [', Toks[I].Text, ']');
  P := TAvocadoParser.Create(Toks, Lang, Diags, Src);
  WriteLn('parsing...');
  Prog := P.ParseProgram;
  WriteLn('parsed ok, main stmts=', Length(Prog.MainBlock.Stmts));
  if Length(Prog.MainBlock.Stmts) > 0 then
  begin
    WriteLn('stmt class=', Prog.MainBlock.Stmts[0].ClassName);
    if Prog.MainBlock.Stmts[0] is TAvocadoCallStmt then
    begin
      C := TAvocadoCallStmt(Prog.MainBlock.Stmts[0]).Call;
      WriteLn('callee=', C.CalleeName, ' args=', C.ArgCount);
      if C.ArgCount > 0 then
        WriteLn('arg0=', C.Args[0].ClassName);
    end;
  end;
  WriteLn('done');
end.

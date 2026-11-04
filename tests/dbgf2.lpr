program dbgf2;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens,
  avocado_language, avocado_lexer, avocado_ast, avocado_parser;
var
  Src: TAvocadoSource; Lang: TAvocadoLanguage; Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer; P: TAvocadoParser; Prog: TAvocadoProgram; Toks: TAvocadoTokenArray;
  C: TAvocadoCallExpr;
begin
  Src := TAvocadoSource.Create('t.avocado',
    'program p' + LineEnding + 'start' + LineEnding +
    '  foo(@bar)' + LineEnding + 'koniec.' + LineEnding);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  Toks := Lex.Tokenize;
  P := TAvocadoParser.Create(Toks, Lang, Diags, Src);
  Prog := P.ParseProgram;
  WriteLn('stmt0=', Prog.MainBlock.Stmts[0].ClassName);
  C := TAvocadoCallStmt(Prog.MainBlock.Stmts[0]).Call;
  WriteLn('callee=', C.CalleeName, ' nargs=', C.ArgCount);
  WriteLn('arg0 class=', C.Args[0].ClassName);
  WriteLn('freeing...');
  Prog.Free;
  WriteLn('ok');
end.

program dbgf;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens,
  avocado_language, avocado_lexer, avocado_ast, avocado_parser;
var
  Src: TAvocadoSource; Lang: TAvocadoLanguage; Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer; P: TAvocadoParser; Prog: TAvocadoProgram; Toks: TAvocadoTokenArray;
  U: TAvocadoUnaryExpr; C: TAvocadoCallExpr;
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
  C := TAvocadoCallStmt(Prog.MainBlock.Stmts[0]).Call;
  U := TAvocadoUnaryExpr(C.Args[0]);
  WriteLn('Unary op=', U.Op, ' operand=', U.Operand.ClassName);
  WriteLn('operand is nil? ', U.Operand = nil);
  WriteLn('freeing prog...');
  Prog.Free;
  WriteLn('freed ok');
end.

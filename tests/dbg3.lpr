program dbg3;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_tokens,
  avocado_language, avocado_lexer, avocado_ast, avocado_parser;
var
  Src: TAvocadoSource; Lang: TAvocadoLanguage; Diags: TAvocadoDiagnosticList;
  Lex: TAvocadoLexer; P: TAvocadoParser; Prog: TAvocadoProgram; Toks: TAvocadoTokenArray;
  V: TAvocadoVarDecl; C: TAvocadoCallExpr; I: Integer;
begin
  Src := TAvocadoSource.Create('t.avocado',
    'program p' + LineEnding + 'start' + LineEnding +
    '  lc x = dodaj(5, 10)' + LineEnding + 'koniec.' + LineEnding);
  Lang := TAvocadoLanguage.Create;
  Diags := TAvocadoDiagnosticList.Create;
  Lex := TAvocadoLexer.Create(Src, Lang, Diags);
  Toks := Lex.Tokenize;
  WriteLn('TOKENS:');
  for I := 0 to High(Toks) do
    WriteLn(I, ': kind=', Ord(Toks[I].Kind), ' text=[', Toks[I].Text, ']');
  P := TAvocadoParser.Create(Toks, Lang, Diags, Src);
  Prog := P.ParseProgram;
  WriteLn('GlobalVars=', Length(Prog.GlobalVars));
  if Length(Prog.GlobalVars) > 0 then
  begin
    V := TAvocadoVarDecl(Prog.GlobalVars[0]);
    WriteLn('Var=', V.VarName, ' Type=', V.TypeName, ' InitClass=', V.InitValue.ClassName);
    if V.InitValue is TAvocadoCallExpr then
    begin
      C := TAvocadoCallExpr(V.InitValue);
      WriteLn('Callee=[', C.CalleeName, '] Args=', C.ArgCount);
    end;
  end;
  WriteLn('Diags=', Diags.Count);
  for I := 0 to Diags.Count-1 do WriteLn(Diags[I].FormatText);
end.

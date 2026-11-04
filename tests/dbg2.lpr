program dbg2;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_language,
  avocado_lexer, avocado_ast, avocado_parser, avocado_compiler;
var
  C: TAvocadoCompiler;
  R: TAvocadoCompileResult;
begin
  C := TAvocadoCompiler.Create;
  R := C.CompileSource('t.avocado',
    'program p'#10'start'#10'  lc x = dodaj(5, 10)'#10'  pisz_linie(x)'#10'koniec.'#10);
  WriteLn('Success=', R.Success);
  WriteLn(R.GeneratedPascal.Text);
  R.Free; C.Free;
end.

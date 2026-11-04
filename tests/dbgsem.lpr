program dbgsem;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
begin
  C := TAvocadoCompiler.Create;
  WriteLn('1: foo(@bar)');
  R := C.CompileSource('t.avocado',
    'program p' + LineEnding + 'start' + LineEnding +
    '  foo(@bar)' + LineEnding + 'koniec.' + LineEnding);
  WriteLn('success=', R.Success);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  WriteLn(R.GeneratedPascal.Text);
  R.Free; C.Free;
end.

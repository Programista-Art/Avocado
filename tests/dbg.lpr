program dbg;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
begin
  C := TAvocadoCompiler.Create;
  R := C.CompileFile('tests/dbg.avocado');
  for I := 0 to R.Diagnostics.Count-1 do
    WriteLn(R.Diagnostics[I].FormatText);
  WriteLn('---PASCAL---');
  WriteLn(R.GeneratedPascal.Text);
  WriteLn('Success=', R.Success);
  R.Free; C.Free;
end.

program dbgapi2;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
begin
  C := TAvocadoCompiler.Create;
  WriteLn('compiling...');
  R := C.CompileSource('t.avocado',
    'program_ui okno' + LineEnding +
    'main' + LineEnding +
    '  uruchom_aplikacje' + LineEnding +
    'end.' + LineEnding);
  WriteLn('success=', R.Success, ' diags=', R.Diagnostics.Count);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  WriteLn(R.GeneratedPascal.Text);
  R.Free; C.Free;
end.

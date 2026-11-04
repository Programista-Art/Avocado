program dbgdef;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
begin
  C := TAvocadoCompiler.Create;
  R := C.CompileSource('t.avocado',
    'program_ui okno' + LineEnding +
    'main' + LineEnding +
    '  test' + LineEnding +
    'end.' + LineEnding +
    'procedure test' + LineEnding +
    'start' + LineEnding +
    '  ui_parameters ui' + LineEnding +
    '  ui = Default(TAvocadoWindowParams)' + LineEnding +
    '  ui = default(TAvocadoWindowParams)' + LineEnding +
    'end' + LineEnding);
  WriteLn('success=', R.Success);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  WriteLn(R.GeneratedPascal.Text);
  R.Free; C.Free;
end.

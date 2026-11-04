program dbgapi3;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
  Src: string;
begin
  C := TAvocadoCompiler.Create;
  Src :=
    'program_ui okno' + LineEnding +
    'import avoraiser.window' + LineEnding +
    'hwnd my_window' + LineEnding +
    'main' + LineEnding +
    '  my_win' + LineEnding +
    '  uruchom_aplikacje' + LineEnding +
    'end.' + LineEnding +
    LineEnding +
    'procedure my_win' + LineEnding +
    'start' + LineEnding +
    '  ui_parameters ui' + LineEnding +
    '  ui.tytul = ''Hello''' + LineEnding +
    '  my_window = utworz_okno(ui)' + LineEnding +
    '  wysrodkuj_okno(my_window)' + LineEnding +
    '  ustaw_tytul(my_window, ''Tytul'')' + LineEnding +
    '  pokaz(my_window)' + LineEnding +
    'end' + LineEnding;
  WriteLn('compiling...');
  R := C.CompileSource('t.avocado', Src);
  WriteLn('success=', R.Success);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  WriteLn(R.GeneratedPascal.Text);
  R.Free; C.Free;
end.

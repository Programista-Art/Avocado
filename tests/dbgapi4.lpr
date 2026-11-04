program dbgapi4;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;
var C: TAvocadoCompiler; R: TAvocadoCompileResult; I: Integer;
  Src: string;
begin
  C := TAvocadoCompiler.Create;
  Src :=
    'program_ui okno' + LineEnding +
    'main' + LineEnding +
    '  test' + LineEnding +
    'end.' + LineEnding +
    'procedure test' + LineEnding +
    'start' + LineEnding +
    '  hwnd h' + LineEnding +
    '  reaguj_na_klikniecie(h, @handler)' + LineEnding +
    'end' + LineEnding;
  WriteLn('A: @handler...');
  R := C.CompileSource('t.avocado', Src);
  WriteLn('success=', R.Success);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  R.Free;

  Src :=
    'program_ui okno' + LineEnding +
    'main' + LineEnding +
    '  test' + LineEnding +
    'end.' + LineEnding +
    'procedure test' + LineEnding +
    'start' + LineEnding +
    '  hwnd h' + LineEnding +
    '  przegladarka_stworz(h)' + LineEnding +
    'end' + LineEnding;
  WriteLn('B: webview...');
  R := C.CompileSource('t.avocado', Src);
  WriteLn('success=', R.Success);
  for I := 0 to R.Diagnostics.Count-1 do WriteLn(R.Diagnostics[I].FormatText);
  R.Free;
  C.Free;
end.

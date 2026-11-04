program e2e;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;

procedure One(const AName: string);
var
  C: TAvocadoCompiler;
  R: TAvocadoCompileResult;
  Pas: string;
  I: Integer;
begin
  C := TAvocadoCompiler.Create;
  R := C.CompileFile('examples\' + AName);
  Pas := 'tests\' + ChangeFileExt(AName, '.pas');
  R.GeneratedPascal.SaveToFile(Pas);
  WriteLn('=== ', AName, ' success=', R.Success);
  for I := 0 to R.Diagnostics.Count - 1 do
    if R.Diagnostics[I].Severity = adsError then
      WriteLn('  ', R.Diagnostics[I].FormatText);
  WriteLn(R.GeneratedPascal.Text);
  R.Free;
  C.Free;
end;

begin
  One('hello.avocado');
  One('calculation.avocado');
  One('While.avocado');
  One('Funkcje.avocado');
end.

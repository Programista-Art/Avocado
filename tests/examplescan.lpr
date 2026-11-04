program examplescan;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_diagnostics, avocado_compiler;

procedure Scan(const ADir: string);
var
  Info: TSearchRec;
  C: TAvocadoCompiler;
  R: TAvocadoCompileResult;
  Path: string;
  Ok, Err, I: Integer;
begin
  C := TAvocadoCompiler.Create;
  Ok := 0; Err := 0;
  if FindFirst(ADir + '\*.avocado', faAnyFile, Info) = 0 then
  repeat
    Path := ADir + '\' + Info.Name;
    R := C.CompileFile(Path);
    if R.Success then Inc(Ok) else Inc(Err);
    WriteLn(Format('%s | %s | diags=%d',
      [BoolToStr(R.Success, 'OK  ', 'FAIL'), Info.Name, R.Diagnostics.Count]));
    if not R.Success then
      for I := 0 to R.Diagnostics.Count - 1 do
        if R.Diagnostics[I].Severity = adsError then
          WriteLn('    ', R.Diagnostics[I].FormatText);
    R.Free;
  until FindNext(Info) <> 0;
  FindClose(Info);
  WriteLn(Format('--- %s : ok=%d fail=%d ---', [ADir, Ok, Err]));
  C.Free;
end;

begin
  Scan('examples');
end.

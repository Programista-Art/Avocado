program avocado_cli;

{$mode objfpc}{$H+}

{ Command-line frontend for the Avocado compiler.
  Does not require Lazarus / LCL. }

uses
  SysUtils, Classes,
  avocado_source, avocado_diagnostics, avocado_compiler;

procedure PrintUsage;
begin
  WriteLn('Avocado compiler frontend');
  WriteLn('Usage:');
  WriteLn('  avocado_cli check <file.avocado>     Check only (exit 1 on errors)');
  WriteLn('  avocado_cli translate <file> [-o out.pas]   Translate to Pascal');
  WriteLn('  avocado_cli compile <file> [-o out.exe]     Translate + invoke FPC');
  WriteLn('Options:');
  WriteLn('  -o <path>     Output file');
  WriteLn('  --fpc <path>  Path to fpc.exe');
  WriteLn('Exit codes: 0 = success, 1 = errors, 2 = usage/IO error');
end;

function DoTranslate(const AIn, AOut: string; ACompiler: TAvocadoCompiler): Integer;
var
  Res: TAvocadoCompileResult;
  I: Integer;
begin
  Res := ACompiler.CompileFile(AIn);
  try
    for I := 0 to Res.Diagnostics.Count - 1 do
      WriteLn(Res.Diagnostics[I].FormatText);
    if Res.Success then
    begin
      if AOut <> '' then
        Res.GeneratedPascal.SaveToFile(AOut)
      else
        WriteLn(Res.GeneratedPascal.Text);
      WriteLn(ErrOutput, 'OK: ' + IntToStr(Res.Diagnostics.ErrorCount) + ' errors, ' +
        IntToStr(Res.Diagnostics.Count) + ' diagnostics');
      Result := 0;
    end
    else
    begin
      WriteLn(ErrOutput, 'FAILED: ' + IntToStr(Res.Diagnostics.ErrorCount) + ' errors');
      Result := 1;
    end;
  finally
    Res.Free;
  end;
end;

var
  Mode, InFile, OutFile, FpcPath: string;
  I: Integer;
  Compiler: TAvocadoCompiler;
  Res: TAvocadoCompileResult;
  Cmd: string;
  RC: Integer;
begin
  if ParamCount < 2 then
  begin
    PrintUsage;
    Halt(2);
  end;
  Mode := ParamStr(1);
  InFile := ParamStr(2);
  OutFile := '';
  FpcPath := 'fpc';
  I := 3;
  while I <= ParamCount do
  begin
    if ParamStr(I) = '-o' then
    begin
      Inc(I);
      if I <= ParamCount then OutFile := ParamStr(I);
    end
    else if ParamStr(I) = '--fpc' then
    begin
      Inc(I);
      if I <= ParamCount then FpcPath := ParamStr(I);
    end;
    Inc(I);
  end;

  if not FileExists(InFile) then
  begin
    WriteLn(ErrOutput, 'Brak pliku: ' + InFile);
    Halt(2);
  end;

  Compiler := TAvocadoCompiler.Create;
  try
    if Mode = 'check' then
    begin
      Res := Compiler.CompileFile(InFile);
      try
        for I := 0 to Res.Diagnostics.Count - 1 do
          WriteLn(Res.Diagnostics[I].FormatText);
        if Res.Success then
        begin
          WriteLn('Brak błędów.');
          Halt(0);
        end
        else
          Halt(1);
      finally
        Res.Free;
      end;
    end
    else if Mode = 'translate' then
    begin
      Halt(DoTranslate(InFile, OutFile, Compiler));
    end
    else if Mode = 'compile' then
    begin
      if OutFile = '' then
        OutFile := ChangeFileExt(InFile, '.pas');
      RC := DoTranslate(InFile, OutFile, Compiler);
      if RC <> 0 then
        Halt(RC);
      Cmd := FpcPath + ' -Px86_64 ' + '"' + OutFile + '"';
      if ChangeFileExt(InFile, '.exe') <> '' then
        Cmd := Cmd + ' -o"' + ChangeFileExt(InFile, '.exe') + '"';
      WriteLn('FPC: ' + Cmd);
      RC := SysUtils.ExecuteProcess('/bin/sh', ['-c', Cmd], []);
      if RC <> 0 then
        Halt(1);
      Halt(0);
    end
    else
    begin
      PrintUsage;
      Halt(2);
    end;
  finally
    Compiler.Free;
  end;
end.

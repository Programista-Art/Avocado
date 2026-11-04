{$codepage utf8}
{$mode objfpc}
{$H+}
program mojrogram;
uses SysUtils, Classes, StrUtils, Windows, Crt;

var
  i: Integer;

begin
{$IFDEF WINDOWS}
  SetConsoleCP(65001);
  SetConsoleOutputCP(65001);
{$ENDIF}
  SetTextCodePage(Output, 65001);
  SetTextCodePage(Input, 65001);
  WriteLn('Witaj w Avocado!');
  for i := 1 to 5 do
  begin
    WriteLn(('Numer: ' + IntToStr(i)));
    ReadKey();
  end;
  Readln;
end.

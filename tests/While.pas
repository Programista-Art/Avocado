{$codepage utf8}
{$mode objfpc}
{$H+}
program warunek;
uses SysUtils, Classes, StrUtils, Windows;

procedure warunek_test;
var
  a: Integer;
  c: Integer;
begin
  a := 12;
  c := 6;
  if (a > 11) then
  begin
    WriteLn('Wynik: a większe od c (a>11)');
  end
  else
    WriteLn('Wynik: a mniejsze od c (a<11)');
end;

begin
{$IFDEF WINDOWS}
  SetConsoleCP(65001);
  SetConsoleOutputCP(65001);
{$ENDIF}
  SetTextCodePage(Output, 65001);
  SetTextCodePage(Input, 65001);
  warunek_test();
  Readln;
end.

{$codepage utf8}
{$mode objfpc}
{$H+}
program calculation;
uses SysUtils, Classes, StrUtils, Windows;

procedure calculation(numb1: Integer; numb2: Integer);
var
  a: Integer;
  b: Integer;
  c: Integer;
begin
  a := numb1;
  b := numb2;
  c := (numb1 + numb2);
  WriteLn('Calculation result: ', c);
end;

begin
{$IFDEF WINDOWS}
  SetConsoleCP(65001);
  SetConsoleOutputCP(65001);
{$ENDIF}
  SetTextCodePage(Output, 65001);
  SetTextCodePage(Input, 65001);
  WriteLn('I''am in the main program.');
  calculation(4, 4);
  Readln;
end.

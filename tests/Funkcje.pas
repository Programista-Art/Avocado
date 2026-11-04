{$codepage utf8}
{$mode objfpc}
{$H+}
program mojafunkcja;
uses SysUtils, Classes, StrUtils, Windows, Crt;

var
  wynik: Integer;
  wynik2: Integer;

function dodaj(a: Integer; b: Integer): Integer;
var
  n: Integer;
begin
  n := 10;
  Result := ((a + b) + n);
  Exit;
end;

function subtract(a: Integer; b: Integer): Integer;
var
  n: Integer;
begin
  n := 5;
  Result := ((a - b) - n);
  Exit;
end;

begin
{$IFDEF WINDOWS}
  SetConsoleCP(65001);
  SetConsoleOutputCP(65001);
{$ENDIF}
  SetTextCodePage(Output, 65001);
  SetTextCodePage(Input, 65001);
  wynik := dodaj(5, 10);
  wynik2 := subtract(10, 2);
  GotoXY(10, 50);
  TextColor(Red);
  TextBackground(White);
  WriteLn('Wynik dodawania: ', wynik);
  WriteLn('Wynik odejmowania: ', wynik2);
  Readln;
end.

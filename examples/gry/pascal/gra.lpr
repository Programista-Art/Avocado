{$codepage cp1252}
{$mode objfpc}
{$H+}
program gra;
uses
  SysUtils, Classes, StrUtils, Dialogs, Windows, raylib;


procedure test;
begin
InitWindow(800, 600, 'Raylib Example');
SetTargetFPS(60);
while not WindowShouldClose() do
begin
BeginDrawing();
ClearBackground(BLACK);
DrawText('Hello from Raylib!', 20, 20, 30, WHITE);
DrawCircle(200, 200, 50, RED);
EndDrawing();
end;
CloseWindow();
end;
begin
{$IFDEF WINDOWS}
  SetConsoleCP(1252);
  SetConsoleOutputCP(1252);
{$ENDIF}
  SetTextCodePage(Output, 1252);
  SetTextCodePage(Input, 1252);

test;
  Readln;
end.



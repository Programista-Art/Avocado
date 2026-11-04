{$codepage utf8}
{$mode objfpc}
{$H+}
program gra;
uses
  SysUtils, Classes, Windows, StrUtils, Dialogs, raylib;


begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
  {$ENDIF}
end.
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
  Readln;
end.

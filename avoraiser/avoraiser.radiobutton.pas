(*
Avoraiser UI Framework - High-Performance WinAPI UI for Avocado
Avoraiser is a framework for creating modern user interfaces for the Polish programming language Avocado.
Copyright (c) 2025-2026 Dymitr Wygowski (Programista Art)
Project Created: 23.12.2025

Author:     Dymitr Wygowski (Programista Art)
Contact:    programista.art@gmail.com
GitHub:     https://github.com/Programista-Art/Avoraiser
Version:    1.0
License:    Dual-Licensed: Avoraiser Community / Commercial
            See LICENSE.md for terms and conditions.

Module:     avoraiser.radiobutton
Description:
*)
unit avoraiser.radiobutton;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core;

function create_radio_button(Parent: HWND; const Caption: string; X, Y, Width, Height: Integer; ID: Integer): HWND;
// Funkcja do sprawdzania, czy radio jest zaznaczone
function is_radio_button_checked(hRadio: HWND): Boolean;
// Funkcja do ręcznego zaznaczania
procedure set_radio_button_check(hRadio: HWND; Checked: Boolean);

implementation



function create_radio_button(Parent: HWND; const Caption: string; X, Y, Width,
  Height: Integer; ID: Integer): HWND;
begin
   // Używamy CreateWindowExW dla obsługi Unicode (polskie znaki)
  Result := CreateWindowExW(
    0,
    'BUTTON',
    PWideChar(UnicodeString(Caption)),
    WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON or WS_TABSTOP,
    X, Y, Width, Height,
    Parent,
    HMENU(ID),
    GetModuleHandle(nil),
    nil
  );

  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function is_radio_button_checked(hRadio: HWND): Boolean;
const
  BM_GETCHECK = $00F0;
  BST_CHECKED = $0001;
begin
  if hRadio = 0 then Exit(False);
    Result := SendMessage(hRadio, BM_GETCHECK, 0, 0) = BST_CHECKED;
end;

procedure set_radio_button_check(hRadio: HWND; Checked: Boolean);
const
  BM_SETCHECK   = $00F1;
  BST_CHECKED   = $0001;
  BST_UNCHECKED = $0000;
begin
    if hRadio = 0 then Exit;
    if Checked then
      SendMessage(hRadio, BM_SETCHECK, BST_CHECKED, 0)
    else
      SendMessage(hRadio, BM_SETCHECK, BST_UNCHECKED, 0);
end;

end.


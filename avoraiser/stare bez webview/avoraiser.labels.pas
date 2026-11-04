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

Module:     avoraiser.labels
Description:
*)
unit avoraiser.labels;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core, avoraiser.window,avoraiser.utils;

function create_label(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;


implementation

function label_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
  OldWndProc: WNDPROC;
  MyHFont, MyHBrush: HBRUSH;
begin
   OldWndProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

     case Msg of
       // PRZELICZANIE CZCIONKI
       WM_SIZE:
       begin
         // Używamy funkcji z UTILS!
         set_component_auto_font(hWnd, HiWord(LParam));

         Result := CallWindowProc(OldWndProc, hWnd, Msg, WParam, LParam);
         Exit;
       end;

       // SPRZĄTANIE (Uniwersalne klucze)
       WM_NCDESTROY:
       begin
         // Sprzątanie czcionki
         MyHFont := HFONT(GetPropW(hWnd, AV_PROP_AUTO_FONT));
         if MyHFont <> 0 then DeleteObject(MyHFont);

         // Sprzątanie pędzla
         MyHBrush := HBRUSH(GetPropW(hWnd, AV_PROP_BRUSH));
         if MyHBrush <> 0 then DeleteObject(MyHBrush);

         // Usuwanie właściwości
         RemovePropW(hWnd, AV_PROP_AUTO_FONT);
         RemovePropW(hWnd, AV_PROP_BRUSH);
         RemovePropW(hWnd, AV_PROP_BG_COLOR);
         RemovePropW(hWnd, AV_PROP_TEXT_COLOR);
         RemovePropW(hWnd, 'OldWndProc');

         Result := CallWindowProc(OldWndProc, hWnd, Msg, WParam, LParam);
         Exit;
       end;
     end;

     Result := CallWindowProc(OldWndProc, hWnd, Msg, WParam, LParam);
end;


function create_label(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
var
LabelHandle: HWND;
OldProc: THandle;
begin
   LabelHandle := CreateWindowExW(
     WS_EX_TRANSPARENT,
     'STATIC',
     PWideChar(UnicodeString(Text)),
     WS_VISIBLE or
     WS_CHILD or
     //SS_LEFT or
     SS_CENTERIMAGE or
     SS_NOTIFY or
     SS_LEFTNOWORDWRAP,
     X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
   );

   if LabelHandle <> 0 then
   begin
    OldProc := SetWindowLongPtr(LabelHandle, GWLP_WNDPROC, PtrUInt(@label_proc));
    SetPropW(LabelHandle, 'OldWndProc', OldProc);

    set_component_transparent(LabelHandle, $FFFFFF);
    //set_component_color(LabelHandle, $FFFFFF, $121212);
    set_component_auto_font(LabelHandle, Height);
   end;

   Result := LabelHandle;
end;



end.


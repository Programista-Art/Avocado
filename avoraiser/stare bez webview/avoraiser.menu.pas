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

Module:     avoraiser.menu
Description:
*)

unit avoraiser.menu;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core,avoraiser.events;


// X, Y: Pozycja kursora na ekranie (gdzie ma się pojawić menu)
procedure set_on_context_menu(h_wnd: HWND; event: t_av_context_event);
// Funkcje rejestrujące
procedure set_on_init_menu_popup (h_wnd: HWND; event: t_av_init_menu_event);
procedure set_on_menu_select(h_wnd: HWND; event: t_av_menu_select_event);
procedure set_on_menu_command(Handle: HWND; Event: TAvocadoCommandEvent);
implementation

procedure set_on_context_menu(h_wnd: HWND; event: t_av_context_event);
begin
  SetPropW(h_wnd, AV_PROP_CONTEXT_MENU, HANDLE(PtrUInt(event)));
end;

procedure set_on_init_menu_popup(h_wnd: HWND; event: t_av_init_menu_event);
begin
    if h_wnd <> 0 then
    begin
      SetPropW(h_wnd, AV_PROP_INIT_MENU_POPUP, HANDLE(PtrUInt(event)));
    end;
end;

procedure set_on_menu_select(h_wnd: HWND; event: t_av_menu_select_event);
begin
  if h_wnd <> 0 then
  begin
    SetPropW(h_wnd, AV_PROP_MENU_SELECT, HANDLE(PtrUInt(event)));
  end;
end;

procedure set_on_menu_command(Handle: HWND; Event: TAvocadoCommandEvent);
begin

end;

end.


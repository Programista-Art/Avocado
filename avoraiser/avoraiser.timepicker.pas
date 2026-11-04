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

Module:     avoraiser.timepicker
Description:
*)

unit avoraiser.timepicker;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,
  avoraiser.core;


procedure set_on_time_change(h_wnd: HWND; callback: t_av_time_change_cb);
procedure set_on_init_popup(h_wnd: HWND; callback: t_av_init_popup_cb);
procedure set_on_menu_select(h_wnd: HWND; callback: t_av_menu_select_cb);
procedure clear_timepicker_props(h_wnd: HWND);

implementation

procedure set_on_time_change(h_wnd: HWND; callback: t_av_time_change_cb);
begin
  SetPropW(h_wnd, AV_PROP_TIME_CHANGE, Pointer(callback));
end;

procedure set_on_init_popup(h_wnd: HWND; callback: t_av_init_popup_cb);
begin
  SetPropW(h_wnd, 'av_on_init_popup', Pointer(callback));
end;

procedure set_on_menu_select(h_wnd: HWND; callback: t_av_menu_select_cb);
begin
  SetPropW(h_wnd, 'av_on_menu_select', Pointer(callback));
end;

procedure clear_timepicker_props(h_wnd: HWND);
begin
  // Zwalniamy właściwość, aby zapobiec wyciekom pamięci GDI/USER
  RemovePropW(h_wnd, AV_PROP_TIME_CHANGE);
end;

end.


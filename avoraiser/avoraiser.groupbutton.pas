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

Module:     avoraiser.groupbutton
Description:
*)
unit avoraiser.groupbutton;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core, avoraiser.utils;

function create_group_box(Parent: HWND; const Caption: string; X, Y, Width, Height: Integer; TextColor: COLORREF): HWND;
//Zmiana tytulu
procedure set_group_box_text(h_wnd: HWND; const text: UnicodeString);
//Pobieranie tekstu z groupbox
function get_group_box_text(h_wnd: HWND): UnicodeString;
//Aktywacja / Dezaktywacja
procedure enable_group_box(h_wnd: HWND; enabled: Boolean);
//Zmiana czcionki w locie
procedure set_group_box_font(h_wnd: HWND; h_font: HFONT; redraw: Boolean);


implementation
function GroupBoxProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
DC: HDC;
PS: TPaintStruct;
R, FrameR, TextR: TRect;
hNewBrush, hBgBrush: HBRUSH;
Caption: array[0..255] of WideChar; // 1. Używamy tablicy Unicode
TxtSize: TSize;
CurrentBgColor: COLORREF;
myhFont, hOldFont: HFONT;             // Do obsługi nowej czcionki
PropVal: HANDLE;
current_draw_color: COLORREF;
begin
 case Msg of
    WM_PAINT:
    begin
     PropVal := GetPropW(hWnd, AV_PROP_GB_BG_COLOR);
      if PropVal <> 0 then
        CurrentBgColor := COLORREF(PropVal) - 1
      else
        CurrentBgColor := $F0F0F0;

      DC := BeginPaint(hWnd, PS);
      try
        GetClientRect(hWnd, R);

        hBgBrush := CreateSolidBrush(CurrentBgColor);
        try
          FillRect(DC, R, hBgBrush);

          myhFont := SendMessageW(hWnd, WM_GETFONT, 0, 0);
          if myhFont = 0 then myhFont := GetStockObject(DEFAULT_GUI_FONT);
          hOldFont := SelectObject(DC, myhFont);

          // === TUTAJ JEST TWÓJ NOWY KOD (Z LEKKIM ULEPSZENIEM) ===
          if IsWindowEnabled(hWnd) then
            current_draw_color := COLORREF(dwRefData)          // Normalny kolor
          else
            current_draw_color := GetSysColor(COLOR_GRAYTEXT); // Systemowy szary

          // Ustawiamy kolor tekstu na wybrany
          SetTextColor(DC, current_draw_color);


          SetBkMode(DC, TRANSPARENT);

          GetWindowTextW(hWnd, Caption, 255);
          GetTextExtentPoint32W(DC, Caption, lstrlenW(Caption), TxtSize);

          // Rysujemy nową ramkę UŻYWAJĄC TEGO SAMEGO KOLORU co tekst!
          hNewBrush := CreateSolidBrush(current_draw_color);
          try
            FrameR := R;
            FrameR.Top := FrameR.Top + (TxtSize.cy div 2);
            FrameRect(DC, FrameR, hNewBrush);
          finally
            DeleteObject(hNewBrush);
          end;

          // Wycina dziurę w ramce pod tekst
          TextR.Left := 10;
          TextR.Top := 0;
          TextR.Right := 10 + TxtSize.cx + 4;
          TextR.Bottom := TxtSize.cy;
          FillRect(DC, TextR, hBgBrush);

          // Rysujemy sam tekst
          TextOutW(DC, 12, 0, Caption, lstrlenW(Caption));

          SelectObject(DC, hOldFont);

        finally
          DeleteObject(hBgBrush);
        end;

      finally
        EndPaint(hWnd, PS);
      end;
      Exit(0);
    end;

    WM_NCDESTROY:
    begin
      // 1. Zwalniamy czcionkę z pamięci (jeśli jakaś była przypisana)
      PropVal := GetPropW(hWnd, AV_PROP_GB_FONT);
      if PropVal <> 0 then
        DeleteObject(HFONT(PropVal));

      // Usuwamy właściwości z okna, by nie wyciekały uchwyty
      RemovePropW(hWnd, PWideChar(AV_PROP_GB_FONT));
      RemovePropW(hWnd, PWideChar(AV_PROP_GB_BG_COLOR));

      // Wyrejestrowujemy subclassing
      RemoveWindowSubclass(hWnd, SUBCLASSPROC(@GroupBoxProc), uIdSubclass);

      // 4. Koniecznie zwalniamy pamięć po naszej szufladce!
     // RemovePropW(hWnd, PWideChar(AV_PROP_GB_BG_COLOR));
     // RemoveWindowSubclass(hWnd, SUBCLASSPROC(@GroupBoxProc), uIdSubclass);
    end;
  end;

  Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
end;


function create_group_box(Parent: HWND; const Caption: string; X, Y, Width, Height: Integer; TextColor: COLORREF): HWND;
var
parent_bg_prop: HANDLE;
bg_color: COLORREF;
begin
   parent_bg_prop := GetPropW(Parent, AV_PROP_BG_COLOR);

  if parent_bg_prop <> 0 then
    bg_color := COLORREF(parent_bg_prop) - 1
  else
    bg_color := GetSysColor(COLOR_BTNFACE);

  Result := CreateWindowExW(
      0,
      PWideChar('BUTTON'),
      PWideChar(UnicodeString(Caption)),
      WS_CHILD or WS_VISIBLE or BS_GROUPBOX,
      X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
    );

    if Result <> 0 then
    begin
      // Zabezpieczenie przed czarnym kolorem (0) w SetPropW
      //SetPropW(Result, PWideChar(AV_PROP_GB_BG_COLOR), HANDLE(BgColor + 1));
      //SendMessageW(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
      //SetWindowSubclass(Result, SUBCLASSPROC(@GroupBoxProc), 0, DWORD_PTR(TextColor));

      SetPropW(Result, PWideChar(AV_PROP_GB_BG_COLOR), HANDLE(bg_color + 1));

      SendMessageW(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
      SetWindowSubclass(Result, SUBCLASSPROC(@GroupBoxProc), 0, DWORD_PTR(TextColor));
    end;
end;

procedure set_group_box_text(h_wnd: HWND; const text: UnicodeString);
begin
  if h_wnd = 0 then Exit;
  SetWindowTextW(h_wnd, PWideChar(text));
  InvalidateRect(h_wnd, nil, True);
end;

function get_group_box_text(h_wnd: HWND): UnicodeString;
var
  len: Integer;
begin
 Result := '';
   if h_wnd = 0 then Exit;

   len := GetWindowTextLengthW(h_wnd);
   if len > 0 then
   begin
     SetLength(Result, len + 1);
     GetWindowTextW(h_wnd, PWideChar(Result), len + 1);
     SetLength(Result, len);
   end;
end;

procedure enable_group_box(h_wnd: HWND; enabled: Boolean);
begin
   if h_wnd = 0 then Exit;

     if enabled then
       EnableWindow(h_wnd, True)
     else
       EnableWindow(h_wnd, False);
     InvalidateRect(h_wnd, nil, True);
end;

procedure set_group_box_font(h_wnd: HWND; h_font: HFONT; redraw: Boolean);
var
  old_font: HANDLE;
begin
  if h_wnd = 0 then Exit;

  //Sprawdzamy, czy okno miało już przypisaną naszą własną czcionkę
  old_font := GetPropW(h_wnd, AV_PROP_GB_FONT);

  //Jeśli mieliśmy już jakąś starą czcionkę i jest inna niż nowa, usuwamy ją z RAM-u
  if (old_font <> 0) and (HFONT(old_font) <> h_font) then
  begin
    DeleteObject(HFONT(old_font));
  end;

  // Zapisujemy nową czcionkę do szufladki
  SetPropW(h_wnd, AV_PROP_GB_FONT, HANDLE(h_font));

  // Informujemy okno o zmianie
  if redraw then
    SendMessageW(h_wnd, WM_SETFONT, WPARAM(h_font), 1)
  else
    SendMessageW(h_wnd, WM_SETFONT, WPARAM(h_font), 0);
end;

end.


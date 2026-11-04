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

Module:     avoraiser.combobox
Description:
*)
unit avoraiser.combobox;

{$mode ObjFPC}{$H+}

interface

uses
 Windows, avoraiser.core,avoraiser.utils;

type
  t_subclass_proc = function(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM; u_id_subclass: UINT_PTR; dw_ref_data: DWORD_PTR): LRESULT; stdcall;

procedure set_dropdown_color(h_combo: HWND; text_color, bg_color: DWORD);
function create_combo_box(h_parent: HWND; x, y, width, height: Integer; id: Integer): HWND;
// Funkcja dodaje element i zwraca jego indeks (np. 0, 1, 2...)
function add_item_combo_box(h_wnd: HWND; const text: UnicodeString): Integer;
// Funkcja zaznacza element o podanym indeksie (np. 0 = pierwszy)
procedure select_combo_box_index(h_wnd: HWND; index: Integer);
// Funkcja czyści całą listę
procedure clear_combo_box(h_wnd: HWND);
// Pobiera indeks wybranego elementu (0, 1, 2...)
function get_combo_box_index(h_wnd: HWND): Integer;
// Pobiera tekst wybranego elementu
function get_combo_box_text(h_wnd: HWND): UnicodeString;
// 4. Pobiera tekst aktualnie wybranego elementu
function get_selected_combo_text(h_wnd: HWND): UnicodeString;


implementation
const
  comctl32 = 'comctl32.dll';

function combo_box_proc(h_wnd: HWND; msg: UINT; w_param: WPARAM; l_param: LPARAM;
  u_id_subclass: UINT_PTR; dw_ref_data: DWORD_PTR): LRESULT; stdcall;
const
  UIS_SET = 1;
  UISF_HIDEFOCUS = 1;
  WM_CHANGEUISTATE = $0127;
var
  dc, mem_dc: HDC;
    ps: TPaintStruct;
    r, arrow_r, text_rect: TRect;
    cl_text: COLORREF;
    my_brush, arrow_brush, brush: HBRUSH;
    my_pen, h_old_pen: HPEN;
    my_bitmap, h_old_bitmap: HBITMAP;
    my_font, h_old_font: HFONT;
    txt_size: TSize;
    text_y, cur_sel, len: Integer;
    tme: TTRACKMOUSEEVENT;
    arrow_pts: array[0..2] of TPoint;
    cx, cy: Integer;
    caption_buf: array[0..255] of WideChar;
    run_track_mouse_event: function(var lpEventTrack: TTRACKMOUSEEVENT): BOOL; stdcall;
begin

   case msg of
    // 1. Blokada systemowego czyszczenia tła
    WM_ERASEBKGND:
    begin
       Result := 1;
       Exit;
    end;

    // 2. Blokada systemowej ramki
    WM_NCPAINT: Exit(0);

    // ------------------ MYSZKA (HOVER) ------------------
    WM_MOUSEMOVE:
    begin
      if GetPropW(h_wnd, AV_PROP_CB_IS_HOVER) = 0 then
      begin
        tme.cbSize := SizeOf(tme);
        tme.dwFlags := TME_LEAVE;
        tme.hwndTrack := h_wnd;
        tme.dwHoverTime := HOVER_DEFAULT;

        Pointer(run_track_mouse_event) := GetProcAddress(GetModuleHandle('user32.dll'), 'TrackMouseEvent');
        if Assigned(run_track_mouse_event) then run_track_mouse_event(tme);

        SetPropW(h_wnd, AV_PROP_CB_IS_HOVER, HANDLE(1));
        InvalidateRect(h_wnd, nil, False);
      end;
    end;

    WM_MOUSELEAVE:
    begin
      RemovePropW(h_wnd, AV_PROP_CB_IS_HOVER);
      InvalidateRect(h_wnd, nil, False);
    end;

    // --- KOLOROWANIE LISTY ---
    WM_CTLCOLORLISTBOX:
    begin
       brush := HBRUSH(PtrUInt(GetPropW(h_wnd, AV_PROP_CB_BRUSH)));

       if brush <> 0 then
       begin
          // Używamy kolorów SPECJALNYCH dla listy
          cl_text := COLORREF(PtrUInt(GetPropW(h_wnd, AV_PROP_CB_TEXT_COLOR)));
          SetBkColor(HDC(w_param), COLORREF(PtrUInt(GetPropW(h_wnd, AV_PROP_CB_BG_COLOR))));
       end
       else
       begin
          // PRIORYTET 2: Jeśli nie ma koloru listy, bierzemy kolor GŁÓWNY
          brush := HBRUSH(PtrUInt(GetPropW(h_wnd, AV_PROP_BRUSH)));
          if brush <> 0 then
          begin
             cl_text := COLORREF(PtrUInt(GetPropW(h_wnd, AV_PROP_TEXT_COLOR)));
             SetBkColor(HDC(w_param), COLORREF(PtrUInt(GetPropW(h_wnd, AV_PROP_BG_COLOR))));
          end;
       end;

       // FINALIZACJA:
       if brush <> 0 then
       begin
          SetTextColor(HDC(w_param), cl_text);
          SetBkMode(HDC(w_param), OPAQUE);
          Result := LRESULT(brush);
          Exit;
       end;
    end;

    WM_PAINT, WM_PRINTCLIENT:
    begin
       if msg = WM_PAINT then
          dc := BeginPaint(h_wnd, ps)
       else
          dc := HDC(w_param);

       if dc = 0 then Exit;

       try
          // Pobieranie właściwości GŁÓWNYCH dla okienka ComboBoxa
          cl_text  := COLORREF(PtrUInt(GetPropW(h_wnd, AV_PROP_TEXT_COLOR)));
          my_brush := HBRUSH(PtrUInt(GetPropW(h_wnd, AV_PROP_BRUSH)));
          my_font  := HFONT(PtrUInt(GetPropA(h_wnd, AV_PROP_FONT)));

          if my_brush = 0 then my_brush := GetStockObject(LTGRAY_BRUSH);
          if my_font = 0 then my_font := GetStockObject(DEFAULT_GUI_FONT);

          GetClientRect(h_wnd, r);

          // --- DOUBLE BUFFERING ---
          mem_dc := CreateCompatibleDC(dc);
          try
             my_bitmap := CreateCompatibleBitmap(dc, r.Right, r.Bottom);
             h_old_bitmap := SelectObject(mem_dc, my_bitmap);
             try
                // A. TŁO
                FillRect(mem_dc, r, my_brush);

                // B. STRZAŁKA
                arrow_r := r;
                arrow_r.Left := r.Right - 24;

                cx := (arrow_r.Left + arrow_r.Right) div 2;
                cy := (arrow_r.Top + arrow_r.Bottom) div 2;

                if SendMessageW(h_wnd, CB_GETDROPPEDSTATE, 0, 0) <> 0 then
                begin
                   // Otwarta (Strzałka w górę)
                   arrow_pts[0].x := cx - 5; arrow_pts[0].y := cy + 2;
                   arrow_pts[1].x := cx + 5; arrow_pts[1].y := cy + 2;
                   arrow_pts[2].x := cx;     arrow_pts[2].y := cy - 3;
                end
                else
                begin
                   // Zamknięta (Strzałka w dół)
                   arrow_pts[0].x := cx - 5; arrow_pts[0].y := cy - 2;
                   arrow_pts[1].x := cx + 5; arrow_pts[1].y := cy - 2;
                   arrow_pts[2].x := cx;     arrow_pts[2].y := cy + 3;
                end;

                arrow_brush := CreateSolidBrush(cl_text);
                my_pen := CreatePen(PS_SOLID, 1, cl_text);
                h_old_pen := SelectObject(mem_dc, my_pen);
                SelectObject(mem_dc, arrow_brush);

                Polygon(mem_dc, arrow_pts, 3);

                SelectObject(mem_dc, h_old_pen);
                DeleteObject(my_pen);
                DeleteObject(arrow_brush);

                // C. TEKST
                cur_sel := SendMessageW(h_wnd, CB_GETCURSEL, 0, 0);
                if cur_sel <> CB_ERR then
                begin
                   FillChar(caption_buf, SizeOf(caption_buf), 0);
                   SendMessageW(h_wnd, CB_GETLBTEXT, cur_sel, LPARAM(@caption_buf[0]));
                   len := lstrlenW(@caption_buf[0]);

                   if len > 0 then
                   begin
                      h_old_font := SelectObject(mem_dc, my_font);
                      SetTextColor(mem_dc, cl_text);
                      SetBkMode(mem_dc, TRANSPARENT);

                      GetTextExtentPoint32W(mem_dc, @caption_buf[0], len, txt_size);
                      text_y := (r.Bottom - txt_size.cy) div 2;

                      text_rect := r;
                      text_rect.Left := 6;
                      text_rect.Right := arrow_r.Left;
                      text_rect.Top := text_y;
                      text_rect.Bottom := text_y + txt_size.cy;

                      ExtTextOutW(mem_dc, 6, text_y, ETO_CLIPPED, @text_rect, @caption_buf[0], len, nil);
                      SelectObject(mem_dc, h_old_font);
                   end;
                end;

                // Przerzucamy bufor na ekran
                BitBlt(dc, 0, 0, r.Right, r.Bottom, mem_dc, 0, 0, SRCCOPY);

             finally
                SelectObject(mem_dc, h_old_bitmap);
                DeleteObject(my_bitmap);
             end;
          finally
             DeleteDC(mem_dc);
          end;

       finally
          if msg = WM_PAINT then
             EndPaint(h_wnd, ps);
       end;

       Result := 0;
       Exit;
    end;

    // ANTY-MIGANIE I ANTY-NIEBIESKI FOCUS
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK,
    WM_KEYDOWN, WM_KEYUP, WM_CHAR, WM_MOUSEWHEEL,
    WM_SIZE:
    begin
      SendMessageW(h_wnd, WM_SETREDRAW, 0, 0);
      try
         Result := DefSubclassProc(h_wnd, msg, w_param, l_param);
      finally
         ValidateRect(h_wnd, nil);
         SendMessageW(h_wnd, WM_SETREDRAW, 1, 0);
      end;
      RedrawWindow(h_wnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE or RDW_ALLCHILDREN);
      Exit;
    end;

    WM_SETFOCUS, WM_KILLFOCUS:
    begin
       if msg = WM_SETFOCUS then
         SendMessageW(h_wnd, WM_CHANGEUISTATE, MakeLong(UIS_SET, UISF_HIDEFOCUS), 0);

       SendMessageW(h_wnd, WM_SETREDRAW, 0, 0);
       try
          Result := DefSubclassProc(h_wnd, msg, w_param, l_param);
       finally
          SendMessageW(h_wnd, WM_SETREDRAW, 1, 0);
       end;
       RedrawWindow(h_wnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);
       Exit;
    end;

    CB_SETCURSEL:
    begin
       Result := DefSubclassProc(h_wnd, msg, w_param, l_param);
       RedrawWindow(h_wnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);
       Exit;
    end;

    // SPRZĄTANIE
    WM_NCDESTROY:
    begin
       my_font := HFONT(PtrUInt(GetPropW(h_wnd, AV_PROP_FONT_CB)));
       if my_font <> 0 then DeleteObject(my_font);
      // UWAGA: Głównego pędzla u dołu nie usuwamy stąd na stałe, jeśli współdzielisz go z np. Formularzem,
      // ale jeśli tworzysz go osobno dla ComboBoxa, to usuwamy:
      my_brush := HBRUSH(PtrUInt(GetPropW(h_wnd, AV_PROP_BRUSH)));
      if my_brush <> 0 then DeleteObject(my_brush);

      my_brush := HBRUSH(PtrUInt(GetPropW(h_wnd, AV_PROP_CB_BRUSH)));
      if my_brush <> 0 then DeleteObject(my_brush);

      RemovePropW(h_wnd, AV_PROP_FONT_CB);
      RemovePropW(h_wnd, AV_PROP_TEXT_COLOR);
      RemovePropW(h_wnd, AV_PROP_BG_COLOR);
      RemovePropW(h_wnd, AV_PROP_BRUSH);

      RemovePropW(h_wnd, AV_PROP_CB_BRUSH);
      RemovePropW(h_wnd, AV_PROP_CB_TEXT_COLOR);
      RemovePropW(h_wnd, AV_PROP_CB_BG_COLOR);

      RemovePropW(h_wnd, AV_PROP_CB_IS_HOVER);

      RemoveWindowSubclass(h_wnd, TSubclassProc(@combo_box_proc), u_id_subclass);
    end;
  end;
  Result := DefSubclassProc(h_wnd, msg, w_param, l_param);
end;

procedure set_dropdown_color(h_combo: HWND; text_color, bg_color: DWORD);
var
  new_brush, old_brush: HBRUSH;
begin
 if h_combo = 0 then Exit;

  //Tworzymy nowy pędzel dla tła
  new_brush := CreateSolidBrush(bg_color);

  //Sprzątamy stary pędzel (Pobieramy jako HANDLE i rzutujemy na HBRUSH)
  old_brush := HBRUSH(GetPropW(h_combo, AV_PROP_CB_BRUSH));

  if old_brush <> 0 then
  begin
    DeleteObject(old_brush);
  end;

  //Zapisujemy Pędzel
  SetPropW(h_combo, AV_PROP_CB_BRUSH, THandle(new_brush));

  //Zapisujemy Kolory (Jako liczby)
  SetPropW(h_combo, AV_PROP_CB_TEXT_COLOR, THandle(PtrUInt(text_color)));
  SetPropW(h_combo, AV_PROP_CB_BG_COLOR,   THandle(PtrUInt(bg_color)));
end;

function create_combo_box(h_parent: HWND; x, y, width, height: Integer; id: Integer): HWND;
var
  style: LONG_PTR;
  h_font: HFONT;
begin
  // Używamy PWideChar dla bezpieczeństwa przy CreateWindowExW
  Result := CreateWindowExW(
    0,
    PWideChar('COMBOBOX'),
    nil,
    WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP or CBS_DROPDOWNLIST or CBS_HASSTRINGS,
    x, y, width, height, // Używamy przekazanego parametru height zamiast sztywnego 400
    h_parent,
    HMENU(PtrUInt(id)),
    GetModuleHandle(nil),
    nil
  );

  if Result <> 0 then
  begin
    style := GetWindowLongPtr(Result, GWL_EXSTYLE);
    SetWindowLongPtr(Result, GWL_EXSTYLE, style and not WS_EX_CLIENTEDGE);
    SetWindowPos(Result, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);

    h_font := create_ui_font(PWideChar('Segoe UI'), 9);
    //Ustawiamy czcionkę w samej kontrolce WinAPI
    SendMessageW(Result, WM_SETFONT, h_font, 1);
    SetPropW(Result, AV_PROP_FONT_CB, THandle(h_font));

    //Podpinamy naszą własną procedurę rysującą
    SetWindowSubclass(Result, TSubclassProc(@combo_box_proc), 0, 0);

    //Ustawiamy bezpieczne kolory startowe
    set_dropdown_color(Result,$FFFFFF, $2D2D2D);
    set_component_color(Result, $000000, $2D2D2D);    //$000000
    //set_component_color(Result, $FFFFFF, $2D2D2D);
  end;
end;

function add_item_combo_box(h_wnd: HWND; const text: UnicodeString): Integer;
const
  CB_ERR = -1;
begin
// Zabezpieczenie przed błędem
  if h_wnd = 0 then Exit(CB_ERR);
  // Zwraca indeks dodanego elementu (0, 1, 2...)
  Result := SendMessageW(h_wnd, CB_ADDSTRING, 0, LPARAM(PWideChar(text)));
end;

procedure select_combo_box_index(h_wnd: HWND; index: Integer);
const
  CB_SETCURSEL = $014E;
begin
  if h_wnd = 0 then Exit;
  SendMessageW(h_wnd, CB_SETCURSEL, WPARAM(index), 0);
end;

procedure clear_combo_box(h_wnd: HWND);
const
  CB_RESETCONTENT = $014B;
begin
  if h_wnd = 0 then Exit;
    SendMessageW(h_wnd, CB_RESETCONTENT, 0, 0);
end;

function get_combo_box_index(h_wnd: HWND): Integer;
const
  CB_GETCURSEL = $0147;
  CB_ERR = -1;
begin
  if h_wnd = 0 then Exit(CB_ERR);
  Result := SendMessageW(h_wnd, CB_GETCURSEL, 0, 0);
end;

function get_combo_box_text(h_wnd: HWND): UnicodeString;
const
  CB_GETCURSEL    = $0147;
  CB_GETLBTEXTLEN = $0149;
  CB_GETLBTEXT    = $0148;
  CB_ERR          = -1;
var
idx, len: Integer;
begin
  Result := '';
  if h_wnd = 0 then Exit;

  //Pobieramy indeks wybranego elementu
  idx := SendMessageW(h_wnd, CB_GETCURSEL, 0, 0);

  if idx <> CB_ERR then
  begin
    //Pobieramy długość tekstu pod tym indeksem
    len := SendMessageW(h_wnd, CB_GETLBTEXTLEN, idx, 0);

    if len > 0 then
    begin
      //Rezerwujemy pamięć BEZPOŚREDNIO w Result
      SetLength(Result, len);

      //Pobieramy tekst prosto do wewnętrznego bufora Result
      SendMessageW(h_wnd, CB_GETLBTEXT, idx, LPARAM(PWideChar(Result)));
    end;
  end;
end;

function get_selected_combo_text(h_wnd: HWND): UnicodeString;
const
  CB_GETCURSEL    = $0147;
  CB_GETLBTEXTLEN = $0149;
  CB_GETLBTEXT    = $0148;
  CB_ERR          = -1;
var
  idx, len: Integer;
begin
  Result := '';
  if h_wnd = 0 then Exit;

  idx := SendMessageW(h_wnd, CB_GETCURSEL, 0, 0);

  if idx <> CB_ERR then
  begin
    len := SendMessageW(h_wnd, CB_GETLBTEXTLEN, idx, 0);

    if len > 0 then
    begin
      // Zamiast osobnej tablicy, rezerwujemy miejsce od razu w wyniku
      SetLength(Result, len);
      // Ładujemy tekst z WinAPI prosto do zmiennej Result
      SendMessageW(h_wnd, CB_GETLBTEXT, idx, LPARAM(PWideChar(Result)));
    end;
  end;
end;

end.


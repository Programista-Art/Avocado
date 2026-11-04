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

Module:     avoraiser.spinedit
Description:
*)

unit avoraiser.spinedit;
{$MODE objfpc}
{$H+}
{$CODEPAGE UTF8}

interface

uses
  Windows,
  avoraiser.core,
  avoraiser.utils;
//type
//  TSubclassProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM; uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;

const
  CLEARTYPE_QUALITY = 5;

function create_spin_edit(Parent: HWND; X, Y, Width, Height: Integer): HWND;
//pobiera wartosc liczbowa
function get_spin_value(Spin: HWND): Integer;
//Zmiana koloru strzalek w SpinEdit
procedure set_spin_arrow_color(hSpin: HWND; Color: DWORD);
// Zmienia kolor tła pod strzałkami (Panel boczny)
procedure set_spin_background_color(hSpin: HWND; Color: DWORD);
procedure update_spin_layout(hWnd: HWND; btn_width: Integer);

implementation

procedure draw_spin_buttons(hWnd: HWND; TargetDC: HDC; BtnWidth: Integer);
var
r, btn_r: TRect;
mid_y, center_x, down_y: Integer;
arrow_col, btn_bk_col, border_col, prop_val: DWORD;
brush, pen, old_brush, old_pen: HGDIOBJ;
points: array[0..2] of TPoint;
begin
  FillChar(r, SizeOf(r), 0);
 // 1. Obliczamy wymiary na podstawie okna
 GetClientRect(hWnd, r);
  btn_r := r;
   btn_r.Left := r.Right - BtnWidth;

   // Środek w pionie i poziomie
   mid_y := (btn_r.Bottom - btn_r.Top) div 2;
   center_x := btn_r.Left + (BtnWidth div 2);

   // 2. Pobieramy kolory (Naprawa obsługi koloru czarnego)
   // Używamy logiki: Wartość = Kolor + 1
   prop_val := DWORD(GetProp(hWnd, AV_SPIN_ARROW_COLOR));
   if prop_val <> 0 then arrow_col := prop_val - 1 else arrow_col := $404040; // Ciemnoszary

   prop_val := DWORD(GetProp(hWnd, AV_SPIN_BUTTON_BG));
   if prop_val <> 0 then btn_bk_col := prop_val - 1 else btn_bk_col := $F0F0F0; // Jasnoszary

   border_col := $A0A0A0; // Kolor ramki

   // 3. Rysujemy TŁO PANELU
   brush := CreateSolidBrush(btn_bk_col);
   FillRect(TargetDC, btn_r, HBRUSH(brush));
   DeleteObject(brush);

   // 4. Rysujemy LINIE (Podział przycisków)
   pen := CreatePen(PS_SOLID, 1, border_col);
   old_pen := SelectObject(TargetDC, pen);

   // Pionowa (oddzielająca tekst od przycisków)
   MoveToEx(TargetDC, btn_r.Left, btn_r.Top, nil);
   LineTo(TargetDC, btn_r.Left, btn_r.Bottom);

   // Pozioma (oddzielająca przycisk góra/dół)
   MoveToEx(TargetDC, btn_r.Left, mid_y, nil);
   LineTo(TargetDC, btn_r.Right, mid_y);

   SelectObject(TargetDC, old_pen);
   DeleteObject(pen);

   // 5. Rysujemy STRZAŁKI (Trójkąty)
   brush := CreateSolidBrush(arrow_col);
   pen := GetStockObject(NULL_PEN); // Bez obrysu, tylko wypełnienie

   old_brush := SelectObject(TargetDC, brush);
   old_pen := SelectObject(TargetDC, pen);

   // Strzałka Góra
   points[0].X := center_x;     points[0].Y := (mid_y div 2) - 2;
   points[1].X := center_x - 4; points[1].Y := (mid_y div 2) + 2;
   points[2].X := center_x + 4; points[2].Y := (mid_y div 2) + 2;
   Polygon(TargetDC, points, 3);

   // Strzałka Dół
   down_y := mid_y + (mid_y div 2);
   points[0].X := center_x;     points[0].Y := down_y + 3;
   points[1].X := center_x - 4; points[1].Y := down_y - 1;
   points[2].X := center_x + 4; points[2].Y := down_y - 1;
   Polygon(TargetDC, points, 3);

   // Sprzątanie
   SelectObject(TargetDC, old_brush);
   SelectObject(TargetDC, old_pen);
   DeleteObject(brush);
   // NULL_PEN nie trzeba usuwać, bo to obiekt systemowy (StockObject)
end;

function spin_edit_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
  ps: TPaintStruct;
  dc, mem_dc: HDC;
  mem_bitmap, old_bitmap: HBITMAP;
  r: TRect;
  btn_width, mid_y,font_height: Integer;
  pt: TPoint;
  val_int, code, len: Integer;
  s_val: UnicodeString; // Używamy UnicodeString
  s_buffer: array of WideChar; // Bufor na tekst
  new_font, old_font_handle: HFONT;
begin
  btn_width := 24; // Szerokość przycisków

  case Msg of
    // 1. OCHRONA MARGINESU (Tekst nie włazi pod przyciski)
    WM_SIZE:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
      update_spin_layout(hWnd, btn_width);
      GetClientRect(hWnd, r);
      if (r.Bottom - r.Top) > 0 then
      begin
        // B. Obliczamy wysokość czcionki (ok. 65-70% wysokości pola wygląda najlepiej)
        font_height := Round((r.Bottom - r.Top) * 0.70);

        // C. Tworzymy nową czcionkę
        new_font := CreateFontW(
          -font_height,             // Wysokość (minus = piksele)
          0, 0, 0,                  // Szerokość, Kąty
          FW_NORMAL,                // Grubość
          0, 0, 0,                  // Italic, Underline, Strike
          DEFAULT_CHARSET,
          OUT_DEFAULT_PRECIS,
          CLIP_DEFAULT_PRECIS,
          CLEARTYPE_QUALITY,        // Ładne wygładzanie
          DEFAULT_PITCH or FF_DONTCARE,
          'Segoe UI'                // Nowoczesna czcionka
        );

        // D. Sprzątamy starą czcionkę (jeśli my ją stworzyliśmy)
        // Pobieramy uchwyt starej czcionki z właściwości okna
        old_font_handle := HFONT(GetProp(hWnd, AV_SPIN_AUTO_FONT));
        if old_font_handle <> 0 then DeleteObject(old_font_handle);

        // E. Zapisujemy nową i ustawiamy
        SetProp(hWnd, AV_SPIN_AUTO_FONT, THandle(new_font));

        // Ważne: False na końcu, żeby nie wymuszać przerysowania natychmiast (zapętlenie)
        SendMessageW(hWnd, WM_SETFONT, PtrUInt(new_font), 0);


        SendMessageW(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, MakeLParam(0, btn_width + 2));
       //SendMessageW(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, MakeLParam(0, btn_width));
      Exit;
    end;
    end;

    // Dodatkowe zabezpieczenie marginesu przy ręcznej zmianie czcionki
    WM_SETFONT:
    begin
       Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
       //SendMessageW(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, MakeLParam(0, btn_width + 2));
       SendMessageW(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, MakeLParam(0, btn_width + 4));
       Exit;
    end;

    WM_LBUTTONDOWN:
    begin
      GetClientRect(hWnd, r);
      pt.X := LoWord(LParam);
      pt.Y := HiWord(LParam);

      // Sprawdzamy, czy kliknięto w obszar przycisków
      if pt.X >= (r.Right - btn_width) then
      begin
        // 1. DIAGNOSTYKA: Dźwięk potwierdza, że kliknięcie "weszło"
        MessageBeep(0);

        // 2. Pobieramy tekst bezpiecznie
        len := GetWindowTextLengthW(hWnd);
        SetLength(s_buffer, len + 1);
        if len > 0 then
          GetWindowTextW(hWnd, @s_buffer[0], len + 1);

        SetString(s_val, PWideChar(@s_buffer[0]), len);

        // 3. Prosty TRIM (Usuwanie spacji - dla bezpieczeństwa Val)
        // Czasem ES_RIGHT dodaje wizualne spacje, a Val ich nie lubi
        while (Length(s_val) > 0) and (s_val[1] <= ' ') do Delete(s_val, 1, 1);
        while (Length(s_val) > 0) and (s_val[Length(s_val)] <= ' ') do SetLength(s_val, Length(s_val) - 1);

        // 4. Konwersja (Bezpieczna)
        Val(s_val, val_int, code);
        if code <> 0 then val_int := 0; // Jak błąd, to startujemy od 0

        // 5. Zmiana wartości
        mid_y := (r.Bottom - r.Top) div 2;
        if pt.Y < mid_y then
          Inc(val_int)  // Góra (+)
        else
          Dec(val_int); // Dół (-)

        // 6. Zapisanie wyniku (Przez ShortString dla pewności)
        Str(val_int, s_val);
        SetWindowTextW(hWnd, PWideChar(s_val));

        // 7. Focus i odświeżenie
        SetFocus(hWnd);
        SendMessageW(hWnd, EM_SETSEL, 0, -1);

        dc := GetDC(hWnd);
        // Ograniczamy rysowanie, żeby nie zamazać tekstu
        IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
        draw_spin_buttons(hWnd, dc, btn_width);
        ReleaseDC(hWnd, dc);

        Result := 0;
        Exit;
      end
      else
      begin
        // 1. Niech Edit zrobi swoje (ustawi kursor, zamaluje tło)
        Result := DefSubclassProc(hWnd, Msg, WParam, LParam);

        // 2. A my NATYCHMIAST rysujemy przyciski z powrotem na wierzchu
        dc := GetDC(hWnd);
        IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
        draw_spin_buttons(hWnd, dc, btn_width);
        ReleaseDC(hWnd, dc);

        Exit;
      end;
    end;

     // 1. BLOKADA MALOWANIA TŁA PRZEZ SYSTEM
    WM_CTLCOLOREDIT:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
      GetClientRect(hWnd, r);
      ExcludeClipRect(HDC(WParam), r.Right - btn_width, r.Top, r.Right, r.Bottom);
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      Result := 1;
      Exit;
    end;

    WM_CHAR, WM_KEYUP:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);

      // Po każdym znaku odświeżamy tylko przyciski
      dc := GetDC(hWnd);
      try
        GetClientRect(hWnd, r);
        IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
        draw_spin_buttons(hWnd, dc, btn_width);
      finally
        ReleaseDC(hWnd, dc);
      end;
      Exit;
    end;


    // 2. NAPRAWA PODCZAS RUCHU MYSZĄ
    WM_MOUSEMOVE:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);

      // Jeśli lewy przycisk jest wciśnięty (zaznaczanie)
      if (WParam and MK_LBUTTON <> 0) then
      begin
        dc := GetDC(hWnd);
        try
          GetClientRect(hWnd, r);
          // Rysujemy przyciski "na sztywno"
          draw_spin_buttons(hWnd, dc, btn_width);
        finally
          ReleaseDC(hWnd, dc);
        end;
      end;
      Exit;
    end;


    // 3. NAPRAWA PODWÓJNEGO KLIKNIĘCIA
    WM_LBUTTONDBLCLK:
    begin
      GetClientRect(hWnd, r);
      if LoWord(LParam) >= (r.Right - btn_width) then
      begin
        // Traktuj double-click na przycisku jak zwykły click (szybkie przewijanie)
        SendMessageW(hWnd, WM_LBUTTONDOWN, WParam, LParam);
        Result := 0;

        // Przerysuj przyciski "na wierzchu"
        dc := GetDC(hWnd);
        try
          GetClientRect(hWnd, r);
          IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
          draw_spin_buttons(hWnd, dc, btn_width);
        finally
          ReleaseDC(hWnd, dc);
        end;

        Exit;
      end
      else
      begin
        Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
        dc := GetDC(hWnd);
        try
           // Ograniczamy rysowanie tylko do paska przycisków
           IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
           draw_spin_buttons(hWnd, dc, btn_width);
        finally
           ReleaseDC(hWnd, dc);
        end;
        Exit;
      end;
    end;

    // 4. ODŚWIEŻANIE PRZYCISKÓW (Przy pisaniu, focusie itp.)
    WM_LBUTTONUP, WM_SETFOCUS, WM_KILLFOCUS, WM_KEYDOWN:// WM_KEYUP:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);

      if (Msg = WM_MOUSEMOVE) and ((WParam and MK_LBUTTON) = 0) then
      Exit;

      dc := GetDC(hWnd);
      try
        GetClientRect(hWnd, r);
        IntersectClipRect(dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
        draw_spin_buttons(hWnd, dc, btn_width);
      finally
        ReleaseDC(hWnd, dc);
      end;

      Exit;
    end;





    // 5. GŁÓWNE RYSOWANIE (Podwójne buforowanie)
    WM_PAINT:
    begin
      dc := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, r);
        mem_dc := CreateCompatibleDC(dc);
        mem_bitmap := CreateCompatibleBitmap(dc, r.Right, r.Bottom);
        old_bitmap := SelectObject(mem_dc, mem_bitmap);

        try
          // A. Rysujemy Edit bez obszaru przycisków
          ExcludeClipRect(mem_dc, r.Right - btn_width, r.Top, r.Right, r.Bottom);
          //SendMessageW(hWnd, WM_PRINTCLIENT, WPARAM(mem_dc), PRF_CLIENT or PRF_CHECKVISIBLE or PRF_ERASEBKGND);
           SendMessage(hWnd, WM_PRINTCLIENT, PtrUInt(mem_dc), PRF_CLIENT or PRF_CHECKVISIBLE or PRF_ERASEBKGND);
          // B. Rysujemy przyciski
          SelectClipRgn(mem_dc, 0);
          draw_spin_buttons(hWnd, mem_dc, btn_width);

          // C. Kopiujemy na ekran
          BitBlt(dc, 0, 0, r.Right, r.Bottom, mem_dc, 0, 0, SRCCOPY);
        finally
          SelectObject(mem_dc, old_bitmap);
          DeleteObject(mem_bitmap);
          DeleteDC(mem_dc);
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Exit(0);
    end;



    // 6. KURSOR
    WM_SETCURSOR:
    begin
      GetCursorPos(pt);
      ScreenToClient(hWnd, pt);
      GetClientRect(hWnd, r);
      if pt.X >= (r.Right - btn_width) then
      begin
        SetCursor(LoadCursor(0, IDC_HAND));
        Result := 1;
        Exit;
      end;
    end;

    // 7. SPRZĄTANIE (Używamy stałych z CORE)
    WM_NCDESTROY:
    begin
      RemoveWindowSubclass(hWnd, SUBCLASSPROC(@spin_edit_proc), uIdSubclass);

      // Sprzątamy automatyczną czcionkę
      old_font_handle := HFONT(GetProp(hWnd, AV_SPIN_AUTO_FONT));
      if old_font_handle <> 0 then DeleteObject(old_font_handle);
      RemoveProp(hWnd, AV_SPIN_AUTO_FONT);

      RemoveProp(hWnd, AV_SPIN_ARROW_COLOR);
      RemoveProp(hWnd, AV_SPIN_BUTTON_BG);
      RemoveProp(hWnd, AV_CTX_RADIUS);
    end;
  end;

  Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
end;

function create_spin_edit(Parent: HWND; X, Y, Width, Height: Integer): HWND;
begin
  Result := CreateWindowEx(
    0, 'EDIT', '0',
    WS_CHILD or
    WS_VISIBLE or
    WS_BORDER or
    ES_RIGHT or
    ES_NUMBER,
    X, Y, Width, Height,
    Parent, 0, GetModuleHandle(nil), nil);

  // Ustawienie czcionki
  SetWindowSubclass(Result, SUBCLASSPROC(@spin_edit_proc), 1, 0);

  if Result <> 0 then
  begin
    SetWindowSubclass(Result, SUBCLASSPROC(@spin_edit_proc), 101, 0);
    // Ustawienie promienia ramki (dla AvocadoEditProc)
    SetProp(Result, AV_CTX_RADIUS, 10);
    update_spin_layout(Result, 24);
  end;
end;

function get_spin_value(Spin: HWND): Integer;
begin
   Result := get_window_int(Spin);
end;

procedure set_spin_arrow_color(hSpin: HWND; Color: DWORD);
begin
  SetProp(hSpin,  AV_SPIN_ARROW_COLOR, THandle(Color +1));
  InvalidateRect(hSpin, nil, True);
end;

procedure set_spin_background_color(hSpin: HWND; Color: DWORD);
begin
  SetProp(hSpin, AV_SPIN_BUTTON_BG, THandle(Color +1));
  InvalidateRect(hSpin, nil, True);
end;

procedure update_spin_layout(hWnd: HWND; btn_width: Integer);
var
  r: TRect;
  font_height: Integer;
  new_font, old_font_handle: HFONT;
begin
  GetClientRect(hWnd, r);
    if (r.Bottom - r.Top) <= 0 then Exit;

    // 1. OBLICZANIE CZCIONKI (70% wysokości okna)
    font_height := Round((r.Bottom - r.Top) * 0.70);

    new_font := CreateFontW(
      -font_height,
      0, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      5,
      DEFAULT_PITCH or FF_DONTCARE, 'Segoe UI'
    );

    // Usuwanie starej czcionki (żeby nie było wycieków pamięci)
    old_font_handle := HFONT(GetProp(hWnd, AV_SPIN_AUTO_FONT));
    if old_font_handle <> 0 then DeleteObject(old_font_handle);

    SetProp(hWnd, AV_SPIN_AUTO_FONT, THandle(new_font));

    // Ustawiamy czcionkę (False = bez przerysowania, bo zaraz zrobimy to marginesem)
    SendMessageW(hWnd, WM_SETFONT, PtrUInt(new_font), 0);

    SendMessageW(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, MakeLParam(0, btn_width + 4));
end;


end.


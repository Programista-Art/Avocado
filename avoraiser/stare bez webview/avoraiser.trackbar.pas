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

Module:     avoraiser.trackbar
Description:
*)
unit avoraiser.trackbar;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,avoraiser.core,avoraiser.utils;

const
  CLASS_NAME_TRACKBAR = 'AvocadoTrackBar';

function create_trackbar(Parent: HWND; X, Y, Width, Height: Integer): HWND;
// Ustawienie wartości
procedure set_trackbar_pos(hTrack: HWND; Pos: Integer);
// Pobranie wartości
function get_trackbar_pos(hTrack: HWND): Integer;
// Ustawienie zakresu (np. 0-255 dla jasności)
procedure set_trackbar_range(hTrack: HWND; Min, Max: Integer);
// Ustawienie kolorów
procedure set_trackbar_colors(hTrack: HWND; clTrack, clProgress, clThumb: DWORD);
procedure set_trackbar_step(hTrack: HWND; Step: Integer);
procedure set_trackbar_show_value(hTrack: HWND; Show: Boolean);
procedure avocado_trackbar_paint(hWnd: HWND);

implementation
procedure avocado_trackbar_paint(hWnd: HWND);
var
  ps: TPaintStruct;
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  R, TrR, TxtR: TRect;
  Brush: HBRUSH;
  Pen: HPEN;
  OldFont: HGDIOBJ;

  // Zmienne logiczne
  Margin, ThumbRadius, TrackH, CY: Integer;
  Min, Max, Pos, ThumbX: Integer;
  TrackCol, ProgressCol, ThumbCol, ParentCol: DWORD;
  Percent: Double;
  ValStr: string;
  TextSize: TSize;
begin
  DC := BeginPaint(hWnd, ps);
  try
    SetBkMode(DC, TRANSPARENT);

    // Konfiguracja wymiarów
    Margin := 13;
    if GetProp(hWnd, 'IsHover') = 1 then
      ThumbRadius := 8
    else
      ThumbRadius := 7;

    GetClientRect(hWnd, R);

    // podwójne buforowanie (double buffering) --
    MemDC := CreateCompatibleDC(DC);
    MemBitmap := CreateCompatibleBitmap(DC, R.Right, R.Bottom);
    OldBitmap := SelectObject(MemDC, MemBitmap);

    try

      //tło(Symulacja przezroczystości)
      // Pobieramy kolor tła RODZICA używając systemu Avocado.
      // Jeśli rodzic nie ma ustawionego koloru, bierzemy systemowy.
      ParentCol := get_prop_color(GetParent(hWnd), AV_PROP_BG_COLOR, GetSysColor(COLOR_BTNFACE));

      // Wypełniamy CAŁY bufor kolorem rodzica.
      // Dzięki temu Trackbar wygląda na przezroczysty.
      Brush := CreateSolidBrush(ParentCol);
      FillRect(MemDC, R, Brush);
      DeleteObject(Brush);

      // pobieranie danych

      Min := Integer(GetProp(hWnd, AV_TRACK_MIN));
      Max := Integer(GetProp(hWnd, AV_TRACK_MAX));
      Pos := Integer(GetProp(hWnd, AV_TRACK_POS));
      if Max <= Min then Max := Min + 1;

      // Kolory elementów (z fallbackiem)
      if GetProp(hWnd, 'AvTrColTr') <> 0 then TrackCol := DWORD(GetProp(hWnd, 'AvTrColTr')) else TrackCol := $505050; // Ciemnoszary pasek
      if GetProp(hWnd, 'AvTrColProg') <> 0 then ProgressCol := DWORD(GetProp(hWnd, 'AvTrColProg')) else ProgressCol := $404040;
      if GetProp(hWnd, 'AvTrColTh') <> 0 then ThumbCol := DWORD(GetProp(hWnd, 'AvTrColTh')) else ThumbCol := $000000;


      //rysowanie paska (track - tło suwaka)

      TrackH := 4;
      CY := (R.Bottom - R.Top) div 2;

      // Obliczamy prostokąt paska
      TrR.Left := Margin;
      TrR.Right := R.Right - Margin;
      TrR.Top := CY - (TrackH div 2);
      TrR.Bottom := CY + (TrackH div 2);

      // Malujemy pasek kolorem TRACK (a nie ParentCol!)
      Brush := CreateSolidBrush(TrackCol);
      FillRect(MemDC, TrR, Brush);
      DeleteObject(Brush);


      //rysowanie postępu (lewa strona)

      Percent := (Pos - Min) / (Max - Min);
      ThumbX := Margin + Round(Percent * (R.Right - R.Left - 2 * Margin));

      TrR.Right := ThumbX; // Skracamy prostokąt do pozycji suwaka
      Brush := CreateSolidBrush(ProgressCol);
      FillRect(MemDC, TrR, Brush);
      DeleteObject(Brush);


      //rysowanie suwaka (thumb - kółko)

      SelectObject(MemDC, GetStockObject(NULL_PEN)); // Bez obrysu systemowego
      Brush := CreateSolidBrush(ThumbCol);
      SelectObject(MemDC, Brush);
      Ellipse(MemDC, ThumbX - ThumbRadius, CY - ThumbRadius, ThumbX + ThumbRadius, CY + ThumbRadius);
      DeleteObject(Brush);

      // Opcjonalna ramka suwaka (Dla estetyki)
      Pen := CreatePen(PS_SOLID, 1, $808080);
      SelectObject(MemDC, GetStockObject(NULL_BRUSH)); // Przezroczysty środek
      SelectObject(MemDC, Pen);
      Ellipse(MemDC, ThumbX - ThumbRadius, CY - ThumbRadius, ThumbX + ThumbRadius, CY + ThumbRadius);
      DeleteObject(Pen);


      // rysowanie wartości (tooltip)
      if (GetCapture = hWnd) and (GetProp(hWnd, 'AvTrShVal') = 1) then
      begin
         Str(Pos, ValStr);
         ValStr := ValStr + '%';

         OldFont := SelectObject(MemDC, GetStockObject(DEFAULT_GUI_FONT));
         try
           SetBkMode(MemDC, TRANSPARENT);
           SetTextColor(MemDC, ThumbCol);

           GetTextExtentPoint32W(MemDC, PWideChar(UnicodeString(ValStr)), Length(ValStr), TextSize);

           // Centrowanie nad suwakiem
           TxtR.Left := ThumbX - (TextSize.cx div 2);
           TxtR.Top := CY - ThumbRadius - TextSize.cy - 5;

           // Zabezpieczenie krawędzi
           if TxtR.Left < 0 then TxtR.Left := 0;
           if (TxtR.Left + TextSize.cx) > R.Right then TxtR.Left := R.Right - TextSize.cx;

           TextOutW(MemDC, TxtR.Left, TxtR.Top, PWideChar(UnicodeString(ValStr)), Length(ValStr));
         finally
           SelectObject(MemDC, OldFont);
         end;
      end;


      BitBlt(DC, 0, 0, R.Right, R.Bottom, MemDC, 0, 0, SRCCOPY);

    finally
      // Sprzątanie Double Buffering
      SelectObject(MemDC, OldBitmap);
      DeleteObject(MemBitmap);
      DeleteDC(MemDC);
    end;

  finally
    EndPaint(hWnd, ps);
  end;
end;

function AvocadoTrackBarProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
ps: TPaintStruct;
DC, MemDC: HDC; // MemDC do podwójnego buforowania
MemBitmap, OldBitmap: HBITMAP;
R, TrR: TRect;
Min, Max, Pos: Integer;
ThumbX, ThumbRadius, Margin: Integer;
Brush, Pen: HGDIOBJ;
TrackCol, ProgressCol, ThumbCol: DWORD;
Percent: Double;
MouseX: Integer;
ParentBrush: HBRUSH;
TrackH: Integer;
CY: Integer;
WorkWidth: Integer;
Step: Integer;
RawPos: Integer;
ValStr: UnicodeString;
TextSize: TSize;
TxtR: TRect;
OldFont: HGDIOBJ;
tme: TTRACKMOUSEEVENT;
begin
 ThumbRadius := 8;
  //Margin := 10;
  Margin := 13;

  case Msg of
    // 1. ZATRZYMUJEMY SYSTEMOWE CZYSZCZENIE (Zero migotania)
    WM_ERASEBKGND:
    begin
      Result := 1;
      Exit;
    end;

    WM_PAINT:
    begin
      avocado_trackbar_paint(hWnd);
      Result := 0;
      Exit;
    end;

    //OBSŁUGA WYJŚCIA MYSZY (Resetowanie Hover)
    WM_MOUSELEAVE:
    begin
      SetProp(hWnd, 'AvIsHover', 0);
      InvalidateRect(hWnd, nil, False);
      Exit;
    end;

    // OBSŁUGA MYSZY
    WM_LBUTTONDOWN, WM_MOUSEMOVE:
    begin
      Margin := 13;
      // LOGIKA HOVER (Wykrywanie najechania)
      // Jeśli mysz właśnie wjechała (a wcześniej jej nie było)
      if GetProp(hWnd, 'AvIsHover') = 0 then
      begin
        SetProp(hWnd, 'AvIsHover', 1);


        // Prosimy system: "Powiadom mnie, jak mysz ucieknie (WM_MOUSELEAVE)"
        tme.cbSize := SizeOf(tme);
        tme.dwFlags := TME_LEAVE;
        tme.hwndTrack := hWnd;
        Windows.TrackMouseEvent(@tme);
        // Odśwież, żeby powiększyć kółko
        InvalidateRect(hWnd, nil, False);
      end;


      if (Msg = WM_LBUTTONDOWN) or ((Msg = WM_MOUSEMOVE) and ((WParam and MK_LBUTTON) <> 0)) then
      begin
        if Msg = WM_LBUTTONDOWN then SetCapture(hWnd);
        GetClientRect(hWnd, R);
        //MouseX := LoWord(LParam);
        MouseX := SmallInt(LoWord(LParam));
        if MouseX < Margin then MouseX := Margin;
        if MouseX > (R.Right - Margin) then MouseX := R.Right - Margin;

        WorkWidth := (R.Right - R.Left) - (2 * Margin);
        if WorkWidth < 1 then WorkWidth := 1; // Zabezpieczenie przed dzieleniem przez 0
        Percent := (MouseX - Margin) / (R.Right - 2 * Margin);


        Min := Integer(GetProp(hWnd, 'AvTrMin'));
        Max := Integer(GetProp(hWnd, 'AvTrMax'));

        // LOGIKA STEP (PRZYCIĄGANIE) ---

        // Najpierw obliczamy "surową" pozycję

        RawPos := Min + Round(Percent * (Max - Min));
        // Pobieramy wartość kroku (np. 0, 1, 5, 10...)
        Step := Integer(GetProp(hWnd, 'AvTrStep'));

        if Step > 0 then
        begin
          // Matematyka: Odejmujemy Min, dzielimy przez krok, zaokrąglamy, mnożymy i dodajemy Min
          // Dzięki temu kroki liczą się od wartości Min (np. Min=10, Step=5 -> 10, 15, 20...)
          Pos := Min + (Round((RawPos - Min) / Step) * Step);
        end
        else
        begin
          Pos := RawPos;
        end;

        //Pos := Min + Round(Percent * (Max - Min));
        if Pos < Min then Pos := Min;
        if Pos > Max then Pos := Max;

        if Integer(GetProp(hWnd, 'AvTrPos')) <> Pos then
        begin
          SetProp(hWnd, 'AvTrPos', THandle(Pos));
          InvalidateRect(hWnd, nil, False);
          SendMessage(GetParent(hWnd), WM_COMMAND, MakeWParam(Word(GetDlgCtrlID(hWnd)), 0), PtrInt(hWnd));
        end;
      end;
      Result := 0;
      Exit;
    end;

    WM_LBUTTONUP:
    begin
      ReleaseCapture;
      Result := 0;
      Exit;
    end;

    WM_NCDESTROY:
    begin
      RemoveProp(hWnd, AV_TRACK_MIN);
      RemoveProp(hWnd, AV_TRACK_MAX);
      RemoveProp(hWnd, AV_TRACK_POS);

      RemoveProp(hWnd, AV_TRACK_COL_TRACK);
      RemoveProp(hWnd, AV_TRACK_COL_PROGRESS);
      RemoveProp(hWnd, AV_TRACK_COL_THUMB);

      RemoveProp(hWnd, AV_TRACK_STEP);
      RemoveProp(hWnd, AV_TRACK_SHOV_IS_HOVER);
      RemoveProp(hWnd, AV_TRACK_SHOV_VALUE);
    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;

function create_trackbar(Parent: HWND; X, Y, Width, Height: Integer): HWND;
var
  wnd_class: TWndClassExW;
begin
    if not GetClassInfoExW(GetModuleHandle(nil), CLASS_NAME_TRACKBAR, @wnd_class) then
    begin
      FillChar(wnd_class, SizeOf(wnd_class), 0);
      wnd_class.cbSize := SizeOf(TWndClassExW);
      wnd_class.style := CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS;
      wnd_class.lpfnWndProc := @AvocadoTrackBarProc; // Twoja procedura obsługi

      wnd_class.hInstance := GetModuleHandle(nil);
      wnd_class.hCursor := LoadCursor(0, IDC_HAND); // Łapka

      wnd_class.hbrBackground := HBRUSH(GetStockObject(NULL_BRUSH));
      wnd_class.lpszClassName := CLASS_NAME_TRACKBAR;

    if RegisterClassExW(wnd_class) = 0 then
    begin
       Result := 0;
       Exit;
    end;
    end;

    // 2. Tworzenie okna
    Result := CreateWindowExW(
      WS_EX_TRANSPARENT,
     // 0, // WS_EX_TRANSPARENT jeśli chcesz widzieć tło rodzica (skomplikowane)
      CLASS_NAME_TRACKBAR,
      nil,
      WS_VISIBLE or WS_CHILD, // Styl okna
      x, y, width, height,
      parent,
      0,
      GetModuleHandle(nil),
      nil
    );

    // 3. Ustawienia domyślne (użyj stałych z avoraiser.core!)
    if Result <> 0 then
    begin

      SetProp(Result, AV_TRACK_MIN, 0);
      SetProp(Result, AV_TRACK_MAX, 100);
      SetProp(Result, AV_TRACK_POS, 50);

      // Wymuszenie pierwszego rysowania
      InvalidateRect(Result, nil, True);
    end;
  end;

procedure set_trackbar_pos(hTrack: HWND; Pos: Integer);
begin
  SetProp(hTrack, 'AvTrPos', THandle(Pos));
  InvalidateRect(hTrack, nil, False);
end;

function get_trackbar_pos(hTrack: HWND): Integer;
begin
  Result := Integer(GetProp(hTrack, 'AvTrPos'));
end;

procedure set_trackbar_range(hTrack: HWND; Min, Max: Integer);
begin
  SetProp(hTrack, 'AvTrMin', THandle(Min));
  SetProp(hTrack, 'AvTrMax', THandle(Max));
  InvalidateRect(hTrack, nil, True);
end;

procedure set_trackbar_colors(hTrack: HWND; clTrack, clProgress, clThumb: DWORD);
begin
  SetProp(hTrack, 'AvTrColTr', THandle(clTrack));
  SetProp(hTrack, 'AvTrColProg', THandle(clProgress));
  SetProp(hTrack, 'AvTrColTh', THandle(clThumb));
  InvalidateRect(hTrack, nil, True);
end;

procedure set_trackbar_step(hTrack: HWND; Step: Integer);
begin
  SetProp(hTrack, 'AvTrStep', THandle(Step));
end;

procedure set_trackbar_show_value(hTrack: HWND; Show: Boolean);
begin
    if Show then
       SetProp(hTrack, 'AvTrShVal', 1)
     else
       SetProp(hTrack, 'AvTrShVal', 0);
end;

end.


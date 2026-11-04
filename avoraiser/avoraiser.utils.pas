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

Module:     avoraiser.utils
Description:
*)
unit avoraiser.utils;

{$mode ObjFPC}{$H+}
interface
uses
  Windows, avoraiser.core;
//avoraiser.events,
type
  SUBCLASSPROC = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
    uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;

{KONWERSJE }
// Zwraca długość tekstu w oknie lub kontrolce (liczba znaków)
function get_window_text_length(Handle: HWND): Integer;
// Ustawia tekst dowolnej kontrolki (Button, Label, Window, Edit)
procedure set_text(Handle: HWND; const AText: string);
// Pobiera tekst z dowolnej kontrolki
function get_text(Handle: HWND): string;
//Konwersje (Zastępują SysUtils)
// Zamienia liczbę na zwykły string
function int_to_str(value: Integer): string; inline;
// Zamienia liczbę na UnicodeString (Do kontrolek WinAPI, np. SetWindowTextW)
function int_to_wide(value: Integer): UnicodeString; inline;
function str_to_int(const s: UnicodeString; default_val: Integer): Integer;

{POMOCNICZE FUNKCJE}
function rgb(R, G, B: Byte): DWORD; inline;
// Wstawiaj to wewnątrz długich pętli (np. while).
procedure process_messages;
function get_prop_color(hWnd: HWND; const PropName: string; DefaultCol: DWORD): DWORD;
function av_adjust_line_breaks(const s: UnicodeString): UnicodeString;

procedure int_to_pchar(Value: Integer; Buffer: PChar);
{Zamienia PChar na liczbę. W razie błędu zwraca Default}
function pchar_to_int(Str: PChar; Default: Integer = 0): Integer;
{Pobiera liczbę bezpośrednio z kontrolki (np. z Edit)}
function get_window_int(hWnd: HWND): Integer;
{Wpisuje liczbę bezpośrednio do kontrolki }
procedure set_window_int(hWnd: HWND; Value: Integer);
//Ustawia kolor kontrolkam (Edit, Memo, itp)
procedure set_control_color(Control: HWND; TextColor, BgColor: DWORD);
// Pobiera informacje o monitorze, na którym znajduje się okno
function get_window_monitor_info(Handle: HWND): TAvocadoMonitorInfo;
//geometria okna / kontrolki
function get_window_x(Handle: HWND): Integer;
function get_window_y(Handle: HWND): Integer;
function get_window_width(Handle: HWND): Integer;
function get_window_height(Handle: HWND): Integer;
procedure set_dark_mode(Handle: HWND; Enable: Boolean);
function get_window_title(Handle: HWND): string;
// Bezpiecznie niszczy dowolną kontrolkę lub okno
procedure destroy_window(Handle: HWND);
// Cień pod oknem (szczególnie dla Frameless)
procedure set_window_shadow(Handle: HWND; Enable: Boolean);
// aby móc zmieniać napis na pasku tytułu "w locie", np. pokazując postęp ładowania lub nazwę otwartego pliku?
procedure set_title(Handle: HWND; const NewTitle: string);
// Uruchamia timer. Jeśli TimerID = 0, system stworzy nowy ID. Interval w milisekundach.
function start_timer(Handle: HWND; TimerID: UINT_PTR; Interval: UINT): UINT_PTR;
// Zatrzymuje timer.
function stop_timer(Handle: HWND; TimerID: UINT_PTR): BOOL;
procedure set_on_query_end_session(Handle: HWND; Event: TAvocadoQueryEndSessionEvent);
procedure set_on_end_session(Handle: HWND; Event: TAvocadoEndSessionEvent);
function make_wparam(Low, High: Word): WPARAM; inline;
// Pozwala systemowi "odetchnąć" i obsłużyć kliknięcia/odświeżanie
procedure set_component_color(h_wnd: HWND; text_color, background_color: DWORD);
 //Uniwersalne skalowanie czcionki
procedure set_component_auto_font(Handle: HWND; Height: Integer);
// Oblicza nowe wymiary tak, by obraz o wymiarach
procedure calculate_aspect_ratio(OrigW, OrigH, MaxW, MaxH: Integer; out NewW, NewH: Integer);
function SetWindowSubclass(hWnd: HWND; pfnSubclass: SUBCLASSPROC; uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): BOOL; stdcall; external 'comctl32.dll' name 'SetWindowSubclass';
function GetWindowSubclass(hWnd: HWND; pfnSubclass: SUBCLASSPROC; uIdSubclass: UINT_PTR; pdwRefData: PDWORD_PTR): BOOL; stdcall; external 'comctl32.dll' name 'GetWindowSubclass';
function RemoveWindowSubclass(hWnd: HWND; pfnSubclass: SUBCLASSPROC; uIdSubclass: UINT_PTR): BOOL; stdcall; external 'comctl32.dll' name 'RemoveWindowSubclass';
function DefSubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; external 'comctl32.dll' name 'DefSubclassProc';
procedure set_component_transparent(h_wnd: HWND; text_color: DWORD);
procedure set_component_text_color(Handle: HWND; Color: DWORD);
procedure track_mouse_leave(Handle: HWND);
//ustawienie czcionki
procedure set_component_size_font(hComponent: HWND; FontName: PWideChar; Size: Integer);
//ustawia kolor tla listboxa
procedure set_listbox_color(Handle: HWND; TextColor, BgColor: DWORD);
// Pokazuje (True) lub ukrywa (False) dowolny komponent/obiekt
procedure show_component(hComponent: HWND; Visible: Boolean);
function create_panel(Parent: HWND; X, Y, W, H: Integer; Color: DWORD): HWND;
//Przełącza widoczność (jak jest widoczny to ukrywa, jak ukryty to pokazuje)
procedure show_toggle_component(hComponent: HWND);
function color_to_argb(WinColor: DWORD): DWORD;
//Uniwersalna funkcja pomocnicz do tworzenia fontow
function create_ui_font(const font_name: PWideChar; size: Integer): HFONT;
function extract_file_ext(const file_name: UnicodeString): UnicodeString;
function same_text(const s1, s2: UnicodeString): Boolean;
procedure open_url(const url: UnicodeString);
function read_file_to_string(const file_path: UnicodeString): UnicodeString;
function get_file_name_only(const file_path: UnicodeString): UnicodeString;
function get_file_extension(const file_path: UnicodeString): UnicodeString;
// Zamiennik FileExists - sprawdza atrybuty pliku
function file_exists_win(const filename: UnicodeString): Boolean;
// Zamiennik ExtractFilePath - wycina ścieżkę z pełnej nazwy modułu
function get_app_path: UnicodeString;

implementation




function DwmExtendFrameIntoClientArea(hwnd: HWND; const pMarInset: MARGINS): HRESULT; stdcall; external 'dwmapi.dll';
function MonitorFromWindow(hwnd: HWND; dwFlags: DWORD): HMONITOR; stdcall; external 'user32.dll';
function GetMonitorInfoW(hMonitor: HMONITOR; lpmi: PMONITORINFO): BOOL; stdcall; external 'user32.dll';
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';
function ShellExecuteW(hwnd: HWND; lpOperation, lpFile, lpParameters, lpDirectory: PWideChar; nShowCmd: Integer): HINST; stdcall; external 'shell32.dll' name 'ShellExecuteW';

procedure set_dark_mode(Handle: HWND; Enable: Boolean);
var
  DarkMode: Integer;
begin
  if Enable then DarkMode := 1 else DarkMode := 0;
  DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkMode, SizeOf(DarkMode));
end;

function get_window_title(Handle: HWND): string;
begin
  Result := get_text(Handle);
end;

procedure destroy_window(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    Windows.DestroyWindow(Handle);
  end;
end;

procedure set_window_shadow(Handle: HWND; Enable: Boolean);
var
  m: MARGINS;
  v: Integer;
begin
  if Handle = 0 then Exit;
  if Enable then
  begin
    // Rozszerzamy ramkę o 1 piksel z każdej strony -> System rysuje cień
    m.cxLeftWidth := 1;
    m.cxRightWidth := 1;
    m.cyTopHeight := 1;
    m.cyBottomHeight := 1;
    DwmExtendFrameIntoClientArea(Handle, m);

    // Dodatkowo upewniamy się, że styl pozwala na cień (CS_DROPSHADOW czasem pomaga)
    // Ale DwmExtendFrameIntoClientArea jest ważniejsze w nowoczesnych Windowsach.
  end
  else
  begin
    // Zerujemy marginesy -> Brak cienia
    m.cxLeftWidth := 0;
    m.cxRightWidth := 0;
    m.cyTopHeight := 0;
    m.cyBottomHeight := 0;
    DwmExtendFrameIntoClientArea(Handle, m);
  end;
end;

procedure set_title(Handle: HWND; const NewTitle: string);
begin
  if Handle <> 0 then
  begin
    SetWindowTextW(Handle, PWideChar(UnicodeString(NewTitle)));
  end;
end;

function start_timer(Handle: HWND; TimerID: UINT_PTR; Interval: UINT): UINT_PTR;
begin
  Result := SetTimer(Handle, TimerID, Interval, nil);
end;

function stop_timer(Handle: HWND; TimerID: UINT_PTR): BOOL;
begin
  Result := KillTimer(Handle, TimerID);
end;

procedure set_on_query_end_session(Handle: HWND; Event: TAvocadoQueryEndSessionEvent);
begin
  SetProp(Handle, AV_PROP_ON_QUERY_END, THandle(Event));
end;

procedure set_on_end_session(Handle: HWND; Event: TAvocadoEndSessionEvent);
begin
  SetProp(Handle, AV_PROP_ON_END_SESSION, THandle(Event));
end;

function make_wparam(Low, High: Word): WPARAM;
begin
  Result := (Low and $FFFF) or (DWORD(High) shl 16);
end;

procedure set_component_color(h_wnd: HWND; text_color, background_color: DWORD);
var
  new_brush, old_brush: HBRUSH;
begin
  if h_wnd = 0 then Exit;

  SetPropW(h_wnd, AV_PROP_BG_COLOR, THandle(background_color + 1));
  SetPropW(h_wnd, AV_PROP_TEXT_COLOR, THandle(text_color + 1));

  old_brush := HBRUSH(GetPropW(h_wnd, AV_PROP_BRUSH));
  if old_brush <> 0 then DeleteObject(old_brush);

  new_brush := CreateSolidBrush(background_color);
  SetPropW(h_wnd, AV_PROP_BRUSH, THandle(new_brush));

  RedrawWindow(h_wnd, nil, 0, RDW_INVALIDATE or RDW_FRAME or RDW_ERASE or RDW_UPDATENOW);
end;

procedure set_component_auto_font(Handle: HWND; Height: Integer);
var
  NewHeight: Integer;
  NewFont, OldFont: HFONT;
begin
  if Handle = 0 then Exit;
    // Obliczamy wysokość (Height - margines)
    NewHeight := -1 * (Height - 6);

    // Zabezpieczenie przed zniknięciem tekstu
    if NewHeight > -10 then NewHeight := -10;


    NewFont := CreateFontW(NewHeight, 0, 0, 0, FW_NORMAL, 0, 0, 0,
                           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                           CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

    // Sprzątamy starą czcionkę (korzystamy z uniwersalnego klucza z core!)
    OldFont := HFONT(GetPropW(Handle, AV_PROP_AUTO_FONT));
    if OldFont <> 0 then DeleteObject(OldFont);

    //Zapisujemy i aplikujemy
    SetPropW(Handle, AV_PROP_AUTO_FONT, THandle(NewFont));
    SendMessageW(Handle, WM_SETFONT, WPARAM(NewFont), 1);
end;

procedure calculate_aspect_ratio(OrigW, OrigH, MaxW, MaxH: Integer; out NewW,
  NewH: Integer);
var
  RatioW, RatioH, MinRatio: Double;
begin
   // Zabezpieczenie przed dzieleniem przez zero
    if (OrigW <= 0) or (OrigH <= 0) then
    begin
      NewW := 0;
      NewH := 0;
      Exit;
    end;

    // Obliczamy współczynnik skali dla szerokości i wysokości
    RatioW := MaxW / OrigW;
    RatioH := MaxH / OrigH;

    // Wybieramy mniejszy współczynnik, aby obraz na pewno nie wyszedł poza "pudełko"
    if RatioW < RatioH then
      MinRatio := RatioW
    else
      MinRatio := RatioH;

    // Aplikujemy skalę i zaokrąglamy do pełnych pikseli
    NewW := Round(OrigW * MinRatio);
    NewH := Round(OrigH * MinRatio);
end;

procedure set_component_transparent(h_wnd: HWND; text_color: DWORD);
var
  old_brush: HBRUSH;
begin
  if h_wnd = 0 then Exit;
    SetPropW(h_wnd, AV_PROP_TEXT_COLOR, THandle(text_color + 1));
    old_brush := HBRUSH(GetPropW(h_wnd, AV_PROP_BRUSH));
    if (old_brush <> 0) and (old_brush <> GetStockObject(NULL_BRUSH)) then
       DeleteObject(old_brush);
    SetPropW(h_wnd, AV_PROP_BRUSH, THandle(GetStockObject(NULL_BRUSH)));
    InvalidateRect(h_wnd, nil, True);
end;

procedure set_component_text_color(Handle: HWND; Color: DWORD);
begin
  if Handle = 0 then Exit;
  SetPropW(Handle, AV_PROP_TEXT_COLOR, THandle(Color + 1));
  InvalidateRect(Handle, nil, True);
  UpdateWindow(Handle);
end;

procedure track_mouse_leave(Handle: HWND);
var
  tme: TTrackMouseEvent; // Zmienna lokalna, ukryta tutaj
begin
  if Handle = 0 then Exit;

  if GetPropW(Handle, 'IsHover') = 0 then
  begin
    SetPropW(Handle, 'IsHover', 1);

    tme.cbSize := SizeOf(TTrackMouseEvent); // Tutaj też zmiana
    tme.dwFlags := TME_LEAVE;
    tme.hwndTrack := Handle;
    tme.dwHoverTime := 0;

    // Teraz kompilator wie, że to funkcja, a tme to zmienna typu TTrackMouseEvent
    TrackMouseEvent(tme);

    InvalidateRect(Handle, nil, False);
  end;
end;

procedure set_component_size_font(hComponent: HWND; FontName: PWideChar;Size: Integer);
var
hNewFont, hOldFontProp: HFONT;
myhDC: HDC;
hPrevFont: HGDIOBJ;
TextSize: TSize;
ClassName: array[0..255] of WideChar;
Buffer: array[0..511] of WideChar;
begin
 if hComponent = 0 then Exit;

  myhDC := GetDC(hComponent);
  try
    //Tworzymy nową czcionkę (DPI Aware + ClearType)
    hNewFont := CreateFontW(
      -MulDiv(Size, GetDeviceCaps(myhDC, LOGPIXELSY), 72),
      0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      CLEARTYPE_QUALITY,
      DEFAULT_PITCH or FF_DONTCARE, FontName);
  finally
    ReleaseDC(hComponent, myhDC);
  end;

  if hNewFont = 0 then Exit;

  // Sprzątanie starej czcionki (Memory Leak prevention)
  hOldFontProp := HFONT(GetPropW(hComponent, 'AvoFont'));
  if hOldFontProp <> 0 then DeleteObject(hOldFontProp);

  SetPropW(hComponent, 'AvoFont', THandle(hNewFont));

  // Ustawiamy czcionkę w kontrolce
  SendMessageW(hComponent, WM_SETFONT, WPARAM(hNewFont), LPARAM(True));


  // auto-naprawa wyglądu (dla list i labeli)
  if GetClassNameW(hComponent, ClassName, 255) > 0 then
  begin
    myhDC := GetDC(hComponent);
    // Wybieramy nową czcionkę do kontekstu, żeby ją zmierzyć
    hPrevFont := SelectObject(myhDC, hNewFont);

    try
       // LABEL (STATIC)
       if lstrcmpiW(ClassName, 'STATIC') = 0 then
       begin
          // Pobieramy aktualny tekst labela
          GetWindowTextW(hComponent, Buffer, 511);

          if lstrlenW(Buffer) > 0 then
          begin
             // Mierzymy, ile miejsca zajmie ten tekst z nową czcionką
             GetTextExtentPoint32W(myhDC, Buffer, lstrlenW(Buffer), TextSize);
             SetWindowPos(hComponent, 0, 0, 0,
                TextSize.cx + 2,
                TextSize.cy + 2,
                SWP_NOMOVE or SWP_NOZORDER);
          end;
       end

       // LISTBOX (Wysokość wiersza)
       else if lstrcmpiW(ClassName, 'LISTBOX') = 0 then
       begin
          GetTextExtentPoint32W(myhDC, 'Ay', 2, TextSize);
          SendMessageW(hComponent, LB_SETITEMHEIGHT, 0, TextSize.cy + 6);
       end;

    finally
       SelectObject(myhDC, hPrevFont);
       ReleaseDC(hComponent, myhDC);
    end;
    InvalidateRect(hComponent, nil, True);
  end;
end;

procedure set_listbox_color(Handle: HWND; TextColor, BgColor: DWORD);
var
  OldBrush: HBRUSH;
begin
    SetPropW(Handle, AV_PROP_TEXT_COLOR, THandle(TextColor + 1));
    SetPropW(Handle, AV_PROP_BG_COLOR,   THandle(BgColor)); // Kolor tła (jako wartość)

    OldBrush := HBRUSH(GetPropW(Handle, AV_PROP_BRUSH));
    if (OldBrush <> 0) and (OldBrush <> GetStockObject(NULL_BRUSH)) then
       DeleteObject(OldBrush);
    SetPropW(Handle, AV_PROP_BRUSH, THandle(CreateSolidBrush(BgColor)));
    InvalidateRect(Handle, nil, True);
end;

procedure show_component(hComponent: HWND; Visible: Boolean);
begin
  if hComponent = 0 then Exit;
  if Visible then
    ShowWindow(hComponent, SW_SHOW)
  else
    ShowWindow(hComponent, SW_HIDE);
end;

function create_panel(Parent: HWND; X, Y, W, H: Integer; Color: DWORD): HWND;
begin
  Result := CreateWindowExW(
    0, 'STATIC', nil,
    WS_CHILD or WS_VISIBLE or SS_NOTIFY,
    X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
  );

  if Result <> 0 then
  begin
    set_component_color(Result, 0, Color);
  end;
end;

procedure show_toggle_component(hComponent: HWND);
begin
  if hComponent = 0 then Exit;
  // Sprawdzam czy jest widoczny (IsWindowVisible) i robimy na odwrót
  if IsWindowVisible(hComponent) then
    ShowWindow(hComponent, SW_HIDE)
  else
    ShowWindow(hComponent, SW_SHOW);
end;

function color_to_argb(WinColor: DWORD): DWORD;
var
  R, G, B: Byte;
begin
  R := WinColor and $FF;
  G := (WinColor shr 8) and $FF;
  B := (WinColor shr 16) and $FF;

  // GDI+ wymaga AARRGGBB
  Result := $FF000000 or (DWORD(R) shl 16) or (DWORD(G) shl 8) or DWORD(B);
end;

function create_ui_font(const font_name: PWideChar; size: Integer): HFONT;
var
  pixel_height: Integer;
  dc: HDC;
begin
    // Pobieramy kontekst ekranu, aby poprawnie przeliczyć punkty (pt) na piksele (px)
    dc := GetDC(0);
    pixel_height := -MulDiv(size, GetDeviceCaps(dc, LOGPIXELSY), 72);
    ReleaseDC(0, dc);

    // Tworzymy nowoczesną czcionkę
    Result := CreateFontW(
      pixel_height,
      0, 0, 0,
      FW_NORMAL,
      0, 0, 0,
      DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS,
      CLIP_DEFAULT_PRECIS,
      CLEARTYPE_QUALITY,
      DEFAULT_PITCH or FF_DONTCARE,
      font_name
    );
end;

function extract_file_ext(const file_name: UnicodeString): UnicodeString;
var
  i: Integer;
  len: Integer;
begin
  Result := '';
    len := Length(file_name);

    // Szukamy kropki od końca ciągu
    for i := len downto 1 do
    begin
      // Jeśli znajdziemy kropkę, zwracamy wszystko od kropki do końca
      if file_name[i] = '.' then
      begin
        Result := Copy(file_name, i, len - i + 1);
        Exit;
      end;
      if (file_name[i] = '\') or (file_name[i] = '/') then
        Exit;
    end;
end;

function same_text(const s1, s2: UnicodeString): Boolean;
const
NORM_IGNORECASE = $00000001;
CSTR_EQUAL      = 2;
LOCALE_USER_DEFAULT = $0400;
begin
    // Jeśli długości są różne, to na pewno nie są to te same teksty
    if Length(s1) <> Length(s2) then
    begin
      Result := False;
      Exit;
    end;

    // Funkcja CompareStringW zwraca 2 (CSTR_EQUAL) jeśli teksty są identyczne
    // przy ignorowaniu wielkości liter (NORM_IGNORECASE)
    Result := CompareStringW(
      LOCALE_USER_DEFAULT,
      NORM_IGNORECASE,
      PWideChar(s1),
      Length(s1),
      PWideChar(s2),
      Length(s2)
    ) = CSTR_EQUAL;
end;

procedure open_url(const url: UnicodeString);
begin
  if url = '' then Exit;
  ShellExecuteW(0, 'open', PWideChar(url), nil, nil, SW_SHOWNORMAL);
end;

function read_file_to_string(const file_path: UnicodeString): UnicodeString;
var
h_file: THandle;
file_size, bytes_read: DWORD;
raw_buffer: PAnsiChar;
wide_len: Integer;
begin
  Result := '';

  h_file := CreateFileW(PWideChar(file_path), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if h_file = INVALID_HANDLE_VALUE then Exit;

  try
    file_size := GetFileSize(h_file, nil);
    if (file_size = 0) or (file_size = INVALID_FILE_SIZE) then Exit;

    // Alokujemy surowy bufor pamięci
    GetMem(raw_buffer, file_size);
    try
      if ReadFile(h_file, raw_buffer^, file_size, bytes_read, nil) then
      begin
        // Najpierw sprawdzamy, jak duży będzie tekst po konwersji na Unicode (UTF-16)
        wide_len := MultiByteToWideChar(CP_UTF8, 0, raw_buffer, file_size, nil, 0);

        if wide_len > 0 then
        begin
          SetLength(Result, wide_len);
          // Właściwa konwersja do bufora Result
          MultiByteToWideChar(CP_UTF8, 0, raw_buffer, file_size, PWideChar(Result), wide_len);
        end;
      end;
    finally
      FreeMem(raw_buffer);
    end;
  finally
    CloseHandle(h_file);
  end;
end;

function get_file_name_only(const file_path: UnicodeString): UnicodeString;
var
  i: Integer;
begin
  Result := file_path; // Domyślnie zwracamy całość, jeśli nie znajdziemy ukośnika

    // Przeszukujemy od końca w poszukiwaniu '\' (Windows) lub '/' (Linux/URL)
    for i := Length(file_path) downto 1 do
    begin
      if (file_path[i] = '\') or (file_path[i] = '/') then
      begin
        // Wycinamy wszystko, co znajduje się po ukośniku
        Result := Copy(file_path, i + 1, Length(file_path) - i);
        Break;
      end;
    end;
end;

function get_file_extension(const file_path: UnicodeString): UnicodeString;
var
  i, dot_pos: Integer;
begin
  Result := '';
    dot_pos := 0;

    //  Szukamy kropki od końca stringa
    for i := Length(file_path) downto 1 do
    begin
      // Jeśli napotkamy ukośnik przed kropką, to plik nie ma rozszerzenia
      // (kropka mogła być częścią nazwy folderu wcześniej)
      if (file_path[i] = '\') or (file_path[i] = '/') then
        Break;

      if file_path[i] = '.' then
      begin
        dot_pos := i;
        Break;
      end;
    end;

    // Jeśli znaleźliśmy kropkę i nie jest ona na samym końcu
    if (dot_pos > 0) and (dot_pos < Length(file_path)) then
    begin
      // Wycinamy tekst po kropce
      Result := Copy(file_path, dot_pos + 1, Length(file_path) - dot_pos);
    end;
end;

function file_exists_win(const filename: UnicodeString): Boolean;
var
attr: DWORD;
begin
  attr := GetFileAttributesW(PWideChar(filename));
  Result := (attr <> $FFFFFFFF) and (attr and FILE_ATTRIBUTE_DIRECTORY = 0);
end;

function get_app_path: UnicodeString;
var
  buf: array[0..MAX_PATH] of WideChar;
  path: UnicodeString;
  i: Integer;
begin
   GetModuleFileNameW(0, buf, MAX_PATH);
    path := UnicodeString(buf);
    // Szukamy ostatniego ukośnika od końca
    for i := Length(path) downto 1 do
    begin
      if path[i] = '\' then
      begin
        Result := Copy(path, 1, i);
        Exit;
      end;
    end;
    Result := '';
end;



procedure process_messages;
var
  msg: TMsg;
begin
   // PM_REMOVE oznacza: pobierz wiadomość i usuń ją z kolejki
    while PeekMessageW(msg, 0, 0, 0, PM_REMOVE) do
    begin
      // Obsługa standardowa (translacja klawiszy, wysłanie do procedury okna)
      TranslateMessage(msg);
      DispatchMessageW(msg);
    end;
end;

function get_prop_color(hWnd: HWND; const PropName: string; DefaultCol: DWORD): DWORD;
var
  Value: THandle;
begin
    Value := GetPropW(hWnd, PWideChar(UnicodeString(PropName)));
    if Value <> 0 then
      Result := DWORD(Value - 1)
    else
      Result := DefaultCol;
end;

function av_adjust_line_breaks(const s: UnicodeString): UnicodeString;
var
  i, j, extra_chars: Integer;
begin
  Result := '';
    if s = '' then Exit;

    // 1. Liczymy ile mamy znaków #13, które nie mają po sobie #10
    extra_chars := 0;
    for i := 1 to Length(s) do
    begin
      if (s[i] = #13) then
      begin
        if (i = Length(s)) or (s[i + 1] <> #10) then
          Inc(extra_chars);
      end;
    end;

    if extra_chars = 0 then
    begin
      Result := s;
      Exit;
    end;

    // Alokujemy miejsce na nowy string
    SetLength(Result, Length(s) + extra_chars);

    //Przepisujemy znaki z poprawką
    j := 1;
    for i := 1 to Length(s) do
    begin
      Result[j] := s[i];
      Inc(j);

      // Jeśli to #13 i nie ma po nim #10, to wstawiamy #10
      if (s[i] = #13) then
      begin
        if (i = Length(s)) or (s[i + 1] <> #10) then
        begin
          Result[j] := #10;
          Inc(j);
        end;
      end;
    end;
end;

function get_window_text_length(Handle: HWND): Integer;
begin
    Result := 0;
  if Handle <> 0 then
  begin
    Result := Windows.GetWindowTextLengthW(Handle);
  end;
end;

procedure set_text(Handle: HWND; const AText: string);
begin
  if Handle <> 0 then
    begin
      SetWindowTextW(Handle, PWideChar(WideString(AText)));
    end;
end;

function get_text(Handle: HWND): string;
var
  Len: Integer;
  Buffer: WideString;
begin
  Result := '';
  if Handle = 0 then Exit;

  //Sprawdzamy długość tekstu
  Len := GetWindowTextLengthW(Handle);

  if Len > 0 then
  begin
    // Rezerwujemy pamięć (+1 na znak null)
    SetLength(Buffer, Len + 1);
    // 3. Pobieramy tekst
    GetWindowTextW(Handle, PWideChar(Buffer), Len + 1);
    // Obcinamy nadmiar
    SetLength(Buffer, Len);
    // Konwertujemy WideString na UTF-8 String
    Result := UTF8Encode(Buffer);
  end;
end;

function int_to_str(value: Integer): string;
begin
  System.Str(value, Result);
end;

function int_to_wide(value: Integer): UnicodeString;
begin
  System.Str(value, Result);
end;

function str_to_int(const s: UnicodeString; default_val: Integer): Integer;
var
  code: Integer;
begin
    Val(s, Result, code);
    if code <> 0 then
      Result := default_val;
end;

function rgb(R, G, B: Byte): DWORD;
begin
  Result := (B shl 16) or (G shl 8) or R;
end;

procedure int_to_pchar(Value: Integer; Buffer: PChar);
var
  S: ShortString;
  I: Integer;
begin
    Str(Value, S);
    for I := 1 to Length(S) do
    begin
      Buffer[I-1] := S[I];
    end;
    Buffer[Length(S)] := #0;
end;

function pchar_to_int(Str: PChar; Default: Integer): Integer;
var
  Code: Integer;
  TempS: ShortString;
begin
  TempS := Str;
  Val(TempS, Result, Code);
  if Code <> 0 then
    Result := Default;
end;

function get_window_int(hWnd: HWND): Integer;
var
  Buf: array[0..31] of Char;
begin
  GetWindowText(hWnd, Buf, 31);
  Result := pchar_to_int(Buf, 0);
end;

procedure set_window_int(hWnd: HWND; Value: Integer);
var
  Buf: array[0..31] of Char;
begin
  int_to_pchar(Value, Buf);
  SetWindowText(hWnd, Buf);
end;

procedure set_control_color(Control: HWND; TextColor, BgColor: DWORD);
var
NewBrush: HBRUSH;
OldBrush: HBRUSH;
begin
  //Sprawdź, czy już jest pędzel i go usuń (żeby nie było wycieków przy zmianie koloru)
  OldBrush := HBRUSH(GetProp(Control, 'AvocadoBrush'));
  if OldBrush <> 0 then DeleteObject(OldBrush);

  //Stwórz nowy pędzel tła
  NewBrush := CreateSolidBrush(BgColor);

  //Zapisz dane w kontrolce
  SetProp(Control, 'AvocadoBrush', THandle(NewBrush));
  SetProp(Control, 'AvocadoTextColor', THandle(TextColor));
  SetProp(Control, 'AvocadoBgColor', THandle(BgColor));
  //Wymuś odświeżenie kontrolki
  InvalidateRect(Control, nil, True);
end;

function get_window_monitor_info(Handle: HWND): TAvocadoMonitorInfo;
var
  HMon: HMONITOR;
  MonInfo: MONITORINFO;
begin
  // Zerowanie wyniku (na wypadek błędu)
  FillChar(Result, SizeOf(Result), 0);

  if Handle = 0 then Exit;

  // 1. Pobieramy uchwyt monitora
  HMon := MonitorFromWindow(Handle, MONITOR_DEFAULTTONEAREST);

  if HMon <> 0 then
  begin
    FillChar(MonInfo, SizeOf(MonInfo), 0);
    MonInfo.cbSize := SizeOf(MonInfo); // Jeśli rekord nie jest packed, SizeOf będzie błędne

    // 2. Pobieramy dane
    if GetMonitorInfoW(HMon, @MonInfo) then
    begin
      Result.MonitorRect := MonInfo.rcMonitor;
      Result.WorkRect := MonInfo.rcWork;
      Result.IsPrimary := (MonInfo.dwFlags and MONITORINFOF_PRIMARY) <> 0;
    end;
  end;
end;

function get_window_x(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Left;
end;

function get_window_y(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Top;
end;

function get_window_width(Handle: HWND): Integer;
var
  Rect: TRect;
begin
   Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Right - Rect.Left;
end;

function get_window_height(Handle: HWND): Integer;
var
  Rect: TRect;
begin
   Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Bottom - Rect.Top;
end;

end.


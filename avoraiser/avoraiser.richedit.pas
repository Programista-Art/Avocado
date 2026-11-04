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

Module:     avoraiser.richedit
Description:
*)

unit avoraiser.richedit;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,avoraiser.core,avoraiser.utils,avoraiser.system;

type
  // Zakres znaków (używany w wielu komunikatach RichEdit)
  TCharRange = record
    cpMin: LongInt;
    cpMax: LongInt;
  end;

  // Struktura potrzebna do EM_FINDTEXTEXW
  TFindTextExW = record
    chrg: TCharRange;      // Zakres, w którym szukamy (wejście)
    lpstrText: PWideChar;  // Tekst, którego szukamy (wejście)
    chrgText: TCharRange;  // Zakres znalezionego tekstu (wyjście)
  end;

type
  {$PACKRECORDS 4}
  t_av_char_format = packed record
    cb_size: UINT;
    dw_mask: DWORD;
    dw_effects: DWORD;
    y_height: LongInt;
    y_offset: LongInt;
    cr_text_color: COLORREF;
    b_char_set: Byte;
    b_pitch_and_family: Byte;
    sz_face_name: array[0..31] of WideChar;
    w_weight: Word;
    s_spacing: SmallInt;
    cr_back_color: COLORREF;
    lcid: LCID;
    dw_reserved: DWORD;
    s_style: SmallInt;
    w_kerning: Word;
    b_underline_type: Byte;
    b_animation: Byte;
    b_rev_author: Byte;
    b_reserved1: Byte;
  end;

  // PARAFORMAT2 - musi być PACKED!
  t_av_para_format = packed record
    cb_size: UINT;
    dw_mask: DWORD;
    w_numbering: Word;
    w_effects: Word;
    dx_start_indent: LongInt;
    dx_right_indent: LongInt;
    dx_offset: LongInt;
    w_alignment: Word;
    c_tab_count: SmallInt;
    rgx_tabs: array[0..31] of LongInt;
    dy_space_before: LongInt;
    dy_space_after: LongInt;
    dy_line_spacing: LongInt;
    s_style: SmallInt;
    b_line_spacing_rule: Byte;
    b_outline_level: Byte;
    w_shading_weight: Word;
    w_shading_style: Word;
    w_numbering_start: Word;
    w_numbering_style: Word;
    w_numbering_tab: Word;
    w_border_space: Word;
    w_border_width: Word;
    w_borders: Word;
  end;

  // Strumieniowanie (do wczytywania/zapisywania RTF)
  t_av_edit_stream = packed record
    dw_cookie: DWORD_PTR;
    dw_error: DWORD;
    pfn_callback: Pointer; // Zmieniamy nazwę na snake_case
  end;
type
  t_av_stream_callback = function(dw_cookie: DWORD_PTR; pb_buff: LPBYTE; cb: LongInt; var pcb: LongInt): DWORD; stdcall;


function create_rich_edit(h_parent: HWND; x, y, w, h: Integer; bg_color, text_color: COLORREF): HWND;
//zmiana koloru tła
procedure set_rich_text_background_color(Handle: HWND; Color: Integer);
//zmiana koloru tekstu

// Włącza lub wyłącza systemową ramkę (3D)
procedure set_rich_text_border(Handle: HWND; Enable: Boolean);
procedure set_rich_text_word_wrap(Handle: HWND; Enable: Boolean);
procedure set_rich_text_read_only(Handle: HWND; ReadOnly: Boolean);

// Pomocnicza funkcja do wysyłania struktury CHARFORMAT2
procedure apply_char_format(h_wnd: HWND; mask, effects: DWORD; color: DWORD; size: Integer);
// Funkcje formatowania (działają na ZAZNACZONYM tekście)
procedure set_rich_text_bold(h_wnd: HWND; enable: Boolean);
procedure set_rich_text_italic(h_wnd: HWND; enable: Boolean);
procedure set_rich_text_underline(h_wnd: HWND; enable: Boolean);
procedure set_rich_text_color(handle: HWND; color: COLORREF);

procedure set_rich_text_size(h_wnd: HWND; size: Integer);
// 1 Left, 2 Center, 3 Right
procedure set_rich_text_alignment(Handle: HWND; Align: Integer);
//Callback do wczytywania (RichEdit -> Program)
//function edit_stream_in_callback(dwCookie: DWORD_PTR; pbBuff: PByte; cb: LongInt; pcb: PLongInt): DWORD; stdcall;
// Callback do zapisywania (Program -> RichEdit)
function edit_stream_out_callback(dwCookie: DWORD_PTR; pbBuff: PByte; cb: LongInt; pcb: PLongInt): DWORD; stdcall;
procedure set_rich_text_bullets(Handle: HWND; Enable: Boolean);
procedure rich_text_undo(Handle: HWND);
procedure rich_text_redo(Handle: HWND);
procedure load_rich_text_from_file(h_rich_edit: HWND; const file_path: UnicodeString);
procedure save_rich_text_to_file(handle: HWND; const filename: UnicodeString);
// StartPos: od którego znaku szukać (0 = początek)
function find_rich_text(handle: HWND; const search_str: UnicodeString;start_pos: Integer; match_case, whole_word: Boolean): Integer;
procedure select_rich_text(h_rich: HWND; start_pos, len: Integer);
// Sprawdza, czy zaznaczony tekst jest pogrubiony
function is_rich_text_bold(Handle: HWND): Boolean;
// Zmiana rozmiaru (w punktach, np. 10, 12, 14...)
procedure set_rich_text_font_size(handle: HWND; size_points: Integer);
procedure set_rich_text_font_size_all(handle: HWND; size_points: Integer; all_text: Boolean = False);
// Zmiana nazwy czcionki (np. 'Arial', 'Times New Roman')
procedure set_rich_text_font_name(handle: HWND; const font_name: UnicodeString);
//Resetuj formatowanie, która ustawia standardowy wygląd
procedure reset_to_standard_font(handle: HWND);
// Zwraca True, jeśli zaznaczony tekst jest pogrubiony/kursywą itp.
// StyleToCheck: 1=Bold, 2=Italic, 4=Underline
function is_rich_text_style_active(handle: HWND; style_to_check: Integer): Boolean;
procedure set_rich_text_zoom(handle: HWND; numerator, denominator: Integer);
procedure set_rich_text_zoom_percent(handle: HWND; percent: Integer);
procedure set_rich_text_auto_url(handle: HWND; enable: Boolean);
procedure get_rich_text_caret_pos(handle: HWND; var line, col: Integer);
procedure goto_rich_text_line(handle: HWND; line_num: Integer);
function get_rich_text_line_count(handle: HWND): Integer;
function get_rich_text_selection_length(handle: HWND): Integer;
procedure change_rich_text_indent(handle: HWND; increase: Boolean);
// Zwraca nazwę pliku, jeśli się udało, lub pusty ciąg znaków
function handle_drop_files (handle: HWND; drop_info: WPARAM): UnicodeString;
function get_rich_text_text(handle: HWND): UnicodeString;
procedure set_rich_text_text(handle: HWND; const text: UnicodeString);
//wstawiania w miejscu kursora:
procedure insert_rich_text_at_cursor(handle: HWND; const a_text: string);
procedure install_avocado_rich_edit_subclass(h_rich: HWND);

var
  old_rich_edit_proc: WNDPROC = nil;


implementation

function avocado_rich_edit_proc(h_wnd: HWND; msg: UINT; w_param: WPARAM; l_param: LPARAM): LRESULT; stdcall;
var
  dc: HDC;
  ps: PAINTSTRUCT;
begin
  // 1. Obsługa własnego rysowania
  if msg = WM_PAINT then
  begin
    // Najpierw pozwalamy RichEditowi narysować tekst
    Result := CallWindowProcW(old_rich_edit_proc, h_wnd, msg, w_param, l_param);

    // Teraz możemy dorysować coś "na wierzchu" (np. margines)
    dc := BeginPaint(h_wnd, ps);
    // Tutaj Twoje funkcje rysujące GDI, np. Rectangle, TextOut...
    EndPaint(h_wnd, ps);

    Exit;
  end;

  // 2. Pozostałe komunikaty przesyłamy do oryginału
  Result := CallWindowProcW(old_rich_edit_proc, h_wnd, msg, w_param, l_param);
end;

function AvoStreamReadCallback(dwCookie: DWORD_PTR; pbBuff: LPBYTE; cb: LongInt; var pcb: LongInt): DWORD; stdcall;
var
  hFile: THandle;
  BytesRead: DWORD;
begin
  hFile := THandle(dwCookie);
  if ReadFile(hFile, pbBuff^, cb, BytesRead, nil) then
  begin
    pcb := LongInt(BytesRead);
    Result := 0;
  end
  else
  begin
    Result := 1;
  end;
end;

function AvoStreamWriteCallback(dwCookie: DWORD_PTR; pbBuff: LPBYTE; cb: LongInt; var pcb: LongInt): DWORD; stdcall;
var
  hFile: THandle;
  BytesWritten: DWORD;
begin
  hFile := THandle(dwCookie);
  if WriteFile(hFile, pbBuff^, cb, BytesWritten, nil) then
  begin
    pcb := LongInt(BytesWritten);
    Result := 0;
  end
  else
  begin
    Result := 1;
  end;
end;

function create_rich_edit(h_parent: HWND; x, y, w, h: Integer; bg_color, text_color: COLORREF): HWND;
const
  SCF_DEFAULT = $0000;
  SCF_ALL     = $0004;
var
h_lib: THandle;
class_name: PWideChar;
cf: t_av_char_format;
h_font: HFONT;
begin
 Result := 0;

   // 1. Ładowanie biblioteki
   h_lib := LoadLibraryW('msftedit.dll');
   if h_lib <> 0 then class_name := 'RichEdit50W'
   else begin
     h_lib := LoadLibraryW('riched20.dll');
     if h_lib <> 0 then class_name := 'RichEdit20W' else Exit;
   end;

   // 2. Tworzenie okna
   Result := CreateWindowExW(0, class_name, '',
     WS_CHILD or WS_TABSTOP or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or
     ES_MULTILINE or ES_AUTOVSCROLL or ES_AUTOHSCROLL or ES_NOHIDESEL or ES_WANTRETURN,
     x, y, w, h, h_parent, 0, GetModuleHandle(nil), nil);

   if Result <> 0 then
   begin
     // kolor tła
     SendMessageW(Result, EM_SETBKGNDCOLOR, 0, LPARAM(bg_color));

     // czcionka
     h_font := create_ui_font('Segoe UI', 10);
     SendMessageW(Result, WM_SETFONT, WPARAM(h_font), 1);

     // kolor tekstu
     FillChar(cf, SizeOf(cf), 0);
     cf.cb_size := SizeOf(cf); // To musi być dokładnie 84 bajty dla CHARFORMAT2
     cf.dw_mask := CFM_COLOR;
     cf.cr_text_color := text_color;
     cf.dw_effects := 0; // Usuwamy CFE_AUTOTCOLOR!

     // Ustawiamy format domyślny (dla przyszłego tekstu)
     SendMessageW(Result, EM_SETCHARFORMAT, SCF_DEFAULT, LPARAM(@cf));

     // Ustawiamy format dla wszystkiego, co ewentualnie już jest w kontrolce
     SendMessageW(Result, EM_SETCHARFORMAT, SCF_ALL, LPARAM(@cf));

     SendMessageW(Result, EM_EXLIMITTEXT, 0, $7FFFFFF0);
     SendMessageW(Result, EM_SETEVENTMASK, 0, ENM_SELCHANGE or ENM_CHANGE or ENM_LINK);
     DragAcceptFiles(Result, True);
   end;
end;

procedure set_rich_text_background_color(Handle: HWND; Color: Integer);
const
  EM_SETBKGNDCOLOR = $0443;
begin
  if Handle = 0 then Exit;
  // Parametr 0 w wParam oznacza: "Użyj podanego koloru" (nie systemowego)
  SendMessage(Handle, EM_SETBKGNDCOLOR, 0, Color);
end;

procedure set_rich_text_color(handle: HWND; color: COLORREF);
const
EM_SETCHARFORMAT = $0444;
SCF_SELECTION    = $0001;
CFM_COLOR        = $40000000;
CFE_AUTOTCOLOR   = $40000000;
var
  cf: t_av_char_format;
begin
  if handle = 0 then Exit;
  FillChar(cf, SizeOf(cf), 0);
  cf.cb_size := SizeOf(cf);

  // Ustawiamy maskę na kolor (mówimy: "zmień tylko kolor")
  cf.dw_mask := CFM_COLOR;
  cf.cr_text_color := color;

  // Usuwamy flagę automatycznego koloru, aby wymusić nasz COLORREF
  cf.dw_effects := cf.dw_effects and (not CFE_AUTOTCOLOR);

  // Wysyłamy formatowanie do zaznaczonego tekstu (SCF_SELECTION)
  SendMessageW(handle, EM_SETCHARFORMAT, SCF_SELECTION, LPARAM(@cf));
end;

procedure set_rich_text_border(Handle: HWND; Enable: Boolean);
var
  Style, ExStyle: PtrInt;
begin
  if Handle = 0 then Exit;

     // Pobieramy obecne style
     Style := GetWindowLongPtr(Handle, GWL_STYLE);
     ExStyle := GetWindowLongPtr(Handle, GWL_EXSTYLE);

     if Enable then
     begin
       // Dodajemy ramkę (Standard i 3D)
       Style := Style or WS_BORDER;
       ExStyle := ExStyle or WS_EX_CLIENTEDGE;
     end
     else
     begin
       // Usuwamy ramkę (Czysty tekst bez krawędzi)
       Style := Style and (not WS_BORDER);
       ExStyle := ExStyle and (not WS_EX_CLIENTEDGE);
     end;

     // Zapisujemy zmiany
     SetWindowLongPtr(Handle, GWL_STYLE, Style);
     SetWindowLongPtr(Handle, GWL_EXSTYLE, ExStyle);

     SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure set_rich_text_word_wrap(Handle: HWND; Enable: Boolean);
begin
    if Enable then
  begin
    // Włącz zawijanie do okna (Target Device = 0, Line Width = 0)
    SendMessage(Handle, EM_SETTARGETDEVICE, 0, 0);
  end
  else
  begin
    // Wyłącz zawijanie (ogromna szerokość linii)
    SendMessage(Handle, EM_SETTARGETDEVICE, 0, 1); // 1 = WYŁĄCZ
  end;
end;

procedure set_rich_text_read_only(Handle: HWND; ReadOnly: Boolean);
begin
   if Handle = 0 then Exit;
    SendMessage(Handle, EM_SETREADONLY, WPARAM(ReadOnly), 0);

    // Opcjonalnie: Zmień kolor tła, żeby użytkownik widział różnicę
    if ReadOnly then
      SendMessage(Handle, EM_SETBKGNDCOLOR, 0, $F0F0F0) // Jasnoszary
    else
      SendMessage(Handle, EM_SETBKGNDCOLOR, 0, $FFFFFF); // Biały
    InvalidateRect(Handle, nil, True);
end;

procedure apply_char_format(h_wnd: HWND; mask, effects: DWORD; color: DWORD; size: Integer);
const
  EM_SETCHARFORMAT = $0444;
  SCF_SELECTION    = $0001;
var
  format: t_av_char_format;
begin
  if h_wnd = 0 then Exit;
  FillChar(format, SizeOf(format), 0);

  format.cb_size := SizeOf(format);
  format.dw_mask := mask;
  format.dw_effects := effects;
  format.cr_text_color := color;
  format.y_height := size * 20;

  // SCF_SELECTION = formatujemy tylko zaznaczony tekst (lub ten nowo wpisywany)
  SendMessageW(h_wnd, EM_SETCHARFORMAT, SCF_SELECTION, LPARAM(@format));
end;

procedure set_rich_text_bold(h_wnd: HWND; enable: Boolean);
const
  CFM_BOLD = $00000001;
  CFE_BOLD = $00000001;
var
  effects: DWORD;
begin
  if enable then
    effects := CFE_BOLD
  else effects := 0;
    apply_char_format(h_wnd, CFM_BOLD, effects, 0, 0);
end;

procedure set_rich_text_italic(h_wnd: HWND; enable: Boolean);
const
  CFM_ITALIC = $00000002;
  CFE_ITALIC = $00000002;
var
  effects: DWORD;
begin
  if enable then
    effects := CFE_ITALIC
  else
    effects := 0;
  apply_char_format(h_wnd, CFM_ITALIC, effects, 0, 0);
end;

procedure set_rich_text_underline(h_wnd: HWND; enable: Boolean);
const
  CFM_UNDERLINE = $00000004;
  CFE_UNDERLINE = $00000004;
var
  effects: DWORD;
begin
  if enable then
    effects := CFE_UNDERLINE
  else
    effects := 0;
  apply_char_format(h_wnd, CFM_UNDERLINE, effects, 0, 0);
end;

procedure set_rich_text_size(h_wnd: HWND; size: Integer);
const CFM_SIZE = $80000000;
begin
   apply_char_format(h_wnd, CFM_SIZE, 0, 0, size);
end;

procedure set_rich_text_alignment(Handle: HWND; Align: Integer);
const
  EM_SETPARAFORMAT = $0447;
  PFM_ALIGNMENT    = $00000008;
var
  para_format: t_av_para_format;
begin
  if Handle = 0 then Exit;
  // Czyścimy pamięć
  FillChar(para_format, SizeOf(para_format), 0);
  // Ustawiamy rozmiar struktury
  para_format.cb_size := SizeOf(para_format);
  // wyrównanie"
  para_format.dw_mask := PFM_ALIGNMENT;
  // wartość (1=Lewo, 2=Prawo, 3=Środek, 4=Wyjustuj)
  para_format.w_alignment := Word(align);
  SendMessageW(Handle, EM_SETPARAFORMAT, 0, LPARAM(@para_format));
end;

function edit_stream_in_callback(dwCookie: DWORD_PTR; pbBuff: PByte; cb: LongInt; pcb: PLongInt): DWORD; stdcall;
var
file_handle: HANDLE;
bytes_read: DWORD;
begin
  MessageBoxW(0, 'Callback ruszył!', 'Debug', 0);

 Result := 0; // Sukces dla RichEdit

  // 1. Sprawdzamy, czy wskaźniki od Windowsa nie są puste
  if (pcb = nil) or (pbBuff = nil) then
  begin
    Result := 1;
    Exit;
  end;

  // 2. Inicjalizujemy wartość pod adresem (używając daszka ^)
  pcb^ := 0;

  // 3. Odczytujemy uchwyt pliku z ciasteczka
  file_handle := HANDLE(dwCookie);

  // 4. Próba odczytu z pliku
  if ReadFile(file_handle, pbBuff^, cb, bytes_read, nil) then
  begin
    // Zapisujemy liczbę przeczytanych bajtów pod adres pcb
    pcb^ := LongInt(bytes_read);
  end
  else
    Result := 1; // Błąd systemowy przerywa strumień
end;

function edit_stream_out_callback(dwCookie: DWORD_PTR; pbBuff: PByte; cb: LongInt; pcb: PLongInt): DWORD; stdcall;
var
file_handle: HANDLE;
bytes_written: DWORD;
begin
 Result := 0;

  //Sprawdzamy, czy Windows na pewno dał nam adres do wpisania wyniku
  if (pcb = nil) then
  begin
    Result := 1;
    Exit;
  end;

  // Zerujemy WARTOŚĆ pod adresem (używamy ^)
  pcb^ := 0;

  // dwCookie to nasz natywny HANDLE pliku
  file_handle := HANDLE(dwCookie);

  if (file_handle = INVALID_HANDLE_VALUE) or (pbBuff = nil) or (cb <= 0) then
  begin
    Result := 1;
    Exit;
  end;

  //Zapisujemy dane na dysk
  if WriteFile(file_handle, pbBuff^, cb, bytes_written, nil) then
  begin
    //WPISUJEMY wartość pod adres (używamy ^)
    pcb^ := LongInt(bytes_written);
  end
  else
  begin
    Result := 1; // Błąd zapisu
  end;
end;

procedure set_rich_text_bullets(Handle: HWND; Enable: Boolean);
const
  // Stałe sterujące formatowaniem akapitu
  PFM_NUMBERING    = $00000020;
  PFM_OFFSET       = $00000004;
  PFM_STARTINDENT  = $00000001;
  PFN_BULLET       = 1;

  // Flagi dla SendMessage
  SCF_SELECTION    = $0001; // Zastosuj do zaznaczenia
  EM_SETPARAFORMAT = $0447;
var
  pf: t_av_para_format; // Używamy Twojej nazwy typu z modułu
begin
  if Handle = 0 then Exit;

    // Zerujemy rekord i ustawiamy rozmiar (bardzo ważne dla WinAPI)
    FillChar(pf, SizeOf(pf), 0);
    pf.cb_size := SizeOf(pf);

    // Maskujemy to, co chcemy zmienić
    pf.dw_mask := PFM_NUMBERING or PFM_STARTINDENT or PFM_OFFSET;

    if Enable then
    begin
      pf.w_numbering := PFN_BULLET;
      pf.dx_offset := 360;       // Odstęp tekstu od kropki
      pf.dx_start_indent := 360; // Wcięcie całego akapitu
    end
    else
    begin
      pf.w_numbering := 0; // Wyłączenie punktora
      pf.dx_offset := 0;
      pf.dx_start_indent := 0;
    end;

    // Wysyłamy do RichEdit z flagą SCF_SELECTION
    SendMessage(Handle, EM_SETPARAFORMAT, SCF_SELECTION, LPARAM(@pf));
end;

procedure rich_text_undo(Handle: HWND);
const
  EM_CANUNDO = $00C6;
  EM_UNDO    = $00C7;
begin
    if Handle = 0 then Exit;
    // Sprawdzamy, czy jest co cofnąć
    if SendMessage(Handle, EM_CANUNDO, 0, 0) <> 0 then
      SendMessage(Handle, EM_UNDO, 0, 0);
end;

procedure rich_text_redo(Handle: HWND);
const
  EM_CANREDO = $0455; // WM_USER + 85
  EM_REDO    = $0454; // WM_USER + 84
begin
    if Handle = 0 then Exit;
      // Sprawdzamy, czy jest co przywrócić
    if SendMessage(Handle, EM_CANREDO, 0, 0) <> 0 then
      SendMessage(Handle, EM_REDO, 0, 0);
end;

procedure load_rich_text_from_file(h_rich_edit: HWND; const file_path: UnicodeString);
var
  file_h: HANDLE;
  edit_stream: TEditStream;
begin
    // KLUCZOWE: Czyścimy strukturę przed użyciem
  FillChar(edit_stream, SizeOf(edit_stream), 0);

  edit_stream.dwCookie    := DWORD_PTR(file_h);
  edit_stream.pfnCallback := @edit_stream_in_callback;

  SendMessageW(h_rich_edit, EM_STREAMIN, 2, LPARAM(@edit_stream));

   if h_rich_edit = 0 then Exit; // Zabezpieczenie przed zerowym uchwytem

  file_h := CreateFileW(PWideChar(file_path), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if file_h = INVALID_HANDLE_VALUE then
  begin
    // Debug: jeśli plik się nie otwiera, błędu 216 nie będzie, ale nic nie wczytasz
    Exit;
  end;

  try
    FillChar(edit_stream, SizeOf(edit_stream), 0); // Zerujemy całą strukturę!
    edit_stream.dwCookie    := DWORD_PTR(file_h);
    edit_stream.pfnCallback := @edit_stream_in_callback;

    // Zamiast 2, użyjemy jawnej stałej SF_RTF
    SendMessageW(h_rich_edit, EM_STREAMIN, 2, LPARAM(@edit_stream));
  finally
    CloseHandle(file_h);
  end;
end;

procedure save_rich_text_to_file(handle: HWND; const filename: UnicodeString);
const
EM_STREAMOUT = $044A;
SF_RTF       = $0002;
SF_TEXT      = $0001;
var
file_h: HANDLE;
es: TEditStream;
flags: DWORD;
ext: UnicodeString;
begin
   if handle = 0 then Exit;

  // 1. Otwieramy/Tworzymy plik przez czyste WinAPI
  file_h := CreateFileW(
    PWideChar(filename),
    GENERIC_WRITE,
    0,
    nil,
    CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    0
  );

  if file_h = INVALID_HANDLE_VALUE then
  begin
    MessageBoxW(0, 'Nie można utworzyć pliku!', 'Błąd', MB_ICONERROR);
    Exit;
  end;

  try
    // 2. Zerujemy strukturę i ustawiamy parametry
    FillChar(es, SizeOf(es), 0);
    es.dwCookie := DWORD_PTR(file_h);
    es.pfnCallback := @edit_stream_out_callback; // Upewnij się, że ma PLongInt!

    // 3. Wybór formatu na podstawie rozszerzenia
    ext := extract_file_ext(filename);
    if same_text(ext, '.txt') then
      flags := SF_TEXT
    else
      flags := SF_RTF; // Bez SFF_SELECTION, aby zapisać całość

    // 4. Wysyłamy dane do pliku
    SendMessageW(handle, EM_STREAMOUT, flags, LPARAM(@es));

    if es.dwError <> 0 then
      MessageBoxW(0, 'Wystąpił błąd podczas strumieniowania danych.', 'Błąd', MB_ICONERROR);

  finally
    // 5. Zamykamy uchwyt pliku
    CloseHandle(file_h);
  end;
end;

function find_rich_text(handle: HWND; const search_str: UnicodeString;
  start_pos: Integer; match_case, whole_word: Boolean): Integer;
const
EM_FINDTEXTEXW = $047C;
FR_DOWN        = $00000001;
FR_WHOLEWORD   = $00000002;
FR_MATCHCASE   = $00000004;
var
find_ex: TFindTextExW;
flags: DWORD;
begin
 Result := -1;
  if (handle = 0) or (search_str = '') then Exit;

  // Czyścimy strukturę
  FillChar(find_ex, SizeOf(find_ex), 0);

  // Ustawiamy zakres wyszukiwania
  find_ex.chrg.cpMin := start_pos;
  find_ex.chrg.cpMax := -1; // Szukaj do końca dokumentu
  find_ex.lpstrText := PWideChar(search_str);

  // Flagi wyszukiwania
  flags := FR_DOWN;
  if match_case then flags := flags or FR_MATCHCASE;
  if whole_word then flags := flags or FR_WHOLEWORD;

  // Wysyłamy zapytanie. SendMessage zwróci pozycję lub -1.
  Result := SendMessageW(handle, EM_FINDTEXTEXW, flags, LPARAM(@find_ex));
end;

procedure select_rich_text(h_rich: HWND; start_pos, len: Integer);
const
  EM_EXSETSEL    = $0437;
  EM_SCROLLCARET = $00B7;
var
  cr: TCharRange;
begin
  if h_rich = 0 then Exit;

    // Ustawiamy zakres zaznaczenia
    cr.cpMin := start_pos;
    cr.cpMax := start_pos + len;

    //Wysyłamy komunikat, który podświetla tekst na niebiesko
    SendMessageW(h_rich, EM_EXSETSEL, 0, LPARAM(@cr));

    // Bardzo ważne: przewijamy dokument do kursora,
    // aby znaleziony tekst nie był "poza ekranem"
    SendMessageW(h_rich, EM_SCROLLCARET, 0, 0);
end;

function is_rich_text_bold(Handle: HWND): Boolean;
const
  EM_GETCHARFORMAT = $043A;
  SCF_SELECTION    = $0001;
  CFM_BOLD         = $00000001;
  CFE_BOLD         = $00000001;
var
  format: t_av_char_format;
begin
   Result := False;
  if handle = 0 then Exit;

  // Zerujemy i ustawiamy rozmiar korzystając z Twoich nazw pól
  FillChar(format, SizeOf(format), 0);
  format.cb_size := SizeOf(format);

  // Pobieramy formatowanie
  SendMessageW(handle, EM_GETCHARFORMAT, SCF_SELECTION, LPARAM(@format));

  // Sprawdzamy maskę i efekty (Twoje nazwy: dw_mask i dw_effects)
  if (format.dw_mask and CFM_BOLD) <> 0 then
  begin
    Result := (format.dw_effects and CFE_BOLD) <> 0;
  end;
end;

procedure set_rich_text_font_size(handle: HWND; size_points: Integer);
const
  EM_SETCHARFORMAT = $0444;
  SCF_SELECTION    = $0001;
  CFM_SIZE         = $80000000;
var
  cf: t_av_char_format;
begin
 if handle = 0 then Exit;

  // Zerujemy strukturę i ustawiamy rozmiar
  FillChar(cf, SizeOf(cf), 0);
  cf.cb_size := SizeOf(cf);

  // Maska mówi systemowi: "Zmieniaj tylko rozmiar czcionki"
  cf.dw_mask := CFM_SIZE;

  // Przeliczamy punkty na Twipsy (1 pt = 20 twips)
  cf.y_height := size_points * 20;

  // Wysyłamy formatowanie do zaznaczonego tekstu (SCF_SELECTION)
  SendMessageW(handle, EM_SETCHARFORMAT, SCF_SELECTION, LPARAM(@cf));
end;

procedure set_rich_text_font_size_all(handle: HWND; size_points: Integer;
  all_text: Boolean);
const
  EM_SETCHARFORMAT = $0444;
  SCF_SELECTION    = $0001;
  SCF_ALL          = $0004;
  CFM_SIZE         = $80000000;
var
  cf: t_av_char_format;
  flags: WPARAM;
begin
 if handle = 0 then Exit;

   FillChar(cf, SizeOf(cf), 0);
   cf.cb_size := SizeOf(cf);
   cf.dw_mask := CFM_SIZE;
   cf.y_height := size_points * 20;

   if all_text then
     flags := SCF_ALL
   else
     flags := SCF_SELECTION;

   // Sprawdźmy wynik SendMessage. Jeśli zwróci 0, oznacza to błąd.
   if SendMessageW(handle, EM_SETCHARFORMAT, flags, LPARAM(@cf)) = 0 then
   begin
     // Tutaj możesz dodać debug, jeśli funkcja nadal nie reaguje
   end;
end;

procedure set_rich_text_font_name(handle: HWND; const font_name: UnicodeString);
const
  EM_SETCHARFORMAT = $0444;
  SCF_SELECTION    = $0001;
  CFM_FACE         = $20000000;
var
  cf: t_av_char_format;
  i, len: Integer;
begin
  if (handle = 0) or (font_name = '') then Exit;

  //Przygotowanie struktury
  FillChar(cf, SizeOf(cf), 0);
  cf.cb_size := SizeOf(cf);
  cf.dw_mask := CFM_FACE;

  // Bezpieczne kopiowanie nazwy czcionki (sz_face_name ma rozmiar 32)
  len := Length(font_name);
  if len > 31 then len := 31;

  for i := 1 to len do
    cf.sz_face_name[i - 1] := font_name[i];


  // Wysłanie komunikatu do zaznaczenia
  SendMessageW(handle, EM_SETCHARFORMAT, SCF_SELECTION, LPARAM(@cf));
end;

procedure reset_to_standard_font(handle: HWND);
begin
  set_rich_text_font_name(handle, 'Segoe UI');
  set_rich_text_font_size(handle, 11);
end;

function is_rich_text_style_active(handle: HWND; style_to_check: Integer): Boolean;
Const
EM_GETCHARFORMAT = $043A;
SCF_SELECTION    = $0001;
// Maski i efekty (zazwyczaj są identyczne dla tych stylów)
CFM_BOLD         = $00000001;
CFM_ITALIC       = $00000002;
CFM_UNDERLINE    = $00000004;
CFE_BOLD         = $00000001;
CFE_ITALIC       = $00000002;
CFE_UNDERLINE    = $00000004;
var
cf: t_av_char_format;
mask_val, effect_val: DWORD;
begin
 Result := False;
  if handle = 0 then Exit;

  // 1. Przygotowanie Twojej struktury
  FillChar(cf, SizeOf(cf), 0);
  cf.cb_size := SizeOf(cf);

  // 2. Pobranie formatowania
  SendMessageW(handle, EM_GETCHARFORMAT, SCF_SELECTION, LPARAM(@cf));

  // 3. Mapowanie parametrów na flagi WinAPI
  case style_to_check of
    1: begin mask_val := CFM_BOLD;      effect_val := CFE_BOLD;      end; // Bold
    2: begin mask_val := CFM_ITALIC;    effect_val := CFE_ITALIC;    end; // Italic
    4: begin mask_val := CFM_UNDERLINE; effect_val := CFE_UNDERLINE; end; // Underline
    else Exit;
  end;

  // 4. Sprawdzenie logiczne
  // Sprawdzamy dw_mask, aby wiedzieć, czy styl jest spójny w zaznaczeniu
  // Jeśli zaznaczenie jest "mieszane" (pół-bold), bit w dw_mask będzie zerem.
  if (cf.dw_mask and mask_val) <> 0 then
  begin
    // Jeśli maska potwierdza spójność, sprawdzamy czy efekt jest włączony
    Result := (cf.dw_effects and effect_val) <> 0;
  end;
end;

procedure set_rich_text_zoom(handle: HWND; numerator, denominator: Integer);
const
  EM_SETZOOM = $04E1;
begin
  if handle = 0 then Exit;

    // W systemie Windows specjalna kombinacja 0/0 resetuje zoom do 100%
    // Jeśli użytkownik poda denominator = 0, a numerator > 0, poprawiamy to na 1.
    if (denominator = 0) and (numerator <> 0) then
      denominator := 1;

    // Wysyłamy komunikat. System oblicza powiększenie jako numerator / denominator.
    // Przykład: 2/1 to 200%, 1/2 to 50%.
    SendMessageW(handle, EM_SETZOOM, WPARAM(numerator), LPARAM(denominator));
end;

procedure set_rich_text_zoom_percent(handle: HWND; percent: Integer);
begin
   if handle = 0 then Exit;

  // Obsługa resetu i wartości nieprawidłowych
  // W RichEdit kombinacja 0/0 to powrót do 100%
  if percent <= 0 then
  begin
    set_rich_text_zoom(handle, 0, 0);
  end
  else
  begin
    // 2. Ograniczenie systemowe (RichEdit zazwyczaj obsługuje od 1% do 6400%)
    if percent > 6400 then percent := 6400;

    // 3. Ustawienie ułamka (np. 125/100 dla 125%)
    set_rich_text_zoom(handle, percent, 100);
  end;
end;

procedure set_rich_text_auto_url(handle: HWND; enable: Boolean);
const
  EM_AUTOURLDETECT = $045B;
  EM_SETEVENTMASK  = $0445;
  ENM_LINK         = $00000020; // Maska powiadomień o linkach
var
event_mask: LRESULT;
begin
   if handle = 0 then Exit;

    // 1. Włączamy/Wyłączamy samą detekcję (zmiana koloru i kursora nad linkiem)
    if enable then
      SendMessageW(handle, EM_AUTOURLDETECT, 1, 0)
    else
      SendMessageW(handle, EM_AUTOURLDETECT, 0, 0);

    // 2. Kluczowy krok: informujemy RichEdit, że chcemy otrzymywać powiadomienia EN_LINK
    // Najpierw pobieramy obecną maskę, żeby niczego nie zepsuć
    event_mask := SendMessageW(handle, EM_SETEVENTMASK, 0, 0);

    if enable then
      event_mask := event_mask or ENM_LINK
    else
      event_mask := event_mask and not ENM_LINK;

    SendMessageW(handle, EM_SETEVENTMASK, 0, event_mask);
end;

procedure get_rich_text_caret_pos(handle: HWND; var line, col: Integer);
const
EM_EXLINEFROMCHAR = $0436;
EM_LINEINDEX      = $00BB;
EM_GETSEL         = $00B0;
var
selection_start: DWORD;
line_index: LRESULT;
res_line: LRESULT;
begin
  line := 1;
  col := 1;
  if handle = 0 then Exit;

  //  Pobieramy pozycję znaku, na której jest kursor
  // EM_GETSEL zwraca start w WPARAM i koniec w LPARAM
  SendMessageW(handle, EM_GETSEL, WPARAM(@selection_start), 0);

  // Obliczamy indeks linii (0-based) na podstawie pozycji znaku
  line := SendMessageW(handle, EM_EXLINEFROMCHAR, 0, LPARAM(selection_start));

  // Pobieramy indeks znaku, który zaczyna tę linię
  line_index := SendMessageW(handle, EM_LINEINDEX, WPARAM(res_line), 0);

  // 4. Obliczamy kolumnę i konwertujemy na format 1-based
  line := Integer(res_line) + 1;
  col  := Integer(selection_start - line_index) + 1;

  // Konwersja na format przyjazny dla człowieka (liczenie od 1)
  Inc(line);
  Inc(col);
end;

procedure goto_rich_text_line(handle: HWND; line_num: Integer);
const
  EM_LINEINDEX    = $00BB;
  EM_SETSEL       = $00B1;
  EM_SCROLLCARET  = $00B7;
var
  char_index: LRESULT;
begin
  if handle = 0 then Exit;
    if line_num < 1 then line_num := 1;
    // Pobieramy indeks znaku, który zaczyna daną linię (0-based)
    // Jeśli podasz numer większy niż liczba linii, zwróci -1
    char_index := SendMessageW(handle, EM_LINEINDEX, WPARAM(line_num - 1), 0);

    if char_index <> -1 then
    begin
      // Ustawiamy kursor (zaznaczenie o długości 0) na początku tej linii
      SendMessageW(handle, EM_SETSEL, WPARAM(char_index), LPARAM(char_index));

      // Przewijamy widok do kursora, aby linia była widoczna
      SendMessageW(handle, EM_SCROLLCARET, 0, 0);

      //Opcjonalnie: Ustawienie fokusu na kontrolkę
      SetFocus(handle);
    end;
end;

function get_rich_text_line_count(handle: HWND): Integer;
const
  EM_GETLINECOUNT = $00BA;
begin
  Result := 0;
    if handle = 0 then Exit;
    // EM_GETLINECOUNT zwraca liczbę linii w kontrolce.
    // Nawet jeśli tekst jest pusty, wynik wyniesie 1.
    Result := SendMessageW(handle, EM_GETLINECOUNT, 0, 0);
end;

function get_rich_text_selection_length(handle: HWND): Integer;
const
  EM_EXGETSEL = $0434;
var
  cr: t_av_char_range;
begin
  Result := 0;
    if handle = 0 then Exit;

    // Pobieramy zakres zaznaczenia (początek i koniec)
    // Struktura t_av_char_range (cp_min, cp_max) musi być w sekcji Core
    SendMessageW(handle, EM_EXGETSEL, 0, LPARAM(@cr));

    // Długość to różnica między końcem a początkiem
    // Używamy Abs(), ponieważ w specyficznych warunkach WinAPI
    // kolejność min/max może zależeć od kierunku zaznaczania myszką
    Result := Abs(cr.cp_max - cr.cp_min);
end;

procedure change_rich_text_indent(handle: HWND; increase: Boolean);
const
  EM_GETPARAFORMAT = $043D;
  EM_SETPARAFORMAT = $0447;
  PFM_STARTINDENT  = $00000001;
  INDENT_STEP      = 300;
var
pf: t_av_para_format;
begin
   if handle = 0 then Exit;

  // 1. Inicjalizacja struktury
  FillChar(pf, SizeOf(pf), 0);
  pf.cb_size := SizeOf(pf);

  // 2. Pobranie aktualnego formatu akapitu
  // Używamy SendMessageW dla spójności z resztą Avocado
  SendMessageW(handle, EM_GETPARAFORMAT, 0, LPARAM(@pf));

  // 3. Modyfikacja wcięcia
  pf.dw_mask := PFM_STARTINDENT;

  if increase then
  begin
    pf.dx_start_indent := pf.dx_start_indent + INDENT_STEP;
  end
  else
  begin
    pf.dx_start_indent := pf.dx_start_indent - INDENT_STEP;
    // Zabezpieczenie: wcięcie nie może być ujemne
    if pf.dx_start_indent < 0 then pf.dx_start_indent := 0;
  end;

  // 4. Resetujemy offset (ważne dla poprawnego wyświetlania list/kropek)
  pf.dx_offset := 0;

  // 5. Zastosowanie nowych ustawień
  SendMessageW(handle, EM_SETPARAFORMAT, 0, LPARAM(@pf));
end;

function handle_drop_files(handle: HWND; drop_info: WPARAM): UnicodeString;
var
my_drop: HDROP;
file_count: UINT;
i: UINT;
file_path: array[0..MAX_PATH] of WideChar;
begin
  if drop_info = 0 then Exit;
  my_drop := HDROP(drop_info);

  try
    //Pobieramy całkowitą liczbę upuszczonych plików
    file_count := DragQueryFileW(my_drop, $FFFFFFFF, nil, 0);

    for i := 0 to file_count - 1 do
    begin
      // Pobieramy ścieżkę każdego pliku po kolei
      if DragQueryFileW(my_drop, i, file_path, MAX_PATH) > 0 then
      begin
        // Logika otwierania - np. pierwszy plik w bieżącym oknie,
        // reszta w nowych (jeśli Avocado to wspiera)
        if i = 0 then
          load_rich_text_from_file(handle, UnicodeString(file_path))
      end;
    end;
  finally
    // zwalniamy uchwyt dropu
    DragFinish(my_drop);
  end;
end;

function get_rich_text_text(handle: HWND): UnicodeString;
const
  WM_GETTEXT       = $000D;
  WM_GETTEXTLENGTH = $000E;
var
  len: LRESULT;
  raw_text: UnicodeString;
begin
 Result := '';
  if handle = 0 then Exit;

  //  Pobieramy długość tekstu
  len := SendMessageW(handle, WM_GETTEXTLENGTH, 0, 0);

  if len > 0 then
  begin
    // Pobieramy "surowy" tekst z RichEdit (z samymi #13)
    SetLength(raw_text, len);
    SendMessageW(handle, WM_GETTEXT, WPARAM(len + 1), LPARAM(PWideChar(raw_text)));

    // Konwersja zakończeń linii na standard Windows (CRLF)
    // AdjustLineBreaks to potężna funkcja systemowa, która robi to za Ciebie
    Result := av_adjust_line_breaks(raw_text);
  end;
end;

procedure set_rich_text_text(handle: HWND; const text: UnicodeString);
const
  WM_SETTEXT = $000C;
begin
  if handle = 0 then Exit;
    SendMessageW(handle, WM_SETTEXT, 0, LPARAM(PWideChar(text)));
end;

procedure insert_rich_text_at_cursor(handle: HWND; const a_text: string);
const
  EM_REPLACESEL = $00C2;
var
  w_str: UnicodeString;
begin
 if handle = 0 then Exit;

  // Konwertujemy tekst z UTF-8 na format Windowsowy Unicode (UTF-16)
  // Robimy to jawnie, aby mieć pewność co do kodowania polskich znaków
  w_str := UnicodeString(a_text);

  //  Wstawiamy tekst w miejsce kursora
  // WPARAM = 1 oznacza, że operację można cofnąć (Undo - Ctrl+Z)
  // LPARAM = wskaźnik na nasz skonwertowany tekst
  SendMessageW(handle, EM_REPLACESEL, 1, LPARAM(PWideChar(w_str)));
end;

procedure install_avocado_rich_edit_subclass(h_rich: HWND);
const
  GWLP_WNDPROC = -4;
begin
 if h_rich = 0 then Exit;
   old_rich_edit_proc := WNDPROC(GetWindowLongPtrW(h_rich, GWLP_WNDPROC));
   SetWindowLongPtrW(h_rich, GWLP_WNDPROC, LONG_PTR(@avocado_rich_edit_proc));
end;


end.


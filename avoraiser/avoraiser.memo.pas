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

Module:     avoraiser.memo
Description:
*)

unit avoraiser.memo;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core, avoraiser.utils;
//Wstawianie tekstu w miejsce kursora
procedure insert_text_at_cursor(hMemo: HWND; const Text: string);

//Sprawdzanie, czy tekst został zmieniony (Modified)
function is_memo_modified(hMemo: HWND): Boolean;

procedure set_memo_modified(hMemo: HWND; Modified: Boolean);
//Liczenie linii i znaków
function get_memo_line_count(hMemo: HWND): Integer;
function get_memo_text_length(hMemo: HWND): Integer;

//Pozwala ona zablokować edycję tekstu
procedure set_memo_read_only(hMemo: HWND; ReadOnly: Boolean);
//Limit znaków w memo
procedure set_memo_limit(hMemo: HWND; MaxChars: DWORD);
//Glowna funkcja tworzenia memo
function create_memo(Parent: HWND; X, Y, Width, Height: Integer): HWND;

function get_memo_text(hMemo: HWND): string;
procedure append_memo_text(hMemo: HWND; const Text: string);
//Ta funkcja po prostu zastępuje całą treść w Memo nowym tekstem.
procedure set_memo_text(h_memo: HWND; const a_text: UnicodeString);
function load_memo_from_file(h_memo: HWND; const file_path: UnicodeString): Boolean;
//Zapisywanie tekstu z memo do pliku
function write_string_to_file(const file_path: UnicodeString; const content: UnicodeString): Boolean;
// Włącza (True) lub wyłącza (False) dodawanie znaków końca linii przy zawijaniu wierszy
procedure set_memo_fmt_lines(Handle: HWND; AddBreaks: Boolean);
// Limit: 0 = Maksymalny możliwy (ok. 2 miliardy znaków).
procedure set_memo_limit(Handle: HWND; Limit: Integer);

// nawigacja (scrolling)
// Przewija widok.
// Direction: SB_LINEDOWN (1), SB_LINEUP (0), SB_PAGEDOWN (3), SB_PAGEUP (2)
procedure scroll_memo(Handle: HWND; Direction: Integer);
// Przesuwa widok tak, aby kursor był widoczny
procedure scroll_memo_to_caret(Handle: HWND);
// Przewija na sam koniec (Auto-Scroll, np. w logach)
procedure scroll_memo_to_end(Handle: HWND);
// informacje o tekście
// Zwraca liczbę linii (zawsze minimum 1, nawet jak pusty)
function get_line_count(Handle: HWND): Integer;
// Zwraca indeks znaku, od którego zaczyna się dana linia
// line_index: numer linii od 0. (-1 = linia, w której jest kursor)
function get_line_index(handle: HWND; line_index: Integer): Integer;
// Zwraca długość linii w znakach
// char_index: indeks dowolnego znaku w tej linii (lub -1 dla obecnej linii)
// UWAGA: WinAPI wymaga tu indeksu znaku, a nie numeru linii!
function get_line_length(handle: HWND; char_index: Integer): Integer;
// Pobiera treść całej linii jako String
function get_line_text(handle: HWND; line_index: Integer): string;

implementation


procedure insert_text_at_cursor(hMemo: HWND; const Text: string);
var
  WStr: UnicodeString;
begin
  if hMemo = 0 then Exit;
  WStr := UnicodeString(Text);
  SendMessageW(hMemo, EM_REPLACESEL, 1, LPARAM(PWideChar(WStr)));
end;

function is_memo_modified(hMemo: HWND): Boolean;
begin
  Result := SendMessage(hMemo, EM_GETMODIFY, 0, 0) <> 0;
end;

procedure set_memo_modified(hMemo: HWND; Modified: Boolean);
begin
  SendMessage(hMemo, EM_SETMODIFY, WPARAM(Modified), 0);
end;

function get_memo_line_count(hMemo: HWND): Integer;
begin
   Result := SendMessage(hMemo, EM_GETLINECOUNT, 0, 0);
end;

function get_memo_text_length(hMemo: HWND): Integer;
begin
   Result := SendMessage(hMemo, WM_GETTEXTLENGTH, 0, 0);
end;

procedure set_memo_read_only(hMemo: HWND; ReadOnly: Boolean);
begin
   // WParam = 1 (Tylko do odczytu), 0 (Edytowalne)
   SendMessage(hMemo, EM_SETREADONLY, Ord(ReadOnly), 0);
end;

procedure set_memo_limit(hMemo: HWND; MaxChars: DWORD);
begin
  SendMessage(hMemo, EM_LIMITTEXT, MaxChars, 0);
end;

function create_memo(Parent: HWND; X, Y, Width, Height: Integer): HWND;
var
  myHFont: HFONT;
begin
    Result := CreateWindowExW(
          0,
          'EDIT',
          '',
          WS_CHILD or WS_VISIBLE or WS_VSCROLL or
          ES_MULTILINE or ES_AUTOVSCROLL or ES_WANTRETURN,
          X, Y, Width, Height,
          Parent,
          0,
          GetModuleHandle(nil),
          nil
        );

      if Result <> 0 then
      begin
        // 1. Tworzymy czcionkę Segoe UI (rozmiar -17 odpowiada ok. 13px)
        myHFont := CreateFontW(
          -17,                        // Wysokość (nValue)
          0,                          // Szerokość
          0,                          // Kąt ucieczki
          0,                          // Kąt orientacji
          FW_NORMAL,                  // Grubość (Normalna)
          0,                          // Kursywa (False)
          0,                          // Podkreślenie (False)
          0,                          // Przekreślenie (False)
          EASTEUROPE_CHARSET,         // Kodowanie znaków (ważne dla PL znaków)
          OUT_DEFAULT_PRECIS,
          CLIP_DEFAULT_PRECIS,
          CLEARTYPE_QUALITY,          // Jakość ClearType
          VARIABLE_PITCH or FF_SWISS,
          'Segoe UI'                  // Nazwa kroju
        );

        // 2. Wysyłamy komunikat WM_SETFONT do nowej kontrolki
        // Ostatni parametr (1) wymusza natychmiastowe przerysowanie kontrolki
        if myHFont <> 0 then
          SendMessageW(Result, WM_SETFONT, WPARAM(myHFont), 1);
        // Zwiększenie limitu do ok. 214 MB (maksimum dla standardowego EDIT)
          SendMessageW(Result, EM_SETLIMITTEXT, $7FFFFFF, 0);
      end;
end;

function get_memo_text(hMemo: HWND): string;
var
  TextLen: Integer;
  WText: WideString;
begin
    Result := '';
    if hMemo = 0 then Exit;

    // Pobieramy długość tekstu (w znakach)
    TextLen := GetWindowTextLengthW(hMemo);
    if TextLen > 0 then
    begin
      // Przygotowujemy bufor (WideString dla pełnego Unicode)
      SetLength(WText, TextLen);
      // Kopiujemy tekst z kontrolki do bufora
      GetWindowTextW(hMemo, PWideChar(WText), TextLen + 1);
      Result := UTF8Encode(WText); // Konwertujemy na string (UTF-8)
    end;
end;

procedure append_memo_text(hMemo: HWND; const Text: string);
var
  WText: WideString;
begin
  if hMemo = 0 then Exit;
    WText := UnicodeString(Text + #13#10);
    // Przesuwamy kursor na koniec tekstu
    SendMessageW(hMemo, EM_SETSEL, -1, -1);
    // Wstawiamy nowy tekst
    SendMessageW(hMemo, EM_REPLACESEL, 0, LPARAM(PWideChar(WText)));
end;

procedure set_memo_text(h_memo: HWND; const a_text: UnicodeString);
const
  WM_SETTEXT = $000C;
begin
  if h_memo = 0 then Exit;
  SendMessageW(h_memo, WM_SETTEXT, 0, LPARAM(PWideChar(a_text)));
end;

function load_memo_from_file(h_memo: HWND; const file_path: UnicodeString): Boolean;
var
  content: UnicodeString;
begin
    Result := False;

    // Sprawdzamy czy okno Memo w ogóle istnieje
    if (h_memo = 0) or (not IsWindow(h_memo)) then Exit;

    content := read_file_to_string(file_path);

    // Jeśli plik nie był pusty
  if Length(content) > 0 then
  begin
    // Poprawiamy końce linii (Memo potrzebuje #13#10)
    content := av_adjust_line_breaks(content);

    // Wysyłamy tekst - PWideChar jest bezpieczny dla zainicjalizowanego stringa
    SendMessageW(h_memo, WM_SETTEXT, 0, LPARAM(PWideChar(content)));
    Result := True;
  end;
end;

function write_string_to_file(const file_path: UnicodeString;
  const content: UnicodeString): Boolean;
var
  h_file: THandle;
  bytes_written: DWORD;
  utf8_len: Integer;
  utf8_buffer: PAnsiChar;
begin
    Result := False;
      if file_path = '' then Exit;

      // Otwieramy/Tworzymy plik do zapisu (nadpisujemy istniejący)
      h_file := CreateFileW(
        PWideChar(file_path),
        GENERIC_WRITE,
        0,
        nil,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
      );

      if h_file = INVALID_HANDLE_VALUE then Exit;

      try
        if Length(content) > 0 then
        begin
          // Sprawdzamy, ile miejsca zajmie tekst po konwersji na UTF-8
          utf8_len := WideCharToMultiByte(CP_UTF8, 0, PWideChar(content), Length(content), nil, 0, nil, nil);

          if utf8_len > 0 then
          begin
            GetMem(utf8_buffer, utf8_len);
            try
              // Właściwa konwersja do bufora
              WideCharToMultiByte(CP_UTF8, 0, PWideChar(content), Length(content), utf8_buffer, utf8_len, nil, nil);

              // Zapis do pliku
              Result := WriteFile(h_file, utf8_buffer^, utf8_len, bytes_written, nil);
            finally
              FreeMem(utf8_buffer);
            end;
          end;
        end
        else
          Result := True; // Pusty plik to też poprawny zapis
      finally
        CloseHandle(h_file);
      end;
end;

procedure set_memo_fmt_lines(Handle: HWND; AddBreaks: Boolean);
begin
   if Handle <> 0 then
    SendMessage(Handle, EM_FMTLINES, WPARAM(AddBreaks), 0);
end;

procedure set_memo_limit(Handle: HWND; Limit: Integer);
const
  EM_SETLIMITTEXT = $00C5;
begin
   if Handle <> 0 then
      SendMessage(Handle, EM_SETLIMITTEXT, WPARAM(Limit), 0);
end;

procedure scroll_memo(Handle: HWND; Direction: Integer);
begin
 if Handle <> 0 then
    SendMessage(Handle, EM_SCROLL, Direction, 0);
end;

procedure scroll_memo_to_caret(Handle: HWND);
begin
  if Handle <> 0 then
    SendMessage(Handle, EM_SCROLLCARET, 0, 0);
end;

procedure scroll_memo_to_end(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    // Ustawiamy kursor na samym końcu tekstu (MaxInt)
    SendMessage(Handle, EM_SETSEL, $7FFFFFFF, $7FFFFFFF);
    // Przewijamy widok do tego kursora
    SendMessage(Handle, EM_SCROLLCARET, 0, 0);
  end;

end;

function get_line_count(Handle: HWND): Integer;
begin
  if Handle <> 0 then
      Result := SendMessage(Handle, EM_GETLINECOUNT, 0, 0)
    else
      Result := 0;
end;

function get_line_index(handle: HWND; line_index: Integer): Integer;
begin
  if handle <> 0 then
    Result := SendMessage(handle, EM_LINEINDEX, line_index, 0)
  else
    Result := 0;
end;

function get_line_length(handle: HWND; char_index: Integer): Integer;
begin
  if handle <> 0 then
    Result := SendMessage(handle, EM_LINELENGTH, char_index, 0)
  else
    Result := 0;
end;

function get_line_text(handle: HWND; line_index: Integer): string;
var
  len, char_idx: Integer;
  buffer: array of WideChar;
begin
  Result := '';
    if handle = 0 then Exit;
    char_idx := get_line_index(handle, line_index);
    len := get_line_length(handle, char_idx);

    if len > 0 then
    begin
      SetLength(buffer, len + 1);
      PWord(@buffer[0])^ := len + 1;
      SendMessage(handle, EM_GETLINE, line_index, LPARAM(@buffer[0]));
      SetString(Result, PWideChar(@buffer[0]), len);
    end;
end;

end.


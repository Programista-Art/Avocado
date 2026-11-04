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

Module:     avoraiser.listbox
Description:
*)

unit avoraiser.listbox;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core, avoraiser.utils;

function create_listbox(Parent: HWND; X, Y, Width, Height: Integer): HWND;

// Zarządzanie danymi
procedure list_add(h_list: HWND; const text: string);
procedure list_insert(h_list: HWND; index: Integer; const text: string);
function list_delete(h_list: HWND; index: Integer): Integer;
procedure list_delete_selected(h_list: HWND);
procedure list_clear(h_list: HWND);

// Informacje
function list_count(h_list: HWND): Integer;
function list_get_index(h_list: HWND): Integer;
function list_get_text(h_list: HWND): string;
function list_find(h_list: HWND; const text: string): Integer;

// Ukryte dane (ID)
procedure list_set_data(h_list: HWND; index: Integer; value: Integer);
function list_get_data(h_list: HWND; index: Integer): Integer;
function list_get_selected_data(h_list: HWND): Integer;

// Wygląd
procedure set_listbox_selection_color(Handle: HWND; TextColor, BgColor: DWORD);
procedure set_listbox_colors(Handle: HWND; TextCol, BgCol, SelTextCol, SelBgCol: DWORD);
procedure list_begin_update(h_list: HWND);
procedure list_end_update(h_list: HWND);
procedure draw_listbox_item(mylparam: LPARAM);

implementation

uses
  avoraiser.window; // Tu jest draw_avocado_border

// Deklaracja forward, bo używamy jej w ParentProc
//procedure draw_listbox_item(l_param: LPARAM); forward;

// --- 1. NOWOŚĆ: PROCEDURA RODZICA (Hook na okno główne) ---
// Ta procedura "siedzi" na oknie głównym i wyłapuje komunikaty dla ListBoxa
function listbox_parent_proc(hwnd: HWND; msg: UINT; wparam: WPARAM; lparam: LPARAM;
  u_id_subclass: UINT_PTR; dwrefdata: DWORD_PTR): LRESULT; stdcall;
var
  dis: PDrawItemStruct;
  my_listbox_handle: HWND;
begin
  // Odczytujemy uchwyt naszego ListBoxa (przekazany jako dwRefData przy tworzeniu)
  //my_listbox_handle := HWND(dw_ref_data);
   my_listbox_handle := PtrUInt(dwrefdata);
  //my_listbox_handle := HWND(dw_ref_data);

  case msg of
    // Wyłapujemy WM_DRAWITEM (Rysowanie elementu)
    WM_DRAWITEM:
    begin
      dis := PDrawItemStruct(lparam);
      // Sprawdzamy: Czy to rysowanie dotyczy TEGO konkretnego ListBoxa?
      if dis^.hwndItem = my_listbox_handle then
      begin
        draw_listbox_item(lparam);
        Result := 1; // Zgłaszamy: Obsłużono!
        Exit;
      end;
    end;

    // Wyłapujemy WM_DELETEITEM (Sprzątanie przy usuwaniu elementu)
    WM_DELETEITEM:
    begin
       // Jeśli to nasz ListBox, zwracamy True
       if PDeleteItemStruct(lparam)^.hwndItem = my_listbox_handle then
       begin
         Result := 1;
         Exit;
       end;
    end;

    // Opcjonalnie: Zmiana koloru suwaka lub tła (WM_CTLCOLORLISTBOX)
    WM_CTLCOLORLISTBOX:
    begin
       if lparam = my_listbox_handle then
       begin
          // Tutaj można zwrócić pędzel tła, jeśli draw_listbox_item nie wystarcza
          // Ale przy OwnerDraw zazwyczaj nie jest to konieczne.
       end;
    end;
  end;

  // Wszystkie inne komunikaty puszczamy dalej do Rodzica
  Result := DefSubclassProc(hwnd, msg, wparam, lparam);
end;


// --- 2. PROCEDURA LISTBOXA (Własne zachowanie kontrolki) ---
function listbox_proc(hwnd: HWND; msg: UINT; w_param: WPARAM; l_param: LPARAM;
  u_id_subclass: UINT_PTR; dw_ref_data: DWORD_PTR): LRESULT; stdcall;
var
  dc: HDC;
  r: TRect;
  brush: HBRUSH;
  bg_color, prop_val: DWORD;
  parent_handle: HWND;
  my_listbox_handle: HWND;
begin
  // Rzutujemy bezpiecznie: DWORD_PTR -> THandle -> HWND
  my_listbox_handle := THandle(dw_ref_data);
  case msg of
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_MOUSEMOVE, WM_KEYDOWN, WM_KEYUP:
    begin
      Result := DefSubclassProc(hwnd, msg, w_param, l_param);
      draw_border(hwnd);
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      dc := HDC(w_param);
      GetClientRect(hwnd, r);
      prop_val := DWORD(GetProp(hwnd, AV_LIST_BG_COLOR));
      if prop_val <> 0 then bg_color := prop_val - 1 else bg_color := $121212;
      brush := CreateSolidBrush(bg_color);
      FillRect(dc, r, brush);
      DeleteObject(brush);
      Result := 1;
      Exit;
    end;

    WM_NCCALCSIZE:
    begin
      if w_param <> 0 then
      begin
        with PRect(l_param)^ do
        begin
          Left   := Left + 1;
          Top    := Top + 1;
          Right  := Right - 1;
          Bottom := Bottom - 1;
        end;
        Result := 0;
        Exit;
      end;
    end;

    WM_NCPAINT, WM_SETFOCUS, WM_KILLFOCUS:
    begin
      Result := DefSubclassProc(hwnd, msg, w_param, l_param);
      draw_border(hwnd);
      Exit;
    end;

    // --- SPRZĄTANIE ---
    WM_NCDESTROY:
    begin
      // 1. Odpinamy procedurę LISTBOXA
      RemoveWindowSubclass(hwnd, SUBCLASSPROC(@listbox_proc), u_id_subclass);

      // 2. WAŻNE: Odpinamy procedurę RODZICA!
      // Musimy pobrać rodzica, żeby wiedzieć z kogo zdjąć hooka.
      parent_handle := GetParent(hwnd);
      if parent_handle <> 0 then
      begin
         // Jako ID podajemy uchwyt listboxa (hwnd), tak jak przy tworzeniu
         RemoveWindowSubclass(parent_handle, SUBCLASSPROC(@listbox_parent_proc), UINT_PTR(hwnd));
      end;

      // 3. Usuwamy właściwości
      RemoveProp(hwnd, AV_LIST_BG_COLOR);
      RemoveProp(hwnd, AV_LIST_TEXT_COLOR);
      RemoveProp(hwnd, AV_LIST_SEL_BG);
      RemoveProp(hwnd, AV_LIST_SEL_TEXT);
    end;
  end;

  Result := DefSubclassProc(hwnd, msg, w_param, l_param);

  if msg = WM_PAINT then
    draw_border(hwnd);
end;

// --- TWORZENIE (Instalacja obu hooków) ---

function create_listbox(Parent: HWND; X, Y, Width, Height: Integer): HWND;
begin
  // LBS_OWNERDRAWFIXED: My rysujemy, ale każdy wiersz ma stałą wysokość
  // LBS_HASSTRINGS: ListBox przechowuje tekst (inaczej musiałbyś zarządzać pamięcią)
  // LBS_NOINTEGRALHEIGHT: ListBox może mieć dowolną wysokość (nie ucina do pełnego wiersza)
  Result := CreateWindowExW(
    0,
    'LISTBOX', nil,
    WS_VISIBLE or
    WS_CHILD or
    WS_VSCROLL or
    WS_TABSTOP or
    LBS_NOTIFY or
    LBS_OWNERDRAWFIXED or
    LBS_HASSTRINGS or
    LBS_NOINTEGRALHEIGHT or
    WS_BORDER,
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );

  if Result <> 0 then
  begin
    // Ustawiamy wysokość wiersza (np. 24 piksele - wygodne dla palca/myszy)
    SendMessage(Result, LB_SETITEMHEIGHT, 0, 14);

    // Domyślne kolory Avocado (Ciemne tło, Pomarańczowe zaznaczenie)
   set_listbox_colors(Result, $FFFFFF, $121212, $000000, $00FF965F);
                            // Kolor czcionki tla  Kolor tekstu
   //set_listbox_colors(Result, $00FF6843, $121212, $00FF6843, $2D2D2D);
  end;
end;

procedure list_add(h_list: HWND; const text: string);
begin
  SendMessageW(h_list, LB_ADDSTRING, 0, LPARAM(PWideChar(UnicodeString(text))));
end;

procedure list_insert(h_list: HWND; index: Integer; const text: string);
begin
  SendMessageW(h_list, LB_INSERTSTRING, index, LPARAM(PWideChar(UnicodeString(text))));
end;

function list_delete(h_list: HWND; index: Integer): Integer;
begin
  Result := SendMessageW(h_list, LB_DELETESTRING, index, 0);
end;

procedure list_delete_selected(h_list: HWND);
var
  idx: Integer;
begin
  idx := SendMessageW(h_list, LB_GETCURSEL, 0, 0);
  if idx <> LB_ERR then
    SendMessageW(h_list, LB_DELETESTRING, idx, 0);
end;

procedure set_listbox_selection_color(Handle: HWND; TextColor, BgColor: DWORD);
begin
  if Handle = 0 then Exit;
    // Ustawiamy właściwości, które odczytuje avocado_draw_listbox_item w WM_DRAWITEM
    SetPropW(Handle, AV_PROP_SEL_TXT_COLOR, THandle(TextColor));
    SetPropW(Handle, AV_PROP_SEL_BG_COLOR,  THandle(BgColor));

    // Wymuszamy przerysowanie
    InvalidateRect(Handle, nil, True);
end;

procedure list_set_data(h_list: HWND; index: Integer; value: Integer);
begin
  SendMessageW(h_list, LB_SETITEMDATA, index, value);
end;

function list_get_data(h_list: HWND; index: Integer): Integer;
begin
  Result := SendMessageW(h_list, LB_GETITEMDATA, index, 0);
end;

function list_get_selected_data(h_list: HWND): Integer;
var
  idx: Integer;
begin
  idx := SendMessageW(h_list, LB_GETCURSEL, 0, 0);
  if idx <> LB_ERR then
    Result := list_get_data(h_list, idx)
  else
    Result := 0;
end;

procedure set_listbox_colors(Handle: HWND; TextCol, BgCol, SelTextCol,
  SelBgCol: DWORD);
begin
  // Zapisujemy wszystkie 4 kolory we właściwościach
  SetPropW(Handle, AV_PROP_TEXT_COLOR, THandle(TextCol));
  SetPropW(Handle, AV_PROP_BG_COLOR,   THandle(BgCol));
  SetPropW(Handle, AV_PROP_SEL_TXT_COLOR, THandle(SelTextCol));
  SetPropW(Handle, AV_PROP_SEL_BG_COLOR,  THandle(SelBgCol));

  InvalidateRect(Handle, nil, True);
end;

procedure list_begin_update(h_list: HWND);
begin
  SendMessageW(h_list, WM_SETREDRAW, 0, 0);
end;

procedure list_end_update(h_list: HWND);
begin
  SendMessageW(h_list, WM_SETREDRAW, 1, 0);
  RedrawWindow(h_list, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

function list_find(h_list: HWND; const text: string): Integer;
begin
  Result := SendMessageW(h_list, LB_FINDSTRINGEXACT, -1, LPARAM(PWideChar(UnicodeString(text))));
end;

function list_count(h_list: HWND): Integer;
begin
  Result := SendMessageW(h_list, LB_GETCOUNT, 0, 0);
end;

procedure list_clear(h_list: HWND);
begin
  SendMessageW(h_list, LB_RESETCONTENT, 0, 0);
end;

function list_get_index(h_list: HWND): Integer;
begin
  Result := SendMessageW(h_list, LB_GETCURSEL, 0, 0);
end;

function list_get_text(h_list: HWND): string;
var
  idx, len: Integer;
  buffer: array of WideChar;
begin
  Result := '';
  idx := SendMessageW(h_list, LB_GETCURSEL, 0, 0);
  if idx <> LB_ERR then
  begin
    len := SendMessageW(h_list, LB_GETTEXTLEN, idx, 0);
    if len > 0 then
    begin
      SetLength(buffer, len + 1);
      SendMessageW(h_list, LB_GETTEXT, idx, LPARAM(@buffer[0]));
      Result := WideCharToString(@buffer[0]);
    end;
  end;
end;


procedure draw_listbox_item(mylparam: LPARAM);
var
DrawStruct: PDrawItemStruct;
DC: HDC;
R: TRect;
Idx: Integer;
IsSelected: Boolean;
TextCol, BgCol: DWORD;
Brush: HBRUSH;
Buffer: array[0..255] of WideChar;
begin
  DrawStruct := PDrawItemStruct(mylparam);
  DC := DrawStruct^.hDC;
  R := DrawStruct^.rcItem;
  Idx := DrawStruct^.itemID;

  // 1. Obsługa pustej listy (gdy focus jest, ale nie ma elementów)
  if Idx = -1 then
  begin
    if (DrawStruct^.itemState and ODS_FOCUS) <> 0 then
      DrawFocusRect(DC, R);
    Exit;
  end;

  // 2. Sprawdzamy, czy element jest zaznaczony
  IsSelected := (DrawStruct^.itemState and ODS_SELECTED) <> 0;

  // 3. Pobieramy uchwyt ListBoxa (z DrawStruct)
  // i decydujemy o kolorach na podstawie stanu
  if IsSelected then
  begin
    BgCol := DWORD(GetPropW(DrawStruct^.hwndItem, AV_PROP_SEL_BG_COLOR));
    TextCol := DWORD(GetPropW(DrawStruct^.hwndItem, AV_PROP_SEL_TXT_COLOR));
  end
  else
  begin
    BgCol := DWORD(GetPropW(DrawStruct^.hwndItem, AV_PROP_BG_COLOR));
    TextCol := DWORD(GetPropW(DrawStruct^.hwndItem, AV_PROP_TEXT_COLOR));
  end;

  // Fallback, jeśli kolory nie zostały ustawione (żeby nie było czarno na czarnym)
  if BgCol = 0 then BgCol := GetSysColor(COLOR_WINDOW);
  if (TextCol = 0) and (BgCol = 0) then TextCol := GetSysColor(COLOR_WINDOWTEXT);

  // 4. RYSOWANIE TŁA (Wiersza)
  Brush := CreateSolidBrush(BgCol);
  FillRect(DC, R, Brush);
  DeleteObject(Brush);

  // 5. RYSOWANIE TEKSTU
  // Pobieramy tekst z ListBoxa
  SendMessageW(DrawStruct^.hwndItem, LB_GETTEXT, Idx, LPARAM(@Buffer));

  SetBkMode(DC, TRANSPARENT);
  SetTextColor(DC, TextCol);

  // Margines tekstu (np. 5px od lewej)
  R.Left := R.Left + 5;

  // Rysujemy tekst wyśrodkowany w pionie
  DrawTextW(DC, Buffer, -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  // 6. RYSOWANIE RAMKI FOCUSU (Opcjonalne - dla klawiatury)
  // Jeśli chcesz "czysty" wygląd jak w nowoczesnych apkach, możesz to zakomentować.
  {
  if (DrawStruct^.itemState and ODS_FOCUS) <> 0 then
    DrawFocusRect(DC, DrawStruct^.rcItem);
  }
end;

end.

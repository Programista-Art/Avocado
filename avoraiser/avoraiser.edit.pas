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

Module:     avoraiser.edit
Description:
*)
unit avoraiser.edit;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,avoraiser.core, avoraiser.utils, avoraiser.clipboard ;

const
AV_EDIT_BRUSH_CACHE = 'AvBrush';

// Ustawia znak maskujący (np. '*' lub '●'). Wstaw #0 aby wyłączyć hasło.
procedure set_edit_password_char(Handle: HWND; C: WideChar);
// Blokuje (True) lub odblokowuje (False) możliwość pisania w Edit/Memo.
procedure set_control_read_only(Handle: HWND; ReadOnly: Boolean);
// Czyści całą zawartość pola Edit memo
procedure clear_control(Handle: HWND);
procedure set_on_color_edit(Handle: HWND; Event: TAvocadoColorEvent);
// zaznaczanie tekstu (selection)
// po prostu przesuwa kursor w to miejsce.
procedure select_text(Handle: HWND; StartPos, EndPos: Integer);
// Zaznacza cały tekst w kontrolce (Skrót Ctrl+A)
procedure select_all_text(Handle: HWND);
// Pobiera informację, gdzie jest kursor lub co jest zaznaczone
function get_selection(Handle: HWND): TTextSelection;
// Ustawia kursor na konkretnej pozycji (indeks znaku od 0)
procedure set_cursor_position(Handle: HWND; Position: Integer);
// Przesuwa kursor na sam koniec tekstu (przydatne przy logach)
procedure move_cursor_to_end(Handle: HWND);
// Zamienia zaznaczony tekst na inny (lub wstawia w miejscu kursora)
// can_undo: Czy operację można cofnąć (Ctrl+Z) Domyślnie True.
procedure replace_selection(handle: HWND; const new_text: string; can_undo: Boolean = True);
// Tworzenie pola edycyjnego jednowierszowego (Input)
function create_edit(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
procedure set_edit_placeholder(hEdit: HWND; const PlaceholderText: string; StayOnFocus: Boolean = True);
//Wyrownanie teksru w poziomie w Edit
procedure set_edit_alignment(hEdit: HWND; Alignment: DWORD);
//Centrowanie w pionie
procedure set_edit_vertical_center(hEdit: HWND);
procedure set_edit_focus_color(hEdit: HWND; Color: COLORREF);
procedure set_edit_numbers_only(h_wnd: HWND; enable: Boolean);
procedure set_edit_math_only(h_wnd: HWND);
//dodaje tekst do edita
procedure add_to_edit(h_wnd: HWND; const text_to_add: UnicodeString);

implementation
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


function edit_math_proc(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM): LRESULT; stdcall;
 var
  OldProc: QWord;
  InputChar: WideChar;
 begin
   if u_msg = WM_CHAR then
   begin
     InputChar := WideChar(w_param);

     // Zezwalamy tylko na: cyfry, wybrane znaki i Backspace (#8 do kasowania błędów)
     if not (InputChar in ['0'..'9', '+', '-', '*', '/', #8]) then
     begin
       // Klawisz odrzucony - zwracamy 0 i kończymy, znak nie pojawi się w polu Edit
       Result := 0;
       Exit;
     end;
   end;

   // Przekazanie do oryginalnej procedury (która rysuje literkę, obsługuje kursor itp.)
   OldProc := QWord(GetPropW(h_wnd, PWideChar('OldWndProc')));
   if OldProc <> 0 then
     Result := CallWindowProcW(WNDPROC(Pointer(OldProc)), h_wnd, u_msg, w_param, l_param)
   else
     Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
 end;

// funkcja dopasowująca układ (czcionka i marginesy)
procedure update_edit_layout(hWnd: HWND);
var
  r, rect_f: TRect;
  font_height, off_top: Integer;
  new_font, old_font_handle: HFONT;
  dc: HDC;
  ts: TSize;
  old_obj: HGDIOBJ;
begin
 GetClientRect(hWnd, r);
  if (r.Bottom - r.Top) <= 0 then Exit;

  // 1. OBLICZANIE I TWORZENIE CZCIONKI
  font_height := Round((r.Bottom - r.Top) * 0.65);
  new_font := CreateFontW(
    -font_height, 0, 0, 0, FW_NORMAL, 0, 0, 0,
    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
    5, DEFAULT_PITCH or FF_DONTCARE, 'Segoe UI'
  );

  // 2. AKTUALIZACJA CZCIONKI W PAMIĘCI
  old_font_handle := HFONT(GetProp(hWnd, AV_EDIT_AUTO_FONT));
  if old_font_handle <> 0 then DeleteObject(old_font_handle);
  SetProp(hWnd, AV_EDIT_AUTO_FONT, THandle(new_font));

  // 3. USTAWIANIE CZCIONKI (To musi być PRZED mierzeniem i EM_SETRECT)
  SendMessageW(hWnd, WM_SETFONT, PtrUInt(new_font), 1);

  // 3. MIERZENIE TEKSTU (Potrzebne do centrowania)
  dc := GetDC(hWnd);
  old_obj := SelectObject(dc, new_font);
  GetTextExtentPoint32W(dc, 'Ay', 2, ts); // Mierzymy wysokość wzorcową
  SelectObject(dc, old_obj);
  ReleaseDC(hWnd, dc);

  // 4. USTAWIANIE CZCIONKI
  //SendMessageW(hWnd, WM_SETFONT, PtrUInt(new_font), 1);

  // 5. CENTROWANIE W PIONIE (EM_SETRECT)
  // Obliczamy ile wolnego miejsca zostaje na górze
  off_top := ((r.Bottom - r.Top) - ts.cy) div 2;
  if off_top < 0 then off_top := 0;

  // Definiujemy "prostokąt formatowania"
  rect_f.Left   := 6;                  // Lewy padding
  rect_f.Top    := off_top;            // To centruje tekst w pionie!
  rect_f.Right  := r.Right - 6;        // Prawy padding
  rect_f.Bottom := r.Bottom;           // Dół

  // UWAGA: EM_SETRECT działa tylko gdy jest flaga ES_MULTILINE
  SendMessageW(hWnd, EM_SETRECT, 0, LPARAM(@rect_f));
  InvalidateRect(hWnd, nil, True);
end;

procedure draw_edit_border(hWnd: HWND);
var
DC: HDC;
R: TRect;
Pen, OldPen: HPEN;
BorderCol: DWORD;
begin
 DC := GetWindowDC(hWnd);
  try
    GetWindowRect(hWnd, R);
    OffsetRect(R, -R.Left, -R.Top); // Przeliczamy na (0,0,W,H)

    // Pobieramy kolor (standardowy lub Focus)
    if GetFocus = hWnd then
      BorderCol := get_prop_color(hWnd, AV_EDIT_FOCUS_COLOR, $505050)
    else
      BorderCol := get_prop_color(hWnd, AV_EDIT_BORDER_COLOR, $303030);

    Pen := CreatePen(PS_SOLID, 1, BorderCol);
    OldPen := SelectObject(DC, Pen);
    SelectObject(DC, GetStockObject(NULL_BRUSH));

    // Rysujemy prostokąt ramki
    Rectangle(DC, 0, 0, R.Right, R.Bottom);

    SelectObject(DC, OldPen);
    DeleteObject(Pen);
  finally
    ReleaseDC(hWnd, DC);
  end;
end;

function edit_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
BgCol, TxtCol: DWORD;
EditBrush: HBRUSH;
DC: HDC;      // Typ dla uchwytu graficznego
R: TRect;     // Typ dla współrzędnych obszaru
begin
 case Msg of
    // Tworzymy 1px miejsca na ramkę Avocado
    WM_NCCALCSIZE:
    begin
      if WParam <> 0 then
      begin
        Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
        with PRect(LParam)^ do
        begin
          Left := Left + 1; Top := Top + 1; Right := Right - 1; Bottom := Bottom - 1;
        end;
        Exit;
      end;
    end;

    // KLUCZ DO KOLORÓW: Tu ustawiamy tło i kolor tekstu
    WM_CTLCOLOREDIT:
    begin
     BgCol  := get_prop_color(hWnd, AV_EDIT_BG_COLOR, $121212);
      TxtCol := get_prop_color(hWnd, AV_EDIT_TEXT_COLOR, $FFFFFF);

      SetTextColor(HDC(WParam), TxtCol);
      SetBkColor(HDC(WParam), BgCol);

      EditBrush := HBRUSH(GetPropW(hWnd, AV_EDIT_BRUSH_CACHE));
      if EditBrush = 0 then
      begin
        EditBrush := CreateSolidBrush(BgCol);
        SetPropW(hWnd, AV_EDIT_BRUSH_CACHE, THandle(EditBrush));
      end;

      Result := LRESULT(EditBrush);
      Exit;
    end;

    WM_CONTEXTMENU:
    begin
      // HWnd to uchwyt kontrolki tekstowej, nad którą kliknięto
      show_context_menu(HWnd);
      Exit(0);
    end;
    // Blokujemy standardowe czyszczenie tła, by uniknąć migania
    //WM_ERASEBKGND:
    //begin
    //  Result := 1;
    //  Exit;
    //end;
    WM_ERASEBKGND:
    begin
      // Edit sam maluje swoje tło na kolor z SetProp
      BgCol := get_prop_color(hWnd, AV_EDIT_BG_COLOR, $121212);
      DC := HDC(WParam);
      GetClientRect(hWnd, R);

      EditBrush := HBRUSH(GetPropW(hWnd, AV_EDIT_BRUSH_CACHE));
      if EditBrush = 0 then
      begin
        EditBrush := CreateSolidBrush(BgCol);
        SetPropW(hWnd, AV_EDIT_BRUSH_CACHE, THandle(EditBrush));
      end;

      FillRect(DC, R, EditBrush);
      Result := 1; // Mówimy systemowi: tło gotowe!
      Exit;
    end;

    // Rysowanie ramki
    WM_NCPAINT:
    begin
      draw_edit_border(hWnd);
      Result := 0;
      Exit;
    end;

    WM_PAINT:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
      draw_edit_border(hWnd);
      Exit;
    end;

    // Reagujemy na Focus, by zmienić kolor ramki
    WM_SETFOCUS, WM_KILLFOCUS:
    begin
      Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
      RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_FRAME or RDW_UPDATENOW);
      Exit;
    end;

    // Sprzątanie po zniszczeniu kontrolki
    WM_NCDESTROY:
    begin
      EditBrush := HBRUSH(GetPropW(hWnd, AV_EDIT_BRUSH_CACHE));
      if EditBrush <> 0 then DeleteObject(EditBrush);
      RemovePropW(hWnd, AV_EDIT_BRUSH_CACHE);
      // Usuwamy resztę właściwości...
      RemoveWindowSubclass(hWnd, SUBCLASSPROC(@edit_proc), uIdSubclass);
    end;
  end;

  Result := DefSubclassProc(hWnd, Msg, WParam, LParam);
end;




procedure set_edit_password_char(Handle: HWND; C: WideChar);
begin
  if Handle <> 0 then
  begin
    SendMessageW(Handle, EM_SETPASSWORDCHAR, WPARAM(Ord(C)), 0);
    InvalidateRect(Handle, nil, True);
  end;
end;

procedure set_control_read_only(Handle: HWND; ReadOnly: Boolean);
begin
    if Handle <> 0 then
    begin
      // EM_SETREADONLY: WParam = 1 (zablokuj), 0 (odblokuj)
      SendMessage(Handle, EM_SETREADONLY, WPARAM(ReadOnly), 0);
    end;
end;

procedure clear_control(Handle: HWND);
var
ClassName: array[0..31] of WideChar;
Style: LongInt;
IsCheckbox: Boolean;
begin
  if Handle = 0 then Exit;
  IsCheckbox := False;
  // 1. Pobieramy nazwę klasy (używamy systemowego GetClassNameW)
  if GetClassNameW(Handle, ClassName, 32) > 0 then
  begin
    // lstrcmpiW to lekka funkcja z kernel32.dll (odpowiednik StrComp, ale ignoruje wielkość liter)
    if lstrcmpiW(ClassName, 'BUTTON') = 0 then
    begin
      Style := GetWindowLongW(Handle, GWL_STYLE);

      // Sprawdzamy, czy to typ Checkbox używając maski BS_TYPEMASK ($0F)
      case (Style and $0000000F) of
        $00000002, // BS_CHECKBOX
        $00000003, // BS_AUTOCHECKBOX
        $00000005, // BS_3STATE
        $00000006: // BS_AUTO3STATE
          IsCheckbox := True;
      end;
    end;
  end;

  //Wykonujemy akcję
  if IsCheckbox then
  begin
    // BM_SETCHECK ($00F1), BST_UNCHECKED (0)
    SendMessageW(Handle, $00F1, 0, 0);
  end
  else
  begin
    SetWindowTextW(Handle, nil);
  end;
end;

procedure set_on_color_edit(Handle: HWND; Event: TAvocadoColorEvent);
begin
  if Handle <> 0 then
    begin
      SetProp(Handle, KP_EDIT_ON_COLOR, THandle(Pointer(Event)));
      InvalidateRect(Handle, nil, True);
    end;
end;

procedure select_text(Handle: HWND; StartPos, EndPos: Integer);
begin
  if Handle <> 0 then
    SendMessage(Handle, EM_SETSEL, StartPos, EndPos);
end;

procedure select_all_text(Handle: HWND);
begin
  if Handle <> 0 then
    // 0, -1 w komunikacie EM_SETSEL oznacza Zaznacz wszystko
    SendMessage(Handle, EM_SETSEL, 0, -1);
end;

function get_selection(Handle: HWND): TTextSelection;
var
  StartP, EndP: DWORD;
begin
    Result.StartPos := 0;
    Result.EndPos := 0;

    if Handle <> 0 then
    begin
      SendMessage(Handle, EM_GETSEL, WPARAM(@StartP), LPARAM(@EndP));
      Result.StartPos := Integer(StartP);
      Result.EndPos   := Integer(EndP);
    end;
end;

procedure set_cursor_position(Handle: HWND; Position: Integer);
begin
  select_text(Handle, Position, Position);
end;

procedure move_cursor_to_end(Handle: HWND);
begin
    select_text(Handle, $7FFFFFFF, $7FFFFFFF);
end;

procedure replace_selection(handle: HWND; const new_text: string;can_undo: Boolean);
const
  EM_REPLACESEL = $00C2;
begin
 SendMessage(handle, EM_REPLACESEL, WPARAM(can_undo), LPARAM(PChar(new_text)));
end;

function create_edit(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
const
  EM_SETCUEBANNER = $1501;
begin
 // Używamy CreateWindowExW dla pełnego wsparcia Unicode
  Result := CreateWindowExW(
    0,
    'EDIT',
    PWideChar(UnicodeString(Text)),
    WS_VISIBLE or
    WS_CHILD or
    WS_TABSTOP or
    ES_MULTILINE or
    ES_AUTOHSCROLL,
    X, Y, Width, Height,
    Parent,
    0,
    GetModuleHandle(nil),
    nil
  );

  if Result <> 0 then
  begin
    SetWindowSubclass(Result, SUBCLASSPROC(@edit_proc), 1, 0);
    // Ustawiamy font
    SendMessageW(Result, WM_SETFONT, PtrUInt(GetStockObject(DEFAULT_GUI_FONT)), 1);
    // Ustawiamy marginesy (Padding wewnętrzny)
    SendMessageW(Result, EM_SETMARGINS, EC_LEFTMARGIN or EC_RIGHTMARGIN, MakeLParam(6, 6));

    //Inicjalizacja domyślnego koloru ramki w Core
    SetProp(Result, AV_EDIT_BORDER_COLOR, THandle($303030 + 1));
    update_edit_layout(Result);
    SetWindowPos(Result, 0, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
  end;
end;

procedure set_edit_placeholder(hEdit: HWND; const PlaceholderText: string;
  StayOnFocus: Boolean);
var
  w_param: WPARAM;
begin
  if hEdit = 0 then Exit;
  if StayOnFocus then w_param := 1
  else
    w_param := 0;
    SetProp(hEdit, AV_EDIT_PLACEHOLDER, THandle(GlobalAddAtomW(PWideChar(UnicodeString(PlaceholderText)))));
     SendMessageW(hEdit, EM_SETCUEBANNER, w_param, LPARAM(PWideChar(UnicodeString(PlaceholderText))));
end;

procedure set_edit_alignment(hEdit: HWND; Alignment: DWORD);
var
  old_style: LONG_PTR;
begin
  if hEdit = 0 then Exit;
     old_style := GetWindowLongPtrW(hEdit, GWL_STYLE);
     old_style := old_style and not (ES_LEFT or ES_CENTER or ES_RIGHT);
     SetWindowLongPtrW(hEdit, GWL_STYLE, old_style or Alignment);
     SetWindowPos(hEdit, 0, 0, 0, 0, 0,
       SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
     InvalidateRect(hEdit, nil, True);
end;

procedure set_edit_vertical_center(hEdit: HWND);
var
r, rect_f: TRect;
txt_size: TSize;
dc: HDC;
font_handle, old_font: HFONT;
off_top: Integer;
begin
  if hEdit = 0 then Exit;
    // Pobieramy wymiary obszaru klienta
    GetClientRect(hEdit, r);
    // Mierzymy wysokość tekstu dla aktualnej czcionki
    dc := GetDC(hEdit);
    try
      font_handle := HFONT(SendMessageW(hEdit, WM_GETFONT, 0, 0));
      if font_handle = 0 then font_handle := GetStockObject(DEFAULT_GUI_FONT);

      old_font := SelectObject(dc, font_handle);
      GetTextExtentPoint32W(dc, 'Ay', 2, txt_size);
      SelectObject(dc, old_font);
    finally
      ReleaseDC(hEdit, dc);
    end;

    // 3. Obliczamy margines górny
    off_top := ( (r.Bottom - r.Top) - txt_size.cy ) div 2;

    // Zabezpieczenie, żeby tekst nie uciekł nad górną krawędź
    if off_top < 0 then off_top := 0;

    // 4. Ustawiamy prostokąt formatowania (Formatting Rectangle)
    rect_f.Left   := 6;                       // Lewy margines
    rect_f.Top    := off_top;                 // Centrowanie w pionie
    rect_f.Right  := r.Right - 6;             // Prawy margines
    rect_f.Bottom := off_top + txt_size.cy;   // Spód tekstu
    SendMessageW(hEdit, EM_SETRECT, 0, LPARAM(@rect_f));
end;

procedure set_edit_focus_color(hEdit: HWND; Color: COLORREF);
begin
    if hEdit = 0 then
    Exit;
    SetProp(hEdit, AV_EDIT_FOCUS_COLOR, THandle(Color));
end;

procedure set_edit_numbers_only(h_wnd: HWND; enable: Boolean);
var
  CurrentStyle: LONG_PTR;
begin
    if h_wnd = 0 then Exit;
      CurrentStyle := GetWindowLongPtrW(h_wnd, GWL_STYLE);

      if enable then
        CurrentStyle := CurrentStyle or ES_NUMBER
      else
        CurrentStyle := CurrentStyle and not ES_NUMBER;
      SetWindowLongPtrW(h_wnd, GWL_STYLE, CurrentStyle);
end;

procedure set_edit_math_only(h_wnd: HWND);
var
  OldProc: QWord;
begin
  if h_wnd = 0 then Exit;
    OldProc := QWord(SetWindowLongPtrW(h_wnd, GWLP_WNDPROC, LONG_PTR(@edit_math_proc)));

    if OldProc <> 0 then
      SetPropW(h_wnd, PWideChar('OldWndProc'), HANDLE(OldProc));
end;

procedure add_to_edit(h_wnd: HWND; const text_to_add: UnicodeString);
var
  TextLen: Integer;
begin
    if h_wnd = 0 then Exit;
      TextLen := GetWindowTextLengthW(h_wnd);
      SendMessageW(h_wnd, EM_SETSEL, WPARAM(TextLen), LPARAM(TextLen));
      SendMessageW(h_wnd, EM_REPLACESEL, 0, LPARAM(PWideChar(text_to_add)));
end;



end.


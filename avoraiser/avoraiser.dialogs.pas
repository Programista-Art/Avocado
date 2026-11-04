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

Module:     avoraiser.dialogs
Description:
*)

unit avoraiser.dialogs;
{$mode ObjFPC}{$H+}
{$codepage utf8}
interface

uses
  Windows, avoraiser.gdi, avoraiser.button, avoraiser.edit,CommDlg;
type
  TDialogLanguage = (LangPL, LangEN);
// Jakie przyciski mają się pojawić?
type
  TDialogButtons = (
      DlgBtnOK,                  // OK
      DlgBtnOKCancel,            // OK, Anuluj
      DlgBtnYesNo,               // Tak, Nie
      DlgBtnYesNoCancel,         // Tak, Nie, Anuluj
      DlgBtnAbortRetryIgnore,    // Przerwij, Ponów, Ignoruj
      DlgBtnRetryCancel          // Ponów, Anuluj
  );

// Co kliknął użytkownik? Wynik działania funkcji
type
  TDialogResult = (
    DlgResultNone,
    DlgResultOK,
    DlgResultCancel,
    DlgResultYes,
    DlgResultNo,
    DlgResultAbort,
    DlgResultRetry,
    DlgResultIgnore
  );

// Wyświetla proste okno z informacją
procedure show_message(Owner: HWND; const Title, Text: UnicodeString);
// Wyświetla pytanie Tak/Nie. Zwraca True, jeśli użytkownik kliknął "Tak"
function ask_question(Owner: HWND; const Title, Text: UnicodeString): Boolean;
// Wyświetla ostrzeżenie z ikoną wykrzyknika
procedure show_warning(Owner: HWND; const Title, Text: UnicodeString);
// Główna funkcja tworząca customowy dialog zwraca wynik
function show_custom_dialog(Owner: HWND; const Title, Description: UnicodeString; BgColor, TextColor, AccentColor: DWORD; Buttons: TDialogButtons = DlgBtnOK): TDialogResult;
//Zmiana jezyka przyciskow
procedure set_dialog_language(Lang: TDialogLanguage);
// Wyświetla okno z prośbą o wpisanie tekstu.
// Zwraca True, jeśli użytkownik zatwierdził (OK), a wpisany tekst trafia do zmiennej Value.
function input_box(Owner: HWND; const Title, Prompt: UnicodeString; var Value: UnicodeString; BgColor, TextColor, AccentColor, EditBgColor, EditTextColor: DWORD): Boolean;
// Wyświetla okno do wpisywania hasła (znaki są maskowane).
function password_box(Owner: HWND; const Title, Prompt: UnicodeString; var Value: UnicodeString; BgColor, TextColor, AccentColor, EditBgColor, EditTextColor: DWORD): Boolean;
// Wyświetla powiadomienie typu Toast. Nie blokuje aplikacji i znika automatycznie.
procedure show_toast(Owner: HWND; const MessageText: UnicodeString; BgColor, TextColor: DWORD; Duration: Integer = 3000; Width: Integer = 250; Height: Integer = 45);
// Wyświetla pionowe menu z dużymi przyciskami. Zwraca indeks klikniętego przycisku (0, 1, 2...) lub -1 jeśli anulowano.
function show_action_sheet(Owner: HWND; const Title: UnicodeString; const Options, IconPaths: array of UnicodeString; BgColor, TextColor, AccentColor: DWORD): Integer;
function show_progress_dialog(Owner: HWND; const Title, Status: UnicodeString; BgColor, TextColor, AccentColor: DWORD): HWND;
procedure update_progress(HDlg: HWND; Position: Integer; const NewStatus: UnicodeString);
function get_file_name_from_user(h_wnd: HWND; is_save: Boolean; const filter: UnicodeString = 'Wszystkie pliki (*.*)|*.*'; const default_ext: UnicodeString = ''): UnicodeString;

implementation
// Stałe ID dla przycisków
const
  CLEARTYPE_QUALITY = 5;
  ID_BTN_OK = 100;
  ID_BTN_CANCEL = 101;
  ID_BTN_YES = 102;
  ID_BTN_NO = 103;
  ID_BTN_CLOSE_X = 104;
  ID_BTN_ABORT = 105;
  ID_BTN_RETRY = 106;
  ID_BTN_IGNORE = 107;
  TOAST_TIMER_ID = 1001;



var
  DialogClassRegistered: Boolean = False;
  PaletteClassRegistered: Boolean = False;
  // Zmienna globalna w module do przekazania wyniku z procedury okna do funkcji głównej
  CurrentDialogResult: TDialogResult;
  CurrentDialogLang: TDialogLanguage = LangPL;
  InputDialogClassRegistered: Boolean = False;
  CurrentInputResult: Boolean;
  CurrentInputText: UnicodeString;
  ToastClassRegistered: Boolean = False;
  //CurrentPaletteResult: UnicodeString;
  //OriginalCommands: array of UnicodeString; // Przechowuje pełną listę poleceń

function progress_proc(HWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
PS: TPaintStruct;
DC: HDC;
R, BarR, FillR: TRect;
Title, Status: PWideChar;
HFontMain, HOldFont: HFONT;
BgBrush, BarBgBrush, AccentBrush: HBRUSH;
BgCol, TxCol, AxCol: DWORD;
ProgressPos: Integer;
MemDC: HDC;
MemBmp, OldMemBmp: HBITMAP;
begin
  case Msg of
  WM_ERASEBKGND:
  begin
    Result := 1;
    Exit;
  end;

  WM_PAINT:
    begin
      DC := BeginPaint(HWnd, PS);
      GetClientRect(HWnd, R);

      //  DOUBLE BUFFERING
      MemDC := CreateCompatibleDC(DC);
      MemBmp := CreateCompatibleBitmap(DC, R.Right, R.Bottom);
      OldMemBmp := SelectObject(MemDC, MemBmp);

      try
        // Pobieranie danych (zmienne PascalCase)
        BgCol := DWORD(GetPropW(HWnd, 'BgColor'));
        TxCol := DWORD(GetPropW(HWnd, 'TextColor'));
        AxCol := DWORD(GetPropW(HWnd, 'AccentColor'));
        Title := PWideChar(GetPropW(HWnd, 'TitleText'));
        Status := PWideChar(GetPropW(HWnd, 'StatusText'));
        ProgressPos := Integer(GetPropW(HWnd, 'ProgressPos'));

        // Rysowanie tła na MemDC
        BgBrush := CreateSolidBrush(BgCol);
        FillRect(MemDC, R, BgBrush);
        DeleteObject(BgBrush);

        // Czcionka Segoe UI (Twoje parametry)
        HFontMain := CreateFontW(-17, 0, 0, 0, FW_NORMAL, 0, 0, 0, EASTEUROPE_CHARSET,
                                 OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                 DEFAULT_PITCH, 'Segoe UI');
        HOldFont := SelectObject(MemDC, HFontMain);
        SetBkMode(MemDC, TRANSPARENT);
        SetTextColor(MemDC, TxCol);

        //Rysowanie Tytułu
        BarR := R;
        BarR.Top := 20;
        BarR.Left := 25;
        DrawTextW(MemDC, Title, -1, @BarR, DT_LEFT or DT_SINGLELINE);

        // Pasek postępu (Flat Design)
        BarR.Left := 25;
        BarR.Right := R.Right - 25;
        BarR.Top := 55;
        BarR.Bottom := 75;

        BarBgBrush := CreateSolidBrush(BgCol + $0A0A0A);
        FillRect(MemDC, BarR, BarBgBrush);
        DeleteObject(BarBgBrush);

        FillR := BarR;
        FillR.Right := BarR.Left + ((BarR.Right - BarR.Left) * ProgressPos div 100);
        AccentBrush := CreateSolidBrush(AxCol);
        FillRect(MemDC, FillR, AccentBrush);
        DeleteObject(AccentBrush);

        // Rysowanie Statusu
        BarR.Top := 85;
        BarR.Bottom := R.Bottom;
        DrawTextW(MemDC, Status, -1, @BarR, DT_LEFT or DT_SINGLELINE);


        SelectObject(MemDC, HOldFont);
        DeleteObject(HFontMain);

        // KOPIOWANIE BUFORA NA EKRAN
        BitBlt(DC, 0, 0, R.Right, R.Bottom, MemDC, 0, 0, SRCCOPY);

      finally
        // Sprzątanie pamięci
        SelectObject(MemDC, OldMemBmp);
        DeleteObject(MemBmp);
        DeleteDC(MemDC);
        EndPaint(HWnd, PS);
      end;
      Exit(0);
    end;


  WM_NCDESTROY:
  begin
    RemovePropW(HWnd, 'TitleText');
    RemovePropW(HWnd, 'StatusText');
    RemovePropW(HWnd, 'BgColor');
    RemovePropW(HWnd, 'TextColor');
    RemovePropW(HWnd, 'AccentColor');
    RemovePropW(HWnd, 'ProgressPos');
  end;
end;
Result := DefWindowProcW(HWnd, Msg, WParam, LParam);
end;

function action_sheet_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  R, TitleRect: TRect;
  BgColor, TextColor: DWORD;
  TitleStr: UnicodeString;
  BufferState: TDoubleBufferState;
  myhFont: HFONT;
  hOldFont: HGDIOBJ;
  PropPtr: Pointer;
  hOwner: HWND;

begin
  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      GetClientRect(hWnd, R);
      BufferState := begin_double_buffer(DC, R);
      try
        BgColor := DWORD(GetWindowLongPtrW(hWnd, 0));
        TextColor := DWORD(GetWindowLongPtrW(hWnd, 8));

        PropPtr := Pointer(GetPropW(hWnd, 'SheetTitlePtr'));
        if PropPtr <> nil then TitleStr := UnicodeString(PropPtr) else TitleStr := '';

        draw_fill_rectangle(hWnd, 0, 0, R.Right, R.Bottom, BgColor, BufferState.MemDC);

        myhFont := CreateFontW(-18, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET,
                             OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

        set_text_color(BufferState.MemDC, TextColor);
        set_bk_mode(BufferState.MemDC, True);
        hOldFont := SelectObject(BufferState.MemDC, myhFont);

        TitleRect := R;
        TitleRect.Top := 20;
        draw_text_advanced(BufferState.MemDC, TitleRect, TitleStr, DT_CENTER or DT_TOP or DT_SINGLELINE);

        SelectObject(BufferState.MemDC, hOldFont);
        DeleteObject(myhFont);
      finally
        end_double_buffer(BufferState);
        EndPaint(hWnd, ps);
      end;
      Result := 0; Exit;
    end;

    WM_COMMAND:
    begin
      // Jeśli kliknięto jakikolwiek przycisk (ID >= 1000)
      if (LOWORD(WParam) >= 1000) and (LOWORD(WParam) < 2000) then
      begin
        SetWindowLongPtrW(hWnd, 16, LOWORD(WParam)); // Zapisujemy kliknięte ID
        PostMessageW(hWnd, WM_CLOSE, 0, 0);
      end;

      if LOWORD(WParam) = ID_BTN_CLOSE_X then PostMessageW(hWnd, WM_CLOSE, 0, 0);

      Result := 0; Exit;
    end;

    WM_CLOSE:
    begin
      hOwner := GetWindow(hWnd, GW_OWNER);
      if hOwner <> 0 then EnableWindow(hOwner, True);
      DestroyWindow(hWnd);
      PostMessageW(0, WM_NULL, 0, 0);
      Result := 0; Exit;
    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;

function toast_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
ps: TPaintStruct;
DC: HDC;
R: TRect;
BgColor, TextColor: DWORD;
MsgStr: UnicodeString;
BufferState: TDoubleBufferState;
myhFont: HFONT;
hOldFont: HGDIOBJ;
begin
  case Msg of
    // 1. ZEGAR: Czas minął, niszczymy okno!
    WM_TIMER:
    begin
      if WParam = TOAST_TIMER_ID then
      begin
        KillTimer(hWnd, TOAST_TIMER_ID); // Zatrzymujemy zegar
        DestroyWindow(hWnd);             // Usuwamy dymek
      end;
      Result := 0;
      Exit;
    end;

    // 2. KLIKNIĘCIE: Jeśli użytkownik kliknie w Toast, też go zamykamy (wcześniej)
    WM_LBUTTONDOWN:
    begin
      KillTimer(hWnd, TOAST_TIMER_ID);
      DestroyWindow(hWnd);
      Result := 0;
      Exit;
    end;

    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      GetClientRect(hWnd, R);
      BufferState := begin_double_buffer(DC, R);
      try
        BgColor := DWORD(GetPropW(hWnd, 'ToastBg'));
        TextColor := DWORD(GetPropW(hWnd, 'ToastTxt'));
        MsgStr := UnicodeString(Pointer(GetPropW(hWnd, 'ToastMsgPtr')));

        // Malujemy tło powiadomienia
        draw_fill_rectangle(hWnd, 0, 0, R.Right, R.Bottom, BgColor, BufferState.MemDC);

        // Ustawiamy ładną czcionkę (mniejszą niż w oknach dialogowych)
        myhFont := CreateFontW(-14, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
                                        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                        CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

        set_text_color(BufferState.MemDC, TextColor);
        set_bk_mode(BufferState.MemDC, True);
         hOldFont := SelectObject(BufferState.MemDC, myhFont);

        // Tekst wyśrodkowany idealnie w pionie i poziomie
        draw_text_advanced(BufferState.MemDC, R, MsgStr, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

        SelectObject(BufferState.MemDC, hOldFont);
        DeleteObject(myhFont);
      finally
        end_double_buffer(BufferState);
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      Result := 1;
      Exit;
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'ToastBg');
      RemovePropW(hWnd, 'ToastTxt');
      RemovePropW(hWnd, 'ToastMsgPtr');
    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;

function input_dialog_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  R, TitleRect, PromptRect: TRect;
  BgColor, TextColor: DWORD;
  TitleStr, PromptStr: UnicodeString;
  BufferState: TDoubleBufferState;
  hEdit: HWND;
  TextLen: Integer;
  Buffer: array of WideChar;
  hTitleFont,hDescFont: HFONT;
  hOldFont: HGDIOBJ;
  hOwner: HWND;
  hdcEdit: HDC;
  TxtCol: DWORD;
  BgCol: DWORD;
  myhBrush: HBRUSH;
begin
  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      GetClientRect(hWnd, R);
      BufferState := begin_double_buffer(DC, R);
      try
        BgColor := DWORD(GetPropW(hWnd, 'DlgBg'));
        TextColor := DWORD(GetPropW(hWnd, 'DlgTxt'));
        TitleStr := UnicodeString(Pointer(GetPropW(hWnd, 'DlgTitlePtr')));
        PromptStr := UnicodeString(Pointer(GetPropW(hWnd, 'DlgPromptPtr')));

        draw_fill_rectangle(hWnd, 0, 0, R.Right, R.Bottom, BgColor, BufferState.MemDC);

        hTitleFont := CreateFontW(-20, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET,
                                             OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                             CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');
        hDescFont := CreateFontW(-15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
                                            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                            CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

        set_text_color(BufferState.MemDC, TextColor);
        set_bk_mode(BufferState.MemDC, True);

        hOldFont := SelectObject(BufferState.MemDC, hTitleFont);

        // Tytuł
        TitleRect := R;
        TitleRect.Top := 15; TitleRect.Left := 20; TitleRect.Right := R.Right - 40;
        draw_text_advanced(BufferState.MemDC, TitleRect, TitleStr, DT_LEFT or DT_SINGLELINE);

        // Treść zachęty (Prompt)
        SelectObject(BufferState.MemDC, hDescFont);
        PromptRect := R;
        PromptRect.Top := 50; PromptRect.Left := 20; PromptRect.Right := R.Right - 20;
        draw_text_advanced(BufferState.MemDC, PromptRect, PromptStr, DT_LEFT or DT_WORDBREAK);

        SelectObject(BufferState.MemDC, hOldFont);
        DeleteObject(hTitleFont);
        DeleteObject(hDescFont);
      finally
        end_double_buffer(BufferState);
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      Result := 1;
      Exit;
    end;

    WM_NCHITTEST:
    begin
      Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
      if Result = HTCLIENT then Result := HTCAPTION;
      Exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(WParam) of
        ID_BTN_OK:
        begin
          // Pobieramy uchwyt pola tekstowego zapisany we właściwościach okna
          hEdit := GetPropW(hWnd, 'DlgEditHandle');

          // Zczytujemy tekst z pola do naszej zmiennej
          TextLen := GetWindowTextLengthW(hEdit);
          SetLength(Buffer, TextLen + 1);
          GetWindowTextW(hEdit, PWideChar(Buffer), TextLen + 1);

          CurrentInputText := PWideChar(Buffer);
          CurrentInputResult := True;
        end;
        ID_BTN_CANCEL, ID_BTN_CLOSE_X:
        begin
          CurrentInputResult := False;
        end;
      end;

      if (LOWORD(WParam) = ID_BTN_OK) or (LOWORD(WParam) = ID_BTN_CANCEL) or (LOWORD(WParam) = ID_BTN_CLOSE_X) then
      begin
         hOwner := GetWindow(hWnd, GW_OWNER);
         if hOwner <> 0 then
         begin
           EnableWindow(hOwner, True);
           SetForegroundWindow(hOwner);
         end;
         DestroyWindow(hWnd);
      end;
      Result := 0;
      Exit;
    end;

    WM_CTLCOLOREDIT:
    begin
      // WParam przechowuje płótno (DC) samego pola tekstowego
      hdcEdit := HDC(WParam);

      // Pobieramy kolory i pędzel, które zaraz przekażemy do okna
      TxtCol := DWORD(GetPropW(hWnd, 'DlgEditTxt'));
      BgCol := DWORD(GetPropW(hWnd, 'DlgEditBg'));
      myhBrush := HBRUSH(GetPropW(hWnd, 'DlgEditBrush'));

      // Ustawiamy kolor tekstu i tła pod tekstem
      SetTextColor(hdcEdit, TxtCol);
      SetBkColor(hdcEdit, BgCol);

      // Zwracamy pędzel, którym Windows pomaluje resztę tła pola tekstowego
      Result := LRESULT(myhBrush);
      Exit;
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'DlgBg');
      RemovePropW(hWnd, 'DlgTxt');
      RemovePropW(hWnd, 'DlgTitlePtr');
      RemovePropW(hWnd, 'DlgPromptPtr');
      RemovePropW(hWnd, 'DlgEditHandle');
    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;

function custom_dialog_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
ps: TPaintStruct;
DC: HDC;
R: TRect;
BgColor, TextColor: DWORD;
TitleStr, DescStr: UnicodeString;
TitleRect, DescRect: TRect;
// Bufory z avoraiser.gdi
BufferState: TDoubleBufferState;
hDescFont: HFONT;
hTitleFont: HFONT;
hOldFont: HGDIOBJ;
hOwner: HWND;
begin
  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      GetClientRect(hWnd, R);

      // 1. START DOUBLE BUFFERING (Eliminacja migotania!)
      BufferState := begin_double_buffer(DC, R);
      try
        // Pobieramy właściwości
        BgColor := DWORD(GetPropW(hWnd, 'DlgBg'));
        TextColor := DWORD(GetPropW(hWnd, 'DlgTxt'));
        // Pobieramy stringi (konwersja z PtrUInt na obiekt/wskaźnik)
        TitleStr := UnicodeString(Pointer(GetPropW(hWnd, 'DlgTitlePtr')));
        DescStr := UnicodeString(Pointer(GetPropW(hWnd, 'DlgDescPtr')));

        // 2. Rysujemy TŁO na buforze pamięci
        draw_fill_rectangle(hWnd, 0, 0, R.Right, R.Bottom, BgColor, BufferState.MemDC);

         hTitleFont := CreateFontW(-20, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET,
                                             OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                             CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

        // Tworzymy mniejszą, zwykłą czcionkę dla opisu (Wielkość -15)
        hDescFont := CreateFontW(-15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
                                            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                            CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');

        // 3. Rysujemy TEKSTY na buforze pamięci
        // Używamy funkcji GDI z avoraiser.gdi
        set_text_color(BufferState.MemDC, TextColor);
        set_bk_mode(BufferState.MemDC, True);

        // Podpinamy czcionkę tytułową do naszego płótna
        hOldFont := SelectObject(BufferState.MemDC, hTitleFont);

        // Tytuł
        TitleRect := R;
        TitleRect.Top := 15;  // Podniesione do góry
        TitleRect.Left := 20; // Odsunięte od lewej krawędzi
        TitleRect.Right := R.Right - 40; // Żeby tekst nie wszedł na przycisk "X"
        //TitleRect.Bottom := 60;

        //draw_text_advanced(BufferState.MemDC, TitleRect, TitleStr, DT_CENTER or DT_SINGLELINE);
        draw_text_advanced(BufferState.MemDC, TitleRect, TitleStr, DT_LEFT or DT_SINGLELINE);

        // Opis
        // Podpinamy czcionkę opisu
        SelectObject(BufferState.MemDC, hDescFont);
        DescRect := R;
        DescRect.Top := 50;
        DescRect.Left := 20;
        DescRect.Right := R.Right - 20;
        //draw_text_advanced(BufferState.MemDC, DescRect, DescStr, DT_CENTER or DT_WORDBREAK);
        // Ustawione do lewej z zawijaniem wierszy
        draw_text_advanced(BufferState.MemDC, DescRect, DescStr, DT_LEFT or DT_WORDBREAK);

        //  sprzątanie pamięci
        SelectObject(BufferState.MemDC, hOldFont);
        DeleteObject(hTitleFont);
        DeleteObject(hDescFont);

      finally
        // koniec double buffering (przerzut na ekran)
        end_double_buffer(BufferState);
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

   // dla braku migotania: blokujemy systemowe czyszczenie tła
    WM_ERASEBKGND:
    begin
       Result := 1;
       Exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(WParam) of
        ID_BTN_OK: CurrentDialogResult := DlgResultOK;
        ID_BTN_CANCEL: CurrentDialogResult := DlgResultCancel;
        ID_BTN_YES: CurrentDialogResult := DlgResultYes;
        ID_BTN_NO: CurrentDialogResult := DlgResultNo;
        ID_BTN_CLOSE_X: CurrentDialogResult := DlgResultCancel;
        ID_BTN_ABORT: CurrentDialogResult := DlgResultAbort;
        ID_BTN_RETRY: CurrentDialogResult := DlgResultRetry;
        ID_BTN_IGNORE: CurrentDialogResult := DlgResultIgnore;
      end;

      if (LOWORD(WParam) >= ID_BTN_OK) and (LOWORD(WParam) <= ID_BTN_IGNORE) then
      begin
         hOwner := GetWindow(hWnd, GW_OWNER);
         if hOwner <> 0 then
         begin
           EnableWindow(hOwner, True);         // Budzimy rodzica
           SetForegroundWindow(hOwner);        // Dajemy mu focus
         end;
         DestroyWindow(hWnd);
      end;
      Result := 0;
      Exit;
    end;

    WM_NCHITTEST:
    begin
      Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
      if Result = HTCLIENT then
      begin
        Result := HTCAPTION;
      end;

      Exit;
    end;

    WM_NCDESTROY:
    begin
      // Sprzątanie (Stringi w Pascalu są zarządzane automatycznie, ale usuwamy propsy)
      RemovePropW(hWnd, 'DlgBg');
      RemovePropW(hWnd, 'DlgTxt');
      RemovePropW(hWnd, 'DlgTitlePtr');
      RemovePropW(hWnd, 'DlgDescPtr');
    end;
  end;

  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;


procedure show_message(Owner: HWND; const Title, Text: UnicodeString);
begin
  MessageBoxW(Owner, PWideChar(Text), PWideChar(Title), MB_OK or
  MB_ICONINFORMATION or
  MB_SETFOREGROUND);
end;

function ask_question(Owner: HWND; const Title, Text: UnicodeString): Boolean;
begin
   // MB_YESNO - przyciski Tak i Nie
    // MB_ICONQUESTION - ikonka znaku zapytania
    // Zwraca IDYES, jeśli kliknięto "Tak"
    Result := MessageBoxW(Owner, PWideChar(Text), PWideChar(Title),
    MB_YESNO or MB_ICONQUESTION or MB_SETFOREGROUND) = IDYES;
end;

procedure show_warning(Owner: HWND; const Title, Text: UnicodeString);
begin
    // MB_ICONWARNING - żółty trójkąt z wykrzyknikiem
    MessageBoxW(Owner, PWideChar(Text), PWideChar(Title), MB_OK or
    MB_ICONWARNING or MB_SETFOREGROUND);
end;

// Wewnętrzna funkcja tłumacząca ID przycisku na tekst w wybranym języku
function get_btn_text(BtnID: Integer): UnicodeString;
begin
  case CurrentDialogLang of
    LangPL:
      case BtnID of
        ID_BTN_OK:     Result := 'OK';
        ID_BTN_CANCEL: Result := 'Anuluj';
        ID_BTN_YES:    Result := 'Tak';
        ID_BTN_NO:     Result := 'Nie';
        ID_BTN_ABORT:  Result := 'Przerwij';
        ID_BTN_RETRY:  Result := 'Ponów';
        ID_BTN_IGNORE: Result := 'Ignoruj';
      else
        Result := '';
      end;

    LangEN:
      case BtnID of
        ID_BTN_OK:     Result := 'OK';
        ID_BTN_CANCEL: Result := 'Cancel';
        ID_BTN_YES:    Result := 'Yes';
        ID_BTN_NO:     Result := 'No';
        ID_BTN_ABORT:  Result := 'Abort';
        ID_BTN_RETRY:  Result := 'Retry';
        ID_BTN_IGNORE: Result := 'Ignore';
      else
        Result := '';
      end;
  end;
end;


function show_custom_dialog(Owner: HWND; const Title,
  Description: UnicodeString; BgColor, TextColor, AccentColor: DWORD;
  Buttons: TDialogButtons): TDialogResult;
var
  wc: TWndClassW;
  hDlg, hBtn1, hBtn2,hBtn3, hBtnX: HWND;
  msg: TMsg;
  DlgW, DlgH, PosX, PosY: Integer;
  OwnerRect: TRect;
  BtnW, BtnH, BtnGap, BtnY: Integer;
  GrayColor: DWORD;
  StartX: Integer;
begin
  // Domyślny wynik, jeśli coś pójdzie nie tak lub zamknięto "X"
    CurrentDialogResult := DlgResultCancel;
    if Buttons = DlgBtnOK then CurrentDialogResult := DlgResultOK;

    // 1. Rejestracja klasy okna (jednorazowa)
    if not DialogClassRegistered then
    begin
      FillChar(wc, SizeOf(wc), 0);
      wc.lpfnWndProc := @custom_dialog_proc;
      wc.hInstance := GetModuleHandle(nil);
      wc.hCursor := LoadCursor(0, IDC_ARROW);
      wc.lpszClassName := 'AvocadoDialogV2Class';
      // CS_DROPSHADOW - dodaje cień pod oknem (ładny efekt w Windows)
      wc.style := CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
      RegisterClassW(wc);
      DialogClassRegistered := True;
    end;

    // Wymiary i pozycja
    DlgW := 400; DlgH := 220;
    BtnW := 100; BtnH := 35; BtnGap := 20;
    BtnY := DlgH - BtnH - 25;
    GrayColor := $404040; // Kolor dla przycisków "Anuluj" / "Nie"

    if (Owner <> 0) and GetWindowRect(Owner, OwnerRect) then
    begin
      PosX := OwnerRect.Left + ((OwnerRect.Right - OwnerRect.Left) div 2) - (DlgW div 2);
      PosY := OwnerRect.Top + ((OwnerRect.Bottom - OwnerRect.Top) div 2) - (DlgH div 2);
    end else begin PosX := 300; PosY := 300; end;

    // 2. Tworzenie okna (WS_POPUP = brak systemowej ramki)
    hDlg := CreateWindowExW(WS_EX_TOPMOST, 'AvocadoDialogV2Class', nil,
      WS_POPUP or WS_VISIBLE, PosX, PosY, DlgW, DlgH, Owner, 0, GetModuleHandle(nil), nil);

    if hDlg <> 0 then
    begin
      // Przekazujemy dane do okna
      SetPropW(hDlg, 'DlgBg', THandle(BgColor));
      SetPropW(hDlg, 'DlgTxt', THandle(TextColor));
      // Przekazujemy wskaźniki do stringów Unicode
      SetPropW(hDlg, 'DlgTitlePtr', THandle(Pointer(Title)));
      SetPropW(hDlg, 'DlgDescPtr', THandle(Pointer(Description)));

      //Tworzenie przyciskow
      // Przycisk "X" w prawym górnym rogu (mały, kwadratowy)
      hBtnX := create_button(hDlg, 'X', DlgW - 35, 5, 30, 30);
      set_button_id(hBtnX, ID_BTN_CLOSE_X);
      // Stylizujemy X: Tło przezroczyste (lub kolor dialogu), tekst szary, po najechaniu lekko jaśniejszy
      //set_button_colors(hBtnX, BgColor, BgColor + $101010, TextColor, $AAAAAA);
      set_button_colors(hBtnX, BgColor, BgColor + $101010, BgColor - $050505, TextColor, BgColor);


      // Przyciski główne na dole
      case Buttons of
        DlgBtnOK:
      begin
        StartX := (DlgW - BtnW) div 2;
        hBtn1 := create_button(hDlg, 'OK', StartX, BtnY, BtnW, BtnH);
        set_button_id(hBtn1, ID_BTN_OK);
        set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);
      end;

      DlgBtnOKCancel, DlgBtnYesNo, DlgBtnRetryCancel:
      begin
        // Układ na 2 przyciski: (Szerokość 2 przycisków + przerwa)
        StartX := (DlgW - (2 * BtnW + BtnGap)) div 2;

        // Lewy przycisk
        hBtn1 := create_button(hDlg, '', StartX, BtnY, BtnW, BtnH);
        set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

        // Prawy przycisk
        hBtn2 := create_button(hDlg, '', StartX + BtnW + BtnGap, BtnY, BtnW, BtnH);
        set_button_colors(hBtn2, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);

        {if Buttons = DlgBtnOKCancel then begin
          SetWindowTextW(hBtn1, 'OK'); set_button_id(hBtn1, ID_BTN_OK);
          SetWindowTextW(hBtn2, 'Anuluj'); set_button_id(hBtn2, ID_BTN_CANCEL);
        end else if Buttons = DlgBtnYesNo then begin
          SetWindowTextW(hBtn1, 'Tak'); set_button_id(hBtn1, ID_BTN_YES);
          SetWindowTextW(hBtn2, 'Nie'); set_button_id(hBtn2, ID_BTN_NO);
        end else begin
          SetWindowTextW(hBtn1, 'Ponów'); set_button_id(hBtn1, ID_BTN_RETRY);
          SetWindowTextW(hBtn2, 'Anuluj'); set_button_id(hBtn2, ID_BTN_CANCEL);
        end;
        }
        if Buttons = DlgBtnOKCancel then begin
          SetWindowTextW(hBtn1, PWideChar(get_btn_text(ID_BTN_OK)));     set_button_id(hBtn1, ID_BTN_OK);
          SetWindowTextW(hBtn2, PWideChar(get_btn_text(ID_BTN_CANCEL))); set_button_id(hBtn2, ID_BTN_CANCEL);
        end else if Buttons = DlgBtnYesNo then begin
          SetWindowTextW(hBtn1, PWideChar(get_btn_text(ID_BTN_YES)));    set_button_id(hBtn1, ID_BTN_YES);
          SetWindowTextW(hBtn2, PWideChar(get_btn_text(ID_BTN_NO)));     set_button_id(hBtn2, ID_BTN_NO);
        end else begin
          SetWindowTextW(hBtn1, PWideChar(get_btn_text(ID_BTN_RETRY)));  set_button_id(hBtn1, ID_BTN_RETRY);
          SetWindowTextW(hBtn2, PWideChar(get_btn_text(ID_BTN_CANCEL))); set_button_id(hBtn2, ID_BTN_CANCEL);
        end;
      end;

      DlgBtnYesNoCancel, DlgBtnAbortRetryIgnore:
      begin
        // Układ na 3 przyciski: (Szerokość 3 przycisków + 2 przerwy)
        StartX := (DlgW - (3 * BtnW + 2 * BtnGap)) div 2;

        // Lewy przycisk (hBtn1)
        hBtn1 := create_button(hDlg, '', StartX, BtnY, BtnW, BtnH);
        set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

        // Środkowy przycisk (hBtn2)
        hBtn2 := create_button(hDlg, '', StartX + BtnW + BtnGap, BtnY, BtnW, BtnH);
        set_button_colors(hBtn2, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);

        // Prawy przycisk (nowa zmienna hBtn3, musisz ją dopisać w sekcji var u góry funkcji)
        hBtn3 := create_button(hDlg, '', StartX + 2 * (BtnW + BtnGap), BtnY, BtnW, BtnH);
        set_button_colors(hBtn3, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);

        if Buttons = DlgBtnYesNoCancel then begin
          SetWindowTextW(hBtn1, 'Tak'); set_button_id(hBtn1, ID_BTN_YES);
          SetWindowTextW(hBtn2, 'Nie'); set_button_id(hBtn2, ID_BTN_NO);
          SetWindowTextW(hBtn3, 'Anuluj'); set_button_id(hBtn3, ID_BTN_CANCEL);
        end else begin
          SetWindowTextW(hBtn1, 'Przerwij'); set_button_id(hBtn1, ID_BTN_ABORT);
          SetWindowTextW(hBtn2, 'Ponów'); set_button_id(hBtn2, ID_BTN_RETRY);
          SetWindowTextW(hBtn3, 'Ignoruj'); set_button_id(hBtn3, ID_BTN_IGNORE);
        end;
      end;
    end;
        {
        DlgBtnOK:
        begin
          // Pojedynczy przycisk OK na środku
          hBtn1 := create_button(hDlg, 'OK', (DlgW div 2) - (BtnW div 2), BtnY, BtnW, BtnH);
          set_button_id(hBtn1, ID_BTN_OK);
          set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);
        end;

        DlgBtnOKCancel:
        begin
          // OK po prawej (akcent), Anuluj po lewej (szary)
          hBtn1 := create_button(hDlg, 'OK', (DlgW div 2) + (BtnGap div 2), BtnY, BtnW, BtnH);
          set_button_id(hBtn1, ID_BTN_OK);
          set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

          hBtn2 := create_button(hDlg, 'Anuluj', (DlgW div 2) - BtnW - (BtnGap div 2), BtnY, BtnW, BtnH);
          set_button_id(hBtn2, ID_BTN_CANCEL);
          set_button_colors(hBtn2, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);
        end;

        DlgBtnYesNo:
        begin
          // Tak po prawej, Nie po lewej
          hBtn1 := create_button(hDlg, 'Tak', (DlgW div 2) + (BtnGap div 2), BtnY, BtnW, BtnH);
          set_button_id(hBtn1, ID_BTN_YES);
          set_button_colors(hBtn1, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

          hBtn2 := create_button(hDlg, 'Nie', (DlgW div 2) - BtnW - (BtnGap div 2), BtnY, BtnW, BtnH);
          set_button_id(hBtn2, ID_BTN_NO);
         set_button_colors(hBtn2, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);
        end;
      end;
       }
      // 3. Pętla modalna (blokada rodzica)
      if Owner <> 0 then EnableWindow(Owner, False);

      while GetMessage(@msg, 0, 0, 0) do
      begin
        if not IsWindow(hDlg) then Break;
        TranslateMessage(@msg);
        DispatchMessage(@msg);
      end;

      if Owner <> 0 then
      begin
        EnableWindow(Owner, True);
        SetForegroundWindow(Owner);
      end;
    end;

    // Zwracamy wynik, który został ustawiony w WM_COMMAND
    Result := CurrentDialogResult;
end;

procedure set_dialog_language(Lang: TDialogLanguage);
begin
  CurrentDialogLang := Lang;
end;

function input_box(Owner: HWND; const Title, Prompt: UnicodeString; var Value: UnicodeString; BgColor, TextColor, AccentColor, EditBgColor, EditTextColor: DWORD): Boolean;
var
  wc: TWndClassW;
  hDlg, hBtnOK, hBtnCancel, hBtnX, hEdit: HWND;
  msg: TMsg;
  DlgW, DlgH, PosX, PosY: Integer;
  OwnerRect: TRect;
  BtnW, BtnH, BtnGap, BtnY, StartX: Integer;
  GrayColor: DWORD;
  hEditFont: HFONT;
  hEditBrush: HBRUSH;
begin
  CurrentInputResult := False;
    CurrentInputText := Value; // Domyślna wartość w polu

    if not InputDialogClassRegistered then
    begin
      FillChar(wc, SizeOf(wc), 0);
      wc.lpfnWndProc := @input_dialog_proc;
      wc.hInstance := GetModuleHandle(nil);
      wc.hCursor := LoadCursor(0, IDC_ARROW);
      wc.lpszClassName := 'AvocadoInputDialogClass';
      wc.style := CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
      RegisterClassW(wc);
      InputDialogClassRegistered := True;
    end;

    DlgW := 400; DlgH := 200;
    BtnW := 100; BtnH := 35; BtnGap := 20;
    BtnY := DlgH - BtnH - 20;
    GrayColor := $404040;

    if (Owner <> 0) and GetWindowRect(Owner, OwnerRect) then
    begin
      PosX := OwnerRect.Left + ((OwnerRect.Right - OwnerRect.Left) div 2) - (DlgW div 2);
      PosY := OwnerRect.Top + ((OwnerRect.Bottom - OwnerRect.Top) div 2) - (DlgH div 2);
    end else begin PosX := 300; PosY := 300; end;

    hDlg := CreateWindowExW(WS_EX_TOPMOST, 'AvocadoInputDialogClass', nil,
      WS_POPUP or WS_VISIBLE, PosX, PosY, DlgW, DlgH, Owner, 0, GetModuleHandle(nil), nil);

    if hDlg <> 0 then
    begin
      SetPropW(hDlg, 'DlgBg', THandle(BgColor));
      SetPropW(hDlg, 'DlgTxt', THandle(TextColor));
      SetPropW(hDlg, 'DlgTitlePtr', THandle(Pointer(Title)));
      SetPropW(hDlg, 'DlgPromptPtr', THandle(Pointer(Prompt)));
      SetPropW(hDlg, 'DlgEditTxt', THandle(EditTextColor));
      SetPropW(hDlg, 'DlgEditBg', THandle(EditBgColor));


      hEditBrush := CreateSolidBrush(EditBgColor);
      SetPropW(hDlg, 'DlgEditBrush', THandle(hEditBrush));

      //tworzenie kontrolek
      hBtnX := create_button(hDlg, '✕', DlgW - 35, 5, 30, 30);
      set_button_id(hBtnX, ID_BTN_CLOSE_X);

      set_button_colors(hBtnX, BgColor, BgColor + $101010, BgColor - $050505, TextColor, BgColor);

      StartX := (DlgW - (2 * BtnW + BtnGap)) div 2;

      hBtnOK := create_button(hDlg, PWideChar(get_btn_text(ID_BTN_OK)), StartX, BtnY, BtnW, BtnH);
      set_button_id(hBtnOK, ID_BTN_OK);
      set_button_colors(hBtnOK, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

      hBtnCancel := create_button(hDlg, PWideChar(get_btn_text(ID_BTN_CANCEL)), StartX + BtnW + BtnGap, BtnY, BtnW, BtnH);
      set_button_id(hBtnCancel, ID_BTN_CANCEL);
      set_button_colors(hBtnCancel, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);

      // TWORZENIE POLA TEKSTOWEGO
      // Uwaga: Zakładam że w avoraiser.edit masz np. funkcję create_edit.
      // Jeśli jej sygnatura jest inna, podmień kolejność parametrów!
      // Poniższy kod używa domyślnego tworzenia z WinAPI (na wszelki wypadek):
      {hEdit := CreateWindowExW(WS_EX_CLIENTEDGE, 'EDIT', PWideChar(Value),
        WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL,
        20, 85, DlgW - 40, 25,
        hDlg, 0, GetModuleHandle(nil), nil);
      }
           // Zmieniamy styl na WS_BORDER (zamiast wypukłego WS_EX_CLIENTEDGE) - wygląda dużo bardziej płasko i nowocześnie
      hEdit := CreateWindowExW(0, 'EDIT', PWideChar(Value),
      WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL,
      20, 85, DlgW - 40, 25,
      hDlg, 0, GetModuleHandle(nil), nil);

      // Zapisujemy uchwyt w oknie, żeby procedura wyżej mogła zczytać tekst na kliknięcie OK
      SetPropW(hDlg, 'DlgEditHandle', hEdit);

      // Ustawienie nowoczesnej czcionki dla pola wpisywania
      hEditFont := CreateFontW(-15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
                                          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                          CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');
      SendMessage(hEdit, WM_SETFONT, WPARAM(hEditFont), 1);
      SetFocus(hEdit);

      if Owner <> 0 then EnableWindow(Owner, False);

      while GetMessage(@msg, 0, 0, 0) do
      begin
        if not IsWindow(hDlg) then Break;
        TranslateMessage(@msg);
        DispatchMessage(@msg);
      end;

      DeleteObject(hEditFont);
      DeleteObject(hEditBrush);
    end;

    // Przypisanie zczytanej wartości
    if CurrentInputResult then
      Value := CurrentInputText;

    Result := CurrentInputResult;
end;

function password_box(Owner: HWND; const Title, Prompt: UnicodeString;
  var Value: UnicodeString; BgColor, TextColor, AccentColor, EditBgColor,
  EditTextColor: DWORD): Boolean;
var
  wc: TWndClassW;
  hDlg, hBtnOK, hBtnCancel, hBtnX, hEdit: HWND;
  msg: TMsg;
  DlgW, DlgH, PosX, PosY: Integer;
  OwnerRect: TRect;
  BtnW, BtnH, BtnGap, BtnY, StartX: Integer;
  GrayColor: DWORD;
  hEditBrush: HBRUSH;
  hEditFont: HFONT;
begin
  CurrentInputResult := False;
    CurrentInputText := Value;

    // Używamy dokładnie tej samej procedury okna co input_box!
    if not InputDialogClassRegistered then
    begin
      FillChar(wc, SizeOf(wc), 0);
      wc.lpfnWndProc := @input_dialog_proc; // Magia re-używalności kodu
      wc.hInstance := GetModuleHandle(nil);
      wc.hCursor := LoadCursor(0, IDC_ARROW);
      wc.lpszClassName := 'AvocadoInputDialogClass';
      wc.style := CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
      RegisterClassW(wc);
      InputDialogClassRegistered := True;
    end;

    DlgW := 400; DlgH := 200;
    BtnW := 100; BtnH := 35; BtnGap := 20;
    BtnY := DlgH - BtnH - 20;
    GrayColor := $404040;

    if (Owner <> 0) and GetWindowRect(Owner, OwnerRect) then
    begin
      PosX := OwnerRect.Left + ((OwnerRect.Right - OwnerRect.Left) div 2) - (DlgW div 2);
      PosY := OwnerRect.Top + ((OwnerRect.Bottom - OwnerRect.Top) div 2) - (DlgH div 2);
    end else begin PosX := 300; PosY := 300; end;

    hDlg := CreateWindowExW(WS_EX_TOPMOST, 'AvocadoInputDialogClass', nil,
      WS_POPUP or WS_VISIBLE, PosX, PosY, DlgW, DlgH, Owner, 0, GetModuleHandle(nil), nil);

    if hDlg <> 0 then
    begin
      SetPropW(hDlg, 'DlgBg', THandle(BgColor));
      SetPropW(hDlg, 'DlgTxt', THandle(TextColor));
      SetPropW(hDlg, 'DlgTitlePtr', THandle(Pointer(Title)));
      SetPropW(hDlg, 'DlgPromptPtr', THandle(Pointer(Prompt)));
      SetPropW(hDlg, 'DlgEditTxt', THandle(EditTextColor));
      SetPropW(hDlg, 'DlgEditBg', THandle(EditBgColor));

      hEditBrush := CreateSolidBrush(EditBgColor);
      SetPropW(hDlg, 'DlgEditBrush', THandle(hEditBrush));

      // --- TWORZENIE PRZYCISKÓW ---
      hBtnX := create_button(hDlg, '✕', DlgW - 35, 5, 30, 30);
      set_button_id(hBtnX, ID_BTN_CLOSE_X);
      set_button_colors(hBtnX, BgColor, BgColor + $101010, BgColor - $050505, TextColor, BgColor);

      StartX := (DlgW - (2 * BtnW + BtnGap)) div 2;

      hBtnOK := create_button(hDlg, PWideChar(get_btn_text(ID_BTN_OK)), StartX, BtnY, BtnW, BtnH);
      set_button_id(hBtnOK, ID_BTN_OK);
      set_button_colors(hBtnOK, AccentColor, AccentColor + $101010, AccentColor - $101010, $FFFFFF, AccentColor);

      hBtnCancel := create_button(hDlg, PWideChar(get_btn_text(ID_BTN_CANCEL)), StartX + BtnW + BtnGap, BtnY, BtnW, BtnH);
      set_button_id(hBtnCancel, ID_BTN_CANCEL);
      set_button_colors(hBtnCancel, GrayColor, GrayColor + $101010, GrayColor - $101010, $DDDDDD, GrayColor);

      // --- TWORZENIE POLA TEKSTOWEGO Z UKRYWANIEM ZNAKÓW ---
      // Zauważ dodaną flagę ES_PASSWORD na końcu!
      hEdit := CreateWindowExW(0, 'EDIT', PWideChar(Value),
        WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL or ES_PASSWORD,
        20, 85, DlgW - 40, 25,
        hDlg, 0, GetModuleHandle(nil), nil);

      // Bonus: Zmieniamy znak maskujący na nowoczesną, dużą kropkę (Unicode: 9679)
      SendMessageW(hEdit, EM_SETPASSWORDCHAR, 9679, 0);

      SetPropW(hDlg, 'DlgEditHandle', hEdit);

      hEditFont := CreateFontW(-15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
                               OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                               CLEARTYPE_QUALITY, DEFAULT_PITCH, 'Segoe UI');
      SendMessage(hEdit, WM_SETFONT, WPARAM(hEditFont), 1);

      SetFocus(hEdit);

      if Owner <> 0 then EnableWindow(Owner, False);

      while GetMessage(@msg, 0, 0, 0) do
      begin
        if not IsWindow(hDlg) then Break;
        TranslateMessage(@msg);
        DispatchMessage(@msg);
      end;

      DeleteObject(hEditFont);
      DeleteObject(hEditBrush);
    end;

    if CurrentInputResult then
      Value := CurrentInputText;
    Result := CurrentInputResult;

end;

procedure show_toast(Owner: HWND; const MessageText: UnicodeString; BgColor,TextColor: DWORD; Duration: Integer; Width: Integer = 250; Height: Integer = 45);
var
  wc: TWndClassW;
  hToast: HWND;
  OwnerRect: TRect;
  PosX, PosY, ToastW, ToastH: Integer;
begin
    if not ToastClassRegistered then
      begin
        FillChar(wc, SizeOf(wc), 0);
        wc.lpfnWndProc := @toast_proc;
        wc.hInstance := GetModuleHandle(nil);
        wc.hCursor := LoadCursor(0, IDC_ARROW);
        wc.lpszClassName := 'AvocadoToastClass';
        //cień dla eleganckiego oderwania od tła
        wc.style := CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
        RegisterClassW(wc);
        ToastClassRegistered := True;
      end;

      // Wymiary toasta dość płaski, szeroki pasek
      //ToastW := 250;
      //ToastH := 45;


      if (Owner <> 0) and GetWindowRect(Owner, OwnerRect) then
      begin
        PosX := OwnerRect.Left + ((OwnerRect.Right - OwnerRect.Left) div 2) - (Width div 2);
        PosY := OwnerRect.Bottom - Height - 25; // Odstęp od dołu okna
      end else
      begin
        PosX := 10; PosY := 10;
      end;

      hToast := CreateWindowExW(WS_EX_TOPMOST or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE,
        'AvocadoToastClass', nil,
        WS_POPUP,
        PosX, PosY, Width, Height, Owner, 0, GetModuleHandle(nil), nil);

      if hToast <> 0 then
      begin
        SetPropW(hToast, 'ToastBg', THandle(BgColor));
        SetPropW(hToast, 'ToastTxt', THandle(TextColor));
        SetPropW(hToast, 'ToastMsgPtr', THandle(Pointer(MessageText)));

        SetTimer(hToast, TOAST_TIMER_ID, Duration, nil);
        ShowWindow(hToast, SW_SHOWNOACTIVATE);
      end;
end;

function show_action_sheet(Owner: HWND; const Title: UnicodeString; const Options, IconPaths: array of UnicodeString; BgColor, TextColor, AccentColor: DWORD): Integer;
var
wc: TWndClassW;
h_dlg, h_btn: HWND;
msg: TMsg;
dlg_w, dlg_h, pos_x, pos_y, i: Integer;
owner_rect: TRect;
h_bg_brush: HBRUSH;
h_font_main: HFONT;
h_icon_bmp: HBITMAP;
btn_w, btn_h, btn_y, btn_gap: Integer;
final_id: Int64;
combined_text: UnicodeString;
begin
  Result := -1;
  h_bg_brush := 0;

  // Rejestracja klasy (tylko jeśli nie zarejestrowana)
  if not PaletteClassRegistered then
  begin
    FillChar(wc, SizeOf(wc), 0);
    wc.lpfnWndProc := @action_sheet_proc;
    wc.hInstance := GetModuleHandle(nil);
    wc.hCursor := LoadCursor(0, IDC_ARROW);
    wc.lpszClassName := 'AvocadoActionSheetClass';
    wc.style := CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
    wc.cbWndExtra := 40;
    RegisterClassW(wc);
    PaletteClassRegistered := True;
  end;

  // Wymiary okna
  btn_w := 320; btn_h := 50; btn_gap := 10;
  dlg_w := 360;
  dlg_h := 95 + (Length(Options) * (btn_h + btn_gap));

  // Pozycjonowanie na ekranie
  if (Owner <> 0) and GetWindowRect(Owner, owner_rect) then
  begin
    pos_x := owner_rect.Left + ((owner_rect.Right - owner_rect.Left) div 2) - (dlg_w div 2);
    pos_y := owner_rect.Top + ((owner_rect.Bottom - owner_rect.Top) div 2) - (dlg_h div 2);
  end else begin pos_x := 400; pos_y := 300; end;

  h_dlg := CreateWindowExW(WS_EX_TOPMOST, 'AvocadoActionSheetClass', nil,
    WS_POPUP or WS_VISIBLE, pos_x, pos_y, dlg_w, dlg_h, Owner, 0, GetModuleHandle(nil), nil);

  if h_dlg <> 0 then
  begin
    h_bg_brush := CreateSolidBrush(BgColor);

    // Zapisujemy parametry w pamięci okna (Extra Bytes)
    SetWindowLongPtrW(h_dlg, 0, BgColor);
    SetWindowLongPtrW(h_dlg, 8, TextColor);
    SetWindowLongPtrW(h_dlg, 16, -1); // Tu trafi wynik
    SetPropW(h_dlg, 'SheetTitlePtr', THandle(Pointer(Title)));

    h_font_main := CreateFontW(-17, 0, 0, 0, FW_NORMAL, 0, 0, 0, EASTEUROPE_CHARSET,
                               OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                               DEFAULT_PITCH, 'Segoe UI');

    btn_y := 75;
    for i := Low(Options) to High(Options) do
    begin
      // Tworzymy przycisk (tekst przesunięty spacjami dla ikony)
      combined_text := '       ' + Options[i];
      h_btn := create_button(h_dlg, PWideChar(combined_text), (dlg_w - btn_w) div 2, btn_y, btn_w, btn_h);

      SetWindowLong(h_btn, GWL_STYLE, GetWindowLong(h_btn, GWL_STYLE) or BS_BITMAP);

      set_button_id(h_btn, 1000 + i);
      set_button_colors(h_btn, AccentColor, AccentColor + $0A0A0A, AccentColor - $0A0A0A, $FFFFFF, AccentColor);
      SendMessage(h_btn, WM_SETFONT, WPARAM(h_font_main), 1);

      // --- ŁADOWANIE IKONY BMP ---
      if (i <= High(IconPaths)) and (IconPaths[i] <> '') then
      begin
        h_icon_bmp := load_button_icon(IconPaths[i]);
        if h_icon_bmp <> 0 then
        begin
          // Systemowy sposób na ustawienie obrazka na przycisku
          SendMessage(h_btn, BM_SETIMAGE, IMAGE_BITMAP, LPARAM(h_icon_bmp));
        end;
      end;

      btn_y := btn_y + btn_h + btn_gap;
    end;

    if Owner <> 0 then EnableWindow(Owner, False);

    // Pętla komunikatów
    while GetMessage(@msg, 0, 0, 0) do
    begin
      if not IsWindow(h_dlg) then Break;
      // Jeśli w pamięci okna pojawił się wynik - kończymy
      if GetWindowLongPtrW(h_dlg, 16) <> -1 then Break;

      TranslateMessage(@msg);
      DispatchMessage(@msg);
    end;

    final_id := GetWindowLongPtrW(h_dlg, 16);
    if final_id >= 1000 then Result := final_id - 1000;

    if Owner <> 0 then EnableWindow(Owner, True);

    RemovePropW(h_dlg, 'SheetTitlePtr');
    DeleteObject(h_bg_brush);
    DeleteObject(h_font_main);
    DestroyWindow(h_dlg);
  end;
end;

function show_progress_dialog(Owner: HWND; const Title, Status: UnicodeString; BgColor, TextColor, AccentColor: DWORD): HWND;
var
WC: TWndClassW;
HDlg: HWND;
DlgW, DlgH, PosX, PosY: Integer;
OwnerRect: TRect;
HInst: THandle;
begin
 HInst := GetModuleHandle(nil);

  if GetClassInfoW(HInst, 'AvocadoProgressClass', @WC) = False then
  begin
    FillChar(WC, SizeOf(WC), 0);
    WC.lpfnWndProc := @progress_proc;
    WC.hInstance := HInst;
    WC.hCursor := LoadCursor(0, IDC_ARROW);
    WC.lpszClassName := 'AvocadoProgressClass';
    // Ustawiamy pędzel tła, aby uniknąć migotania przy tworzeniu
    //WC.hbrBackground := CreateSolidBrush(BgColor);
    WC.hbrBackground := 0;
    RegisterClassW(WC);
  end;

  DlgW := 420; DlgH := 130;

  if (Owner <> 0) and GetWindowRect(Owner, OwnerRect) then
  begin
    PosX := OwnerRect.Left + ((OwnerRect.Right - OwnerRect.Left) div 2) - (DlgW div 2);
    PosY := OwnerRect.Top + ((OwnerRect.Bottom - OwnerRect.Top) div 2) - (DlgH div 2);
  end else begin PosX := 400; PosY := 300; end;

  HDlg := CreateWindowExW(WS_EX_TOPMOST, 'AvocadoProgressClass', nil,
    WS_POPUP or WS_BORDER, PosX, PosY, DlgW, DlgH, Owner, 0, HInst, nil);

  if HDlg <> 0 then
  begin
    SetPropW(HDlg, 'TitleText', THandle(Pointer(Title)));
    SetPropW(HDlg, 'StatusText', THandle(Pointer(Status)));
    SetPropW(HDlg, 'BgColor', THandle(BgColor));
    SetPropW(HDlg, 'TextColor', THandle(TextColor));
    SetPropW(HDlg, 'AccentColor', THandle(AccentColor));
    SetPropW(HDlg, 'ProgressPos', 0);

    ShowWindow(HDlg, SW_SHOW);
    UpdateWindow(HDlg);
  end;

  Result := HDlg;
end;

procedure update_progress(HDlg: HWND; Position: Integer; const NewStatus: UnicodeString);
begin
   if HDlg = 0 then Exit;

  SetPropW(HDlg, 'ProgressPos', THandle(Position));

  if NewStatus <> '' then
    SetPropW(HDlg, 'StatusText', THandle(Pointer(NewStatus)));

  // Wymuszamy natychmiastowe przerysowanie
  InvalidateRect(HDlg, nil, False);
  UpdateWindow(HDlg);
end;

function get_file_name_from_user(h_wnd: HWND; is_save: Boolean; const filter: UnicodeString = 'Wszystkie pliki (*.*)|*.*'; const default_ext: UnicodeString = ''): UnicodeString;
var
ofn: OPENFILENAMEW;
file_buf: array[0..MAX_PATH] of WideChar;
win_filter: UnicodeString;
i: Integer;
begin
 Result := '';

  // 1. Przygotowanie buforów
  FillChar(file_buf, SizeOf(file_buf), 0);
  FillChar(ofn, SizeOf(ofn), 0);

  // Przetwarzanie filtra (zamiana '|' na techniczne '#0')
  // Dzięki temu możesz pisać 'Tekst|*.txt' zamiast 'Tekst'#0'*.txt'
  win_filter := filter;
  for i := 1 to Length(win_filter) do
    if win_filter[i] = '|' then win_filter[i] := #0;
  win_filter := win_filter + #0#0;

  // Konfiguracja struktury
  ofn.lStructSize := SizeOf(ofn);
  ofn.hwndOwner   := h_wnd;
  ofn.lpstrFile   := @file_buf;
  ofn.nMaxFile    := MAX_PATH;
  ofn.lpstrFilter := PWideChar(win_filter);
  ofn.nFilterIndex := 1;

  if Length(default_ext) > 0 then
    ofn.lpstrDefExt := PWideChar(default_ext);

  // Dobór flag w zależności od trybu
  // Przy zapisie nie używamy OFN_FILEMUSTEXIST (bo plik może być nowy)
  ofn.Flags := OFN_PATHMUSTEXIST or OFN_HIDEREADONLY;

  if is_save then
  begin
    ofn.Flags := ofn.Flags or OFN_OVERWRITEPROMPT;
    if GetSaveFileNameW(@ofn) then
      Result := UnicodeString(file_buf);
  end
  else
  begin
    ofn.Flags := ofn.Flags or OFN_FILEMUSTEXIST;
    if GetOpenFileNameW(@ofn) then
      Result := UnicodeString(file_buf);
  end;
end;



end.


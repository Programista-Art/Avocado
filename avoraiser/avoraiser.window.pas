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

Module:     avoraiser.window
Description:
*)
unit avoraiser.window;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,
  avoraiser.core,
  avoraiser.utils,
  avoraiser.listbox,
  avoraiser.events,
  avoraiser.layout;
  //avoraiser.timepicker;



type
TAvocadoWindowParams = record
  Parent: HWND;
  Title: string;
  Width: Integer;
  Height: Integer;
  X: Integer;
  Y: Integer;
  Visible: Boolean;
  BackgroundColor: DWORD; //kolor okna
  AllowDrag: Boolean; // Przeciąganie za tło
  Frameless: Boolean; // bezramkowe okno
  AllowMaximize: Boolean;
end;

type
  TAvocadoPaintEvent = procedure(Sender: HWND; DC: HDC);


function  create_window(Params: TAvocadoWindowParams): HWND;
procedure run(var msg: TMsg);
procedure set_on_paint(Handle: HWND; Event: TAvocadoPaintEvent);
procedure close_window(Handle: HWND);
procedure activate_window(Handle: HWND);
procedure set_window_icons(Handle: HWND; SmallIcon, BigIcon: HICON);
//MINMAXINFO (Ograniczenia rozmiaru) ---
procedure set_on_get_min_max_info(Handle: HWND; Event: TAvocadoMinMaxEvent);
function window_get_default_params: TAvocadoWindowParams;
procedure set_on_hit_test(Handle: HWND; Event: TAvocadoHitTestEvent);
// Sprawdza, czy okno jest zminimalizowane do paska zadań
function is_window_minimized(Handle: HWND): Boolean;
// Sprawdza, czy okno jest zmaksymalizowane na cały ekran
function is_window_maximized(Handle: HWND): Boolean;
//zdarzenia fokusa
procedure set_on_set_focus(Handle: HWND; Event: TAvocadoFocusEvent);
procedure set_on_kill_focus (Handle: HWND; Event: TAvocadoFocusEvent);
// Rejestruje procedurę obsługi timerów dla danego okna
procedure set_on_timer(Handle: HWND; Event: TAvocadoTimerEvent);
procedure set_on_drop_files(Handle: HWND; Event: TAvocadoDropFilesEvent);
procedure set_on_clipboard_render (Handle: HWND; OnRender: TAvocadoRenderFormatEvent; OnRenderAll: TAvocadoRenderAllEvent);
procedure set_on_sizing(Handle: HWND; Event: TAvocadoSizingEvent);
// Rejestracja zdarzenia w trakcie przesuwania
procedure set_on_moving(Handle: HWND; Event: TAvocadoMovingEvent);
// Rejestracja zdarzenia Zanim zmieni się pozycja
procedure set_on_window_pos_changing(Handle: HWND; Event: TAvocadoWindowPosEvent);

//Mysz
procedure set_on_mouse_move(Handle: HWND; Event: TAvocadoMouseEvent);
//scrolowanie zdarzenie
procedure set_on_vscroll(Handle: HWND; Event: TAvocadoScrollEvent);
procedure set_on_hscroll(Handle: HWND; Event: TAvocadoScrollEvent);
procedure set_on_click(ControlHandle: HWND; Event: TAvocadoEvent);
procedure set_on_change(ControlHandle: HWND; Event: TAvocadoEvent);
procedure set_opacity(Handle: HWND; Opacity: Byte);

//Zmiana stanu wyświetlania (pełny ekran, do paska, przywrócenie).
procedure maximize_window(Handle: HWND);
procedure minimize_window(Handle: HWND);
procedure restore_window(Handle: HWND);
function get_window_monitor_info(Handle: HWND): TAvocadoMonitorInfo;
procedure set_on_notify(Handle: HWND; Event: TAvocadoNotifyEvent);
// Włącza/Wyłącza przyklejanie do krawędzi (Snapping)
procedure set_window_sticky(Handle: HWND; Enable: Boolean; SnapDistance: Integer = 20);
//ustawienie koloru naglowka okna
procedure set_caption_color(Handle: HWND; Color: DWORD);
//ustawienie koloru tekstu naglowka okna
procedure set_caption_text_color(Handle: HWND; Color: DWORD);
//tysowanie teksta na srodku okna
procedure draw_text_center(Handle: HWND; const AText: string; Color: DWORD);
// Zablokowane okno nie reaguje na myszkę ani klawiaturę.
procedure set_window_enabled(Handle: HWND; Enable: Boolean);
function is_window_on_top(Handle: HWND): Boolean;
procedure set_color(Handle: HWND; Color: DWORD);
//Zawsze na wierzchu
procedure set_always_on_top(Handle: HWND; Enable: Boolean);
// Wyłączanie ramki (np. dla Splash Screen lub Fullscreen)
procedure set_border(Handle: HWND; Enable: Boolean);
// Czy użytkownik może przeciągać krawędzie okna.
procedure set_sizable(Handle: HWND; Enable: Boolean);
// Ukrywanie/Pokazywanie przycisku minimalizacji
procedure set_minimize_button(Handle: HWND; Enable: Boolean);
function get_color(Handle: HWND): DWORD;
// Pokaż okno (jeśli było ukryte)
procedure show(Handle: HWND);
procedure hide(Handle: HWND);
// kolejność z-order
procedure bring_to_top(Handle: HWND);
procedure send_to_back(Handle: HWND);
// ograniczenia (constraints)
procedure set_min_window_size (Handle: HWND; MinWidth, MinHeight: Integer);
//Reakcja na przesunięcie okna
procedure set_on_move(Handle: HWND; OnMoveEvent: TAvocadoEvent);
// odświeżanie (painting
procedure invalidate(Handle: HWND);
// Repaint Wymusza odrysowanie TERAZ (natychmiast).
procedure repaint(Handle: HWND);
// rejestracja zdarzeń stanu
procedure set_on_activate_app(Handle: HWND; Event: TAvocadoActivateAppEvent);
procedure set_on_enable (Handle: HWND; Event: TAvocadoEnableEvent);
procedure begin_update(Handle: HWND);
procedure end_update(Handle: HWND);
procedure snapshot_to_clipboard(Handle: HWND);
procedure set_on_sys_key_down(Handle: HWND; Event: TAvocadoKeyEvent);
procedure set_on_sys_key_up(Handle: HWND; Event: TAvocadoKeyEvent);
//Przyciski
procedure set_on_char(Handle: HWND; Event: TAvocadoCharEvent);
// Znaki systemowe (np. ALT + Litera)
procedure set_on_sys_char(Handle: HWND; Event: TAvocadoCharEvent);
// "Martwe" znaki (np. tylda ~, która czeka na literę n, żeby zrobić ñ)
procedure set_on_dead_char(Handle: HWND; Event: TAvocadoCharEvent);
// Nowoczesne znaki Unicode (dla pełnej zgodności z nowszymi systemami)
procedure set_on_uni_char(Handle: HWND; Event: TAvocadoCharEvent);
//funkcje wspolne
//Ustawia widoczność (True = Pokaż, False = Ukryj)
procedure set_component_visible(hComponent: HWND; Visible: Boolean);
//Przełącza widoczność (Jak jest widoczny to ukrywa, jak ukryty to pokazuje)
procedure toggle_component_visible(hComponent: HWND);
//Zaokraglenia rogów
procedure set_component_rounding(hComponent: HWND; Radius: Integer);
//Wygladzenie krawedzi
procedure rounding(hComponent: HWND; Radius: Integer);
//Rysowanie bordera
procedure draw_border(hWnd: HWND);
//Wylaczenie przycisku maksymalizaji okna
procedure set_window_maximize_button(h_wnd: HWND; enabled: Boolean);
//Wylaczenie przycisku minimalizacji okna
procedure set_window_minimize_button(h_wnd: HWND; enabled: Boolean);
//Wylaczenie przycisku zamkniecia okna x
procedure set_window_close_button(h_wnd: HWND; enabled: Boolean);
// Miganie oknem na pasku zadań (Powiadomienia)
// Handle: uchwyt okna
// Count: liczba mrugnięć (wpisz -1, aby mrugało dopóki nie klikniesz w okno)
// Interval: szybkość w ms (0 = domyślna systemowa, np. 500ms)
procedure flash_window(h_wnd: HWND; count: Integer; interval: Integer);
//Funkcja do blokowania zmiany rozmiaru
procedure set_window_resizable(h_wnd: HWND; is_resizable: Boolean);
//Automatyczne zarzadzanie komunikatem MSG
procedure run_app;
procedure center_window(h_wnd: HWND);



implementation
function MonitorFromWindow(hwnd: HWND; dwFlags: DWORD): HMONITOR; stdcall; external 'user32.dll';
function GetMonitorInfoW(hMonitor: HMONITOR; lpmi: PMONITORINFO): BOOL; stdcall; external 'user32.dll';
procedure DragAcceptFiles(hWnd: HWND; fAccept: BOOL); stdcall; external 'shell32.dll' name 'DragAcceptFiles';
function DragQueryFile(hDrop: THandle; iFile: UINT; lpszFile: PChar; cch: UINT): UINT; stdcall; external 'shell32.dll' name 'DragQueryFileA';
procedure DragFinish(hDrop: THandle); stdcall; external 'shell32.dll' name 'DragFinish';
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';


procedure UpdateStyle(Handle: HWND; Flag: LongInt; Enable: Boolean);
var
  Style: LongInt;
begin
  if Handle = 0 then Exit;

  Style := GetWindowLong(Handle, GWL_STYLE);
  if Enable then
    Style := Style or Flag
  else
    Style := Style and not Flag;

  SetWindowLong(Handle, GWL_STYLE, Style);

  // SWP_FRAMECHANGED informuje system, że zmieniliśmy wygląd ramki
  SetWindowPos(Handle, 0, 0, 0, 0, 0,
               SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;


function AvocadoWindowProc(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM): LRESULT; stdcall;
var
CanDrag: PBoolean;
PS: TPaintStruct;
DC: HDC;
Rect: TRect;
Brush: HBRUSH;
EventToRun: TAvocadoEvent;
ResizeToRun: TAvocadoEvent;
KeyDownToRun: TAvocadoKeyEvent;
KeyUpToRun: TAvocadoKeyEvent;
CloseQueryFunc: TAvocadoCloseEvent;
CanClose: Boolean;
MMI: PMinMaxInfo;
MinW, MinH: Integer;
MoveFunc: TAvocadoEvent;
SizingFunc: TAvocadoSizingEvent;
PR: PRect;
MovingFunc: TAvocadoMovingEvent;
PosFunc: TAvocadoWindowPosEvent;
PWinPos: PWINDOWPOS;
SnapDist: Integer;
MonInfo: TAvocadoMonitorInfo;
WinW, WinH: Integer;
Idx: Integer;
MouseX, MouseY: Integer;
WheelDelta: Integer;
CB: ^TMouseCallbacks;
i: integer;
Pt: TPoint;
KCB: ^TKeyboardCallbacks;
OldProcPtr: HANDLE;
CmdID: Word;
SysCmd: Integer;
UserHit: Integer;
TitleBarRect: TRect;
TitleBrush: HBRUSH;
ContentRect: TRect;
hDrop: THandle;
FileName: array[0..MAX_PATH] of WideChar;
FileCount, k: Integer; // Zmienna pętli to 'k' (unikanie konfliktu z 'i')
//FileList: TStringList;
DropIdx: Integer;
ClipIdx: Integer;
pHeader: PNMHDR;
NotifyIdx: Integer;
ScrollCode: Word;
Pos16: SmallInt;
CurrentRegistry: array of TScrollEntry; // Wskaźnik na odpowiednią tablicę
UserBrush: HBRUSH;
hControlUnivesal: HWND;
hDCUniversal: HDC;
PropBrush: HBRUSH;
PropTextCol, PropBgCol: COLORREF;
TimerID: UINT_PTR;
X, Y: Integer;
hParentCombo: HWND;
//Dotyczy ComBoBoxa
NotifyCode: Word;
hComboParent: HWND;
hListBox: HWND;
hDCList: HDC;
TextCol: COLORREF;
BgCol: COLORREF;
hTargetCombo: HWND;
Radius, NewW, NewH: Integer;
myhRgn: HRGN;
DrawStruct: PDRAWITEMSTRUCT;
ControlHandle: HWND;
OnDraw: TAvoDrawItemEvent;
OnQuery: TAvocadoQueryEndSessionEvent;
OnEnd: TAvocadoEndSessionEvent;
FocusPtr: THandle;
OnFocus: TAvocadoFocusEvent;
TimerPtr: THandle;
OnTimer: TAvocadoTimerEvent;
DropPtr: THandle;
OnDrop: TAvocadoDropFilesEvent;
Ptr: THandle;
OnMouse: TAvocadoMouseEvent; // Zmienna proceduralna
OnRender: TAvocadoRenderFormatEvent;
OnRenderAll: TAvocadoRenderAllEvent;
OnHit: TAvocadoHitTestEvent;
OnNCMouse: TAvocadoNCMouseEvent;
OnScroll: TAvocadoScrollEvent;
OnSizing: TAvocadoSizingEvent;
OnMoving: TAvocadoMovingEvent;
OnPosCh: TAvocadoWindowPosEvent;
new_w, new_h: Integer;
on_resize: TAvocadoResizeEvent;
my_h_rgn: HRGN;
win_rect: TRect;
on_key: TAvocadoKeyEvent; // Pojemnik na wyciągniętą funkcję
key_code: Word;
on_close: TAvocadoCloseEvent;
p_link: p_av_en_link;        // Wskaźnik do danych o kliknięciu
tr: t_av_text_range;         // Instrukcja: "co i dokąd skopiować"
url_text: array[0..511] of WideChar;
nm_hdr: PNMHDR;
drop_ptr: THandle;
on_drop: t_av_drop_files_event;
on_time_change: t_av_time_change_cb;
OnContext: t_av_context_event;
PosX, PosY: SmallInt;
//EventToRun: t_av_event;
hControl: HWND;

begin
  //case Message of
  case LongInt(u_msg) of
    // obsługa kolorów (properties)
    WM_CTLCOLOREDIT,   // Pola tekstowe (Edit, Memo)    //CheckBoxy, RadioButtony (ale nie zwykłe przyciski!)
    WM_CTLCOLORSTATIC, // Etykiety (Label), Ramki (GroupBox), Tekst Checkboxa
    WM_CTLCOLORBTN,
    WM_CTLCOLORLISTBOX:

    begin
      hDCUniversal := HDC(w_param);       // Kontekst graficzny
      hControlUnivesal := HWND(l_param); // Uchwyt kontrolki
      // Próbujemy pobrać pędzel bezpośrednio z kontrolki
      PropBrush := HBRUSH(GetPropW(hControlUnivesal, AV_PROP_BRUSH));

      // SPECJALNA OBSŁUGA COMBOBOXA (Lista rozwijana)
      // Jeśli to jest ListBox, ale nie ma własnego pędzla, to może być "dziecko" ComboBoxa.
      // Wtedy musimy "pożyczyć" kolory od rodzica (ComboBoxa).
      if (LongInt(u_msg) = WM_CTLCOLORLISTBOX) and (PropBrush = 0) then
      begin
         hParentCombo := GetParent(hControlUnivesal);
         if hParentCombo <> 0 then
         begin
            // Sprawdzamy, czy rodzic (ComboBox) ma ustawiony pędzel
            PropBrush := HBRUSH(GetPropW(hParentCombo, AV_PROP_BRUSH));

            if PropBrush <> 0 then
            begin
               // KLUCZOWE: Podmieniamy uchwyt na rodzica!
               // Dzięki temu funkcja get_prop_color poniżej pobierze kolory
               // z ComboBoxa, a nie z tej tymczasowej listy systemowej.
               hControlUnivesal := hParentCombo;
            end;
         end;
      end;

      // Aplikowanie kolorów (Jeśli znaleźliśmy pędzel - własny lub rodzica)
      if PropBrush <> 0 then
      begin
         // Pobieramy kolory z właściwości (dzięki podmianie uchwytu działa to też dla ComboBoxa)
         PropBgCol   := get_prop_color(hControlUnivesal, AV_PROP_BG_COLOR, $121212);
         PropTextCol := get_prop_color(hControlUnivesal, AV_PROP_TEXT_COLOR, $FFFFFF);

         SetTextColor(hDCUniversal, PropTextCol);
         SetBkColor(hDCUniversal, PropBgCol);

         // 4. TRYB RYSOWANIA TŁA LITER
         // Dla Labeli i Buttonów (Static/Btn) chcemy TRANSPARENT (przezroczyste tło liter).
         // Dla Editów i ListBoxów MUSI być OPAQUE (zamalowywanie tła),
         // inaczej przy przewijaniu literki będą się nakładać na siebie.
         if (LongInt(u_msg) = WM_CTLCOLORSTATIC) or (LongInt(u_msg) = WM_CTLCOLORBTN) then
            SetBkMode(hDCUniversal, TRANSPARENT)
         else
            SetBkMode(hDCUniversal, OPAQUE);

         Result := LRESULT(PropBrush);
         Exit;
      end;

      // 5. FALLBACK (Domyślny ciemny motyw, jeśli nic nie ustawiono)
      SetTextColor(hDCUniversal, $FFFFFF); // Biały tekst
      SetBkColor(hDCUniversal, $121212);   // Ciemne tło liter
      SetBkMode(hDCUniversal, OPAQUE);     // Bezpieczniej dać Opaque dla fallbacku

      // Zwracamy czarny pędzel systemowy (lub stwórz globalny pędzel $121212 dla idealnego dopasowania)
      Result := LRESULT(GetStockObject(BLACK_BRUSH));
      Exit;
      end;



    // Wklej to do instrukcji case w AvocadoWindowProc
    WM_GETMINMAXINFO:
    begin
      // 1. Sprawdzamy, czy użytkownik ustawił minimalną szerokość
      Ptr := GetProp(h_wnd, AV_PROP_ON_MINMAX);
      if Ptr <> 0 then
      TAvocadoMinMaxEvent(Pointer(Ptr))(h_wnd, PMinMaxInfo(l_param));
      Result := 0;
      Exit;
      // 2. FALLBACK: Obsługa właściwości minimalnych rozmiarów (jeśli nie ma zdarzenia)
      // To zostawiamy, bo to fajny "automat" Avocado
      Ptr := GetPropW(h_wnd, 'AvocadoMinW'); // Lub Twoja stała AV_PROP_MIN_WIDTH
      if Ptr <> 0 then
        PMinMaxInfo(l_param)^.ptMinTrackSize.x := Integer(Ptr);

      Ptr := GetPropW(h_wnd, 'AvocadoMinH'); // Lub Twoja stała AV_PROP_MIN_HEIGHT
      if Ptr <> 0 then
        PMinMaxInfo(l_param)^.ptMinTrackSize.y := Integer(Ptr);

      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
    end;

        WM_TIMER:
        begin
          // Pobieramy adres funkcji z szufladki
          TimerPtr := GetProp(h_wnd, AV_PROP_ON_TIMER);

          // Jeśli coś tam jest, rzutujemy i wywołujemy
          if TimerPtr <> 0 then
          begin
            OnTimer := TAvocadoTimerEvent(Pointer(TimerPtr));
            // WParam w komunikacie WM_TIMER to identyfikator (ID) timera
            OnTimer(h_wnd, w_param);
            Result := 0;
            Exit;
          end;
        end;
     // --- OBSŁUGA POLECEŃ SYSTEMOWYCH (Min, Max, Close, Screensaver) ---
    WM_SYSCOMMAND:
    begin
      // 1. Sprawdzamy, co to za komenda (maskujemy dolne 4 bity, bo system używa ich wewnętrznie)
      SysCmd := w_param and $FFF0;

      // Tutaj mógłbyś wywołać zdarzenie użytkownika: OnSysCommand(Window, SysCmd, ...)

      // PRZYKŁAD: Blokada wygaszacza ekranu
      if (SysCmd = SC_SCREENSAVE) or (SysCmd = SC_MONITORPOWER) then
      begin
        // Jeśli zwrócisz 0, wygaszacz się nie włączy
        // Result := 0; Exit;
      end;

      // WAŻNE: Musisz przekazać to do DefWindowProc, inaczej nie zadziała
      // przesuwanie okna, minimalizacja ani przycisk X!
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;
    WM_DRAWITEM:
    begin
       if (PDrawItemStruct(l_param)^.CtlType = ODT_LISTBOX) or
          (PDrawItemStruct(l_param)^.CtlType = ODT_COMBOBOX) then
       begin
         draw_listbox_item(l_param);

         Result := 1;
         Exit;
       end;
      {
      draw_listbox_item(LParam);
      DrawStruct := PDRAWITEMSTRUCT(LParam);
      ControlHandle := DrawStruct^.hwndItem;
      if GetProp(ControlHandle, AV_PROP_ON_DRAW) <> 0 then
      begin
        // 4. Pobieramy adres funkcji z ListBoxa
        OnDraw := TAvoDrawItemEvent(GetProp(ControlHandle, AV_PROP_ON_DRAW));
        //draw_listbox_item(LParam);
         Result := 1; // Ważne: Zwracamy 1, że obsłużono

        // 5. Wywołujemy funkcję (Okno mówi: "ListBoxie, narysuj się sam!")
        OnDraw(ControlHandle, DrawStruct);

        Result := 1; // Obsłużono
        Exit;
      end;
      }
    end;

    WM_ERASEBKGND:
    begin
      //DC := HDC(THandle(WParam));
      DC := HDC(w_param);
      PropBrush := HBRUSH(GetPropW(h_wnd, AV_PROP_BRUSH));

      if PropBrush <> 0 then
      begin
        GetClientRect(h_wnd, Rect);
        FillRect(DC, Rect, PropBrush);
        Result := 1;
        Exit;
      end;

     // Jeśli pędzla brak, malujemy na czarno (zabezpieczenie)
      GetClientRect(h_wnd, Rect);
      FillRect(DC, Rect, GetStockObject(BLACK_BRUSH));
      Result := 1;
      Exit;
    end;


    // --- OBSŁUGA MENU (Init & Select) ---
    WM_INITMENUPOPUP, WM_MENUSELECT:
    begin
      Idx := -1;
      for i := 0 to High(MenuRegistry) do
        if MenuRegistry[i].Handle = h_wnd then begin Idx := i; Break; end;

      if Idx <> -1 then
      begin
        if u_msg = WM_INITMENUPOPUP then
        begin
           // WParam = HMENU, LoWord(LParam) = Index (ignorujemy), HiWord(LParam) = IsWindowMenu
           if Assigned(MenuRegistry[Idx].Callbacks.OnInitPopup) then
             MenuRegistry[Idx].Callbacks.OnInitPopup(h_wnd, HMENU(w_param), Boolean(HiWord(l_param)));
        end
        else // WM_MENUSELECT
        begin
           // LoWord(WParam) = ItemID, HiWord(WParam) = Flags, LParam = HMENU
           if Assigned(MenuRegistry[Idx].Callbacks.OnSelect) then
             MenuRegistry[Idx].Callbacks.OnSelect(h_wnd, w_param and $FFFF, (w_param shr 16) and $FFFF, HMENU(l_param));
        end;
      end;

      // WM_MENUSELECT wymaga zwrócenia 0 jeśli przetworzono, ale DefWindowProc też jest OK.
      if u_msg = WM_INITMENUPOPUP then
      begin
        Result := 0;
        Exit; // InitPopup nie powinien iść do DefWindowProc jeśli chcemy go kontrolować
      end;

      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
    end;


    // --- KLIKNIĘCIA (COMMAND) ---
    {WM_COMMAND:
    begin
      // --- DIAGNOSTYKA START ---
      // 1. Czy w ogóle wchodzimy do WM_COMMAND?
      // Jeśli to się nie pokaże po wyborze z listy, znaczy że Subclassing (ComboBoxProc) blokuje sygnał.
     { if HiWord(WParam) = CBN_SELCHANGE then
      begin
         MessageBoxW(0, 'Sygnał CBN_SELCHANGE dotarł do okna!', 'Debug', 0);
      end;
      }
      if LParam <> 0 then
       begin
          // Tylko logika zdarzeń, bez naprawiania grafiki (bo ComboBox naprawia się sam)
          NotifyCode := HiWord(WParam);
          EventToRun := FindEvent(HWND(LParam));

          if Assigned(EventToRun) then
          begin
             if (NotifyCode = BN_CLICKED) or (NotifyCode = CBN_SELCHANGE) then
                EventToRun(HWND(LParam));
          end;
       end
       else
       begin
          CmdID := LoWord(WParam);
       end;

       Result := 0;
       Exit;
    end;
    }
    WM_COMMAND:
    begin
      // Przypadek A: Komunikat od kontrolki (LParam = Handle kontrolki)
      if l_param <> 0 then
      begin
        hControl := HWND(l_param);
        NotifyCode := HiWord(w_param);
        // Sprawdzamy, czy to kliknięcie (BN_CLICKED / STN_CLICKED) lub zmiana wyboru (CBN_SELCHANGE)
        if (NotifyCode = BN_CLICKED) or (NotifyCode = CBN_SELCHANGE) then
        begin
          // Pytamy KONTROLKĘ (hControl), czy ma przypisane zdarzenie
          // Bezpośrednie rzutowanie na Twój typ TAvocadoEvent
          EventToRun := TAvocadoEvent(Pointer(GetPropW(hControl, AV_PROP_ON_EVENT)));

          // Jeśli funkcja jest przypisana, wywołujemy ją przekazując uchwyt
          if Assigned(EventToRun) then
            EventToRun(hControl);
        end;
      end
      // Przypadek B: Komunikat od Menu lub akceleratora (l_param = 0)
      else
      begin
        CmdID := LoWord(w_param);
        // Tu w przyszłości obsłużysz menu główne
      end;

       { // Sprawdzamy, czy to kliknięcie (BN_CLICKED) lub zmiana wyboru (CBN_SELCHANGE)
        // Wartości: BN_CLICKED = 0, CBN_SELCHANGE = 1, STN_CLICKED = 0
        if (NotifyCode = BN_CLICKED) or (NotifyCode = CBN_SELCHANGE) then
        begin
          // Pytamy KONTROLKĘ (LParam), czy ma przypisane zdarzenie
          Ptr := GetProp(HWND(l_param), AV_PROP_ON_EVENT);

          if Ptr <> 0 then
          begin
            EventToRun := TAvocadoEvent(Pointer(Ptr));
            EventToRun(HWND(l_param)); // Wywołujemy zdarzenie dla kontrolki
          end;
        end;
      end
      // Przypadek B: Komunikat od Menu lub akceleratora (LParam = 0)
      else
      begin
        CmdID := LoWord(w_param);
        // Tu w przyszłości obsłużysz menu główne (jeśli będziesz używał Resource ID)
      end;
       }
      Result := 0;
      Exit;
    end;

    // --- HIT TEST (Gdzie jest myszka?) ---
    WM_NCHITTEST:
    begin
      // 1. Najpierw pytamy system o standardowe zachowanie (krawędzie, paski itp.)
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);

      // 2. Jeśli mysz jest wewnątrz okna (HTCLIENT), sprawdzamy czy mamy własną logikę
      if Result = HTCLIENT then
      begin
        Ptr := GetProp(h_wnd, AV_PROP_ON_HITTEST);
        if Ptr <> 0 then
        begin
          OnHit := TAvocadoHitTestEvent(Pointer(Ptr));

          // Wywołujemy funkcję użytkownika
          // Współrzędne w WM_NCHITTEST są ekranowe, wyciągamy je tak samo:
          UserHit := OnHit(h_wnd,
                           SmallInt(l_param and $FFFF),
                           SmallInt((l_param shr 16) and $FFFF));

          // Jeśli użytkownik zwrócił coś innego niż -1 (np. HTCAPTION), nadpisujemy
          if UserHit <> -1 then
          begin
            Result := UserHit;
            Exit;
          end;
        end;
      end;
      // Zwracamy wynik systemowy
      Exit;
    end;
    // po zmianie rozmiaru
    WM_SIZE:
    begin

      // Od razu wyciągamy wymiary z l_param (przydadzą się wszędzie)
      new_w := SmallInt(l_param and $FFFF);
      new_h := SmallInt(l_param shr 16);

      //  Wywołujemy podpięte zdarzenie (Nowy system "szufladek")
      ptr := GetPropA(h_wnd, AV_PROP_ON_RESIZE);
      //ptr := GetPropA(h_wnd, PChar(AV_PROP_ON_RESIZE));
      if ptr <> 0 then
      begin
        on_resize := TAvocadoResizeEvent(Pointer(ptr));
        on_resize(h_wnd, new_w, new_h, w_param);
      end;

      if w_param <> SIZE_MINIMIZED then
      begin
        // A. Zaokrąglenie okna
        radius := Integer(GetPropW(h_wnd, 'AvocadoRadius'));
        if radius > 0 then
        begin
          // Pobieramy prawdziwy, pełny rozmiar okna (razem z tytułem i ramkami)
          GetWindowRect(h_wnd, win_rect);

          // Tworzymy region na podstawie różnicy współrzędnych ekranowych
          my_h_rgn := CreateRoundRectRgn(0, 0,
                                         win_rect.Right - win_rect.Left,
                                         win_rect.Bottom - win_rect.Top,
                                         radius, radius);
          SetWindowRgn(h_wnd, my_h_rgn, True);
        end;

        // B. Wywołaj system Anchors
        update_layout(h_wnd);
      end;

    end;

   { WM_NCHITTEST:
    begin
      // 1. Najpierw pytamy system Windows, co on o tym sądzi
      // (To ważne, żeby działało zmienianie rozmiaru na krawędziach)
      Result := DefWindowProcW(Window, Message, WParam, LParam);

      // 2. Jeśli system mówi "To jest wnętrze okna" (HTCLIENT),
      // to możemy sprawdzić, czy użytkownik nie chce tu zrobić paska tytułu.
      if Result = HTCLIENT then
      begin
        Idx := -1;
        for i := 0 to High(MouseRegistry) do
          if MouseRegistry[i].Handle = Window then begin Idx := i; Break; end;

        if (Idx <> -1) and Assigned(MouseRegistry[Idx].Callbacks.OnHitTest) then
        begin
          MouseX := SmallInt(LParam and $FFFF);
          MouseY := SmallInt((LParam shr 16) and $FFFF);

          // Pytamy funkcję użytkownika
          //Oczekujemy, że zwróci np. HTCAPTION, HTCLIENT, albo -1 (brak zmiany)
          UserHit := MouseRegistry[Idx].Callbacks.OnHitTest(Window, MouseX, MouseY);

          // Jeśli użytkownik zwrócił konkretną wartość (np. HTCAPTION), nadpisujemy system
          if UserHit <> -1 then
          begin
            Result := UserHit;
            Exit;
          end;
        end;
      end;

      // Zwracamy wynik (systemowy lub nadpisany)
      Exit;
    end;
    }
    // --- OBSŁUGA ZASILANIA I URZĄDZEŃ ---
    WM_POWERBROADCAST, WM_DEVICECHANGE:
    begin
      // 1. Sprawdzamy, która "szufladka" nas interesuje
      if u_msg = WM_POWERBROADCAST then
        ptr := GetPropA(h_wnd, AV_PROP_ON_POWER)
      else
        ptr := GetPropA(h_wnd, AV_PROP_ON_DEVICE);

      // 2. Jeśli w szufladce jest adres procedury - wywołujemy ją
      if ptr <> 0 then
      begin
        // Rzutujemy i wywołujemy (oba typy mają te same parametry)
        TAvocadoPowerEvent(Pointer(ptr))(h_wnd, w_param, l_param);
      end;

      // Zwrócenie 1 (TRUE) jest standardem dla tych komunikatów
      Result := 1;
      Exit;
    end;

    {WM_POWERBROADCAST, WM_DEVICECHANGE:
    begin
      // 1. WM_POWERBROADCAST (Bateria, Uśpienie)
      if u_msg = WM_POWERBROADCAST then
      begin
        Idx := -1;
        for k := 0 to High(PowerRegistry) do
          if PowerRegistry[k].Handle = h_wnd then begin Idx := k; Break; end;

        if (Idx <> -1) and Assigned(PowerRegistry[Idx].OnPower) then
          PowerRegistry[Idx].OnPower(h_wnd, w_param, l_param);

        // Zwrócenie TRUE (1) jest ważne - w starszych Windowsach pozwalało to na uśpienie.
        // W nowych jest informacyjne.
        Result := 1;
        Exit;
      end

      // 2. WM_DEVICECHANGE (USB, Dyski)
      else if u_msg = WM_DEVICECHANGE then
      begin
        Idx := -1;
        for k := 0 to High(DeviceRegistry) do
          if DeviceRegistry[k].Handle = h_wnd then begin Idx := k; Break; end;

        if (Idx <> -1) and Assigned(DeviceRegistry[Idx].OnDevice) then
          DeviceRegistry[Idx].OnDevice(h_wnd, w_param, l_param);

        Result := 1;
        Exit;
      end;
    end;
    }
    // --- W TRAKCIE ZMIANY ROZMIARU (WM_SIZING) ---
   { WM_SIZING:
    begin
      SizingFunc := FindSizingEvent(Window);
      if Assigned(SizingFunc) then
      begin
        PR := PRect(LParam);
        SizingFunc(Window, PR^);
        Result := 1; // 1 = przetworzono
        Exit;
      end;
      // Brak Exit = idź do DefWindowProc
    end;
    }




    WM_SETFOCUS, WM_KILLFOCUS:
    begin
      // 1. Wybieramy odpowiedni klucz w zależności od komunikatu
      if u_msg = WM_SETFOCUS then
        FocusPtr := GetProp(h_wnd, AV_PROP_ON_SET_FOCUS)
      else
        FocusPtr := GetProp(h_wnd, AV_PROP_ON_KILL_FOCUS);

      // 2. Jeśli pod tym kluczem coś jest schowane, wywołujemy to
      if FocusPtr <> 0 then
      begin
        OnFocus := TAvocadoFocusEvent(Pointer(FocusPtr));
        if Assigned(OnFocus) then OnFocus(h_wnd);
      end;

      // 3. Obsługa subclassingu (bardzo ważne dla Memo i innych kontrolek)
      OldProcPtr := GetProp(h_wnd, 'OldWndProc');
      if OldProcPtr <> 0 then
        Exit(CallWindowProc(WNDPROC(OldProcPtr), h_wnd, u_msg, w_param, l_param))
      else
        Exit(DefWindowProcW(h_wnd, u_msg, w_param, l_param));
    end;


    // obsługa klawiatury
    // --- OBSŁUGA KLAWIATURY I TEKSTU ---
    WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP,
    WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_UNICHAR:
    begin
      // 1. Handshake dla Unicode (potwierdza systemowi, że obsługujemy UTF-16)
      if (u_msg = WM_UNICHAR) and (w_param = $FFFF) then

      begin
        Result := 1;
        Exit;
      end;

      // Pobieramy odpowiednią właściwość (UŻYWAMY GetPropA!)
      case u_msg of
        WM_KEYDOWN:    ptr := GetPropA(h_wnd, AV_PROP_ON_KEY_DOWN);
        WM_KEYUP:      ptr := GetPropA(h_wnd, AV_PROP_ON_KEY_UP);
        WM_SYSKEYDOWN: ptr := GetPropA(h_wnd, AV_PROP_ON_SYS_KEY_DOWN);
        WM_SYSKEYUP:   ptr := GetPropA(h_wnd, AV_PROP_ON_SYS_KEY_UP);
        WM_CHAR:       ptr := GetPropA(h_wnd, AV_PROP_ON_CHAR);
        WM_SYSCHAR:    ptr := GetPropA(h_wnd, AV_PROP_ON_SYS_CHAR);
        WM_DEADCHAR:   ptr := GetPropA(h_wnd, AV_PROP_ON_DEAD_CHAR);
        WM_UNICHAR:    ptr := GetPropA(h_wnd, AV_PROP_ON_UNI_CHAR);
      else
        ptr := 0;
      end;

      // Wywołanie, jeśli zdarzenie jest przypisane
      if ptr <> 0 then
      begin
        //if u_msg = WM_KEYDOWN then Windows.Beep(2000, 100);
        case u_msg of
          // Grupa 1: Klawisze fizyczne (Virtual Keys) -> Word
          WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP:
            TAvocadoKeyEvent(Pointer(ptr))(h_wnd, Word(w_param));

          // Grupa 2: Znaki tekstowe -> WideChar
          WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_UNICHAR:
            TAvocadoCharEvent(Pointer(ptr))(h_wnd, WideChar(w_param));
        end;
      end;

      // 4. Przepuszczamy do systemu (ważne dla Alt+F4, skrótów menu itp.)
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;
    {WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP,
    WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_UNICHAR:
    begin
      // 1. Handshake dla Unicode
      if (u_msg = WM_UNICHAR) and (w_param = $FFFF) then
      begin
        Result := 1;
        Exit;
      end;

      // 2. Pobieramy odpowiednią właściwość na podstawie komunikatu
      case u_msg of
        WM_KEYDOWN:    Ptr := GetProp(h_wnd, AV_PROP_ON_KEYDOWN);
        WM_KEYUP:      Ptr := GetProp(h_wnd, AV_PROP_ON_KEYUP);
        WM_SYSKEYDOWN: Ptr := GetProp(h_wnd, AV_PROP_ON_SYSKEYDOWN);
        WM_SYSKEYUP:   Ptr := GetProp(h_wnd, AV_PROP_ON_SYSKEYUP);
        WM_CHAR:       Ptr := GetProp(h_wnd, AV_PROP_ON_CHAR);
        WM_SYSCHAR:    Ptr := GetProp(h_wnd, AV_PROP_ON_SYSCHAR);
        WM_DEADCHAR:   Ptr := GetProp(h_wnd, AV_PROP_ON_DEADCHAR);
        WM_UNICHAR:    Ptr := GetProp(h_wnd, AV_PROP_ON_UNICHAR);
      else
        Ptr := 0;
      end;

      // 3. Wywołanie, jeśli zdarzenie jest przypisane
      if Ptr <> 0 then
      begin
        case u_msg of
          // Klawisze fizyczne (Word)
         // Grupa 1: Klawisze fizyczne (Virtual Keys) -> Word(WParam)
          WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP:
            TAvocadoKeyEvent(Pointer(Ptr))(h_wnd, Word(w_param));

          // Grupa 2: Znaki tekstowe -> WideChar(WParam)
          WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_UNICHAR:
            TAvocadoCharEvent(Pointer(Ptr))(h_wnd, WideChar(w_param));
        end;
      end;

      // 4. Przepuszczamy do systemu (ważne dla Alt+F4, skrótów menu itp.)
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;
    }



    {WM_KEYDOWN, WM_KEYUP,
    WM_SYSKEYDOWN, WM_SYSKEYUP,
    WM_CHAR, WM_SYSCHAR,
    WM_DEADCHAR, WM_UNICHAR:
    begin
      // 1. Specjalna obsługa WM_UNICHAR (Handshake)
      if (Message = WM_UNICHAR) and (WParam = $FFFF) then
      begin
        Result := 1; // Tak, obsługujemy Unicode!
        Exit;
      end;

      Idx := -1;
      // Szukamy w rejestrze klawiatury
      for i := 0 to High(KeyboardRegistry) do
        if KeyboardRegistry[i].Handle = Window then
        begin
          Idx := i;
          Break;
        end;

     // 3. Wywołanie zdarzeń użytkownika
      if Idx <> -1 then
      begin
        // Przypisanie wskaźnika dla czytelności

        KCB := @KeyboardRegistry[Idx].Callbacks;
        // UWAGA: Jeśli FPC zgłosi błąd przy 'var' tutaj,
        // przenieś 'KCB: ^TKeyboardCallbacks;' do sekcji 'var' na górze funkcji AvocadoWindowProc.

        case Message of
          // Zdarzenia fizyczne (KeyCode)
          WM_KEYDOWN:    if Assigned(KCB^.OnKeyDown)    then KCB^.OnKeyDown(Window, Word(WParam));
          WM_KEYUP:      if Assigned(KCB^.OnKeyUp)      then KCB^.OnKeyUp(Window, Word(WParam));
          WM_SYSKEYDOWN: if Assigned(KCB^.OnSysKeyDown) then KCB^.OnSysKeyDown(Window, Word(WParam));
          WM_SYSKEYUP:   if Assigned(KCB^.OnSysKeyUp)   then KCB^.OnSysKeyUp(Window, Word(WParam));

          // Zdarzenia znakowe (Char)
          WM_CHAR:       if Assigned(KCB^.OnChar)       then KCB^.OnChar(Window, WideChar(WParam));
          WM_SYSCHAR:    if Assigned(KCB^.OnSysChar)    then KCB^.OnSysChar(Window, WideChar(WParam));
          WM_DEADCHAR:   if Assigned(KCB^.OnDeadChar)   then KCB^.OnDeadChar(Window, WideChar(WParam));
          WM_UNICHAR:    if Assigned(KCB^.OnUniChar)    then KCB^.OnUniChar(Window, WideChar(WParam));
        end;
      end;

      // 4. WAŻNE: Przepuszczamy do systemu
      Result := DefWindowProcW(Window, Message, WParam, LParam);
    end;
    }
    // PRZESUWANIE
    WM_MOVE:
    begin
      Ptr := GetProp(h_wnd, AV_PROP_ON_MOVE);
      if Ptr <> 0 then
      begin
        TAvocadoEvent(Pointer(Ptr))(h_wnd);
      end;
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;



    // --- ZAMYKANIE (QUERY) ---
    {WM_CLOSE:
    begin
      CanClose := True;
      CloseQueryFunc := FindCloseEvent(h_wnd);

      if Assigned(CloseQueryFunc) then
        CanClose := CloseQueryFunc(h_wnd);

      if CanClose then
        DestroyWindow(h_wnd)
      else
      begin
        Result := 0;
        Exit;
      end;

      Result := 0;
      Exit;
    end;}

  WM_CLOSE:
    begin
      ptr := GetPropA(h_wnd, AV_PROP_ON_CLOSE_QUERY);

      if ptr <> 0 then
      begin
        // Jeśli zdarzenie istnieje, wywołujemy je
        on_close := TAvocadoCloseEvent(Pointer(ptr));

        // Jeśli użytkownik zwróci False, przerywamy zamykanie
        if not on_close(h_wnd) then
        begin
          Result := 0;
          Exit;
        end;
      end;

      // Jeśli nie ma zdarzenia LUB użytkownik pozwolił (True) -> niszczymy okno
      DestroyWindow(h_wnd);
      Result := 0;
      Exit;
    end;



    // --- OBSŁUGA ZAAWANSOWANYCH KONTROLEK (WM_NOTIFY) ---
    WM_NOTIFY:
    begin
      nm_hdr := PNMHDR(l_param);

      case nm_hdr^.code of
      EN_LINK:
        begin
          p_link := p_av_en_link(l_param);

          if (p_link^.msg = WM_LBUTTONDOWN) then
          begin
            FillChar(url_text, SizeOf(url_text), 0);
            tr.chrg := p_link^.chrg;
            tr.lpstr_text := url_text;

            SendMessageW(p_link^.nmhdr.hwndFrom, EM_GETTEXTRANGE, 0, LPARAM(@tr));
            open_url(url_text);

            Result := 1;
            Exit;
          end;
        end;
        //
    end;
   end;


    // --- OBSŁUGA PRZEWIJANIA (SCROLLING)
    WM_VSCROLL, WM_HSCROLL:
    begin
      // 1. Wybieramy odpowiednią szufladkę
      if u_msg = WM_VSCROLL then
        Ptr := GetProp(h_wnd, AV_PROP_ON_VSCROLL)
      else
        Ptr := GetProp(h_wnd, AV_PROP_ON_HSCROLL);

      if Ptr <> 0 then
      begin
        // Rzutujemy na typ zdarzenia suwaka
        OnScroll := TAvocadoScrollEvent(Pointer(Ptr));
        // LParam: Uchwyt paska (jeśli to kontrolka)
        OnScroll(h_wnd,
                 l_param,                 // Scrollbar Handle
                 w_param and $FFFF,        // Scroll Code (Loword)
                 (w_param shr 16) and $FFFF // Position (Hiword)
        );
        Result := 0;
        Exit;
      end;
    end;
    {WM_VSCROLL, WM_HSCROLL:
    begin
      // 1. Rozpakowanie parametrów komunikatu
      ScrollCode := LOWORD(WParam); // Jaka akcja (np. SB_LINEUP)
      Pos16      := SmallInt(HIWORD(WParam)); // Pozycja suwaka (16-bit)
      hControl   := HWND(LParam);   // Uchwyt kontrolki (0 jeśli to pasek okna)

      // 2. Wybór odpowiedniego rejestru
      if Message = WM_VSCROLL then
        CurrentRegistry := VScrollRegistry // Kopiuje dane (w Pascalu tablice dyn. to referencje, ale tu upraszczamy)
      else
        CurrentRegistry := HScrollRegistry;

      // Uwaga: W FPC przypisanie tablicy dynamicznej kopiuje referencję,
      // ale dla bezpieczeństwa wyszukajmy w pętli bezpośrednio na globalnych zmiennych.

      Idx := -1;
      if Message = WM_VSCROLL then
      begin
        for k := 0 to High(VScrollRegistry) do
          if VScrollRegistry[k].Handle = Window then begin Idx := k; Break; end;

        if (Idx <> -1) and Assigned(VScrollRegistry[Idx].OnScroll) then
          VScrollRegistry[Idx].OnScroll(Window, ScrollCode, Pos16, hControl);
      end
      else // WM_HSCROLL
      begin
        for k := 0 to High(HScrollRegistry) do
          if HScrollRegistry[k].Handle = Window then begin Idx := k; Break; end;

        if (Idx <> -1) and Assigned(HScrollRegistry[Idx].OnScroll) then
          HScrollRegistry[Idx].OnScroll(Window, ScrollCode, Pos16, hControl);
      end;

      Result := 0;
      Exit;
    end;
    }

    // --- ZMIANA ROZMIARU I PRZESUWANIE (LIVE) ---
    WM_SIZING, WM_MOVING:
    begin
      if u_msg = WM_SIZING then
        Ptr := GetProp(h_wnd, AV_PROP_ON_SIZING)
      else
        Ptr := GetProp(h_wnd, AV_PROP_ON_MOVING);

      if Ptr <> 0 then
      begin
        // WParam: Krawędź (np. WMSZ_BOTTOMRIGHT)
        // LParam: Wskaźnik na prostokąt (PRect), który można modyfikować!

        if u_msg = WM_SIZING then
        begin
          OnSizing := TAvocadoSizingEvent(Pointer(Ptr));
          // Sizing potrzebuje 3 parametrów (Okno, Rect, Krawędź)
          OnSizing(h_wnd, PRect(l_param)^, w_param);
        end
        else
        begin
          OnMoving := TAvocadoMovingEvent(Pointer(Ptr));
          // Moving potrzebuje tylko 2 parametrów (Okno, Rect)
          // Definicja w core.pas musi pasować!
          OnMoving(h_wnd, PRect(l_param)^);
        end;

        Result := 1;
        Exit;
      end;
    end;

    //zaawansowane pozycjonowanie
   WM_WINDOWPOSCHANGING:
    begin
      // 1. Rzutujemy LParam na wskaźnik struktury (niezbędne)
      PWinPos := PWINDOWPOS(l_param);

      // 2. LOGIKA PRZYKLEJANIA (Sticky Windows)
      // Pobieramy flagę włączającą z właściwości okna (zwraca 0 lub 1)
      if GetProp(h_wnd, 'AV_PROP_STICKY') = 1 then
      begin
        // Działamy tylko, jeśli okno faktycznie zmienia pozycję (brak flagi NOMOVE)
        if (PWinPos^.flags and SWP_NOMOVE) = 0 then
        begin
          // Pobieramy dystans przyciągania (domyślnie 20px)
          SnapDist := Integer(GetProp(h_wnd, 'AV_PROP_SNAP_DIST'));
          if SnapDist <= 0 then SnapDist := 20;

          // Pobieramy info o monitorze (Twoja funkcja pomocnicza z utils/core)
          MonInfo := get_window_monitor_info(h_wnd);

          // Obliczamy aktualne wymiary okna
          WinW := PWinPos^.cx;
          if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
            WinW := get_window_width(h_wnd);

          WinH := PWinPos^.cy;
          if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
            WinH := get_window_height(h_wnd);

          // przyklejanie (matematyka)
          // Lewa krawędź
          if Abs(PWinPos^.x - MonInfo.WorkRect.Left) <= SnapDist then
             PWinPos^.x := MonInfo.WorkRect.Left;

          // Prawa krawędź
          if Abs((PWinPos^.x + WinW) - MonInfo.WorkRect.Right) <= SnapDist then
             PWinPos^.x := MonInfo.WorkRect.Right - WinW;

          // Górna krawędź
          if Abs(PWinPos^.y - MonInfo.WorkRect.Top) <= SnapDist then
             PWinPos^.y := MonInfo.WorkRect.Top;

          // Dolna krawędź
          if Abs((PWinPos^.y + WinH) - MonInfo.WorkRect.Bottom) <= SnapDist then
             PWinPos^.y := MonInfo.WorkRect.Bottom - WinH;
        end;
      end;

      // 3. LOGIKA UŻYTKOWNIKA (Zdarzenia) - FIX DLA 30 KB
      // Zamiast FindPosChangingEvent, używamy GetProp!
      Ptr := GetProp(h_wnd, AV_PROP_ON_POS_CHANGING);
      if Ptr <> 0 then
      begin
        OnPosCh := TAvocadoWindowPosEvent(Pointer(Ptr));
        OnPosCh(h_wnd, PWinPos^);
      end;

      Result := 0;
      Exit;
    end;
    {WM_WINDOWPOSCHANGING:
      begin
        // 1. Najpierw pobieramy wskaźnik na strukturę (jest potrzebny zawsze)
              PWinPos := PWINDOWPOS(LParam);

              // 2. LOGIKA WEWNĘTRZNA BIBLIOTEKI (Sticky / Snapping)
              // To musi się wykonać ZAWSZE, niezależnie czy użytkownik podpiął zdarzenie
              if GetProp(Window, 'AvocadoSticky') = 1 then
              begin
                // Działamy tylko, jeśli okno się przesuwa (brak flagi NOMOVE)
                if (PWinPos^.flags and SWP_NOMOVE) = 0 then
                begin
                  SnapDist := Integer(GetProp(Window, 'SnapDist'));
                  if SnapDist <= 0 then SnapDist := 20;

                  // Pobieramy info o monitorze (Upewnij się, że masz "packed record" w definicji!)
                  MonInfo := avo_get_window_monitor_info(Window);

                  // Obliczamy wymiary
                  WinW := PWinPos^.cx;
                  if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
                    WinW := avo_get_window_width(Window);

                  WinH := PWinPos^.cy;
                  if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
                    WinH := avo_get_window_height(Window);

                  // --- PRZYKLEJANIE POZIOME (X) ---
                  if Abs(PWinPos^.x - MonInfo.WorkRect.Left) <= SnapDist then
                     PWinPos^.x := MonInfo.WorkRect.Left;

                  if Abs((PWinPos^.x + WinW) - MonInfo.WorkRect.Right) <= SnapDist then
                     PWinPos^.x := MonInfo.WorkRect.Right - WinW;

                  // --- PRZYKLEJANIE PIONOWE (Y) ---
                  if Abs(PWinPos^.y - MonInfo.WorkRect.Top) <= SnapDist then
                     PWinPos^.y := MonInfo.WorkRect.Top;

                  if Abs((PWinPos^.y + WinH) - MonInfo.WorkRect.Bottom) <= SnapDist then
                     PWinPos^.y := MonInfo.WorkRect.Bottom - WinH;
                end;
              end;

              // 3. LOGIKA UŻYTKOWNIKA (Zdarzenia)
              // Dopiero teraz sprawdzamy, czy użytkownik chce coś dodać od siebie
              PosFunc := FindPosChangingEvent(Window);
              if Assigned(PosFunc) then
              begin
                PosFunc(Window, PWinPos^);
              end;

              Result := 0;
              Exit;
    end;
    }
    // --- ZMIANA POZYCJI ZAKOŃCZONA (WM_WINDOWPOSCHANGED) --- [NOWE]
    // Ten komunikat przychodzi PO TYM jak okno zmieniło pozycję/rozmiar
    WM_WINDOWPOSCHANGED:
    begin
      PWinPos := PWINDOWPOS(l_param);

      // 1. Sprawdzamy, czy pozycja uległa zmianie (brak flagi SWP_NOMOVE)
      if (PWinPos^.flags and SWP_NOMOVE) = 0 then
      begin
        // Tutaj możesz zaktualizować globalne zmienne biblioteki, np.:
        // CurrentWindowX := PWinPos^.x;
        // CurrentWindowY := PWinPos^.y;
      end;

      // 2. Sprawdzamy, czy rozmiar uległ zmianie (brak flagi SWP_NOSIZE)
      if (PWinPos^.flags and SWP_NOSIZE) = 0 then
      begin
        // Tutaj aktualizacja szerokości/wysokości w strukturach biblioteki
      end;

      // WAŻNE: Nie dajemy tu 'Exit'. Pozwalamy przejść do DefWindowProc (klauzula else),
      // ponieważ DefWindowProc generuje komunikaty WM_SIZE i WM_MOVE na podstawie tego.
    end;

    // --- OBSŁUGA MENU KONTEKSTOWEGO (FINALNA WERSJA) ---
    WM_CONTEXTMENU:
    begin
      // KROK 1: Sprawdzamy, czy użytkownik zdefiniował WŁASNE MENU
      OnContext := t_av_context_event(Pointer(GetPropW(h_wnd, AV_PROP_ON_CONTEXT)));

      if Assigned(OnContext) then
      begin
        // Pobieramy współrzędne (ekranowe)
        PosX := SmallInt(l_param and $FFFF);
        PosY := SmallInt((l_param shr 16) and $FFFF);

        // Obsługa klawiatury (Shift+F10 lub klawisz Menu zwracają -1)
        if (PosX = -1) and (PosY = -1) then
        begin
          GetCursorPos(Pt);
          PosX := Pt.X;
          PosY := Pt.Y;
        end;

        OnContext(h_wnd, PosX, PosY);
        Result := 0;
        Exit;
      end;

      // KROK 2: Jeśli nie ma OnContext, sprawdzamy czy blokować menu systemowe
      if Pointer(GetPropW(h_wnd, AV_PROP_ON_RBUTTON_DOWN)) <> nil then
      begin
        Result := 0;
        Exit;
      end;

      // KROK 3: Fallback dla kontrolek (np. Memo) - obsługa subclassingu
      //OldProcPtr := Pointer(GetPropW(h_wnd, PWideChar('OldWndProc')));
      OldProcPtr := QWord(GetPropW(h_wnd, PWideChar('OldWndProc')));

      if OldProcPtr <> 0 then
        Exit(CallWindowProcW(WNDPROC(Pointer(OldProcPtr)), h_wnd, u_msg, w_param, l_param))
      else
        Exit(DefWindowProcW(h_wnd, u_msg, w_param, l_param));
    end;
   { WM_CONTEXTMENU:
    begin
      // KROK 1: Sprawdzamy, czy użytkownik zdefiniował WŁASNE MENU
      Idx := -1;
      for k := 0 to High(ContextRegistry) do
        if ContextRegistry[k].Handle = Window then begin Idx := k; Break; end;

      if (Idx <> -1) and Assigned(ContextRegistry[Idx].OnContext) then
      begin
        // Pobieramy współrzędne
        X := GET_X_LPARAM(LParam);
        Y := GET_Y_LPARAM(LParam);

        // Obsługa klawiatury (Shift+F10 lub klawisz Menu)
        if (X = -1) and (Y = -1) then
        begin
          GetCursorPos(Pt); // Pt musi być w 'var' procedury
          X := Pt.X;
          Y := Pt.Y;
        end;

        ContextRegistry[Idx].OnContext(Window, X, Y);
        Result := 0;
        Exit; // Obsłużone, wychodzimy
      end;

      // KROK 2: Jeśli nie ma menu, sprawdzamy czy blokować (bo np. gra/rysowanie)
      // Jeśli użytkownik obsługuje "OnRDown" (klikanie prawym), to zazwyczaj
      // nie chce, żeby systemowe menu mu wyskakiwało pod kursorem.
      Idx := -1;
      for k := 0 to High(MouseRegistry) do
         if MouseRegistry[k].Handle = Window then begin Idx := k; Break; end;

      if (Idx <> -1) and Assigned(MouseRegistry[Idx].Callbacks.OnRDown) then
      begin
         Result := 0;
         Exit; // Blokujemy menu systemowe
      end;

      // KROK 3: Fallback dla kontrolek (np. Memo - Kopiuj/Wklej)
      OldProcPtr := GetProp(Window, 'OldWndProc');
      if OldProcPtr <> 0 then
        Result := CallWindowProc(WNDPROC(OldProcPtr), Window, Message, WParam, LParam)
      else
        Result := DefWindowProcW(Window, Message, WParam, LParam);

      Exit;
    end;
    }
    // obsługa myszy
    WM_MOUSEMOVE,WM_MOUSEWHEEL, WM_MOUSEHWHEEL,
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK,
    WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK,
    WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK:
    begin
      if dispatch_mouse_event(h_wnd, u_msg, w_param, l_param) then
      begin
        Exit(0);
      end;
    end;

    // --- 1. OBSŁUGA UPUSZCZANIA PLIKÓW (WM_DROPFILES) ---
    WM_DROPFILES:
    begin
      // Pobieramy wskaźnik do funkcji zdarzenia przypisany do okna
        drop_ptr := GetPropW(h_wnd, AV_PROP_ON_DROP_FILES);

        if drop_ptr <> 0 then
        begin
          on_drop := t_av_drop_files_event(drop_ptr);
          if Assigned(on_drop) then
          begin
            // Wywołujemy zdarzenie.
            // UWAGA: Nie wywołujemy tutaj DragFinish, jeśli robi to funkcja on_drop!
            on_drop(h_wnd, w_param);
          end;

          Result := 0;
          Exit;
    end;

    end;
    {WM_DROPFILES:
    begin
      // Szukamy, czy użytkownik obsługuje Drop Files dla tego okna
      DropIdx := -1;
      for k := 0 to High(DropRegistry) do
        if DropRegistry[k].Handle = Window then begin DropIdx := k; Break; end;

      if (DropIdx <> -1) and Assigned(DropRegistry[DropIdx].OnDrop) then
      begin
        //hDrop := HDROP(WParam);
        hDrop := THandle(WParam);
        try
          // Pobieramy liczbę plików
          FileCount := DragQueryFileW(hDrop, $FFFFFFFF, nil, 0);

          FileList := TStringList.Create;
          try
            for k := 0 to FileCount - 1 do
            begin
              // Pobieramy nazwę k-tego pliku
              DragQueryFileW(hDrop, k, FileName, MAX_PATH);
              FileList.Add(WideCharToString(FileName));
            end;

            // Wywołujemy funkcję użytkownika
            DropRegistry[DropIdx].OnDrop(Window, FileList);
          finally
            FileList.Free;
          end;
        finally
          DragFinish(hDrop); // Zwalniamy pamięć systemową dropu
        end;
      end;

      Result := 0; Exit;
    end;
    }
    // --- 2. OPÓŹNIONE RENDEROWANIE SCHOWKA (WM_RENDER...) ---
    {WM_RENDERFORMAT, WM_RENDERALLFORMATS:
    begin
      ClipIdx := -1;
      for k := 0 to High(ClipRegistry) do
        if ClipRegistry[k].Handle = Window then
        begin ClipIdx := k;
          Break;
        end;

      if ClipIdx <> -1 then
      begin
        if Message = WM_RENDERFORMAT then
        begin
          // System prosi o konkretny format (WParam)
          if Assigned(ClipRegistry[ClipIdx].OnRender) then
             ClipRegistry[ClipIdx].OnRender(Window, UINT(WParam));
        end
        // 3. Aplikacja się zamyka (trzeba wygenerować wszystko)
        else // WM_RENDERALLFORMATS
        begin
          // Aplikacja się zamyka, trzeba wygenerować wszystko
          if Assigned(ClipRegistry[ClipIdx].OnRenderAll) then
             ClipRegistry[ClipIdx].OnRenderAll(Window);
        end;
      end;

      Result := 0; Exit;
    end;
    }
    // Gdy inna aplikacja prosi o konkretny format (np. tekst)
    WM_RENDERFORMAT:
    begin
      Ptr := GetProp(h_wnd, AV_PROP_ON_CLIP_RENDER);
      if Ptr <> 0 then
      begin
        OnRender := TAvocadoRenderFormatEvent(Pointer(Ptr));
        // WParam to żądany format danych (np. CF_TEXT)
        if Assigned(OnRender) then OnRender(h_wnd, UINT(w_param));
        Result := 0;
        Exit;
      end;
    end;

    // Gdy aplikacja jest zamykana, a nadal trzyma dane w schowku
    WM_RENDERALLFORMATS:
    begin
      Ptr := GetProp(h_wnd, AV_PROP_ON_CLIP_RENDER_ALL);
      if Ptr <> 0 then
      begin
        OnRenderAll := TAvocadoRenderAllEvent(Pointer(Ptr));
        if Assigned(OnRenderAll) then OnRenderAll(h_wnd);
        Result := 0;
        Exit;
      end;
    end;



    // obsługa myszy non-client (ramka, tytuł)

    WM_NCMOUSEMOVE,
    WM_NCLBUTTONDOWN, WM_NCLBUTTONUP, WM_NCLBUTTONDBLCLK,
    WM_NCRBUTTONDOWN, WM_NCRBUTTONUP:
    begin
      // Sprawdzamy, czy to dowolny komunikat z zakresu Non-Client
      if dispatch_nc_event(h_wnd, u_msg, w_param, l_param) then
      begin
      end
      else
        Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
    end;


    // --- OBSŁUGA IKONY (Alt+Tab, Pasek Zadań) ---
    WM_SETICON:
    begin
      // WParam: 0 = Mała (Small), 1 = Duża (Big)
      // LParam: Uchwyt ikony (HICON)

      if w_param = ICON_BIG then
        SetProp(h_wnd, 'AvocadoIconBig', THandle(l_param))
      else
        SetProp(h_wnd, 'AvocadoIconSmall', THandle(l_param));

      // WAŻNE: Musimy przekazać to do DefWindowProcW!
      // To Windows fizycznie rysuje ikonę na pasku zadań.
      // My tylko ją "zapamiętaliśmy" dla WM_GETICON.
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;

    WM_GETICON:
    begin
      // WParam: Rodzaj ikony, o którą pyta system (Big/Small)
      // System pyta: "Daj mi swoją ikonę"

      if w_param = ICON_BIG then
        Result := LRESULT(GetProp(h_wnd, 'AvocadoIconBig'))
      else
        Result := LRESULT(GetProp(h_wnd, 'AvocadoIconSmall'));

      // Jeśli mamy zapisaną ikonę -> zwracamy ją.
      if Result <> 0 then Exit;

      // Jeśli nie mamy (zwróciło 0), niech system poszuka domyślnej
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;

    // --- ZMIANA CZASU SYSTEMOWEGO ---
    WM_TIMECHANGE:
    begin
      //Pointer(on_time_change) := GetPropW(h_wnd, 'av_on_time_change');
      on_time_change := t_av_time_change_cb(Pointer(GetPropW(h_wnd, AV_PROP_TIME_CHANGE)));
      if Assigned(on_time_change) then
        on_time_change(h_wnd);

      Result := 0;
      Exit;

      // 1. Szukamy funkcji użytkownika
      {Idx := -1;
      for k := 0 to High(TimeChangeRegistry) do
        if TimeChangeRegistry[k].Handle = h_wnd then
        begin
          Idx := k;
          Break;
        end;

      // 2. Wywołujemy zdarzenie
      if (Idx <> -1) and Assigned(TimeChangeRegistry[Idx].OnTimeChange) then
      begin
        TimeChangeRegistry[Idx].OnTimeChange(h_wnd);
      end;
      }
      // Zgodnie z dokumentacją, aplikacja powinna zwrócić 0 po obsłużeniu tego komunikatu
      Result := 0;
      Exit;
    end;

    // --- STAN APLIKACJI (Active / Enable) ---
   {WM_ACTIVATEAPP, WM_ENABLE:
    begin
      // 1. Szukamy zdarzeń użytkownika w rejestrze FOKUSA (FocusRegistry)
      // Używamy tego samego rejestru co przy SetFocus/KillFocus
      Idx := -1;
      for i := 0 to High(FocusRegistry) do
        if FocusRegistry[i].Handle = Window then
        begin
          Idx := i;
          Break;
        end;

      if Idx <> -1 then
      begin
        case Message of
          WM_ACTIVATEAPP:
          begin
             if Assigned(FocusRegistry[Idx].Callbacks.OnActivateApp) then
               // WParam: True (Active) / False (Inactive)
               // LParam: ThreadID (rzadko używane)
               FocusRegistry[Idx].Callbacks.OnActivateApp(Window, Boolean(WParam), DWORD(LParam));
          end;

          WM_ENABLE:
          begin
             if Assigned(FocusRegistry[Idx].Callbacks.OnEnable) then
               // WParam: True (Enabled) / False (Disabled)
               FocusRegistry[Idx].Callbacks.OnEnable(Window, Boolean(WParam));
          end;
        end;
      end;
    end;
    }
    // stan aplikacji (active / enable) -
    WM_ACTIVATEAPP:
    begin
      Ptr := GetProp(h_wnd, AV_PROP_ON_ACTIVATE_APP);
      if Ptr <> 0 then
      begin
        TAvocadoActivateAppEvent(Pointer(Ptr))(h_wnd, Boolean(w_param), DWORD(l_param));
      end;
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;

    WM_ENABLE:
    begin
      Ptr := GetProp(h_wnd, AV_PROP_ON_ENABLE);

      if Ptr <> 0 then
      begin
        // 2. Rzutujemy i wywołujemy
        // WParam: True (Enabled) / False (Disabled)
        TAvocadoEnableEvent(Pointer(Ptr))(h_wnd, Boolean(w_param));
      end;

      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
      Exit;
    end;
    // --- NISZCZENIE (DESTROY) ---
    WM_DESTROY:
    begin
      CanDrag := PBoolean(GetWindowLongPtr(h_wnd, GWL_USERDATA));
      if CanDrag <> nil then Dispose(CanDrag);

      //RemovePropA(h_wnd, AV_PROP_ON_POWER_EVENT);
      RemovePropA(h_wnd, AV_PROP_ON_POWER);
      RemovePropA(h_wnd, AV_PROP_ON_DEVICE);

      RemovePropW(h_wnd, AV_PROP_TIME_CHANGE);
      RemoveProp(h_wnd, 'IsHover');
      RemoveProp(h_wnd, 'IsDown');
      RemoveProp(h_wnd, 'ColNormal');
      RemoveProp(h_wnd, 'ColHover');
      RemoveProp(h_wnd, 'ColPressed');
      RemoveProp(h_wnd, 'ColText');
      RemoveProp(h_wnd, 'AvocadoBrush');
      RemoveProp(h_wnd, 'AvocadoRadius');
      RemoveProp(h_wnd, 'AV_PROP_ON_ACTIVATE_APP');

      // Dodaj też czyszczenie MinW/MinH jeśli chcesz być perfekcyjny
      RemoveProp(h_wnd, 'AvocadoMinW');
      RemoveProp(h_wnd, 'AvocadoMinH');
      // Sticky props
      RemoveProp(h_wnd, 'AvocadoSticky');
      RemoveProp(h_wnd, 'SnapDist');
      RemoveProp(h_wnd, 'AvocadoIconBig');
      RemoveProp(h_wnd, 'AvocadoIconSmall');

      RemoveProp(h_wnd, AV_LABEL_BRUSH);
      RemoveProp(h_wnd, AV_LABEL_BG_COLOR);
      RemoveProp(h_wnd, AV_LABEL_TEXT_COLOR);
      RemovePropA(h_wnd, AV_PROP_ON_RESIZE);
      RemovePropA(h_wnd, AV_PROP_ON_KEY_DOWN);
      RemovePropA(h_wnd, AV_PROP_ON_CLOSE_QUERY);
      RemoveProp(h_wnd, 'AvBrush'); // Dla Edita

      PostQuitMessage(0);
      Result := 0;
      Exit;
    end;

    WM_PAINT:
    begin
      // 1. Obsługa kontrolek z subclassingiem (np. Memo, Edit)
      // Jeśli to kontrolka systemowa, niech maluje się sama standardowo.
      if GetPropW(h_wnd, 'OldWndProc') <> 0 then
      begin
        Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
        Exit;
      end;

      // 2. Rozpoczynamy malowanie własnego okna
      DC := BeginPaint(h_wnd, PS);
      try
         // Lekka obsługa własnego rysowania
         Ptr := GetPropW(h_wnd, AV_PROP_ON_PAINT);
         if Ptr <> 0 then
         begin
           // Rzutujemy wskaźnik na typ procedury i wywołujemy
           TAvocadoPaintEvent(Pointer(Ptr))(h_wnd, DC);
         end;

      finally
        // To mówi systemowi: "Skończyłem malować, nie wysyłaj więcej WM_PAINT"
        EndPaint(h_wnd, PS);
      end;

      Result := 0;
      Exit;
    end;


    // 1. SYSTEM PYTA: "CZY MOGĘ SIĘ ZAMKNĄĆ?"
    WM_QUERYENDSESSION:
        begin
          if GetProp(h_wnd, AV_PROP_ON_QUERY_END) <> 0 then
          begin
            OnQuery := TAvocadoQueryEndSessionEvent(Pointer(GetProp(h_wnd, AV_PROP_ON_QUERY_END)));
            if Assigned(OnQuery) then
            begin
              if OnQuery(h_wnd, l_param) then Result := 1 else Result := 0;
              Exit;
            end;
          end;
          Result := 1; // Domyślnie pozwól na zamknięcie
          Exit;
        end;

        // 2. ROZKAZ: "ZAMYKAM SYSTEM - SPRZĄTAJ!"
        WM_ENDSESSION:
        begin
          // Sprawdzamy czy WParam jest True (sesja faktycznie się kończy)
          if (w_param <> 0) and (GetProp(h_wnd, AV_PROP_ON_END_SESSION) <> 0) then
          begin
            OnEnd := TAvocadoEndSessionEvent(Pointer(GetProp(h_wnd, AV_PROP_ON_END_SESSION)));
            if Assigned(OnEnd) then
            begin
              // Tutaj zazwyczaj przekazujemy: Okno, Czy się kończy, Powód
              OnEnd(h_wnd, w_param <> 0, l_param);
            end;
          end;
          Result := 0; // System oczekuje 0 po obsłużeniu WM_ENDSESSION
          Exit;
        end;

    // --- OBSŁUGA ZAMYKANIA SYSTEMU (SESJI) ---
    {WM_QUERYENDSESSION, WM_ENDSESSION:
    begin
      Idx := -1;
      for k := 0 to High(SessionRegistry) do
        if SessionRegistry[k].Handle = Window then begin Idx := k; Break; end;

      if Idx <> -1 then
      begin
        // 2. WM_QUERYENDSESSION - Czy pozwalamy na zamknięcie?
        if Message = WM_QUERYENDSESSION then
        begin
          if Assigned(SessionRegistry[Idx].OnQuery) then
          begin
            // Pytamy użytkownika (funkcja zwraca True/False)
            CanClose := SessionRegistry[Idx].OnQuery(Window, UINT(LParam));

            if CanClose then Result := 1  // Zgoda (TRUE)
            else Result := 0;             // Blokada (FALSE)

            Exit;
          end
          else
          begin
            // Jeśli nie przypisano funkcji, domyślnie zgadzamy się na zamknięcie
            Result := 1;
            Exit;
          end;
        end
        // 3. WM_ENDSESSION - Informacja ostateczna
        else // WM_ENDSESSION
        begin
          if Assigned(SessionRegistry[Idx].OnEnd) then
          begin
            // WParam <> 0 oznacza, że sesja się kończy (True)
            // LParam to powód
            SessionRegistry[Idx].OnEnd(Window, WParam <> 0, UINT(LParam));
          end;
          Result := 0;
          Exit;
        end;
      end;

      // Domyślne zachowanie systemowe (gdy brak rejestracji)
      if Message = WM_QUERYENDSESSION then Result := 1 else Result := 0;
    end;
    }


    // --- DOMYŚLNA OBSŁUGA ---
    else
      Result := DefWindowProcW(h_wnd, u_msg, w_param, l_param);
    end;
end;

function create_window(Params: TAvocadoWindowParams): HWND;
var
WndClass: TWndClassExW;
ClassName, WindowName: WideString;
hInstance: HMODULE;
pDrag: PBoolean;
dwStyle: DWORD;
begin
   dwStyle := WS_OVERLAPPEDWINDOW;
   if (Params.AllowMaximize = False) then
      dwStyle := dwStyle and not WS_MAXIMIZEBOX;

  hInstance := GetModuleHandle(nil);
  ClassName := 'AvocadoWindowClass';
  WindowName := WideString(Params.Title);

  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.cbSize := SizeOf(TWndClassExW);
  WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS;
  WndClass.lpfnWndProc := @AvocadoWindowProc;
  WndClass.hInstance := hInstance;
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);


  // użycie koloru z parametrów:
  //WndClass.hbrBackground := CreateSolidBrush(Params.BackgroundColor);
  WndClass.hbrBackground := GetStockObject(BLACK_BRUSH);

  WndClass.lpszClassName := PWideChar(ClassName);

  if RegisterClassExW(WndClass) = 0 then
  begin
    if GetLastError() <> ERROR_CLASS_ALREADY_EXISTS then
      Exit(0);
  end;

  // Jeśli użytkownik wyraźnie poprosił o okno bez nagłówka:
  if Params.Frameless then
  begin
    dwStyle := WS_POPUP;
  end
  else
  begin
    // Startujemy od pełnego okna z nagłówkiem (standard)
    dwStyle := WS_OVERLAPPEDWINDOW;

    // Jeśli użytkownik nie chce maksymalizacji, zabieramy mu tylko ten przycisk
    if Params.AllowMaximize = False then
      dwStyle := dwStyle and not WS_MAXIMIZEBOX;
  end;
  // dobór stylu
  {if Params.Frameless then
    dwStyle := WS_POPUP
  else
  begin
    // Startujemy od pełnego okna
    dwStyle := WS_OVERLAPPEDWINDOW;

    // Jeśli użytkownik nie chce maksymalizacji, zabieramy mu przycisk
    //if not Params.AllowMaximize then
    //  dwStyle := dwStyle and not WS_MAXIMIZEBOX;

  end;
  }

  Result := CreateWindowExW(
      WS_EX_APPWINDOW,           // dwExStyle
      PWideChar(ClassName),      // lpClassName
      PWideChar(WindowName),     // lpWindowName
      dwStyle,
      Params.X,
      Params.Y,
      Params.Width,
      Params.Height,
      Params.Parent,            // hWndParent
      0,                         // hMenu
      hInstance,
      nil                        // lpParam
      );

  if (Result <> 0) then
  begin
    //Uniwersalny kolor z utils
    //set_component_color(Result, $202020, Params.BackgroundColor);
    set_component_color(Result, $FFFFFF, Params.BackgroundColor);
     // Dark mode włączony zawsze,
    set_dark_mode(Result, True);
    // włączenie obsługi upuszczania plików
    DragAcceptFiles(Result, True);
    New(pDrag);
    pDrag^ := Params.AllowDrag;
    SetWindowLongPtr(Result, GWL_USERDATA, LONG_PTR(pDrag));



    if Params.Visible then
    begin
      ShowWindow(Result, SW_SHOWNORMAL);
      UpdateWindow(Result);
    end;
  end;
end;

procedure run(var msg: TMsg);
begin
  while GetMessage(msg, 0, 0, 0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end;

procedure set_on_paint(Handle: HWND; Event: TAvocadoPaintEvent);
begin
  if Handle = 0 then Exit;
    SetPropW(Handle, AV_PROP_ON_PAINT, THandle(Event));
end;

procedure close_window(Handle: HWND);
begin
   if Handle <> 0 then
    PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure activate_window(Handle: HWND);
begin
    if (Handle <> 0) and IsWindow(Handle) then
    SetActiveWindow(Handle);
end;

procedure set_window_icons(Handle: HWND; SmallIcon, BigIcon: HICON);
begin
  if Handle = 0 then Exit;
    //Ustawiamy małą ikonę (Pasek zadań, lewy górny róg okna)
    if SmallIcon <> 0 then
      SendMessage(Handle, WM_SETICON, ICON_SMALL, LPARAM(SmallIcon));
    // Ustawiamy dużą ikonę (Alt + Tab, Menedżer Zadań)
    if BigIcon <> 0 then
      SendMessage(Handle, WM_SETICON, ICON_BIG, LPARAM(BigIcon));
end;

procedure set_on_get_min_max_info(Handle: HWND; Event: TAvocadoMinMaxEvent);
begin
 if Handle = 0 then Exit;
  SetPropW(Handle, AV_PROP_ON_MINMAX, THandle(Event));
end;

function window_get_default_params: TAvocadoWindowParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Title := 'Avocado Window';
  Result.Width := 800;
  Result.Height := 600;
  Result.Visible := True;
  Result.BackgroundColor := $FFFFFF;
  Result.AllowMaximize := True;
  Result.AllowDrag := True;
end;

procedure set_on_hit_test(Handle: HWND; Event: TAvocadoHitTestEvent);
begin
   if Handle <> 0 then
  begin
    SetProp(Handle, AV_PROP_ON_HITTEST, THandle(Event));
  end;
end;

function is_window_minimized(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    Result := Windows.IsIconic(Handle);
end;

function is_window_maximized(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    Result := Windows.IsZoomed(Handle);
end;

procedure set_on_set_focus(Handle: HWND; Event: TAvocadoFocusEvent);
begin
  if Handle <> 0 then
  begin
    SetProp(Handle, AV_PROP_ON_SET_FOCUS, THandle(Pointer(Event)));
  end
  else
    RemoveProp(Handle, AV_PROP_ON_SET_FOCUS);
end;

procedure set_on_kill_focus(Handle: HWND; Event: TAvocadoFocusEvent);
begin
  if Handle <> 0 then begin
    SetProp(Handle, AV_PROP_ON_KILL_FOCUS, THandle(Pointer(Event)));
  end
  else
    RemoveProp(Handle, AV_PROP_ON_KILL_FOCUS);
end;

procedure set_on_timer(Handle: HWND; Event: TAvocadoTimerEvent);
begin
  if Handle <> 0 then
  begin
    SetProp(Handle, AV_PROP_ON_TIMER, THandle(Pointer(Event)));
  end;
end;

procedure set_on_drop_files(Handle: HWND; Event: TAvocadoDropFilesEvent);
begin
  if Handle <> 0 then
    begin
      SetProp(Handle, AV_PROP_ON_DROP_FILES, THandle(Pointer(Event)));
      DragAcceptFiles(Handle, Assigned(Event));
    end;
end;

procedure set_on_clipboard_render(Handle: HWND; OnRender: TAvocadoRenderFormatEvent; OnRenderAll: TAvocadoRenderAllEvent);
begin
  if Handle <> 0 then
    begin
      SetProp(Handle, AV_PROP_ON_CLIP_RENDER, THandle(Pointer(OnRender)));
      SetProp(Handle, AV_PROP_ON_CLIP_RENDER_ALL, THandle(Pointer(OnRenderAll)));
    end;
end;

procedure set_on_sizing(Handle: HWND; Event: TAvocadoSizingEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_SIZING,THandle(Pointer(Event)));
end;

procedure set_on_moving(Handle: HWND; Event: TAvocadoMovingEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_MOVING, THandle(Pointer(Event)));
end;

procedure set_on_window_pos_changing(Handle: HWND; Event: TAvocadoWindowPosEvent);
begin
  if Handle <> 0 then SetProp(Handle, AV_PROP_ON_POS_CHANGING, THandle(Pointer(Event)));
end;


procedure set_on_mouse_move(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  SetProp(Handle, AV_PROP_ON_MOUSE_MOVE, THandle(Pointer(Event)));
end;

procedure set_on_vscroll(Handle: HWND; Event: TAvocadoScrollEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_VSCROLL, THandle(Pointer(Event)));
end;

procedure set_on_hscroll(Handle: HWND; Event: TAvocadoScrollEvent);
begin
 if Handle <> 0 then
   SetProp(Handle, AV_PROP_ON_HSCROLL, THandle(Pointer(Event)));
end;

procedure set_on_click(ControlHandle: HWND; Event: TAvocadoEvent);
begin
  //if ControlHandle <> 0 then
  //  SetProp(ControlHandle, AV_PROP_ON_EVENT, THandle(Pointer(Event)));
  if ControlHandle <> 0 then
    SetPropW(ControlHandle, AV_PROP_ON_EVENT, HANDLE(PtrUInt(Event)));
end;

procedure set_on_change(ControlHandle: HWND; Event: TAvocadoEvent);
begin
  set_on_click(ControlHandle, Event);
end;

procedure set_opacity(Handle: HWND; Opacity: Byte);
var
  CurrentStyle: LongInt;
begin
  if Handle <> 0 then
     begin
       CurrentStyle := GetWindowLong(Handle, GWL_EXSTYLE);
       if (CurrentStyle and WS_EX_LAYERED) = 0 then
         SetWindowLong(Handle, GWL_EXSTYLE, CurrentStyle or WS_EX_LAYERED);
       // Ustawiamy przezroczystość
       // LWA_ALPHA ($2) informuje, że używamy parametru Opacity do sterowania kanałem Alpha
       SetLayeredWindowAttributes(Handle, 0, Opacity, LWA_ALPHA);
     end;
end;

procedure maximize_window(Handle: HWND);
begin
   if Handle <> 0 then
      ShowWindow(Handle, SW_MAXIMIZE);
end;

procedure minimize_window(Handle: HWND);
begin
  if Handle <> 0 then
     ShowWindow(Handle, SW_MINIMIZE);
end;

procedure restore_window(Handle: HWND);
begin
  if Handle <> 0 then
     ShowWindow(Handle, SW_RESTORE);
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

procedure set_on_notify(Handle: HWND; Event: TAvocadoNotifyEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_NOTIFY, THandle(Pointer(Event)));
end;

procedure set_window_sticky(Handle: HWND; Enable: Boolean; SnapDistance: Integer = 20);
begin
 if Handle <> 0 then
    begin
      if Enable then
      begin
        SetProp(Handle, 'AV_PROP_STICKY', 1);
        SetProp(Handle, 'AV_PROP_SNAP_DIST', THandle(SnapDistance));
      end
      else
      begin
        SetProp(Handle, AV_PROP_STICKY, 0);
        //RemoveProp(Handle, 'AvocadoSticky');
        //RemoveProp(Handle, 'SnapDist');
      end;
    end;
end;

procedure set_caption_color(Handle: HWND; Color: DWORD);
const
  DWMWA_CAPTION_COLOR = 35;
begin
  DwmSetWindowAttribute(Handle, DWMWA_CAPTION_COLOR, @Color, SizeOf(Color));
end;

procedure set_caption_text_color(Handle: HWND; Color: DWORD);
const
  DWMWA_TEXT_COLOR = 36;
begin
   DwmSetWindowAttribute(Handle, DWMWA_TEXT_COLOR, @Color, SizeOf(Color));
end;

procedure draw_text_center(Handle: HWND; const AText: string; Color: DWORD);
var
  DC: HDC;
  R: TRect;
begin
 if Handle = 0 then Exit;

   DC := GetDC(Handle);
   // Sprawdzamy, czy DC jest poprawne (bezpieczeństwo)
   if DC <> 0 then
   try
     GetClientRect(Handle, R);
     SetBkMode(DC, TRANSPARENT);
     SetTextColor(DC, Color);
     SelectObject(DC, GetStockObject(DEFAULT_GUI_FONT));
     DrawText(DC, PChar(AText), Length(AText), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
   finally
     ReleaseDC(Handle, DC);
   end;
end;

procedure set_window_enabled(Handle: HWND; Enable: Boolean);
begin
  if Handle <> 0 then
     Windows.EnableWindow(Handle, Enable);
end;

function is_window_on_top(Handle: HWND): Boolean;
begin
  Result := (Handle <> 0) and (GetForegroundWindow() = Handle);
  //Result := False;
  //if Handle <> 0 then
  //  Result := (GetForegroundWindow() = Handle);
end;

procedure set_color(Handle: HWND; Color: DWORD);
var
  NewBrush, OldBrush: HBRUSH;
begin
  if Handle <> 0 then
    begin
      SetProp(Handle, 'AvBgCol', THandle(Color));
      NewBrush := CreateSolidBrush(Color);

      {$IFDEF WIN64}
      OldBrush := HBRUSH(SetClassLongPtr(Handle, GCLP_HBRBACKGROUND, LONG_PTR(NewBrush)));
      {$ELSE}
      OldBrush := HBRUSH(SetClassLong(Handle, GCL_HBRBACKGROUND, LongInt(NewBrush)));
      {$ENDIF}

      if OldBrush <> 0 then
        DeleteObject(OldBrush);
      //natychmiastowe przerysowanie okna nowym kolorem
      InvalidateRect(Handle, nil, True);
      UpdateWindow(Handle);
    end;
end;

procedure set_always_on_top(Handle: HWND; Enable: Boolean);
var
  InsertAfter: HWND;
begin
    if Handle <> 0 then
    begin
      // Wybieramy odpowiednią flagę w zależności od parametru Enable
      if Enable then
        InsertAfter := HWND_TOPMOST    // Zawsze na wierzchu
      else
        InsertAfter := HWND_NOTOPMOST; // Przywrócenie normalnego zachowania
      SetWindowPos(Handle, InsertAfter, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    end;
end;

procedure set_border(Handle: HWND; Enable: Boolean);
begin
   UpdateStyle(Handle, WS_CAPTION or WS_THICKFRAME, Enable);
end;

procedure set_sizable(Handle: HWND; Enable: Boolean);
begin
  UpdateStyle(Handle, WS_THICKFRAME, Enable);
end;

procedure set_minimize_button(Handle: HWND; Enable: Boolean);
begin
  UpdateStyle(Handle, WS_MINIMIZEBOX, Enable);
end;

function get_color(Handle: HWND): DWORD;
begin
  if Handle <> 0 then
    Result := DWORD(GetProp(Handle, 'AvBgCol'))
  else
    Result := $FFFFFF;
end;

procedure show(Handle: HWND);
begin
  if Handle <> 0 then
    ShowWindow(Handle, SW_SHOW);
end;

procedure hide(Handle: HWND);
begin
  if Handle <> 0 then
    ShowWindow(Handle, SW_HIDE);
end;

procedure bring_to_top(Handle: HWND);
begin
  if Handle <> 0 then
    SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure send_to_back(Handle: HWND);
begin
  if Handle <> 0 then
    SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure set_min_window_size(Handle: HWND; MinWidth, MinHeight: Integer);
begin
    if Handle <> 0 then
  begin
    SetProp(Handle, AV_PROP_MIN_WIDTH, THandle(MinWidth));
    SetProp(Handle, AV_PROP_MIN_HEIGHT, THandle(MinHeight));
  end;
end;

procedure set_on_move(Handle: HWND; OnMoveEvent: TAvocadoEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_MOVE, THandle(Pointer(OnMoveEvent)));
end;

procedure invalidate(Handle: HWND);
begin
   if Handle <> 0 then
    InvalidateRect(Handle, nil, True);
end;

procedure repaint(Handle: HWND);
begin
   if Handle <> 0 then
  begin
    InvalidateRect(Handle, nil, True);
    UpdateWindow(Handle);
  end;
end;

procedure set_on_activate_app(Handle: HWND; Event: TAvocadoActivateAppEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_ACTIVATE_APP, THandle(Pointer(Event)));
end;

procedure set_on_enable(Handle: HWND; Event: TAvocadoEnableEvent);
begin
  if Handle <> 0 then
      SetProp(Handle, AV_PROP_ON_ENABLE, THandle(Pointer(Event)));
end;

procedure begin_update(Handle: HWND);
begin
    if Handle <> 0 then
    SendMessage(Handle, WM_SETREDRAW, 0, 0);
end;

procedure end_update(Handle: HWND);
begin
  if Handle <> 0 then
   begin
     SendMessage(Handle, WM_SETREDRAW, 1, 0);
     RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN OR RDW_ERASE);
   end;
end;

procedure snapshot_to_clipboard(Handle: HWND);
const
  PRF_CHECKVISIBLE = $00000001;
  PRF_NONCLIENT    = $00000002;
  PRF_CLIENT       = $00000004;
  PRF_ERASEBKGND   = $00000008;
  PRF_CHILDREN     = $00000010;
  CF_BITMAP        = 2;
var
  Rect: TRect;
  Width, Height: Integer;
  WinDC, MemDC: HDC;
  Bitmap, OldBitmap: HBITMAP;
begin
  if Handle = 0 then Exit;
    GetWindowRect(Handle, Rect);
    Width := Rect.Right - Rect.Left;
    Height := Rect.Bottom - Rect.Top;
    WinDC := GetDC(Handle);
    MemDC := CreateCompatibleDC(WinDC);
    Bitmap := CreateCompatibleBitmap(WinDC, Width, Height);
    OldBitmap := SelectObject(MemDC, Bitmap);

    try
      SendMessage(Handle, WM_PRINT, MemDC,
                  PRF_NONCLIENT or PRF_CLIENT or PRF_ERASEBKGND or PRF_CHILDREN);

      if OpenClipboard(0) then
      begin
        EmptyClipboard;
        SetClipboardData(CF_BITMAP, Bitmap);
        CloseClipboard;
        Bitmap := 0;
      end;

    finally
      // Sprzątanie
      SelectObject(MemDC, OldBitmap);
      if Bitmap <> 0 then DeleteObject(Bitmap);

      DeleteDC(MemDC);
      ReleaseDC(Handle, WinDC);
    end;
end;

procedure set_on_sys_key_down(Handle: HWND; Event: TAvocadoKeyEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_SYS_KEY_DOWN, THandle(Pointer(Event)));
end;

procedure set_on_sys_key_up(Handle: HWND; Event: TAvocadoKeyEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_SYS_KEY_UP, THandle(Pointer(Event)));
end;



procedure set_on_key_up(H: HWND; E: TAvocadoKeyEvent);
begin
  begin
    SetProp(H, AV_PROP_ON_KEYUP,THandle(Pointer(E)));
  end;
end;

procedure set_on_char(Handle: HWND; Event: TAvocadoCharEvent);
begin
  if Handle <> 0 then
      SetProp(Handle, AV_PROP_ON_CHAR, THandle(Pointer(Event)));
end;

procedure set_on_sys_char(Handle: HWND; Event: TAvocadoCharEvent);
begin
  if Handle <> 0 then
     SetProp(Handle, AV_PROP_ON_SYSCHAR, THandle(Pointer(Event)));
end;

procedure set_on_dead_char(Handle: HWND; Event: TAvocadoCharEvent);
begin
  if Handle <> 0 then
    SetProp(Handle, AV_PROP_ON_DEADCHAR, THandle(Pointer(Event)));
end;

procedure set_on_uni_char(Handle: HWND; Event: TAvocadoCharEvent);
begin
  if Handle <> 0 then
     SetProp(Handle, AV_PROP_ON_UNICHAR, THandle(Pointer(Event)));
end;

procedure set_component_visible(hComponent: HWND; Visible: Boolean);
begin
  if hComponent = 0 then Exit;
  if Visible then
    ShowWindow(hComponent, SW_SHOW)
  else
    ShowWindow(hComponent, SW_HIDE);
end;

procedure toggle_component_visible(hComponent: HWND);
begin
    if hComponent <> 0 then
    begin
      if IsWindowVisible(hComponent) then
        ShowWindow(hComponent, SW_HIDE)
      else
        ShowWindow(hComponent, SW_SHOW);
    end;
end;

procedure set_component_rounding(hComponent: HWND; Radius: Integer);
begin
  if hComponent <> 0 then
  begin
    SetPropW(hComponent, ROUNDING_COMP, Radius);
    InvalidateRect(hComponent, nil, False);
  end;
end;

procedure rounding(hComponent: HWND; Radius: Integer);
begin
  if hComponent <> 0 then
  begin
    SetProp(hComponent, KP_RADIUS, THandle(radius));
    InvalidateRect(hComponent, nil, True);
  end;
end;

procedure draw_border(hWnd: HWND);
var
  dc: HDC;
  r: TRect;
  pen, old_pen: HPEN;
  border_col, focus_col, prop_val: DWORD;
  w, h: Integer;
begin
  if hwnd = 0 then Exit;
    dc := GetWindowDC(hwnd);
    try
      GetWindowRect(hwnd, r);
      w := r.Right - r.Left;
      h := r.Bottom - r.Top;

      //Sprawdzamy dedykowany kolor ramki
      prop_val := DWORD(GetProp(hwnd, KP_COL_BORD));

      if prop_val <> 0 then
      begin
        border_col := prop_val - 1;
      end
      else
      begin
        // Kolor tekstu
        //prop_val := DWORD(GetProp(hwnd, KP_COL_TEXT));
          prop_val := DWORD(GetProp(hwnd, AV_CTX_BORDER_COLOR));
        if prop_val <> 0 then
          border_col := prop_val - 1
        else
          border_col := $303030; //  ciemnoszary
      end;

      // Obsługa Focusa (dla Edit/ListBox,
      if GetFocus = hwnd then
      begin
        focus_col := DWORD(GetProp(hwnd, KP_COL_FOCS));
        if focus_col <> 0 then
          border_col := focus_col - 1;
      end;

      //Rysowanie
      pen := CreatePen(PS_SOLID, 1, border_col);
      old_pen := SelectObject(dc, pen);

      SelectObject(dc, GetStockObject(NULL_BRUSH));
      Rectangle(dc, 0, 0, w, h);

      SelectObject(dc, old_pen);
      DeleteObject(pen);
    finally
      ReleaseDC(hwnd, dc);
    end;
end;

procedure set_window_maximize_button(h_wnd: HWND; enabled: Boolean);
var
  style: LongInt;
begin
 if h_wnd = 0 then Exit;

  // Pobieramy obecny styl okna
  style := GetWindowLongW(h_wnd, GWL_STYLE);

  // Modyfikujemy bit odpowiedzialny za przycisk maksymalizacji (WS_MAXIMIZEBOX)
  if enabled then
    style := style or WS_MAXIMIZEBOX
  else
    style := style and not WS_MAXIMIZEBOX;

  // Nakładamy nowy styl na okno
  SetWindowLongW(h_wnd, GWL_STYLE, style);

  // Informujemy system, że ramka okna (Frame) uległa zmianie.
  // Bez tego przycisk może stać się nieaktywny, ale wizualnie wciąż wyglądać na włączony.
  SetWindowPos(h_wnd, 0, 0, 0, 0, 0,
               SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure set_window_minimize_button(h_wnd: HWND; enabled: Boolean);
var
  style: LongInt;
begin
  if h_wnd = 0 then Exit;
    style := GetWindowLongW(h_wnd, GWL_STYLE);

    // Modyfikujemy bit WS_MINIMIZEBOX
    if enabled then
      style := style or WS_MINIMIZEBOX
    else
      style := style and not WS_MINIMIZEBOX;

    // Nakładamy styl i wymuszamy odświeżenie ramki
    SetWindowLongW(h_wnd, GWL_STYLE, style);

    SetWindowPos(h_wnd, 0, 0, 0, 0, 0,
                 SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure set_window_close_button(h_wnd: HWND; enabled: Boolean);
var
  h_menu: HMENU;
begin
    if h_wnd = 0 then Exit;

      h_menu := GetSystemMenu(h_wnd, False);

      if h_menu <> 0 then
      begin
        // Jeśli enabled = True, włączamy (MF_ENABLED), jeśli False - wyłączamy i szarzymy (MF_GRAYED)
        if enabled then
          EnableMenuItem(h_menu, SC_CLOSE, MF_BYCOMMAND or MF_ENABLED)
        else
          EnableMenuItem(h_menu, SC_CLOSE, MF_BYCOMMAND or MF_GRAYED);

        // Odświeżamy ramkę okna, aby system narysował przycisk w nowym stanie
        SetWindowPos(h_wnd, 0, 0, 0, 0, 0,
                     SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
      end;
end;

procedure flash_window(h_wnd: HWND; count: Integer; interval: Integer);
var
  fwi: TFlashWInfo;
begin
      if h_wnd = 0 then Exit;

  // 1. Zerujemy strukturę (bezpieczeństwo przede wszystkim)
  FillChar(fwi, SizeOf(fwi), 0);
  fwi.cbSize := SizeOf(fwi);
  fwi.hwnd := h_wnd;
  fwi.dwTimeout := DWORD(interval);

  // 2. Logika trybów migania
  if count = 0 then
  begin
    // STOP - Wyłączamy jakiekolwiek aktywne mruganie
    fwi.dwFlags := FLASHW_STOP;
    fwi.uCount := 0;
  end
  else if count < 0 then
  begin
    // TRYB CIĄGŁY - Mrugaj, dopóki użytkownik nie kliknie w okno (TIMERNOFG)
    fwi.dwFlags := FLASHW_ALL or FLASHW_TIMERNOFG;
    fwi.uCount := 0;
  end
  else
  begin
    // TRYB LICZNIKA - Mrugaj dokładnie tyle razy, ile podano w count
    fwi.dwFlags := FLASHW_ALL;
    fwi.uCount := count;
  end;

  // 3. Wyślij polecenie do systemu Windows
  FlashWindowEx(@fwi);
end;

procedure set_window_resizable(h_wnd: HWND; is_resizable: Boolean);
var
  CurrentStyle: LONG_PTR;
begin
    if h_wnd = 0 then Exit;
    // 1. Pobieramy obecny styl okna
    CurrentStyle := GetWindowLongPtrW(h_wnd, GWL_STYLE);
    // 2. Dodajemy lub usuwamy flagę odpowiadającą za ramkę do rozciągania
    if is_resizable then
      CurrentStyle := CurrentStyle or WS_THICKFRAME
    else
      CurrentStyle := CurrentStyle and not WS_THICKFRAME;
    // 3. Zapisujemy nowy styl
    SetWindowLongPtrW(h_wnd, GWL_STYLE, CurrentStyle);
    // 4. Bardzo ważne: mówimy systemowi Windows, żeby odświeżył ramkę okna!
    // Inaczej zmiany mogłyby być widoczne dopiero po minimalizacji.
    SetWindowPos(h_wnd, 0, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure run_app;
var
  msg: TMsg;
begin
  while GetMessage(@msg, 0, 0, 0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end;

procedure center_window(h_wnd: HWND);
var
  screen_w, screen_h: Integer;
  win_rect: TRect;
  win_w, win_h: Integer;
  new_x, new_y: Integer;
begin
    //Pobieramy rozdzielczość głównego ekranu
    screen_w := GetSystemMetrics(SM_CXSCREEN);
    screen_h := GetSystemMetrics(SM_CYSCREEN);

    //Pobieramy aktualne wymiary okna
    GetWindowRect(h_wnd, win_rect);
    win_w := win_rect.Right - win_rect.Left;
    win_h := win_rect.Bottom - win_rect.Top;

    new_x := (screen_w - win_w) div 2;
    new_y := (screen_h - win_h) div 2;

    //Przesuwamy okno bez zmiany jego rozmiaru i kolejności (Z-Order)
    SetWindowPos(h_wnd, 0, new_x, new_y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
end;

end.


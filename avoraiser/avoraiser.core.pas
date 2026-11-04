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

Module:     avoraiser.core
Description: [Core engine for message loop and window management]
*)

unit avoraiser.core;
{$mode ObjFPC}{$H+}

interface
uses
  windows,Messages;


const
  CLEARTYPE_QUALITY = 5;
  WS_EX_LAYERED = $80000;
  LWA_ALPHA     = $2;
  UNICODE_NOCHAR = $FFFF; // <--- Dodaj to tutaj
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  FLASHW_STOP = 0;
  FLASHW_CAPTION = 1;
  FLASHW_TRAY = 2;
  FLASHW_ALL = 3;        // FLASHW_CAPTION or FLASHW_TRAY
  FLASHW_TIMER = 4;      // Mrugaj ciągle
  FLASHW_TIMERNOFG = 12; // Mrugaj dopóki okno nie wyjdzie na wierzch

  //Combobox
  AV_PROP_CB_BRUSH      : PWideChar = 'AvCbBrsh';
  AV_PROP_CB_TEXT_COLOR : PWideChar = 'AvCbTxtC';
  AV_PROP_CB_BG_COLOR   : PWideChar = 'AvCbBgC';
  AV_PROP_CB_IS_HOVER   : PWideChar = 'AvCbHov';
  AV_PROP_FONT_CB       : PWideChar = 'AvCbFont';

  //Uniwersalne właściwości wyglądu
  AV_PROP_TEXT_COLOR   : PWideChar = 'AvTxtC';
  AV_PROP_BG_COLOR     : PWideChar = 'AvBgC';
  AV_PROP_BRUSH        : PWideChar = 'AvBrsh';


  // Stałe dla SetWindowCompositionAttribute (Blur/Acrylic)
  WCA_ACCENT_POLICY = 19;
  ACCENT_DISABLED = 0;
  ACCENT_ENABLE_GRADIENT = 1;
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2;
  ACCENT_ENABLE_BLURBEHIND = 3;        // Klasyczny Blur
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4; // Acrylic (Win 10+)
  ACCENT_ENABLE_HOSTBACKDROP = 5;      // Mica (Win 11)
  AV_PROP_ON_DRAW = 'AvOnDraw'; // Pod tym kluczem zapiszemy funkcję
  // Stałe dla DwmSetWindowAttribute
  DWMWA_WINDOW_CORNER_PREFERENCE = 33; // Win 11
  DWMWCP_DEFAULT    = 0;
  DWMWCP_DONOTROUND = 1;
  DWMWCP_ROUND      = 2;
  DWMWCP_ROUNDSMALL = 3;

  MONITOR_DEFAULTTONEAREST = 2;
  MONITORINFOF_PRIMARY = 1;

  AV_PROP_ON_DROP_FILES = 'AvOnDropFiles';
  //AV_PROP_ON_HITTEST = 'AvOnHitTest';
  AV_PROP_ON_TIMER = 'AvOnTimer';
  AV_PROP_ON_QUERY_END = 'AvOnQueryEnd';
  AV_PROP_ON_END_SESSION = 'AvOnEndSes';
  AV_PROP_ON_SET_FOCUS = 'AvOnSetFocus';
  AV_PROP_ON_KILL_FOCUS = 'AvOnKillFocus';
  AV_PROP_ON_CLIP_RENDER = 'AvClipRnd';
  AV_PROP_ON_CLIP_RENDER_ALL = 'AvClipRndAll';


  //menu
  AV_PROP_ON_CONTEXT = 'AvCtxM';

  //obsługa myszy non-client (ramka, tytuł)
  AV_PROP_ON_NCMOVE     = 'AvNcMov';
  AV_PROP_ON_NCLDOWN    = 'AvNcLD';
  AV_PROP_ON_NCLUP      = 'AvNcLU';
  AV_PROP_ON_NCLDBLCLK  = 'AvNcLDc';
  AV_PROP_ON_NCRDOWN    = 'AvNcRD';
  AV_PROP_ON_NCRUP      = 'AvNcRU';
  //Scroll
  AV_PROP_ON_VSCROLL = 'AvVScr';
  AV_PROP_ON_HSCROLL = 'AvHScr';
  //Sizing
  AV_PROP_ON_SIZING       = 'AvSzng';
  AV_PROP_ON_MOVING       = 'AvMvng';
  AV_PROP_ON_POS_CHANGING = 'AvPosC';
  //Avocado Event
  AV_PROP_ON_EVENT = 'AvEvt';
  //
  AV_PROP_ON_NOTIFY = 'AvNtf'; // WM_NOTIFY
  AV_PROP_STICKY    = 'AvStk'; // Czy przyklejanie włączone (1/0)
  AV_PROP_SNAP_DIST = 'AvSnD'; // Dystans przyciągania (np. 20)
  AV_PROP_CAPTION_COLOR = 'AvCapC';  // Kolor tła nagłówka
  //AV_PROP_TEXT_COLOR    = 'AvTxtC';  // Kolor tekstu nagłówka
  AV_PROP_MIN_WIDTH  = 'AvMinW';
  AV_PROP_MIN_HEIGHT = 'AvMinH';
  AV_PROP_ON_MOVE = 'AvOnMov';
  AV_PROP_ON_ACTIVATE_APP = 'AvActApp';
  AV_PROP_ON_ENABLE       = 'AvEnbl';
  //AV_PROP_ON_SYS_KEY_DOWN = 'AvSysKD';
  //AV_PROP_ON_SYS_KEY_UP   = 'AvSysKU';
  //Przyciski
 // AV_PROP_ON_KEYDOWN    = 'AvKD';
  AV_PROP_ON_KEYUP      = 'AvKU';
  AV_PROP_ON_SYSKEYDOWN = 'AvSKD';
  AV_PROP_ON_SYSKEYUP   = 'AvSKU';
  //AV_PROP_ON_CHAR       = 'AvCh';
  AV_PROP_ON_SYSCHAR    = 'AvSCh';
  AV_PROP_ON_DEADCHAR   = 'AvDCh';
  AV_PROP_ON_UNICHAR    = 'AvUCh';

  AV_PROP_ON_KEYDOWN    = 'AvKdn';
  //przyciski
  AV_BTN_COL_NORMAL  = 'AvBtnN';
  AV_BTN_COL_HOVER   = 'AvBtnH';
  AV_BTN_COL_PRESS   = 'AvBtnP';
  AV_BTN_COL_TEXT    = 'AvBtnT';
  AV_PROP_ON_COLOR = 'AvBtnColEv';

  KP_FONT      = 'AvFnt';
  KP_COL_NORM  = 'AvCN';
  KP_COL_BORDER = 'AvCBorder';
  KP_COL_HOVR  = 'AvCH';
  KP_COL_PRES  = 'AvCP';
  KP_COL_TEXT  = 'AvCT';
  KP_RADIUS    = 'AvRad';
  KP_IS_HOVER  = 'AvIsH';
  KP_IS_PRESS  = 'AvIsP';
  KP_ON_COLOR  = 'AvEvC';
  //Edit
  KP_EDIT_ON_COLOR = 'AvEdCol';
  EM_SETSEL = $00B1;
  EM_GETSEL = $00B0;
  AV_EDIT_BORDER_COLOR = 'AvEdBrd'; // Kolor ramki
  AV_EDIT_FOCUS_COLOR  = 'AvEdFoc'; // Kolor ramki przy aktywności (Focus)
  AV_EDIT_PLACEHOLDER  = 'AvEdPlh'; // Tekst podpowiedzi (Placeholder)
  AV_EDIT_BG_COLOR     = 'AvEdBg';  // kolor tła
  AV_EDIT_TEXT_COLOR =  'AvEdTxt';  // Kolor tekstu

  //Label (Static)
  AV_LABEL_BG_COLOR   = 'AvLblBg';
  AV_LABEL_TEXT_COLOR = 'AvLblTxt';
  AV_LABEL_FONT       = 'AvLblFnt';
  AV_LABEL_BRUSH      = 'AvLblBr';

  //AV_PROP_BG_COLOR   = 'AvoBg';
  //AV_PROP_TEXT_COLOR = 'AvoTxt'
  //AV_PROP_TEXT_COLOR = 'AvoTxt';
 // AV_PROP_BRUSH      = 'AvoBr';
  AV_PROP_AUTO_FONT  = 'AvoFnt'; // Przyda się później do czcionek

  EM_SETCUEBANNER = $1501;
  //Rozmiar czcionki dla Edita
  AV_EDIT_AUTO_FONT = 'AvEdFnt';

  //Memo
  EM_SCROLL      = $00B5;
  EM_SCROLLCARET = $00B7;
  EM_GETLINECOUNT= $00BA;
  EM_GETLINE      = $00C4;
  EM_LINEINDEX    = $00BB;
  EM_LINELENGTH   = $00C1;
  //Progress Bar
  AV_PROG_BAR_SHOW_TEXT = 'AvShText';
  AV_PROG_BAR_COLOR = 'AvBarColor';
  AV_PROGRES = 'AvProgress';
  AV_PROGRES_TEXT_COLOR = 'AvProgTextColor';
  AV_PROGRES_BG_COLOR = 'AvProgBgColor';
  AV_PROGRES_BORDER_COLOR = 'AvProgBorderColor';

  AV_CTX_BORDER_COLOR = 'AvBordCol'; // Context/Common Border Color
  AV_CTX_TEXT_COLOR   = 'AvTextCol';
  AV_CTX_FOCUS_COLOR  = 'AvFocCol';
  //LISTBOX
  AV_LIST_BG_COLOR   = 'AvLsBg';    // Tło listy
  AV_LIST_TEXT_COLOR = 'AvLsTx';    // Tekst listy
  AV_LIST_SEL_BG     = 'AvLsSelBg'; // Tło zaznaczenia
  AV_LIST_SEL_TEXT   = 'AvLsSelTx'; // Tekst zaznaczenia

  AV_PROP_SEL_BG_COLOR = 'AvoSelBg';  // Tło zaznaczenia
  AV_PROP_SEL_TXT_COLOR = 'AvoSelTxt'; // Tekst zaznaczenia
  //AV_PROP_FONT = 'AvoFont'; // Uchwyt czcionki
  AV_PROP_FONT : PChar = 'AvoFont';
  //TrackBar
  // --- TRACKBAR (Suwak) ---
  AV_TRACK_POS = 'AvTrPos'; // Krótki klucz zamiast 'AvocadoPos'
  AV_TRACK_MIN = 'AvTrMin';
  AV_TRACK_MAX = 'AvTrMax';
  AV_TRACK_STEP = 'AvTrStep';
  AV_TRACK_SHOV_VALUE = 'AvTrShVal';
  AV_TRACK_SHOV_IS_HOVER = 'AvIsHover';

  // Opcjonalnie kolory
  AV_TRACK_COL_THUMB = 'AvTrColTh'; // Kolor suwaka
  AV_TRACK_COL_PROGRESS = 'AvTrColProg'; // Kolor linii
  AV_TRACK_COL_TRACK = 'AvTrColTr'; // Kolor linii

  // uniwersalne właściwości wizualne
  AV_CTX_RADIUS = 'AvRad';
  // Kod powiadomienia (wysyłany w WM_NOTIFY)
  EN_LINK = $070B;

  // SPIN EDIT (Licznik ze strzałkami)
  AV_SPIN_ARROW_COLOR = 'AvSpArr';  // Kolor samej strzałki (symbolu)
  AV_SPIN_BUTTON_BG   = 'AvSpBk';   // Kolor tła przycisku (pod strzałką)
  AV_SPIN_AUTO_FONT = 'AvSpFont'; //automatyczny rozmiar czcionki

  //WSPOLNE KLUCZE
  KP_COL_BORD = 'AvCB'; // Border Color
  AV_PROP_ON_PAINT = 'OnPaint';
  AV_PROP_ON_MINMAX = 'OnMinMax'; // Klucz do zdarzenia MinMaxInfo
  //KP_COL_TEXT = 'AvCT'; // Text Color (fallback)
  KP_COL_FOCS = 'AvCF'; // Focus Color

  //DLA MYSZKI (TRACKMOUSEEVENT)
  TME_HOVER = $00000001;
  TME_LEAVE = $00000002;
  WM_MOUSELEAVE = $02A3;

  //Zaokraglenie
  ROUNDING_COMP = 'RoundingValue';

  //Menu
  CMD_MENU_UNDO  = 1001;
  CMD_MENU_CUT   = 1002;
  CMD_MENU_COPY  = 1003;
  CMD_MENU_PASTE = 1004;
      //Mysz
  AV_PROP_ON_MOUSE_MOVE = 'AvMoMo';
  AV_PROP_ON_LBUTTON_DOWN = 'AvLBD';
  AV_PROP_ON_RBUTTON_DOWN = 'AvRBD';
  AV_PROP_ON_LBUTTON_UP   = 'AvLBU';
  AV_PROP_ON_HITTEST = 'AvHitT';
  AV_PROP_ON_LBUTTON_DBLCLK= 'AvLBDC';
  AV_PROP_ON_RBUTTON_UP    = 'AvRBU';
  AV_PROP_ON_RBUTTON_DBLCLK= 'AvRBDC';
  AV_PROP_ON_WHEEL         = 'AvWhl';
  AV_PROP_ON_HWHEEL = 'AvHWhl';

  //Srodkowy przycsik
  AV_PROP_ON_MBUTTON_DOWN   = 'AvMBD';
  AV_PROP_ON_MBUTTON_UP     = 'AvMBU';
  AV_PROP_ON_MBUTTON_DBLCLK = 'AvMBDC';

  // Klucze dla obszaru Non-Client (Ramka i pasek tytułu)
  AV_PROP_ON_NC_MOUSE_MOVE = 'AvNCMoMo';
  AV_PROP_ON_NC_LBTN_DOWN  = 'AvNCLBD';
  AV_PROP_ON_NC_LBTN_UP    = 'AvNCLBU';
  AV_PROP_ON_NC_LBTN_DBL   = 'AvNCLBDC';
  AV_PROP_ON_NC_RBTN_DOWN  = 'AvNCRBD';
  AV_PROP_ON_NC_RBTN_UP    = 'AvNCRBU';
  //AV_PROP_ON_RESIZE = 'AvResz'; // zdarzenie zmiany rozmiaru
  AV_PROP_ON_RESIZE: PChar = 'AvResz';

  AV_PROP_ON_KEY_DOWN: PChar = 'AvKeyDn';
  AV_PROP_ON_KEY_UP: PChar = 'AvKeyUp';

  // Twarde deklaracje PChar, żeby WinAPI się nie zgubiło!
  //AV_PROP_ON_KEY_DOWN: PChar     = 'AvKeyDn';
  //AV_PROP_ON_KEY_UP: PChar       = 'AvKeyUp';
  AV_PROP_ON_SYS_KEY_DOWN: PChar = 'AvSysDn';
  AV_PROP_ON_SYS_KEY_UP: PChar   = 'AvSysUp';

  AV_PROP_ON_CHAR: PChar         = 'AvChar';
  AV_PROP_ON_SYS_CHAR: PChar     = 'AvSysCh';
  AV_PROP_ON_DEAD_CHAR: PChar    = 'AvDead';
  AV_PROP_ON_UNI_CHAR: PChar     = 'AvUni';
  AV_PROP_ON_CLOSE_QUERY: PChar = 'AvCloseQ';

  AV_PROP_ON_MOUSE_DOWN: PChar = 'AvMsDn';
 // AV_PROP_ON_POWER_EVENT: PChar = 'AvPwrEv'

  AV_PROP_ON_POWER:  PChar = 'AvPwrEv';
  AV_PROP_ON_DEVICE: PChar = 'AvDevEv';

  // Groupbox
  BS_GROUPBOX         = $0007;
  AV_PROP_GB_BG_COLOR : PWideChar = 'AvGbBgC';
  AV_PROP_GB_FONT : PWideChar = 'AvGbFont';



  EM_GETCHARFORMAT  = $043A;
  EM_GETTEXTRANGE   = $044B;
  EM_AUTOURLDETECT  = $045B;
  EM_FINDTEXTEXW    = $047C;
  EM_SETZOOM        = $04E1;
  //EM_SCROLLCARET    = $00B7;



  // Style tekstu (Maska i Efekt)
  CFM_BOLD          = $00000001;
  CFM_ITALIC        = $00000002;
  CFM_UNDERLINE     = $00000004;
  CFM_FACE          = $20000000;
  CFM_SIZE          = $80000000;

  CFE_BOLD          = $00000001;
  CFE_ITALIC        = $00000002;
  CFE_UNDERLINE     = $00000004;


  // --- RichEdit Messages ---
  EM_EXLIMITTEXT          = $0435;
  EM_EXLINEFROMCHAR       = $0436;
  EM_EXSETSEL             = $0437;
  EM_EXGETSEL             = $0434;
  EM_SETCHARFORMAT        = $0444;
  EM_SETEVENTMASK         = $0445;
  EM_SETBKGNDCOLOR        = $0443;
  EM_SETTYPOGRAPHYOPTIONS = $04CA;
  EM_GETPARAFORMAT        = $043D;
  EM_SETPARAFORMAT        = $0447;

  // Options & Masks
  TO_ADVANCEDTYPOGRAPHY   = $0001;
  SCF_ALL                 = $0004;
  SCF_SELECTION           = $0001;

  // Event Masks (Powiadomienia)
  ENM_CHANGE              = $00000001;
  ENM_SELCHANGE           = $00080000;
  ENM_LINK                = $00000020;
  ENM_DROPFILES           = $00100000;

  // Character & Para Format Masks
  CFM_COLOR               = $40000000;
  PFM_STARTINDENT         = $00000001;
  SCF_DEFAULT = $0000;
  CFE_AUTOTCOLOR   = $40000000;
  //Dla funkcji WideCharToMultiByte.
  CP_UTF8 = 65001;
  AV_PROP_TIME_CHANGE: PWideChar = 'av_on_time_change';

  CLEARTYPE_NATURAL_QUALITY = 6;
  // Stała określająca sposób wyświetlenia okna (Normalny)
  SW_SHOWNORMAL = 1;
  //menu
  AV_PROP_INIT_MENU_POPUP: PWideChar = 'av_on_init_popup';
  AV_PROP_MENU_SELECT: PWideChar = 'av_on_menu_select';
  AV_PROP_CONTEXT_MENU: PWideChar = 'av_on_context_menu';


type
  // Zakres znaków
  t_av_char_range = packed record
    cp_min: LongInt;
    cp_max: LongInt;
  end;

  // Struktura wyszukiwania
  t_av_find_text_ex = packed record
    chrg: t_av_char_range;
    lpstr_text: PWideChar;
    chrg_text: t_av_char_range;
  end;

  // Struktura pobierania tekstu (np. dla linków)
  t_av_text_range = packed record
    chrg: t_av_char_range;
    lpstr_text: PWideChar;
  end;

  // Powiadomienie o linku
  p_av_en_link = ^t_av_en_link;
  t_av_en_link = packed record
    nmhdr: NMHDR;
    msg: UINT;
    w_param: WPARAM;
    l_param: LPARAM;
    chrg: t_av_char_range;
  end;

type
HMONITOR = THandle;
tagMONITORINFO = packed record
  cbSize: DWORD;
  rcMonitor: TRect;
  rcWork: TRect;
  dwFlags: DWORD;
end;

  MONITORINFO = tagMONITORINFO;
  PMONITORINFO = ^MONITORINFO; // Wskaźnik do struktury

//  struktura trackmouseevent
type
  // Zmieniamy nazwę na TTrackMouseEvent (dodajemy 'T')
  TTrackMouseEvent = record
    cbSize: DWORD;
    dwFlags: DWORD;
    hwndTrack: HWND;
    dwHoverTime: DWORD;
  end;

type
  t_av_time_change_cb = procedure(h_wnd: HWND);
  t_av_init_popup_cb  = procedure(h_wnd: HWND; h_menu: HMENU; is_window_menu: Boolean);
  t_av_menu_select_cb = procedure(h_wnd: HWND; item_id: Word; flags: Word; h_menu: HMENU);



type
  TEditStreamCallback = function(dwCookie: DWORD_PTR; pbBuff: PByte; cb: LongInt; pcb: PLongInt): DWORD; stdcall;
type
  TAvocadoPaintEvent = procedure(Window: HWND; DC: HDC);
  TAvocadoMinMaxEvent = procedure(Window: HWND; MinMaxInfo: PMinMaxInfo);
  // Zdarzenie przekazuje uchwyt okna oraz nową szerokość i wysokość
  TAvocadoResizeEvent = procedure(h_wnd: HWND; width, height: Integer; resize_type: WPARAM);

type
    TAvoRenderFormatEvent = procedure(Sender: HWND; Format: UINT);
    TAvoRenderAllEvent = procedure(Sender: HWND);
type
  TAvoDropFilesEvent = procedure(Sender: HWND; DropHandle: THandle);

type
    TAvoDrawItemEvent = procedure(Sender: HWND; DrawStruct: PDRAWITEMSTRUCT);
type
  TAvoNotifyEvent = procedure(Sender: HWND);
// Zdarzenie zmiany wartości liczbowej (np. dla SpinEdit, ProgressBar, TrackBar)
type
TAvoIntChangeEvent = procedure(Sender: HWND; NewValue: Integer);

type
  // Info: Wskaźnik do struktury, w której ustawiamy limity (np. ptMinTrackSize)

  // CONTEXT MENU (Prawy przycisk myszy) ---

  //TAvocadoContextEvent = procedure(Sender: HWND; ScreenX, ScreenY: Integer);
   t_av_context_event = procedure(h_wnd: HWND; x, y: Integer);
type
  TSubclassProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
type
  TAvocadoScrollInfo = record
    Handle: HWND;
    ParentMemo: HWND;
    ThumbPos: Integer;   // Pozycja suwaka (w pikselach)
    ThumbHeight: Integer; // Wysokość suwaka
    IsDragging: Boolean;
  end;

type
  TAvocadoQueryEndSessionEvent = function(Sender: HWND; Reason: LPARAM): Boolean;
  TAvocadoEndSessionEvent = procedure(Sender: HWND; IsEnding: Boolean; Reason: UINT);
type
  // Status: Dodatkowe dane (np. poziom baterii)
  //TAvocadoPowerEvent = procedure(Sender: HWND; Event: WPARAM; Status: LPARAM);
  TAvocadoPowerEvent = procedure(h_wnd: HWND; event_code: UIntPtr; data: LPARAM);
  TAvocadoDeviceEvent = procedure(h_wnd: HWND; event_code: UIntPtr; data: LPARAM);
  t_av_init_menu_event = procedure(h_wnd: HWND; h_menu: HMENU; is_window_menu: Boolean);

  // Zdarzenie wywoływane, gdy użytkownik "najedzie" na pozycję w menu
  t_av_menu_select_event = procedure(h_wnd: HWND; item_id: Word; flags: Word; h_menu: HMENU);
  // --- DEVICE (Urządzenia USB/CD) ---
  // Event: Co się stało? (np. DBT_DEVICEARRIVAL - włożono USB)
  // Data: Wskaźnik na strukturę z detalami (co dokładnie włożono)
  //TAvocadoDeviceEvent = procedure(Sender: HWND; Event: WPARAM; Data: LPARAM);

type
  // TimerID: Numer identyfikacyjny timera (żebyś wiedział, który "zadzwonił")
  TAvocadoTimerEvent = procedure(Sender: HWND; TimerID: UINT_PTR);
//type
  //TAvocadoColorEvent = function(Sender: HWND; Control: HWND; DC: HDC): HBRUSH;
type
  TAvocadoColorEvent = procedure(Sender: HWND; var Normal, Hover, Pressed: DWORD);
  TAvocadoScrollEvent = procedure(Sender: HWND; ScrollCode: Word; Position: Integer; ScrollBarHandle: HWND);

//type
  //TAvocadoPaintEvent = procedure(Sender: HWND; DC: HDC);

type
  // Zdarzenie systemowe (np. minimalizacja, zamknięcie)
  // CmdType: np. SC_CLOSE, SC_MAXIMIZE
  TAvocadoSysCommandEvent = procedure(Sender: HWND; CmdType: Integer; X, Y: Integer);
  // Zwróć -1 (HTNOWHERE), jeśli chcesz zdać się na system.
  //TAvocadoHitTestEvent = function(Sender: HWND; X, Y: Integer): Integer;
  TAvocadoHitTestEvent = function(Window: HWND; X, Y: Integer): LRESULT; stdcall;

  // Zdarzenie inicjacji menu (żeby je np. zablokować/odblokować przed pokazaniem)
  TAvocadoInitMenuEvent = procedure(Sender: HWND; MenuHandle: HMENU; IsPopup: Boolean);

  // Zdarzenie wyboru elementu menu (hover) - np. do paska stanu
  TAvocadoMenuSelectEvent = procedure(Sender: HWND; ItemID: Word; Flags: Word; MenuHandle: HMENU);

  // Zdarzenie wejścia/wyjścia z pętli menu
  TAvocadoMenuLoopEvent = procedure(Sender: HWND; IsEntering: Boolean);
type
  TAvocadoCommandEvent = procedure(Sender: HWND; CommandID: Word);
type
  TAvocadoNotifyEvent = procedure(Sender: HWND; Header: PNMHDR);


type
  // Zdarzenie upuszczenia plików (zwraca listę ścieżek)
  //TAvocadoDropFilesEvent = procedure(Sender: HWND; Files: TStringList);
  TAvocadoDropFilesEvent = procedure(Sender: HWND; DropHandle: THandle);
  t_av_drop_files_event = procedure(h_wnd: HWND; drop_info: WPARAM);

  // Zdarzenia schowka (gdy system prosi o dane)
  TAvocadoRenderFormatEvent = procedure(Sender: HWND; Format: UINT);
  TAvocadoRenderAllEvent = procedure(Sender: HWND);

type
  TAvocadoActivateAppEvent = procedure(Sender: HWND; Active: Boolean; ThreadID: DWORD);
  TAvocadoEnableEvent = procedure(Sender: HWND; Enabled: Boolean);
  //TAvocadoNCMouseEvent = procedure(Sender: HWND; HitTest: Integer; X, Y: Integer);
  TAvocadoNCMouseEvent = procedure(h_wnd: HWND; x, y: Integer; hit_test: WPARAM);
  TAvocadoFocusEvent = procedure(Sender: HWND);

type
  // Zdarzenie myszy (X, Y to współrzędne względem okna)
  //TAvocadoMouseEvent = procedure(Sender: HWND; X, Y: Integer);
  TAvocadoMouseEvent = procedure(h_wnd: HWND; x, y: Integer);
  // Zdarzenie kółka myszy (Delta > 0 góra/prawo, Delta < 0 dół/lewo)
  //TAvocadoWheelEvent = procedure(Sender: HWND; Delta: Integer; X, Y: Integer);
  TAvocadoWheelEvent = procedure(h_wnd: HWND; x, y, delta: Integer);

type
  // Struktura z informacjami o monitorze
  TAvocadoMonitorInfo = record
    MonitorRect: TRect; // Pełna rozdzielczość monitora
    WorkRect: TRect;    // Obszar roboczy (bez paska zadań)
    IsPrimary: Boolean; // Czy to główny monitor
  end;

type
  // Definicja typu procedury: przyjmuje "Sender" czyli uchwyt klikniętego elementu
  TAvocadoEvent = procedure(Sender: HWND);
type
    //TAvocadoKeyEvent = procedure(Sender: HWND; Key: Word);
    TAvocadoKeyEvent = procedure(h_wnd: HWND; key_code: Word);
    TAvocadoCharEvent = procedure(h_wnd: HWND; key_char: WideChar);
    //TAvocadoCharEvent = procedure(Sender: HWND; Ch: WideChar);

type
  // Nowy typ: Funkcja zwracająca True (można zamknąć) lub False (zablokuj)
  TAvocadoCloseEvent = function(h_wnd: HWND): Boolean;

type
  // Nowy typ: Pozwala modyfikować Rect w trakcie zmiany rozmiaru!
  TAvocadoSizingEvent = procedure(Sender: HWND; var Rect: TRect; Edge: Integer);
  // Typ zdarzenia dla przesuwania - pozwala edytować Rect w locie
  TAvocadoMovingEvent = procedure(Sender: HWND; var Rect: TRect);

type
  // Zdarzenie dające dostęp do pełnej struktury WINDOWPOS
  TAvocadoWindowPosEvent = procedure(Sender: HWND; var WinPos: WINDOWPOS);
  TTextSelection = record
    StartPos: Integer;
    EndPos: Integer;
  end;


//type
 // TAvocadoMinMaxEvent = procedure(Window: HWND; MinMaxInfo: PMinMaxInfo);
type
  // Rodzaje kotwic
  TAvocadoAnchorKind = (akLeft, akTop, akRight, akBottom);
  TAvocadoAnchors = set of TAvocadoAnchorKind;

type
  MARGINS = record
    cxLeftWidth, cxRightWidth, cyTopHeight, cyBottomHeight: Integer;
  end;

function TrackMouseEvent(var lpEventTrack: TTrackMouseEvent): BOOL; stdcall; external 'user32.dll' name 'TrackMouseEvent';
function GetFileSizeEx(h_file: THandle; lp_file_size: PLargeInteger): BOOL; stdcall; external 'kernel32' name 'GetFileSizeEx';

// Ruch myszy
procedure set_on_mouse_move(Handle: HWND; Event: TAvocadoMouseEvent);
procedure set_on_lbutton_down(Handle: HWND; Event: TAvocadoMouseEvent);
function dispatch_mouse_event(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM): Boolean;

procedure set_on_mouse_wheel(h_wnd: HWND; event: TAvocadoWheelEvent);
procedure set_on_mouse_hwheel(h_wnd: HWND; event: TAvocadoWheelEvent);

procedure set_on_lbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_lbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_rbutton_down(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_rbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_rbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_mbutton_down(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_mbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
procedure set_on_mbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);

procedure set_on_hittest(HWnd: HWND; Event: TAvocadoHitTestEvent);

// interakcja z ramką i tytułem (non-client)
procedure set_on_nc_mouse_move(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
procedure set_on_nc_left_down(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
procedure set_on_nc_left_up(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
procedure set_on_nc_left_double_click(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
procedure set_on_nc_right_down(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
procedure set_on_nc_right_up(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
function dispatch_nc_event(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM): Boolean;
// Funkcja przypisująca reakcję na zmianę rozmiaru okna
procedure set_on_resize(h_wnd: HWND; event: TAvocadoResizeEvent);
procedure set_on_key_down(h_wnd: HWND; event: TAvocadoKeyEvent);
procedure set_on_key_up(h_wnd: HWND; event: TAvocadoKeyEvent);
//pomocnice funkcje
function lo_word(L: DWORD): Word; inline;
function hi_word(L: DWORD): Word; inline;
procedure set_on_close_query(h_wnd: HWND; on_close_event: TAvocadoCloseEvent);
procedure set_on_mouse_down(h_wnd: HWND; event: TAvocadoMouseEvent);
procedure set_on_power_event(h_wnd: HWND; event: TAvocadoPowerEvent);
procedure set_on_device_event(h_wnd: HWND; event: TAvocadoDeviceEvent);

// Odświeża interfejs w trakcie ciężkich obliczeń, zapobiegając zawieszeniu okna
procedure refresh_ui;
implementation

procedure set_on_mouse_move(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
  begin
    SetPropW(Handle, AV_PROP_ON_MOUSE_MOVE, THandle(Pointer(Event)));
  end;
end;

procedure set_on_lbutton_down(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    SetPropW(Handle, AV_PROP_ON_LBUTTON_DOWN, THandle(Pointer(Event)));
end;

function dispatch_mouse_event(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM): Boolean;
var
ptr: THandle;
on_wheel: TAvocadoWheelEvent;
on_mouse: TAvocadoMouseEvent;
pt: TPoint;
wheel_delta: Integer;
begin
 Result := False;

  case u_msg of
    WM_MOUSEMOVE:       Ptr := GetPropW(h_wnd, AV_PROP_ON_MOUSE_MOVE);
    WM_LBUTTONDOWN:     Ptr := GetPropW(h_wnd, AV_PROP_ON_LBUTTON_DOWN);
    WM_LBUTTONUP:       Ptr := GetPropW(h_wnd, AV_PROP_ON_LBUTTON_UP);
    WM_LBUTTONDBLCLK:   Ptr := GetPropW(h_wnd, AV_PROP_ON_LBUTTON_DBLCLK);
    WM_RBUTTONDOWN:     Ptr := GetPropW(h_wnd, AV_PROP_ON_RBUTTON_DOWN);
    WM_RBUTTONUP:       Ptr := GetPropW(h_wnd, AV_PROP_ON_RBUTTON_UP);
    WM_RBUTTONDBLCLK:   Ptr := GetPropW(h_wnd, AV_PROP_ON_RBUTTON_DBLCLK);
    WM_MBUTTONDOWN:     Ptr := GetPropW(h_wnd, AV_PROP_ON_MBUTTON_DOWN);
    WM_MBUTTONUP:       Ptr := GetPropW(h_wnd, AV_PROP_ON_MBUTTON_UP);
    WM_MBUTTONDBLCLK:   Ptr := GetPropW(h_wnd, AV_PROP_ON_MBUTTON_DBLCLK);
    WM_MOUSEWHEEL:  ptr := GetPropW(h_wnd, AV_PROP_ON_WHEEL);
    WM_MOUSEHWHEEL: ptr := GetPropW(h_wnd, AV_PROP_ON_HWHEEL);
    else Ptr := 0;
  end;


  if Ptr <> 0 then
  begin
    on_wheel := TAvocadoWheelEvent(Pointer(ptr));

   if (u_msg = WM_MOUSEWHEEL) or (u_msg = WM_MOUSEHWHEEL) then
    begin

     on_wheel := TAvocadoWheelEvent(Pointer(ptr));

      // Dla kółka l_param to współrzędne EKRANOWE, musimy je przeliczyć na lokalne (Client)
      pt.X := lo_word(l_param);
      pt.Y := hi_word(l_param);
      ScreenToClient(h_wnd, pt);

      // Przeliczamy współrzędne ekranowe na lokalne okna
      //pt.X := SmallInt(l_param and $FFFF);
      //pt.Y := SmallInt(l_param shr 16);
      //ScreenToClient(h_wnd, pt);


      //on_wheel(h_wnd, pt.X, pt.Y);
      wheel_delta := SmallInt(hi_word(w_param));
      on_wheel(h_wnd, pt.X, pt.Y, wheel_delta);
    end
    else
    begin
      // Zwykłe zdarzenia (LButton itp. - jeśli używają tego samego typu eventu)
     // TAvocadoMouseEvent(Pointer(ptr))(h_wnd, SmallInt(l_param), SmallInt(l_param shr 16));
      on_mouse := TAvocadoMouseEvent(Pointer(ptr));

      // Tutaj l_param to już są współrzędne lokalne okna
      on_mouse(h_wnd, lo_word(l_param), hi_word(l_param));
    end;

    Result := True;
  end;
end;


procedure set_on_mouse_wheel(h_wnd: HWND; event: TAvocadoWheelEvent);
begin
    if h_wnd <> 0 then
    SetPropW(h_wnd, AV_PROP_ON_WHEEL, THandle(Pointer(event)));
end;

procedure set_on_mouse_hwheel(h_wnd: HWND; event: TAvocadoWheelEvent);
begin
    if h_wnd <> 0 then
    SetPropW(h_wnd, AV_PROP_ON_HWHEEL, THandle(Pointer(event)));
end;

procedure set_on_lbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_LBUTTON_UP, THandle(Pointer(Event)));
end;

procedure set_on_lbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_LBUTTON_DBLCLK, THandle(Pointer(Event)));
end;

procedure set_on_rbutton_down(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_RBUTTON_DOWN, THandle(Pointer(Event)));
end;

procedure set_on_rbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_RBUTTON_UP, THandle(Pointer(Event)));
end;

procedure set_on_rbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_RBUTTON_DBLCLK, THandle(Pointer(Event)));
end;

procedure set_on_mbutton_down(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_MBUTTON_DOWN, THandle(Pointer(Event)));
end;

procedure set_on_mbutton_up(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_MBUTTON_UP, THandle(Pointer(Event)));
end;

procedure set_on_mbutton_dbl_clk(HWnd: HWND; Event: TAvocadoMouseEvent);
begin
   if HWnd <> 0 then
   SetPropW(HWnd, AV_PROP_ON_MBUTTON_DBLCLK, THandle(Pointer(Event)));
end;

procedure set_on_hittest(HWnd: HWND; Event: TAvocadoHitTestEvent);
begin
  if HWnd <> 0 then
  SetPropW(HWnd, AV_PROP_ON_HITTEST, THandle(Pointer(Event)));
end;

procedure set_on_nc_mouse_move(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
  if h_wnd <> 0 then
  begin
    // Używamy SetPropW, aby "przykleić" wskaźnik do zdarzenia bezpośrednio do okna
    // AV_PROP_ON_NC_MOUSE_MOVE to Twoja stała (np. 'AvNCMoMo')
    SetPropW(h_wnd, AV_PROP_ON_NC_MOUSE_MOVE, THandle(Pointer(event)));
  end;
end;

procedure set_on_nc_left_down(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
  if h_wnd <> 0 then
  SetPropW(h_wnd, AV_PROP_ON_NC_LBTN_DOWN, THandle(Pointer(event)));
end;

procedure set_on_nc_left_up(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
  if h_wnd <> 0 then
  SetPropW(h_wnd, AV_PROP_ON_NC_LBTN_UP, THandle(Pointer(event)));
end;

procedure set_on_nc_left_double_click(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
  if h_wnd <> 0 then
  begin
  SetPropW(h_wnd, AV_PROP_ON_NC_LBTN_DBL, THandle(Pointer(event)));
  end;
end;

procedure set_on_nc_right_down(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
  if h_wnd <> 0 then
  begin
    SetPropW(h_wnd, AV_PROP_ON_NC_RBTN_DOWN, THandle(Pointer(event)));
  end;
end;

procedure set_on_nc_right_up(h_wnd: HWND; Event: TAvocadoNCMouseEvent);
begin
    if h_wnd <> 0 then
    begin
      SetPropW(h_wnd, AV_PROP_ON_NC_RBTN_UP, THandle(Pointer(event)));
    end;
end;

function dispatch_nc_event(h_wnd: HWND; u_msg: UINT; w_param: WPARAM;l_param: LPARAM): Boolean;
var
  ptr: THandle;
  on_nc_mouse: TAvocadoNCMouseEvent;
begin
 Result := False;

   // 1. Mapujemy komunikat na odpowiedni klucz szufladki
   case u_msg of
     WM_NCMOUSEMOVE:       ptr := GetPropW(h_wnd, AV_PROP_ON_NC_MOUSE_MOVE);
     WM_NCLBUTTONDOWN:     ptr := GetPropW(h_wnd, AV_PROP_ON_NC_LBTN_DOWN);
     WM_NCLBUTTONUP:       ptr := GetPropW(h_wnd, AV_PROP_ON_NC_LBTN_UP);
     WM_NCLBUTTONDBLCLK:   ptr := GetPropW(h_wnd, AV_PROP_ON_NC_LBTN_DBL);
     WM_NCRBUTTONDOWN:     ptr := GetPropW(h_wnd, AV_PROP_ON_NC_RBTN_DOWN);
     WM_NCRBUTTONUP:       ptr := GetPropW(h_wnd, AV_PROP_ON_NC_RBTN_UP);
     else ptr := 0;
   end;

   //Jeśli znaleźliśmy podpiętą funkcję, wywołujemy ją
   if ptr <> 0 then
   begin
     on_nc_mouse := TAvocadoNCMouseEvent(Pointer(ptr));

     // Przekazujemy: uchwyt, X, Y oraz Hit-Test (z w_param)
     // Współrzędne NC są w układzie ekranu (nie trzeba ScreenToClient)
     on_nc_mouse(h_wnd,
                 SmallInt(l_param and $FFFF),
                 SmallInt(l_param shr 16),
                 w_param);

     Result := True;
   end;
end;

procedure set_on_resize(h_wnd: HWND; event: TAvocadoResizeEvent);
begin
  if h_wnd <> 0 then
    //Windows.Beep(1000, 100);
    SetPropA(h_wnd, AV_PROP_ON_RESIZE, THandle(Pointer(event)));
    //SetPropA(h_wnd, PChar(AV_PROP_ON_RESIZE), THandle(Pointer(event)));
end;

procedure set_on_key_down(h_wnd: HWND; event: TAvocadoKeyEvent);
begin
  if h_wnd <> 0 then
      SetPropA(h_wnd, AV_PROP_ON_KEY_DOWN, THandle(Pointer(event)));
end;

procedure set_on_key_up(h_wnd: HWND; event: TAvocadoKeyEvent);
begin
  if h_wnd <> 0 then
    SetPropA(h_wnd, AV_PROP_ON_KEY_UP, THandle(Pointer(event)));
end;

function lo_word(L: DWORD): Word;
begin
  Result := Word(l and $FFFF);
end;

function hi_word(L: DWORD): Word;
begin
  Result := Word((l shr 16) and $FFFF);
end;

procedure set_on_close_query(h_wnd: HWND; on_close_event: TAvocadoCloseEvent);
begin
  if h_wnd <> 0 then
    SetPropA(h_wnd, AV_PROP_ON_CLOSE_QUERY, THandle(Pointer(on_close_event)));
end;

procedure set_on_mouse_down(h_wnd: HWND; event: TAvocadoMouseEvent);
begin
  if h_wnd <> 0 then
    //SetPropA(h_wnd, AV_PROP_ON_MOUSE_DOWN, THandle(Pointer(event)));
    SetPropA(h_wnd, AV_PROP_ON_LBUTTON_DOWN, THandle(Pointer(event)));
end;

procedure set_on_power_event(h_wnd: HWND; event: TAvocadoPowerEvent);
begin
  if h_wnd <> 0 then
    SetPropA(h_wnd, AV_PROP_ON_POWER, THandle(Pointer(event)));
end;

procedure set_on_device_event(h_wnd: HWND; event: TAvocadoDeviceEvent);
begin
  if h_wnd <> 0 then
    SetPropA(h_wnd, AV_PROP_ON_DEVICE, THandle(Pointer(event)));
end;

procedure refresh_ui;
var
  msg: TMsg;
begin
  while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end;

end.


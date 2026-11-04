(*
Avocado UI - an interface creation library for the Avocado programming language.
Author:  Programista Art
e-mail: programista.art@gmail.com
GitHub: https://github.com/Programista-Art
Website: https://avocado-code.com/
Version: 1.0
Date 23.12.2025
*)
unit avocado_ui;
{$MODE objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Windows,SysUtils;

type
  TAvocadoPaintEvent = procedure(Sender: HWND; DC: HDC);

type
  // Zdarzenie systemowe (np. minimalizacja, zamknięcie)
  // CmdType: np. SC_CLOSE, SC_MAXIMIZE
  TAvocadoSysCommandEvent = procedure(Sender: HWND; CmdType: Integer; X, Y: Integer);
  // Zwróć -1 (HTNOWHERE), jeśli chcesz zdać się na system.
  TAvocadoHitTestEvent = function(Sender: HWND; X, Y: Integer): Integer;

  // Zdarzenie inicjacji menu (żeby je np. zablokować/odblokować przed pokazaniem)
  TAvocadoInitMenuEvent = procedure(Sender: HWND; MenuHandle: HMENU; IsPopup: Boolean);

  // Zdarzenie wyboru elementu menu (hover) - np. do paska stanu
  TAvocadoMenuSelectEvent = procedure(Sender: HWND; ItemID: Word; Flags: Word; MenuHandle: HMENU);

  // Zdarzenie wejścia/wyjścia z pętli menu
  TAvocadoMenuLoopEvent = procedure(Sender: HWND; IsEntering: Boolean);
type
  TAvocadoCommandEvent = procedure(Sender: HWND; CommandID: Word);
type
  // Sender: Okno
  // IsActivating: True = Aplikacja staje się aktywna, False = Użytkownik idzie do innego programu
  // ThreadId: ID wątku drugiego okna (zazwyczaj niepotrzebne, ale dostępne)
  TAvocadoActivateAppEvent = procedure(Sender: HWND; IsActivating: Boolean; ThreadId: DWORD);

  // Enabled: True = Okno odblokowane, False = Okno zablokowane
  TAvocadoEnableEvent = procedure(Sender: HWND; Enabled: Boolean);

type
  TAvocadoNCMouseEvent = procedure(Sender: HWND; HitTest: Integer; X, Y: Integer);

type
  TAvocadoFocusEvent = procedure(Sender: HWND);

type
  // Zdarzenie myszy (X, Y to współrzędne względem okna)
  TAvocadoMouseEvent = procedure(Sender: HWND; X, Y: Integer);

  // Zdarzenie kółka myszy (Delta > 0 góra/prawo, Delta < 0 dół/lewo)
  TAvocadoWheelEvent = procedure(Sender: HWND; Delta: Integer; X, Y: Integer);

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
  // Nowy typ zdarzenia dla klawiatury - przekazuje kod klawisza (Key)
  //TAvocadoKeyEvent = procedure(Sender: HWND; Key: Word);
   TAvocadoKeyEvent = procedure(Sender: HWND; KeyCode: Word);
  // Zdarzenie wpisania znaku (np. 'A', 'ł', '@')
  TAvocadoCharEvent = procedure(Sender: HWND; C: WideChar);

type
  // Nowy typ: Funkcja zwracająca True (można zamknąć) lub False (zablokuj)
  TAvocadoCloseEvent = function(Sender: HWND): Boolean;

type
  // Nowy typ: Pozwala modyfikować Rect w trakcie zmiany rozmiaru!
  TAvocadoSizingEvent = procedure(Sender: HWND; var Rect: TRect);
type
  // Typ zdarzenia dla przesuwania - pozwala edytować Rect w locie
  TAvocadoMovingEvent = procedure(Sender: HWND; var Rect: TRect);

type
  // Zdarzenie dające dostęp do pełnej struktury WINDOWPOS
  TAvocadoWindowPosEvent = procedure(Sender: HWND; var WinPos: WINDOWPOS);
  TTextSelection = record
    StartPos: Integer; // Gdzie zaczyna się zaznaczenie
    EndPos: Integer;   // Gdzie się kończy
  end;


//type
  // Zdarzenie tuż przed otwarciem menu (do blokowania opcji)
  //TAvocadoInitMenuEvent = procedure(Sender: HWND; MenuHandle: HMENU; IsPopup: Boolean);
  //// Zdarzenie najechania myszką na opcję (do paska statusu)
  //TAvocadoMenuSelectEvent = procedure(Sender: HWND; ItemID: Word; Flags: Word; MenuHandle: HMENU);

type
  TAvocadoWindowParams = record
    Parent: HWND;       // <--- DODAJ TO (0 = Główne, Inne = Podrzędne)
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
  // Rodzaje kotwic
  TAvocadoAnchorKind = (akLeft, akTop, akRight, akBottom);
  TAvocadoAnchors = set of TAvocadoAnchorKind;

type
  MARGINS = record
    cxLeftWidth, cxRightWidth, cyTopHeight, cyBottomHeight: Integer;
  end;


  {OKNO}
function GetMenuEntryIndex(Handle: HWND): Integer;
function CreateAvocadoWindow(Params: TAvocadoWindowParams): HWND;
procedure ShowWindowAvocado(var msg: TMsg); // Zmieniono na var dla wydajności
procedure SetDarkMode(Handle: HWND; Enable: Boolean);
function AvocadoWindowProc(Window: HWND; Message: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
procedure SetOnPaint(Handle: HWND; Event: TAvocadoPaintEvent);
//zamykanie okna
procedure CloseAvocadoWindow(Handle: HWND);
procedure Focus(Handle: HWND);
procedure ActivateWindow(Handle: HWND);
function GetText(Handle: HWND): string;
procedure SetText(Handle: HWND; const AText: string);

//domyslne parametry
function DefaultWindowParams: TAvocadoWindowParams;
//
procedure SetOnHitTest(Handle: HWND; Event: TAvocadoHitTestEvent);
// Sprawdza, czy okno jest zminimalizowane do paska zadań
function IsWindowMinimized(Handle: HWND): Boolean;
// Funkcje rejestrujące
procedure SetOnInitMenuPopup(Handle: HWND; Event: TAvocadoInitMenuEvent);
procedure SetOnMenuSelect(Handle: HWND; Event: TAvocadoMenuSelectEvent);
// Sprawdza, czy okno jest zmaksymalizowane na cały ekran
function IsWindowMaximized(Handle: HWND): Boolean;

// Pobiera tytuł okna (Alias dla GetText, dla czytelności)
function GetWindowTitle(Handle: HWND): string;
procedure SetOnMenuCommand(Handle: HWND; Event: TAvocadoCommandEvent);
// Włącza efekt rozmycia tła (Acrylic / Blur)
// Color: Opcjonalnie kolor tinty (np. $00000000 dla czystego rozmycia)
procedure SetBlurBehind(Handle: HWND; Enable: Boolean);
// Natychmiast niszczy okno lub kontrolkę (przycisk, label, itp.)
// Używaj tego do dynamicznego usuwania elementów.
procedure DestroyControl(Handle: HWND);
// (Windows 11) Zaokrąglone rogi
// Mode: 0=Domyślne, 1=Kwadratowe (Brak), 2=Okrągłe, 3=Małe Okrągłe
procedure SetWindowRoundedCorners(Handle: HWND; Mode: Integer);

// Cień pod oknem (szczególnie dla Frameless)
procedure SetWindowShadow(Handle: HWND; Enable: Boolean);

// aby móc zmieniać napis na pasku tytułu "w locie", np. pokazując postęp ładowania lub nazwę otwartego pliku?
procedure SetTitle(Handle: HWND; const NewTitle: string);
//POZYCJA OKNA
// --- ZDARZENIA FOKUSA ---
procedure SetOnSetFocus(Handle: HWND; Event: TAvocadoFocusEvent);
procedure SetOnKillFocus(Handle: HWND; Event: TAvocadoFocusEvent);

//Center okna
procedure CenterWindow(Handle: HWND);
procedure SetPosition(Handle: HWND; X, Y: Integer);
procedure SetSize(Handle: HWND; Width, Height: Integer);
procedure SetBounds(Handle: HWND; X, Y, Width, Height: Integer);
// Rejestracja zdarzenia "W trakcie zmiany rozmiaru"
procedure SetOnSizing(Handle: HWND; OnSizingEvent: TAvocadoSizingEvent);
function FindSizingEvent(Handle: HWND): TAvocadoSizingEvent;
function FindMovingEvent(Handle: HWND): TAvocadoMovingEvent;
function FindPosChangingEvent(Handle: HWND): TAvocadoWindowPosEvent;

// Rejestracja zdarzenia w trakcie przesuwania
procedure SetOnMoving(Handle: HWND; OnMovingEvent: TAvocadoMovingEvent);
// Rejestracja zdarzenia "Zanim zmieni się pozycja"
procedure SetOnWindowPosChanging(Handle: HWND; OnPosChangingEvent: TAvocadoWindowPosEvent);
//Przezroczystyosc okna
procedure SetOpacity(Handle: HWND; Opacity: Byte);
//Zmiana stanu wyświetlania (pełny ekran, do paska, przywrócenie).
procedure MaximizeWindow(Handle: HWND);
procedure MinimizeWindow(Handle: HWND);
procedure RestoreWindow(Handle: HWND);

// Pobiera informacje o monitorze, na którym znajduje się okno
function GetWindowMonitorInfo(Handle: HWND): TAvocadoMonitorInfo;

// Włącza/Wyłącza przyklejanie do krawędzi (Snapping)
// SnapDistance: Odległość w pikselach, przy której okno "przeskoczy" (domyślnie 20)
procedure SetWindowSticky(Handle: HWND; Enable: Boolean; SnapDistance: Integer = 20);

//ustawienie koloru naglowka okna
procedure SetCaptionColor(Handle: HWND; Color: DWORD);
//ustawienie koloru tekstu naglowka okna
procedure SetCaptionTextColor(Handle: HWND; Color: DWORD);
//tysowanie teksta na srodku okna
procedure DrawTextCenter(Handle: HWND; const AText: string; Color: DWORD);
// Blokuje (False) lub Odblokowuje (True) okno.
// Zablokowane okno nie reaguje na myszkę ani klawiaturę.
procedure SetWindowEnabled(Handle: HWND; Enable: Boolean);
//Pobieranie aktualnej pozycji i rozmiaru okna
function GetX(Handle: HWND): Integer;
function GetY(Handle: HWND): Integer;
function GetWidth(Handle: HWND): Integer;
function GetHeight(Handle: HWND): Integer;
//gdy chcesz precyzyjnie układać elementy wewnątrz okna (np. centrować Memo lub przyciski),
//ponieważ pomija ono grubości ramek i wysokość paska tytułu.
function GetClientArea(Handle: HWND): TRect;
//czy Twoje okno jest obecnie oknem aktywnym (tym, w którym
//użytkownik aktualnie pisze lub które widzi nad wszystkimi innymi)
function IsWindowOnTop(Handle: HWND): Boolean;
//Okno zawsze na wierzchu
procedure SetAlwaysOnTop(Handle: HWND; Enable: Boolean);
//Focus - Sprawia, że okno staje się aktywne i przyjmuje sygnały z klawiatury
function GetFocusEntryIndex(Handle: HWND): Integer;
//nadanie koloru oknu
procedure SetColor(Handle: HWND; Color: DWORD);
//Włączanie/wyłączanie ramek (przydatne do trybu Fullscreen).
procedure SetBorder(Handle: HWND; Enable: Boolean);
//Czy użytkownik może przeciągać krawędzie okna.
procedure SetSizable(Handle: HWND; Enable: Boolean);
//Ukrywanie przycisku minimalizacji.
procedure SetMinimizeButton(Handle: HWND; Enable: Boolean);
// --- INTERAKCJA I WIDOCZNOŚĆ (Z-Order) ---
// Wyciąga okno na wierzch (bez aktywowania/kradzenia klawiatury)
procedure BringToTop(Handle: HWND);
// Spycha okno na sam spód (pod inne okna)
procedure SendToBack(Handle: HWND);
// Pokaż okno (jeśli było ukryte)
procedure Show(Handle: HWND);
// Ukryj okno (staje się niewidoczne, ale program działa dalej)
procedure Hide(Handle: HWND);
//Ograniczanie minimalnego rozmiaru
procedure SetMinWindowSize(Handle: HWND; MinWidth, MinHeight: Integer);
//Reakcja na przesunięcie okna
procedure SetOnMove(Handle: HWND; OnMoveEvent: TAvocadoEvent);
// Funkcja pomocnicza do szukania (wewnętrzna)
function FindMoveEvent(Handle: HWND): TAvocadoEvent;
// --- ODŚWIEŻANIE I RYSOWANIE ---
// Wymusza natychmiastowe przerysowanie okna (WM_PAINT)
procedure Repaint(Handle: HWND);
// Oznacza okno jako "do odświeżenia" przy najbliższej okazji (lżejsze niż Repaint)
procedure Invalidate(Handle: HWND);
// Zatrzymuje rysowanie okna (WM_SETREDRAW = False).
// Używaj przed dużymi operacjami (np. dodawanie 1000 elementów), żeby uniknąć migania.
procedure BeginUpdate(Handle: HWND);
// Przywraca rysowanie okna (WM_SETREDRAW = True) i odświeża je.
// Używaj po zakończeniu dużych operacji.
procedure EndUpdate(Handle: HWND);
// Robi "zdjęcie" okna i kopiuje je do Schowka (używa WM_PRINT)
procedure SnapshotToClipboard(Handle: HWND);
// Ustawia limit znaków dla Memo.
// Limit: 0 = Maksymalny możliwy (ok. 2 miliardy znaków).
procedure SetMemoLimit(Handle: HWND; Limit: Integer);

// --- ZDARZENIA STANU APLIKACJI ---
procedure SetOnActivateApp(Handle: HWND; Event: TAvocadoActivateAppEvent);
procedure SetOnEnable(Handle: HWND; Event: TAvocadoEnableEvent);
// --- OBSŁUGA KLAWIATURY ---

// Klawisze fizyczne (Virtual Keys)
//procedure SetOnKeyDown(Handle: HWND; Event: TAvocadoKeyEvent);
//procedure SetOnKeyUp(Handle: HWND; Event: TAvocadoKeyEvent);

// Klawisze systemowe (z wciśniętym ALT lub F10)
procedure SetOnSysKeyDown(Handle: HWND; Event: TAvocadoKeyEvent);
procedure SetOnSysKeyUp(Handle: HWND; Event: TAvocadoKeyEvent);

// Wprowadzanie tekstu (Znaki)
procedure SetOnChar(Handle: HWND; Event: TAvocadoCharEvent);     // Zwykłe znaki
procedure SetOnSysChar(Handle: HWND; Event: TAvocadoCharEvent);  // Znaki z ALT (rzadkie)
procedure SetOnDeadChar(Handle: HWND; Event: TAvocadoCharEvent); // "Martwe" znaki (np. ogonek przed ą)
procedure SetOnUniChar(Handle: HWND; Event: TAvocadoCharEvent);  // Uniwersalne znaki Unicode (nowoczesne)

{PRZYCISK}
// Tworzenie przycisku
function CreateAvocadoButton(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
// Tworzenie w pełni kolorowalnego przycisku (Custom)
function CreateCustomButton(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
// Procedura obsługująca zachowanie naszego przycisku
function AvocadoButtonProc(Window: HWND; Message: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
// Ustawianie kolorów dla Custom Button (Normalny, Najechanie, Wciśnięcie, Tekst)
procedure SetButtonColors(Handle: HWND; ColNormal, ColHover, ColPressed, ColText: DWORD);
function MakeWParam(Low, High: Word): WPARAM; inline;

// --- ZAZNACZANIE TEKSTU (SELECTION) ---

// Ustawia zaznaczenie od StartPos do EndPos
// Jeśli StartPos = EndPos, po prostu przesuwa kursor w to miejsce.
procedure SelectText(Handle: HWND; StartPos, EndPos: Integer);
// Zaznacza cały tekst w kontrolce (Skrót Ctrl+A)
procedure SelectAllText(Handle: HWND);
// Pobiera informację, gdzie jest kursor lub co jest zaznaczone
function GetSelection(Handle: HWND): TTextSelection;
// Ustawia kursor na konkretnej pozycji (indeks znaku od 0)
procedure SetCursorPosition(Handle: HWND; Position: Integer);
// Przesuwa kursor na sam koniec tekstu (przydatne przy logach)
procedure MoveCursorToEnd(Handle: HWND);

// Zamienia zaznaczony tekst na inny (lub wstawia w miejscu kursora)
// CanUndo: Czy operację można cofnąć (Ctrl+Z)? Domyślnie True.
procedure ReplaceSelection(Handle: HWND; const NewText: string; CanUndo: Boolean = True);

// --- OPERACJE NA LINIACH (Dla Memo/Edit) ---
// Zwraca całkowitą liczbę linii w tekście
function GetLineCount(Handle: HWND): Integer;
// Zwraca numer linii, w której znajduje się dany znak (indeks znaku)
// Jeśli CharIndex = -1, zwraca linię, w której jest kursor (caret).
function GetLineFromChar(Handle: HWND; CharIndex: Integer): Integer;
// Pomocnicza: Zwraca numer aktualnej linii (tam gdzie jest kursor)
function GetCurrentLineNumber(Handle: HWND): Integer;
// Zwraca indeks pierwszego znaku w podanej linii
// (Przydatne do ustawiania kursora na początku konkretnej linii)
function GetLineIndex(Handle: HWND; LineIndex: Integer): Integer;
// Zwraca długość linii (w znakach)

// Pozwala aplikacji przetworzyć zaległe zdarzenia (zapobiega "zwiechom" w pętlach)
procedure ProcessMessages;
// CharIndex: Dowolny znak należący do tej linii (lub -1 dla bieżącej)
function GetLineLength(Handle: HWND; CharIndex: Integer): Integer;

// Pobiera tekst konkretnej linii jako String
function GetLineText(Handle: HWND; LineIndex: Integer): string;

{LABEL}
// Tworzenie etykiety tekstowej (Label)
function CreateAvocadoLabel(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
// Tworzenie pola edycyjnego jednowierszowego (Input)
function CreateAvocadoEdit(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;


{CHECKBOX}
function CreateAvocadoCheckbox(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
// Sprawdzanie stanu Checkboxa
function IsCheckboxChecked(Handle: HWND): Boolean;

// Ustawianie kolorów dla Label, Edit, Memo (i tła Checkbox)
procedure SetComponentColor(Handle: HWND; TextColor, BackgroundColor: DWORD);

{GRAFIKA GDI}
//Prosta grafika GDI
// Rysowanie prostokąta (obrys)
procedure DrawRectangle(Handle: HWND; X, Y, W, H: Integer; Color: DWORD);
// Rysowanie wypełnionego prostokąta
procedure DrawFillRectangle(Handle: HWND; X, Y, W, H: Integer; Color: DWORD);

{MESSAGE KOMUNIKATY}
// Wyświetlanie prostego komunikatu
procedure ShowMessage(Owner: HWND; const Title, Text: string);
// Wyświetlanie pytania Tak/Nie (zwraca True dla Tak)
function AskQuestion(Owner: HWND; const Title, Text: string): Boolean;
//kotwica
procedure SetAnchor(Control: HWND; Anchors: TAvocadoAnchors);
procedure UpdateLayout(ParentWnd: HWND);

// --- UNIWERSALNE FUNKCJE SCHOWKA (CLIPBOARD) ---
// Działają dla Edit, Memo, RichEdit, ComboBox

procedure CopyToClipboard(Handle: HWND);   // Kopiuje zaznaczenie
procedure CutToClipboard(Handle: HWND);    // Wycina zaznaczenie
procedure PasteFromClipboard(Handle: HWND);// Wkleja w miejscu kursora
procedure UndoLastAction(Handle: HWND);    // Cofnij (Ctrl+Z)
function CanUndo(Handle: HWND): Boolean;   // Czy można cofnąć?


{KOMPONENT MEMO}
function CreateAvocadoMemo(Parent: HWND; X, Y, Width, Height: Integer): HWND;
function GetMemoText(hMemo: HWND): string;
procedure AppendMemoText(hMemo: HWND; const Text: string);
// Zwraca długość tekstu w oknie lub kontrolce (liczba znaków)
function GetWindowTextLength(Handle: HWND): Integer;
// Czyści całą zawartość pola Memo
procedure ClearControl(Handle: HWND);


{ZDARZENIA}
// --- INTERAKCJA Z MYSZKĄ ---

// Ruch myszy
procedure SetOnMouseMove(Handle: HWND; Event: TAvocadoMouseEvent);

// Lewy Przycisk (LMB)
procedure SetOnMouseLeftDown(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseLeftUp(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseLeftDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);

// Prawy Przycisk (RMB)
procedure SetOnMouseRightDown(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseRightUp(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseRightDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);

// Środkowy Przycisk (MMB / Scroll)
procedure SetOnMouseMiddleDown(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseMiddleUp(Handle: HWND; Event: TAvocadoMouseEvent);
procedure SetOnMouseMiddleDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);

// Kółko myszy (Scroll)
procedure SetOnMouseWheel(Handle: HWND; Event: TAvocadoWheelEvent);       // Pionowo
procedure SetOnMouseHWheel(Handle: HWND; Event: TAvocadoWheelEvent);      // Poziomo

// --- INTERAKCJA Z RAMKĄ I TYTUŁEM (NON-CLIENT) ---
procedure SetOnNCMouseMove(Handle: HWND; Event: TAvocadoNCMouseEvent);
procedure SetOnNCLeftDown(Handle: HWND; Event: TAvocadoNCMouseEvent);
procedure SetOnNCLeftUp(Handle: HWND; Event: TAvocadoNCMouseEvent);
procedure SetOnNCLeftDoubleClick(Handle: HWND; Event: TAvocadoNCMouseEvent);
procedure SetOnNCRightDown(Handle: HWND; Event: TAvocadoNCMouseEvent);
procedure SetOnNCRightUp(Handle: HWND; Event: TAvocadoNCMouseEvent);

// Funkcja przypisująca reakcję na kliknięcie
procedure SetOnClick(Handle: HWND; OnClickEvent: TAvocadoEvent);
// Procedura pomocnicza do szukania zdarzenia (wewnętrzna)
function FindEvent(Handle: HWND): TAvocadoEvent;
// Funkcja przypisująca reakcję na zmianę rozmiaru okna
procedure SetOnResize(Handle: HWND; OnResizeEvent: TAvocadoEvent);
// Funkcja pomocnicza do szukania zdarzenia zmiany rozmiaru
function FindResizeEvent(Handle: HWND): TAvocadoEvent;
// Rejestracja zdarzeń klawiatury
procedure SetOnKeyDown(Handle: HWND; Event: TAvocadoKeyEvent);
procedure SetOnKeyUp(Handle: HWND; Event: TAvocadoKeyEvent);
//pomocnice funkcje
function LoWord(L: DWORD): Word; inline;
function HiWord(L: DWORD): Word; inline;
function FindKeyDownEvent(Handle: HWND): TAvocadoKeyEvent;
function FindKeyUpEvent(Handle: HWND): TAvocadoKeyEvent;
// Funkcja rejestrująca
procedure SetOnCloseQuery(Handle: HWND; OnCloseEvent: TAvocadoCloseEvent);
// Funkcja szukająca
function FindCloseEvent(Handle: HWND): TAvocadoCloseEvent;
function FlashWindowEx(var pfwi: TFlashWInfo): BOOL; stdcall; external 'user32.dll';
//ustawienie czy ma byc aktywny przycisk maksymalizacji na oknie
procedure SetWindowMaximizeButton(Handle: HWND; Enabled: Boolean);
// Funkcja pomocnicza (taka sama logika jak przy myszy)
function GetKeyEntryIndex(Handle: HWND): Integer;
// --- INTERAKCJA PASKIEM ZADAŃ ---

// Miganie oknem na pasku zadań (Powiadomienia)
// Handle: uchwyt okna
// Count: liczba mrugnięć (wpisz -1, aby mrugało dopóki nie klikniesz w okno)
// Interval: szybkość w ms (0 = domyślna systemowa, np. 500ms)
procedure FlashWindow(Handle: HWND; Count: Integer; Interval: Integer);




const
  UNICODE_NOCHAR = $FFFF; // <--- Dodaj to tutaj
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  FLASHW_STOP = 0;
  FLASHW_CAPTION = 1;
  FLASHW_TRAY = 2;
  FLASHW_ALL = 3;        // FLASHW_CAPTION or FLASHW_TRAY
  FLASHW_TIMER = 4;      // Mrugaj ciągle
  FLASHW_TIMERNOFG = 12; // Mrugaj dopóki okno nie wyjdzie na wierzch

  // Stałe dla SetWindowCompositionAttribute (Blur/Acrylic)
  WCA_ACCENT_POLICY = 19;
  ACCENT_DISABLED = 0;
  ACCENT_ENABLE_GRADIENT = 1;
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2;
  ACCENT_ENABLE_BLURBEHIND = 3;        // Klasyczny Blur
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4; // Acrylic (Win 10+)
  ACCENT_ENABLE_HOSTBACKDROP = 5;      // Mica (Win 11)

  // Stałe dla DwmSetWindowAttribute
  DWMWA_WINDOW_CORNER_PREFERENCE = 33; // Win 11
  DWMWCP_DEFAULT    = 0;
  DWMWCP_DONOTROUND = 1;
  DWMWCP_ROUND      = 2;
  DWMWCP_ROUNDSMALL = 3;

  MONITOR_DEFAULTTONEAREST = 2;
  MONITORINFOF_PRIMARY = 1;


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

// Importujemy funkcję z Windows API
function GetMouseEntryIndex(Handle: HWND): Integer;
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';
function MonitorFromWindow(hwnd: HWND; dwFlags: DWORD): HMONITOR; stdcall; external 'user32.dll';
function GetMonitorInfoW(hMonitor: HMONITOR; lpmi: PMONITORINFO): BOOL; stdcall; external 'user32.dll';
// Importy dla efektów
//function DwmExtendFrameIntoClientArea(hwnd: HWND; const pMarInset: MARGINS): HRESULT; stdcall; external 'dwmapi.dll';
implementation
type
  TMenuCallbacks = record
    OnInitPopup: TAvocadoInitMenuEvent;
    OnSelect: TAvocadoMenuSelectEvent;
  end;

  TMenuEntry = record
    Handle: HWND;
    Callbacks: TMenuCallbacks;
  end;
type
  TFocusCallbacks = record
    OnSetFocus: TAvocadoFocusEvent;
    OnKillFocus: TAvocadoFocusEvent;
    // --- NOWE POLA ---
    OnActivateApp: TAvocadoActivateAppEvent;
    OnEnable: TAvocadoEnableEvent;
  end;

  TFocusEntry = record
    Handle: HWND;
    Callbacks: TFocusCallbacks;
  end;
type
  TKeyboardCallbacks = record
    OnKeyDown, OnKeyUp: TAvocadoKeyEvent;
    OnSysKeyDown, OnSysKeyUp: TAvocadoKeyEvent;
    OnChar, OnSysChar: TAvocadoCharEvent;
    OnDeadChar, OnUniChar: TAvocadoCharEvent;
  end;

  TKeyboardEntry = record
    Handle: HWND;
    Callbacks: TKeyboardCallbacks;
  end;

type
  // Rekord trzymający wszystkie callbacki myszy dla jednego okna
  TMouseCallbacks = record
    OnMove: TAvocadoMouseEvent;
    OnLDown, OnLUp, OnLDblClick: TAvocadoMouseEvent;
    OnRDown, OnRUp, OnRDblClick: TAvocadoMouseEvent;
    OnMDown, OnMUp, OnMDblClick: TAvocadoMouseEvent;
    OnWheel, OnHWheel: TAvocadoWheelEvent;

    OnHitTest: TAvocadoHitTestEvent; // <--- DODAJ TO POLE

    // Pola Non-Client
    OnNCMove: TAvocadoNCMouseEvent;
    OnNCLDown: TAvocadoNCMouseEvent;
    OnNCLUp: TAvocadoNCMouseEvent;
    OnNCLDblClick: TAvocadoNCMouseEvent;
    OnNCRDown: TAvocadoNCMouseEvent;
    OnNCRUp: TAvocadoNCMouseEvent;
  end;
  TMouseEntry = record
      Handle: HWND;
      Callbacks: TMouseCallbacks;
    end;
//type
//// Struktura dla cienia
//  MARGINS = record
//    cxLeftWidth: Integer;
//    cxRightWidth: Integer;
//    cyTopHeight: Integer;
//    cyBottomHeight: Integer;
  //end;
 type
  // Struktury dla Blur/Acrylic
  TAccentPolicy = packed record
    AccentState: Integer;
    AccentFlags: Integer;
    GradientColor: Integer; // Format AABBGGRR
    AnimationId: Integer;
  end;

  TWindowCompositionAttributeData = packed record
    Attribute: Integer;
    Data: Pointer;
    SizeOfData: Integer;
  end;

type
TEventEntry = record
  Handle: HWND;
  Callback: TAvocadoEvent;
end;

type
TResizeEntry = record
  Handle: HWND;
  Callback: TAvocadoEvent;
end;

type
  TKeyEntry = record
    Handle: HWND;
    Callback: TAvocadoKeyEvent;
  end;

type
TMoveEntry = record
  Handle: HWND;
  Callback: TAvocadoEvent;
end;

type
TCloseEntry = record
  Handle: HWND;
  Callback: TAvocadoCloseEvent;
end;

type
  TSizingEntry = record
    Handle: HWND;
    Callback: TAvocadoSizingEvent;
  end;

type
  TMovingEntry = record
    Handle: HWND;
    Callback: TAvocadoMovingEvent;
  end;

type
  TPosChangingEntry = record
    Handle: HWND;
    Callback: TAvocadoWindowPosEvent;
end;


  // Rekord przechowujący dane o zakotwiczonej kontrolce
TAnchorData = record
  Control: HWND;
  Parent: HWND;
  Anchors: TAvocadoAnchors;
  // Zapamiętujemy początkowe marginesy od krawędzi rodzica
  MarginLeft, MarginTop, MarginRight, MarginBottom: Integer;
  // Zapamiętujemy początkowe wymiary (potrzebne, gdy kotwice nie zmieniają rozmiaru)
  InitialWidth, InitialHeight: Integer;
end;


  //TAccentPolicy = packed record
  //  AccentState, AccentFlags, GradientColor, AnimationId: Integer;
  //end;

  {TWindowCompositionAttributeData = packed record
    Attribute: Integer;
    Data: Pointer;
    SizeOfData: Integer;
  end;
  }

var
  EventRegistry: array of TEventEntry;
  // Osobna tablica dla zdarzeń zmiany rozmiaru
  ResizeRegistry: array of TResizeEntry;
  // Osobne rejestry dla wciśnięcia i puszczenia klawisza
  KeyDownRegistry: array of TKeyEntry;
  KeyUpRegistry: array of TKeyEntry;
  CloseQueryRegistry: array of TCloseEntry;
  // Tablica do przechowywania zdarzeń ruchu
  MoveRegistry: array of TMoveEntry;
  SizingRegistry: array of TSizingEntry;
  MovingRegistry: array of TMovingEntry;
  PosChangingRegistry: array of TPosChangingEntry;
  // Globalna tablica przechowująca dane wszystkich zakotwiczonych kontrolek
  AnchoredControls: array of TAnchorData;
  // Jeden rejestr do wszystkiego co związane z myszą
  MouseRegistry: array of TMouseEntry;
  // Globalny rejestr klawiatury
  KeyboardRegistry: array of TKeyboardEntry;
  FocusRegistry: array of TFocusEntry;
  MenuRegistry: array of TMenuEntry;

  PaintRegistry: array of record
    Handle: HWND;
    OnPaint: TAvocadoPaintEvent;
  end;


//uses
 // SysUtils;
function DwmExtendFrameIntoClientArea(hwnd: HWND; const pMarInset: MARGINS): HRESULT; stdcall; external 'dwmapi.dll';

function AvocadoButtonProc(Window: HWND; Message: UINT; WParam: WPARAM;
  LParam: LPARAM): LRESULT; stdcall;
var
PS: TPaintStruct;
DC: HDC;
Rect: TRect;
Brush: HBRUSH;
CurrentColor, TextColor: DWORD;
IsHover, IsDown: Boolean;
TME: TTrackMouseEvent;
BtnText: array[0..255] of WideChar;

Pt: TPoint;
CursorPt: TPoint;
begin
 IsHover := GetProp(Window, 'IsHover') = 1;
  IsDown  := GetProp(Window, 'IsDown') = 1;

  case Message of
    WM_PAINT:
    begin
      DC := BeginPaint(Window, PS);
      GetClientRect(Window, Rect);

      // --- RYSOWANIE TŁA ---
      if IsDown then CurrentColor := DWORD(GetProp(Window, 'ColPressed'))
      else if IsHover then CurrentColor := DWORD(GetProp(Window, 'ColHover'))
      else CurrentColor := DWORD(GetProp(Window, 'ColNormal'));

      if CurrentColor = 0 then
      begin
         if IsDown then CurrentColor := $999999
         else if IsHover then CurrentColor := $BBBBBB
         else CurrentColor := $DDDDDD;
      end;

      Brush := CreateSolidBrush(CurrentColor);
      FillRect(DC, Rect, Brush);
      DeleteObject(Brush);

      // --- RYSOWANIE TEKSTU ---
      TextColor := DWORD(GetProp(Window, 'ColText'));
      SetBkMode(DC, TRANSPARENT);
      SetTextColor(DC, TextColor);
      SelectObject(DC, GetStockObject(DEFAULT_GUI_FONT));

      // Czyścimy bufor i pobieramy tekst
      FillChar(BtnText, SizeOf(BtnText), 0);
      if GetWindowTextW(Window, BtnText, 255) > 0 then
      begin
        DrawTextW(DC, BtnText, -1, Rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;

      EndPaint(Window, PS);
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      Result := 1;
      Exit;
    end;

    WM_MOUSEMOVE:
    begin
      if not IsHover then
      begin
        SetProp(Window, 'IsHover', 1);
        TME.cbSize := SizeOf(TME);
        TME.dwFlags := TME_LEAVE;
        TME.hwndTrack := Window;
        TrackMouseEvent(TME);
        InvalidateRect(Window, nil, True);
      end;
    end;

    WM_MOUSELEAVE:
    begin
      SetProp(Window, 'IsHover', 0);
      InvalidateRect(Window, nil, True);
    end;

    WM_LBUTTONDOWN:
    begin
      SetProp(Window, 'IsDown', 1);
      InvalidateRect(Window, nil, True);
      SetCapture(Window);
    end;

    WM_LBUTTONUP:
    begin
      if IsDown then
      begin
        SetProp(Window, 'IsDown', 0);
        ReleaseCapture();
        InvalidateRect(Window, nil, True);

        GetClientRect(Window, Rect);
        GetCursorPos(CursorPt);
        ScreenToClient(Window, CursorPt);

        if PtInRect(Rect, CursorPt) then
        begin
          // Wysyłamy sygnał kliknięcia
          SendMessage(GetParent(Window), WM_COMMAND,
             Word(GetDlgCtrlID(Window)) or (BN_CLICKED shl 16),
             Windows.LPARAM(Window));
        end;
      end;
    end;

    WM_DESTROY:
    begin
       RemoveProp(Window, 'IsHover');
       RemoveProp(Window, 'IsDown');
       RemoveProp(Window, 'ColNormal');
       RemoveProp(Window, 'ColHover');
       RemoveProp(Window, 'ColPressed');
       RemoveProp(Window, 'ColText');
    end;

  end;

  // <--- KLUCZOWA ZMIANA TUTAJ:
  // Używamy DefWindowProcW (Unicode), a nie DefWindowProc (Ansi)
  Result := DefWindowProcW(Window, Message, WParam, LParam);

end;

procedure SetButtonColors(Handle: HWND; ColNormal, ColHover, ColPressed,
  ColText: DWORD);
begin
  if Handle = 0 then Exit;
  SetProp(Handle, 'ColNormal', THandle(ColNormal));
  SetProp(Handle, 'ColHover', THandle(ColHover));
  SetProp(Handle, 'ColPressed', THandle(ColPressed));
  SetProp(Handle, 'ColText', THandle(ColText));
  InvalidateRect(Handle, nil, True); // Odśwież
end;

function MakeWParam(Low, High: Word): WPARAM;
begin
  Result := (Low and $FFFF) or (DWORD(High) shl 16);
end;

procedure SelectText(Handle: HWND; StartPos, EndPos: Integer);
begin
  if Handle <> 0 then
    // EM_SETSEL: WParam = Start, LParam = End
    SendMessage(Handle, EM_SETSEL, WPARAM(StartPos), LPARAM(EndPos));
end;

procedure SelectAllText(Handle: HWND);
begin
  if Handle <> 0 then
    // W Windows API ustawienie (0, -1) oznacza "Zaznacz wszystko"
    SendMessage(Handle, EM_SETSEL, 0, -1);
end;

function GetSelection(Handle: HWND): TTextSelection;
var
  S, E: DWORD; // Windows używa DWORD (liczb bez znaku)
begin
  Result.StartPos := 0;
  Result.EndPos := 0;

  if Handle <> 0 then
  begin
    // EM_GETSEL: Przekazujemy ADRESY zmiennych, do których system wpisze wartości
    SendMessage(Handle, EM_GETSEL, WPARAM(@S), LPARAM(@E));
    Result.StartPos := Integer(S);
    Result.EndPos := Integer(E);
  end;
end;

procedure SetCursorPosition(Handle: HWND; Position: Integer);
begin
  if Handle <> 0 then
    begin
      // 1. Ustawienie zaznaczenia o długości 0 w wybranym miejscu
      // (Start = Position, End = Position) -> To przesuwa kursor.
      SendMessage(Handle, EM_SETSEL, WPARAM(Position), LPARAM(Position));

      // 2. WAŻNE: Przewiń widok tak, aby kursor był widoczny
      // Bez tego kursor się przesunie, ale użytkownik tego nie zobaczy,
      // jeśli tekst wychodzi poza ramkę.
      SendMessage(Handle, EM_SCROLLCARET, 0, 0);
    end;
end;

procedure MoveCursorToEnd(Handle: HWND);
var
  Len: Integer;
begin
  if Handle <> 0 then
    begin
      // Pobieramy długość tekstu (korzystamy z funkcji, którą już masz lub systemowej)
      Len := Windows.GetWindowTextLengthW(Handle);

      // Ustawiamy kursor na pozycji równej długości tekstu (czyli za ostatnim znakiem)
      SetCursorPosition(Handle, Len);
    end;
end;

procedure ReplaceSelection(Handle: HWND; const NewText: string; CanUndo: Boolean);
begin
  if Handle <> 0 then
    begin
      // EM_REPLACESEL:
      // WParam = 1 (True) jeśli chcemy, by można było to cofnąć (Undo)
      // LParam = Wskaźnik na nowy tekst (Unicode)
      SendMessageW(Handle, EM_REPLACESEL, WPARAM(CanUndo), LPARAM(PWideChar(UnicodeString(NewText))));
    end;
end;

function GetLineCount(Handle: HWND): Integer;
begin
  Result := 0;
  if Handle <> 0 then
    Result := SendMessage(Handle, EM_GETLINECOUNT, 0, 0);
end;

function GetLineFromChar(Handle: HWND; CharIndex: Integer): Integer;
begin
 Result := 0;
  if Handle <> 0 then
    // WParam = Indeks znaku (lub -1 dla obecnej pozycji kursora)
    Result := SendMessage(Handle, EM_LINEFROMCHAR, WPARAM(CharIndex), 0);
end;

function GetCurrentLineNumber(Handle: HWND): Integer;
begin
  // Wrapper dla wygody: -1 oznacza "gdzie jest kursor"
  Result := GetLineFromChar(Handle, -1);
end;

function GetLineIndex(Handle: HWND; LineIndex: Integer): Integer;
begin
  Result := 0;
  if Handle <> 0 then
    // Zwraca indeks pierwszego znaku w danej linii
    Result := SendMessage(Handle, EM_LINEINDEX, WPARAM(LineIndex), 0);
end;

procedure ProcessMessages;
var
  Msg: TMsg;
begin
  // Sprawdzamy, czy są jakieś komunikaty w kolejce systemowej
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      // Jeśli to komunikat zamknięcia, wstawiamy go z powrotem i wychodzimy
      if Msg.message = WM_QUIT then
      begin
        PostQuitMessage(Msg.wParam);
        Break;
      end;

      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
end;

function GetLineLength(Handle: HWND; CharIndex: Integer): Integer;
begin
  Result := 0;
  if Handle <> 0 then
    // Pobiera długość linii na podstawie indeksu znaku w niej zawartego
    Result := SendMessage(Handle, EM_LINELENGTH, WPARAM(CharIndex), 0);
end;

function GetLineText(Handle: HWND; LineIndex: Integer): string;
var
  Len, CharIndex: Integer;
  Buffer: WideString;
  WordPtr: PWord;
begin
Result := '';
  if Handle = 0 then Exit;

  // 1. Musimy najpierw wiedzieć, jak długa jest ta linia, żeby przygotować pamięć
  // Najpierw pobieramy indeks pierwszego znaku tej linii
  CharIndex := SendMessage(Handle, EM_LINEINDEX, WPARAM(LineIndex), 0);

  // Jeśli linia nie istnieje (błąd), wynik to -1
  if CharIndex = -1 then Exit;

  // Teraz pytamy o długość linii, podając indeks znaku
  Len := SendMessage(Handle, EM_LINELENGTH, WPARAM(CharIndex), 0);

  if Len > 0 then
  begin
    // 2. Rezerwujemy pamięć (Len + 1 na znak null)
    SetLength(Buffer, Len + 1);

    // 3. MAGIA WINDOWS API:
    // Pierwsze słowo (Word, 2 bajty) bufora musi zawierać jego rozmiar.
    // Inaczej EM_GETLINE nie wie ile może wpisać i może nadpisać pamięć.
    WordPtr := PWord(PWideChar(Buffer));
    WordPtr^ := Word(Len + 1);

    // 4. Pobieramy tekst
    SendMessageW(Handle, EM_GETLINE, WPARAM(LineIndex), LPARAM(PWideChar(Buffer)));

    // 5. Obcinamy string do faktycznej długości i konwertujemy na UTF-8
    SetLength(Buffer, Len);
    Result := UTF8Encode(Buffer);
  end;
end;

//"sercem" Twojego okna – tutaj decydujesz, jak okno ma reagować na sygnały z systemu (kliknięcia, klawiaturę, zamykanie).
function AvocadoWindowProc(Window: HWND; Message: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
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

begin
  case Message of
    // --- KOLORY KONTROLEK ---
    WM_CTLCOLOREDIT, WM_CTLCOLORSTATIC, WM_CTLCOLORBTN:
    begin
      Brush := HBRUSH(GetProp(HWND(LParam), 'AvocadoBrush'));
      if Brush <> 0 then
      begin
        SetTextColor(WParam, COLORREF(GetProp(HWND(LParam), 'AvocadoTextColor')));
        SetBkColor(WParam, COLORREF(GetProp(HWND(LParam), 'AvocadoBgColor')));
        Result := LRESULT(Brush);
        Exit;
      end
      else
      begin
        SetTextColor(WParam, $FFFFFF);
        SetBkColor(WParam, $121212);
        Result := LRESULT(GetClassLongPtr(Window, GCLP_HBRBACKGROUND));
        Exit;
      end;
    end;

     // --- OBSŁUGA POLECEŃ SYSTEMOWYCH (Min, Max, Close, Screensaver) ---
    WM_SYSCOMMAND:
    begin
      // 1. Sprawdzamy, co to za komenda (maskujemy dolne 4 bity, bo system używa ich wewnętrznie)
      SysCmd := WParam and $FFF0;

      // Tutaj mógłbyś wywołać zdarzenie użytkownika: OnSysCommand(Window, SysCmd, ...)

      // PRZYKŁAD: Blokada wygaszacza ekranu
      if (SysCmd = SC_SCREENSAVE) or (SysCmd = SC_MONITORPOWER) then
      begin
        // Jeśli zwrócisz 0, wygaszacz się nie włączy
        // Result := 0; Exit;
      end;

      // WAŻNE: Musisz przekazać to do DefWindowProc, inaczej nie zadziała
      // przesuwanie okna, minimalizacja ani przycisk X!
      Result := DefWindowProcW(Window, Message, WParam, LParam);
      Exit;
    end;


    // --- PĘTLA MENU (Wejście / Wyjście) ---
    // --- OBSŁUGA MENU (Init & Select) ---
    WM_INITMENUPOPUP, WM_MENUSELECT:
    begin
      Idx := -1;
      for i := 0 to High(MenuRegistry) do
        if MenuRegistry[i].Handle = Window then begin Idx := i; Break; end;

      if Idx <> -1 then
      begin
        if Message = WM_INITMENUPOPUP then
        begin
           // WParam = HMENU, LoWord(LParam) = Index (ignorujemy), HiWord(LParam) = IsWindowMenu
           if Assigned(MenuRegistry[Idx].Callbacks.OnInitPopup) then
             MenuRegistry[Idx].Callbacks.OnInitPopup(Window, HMENU(WParam), Boolean(HiWord(LParam)));
        end
        else // WM_MENUSELECT
        begin
           // LoWord(WParam) = ItemID, HiWord(WParam) = Flags, LParam = HMENU
           if Assigned(MenuRegistry[Idx].Callbacks.OnSelect) then
             MenuRegistry[Idx].Callbacks.OnSelect(Window, WParam and $FFFF, (WParam shr 16) and $FFFF, HMENU(LParam));
        end;
      end;

      // WM_MENUSELECT wymaga zwrócenia 0 jeśli przetworzono, ale DefWindowProc też jest OK.
      if Message = WM_INITMENUPOPUP then
      begin
        Result := 0; Exit; // InitPopup nie powinien iść do DefWindowProc jeśli chcemy go kontrolować
      end;

      Result := DefWindowProcW(Window, Message, WParam, LParam);
    end;


    // --- KLIKNIĘCIA (COMMAND) ---
    WM_COMMAND:
    begin
      // Przypadek 1: To jest KONTROLKA (np. Przycisk)
      // Rozpoznajemy po tym, że LParam (Uchwyt) jest różny od zera.
      if LParam <> 0 then
      begin
        // Tutaj Twoja obecna logika szukania zdarzenia po uchwycie
        EventToRun := FindEvent(HWND(LParam));
        if Assigned(EventToRun) then
        begin
           // Opcjonalnie: Możesz tu sprawdzać HiWord(WParam),
           // żeby reagować tylko na kliknięcie (BN_CLICKED = 0),
           // a nie np. na podwójne kliknięcie czy zmianę fokusa.
           if HiWord(WParam) = BN_CLICKED then
             EventToRun(HWND(LParam));
        end;
      end

      // Przypadek 2: To jest MENU lub SKRÓT
      // LParam wynosi 0. Musimy sprawdzić ID polecenia (LowWord(WParam)).
      else
      begin

        CmdID := LoWord(WParam);

        // Tutaj przydałby się mechanizm:
        // "Znajdź funkcję przypisaną do tego ID Menu".
        // Na razie zrobimy prosty przykład przekazania do Okna Głównego:

        Idx := -1;
        // Szukamy indeksu okna w rejestrze (np. FocusRegistry lub innym)
        // Zakładam, że masz jakąś funkcję do pobrania eventów okna,
        // np. OnMenuCommand(Window, CmdID);

        // PRZYKŁAD IMPLEMENTACJI "NA SZYBKO":
        // Możesz wysłać to jako specjalne zdarzenie użytkownika
        // albo po prostu obsłużyć konkretne ID tutaj, jeśli to prosta biblioteka.
      end;

      Result := 0;
      Exit;
    end;

    // --- HIT TEST (Gdzie jest myszka?) ---
    WM_NCHITTEST:
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



    // --- W TRAKCIE ZMIANY ROZMIARU (WM_SIZING) ---
    WM_SIZING:
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

    // --- PO ZMIANIE ROZMIARU (WM_SIZE) ---
    WM_SIZE:
    begin
      if WParam <> SIZE_MINIMIZED then
      begin
        // 1. Wywołaj system Anchors
        UpdateLayout(Window);
        ResizeToRun := FindResizeEvent(Window);
        if Assigned(ResizeToRun) then
          ResizeToRun(Window);
      end;
      // Brak Exit = system też musi przeliczyć
    end;

    // --- LIMITY ROZMIARU (MIN/MAX) ---
    WM_GETMINMAXINFO:
    begin
      MMI := PMinMaxInfo(LParam);
      MinW := Integer(GetProp(Window, 'AvocadoMinW'));
      MinH := Integer(GetProp(Window, 'AvocadoMinH'));

      if MinW > 0 then MMI^.ptMinTrackSize.x := MinW;
      if MinH > 0 then MMI^.ptMinTrackSize.y := MinH;

      Result := 0;
      Exit;
    end;

    WM_SETFOCUS, WM_KILLFOCUS:
    begin
      Idx := -1;
      for i := 0 to High(FocusRegistry) do
        if FocusRegistry[i].Handle = Window then
        begin
          Idx := i;
          Break;
        end;

      if Idx <> -1 then
      begin
        if Message = WM_SETFOCUS then
        begin
          if Assigned(FocusRegistry[Idx].Callbacks.OnSetFocus) then
            FocusRegistry[Idx].Callbacks.OnSetFocus(Window);
        end
        else // WM_KILLFOCUS
        begin
          if Assigned(FocusRegistry[Idx].Callbacks.OnKillFocus) then
            FocusRegistry[Idx].Callbacks.OnKillFocus(Window);
        end;
      end;

      // Bardzo ważne dla kontrolek systemowych (np. Memo)

      OldProcPtr := GetProp(Window, 'OldWndProc');
      if OldProcPtr <> 0 then
        Result := CallWindowProc(WNDPROC(OldProcPtr), Window, Message, WParam, LPARAM)
      else
        Result := DefWindowProcW(Window, Message, WParam, LParam);
    end;

    // --- OBSŁUGA KLAWIATURY ---
    WM_KEYDOWN, WM_KEYUP,
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

    // --- PRZESUWANIE ---
    WM_MOVE:
    begin
      MoveFunc := FindMoveEvent(Window);
      if Assigned(MoveFunc) then
        MoveFunc(Window);
      // Brak Exit
    end;



    // --- ZAMYKANIE (QUERY) ---
    WM_CLOSE:
    begin
      CanClose := True;
      CloseQueryFunc := FindCloseEvent(Window);

      if Assigned(CloseQueryFunc) then
        CanClose := CloseQueryFunc(Window);

      if CanClose then
        DestroyWindow(Window)
      else
      begin
        Result := 0;
        Exit;
      end;

      Result := 0;
      Exit;
    end;

    // --- STRAŻNIK POZYCJI (WM_WINDOWPOSCHANGING) ---
    WM_WINDOWPOSCHANGING:
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
                  MonInfo := GetWindowMonitorInfo(Window);

                  // Obliczamy wymiary
                  WinW := PWinPos^.cx;
                  if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
                    WinW := GetWidth(Window);

                  WinH := PWinPos^.cy;
                  if (PWinPos^.flags and SWP_NOSIZE) <> 0 then
                    WinH := GetHeight(Window);

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

    // --- ZMIANA POZYCJI ZAKOŃCZONA (WM_WINDOWPOSCHANGED) --- [NOWE]
    // Ten komunikat przychodzi PO TYM jak okno zmieniło pozycję/rozmiar
    WM_WINDOWPOSCHANGED:
    begin
      PWinPos := PWINDOWPOS(LParam); // Używamy tej samej zmiennej co wyżej

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
      // --- BLOKADA STANDARDOWEGO MENU ---
    WM_CONTEXTMENU:
    begin
    // 1. Sprawdzamy, czy dla tego okna zdefiniowano obsługę prawego przycisku
          Idx := -1;
          for i := 0 to High(MouseRegistry) do
            if MouseRegistry[i].Handle = Window then
            begin
              Idx := i;
              Break;
            end;

          // 2. Jeśli mamy własną funkcję "OnRDown", to NIE CHCEMY menu systemowego
          if (Idx <> -1) and Assigned(MouseRegistry[Idx].Callbacks.OnRDown) then
          begin
            Result := 0;
            Exit; // <--- To jest klucz! Tutaj ucinamy sprawę.
          end;

          // Jeśli nie mamy własnej funkcji, kod pójdzie dalej do 'else'
          // i Memo wyświetli swoje standardowe menu.
    end;

    // --- OBSŁUGA MYSZY ---

    WM_MOUSEMOVE,
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK,
    WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK,
    WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK,
    WM_MOUSEWHEEL, WM_MOUSEHWHEEL:

    begin
      Idx := -1;
      // Szukanie w rejestrze myszy
      for i := 0 to High(MouseRegistry) do
        if MouseRegistry[i].Handle = Window then
        begin
          Idx := i;
          Break;
        end;

      if Idx <> -1 then
      begin
        CB := @MouseRegistry[Idx].Callbacks;
        MouseX := SmallInt(LParam and $FFFF);
        MouseY := SmallInt((LParam shr 16) and $FFFF);

        case Message of
          WM_MOUSEMOVE:     if Assigned(CB^.OnMove) then CB^.OnMove(Window, MouseX, MouseY);

          // --- LEWY PRZYCISK (Z Draggingiem) ---
          WM_LBUTTONDOWN:
          begin
             // 1. Zdarzenie użytkownika
             if Assigned(CB^.OnLDown) then CB^.OnLDown(Window, MouseX, MouseY);

             // 2. Logika Dragging (Przesuwanie za tło)
             CanDrag := PBoolean(GetWindowLongPtr(Window, GWL_USERDATA));
             if (CanDrag <> nil) and (CanDrag^ = True) then
             begin
               ReleaseCapture();
               SendMessage(Window, WM_NCLBUTTONDOWN, HTCAPTION, 0);
               Result := 0;
               Exit;
             end;
          end;

          WM_LBUTTONUP:     if Assigned(CB^.OnLUp) then CB^.OnLUp(Window, MouseX, MouseY);
          WM_LBUTTONDBLCLK: if Assigned(CB^.OnLDblClick) then CB^.OnLDblClick(Window, MouseX, MouseY);

          // --- PRAWY PRZYCISK (POPRAWKA DLA MENU) ---
          WM_RBUTTONDOWN:
          begin
            if Assigned(CB^.OnRDown) then
            begin
              CB^.OnRDown(Window, MouseX, MouseY);
              // WAŻNE: Blokujemy dalsze przetwarzanie, żeby nie wyskoczyło menu systemowe!
              Result := 0;
              Exit;
            end;
          end;

          WM_RBUTTONUP:
          begin
            if Assigned(CB^.OnRUp) then
            begin
              CB^.OnRUp(Window, MouseX, MouseY);
              Result := 0;
              Exit;
            end;
          end;

          WM_RBUTTONDBLCLK: if Assigned(CB^.OnRDblClick) then CB^.OnRDblClick(Window, MouseX, MouseY);

          // --- ŚRODKOWY PRZYCISK ---
          WM_MBUTTONDOWN:   if Assigned(CB^.OnMDown) then CB^.OnMDown(Window, MouseX, MouseY);
          WM_MBUTTONUP:     if Assigned(CB^.OnMUp) then CB^.OnMUp(Window, MouseX, MouseY);
          WM_MBUTTONDBLCLK: if Assigned(CB^.OnMDblClick) then CB^.OnMDblClick(Window, MouseX, MouseY);

          // --- KÓŁKO MYSZY ---
          WM_MOUSEWHEEL:
          begin
            WheelDelta := SmallInt(HiWord(WParam));
            Pt.x := MouseX; Pt.y := MouseY;
            ScreenToClient(Window, Pt);
            if Assigned(CB^.OnWheel) then CB^.OnWheel(Window, WheelDelta, Pt.x, Pt.y);
          end;

          WM_MOUSEHWHEEL:
          begin
            WheelDelta := SmallInt(HiWord(WParam));
            Pt.x := MouseX; Pt.y := MouseY;
            ScreenToClient(Window, Pt);
            if Assigned(CB^.OnHWheel) then CB^.OnHWheel(Window, WheelDelta, Pt.x, Pt.y);
          end;
        end;
      end
      else
      begin
        // Fallback dla Draggingu (gdy brak zdarzeń myszy)
        if Message = WM_LBUTTONDOWN then
        begin
           CanDrag := PBoolean(GetWindowLongPtr(Window, GWL_USERDATA));
           if (CanDrag <> nil) and (CanDrag^ = True) then
           begin
             ReleaseCapture();
             SendMessage(Window, WM_NCLBUTTONDOWN, HTCAPTION, 0);
             Result := 0;
             Exit;
           end;
        end;
      end;
    end;



    // --- OBSŁUGA MYSZY NON-CLIENT (RAMKA, TYTUŁ) ---
    WM_NCMOUSEMOVE,
    WM_NCLBUTTONDOWN, WM_NCLBUTTONUP, WM_NCLBUTTONDBLCLK,
    WM_NCRBUTTONDOWN, WM_NCRBUTTONUP:
    begin
      // 1. Obsługa zdarzeń użytkownika (Avocado UI)
      Idx := -1;
      for i := 0 to High(MouseRegistry) do
        if MouseRegistry[i].Handle = Window then
        begin
          Idx := i;
          Break;
        end;

      if Idx <> -1 then
      begin
        CB := @MouseRegistry[Idx].Callbacks;
        MouseX := SmallInt(LParam and $FFFF);
        MouseY := SmallInt((LParam shr 16) and $FFFF);

        case Message of
          WM_NCMOUSEMOVE:     if Assigned(CB^.OnNCMove) then CB^.OnNCMove(Window, Integer(WParam), MouseX, MouseY);

          WM_NCLBUTTONDOWN:   if Assigned(CB^.OnNCLDown) then CB^.OnNCLDown(Window, Integer(WParam), MouseX, MouseY);
          WM_NCLBUTTONUP:     if Assigned(CB^.OnNCLUp) then CB^.OnNCLUp(Window, Integer(WParam), MouseX, MouseY);
          WM_NCLBUTTONDBLCLK: if Assigned(CB^.OnNCLDblClick) then CB^.OnNCLDblClick(Window, Integer(WParam), MouseX, MouseY);

          WM_NCRBUTTONDOWN:   if Assigned(CB^.OnNCRDown) then CB^.OnNCRDown(Window, Integer(WParam), MouseX, MouseY);
          WM_NCRBUTTONUP:     if Assigned(CB^.OnNCRUp) then CB^.OnNCRUp(Window, Integer(WParam), MouseX, MouseY);
        end;
      end;

      // 2. NAPRAWA: Przekazujemy sterowanie do systemu!
      // Bez tego przyciski X, Min, Max oraz przesuwanie okna nie działają,
      // ponieważ 'case' pomija sekcję 'else'.
      Result := DefWindowProcW(Window, Message, WParam, LParam);
    end;
    // --- STAN APLIKACJI (Active / Enable) ---
   WM_ACTIVATEAPP, WM_ENABLE:
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

    // --- NISZCZENIE (DESTROY) ---
    WM_DESTROY:
    begin
      CanDrag := PBoolean(GetWindowLongPtr(Window, GWL_USERDATA));
      if CanDrag <> nil then Dispose(CanDrag);

      RemoveProp(Window, 'IsHover');
      RemoveProp(Window, 'IsDown');
      RemoveProp(Window, 'ColNormal');
      RemoveProp(Window, 'ColHover');
      RemoveProp(Window, 'ColPressed');
      RemoveProp(Window, 'ColText');
      // Dodaj też czyszczenie MinW/MinH jeśli chcesz być perfekcyjny
      RemoveProp(Window, 'AvocadoMinW');
      RemoveProp(Window, 'AvocadoMinH');
      // Sticky props
      RemoveProp(Window, 'AvocadoSticky');
      RemoveProp(Window, 'SnapDist');

      PostQuitMessage(0);
      Result := 0;
      Exit;
    end;



    // --- W TRAKCIE PRZESUWANIA (WM_MOVING) ---
    WM_MOVING:
    begin
      MovingFunc := FindMovingEvent(Window);
      if Assigned(MovingFunc) then
      begin
        PR := PRect(LParam); // Odczytujemy sugerowaną pozycję

        // Wywołujemy funkcję użytkownika, która może zmienić PR^
        MovingFunc(Window, PR^);

        Result := 1; // Zwracamy TRUE (1) = przetworzono
        Exit;
      end;
      // Brak Exit = systemowa obsługa
    end;

    // --- MALOWANIE ---
    WM_PAINT:
    begin
      {
      if GetProp(Window, 'OldWndProc') <> 0 then
      begin
         // Memo samo się maluje

      end
      else
      begin
        DC := BeginPaint(Window, PS);
        GetClientRect(Window, Rect);

        // --- MALOWANIE WŁASNEGO PASKA (Góra) ---

        TitleBarRect := Rect;
        TitleBarRect.Bottom := 40; // Wysokość Twojego paska

        // Wybierz kolor paska (np. ciemny granat $400000)
        TitleBrush := CreateSolidBrush($400000);
        FillRect(DC, TitleBarRect, TitleBrush);
        DeleteObject(TitleBrush);

        // --- MALOWANIE RESZTY OKNA (Dół) ---

        ContentRect := Rect;
        ContentRect.Top := 40;

        Brush := HBRUSH(GetClassLongPtr(Window, GCLP_HBRBACKGROUND));
        FillRect(DC, ContentRect, Brush);

        EndPaint(Window, PS);
        Result := 0; Exit;
      end;
      }

      DC := BeginPaint(Window, PS);
      GetClientRect(Window, Rect);
      Brush := HBRUSH(GetClassLongPtr(Window, GCLP_HBRBACKGROUND));
      FillRect(DC, Rect, Brush);

      SetBkMode(DC, TRANSPARENT);

      // 2. SZUKAMY CZY UŻYTKOWNIK CHCE COŚ DORYSOWAĆ
      for i := 0 to High(PaintRegistry) do
        if PaintRegistry[i].Handle = Window then
        begin
          if Assigned(PaintRegistry[i].OnPaint) then
            PaintRegistry[i].OnPaint(Window, DC);
          Break;
        end;


      EndPaint(Window, PS);
      Result := 0;
      Exit;

    end;

    // --- DOMYŚLNA OBSŁUGA ---
    else
      Result := DefWindowProcW(Window, Message, WParam, LParam);
    end;
end;


procedure ShowWindowAvocado(var msg: TMsg);
begin
  while GetMessage(msg, 0, 0, 0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end;

procedure SetDarkMode(Handle: HWND; Enable: Boolean);
var
  DarkMode: Integer;
begin
  if Enable then DarkMode := 1 else DarkMode := 0;
  DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkMode, SizeOf(DarkMode));
end;

procedure SetOnPaint(Handle: HWND; Event: TAvocadoPaintEvent);
begin

end;

procedure CloseAvocadoWindow(Handle: HWND);
begin
  if Handle <> 0 then
    PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure ActivateWindow(Handle: HWND);
begin
  if (Handle <> 0) and IsWindow(Handle) then
    SetActiveWindow(Handle);
end;

function GetText(Handle: HWND): string;
var
  Len: Integer;
  Buffer: WideString;
begin
  Result := '';
  if Handle = 0 then Exit;

  // 1. Sprawdzamy długość tekstu
  Len := GetWindowTextLengthW(Handle);

  if Len > 0 then
  begin
    // 2. Rezerwujemy pamięć (+1 na znak null)
    SetLength(Buffer, Len + 1);

    // 3. Pobieramy tekst
    GetWindowTextW(Handle, PWideChar(Buffer), Len + 1);

    // 4. Obcinamy nadmiar
    SetLength(Buffer, Len);

    // 5. Konwertujemy WideString na UTF-8 String
    Result := UTF8Encode(Buffer);
  end;
end;

procedure SetText(Handle: HWND; const AText: string);
begin
  if Handle <> 0 then
    begin
      // Używamy AText zamiast Text, aby uniknąć konfliktu z typem pliku
      SetWindowTextW(Handle, PWideChar(WideString(AText)));
    end;
end;

function DefaultWindowParams: TAvocadoWindowParams;
begin
  FillChar(Result, SizeOf(Result), 0); // Czyścimy wszystko
  Result.Title := 'Avocado Window';
  Result.Width := 800;
  Result.Height := 600;
  Result.Visible := True;
  Result.BackgroundColor := $FFFFFF;

  // OTO TWOJA DOMYŚLNA WARTOŚĆ:
  Result.AllowMaximize := True;
  Result.AllowDrag := True;
end;

procedure SetOnHitTest(Handle: HWND; Event: TAvocadoHitTestEvent);
var
  Idx: Integer;
begin
 if Handle <> 0 then
  begin
    // Używamy tej samej funkcji co dla reszty myszy
    // Ona zadba o powiększenie tablicy MouseRegistry
    Idx := GetMouseEntryIndex(Handle);

    MouseRegistry[Idx].Callbacks.OnHitTest := Event;
  end;
end;

function IsWindowMinimized(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    // IsIconic to systemowa funkcja Windows API
    Result := Windows.IsIconic(Handle);
end;

procedure SetOnInitMenuPopup(Handle: HWND; Event: TAvocadoInitMenuEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then
    begin Idx := GetMenuEntryIndex(Handle);
      MenuRegistry[Idx].Callbacks.OnInitPopup := Event;
    end;
end;

procedure SetOnMenuSelect(Handle: HWND; Event: TAvocadoMenuSelectEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then
    begin Idx := GetMenuEntryIndex(Handle);
      MenuRegistry[Idx].Callbacks.OnSelect := Event;
    end;
end;

function IsWindowMaximized(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    // IsZoomed to systemowa funkcja Windows API
    Result := Windows.IsZoomed(Handle);
end;

function GetWindowTitle(Handle: HWND): string;
begin
    // Po prostu korzystamy z naszej uniwersalnej funkcji GetText
    Result := GetText(Handle);
end;

procedure SetOnMenuCommand(Handle: HWND; Event: TAvocadoCommandEvent);
begin

end;

procedure SetBlurBehind(Handle: HWND; Enable: Boolean);
type
    TSetWindowCompositionAttribute = function(h: HWND; data: Pointer): Integer; stdcall;
var
  User32: HMODULE;
  // 2. Zmienna jest tego typu
  SetWindowCompositionAttribute: TSetWindowCompositionAttribute;
  Accent: TAccentPolicy;
  Data: TWindowCompositionAttributeData;
begin
  if Handle = 0 then Exit;

  User32 := GetModuleHandle('user32.dll');
  if User32 <> 0 then
  begin
    // 3. POPRAWKA:
    // - Usuwamy "@" z lewej strony.
    // - Rzutujemy wynik GetProcAddress na nasz typ TSetWindowCompositionAttribute
    SetWindowCompositionAttribute := TSetWindowCompositionAttribute(GetProcAddress(User32, 'SetWindowCompositionAttribute'));

    if Assigned(SetWindowCompositionAttribute) then
    begin
      FillChar(Accent, SizeOf(Accent), 0);

      if Enable then
      begin
        Accent.AccentState := ACCENT_ENABLE_BLURBEHIND;
        // Opcjonalnie dla lepszego efektu na nowszych Windowsach:
        // Accent.AccentState := ACCENT_ENABLE_ACRYLICBLURBEHIND;
        // Accent.GradientColor := $01000000; // Lekka przezroczystość
      end
      else
      begin
        Accent.AccentState := ACCENT_DISABLED;
      end;

      Data.Attribute := WCA_ACCENT_POLICY;
      Data.Data := @Accent;
      Data.SizeOfData := SizeOf(Accent);

      SetWindowCompositionAttribute(Handle, @Data);
    end;
  end;
end;

procedure DestroyControl(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    Windows.DestroyWindow(Handle);
  end;
end;

procedure SetWindowRoundedCorners(Handle: HWND; Mode: Integer);
var
  Preference: Integer;
begin
    // Mode: 0=Default, 1=Square, 2=Round, 3=SmallRound
    if Handle = 0 then Exit;
    Preference := Mode;
    DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @Preference, SizeOf(Preference));
end;

procedure SetWindowShadow(Handle: HWND; Enable: Boolean);
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

procedure SetTitle(Handle: HWND; const NewTitle: string);
begin
  if Handle <> 0 then
    begin
    // Konwertujemy string na WideString (Unicode), a następnie na wskaźnik PWideChar
    SetWindowTextW(Handle, PWideChar(UnicodeString(NewTitle)));
    end;
end;

procedure SetOnSetFocus(Handle: HWND; Event: TAvocadoFocusEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then begin
    Idx := GetFocusEntryIndex(Handle);
    FocusRegistry[Idx].Callbacks.OnSetFocus := Event;
  end;
end;

procedure SetOnKillFocus(Handle: HWND; Event: TAvocadoFocusEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then begin
    Idx := GetFocusEntryIndex(Handle);
    FocusRegistry[Idx].Callbacks.OnKillFocus := Event;
  end;
end;

procedure CenterWindow(Handle: HWND);
var
  Rect: TRect;
  ScreenWidth, ScreenHeight: Integer;
  WindowWidth, WindowHeight: Integer;
  NewX, NewY: Integer;
begin
  if Handle <> 0 then
    begin
      // 1. Pobieramy wymiary pulpitu (Głównego monitora)
      ScreenWidth := GetSystemMetrics(SM_CXSCREEN);
      ScreenHeight := GetSystemMetrics(SM_CYSCREEN);

      // 2. Pobieramy wymiary naszego okna
      GetWindowRect(Handle, Rect);
      WindowWidth := Rect.Right - Rect.Left;
      WindowHeight := Rect.Bottom - Rect.Top;

      // 3. Obliczamy środek
      NewX := (ScreenWidth - WindowWidth) div 2;
      NewY := (ScreenHeight - WindowHeight) div 2;

      // 4. Ustawiamy nową pozycję (używamy SWP_NOSIZE, żeby nie zmieniać szerokości/wysokości)
      SetWindowPos(Handle, 0, NewX, NewY, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
    end;
end;

procedure SetPosition(Handle: HWND; X, Y: Integer);
begin
  if Handle <> 0 then
    // SWP_NOSIZE - nie zmieniaj rozmiaru
    // SWP_NOZORDER - nie zmieniaj kolejności okien (na wierzchu/pod spodem)
    SetWindowPos(Handle, 0, X, Y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
end;

procedure SetSize(Handle: HWND; Width, Height: Integer);
begin
 if Handle <> 0 then
    // SWP_NOMOVE - nie zmieniaj pozycji X, Y
    SetWindowPos(Handle, 0, 0, 0, Width, Height, SWP_NOMOVE or SWP_NOZORDER);
end;

procedure SetBounds(Handle: HWND; X, Y, Width, Height: Integer);
begin
  if Handle <> 0 then
    // Tutaj zmieniamy oba parametry, więc nie używamy flag blokujących
    SetWindowPos(Handle, 0, X, Y, Width, Height, SWP_NOZORDER);
end;

procedure SetOnSizing(Handle: HWND; OnSizingEvent: TAvocadoSizingEvent);
var
  i: Integer;
begin
  if Handle = 0 then Exit;

    for i := 0 to High(SizingRegistry) do
    begin
      if SizingRegistry[i].Handle = Handle then
      begin
        SizingRegistry[i].Callback := OnSizingEvent;
        Exit;
      end;
    end;

    SetLength(SizingRegistry, Length(SizingRegistry) + 1);
    SizingRegistry[High(SizingRegistry)].Handle := Handle;
    SizingRegistry[High(SizingRegistry)].Callback := OnSizingEvent;
end;

function FindSizingEvent(Handle: HWND): TAvocadoSizingEvent;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(SizingRegistry) do
  begin
    if SizingRegistry[i].Handle = Handle then
    begin
      Result := SizingRegistry[i].Callback;
      Exit;
    end;
  end;
end;

function FindMovingEvent(Handle: HWND): TAvocadoMovingEvent;
var
  i: Integer;
begin
Result := nil;
  for i := 0 to High(MovingRegistry) do
  begin
    if MovingRegistry[i].Handle = Handle then
    begin
      Result := MovingRegistry[i].Callback;
      Exit;
    end;
  end;
end;

function FindPosChangingEvent(Handle: HWND): TAvocadoWindowPosEvent;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(PosChangingRegistry) do
    if PosChangingRegistry[i].Handle = Handle then Exit(PosChangingRegistry[i].Callback);
end;

procedure SetOnMoving(Handle: HWND; OnMovingEvent: TAvocadoMovingEvent);
var
  i: Integer;
begin
  if Handle = 0 then Exit;

    for i := 0 to High(MovingRegistry) do
    begin
      if MovingRegistry[i].Handle = Handle then
      begin
        MovingRegistry[i].Callback := OnMovingEvent;
        Exit;
      end;
    end;

    SetLength(MovingRegistry, Length(MovingRegistry) + 1);
    MovingRegistry[High(MovingRegistry)].Handle := Handle;
    MovingRegistry[High(MovingRegistry)].Callback := OnMovingEvent;
end;

procedure SetOnWindowPosChanging(Handle: HWND;
  OnPosChangingEvent: TAvocadoWindowPosEvent);
var
  i: Integer;
begin
  if Handle = 0 then Exit;
    for i := 0 to High(PosChangingRegistry) do
    begin
      if PosChangingRegistry[i].Handle = Handle then
      begin
        PosChangingRegistry[i].Callback := OnPosChangingEvent;
        Exit;
      end;
    end;
    SetLength(PosChangingRegistry, Length(PosChangingRegistry) + 1);
    PosChangingRegistry[High(PosChangingRegistry)].Handle := Handle;
    PosChangingRegistry[High(PosChangingRegistry)].Callback := OnPosChangingEvent;
end;

procedure SetOpacity(Handle: HWND; Opacity: Byte);
var
  CurrentStyle: LongInt;
begin
  if Handle <> 0 then
    begin
      // 1. Pobieramy obecny styl rozszerzony okna
      CurrentStyle := GetWindowLong(Handle, GWL_EXSTYLE);

      // 2. Dodajemy styl WS_EX_LAYERED, jeśli jeszcze go nie ma
      if (CurrentStyle and WS_EX_LAYERED) = 0 then
        SetWindowLong(Handle, GWL_EXSTYLE, CurrentStyle or WS_EX_LAYERED);

      // 3. Ustawiamy przezroczystość
      // LWA_ALPHA ($2) informuje, że używamy parametru Opacity do sterowania kanałem Alpha
      SetLayeredWindowAttributes(Handle, 0, Opacity, LWA_ALPHA);
    end;
end;

procedure MaximizeWindow(Handle: HWND);
begin
  if Handle <> 0 then
      ShowWindow(Handle, SW_MAXIMIZE);
end;

procedure MinimizeWindow(Handle: HWND);
begin
  if Handle <> 0 then
      ShowWindow(Handle, SW_MINIMIZE);
end;

procedure RestoreWindow(Handle: HWND);
begin
  if Handle <> 0 then
    ShowWindow(Handle, SW_RESTORE);
end;

function GetWindowMonitorInfo(Handle: HWND): TAvocadoMonitorInfo;
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

procedure SetWindowSticky(Handle: HWND; Enable: Boolean; SnapDistance: Integer);
begin
  if Handle <> 0 then
    begin
      if Enable then
      begin
        SetProp(Handle, 'AvocadoSticky', 1);
        SetProp(Handle, 'SnapDist', THandle(SnapDistance));
      end
      else
      begin
        RemoveProp(Handle, 'AvocadoSticky');
        RemoveProp(Handle, 'SnapDist');
      end;
    end;
end;

procedure SetCaptionColor(Handle: HWND; Color: DWORD);
const
  DWMWA_CAPTION_COLOR = 35; // Flaga dla Windows 11 / nowszych Win 10
begin
  DwmSetWindowAttribute(Handle, DWMWA_CAPTION_COLOR, @Color, SizeOf(Color));
end;

procedure SetCaptionTextColor(Handle: HWND; Color: DWORD);
const
  DWMWA_TEXT_COLOR = 36;
begin
  DwmSetWindowAttribute(Handle, DWMWA_TEXT_COLOR, @Color, SizeOf(Color));
end;

procedure DrawTextCenter(Handle: HWND; const AText: string; Color: DWORD);
var
  DC: HDC;
  Rect: TRect;
  OldColor: COLORREF;
begin
    if Handle = 0 then Exit;

    DC := GetDC(Handle);
    try
      GetClientRect(Handle, Rect);

      // Ustawienia tekstu
      SetBkMode(DC, TRANSPARENT);
      OldColor := SetTextColor(DC, Color);

      // Wybór czcionki systemowej (opcjonalnie)
      SelectObject(DC, GetStockObject(DEFAULT_GUI_FONT));

      // Rysowanie tekstu na środku
      // DT_CENTER | DT_VCENTER | DT_SINGLELINE centruje tekst w pionie i poziomie
      DrawTextW(DC, PWideChar(UnicodeString(AText)), -1, Rect,
                DT_CENTER or DT_VCENTER or DT_SINGLELINE);

      SetTextColor(DC, OldColor);
    finally
      ReleaseDC(Handle, DC);
    end;
end;

procedure SetWindowEnabled(Handle: HWND; Enable: Boolean);
begin
if Handle <> 0 then
    // Windows.EnableWindow zwraca poprzedni stan, ale my go ignorujemy
Windows.EnableWindow(Handle, Enable);
end;

function GetX(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Left;
end;

function GetY(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Top;
end;

function GetWidth(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
      Result := Rect.Right - Rect.Left;
end;

function GetHeight(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
  if (Handle <> 0) and GetWindowRect(Handle, Rect) then
    Result := Rect.Bottom - Rect.Top;
end;

function GetClientArea(Handle: HWND): TRect;
var
  Rect: TRect;
begin
  FillChar(Rect, SizeOf(Rect), 0);
    if Handle <> 0 then
      Windows.GetClientRect(Handle, Rect);
    Result := Rect;
end;

function IsWindowOnTop(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    // GetForegroundWindow zwraca uchwyt okna, z którym użytkownik obecnie pracuje
    Result := (GetForegroundWindow() = Handle);
end;

procedure SetAlwaysOnTop(Handle: HWND; Enable: Boolean);
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

      // SWP_NOMOVE or SWP_NOSIZE sprawia, że zmieniamy tylko "warstwę",
      // nie ruszając pozycji ani rozmiaru okna.
      SetWindowPos(Handle, InsertAfter, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    end;
end;

procedure Focus(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    // 1. Wyciąga okno na przód i aktywuje je w systemie
    SetForegroundWindow(Handle);
    // 2. Bezpośrednio kieruje sygnały klawiatury do tego okna
    SetFocus(Handle);
  end;
end;

function GetFocusEntryIndex(Handle: HWND): Integer;
var
i: Integer;
begin
  for i := 0 to High(FocusRegistry) do
    if FocusRegistry[i].Handle = Handle then Exit(i);
  SetLength(FocusRegistry, Length(FocusRegistry) + 1);
  Result := High(FocusRegistry);
  FocusRegistry[Result].Handle := Handle;
  FillChar(FocusRegistry[Result].Callbacks, SizeOf(TFocusCallbacks), 0);
end;

procedure SetColor(Handle: HWND; Color: DWORD);
var
  NewBrush, OldBrush: HBRUSH;
begin
  if Handle <> 0 then
  begin
    // 1. Tworzymy nowy pędzel
    NewBrush := CreateSolidBrush(Color);

    // 2. Podmieniamy pędzel w klasie okna i pobieramy stary (GCLP_HBRBACKGROUND)
    // Używamy Handle (parametru funkcji) zamiast błędnego "Window"
    OldBrush := HBRUSH(SetClassLongPtr(Handle, GCLP_HBRBACKGROUND, LONG_PTR(NewBrush)));

    // 3. Usuwamy stary pędzel z pamięci, aby nie było wycieków (GDI Leak)
    if OldBrush <> 0 then
      DeleteObject(OldBrush);

    // 4. Wymuszamy natychmiastowe przerysowanie okna nowym kolorem
    InvalidateRect(Handle, nil, True);
    UpdateWindow(Handle);
  end;
end;

procedure SetBorder(Handle: HWND; Enable: Boolean);
var
  Style: LongInt;
begin
 if Handle = 0 then Exit;
  Style := GetWindowLong(Handle, GWL_STYLE);

  if Enable then
    Style := Style or WS_CAPTION or WS_BORDER
  else
    Style := Style and not (WS_CAPTION or WS_BORDER);

  SetWindowLong(Handle, GWL_STYLE, Style);
  // Odświeżenie ramki
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure SetSizable(Handle: HWND; Enable: Boolean);
var
  Style: LongInt;
begin
  if Handle = 0 then Exit;
    Style := GetWindowLong(Handle, GWL_STYLE);

    if Enable then
      Style := Style or WS_THICKFRAME // WS_THICKFRAME to styl pozwalający na zmianę rozmiaru
    else
      Style := Style and not WS_THICKFRAME;

    SetWindowLong(Handle, GWL_STYLE, Style);
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure SetMinimizeButton(Handle: HWND; Enable: Boolean);
var
  Style: LongInt;
begin
if Handle = 0 then Exit;
  Style := GetWindowLong(Handle, GWL_STYLE);

  if Enable then
    Style := Style or WS_MINIMIZEBOX
  else
    Style := Style and not WS_MINIMIZEBOX;

  SetWindowLong(Handle, GWL_STYLE, Style);
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure BringToTop(Handle: HWND);
begin
  if Handle <> 0 then
    // HWND_TOP = umieść na szczycie kolejności Z-Order
    // SWP_NOMOVE or SWP_NOSIZE = nie zmieniaj położenia ani wielkości
    // SWP_NOACTIVATE = nie aktywuj okna (nie zabieraj fokusu klawiatury)
    SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure SendToBack(Handle: HWND);
begin
  if Handle <> 0 then
      // HWND_BOTTOM = umieść na samym spodzie (pod wszystkimi innymi oknami)
      SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure Show(Handle: HWND);
begin
  if Handle <> 0 then
    // SW_SHOWNA = Pokaż w obecnym stanie, bez aktywowania (Non-Activated)
    ShowWindow(Handle, SW_SHOWNA);
end;

procedure Hide(Handle: HWND);
begin
  if Handle <> 0 then
      ShowWindow(Handle, SW_HIDE);
end;

procedure SetMinWindowSize(Handle: HWND; MinWidth, MinHeight: Integer);
begin
  if Handle <> 0 then
  begin
    // Zapisujemy te wartości w pamięci okna
    SetProp(Handle, 'AvocadoMinW', THandle(MinWidth));
    SetProp(Handle, 'AvocadoMinH', THandle(MinHeight));
  end;
end;

procedure SetOnMove(Handle: HWND; OnMoveEvent: TAvocadoEvent);
var
  i: Integer;
begin
  if Handle = 0 then Exit;

    // 1. Szukamy, czy już jest przypisane (aktualizacja)
    for i := 0 to High(MoveRegistry) do
    begin
      if MoveRegistry[i].Handle = Handle then
      begin
        MoveRegistry[i].Callback := OnMoveEvent;
        Exit;
      end;
    end;

    // 2. Jeśli nie ma, dodajemy nowe (POZA PĘTLĄ!)
    SetLength(MoveRegistry, Length(MoveRegistry) + 1);
    MoveRegistry[High(MoveRegistry)].Handle := Handle;
    MoveRegistry[High(MoveRegistry)].Callback := OnMoveEvent;
end;

function FindMoveEvent(Handle: HWND): TAvocadoEvent;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(MoveRegistry) do
  begin
    if MoveRegistry[i].Handle = Handle then
    begin
      Result := MoveRegistry[i].Callback;
      Exit;
    end;
  end;
end;

procedure Repaint(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    // 1. InvalidateRect: Mówi systemowi "to okno jest brudne, trzeba je przerysować"
    // Parametr True = wymaż tło (WM_ERASEBKGND)
    InvalidateRect(Handle, nil, True);

    // 2. UpdateWindow: Wymusza natychmiastowe wysłanie WM_PAINT (nie czeka w kolejce)
    UpdateWindow(Handle);
  end;
end;

procedure Invalidate(Handle: HWND);
begin
  if Handle <> 0 then
    // Tylko planuje odświeżenie (system zrobi to, gdy procesor będzie wolny)
    InvalidateRect(Handle, nil, True);
end;

procedure BeginUpdate(Handle: HWND);
begin
  if Handle <> 0 then
    // WM_SETREDRAW: 0 (False) = blokada rysowania
    SendMessage(Handle, WM_SETREDRAW, 0, 0);
end;

procedure EndUpdate(Handle: HWND);
begin
  if Handle <> 0 then
  begin
    // WM_SETREDRAW: 1 (True) = odblokowanie rysowania
    SendMessage(Handle, WM_SETREDRAW, 1, 0);

    // Konieczne jest wymuszenie odświeżenia, żeby pokazać zmiany
    // RDW_FRAME = przerysuj też ramkę (WM_NCPAINT)
    // RDW_INVALIDATE = oznacz treść jako nieaktualną
    // RDW_UPDATENOW = zrób to teraz
    // RDW_ALLCHILDREN = odśwież też przyciski w środku
    RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN);
  end;
end;

procedure SnapshotToClipboard(Handle: HWND);
var
  DC, MemDC: HDC;
  Bitmap, OldBitmap: HBITMAP;
  Rect: TRect;
  W, H: Integer;
begin
  if Handle = 0 then Exit;

  // 1. Pobieramy wymiary
  GetWindowRect(Handle, Rect);
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;

  // 2. Przygotowujemy kontekst pamięci (wirtualne płótno)
  DC := GetWindowDC(Handle); // Pobieramy DC całego okna (z ramką)
  MemDC := CreateCompatibleDC(DC);
  Bitmap := CreateCompatibleBitmap(DC, W, H);
  OldBitmap := SelectObject(MemDC, Bitmap);

  try
    // 3. WM_PRINT: Magia! Prosimy okno, żeby narysowało się na naszym wirtualnym płótnie
    // PRF_CHILDREN = rysuj też przyciski w środku
    // PRF_CLIENT = rysuj środek
    // PRF_NONCLIENT = rysuj ramkę i pasek tytułu
    SendMessage(Handle, WM_PRINT, WPARAM(MemDC),
      PRF_CHILDREN or PRF_CLIENT or PRF_NONCLIENT or PRF_ERASEBKGND);

    // 4. Kopiujemy do schowka
    if OpenClipboard(Handle) then
    begin
      EmptyClipboard;
      SetClipboardData(CF_BITMAP, Bitmap);
      CloseClipboard;
    end;

    // Uwaga: Jeśli Bitmap trafiła do schowka, system nią zarządza, nie usuwamy jej DeleteObject!
    // Ale w tym kodzie Bitmap jest kopią w schowku, więc oryginał trzeba zwolnić,
    // chyba że SetClipboardData przejmuje własność (w WinAPI przejmuje).
    // Dla bezpieczeństwa w prostym kodzie zakładamy, że system przejął bitmapę.
    // Aby być w 100% czystym, zazwyczaj robi się kopię CopyImage przed schowkiem.
    // Tutaj uproszczona wersja.

  finally
    SelectObject(MemDC, OldBitmap);
    DeleteDC(MemDC);
    ReleaseDC(Handle, DC);
  end;
end;

procedure SetMemoLimit(Handle: HWND; Limit: Integer);
begin
  if Handle <> 0 then
    // EM_SETLIMITTEXT ustawia limit. Jeśli Limit = 0, ustawia max systemowy.
    SendMessage(Handle, EM_SETLIMITTEXT, WPARAM(Limit), 0);
end;

procedure SetOnActivateApp(Handle: HWND; Event: TAvocadoActivateAppEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then begin
    Idx := GetFocusEntryIndex(Handle);
    FocusRegistry[Idx].Callbacks.OnActivateApp := Event;
  end;
end;

procedure SetOnEnable(Handle: HWND; Event: TAvocadoEnableEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then begin
    Idx := GetFocusEntryIndex(Handle);
    FocusRegistry[Idx].Callbacks.OnEnable := Event;
  end;
end;

procedure SetOnSysKeyDown(Handle: HWND; Event: TAvocadoKeyEvent);
var
  Idx: Integer;
begin
  if Handle<>0 then
  begin Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnKeyDown:=Event;
  end;
end;

procedure SetOnSysKeyUp(Handle: HWND; Event: TAvocadoKeyEvent);
var
  Idx: Integer;
begin
  if Handle<>0 then
  begin
    Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnKeyUp := Event;
  end;
end;

procedure SetOnChar(Handle: HWND; Event: TAvocadoCharEvent);
var
  Idx: Integer;
begin
  if Handle<>0 then
  begin
    Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnChar:=Event;
  end;
end;

procedure SetOnSysChar(Handle: HWND; Event: TAvocadoCharEvent);
var
Idx: Integer;
begin
  if Handle<>0 then
  begin
    Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnSysChar:=Event;
  end;
end;

procedure SetOnDeadChar(Handle: HWND; Event: TAvocadoCharEvent);
var
  Idx: Integer;
begin
  if Handle<>0 then
  begin Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnDeadChar:=Event;
  end;
end;

procedure SetOnUniChar(Handle: HWND; Event: TAvocadoCharEvent);
var
Idx: Integer;
begin
  if Handle<>0 then
  begin Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnUniChar:=Event;
  end;
end;

function CreateAvocadoButton(Parent: HWND; const Text: string; X, Y, Width,
  Height: Integer): HWND;
begin
  Result := CreateWindowExW(
    0, 'BUTTON', PWideChar(UnicodeString(Text)),
    WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or WS_TABSTOP,
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );
  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function CreateCustomButton(Parent: HWND; const Text: string; X, Y, Width,
  Height: Integer): HWND;
var
  WndClass: TWndClassExW;
  ClassName: WideString;
  TempText: UnicodeString; // <--- TO JEST KLUCZ DO SUKCESU
begin
  ClassName := 'AvocadoCustomButton';
  TempText := UnicodeString(Text);

  // 1. Rejestracja klasy
  if not GetClassInfoExW(GetModuleHandle(nil), PWideChar(ClassName), @WndClass) then
  begin
    FillChar(WndClass, SizeOf(WndClass), 0);
    WndClass.cbSize := SizeOf(TWndClassExW);
    WndClass.style := CS_HREDRAW or CS_VREDRAW;
    WndClass.lpfnWndProc := @AvocadoButtonProc;
    WndClass.hInstance := GetModuleHandle(nil);
    WndClass.hCursor := LoadCursor(0, IDC_HAND);
    WndClass.lpszClassName := PWideChar(ClassName);
    RegisterClassExW(WndClass);
  end;

  // 2. Tworzenie okna
  Result := CreateWindowExW(
    0,
    PWideChar(ClassName),
    PWideChar(TempText),
    WS_VISIBLE or WS_CHILD,
    X, Y, Width, Height,
    Parent, 0, GetModuleHandle(nil), nil
  );

  // 3. FIX OSTATECZNY: Ustawiamy tekst ponownie, jawnie jako Unicode
  // Jeśli CreateWindow coś zepsuł przy konwersji, to naprawi sprawę.
  if Result <> 0 then
  begin
    SetWindowTextW(Result, PWideChar(TempText));
    SetButtonColors(Result, $E0E0E0, $C0C0C0, $A0A0A0, $000000);
  end;
  end;




function CreateAvocadoLabel(Parent: HWND; const Text: string; X, Y, Width,
  Height: Integer): HWND;
begin
  Result := CreateWindowExW(
    0, 'STATIC', PWideChar(UnicodeString(Text)),
    WS_VISIBLE or WS_CHILD or SS_LEFT, // SS_LEFT wyrównuje do lewej
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );
  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function CreateAvocadoEdit(Parent: HWND; const Text: string; X, Y, Width,
  Height: Integer): HWND;
begin
  Result := CreateWindowExW(
    WS_EX_CLIENTEDGE, 'EDIT', PWideChar(UnicodeString(Text)),
    WS_VISIBLE or WS_CHILD or ES_AUTOHSCROLL or WS_TABSTOP, // Brak ES_MULTILINE = jedna linia
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );
  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function CreateAvocadoCheckbox(Parent: HWND; const Text: string; X, Y, Width,
  Height: Integer): HWND;
begin
  Result := CreateWindowExW(
    0, 'BUTTON', PWideChar(UnicodeString(Text)),
    WS_VISIBLE or WS_CHILD or BS_AUTOCHECKBOX or WS_TABSTOP,
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );
  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function IsCheckboxChecked(Handle: HWND): Boolean;
begin
  Result := False;
  if Handle <> 0 then
    // SendMessage zwraca BST_CHECKED (1) jeśli zaznaczony
    Result := (SendMessage(Handle, BM_GETCHECK, 0, 0) = BST_CHECKED);
end;

procedure SetComponentColor(Handle: HWND; TextColor, BackgroundColor: DWORD);
var
  NewBrush, OldBrush: HBRUSH;
begin
  if Handle = 0 then Exit;

    // 1. Zapisujemy kolor tekstu i tła jako "Właściwości" (Properties) okna
    SetProp(Handle, 'AvocadoTextColor', THandle(TextColor));
    SetProp(Handle, 'AvocadoBgColor', THandle(BackgroundColor));

    // 2. Tworzymy pędzel tła i też go zapisujemy (potrzebny do WM_CTLCOLOR)
    NewBrush := CreateSolidBrush(BackgroundColor);

    // Jeśli był stary pędzel, usuwamy go, żeby nie zaśmiecać pamięci
    OldBrush := HBRUSH(GetProp(Handle, 'AvocadoBrush'));
    if OldBrush <> 0 then DeleteObject(OldBrush);

    SetProp(Handle, 'AvocadoBrush', THandle(NewBrush));

    // 3. Wymuszamy przerysowanie
    InvalidateRect(Handle, nil, True);
end;

procedure DrawRectangle(Handle: HWND; X, Y, W, H: Integer; Color: DWORD);
var
  DC: HDC;
  Pen: HPEN;
  OldPen: HPEN;
  OldBrush: HBRUSH;
begin
  if Handle = 0 then Exit;
    DC := GetDC(Handle);
    try
      Pen := CreatePen(PS_SOLID, 1, Color);
      OldPen := SelectObject(DC, Pen);
      // Wybieramy "pusty" pędzel, żeby nie zamalować środka
      OldBrush := SelectObject(DC, GetStockObject(NULL_BRUSH));

      Rectangle(DC, X, Y, X + W, Y + H);

      SelectObject(DC, OldBrush);
      SelectObject(DC, OldPen);
      DeleteObject(Pen);
    finally
      ReleaseDC(Handle, DC);
    end;
end;

procedure DrawFillRectangle(Handle: HWND; X, Y, W, H: Integer; Color: DWORD);
var
  DC: HDC;
  Rect: TRect;
  Brush: HBRUSH;
begin
  if Handle = 0 then Exit;
    DC := GetDC(Handle);
    try
      Rect.Left := X;
      Rect.Top := Y;
      Rect.Right := X + W;
      Rect.Bottom := Y + H;

      Brush := CreateSolidBrush(Color);
      FillRect(DC, Rect, Brush);
      DeleteObject(Brush);
    finally
      ReleaseDC(Handle, DC);
    end;
end;

procedure ShowMessage(Owner: HWND; const Title, Text: string);
begin
  MessageBoxW(Owner, PWideChar(UnicodeString(Text)), PWideChar(UnicodeString(Title)), MB_OK or MB_ICONINFORMATION);
end;

function AskQuestion(Owner: HWND; const Title, Text: string): Boolean;
begin
  Result := MessageBoxW(Owner, PWideChar(UnicodeString(Text)), PWideChar(UnicodeString(Title)), MB_YESNO or MB_ICONQUESTION) = IDYES;
end;

procedure SetAnchor(Control: HWND; Anchors: TAvocadoAnchors);
var
  Parent: HWND;
  ParentRect, CtrlRect: TRect;
  Data: TAnchorData;
  Pt: TPoint;
  Index: Integer;
begin
Parent := GetParent(Control);
  if Parent = 0 then Exit;

  // 1. Pobieramy geometrię
  GetClientRect(Parent, ParentRect); // Rozmiar wnętrza rodzica
  GetWindowRect(Control, CtrlRect);  // Rozmiar kontrolki (ekranowy)

  // Konwertujemy pozycję kontrolki z ekranu na współrzędne klienta rodzica
  Pt.x := CtrlRect.Left;
  Pt.y := CtrlRect.Top;
  ScreenToClient(Parent, Pt);

  // 2. Wypełniamy dane
  Data.Control := Control;
  Data.Parent := Parent;
  Data.Anchors := Anchors;

  // Obliczamy marginesy na podstawie OBECNEJ pozycji
  Data.MarginLeft := Pt.x;
  Data.MarginTop := Pt.y;
  Data.MarginRight := ParentRect.Right - (Pt.x + (CtrlRect.Right - CtrlRect.Left));
  Data.MarginBottom := ParentRect.Bottom - (Pt.y + (CtrlRect.Bottom - CtrlRect.Top));

  Data.InitialWidth := CtrlRect.Right - CtrlRect.Left;
  Data.InitialHeight := CtrlRect.Bottom - CtrlRect.Top;

  // 3. Dodajemy do tablicy (prosty append)
  // W wersji produkcyjnej warto sprawdzić, czy kontrolka już tam jest i zaktualizować
  Index := Length(AnchoredControls);
  SetLength(AnchoredControls, Index + 1);
  AnchoredControls[Index] := Data;
end;

procedure UpdateLayout(ParentWnd: HWND);
var
  i: Integer;
  ParentRect: TRect;
  NewX, NewY, NewW, NewH: Integer;
  ParentW, ParentH: Integer;
begin
  // Pobieramy nowe wymiary rodzica
    GetClientRect(ParentWnd, ParentRect);
    ParentW := ParentRect.Right;
    ParentH := ParentRect.Bottom;

    for i := 0 to High(AnchoredControls) do
    begin
      // Przetwarzamy tylko dzieci tego konkretnego okna
      if AnchoredControls[i].Parent = ParentWnd then
      begin
        with AnchoredControls[i] do
        begin
          // --- POZIOMO (X i Width) ---
          if (akLeft in Anchors) and (akRight in Anchors) then
          begin
            // Rozciąganie: Lewy i Prawy margines stały -> Zmienia się szerokość
            NewX := MarginLeft;
            NewW := ParentW - MarginLeft - MarginRight;
          end
          else if (akRight in Anchors) then
          begin
            // Tylko prawy: Przesuwamy X w prawo, szerokość stała
            NewX := ParentW - InitialWidth - MarginRight;
            NewW := InitialWidth;
          end
          else // (akLeft) lub brak
          begin
            // Domyślnie: Trzymaj się lewej
            NewX := MarginLeft;
            NewW := InitialWidth;
          end;

          // --- PIONOWO (Y i Height) ---
          if (akTop in Anchors) and (akBottom in Anchors) then
          begin
            // Rozciąganie pionowe
            NewY := MarginTop;
            NewH := ParentH - MarginTop - MarginBottom;
          end
          else if (akBottom in Anchors) then
          begin
            // Tylko dół: Przesuwamy Y w dół
            NewY := ParentH - InitialHeight - MarginBottom;
            NewH := InitialHeight;
          end
          else // (akTop) lub brak
          begin
            // Domyślnie: Trzymaj się góry
            NewY := MarginTop;
            NewH := InitialHeight;
          end;

          // Aplikujemy zmiany
          // SWP_NOZORDER = nie zmieniaj kolejności warstw
          // SWP_NOACTIVATE = nie aktywuj kontrolki (nie kradnij focusa)
          SetWindowPos(Control, 0, NewX, NewY, NewW, NewH, SWP_NOZORDER or SWP_NOACTIVATE);

          // Aktualizujemy "Initial" w razie gdyby okno znów zmieniło rozmiar (dla logiki samej kotwicy nie zawsze konieczne, ale bezpieczne)
          if not ((akLeft in Anchors) and (akRight in Anchors)) then InitialWidth := NewW;
          if not ((akTop in Anchors) and (akBottom in Anchors)) then InitialHeight := NewH;
        end;
      end;
    end;
end;

procedure CopyToClipboard(Handle: HWND);
begin
  if Handle <> 0 then
      SendMessage(Handle, WM_COPY, 0, 0);
end;

procedure CutToClipboard(Handle: HWND);
begin
  if Handle <> 0 then
      SendMessage(Handle, WM_CUT, 0, 0);
end;

procedure PasteFromClipboard(Handle: HWND);
begin
  if Handle <> 0 then
      SendMessage(Handle, WM_PASTE, 0, 0);
end;

procedure UndoLastAction(Handle: HWND);
begin
  if Handle <> 0 then
      // WM_UNDO jest uniwersalnym komunikatem dla kontrolek edycyjnych
      SendMessage(Handle, WM_UNDO, 0, 0);
end;

function CanUndo(Handle: HWND): Boolean;
begin
Result := False;
  if Handle <> 0 then
    // EM_CANUNDO działa dla wszystkich standardowych pól edycyjnych (Edit/Memo)
    Result := SendMessage(Handle, EM_CANUNDO, 0, 0) <> 0;
end;

function CreateAvocadoMemo(Parent: HWND; X, Y, Width, Height: Integer): HWND;
begin
   Result := CreateWindowExW(
    //WS_EX_CLIENTEDGE,         // Lekka ramka wklęsła
    0,
    'EDIT',                   // Nazwa wbudowanej klasy Windows
    '',                       // Początkowy tekst
    WS_CHILD or WS_VISIBLE or WS_VSCROLL or
    ES_MULTILINE or ES_AUTOVSCROLL, // Style dla Memo
    X, Y, Width, Height,
    Parent,                   // Okno Avocado jako rodzic
    0,
    GetModuleHandle(nil),
    nil
  );

  // Opcjonalnie: Ustawienie czcionki systemowej
  if Result <> 0 then
    SendMessage(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
end;

function GetMemoText(hMemo: HWND): string;
var
  TextLen: Integer;
  WText: WideString;
begin
  Result := '';
    if hMemo = 0 then Exit;

    // 1. Pobieramy długość tekstu (w znakach)
    TextLen := GetWindowTextLengthW(hMemo);
    if TextLen > 0 then
    begin
      // 2. Przygotowujemy bufor (WideString dla pełnego Unicode)
      SetLength(WText, TextLen);
      // 3. Kopiujemy tekst z kontrolki do bufora
      GetWindowTextW(hMemo, PWideChar(WText), TextLen + 1);
      Result := UTF8Encode(WText); // Konwertujemy na string (UTF-8)
    end;
end;

procedure AppendMemoText(hMemo: HWND; const Text: string);
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

function GetWindowTextLength(Handle: HWND): Integer;
begin
  Result := 0;
  if Handle <> 0 then
  begin
    // Używamy wersji 'W' (Unicode) z modułu Windows
    Result := Windows.GetWindowTextLengthW(Handle);
  end;
end;

function FindEvent(Handle: HWND): TAvocadoEvent;
var
  i: Integer;
begin
  Result := nil;
    for i := 0 to High(EventRegistry) do
    begin
      if EventRegistry[i].Handle = Handle then
      begin
        Result := EventRegistry[i].Callback;
        Exit;
      end;
    end;
end;

procedure SetOnResize(Handle: HWND; OnResizeEvent: TAvocadoEvent);
var
  i: Integer;
begin
  if Handle = 0 then Exit;

    // 1. Sprawdzamy czy już jest przypisane zdarzenie
    for i := 0 to High(ResizeRegistry) do
    begin
      if ResizeRegistry[i].Handle = Handle then
      begin
        ResizeRegistry[i].Callback := OnResizeEvent;
        Exit;
      end;
    end;

    // 2. Jeśli nie, dodajemy nowe (POZA PĘTLĄ)
    SetLength(ResizeRegistry, Length(ResizeRegistry) + 1);
    ResizeRegistry[High(ResizeRegistry)].Handle := Handle;
    ResizeRegistry[High(ResizeRegistry)].Callback := OnResizeEvent;
end;

function FindResizeEvent(Handle: HWND): TAvocadoEvent;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(ResizeRegistry) do
  begin
    if ResizeRegistry[i].Handle = Handle then
    begin
      Result := ResizeRegistry[i].Callback;
      Exit;
    end;
  end;
end;

procedure SetOnKeyDown(Handle: HWND; Event: TAvocadoKeyEvent);
var
Idx: Integer;
//i: Integer;
begin
  if Handle<>0 then
  begin Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnKeyDown:=Event;
  end;
  {
  if Handle = 0 then Exit;
    for i := 0 to High(KeyDownRegistry) do
    begin
      if KeyDownRegistry[i].Handle = Handle then
      begin
        KeyDownRegistry[i].Callback := OnKeyDownEvent;
        Exit;
      end;
    end;
    SetLength(KeyDownRegistry, Length(KeyDownRegistry) + 1);
    KeyDownRegistry[High(KeyDownRegistry)].Handle := Handle;
    KeyDownRegistry[High(KeyDownRegistry)].Callback := OnKeyDownEvent;
    }
end;

procedure SetOnKeyUp(Handle: HWND; Event: TAvocadoKeyEvent);
var
Idx: Integer;
begin
  if Handle<>0 then
  begin Idx:=GetKeyEntryIndex(Handle);
    KeyboardRegistry[Idx].Callbacks.OnKeyUp := Event;
  end;
  {
  if Handle = 0 then Exit;
    for i := 0 to High(KeyUpRegistry) do
    begin
      if KeyUpRegistry[i].Handle = Handle then
      begin
        KeyUpRegistry[i].Callback := OnKeyUpEvent;
        Exit;
      end;
    end;
    SetLength(KeyUpRegistry, Length(KeyUpRegistry) + 1);
    KeyUpRegistry[High(KeyUpRegistry)].Handle := Handle;
    KeyUpRegistry[High(KeyUpRegistry)].Callback := OnKeyUpEvent;
    }
end;

function LoWord(L: DWORD): Word;
begin
  Result := L and $FFFF; // Bierze tylko pierwsze 16 bitów (bity 0-15)
end;

function HiWord(L: DWORD): Word;
begin
  Result := (L shr 16) and $FFFF; // Przesuwa o 16 w prawo i bierze resztę
end;

function FindKeyDownEvent(Handle: HWND): TAvocadoKeyEvent;
var
i: Integer;
begin
Result := nil;
  for i := 0 to High(KeyDownRegistry) do
    if KeyDownRegistry[i].Handle = Handle then Exit(KeyDownRegistry[i].Callback);
end;

function FindKeyUpEvent(Handle: HWND): TAvocadoKeyEvent;
var
i: Integer;
begin
  Result := nil;
  for i := 0 to High(KeyUpRegistry) do
    if KeyUpRegistry[i].Handle = Handle then Exit(KeyUpRegistry[i].Callback);
end;

procedure SetOnCloseQuery(Handle: HWND; OnCloseEvent: TAvocadoCloseEvent);
var
i: Integer;
begin
  if Handle = 0 then Exit;

    for i := 0 to High(CloseQueryRegistry) do
    begin
      if CloseQueryRegistry[i].Handle = Handle then
      begin
        CloseQueryRegistry[i].Callback := OnCloseEvent;
        Exit;
      end;
    end;

    SetLength(CloseQueryRegistry, Length(CloseQueryRegistry) + 1);
    CloseQueryRegistry[High(CloseQueryRegistry)].Handle := Handle;
    CloseQueryRegistry[High(CloseQueryRegistry)].Callback := OnCloseEvent;
end;

function FindCloseEvent(Handle: HWND): TAvocadoCloseEvent;
var
i: Integer;
begin
Result := nil;
  for i := 0 to High(CloseQueryRegistry) do
  begin
    if CloseQueryRegistry[i].Handle = Handle then
    begin
      Result := CloseQueryRegistry[i].Callback;
      Exit;
    end;
  end;
end;

procedure SetWindowMaximizeButton(Handle: HWND; Enabled: Boolean);
var
  Style: LongInt;
begin
  // Pobieramy obecne style okna
  Style := GetWindowLong(Handle, GWL_STYLE);

  if Enabled then
    Style := Style or WS_MAXIMIZEBOX  // Dodaj przycisk
  else
    Style := Style and not WS_MAXIMIZEBOX; // Usuń przycisk

  // Aplikujemy nowy styl
  SetWindowLong(Handle, GWL_STYLE, Style);

  // Wymuszamy odświeżenie ramki okna
  SetWindowPos(Handle, 0, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

function GetKeyEntryIndex(Handle: HWND): Integer;
var
  i: Integer;
begin
 for i := 0 to High(KeyboardRegistry) do
    if KeyboardRegistry[i].Handle = Handle then Exit(i);

  SetLength(KeyboardRegistry, Length(KeyboardRegistry) + 1);
  Result := High(KeyboardRegistry);
  KeyboardRegistry[Result].Handle := Handle;
  FillChar(KeyboardRegistry[Result].Callbacks, SizeOf(TKeyboardCallbacks), 0);
end;

procedure FlashWindow(Handle: HWND; Count: Integer; Interval: Integer);
var
  FWI: TFlashWInfo;
begin
  if Handle = 0 then Exit;

    // Zerujemy strukturę (ważne w Pascalu)
    FillChar(FWI, SizeOf(FWI), 0);
    FWI.cbSize := SizeOf(FWI);
    FWI.hwnd := Handle;
    FWI.dwTimeout := DWORD(Interval); // Szybkość (0 = domyślna)

    if Count = 0 then
    begin
      // STOP - Zatrzymujemy mruganie
      FWI.dwFlags := FLASHW_STOP;
      FWI.uCount := 0;
    end
    else if Count < 0 then
    begin
      // MODE "TIMERNOFG" - Mrugaj w nieskończoność, aż użytkownik aktywuje okno
      // To jest standardowe zachowanie komunikatorów (np. Teams, Discord)
      FWI.dwFlags := FLASHW_ALL or FLASHW_TIMERNOFG;
      FWI.uCount := 0;
    end
    else
    begin
      // MODE "COUNT" - Mrugaj konkretną liczbę razy
      FWI.dwFlags := FLASHW_ALL;
      FWI.uCount := Count;
    end;

    FlashWindowEx(FWI);
end;

procedure ClearControl(Handle: HWND);
var
  Style: LongInt;
  IsCheckbox: Boolean;
  ClassName: array[0..255] of WideChar;
begin
    if Handle = 0 then Exit;

      // 1. Sprawdzamy, czy to Checkbox
      IsCheckbox := False;

      // Pobieramy nazwę klasy
      GetClassNameW(Handle, ClassName, 255);

      // Jeśli to klasa 'BUTTON' (bo Checkbox to technicznie Button)
      if StrComp(PWideChar(ClassName), 'BUTTON') = 0 then
      begin
        Style := GetWindowLong(Handle, GWL_STYLE);
        // Sprawdzamy bity stylu odpowiedzialne za typ przycisku
        // $0F to maska BS_TYPEMASK
        case (Style and $0F) of
           BS_CHECKBOX, BS_AUTOCHECKBOX, BS_3STATE, BS_AUTO3STATE:
             IsCheckbox := True;
        end;
      end;

      // 2. Wykonujemy odpowiednią akcję
      if IsCheckbox then
      begin
        // DLA CHECKBOXA: Tylko odznaczamy (stan = 0), tekst zostawiamy w spokoju!
        SendMessage(Handle, BM_SETCHECK, 0, 0); // 0 = BST_UNCHECKED
      end
      else
      begin
        // DLA CAŁEJ RESZTY (Edit, Memo, Label): Czyścimy tekst
        SetWindowTextW(Handle, '');
      end;
end;

procedure SetOnMouseMove(Handle: HWND; Event: TAvocadoMouseEvent);
var
  Idx: Integer;
begin
  //if Handle <> 0 then
  //  MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnMove := Event;
  if Handle <> 0 then
  begin
    // Najpierw pobierz indeks do zmiennej
    Idx := GetMouseEntryIndex(Handle);

    // Upewnij się, że indeks jest poprawny (zabezpieczenie)
    if (Idx >= 0) and (Idx <= High(MouseRegistry)) then
    begin
      MouseRegistry[Idx].Callbacks.OnMove := Event;
    end;
  end;
end;

procedure SetOnMouseLeftDown(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnLDown := Event;
end;

procedure SetOnMouseLeftUp(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnLUp := Event;
end;

procedure SetOnMouseLeftDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnLDblClick := Event;
end;

procedure SetOnMouseRightDown(Handle: HWND; Event: TAvocadoMouseEvent);
var
  Idx: Integer;
begin
 if Handle <> 0 then
  begin
    // 1. Najpierw pobierz (lub utwórz) indeks.
    // Funkcja GetMouseEntryIndex zadba o powiększenie tablicy (SetLength).
    Idx := GetMouseEntryIndex(Handle);

    // 2. Dopiero teraz przypisz zdarzenie.
    // Mamy pewność, że MouseRegistry[Idx] istnieje.
    MouseRegistry[Idx].Callbacks.OnRDown := Event;
  end;
 {
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnRDown := Event;
    }
end;

procedure SetOnMouseRightUp(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnRUp := Event;
end;

procedure SetOnMouseRightDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
  MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnRDblClick := Event;
end;

procedure SetOnMouseMiddleDown(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnMDown := Event;
end;

procedure SetOnMouseMiddleUp(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnMUp := Event;
end;

procedure SetOnMouseMiddleDoubleClick(Handle: HWND; Event: TAvocadoMouseEvent);
begin
  if Handle <> 0 then
  MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnMDblClick := Event;
end;

procedure SetOnMouseWheel(Handle: HWND; Event: TAvocadoWheelEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnWheel := Event;
end;

procedure SetOnMouseHWheel(Handle: HWND; Event: TAvocadoWheelEvent);
begin
  if Handle <> 0 then
    MouseRegistry[GetMouseEntryIndex(Handle)].Callbacks.OnHWheel := Event;
end;

function GetMouseEntryIndex(Handle: HWND): Integer;
var
  i: Integer;
begin
    // 1. Szukamy, czy okno już jest w rejestrze
    for i := 0 to High(MouseRegistry) do
      if MouseRegistry[i].Handle = Handle then Exit(i);

    // 2. Jeśli nie ma - TWORZYMY NOWE MIEJSCE
    SetLength(MouseRegistry, Length(MouseRegistry) + 1); // <--- TO JEST KLUCZOWE!

    Result := High(MouseRegistry); // Pobieramy indeks nowego elementu
    MouseRegistry[Result].Handle := Handle;

    // Czyścimy pamięć (ważne, żeby usunąć śmieci z pamięci)
    FillChar(MouseRegistry[Result].Callbacks, SizeOf(TMouseCallbacks), 0);
end;

procedure SetOnNCMouseMove(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then
    MouseRegistry[Idx].Callbacks.OnNCMove := Event;
  end;
end;

procedure SetOnNCLeftDown(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
  Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then
    MouseRegistry[Idx].Callbacks.OnNCLDown := Event;
  end;

end;

procedure SetOnNCLeftUp(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
  Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then
    MouseRegistry[Idx].Callbacks.OnNCLUp := Event;
  end;
end;

procedure SetOnNCLeftDoubleClick(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
  Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then MouseRegistry[Idx].Callbacks.OnNCLDblClick := Event;
  end;
end;

procedure SetOnNCRightDown(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
  Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then
    MouseRegistry[Idx].Callbacks.OnNCRDown := Event;
  end;
end;

procedure SetOnNCRightUp(Handle: HWND; Event: TAvocadoNCMouseEvent);
var
 Idx: Integer;
begin
  if Handle <> 0 then
  begin Idx := GetMouseEntryIndex(Handle);
    if Idx >= 0 then MouseRegistry[Idx].Callbacks.OnNCRUp := Event;
  end;
end;

procedure SetOnClick(Handle: HWND; OnClickEvent: TAvocadoEvent);
var
  i: Integer;
begin
if Handle = 0 then Exit;

// 1. Sprawdzamy, czy ten element ma już zdarzenie (jeśli tak, nadpisujemy)
for i := 0 to High(EventRegistry) do
begin
  if EventRegistry[i].Handle = Handle then
  begin
    EventRegistry[i].Callback := OnClickEvent;
    Exit;// Znaleziono i zaktualizowano - wychodzimy z procedury!
  end;
  end;
  // 2. Jeśli nie ma, dodajemy nowy wpis
  SetLength(EventRegistry, Length(EventRegistry) + 1);
  EventRegistry[High(EventRegistry)].Handle := Handle;
  EventRegistry[High(EventRegistry)].Callback := OnClickEvent;
end;

function GetMenuEntryIndex(Handle: HWND): Integer;
var
i: Integer;
begin
  for i := 0 to High(MenuRegistry) do
    if MenuRegistry[i].Handle = Handle then Exit(i);
  SetLength(MenuRegistry, Length(MenuRegistry) + 1);
  Result := High(MenuRegistry);
  MenuRegistry[Result].Handle := Handle;
  FillChar(MenuRegistry[Result].Callbacks, SizeOf(TMenuCallbacks), 0);
end;

function CreateAvocadoWindow(Params: TAvocadoWindowParams): HWND;
var
    WndClass: TWndClassExW;
    ClassName, WindowName: WideString;
    hInstance: HMODULE;
    pDrag: PBoolean;
    //WindowStyle: DWORD;
    dwStyle: DWORD;   //nowe
begin
   dwStyle := WS_OVERLAPPEDWINDOW;

   // Jeśli ktoś celowo ustawił False, to zabieramy przycisk
   if (Params.AllowMaximize = False) then
      dwStyle := dwStyle and not WS_MAXIMIZEBOX;


  hInstance := GetModuleHandle(nil);
  ClassName := 'AvocadoWindowClass';
  WindowName := WideString(Params.Title);



 // Result := 0;
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.cbSize := SizeOf(TWndClassExW);
  WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS;
  WndClass.lpfnWndProc := @AvocadoWindowProc;
  WndClass.hInstance := hInstance;
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  // UŻYCIE KOLORU Z PARAMETRÓW:
  WndClass.hbrBackground := CreateSolidBrush(Params.BackgroundColor);
  WndClass.lpszClassName := PWideChar(ClassName);

  if RegisterClassExW(WndClass) = 0 then
  begin
    if GetLastError() <> ERROR_CLASS_ALREADY_EXISTS then
      Exit(0);
  end;

  // 2. DOBÓR STYLU (Logika scalona)
  if Params.Frameless then
    dwStyle := WS_POPUP
  else
  begin
    // Startujemy od pełnego okna
    dwStyle := WS_OVERLAPPEDWINDOW;

    // Jeśli użytkownik nie chce maksymalizacji, zabieramy mu przycisk
    if not Params.AllowMaximize then
      dwStyle := dwStyle and not WS_MAXIMIZEBOX;
  end;


  Result := CreateWindowExW(
      WS_EX_APPWINDOW,           // dwExStyle
      PWideChar(ClassName),      // lpClassName
      PWideChar(WindowName),     // lpWindowName
      dwStyle,
      Params.X,
      Params.Y,
      Params.Width,
      Params.Height,
      Params.Parent,                       // hWndParent
      0,                         // hMenu
      hInstance,
      nil                        // lpParam

  );

  if (Result <> 0) then
  begin

    New(pDrag);
    pDrag^ := Params.AllowDrag;
    SetWindowLongPtr(Result, GWL_USERDATA, LONG_PTR(pDrag));

    // Dark mode włączamy zawsze, jeśli chcemy nowoczesny wygląd
    SetDarkMode(Result, True);

    if Params.Visible then
    begin
      ShowWindow(Result, SW_SHOWNORMAL);
      UpdateWindow(Result);
    end;
  end;
end;

end.

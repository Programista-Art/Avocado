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
  // Definicja typu procedury: przyjmuje "Sender" czyli uchwyt klikniętego elementu
  TAvocadoEvent = procedure(Sender: HWND);
type
  // Nowy typ zdarzenia dla klawiatury - przekazuje kod klawisza (Key)
  TAvocadoKeyEvent = procedure(Sender: HWND; Key: Word);

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
  end;

{OKNO}
function CreateAvocadoWindow(Params: TAvocadoWindowParams): HWND;
procedure ShowWindowAvocado(var msg: TMsg); // Zmieniono na var dla wydajności
procedure SetDarkMode(Handle: HWND; Enable: Boolean);
function AvocadoWindowProc(Window: HWND; Message: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
//zamykanie okna
procedure CloseAvocadoWindow(Handle: HWND);
// aby móc zmieniać napis na pasku tytułu "w locie", np. pokazując postęp ładowania lub nazwę otwartego pliku?
procedure SetTitle(Handle: HWND; const NewTitle: string);
//POZYCJA OKNA
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
procedure Focus(Handle: HWND);
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


{KOMPONENT MEMO}
function CreateAvocadoMemo(Parent: HWND; X, Y, Width, Height: Integer): HWND;
function GetMemoText(hMemo: HWND): string;
procedure AppendMemoText(hMemo: HWND; const Text: string);

{ZDARZENIA}
// Funkcja przypisująca reakcję na kliknięcie
procedure SetOnClick(Handle: HWND; OnClickEvent: TAvocadoEvent);
// Procedura pomocnicza do szukania zdarzenia (wewnętrzna)
function FindEvent(Handle: HWND): TAvocadoEvent;
// Funkcja przypisująca reakcję na zmianę rozmiaru okna
procedure SetOnResize(Handle: HWND; OnResizeEvent: TAvocadoEvent);
// Funkcja pomocnicza do szukania zdarzenia zmiany rozmiaru
function FindResizeEvent(Handle: HWND): TAvocadoEvent;
// Rejestracja zdarzeń klawiatury
procedure SetOnKeyDown(Handle: HWND; OnKeyDownEvent: TAvocadoKeyEvent);
procedure SetOnKeyUp(Handle: HWND; OnKeyUpEvent: TAvocadoKeyEvent);
//pomocnice funkcje
function FindKeyDownEvent(Handle: HWND): TAvocadoKeyEvent;
function FindKeyUpEvent(Handle: HWND): TAvocadoKeyEvent;
// Funkcja rejestrująca
procedure SetOnCloseQuery(Handle: HWND; OnCloseEvent: TAvocadoCloseEvent);
// Funkcja szukająca
function FindCloseEvent(Handle: HWND): TAvocadoCloseEvent;
function FlashWindowEx(var pfwi: TFlashWInfo): BOOL; stdcall; external 'user32.dll';
// --- INTERAKCJA PASKIEM ZADAŃ ---

// Miganie oknem na pasku zadań (Powiadomienia)
// Handle: uchwyt okna
// Count: liczba mrugnięć (wpisz -1, aby mrugało dopóki nie klikniesz w okno)
// Interval: szybkość w ms (0 = domyślna systemowa, np. 500ms)
procedure FlashWindow(Handle: HWND; Count: Integer; Interval: Integer);




const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  FLASHW_STOP = 0;
  FLASHW_CAPTION = 1;
  FLASHW_TRAY = 2;
  FLASHW_ALL = 3;        // FLASHW_CAPTION or FLASHW_TRAY
  FLASHW_TIMER = 4;      // Mrugaj ciągle
  FLASHW_TIMERNOFG = 12; // Mrugaj dopóki okno nie wyjdzie na wierzch

// Importujemy funkcję z Windows API
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: LPCVOID; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';

implementation

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


//uses
 // SysUtils;

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

    // --- KLIKNIĘCIA (COMMAND) ---
    WM_COMMAND:
    begin
      if LParam <> 0 then
      begin
        EventToRun := FindEvent(HWND(LParam));
        if Assigned(EventToRun) then
        begin
          EventToRun(HWND(LParam));
        end;
      end;
      Result := 0;
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

    // --- KLAWIATURA ---
    WM_KEYDOWN:
    begin
      KeyDownToRun := FindKeyDownEvent(Window);
      if Assigned(KeyDownToRun) then
        KeyDownToRun(Window, Word(WParam));
      Result := 0;
      Exit;
    end;

    WM_KEYUP:
    begin
      KeyUpToRun := FindKeyUpEvent(Window);
      if Assigned(KeyUpToRun) then
        KeyUpToRun(Window, Word(WParam));
      Result := 0;
      Exit;
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
        PosFunc := FindPosChangingEvent(Window);
        if Assigned(PosFunc) then
        begin
          PWinPos := PWINDOWPOS(LParam);
          // Wywołujemy funkcję użytkownika, która może zmienić flagi lub x,y
          PosFunc(Window, PWinPos^);
        end;
      // WAŻNE: Tutaj zawsze zwracamy 0, niezależnie czy obsłużyliśmy czy nie
      Result := 0;
      Exit;
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

      PostQuitMessage(0);
      Result := 0;
      Exit;
    end;

    // --- DRAGGING (PRZESUWANIE MYSZĄ) ---
    WM_LBUTTONDOWN:
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
      DC := BeginPaint(Window, PS);
      GetClientRect(Window, Rect);
      Brush := HBRUSH(GetClassLongPtr(Window, GCLP_HBRBACKGROUND));
      FillRect(DC, Rect, Brush);
      SetBkMode(DC, TRANSPARENT);
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

procedure CloseAvocadoWindow(Handle: HWND);
begin
  if Handle <> 0 then
    PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure SetTitle(Handle: HWND; const NewTitle: string);
begin
  if Handle <> 0 then
    begin
    // Konwertujemy string na WideString (Unicode), a następnie na wskaźnik PWideChar
    SetWindowTextW(Handle, PWideChar(UnicodeString(NewTitle)));
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

procedure SetOnKeyDown(Handle: HWND; OnKeyDownEvent: TAvocadoKeyEvent);
var
i: Integer;
begin
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
end;

procedure SetOnKeyUp(Handle: HWND; OnKeyUpEvent: TAvocadoKeyEvent);
var
i: Integer;
begin
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


function CreateAvocadoWindow(Params: TAvocadoWindowParams): HWND;
var
    WndClass: TWndClassExW;
    ClassName, WindowName: WideString;
    hInstance: HMODULE;
    pDrag: PBoolean;
    WindowStyle: DWORD;
begin


 // Result := 0;
  hInstance := GetModuleHandle(nil);
  ClassName := 'AvocadoWindowClass';
  WindowName := WideString(Params.Title);

  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.cbSize := SizeOf(TWndClassExW);
  WndClass.style := CS_HREDRAW or CS_VREDRAW;
  //WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_DROPSHADOW;

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

  // DOBÓR STYLU - powrót do stabilnych podstaw
  if Params.Frameless then
    WindowStyle := WS_POPUP // Czysty prostokąt bez niczego
  else
    WindowStyle := WS_OVERLAPPEDWINDOW;

  Result := CreateWindowExW(
      WS_EX_APPWINDOW,           // dwExStyle
      PWideChar(ClassName),      // lpClassName
      PWideChar(WindowName),     // lpWindowName
      WindowStyle,               // dwStyle (tutaj ląduje nasza zmienna!)
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

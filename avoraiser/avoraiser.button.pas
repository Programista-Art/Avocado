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

Module:     avoraiser.button
Description:
*)
unit avoraiser.button;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core, avoraiser.utils, avoraiser.events,avoraiser.gdi;
  // Usunąłem avoraiser.events, bo przenosimy wszystko do core/window

type
  TAvocadoClickEvent = procedure(HWnd: HWND); stdcall;
  type
  // Podstawowe typy danych GDI+
  GPStatus = Integer;
  GdiplusStartupInput = record
    GdiplusVersion: Cardinal;
    DebugEventCallback: Pointer;
    SuppressBackgroundThread: BOOL;
    SuppressExternalCodecs: BOOL;
  end;

// Importowanie funkcji z gdiplus.dll
function GdiplusStartup(out Token: ULONG_PTR; const Input: GdiplusStartupInput; Output: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
procedure GdiplusShutdown(Token: ULONG_PTR); stdcall; external 'gdiplus.dll';
function GdipCreateFromHDC(DC: HDC; out Graphics: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipDeleteGraphics(Graphics: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipLoadImageFromFile(FileName: PWideChar; out Image: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipDisposeImage(Image: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipDrawImageRectI(Graphics, Image: Pointer; X, Y, Width, Height: Integer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipSetInterpolationMode(Graphics: Pointer; Mode: Integer): GPStatus; stdcall; external 'gdiplus.dll';


procedure set_on_color_btn(Handle: HWND; Event: TAvocadoColorEvent);
function create_button(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
function create_image_button(parent_wnd: HWND; const text, image_path: UnicodeString; x, y, width, height: Integer): HWND;
procedure set_button_colors(Handle: HWND; Normal, Hover, Pressed, Text, borderColor: DWORD);
procedure set_button_radius(Handle: HWND; Radius: Integer);
procedure set_button_id(ButtonHandle: HWND; NewID: Integer);

function TransparentBlt(hdcDest: HDC; xoriginDest, yoriginDest, wDest, hDest: Integer; hdcSrc: HDC; xoriginSrc, yoriginSrc, wSrc, hSrc: Integer; crTransparent: UINT): BOOL; stdcall; external 'msimg32.dll' name 'TransparentBlt';
//procedure set_on_click(HBtn: HWND; Callback: TAvocadoClickEvent);
// Import funkcji z DLL
function GdipSetSmoothingMode(Graphics: Pointer; Mode: Integer): Integer; stdcall; external 'gdiplus.dll';
function GdipSetPixelOffsetMode(Graphics: Pointer; Mode: Integer): Integer; stdcall; external 'gdiplus.dll';

implementation
const
  // Statusy GDI+
  Ok = 0;

  // Tryby wygładzania (SmoothingMode)
  SmoothingModeDefault     = 0;
  SmoothingModeHighSpeed   = 1;
  SmoothingModeHighQuality = 2;
  SmoothingModeNone        = 3;
  SmoothingModeAntiAlias   = 4;
  // Tryby przesunięcia pikseli (PixelOffsetMode)
  PixelOffsetModeDefault     = 0;
  PixelOffsetModeHighSpeed   = 1;
  PixelOffsetModeHighQuality = 2;
  PixelOffsetModeNone        = 3;
  PixelOffsetModeHalf        = 4;


function AvocadoImageButtonProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
PS: TPaintStruct;
DC: HDC;
R: TRect;
Graphics, Image: Pointer;
ImgPath: PWideChar;
HFontMain, HOldFont: HFONT;
Txt: array[0..255] of WideChar;
ClickPtr: THandle;
OnClick: TAvocadoEvent;
Pt: TPoint;
Rect: TRect;
IsPressed: Boolean;
EventPtr: THandle;
Path: Pointer;
D: Integer;
ImgBrush: Pointer;
Radius: Integer;
Angle180, Angle270, Angle0, Angle90, SweepAngle: Single;
SolidBrush: Pointer;
BgColor: DWORD;
TME: TTrackMouseEvent;
IsHovered: Boolean;
HoverBrush: Pointer;
HControl: HWND;
begin
  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, PS);
      try
        GetClientRect(hWnd, R);

        // POBIERAMY ZAŁADOWANY OBRAZEK (zamiast ścieżki)
        Image := Pointer(GetPropW(hWnd, 'GdipImg'));

        // Pobieramy dynamiczną wartość promienia (domyślnie 0, jeśli nie ustawiono)
        Radius := Integer(GetPropW(HWnd, ROUNDING_COMP));

        if GdipCreateFromHDC(DC, Graphics) = 0 then
        begin
          // Pełna jakość i wygładzanie
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);
          GdipSetPixelOffsetMode(Graphics, PixelOffsetModeHighQuality);
          GdipSetInterpolationMode(Graphics, 7);
          GdipCreatePath(0, Path);

          // Logika dynamicznego kształtu
          if Radius > 0 then
          begin
            D := Radius * 2;

            // Zabezpieczamy, żeby rogi nie były większe niż sam przycisk
            if D > (R.Right - R.Left) then D := R.Right - R.Left;
            if D > (R.Bottom - R.Top) then D := R.Bottom - R.Top;

            Angle180 := 180.0;
            Angle270 := 270.0;
            Angle0 := 0.0;
            Angle90 := 90.0;
            SweepAngle := 90.0;

            GdipAddPathArc(Path, R.Left, R.Top, D, D, Angle180, SweepAngle);
            GdipAddPathArc(Path, R.Right - D, R.Top, D, D, Angle270, SweepAngle);
            GdipAddPathArc(Path, R.Right - D, R.Bottom - D, D, D, Angle0, SweepAngle);
            GdipAddPathArc(Path, R.Left, R.Bottom - D, D, D, Angle90, SweepAngle);

            GdipClosePathFigure(Path);
          end
          else
          begin
             GdipAddPathRectangleI(Path, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top);
          end;

          // Pobieranie koloru przyciska
          BgColor := DWORD(GetPropW(HWnd, KP_COL_NORM));
          BgColor := color_to_argb(BgColor);

          // rysujemy tło przycisku (Zawsze)
          if GdipCreateSolidFill(BgColor, SolidBrush) = 0 then
          begin
            GdipFillPath(Graphics, SolidBrush, Path);
            GdipDeleteBrush(SolidBrush);
          end;

          // ==========================================
          // ZMIENIONY BLOK: SZYBKIE RYSOWANIE OBRAZKA
          // ==========================================
          if Image <> nil then
          begin
            // Używamy gotowego obrazka, który załadował się podczas create_image_button
            GdipCreateTexture(Image, 0, ImgBrush);
            GdipFillPath(Graphics, ImgBrush, Path); // Obrazek przykrywa tło
            GdipDeleteBrush(ImgBrush);
          end;
          // ==========================================

          IsHovered := GetPropW(HWnd, 'IsHovered') = 1;
          IsPressed := GetPropW(HWnd, 'IsPressed') = 1;

          if IsPressed then
          begin
            // WCIŚNIĘCIE: Półprzezroczysta CZERŃ (Alpha $33 = ~20% widoczności)
            if GdipCreateSolidFill($33000000, HoverBrush) = 0 then
            begin
              GdipFillPath(Graphics, HoverBrush, Path);
              GdipDeleteBrush(HoverBrush);
            end;
          end
          else if IsHovered then
          begin
            // NAJAZD: Półprzezroczysta BIEL (Alpha $1A = ~10% widoczności)
            if GdipCreateSolidFill($1AFFFFFF, HoverBrush) = 0 then
            begin
              GdipFillPath(Graphics, HoverBrush, Path);
              GdipDeleteBrush(HoverBrush);
            end;
          end;

          // sprzatanie
          GdipDeletePath(Path);
          GdipDeleteGraphics(Graphics);
        end;

        // Rysowanie tekstu
        HFontMain := CreateFontW(-17, 0, 0, 0, FW_NORMAL, 0, 0, 0, EASTEUROPE_CHARSET,
                                 0, 0, CLEARTYPE_QUALITY, 0, 'Segoe UI');
        HOldFont := SelectObject(DC, HFontMain);
        SetBkMode(DC, TRANSPARENT);
        SetTextColor(DC, $FFFFFF);

        GetWindowTextW(hWnd, Txt, 255);
        DrawTextW(DC, Txt, -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

        SelectObject(DC, HOldFont);
        DeleteObject(HFontMain);
      finally
        EndPaint(hWnd, PS);
      end;
      Exit(0);
    end;

    WM_MOUSELEAVE:
    begin
      // Mysz zjechała z przycisku
      SetPropW(HWnd, 'IsHovered', 0);
      SetPropW(HWnd, 'IsPressed', 0);
      InvalidateRect(HWnd, nil, False);
      Exit(0);
    end;



   WM_LBUTTONDOWN:
    begin
      SetPropW(HWnd, 'IsPressed', 1);
      //SetCapture(HWnd); // Przejmujemy mysz, żeby nie zgubić puszczenia przycisku
      InvalidateRect(HWnd, nil, False);
      Exit(0);
    end;

    WM_LBUTTONUP:
    begin
      IsPressed := GetPropW(HWnd, 'IsPressed') = 1;
      if IsPressed then
      begin
        SetPropW(HWnd, 'IsPressed', 0);
        InvalidateRect(HWnd, nil, False);
        //RemovePropW(HWnd, 'IsPressed');
        //ReleaseCapture;

        // Sprawdzamy, czy kursor myszy nadal jest nad przyciskiem
        GetClientRect(HWnd, R);
        Pt.X := SmallInt(LParam and $FFFF);
        Pt.Y := SmallInt(LParam shr 16);

        if PtInRect(R, Pt) then
        begin
          // KLUCZ: Pobieramy zdarzenie za pomocą Twojej stałej
          EventPtr := GetProp(HWnd, AV_PROP_ON_EVENT);
          if EventPtr <> 0 then
          begin
            OnClick := TAvocadoEvent(Pointer(EventPtr));
            OnClick(HWnd);
          end;
        end;

        InvalidateRect(HWnd, nil, False);
      end;
      Exit(0);
    end;

    WM_MOUSEMOVE:
    begin
      // Jeśli jeszcze nie śledzimy tego przycisku, włączamy śledzenie
      if GetPropW(HWnd, 'IsHovered') = 0 then
      begin
        SetPropW(HWnd, 'IsHovered', 1);

        // Konfiguracja struktury śledzącej
        TME.cbSize := SizeOf(TTRACKMOUSEEVENT);
        TME.dwFlags := TME_LEAVE;
        TME.hwndTrack := HWnd;
        TME.dwHoverTime := HOVER_DEFAULT;
        TrackMouseEvent(TME);

        InvalidateRect(HWnd, nil, False); // Wymusza przerysowanie (zaświecenie)
      end;
      Exit(0);
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'ImagePath');
      RemovePropW(hWnd, 'ImageHandle');
      RemovePropW(HWnd, 'IsPressed');
      RemovePropW(HWnd,  ROUNDING_COMP);

    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;


// obsługa okna (callback)
function AvocadoCustomButtonProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
PS: TPaintStruct;
DC: HDC;
R: TRect;
Pt: TPoint;
MyFont, HOldFont: HFONT;
MyBrush, HOldBrush: HBRUSH;
Pen, HOldPen: HPEN;
Txt: array[0..255] of WideChar;
BgCol, TxCol: DWORD;
IsHover, IsPressed: Boolean;
Radius: Integer;
EventPtr: THandle;
ColN, ColH, ColP, ColBorder: DWORD;
// Zmienne do obsługi ikony (PascalCase)
HBmp: HBITMAP;
MDC: HDC;
HOldBmp: HGDIOBJ;
BM: Windows.TBitmap;
IconX, IconY: Integer;
TextRect: TRect;
DestW, DestH, Padding: Integer;
OldStretchMode: Integer;
begin
  case Msg of
    WM_SETFONT:
    begin
      SetProp(hWnd, KP_FONT, THandle(WParam));
      if LParam <> 0 then InvalidateRect(hWnd, nil, True);
      Exit(0);
    end;

    WM_GETFONT:
    begin
      Result := GetProp(hWnd, KP_FONT);
      Exit;
    end;

    WM_PAINT:
    begin
    DC := BeginPaint(hWnd, PS);
      try
        GetClientRect(hWnd, R);
        TextRect := R; // Prostokąt pomocniczy do centrowania tekstu

        // 1. Pobieranie stanów i kolorów z właściwości okna
        IsHover   := GetProp(hWnd, KP_IS_HOVER) = 1;
        IsPressed := GetProp(hWnd, KP_IS_PRESS) = 1;

        ColN      := DWORD(GetProp(hWnd, KP_COL_NORM));
        ColH      := DWORD(GetProp(hWnd, KP_COL_HOVR));
        ColP      := DWORD(GetProp(hWnd, KP_COL_PRES));
        TxCol     := DWORD(GetProp(hWnd, KP_COL_TEXT));
        ColBorder := DWORD(GetProp(hWnd, KP_COL_BORDER));

        // Obsługa dynamicznej zmiany kolorów (jeśli przypisano zdarzenie)
        EventPtr := GetProp(hWnd, KP_ON_COLOR);
        if EventPtr <> 0 then
          TAvocadoColorEvent(Pointer(EventPtr))(hWnd, ColN, ColH, ColP);

        // Wybór koloru tła na podstawie stanu myszy
        if IsPressed then BgCol := ColP
        else if IsHover then BgCol := ColH
        else BgCol := ColN;

        // 2. RYSOWANIE TŁA PRZYCISKU
        Radius := Integer(GetProp(hWnd, KP_RADIUS));
        MyBrush := CreateSolidBrush(BgCol);
        HOldBrush := SelectObject(DC, MyBrush);

        if Radius > 0 then
        begin
          // Zaokrąglony prostokąt z obramowaniem
          Pen := CreatePen(PS_SOLID, 1, ColBorder);
          HOldPen := SelectObject(DC, Pen);
          RoundRect(DC, R.Left, R.Top, R.Right, R.Bottom, Radius, Radius);
          SelectObject(DC, HOldPen);
          DeleteObject(Pen);
        end
        else
        begin
          // Standardowy prostokąt (FillRect nie rysuje obramowania, używamy Rectangle jeśli trzeba)
          FillRect(DC, R, MyBrush);
        end;

        SelectObject(DC, HOldBrush);
        DeleteObject(MyBrush);

       // 3. RYSOWANIE IKONY (Z wygładzaniem HALFTONE!)
        HBmp := HBITMAP(GetPropW(hWnd, 'BtnIcon'));
        if HBmp <> 0 then
        begin
          if GetObject(HBmp, SizeOf(BM), @BM) <> 0 then
          begin
            MDC := CreateCompatibleDC(DC);
            HOldBmp := SelectObject(MDC, HBmp);

            Padding := (R.Bottom - R.Top) div 5;
            DestH := (R.Bottom - R.Top) - (Padding * 2);
            DestW := (BM.bmWidth * DestH) div BM.bmHeight;
            IconX := 15;
            IconY := Padding;

            // --- NOWOŚĆ: WŁĄCZAMY WYGŁADZANIE ---
            // Zapamiętujemy stary tryb i ustawiamy HALFTONE (najlepsza jakość w GDI)
            OldStretchMode := SetStretchBltMode(DC, HALFTONE);
            // Reset punktu odniesienia pędzla (wymagane dla poprawnego działania HALFTONE)
            SetBrushOrgEx(DC, 0, 0, nil);

            TransparentBlt(
              DC, IconX, IconY, DestW, DestH,
              MDC, 0, 0, BM.bmWidth, BM.bmHeight,
              $FFFFFF
            );

            // --- NOWOŚĆ: PRZYWRACAMY STARY TRYB ---
            SetStretchBltMode(DC, OldStretchMode);

            SelectObject(MDC, HOldBmp);
            DeleteDC(MDC);
          end;
        end;

        // 4. RYSOWANIE TEKSTU (Idealnie na środku)
        MyFont := HFONT(GetProp(hWnd, KP_FONT));
        if MyFont = 0 then MyFont := GetStockObject(DEFAULT_GUI_FONT);

        HOldFont := SelectObject(DC, MyFont);
        SetBkMode(DC, TRANSPARENT);
        SetTextColor(DC, TxCol);

        GetWindowTextW(hWnd, Txt, 255);
        // Używamy TextRect (cały obszar), aby flaga DT_CENTER wyliczyła matematyczny środek
        DrawTextW(DC, Txt, -1, TextRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

        SelectObject(DC, HOldFont);

      finally
        EndPaint(hWnd, PS);
      end;
      Exit(0);
    end;


    BM_SETIMAGE:
    begin
      SetPropW(hWnd, 'BtnIcon', THandle(LParam));
      InvalidateRect(hWnd, nil, True);
      Exit(LRESULT(0));
    end;

    WM_MOUSEMOVE: track_mouse_leave(hWnd);

    WM_MOUSELEAVE:
    begin
      SetPropW(hWnd, 'IsHover', 0);
      InvalidateRect(hWnd, nil, True);
    end;

    WM_LBUTTONDOWN:
    begin
      SetProp(hWnd, KP_IS_PRESS, 1);
      InvalidateRect(hWnd, nil, True);
      SetCapture(hWnd);
    end;

    WM_LBUTTONUP:
    begin
      if GetProp(hWnd, KP_IS_PRESS) = 1 then
      begin
        SetProp(hWnd, KP_IS_PRESS, 0);
        ReleaseCapture();
        InvalidateRect(hWnd, nil, True);
        GetClientRect(hWnd, R);
        GetCursorPos(Pt);
        ScreenToClient(hWnd, Pt);
        if PtInRect(R, Pt) then
          SendMessage(GetParent(hWnd), WM_COMMAND, MakeWParam(Word(GetDlgCtrlID(hWnd)), BN_CLICKED), PtrInt(hWnd));
      end;
    end;

    WM_NCDESTROY:
    begin
      RemoveProp(hWnd, KP_FONT);
      RemoveProp(hWnd, KP_COL_NORM);
      RemoveProp(hWnd, KP_COL_HOVR);
      RemoveProp(hWnd, KP_COL_PRES);
      RemoveProp(hWnd, KP_COL_TEXT);
      RemoveProp(hWnd, KP_RADIUS);
      RemoveProp(hWnd, KP_IS_HOVER);
      RemoveProp(hWnd, KP_IS_PRESS);
      RemoveProp(hWnd, KP_ON_COLOR);
      RemovePropW(hWnd, 'BtnIcon');
    end;
  end;
  Result := DefWindowProcW(hWnd, Msg, WParam, LParam);
end;

// funkcje publiczne

procedure set_on_color_btn(Handle: HWND; Event: TAvocadoColorEvent);
begin
  if Handle <> 0 then
  begin
    SetProp(Handle, KP_ON_COLOR, THandle(Pointer(Event)));
    // Odśwież od razu
    InvalidateRect(Handle, nil, True);
  end;
end;

function create_button(Parent: HWND; const Text: string; X, Y, Width, Height: Integer): HWND;
const
  ClassName = 'AvocadoCustomButton';
var
  WndClass: TWndClassExW;
  TempText: UnicodeString;
begin
  TempText := UnicodeString(Text);

  // Rejestracja klasy
  if not GetClassInfoExW(HInstance, ClassName, @WndClass) then
  begin
    FillChar(WndClass, SizeOf(WndClass), 0);
    WndClass.cbSize := SizeOf(TWndClassExW);
    WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS;
    WndClass.lpfnWndProc := @AvocadoCustomButtonProc;
    WndClass.hInstance := HInstance;
    WndClass.hCursor := LoadCursor(0, IDC_HAND);
    WndClass.hbrBackground := 0;
    WndClass.lpszClassName := ClassName;
    RegisterClassExW(WndClass);
  end;

  // Tworzenie okna
  Result := CreateWindowExW(
    0,
    ClassName,
    PWideChar(TempText),
    WS_VISIBLE or WS_CHILD or WS_TABSTOP,
    X, Y, Width, Height,
    Parent,
    0,
    HInstance,
    nil
  );

  // Domyślne kolory
  if Result <> 0 then
  begin
    set_button_colors(Result, $E0E0E0, $C0C0C0, $A0A0A0, $000000,$2D2D2D);
  end;
end;

function create_image_button(parent_wnd: HWND; const text, image_path: UnicodeString; x, y, width, height: Integer): HWND;
const
  class_name = 'AvocadoImageButton';
var
  wnd_class: TWndClassExW;
  h_btn: HWND;
  img: Pointer;
begin
  if not GetClassInfoExW(HInstance, class_name, @wnd_class) then
  begin
    FillChar(wnd_class, SizeOf(wnd_class), 0);
    wnd_class.cbSize := SizeOf(TWndClassExW);
    wnd_class.style := CS_HREDRAW or CS_VREDRAW;
    wnd_class.lpfnWndProc := @AvocadoImageButtonProc;
    wnd_class.hInstance := HInstance;
    wnd_class.hCursor := LoadCursor(0, IDC_HAND);
    wnd_class.lpszClassName := class_name;
    RegisterClassExW(wnd_class);
  end;

  // 1. ŁADUJEMY OBRAZEK OD RAZU!
  img := nil;
  // Jeśli podano ścieżkę, GDI+ ładuje plik i zapisuje wskaźnik do 'img'
  if Length(image_path) > 0 then
    GdipLoadImageFromFile(PWideChar(image_path), img);

  // 2. Tworzenie okna
  h_btn := CreateWindowExW(0, class_name, PWideChar(text),
    WS_VISIBLE or WS_CHILD or WS_TABSTOP,
    x, y, width, height, parent_wnd, 0, HInstance, nil);

  if h_btn <> 0 then
  begin
    // 3. Zapisujemy GOTOWY OBRAZEK do okna pod nazwą 'GdipImg' (tak samo jak w image_box)
    SetPropW(h_btn, 'GdipImg', THandle(img));
  end
  else
  begin
    // Zabezpieczenie: jeśli okno się nie stworzyło, a obrazek się załadował - usuwamy z pamięci
    if img <> nil then
      GdipDisposeImage(img);
  end;

  Result := h_btn;
end;

procedure set_button_colors(Handle: HWND; Normal, Hover, Pressed, Text, borderColor: DWORD);
begin
  if Handle <> 0 then
  begin
    SetProp(Handle, KP_COL_NORM, THandle(Normal));
    SetProp(Handle, KP_COL_HOVR, THandle(Hover));
    SetProp(Handle, KP_COL_PRES, THandle(Pressed));
    SetProp(Handle, KP_COL_TEXT, THandle(Text));
    //Kolor border
    SetProp(Handle, KP_COL_BORDER, THandle(borderColor));
    InvalidateRect(Handle, nil, True);
  end;
end;

procedure set_button_radius(Handle: HWND; Radius: Integer);
begin
  if Handle <> 0 then
  begin
    SetProp(Handle, KP_RADIUS, THandle(Radius));
    InvalidateRect(Handle, nil, True);
  end;
end;

procedure set_button_id(ButtonHandle: HWND; NewID: Integer);
begin
  if ButtonHandle <> 0 then
    SetWindowLongPtrW(ButtonHandle, GWLP_ID, NewID);
end;


end.

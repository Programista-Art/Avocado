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

Module:     avoraiser.gdi
Description:
*)
unit avoraiser.gdi;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,avoraiser.core, avoraiser.utils;

type
  // Struktura przechowująca stan wirtualnego bufora
  TDoubleBufferState = record
    OriginalDC: HDC;
    MemDC: HDC;
    MemBitmap: HBITMAP;
    OldBitmap: HGDIOBJ;
    Width: Integer;
    Height: Integer;
  end;
type
  GpStatus = Integer;
  GpGraphics = Pointer;
  GpPen = Pointer;
  GpBrush = Pointer;
  GpImage = Pointer;
  GpPath = Pointer;
  FillMode = Integer;

TGdiplusStartupInput = record
  GdiplusVersion: Cardinal;
  DebugEventCallback: Pointer;
  SuppressBackgroundThread: LongBool;
  SuppressExternalCodecs: LongBool;
  end;

type
GpRect = record
  X, Y, Width, Height: Integer;
end;
PGpRect = ^GpRect;

// Rysuje sam obrys prostokąta (pusty w środku)
procedure draw_rectangle(Window: HWND; X, Y, W, H: Integer; Color: DWORD; TargetDC: HDC = 0);
// Rysuje wypełniony prostokąt (bez obrysu lub z obrysem w tym samym kolorze)
procedure draw_fill_rectangle(Window: HWND; X, Y, W, H: Integer; Color: DWORD; TargetDC: HDC = 0);
// Tworzy trwałą ramkę (pusta w środku)
function create_frame(Parent: HWND; X, Y, W, H: Integer; Color: DWORD; Thickness: Integer = 1): HWND;
// Rysowanie linii znika
procedure draw_line(Window: HWND; X1, Y1, X2, Y2: Integer; Color: DWORD; TargetDC: HDC = 0);
//Rysowanie Linii nie znika
function create_line(Parent: HWND; X1, Y1, X2, Y2: Integer; Color: DWORD; Thickness: Integer = 1): HWND;
// Tworzy pełne, kolorowe koło
function create_circle_filled(Parent: HWND; X, Y, Diameter: Integer; Color: DWORD): HWND;
// Tworzy sam obrys koła (puste w środku)
function create_circle_outline(Parent: HWND; X, Y, Diameter: Integer; Color: DWORD; Thickness: Integer = 1): HWND;
//Obrazek w kolo
function create_circle_image(Parent: HWND; FilePath: UnicodeString; X, Y, Size: Integer): HWND;
function create_polyline_box(Parent: HWND; X, Y, W, H: Integer; const Points: array of TPoint; Color: DWORD; Thickness: Integer): HWND;
// Obrazki
function create_image_box(Parent: HWND; FilePath: UnicodeString; X, Y, W, H: Integer): HWND;
//Tworzy gradient
function create_gradient_panel(Parent: HWND; X, Y, W, H: Integer; ColorStart, ColorEnd: DWORD; Direction: Integer = 1): HWND;
function create_rounded_panel(Parent: HWND; X, Y, W, H: Integer; Color: DWORD; Radius: Integer): HWND;
function create_rotated_image(Parent: HWND; FilePath: UnicodeString; X, Y, W, H: Integer; InitialAngle: Integer = 0): HWND;
//Zmiana kąta w locie (np. animacja)
procedure set_image_angle(hImg: HWND; Angle: Integer);
// Usuwa dowolny obiekt graficzny (kółko, linię, obrazek, panel) i zwalnia pamięć
function delete_object(hObject: HWND): Boolean;
procedure draw_polyline(Window: HWND; const Points: array of TPoint; Color: DWORD; Thickness: Integer; TargetDC: HDC);
// Tworzy strukturę TPoint w locie (zastępuje funkcję z modułu Classes)
function point(X, Y: Integer): TPoint; inline;
// Tworzy obiekt zamkniętego wielokąta (np. trójkąta) wypełnionego kolorem
function create_polygon_box(Parent: HWND; X, Y, W, H: Integer; const Points: array of TPoint; FillColor: DWORD): HWND;
// Szybkie kopiowanie bloku pikseli 1:1 (odpowiednik BitBlt)
function copy_pixels(DestDC: HDC; DestX, DestY, W, H: Integer; SrcDC: HDC; SrcX, SrcY: Integer): Boolean;
// Kopiowanie ze skalowaniem (odpowiednik StretchBlt)
function stretch_pixels(DestDC: HDC; DestX, DestY, DestW, DestH: Integer; SrcDC: HDC; SrcX, SrcY, SrcW, SrcH: Integer): Boolean;
// Szybkie wypełnianie z użyciem operacji bitowych (odpowiednik PatBlt)
// Rop = Raster Operation (np. PATCOPY, DSTINVERT)
procedure fill_pattern(DC: HDC; X, Y, W, H: Integer; Rop: DWORD = PATCOPY);
// Rozpoczyna rysowanie w pamięci RAM (poza ekranem)
function begin_double_buffer(TargetDC: HDC; const R: TRect): TDoubleBufferState;
// Kończy rysowanie, przerzuca obraz na ekran i sprząta pamięć
procedure end_double_buffer(var State: TDoubleBufferState);
// Zmienia kolor rysowanego tekstu na danym DC
procedure set_text_color(DC: HDC; Color: DWORD);
// Ustawia tryb tła pod tekstem (True = przezroczyste, False = zamalowane kolorem tła)
procedure set_bk_mode(DC: HDC; IsTransparent: Boolean);
// rysowanie tekstu
// Szybkie rysowanie tekstu w jednym rzędzie (odpowiednik TextOut)
procedure draw_text_simple(DC: HDC; X, Y: Integer; Text: UnicodeString);
// Zaawansowane rysowanie w prostokącie (odpowiednik DrawText)
// Obsługuje zawijanie wierszy, wyrównanie do prawej/środka i ucinanie z "..."
procedure draw_text_advanced(DC: HDC; var R: TRect; Text: UnicodeString; Flags: Cardinal = DT_LEFT or DT_TOP or DT_SINGLELINE);
procedure draw_text_custom(DC: HDC; X, Y: Integer; Text: UnicodeString; Color: DWORD; TransparentBk: Boolean = True);
// Rysuje pojedynczy punkt na podanych współrzędnych
procedure set_pixel(DC: HDC; X, Y: Integer; Color: DWORD);
// Pobiera kolor piksela z podanych współrzędnych (zwraca wartość DWORD / COLORREF)
function get_pixel(DC: HDC; X, Y: Integer): DWORD;
// Oblicza szerokość i wysokość tekstu w pikselach dla aktualnej czcionki na DC
procedure get_text_size(DC: HDC; const Text: UnicodeString; out Width, Height: Integer);
function load_button_icon(const filename: UnicodeString): HBITMAP;
//function gdiplus_init: Boolean;
procedure gdiplus_shutdown;
procedure draw_image(h_dc: HDC; x, y, width, height: Integer; const image_path: UnicodeString);
procedure draw_smooth_rounded_rect(Graphics: Pointer; Rect: TRect; Radius: Integer; Color: DWORD);
//Pobiera rozmiar obrazka
function get_image_size(const file_path: UnicodeString; out width, height: Integer): Boolean;



function GdipResetClip(Graphics: Pointer): Integer; stdcall; external 'gdiplus.dll';
function GdipCreateTexture(Image: Pointer; WrapMode: Integer; out Brush: Pointer): Integer; stdcall; external 'gdiplus.dll';
function GdipAddPathEllipseI(Path: Pointer; X, Y, Width, Height: Integer): Integer; stdcall; external 'gdiplus.dll';
function GdipAddPathRectangleI(Path: Pointer; X, Y, Width, Height: Integer): Integer; stdcall; external 'gdiplus.dll';



function GdiplusStartup(out token: ULONG_PTR; const input: TGdiplusStartupInput; output: Pointer): Integer; stdcall; external 'gdiplus.dll';
procedure GdiplusShutdown(token: ULONG_PTR); stdcall; external 'gdiplus.dll';
function GdipCreateFromHDC(hdc: HDC; out graphics: Pointer): Integer; stdcall; external 'gdiplus.dll';
function GdipDeleteGraphics(graphics: Pointer): Integer; stdcall; external 'gdiplus.dll';



function GdipFillPolygonI(graphics: GpGraphics; brush: GpBrush; points: Pointer; count: Integer; fillMode: Integer): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDrawPolygonI(graphics: GpGraphics; pen: GpPen; points: Pointer; count: Integer): GpStatus; stdcall; external 'gdiplus.dll';
function GdipCreatePath(brushMode: FillMode; out path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDeletePath(path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';
function GdipResetPath(path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';
function GdipAddPathArcI(path: GpPath; x, y, width, height: Integer; startAngle, sweepAngle: Single): GpStatus; stdcall; external 'gdiplus.dll';
function GdipClosePathFigure(path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';
function GdipFillPath(graphics: GpGraphics; brush: GpBrush; path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';




// Importujemy funkcje bezpośrednio z DLL, żeby nie wymagać zewnętrznych modułów
function GdiplusStartup(out Token: ULONG_PTR; Input: Pointer; Output: Pointer): GPStatus; stdcall; external 'gdiplus.dll';
//function GdiplusStartup(out token: PtrUInt; input: Pointer; output: Pointer): GpStatus; stdcall; external 'gdiplus.dll';

//function GdipSetSmoothingMode(graphics: GpGraphics; mode: Integer): GpStatus; stdcall; external 'gdiplus.dll';
 //nowe
function GdipSetSmoothingMode(Graphics: Pointer; Mode: Integer): GPStatus; stdcall; external 'gdiplus.dll';
function GdipSetPixelOffsetMode(Graphics: Pointer; Mode: Integer): GPStatus; stdcall; external 'gdiplus.dll';

function GdipDrawLineI(graphics: GpGraphics; pen: GpPen; x1, y1, x2, y2: Integer): GpStatus; stdcall; external 'gdiplus.dll';
// Pędzle i Pióra
function GdipCreateSolidFill(color: DWORD; out brush: GpBrush): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDeleteBrush(brush: GpBrush): GpStatus; stdcall; external 'gdiplus.dll';
function GdipCreatePen1(color: DWORD; width: Single; unit_: Integer; out pen: GpPen): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDeletePen(pen: GpPen): GpStatus; stdcall; external 'gdiplus.dll';

// Rysowanie
function GdipFillEllipseI(graphics: GpGraphics; brush: GpBrush; x, y, width, height: Integer): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDrawEllipseI(graphics: GpGraphics; pen: GpPen; x, y, width, height: Integer): GpStatus; stdcall; external 'gdiplus.dll';

// Ładowanie i usuwanie obrazków
function GdipLoadImageFromFile(filename: PWideChar; out image: GpImage): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDisposeImage(image: GpImage): GpStatus; stdcall; external 'gdiplus.dll';
// Do transformacji Obracanie
function GdipRotateWorldTransform(graphics: GpGraphics; angle: Single; order: Integer): GpStatus; stdcall; external 'gdiplus.dll';
function GdipDrawImageRectI(graphics: GpGraphics; image: GpImage; x, y, width, height: Integer): GpStatus; stdcall; external 'gdiplus.dll';
function GdipTranslateWorldTransform(graphics: GpGraphics; dx, dy: Single; order: Integer): GpStatus; stdcall; external 'gdiplus.dll';

function GdipAddPathArc(Path: Pointer; X, Y, Width, Height, StartAngle, SweepAngle: Single): Integer; stdcall; external 'gdiplus.dll';
function GdipGetImageWidth(image: GpImage; out width: Cardinal): GpStatus; stdcall; external 'gdiplus.dll';
function GdipGetImageHeight(image: GpImage; out height: Cardinal): GpStatus; stdcall; external 'gdiplus.dll';
// Import funkcji tworzącej pędzel gradientowy
function GdipCreateLineBrushFromRectI(rect: PGpRect; color1, color2: DWORD; mode: Integer; wrapMode: Integer; out brush: GpBrush): GpStatus; stdcall; external 'gdiplus.dll';
// Import funkcji wypełniającej prostokąt
function GdipFillRectangleI(graphics: GpGraphics; brush: GpBrush; x, y, width, height: Integer): GpStatus; stdcall; external 'gdiplus.dll';
// Import do rysowania wielu połączonych linii na raz
function GdipDrawLinesI(graphics: GpGraphics; pen: GpPen; points: PPoint; count: Integer): GpStatus; stdcall; external 'gdiplus.dll';


//function GdipSetPixelOffsetMode(Graphics: Pointer; Mode: Integer): GPStatus; stdcall; external 'gdiplus.dll';
// Opcjonalnie do ramki:
function GdipDrawPath(graphics: GpGraphics; pen: GpPen; path: GpPath): GpStatus; stdcall; external 'gdiplus.dll';

// Do przycinania Avatary
function GdipSetClipPath(graphics: GpGraphics; path: GpPath; mode: Integer): GpStatus; stdcall; external 'gdiplus.dll';

implementation
const
  // Tryb wysokiej jakości
  SmoothingModeAntiAlias = 4;
  LinearGradientModeHorizontal = 0;
  LinearGradientModeVertical = 1;
  LinearGradientModeForwardDiagonal = 2; // Ukośny \
  LinearGradientModeBackwardDiagonal = 3; // Ukośny /
  WrapModeTile = 0;
  FillModeAlternate = 0;
  CombineModeReplace = 0;
  MatrixOrderPrepend = 0;
  MatrixOrderAppend = 1;

  // Tryby wygładzania (SmoothingMode)
  SmoothingModeNone = 0;
  SmoothingModeHighSpeed = 1;
  //SmoothingModeAntiAlias = 2;
  SmoothingModeHighQuality = 2;

  // Tryby przesunięcia pikseli (PixelOffsetMode) - ważne dla precyzji krawędzi
  PixelOffsetModeDefault = 0;
  PixelOffsetModeHighSpeed = 1;
  PixelOffsetModeHighQuality = 2;
  PixelOffsetModeHalf = 4;



var
  //gdiplusToken: PtrUInt;
  StartupInput: TGdiplusStartupInput;
  GdiplusToken: ULONG_PTR;



  // Funkcje do obsługi ścieżek (Path)
  //function GdipSetClipPath(Graphics, Path: Pointer; CombineMode: Integer): Integer; stdcall; external 'gdiplus.dll';
  //function GdipResetClip(Graphics: Pointer): Integer; stdcall; external 'gdiplus.dll';


  // Konwersja koloru WinAPI ($00BBGGRR) na GDI+ ARGB ($AARRGGBB)
function ColorRefToARGB(Color: DWORD): DWORD;
var
  R, G, B: Byte;
begin
  // Rozbijamy WinAPI Color
  R := Color and $FF;
  G := (Color shr 8) and $FF;
  B := (Color shr 16) and $FF;
  // Składamy ARGB (Alpha = 255/FF - pełna widoczność)
  Result := ($FF shl 24) or (R shl 16) or (G shl 8) or B;
end;

// Pomocnik: Tworzy kształt zaokrąglonego prostokąta w pamięci
procedure MakeRoundedPath(Path: GpPath; R: TRect; Diameter: Integer);
begin
  // GDI+ sam łączy dodawane łuki liniami prostymi.
  // Kolejność: Lewy-Góra -> Prawy-Góra -> Prawy-Dół -> Lewy-Dół

  // 1. Lewy Górny Róg
  GdipAddPathArcI(Path, R.Left, R.Top, Diameter, Diameter, 180, 90);

  // 2. Prawy Górny Róg
  GdipAddPathArcI(Path, R.Right - Diameter, R.Top, Diameter, Diameter, 270, 90);

  // 3. Prawy Dolny Róg
  GdipAddPathArcI(Path, R.Right - Diameter, R.Bottom - Diameter, Diameter, Diameter, 0, 90);

  // 4. Lewy Dolny Róg
  GdipAddPathArcI(Path, R.Left, R.Bottom - Diameter, Diameter, Diameter, 90, 90);

  // Zamknij figurę (połącz ostatni punkt z pierwszym)
  GdipClosePathFigure(Path);
end;

function polygon_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Brush: GpBrush;
  Color: DWORD;
  PtsPtr: Pointer;
  PtsCount: Integer;
  ARGB: DWORD;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        Color := DWORD(GetPropW(hWnd, 'PolyCol'));
        PtsPtr := Pointer(GetPropW(hWnd, 'PolyPts'));
        PtsCount := Integer(GetPropW(hWnd, 'PolyCnt'));

        // Poligon potrzebuje minimum 3 punktów (trójkąt)
        if (PtsPtr <> nil) and (PtsCount >= 3) then
        begin
          ARGB := ColorRefToARGB(Color);

          if GdipCreateFromHDC(DC, Graphics) = 0 then
          begin
            GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);
            GdipCreateSolidFill(ARGB, Brush);

            // Rysujemy wypełniony wielokąt.
            // 0 na końcu to FillModeAlternate (domyślny tryb wypełniania dla GDI+)
            GdipFillPolygonI(Graphics, Brush, PtsPtr, PtsCount, 0);

            GdipDeleteBrush(Brush);
            GdipDeleteGraphics(Graphics);
          end;
        end;
      finally
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
      // Zwalnianie zaalokowanej pamięci RAM
      PtsPtr := Pointer(GetPropW(hWnd, 'PolyPts'));
      if PtsPtr <> nil then FreeMem(PtsPtr);

      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'PolyCol');
      RemovePropW(hWnd, 'PolyPts');
      RemovePropW(hWnd, 'PolyCnt');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

function polyline_proc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Pen: GpPen;
  Color: DWORD;
  Thickness: Integer;
  PtsPtr: Pointer;
  PtsCount: Integer;
  ARGB: DWORD;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        // Pobieramy dane zapisane w oknie
        Color := DWORD(GetPropW(hWnd, 'PolyCol'));
        Thickness := Integer(GetPropW(hWnd, 'PolyThick'));
        PtsPtr := Pointer(GetPropW(hWnd, 'PolyPts')); // Nasz wskaźnik do pamięci RAM
        PtsCount := Integer(GetPropW(hWnd, 'PolyCnt'));

        // Jeśli mamy punkty i jest ich co najmniej 2
        if (PtsPtr <> nil) and (PtsCount >= 2) then
        begin
          ARGB := ColorRefToARGB(Color);

          if GdipCreateFromHDC(DC, Graphics) = 0 then
          begin
            GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias); // Gładkie łuki
            GdipCreatePen1(ARGB, Thickness, 2, Pen);

            // Rysujemy linie, podając wskaźnik do naszej zaalokowanej pamięci
            GdipDrawLinesI(Graphics, Pen, PtsPtr, PtsCount);

            GdipDeletePen(Pen);
            GdipDeleteGraphics(Graphics);
          end;
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
       Result := 1; // Pudełko musi być przezroczyste, by widać było tło pod wykresem
       Exit;
    end;

    WM_NCDESTROY:
    begin
      // KLUCZOWE: Musimy uwolnić pamięć RAM, żeby nie było wycieku!
      PtsPtr := Pointer(GetPropW(hWnd, 'PolyPts'));
      if PtsPtr <> nil then FreeMem(PtsPtr);

      // Usuwamy właściwości
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'PolyCol');
      RemovePropW(hWnd, 'PolyThick');
      RemovePropW(hWnd, 'PolyPts');
      RemovePropW(hWnd, 'PolyCnt');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;


function CircleImageProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Img: GpImage;
  Path: GpPath;
  R: TRect;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);
        Img := GpImage(GetPropW(hWnd, 'GdipImg'));

        if (Img <> nil) and (GdipCreateFromHDC(DC, Graphics) = 0) then
        begin
          // Antyaliasing (żeby krawędzie koła były gładkie)
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);

          // 1. Tworzymy koło w pamięci (Path)
          if GdipCreatePath(FillModeAlternate, Path) = 0 then
          begin
             GdipAddPathArcI(Path, 0, 0, R.Right, R.Bottom, 0, 360);

             // 2. Ustawiamy to koło jako OBSZAR PRZYCINANIA (Clip)
             // Wszystko narysowane po tej komendzie będzie widoczne TYLKO wewnątrz koła
             GdipSetClipPath(Graphics, Path, CombineModeReplace);

             // 3. Rysujemy obrazek (normalnie, jako prostokąt)
             // GDI+ utnie rogi automatycznie
             GdipDrawImageRectI(Graphics, Img, 0, 0, R.Right, R.Bottom);

             // Opcjonalnie: Rysujemy ramkę dookoła (Border)
             // GdipDrawPath(...) - jeśli potrzebujesz

             GdipDeletePath(Path);
          end;

          GdipDeleteGraphics(Graphics);
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
       Result := 1; // Przezroczystość rogów
       Exit;
    end;

    WM_NCDESTROY:
    begin
      Img := GpImage(GetPropW(hWnd, 'GdipImg'));
      if Img <> nil then GdipDisposeImage(Img);
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'GdipImg');
    end;
  end;
  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

function RotateImageProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Img: GpImage;
  R: TRect;
  Angle: Single;
  CenterX, CenterY: Single;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);
        Img := GpImage(GetPropW(hWnd, 'GdipImg'));
        // Pobieramy kąt obrotu (jako Integer, rzutowany na Single w logice)
        Angle := Integer(GetPropW(hWnd, 'ImgAngle'));

        if (Img <> nil) and (GdipCreateFromHDC(DC, Graphics) = 0) then
        begin
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias); // Ważne przy obrocie, żeby nie było schodków

          // Obliczamy środek kontrolki
          CenterX := R.Right / 2.0;
          CenterY := R.Bottom / 2.0;

          // 1. Przesuwamy punkt początkowy układu współrzędnych na środek obrazka
          GdipTranslateWorldTransform(Graphics, CenterX, CenterY, MatrixOrderPrepend);

          // 2. Obracamy układ współrzędnych
          GdipRotateWorldTransform(Graphics, Angle, MatrixOrderPrepend);

          // 3. Cofamy przesunięcie (rysowanie odbywa się względem nowego środka)
          // Rysujemy obrazek tak, żeby jego środek wypadł w punkcie 0,0
          GdipTranslateWorldTransform(Graphics, -CenterX, -CenterY, MatrixOrderPrepend);

          // Rysowanie
          GdipDrawImageRectI(Graphics, Img, 0, 0, R.Right, R.Bottom);

          GdipDeleteGraphics(Graphics);
        end;
      finally
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
      Img := GpImage(GetPropW(hWnd, 'GdipImg'));
      if Img <> nil then GdipDisposeImage(Img);
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'GdipImg');
      RemovePropW(hWnd, 'ImgAngle');
    end;
  end;
  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

function RoundedProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Brush: GpBrush;
  Path: GpPath;
  R: TRect;
  Color: DWORD;
  Radius, Diameter: Integer;
  ARGB: DWORD;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);
        Color := DWORD(GetPropW(hWnd, 'RndColor'));
        Radius := Integer(GetPropW(hWnd, 'RndRadius'));

        // Zabezpieczenie: Średnica nie może być większa niż wymiar okna
        Diameter := Radius * 2;
        if Diameter > R.Right then Diameter := R.Right;
        if Diameter > R.Bottom then Diameter := R.Bottom;

        ARGB := ColorRefToARGB(Color);

        if GdipCreateFromHDC(DC, Graphics) = 0 then
        begin
          // Antyaliasing to podstawa przy łukach!
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);

          // 1. Tworzymy ścieżkę
          if GdipCreatePath(FillModeAlternate, Path) = 0 then
          begin
            // 2. Rysujemy kształt w pamięci
            // Odejmujemy 1px od szerokości/wysokości, żeby antyaliasing nie uciął krawędzi
            R.Right := R.Right - 1;
            R.Bottom := R.Bottom - 1;
            MakeRoundedPath(Path, R, Diameter);

            // 3. Wypełniamy kolorem
            GdipCreateSolidFill(ARGB, Brush);
            GdipFillPath(Graphics, Brush, Path);

            // Sprzątanie
            GdipDeleteBrush(Brush);
            GdipDeletePath(Path);
          end;

          GdipDeleteGraphics(Graphics);
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
       // Ważne: Rogi poza zaokrągleniem muszą być przezroczyste!
       Result := 1;
       Exit;
    end;

    WM_SIZE: InvalidateRect(hWnd, nil, False); // Przerysuj przy zmianie rozmiaru

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'RndColor');
      RemovePropW(hWnd, 'RndRadius');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

function GradientProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Brush: GpBrush;
  R: TRect;
  GpR: GpRect; // Prostokąt dla GDI+
  Col1, Col2: DWORD;
  Mode: Integer;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);

        // Pobieramy kolory i konwertujemy na ARGB
        Col1 := ColorRefToARGB(DWORD(GetPropW(hWnd, 'GradCol1')));
        Col2 := ColorRefToARGB(DWORD(GetPropW(hWnd, 'GradCol2')));
        Mode := Integer(GetPropW(hWnd, 'GradMode'));

        // Inicjalizacja GDI+
        if GdipCreateFromHDC(DC, Graphics) = 0 then
        begin
          // Przygotowujemy prostokąt pędzla (musi pokrywać cały obszar)
          GpR.X := 0;
          GpR.Y := 0;
          GpR.Width := R.Right;
          GpR.Height := R.Bottom;

          // 1. Tworzymy pędzel gradientowy
          // GDI+ sam obliczy przejścia kolorów w zadanym prostokącie
          if GdipCreateLineBrushFromRectI(@GpR, Col1, Col2, Mode, WrapModeTile, Brush) = 0 then
          begin
             // 2. Wypełniamy całe okno tym pędzlem
             GdipFillRectangleI(Graphics, Brush, 0, 0, R.Right, R.Bottom);

             // 3. Usuwamy pędzel
             GdipDeleteBrush(Brush);
          end;

          // Usuwamy grafikę
          GdipDeleteGraphics(Graphics);
        end;

      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    // Przeciwdziałanie migotaniu (flickering) przy zmianie rozmiaru
    WM_ERASEBKGND:
    begin
       Result := 1;
       Exit;
    end;

    WM_SIZE:
    begin
       // Gdy zmieniamy rozmiar panelu, gradient musi być przeliczony na nowo
       // (inaczej zostałby rozciągnięty jak obrazek). Wymuszamy repaint.
       InvalidateRect(hWnd, nil, False);
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'GradCol1');
      RemovePropW(hWnd, 'GradCol2');
      RemovePropW(hWnd, 'GradMode');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

function ImageProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  Graphics: GpGraphics;
  Img: GpImage;
  R: TRect;
  OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);

        // Pobieramy wskaźnik na załadowany obrazek
        Img := GpImage(GetPropW(hWnd, 'GdipImg'));

        if Img <> nil then
        begin
          if GdipCreateFromHDC(DC, Graphics) = 0 then
          begin
            // Ustawiamy wysoką jakość skalowania (opcjonalne, ale zalecane)
            // GdipSetInterpolationMode(Graphics, HighQualityBicubic);

            // Rysujemy obrazek rozciągnięty na całą kontrolkę
            GdipDrawImageRectI(Graphics, Img, 0, 0, R.Right, R.Bottom);

            GdipDeleteGraphics(Graphics);
          end;
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
       Result := 1; // Przezroczystość tła (dla PNG z kanałem alpha)
       Exit;
    end;

    WM_NCDESTROY:
    begin
      // WAŻNE: Musimy zwolnić obrazek z pamięci przy zamykaniu okna!
      Img := GpImage(GetPropW(hWnd, 'GdipImg'));
      if Img <> nil then GdipDisposeImage(Img);

      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'GdipImg');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;


// Onsluga kola
function CircleProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
ps: TPaintStruct;
DC: HDC;
Graphics: GpGraphics;
Pen: GpPen;
Brush: GpBrush;
R: TRect;
Color: DWORD;
Thickness: Integer;
IsFilled: Boolean;
ARGB: DWORD;
OldProc: WNDPROC;
begin
 OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);

        // Pobieramy właściwości
        Color := DWORD(GetPropW(hWnd, 'CirColor'));
        Thickness := Integer(GetPropW(hWnd, 'CirThick'));
        IsFilled := (GetPropW(hWnd, 'CirFill') = 1);

        // Konwertujemy kolor na format GDI+
        ARGB := ColorRefToARGB(Color);

        // 1. Inicjalizacja Grafiki GDI+ na tym DC
        if GdipCreateFromHDC(DC, Graphics) = 0 then
        begin
          // 2. WŁĄCZAMY WYGŁADZANIE (Antialiasing)
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);

          if IsFilled then
          begin
            // Wypełnienie
            GdipCreateSolidFill(ARGB, Brush);
            // GDI+ rysuje idealnie od krawędzi, ale dla pewności odejmujemy 1px
            GdipFillEllipseI(Graphics, Brush, 0, 0, R.Right - 1, R.Bottom - 1);
            GdipDeleteBrush(Brush);
          end
          else
          begin
            // Obrys
            // Unit 2 = Pixel. Tworzymy pióro o zadanej grubości
            GdipCreatePen1(ARGB, Thickness, 2, Pen);

            // Korekta: GDI+ rysuje obrys "na linii", więc połowa grubości wychodzi poza obszar.
            // Musimy wsunąć rysunek do środka o połowę grubości.
            GdipDrawEllipseI(Graphics, Pen,
              Thickness div 2,
              Thickness div 2,
              R.Right - Thickness - 1,
              R.Bottom - Thickness - 1);

            GdipDeletePen(Pen);
          end;

          // Sprzątamy Grafikę
          GdipDeleteGraphics(Graphics);
        end;

      finally
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
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'CirColor');
      RemovePropW(hWnd, 'CirThick');
      RemovePropW(hWnd, 'CirFill');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;
// Procedura obsługi Linii
function LineProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
ps: TPaintStruct;
DC: HDC;
Graphics: GpGraphics;
Pen: GpPen;
R: TRect;
Color: DWORD;
Thickness, Direction: Integer;
ARGB: DWORD;
OldProc: WNDPROC;
begin
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);

        // Pobieramy parametry
        Color := DWORD(GetPropW(hWnd, 'LineColor'));
        Thickness := Integer(GetPropW(hWnd, 'LineThick'));
        Direction := Integer(GetPropW(hWnd, 'LineDir')); // 0: (\), 1: (/)

        // Konwersja koloru na GDI+
        ARGB := ColorRefToARGB(Color);

        // 1. Inicjalizacja GDI+
        if GdipCreateFromHDC(DC, Graphics) = 0 then
        begin
          // 2. Włączamy ANTYALIASING (To sprawia, że linia jest gładka)
          GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);

          // 3. Tworzymy pióro
          GdipCreatePen1(ARGB, Thickness, 2, Pen);

          // 4. Rysujemy linię zależnie od kierunku
          if Direction = 0 then
          begin
             // Kierunek: Lewy-Góra -> Prawy-Dół (\)
             GdipDrawLineI(Graphics, Pen, 0, 0, R.Right, R.Bottom);
          end
          else
          begin
             // Kierunek: Lewy-Dół -> Prawy-Góra (/)
             GdipDrawLineI(Graphics, Pen, 0, R.Bottom, R.Right, 0);
          end;

          // Sprzątanie
          GdipDeletePen(Pen);
          GdipDeleteGraphics(Graphics);
        end;
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
       Result := 1; // Przezroczystość tła
       Exit;
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'LineColor');
      RemovePropW(hWnd, 'LineThick');
      RemovePropW(hWnd, 'LineDir');
    end;
  end;
  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;
// Procedura obsługi ramki - rysuje się sama w WM_PAINT
function FrameProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  ps: TPaintStruct;
  DC: HDC;
  R: TRect;
  Brush: HBRUSH;
  Color: DWORD;
  Thickness: Integer;
  OldProc: WNDPROC;
begin
  // Pobieramy starą procedurę, żeby wszystko działało stabilnie
  OldProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, ps);
      try
        GetClientRect(hWnd, R);
        Color := DWORD(GetPropW(hWnd, AV_PROP_BG_COLOR)); // Używamy bg_color jako koloru ramki
        Thickness := Integer(GetPropW(hWnd, 'FrameThick'));
        if Thickness = 0 then Thickness := 1;

        // Rysujemy ramkę funkcją systemową FrameRect (szybka!)
        // Ale FrameRect używa pędzla
        Brush := CreateSolidBrush(Color);

        // Górna belka
        R.Bottom := Thickness;
        FillRect(DC, R, Brush);

        // Dolna belka
        GetClientRect(hWnd, R);
        R.Top := R.Bottom - Thickness;
        FillRect(DC, R, Brush);

        // Lewa belka
        GetClientRect(hWnd, R);
        R.Right := Thickness;
        FillRect(DC, R, Brush);

        // Prawa belka
        GetClientRect(hWnd, R);
        R.Left := R.Right - Thickness;
        FillRect(DC, R, Brush);

        DeleteObject(Brush);
      finally
        EndPaint(hWnd, ps);
      end;
      Result := 0;
      Exit;
    end;

    // Tło musi być przezroczyste (HOLLOW), żeby było widać co jest pod ramką
    WM_ERASEBKGND:
    begin
       Result := 1; // Mówimy: "My już wyczyściliśmy tło (nic nie robiąc)"
       Exit;
    end;

    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'FrameThick');
    end;
  end;

  Result := CallWindowProc(OldProc, hWnd, Msg, WParam, LParam);
end;

procedure draw_rectangle(Window: HWND; X, Y, W, H: Integer; Color: DWORD;TargetDC: HDC);
var
  DC: HDC;
  Pen, OldPen: HPEN;
  OldBrush: HBRUSH;
  MustReleaseDC: Boolean;
begin
  MustReleaseDC := False;

    // Jeśli użytkownik nie podał DC, pobieramy je z okna
    if TargetDC = 0 then
    begin
      DC := GetDC(Window);
      MustReleaseDC := True;
    end
    else
      DC := TargetDC;

    if DC <> 0 then
    try
      Pen := CreatePen(PS_SOLID, 1, Color);
      OldPen := SelectObject(DC, Pen);
      OldBrush := SelectObject(DC, GetStockObject(NULL_BRUSH));
      Rectangle(DC, X, Y, X + W, Y + H);

     // Sprzątamy (Przywracamy stare obiekty i usuwamy stworzone)
      SelectObject(DC, OldBrush);
      SelectObject(DC, OldPen);
      DeleteObject(Pen);
    finally
      if MustReleaseDC then ReleaseDC(Window, DC);
    end;
end;

procedure draw_fill_rectangle(Window: HWND; X, Y, W, H: Integer; Color: DWORD;TargetDC: HDC);
var
  DC: HDC;
  Brush: HBRUSH;
  R: TRect;
  MustReleaseDC: Boolean;
begin
  MustReleaseDC := False;
  if TargetDC = 0 then
  begin
    DC := GetDC(Window);
    MustReleaseDC := True;
  end
  else
    DC := TargetDC;

  if DC <> 0 then
  try
    // Ustawiamy obszar
    R.Left := X;
    R.Top := Y;
    R.Right := X + W;
    R.Bottom := Y + H;

    // Tworzymy pełny pędzel
    Brush := CreateSolidBrush(Color);

    // FillRect jest szybsze niż Rectangle dla samego wypełnienia
    // i nie wymaga wybierania pędzla do DC
    FillRect(DC, R, Brush);

    // Usuwamy pędzel
    DeleteObject(Brush);
  finally
    if MustReleaseDC then ReleaseDC(Window, DC);
  end;
end;

procedure draw_line(Window: HWND; X1, Y1, X2, Y2: Integer; Color: DWORD;TargetDC: HDC = 0);
var
  DC: HDC;
  Pen, OldPen: HPEN;
  MustReleaseDC: Boolean;
begin
  MustReleaseDC := False;
    if TargetDC = 0 then
    begin
      DC := GetDC(Window);
      MustReleaseDC := True;
    end
    else DC := TargetDC;

    if DC <> 0 then
    try
      Pen := CreatePen(PS_SOLID, 1, Color);
      OldPen := SelectObject(DC, Pen);

      MoveToEx(DC, X1, Y1, nil);
      LineTo(DC, X2, Y2);

      SelectObject(DC, OldPen);
      DeleteObject(Pen);
    finally
      if MustReleaseDC then ReleaseDC(Window, DC);
    end;
end;

function create_frame(Parent: HWND; X, Y, W, H: Integer; Color: DWORD;Thickness: Integer): HWND;
var
  hFrame: HWND;
  OldProc: THandle;
begin
     hFrame := CreateWindowExW(
      WS_EX_TRANSPARENT,
      'STATIC', nil,
      WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
    );

    if hFrame <> 0 then
    begin
      // Zapisujemy parametry
      SetPropW(hFrame, AV_PROP_BG_COLOR, THandle(Color));
      SetPropW(hFrame, 'FrameThick', THandle(Thickness));

      // Podmieniamy procedurę (Subclassing)
      OldProc := SetWindowLongPtr(hFrame, GWLP_WNDPROC, PtrUInt(@FrameProc));
      SetPropW(hFrame, 'OldWndProc', OldProc);
    end;

    Result := hFrame;
end;

function create_line(Parent: HWND; X1, Y1, X2, Y2: Integer; Color: DWORD;Thickness: Integer): HWND;
var
  hLine: HWND;
  OldProc: THandle;
  X, Y, W, H: Integer;
  Dir: Integer;
begin
 // 1. Obliczamy Bounding Box
  if X1 < X2 then X := X1 else X := X2;
  if Y1 < Y2 then Y := Y1 else Y := Y2;
  W := Abs(X2 - X1);
  H := Abs(Y2 - Y1);

  // Minimalne wymiary (żeby linia pozioma/pionowa miała wysokość/szerokość przynajmniej grubości)
  if W < Thickness then W := Thickness;
  if H < Thickness then H := Thickness;

  // 2. Ustalamy kierunek
  // Jeśli oba rosną lub oba maleją -> Dir 0 (\)
  if ((X1 <= X2) and (Y1 <= Y2)) or ((X1 >= X2) and (Y1 >= Y2)) then
    Dir := 0
  else
    Dir := 1;

  // 3. Tworzymy okno
  hLine := CreateWindowExW(
    WS_EX_TRANSPARENT,
    'STATIC', nil,
    WS_CHILD or WS_VISIBLE,
    X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
  );

  if hLine <> 0 then
  begin
    SetPropW(hLine, 'LineColor', THandle(Color));
    SetPropW(hLine, 'LineThick', THandle(Thickness));
    SetPropW(hLine, 'LineDir',   THandle(Dir));

    OldProc := SetWindowLongPtr(hLine, GWLP_WNDPROC, PtrUInt(@LineProc));
    SetPropW(hLine, 'OldWndProc', OldProc);
  end;

  Result := hLine;
end;

function create_circle_filled(Parent: HWND; X, Y, Diameter: Integer;Color: DWORD): HWND;
var
  hCir: HWND;
  OldProc: THandle;
begin
  hCir := CreateWindowExW(WS_EX_TRANSPARENT, 'STATIC', nil, WS_CHILD or WS_VISIBLE,
    X, Y, Diameter, Diameter, Parent, 0, GetModuleHandle(nil), nil);

  if hCir <> 0 then
  begin
    SetPropW(hCir, 'CirColor', THandle(Color));
    SetPropW(hCir, 'CirFill',  1);
    OldProc := SetWindowLongPtr(hCir, GWLP_WNDPROC, PtrUInt(@CircleProc));
    SetPropW(hCir, 'OldWndProc', OldProc);
  end;
  Result := hCir;
end;

function create_circle_outline(Parent: HWND; X, Y, Diameter: Integer;Color: DWORD; Thickness: Integer): HWND;
var
  hCir: HWND;
  OldProc: THandle;
begin
 hCir := CreateWindowExW(WS_EX_TRANSPARENT, 'STATIC', nil, WS_CHILD or WS_VISIBLE,
    X, Y, Diameter, Diameter, Parent, 0, GetModuleHandle(nil), nil);

  if hCir <> 0 then
  begin
    SetPropW(hCir, 'CirColor', THandle(Color));
    SetPropW(hCir, 'CirThick', THandle(Thickness));
    SetPropW(hCir, 'CirFill',  0);
    OldProc := SetWindowLongPtr(hCir, GWLP_WNDPROC, PtrUInt(@CircleProc));
    SetPropW(hCir, 'OldWndProc', OldProc);
  end;
  Result := hCir;
end;

function create_circle_image(Parent: HWND; FilePath: UnicodeString; X, Y,Size: Integer): HWND;
var
  hImg: HWND;
  OldProc: THandle;
  Img: GpImage;
begin
  Result := 0;
    if GdipLoadImageFromFile(PWideChar(FilePath), Img) <> 0 then Exit;

    // Tworzymy kwadratowe okno (Size x Size)
    hImg := CreateWindowExW(WS_EX_TRANSPARENT, 'STATIC', nil, WS_CHILD or WS_VISIBLE,
      X, Y, Size, Size, Parent, 0, GetModuleHandle(nil), nil);

    if hImg <> 0 then
    begin
      SetPropW(hImg, 'GdipImg', THandle(Img));
      OldProc := SetWindowLongPtr(hImg, GWLP_WNDPROC, PtrUInt(@CircleImageProc));
      SetPropW(hImg, 'OldWndProc', OldProc);
      Result := hImg;
    end
    else
    GdipDisposeImage(Img);
end;

function create_polyline_box(Parent: HWND; X, Y, W, H: Integer;
  const Points: array of TPoint; Color: DWORD; Thickness: Integer): HWND;
var
  hBox: HWND;
  OldProc: THandle;
  PtsPtr: Pointer;
  PtsSize: Integer;
begin
  Result := 0;
    // Nie twórz okna, jeśli brakuje punktów
    if Length(Points) < 2 then Exit;

    // Tworzymy przezroczysty kontener
    hBox := CreateWindowExW(
      WS_EX_TRANSPARENT, 'STATIC', nil,
      WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
    );

    if hBox <> 0 then
    begin
      //Obliczamy, ile bajtów zajmuje tablica punktów
      PtsSize := Length(Points) * SizeOf(TPoint);

      // Rezerwujemy miejsce w pamięci RAM
      GetMem(PtsPtr, PtsSize);

      // Kopiujemy nasze punkty do tej bezpiecznej pamięci
      Move(Points[0], PtsPtr^, PtsSize);

      // Zapisujemy wskaźnik i parametry w oknie
      SetPropW(hBox, 'PolyCol', THandle(Color));
      SetPropW(hBox, 'PolyThick', THandle(Thickness));
      SetPropW(hBox, 'PolyPts', THandle(PtsPtr));    // Adres pamięci
      SetPropW(hBox, 'PolyCnt', THandle(Length(Points))); // Ilość punktów

      OldProc := SetWindowLongPtr(hBox, GWLP_WNDPROC, PtrUInt(@polyline_proc));
      SetPropW(hBox, 'OldWndProc', OldProc);

      Result := hBox;
    end;
end;

function create_image_box(Parent: HWND; FilePath: UnicodeString; X, Y, W,H: Integer): HWND;
var
  hImgBox: HWND;
  OldProc: THandle;
  Img: GpImage;
begin
  Result := 0;

    // 1. Próbujemy załadować plik
    if GdipLoadImageFromFile(PWideChar(FilePath), Img) <> 0 then
      Exit; // Błąd ładowania (np. plik nie istnieje)

    // 2. Tworzymy okno
    hImgBox := CreateWindowExW(
      WS_EX_TRANSPARENT, // Myszka przenika przez przezroczyste fragmenty
      'STATIC', nil,
      WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
    );

    if hImgBox <> 0 then
    begin
      // Zapisujemy wskaźnik do obrazka
      SetPropW(hImgBox, 'GdipImg', THandle(Img));

      OldProc := SetWindowLongPtr(hImgBox, GWLP_WNDPROC, PtrUInt(@ImageProc));
      SetPropW(hImgBox, 'OldWndProc', OldProc);
      Result := hImgBox;
    end
    else
    begin
      // zwalniamy obrazek
      GdipDisposeImage(Img);
    end;
end;

function create_gradient_panel(Parent: HWND; X, Y, W, H: Integer; ColorStart,ColorEnd: DWORD; Direction: Integer): HWND;
var
  hPanel: HWND;
  OldProc: THandle;
begin
  // Tworzymy zwykły STATIC (jako kontener)
  hPanel := CreateWindowExW(
    0, 'STATIC', nil,
    WS_CHILD or WS_VISIBLE or SS_NOTIFY, // SS_NOTIFY jeśli chcesz klikać w panel
    X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
  );

  if hPanel <> 0 then
  begin
    // Zapisujemy parametry gradientu
    SetPropW(hPanel, 'GradCol1', THandle(ColorStart));
    SetPropW(hPanel, 'GradCol2', THandle(ColorEnd));
    SetPropW(hPanel, 'GradMode', THandle(Direction));

    // Subclassing
    OldProc := SetWindowLongPtr(hPanel, GWLP_WNDPROC, PtrUInt(@GradientProc));
    SetPropW(hPanel, 'OldWndProc', OldProc);
  end;

  Result := hPanel;
end;

function create_rounded_panel(Parent: HWND; X, Y, W, H: Integer; Color: DWORD; Radius: Integer): HWND;
var
  hPanel: HWND;
  OldProc: THandle;
begin
  hPanel := CreateWindowExW(
      WS_EX_TRANSPARENT, // Kluczowe dla rogów
      'STATIC', nil,
      WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
    );

    if hPanel <> 0 then
    begin
      SetPropW(hPanel, 'RndColor', THandle(Color));
      SetPropW(hPanel, 'RndRadius', THandle(Radius));

      OldProc := SetWindowLongPtr(hPanel, GWLP_WNDPROC, PtrUInt(@RoundedProc));
      SetPropW(hPanel, 'OldWndProc', OldProc);
    end;

    Result := hPanel;
end;

function create_rotated_image(Parent: HWND; FilePath: UnicodeString; X, Y, W, H: Integer; InitialAngle: Integer): HWND;
var
  hImg: HWND;
  OldProc: THandle;
  Img: GpImage;
begin
  Result := 0;
    if GdipLoadImageFromFile(PWideChar(FilePath), Img) <> 0 then Exit;

    hImg := CreateWindowExW(WS_EX_TRANSPARENT, 'STATIC', nil, WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil);

    if hImg <> 0 then
    begin
      SetPropW(hImg, 'GdipImg', THandle(Img));
      SetPropW(hImg, 'ImgAngle', THandle(InitialAngle)); // Zapisujemy kąt

      OldProc := SetWindowLongPtr(hImg, GWLP_WNDPROC, PtrUInt(@RotateImageProc));
      SetPropW(hImg, 'OldWndProc', OldProc);
      Result := hImg;
    end
    else
    GdipDisposeImage(Img);
end;

procedure set_image_angle(hImg: HWND; Angle: Integer);
begin
  SetPropW(hImg, 'ImgAngle', THandle(Angle));
  InvalidateRect(hImg, nil, False);
end;

function delete_object(hObject: HWND): Boolean;
begin
  Result := False;
  // Sprawdzamy, czy uchwyt jest prawidłowy i czy to w ogóle jest okno
  if (hObject <> 0) and IsWindow(hObject) then
  begin
    Result := DestroyWindow(hObject);
  end;
end;

procedure draw_polyline(Window: HWND; const Points: array of TPoint;Color: DWORD; Thickness: Integer; TargetDC: HDC);
var
  DC: HDC;
  MustReleaseDC: Boolean;
  Graphics: GpGraphics;
  Pen: GpPen;
  ARGB: DWORD;
begin
    // Linia musi mieć co najmniej dwa punkty (start i koniec)
    if Length(Points) < 2 then Exit;

    MustReleaseDC := False;

    if TargetDC = 0 then
    begin
      DC := GetDC(Window);
      MustReleaseDC := True;
    end
    else
      DC := TargetDC;
    if DC <> 0 then
    try
      if GdipCreateFromHDC(DC, Graphics) = 0 then
      begin
        // Wygładzanie kluczowe dla ładnych wykresów i skosów
        GdipSetSmoothingMode(Graphics, SmoothingModeAntiAlias);

        // Przygotowanie pióra
        ARGB := ColorRefToARGB(Color);
        GdipCreatePen1(ARGB, Thickness, 2, Pen); // 2 = UnitPixel
        GdipDrawLinesI(Graphics, Pen, @Points[0], Length(Points));

        //Sprzątanie pamięci karty graficznej
        GdipDeletePen(Pen);
        GdipDeleteGraphics(Graphics);
      end;
    finally
      if MustReleaseDC then ReleaseDC(Window, DC);
    end;
end;

function point(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function create_polygon_box(Parent: HWND; X, Y, W, H: Integer; const Points: array of TPoint; FillColor: DWORD): HWND;
var
  hBox: HWND;
  OldProc: THandle;
  PtsPtr: Pointer;
  PtsSize: Integer;
begin
  Result := 0;
    // Muszą być co najmniej 3 punkty, żeby zamknąć figurę
    if Length(Points) < 3 then Exit;

    hBox := CreateWindowExW(
      WS_EX_TRANSPARENT, 'STATIC', nil,
      WS_CHILD or WS_VISIBLE,
      X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil
    );

    if hBox <> 0 then
    begin
      PtsSize := Length(Points) * SizeOf(TPoint);
      GetMem(PtsPtr, PtsSize);
      Move(Points[0], PtsPtr^, PtsSize);

      SetPropW(hBox, 'PolyCol', THandle(FillColor));
      SetPropW(hBox, 'PolyPts', THandle(PtsPtr));
      SetPropW(hBox, 'PolyCnt', THandle(Length(Points)));
      OldProc := SetWindowLongPtr(hBox, GWLP_WNDPROC, PtrUInt(@polygon_proc));
      SetPropW(hBox, 'OldWndProc', OldProc);

      Result := hBox;
    end;
end;

function copy_pixels(DestDC: HDC; DestX, DestY, W, H: Integer; SrcDC: HDC;
  SrcX, SrcY: Integer): Boolean;
begin
  // SRCCOPY to standardowa flaga nadpisywania pikseli
  Result := BitBlt(DestDC, DestX, DestY, W, H, SrcDC, SrcX, SrcY, SRCCOPY);
end;

function stretch_pixels(DestDC: HDC; DestX, DestY, DestW, DestH: Integer;
  SrcDC: HDC; SrcX, SrcY, SrcW, SrcH: Integer): Boolean;
begin
    // HALFTONE zapobiega brzydkiemu pikselowaniu przy pomniejszaniu obrazu w starym GDI
    SetStretchBltMode(DestDC, HALFTONE);
    // Ustawienie punktu startowego dla algorytmu Halftone (wymagane w WinAPI)
    SetBrushOrgEx(DestDC, 0, 0, nil);
    Result := StretchBlt(DestDC, DestX, DestY, DestW, DestH, SrcDC, SrcX, SrcY, SrcW, SrcH, SRCCOPY);
end;

procedure fill_pattern(DC: HDC; X, Y, W, H: Integer; Rop: DWORD);
begin
  PatBlt(DC, X, Y, W, H, Rop);
end;

function begin_double_buffer(TargetDC: HDC; const R: TRect): TDoubleBufferState;
begin
  // Zapisujemy oryginalny DC i wymiary, żeby end_double_buffer miało do nich dostęp
  Result.OriginalDC := TargetDC;
  Result.Width := R.Right - R.Left;
  Result.Height := R.Bottom - R.Top;
  // Tworzymy wirtualne płótno (Memory DC) zgodne z ekranem
  Result.MemDC := CreateCompatibleDC(TargetDC);
  // Tworzymy "czystą kartkę" (Bitmapę) w pamięci RAM o wymiarach naszego okna
  Result.MemBitmap := CreateCompatibleBitmap(TargetDC, Result.Width, Result.Height);
  // Podpinamy kartkę do wirtualnego płótna i zapamiętujemy to, co było tam domyślnie
  Result.OldBitmap := SelectObject(Result.MemDC, Result.MemBitmap);
end;

procedure end_double_buffer(var State: TDoubleBufferState);
begin
  if State.MemDC <> 0 then
  begin
    //Kopiujemy cały gotowy obraz z wirtualnego płótna na prawdziwy ekran!
    BitBlt(State.OriginalDC, 0, 0, State.Width, State.Height, State.MemDC, 0, 0, SRCCOPY);
    //Sprzątanie (Bardzo ważne, żeby uniknąć wycieków pamięci GDI)
    // Odpinamy naszą bitmapę od wirtualnego płótna
    SelectObject(State.MemDC, State.OldBitmap);
    // Usuwamy naszą bitmapę i wirtualne płótno z pamięci karty graficznej
    DeleteObject(State.MemBitmap);
    DeleteDC(State.MemDC);
    // Zabezpieczamy rekord, żeby nie użyć go podwójnie
    State.MemDC := 0;
  end;
end;

procedure set_text_color(DC: HDC; Color: DWORD);
begin
  SetTextColor(DC, Color);
end;

procedure set_bk_mode(DC: HDC; IsTransparent: Boolean);
begin
  if IsTransparent then
    SetBkMode(DC, TRANSPARENT)
  else
    SetBkMode(DC, OPAQUE);
end;

procedure draw_text_simple(DC: HDC; X, Y: Integer; Text: UnicodeString);
begin
  if Length(Text) = 0 then Exit;
  // TextOutW rysuje tekst najszybciej jak to możliwe, ignorując formatowanie
  TextOutW(DC, X, Y, PWideChar(Text), Length(Text));
end;


procedure draw_text_advanced(DC: HDC; var R: TRect; Text: UnicodeString;Flags: Cardinal);
begin
  if Length(Text) = 0 then Exit;
  // DrawTextW potrafi układać tekst w prostokącie, wyrównywać i łamać wiersze
  DrawTextW(DC, PWideChar(Text), Length(Text), R, Flags);
end;

procedure draw_text_custom(DC: HDC; X, Y: Integer; Text: UnicodeString;Color: DWORD; TransparentBk: Boolean);
begin
    // Ustawiamy tryb tła
    set_bk_mode(DC, TransparentBk);
    // Ustawiamy kolor tekstu
    set_text_color(DC, Color);
    // Rysujemy tekst
    draw_text_simple(DC, X, Y, Text);
end;

procedure set_pixel(DC: HDC; X, Y: Integer; Color: DWORD);
begin
  SetPixel(DC, X, Y, Color);
end;

function get_pixel(DC: HDC; X, Y: Integer): DWORD;
begin
  Result := GetPixel(DC, X, Y);
end;

procedure get_text_size(DC: HDC; const Text: UnicodeString; out Width,
  Height: Integer);
var
  Size: TSize;
begin
  Width := 0;
    Height := 0;

    if (DC <> 0) and (Length(Text) > 0) then
    begin
      if GetTextExtentPoint32W(DC, PWideChar(Text), Length(Text), Size) then
      begin
        Width := Size.cx;  // szerokość
        Height := Size.cy; // wysokość
      end;
    end;
end;

function load_button_icon(const filename: UnicodeString): HBITMAP;
var
  h_img: THandle;
begin
  h_img := LoadImageW(
      0,
      PWideChar(filename),
      IMAGE_BITMAP,
      0, 0,
      LR_LOADFROMFILE or LR_CREATEDIBSECTION
    );

    Result := HBITMAP(h_img);
end;

{function gdiplus_init: Boolean;
var
  StartupInput: GdiplusStartupInput;
begin
    FillChar(StartupInput, SizeOf(StartupInput), 0);
    StartupInput.GdiplusVersion := 1;
    Result := GdiplusStartup(GdiplusToken, @StartupInput, nil) = 0;
end;
}

procedure gdiplus_shutdown;
begin
if GdiplusToken <> 0 then
  begin
    GdiplusShutdown(GdiplusToken);
    GdiplusToken := 0;
  end;
end;


procedure draw_image(h_dc: HDC; x, y, width, height: Integer; const image_path: UnicodeString);
var
Gfx: Pointer;
Img: Pointer;
begin
if h_dc = 0 then Exit;

  // Ładujemy obraz (zakładamy, że silnik GDI+ wystartował na dole modułu)
  if GdipLoadImageFromFile(PWideChar(image_path), Img) = 0 then
  begin
    if GdipCreateFromHDC(h_dc, Gfx) = 0 then
    begin
      GdipDrawImageRectI(Gfx, Img, x, y, width, height);
      GdipDeleteGraphics(Gfx);
    end;
    GdipDisposeImage(Img);
  end;
end;

procedure draw_smooth_rounded_rect(Graphics: Pointer; Rect: TRect;
  Radius: Integer; Color: DWORD);
var
  Path: Pointer;
  Brush: Pointer;
  R, D: Single;
begin
  R := Radius;
  D := R * 2;

  if GdipCreatePath(0, Path) = 0 then
  begin
    // Dodajemy cztery łuki, które stworzą zaokrąglone narożniki
    GdipAddPathArc(Path, Rect.Left, Rect.Top, D, D, 180, 90);
    GdipAddPathArc(Path, Rect.Right - D, Rect.Top, D, D, 270, 90);
    GdipAddPathArc(Path, Rect.Right - D, Rect.Bottom - D, D, D, 0, 90);
    GdipAddPathArc(Path, Rect.Left, Rect.Bottom - D, D, D, 90, 90);

    // Zamykamy kształt
    GdipClosePathFigure(Path);

    // Tworzymy pędzel w formacie ARGB
    //  Color musi mieć kanał Alpha, np. $FF000000 dla czarnego
    if GdipCreateSolidFill(Color, Brush) = 0 then
    begin
      // Wypełniamy ścieżkę z włączonym wcześniej Antyaliasingiem
      GdipFillPath(Graphics, Brush, Path);
      GdipDeleteBrush(Brush);
    end;

    GdipDeletePath(Path);
  end;
end;

function get_image_size(const file_path: UnicodeString; out width,height: Integer): Boolean;
var
  Img: GpImage;
  W, H: Cardinal;
begin
    Result := False;
    width := 0;
    height := 0;

    // Ładujemy obraz (GDI+ błyskawicznie czyta nagłówek PNG/JPG/BMP)
    if GdipLoadImageFromFile(PWideChar(file_path), Img) = 0 then
    begin
      // Wyciągamy oryginalną szerokość i wysokość
      if (GdipGetImageWidth(Img, W) = 0) and (GdipGetImageHeight(Img, H) = 0) then
      begin
        width := Integer(W);
        height := Integer(H);
        Result := True;
      end;
      // od razu usuwamy obraz z pamięci RAM
      GdipDisposeImage(Img);
    end;
end;


initialization
  FillChar(StartupInput, SizeOf(StartupInput), 0);
  StartupInput.GdiplusVersion := 1;
  StartupInput.DebugEventCallback := nil;
  StartupInput.SuppressBackgroundThread := False;
  StartupInput.SuppressExternalCodecs := False;

  // Bez znaku "@"
  GdiplusStartup(GdiplusToken, StartupInput, nil);

finalization
  // Wyłączenie silnika przy zamykaniu
  gdiplus_shutdown;


end.


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

Module:     avoraiser.checkbox
Description:
*)
unit avoraiser.chekbox;

{$mode ObjFPC}{$H+}

interface

uses
 Windows, avoraiser.core,avoraiser.utils;

function create_checkbox(Parent: HWND; const Caption: string; X, Y, Width, Height: Integer; TextColor: DWORD): HWND;
// Sprawdzanie stanu Checkboxa
function is_checkbox_checked(Handle: HWND): Boolean;
//odczytanie czy jest zaznaczony checkbox
function get_checkbox_checked(hCheckbox: HWND): Boolean;

implementation
procedure avocado_checkbox_paint(hWnd: HWND);
var
  ps: TPaintStruct;
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  R, BoxR, TextR: TRect;
  Brush: HBRUSH;
  Pen: HPEN;
  OldFont: HGDIOBJ;
  IsChecked, IsHover, IsPressed: Boolean;
  TextColor, ParentCol: DWORD;
  BoxSize, TextOffset: Integer;
  Caption: array[0..255] of WideChar;
begin
  DC := BeginPaint(hWnd, ps);
  try
    GetClientRect(hWnd, R);
    MemDC := CreateCompatibleDC(DC);
    MemBitmap := CreateCompatibleBitmap(DC, R.Right, R.Bottom);
    OldBitmap := SelectObject(MemDC, MemBitmap);

    try
      // tło (Przezroczystość)
      ParentCol := get_prop_color(GetParent(hWnd), AV_PROP_BG_COLOR, $121212);
      Brush := CreateSolidBrush(ParentCol);
      FillRect(MemDC, R, Brush);
      DeleteObject(Brush);

      //stany
      IsChecked := (SendMessage(hWnd, BM_GETCHECK, 0, 0) <> 0);
      IsHover := (GetPropW(hWnd, 'IsHover') = 1);
      // Sprawdzamy czy przycisk jest fizycznie wciśnięty (Capture + Mysz wewnątrz)
      IsPressed := (GetCapture = hWnd);

      TextColor := get_prop_color(hWnd, AV_PROP_TEXT_COLOR, $FFFFFF);

      // wymiary
      BoxSize := 14;
      TextOffset := 22;
      BoxR.Left := 0;
      BoxR.Right := BoxSize;
      BoxR.Top := (R.Bottom - R.Top - BoxSize) div 2;
      BoxR.Bottom := BoxR.Top + BoxSize;

      // rysowanie kwadracika(Wypełnienie)
      if IsPressed then
        Brush := CreateSolidBrush($404040) // przy kliknięciu
      else if IsHover then
        Brush := CreateSolidBrush($404040)   // ciemnoszary przy hover
      else
        Brush := CreateSolidBrush($252525);  // prawie czarny normalnie

      FillRect(MemDC, BoxR, Brush);
      DeleteObject(Brush);

      // obrys (Ramka kwadracika)
      if IsHover or IsPressed then
        Pen := CreatePen(PS_SOLID, 1, TextColor) // Jak jest najechanie kolor kwadracika
      else
        //Pen := CreatePen(PS_SOLID, 1, $606060); // Szara ramka
          Pen := CreatePen(PS_SOLID, 1, TextColor); // W stanie spoczynku


      SelectObject(MemDC, GetStockObject(NULL_BRUSH));
      SelectObject(MemDC, Pen);
      Rectangle(MemDC, BoxR.Left, BoxR.Top, BoxR.Right, BoxR.Bottom);
      DeleteObject(Pen);

      // 6. PTASZEK (Checkmark) - Rysujemy tylko gdy IsChecked = True
      if IsChecked then
      begin
        // Ptaszek będzie biały lub w kolorze akcentu Avocado
        Pen := CreatePen(PS_SOLID, 2, TextColor);
        SelectObject(MemDC, Pen);

        MoveToEx(MemDC, BoxR.Left + 3, BoxR.Top + 7, nil);
        LineTo(MemDC, BoxR.Left + 6, BoxR.Top + 10);
        LineTo(MemDC, BoxR.Left + 11, BoxR.Top + 4);
        DeleteObject(Pen);
      end;

      // 7. TEKST
      GetWindowTextW(hWnd, Caption, 255);
      TextR := R;
      TextR.Left := TextOffset;
      SetBkMode(MemDC, TRANSPARENT);
      SetTextColor(MemDC, TextColor);
      OldFont := SelectObject(MemDC, HGDIOBJ(SendMessage(hWnd, WM_GETFONT, 0, 0)));
      DrawTextW(MemDC, Caption, -1, TextR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      SelectObject(MemDC, OldFont);

      // ZRZUT NA EKRAN
      BitBlt(DC, 0, 0, R.Right, R.Bottom, MemDC, 0, 0, SRCCOPY);
    finally
      SelectObject(MemDC, OldBitmap);
      DeleteObject(MemBitmap);
      DeleteDC(MemDC);
    end;
  finally
    EndPaint(hWnd, ps);
  end;
end;

function CheckboxProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  OldWndProc: WNDPROC;
  State: Integer;
begin
  OldWndProc := WNDPROC(GetPropW(hWnd, 'OldWndProc'));

  case Msg of
    WM_LBUTTONDOWN:
    begin
      SetCapture(hWnd);
      InvalidateRect(hWnd, nil, False);
      Exit(0);
    end;

    WM_LBUTTONUP:
    begin
      if GetCapture = hWnd then
      begin
        ReleaseCapture;
        State := SendMessage(hWnd, BM_GETCHECK, 0, 0);
        if State = BST_CHECKED then
          SendMessage(hWnd, BM_SETCHECK, BST_UNCHECKED, 0)
        else
          SendMessage(hWnd, BM_SETCHECK, BST_CHECKED, 0);

        InvalidateRect(hWnd, nil, False);
      end;
      Exit(0);
    end;

    // blokujemy wewnętrzne zmiany stanu (eliminuje biały błysk)
    //BM_SETSTATE:
    //begin
    //  InvalidateRect(hWnd, nil, False);
    //  Exit(0);
    //end;


    WM_PAINT:
    begin
      avocado_checkbox_paint(hWnd);
      Result := 0;
      Exit;
    end;

    WM_ERASEBKGND:
    begin
      //Result := 1;
      Exit;
    end;
    //  WM_LBUTTONUP, WM_LBUTTONDOWN:
    //begin
    //  Result := CallWindowProc(OldWndProc, hWnd, Msg, WParam, LParam);
    //  InvalidateRect(hWnd, nil, False);
    //  Exit;
    //end;
    // Obsługa HOVER (Podświetlenie) ---
    WM_MOUSEMOVE:
    begin
      track_mouse_leave(hWnd);
    end;

    WM_MOUSELEAVE:
    begin
      SetPropW(hWnd, 'IsHover', 0);
      InvalidateRect(hWnd, nil, False);
    end;



    // --- Sprzątanie ---
    WM_NCDESTROY:
    begin
      RemovePropW(hWnd, 'OldWndProc');
      RemovePropW(hWnd, 'IsHover');
      // Właściwości z utils (Kolor, Font) usunie system, lub można dodać sprzątanie tutaj
      // ...
    end;
  end;

  Result := CallWindowProc(OldWndProc, hWnd, Msg, WParam, LParam);
end;



function create_checkbox(Parent: HWND; const Caption: string; X, Y, Width, Height: Integer; TextColor: DWORD): HWND;
var
  CheckboxHandle: HWND;
  OldProc: THandle;
begin
  // Używamy BS_AUTOCHECKBOX - system sam dba o logikę (kliknięcie = zmiana stanu)
  // My zajmiemy się tylko wyglądem w WM_PAINT.
  CheckboxHandle := CreateWindowExW(
    0, 'BUTTON', PWideChar(UnicodeString(Caption)),
    WS_VISIBLE or WS_CHILD or BS_AUTOCHECKBOX or WS_TABSTOP,
    X, Y, Width, Height, Parent, 0, GetModuleHandle(nil), nil
  );

  if CheckboxHandle <> 0 then
  begin
    // 1. Klasyczny Subclassing (Bez CommCtrl)
    OldProc := SetWindowLongPtr(CheckboxHandle, GWLP_WNDPROC, PtrUInt(@CheckboxProc));
    SetPropW(CheckboxHandle, 'OldWndProc', OldProc);

    // 2. Ustawiamy przezroczystość i kolor tekstu (z utils)
    // Tło będzie brane z rodzica w WM_PAINT
    set_component_transparent(CheckboxHandle, TextColor);

    // 3. Skalowanie czcionki (z utils)
    set_component_auto_font(CheckboxHandle, Height);
  end;

  Result := CheckboxHandle;
end;


function is_checkbox_checked(Handle: HWND): Boolean;
const
  BM_GETCHECK = $00F0;
  BST_CHECKED = $0001;
begin
  Result := False;
  if Handle <> 0 then
    Result := (SendMessage(Handle, BM_GETCHECK, 0, 0) = BST_CHECKED);
end;

function get_checkbox_checked(hCheckbox: HWND): Boolean;
const
  BM_GETCHECK = $00F0;
  BST_CHECKED = $0001;
begin
  if hCheckbox = 0 then Exit(False);
    Result := SendMessage(hCheckbox, BM_GETCHECK, 0, 0) = BST_CHECKED;
end;

end.


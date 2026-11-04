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

Module:     avoraiser.layout
Description:
*)

unit avoraiser.layout;

{$mode ObjFPC}{$H+}

interface
uses
  Windows,
  avoraiser.core,
  avoraiser.events;

type
TAvocadoAnchorKind = (akLeft, akTop, akRight, akBottom);
TAvocadoAnchors = set of TAvocadoAnchorKind;

TAnchorData = record
  Control: HWND;
  Parent: HWND;
  Anchors: TAvocadoAnchors;
  MarginLeft, MarginTop, MarginRight, MarginBottom: Integer;
  InitialWidth, InitialHeight: Integer;
end;

procedure update_layout(ParentWnd: HWND);
procedure center_window(Handle: HWND);
procedure set_position(Handle: HWND; X, Y: Integer);
procedure set_size(Handle: HWND; Width, Height: Integer);
procedure set_bounds(Handle: HWND; X, Y, Width, Height: Integer);
//Pobieranie aktualnej pozycji i rozmiaru okna
function get_x(Handle: HWND): Integer;
function get_y(Handle: HWND): Integer;
function get_width(Handle: HWND): Integer;
function get_height(Handle: HWND): Integer;
function get_client_area(Handle: HWND): TRect;


implementation
var
  AnchoredControls: array of TAnchorData;

procedure update_layout(ParentWnd: HWND);
var
  i: Integer;
  ParentRect: TRect;
  NewX, NewY, NewW, NewH: Integer;
  ParentW, ParentH: Integer;
begin
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

procedure center_window(Handle: HWND);
var
  Rect: TRect;
  ScreenWidth, ScreenHeight: Integer;
  WindowWidth, WindowHeight: Integer;
  NewX, NewY: Integer;
begin
  if Handle <> 0 then
  begin
    // Pobieramy wymiary pulpitu (Głównego monitora)
    ScreenWidth := GetSystemMetrics(SM_CXSCREEN);
    ScreenHeight := GetSystemMetrics(SM_CYSCREEN);
    GetWindowRect(Handle, Rect);
    WindowWidth := Rect.Right - Rect.Left;
    WindowHeight := Rect.Bottom - Rect.Top;
    NewX := (ScreenWidth - WindowWidth) div 2;
    NewY := (ScreenHeight - WindowHeight) div 2;
    SetWindowPos(Handle, 0, NewX, NewY, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
  end;
end;

procedure set_position(Handle: HWND; X, Y: Integer);
begin
  if Handle <> 0 then
     SetWindowPos(Handle, 0, X, Y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
end;

procedure set_size(Handle: HWND; Width, Height: Integer);
begin
  if Handle <> 0 then
     SetWindowPos(Handle, 0, 0, 0, Width, Height, SWP_NOMOVE or SWP_NOZORDER);
end;

procedure set_bounds(Handle: HWND; X, Y, Width, Height: Integer);
begin
  if Handle <> 0 then
     SetWindowPos(Handle, 0, X, Y, Width, Height, SWP_NOZORDER);
end;

function get_x(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
  if (Handle <> 0) and GetWindowRect(Handle, Rect) then
    Result := Rect.Left;
end;

function get_y(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
    Result := Rect.Top;
end;

function get_width(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
    if (Handle <> 0) and GetWindowRect(Handle, Rect) then
    Result := Rect.Right - Rect.Left;
end;

function get_height(Handle: HWND): Integer;
var
  Rect: TRect;
begin
  Result := 0;
   if (Handle <> 0) and GetWindowRect(Handle, Rect) then
   Result := Rect.Bottom - Rect.Top;
end;

function get_client_area(Handle: HWND): TRect;
var
  Rect: TRect;
begin
    FillChar(Rect, SizeOf(Rect), 0);
    if Handle <> 0 then
      Windows.GetClientRect(Handle, Rect);
    Result := Rect;
end;

end.


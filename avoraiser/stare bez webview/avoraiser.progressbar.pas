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

Module:     avoraiser.progressbar
Description:
*)
unit avoraiser.progressbar;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, avoraiser.core,avoraiser.utils, avoraiser.window;

{ProgressBar (Pasek Postępu)}
function create_progressbar(Parent: HWND; X, Y, W, H: Integer): HWND;
//zmiana wartości paska.
procedure set_progressbar_value(hProgress: HWND; Value: Integer);
// Funkcja pomocnicza do ustawiania koloru paska
procedure set_progressbar_color(hProgress: HWND; BarColor: DWORD);
//Tą funkcją decydujesz, czy dany pasek ma mieć napis, czy nie.
procedure set_progressbar_show_text(hProg: HWND; Enable: Boolean);
//Zmienia kolor tekstu w progress bar
procedure set_progressbar_text_color(hProg: HWND; Color: DWORD);
//Pozwoli ona ustawić kolor ramki niezależnie od tekstu.w ProgressBar
procedure set_progressbar_border_color(hProg: HWND; border_color: DWORD);
//Pobranie wartosci  zprogressbara
function get_progressbar_value(hProg: HWND): Integer;
//Krokowa zmiana wartosci w progressBar
procedure progressbar_step(hProg: HWND; Delta: Integer);
// Current: ile masz (np. 150 plików)
// Max: ile jest wszystkich (np. 600 plików)
procedure set_progressbar_from_max(hProg: HWND; Current, Max: Integer);



implementation

function ProgressBarProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
  DC: HDC;
  R,BarRect: TRect;
  Brush: HBRUSH;
  BgColor, BarColor, TextColor, PropVal: DWORD;
  Progress, Width, BarWidth: Integer;
  Txt: UnicodeString;
  ps: TPaintStruct;
  ShowText: Boolean;
  myFont: HFONT;
begin
  case Msg of
      WM_ERASEBKGND:
      begin
        Result := 1;
        Exit;
      end;

      // Rysowanie ramki systemowej (Non-Client area)
      WM_NCPAINT:
      begin
        Result := DefSubclassProc(hwnd, msg, wparam, lparam);
        draw_border(hwnd);
        Exit;
      end;

      WM_PAINT:
      begin
        DC := BeginPaint(hWnd, ps);
        try
          GetClientRect(hWnd, R);
          Width := R.Right - R.Left;

          // 1. POBIERAMY WARTOŚĆ POSTĘPU (0-100)
          PropVal := DWORD(PtrUInt(GetProp(hWnd, 'AvProgress')));
          Progress := Integer(PropVal);
          if Progress < 0 then Progress := 0;
          if Progress > 100 then Progress := 100;
          ShowText := GetProp(hWnd, 'AvShText') = 1;
          // 2. KOLORY
          PropVal := DWORD(PtrUInt(GetProp(hWnd, 'AvProgBgColor')));
          if PropVal <> 0 then
          BgColor := PropVal - 1
          else
          BgColor := $303030;

          PropVal := DWORD(PtrUInt(GetProp(hWnd, 'AvBarColor')));
          if PropVal <> 0 then
          BarColor := PropVal - 1
          else
          BarColor := RGB(64,64,64);//$00FF00; // Domyślny zielony

          PropVal := DWORD(PtrUInt(GetProp(hWnd, 'AvProgTextColor')));
          if PropVal <> 0 then
          TextColor := PropVal - 1
          else
          TextColor := $FFFFFF;   //$000000

          // 3. RYSUJEMY TŁO (Pusty pasek)
          Brush := CreateSolidBrush(BgColor);
          FillRect(DC, R, Brush);
          DeleteObject(Brush);

          // 4. RYSUJEMY PASEK POSTĘPU
          if Progress > 0 then
          begin
            BarRect := R; // Kopiujemy R do BarRect
            BarWidth := Round(Width * (Progress / 100));
           // R.Right := BarWidth; // Zmniejszamy prostokąt do szerokości postępu
            BarRect.Right := BarRect.Left + BarWidth; // Modyfikujemy tylko BarRect!

           // RBar := R;
           // RBar.Right := BarWidth;

            Brush := CreateSolidBrush(BarColor);
            FillRect(DC, BarRect, Brush);
            DeleteObject(Brush);

            //R.Right := Width; // Przywracamy pełną szerokość dla tekstu
          end;
          // 5. Rysujemy TEKST (tylko jeśli włączony)
          if ShowText then
          begin
            SetBkMode(DC, TRANSPARENT);  // Tło tekstu przezroczyste
            SetTextColor(DC, TextColor);
            // Pobieramy font ustawiony w kontrolce (np. przez SetComponentSizeFont)
            myFont := HFONT(SendMessage(hWnd, WM_GETFONT, 0, 0));

           { if myFont <> 0 then
            begin
              SelectObject(DC, myFont);
              Txt := IntToStr(Progress) + '%';
              DrawTextW(DC, PWideChar(Txt), Length(Txt), R,
              DT_CENTER or DT_VCENTER or DT_SINGLELINE);
            end;
            }

            if myFont = 0 then myFont := GetStockObject(DEFAULT_GUI_FONT);
              SelectObject(DC, myFont);
            // Jawna konwersja na UnicodeString
             Txt := UnicodeString(int_to_str(Progress) + '%');

            // Rysujemy używając R (którego NIE ZMIENILIŚMY), więc tekst będzie na środku
             DrawTextW(DC, PWideChar(Txt), Length(Txt), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

           end;

          // Rysowanie ramki (korzystając z Twojej funkcji DrawAvocadoBorder, jeśli chcesz)
          draw_border(hWnd);

        finally
          EndPaint(hWnd, ps);
        end;
        Exit(0);
      end;

      WM_NCDESTROY:
      begin
        RemoveWindowSubclass(hWnd, SUBCLASSPROC(@ProgressBarProc), uIdSubclass);
        // Usuwamy właściwości
        //RemoveProp(hwnd, KP_PRG_VAL);
        RemoveProp(hwnd, AV_PROGRES_BG_COLOR);
        RemoveProp(hwnd, AV_PROG_BAR_COLOR);
        RemoveProp(hwnd, AV_PROGRES_TEXT_COLOR);
        RemoveProp(hwnd, AV_PROG_BAR_SHOW_TEXT);

      end;
    end;
    Result := DefSubclassProc(hWnd, Msg, WParam, LParam);

end;

function create_progressbar(Parent: HWND; X, Y, W, H: Integer): HWND;
begin
  Result := CreateWindowExW(0, 'STATIC', nil,
    WS_CHILD or WS_VISIBLE,
    X, Y, W, H, Parent, 0, GetModuleHandle(nil), nil);

  if Result <> 0 then
  begin
    SetWindowSubclass(Result, SUBCLASSPROC(@ProgressBarProc), 1, 0);
    // Ustawiamy domyślny postęp na 0
    SetProp(Result, 'AvProgress', 0);
    SendMessageW(Result, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
  end;
end;

procedure set_progressbar_value(hProgress: HWND; Value: Integer);
begin
  if Value < 0 then Value := 0;
  if Value > 100 then Value := 100;
  SetProp(hProgress, 'AvProgress', THandle(Value));
  //przerysowanie
  InvalidateRect(hProgress, nil, False);
end;

procedure set_progressbar_color(hProgress: HWND; BarColor: DWORD);
begin
  SetProp(hProgress, 'AvBarColor', THandle(BarColor + 1)); // Trik +1
  InvalidateRect(hProgress, nil, False);
end;

procedure set_progressbar_show_text(hProg: HWND; Enable: Boolean);
begin
    if Enable then
      SetProp(hProg, 'AvShText', 1)
    else
      SetProp(hProg, 'AvShText', 0);
    InvalidateRect(hProg, nil, False);
end;

procedure set_progressbar_text_color(hProg: HWND; Color: DWORD);
begin
    if hProg = 0 then Exit;
  SetProp(hProg, 'AvProgTextColor', THandle(Color + 1));
  InvalidateRect(hProg, nil, False);
end;

procedure set_progressbar_border_color(hProg: HWND; border_color: DWORD);
begin
    if hProg <> 0 then
    begin
       SetProp(hProg, AV_PROGRES_BORDER_COLOR, THandle(border_color + 1));
       InvalidateRect(hProg, nil, False);
       if border_color <> 0 then
         SetProp(hProg, AV_PROGRES_BORDER_COLOR, THandle(border_color + 1));
       if border_color <> 0 then
         SetProp(hProg, AV_CTX_BORDER_COLOR, THandle(border_color + 1))
       else
         RemoveProp(hProg, AV_CTX_BORDER_COLOR);
        InvalidateRect(hProg, nil, True);
    end;

end;

function get_progressbar_value(hProg: HWND): Integer;
begin
    if hProg = 0 then Exit(0);
    Result := Integer(PtrUInt(GetProp(hProg, 'AvProgress')));
end;

procedure progressbar_step(hProg: HWND; Delta: Integer);
var
  Current, NewVal: Integer;
begin
  Current := get_progressbar_value(hProg);
  NewVal := Current + Delta;
  set_progressbar_value(hProg, NewVal);
end;

procedure set_progressbar_from_max(hProg: HWND; Current, Max: Integer);
var
  Percent: Integer;
begin
    if Max <= 0 then Percent := 0
        else
          Percent := Round((Current / Max) * 100);
          set_progressbar_value(hProg, Percent);
end;


end.


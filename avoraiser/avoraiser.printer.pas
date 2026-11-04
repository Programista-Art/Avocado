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

Module:     avoraiser.printer
Description:
*)
unit avoraiser.printer;

{$mode objfpc}{$H+}
{$codepage UTF-8}

interface

uses
  Windows, CommDlg;

// Wywołuje systemowe okno wyboru drukarki i zwraca jej kontekst (HDC)
function printer_show_dialog(h_owner: HWND; out h_printer_dc: HDC): Boolean;
// Rozpoczyna nowe zadanie drukowania (pojawia się w buforze Windowsa)
procedure printer_begin_doc(h_dc: HDC; const document_name: UnicodeString);
// Kończy zadanie, wypuszcza kartkę z drukarki i zwalnia pamięć
procedure printer_end_doc(h_dc: HDC);
// Rysuje tekst na kartce papieru (współrzędne w pikselach drukarki)
procedure printer_draw_text(h_dc: HDC; x, y: Integer; const text_to_draw: UnicodeString);
// Rysuje prostą linię na kartce papieru (np. do tabel, oddzielania sekcji)
procedure printer_draw_line(h_dc: HDC; x1, y1, x2, y2: Integer);
procedure printer_set_font(h_dc: HDC; const font_name: UnicodeString; height_pixels: Integer);
// Tworzy plik PDF w tle i zwraca gotowy uchwyt (HDC) do rysowania po nim
function printer_export_to_pdf(const file_path: UnicodeString; out h_printer_dc: HDC): Boolean;

// Pobiera fizyczną szerokość płótna (w pikselach) - idealne dla drukarki/PDF
function get_device_width(DC: HDC): Integer;
// Pobiera fizyczną wysokość płótna (w pikselach)
function get_device_height(DC: HDC): Integer;
// Ustawia wyśrodkowanie tekstu względem podanych współrzędnych X
procedure set_text_align_center(DC: HDC);
// Przywraca standardowe rysowanie tekstu od lewej strony (domyślne)
procedure set_text_align_left(DC: HDC);

implementation


function printer_show_dialog(h_owner: HWND; out h_printer_dc: HDC): Boolean;
var
  PrintDlgParams: TPrintDlgW;
begin
  Result := False;
  h_printer_dc := 0;

  // Zerowanie struktury pamięci - bardzo ważne w WinAPI!
  FillChar(PrintDlgParams, SizeOf(PrintDlgParams), 0);

  PrintDlgParams.lStructSize := SizeOf(PrintDlgParams);
  PrintDlgParams.hwndOwner := h_owner;
  // PD_RETURNDC zmusza system do zwrócenia nam gotowego uchwytu HDC do rysowania
  PrintDlgParams.Flags := PD_RETURNDC or PD_NOPAGENUMS or PD_NOSELECTION;

  if PrintDlgW(@PrintDlgParams) then
  begin
    h_printer_dc := PrintDlgParams.hDC;
     // Zwalnianie pamięci zaalokowanej przez systemowe okno dialogowe
    if PrintDlgParams.hDevMode <> 0 then
    begin
       GlobalFree(PrintDlgParams.hDevMode);
    end;
    if PrintDlgParams.hDevNames <> 0 then
    begin
       GlobalFree(PrintDlgParams.hDevNames);
    end;
    Result := True;
  end;
end;


procedure printer_begin_doc(h_dc: HDC; const document_name: UnicodeString);
var
  DocInfo: TDocInfoW;
begin
  if h_dc = 0 then Exit;

  FillChar(DocInfo, SizeOf(DocInfo), 0);
  DocInfo.cbSize := SizeOf(DocInfo);
  DocInfo.lpszDocName := PWideChar(document_name);
  // Zwraca > 0 gdy zadanie pomyślnie wejdzie do kolejki drukowania
  if StartDocW(h_dc, @DocInfo) > 0 then
    StartPage(h_dc);
end;


procedure printer_end_doc(h_dc: HDC);
begin
  if h_dc = 0 then Exit;

  EndPage(h_dc);     // Zamykamy stronę
  EndDoc(h_dc);      // Zamykamy cały dokument (drukarka zaczyna pracować)
  DeleteDC(h_dc);    // Zwalniamy zasoby systemowe przypisane do HDC
end;


procedure printer_draw_text(h_dc: HDC; x, y: Integer; const text_to_draw: UnicodeString);
begin
  if h_dc = 0 then Exit;

  // TextOutW rysuje tekst w formacie UTF-16
  TextOutW(h_dc, x, y, PWideChar(text_to_draw), Length(text_to_draw));
end;


procedure printer_draw_line(h_dc: HDC; x1, y1, x2, y2: Integer);
begin
  if h_dc = 0 then Exit;

  // W systemie Windows rysowanie linii wymaga najpierw "przeniesienia pędzla" do punktu startu...
  MoveToEx(h_dc, x1, y1, nil);
  // ...a następnie przeciągnięcia go do punktu końcowego
  LineTo(h_dc, x2, y2);
end;

procedure printer_set_font(h_dc: HDC; const font_name: UnicodeString;
  height_pixels: Integer);
var
  h_font: HFONT;
begin
  if h_dc = 0 then Exit;

    // Tworzy czcionkę logiczną w Windowsie
    h_font := CreateFontW(
      -height_pixels, 0, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, PWideChar(font_name)
    );
    // Przypisuje stworzoną czcionkę do pędzla, by TextOutW jej użył
    SelectObject(h_dc, h_font);
end;

function printer_export_to_pdf(const file_path: UnicodeString; out
  h_printer_dc: HDC): Boolean;
var
  DocInfo: TDocInfoW;
begin
  Result := False;
    h_printer_dc := 0;
    //Pobieramy uchwyt bezpośrednio dla systemowej drukarki PDF, pomijając okna dialogowe
    h_printer_dc := CreateDCW(nil, 'Microsoft Print to PDF', nil, nil);

    // Jeśli funkcja zwróciła 0, oznacza to, że w systemie (np. starszym) nie ma tej drukarki
    if h_printer_dc = 0 then Exit;

    // Konfigurujemy dokument startowy
    FillChar(DocInfo, SizeOf(DocInfo), 0);
    DocInfo.cbSize := SizeOf(DocInfo);
    DocInfo.lpszDocName := 'Avocado PDF Export';

    // Wskazujemy konkretny plik docelowy.
    // Dzięki temu Windows nie wyświetli okienka "Zapisz jako..."
    DocInfo.lpszOutput := PWideChar(file_path);

    // 3. Startujemy dokument i od razu pierwszą stronę
    if StartDocW(h_printer_dc, @DocInfo) > 0 then
    begin
      StartPage(h_printer_dc);
      Result := True;
    end
    else
    begin
      // Jeśli coś poszło nie tak (np. brak uprawnień do zapisu na dysku C:), sprzątamy
      DeleteDC(h_printer_dc);
      h_printer_dc := 0;
    end;
end;

function get_device_width(DC: HDC): Integer;
begin
  if DC = 0 then Exit(0);
  // HORZRES zwraca szerokość w pikselach dla danego urządzenia (ekran lub drukarka)
  Result := GetDeviceCaps(DC, HORZRES);
end;

function get_device_height(DC: HDC): Integer;
begin
  if DC = 0 then Exit(0);
    Result := GetDeviceCaps(DC, VERTRES);
end;

procedure set_text_align_center(DC: HDC);
begin
  if DC = 0 then Exit;
    SetTextAlign(DC, TA_CENTER or TA_TOP);
end;

procedure set_text_align_left(DC: HDC);
begin
  if DC = 0 then Exit;
    SetTextAlign(DC, TA_LEFT or TA_TOP);
end;

end.


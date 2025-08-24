unit pliki;

{$mode objfpc}
{$H+}

interface

uses
  SysUtils, Classes;

{--- API ---}

// Przypisanie pliku do zmiennej
procedure przypisz_plik(var f: TextFile; const nazwa: string);

// Otwieranie pliku
procedure otworz_do_zapisu(var f: TextFile);
procedure otworz_do_dopisywania(var f: TextFile);
procedure otworz_do_odczytu(var f: TextFile);

// Zamykanie pliku
procedure zamknij_plik(var f: TextFile);

// Zapis do pliku
procedure zapisz_linie(var f: TextFile; const tekst: string);
procedure zapisz(var f: TextFile; const tekst: string);

// Odczyt z pliku
function czytaj_linie(var f: TextFile): string;
function czytaj_znak(var f: TextFile): Char;

// Sprawdzanie końca pliku
function koniec_pliku(var f: TextFile): Boolean;

// Sprawdzanie czy plik istnieje
function czy_plik_istnieje(const nazwa: string): Boolean;

// Kod błędu I/O (po operacji przy wyłączonej kontroli I/O)
function wynik_io: Integer;

implementation

procedure przypisz_plik(var f: TextFile; const nazwa: string);
begin
  AssignFile(f, nazwa);
end;

procedure otworz_do_zapisu(var f: TextFile);
begin
  Rewrite(f);
end;

procedure otworz_do_dopisywania(var f: TextFile);
begin
  Append(f);
end;

procedure otworz_do_odczytu(var f: TextFile);
begin
  Reset(f);
end;

procedure zamknij_plik(var f: TextFile);
begin
  CloseFile(f);
end;

procedure zapisz_linie(var f: TextFile; const tekst: string);
begin
  WriteLn(f, tekst);
end;

procedure zapisz(var f: TextFile; const tekst: string);
begin
  Write(f, tekst);
end;

function czytaj_linie(var f: TextFile): string;
var
  s: string;
begin
  ReadLn(f, s);
  Result := s;
end;

function czytaj_znak(var f: TextFile): Char;
var
  c: Char;
begin
  Read(f, c);
  Result := c;
end;

function koniec_pliku(var f: TextFile): Boolean;
begin
  Result := Eof(f);
end;

function czy_plik_istnieje(const nazwa: string): Boolean;
begin
  Result := FileExists(nazwa);
end;

function wynik_io: Integer;
begin
  Result := IOResult;
end;

end.


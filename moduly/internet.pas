unit internet;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,Dialogs,httpsend,ssl_openssl,pingsend;

function DownloadFileToDisk(const URL, SavePath: string; out ErrorMsg: string): Boolean;
procedure DownloadToStream(const URL: string; const SomeStream: TStream);
function pobierz_plik(const URLtekst, SavePath: string): Boolean;
function pobierz_strone(const URLtekst: string; var WhereSave: TStringList; SavePath: string): Boolean;
//Ping
function Ping(const AHost: string; ATimeout: Integer = 5000): Boolean;



implementation

uses
  ftpsend, blcksock;
const
  Opera_UserAgent = 'Opera/9.80 (Windows NT 5.1; U; pl) Presto/2.2.15 Version/10.10';
  Location_Prefix = 'Location:' + #32;

{ Pobiera TYLKO ZDJECIA
function DownloadFileToDisk(const URL, SavePath: string; out ErrorMsg: string): Boolean;

var
MemStream: TMemoryStream;
Dir: string;
SynHttp: THTTPSend;
begin
  Result := False;
    ErrorMsg := '';
    Dir := ExtractFilePath(SavePath);
    if (Dir <> '') and (not DirectoryExists(Dir)) then
      ForceDirectories(Dir);

    MemStream := TMemoryStream.Create;
    SynHttp := THTTPSend.Create;
    try
      try
        SynHttp.UserAgent := 'Mozilla/5.0';
        if not SynHttp.HTTPMethod('GET', URL) then
        begin
          ErrorMsg := 'HTTP request failed';
          Exit;
        end;

        // sprawdzenie typu MIME – czy to obraz
        if Pos('image', LowerCase(SynHttp.MimeType)) = 0 then
        begin
          ErrorMsg := 'Pobrany plik nie jest obrazem: ' + SynHttp.MimeType;
          Exit;
        end;

        SynHttp.Document.SaveToStream(MemStream);
        MemStream.Position := 0;
        MemStream.SaveToFile(SavePath);
        Result := True;
      except
        on E: Exception do
          ErrorMsg := E.Message;
      end;
    finally
      SynHttp.Free;
      MemStream.Free;
    end;
 end;

 }

 {DZIALA pobiera zdjecia w róznych formatach i pliki}
 function DownloadFileToDisk(const URL, SavePath: string; out ErrorMsg: string): Boolean;
var
MemStream: TMemoryStream;
Dir: string;
SynHttp: THTTPSend;
begin
  Result := False;
  ErrorMsg := '';
  Dir := ExtractFilePath(SavePath);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

  MemStream := TMemoryStream.Create;
  SynHttp := THTTPSend.Create;
  try
    try
      SynHttp.UserAgent := 'Mozilla/5.0';
      if not SynHttp.HTTPMethod('GET', URL) then
      begin
        ErrorMsg := 'HTTP request failed';
        Exit;
      end;

      // Pomiń sprawdzanie MIME – pobieramy wszystko
      SynHttp.Document.SaveToStream(MemStream);
      MemStream.Position := 0;
      MemStream.SaveToFile(SavePath);
      Result := True;
    except
      on E: Exception do
        ErrorMsg := E.Message;
    end;
  finally
    SynHttp.Free;
    MemStream.Free;
  end;

end;

procedure DownloadToStream(const URL: string; const SomeStream: TStream);
const
Location_Prefix = 'Location:' + #32;
var
SynHttp: THTTPSend;
I, Position: Integer;
Str, DirectLink: string;
begin
SynHttp := THTTPSend.Create;
try
SynHttp.UserAgent := Opera_UserAgent;
SynHttp.HTTPMethod('GET', URL);

case SynHttp.ResultCode of
  301, 302: // przekierowanie
    begin
    for I := 0 to SynHttp.Headers.Count - 1 do
    begin
      Str := SynHttp.Headers[I];
      Position := Pos(Location_Prefix, Str);
      if Position > 0 then
      begin
        DirectLink := Copy(Str, Position + Length(Location_Prefix), MaxInt);
        Break;
      end;
    end;
      DownloadToStream(DirectLink, SomeStream);
    end;
    else
      SynHttp.Document.SaveToStream(SomeStream);
      SomeStream.Position := 0;
    end;
    finally
      SynHttp.Free;
    end;
end;

function pobierz_plik(const URLtekst, SavePath: string): Boolean;
var
  ErrorMsg: string;
begin
  Result := DownloadFileToDisk(URLtekst, SavePath, ErrorMsg);
  if Result then
    Writeln('Plik zapisany w: ', SavePath)
  else
    Writeln('Błąd pobierania: ', ErrorMsg);
end;

function pobierz_strone(const URLtekst: string; var WhereSave: TStringList; SavePath: string): Boolean;
begin
   // upewnij się, że lista istnieje
   if WhereSave = nil then
     WhereSave := TStringList.Create;

   Result := HttpGetText(URLtekst, WhereSave);  // zapisuje pobrany tekst do WhereSave

   if not Result then
     WriteLn('Błąd pobierania.')
   else
   begin
     WriteLn('Pobrano stronę:');
     WriteLn(WhereSave.Text);

     // jeśli chcesz zapisać do pliku:
     if SavePath <> '' then
       WhereSave.SaveToFile(SavePath);
   end;
end;

function Ping(const AHost: string; ATimeout: Integer): Boolean;
var
VPing: TPingSend;
begin
   // Ustawiamy domyślny wynik na fałsz
   Result := False;

   // Tworzymy obiekt TPingSend
   VPing := TPingSend.Create;

   try
     // Ustawiamy limit czasu, ile będziemy czekać na odpowiedź (w milisekundach)
     VPing.Timeout := ATimeout;

     // Wykonujemy ping. Metoda Ping zwraca prawdę, jeśli host odpowiedział
     if VPing.Ping(AHost) then
     begin
       Result := True;
     end;
   except
     // Obsługa ewentualnych wyjątków (np. błąd w adresie)
     // W przypadku błędu, funkcja zwróci domyślną wartość False
   end;
   VPing.Free;
end;

function DownloadHTTPStream(URL: string; Buffer: TStream): boolean;
const
  MaxRetries = 3;
var
  RetryAttempt: integer;
  HTTPGetResult: boolean;
begin
  Result:=false;
    RetryAttempt := 1;
    HTTPGetResult := False;
    while ((HTTPGetResult = False) and (RetryAttempt < MaxRetries)) do
    begin
      HTTPGetResult := HttpGetBinary(URL, Buffer);
      //Application.ProcessMessages;
      Sleep(100 * RetryAttempt);
      RetryAttempt := RetryAttempt + 1;
    end;
    if HTTPGetResult = False then
      raise Exception.Create('Nie można załadować dokumentu ze zdalnego serwera');
    Buffer.Position := 0;
    if Buffer.Size = 0 then
      raise Exception.Create('Pobrany dokument jest pusty.');
    Result := True;
end;


end.


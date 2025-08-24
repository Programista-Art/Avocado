unit internet;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
function DownloadFTP(URL, TargetFile: string): boolean;


implementation
uses ftpsend, blcksock, Unit1;
function DownloadFTP(URL, TargetFile: string): boolean;
const
  FTPPort=21;
  FTPScheme='ftp://'; //Имя схемы URI для URL-адресов FTP
var
  Host: string;
  Port: integer;
  Source: string;
  FoundPos: integer;
begin
  // Вычеркиваем информацию о схеме:
    if LeftStr(URL, length(FTPScheme))=FTPScheme then URL:=Copy(URL, length(FTPScheme)+1, length(URL));

    // Грубый парсинг; мог использовать код синтаксического анализа URI в пакетах FPC ...
    FoundPos:=pos('/', URL);
    Host:=LeftStr(URL, FoundPos-1);
    Source:=Copy(URL, FoundPos+1, Length(URL));

    //Проверка номера портов:
    FoundPos:=pos(':', Host);
    Port:=FTPPort;
    if FoundPos>0 then
    begin
      Host:=LeftStr(Host, FoundPos-1);
      Port:=StrToIntDef(Copy(Host, FoundPos+1, Length(Host)),21);
    end;
    Result:=FtpGetFile(Host, IntToStr(Port), Source, TargetFile, 'anonymous', 'fpc@example.com');
    if result=false then writeln('DownloadFTP: error downloading '+URL+'. Details: host: '+Host+'; port: '+Inttostr(Port)+'; remote path: '+Source+' to '+TargetFile);

end;

end.


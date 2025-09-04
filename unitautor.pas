unit unitautor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls,ShellApi,LCLTranslator, DefaultTranslator;

type

  { TFormAutor }

  TFormAutor = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
  private

  public
    procedure OpenLink(link: string);
  end;

var
  FormAutor: TFormAutor;

implementation

{$R *.lfm}

{ TFormAutor }

procedure TFormAutor.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormAutor.SpeedButton2Click(Sender: TObject);
begin
  OpenLink('https://www.youtube.com/@programistaart');
end;

procedure TFormAutor.SpeedButton3Click(Sender: TObject);
begin
   OpenLink('https://www.facebook.com/profile.php?id=61563368962907');
end;

procedure TFormAutor.SpeedButton4Click(Sender: TObject);
begin
  OpenLink('https://avocado.dimitalart.pl/');
end;

procedure TFormAutor.SpeedButton5Click(Sender: TObject);
begin
  OpenLink('https://t.me/avocado_language')
end;

procedure TFormAutor.OpenLink(link: string);
var
  ResultCode: Integer;
begin
  ResultCode := ShellExecute(0, 'open', PChar(link), nil, nil, 1);

  if ResultCode <= 32 then
  begin
    ShowMessage('Nie można otworzyć linku: ' + link + '. Kod błędu: ' + IntToStr(ResultCode));
  end;
end;

end.


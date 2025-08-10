unit Uwsparcie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLIntf, LCLType, Clipbrd, Buttons;

type

  { TWsparcie }

  TWsparcie = class(TForm)
    LabelStatus: TLabel;
    Memo1: TMemo;
    PanelDolny: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure sbOkClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);

  private

  public

  end;

var
  Wsparcie: TWsparcie;

implementation
uses
  unitautor;
{$R *.lfm}

{ TWsparcie }

procedure TWsparcie.sbOkClick(Sender: TObject);
begin
  Close;
end;

procedure TWsparcie.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TWsparcie.SpeedButton2Click(Sender: TObject);
begin
  FormAutor.OpenLink('https://ko-fi.com/programistaart');
end;


end.


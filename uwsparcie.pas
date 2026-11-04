unit Uwsparcie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLIntf, LCLType, Clipbrd, Buttons, LCLTranslator, DefaultTranslator;

type

  { TWsparcie }

  TWsparcie = class(TForm)
    Button1: TButton;
    LabelStatus: TLabel;
    Memo1: TMemo;
    PanelDolny: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure Button1Click(Sender: TObject);
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

procedure TWsparcie.Button1Click(Sender: TObject);
begin
   FormAutor.OpenLink('https://suppi.pl/programista-art?utm_source=avocado_ide&utm_medium=wsparcie&utm_campaign=ide&utm_id=1&utm_term=avocado_ide');
end;

procedure TWsparcie.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TWsparcie.SpeedButton2Click(Sender: TObject);
begin
  FormAutor.OpenLink('https://patronite.pl/programista-art?utm_source=avocado_ide&utm_medium=wsparcie&utm_campaign=patronite&utm_id=1&utm_term=avocado_ide');
end;


end.


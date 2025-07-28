unit Uwsparcie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLIntf, LCLType, Clipbrd, Buttons;

type

  { TWsparcie }

  TWsparcie = class(TForm)
    EditOdbiorca: TEdit;
    EditRachunek: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelStatus: TLabel;
    Memo1: TMemo;
    PanelDolny: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    procedure EditOdbiorcaChange(Sender: TObject);
    procedure EditOdbiorcaClick(Sender: TObject);
    procedure EditRachunekClick(Sender: TObject);

    procedure sbOkClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);

  private

  public

  end;

var
  Wsparcie: TWsparcie;

implementation

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


procedure TWsparcie.EditOdbiorcaChange(Sender: TObject);
begin

end;

procedure TWsparcie.EditOdbiorcaClick(Sender: TObject);
begin
  Clipboard.AsText := EditOdbiorca.Text;
  //EditOdbiorca.Text.CopyToClipboard;
  LabelStatus.Caption := 'Odbiorca skopiowany do schowka';
end;

procedure TWsparcie.EditRachunekClick(Sender: TObject);
begin
   Clipboard.AsText := EditRachunek.Text;
   LabelStatus.Caption := 'Nr rachunku skopiowany do schowka';
end;



end.


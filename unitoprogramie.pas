unit unitoprogramie;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons,LCLTranslator, DefaultTranslator;

type

  { TFormOprogramie }

  TFormOprogramie = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
  private

  public

  end;

var
  FormOprogramie: TFormOprogramie;

implementation

uses
  Unit1;
{$R *.lfm}

{ TFormOprogramie }


procedure TFormOprogramie.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

end.


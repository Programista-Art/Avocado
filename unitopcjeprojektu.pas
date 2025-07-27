unit unitopcjeprojektu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls;

type

  { TFormOpcjeProjektu }

  TFormOpcjeProjektu = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    sbOk: TSpeedButton;
    procedure sbOkClick(Sender: TObject);

  private

  public

  end;

var
  FormOpcjeProjektu: TFormOpcjeProjektu;

implementation

{$R *.lfm}

{ TFormOpcjeProjektu }




procedure TFormOpcjeProjektu.sbOkClick(Sender: TObject);
begin
  Close;
end;

end.


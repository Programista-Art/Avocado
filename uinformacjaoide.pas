unit uinformacjaoide;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  ComCtrls, StdCtrls, RTTICtrls ;

type

  { TFinformacjaide }

  TFinformacjaide = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
  private

  public

  end;

var
  Finformacjaide: TFinformacjaide;

implementation

{$R *.lfm}

{ TFinformacjaide }

procedure TFinformacjaide.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

end.


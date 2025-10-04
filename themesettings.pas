unit themesettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, BCComboBox, BGRACustomDrawn, BCButton, Inifiles, uDarkStyleParams,
   uWin32WidgetSetDark, uDarkStyleSchemes, uMetaDarkStyle;

type

  { TSettingTheme }

  TSettingTheme = class(TForm)
    btnSave: TBCButton;
    ComboModelGPT: TBCComboBox;
    GroupBox1: TGroupBox;
    ImageList1: TImageList;
    Label1: TLabel;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    procedure btnSaveClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private

  public

  end;

var
  SettingTheme: TSettingTheme;

implementation

{$R *.lfm}

{ TSettingTheme }

procedure TSettingTheme.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TSettingTheme.btnSaveClick(Sender: TObject);
begin

end;



end.


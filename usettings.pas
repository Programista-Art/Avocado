unit usettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons, IniFiles,
  StdCtrls;

type

  { TFormSettingIntepreter }

  TFormSettingIntepreter = class(TForm)
    BitBtn1: TBitBtn;
    EdtLinkFPC: TEdit;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    OD: TOpenDialog;
    Panel1: TPanel;
    SpeedButOpenLinkFPC: TSpeedButton;
    SpeedButSaveLInkFPC: TSpeedButton;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButOpenLinkFPCClick(Sender: TObject);
    procedure SpeedButSaveLInkFPCClick(Sender: TObject);
  private

  public
    procedure LoadFPCLink;
  end;

var
  FormSettingIntepreter: TFormSettingIntepreter;
  Ini: TIniFile;
implementation

{$R *.lfm}

{ TFormSettingIntepreter }

procedure TFormSettingIntepreter.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormSettingIntepreter.FormCreate(Sender: TObject);
begin
  LoadFPCLink;
end;

procedure TFormSettingIntepreter.SpeedButOpenLinkFPCClick(Sender: TObject);
begin
  If OD.Execute then
  EdtLinkFPC.Text := OD.FileName;
end;

procedure TFormSettingIntepreter.SpeedButSaveLInkFPCClick(Sender: TObject);
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
    ini.WriteString('main', 'fpc', EdtLinkFPC.Text);
  finally
    FreeAndNil(Ini);
  end;
  MessageDlg('Informacja','Link zapisany', mtConfirmation,[mbOK],0);
end;


procedure TFormSettingIntepreter.LoadFPCLink;
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
    EdtLinkFPC.Text := ini.ReadString('main', 'fpc','');
  finally
    FreeAndNil(Ini);
  end;
end;

end.


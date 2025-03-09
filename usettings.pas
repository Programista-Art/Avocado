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
    EditLinkInterpreter: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButOpenLinkFPC: TSpeedButton;
    SpeedButSaveLInkFPC: TSpeedButton;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButSaveLInkFPCClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private

  public
    procedure LoadIntrepreterLink;
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
  LoadIntrepreterLink;
  LoadFPCLink;
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

procedure TFormSettingIntepreter.SpeedButton2Click(Sender: TObject);
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
     ini.WriteString('main', 'interpretator', EditLinkInterpreter.Text);
  finally
    FreeAndNil(Ini);
  end;
  MessageDlg('Informacja','Link zapisany', mtConfirmation,[mbOK],0);
end;

procedure TFormSettingIntepreter.LoadIntrepreterLink;
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
     EditLinkInterpreter.Text := ini.ReadString('main', 'interpretator','');
  finally
    FreeAndNil(Ini);
  end;
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


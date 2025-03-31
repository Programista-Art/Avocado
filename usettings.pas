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
    ComboBoboxPlatforms: TComboBox;
    EdtLinkFPCFolder: TEdit;
    EdtLinkFPC: TEdit;
    GroupBox1: TGroupBox;
    SpbSaveFolderFPC: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    OD: TOpenDialog;
    Panel1: TPanel;
    SpeedButOpenLinkFPC: TSpeedButton;
    SpbLoadFolderFPC: TSpeedButton;
    SpeedButton4: TSpeedButton;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpbLoadFolderFPCClick(Sender: TObject);
    procedure SpeedButOpenLinkFPCClick(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
  private

  public
    procedure LoadFPCLink;
    procedure SaveFPCLink;
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

procedure TFormSettingIntepreter.SpbLoadFolderFPCClick(Sender: TObject);
begin
  If OD.Execute then
  EdtLinkFPCFolder.Text := OD.FileName;
end;

procedure TFormSettingIntepreter.SpeedButOpenLinkFPCClick(Sender: TObject);
begin
  If OD.Execute then
  EdtLinkFPC.Text := OD.FileName;
end;




procedure TFormSettingIntepreter.SpeedButton4Click(Sender: TObject);
begin
  SaveFPCLink;
end;

procedure TFormSettingIntepreter.LoadFPCLink;
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
    EdtLinkFPC.Text := ini.ReadString('main', 'fpc','');
    EdtLinkFPCFolder.Text := ini.ReadString('main', 'FpcBasePath','');
    ComboBoboxPlatforms.Text := ini.ReadString('main', 'TargetPlatform','');
    //EditLinkLCL.Text := ini.ReadString('main', 'Units','')
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TFormSettingIntepreter.SaveFPCLink;
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
    ini.WriteString('main', 'fpc', EdtLinkFPC.Text);
    ini.WriteString('main', 'FpcBasePath', EdtLinkFPCFolder.Text);
    ini.WriteString('main', 'TargetPlatform', ComboBoboxPlatforms.Text);
  finally
    FreeAndNil(Ini);
  end;
  MessageDlg('Dane','Dane zapisane', mtInformation,[mbOk],0);
end;

end.


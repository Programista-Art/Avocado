unit usettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons, IniFiles,
  StdCtrls,LCLTranslator, DefaultTranslator;

type

  { TFormSettingIntepreter }

  TFormSettingIntepreter = class(TForm)
    BitBtn1: TBitBtn;
    EditLinkToInstantFPC: TEdit;
    EdtLinkFPCFolder: TEdit;
    EdtLinkFPC: TEdit;
    GroupBox3: TGroupBox;
    SpbLoadFolderFPC1: TSpeedButton;
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
    procedure SpbLoadFolderFPC1Click(Sender: TObject);
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
  LinkInstantFpc: String;

resourcestring
  TranslateInformation = 'Information';
  TranslateDataSaved = 'Data saved';

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

procedure TFormSettingIntepreter.SpbLoadFolderFPC1Click(Sender: TObject);
begin
  If OD.Execute then
  EditLinkToInstantFPC.Text := OD.FileName;
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

// Poprawka 17.04.2026
procedure TFormSettingIntepreter.LoadFPCLink;
var
  AppDir,FFpcPath,FFpcBasePath: string;
begin
  AppDir := ExtractFilePath(Application.ExeName);
  Ini:= TIniFile.Create(AppDir + 'setting.ini');
  try
    FFpcPath := ExpandFileName(AppDir + ini.ReadString('main', 'fpc', ''));
    FFpcBasePath := ExpandFileName(AppDir + ini.ReadString('main', 'FpcBasePath', ''));

    EdtLinkFPC.Text := ini.ReadString('main', 'fpc','');
    EdtLinkFPCFolder.Text := ini.ReadString('main', 'FpcBasePath','');
    EditLinkToInstantFPC.Text := ini.ReadString('main', 'instantfpc','');
  finally
    FreeAndNil(Ini);
  end;
end;

// Poprawka 17.04.2026
procedure TFormSettingIntepreter.SaveFPCLink;
var
  AppDir: string;
  RelFpc, RelBase, RelInstant: string;
begin
  AppDir := ExtractFilePath(Application.ExeName);

  RelFpc := ExtractRelativePath(AppDir, EdtLinkFPC.Text);
  RelBase := ExtractRelativePath(AppDir, EdtLinkFPCFolder.Text);
  RelInstant := ExtractRelativePath(AppDir, EditLinkToInstantFPC.Text);

  Ini := TIniFile.Create(AppDir + 'setting.ini');
  try
    ini.WriteString('main', 'fpc', RelFpc);
    ini.WriteString('main', 'FpcBasePath', RelBase);
    ini.WriteString('main', 'instantfpc', RelInstant);
  finally
    FreeAndNil(Ini);
  end;
  MessageDlg(TranslateInformation, TranslateDataSaved, mtInformation,[mbOk],0);
end;

end.


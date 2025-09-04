unit ustawieniaai;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComboEx, MaskEdit, Buttons, Menus, TAChartCombos, BCListBox, BCComboBox,Inifiles,LCLTranslator, DefaultTranslator;

type

  { TSettingai }

  TSettingai = class(TForm)
    ComboModelGPT: TBCComboBox;
    EditTokenGPT: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    MenuItemHideKey: TMenuItem;
    MenuItemShowKey: TMenuItem;
    MenuItemDelete: TMenuItem;
    MenuItemPaste: TMenuItem;
    MenuItemCopy: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PopupMenu1: TPopupMenu;
    SpeedButSave: TSpeedButton;
    SpeedButtonOk: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure MenuItemCopyClick(Sender: TObject);
    procedure MenuItemDeleteClick(Sender: TObject);
    procedure MenuItemHideKeyClick(Sender: TObject);
    procedure MenuItemPasteClick(Sender: TObject);
    procedure MenuItemShowKeyClick(Sender: TObject);
    procedure SpeedButSaveClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButtonOkClick(Sender: TObject);
  private
    procedure SaveDataAiGPT;
    procedure LoadDataAiGPT;
    //Ladowanie modeli
    procedure LoadModelsToComboModels;
  public

  end;

var
  Settingai: TSettingai;
  ini: TIniFile;

implementation

{$R *.lfm}

{ TForm2 }

procedure TSettingai.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TSettingai.MenuItemCopyClick(Sender: TObject);
begin
   EditTokenGPT.CopyToClipboard;
end;

procedure TSettingai.FormCreate(Sender: TObject);
begin
  LoadModelsToComboModels;
  LoadDataAiGPT;
end;

procedure TSettingai.MenuItemDeleteClick(Sender: TObject);
begin
  EditTokenGPT.Text := '';
end;

procedure TSettingai.MenuItemHideKeyClick(Sender: TObject);
begin
  EditTokenGPT.PasswordChar:= '*';
end;

procedure TSettingai.MenuItemPasteClick(Sender: TObject);
begin
  EditTokenGPT.PasteFromClipboard;
end;

procedure TSettingai.MenuItemShowKeyClick(Sender: TObject);
begin
  EditTokenGPT.PasswordChar := #0;
end;

procedure TSettingai.SpeedButSaveClick(Sender: TObject);
begin
  SaveDataAiGPT;
end;

procedure TSettingai.SpeedButtonOkClick(Sender: TObject);
begin
  Close;
end;

procedure TSettingai.SaveDataAiGPT;
begin
    Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
    ini.WriteString('ChatGPT', 'Model', ComboModelGPT.Text);
    ini.WriteString('ChatGPT', 'Token', EditTokenGPT.Text);
  finally
    FreeAndNil(Ini);
  end;
  MessageDlg('Dane','Dane zapisane', mtInformation,[mbOk],0);
  Close;
end;

procedure TSettingai.LoadDataAiGPT;
var
  LoadedModel: string;
  ModelIndex: Integer;
begin
  Ini:= TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini'); //загружаем
  try
     // Załaduj dostępne modele do ComboModelGPT.Items
    ComboModelGPT.Items.LoadFromFile(ExtractFilePath(Application.ExeName) + 'modele-ai.txt');

    // Odczytaj nazwę wybranego modelu z INI
    LoadedModel := Ini.ReadString('ChatGPT', 'Model','');

    // Znajdź index modelu w liście
    ModelIndex := ComboModelGPT.Items.IndexOf(LoadedModel);
    if ModelIndex >= 0 then
      ComboModelGPT.ItemIndex := ModelIndex
    else if ComboModelGPT.Items.Count > 0 then
      ComboModelGPT.ItemIndex := 0; // domyślnie pierwszy

    EditTokenGPT.Text := ini.ReadString('ChatGPT', 'Token','');
    //ComboModelGPT.Items.Text := ini.ReadString('ChatGPT', 'Model','');
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TSettingai.LoadModelsToComboModels;
var
  FilePath: string;
begin
  FilePath := ExtractFilePath(ParamStr(0)) + 'modele-ai.txt';

  if FileExists(FilePath) then
    begin
      WriteLn('Plik istnieje: ', FilePath);
      ComboModelGPT.Items.LoadFromFile(FilePath);
    end
  else
    ShowMessage('Nie znaleziono pliku models.txt');
end;

end.


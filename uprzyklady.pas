unit Uprzyklady;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, BCListBox,
  BGRASpeedButton, StdCtrls, ExtCtrls, Buttons, LCLTranslator,
  DefaultTranslator, FileCtrl;

type

  { TFormPrzyklady }

  TFormPrzyklady = class(TForm)
    ExampleListBox: TFileListBox;
    OD: TOpenDialog;
    PanelBottom: TPanel;
    SpeedButton1: TSpeedButton;
    procedure ExampleListBoxDblClick(Sender: TObject);
    procedure noExampleListBoxDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
   procedure LoadExamplesToListBox;
   procedure DoubleClickLoadToSynEdit;
  public

  end;

var
  FormPrzyklady: TFormPrzyklady;
  FileNameExample,BaseName: String;
  FolderPath: string;

resourcestring
  TranslateAnErrorOccurred = 'An error occurred: ';
  TranslateFileNotExist = 'File does not exist: ';
  TranslateCheckExamples = 'Check that the "examples" folder exists and contains the appropriate files.';
  TranslateErrObjectNotAvailable = 'Error: The FuSettingsChatGPT object is not available.';
  TranslateEmptyItemSelected = 'Empty item selected';
  TranslateNoItemSelected = 'No item selected';
  TranslateErrFolder = 'Error: Folder "';
  TranslateDoesntExist = '"does not exist!"';

implementation


uses
  Unit1;
{$R *.lfm}

{ TFormPrzyklady }

procedure TFormPrzyklady.FormCreate(Sender: TObject);
begin
  LoadExamplesToListBox;
end;

procedure TFormPrzyklady.noExampleListBoxDblClick(Sender: TObject);
begin
  DoubleClickLoadToSynEdit;
end;

procedure TFormPrzyklady.ExampleListBoxDblClick(Sender: TObject);
begin
  DoubleClickLoadToSynEdit;
end;


procedure TFormPrzyklady.SpeedButton1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormPrzyklady.LoadExamplesToListBox;
var
   FolderPath: string;
   FilesList: TStringList;
   i: Integer;
begin
  if not Assigned(ExampleListBox) then Exit;
  ExampleListBox.Clear;

  FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'examples';
   //FolderPath := 'D:\przyklady\';

  if not DirectoryExists(FolderPath) then
  begin
    ShowMessage(TranslateErrFolder + FolderPath + TranslateDoesntExist);
    Exit;
  end;

  FilesList := FindAllFiles(FolderPath, '*.avocado', False);
  try
    for i := 0 to FilesList.Count - 1 do
      ExampleListBox.Items.Add(
        ChangeFileExt(ExtractFileName(FilesList[i]), '')
      );
  finally
    FilesList.Free;
  end;
end;

procedure TFormPrzyklady.DoubleClickLoadToSynEdit;
begin
  // Sprawdź czy coś jest wybrane
 // if noExampleListBox.ItemIndex = -1 then
  if ExampleListBox.ItemIndex = -1 then
  begin
    ShowMessage(TranslateNoItemSelected);
    Exit;
  end;

  // Buduj ścieżkę do folderu przykładów
   FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'examples' + PathDelim;


  // Debug - pokaż ścieżkę (można usunąć w wersji produkcyjnej)
 // ShowMessage('Ścieżka: ' + FolderPath);

  try
    // Get the name of the selected item from the ListBox
    // Pobierz nazwę wybranego elementu z ListBoxa
    BaseName := Trim(ExampleListBox.Items[ExampleListBox.ItemIndex]);
    //ShowMessage('nazwa: ' + BaseName);

    // Sprawdź czy nazwa nie jest pusta
    if BaseName = '' then
    begin
      ShowMessage(TranslateEmptyItemSelected);
      Exit;
    end;
    // Remove the extension if it exists and add the correct one
    // Usuń rozszerzenie jeśli istnieje i dodaj właściwe
    if ExtractFileExt(BaseName) <> '' then
    BaseName := ChangeFileExt(BaseName, ''); // usuń istniejące rozszerzenie

    // Build full file name / Zbuduj pełną nazwę pliku
    FileNameExample := FolderPath + BaseName + '.avocado';

    // Check if the file exists and upload it / Sprawdź czy plik istnieje i załaduj go
    if FileExists(FileNameExample) then
    begin
      if Assigned(FormMain) then
        FormMain.LoadAvocadoFileToEditor(FileNameExample)
      else
        ShowMessage(TranslateErrObjectNotAvailable);
    end
    else
    begin
      ShowMessage(TranslateFileNotExist + FileNameExample + sLineBreak + TranslateCheckExamples);
    end;

  except
    on E: Exception do
    begin
      ShowMessage(TranslateAnErrorOccurred + E.Message);
    end;
  end;
end;


end.


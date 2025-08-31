unit Uprzyklady;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, BCListBox,
  BGRASpeedButton, StdCtrls, ExtCtrls, Buttons;

type

  { TFormPrzyklady }

  TFormPrzyklady = class(TForm)
    ExampleListBox: TBCListBox;
    OD: TOpenDialog;
    PanelBottom: TPanel;
    SpeedButton1: TSpeedButton;
    procedure ExampleListBoxDblClick(Sender: TObject);
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

implementation
uses
  Unit1;
{$R *.lfm}

{ TFormPrzyklady }

procedure TFormPrzyklady.FormCreate(Sender: TObject);
begin
  LoadExamplesToListBox;
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

  FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'przyklady\';
   //FolderPath := 'D:\przyklady\';

  if not DirectoryExists(FolderPath) then
  begin
    ShowMessage('Błąd: Folder "' + FolderPath + '" nie istnieje!');
    Exit;
  end;

  FilesList := FindAllFiles(FolderPath, '*.avocado', False); // tylko pliki .avocado
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
  if ExampleListBox.ItemIndex = -1 then
  begin
    ShowMessage('Nie wybrano żadnego elementu.');
    Exit;
  end;

  // Buduj ścieżkę do folderu przykładów
   FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'przyklady\' + PathDelim;
  //FolderPath := 'D:\przyklady\';

  // Debug - pokaż ścieżkę (można usunąć w wersji produkcyjnej)
  // ShowMessage('Ścieżka: ' + FolderPath);

  try
    // Pobierz nazwę wybranego elementu z ListBoxa
    BaseName := Trim(ExampleListBox.Items[ExampleListBox.ItemIndex]);

    // Sprawdź czy nazwa nie jest pusta
    if BaseName = '' then
    begin
      ShowMessage('Wybrano pusty element.');
      Exit;
    end;

    // Usuń rozszerzenie jeśli istnieje i dodaj właściwe
    if ExtractFileExt(BaseName) <> '' then
      BaseName := ChangeFileExt(BaseName, ''); // usuń istniejące rozszerzenie

    // Zbuduj pełną nazwę pliku
    FileNameExample := FolderPath + BaseName + '.avocado';

    // Sprawdź czy plik istnieje i załaduj go
    if FileExists(FileNameExample) then
    begin
      if Assigned(FormMain) then
        FormMain.LoadAvocadoFileToEditor(FileNameExample)
      else
        ShowMessage('Błąd: Obiekt FustawieniaChatGPT nie jest dostępny.');
    end
    else
    begin
      ShowMessage('Plik nie istnieje: ' + FileNameExample + sLineBreak +
                  'Sprawdź czy folder "przyklady" istnieje i zawiera odpowiednie pliki.');
    end;

  except
    on E: Exception do
    begin
      ShowMessage('Wystąpił błąd: ' + E.Message);
    end;
  end;
end;

  {
  // Folder "przykłady" obok exe
  FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'przyklady';

  ExampleListBox.Clear;

  if DirectoryExists(FolderPath) then
  begin

    FilesList := FindAllFiles(FolderPath, '*.avocado', False);

    try
      for i := 0 to FilesList.Count - 1 do
        ExampleListBox.Items.Add(ExtractFileName(FilesList[i]));
    finally
      FilesList.Free;
    end;
  end
  else
    ShowMessage('Błąd: Folder "' + FolderPath + '" nie istnieje!');
end;
}

end.


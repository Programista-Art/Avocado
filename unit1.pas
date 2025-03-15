unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, ActnList, SynEdit, SynPopupMenu, SynCompletion,
  laz.VTHeaderPopup, Process, IniFiles, AvocadoTranslator;

type
  { TForm1 }
  TForm1 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    MemoLogs: TMemo;
    MemoOutPut: TMemo;
    MenuItem3: TMenuItem;
    MenuAboutProgram: TMenuItem;
    MenuAutor: TMenuItem;
    MenuNewFile: TMenuItem;
    MenuItemSaveFile: TMenuItem;
    MenuItemDeleteMemoLogs: TMenuItem;
    MenuItemOutputCodeClear: TMenuItem;
    MenuProjekt: TMenuItem;
    MenuItem3ClearCode: TMenuItem;
    MenuOpcjeProjektu: TMenuItem;
    MenuItemCutCode: TMenuItem;
    MenuItemPasteCode: TMenuItem;
    MenuItemCopyCode: TMenuItem;
    MenuItemDeleteCode: TMenuItem;
    MenuItemCut: TMenuItem;
    MenuItemPaste: TMenuItem;
    MenuItemCopy: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PanelDolnynadKosnola: TPanel;
    PanelLewy: TPanel;
    PanelPrawy: TPanel;
    PopupMenuMemoLogs: TPopupMenu;
    PopupMenuOutPutPascalCode: TPopupMenu;
    PopupMenuCode: TPopupMenu;
    RunCode: TAction;
    ActionList1: TActionList;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItemDeleteAllCode: TMenuItem;
    MenuUstawinia: TMenuItem;
    MenuOpen: TMenuItem;
    MenuSaveAs: TMenuItem;
    MenuClose: TMenuItem;
    OD: TOpenDialog;
    PopupMenuKonsola: TPopupMenu;
    SD: TSaveDialog;
    Splitter1: TSplitter;
    Splitter3: TSplitter;
    SynCompletion1: TSynCompletion;
    SynEditCode: TSynEdit;
    SynPopupMenuCode: TSynPopupMenu;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuAboutProgramClick(Sender: TObject);
    procedure MenuAutorClick(Sender: TObject);
    procedure MenuCloseClick(Sender: TObject);
    procedure MenuItem3ClearCodeClick(Sender: TObject);
    procedure MenuItemCopyClick(Sender: TObject);
    procedure MenuItemCopyCodeClick(Sender: TObject);
    procedure MenuItemCutClick(Sender: TObject);
    procedure MenuItemCutCodeClick(Sender: TObject);
    procedure MenuItemDeleteCodeClick(Sender: TObject);
    procedure MenuItemOutputCodeClearClick(Sender: TObject);
    procedure MenuItemPasteClick(Sender: TObject);
    procedure MenuItemPasteCodeClick(Sender: TObject);
    procedure MenuItemSaveFileClick(Sender: TObject);
    procedure MenuNewFileClick(Sender: TObject);
    procedure MenuOpcjeProjektuClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuUstawiniaClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
  private
    FTranslator: TAvocadoTranslator;
    FTranslatedCode: TStringList;
    //Laduje link do FPC kompilatora
    procedure LoadFpc;
    procedure SaveCodeToFile;
    //Kompilacja kodu
    procedure CompilePascalCode(const PascalCode, OutputFile: string);
    //Kompilacja kodu release debug
    procedure KompilacjaKoduwPascal(const Code, OutputFile: string);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TInterpreterThread }
  TInterpreterThread = class(TThread)
  private
    FProcess: TProcess;
    FConsole: TSynEdit;
    FOutput: string; // Zmienna pomocnicza do przekazania tekstu
    procedure SyncAppendOutput;
  protected
    procedure Execute; override;
  public
    constructor Create(const AInterpreterPath, ATempFile: string; AConsole: TSynEdit);
  end;

var
  Form1: TForm1;
  Ini: TIniFile;
  FInterpreterPath: string;
  //Link do FPC
  FFpcPath: string;
  FTempFile: string;
  //Tymczasowy plik.pas
  FTempFiles: string;
  FPC_Path: string;
  FPC_Params: TStringList;
  //Nazwa pliku
  FileNamePr: String;
  //Sciezka pliku
  SaveFileProject: String;
  //Otwarta sciezka pliku
  OpenFileProject: String;

implementation

uses
 usettings,unitopcjeprojektu,unitoprogramie,unitautor;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadFpc;
  // Ustalanie ścieżki do pliku tymczasowego
  //FTempFile := ExtractFilePath(Application.ExeName) + 'temp.avocado';
  //Zapisuje plik tymaczosowy tam gdzie jest zapisany projekt
  FTempFile := SaveFileProject + 'temp.avocado';
end;

constructor TForm1.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FTranslator := TAvocadoTranslator.Create;
  FTranslatedCode := TStringList.Create;
  //Caption := 'Avocado IDE :: digitalart.pl';
  //SynEditCode.Highlighter := SynPasSyn1;
  FPC_Params := TStringList.Create;
  FPC_Params.Add('-Sg');
  FPC_Params.Add('-Mobjfpc');
  //FPC_Path := 'D:\Lazarus4RC2\fpc\3.2.2\bin\x86_64-win64\fpc.exe'; // Ręczna ścieżka
end;



procedure TForm1.FormShow(Sender: TObject);
begin
  SynEditCode.SetFocus;
end;

procedure TForm1.MenuAboutProgramClick(Sender: TObject);
begin
  FormOprogramie.ShowModal;
end;

procedure TForm1.MenuAutorClick(Sender: TObject);
begin
  FormAutor.ShowModal
end;

procedure TForm1.MenuCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItem3ClearCodeClick(Sender: TObject);
begin
  SynEditCode.ClearAll;
end;

procedure TForm1.MenuItemCopyClick(Sender: TObject);
begin
  SynEditCode.CopyToClipboard;
end;

procedure TForm1.MenuItemCopyCodeClick(Sender: TObject);
begin
  SynEditCode.CopyToClipboard;
end;

procedure TForm1.MenuItemCutClick(Sender: TObject);
begin
  SynEditCode.CutToClipboard;
end;

procedure TForm1.MenuItemCutCodeClick(Sender: TObject);
begin
  SynEditCode.CutToClipboard;
end;


procedure TForm1.MenuItemDeleteCodeClick(Sender: TObject);
begin
    SynEditCode.ClearAll;
end;

procedure TForm1.MenuItemOutputCodeClearClick(Sender: TObject);
begin
  MemoOutPut.Clear;
end;

procedure TForm1.MenuItemPasteClick(Sender: TObject);
begin
  SynEditCode.PasteFromClipboard;
end;

procedure TForm1.MenuItemPasteCodeClick(Sender: TObject);
begin
  SynEditCode.PasteFromClipboard;
end;

procedure TForm1.MenuItemSaveFileClick(Sender: TObject);
begin
//jesli imię znane to nie trzeba wywowywowylac SaveDialog
//wtedy tylko SaveToFile.
  if SD.FileName <> '' then begin
    SynEditCode.Lines.SaveToFile(SD.FileName);
    //ustawiam Modified w false, tak jak zmiany juz zapisane
    SynEditCode.Modified:= false;
  end //if
    //lub nazwa nie znan, odwolujemy sie do Zapisz Jak...:
  else MenuSaveAsClick(Sender);
end;

procedure TForm1.MenuNewFileClick(Sender: TObject);
begin
   SynEditCode.Clear;
   MemoOutPut.Clear;
   MemoLogs.Clear;
end;

procedure TForm1.MenuOpcjeProjektuClick(Sender: TObject);
begin
  FormOpcjeProjektu.ShowModal;
end;

procedure TForm1.MenuOpenClick(Sender: TObject);
begin
  SynEditCode.Clear;
  MemoOutPut.Clear;
  MemoLogs.Clear;
  if OD.Execute then
  begin
    SynEditCode.Lines.LoadFromFile(OD.FileName);
    OpenFileProject := ChangeFileExt(ExtractFileName(OD.FileName), '');
   // ShowMessage(OpenFileProject);
   Caption := 'IDE Avocado V 1.0.0.1 ' + 'Otwarty projekt: ' + OpenFileProject;
  end;
end;

procedure TForm1.MenuSaveAsClick(Sender: TObject);
begin
  SaveCodeToFile;
end;

procedure TForm1.MenuUstawiniaClick(Sender: TObject);
begin
  FormSettingIntepreter.ShowModal;
end;


procedure TForm1.ToolButton1Click(Sender: TObject);
begin
  //CompileToPascal;
  try
    MemoOutPut.Clear;
    FTranslatedCode.Assign(FTranslator.Translate(SynEditCode.Lines));
    MemoOutPut.Lines.Add('{=== Free Pascal Code ===}');
    MemoOutPut.Lines.Add(FTranslatedCode.Text);
    //BtnCompile.Enabled := True;
  except
    on E: Exception do
      MemoOutPut.Lines.Add('Translation Error: ' + E.Message);
  end;
end;

procedure TForm1.ToolButton2Click(Sender: TObject);
var
  ExeName: string;
  DlgResult: integer;
begin
  if FTranslatedCode.Count = 0 then
    begin
      ShowMessage('Najpierw przetłumacz kod Avocado!');
      MessageDlg('Uwaga!','Najpierw przetłumacz kod Avocado!',mtInformation, [mbOk, mbCancel],0);
      Exit;
    end;
  if SD.FileName = '' then
  Begin
    DlgResult := MessageDlg('Uwaga!','Zapisz projekt a dalej kompiluj',mtInformation, [mbOk, mbCancel],0); // Przypisujemy wynik do zmiennej
    if DlgResult = mrOk then
      SaveCodeToFile;
  end
  else
  Begin
    //ExeName := ChangeFileExt(Application.ExeName, SaveFileProject);
    //ExeName := ChangeFileExt(SaveFileProject, '.exe');
     ExeName := ChangeFileExt(FileNamePr, '.exe');
    CompilePascalCode(FTranslatedCode.Text, ExeName);
    //W trybie release
    //Niby release
    //KompilacjaKoduwPascal(FTranslatedCode.Text, ExeName);
  end;

end;


procedure TForm1.LoadFpc;
begin
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
    FFpcPath := Ini.ReadString('main', 'fpc', '');
  finally
    Ini.Free;
  end;
end;



procedure TForm1.SaveCodeToFile;
begin
  SD.DefaultExt := 'avocado';
  SD.Filter := 'Avocado files (*.avocado)|*.avocado|All files (*.*)|*.*';
  if SD.Execute then
  begin
    SynEditCode.Lines.SaveToFile(SD.FileName);
    SaveFileProject := ChangeFileExt(ExtractFileName(SD.FileName), '');
    //Zspisuje sciezke
    FileNamePr := SD.FileName;
    //ShowMessage(FileNamePr);
  end;
end;

procedure TForm1.CompilePascalCode(const PascalCode, OutputFile: string);
var
  AProcess: TProcess;
  TempFile: string;
  OutputLines: TStringList;
begin
  if SaveFileProject = '' then
    begin
      MemoLogs.Lines.Add('Błąd: Projekt nie został zapisany. Zapisz projekt przed kompilacją.');
      Exit; // Wyjście z procedury
    end;

    TempFile := ChangeFileExt(SaveFileProject, '.pas');

    try
      // Zapis kodu do pliku tymczasowego
      if PascalCode <> '' then
      begin
         OutputLines := TStringList.Create;
        try
          OutputLines.Text := PascalCode;
          OutputLines.SaveToFile(TempFile);
        finally
          OutputLines.Free;
        end;
      end
      else
      begin
         MemoOutPut.Lines.SaveToFile(TempFile); // Zapis z MemoOutPut jeśli PascalCode jest pusty
      end;

      AProcess := TProcess.Create(nil);
      OutputLines := TStringList.Create;
      try
        AProcess.Executable := FFpcPath;
        if not FileExists(FFpcPath) then
          raise Exception.Create('Nie znaleziono kompilatora Free Pascal w: ' + FFpcPath);

        AProcess.Parameters.Add(TempFile);
        AProcess.Parameters.Add('-o' + Trim(OutputFile));
        AProcess.Options := [poUsePipes, poStderrToOutput];
        AProcess.ShowWindow := swoHIDE;

        MemoLogs.Lines.Add('Rozpoczynanie kompilacji...');

        AProcess.Execute;
        AProcess.WaitOnExit;
        OutputLines.LoadFromStream(AProcess.Output);
        MemoLogs.Lines.AddStrings(OutputLines);

        if AProcess.ExitStatus = 0 then
        begin
          MemoLogs.Lines.Add('Kompilacja udana! Plik wyjściowy: ' + OutputFile);
          DeleteFile(TempFile); // Usuń plik tymczasowy
        end
        else
          MemoLogs.Lines.Add('Błąd kompilacji. Kod: ' + IntToStr(AProcess.ExitStatus));

      finally
        AProcess.Free;
        OutputLines.Free;
      end;
    except
      on E: Exception do
        MemoLogs.Lines.Add('Błąd kompilacji: ' + E.Message);
    end;
  end;


procedure TForm1.KompilacjaKoduwPascal(const Code, OutputFile: string);
var
  AProcess: TProcess;
  TempFile: string;
  OutputLines: TStringList;
  BuildMode: string; // Dodajemy zmienną BuildMode
begin
  if SaveFileProject = '' then
    begin
    end;

    TempFile := ChangeFileExt(SaveFileProject, '.pas');

    // Ustaw tryb kompilacji na Release (możesz to przekazywać jako parametr do funkcji)
    BuildMode := 'Release'; // Domyślnie ustawiamy tryb Release, możesz to zmienić

    try
      MemoOutPut.Lines.SaveToFile(TempFile);
      AProcess := TProcess.Create(nil);
      OutputLines := TStringList.Create;
      try
        AProcess.Executable := FFpcPath; //link do fpc
        AProcess.Parameters.Add(TempFile);
        AProcess.Parameters.Add('-o' + Trim(OutputFile));

        // Dodajemy opcje dla trybu Release
        if BuildMode = 'Release' then
        begin
          MemoLogs.Lines.Add('Kompilacja w trybie Release...');
          AProcess.Parameters.Add('-O3');     // Poziom optymalizacji 2
          AProcess.Parameters.Add('-Os'); //Mniejsze niz szybsze
          AProcess.Parameters.Add('-CX'); //Sprytne laczenie
          AProcess.Parameters.Add('-XX'); //Laczenie Sprytne
          AProcess.Parameters.Add('-g-');     // Wyłączenie informacji debugowych
        end else
        begin
          MemoLogs.Lines.Add('Kompilacja w trybie Debug...'); // Domyślny tryb Debug (bez optymalizacji i z debug info)
          // Możesz dodać opcje specyficzne dla Debug, np. -g+ (włączenie debug info, jeśli domyślnie jest wyłączone)
        end;


        AProcess.Options := [poUsePipes, poStderrToOutput];
        AProcess.ShowWindow := swoHIDE;

        MemoLogs.Lines.Add('Rozpoczynanie kompilacji...');

        AProcess.Execute;
        AProcess.WaitOnExit; // Czekaj na zakończenie kompilacji
        OutputLines.LoadFromStream(AProcess.Output);
        MemoLogs.Lines.AddStrings(OutputLines);


        if AProcess.ExitStatus = 0 then
          MemoLogs.Lines.Add('Kompilacja udana! Plik wyjściowy: ' + OutputFile)
        else
          MemoLogs.Lines.Add('Błąd kompilacji. Kod: ' + IntToStr(AProcess.ExitStatus));

      finally
        AProcess.Free;
        OutputLines.Free;
      end;
    except
      on E: Exception do
        MemoLogs.Lines.Add('Błąd kompilacji: ' + E.Message);
    end;
end;


destructor TForm1.Destroy;
begin
  FTranslator.Free;
  FTranslatedCode.Free;
  inherited Destroy;
end;


{ TInterpreterThread }

constructor TInterpreterThread.Create(const AInterpreterPath, ATempFile: string; AConsole: TSynEdit);
begin
  inherited Create(False); // uruchomienie wątku
  FreeOnTerminate := True;
  FConsole := AConsole;
  // Konfiguracja procesu
  FProcess := TProcess.Create(nil);
  FProcess.Executable := AInterpreterPath;
  FProcess.Parameters.Add(ATempFile);
  FProcess.Options := [poUsePipes];
  // Ustawienie ukrycia konsoli (działa na Windows)
  FProcess.ShowWindow := swoHIDE;
  FProcess.Execute;
end;

procedure TInterpreterThread.SyncAppendOutput;
begin
  // Dodaj odczytany tekst do kontrolki – tutaj tekst jest dopisywany
  FConsole.SelStart := Length(FConsole.Text);
  FConsole.SelText := FOutput;
end;

procedure TInterpreterThread.Execute;
var
  Buffer: array[0..1023] of byte;
  BytesRead: Longint;
  NewText: string;
begin
  // Pętla wykonuje się, dopóki proces działa lub są dostępne dane
  while FProcess.Running or (FProcess.Output.NumBytesAvailable > 0) do
  begin
    BytesRead := FProcess.Output.Read(Buffer, SizeOf(Buffer));
    if BytesRead > 0 then
    begin
      SetString(NewText, PAnsiChar(@Buffer[0]), BytesRead);
      FOutput := NewText;
      Synchronize(@SyncAppendOutput);
    end
    else
      Sleep(50);
  end;
  FProcess.Free;
end;

end.


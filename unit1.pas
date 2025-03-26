unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, ActnList, SynEdit, SynPopupMenu, SynCompletion,
  SynMacroRecorder, SynPluginSyncroEdit, SynHighlighterHTML, SynHighlighterPas,
  SynHighlighterTeX, SynHighlighterDiff, SynHighlighterMulti, SynHighlighterAny,
  SynHighlighterPo, laz.VTHeaderPopup, Process, IniFiles, AvocadoTranslator,
  ShellAPI;

type
  { TForm1 }
  TForm1 = class(TForm)
    MenuINformacjaIDE: TMenuItem;
    SynAnySyn1: TSynAnySyn;
    SynAutoComplete1: TSynAutoComplete;
    SynMacroRecorder1: TSynMacroRecorder;
    SynMultiSyn1: TSynMultiSyn;
    SynPoSyn1: TSynPoSyn;
    Transpiluj: TAction;
    ZapiszPlik: TAction;
    NowyPlik: TAction;
    Label1: TLabel;
    Label2: TLabel;
    MemoLogs: TMemo;
    MemoOutPut: TMemo;
    MenuItem3: TMenuItem;
    MenuAboutProgram: TMenuItem;
    MenuAutor: TMenuItem;
    MenuItemDokumentacja: TMenuItem;
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
    Kompiluj: TAction;
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
    procedure MenuINformacjaIDEClick(Sender: TObject);
    procedure TranspilujExecute(Sender: TObject);
    procedure NowyPlikExecute(Sender: TObject);
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
    procedure MenuItemDokumentacjaClick(Sender: TObject);
    procedure MenuItemOutputCodeClearClick(Sender: TObject);
    procedure MenuItemPasteClick(Sender: TObject);
    procedure MenuItemPasteCodeClick(Sender: TObject);
    procedure MenuItemSaveFileClick(Sender: TObject);
    procedure MenuNewFileClick(Sender: TObject);
    procedure MenuOpcjeProjektuClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuUstawiniaClick(Sender: TObject);
    procedure KompilujExecute(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure ZapiszPlikExecute(Sender: TObject);
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
    //Dotyczy nazwy programu
    procedure ExtractProgramFromSynEdit;
    function ExtractProgramName(const Line: string): string;
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
  FFpcBasePath:string;
  FLclBasePath:string;
  FModulsPath: string;
  FTargetPlatform:string;
  //Tymczasowy plik.pas
  FTempFiles: string;
  FPC_Path: string;
  FPC_Params: TStringList;
  //Nazwa pliku
  FileNamePr: String;
  ZapisanaNazwaPliku: String;
  //Sciezka pliku
  SaveFileProject: String;
  //Otwarta sciezka pliku
  OpenFileProject: String;
  NameProgram: String;


implementation

uses
 usettings,unitopcjeprojektu,unitoprogramie,unitautor,uinformacjaoide;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadFpc;
  // Ustalanie ścieżki do pliku tymczasowego
  //FTempFile := ExtractFilePath(Application.ExeName) + 'temp.avocado';
  //Zapisuje plik tymaczosowy tam gdzie jest zapisany projekt
  FTempFile := SaveFileProject + 'temp.avocado';
  //Dodanie zanków polksich
  SynAnySyn1.IdentifierChars := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyząćęłńóśźżĄĆĘŁŃÓŚŹŻ';
  SynEditCode.Repaint; //Opcjonalne, ale czasami konieczne.
end;

procedure TForm1.TranspilujExecute(Sender: TObject);
begin
  ToolButton1Click(sender);
end;

procedure TForm1.MenuINformacjaIDEClick(Sender: TObject);
begin
  Finformacjaide.ShowModal;
end;

procedure TForm1.NowyPlikExecute(Sender: TObject);
begin
  MenuNewFileClick(sender);
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

procedure TForm1.MenuItemDokumentacjaClick(Sender: TObject);
begin
  FormAutor.OpenLink('https://avocado.dimitalart.pl/#dokumentacja');
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
var
  sFileName: string;
begin
   if OD.FileName <> '' then
    sFileName := OD.FileName
  else if SD.FileName <> '' then
    sFileName := SD.FileName
  else
    sFileName := '';

  if sFileName <> '' then
  begin
    SynEditCode.Lines.SaveToFile(sFileName);
    SynEditCode.Modified := False;
  end
  else
    MenuSaveAsClick(Sender);
  {
  if OD.FileName <> '' then begin
    SynEditCode.Lines.SaveToFile(OD.FileName);
  end;
   //jesli imię znane to nie trzeba wywowywowylac SaveDialog
  //wtedy tylko SaveToFile.
  if SD.FileName <> '' then begin
    SynEditCode.Lines.SaveToFile(SD.FileName);
    //ustawiam Modified w false, tak jak zmiany juz zapisane
    SynEditCode.Modified:= false;
  end //if
    //lub nazwa nie znan, odwolujemy sie do Zapisz Jak...:
  else MenuSaveAsClick(Sender);
  }
end;

procedure TForm1.MenuNewFileClick(Sender: TObject);
begin
  if InputQuery('Nowy plik', 'Podaj nazwę programu:', NameProgram) then
  begin
    // Czyścimy edytor kodu oraz okna logów i outputu
    SynEditCode.Clear;
    MemoOutPut.Clear;
    MemoLogs.Clear;
    // Dodajemy początkową deklarację programu na podstawie wprowadzonej nazwy
    SynEditCode.Lines.Add('program ' + NameProgram);
    // Przykładowo możemy też ustawić OpenFileProject lub inną zmienną
    //OpenFileProject := NameProgram;
  end;

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
   Caption := 'IDE Avocado v 1.0.0.3 ' + 'Otwarty projekt: ' + OpenFileProject;
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

procedure TForm1.KompilujExecute(Sender: TObject);
begin
  ToolButton2Click(Sender);
end;


procedure TForm1.ToolButton1Click(Sender: TObject);
begin
 ExtractProgramFromSynEdit;
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
   sFileName: string;
   DlgResult: Integer;
   OutputFolder: string;
begin
 // Sprawdzenie, czy plik jest otwarty (OD) lub zapisany (SD)

  if OD.FileName <> '' then
    sFileName := OD.FileName
  else if SD.FileName <> '' then
    sFileName := SD.FileName
  else
    sFileName := '';

  //sFileName := NameProgram;



 //NameProgram
  // Jeśli plik nie został zapisany, wymuszamy zapisanie przed kompilacją
  if sFileName = '' then
  begin
    DlgResult := MessageDlg('Uwaga!', 'Projekt nie został zapisany. Zapisz projekt przed kompilacją?',
                            mtConfirmation, [mbYes, mbNo], 0);
    if DlgResult = mrYes then
    begin
      MenuSaveAsClick(Sender); // Wywołanie "Zapisz jako..."
      if SD.FileName <> '' then
        sFileName := SD.FileName // Aktualizacja nazwy pliku po zapisaniu
      else
      begin
        MessageDlg('Błąd', 'Nie zapisano pliku. Kompilacja anulowana.', mtError, [mbOk], 0);
        Exit; // Jeśli użytkownik anulował zapis, kończymy procedurę
      end;
    end
    else
    begin
      MessageDlg('Błąd', 'Projekt nie został zapisany. Kompilacja anulowana.', mtError, [mbOk], 0);
      Exit; // Jeśli użytkownik odmówił zapisu, kończymy procedurę
    end;
  end;

  // Wyodrębniamy folder, w którym zapisany został plik
  OutputFolder := ExtractFilePath(sFileName);


  // Ustawienie nazwy pliku wynikowego na podstawie folderu oraz zmiennej NameProgram
  ExeName := IncludeTrailingPathDelimiter(OutputFolder) + NameProgram + '.exe';
  // Ustawienie ExeName na podstawie zapisanego pliku
  //ExeName := ChangeFileExt(NameProgram, '.exe');
  //ExeName := ChangeFileExt(sFileName, '.exe');

  // Kompilujemy kod Pascala – funkcja CompilePascalCode przyjmuje tekst kodu i ścieżkę do pliku .exe
  CompilePascalCode(FTranslatedCode.Text, ExeName);

  // Jeśli plik .exe został poprawnie wygenerowany, uruchamiamy go
  if FileExists(ExeName) then
    ShellExecute(Handle, 'open', PChar(ExeName), nil, nil, 1)
  else
    MessageDlg('Błąd', 'Nie udało się uruchomić programu: ' + ExeName, mtError, [mbOk], 0);

end;

procedure TForm1.ZapiszPlikExecute(Sender: TObject);
begin
  SaveCodeToFile;
end;


procedure TForm1.LoadFpc;
begin
  MemoLogs.Lines.Add('Wczytywanie ustawień');
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
    FFpcPath := Ini.ReadString('main', 'fpc', '');
    FFpcBasePath := Ini.ReadString('main', 'FpcBasePath', '');
    FTargetPlatform := Ini.ReadString('main', 'TargetPlatform', '');
    FLclBasePath := Ini.ReadString('main', 'LclBasePath', ''); // Odczytaj, nawet jeśli opcjonalne
    FModulsPath := Ini.ReadString('main', 'Units', '');

   // --- Walidacja wczytanych ustawień (bez odgadywania) ---
    if (FFpcPath = '') or not FileExists(FFpcPath) then
    begin
      MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka kompilatora FPC (FpcPath) nie istnieje lub nie jest ustawiona w ' + FFpcPath);
      // Tutaj możesz rozważyć poważniejsze działania, np. zablokowanie możliwości kompilacji
    end;

    if FFpcBasePath = '' then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Ścieżka bazowa FPC (FpcBasePath) nie jest ustawiona w ' + FFpcBasePath + '. Standardowe jednostki FPC nie zostaną znalezione!');
    end
    else if not DirectoryExists(FFpcBasePath) then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Skonfigurowana ścieżka bazowa FPC (FpcBasePath) nie istnieje: ' + FFpcBasePath);
       // FFpcBasePath := ''; // Można wyczyścić, aby dalsze operacje na pewno się nie udały
    end;

    if FTargetPlatform = '' then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Platforma docelowa (TargetPlatform) nie jest ustawiona w ' + FTargetPlatform + '. Nie można określić katalogu jednostek!');
    end;

    // Sprawdzenie LclBasePath (mniej krytyczne, chyba że LCL jest wymagany)
    if (FLclBasePath <> '') and not DirectoryExists(FLclBasePath) then
    begin
        MemoLogs.Lines.Add('OSTRZEŻENIE: Skonfigurowana ścieżka LCL (LclBasePath) nie istnieje: ' + FLclBasePath);
        // FLclBasePath := ''; // Opcjonalnie wyczyść
    end;
    //Sprawdza FModulsPath sciezke moduly
    if FModulsPath = '' then
       begin
          MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: brak ustawionej ścieżki do modułów ' + FModulsPath + '. Nie można określić katalogu jednostek!');
       end;


    MemoLogs.Lines.Add('Ustawienia kompilatora wczytane.');
    MemoLogs.Lines.Add(' FpcPath: ' + FFpcPath);
    MemoLogs.Lines.Add(' FpcBasePath: ' + FFpcBasePath);
    MemoLogs.Lines.Add(' TargetPlatform: ' + FTargetPlatform);
    MemoLogs.Lines.Add(' Moduły: ' + FModulsPath);
    if FLclBasePath <> '' then
      MemoLogs.Lines.Add(' LclBasePath: ' + FLclBasePath);
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
    ZapisanaNazwaPliku := ChangeFileExt(ExtractFileName(SD.FileName), '');
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
  FpcUnitPath, LclUnitPath, SourceDir: string;
  IdeDirectory, IdeModulesPath: string;
begin
   // --- Sprawdzenie krytycznych ustawień ---
  if (FFpcPath = '') or not FileExists(FFpcPath) then
  begin
     MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka do kompilatora FPC (FpcPath) nie jest poprawnie skonfigurowana w pliku INI!');
     Exit; // Przerwij kompilację
  end;
  if (FFpcBasePath = '') then // Sprawdź, czy BasePath jest ustawiony
  begin
     MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka bazowa FPC (FpcBasePath) nie jest skonfigurowana w pliku INI!');
     Exit; // Przerwij kompilację
  end;
  // Dodatkowe sprawdzenie, czy katalog BasePath istnieje (już mogło być w LoadSettings, ale dla pewności)
  if not DirectoryExists(FFpcBasePath) then
  begin
     MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Skonfigurowana ścieżka bazowa FPC (' + FFpcBasePath + ') nie istnieje!');
     Exit; // Przerwij kompilację
  end;
  if FModulsPath = '' then // Sprawdź, czy moduly sa ustawione
  begin
     MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: brak ustawionej ścieżki do modułów ' + FModulsPath + '. Nie można określić katalogu jednostek!');
     Exit; // Przerwij kompilację
  end;

  if FTargetPlatform = '' then // Sprawdź, czy TargetPlatform jest ustawiony
  begin
     MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Platforma docelowa (TargetPlatform) nie jest skonfigurowana w pliku INI!');
     Exit; // Przerwij kompilację
  end;
  {
  // Sprawdzenie, czy projekt został zapisany (OpenFileProject i SaveFileProject nie są puste)
   if OpenFileProject = '' then
   begin
     MemoLogs.Lines.Add('Błąd: OpenFileProject pusty. Projekt nie został zapisany. Zapisz projekt przed kompilacją.');
     //Exit;
   end
   else if SaveFileProject = '' then
   begin
     MemoLogs.Lines.Add('Błąd: SaveFileProject pusty. Projekt nie został zapisany. Zapisz projekt przed kompilacją.');
     Exit;
   end
   else
   begin
   }
     // Ustalamy plik tymczasowy na podstawie SaveFileProject (zmiana rozszerzenia na .pas)
    // TempFile := ChangeFileExt(SaveFileProject, '.pas');
     // Ustalanie pliku tymczasowego na podstawie SaveFileProject lub, jeśli jest pusty, OpenFileProject

  if SaveFileProject <> '' then
        TempFile := ChangeFileExt(SaveFileProject, '.pas')
      else
        TempFile := ChangeFileExt(OpenFileProject, '.pas');

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
         // Jeśli PascalCode jest pusty, zapisujemy zawartość MemoOutPut
         //MemoOutPut.Lines.SaveToFile(TempFile);
         if MemoOutPut.Lines.Count > 0 then
          MemoOutPut.Lines.SaveToFile(TempFile)
        else
        begin
          MemoLogs.Lines.Add('Błąd: Brak kodu do kompilacji.');
          Exit;
        end;

       // Utworzenie procesu kompilacji
       AProcess := TProcess.Create(nil);
       OutputLines := TStringList.Create;
       try


 {// Sprawdzenie, czy kompilator Free Pascal (FFpcPath) istnieje
 if not FileExists(FFpcPath) then
   raise Exception.Create('Nie znaleziono kompilatora Free Pascal w: ' + FFpcPath);
   }
           AProcess.Executable := FFpcPath;
           AProcess.Parameters.Add(TempFile);

           FpcUnitPath := IncludeTrailingPathDelimiter(FFpcBasePath) + 'units' + PathDelim + FTargetPlatform;
            if DirectoryExists(FpcUnitPath) then
              AProcess.Parameters.Add('-Fu' + FpcUnitPath)
            else
            MemoLogs.Lines.Add('BŁĄD: Nie znaleziono wymaganego katalogu standardowych jednostek FPC: ' + FpcUnitPath);
          // Można by tutaj przerwać, jeśli standardowe jednostki są absolutnie wymagane
          // Exit;
           // 2. Ścieżka do jednostek LCL (jeśli skonfigurowano i istnieje)
        if (FLclBasePath <> '') and DirectoryExists(FLclBasePath) then
        begin
           // Mamy pewność, że FTargetPlatform nie jest pusty
           LclUnitPath := IncludeTrailingPathDelimiter(FLclBasePath) + 'units' + PathDelim + FTargetPlatform;
           if DirectoryExists(LclUnitPath) then
              AProcess.Parameters.Add('-Fu' + LclUnitPath)
           else
             MemoLogs.Lines.Add('OSTRZEŻENIE: Nie znaleziono katalogu jednostek LCL (sprawdzono): ' + LclUnitPath);
        end;

        // 3. Ścieżka do katalogu z plikiem źródłowym (bez zmian)
        SourceDir := ExtractFilePath(TempFile);
        if SourceDir <> '' then
           AProcess.Parameters.Add('-Fu' + SourceDir);

        // === 4. DODAWANIE ŚCIEŻKI DO MODUŁÓW WZGLĘDEM PLIKU .EXE IDE ===
      IdeDirectory := ExtractFilePath(Application.ExeName); // Pobierz katalog, gdzie jest .exe Twojego IDE

      // *** WAŻNE: Zmień 'ModulyWlasne' na rzeczywistą nazwę Twojego folderu ***
      IdeModulesPath := IncludeTrailingPathDelimiter(IdeDirectory) + 'moduly';

      MemoLogs.Lines.Add('Sprawdzanie katalogu własnych modułów IDE: ' + IdeModulesPath);
      if DirectoryExists(IdeModulesPath) then
      begin
        AProcess.Parameters.Add('-Fu' + IdeModulesPath);
        MemoLogs.Lines.Add(' - Dodano ścieżkę własnych modułów IDE: ' + IdeModulesPath);
      end
      else
      begin
         // Informacja, że katalogu nie znaleziono - nie musi to być błąd krytyczny
         MemoLogs.Lines.Add(' - Informacja: Nie znaleziono katalogu własnych modułów IDE: ' + IdeModulesPath + '. Kompilator nie będzie tam szukał.');
      end;

         // --- KONIEC DODAWANIA ŚCIEŻEK ---

         AProcess.Parameters.Add('-o' + Trim(OutputFile));
         AProcess.Options := [poUsePipes, poStderrToOutput];
         AProcess.ShowWindow := swoHIDE;

         //MemoLogs.Lines.Add('Rozpoczynanie kompilacji...');
         MemoLogs.Lines.Add('Rozpoczynanie kompilacji z parametrami: ' + AProcess.Parameters.Text);
         AProcess.Execute;
         AProcess.WaitOnExit;

         OutputLines.LoadFromStream(AProcess.Output);
         MemoLogs.Lines.AddStrings(OutputLines);

         if AProcess.ExitStatus = 0 then
         begin
           MemoLogs.Lines.Add('Kompilacja udana! Plik wyjściowy: ' + OutputFile);
           if FileExists(TempFile) then
             DeleteFile(TempFile); // Usuwamy plik tymczasowy
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
//end;

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

procedure TForm1.ExtractProgramFromSynEdit;
var
i: Integer;
NProgram: string;
begin
  NProgram := '';
    // Przeszukujemy wszystkie linie w komponencie SynEditCode
    for i := 0 to SynEditCode.Lines.Count - 1 do
    begin
      NProgram := ExtractProgramName(SynEditCode.Lines[i]);
      if NProgram <> '' then
        Break;
    end;
    if NProgram <> '' then
    begin
      // Przykładowo, wyświetlamy wynik lub przypisujemy do zmiennej globalnej
      //ShowMessage('Nazwa programu: ' + NProgram);
      // Możesz też zapisać nazwę do jakiejś zmiennej globalnej lub innego pola
      NameProgram := NProgram;
    end
    else
      ShowMessage('Nie znaleziono deklaracji programu' + #10 + 'Dodaj na początku słowo kluczowe program i nazwe programu.');
end;

function TForm1.ExtractProgramName(const Line: string): string;
var
  Words: TStringList;
begin
  Result := '';
    Words := TStringList.Create;
    try
      // Rozdzielamy ciąg na słowa - białe znaki jako separatory
      ExtractStrings([' ', #9], [], PChar(Line), Words);
      // Sprawdzamy czy pierwszy element to 'program' (niezależnie od wielkości liter)
      if (Words.Count >= 2) and (LowerCase(Words[0]) = 'program') then
        Result := Words[1];
    finally
      Words.Free;
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


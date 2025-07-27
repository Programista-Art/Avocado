unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, ActnList, BCExpandPanels, BCImageButton, BCPanel,
  SynEdit, SynPopupMenu, SynCompletion, SynMacroRecorder, SynPluginSyncroEdit,
  SynHighlighterHTML, SynHighlighterPas, SynHighlighterTeX, SynHighlighterDiff,
  SynHighlighterMulti, SynHighlighterAny, SynHighlighterPo, laz.VTHeaderPopup,
  PrintersDlgs, Process, IniFiles, AvocadoTranslator, ShellAPI;

type
  { TForm1 }
  TForm1 = class(TForm)
    BCExpandPanel1: TBCExpandPanel;
    EditAskPromt: TEdit;
    MemoAnswerChatGPT: TMemo;
    Label2: TLabel;
    PanelAiChatGPT: TPanel;
    PanelTranspilacja: TBCExpandPanel;
    IdleTimer1: TIdleTimer;
    Label1: TLabel;
    MemoLogs: TMemo;
    MenuINformacjaIDE: TMenuItem;
    MenuItemWsparcieprojektu: TMenuItem;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    PanelDolnynadKosnola: TPanel;
    sbzapytaj: TSpeedButton;
    StatusBar: TStatusBar;
    SynAnySyn1: TSynAnySyn;
    SynAutoComplete1: TSynAutoComplete;
    SynEditCode: TSynEdit;
    SynMultiSyn1: TSynMultiSyn;
    Transpiluj: TAction;
    ZapiszPlik: TAction;
    NowyPlik: TAction;
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
    SynPopupMenuCode: TSynPopupMenu;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    procedure IdleTimer1StartTimer(Sender: TObject);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure MenuINformacjaIDEClick(Sender: TObject);
    procedure MenuItemWsparcieprojektuClick(Sender: TObject);
    procedure sbzapytajClick(Sender: TObject);
    procedure SynCompletion1BeforeExecute(ASender: TSynBaseCompletion;
      var ACurrentString: String; var APosition: Integer; var AnX,
      AnY: Integer; var AnResult: TOnBeforeExeucteFlags);
    procedure SynEditCodeChange(Sender: TObject);
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
    // Metoda callback do obsługi odpowiedzi ChatGPT
    procedure OnChatGPTResponse(const ResponseText: string);

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
  //Liczba znaków
  NumberWordSynEdit: Integer;
  PromptChatGPT: String;
  Token: String;
  ModelGPT,PromtAv,PromtS: String;


implementation

uses
 usettings,unitopcjeprojektu,unitoprogramie,unitautor,uinformacjaoide, uwsparcie,
 chatgptavocado,uchatgpt;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadFpc;
  //Zapisuje plik tymaczosowy tam gdzie jest zapisany projekt
  FTempFile := SaveFileProject + 'temp.avocado';
  //Dodanie zanków polksich
  SynAnySyn1.IdentifierChars := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyząćęłńóśźżĄĆĘŁŃÓŚŹŻ';
  SynEditCode.Repaint;
end;

procedure TForm1.TranspilujExecute(Sender: TObject);
begin
  ToolButton1Click(sender);
end;

procedure TForm1.MenuINformacjaIDEClick(Sender: TObject);
begin
  Finformacjaide.ShowModal;
end;

procedure TForm1.MenuItemWsparcieprojektuClick(Sender: TObject);
begin
  Wsparcie.ShowModal;
end;

procedure TForm1.sbzapytajClick(Sender: TObject);
//const
//  CHATGPT_TOKEN = 'sk-0tmz8yl8btgbMe1eQbPOEeCZ9HmjZkhHnt4jVHTvoET3BlbkFJxLdlT7wUc8Jf5ocslX4hR2p3QYo7Grr1us0cQbjzUA';
//  CHATGPT_MODEL = 'gpt-4o'; // lub 'gpt-4' jeśli masz dostęp
begin
  PromptChatGPT := EditAskPromt.Text;
  PromtAv := 'id": "pmpt_68859329bbf8819785a4dc10a207ba8d0b4314eef7a05871'+'"version": "2"';
  PromtS := PromtAv +' '+ PromptChatGPT;
  Token := 'sk-0tmz8yl8btgbMe1eQbPOEeCZ9HmjZkhHnt4jVHTvoET3BlbkFJxLdlT7wUc8Jf5ocslX4hR2p3QYo7Grr1us0cQbjzUA';
  ModelGPT := 'gpt-4o';
   if Trim(PromptChatGPT) = '' then
  begin
    ShowMessage('Proszę wpisać pytanie!');
    Exit;
  end;

  //MemoAnswerChatGPT.Clear;
  //MemoAnswerChatGPT.Lines.Add('Wysyłanie zapytania...');
  // Wyłącz przycisk podczas oczekiwania na odpowiedź
  sbzapytaj.Enabled := False;

  try
    // Wywołanie funkcji z naszego modułu
    ZapytajChatGPT(Token, ModelGPT, PromtS, @OnChatGPTResponse);
  except
    on E: Exception do
    begin
      ShowMessage('Błąd: ' + E.Message);
      sbzapytaj.Enabled := True;
    end;
  end;
end;

procedure TForm1.IdleTimer1StartTimer(Sender: TObject);
begin
  //IdleTimer1.Enabled := True;
end;





procedure TForm1.IdleTimer1Timer(Sender: TObject);
var
  i: TModalResult;
begin
  {
  IdleTimer1.Enabled := False;
  StatusBar.Panels.Items[2].Text :=' Aplikacja jest bezczynna';
  i:= MessageDlg('Wykryto brak zmian w kodzie przez dłuższy czas. Czy potrzebujesz pomocy?',mtInformation,[mbOk,mbCancel],0);
  // Sprawdź, który przycisk kliknął użytkownik
  if i = mrOK then
  begin
    ShowMessage('Wybrano OK. Kontynuuję operację.');

  end
  else if i = mrCancel then
  begin
    //ShowMessage('Wybrano Anuluj. Operacja została przerwana.');
    IdleTimer1.Enabled := False;
  end;
  }
end;

procedure TForm1.SynCompletion1BeforeExecute(ASender: TSynBaseCompletion;
  var ACurrentString: String; var APosition: Integer; var AnX, AnY: Integer;
  var AnResult: TOnBeforeExeucteFlags);
begin

end;

procedure TForm1.SynEditCodeChange(Sender: TObject);
begin

 if Assigned(SynEditCode) then
  begin
    //transpiluje kod
    ToolButton1Click(sender);
    NumberWordSynEdit := Length(SynEditCode.Text);
    StatusBar.Panels.Items[0].Text := IntToStr(SynEditCode.Lines.Count) + ' Linii Kodu';
    StatusBar.Panels.Items[1].Text := IntToStr(NumberWordSynEdit) + ' Znaków';
    IdleTimer1.Enabled := False;
    IdleTimer1.Enabled := True;
  end;
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
   Caption := 'IDE Avocado v 1.0.0.5 ' + 'Otwarty projekt: ' + OpenFileProject;
   //Timer
    IdleTimer1.Enabled := True;
    ToolButton1Click(Sender);
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
  MemoLogs.Lines.Add(' Wczytywanie ustawień');
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
    FFpcPath := Ini.ReadString('main', 'fpc', '');
    FFpcBasePath := Ini.ReadString('main', 'FpcBasePath', '');
    FTargetPlatform := Ini.ReadString('main', 'TargetPlatform', '');
    FModulsPath := Ini.ReadString('main', 'Units', '\moduly');

   // --- Walidacja wczytanych ustawień (bez odgadywania) ---
    if (FFpcPath = '') or not FileExists(FFpcPath) then
    begin
      MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka do kompilatora FPC nie istnieje lub nie jest ustawiona w ' + FFpcPath);
      // Tutaj możesz rozważyć poważniejsze działania, np. zablokowanie możliwości kompilacji
    end;

    if FFpcBasePath = '' then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Ścieżka bazowa do foldera kompilatora FPC nie jest ustawiona w ' + FFpcBasePath + '. Standardowe jednostki FPC nie zostaną znalezione!');
    end
    else if not DirectoryExists(FFpcBasePath) then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Skonfigurowana ścieżka bazowa FPC (FpcBasePath) nie istnieje: ' + FFpcBasePath);
       // FFpcBasePath := ''; // Można wyczyścić, aby dalsze operacje na pewno się nie udały
    end;

    if FTargetPlatform = '' then
    begin
       MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: Platforma docelowa nie jest ustawiona w ' + FTargetPlatform + '. Nie można określić katalogu jednostek!');
    end;

    //Sprawdza FModulsPath sciezke moduly
    if FModulsPath = '' then
       begin
          MemoLogs.Lines.Add('BŁĄD KONFIGURACJI: brak ustawionej ścieżki do modułów ' + FModulsPath + '. Nie można określić katalogu jednostek!');
       end;


    MemoLogs.Lines.Add(' Ustawienia kompilatora wczytane.');
    MemoLogs.Lines.Add(' Link do kompilatora fpc.exe: ' + FFpcPath);
    MemoLogs.Lines.Add(' Link do folderu kompilatora : ' + FFpcBasePath);
    MemoLogs.Lines.Add(' Platforma: ' + FTargetPlatform);
    MemoLogs.Lines.Add(' Moduły: ' + FModulsPath);

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
  FpcUnitPath, SourceDir: string; // Usunięto LclUnitPath, LazarusUnitPath
  IdeDirectory, IdeModulesPath: string;
  UserModulesPath: string;
begin
  // --- Sprawdzenie krytycznych ustawień (bez LCL/Lazarus paths) ---
  if (FFpcPath = '') or not FileExists(FFpcPath) then
  begin
    MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka do kompilatora FPC (FpcPath) nie jest poprawnie skonfigurowana!');
    Exit;
  end;
  if (FFpcBasePath = '') or not DirectoryExists(FFpcBasePath) then
  begin
    MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Ścieżka bazowa FPC (FpcBasePath) nie jest poprawnie skonfigurowana lub nie istnieje!');
    Exit;
  end;
  UserModulesPath := FModulsPath;
  if (UserModulesPath <> '') and not DirectoryExists(UserModulesPath) then
  begin
     MemoLogs.Lines.Add('OSTRZEŻENIE: Skonfigurowana ścieżka do modułów użytkownika (FModulsPath: ' + UserModulesPath + ') nie istnieje!');
     UserModulesPath := '';
  end;
  if FTargetPlatform = '' then
  begin
    MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Platforma docelowa (TargetPlatform) nie jest skonfigurowana!');
    Exit;
  end;
  // Usunięto sprawdzanie FLclBasePath i FLazarusBasePath

  // Sprawdzenie kodu wejściowego
  if Trim(PascalCode) = '' then
  begin
      MemoLogs.Lines.Add('Błąd: Brak kodu Pascala do kompilacji (parametr PascalCode jest pusty).');
      Exit;
  end;

  // Ustalanie nazwy pliku tymczasowego
  if SaveFileProject <> '' then
    TempFile := ChangeFileExt(SaveFileProject, '.pas')
  else if OpenFileProject <> '' then
     TempFile := ChangeFileExt(OpenFileProject, '.pas')
  else
     TempFile := ExtractFilePath(Application.ExeName) + 'temp_compile.pas';

  try
    // Zapis kodu do pliku tymczasowego
    OutputLines := TStringList.Create;
    try
      OutputLines.Text := PascalCode;
      OutputLines.SaveToFile(TempFile);
    finally
      OutputLines.Free;
    end;

    // Utworzenie procesu kompilacji
    AProcess := TProcess.Create(nil);
    OutputLines := TStringList.Create;
    try
      AProcess.Executable := FFpcPath;
      AProcess.Parameters.Add(TempFile);

      // --- Dodawanie ścieżek do jednostek (-Fu) - UPROSZCZONO ---

      // 1. Ścieżka do standardowych jednostek FPC
      FpcUnitPath := IncludeTrailingPathDelimiter(FFpcBasePath) + 'units' + PathDelim + FTargetPlatform;
      if DirectoryExists(FpcUnitPath) then
        AProcess.Parameters.Add('-Fu' + FpcUnitPath)
      else
        MemoLogs.Lines.Add('BŁĄD: Nie znaleziono wymaganego katalogu standardowych jednostek FPC: ' + FpcUnitPath);

      // 2. Ścieżka do jednostek LCL - USUNIĘTO

      // 3. Ścieżka do katalogu z plikiem źródłowym (TempFile)
      SourceDir := ExtractFilePath(TempFile);
      if SourceDir <> '' then
        AProcess.Parameters.Add('-Fu' + SourceDir);

      // 4. Ścieżka do własnych modułów użytkownika (z FModulsPath)
      if UserModulesPath <> '' then
      begin
        AProcess.Parameters.Add('-Fu' + UserModulesPath);
        MemoLogs.Lines.Add(' - Dodano ścieżkę modułów użytkownika: ' + UserModulesPath);
      end;

      // 5. Ścieżka do modułów dostarczonych z IDE (względna)
      IdeDirectory := ExtractFilePath(Application.ExeName);
      IdeModulesPath := IncludeTrailingPathDelimiter(IdeDirectory) + 'moduly';
      MemoLogs.Lines.Add('Sprawdzanie katalogu własnych modułów IDE: ' + IdeModulesPath);
      if DirectoryExists(IdeModulesPath) then
      begin
        if CompareText(IdeModulesPath, UserModulesPath) <> 0 then
        begin
           AProcess.Parameters.Add('-Fu' + IdeModulesPath);
           MemoLogs.Lines.Add(' - Dodano ścieżkę własnych modułów IDE: ' + IdeModulesPath);
        end
        else
            MemoLogs.Lines.Add(' - Informacja: Ścieżka modułów IDE jest taka sama jak modułów użytkownika, pomijanie duplikatu.');
      end
      else
        MemoLogs.Lines.Add(' - Informacja: Nie znaleziono katalogu własnych modułów IDE: ' + IdeModulesPath + '.');

      // 6. Ścieżka do jednostek Lazarusa - USUNIĘTO

      // --- Koniec dodawania ścieżek ---

      // Plik wyjściowy
      AProcess.Parameters.Add('-o' + Trim(OutputFile));

      // Opcje procesu
      AProcess.Options := [poUsePipes, poStderrToOutput];
      AProcess.ShowWindow := swoHIDE;

      // Uruchomienie kompilacji
      MemoLogs.Lines.Add('Rozpoczynanie kompilacji z parametrami: ' + AProcess.Parameters.Text);
      AProcess.Execute;
      AProcess.WaitOnExit;

      // Przechwycenie i wyświetlenie wyniku
      OutputLines.LoadFromStream(AProcess.Output);
      MemoLogs.Lines.AddStrings(OutputLines);

      // Sprawdzenie statusu zakończenia
      if AProcess.ExitStatus = 0 then
      begin
        MemoLogs.Lines.Add('Kompilacja udana! Plik wyjściowy: ' + OutputFile);
        // if FileExists(TempFile) then DeleteFile(TempFile);
      end
      else
      begin
        MemoLogs.Lines.Add('Błąd kompilacji. Kod: ' + IntToStr(AProcess.ExitStatus));
      end;

    finally
      AProcess.Free;
      OutputLines.Free;
    end;

  except
    on E: Exception do
      MemoLogs.Lines.Add('Błąd wykonania kompilacji: ' + E.Message);
  end;
  if FileExists(TempFile) then DeleteFile(TempFile);
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
      //ShowMessage('Nie znaleziono deklaracji programu' + #10 + 'Dodaj na początku słowo kluczowe program i nazwe programu.');
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

procedure TForm1.OnChatGPTResponse(const ResponseText: string);
begin
    try
      MemoAnswerChatGPT.Clear;

    if Trim(ResponseText) <> '' then
    begin
      MemoAnswerChatGPT.Lines.Add('Odpowiedź!');
      MemoAnswerChatGPT.Lines.Add('==================');
      MemoAnswerChatGPT.Lines.Add('');
      MemoAnswerChatGPT.Lines.Add(ResponseText);
      MemoAnswerChatGPT.Lines.Add('');
      MemoAnswerChatGPT.Lines.Add('==================');
      MemoAnswerChatGPT.Lines.Add('⏰' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    end
    else
    begin
      MemoAnswerChatGPT.Lines.Add('❌ Błąd: Otrzymano pustą odpowiedź');
      MemoAnswerChatGPT.Lines.Add('Sprawdź token API i połączenie internetowe');
    end;
  finally
    // Przywróć normalny stan interfejsu
    sbzapytaj.Enabled := True;
  end;

    {
  // Ta metoda zostanie wywołana, gdy otrzymamy odpowiedź
  try
    MemoAnswerChatGPT.Clear;
    MemoAnswerChatGPT.Lines.Add('Odpowiedź ChatGPT:');
    MemoAnswerChatGPT.Lines.Add('------------------');
    MemoAnswerChatGPT.Lines.Add(ResponseText);
  finally
    // Włącz ponownie przycisk
    sbzapytaj.Enabled := True;
  end;
  //ShowMessage('Odpowiedź z ChatGPT: ' + ResponseText);
  }
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


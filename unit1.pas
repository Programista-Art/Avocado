unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, ActnList, BCExpandPanels, BCFluentSlider,
  SynEdit, SynPopupMenu, SynCompletion,
  SynPluginSyncroEdit, SynHighlighterHTML, SynHighlighterPas, SynHighlighterTeX,
  SynHighlighterDiff, SynHighlighterMulti, SynHighlighterAny, SynHighlighterPo,
  laz.VTHeaderPopup, Process, IniFiles, AvocadoTranslator, ShellAPI, LazUTF8,
  LCLIntf, InterfaceBase,DefaultTranslator,LCLTranslator;

type
  { TFormMain }
  TFormMain = class(TForm)
    LRozmiarZccionkiEdytora: TLabel;
    MemoOutPut: TMemo;
    MenuExamples: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuIRosyjski: TMenuItem;
    MenuChinski: TMenuItem;
    MenuHindi: TMenuItem;
    MenuIArabski: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuIteFinski: TMenuItem;
    MenuIteGrecki: TMenuItem;
    itemJaponski: TMenuItem;
    MenuItem19: TMenuItem;
    ItemTools: TMenuItem;
    MenuItAiAsystant: TMenuItem;
    MenuItemTurkishLang: TMenuItem;
    MenuItemSwedishLang: TMenuItem;
    MenuItemSlovenianLang: TMenuItem;
    MenuItemLangSlovak: TMenuItem;
    MenuItemLangRomanian: TMenuItem;
    MenuItemLangLithuanian: TMenuItem;
    MenuItemLangLatvian: TMenuItem;
    MenuItemKoreanski: TMenuItem;
    MenuItIndonezyjski: TMenuItem;
    MenuItWegierski: TMenuItem;
    MenuItemEstonski: TMenuItem;
    MenuItemDansk: TMenuItem;
    MenuItemCzeski: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    RozmiarCzcionkiSynEditor: TBCFluentSlider;
    Label3: TLabel;
    Label4: TLabel;
    Label2: TLabel;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItemCopyAllPascalzCode: TMenuItem;
    MenuItemcopyPascalCode: TMenuItem;
    Panel5: TPanel;
    IdleTimer1: TIdleTimer;
    Label1: TLabel;
    MemoLogs: TMemo;
    MenuINformacjaIDE: TMenuItem;
    MenuItemWsparcieprojektu: TMenuItem;
    Panel3: TPanel;
    Panel4: TPanel;
    PanelDolnynadKosnola: TPanel;
    StatusBar: TStatusBar;
    SynAnySyn1: TSynAnySyn;
    SynAutoComplete1: TSynAutoComplete;
    SynEditCode: TSynEdit;
    SynMultiSyn1: TSynMultiSyn;
    Transpiluj: TAction;
    ZapiszPlik: TAction;
    NowyPlik: TAction;
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
    butCompileCode: TToolButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure itemJaponskiClick(Sender: TObject);
    procedure MenuExamplesClick(Sender: TObject);
    procedure MenuIArabskiClick(Sender: TObject);
    procedure MenuItAiAsystantClick(Sender: TObject);
    procedure MenuIteFinskiClick(Sender: TObject);
    procedure MenuIteGreckiClick(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem14Click(Sender: TObject);
    procedure MenuItem15Click(Sender: TObject);
    procedure MenuIRosyjskiClick(Sender: TObject);
    procedure MenuChinskiClick(Sender: TObject);
    procedure MenuHindiClick(Sender: TObject);
    procedure MenuItem16Click(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem18Click(Sender: TObject);
    procedure MenuItem19Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure MenuItemCzeskiClick(Sender: TObject);
    procedure MenuItemDanskClick(Sender: TObject);
    procedure MenuItemEstonskiClick(Sender: TObject);
    procedure MenuItemKoreanskiClick(Sender: TObject);
    procedure MenuItemLangLatvianClick(Sender: TObject);
    procedure MenuItemLangLithuanianClick(Sender: TObject);
    procedure MenuItemLangRomanianClick(Sender: TObject);
    procedure MenuItemLangSlovakClick(Sender: TObject);
    procedure MenuItemSlovenianLangClick(Sender: TObject);
    procedure MenuItemSwedishLangClick(Sender: TObject);
    procedure MenuItemTurkishLangClick(Sender: TObject);
    procedure MenuItIndonezyjskiClick(Sender: TObject);
    procedure MenuItWegierskiClick(Sender: TObject);
    procedure RozmiarCzcionkiSynEditorChangeValue(Sender: TObject);
    procedure MenuINformacjaIDEClick(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItemCopyAllPascalzCodeClick(Sender: TObject);
    procedure MenuItemcopyPascalCodeClick(Sender: TObject);
    procedure MenuItemWsparcieprojektuClick(Sender: TObject);
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
    procedure butCompileCodeClick(Sender: TObject);
    procedure ZapiszPlikExecute(Sender: TObject);
  private
    FTranslator: TAvocadoTranslator;
    FTranslatedCode: TStringList;
    //Laduje link do FPC kompilatora
    procedure LoadFpc;
    procedure SaveCodeToFile;
    procedure IsClickMainMenuLanguage(number: Integer);

    //Delete Kompilacja kodu release debug
    procedure KompilacjaKoduwPascal(const Code, OutputFile: string);
    //Dotyczy nazwy programu
    procedure ExtractProgramFromSynEdit;
    function ExtractProgramName(const Line: string): string;
    // Metoda callback do obsługi odpowiedzi ChatGPT
    procedure LoadTokenGPT;
    //procedure LoadLang;
    procedure CloseProgram;



  public
    procedure LoadAvocadoFileToEditor(const FileName: string);
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    //Code compilation / Kompilacja kodu
    procedure CompilePascalCode(const PascalCode, OutputFile: string);
   // function CompilePascalCode(const SourceFile, ExeFile: string): Boolean;
   procedure InternalLoadAvocadoFile(const FileName: string);
   procedure TranspilujKod;
  end;

  { TCompileThread }

  TCompileThread = class(TThread)
  private
    FCode: string;
    FExeName: string;
    FHandle: THandle;
    FOwner: TFormMain;
    FPascalCode: string;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
    procedure AfterCompile;
    procedure ShowSuccess;
    procedure ShowError;
  public

    constructor Create(Owner: TFormMain; const PascalCode, ExeName: string);
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
  FormMain: TFormMain;
  Ini,ini_lang: TIniFile;
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
  ExeName: string;
  //Ini
  IniEnd: TIniFile;
  FontSizeEditor: Integer;
  //Language
  lang: String;
  //Translated
  OpenProjectTranslatet: string;
  CharsTranslatet: string;

resourcestring
   NewProgramFile = 'New file';
   NewNamezprogram = 'Enter the name of the program:';
   CountLine = ' Lines of Code';
   CountChars = ' Signs';
   OpenProjectTranslate = 'Open project: ';
   TranslateAttention = 'Attention!';
   TranslateSaveProject = 'Project not saved. Save project before compiling?';
   TranslateMistake = 'Mistake';
   TranslateFilenotSaved = 'File not saved. Compilation canceled.';
   TranslateFilenotSavedBuildCancel = 'Project not saved. Build canceled.';
   TranslateSynEditCodeNotCreated = 'NOTE: SynEditCode not created!';
   TranslateEnterQuestion = 'Please enter your question!';
   TranslateTranslationError = 'Translation Error: ';
   TranslateLoadingSettings = 'Loading settings ';
   TranslateFPCCompilerNotExist = 'FATAL ERROR: The path to the FPC compiler does not exist or is not set in ';
   TranslateFpcConfigureErrPathToFpc = 'CONFIGURATION ERROR: Base path to FPC compiler folder is not set in ';
   TranslateStandardFPCunits = ' .Standard FPC units will not be found!';
   TranslateConfErrFpcBasePath = 'CONFIGURATION ERROR: The configured FPC base path (FpcBasePath) does not exist: ';
   TranslateConfErrTargetPlatform = 'CONFIGURATION ERROR: Target platform not set in ';
   TranslateUnableUnitDirectory = ' .Unable to determine unit directory!';
   TranslateConfErrModulePath = 'CONFIGURATION ERROR: no module path set ';
   TranslateCompilerSettLoaded = 'Compiler settings loaded';
   TranslateLinkToFpc = 'Link to fpc.exe compiler: ';
   TranslateLinkToFpcFolder = 'Link to compiler folder: ';
   TranslatePlatform = 'Platform: ';
   TranslateModules = 'Modules: ';
   TranslateErrPathToFpc = 'FATAL ERROR: The path to the FPC compiler (FpcPath) is not configured correctly!';
   TranslateErrFpcBasePathnotConfigure = 'FATAL ERROR: The FPC base path (FpcBasePath) is not configured correctly or does not exist!';
   TranslateErrUserModulesPath = 'WARNING: Configured user modules path (FModulsPath: ';
   TranslateNotExist = ' ) does not exist! ';
   TranslateErrPacalCodeCompile = 'Error: No Pascal code to compile (PascalCode parameter is empty). ';
   TranslateErrRequiredFPCstandardUnitDirfound = 'ERROR: Required FPC standard unit directory not found: ';
   TranslateAddUserModulesPath = ' - Added user modules path: ';
   TranslateCheckModulesDir = 'Checking the IDE s own modules directory: ';
   TranslateAddCustomModulesPath = ' - Added custom IDE modules path: ';
   TranslateIDeModulesPathSkipDuplicate = ' - Info: IDE modules path is same as user modules, skipping duplicate.';
   TranslateCustModulesDirNotFound = 'Info: IDE custom modules directory not found: ';
   TranslateStartComilationParam = 'Starting compilation with parameters: ';
   TranslateCompilationSuccses = 'Compilation successful! Output file: ';
   TranslateErrCompilationCode = 'Compilation error. Code: ';
   TranslateErrCompilation = 'Compilation error: ';
   TranslateCompilingReleaseMode = 'Compiling in Release mode.';
   TranslateCompilingDebugMode = 'Compiling in Debug mode...';
   TranslateStartComilation = 'Starting compilation...';
   TranslateComilationSuccessOutputFile = 'Compilation successful! Output file: ';
   TranslateAnswer = 'Answer!';
   TranslateErrEmptyResponseReceived = 'Error: Empty response received';
   TranslateCheckApiTokenInternetCon = 'Check API token and internet connection';
   TranslateNoTokenAiAssistant = 'No token from AI Assistant';
   TranslateAiHelperApiKeyAdded = 'AI Helper API Key Added';
   TranslateAiHelperModel = 'AI Helper Model: ';
   TranslateEditorFontSizeNoLoaded = 'Editor font size not loaded: ';
   TranslateEditorFontSizeLoaded = 'Editor font size loaded: ';
   TranslateNoItemSelected = 'No item selected.';
   TranslateItemSelected = 'Empty item selected.';
   TranslateFileDoesNotExist = 'File does not exist: ';
   TranslateChackExamplesFolderExists = 'Check that the "examples" folder exists and contains the appropriate files.';
   TranslateErrOccurred = 'An error occurred: ';
   TranslateFailStartProgram = 'Failed to start program: ';


implementation

uses
 usettings,unitopcjeprojektu,unitoprogramie,unitautor,uinformacjaoide, uwsparcie,
 chatgptavocado,uchatgpt,uprzyklady,ustawieniaai, themesettings, aihelper;

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  if not Assigned(SynEditCode) then
  ShowMessage(TranslateSynEditCodeNotCreated);
  LoadFpc;
  //Saves a temporary file where the project is saved
  //Zapisuje plik tymczasowy tam gdzie jest zapisany projekt
  FTempFile := SaveFileProject + 'temp.avocado';
  //Dodanie zanków polksich
  SynAnySyn1.IdentifierChars := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyząćęłńóśźżĄĆĘŁŃÓŚŹŻ';
  SynEditCode.Repaint;
  LoadTokenGPT;
end;

procedure TFormMain.TranspilujExecute(Sender: TObject);
begin
  ToolButton1Click(sender);
end;

procedure TFormMain.MenuINformacjaIDEClick(Sender: TObject);
begin
  Finformacjaide.ShowModal;
end;

procedure TFormMain.RozmiarCzcionkiSynEditorChangeValue(Sender: TObject);
begin
  SynEditCode.Font.Size:= RozmiarCzcionkiSynEditor.Value;
  FontSizeEditor := RozmiarCzcionkiSynEditor.Value;
  LRozmiarZccionkiEdytora.Caption := IntToStr(FontSizeEditor);
end;



procedure TFormMain.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CloseProgram;
end;

procedure TFormMain.itemJaponskiClick(Sender: TObject);
begin
  SetDefaultLang('jp');
  lang := 'jp';
  IsClickMainMenuLanguage(21);
end;

procedure TFormMain.MenuExamplesClick(Sender: TObject);
begin
  FormPrzyklady.ShowModal;
end;

procedure TFormMain.MenuIArabskiClick(Sender: TObject);
begin
  SetDefaultLang('ar');
  lang := 'ar';
  IsClickMainMenuLanguage(10);
end;

procedure TFormMain.MenuItAiAsystantClick(Sender: TObject);
begin
  aiassistant.Show;
end;

procedure TFormMain.MenuIteFinskiClick(Sender: TObject);
begin
  SetDefaultLang('fi');
  lang := 'fi';
  IsClickMainMenuLanguage(17);
end;

procedure TFormMain.MenuIteGreckiClick(Sender: TObject);
begin
  SetDefaultLang('gr');
  lang := 'gr';
  IsClickMainMenuLanguage(18);
end;

procedure TFormMain.MenuItem10Click(Sender: TObject);
begin
  SetDefaultLang('en');
  lang := 'en';
  IsClickMainMenuLanguage(0);
end;

procedure TFormMain.MenuItem11Click(Sender: TObject);
begin
  SetDefaultLang('es');
  lang := 'es';
  IsClickMainMenuLanguage(1);
end;

procedure TFormMain.MenuItem12Click(Sender: TObject);
begin
  SetDefaultLang('fr');
  lang := 'fr';
  IsClickMainMenuLanguage(2);
end;

procedure TFormMain.MenuItem13Click(Sender: TObject);
begin
  SetDefaultLang('de');
  lang := 'de';
  IsClickMainMenuLanguage(3);
end;

procedure TFormMain.MenuItem14Click(Sender: TObject);
begin
  SetDefaultLang('it');
  lang := 'it';
  IsClickMainMenuLanguage(4);
end;

procedure TFormMain.MenuItem15Click(Sender: TObject);
begin
  SetDefaultLang('pt');
  lang := 'pt';
  IsClickMainMenuLanguage(5);
end;

procedure TFormMain.MenuIRosyjskiClick(Sender: TObject);
begin
  SetDefaultLang('ru');
  lang := 'ru';
  IsClickMainMenuLanguage(7);
end;

procedure TFormMain.MenuChinskiClick(Sender: TObject);
begin
  SetDefaultLang('zh');
  lang := 'zh';
  IsClickMainMenuLanguage(8);
end;

procedure TFormMain.MenuHindiClick(Sender: TObject);
begin
  SetDefaultLang('hi');
  lang := 'hi';
  IsClickMainMenuLanguage(9);
end;

procedure TFormMain.MenuItem16Click(Sender: TObject);
begin
  SetDefaultLang('ua');
  lang := 'ua';
  IsClickMainMenuLanguage(12);
end;

procedure TFormMain.MenuItem17Click(Sender: TObject);
begin
  SetDefaultLang('bg');
  lang := 'bg';
  IsClickMainMenuLanguage(14);
end;

procedure TFormMain.MenuItem18Click(Sender: TObject);
begin
  SetDefaultLang('nl');
  lang := 'nl';
  IsClickMainMenuLanguage(15);
end;

procedure TFormMain.MenuItem19Click(Sender: TObject);
begin
  SettingTheme.ShowModal;
end;

procedure TFormMain.MenuItem9Click(Sender: TObject);
begin
  SetDefaultLang('pl');
  lang := 'pl';
  IsClickMainMenuLanguage(0);
end;

procedure TFormMain.MenuItemCzeskiClick(Sender: TObject);
begin
  SetDefaultLang('cz');
  lang := 'cz';
  IsClickMainMenuLanguage(11);
end;

procedure TFormMain.MenuItemDanskClick(Sender: TObject);
begin
  SetDefaultLang('dk');
  lang := 'dk';
  IsClickMainMenuLanguage(13);
end;

procedure TFormMain.MenuItemEstonskiClick(Sender: TObject);
begin
  SetDefaultLang('et');
  lang := 'et';
  IsClickMainMenuLanguage(16);
end;

procedure TFormMain.MenuItemKoreanskiClick(Sender: TObject);
begin
  SetDefaultLang('kr');
  lang := 'kr';
  IsClickMainMenuLanguage(22);
end;

procedure TFormMain.MenuItemLangLatvianClick(Sender: TObject);
begin
  SetDefaultLang('lv');
  lang := 'lv';
  IsClickMainMenuLanguage(23);
end;

procedure TFormMain.MenuItemLangLithuanianClick(Sender: TObject);
begin
  SetDefaultLang('lt');
  lang := 'lt';
  IsClickMainMenuLanguage(24);
end;

procedure TFormMain.MenuItemLangRomanianClick(Sender: TObject);
begin
  SetDefaultLang('ro');
  lang := 'ro';
  IsClickMainMenuLanguage(25);
end;

procedure TFormMain.MenuItemLangSlovakClick(Sender: TObject);
begin
  SetDefaultLang('sk');
  lang := 'sk';
  IsClickMainMenuLanguage(26);
end;

procedure TFormMain.MenuItemSlovenianLangClick(Sender: TObject);
begin
  SetDefaultLang('sl');
  lang := 'sl';
  IsClickMainMenuLanguage(27);
end;

procedure TFormMain.MenuItemSwedishLangClick(Sender: TObject);
begin
  SetDefaultLang('sv');
  lang := 'sv';
  IsClickMainMenuLanguage(28);
end;

procedure TFormMain.MenuItemTurkishLangClick(Sender: TObject);
begin
  SetDefaultLang('tr');
  lang := 'tr';
  IsClickMainMenuLanguage(29);
end;

procedure TFormMain.MenuItIndonezyjskiClick(Sender: TObject);
begin
  SetDefaultLang('id');
  lang := 'id';
  IsClickMainMenuLanguage(20);
end;

procedure TFormMain.MenuItWegierskiClick(Sender: TObject);
begin
  SetDefaultLang('hu');
  lang := 'hu';
  IsClickMainMenuLanguage(19);
end;

procedure TFormMain.MenuItem4Click(Sender: TObject);
begin
  Settingai.ShowModal;
end;

procedure TFormMain.MenuItem5Click(Sender: TObject);
begin
  MemoLogs.CopyToClipboard;
end;

procedure TFormMain.MenuItem6Click(Sender: TObject);
begin
  MemoLogs.SelectAll;
  MemoLogs.CopyToClipboard;
end;



procedure TFormMain.MenuItemCopyAllPascalzCodeClick(Sender: TObject);
begin
  MemoOutPut.SelectAll;
  MemoOutPut.CopyToClipboard;
end;

procedure TFormMain.MenuItemcopyPascalCodeClick(Sender: TObject);
begin
 MemoOutPut.CopyToClipboard;
end;

procedure TFormMain.MenuItemWsparcieprojektuClick(Sender: TObject);
begin
  Wsparcie.ShowModal;
end;


procedure TFormMain.SynEditCodeChange(Sender: TObject);
begin

 if Assigned(SynEditCode) then
  begin
    ToolButton1Click(sender);
    NumberWordSynEdit := Length(SynEditCode.Text);
    //StatusBar.Panels.Items[0].Text := IntToStr(SynEditCode.Lines.Count) + 'LinesofCodeTranslate';
    StatusBar.Panels.Items[0].Text := (CountLine) + ' ' + IntToStr(SynEditCode.Lines.Count);
    StatusBar.Panels.Items[1].Text := (CountChars) + ' ' + IntToStr(NumberWordSynEdit);
    //StatusBar.Panels.Items[1].Text := IntToStr(NumberWordSynEdit) + 'CharsTranslate';
    IdleTimer1.Enabled := False;
    IdleTimer1.Enabled := True;
  end;
end;



procedure TFormMain.NowyPlikExecute(Sender: TObject);
begin
  MenuNewFileClick(sender);
end;

constructor TFormMain.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FTranslator := TAvocadoTranslator.Create;
  FTranslatedCode := TStringList.Create;
  FPC_Params := TStringList.Create;
  FPC_Params.Add('-Sg');
  FPC_Params.Add('-Mobjfpc');
end;



procedure TFormMain.FormShow(Sender: TObject);
begin
  SynEditCode.SetFocus;
end;

procedure TFormMain.MenuAboutProgramClick(Sender: TObject);
begin
  FormOprogramie.ShowModal;
end;

procedure TFormMain.MenuAutorClick(Sender: TObject);
begin
  FormAutor.ShowModal
end;

procedure TFormMain.MenuCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.MenuItem3ClearCodeClick(Sender: TObject);
begin
  SynEditCode.ClearAll;
end;



procedure TFormMain.MenuItemCopyClick(Sender: TObject);
begin
  SynEditCode.CopyToClipboard;
end;

procedure TFormMain.MenuItemCopyCodeClick(Sender: TObject);
begin
  SynEditCode.CopyToClipboard;
end;

procedure TFormMain.MenuItemCutClick(Sender: TObject);
begin
  SynEditCode.CutToClipboard;
end;

procedure TFormMain.MenuItemCutCodeClick(Sender: TObject);
begin
  SynEditCode.CutToClipboard;
end;


procedure TFormMain.MenuItemDeleteCodeClick(Sender: TObject);
begin
    SynEditCode.ClearAll;
end;

procedure TFormMain.MenuItemDokumentacjaClick(Sender: TObject);
begin
  FormAutor.OpenLink('https://avocado.doc.dimitalart.pl/');
end;

procedure TFormMain.MenuItemOutputCodeClearClick(Sender: TObject);
begin
  MemoOutPut.Clear;
end;

procedure TFormMain.MenuItemPasteClick(Sender: TObject);
begin
  SynEditCode.PasteFromClipboard;
end;

procedure TFormMain.MenuItemPasteCodeClick(Sender: TObject);
begin
  SynEditCode.PasteFromClipboard;
end;

procedure TFormMain.MenuItemSaveFileClick(Sender: TObject);
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
end;

procedure TFormMain.MenuNewFileClick(Sender: TObject);
begin
  if InputQuery(NewProgramFile, NewNamezprogram, NameProgram) then
  begin
    // We clean the code editor and the log and output windows
    // Czyścimy edytor kodu oraz okna logów i outputu
    SynEditCode.Clear;
    MemoOutPut.Clear;
    MemoLogs.Clear;
    // We add the initial program declaration based on the entered name
    // Dodajemy początkową deklarację programu na podstawie wprowadzonej nazwy
    SynEditCode.Lines.Add('program ' + NameProgram);
  end;

end;

procedure TFormMain.MenuOpcjeProjektuClick(Sender: TObject);
begin
  FormOpcjeProjektu.ShowModal;
end;

procedure TFormMain.MenuOpenClick(Sender: TObject);
begin
  SynEditCode.Clear;
  MemoOutPut.Clear;
  MemoLogs.Clear;
  if OD.Execute then
  begin
    SynEditCode.Lines.LoadFromFile(OD.FileName);
    OpenFileProject := ChangeFileExt(ExtractFileName(OD.FileName), '');
   // ShowMessage(OpenFileProject);
   Caption := 'IDE Avocado v 1.0.1.0' + ' ' + OpenProjectTranslate + ' ' + OpenFileProject;
    IdleTimer1.Enabled := True;
    ToolButton1Click(Sender);
  end;
end;

procedure TFormMain.MenuSaveAsClick(Sender: TObject);
begin
  SaveCodeToFile;
end;

procedure TFormMain.MenuUstawiniaClick(Sender: TObject);
begin
  FormSettingIntepreter.ShowModal;
end;

procedure TFormMain.KompilujExecute(Sender: TObject);
begin
  butCompileCodeClick(Sender);
end;


procedure TFormMain.ToolButton1Click(Sender: TObject);
begin
 ExtractProgramFromSynEdit;
  //CompileToPascal;
  try
    MemoOutPut.Clear;
    FTranslatedCode.Assign(FTranslator.Translate(SynEditCode.Lines));
    //MemoOutPut.Lines.Add('{=== Free Pascal Code ===}');

    MemoOutPut.Lines.Add(FTranslatedCode.Text);
    //BtnCompile.Enabled := True;
  except
    on E: Exception do
      MemoOutPut.Lines.Add(TranslateTranslationError + E.Message);
  end;
end;

procedure TFormMain.butCompileCodeClick(Sender: TObject);
var
   sFileName: string;
   DlgResult: Integer;
   OutputFolder: string;
begin
 // Check if a file is open (OD) or saved (SD)
 // Sprawdzenie, czy plik jest otwarty (OD) lub zapisany (SD)

  if OD.FileName <> '' then
    sFileName := OD.FileName
  else if SD.FileName <> '' then
    sFileName := SD.FileName
  else
    sFileName := '';
  //If the file has not been saved, we force it to save before compiling
  // Jeśli plik nie został zapisany, wymuszamy zapisanie przed kompilacją
  if sFileName = '' then
  begin
    DlgResult := MessageDlg(TranslateAttention, TranslateSaveProject,
                            mtConfirmation, [mbYes, mbNo], 0);
    if DlgResult = mrYes then
    begin
      // Call "Save As"
      MenuSaveAsClick(Sender);
      if SD.FileName <> '' then
        sFileName := SD.FileName // Update filename after saving
      else
      begin
        MessageDlg(TranslateMistake, TranslateFilenotSaved, mtError, [mbOk], 0);
        Exit; //If the user canceled the save, we exit the procedure / Jeśli użytkownik anulował zapis, kończymy procedurę
      end;
    end
    else
    begin
      MessageDlg(TranslateMistake, TranslateFilenotSavedBuildCancel, mtError, [mbOk], 0);
      Exit; //If the user refused to save, we terminate the procedure / Jeśli użytkownik odmówił zapisu, kończymy procedurę
    end;
  end;
  // We extract the folder where the file was saved
  // Wyodrębniamy folder, w którym zapisany został plik
  OutputFolder := ExtractFilePath(sFileName);
  // Setting the output file name based on the folder and the NameProgram variable
  // Ustawienie nazwy pliku wynikowego na podstawie folderu oraz zmiennej NameProgram
  ExeName := IncludeTrailingPathDelimiter(OutputFolder) + NameProgram + '.exe';

  // Kompilujemy kod Pascala – funkcja CompilePascalCode przyjmuje tekst kodu i ścieżkę do pliku .exe
  //bez watku CompilePascalCode(FTranslatedCode.Text, ExeName);

  // Start kompilacji w osobnym wątku
  //TCompileThread.Create(FTranslatedCode.Text, ExeName, Handle);
  TCompileThread.Create(Self, FTranslatedCode.Text, ExeName);
end;

procedure TFormMain.ZapiszPlikExecute(Sender: TObject);
begin
  SaveCodeToFile;
end;


procedure TFormMain.LoadFpc;
begin
   //MemoLogs.Lines.Add(TranslateLoadingSettings);
  {
  AppDir := ExtractFilePath(Application.ExeName);
  FFpcPath := ExpandFileName(IncludeTrailingPathDelimiter(AppDir) + 'fpc\3.2.2\bin\x86_64-win64\fpc.exe');
  FFpcBasePath := ExpandFileName(IncludeTrailingPathDelimiter(AppDir) + 'fpc\3.2.2');
  FModulsPath := ExpandFileName(IncludeTrailingPathDelimiter(AppDir) + 'moduly');
  }
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
    // Wczytaj z INI
    FFpcPath := Ini.ReadString('main', 'fpc', '');
    FFpcBasePath := Ini.ReadString('main', 'FpcBasePath', '');
    FTargetPlatform := Ini.ReadString('main', 'TargetPlatform', '');
    FModulsPath := Ini.ReadString('main', 'Units', 'moduly');

    //loads the programm language into the UI
    lang := Ini.ReadString('defaultlanguage','language','en');
    case lang of
    'en':
    begin
      //English language
      SetDefaultLang('en');
      IsClickMainMenuLanguage(0);
    end;
    'pl':
    begin
      //Polish language
      SetDefaultLang('pl');
      IsClickMainMenuLanguage(6);
    end;
    'ru':
    begin
      //Russian language
      SetDefaultLang('ru');
      IsClickMainMenuLanguage(7);
    end;
    'de':
    begin
      //German language
      SetDefaultLang('de');
      IsClickMainMenuLanguage(3);
    end;
    'pt':
    begin
      //Portuguese language
      SetDefaultLang('pt');
      IsClickMainMenuLanguage(5);
    end;
    'es':
    begin
      //Spanish language
      SetDefaultLang('es');
      IsClickMainMenuLanguage(1);
    end;
    'dk':
    begin
      //Danish language
      SetDefaultLang('dk');
       IsClickMainMenuLanguage(13);
    end;
    'it':
    begin
      //Italian language
      SetDefaultLang('it');
      IsClickMainMenuLanguage(4);
    end;
    'hi':
    begin
      //Hindi language
      SetDefaultLang('hi');
      IsClickMainMenuLanguage(9);
    end;
    'fr':
    begin
      //French language
      SetDefaultLang('fr');
      IsClickMainMenuLanguage(2);
    end;
    'cz':
    begin
      //Czech language
      SetDefaultLang('cz');
      IsClickMainMenuLanguage(11);
    end;
    'zh':
    begin
      //Chinese language
      SetDefaultLang('zh');
      IsClickMainMenuLanguage(8);
    end;
    'bn':
    begin
      //Bengali language
      SetDefaultLang('bn');
      //IsClickMainMenuLanguage(8);
    end;
    'ar':
    begin
      //Arabic language
      SetDefaultLang('ar');
      IsClickMainMenuLanguage(10);
    end;
    'bg':
    begin
      //Bulgarian language
       SetDefaultLang('bg');
       IsClickMainMenuLanguage(14);
    end;
    'pnb':
    begin
       //West Punjabi language
       //SetDefaultLang('pnb');
       //IsClickMainMenuLanguage(8);
    end;
    'ua':
    begin
       //Ukrainian language
       SetDefaultLang('ua');
       IsClickMainMenuLanguage(12);
    end;
    'nl':
    begin
       //Dutch language
       SetDefaultLang('nl');
       IsClickMainMenuLanguage(15);
    end;
    'et':
    begin
       //Estonian language
       SetDefaultLang('et');
       IsClickMainMenuLanguage(16);
    end;
    'fi':
    begin
       //Finnish language
       SetDefaultLang('fi');
       IsClickMainMenuLanguage(17);
    end;
    'gr':
    begin
       //Greek language
       SetDefaultLang('gr');
       IsClickMainMenuLanguage(18);
    end;
    'hu':
    begin
       //Hungarian language
       SetDefaultLang('hu');
       IsClickMainMenuLanguage(19);
    end;
    'id':
    begin
       //Indonesian language
       SetDefaultLang('id');
       IsClickMainMenuLanguage(20);
    end;
    'jp':
    begin
       //Japanese language
       SetDefaultLang('jp');
       IsClickMainMenuLanguage(21);
    end;
    'kr':
    begin
       //Korean language
       SetDefaultLang('kr');
       IsClickMainMenuLanguage(22);
    end;
    'lv':
    begin
       //Latvian language
       SetDefaultLang('lv');
       IsClickMainMenuLanguage(23);
    end;
    'lt':
    begin
       //Lithuanian language
       SetDefaultLang('lt');
       IsClickMainMenuLanguage(24);
    end;
    'ro':
    begin
       //Romanian language
       SetDefaultLang('ro');
       IsClickMainMenuLanguage(25);
    end;
    'sk':
    begin
       //Slovak language
       SetDefaultLang('sk');
       IsClickMainMenuLanguage(26);
    end;
    'sl':
    begin
       //Slovenian language
       SetDefaultLang('sl');
       IsClickMainMenuLanguage(27);
    end;
    'se':
    begin
       //Swedish language
       SetDefaultLang('sv');
       IsClickMainMenuLanguage(28);
    end;
    'tr':
    begin
       //Turkish language
       SetDefaultLang('tr');
       IsClickMainMenuLanguage(29);
    end
    else
      SetDefaultLang('en');
      IsClickMainMenuLanguage(0);
    end;
     // end


    if (FFpcPath = '') or not FileExists(FFpcPath) then
    begin
      MemoLogs.Lines.Add(TranslateFPCCompilerNotExist + FFpcPath);
      //blocking compilation capabilities / blokowanie możliwości kompilacji
      butCompileCode.Enabled := False;
    end;

    if FFpcBasePath = '' then
    begin
       MemoLogs.Lines.Add(TranslateFpcConfigureErrPathToFpc + FFpcBasePath + TranslateStandardFPCunits);
    end
    else if not DirectoryExists(FFpcBasePath) then
    begin
       MemoLogs.Lines.Add(TranslateConfErrFpcBasePath + FFpcBasePath);
      //blocking compilation capabilities / blokowanie możliwości kompilacji
      butCompileCode.Enabled := False;
    end;

    if FTargetPlatform = '' then
    begin
       MemoLogs.Lines.Add(TranslateConfErrTargetPlatform + FTargetPlatform + TranslateUnableUnitDirectory);
    end;

    //Sprawdza FModulsPath sciezke moduly
    if FModulsPath = '' then
       begin
          MemoLogs.Lines.Add(TranslateConfErrModulePath + FModulsPath + TranslateUnableUnitDirectory);
       end;
    MemoLogs.Lines.Add(TranslateCompilerSettLoaded);
    MemoLogs.Lines.Add(TranslateLinkToFpc + FFpcPath);
    MemoLogs.Lines.Add(TranslateLinkToFpcFolder + FFpcBasePath);
    MemoLogs.Lines.Add(TranslatePlatform + FTargetPlatform);
    MemoLogs.Lines.Add(TranslateModules + FModulsPath);

  finally
    Ini.Free;
  end;
end;



procedure TFormMain.SaveCodeToFile;
begin
  SD.DefaultExt := 'avocado';
  SD.Filter := 'Avocado files (*.avocado)|*.avocado|All files (*.*)|*.*';
  if SD.Execute then
  begin
    SynEditCode.Lines.SaveToFile(SD.FileName);
    ZapisanaNazwaPliku := ChangeFileExt(ExtractFileName(SD.FileName), '');
    //Save path
    FileNamePr := SD.FileName;
    //ShowMessage(FileNamePr);
  end;
end;

procedure TFormMain.IsClickMainMenuLanguage(number: Integer);
var
  i: Integer;
begin
  for i := 0 to MainMenu1.Items[4].Count - 1 do
    begin
      if i <> number then
        MainMenu1.Items[4].Items[i].Checked := False;
    end;
    // Select the selected item
    MainMenu1.Items[4].Items[number].Checked := True;
end;

procedure TFormMain.CompilePascalCode(const PascalCode, OutputFile: string);
var
  AProcess: TProcess;
  TempFile: string;
  OutputLines: TStringList;
  FpcUnitPath, SourceDir: string;
  IdeDirectory, IdeModulesPath: string;
  UserModulesPath: string;
begin
  // --- Sprawdzenie krytycznych ustawień--
  if (FFpcPath = '') or not FileExists(FFpcPath) then
  begin
    MemoLogs.Lines.Add(TranslateErrPathToFpc);
    Exit;
  end;
  if (FFpcBasePath = '') or not DirectoryExists(FFpcBasePath) then
  begin
    MemoLogs.Lines.Add(TranslateErrFpcBasePathnotConfigure);
    Exit;
  end;
  UserModulesPath := FModulsPath;
  if (UserModulesPath <> '') and not DirectoryExists(UserModulesPath) then
  begin
     MemoLogs.Lines.Add(TranslateErrUserModulesPath + UserModulesPath + TranslateNotExist);
     UserModulesPath := '';
  end;
  {
  if FTargetPlatform = '' then
  begin
    MemoLogs.Lines.Add('BŁĄD KRYTYCZNY: Platforma docelowa (TargetPlatform) nie jest skonfigurowana!');
    Exit;
  end;
 }
  //Input code check / Sprawdzenie kodu wejściowego
  if Trim(PascalCode) = '' then
  begin
      MemoLogs.Lines.Add(TranslateErrPacalCodeCompile);
      Exit;
  end;

  //Setting the name of the temporary file
  // Ustalanie nazwy pliku tymczasowego
  if SaveFileProject <> '' then
    TempFile := ChangeFileExt(SaveFileProject, '.pas')
  else if OpenFileProject <> '' then
     TempFile := ChangeFileExt(OpenFileProject, '.pas')
  else
     TempFile := ExtractFilePath(Application.ExeName) + 'temp_compile.pas';

  try
    // Saving code to a temporary file / Zapis kodu do pliku tymczasowego
    OutputLines := TStringList.Create;
    try
      OutputLines.Text := PascalCode;
      OutputLines.SaveToFile(TempFile);
    finally
      OutputLines.Free;
    end;

    // Creating a build process / Utworzenie procesu kompilacji
    AProcess := TProcess.Create(nil);
    OutputLines := TStringList.Create;
    try
      AProcess.Executable := FFpcPath;
      AProcess.Parameters.Add(TempFile);

      // Adding Paths to Units (-Fu)
      // Dodawanie ścieżek do jednostek (-Fu)

      // Path to Standard FPC Units
      // Ścieżka do standardowych jednostek FPC
      FpcUnitPath := IncludeTrailingPathDelimiter(FFpcBasePath) + 'units' + PathDelim + FTargetPlatform;
      if DirectoryExists(FpcUnitPath) then
        AProcess.Parameters.Add('-Fu' + FpcUnitPath)
      else
        MemoLogs.Lines.Add(TranslateErrRequiredFPCstandardUnitDirfound + FpcUnitPath);

      //Path to the directory with the source file (TempFile)
      // 3. Ścieżka do katalogu z plikiem źródłowym (TempFile)
      SourceDir := ExtractFilePath(TempFile);
      if SourceDir <> '' then
        AProcess.Parameters.Add('-Fu' + SourceDir);

      // Path to user's own modules (from FModulsPath)
      // Ścieżka do własnych modułów użytkownika (z FModulsPath)
      if UserModulesPath <> '' then
      begin
        AProcess.Parameters.Add('-Fu' + UserModulesPath);
        MemoLogs.Lines.Add(TranslateAddUserModulesPath + UserModulesPath);
      end;

      // Path to modules shipped with the IDE (relative)
      // Ścieżka do modułów dostarczonych z IDE (względna)
      IdeDirectory := ExtractFilePath(Application.ExeName);
      IdeModulesPath := IncludeTrailingPathDelimiter(IdeDirectory) + TranslateModules;
      MemoLogs.Lines.Add(TranslateCheckModulesDir + IdeModulesPath);
      if DirectoryExists(IdeModulesPath) then
      begin
        if CompareText(IdeModulesPath, UserModulesPath) <> 0 then
        begin
           AProcess.Parameters.Add('-Fu' + IdeModulesPath);
           MemoLogs.Lines.Add(TranslateAddCustomModulesPath + IdeModulesPath);
        end
        else
            MemoLogs.Lines.Add(TranslateIDeModulesPathSkipDuplicate);
      end
      else
        MemoLogs.Lines.Add(TranslateCustModulesDirNotFound + IdeModulesPath + '.');

      // Stop adding tracks
      // Koniec dodawania ścieżek

      // Output file / Plik wyjściowy
      AProcess.Parameters.Add('-o' + Trim(OutputFile));

      //Process Options / Opcje procesu
      AProcess.Options := [poUsePipes, poStderrToOutput];
      AProcess.ShowWindow := swoHIDE;

      //Starting the compilation / Uruchomienie kompilacji
      MemoLogs.Lines.Add(TranslateStartComilationParam + AProcess.Parameters.Text);
    //  MemoLogs.Lines.Add('### FFpcPath (z LoadFpc): ' + FFpcPath);
     // MemoLogs.Lines.Add('### AProcess.Executable (zanim uruchomiono): ' + AProcess.Executable);
      AProcess.Execute;
      AProcess.WaitOnExit;

      // Capture and display the result
      // Przechwycenie i wyświetlenie wyniku
      OutputLines.LoadFromStream(AProcess.Output);
      MemoLogs.Lines.AddStrings(OutputLines);

      // Checking the completion status
      // Sprawdzenie statusu zakończenia
      if AProcess.ExitStatus = 0 then
      begin
        MemoLogs.Lines.Add(TranslateCompilationSuccses + OutputFile);
        // if FileExists(TempFile) then DeleteFile(TempFile);
      end
      else
      begin
        MemoLogs.Lines.Add(TranslateErrCompilationCode + IntToStr(AProcess.ExitStatus));
      end;

    finally
      AProcess.Free;
      OutputLines.Free;
    end;

  except
    on E: Exception do
      MemoLogs.Lines.Add(TranslateErrCompilation + E.Message);
  end;
  if FileExists(TempFile) then DeleteFile(TempFile);
end;


procedure TFormMain.InternalLoadAvocadoFile(const FileName: string);
begin
  SynEditCode.Lines.LoadFromFile(FileName);
  //Transpiluj
  TranspilujKod;
end;

procedure TFormMain.TranspilujKod;
begin
   ExtractProgramFromSynEdit;
  //CompileToPascal;
  try
    MemoOutPut.Clear;
    FTranslatedCode.Assign(FTranslator.Translate(SynEditCode.Lines));
    //MemoOutPut.Lines.Add('{=== Free Pascal Code ===}');

    MemoOutPut.Lines.Add(FTranslatedCode.Text);
    //BtnCompile.Enabled := True;
  except
    on E: Exception do
      MemoOutPut.Lines.Add('Translation Error: ' + E.Message);
  end;
end;

//end;

procedure TFormMain.KompilacjaKoduwPascal(const Code, OutputFile: string);
var
  AProcess: TProcess;
  TempFile: string;
  OutputLines: TStringList;
  BuildMode: string;
begin
  if SaveFileProject = '' then
    begin
    end;

    TempFile := ChangeFileExt(SaveFileProject, '.pas');
    // Set build mode to Release
    // Ustaw tryb kompilacji na Release
    BuildMode := 'Release';

    try
      MemoOutPut.Lines.SaveToFile(TempFile);
      AProcess := TProcess.Create(nil);
      OutputLines := TStringList.Create;
      try
        AProcess.Executable := FFpcPath; //link to fpc
        AProcess.Parameters.Add(TempFile);
        AProcess.Parameters.Add('-o' + Trim(OutputFile));

        // Dodajemy opcje dla trybu Release
        if BuildMode = 'Release' then
        begin
          MemoLogs.Lines.Add(TranslateCompilingReleaseMode);
          // Optimization level 2 / Poziom optymalizacji 2
          AProcess.Parameters.Add('-O3');
          // Smaller than faster / Mniejsze niz szybsze
          AProcess.Parameters.Add('-Os');
          // Clever connection /Sprytne laczenie
          AProcess.Parameters.Add('-CX');
          // Smart Connection / Laczenie Sprytne
          AProcess.Parameters.Add('-XX');
          // Disabling debug information / Wyłączenie informacji debugowych
          AProcess.Parameters.Add('-g-');
        end else
        begin
          // Default Debug mode (without optimization and with debug info)
          // Domyślny tryb Debug (bez optymalizacji i z debug info)
          MemoLogs.Lines.Add(TranslateCompilingDebugMode);
        end;
        AProcess.Options := [poUsePipes, poStderrToOutput];
        AProcess.ShowWindow := swoHIDE;
        MemoLogs.Lines.Add(TranslateStartComilation);
        AProcess.Execute;
        // Wait for compilation to finish / Czekaj na zakończenie kompilacji
        AProcess.WaitOnExit;
        OutputLines.LoadFromStream(AProcess.Output);
        MemoLogs.Lines.AddStrings(OutputLines);


        if AProcess.ExitStatus = 0 then
          MemoLogs.Lines.Add(TranslateComilationSuccessOutputFile + OutputFile)
        else
          MemoLogs.Lines.Add(TranslateErrCompilationCode + IntToStr(AProcess.ExitStatus));

      finally
        AProcess.Free;
        OutputLines.Free;
      end;
    except
      on E: Exception do
        MemoLogs.Lines.Add(TranslateErrCompilation + E.Message);
    end;
end;

procedure TFormMain.ExtractProgramFromSynEdit;
var
i: Integer;
NProgram: string;
begin
  NProgram := '';
    for i := 0 to SynEditCode.Lines.Count - 1 do
    begin
      NProgram := ExtractProgramName(SynEditCode.Lines[i]);
      if NProgram <> '' then
        Break;
    end;
    if NProgram <> '' then
    begin
      NameProgram := NProgram;
    end
    else
      //ShowMessage('Nie znaleziono deklaracji programu' + #10 + 'Dodaj na początku słowo kluczowe program i nazwe programu.');
end;

function TFormMain.ExtractProgramName(const Line: string): string;
var
  Words: TStringList;
begin
  Result := '';
    Words := TStringList.Create;
    try
      // We split the string into words - whitespace as separators
      // Rozdzielamy ciąg na słowa - białe znaki jako separatory
      ExtractStrings([' ', #9], [], PChar(Line), Words);
      // We check if the first element is 'program' (regardless of letter case)
      // Sprawdzamy czy pierwszy element to 'program' (niezależnie od wielkości liter)
      if (Words.Count >= 2) and (LowerCase(Words[0]) = 'program') then
        Result := Words[1];
    finally
      Words.Free;
    end;
end;


procedure TFormMain.LoadTokenGPT;
begin
 Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
   Token := Ini.ReadString('ChatGPT', 'Token', '');
   ModelGPT:= Ini.ReadString('ChatGPT', 'Model', '');
   //czcionka dla SynEditor
   FontSizeEditor := Ini.ReadInteger('main', 'SizeFontEditor', 0);

  if (Token = '') then
  begin
    MemoLogs.Lines.Add(TranslateNoTokenAiAssistant);
  end
  else
  begin
    MemoLogs.Lines.Add(TranslateAiHelperApiKeyAdded);
    MemoLogs.Lines.Add(TranslateAiHelperModel + ModelGPT);
  end;
  //Regarding the font / Dotyczy czcionki
  if (FontSizeEditor = 0) then
  begin
    MemoLogs.Lines.Add(TranslateEditorFontSizeNoLoaded);
  end
  else
  begin
    MemoLogs.Lines.Add(TranslateEditorFontSizeLoaded);
    SynEditCode.Font.Size := FontSizeEditor;
    RozmiarCzcionkiSynEditor.Value := FontSizeEditor;
    LRozmiarZccionkiEdytora.Caption := IntToStr(FontSizeEditor);
  end;
end;

procedure TFormMain.CloseProgram;
begin
   Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
   //FontSizeEditor := Ini.WriteInteger('main', 'SizeFontEditor', '');
   try
    ini.WriteInteger('main', 'SizeFontEditor', FontSizeEditor);
    ini.WriteString('defaultlanguage', 'language', lang);
    //MessageDlg('Dane','Dane zapisane', mtInformation,[mbOK],0);

  finally
    FreeAndNil(Ini);
  end;


end;



procedure TFormMain.LoadAvocadoFileToEditor(const FileName: string);
var
    FolderPath: string;
    BaseName: string;
    FileNameExample: string;
begin
  if FormPrzyklady.ExampleListBox.ItemIndex = -1 then
    begin
      ShowMessage(TranslateNoItemSelected);
      Exit;
    end;

    FolderPath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'examples' + PathDelim;

    try
      BaseName := Trim(FormPrzyklady.ExampleListBox.Items[FormPrzyklady.ExampleListBox.ItemIndex]);

      if BaseName = '' then
      begin
        ShowMessage(TranslateItemSelected);
        Exit;
      end;

      // Always remove the extension and add .avocado
      // Zawsze usuń rozszerzenie i dodaj .avocado
      BaseName := ChangeFileExt(BaseName, '');
      FileNameExample := FolderPath + BaseName + '.avocado';

      if not FileExists(FileNameExample) then
      begin
        ShowMessage(TranslateFileDoesNotExist + FileNameExample + sLineBreak + TranslateChackExamplesFolderExists);
        Exit;
      end;

      // Direct call to the loading method
      // Bezpośrednie wywołanie metody ładującej
      InternalLoadAvocadoFile(FileNameExample); // Zmiana nazwy metody wewnętrznej

    except
      on E: Exception do
        ShowMessage(TranslateErrOccurred + E.Message);
    end;
end;


destructor TFormMain.Destroy;
begin
  FTranslator.Free;
  FTranslatedCode.Free;
  inherited Destroy;
end;

{ TCompileThread }

procedure TCompileThread.Execute;
begin
  try
      FOwner.CompilePascalCode(FPascalCode, FExeName);
      FSuccess := FileExists(FExeName);
    except
      FSuccess := False;
    end;

    // Po zakończeniu – powiadom GUI
    Synchronize(@AfterCompile);

   //FOwner.CompilePascalCode(FPascalCode, FExeName);
   //
   //
   //if FileExists(FExeName) then
   //  Synchronize(@ShowSuccess)
   //else
   //  Synchronize(@ShowError);
end;

procedure TCompileThread.AfterCompile;
begin
  if FSuccess then
      ShellExecute(0, 'open', PChar(FExeName), nil, nil, 1)
  else
      MessageDlg(TranslateMistake, TranslateFailStartProgram + FExeName, mtError, [mbOk], 0);
end;

procedure TCompileThread.ShowSuccess;
begin
   ShellExecute(FHandle, 'open', PChar(FExeName), nil, nil, 1);
end;

procedure TCompileThread.ShowError;
begin
  MessageDlg(TranslateMistake, TranslateFailStartProgram + FExeName, mtError, [mbOk], 0);
end;


constructor TCompileThread.Create(Owner: TFormMain; const PascalCode, ExeName: string);
begin
   inherited Create(False);
   FreeOnTerminate := True;
   FOwner := Owner;
   FPascalCode := PascalCode;
   FExeName := ExeName;
   FSuccess := False;
end;


{ TInterpreterThread }

constructor TInterpreterThread.Create(const AInterpreterPath, ATempFile: string; AConsole: TSynEdit);
begin
  inherited Create(False); // starting a thread / uruchomienie wątku
  FreeOnTerminate := True;
  FConsole := AConsole;
  // Process configuration / Konfiguracja procesu
  FProcess := TProcess.Create(nil);
  FProcess.Executable := AInterpreterPath;
  FProcess.Parameters.Add(ATempFile);
  FProcess.Options := [poUsePipes];
  // Console Hide Setting / Ustawienie ukrycia konsoli (działa na Windows)
  FProcess.ShowWindow := swoHIDE;
  FProcess.Execute;
end;

procedure TInterpreterThread.SyncAppendOutput;
begin
  // Add the read text to the control – the text is added here
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
  // The loop executes as long as the process is running or data is available.
  // Pętla wykonuje się, dopóki proces działa lub są dostępne dane
  while FProcess.Running or (FProcess.Output.NumBytesAvailable > 0) do
  begin
    BytesRead := FProcess.Output.Read(Buffer, SizeOf(Buffer));
    if BytesRead > 0 then
    begin
      SetString(NewText, PAnsiChar(@Buffer[0]), BytesRead);
      FOutput := NewText;
      Synchronize(@SyncAppendOutput);
      // If the .exe file has been generated correctly, run it
      // Jeśli plik .exe został poprawnie wygenerowany, uruchamiamy go
      if FileExists(ExeName) then
        ShellExecute(Handle, 'open', PChar(ExeName), nil, nil, 1)
      else
        MessageDlg(TranslateMistake, TranslateFailStartProgram + ExeName, mtError, [mbOk], 0);
      end
    //
    else
      //Sleep(10);
  end;
  FProcess.Free;
end;

end.


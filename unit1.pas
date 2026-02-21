unit Unit1;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, ActnList, BCExpandPanels, BCFluentSlider,
  JvAutoComplete, SynEdit, SynCompletion, SynPluginSyncroEdit,
  SynHighlighterHTML, SynHighlighterPas, SynHighlighterTeX, SynHighlighterDiff,
  SynHighlighterMulti, SynHighlighterAny, SynHighlighterPo, Process, IniFiles,
  AvocadoTranslator, ShellAPI, LazUTF8, TreeFilterEdit, LCLIntf, InterfaceBase,
  DefaultTranslator, SynEditTypes, Math,
  LCLTranslator, LCLType, StrUtils, Types;

type
  PNodeRec = ^TNodeRec;
  TNodeRec = record
    IsFolder: Boolean;
    FullPath: string;
    Loaded: Boolean;
 end;

 type

  { TRunInstantThread }

  TRunInstantThread = class(TThread)
  private
    FPascalCode: string;
    FInstantFPCPath: string;
    FTempFile: string;
    FLogMsg: string;
    procedure SyncLog; // Metoda synchronizująca
  protected
    procedure Execute; override;
  public
    constructor Create(const APascalCode, AInstantFPCPath: string);
  end;

  PFileNode = ^TFileNode;
  TFileNode = record
    Name: string;
    FullPath: string;
    IsFolder: Boolean;
  end;

type
  { TFormMain }
  TFormMain = class(TForm)
    Dokumentacja: TAction;
    EditSearchDocumentation: TEdit;
    EditSearchResults: TEdit;
    EditSearchMistakes: TEdit;
    EditSearchComments: TEdit;
    EditSearchVariables: TEdit;
    EditSearchFunctions: TEdit;
    FindDialog: TFindDialog;
    ImageListListView: TImageList;
    AutoCompleteDocumentation: TJvLookupAutoComplete;
    Label5: TLabel;
    Label6: TLabel;
    ListBoxSearchDocumentaion: TListBox;
    ListBoxErrCode: TListBox;
    ListBoxSearchComments: TListBox;
    ListBoxSearchVariables: TListBox;
    ListBoxSearchFunctions: TListBox;
    ListBoxSeacrh: TListBox;
    LRozmiarZccionkiEdytora: TLabel;
    MemoSearchDocumentation: TMemo;
    MemoLogs: TMemo;
    MemoOutPut: TMemo;
    MenuExamples: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuIRosyjski: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItemAvocadoPatrons: TMenuItem;
    MenuItemStandardMode: TMenuItem;
    MenuItemAlwaysontopmode: TMenuItem;
    MenuItem19: TMenuItem;
    ItemTools: TMenuItem;
    MenuItAiAsystant: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItemrunwithoutcompilation: TMenuItem;
    MenuItemConsoleProgram: TMenuItem;
    MenuItemCompile: TMenuItem;
    MenuItemRun: TMenuItem;
    MenuItemSearch: TMenuItem;
    MenuItemOpenFolder: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    PagePanelRight: TPageControl;
    PageInfo: TPageControl;
    Panel4: TPanel;
    Panel6: TPanel;
    PanelTopDocumentation: TPanel;
    PanelTopmistakes: TPanel;
    PanelTopComments: TPanel;
    PanelTopVariables: TPanel;
    PanelTopFunctions: TPanel;
    PanelLeft: TPanel;
    ReplaceDialog: TReplaceDialog;
    RozmiarCzcionkiSynEditor: TBCFluentSlider;
    Label3: TLabel;
    Label4: TLabel;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItemCopyAllPascalzCode: TMenuItem;
    MenuItemcopyPascalCode: TMenuItem;
    Panel5: TPanel;
    IdleTimer1: TIdleTimer;
    Label1: TLabel;
    MenuINformacjaIDE: TMenuItem;
    MenuItemWsparcieprojektu: TMenuItem;
    Panel3: TPanel;
    PaneMain: TPanel;
    PanelDolnynadKosnola: TPanel;
    SBClearSearchDocumentaion: TSpeedButton;
    SBClearSearchFunctions: TSpeedButton;
    SBClearSearcResults: TSpeedButton;
    SBClearSearchVariables: TSpeedButton;
    SBClearSearchComments: TSpeedButton;
    SBClearSearchMistakes: TSpeedButton;
    Separator1: TMenuItem;
    Splitter2: TSplitter;
    SplitterLeft: TSplitter;
    StatusBar: TStatusBar;
    SynAnySyn1: TSynAnySyn;
    SynAutoComplete1: TSynAutoComplete;
    SynEditCode: TSynEdit;
    BottomPanelTab: TTabSheet;

    TabSheet1: TTabSheet;
    TabErrors: TTabSheet;
    FPCCode: TTabSheet;
    Documentation: TTabSheet;
    TabSheetComments: TTabSheet;
    TabSheetLog: TTabSheet;
    TabSheetSearch: TTabSheet;
    TimerScanFunctions: TTimer;
    ToolButton2: TToolButton;
    ToolButtonDebug: TToolButton;
    Transpiluj: TAction;
    TreeFilterEdit1: TTreeFilterEdit;
    TreeView: TTreeView;
    ZapiszPlik: TAction;
    NowyPlik: TAction;
    MenuItem3: TMenuItem;
    MenuAboutProgram: TMenuItem;
    MenuAutor: TMenuItem;
    MenuItemDokumentacja: TMenuItem;
    MenuNewFile: TMenuItem;
    MenuItemSaveFile: TMenuItem;
    MenuItemDeleteMemoLogs: TMenuItem;
    MenuProjekt: TMenuItem;
    MenuItem3ClearCode: TMenuItem;
    MenuOpcjeProjektu: TMenuItem;
    MenuItemCutCode: TMenuItem;
    MenuItemPasteCode: TMenuItem;
    MenuItemCopyCode: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PanelLewy: TPanel;
    PanelPrawy: TPanel;
    PopupMenuMemoLogs: TPopupMenu;
    PopupMenuOutPutPascalCode: TPopupMenu;
    PopupMenuCode: TPopupMenu;
    Kompiluj: TAction;
    ActionList1: TActionList;
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
    SplitterDown: TSplitter;
    SynCompletion1: TSynCompletion;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    butCompileCode: TToolButton;

    //procedure FileTreeDblClick(Sender: TObject);
    procedure DokumentacjaExecute(Sender: TObject);
    procedure EditSearchCommentsChange(Sender: TObject);
    procedure EditSearchFunctionsChange(Sender: TObject);
    procedure EditSearchMistakesChange(Sender: TObject);
    procedure EditSearchResultsChange(Sender: TObject);
    procedure EditSearchVariablesChange(Sender: TObject);

    procedure FindDialogFind(Sender: TObject);
    procedure FindDialogShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ListBoxErrCodeClick(Sender: TObject);
    procedure ListBoxErrCodeDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxSeacrhClick(Sender: TObject);
    procedure ListBoxSeacrhDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxSearchCommentsClick(Sender: TObject);
    procedure ListBoxSearchCommentsDrawItem(Control: TWinControl;
      Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxSearchDocumentaionDblClick(Sender: TObject);
    procedure ListBoxSearchFunctionsClick(Sender: TObject);
    procedure ListBoxSearchFunctionsDrawItem(Control: TWinControl;
      Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxSearchVariablesClick(Sender: TObject);
    procedure ListBoxSearchVariablesDrawItem(Control: TWinControl;
      Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure MenuExamplesClick(Sender: TObject);
    procedure MenuItAiAsystantClick(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuIRosyjskiClick(Sender: TObject);
    procedure MenuItem19Click(Sender: TObject);
    procedure MenuItem20Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure MenuItemAlwaysontopmodeClick(Sender: TObject);
    procedure MenuItemAvocadoPatronsClick(Sender: TObject);
    procedure MenuItemCompileClick(Sender: TObject);
    procedure MenuItemConsoleProgramClick(Sender: TObject);
    procedure MenuItemOpenFolderClick(Sender: TObject);
    procedure MenuItemrunwithoutcompilationClick(Sender: TObject);
    procedure MenuItemSearchClick(Sender: TObject);
    procedure MenuItemStandardModeClick(Sender: TObject);
    procedure NowyPlikExecute(Sender: TObject);
    procedure ReplaceDialogFind(Sender: TObject);
    procedure RozmiarCzcionkiSynEditorChangeValue(Sender: TObject);
    procedure MenuINformacjaIDEClick(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItemCopyAllPascalzCodeClick(Sender: TObject);
    procedure MenuItemcopyPascalCodeClick(Sender: TObject);
    procedure MenuItemWsparcieprojektuClick(Sender: TObject);
    procedure SBClearSearchCommentsClick(Sender: TObject);
    procedure SBClearSearchDocumentaionClick(Sender: TObject);
    procedure SBClearSearchFunctionsClick(Sender: TObject);
    procedure SBClearSearchMistakesClick(Sender: TObject);
    procedure SBClearSearchVariablesClick(Sender: TObject);
    procedure SBClearSearcResultsClick(Sender: TObject);
    procedure SynEditCodeChange(Sender: TObject);
    procedure SynEditCodeClick(Sender: TObject);
    procedure TimerScanFunctionsTimer(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);

    procedure ToolButtonDebugClick(Sender: TObject);
    procedure TranspilujExecute(Sender: TObject);
    //procedure NowyPlikExecute(Sender: TObject);
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
    procedure MenuItemPasteClick(Sender: TObject);
    procedure MenuItemPasteCodeClick(Sender: TObject);
    procedure MenuItemSaveFileClick(Sender: TObject);
    procedure MenuOpcjeProjektuClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuUstawiniaClick(Sender: TObject);
    procedure KompilujExecute(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure butCompileCodeClick(Sender: TObject);
    procedure TreeViewCollapsing(Sender: TObject; Node: TTreeNode;
      var AllowCollapse: Boolean);
    procedure TreeViewDblClick(Sender: TObject);
    procedure TreeViewExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure ZapiszPlikExecute(Sender: TObject);


  private
    FTranslator: TAvocadoTranslator;
    FTranslatedCode: TStringList;
    //Laduje link do FPC kompilatora
    procedure LoadFpc;
    procedure SaveCodeToFile;
    procedure IsClickMainMenuLanguage(number: Integer);
    //Laduje foldery i pliki i pokazuje w FileTree


    //Delete Kompilacja kodu release debug
    //procedure KompilacjaKoduwPascal(const Code, OutputFile: string);

    //Dotyczy nazwy programu
    procedure ExtractProgramFromSynEdit;
    function ExtractProgramName(const Line: string): string;
    // Metoda callback do obsługi odpowiedzi ChatGPT
    procedure LoadTokenGPT;
    //procedure LoadLang;
    procedure CloseProgram;

    procedure DeleteFilesInDir(const APath, AMask: string);


    //Otwiera pliki w TreeView
    procedure LoadProjectTree;
    //Auto zapisywanie pliku gdy jest otwarty w TreeView
    procedure SaveCurrentFile;
    //Dodawanie nod
    procedure AddSubNodes(ParentNode: TTreeNode; const Path: string);
    //Filtrowanie w Listboxach ListBoxSearchComments, ListBoxSearchVariables, ListBoxSearchFunctions, ListBoxSeacrh, ListBoxErrCode
    procedure FilterListBox(const FilterText: string; const SourceList: TStringList; ListBox: TListBox);
    //Uruchaminaie kodu przez instantFPC
    procedure RunPascalInstantly(const PascalCode: string);

  public
    //laduje nazwy funkcji Avoraisera polskie i angielskie do SynAnySyn1 > ObjectAtri podswietlenie skladni
    procedure LoadFunctionsToHighlighter(const FileName: string);

    procedure LoadAvocadoFileToEditor(const FileName: string);
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    //Code compilation / Kompilacja kodu
    procedure CompilePascalCode(const PascalCode, OutputFile: string);


    procedure InternalLoadAvocadoFile(const FileName: string);
    procedure TranspilujKod;
    //Wyszukiwanie funkcji z projektu i wstawienie w ListBox - ListBoxSearchFunctions
    procedure ListFunctionsFromSynEdit;
    function StartsWithWord(const S, Prefix: string; IgnoreCase: Boolean = True): Boolean;
    function FirstDelimiterPos(const S: string; const Delims: TSysCharSet): Integer;
    //load function to stringList
    procedure LoadPrefixesFromFile(const FileName: string);
    //Wyszukiwanie zmiennych z projektu i wstawienie w ListBox - ListBoxSearchVariables
    procedure ListVariablesFromSynEdit;
    // Loading variables from the variables.txt file / Ładowanie zmiennych z pliku variables.txt
    procedure LoadVariablesPrefixesFromFile(const FileName: string);
    //Wyszukiwanie komentarzy z projektu i wstawienie w ListBox - ListBoxSearchComments
    procedure ListCommentsFromSynEdit;
    //debuger
    procedure LoadDebugKeywords(const FileName: string; var Keywords: TStringList);
    //Sprawdza kod
    procedure CheckAvocadoCode;
    //Usuwa sudzyslowie z tekstu
    function RemoveQuotes(const Line: string): string;
    // usuwa komentarze // ... i { ... }
    function RemoveComments(const Line: string): string;
    //Podswietla bledy w SynEditCode
    procedure HighlightErrorLine(LineNum: Integer);
    // Podswietla komentarzy, zmienne, funkcje
    procedure HighlithSynEditLine(LineNum: Integer);
    //Load documentation
    procedure LoadTextDocumenation(FileName: string);
    procedure LoadDocToListBox(const FileName: string; var Keywords: TStringList);
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
  //NameProgram: String;


  //Liczba znaków
  NumberWordSynEdit: Integer;
  PromptChatGPT: String;
  Token: String;
  ModelGPT,PromtAv,PromtS: String;
  ExeName: string;
  //Ini
  IniEnd: TIniFile;
  FontSizeEditor: Integer;
  InstantFpcPath: String;
  //Language
  lang: String;
  OpenProjectTranslatet: string;
  CharsTranslatet: string;
  OpenProjectDir: String;
  OpenProjectName : String;
  //dotyczy funkcji ladowanych z pliku functions.txt
  Prefixes: array of string;
  PrefixesVariables: array of string;
  AvocadoVersion: string;
  //It deals with errors in the project and error filtering in EditSearchMistakes / Dotyczy błędów w projekcie i filtrowanie błedów w EditSearchMistakes
  //FAllErrors: TStringList;
  IsConsoleProgram: boolean;
  FErrAll: TStringList;
  FCmtAll: TStringList;
  FVarAll: TStringList;
  FFuncAll: TStringList;
  FSearchAll: TStringList;
  FSearcDoc: TStringList;


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
   TranslateFunctionNotfound = 'Function not found.';
   TranslateNoPrefixesToSearch = 'No prefixes to search!';
   TranslateNoVariablesFound = 'No variables found.';
   TranslateNoCommentsFound = 'No comments found.';
   TranslateFileNotFound = 'File not found: ';
   TranslateDebuggerFileNotFound = 'Debugger.txt file not found';
   TranslateUnknownName = 'Unknown name';
   TranslateCodeErrorsCompilationStopped = 'Code errors. Compilation stopped!';
   TranslateNoErrorsCodeReadyToCompile = 'No errors. Code ready to compile.';
   TranslateErrorsInTheCode = 'Errors in the code!';
   TranslateCodeCorrect = 'Code correct!';
   TranslateOccurrencesZerofound = '0 occurrences found';
   TranslateFound = 'Found';
   TranslateSpeeches = 'speeches';
   TranslateValueLookingFound = 'The value you were looking for has been found!';
   TranslateNoDataCode = 'No data in the code!';
   TranslateAttentionMsg = 'Attention!';
   TranslateCreateNewFile = 'Create a new file?';
   ErrWritingTemporaryFile = 'Error writing temporary file: ';
   RunInterpreterSeparateWindow = 'Running the interpreter in a separate window..';
   InterpretationCompleted = 'Interpretation completed.';
   ProcessStartupErr = 'Process startup error: ';
   NoCodeOpenFileorWriteCodeEditor = 'No code. Open the file or write code in the editor.';
   TranslateCannotCreateTemporaryDirectory = 'Error: Cannot create temporary directory: ';
   TranslateInformation = 'Information';
   TranslateFileModifiedSaveChanges = 'The current file has been modified. Do you want to save the changes?';

implementation

uses
 usettings,unitopcjeprojektu,unitoprogramie,unitautor,uinformacjaoide, uwsparcie,
 uchatgpt,uprzyklady,ustawieniaai, themesettings, aihelper, patrons;

{ TRunInstantThread }

procedure TRunInstantThread.SyncLog;
begin
  if Assigned(FormMain) then
  begin
    FormMain.MemoLogs.Lines.Add(FLogMsg);
    FormMain.PageInfo.ActivePage := FormMain.TabSheetLog;
  end;
end;

procedure TRunInstantThread.Execute;
var
  AProcess: TProcess;
  CommandLine: string;
  CodeList: TStringList;
begin
    // Zapisz kod do pliku (w wątku)
    CodeList := TStringList.Create;
    try
      try
        CodeList.Text := FPascalCode;
        CodeList.SaveToFile(FTempFile);
      except
        on E: Exception do
        begin
          FLogMsg := ErrWritingTemporaryFile + E.Message;
          Synchronize(@SyncLog);
          Exit;
        end;
      end;
    finally
      CodeList.Free;
    end;
    AProcess := TProcess.Create(nil);
    try
      AProcess.Executable := 'cmd.exe';

      // Budowanie komendy: "instantfpc" "plik" & PAUSE
      //CommandLine := Format('"%s" "%s" & PAUSE', [FInstantFPCPath, FTempFile]);
      CommandLine := Format('"%s" "%s"', [FInstantFPCPath, FTempFile]);
      AProcess.Parameters.Add('/C "' + CommandLine + '"');

      AProcess.Options := [poWaitOnExit];
      AProcess.ShowWindow := swoShowNormal; // Pokaż konsolę
      FLogMsg := RunInterpreterSeparateWindow;
      Synchronize(@SyncLog);
      try
        AProcess.Execute;
        FLogMsg := InterpretationCompleted;
        Synchronize(@SyncLog);
      except
        on E: Exception do
        begin
          FLogMsg := ProcessStartupErr + E.Message;
          Synchronize(@SyncLog);
        end;
      end;

    finally
      if FileExists(FTempFile) then
        DeleteFile(FTempFile);
      AProcess.Free;
    end;
end;

constructor TRunInstantThread.Create(const APascalCode, AInstantFPCPath: string);
begin
inherited Create(False); // Uruchom od razu
FreeOnTerminate := True; // Zwolnij pamięć po zakończeniu
FPascalCode := APascalCode;
FInstantFPCPath := AInstantFPCPath;
// Ustal ścieżkę pliku tymczasowego tutaj, aby była dostępna w wątku
FTempFile := GetTempDir + 'avocado_temp_code.pas';
end;

 //chatgptavocado
{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
var
  TempDir: string;
begin
  IsConsoleProgram := True;
    // Utworzenie folderu Avocado
    TempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'Avocado';

    if not ForceDirectories(TempDir) then
    begin
      // Obsługa błędu, np. wyświetlenie komunikatu
      ShowMessage(TranslateCannotCreateTemporaryDirectory + TempDir);
    end;


  AvocadoVersion := 'IDE Avocado v 2.2.1.0';
  //Ladowanie funkcji Avoraisera
  LoadFunctionsToHighlighter('avoraiser_translate.ini');

  //dotyczy kolorowania SynEditCode
  //ColoredSynEdit;
  FormMain.Caption := AvocadoVersion;
  NeedsAsmIntel := False;
  SynEditCode.Options := SynEditCode.Options - [eoAutoIndent];
  FormMain.KeyPreview := True;
  if not Assigned(SynEditCode) then
  ShowMessage(TranslateSynEditCodeNotCreated);
  LoadFpc;
  //Saves a temporary file where the project is saved
  //Zapisuje plik tymczasowy tam gdzie jest zapisany projekt
  //FTempFile := SaveFileProject + 'temp.avocado';
  //Dodanie znaków polksich
  SynAnySyn1.IdentifierChars := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyząćęłńóśźżĄĆĘŁŃÓŚŹŻ';
  SynEditCode.Repaint;
  LoadTokenGPT;
  //ladowanie funkcji z pliku functions.txt
  LoadPrefixesFromFile('functions.txt');
  LoadVariablesPrefixesFromFile('variables.txt');

  //Odswiezenie listboxow
  ListFunctionsFromSynEdit;
  ListVariablesFromSynEdit;
  //laduje pliki do ListBoxSearchDocumentaion
  PageInfo.ActivePage := TabSheetLog;
  PagePanelRight.ActivePage := FPCCode;
  //Ustawiam tryb aplikacji konsolowy

  //ShowMessage('Aplikacja konsolowa: '+ boolToStr(IsConsoleProgram));
  //Sprawdzanie czy aplikacja konsolowa
  {
  if IsConsoleProgram then
  ShowMessage('Aplikacja konsolowa: True')
  else
  ShowMessage('Aplikacja konsolowa: False');
  }
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
var
rez :TModalResult;
begin
  CloseProgram;
  CanClose := True;
  if  SynEditCode.Text <> '' then
  begin
    rez := MessageDlg(TranslateInformation,TranslateFileModifiedSaveChanges,mtInformation,[mbYes,mbNo,mbCancel],0);
    case rez of
      mrYes:
        begin
          MenuItemSaveFileClick(Sender);
        end;
      mrNo:
        begin
          CanClose := True;
        end;
      mrCancel:
        begin
          CanClose := False;
        end;
    end;
end;
end;

procedure TFormMain.FindDialogFind(Sender: TObject);
var
SearchOptions: TSynSearchOptions;
FoundCount: Integer;
rezultat :TModalResult;
begin
    if not Assigned(FSearchAll) then
      FSearchAll := TStringList.Create
    else
      FSearchAll.Clear;

   ListBoxSeacrh.Clear;
   FoundCount := 0;

   // Inicjalizacja opcji wyszukiwania
   SearchOptions := [ssoFindContinue];

   // Mapowanie opcji z FindDialog na SynEdit
   if frWholeWord in FindDialog.Options then
     Include(SearchOptions, ssoWholeWord);
   if frMatchCase in FindDialog.Options then
     Include(SearchOptions, ssoMatchCase);

   // Ustawienie kursora na początek dokumentu przed rozpoczęciem wyszukiwania
   SynEditCode.CaretXY := Point(1, 1);

   // Wyszukiwanie w pętli
   while SynEditCode.SearchReplace(FindDialog.FindText, '', SearchOptions) > 0 do
   begin
     Inc(FoundCount);
     // Dodanie znalezionego wyniku do ListBox
     ListBoxSeacrh.Items.Add(Format('[%d]: %s', [
       SynEditCode.CaretY,  // Numer linii (od 1)
       SynEditCode.Lines[SynEditCode.CaretY - 1]  // Pobranie tekstu linii
     ]));

     FSearchAll.Add(ListBoxSeacrh.Items[ListBoxSeacrh.Items.Count - 1]);
     SynEditCode.CaretX := SynEditCode.CaretX + 1;
     if SynEditCode.CaretX > Length(SynEditCode.LineText) + 1 then
     begin
       SynEditCode.CaretY := SynEditCode.CaretY + 1;
       SynEditCode.CaretX := 1;
     end;

     // Zabezpieczenie przed wyszukiwaniem poza dokumentem
     if SynEditCode.CaretY > SynEditCode.Lines.Count then
       Break;
   end;

   // Komunikat podsumowujący
   if FoundCount = 0 then
     ListBoxSeacrh.Items.Add(TranslateOccurrencesZerofound)
   else
     //ListBoxSeacrh.Items.Insert(0, Format('Znaleziono %d wystąpień', [FoundCount]));
     ListBoxSeacrh.Items.Insert(0, Format(TranslateFound + ' %d ' + TranslateSpeeches, [FoundCount]));
  if FoundCount > 0  then
  begin
    rezultat := MessageDlg(TranslateAttentionMsg , TranslateValueLookingFound, mtInformation,[mbOk],0);
    if rezultat = mrOk then
    begin
      PageInfo.ActivePage := TabSheetSearch;
      ListBoxSeacrh.SetFocus;
    end;
    end
  else
    MessageDlg(TranslateAttentionMsg, TranslateNoDataCode, mtWarning,[mbOk],0);
end;

procedure TFormMain.EditSearchMistakesChange(Sender: TObject);
begin
  if not Assigned(FErrAll) then Exit;
  FilterListBox(EditSearchMistakes.Text, FErrAll, ListBoxErrCode);
end;

procedure TFormMain.EditSearchResultsChange(Sender: TObject);
begin
  if not Assigned(FSearchAll) then Exit;
  FilterListBox(EditSearchResults.Text, FSearchAll, ListBoxSeacrh);
end;

procedure TFormMain.EditSearchVariablesChange(Sender: TObject);
begin
  if not Assigned(FVarAll) then Exit;
  FilterListBox(EditSearchVariables.Text, FVarAll, ListBoxSearchVariables);
end;

procedure TFormMain.EditSearchCommentsChange(Sender: TObject);
begin
  if not Assigned(FCmtAll) then Exit;
  FilterListBox(EditSearchComments.Text, FCmtAll, ListBoxSearchComments);
end;

procedure TFormMain.DokumentacjaExecute(Sender: TObject);
begin
  FormAutor.OpenLink('https://doc.avocado-code.com/');
end;


procedure TFormMain.EditSearchFunctionsChange(Sender: TObject);
begin
  if not Assigned(FFuncAll) then Exit;
  FilterListBox(EditSearchFunctions.Text, FFuncAll, ListBoxSearchFunctions);
end;

procedure TFormMain.FindDialogShow(Sender: TObject);
var
  Options: TSynSearchOptions;
begin
  if frMatchCase in FindDialog.Options then
    Include(Options, ssoMatchCase);
  if frWholeWord in FindDialog.Options then
    Include(Options, ssoWholeWord);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
var
  i: Integer;
  Node: TTreeNode;
  P: PNodeRec;
begin
   for i := 0 to TreeView.Items.Count - 1 do
   begin
     Node := TreeView.Items[i];

     if Assigned(Node.Data) then
     begin
       P := PNodeRec(Node.Data);
       Dispose(P);
       Node.Data := nil;
     end;
   end;
   //zwalnia pamiec bledy
   //if Assigned(FAllErrors) then
  //  FAllErrors.Free;
  if Assigned(FErrAll) then FErrAll.Free;
  if Assigned(FCmtAll) then FCmtAll.Free;
  if Assigned(FVarAll) then FVarAll.Free;
  if Assigned(FFuncAll) then FFuncAll.Free;
  if Assigned(FSearchAll) then FSearchAll.Free;
  if Assigned(FSearcDoc) then FSearcDoc.Free;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    if (Key = Ord('F')) and (ssCtrl in Shift) then
   begin
     FindDialog.Execute;
     Key := 0;
   end
   else if (Key = Ord('H')) and (ssCtrl in Shift) then
   begin
     ReplaceDialog.Execute;
     Key := 0;
   end;
end;



procedure TFormMain.ListBoxErrCodeClick(Sender: TObject);
var
S, NumStr: string;
LineNum, StartPos, EndPos: Integer;
begin
  if ListBoxErrCode.ItemIndex < 0 then Exit;

  S := ListBoxErrCode.Items[ListBoxErrCode.ItemIndex];
  StartPos := Pos('[', S);
  EndPos := Pos(']', S);

  if (StartPos > 0) and (EndPos > StartPos) then
  begin
    NumStr := Copy(S, StartPos + 1, EndPos - StartPos - 1);
    LineNum := StrToIntDef(NumStr, -1);

    if (LineNum >= 1) and (LineNum <= SynEditCode.Lines.Count) then
    begin
      HighlightErrorLine(LineNum);
      SynEditCode.CaretXY := Point(1, LineNum);
      SynEditCode.TopLine := LineNum;
      SynEditCode.SetFocus;
    end;
  end;
end;

procedure TFormMain.ListBoxErrCodeDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  t: string;
  TextOffset: Integer;
begin
   with (Control as TListBox).Canvas do
     begin
       t := (Control as TListBox).Items[Index];
       TextOffset := 2;

       if (odSelected in State) then
       begin
         Brush.Color := ClRed;
         Font.Color  := clWhite;
       end
       else
       begin
         Brush.Color := (Control as TListBox).Color;
         Font.Color  := (Control as TListBox).Font.Color;
       end;
       FillRect(ARect);
       TextOut(ARect.Left + TextOffset, ARect.Top, t);
       if (odFocused in State) then
       begin
         DrawFocusRect(ARect);
       end;
     end;
end;

procedure TFormMain.ListBoxSeacrhClick(Sender: TObject);
var
LineNumber: Integer;
ItemText: string;
BracketEndPos: Integer;
begin
  if ListBoxSeacrh.ItemIndex >= 0 then
     begin
       // Get the text of the selected item
       // Pobierz tekst zaznaczonego elementu
       ItemText := ListBoxSeacrh.Items[ListBoxSeacrh.ItemIndex];
       // Extract line number from text (format: "[number]:text")
       // Wyodrębnij numer linii z tekstu (format: "[numer]: tekst")
       BracketEndPos := Pos(']:', ItemText);
       if BracketEndPos > 0 then
       begin
         // Converting text to number (line number)
         // Konwersja tekstu na liczbę (numer linii)
         LineNumber := StrToIntDef(Copy(ItemText, 2, BracketEndPos - 2), -1);

         if LineNumber > 0 then
         begin
           //Positioning the cursor in SynEdit on the appropriate line
           // Ustawienie kursora w SynEdit na odpowiedniej linii

           SynEditCode.CaretY := LineNumber;
           SynEditCode.CaretX := 1;
            //podświetlenie
           HighlithSynEditLine(LineNumber);
           // Opcjonalnie: przewiń do widoczności
           SynEditCode.TopLine := Max(1, LineNumber - (SynEditCode.LinesInWindow div 2));
           SynEditCode.SetFocus;
         end;
       end;
     end;
end;

procedure TFormMain.ListBoxSeacrhDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  t: string;
  TextOffset: Integer;
begin
  with (Control as TListBox).Canvas do
       begin
         t := (Control as TListBox).Items[Index];
         TextOffset := 2;

         if (odSelected in State) then
         begin
           Brush.Color := $00258527;
           Font.Color  := clWhite;
         end
         else
         begin
           Brush.Color := (Control as TListBox).Color;
           Font.Color  := (Control as TListBox).Font.Color;
         end;
         FillRect(ARect);
         TextOut(ARect.Left + TextOffset, ARect.Top, t);
         if (odFocused in State) then
         begin
           DrawFocusRect(ARect);
         end;
       end;
end;

procedure TFormMain.ListBoxSearchCommentsClick(Sender: TObject);
var
  S, NumStr: string;
  LineNum, StartPos, EndPos: Integer;
begin
 if ListBoxSearchComments.ItemIndex < 0 then
    Exit;

  S := ListBoxSearchComments.Items[ListBoxSearchComments.ItemIndex];

  // numer linii między '[' a ']'
  StartPos := Pos('[', S);
  EndPos := Pos(']', S);

  if (StartPos > 0) and (EndPos > StartPos) then
  begin
    NumStr := Copy(S, StartPos + 1, EndPos - StartPos - 1);
    LineNum := StrToIntDef(NumStr, -1);

    if (LineNum >= 1) and (LineNum <= SynEditCode.Lines.Count) then
    begin
      //podświetlenie
      HighlithSynEditLine(LineNum);
      // ustaw kursor w SynEdit na początku wskazanej linii
      SynEditCode.CaretXY := Point(1, LineNum);
      SynEditCode.EnsureCursorPosVisible;
      SynEditCode.SetFocus;
    end;
  end;

end;

procedure TFormMain.ListBoxSearchCommentsDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  t: string;
  TextOffset: Integer;
begin
  with (Control as TListBox).Canvas do
      begin
        t := (Control as TListBox).Items[Index];
        TextOffset := 2;

        if (odSelected in State) then
        begin
          Brush.Color := $00258527;
          Font.Color  := clWhite;
        end
        else
        begin
          Brush.Color := (Control as TListBox).Color;
          Font.Color  := (Control as TListBox).Font.Color;
        end;
        FillRect(ARect);
        TextOut(ARect.Left + TextOffset, ARect.Top, t);
        if (odFocused in State) then
        begin
          DrawFocusRect(ARect);
        end;
      end;
end;

procedure TFormMain.ListBoxSearchDocumentaionDblClick(Sender: TObject);
var
  y:integer;
begin
  MemoSearchDocumentation.Clear;
  y:= ListBoxSearchDocumentaion.ItemIndex;
  if ListBoxSearchDocumentaion.selected[y] then
  begin
    MemoSearchDocumentation.Lines.add(ListBoxSearchDocumentaion.Items.Strings[y]);
    //PodliczLinijki(ListBox1, StatusBar2);
    //Status.Panels.Items[3].Text := ' ';
    end;
end;

procedure TFormMain.ListBoxSearchFunctionsClick(Sender: TObject);
var
  S, NumStr: string;
  LineNum, StartPos, EndPos: Integer;
begin
  if ListBoxSearchFunctions.ItemIndex < 0 then
      Exit;

    S := ListBoxSearchFunctions.Items[ListBoxSearchFunctions.ItemIndex];

    // numer linii między '[' a ']'
    StartPos := Pos('[', S);
    EndPos := Pos(']', S);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      NumStr := Copy(S, StartPos + 1, EndPos - StartPos - 1);
      LineNum := StrToIntDef(NumStr, 1);

      if (LineNum > 0) and (LineNum <= SynEditCode.Lines.Count) then
      begin
       //podświetlenie
        HighlithSynEditLine(LineNum);
        SynEditCode.CaretXY := Point(1, LineNum);
        SynEditCode.EnsureCursorPosVisible;
        SynEditCode.SetFocus;
      end;
    end;
end;

procedure TFormMain.ListBoxSearchFunctionsDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  t: string;
  TextOffset: Integer;
begin
     with (Control as TListBox).Canvas do
     begin
       t := (Control as TListBox).Items[Index];
       TextOffset := 2;

       if (odSelected in State) then
       begin
         Brush.Color := $00258527;
         Font.Color  := clWhite;
       end
       else
       begin
         Brush.Color := (Control as TListBox).Color;
         Font.Color  := (Control as TListBox).Font.Color;
       end;
       FillRect(ARect);
       TextOut(ARect.Left + TextOffset, ARect.Top, t);
       if (odFocused in State) then
       begin
         DrawFocusRect(ARect);
       end;
     end;
end;

procedure TFormMain.ListBoxSearchVariablesClick(Sender: TObject);
var
  S, NumStr: string;
  LineNum, StartPos, EndPos: Integer;
begin
  if ListBoxSearchVariables.ItemIndex < 0 then
    Exit;

  S := ListBoxSearchVariables.Items[ListBoxSearchVariables.ItemIndex];

  // numer linii między '[' a ']'
  StartPos := Pos('[', S);
  EndPos := Pos(']', S);
  if (StartPos > 0) and (EndPos > StartPos) then
  begin
    NumStr := Copy(S, StartPos + 1, EndPos - StartPos - 1);
    LineNum := StrToIntDef(NumStr, 1);

    if (LineNum > 0) and (LineNum <= SynEditCode.Lines.Count) then
    begin
      //podświetlenie
      HighlithSynEditLine(LineNum);
      SynEditCode.CaretXY := Point(1, LineNum);
      SynEditCode.EnsureCursorPosVisible;
      SynEditCode.SetFocus;
    end;
  end;
end;

procedure TFormMain.ListBoxSearchVariablesDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  t: string;
  TextOffset: Integer;
begin
  with (Control as TListBox).Canvas do
       begin
         t := (Control as TListBox).Items[Index];
         TextOffset := 2;

         if (odSelected in State) then
         begin
           Brush.Color := $00258527;
           Font.Color  := clWhite;
         end
         else
         begin
           Brush.Color := (Control as TListBox).Color;
           Font.Color  := (Control as TListBox).Font.Color;
         end;
         FillRect(ARect);
         TextOut(ARect.Left + TextOffset, ARect.Top, t);
         if (odFocused in State) then
         begin
           DrawFocusRect(ARect);
         end;
       end;
end;



procedure TFormMain.MenuExamplesClick(Sender: TObject);
begin
  FormPrzyklady.ShowModal;
end;



procedure TFormMain.MenuItAiAsystantClick(Sender: TObject);
begin
  aiassistant.Show;
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
  IsClickMainMenuLanguage(3);
end;

procedure TFormMain.MenuItem13Click(Sender: TObject);
begin
  SetDefaultLang('de');
  lang := 'de';
  IsClickMainMenuLanguage(2);
end;


procedure TFormMain.MenuIRosyjskiClick(Sender: TObject);
begin
  SetDefaultLang('ru');
  lang := 'ru';
  IsClickMainMenuLanguage(4);
end;



procedure TFormMain.MenuItem19Click(Sender: TObject);
begin
  SettingTheme.ShowModal;
end;

procedure TFormMain.MenuItem20Click(Sender: TObject);
var
i: TModalResult;
ShouldProceed: Boolean;
begin
  if SynEditCode.Text <> '' then
  begin
    if MessageDlg(TranslateAttentionMsg, TranslateCreateNewFile, mtInformation, [mbOk, mbCancel], 0) <> mrOk then
      Exit;
  end;
  NameProgram := '';
  if not InputQuery(NewProgramFile, NewNamezprogram, NameProgram) then
    Exit;

  SynEditCode.ClearAll;
  SynEditCode.Lines.Clear;
  MemoOutPut.Clear;
  MemoLogs.Clear;
  IsConsoleProgram := False;

  SynEditCode.Lines.Add('program_ui ' + NameProgram);

  if lang = 'pl' then
  begin
    SynEditCode.Lines.Add('glowny ');
    SynEditCode.Lines.Add(' ');
    SynEditCode.Lines.Add('koniec.');
  end
  else
  begin
    SynEditCode.Lines.Add('main ');
    SynEditCode.Lines.Add(' ');
    SynEditCode.Lines.Add('end.');
  end;
end;

procedure TFormMain.MenuItem9Click(Sender: TObject);
begin
  SetDefaultLang('pl');
  lang := 'pl';
  IsClickMainMenuLanguage(5);
end;

procedure TFormMain.MenuItemAlwaysontopmodeClick(Sender: TObject);
begin
  //FormStyle := fsStayOnTop;
   FormStyle := fsSystemStayOnTop
end;

procedure TFormMain.MenuItemAvocadoPatronsClick(Sender: TObject);
begin
  PatronsAvocado.ShowModal;
end;

procedure TFormMain.MenuItemCompileClick(Sender: TObject);
begin
  butCompileCodeClick(Sender);
end;

procedure TFormMain.MenuItemConsoleProgramClick(Sender: TObject);
var
  i: TModalResult;
begin
  i := MessageDlg(TranslateAttentionMsg,TranslateCreateNewFile, mtInformation,[mbOk,mbCancel],0);
  if i = mrOk then
  begin
    SynEditCode.ClearAll;
    if InputQuery(NewProgramFile, NewNamezprogram, NameProgram) then
  begin
    SynEditCode.Clear;
    MemoOutPut.Clear;
    MemoLogs.Clear;
    IsConsoleProgram := True;

    if lang = 'pl' then
    begin
      SynEditCode.Lines.Add('program ' + NameProgram);
      SynEditCode.Lines.Add('glowny ');
      SynEditCode.Lines.Add(' ');
      SynEditCode.Lines.Add('koniec.');
    end
    else
    begin
      SynEditCode.Lines.Add('program ' + NameProgram);
      SynEditCode.Lines.Add('main ');
      SynEditCode.Lines.Add(' ');
      SynEditCode.Lines.Add('end.');
    end;
  end;
  end;

  if i = mrCancel then
  begin
   ModalResult := mrCancel;
  end;
end;


procedure TFormMain.MenuItemOpenFolderClick(Sender: TObject);
begin
  if OD.Execute then
  begin
    OpenFileProject := OD.FileName;
    LoadProjectTree;
  end;
end;

procedure TFormMain.MenuItemrunwithoutcompilationClick(Sender: TObject);
begin
  if Trim(MemoOutPut.Text) = '' then
  begin
    MessageDlg(TranslateMistake, NoCodeOpenFileorWriteCodeEditor, mtError, [mbOk], 0);
    Exit;
  end;
  RunPascalInstantly(MemoOutPut.Text);
end;

procedure TFormMain.MenuItemSearchClick(Sender: TObject);
begin
  ListBoxSeacrh.Clear;
  FindDialog.Execute;
end;

procedure TFormMain.MenuItemStandardModeClick(Sender: TObject);
begin
  FormStyle := fsNormal;
end;



procedure TFormMain.NowyPlikExecute(Sender: TObject);
begin
  MenuItemConsoleProgramClick(sender);
end;


procedure TFormMain.ReplaceDialogFind(Sender: TObject);
begin
  ListFunctionsFromSynEdit;
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

procedure TFormMain.SBClearSearchCommentsClick(Sender: TObject);
begin
  EditSearchComments.Clear;
end;

procedure TFormMain.SBClearSearchDocumentaionClick(Sender: TObject);
begin
  EditSearchDocumentation.Clear;
end;

procedure TFormMain.SBClearSearchFunctionsClick(Sender: TObject);
begin
  EditSearchFunctions.Clear;
end;

procedure TFormMain.SBClearSearchMistakesClick(Sender: TObject);
begin
  EditSearchMistakes.Clear;
end;

procedure TFormMain.SBClearSearchVariablesClick(Sender: TObject);
begin
  EditSearchVariables.Clear;
end;

procedure TFormMain.SBClearSearcResultsClick(Sender: TObject);
begin
  EditSearchResults.Clear;
end;


procedure TFormMain.SynEditCodeChange(Sender: TObject);
begin
 if Assigned(SynEditCode) then
  begin
    //ToolButton1Click(sender);
    NumberWordSynEdit := Length(SynEditCode.Text);
    StatusBar.Panels.Items[0].Text := (CountLine) + ' ' + IntToStr(SynEditCode.Lines.Count);
    StatusBar.Panels.Items[1].Text := (CountChars) + ' ' + IntToStr(NumberWordSynEdit);
    IdleTimer1.Enabled := False;
    IdleTimer1.Enabled := True;
    // Zrestartowanie timera za każdym naciśnięciem klawisza
    TimerScanFunctions.Enabled := False;
    TimerScanFunctions.Enabled := True;
  end;
end;

procedure TFormMain.SynEditCodeClick(Sender: TObject);
begin
   SynEditCode.SelectedColor.Background := $002F5330;
   SynEditCode.SelectedColor.BackAlpha := 200;
end;

procedure TFormMain.TimerScanFunctionsTimer(Sender: TObject);
begin
  TimerScanFunctions.Enabled := False; // zatrzymujemy timer do następnej zmiany
  // update feature list / aktualizacja listy funkcji
  ToolButton1Click(Sender);
  ListFunctionsFromSynEdit;
  // updating the list of variables. / aktualizacja listy zmiennych.
  ListVariablesFromSynEdit;
  //Updating comment list. / Aktualizacja listy komentarzy.
  ListCommentsFromSynEdit;
end;

procedure TFormMain.ToolButton2Click(Sender: TObject);
begin
  MenuItemrunwithoutcompilationClick(sender);
end;



procedure TFormMain.ToolButtonDebugClick(Sender: TObject);
begin
  CheckAvocadoCode;
end;

//procedure TFormMain.NowyPlikExecute(Sender: TObject);
//begin
//  MenuNewFileClick(sender);
//end;

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
  FormAutor.OpenLink('https://doc.avocado-code.com/');
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


procedure TFormMain.MenuOpcjeProjektuClick(Sender: TObject);
begin
  FormOpcjeProjektu.ShowModal;
end;

procedure TFormMain.MenuOpenClick(Sender: TObject);
begin
  if OD.Execute then
  begin
  SynEditCode.Lines.LoadFromFile(OD.FileName);
  OpenFileProject := OD.FileName;                           // pełna ścieżka
  OpenProjectDir  := ExtractFilePath(OD.FileName);          // katalog projektu
  OpenProjectName := ChangeFileExt(ExtractFileName(OD.FileName), '');
  Caption := AvocadoVersion  + ' ' + OpenProjectTranslate + ' ' + OpenProjectName;
  IdleTimer1.Enabled := True;
  ToolButton1Click(Sender);
  //update feature list. / aktualizacja listy funkcji.
  ListFunctionsFromSynEdit;
  //updating the list of variables. / aktualizacja listy zmiennych.
  ListVariablesFromSynEdit;
  //Updating comment list. / Aktualizacja listy komentarzy.
  ListCommentsFromSynEdit;
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
  try
    MemoOutPut.Clear;

    // 1. Wykonujemy transpilację (używa TranslateCode i słownika .ini wewnątrz)
    FTranslatedCode.Assign(FTranslator.Translate(SynEditCode.Lines));

    // Synchronizujemy flagę GUI z translatora do IDE
    IsConsoleProgram := not FTranslator.IsGUIProject;

    MemoOutPut.Lines.Text := FTranslatedCode.Text;

  except
    on E: Exception do
      MemoOutPut.Lines.Add(TranslateTranslationError + E.Message);
  end;

  //  MemoOutPut.Clear;
  //  FTranslatedCode.Assign(FTranslator.Translate(SynEditCode.Lines));
  //
  //  //MemoOutPut.Lines.Add('{=== Free Pascal Code ===}');
  //
  //  MemoOutPut.Lines.Add(FTranslatedCode.Text);
  //  //BtnCompile.Enabled := True;
  //except
  //  on E: Exception do
  //    MemoOutPut.Lines.Add(TranslateTranslationError + E.Message);
  //end;
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
  // Jeśli plik nie został zapisany, wymuszam zapisanie przed kompilacją
  if (sFileName = '') then
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

procedure TFormMain.TreeViewCollapsing(Sender: TObject; Node: TTreeNode;
  var AllowCollapse: Boolean);
begin
  // Zmień ikonę z powrotem na Folder Zamknięty (0)
  if Assigned(Node.Data) and PNodeRec(Node.Data)^.IsFolder then
  begin
    Node.ImageIndex := 0;
    Node.SelectedIndex := 0;
  end;
end;

procedure TFormMain.TreeViewDblClick(Sender: TObject);
var
Node: TTreeNode;
P: PNodeRec;
begin
    Node := TreeView.Selected;
    if not Assigned(Node) then Exit;

    P := PNodeRec(Node.Data);
    if not Assigned(P) then Exit;

    if P^.IsFolder then
    begin
      Node.Expand(False);
      Exit;
    end;
     //Zapisujemy plik
     SaveCurrentFile;
    // Plik — otwieramy
    try
      SynEditCode.Lines.LoadFromFile(P^.FullPath);
      OpenFileProject := P^.FullPath; // aktualizuje aktualny plik
      Caption := AvocadoVersion + ' ' + OpenProjectTranslate + ' ' + ExtractFileName(OpenProjectName);
      IdleTimer1.Enabled := True;
      ToolButton1Click(Sender);
      //update feature list. / aktualizacja listy funkcji.
      ListFunctionsFromSynEdit;
      //updating the list of variables. / aktualizacja listy zmiennych.
      ListVariablesFromSynEdit;
      //Updating comment list. / Aktualizacja listy komentarzy.
      ListCommentsFromSynEdit;
    except
      on E: Exception do
        MemoLogs.Lines.Add('Błąd otwarcia pliku: ' + E.Message);
    end;
end;

procedure TFormMain.TreeViewExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
  P: PNodeRec;
begin
    if Assigned(Node.Data) then
        begin
          P := PNodeRec(Node.Data);

          if P^.IsFolder then
          begin
            // Zmień ikonę na Folder Otwarty (1)
            Node.ImageIndex := 1;
            Node.SelectedIndex := 1;

            // Sprawdź, czy folder został już załadowany
            if not P^.Loaded then
            begin
              // Usuń "Dummy Node"
              Node.DeleteChildren;

              // Załaduj właściwą zawartość folderu
              AddSubNodes(Node, P^.FullPath);

              // Oznacz jako załadowany
              P^.Loaded := True;
            end;
          end;
        end;
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
    InstantFpcPath := Ini.ReadString('main', 'instantfpc', '\fpc\3.2.2\bin\x86_64-win64\instantfpc.exe');

    //loads the programm language into the UI
    lang := Ini.ReadString('defaultlanguage','language','en');
    case lang of
    'en':
    begin
      //English language
      SetDefaultLang('en');
      IsClickMainMenuLanguage(0);
      LoadTextDocumenation('documentation-en.txt')
    end;
    'pl':
    begin
      //Polish language
      SetDefaultLang('pl');
      IsClickMainMenuLanguage(5);
      LoadTextDocumenation('documentation-pl.txt');
    end;
    'ru':
    begin
      //Russian language
      SetDefaultLang('ru');
      IsClickMainMenuLanguage(4);
      LoadTextDocumenation('documentation-en.txt');
    end;
    'de':
    begin
      //German language
      SetDefaultLang('de');
      IsClickMainMenuLanguage(2);
      LoadTextDocumenation('documentation-en.txt');
    end;
    'pt':
    begin
      //Portuguese language
      SetDefaultLang('pt');
      IsClickMainMenuLanguage(4);
      LoadTextDocumenation('documentation-en.txt');
    end;
    'es':
    begin
      //Spanish language
      SetDefaultLang('es');
      IsClickMainMenuLanguage(1);
      LoadTextDocumenation('documentation-en.txt');
    end;
    'fr':
    begin
      //French language
      SetDefaultLang('fr');
      IsClickMainMenuLanguage(3);
      LoadTextDocumenation('documentation-en.txt');
    end
    else
      SetDefaultLang('en');
      IsClickMainMenuLanguage(0);
      LoadTextDocumenation('documentation-en.txt');
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
var
  Stream: TFileStream;
  OutputString: string;
  // BOM dla UTF-8 to bajty: EF BB BF
  BOM: array[0..2] of Byte = ($EF, $BB, $BF);
begin
      SD.DefaultExt := 'avocado';
      SD.Filter := 'Avocado files (*.avocado)|*.avocado|All files (*.*)|*.*';

      if SD.Execute then
      begin
        Stream := TFileStream.Create(SD.FileName, fmCreate);
        try
          Stream.WriteBuffer(BOM, 3);
          OutputString := SynEditCode.Lines.Text;

          // Zapisz treść pliku
          if OutputString <> '' then
            Stream.WriteBuffer(Pointer(OutputString)^, Length(OutputString));

        finally
          Stream.Free;
        end;

        // Aktualizacja zmiennych w programie
        ZapisanaNazwaPliku := ChangeFileExt(ExtractFileName(SD.FileName), '');
        FileNamePr := SD.FileName;
      end;
  {
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
  }
end;

procedure TFormMain.IsClickMainMenuLanguage(number: Integer);
var
  i: Integer;
begin
  for i := 0 to MainMenu1.Items[6].Count - 1 do
    begin
      if i <> number then
        MainMenu1.Items[6].Items[i].Checked := False;
    end;
    // Select the selected item
    MainMenu1.Items[6].Items[number].Checked := True;
end;


procedure TFormMain.CompilePascalCode(const PascalCode, OutputFile: string);
var
AProcess: TProcess;
OutputLines: TStringList;
FpcUnitPath, SourceDir: string;
IdeDirectory, IdeModulesPath: string;
UserModulesPath: string;
BuildMode: string;
Stream: TFileStream;
BOM: array[0..2] of Byte = ($EF, $BB, $BF);
TempFile, TempDir: string;
RawFileName: string;
i: Integer;
FinalExePath: string;
ExeNameFromCode: string;
begin
  // --- WALIDACJA ŚCIEŻEK ---
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

  if Trim(PascalCode) = '' then
  begin
      MemoLogs.Lines.Add(TranslateErrPacalCodeCompile);
      Exit;
  end;

  // --- PRZYGOTOWANIE PLIKU TYMCZASOWEGO .PAS ---
  TempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'Avocado';
  if not ForceDirectories(TempDir) then
  begin
    MemoLogs.Lines.Add('Błąd: Nie można utworzyć katalogu tymczasowego: ' + TempDir);
    Exit;
  end;
  TempDir := IncludeTrailingPathDelimiter(TempDir);

  if SaveFileProject <> '' then
      RawFileName := ExtractFileName(SaveFileProject)
  else if OpenFileProject <> '' then
      RawFileName := ExtractFileName(OpenFileProject)
  else
      RawFileName := 'avocado_temp.pas';

  // Usuwamy spacje z nazwy pliku .pas
  RawFileName := StringReplace(RawFileName, ' ', '_', [rfReplaceAll]);
  TempFile := TempDir + ChangeFileExt(RawFileName, '.pas');

  // --- ZAPIS KODU DO PLIKU ---
  BuildMode := 'Release';
  try
    try
      if FileExists(TempFile) then
      begin
        if not DeleteFile(TempFile) then
        begin
          Sleep(50);
          if not DeleteFile(TempFile) then
             TempFile := TempDir + 'avocado_temp_' + IntToStr(GetTickCount64) + '.pas';
        end;
      end;

      Stream := TFileStream.Create(TempFile, fmCreate);
      try
        Stream.WriteBuffer(BOM, 3);
        if PascalCode <> '' then
          Stream.WriteBuffer(Pointer(PascalCode)^, Length(PascalCode));
      finally
        Stream.Free;
      end;

      // --- USTALANIE NAZWY PLIKU .EXE (TWOJA ZMIANA) ---

      // 1. Pobieramy nazwę z translatora (zakładam, że masz dostęp do instancji FTranslator lub jest to zmienna globalna)
      // Jeśli NameProgram jest w instancji klasy, użyj FTranslator.NameProgram
      // Jeśli jest globalna w module avocado_translator, użyj po prostu NameProgram
      ExeNameFromCode := Trim(NameProgram); // <--- Zmienna z AvocadoTranslator

      // 2. Jeśli nazwa jest pusta lub domyślna, używamy nazwy z parametru OutputFile
      if (ExeNameFromCode = '') or (ExeNameFromCode = 'untitledprogram') then
      begin
        FinalExePath := OutputFile;
      end
      else
      begin
        // 3. Budujemy nową ścieżkę: Katalog z OutputFile + Nazwa z kodu + .exe
        FinalExePath := ExtractFilePath(OutputFile) + ExeNameFromCode + '.exe';
      end;

      // 4. Usuwamy stary plik .exe (jeśli istnieje), żeby uniknąć błędów linkera
      if FileExists(FinalExePath) then
      begin
        if not DeleteFile(FinalExePath) then
          MemoLogs.Lines.Add('OSTRZEŻENIE: Nie można usunąć starego pliku EXE (może jest uruchomiony?).');
      end;


      // --- KONFIGURACJA PROCESU KOMPILACJI ---
      AProcess := TProcess.Create(nil);
      OutputLines := TStringList.Create;
      try
        AProcess.Executable := FFpcPath;
        AProcess.Parameters.Add(TempFile); // Plik źródłowy

        // Ścieżki do unitów (-Fu)
        FpcUnitPath := IncludeTrailingPathDelimiter(FFpcBasePath) + 'units' + PathDelim + FTargetPlatform;
        if DirectoryExists(FpcUnitPath) then
          AProcess.Parameters.Add('-Fu' + FpcUnitPath)
        else
          MemoLogs.Lines.Add(TranslateErrRequiredFPCstandardUnitDirfound + FpcUnitPath);

        // Tryb Release
        if BuildMode = 'Release' then
        begin
           MemoLogs.Lines.Add(TranslateCompilingReleaseMode);
           AProcess.Parameters.Add('-O3');
           AProcess.Parameters.Add('-Os');
           AProcess.Parameters.Add('-CX');
           AProcess.Parameters.Add('-XX');
           AProcess.Parameters.Add('-g-');

           // GUI vs Konsola
           if not IsConsoleProgram then
             AProcess.Parameters.Add('-WG'); // Windows GUI
        end
        else
        begin
           MemoLogs.Lines.Add(TranslateCompilingDebugMode);
        end;

        AProcess.Parameters.Add('-FU' + TempDir); // Pliki tymczasowe (.o, .ppu)

        SourceDir := ExtractFilePath(TempFile);
        if SourceDir <> '' then AProcess.Parameters.Add('-Fu' + SourceDir);

        if UserModulesPath <> '' then
        begin
          AProcess.Parameters.Add('-Fu' + UserModulesPath);
          MemoLogs.Lines.Add(TranslateAddUserModulesPath + UserModulesPath);
        end;

        // Moduły wbudowane
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

        // --- PLIK WYJŚCIOWY (-o) ---
        // Używamy naszej obliczonej ścieżki
        AProcess.Parameters.Add('-o' + FinalExePath);

        // Opcje procesu
        AProcess.Options := [poUsePipes, poStderrToOutput];
        AProcess.ShowWindow := swoHIDE;

        MemoLogs.Lines.Add(TranslateStartComilationParam + AProcess.Parameters.Text);

        // --- URUCHOMIENIE (ZAPOBIEGANIE ZAWIESZANIU) ---
        AProcess.Execute;

        // Pętla odczytująca dane w locie
        while AProcess.Running do
        begin
          if AProcess.Output.NumBytesAvailable > 0 then
             OutputLines.LoadFromStream(AProcess.Output);

          Sleep(10);
          //Application.ProcessMessages; // Ważne: pozwala oknu reagować
        end;

        // Doczytanie reszty po zakończeniu
        if AProcess.Output.NumBytesAvailable > 0 then
           OutputLines.LoadFromStream(AProcess.Output);

        MemoLogs.Lines.AddStrings(OutputLines);

        // Wynik
        if AProcess.ExitStatus = 0 then
          MemoLogs.Lines.Add(TranslateCompilationSuccses + FinalExePath)
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
  finally
    // Sprzątanie
    try
      DeleteFilesInDir(TempDir, '*.o');
      DeleteFilesInDir(TempDir, '*.ppu');
      if FileExists(TempFile) then DeleteFile(TempFile);
    except
    end;
  end;
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

procedure TFormMain.ListFunctionsFromSynEdit;
var
  i,p: Integer;
  LineText, LineLow: string;
begin
    //Dotyczy wyszukiwania w funkcjach w Edit - EditSearchFunctions
    if not Assigned(FFuncAll) then
    FFuncAll := TStringList.Create
    else
    FFuncAll.Clear;

    ListBoxSearchFunctions.Clear;
    //Teraz laduje sie z pliku functions.txt do Prefixes
    // lista słów kluczowych teraz jest w  pliku functions.txt tak jest lepiej
    // Prefixes := ['function', 'procedure', 'pisz_linie', 'print_line', 'print',
    // 'pisz', 'funkcja'];
  if Length(Prefixes) = 0 then
  begin
    ListBoxSearchFunctions.Items.Add(TranslateNoPrefixesToSearch);
    Exit;
  end;

  for i := 0 to SynEditCode.Lines.Count - 1 do
  begin
    LineText := Trim(SynEditCode.Lines[i]);
    if LineText = '' then Continue;

    LineLow := LowerCase(LineText);

    for p := Low(Prefixes) to High(Prefixes) do
    begin
      //if StartsWithCI(LineLow, Prefixes[p]) then
      if StartsWithWord(LineText, Prefixes[p], True) then
      begin
        // linijka i numer w formacie [linia]:
        ListBoxSearchFunctions.Items.Add(Format('[%d]: %s', [i + 1, LineText]));
        FFuncAll.Add(Format('[%d]: %s', [i + 1, LineText]));
        Break;
      end;
    end;
  end;

  if ListBoxSearchFunctions.Items.Count = 0 then
    ListBoxSearchFunctions.Items.Add(TranslateFunctionNotfound);

end;

function TFormMain.StartsWithWord(const S, Prefix: string; IgnoreCase: Boolean
  ): Boolean;
var
  CompareS, ComparePrefix: string;
  NextChar: Char;
begin
  Result := False;

    if IgnoreCase then
    begin
      CompareS := LowerCase(S);
      ComparePrefix := LowerCase(Prefix);
    end
    else
    begin
      CompareS := S;
      ComparePrefix := Prefix;
      end;

  if Length(CompareS) < Length(ComparePrefix) then Exit;

  if Copy(CompareS, 1, Length(ComparePrefix)) = ComparePrefix then
  begin
    // Sprawdzenie znaku po słowie (jeśli istnieje)
    if Length(CompareS) = Length(ComparePrefix) then
      Result := True
    else
    begin
      NextChar := CompareS[Length(ComparePrefix) + 1];
      if NextChar in [' ', '(', ';'] then
        Result := True;
    end;
  end;
end;

function TFormMain.FirstDelimiterPos(const S: string; const Delims: TSysCharSet
  ): Integer;
var
  i: Integer;
begin
  Result := 0;
    for i := 1 to Length(S) do
      if S[i] in Delims then
      begin
        Result := i;
        Exit;
      end;
end;

procedure TFormMain.LoadPrefixesFromFile(const FileName: string);
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    if FileExists(FileName) then
    begin
      SL.LoadFromFile(FileName);
      SetLength(Prefixes, SL.Count); // dynamiczna tablica
      for i := 0 to SL.Count - 1 do
        Prefixes[i] := Trim(SL[i]);
    end
    else
      raise Exception.Create(TranslateFileNotFound + FileName);
  finally
    SL.Free;
  end;
end;

procedure TFormMain.ListVariablesFromSynEdit;
var
  i,p: Integer;
  LineText, LineLow: string;
begin
    if not Assigned(FVarAll) then
      FVarAll := TStringList.Create
    else
      FVarAll.Clear;

    ListBoxSearchVariables.Clear;
    if Length(PrefixesVariables ) = 0 then
    begin
      ListBoxSearchVariables.Items.Add(TranslateNoPrefixesToSearch);
      Exit;
    end;

    for i := 0 to SynEditCode.Lines.Count - 1 do
    begin
      LineText := Trim(SynEditCode.Lines[i]);
      if LineText = '' then Continue;

      LineLow := LowerCase(LineText);

      for p := Low(PrefixesVariables ) to High(PrefixesVariables ) do
      begin
        //if StartsWithCI(LineLow, Prefixes[p]) then
        if StartsWithWord(LineText, PrefixesVariables [p], True) then
        begin
          // linijka i numer w formacie [linia]:
          ListBoxSearchVariables.Items.Add(Format('[%d]: %s', [i + 1, LineText]));
          // Zapisz też do listy do filtrowania
          FVarAll.Add(Format('[%d]: %s', [i + 1, LineText]));
          Break;
        end;
      end;
    end;

    if ListBoxSearchVariables.Items.Count = 0 then
      ListBoxSearchVariables.Items.Add(TranslateNoVariablesFound);
end;

procedure TFormMain.LoadVariablesPrefixesFromFile(const FileName: string);
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    if FileExists(FileName) then
    begin
      SL.LoadFromFile(FileName);
      SetLength(PrefixesVariables, SL.Count); // dynamiczna tablica
      for i := 0 to SL.Count - 1 do
        PrefixesVariables[i] := Trim(SL[i]);
    end
    else
      raise Exception.Create(TranslateFileNotFound + FileName);
  finally
    SL.Free;
  end;
end;

procedure TFormMain.ListCommentsFromSynEdit;
var
  i: Integer;
  LineText: string;
begin
    if not Assigned(FCmtAll) then
      FCmtAll := TStringList.Create
    else
      FCmtAll.Clear;

   ListBoxSearchComments.Clear;

  for i := 0 to SynEditCode.Lines.Count - 1 do
  begin
    LineText := Trim(SynEditCode.Lines[i]);
    if LineText = '' then Continue;

    // Sprawdź, czy linia zaczyna się od //
    if Copy(LineText, 1, 2) = '//' then
    begin
      ListBoxSearchComments.Items.Add(Format('[%d]: %s', [i + 1, LineText]));
      // Zapisz też do listy do filtrowania
      FCmtAll.Add(Format('[%d]: %s', [i + 1, LineText]));
    end;
  end;

  if ListBoxSearchComments.Items.Count = 0 then
    ListBoxSearchComments.Items.Add(TranslateNoCommentsFound);
end;

procedure TFormMain.LoadDebugKeywords(const FileName: string;
  var Keywords: TStringList);
begin
  Keywords := TStringList.Create;
  if FileExists(FileName) then
    Keywords.LoadFromFile(FileName)
  else
    raise Exception.Create(TranslateDebuggerFileNotFound);
end;

procedure TFormMain.CheckAvocadoCode;
var
  i, j: Integer;
  LineText, Token, CleanLine, ErrorMsg: string;
  Tokens, Keywords, LineErrors, LineTokens: TStringList;
  FoundError: Boolean;
  Value: Double;
  L: string;
  rezultat :TModalResult;
begin
    //Dotyczy błędów w projekcie i filtrowanie błedów w EditSearchMistakes
    if not Assigned(FErrAll) then
    FErrAll := TStringList.Create
    else
    FErrAll.Clear; // wyczyść starą zawartość przed nowym sprawdzaniem


  ListBoxErrCode.Clear;
  FoundError := False;

  Keywords := TStringList.Create;
  LoadDebugKeywords('debuger.txt', Keywords);

  Tokens := TStringList.Create;
  LineErrors := TStringList.Create;
  LineTokens := TStringList.Create;

  try
    for i := 0 to SynEditCode.Lines.Count - 1 do
    begin
      LineText := SynEditCode.Lines[i];

      // Usuń komentarze i cudzysłowy
      CleanLine := RemoveComments(LineText);
      CleanLine := RemoveQuotes(CleanLine);
      CleanLine := Trim(CleanLine);
      if CleanLine = '' then Continue;

      L := LowerCase(CleanLine);

      // Ignoruj linie "program ..."
      if Pos('program ', L) = 1 then Continue;

      // Ignoruj linie debugowe rozpoczynające się od ':'
      //if Copy(L,1,1) = ':' then Continue;


      // IGNORUJ linie z importowaniem modułów

      //if (Copy(L,1,8) = 'importuj') or (Copy(L,1,6) = 'import') then
       if (StartsStr('importuj', L)) or (StartsStr('import', L)) then
      begin
        // Pobierz nazwę modułu
        Tokens.Clear;
        ExtractStrings([' ', #9], [], PChar(CleanLine), Tokens);

        // Jeśli np. "importuj matematyka", to Tokens[1] = "matematyka"
        if Tokens.Count > 1 then
        begin
          if Keywords.IndexOf(Tokens[1]) = -1 then
            Keywords.Add(Tokens[1]);  // traktujemy moduł jako dozwoloną nazwę
        end;

        Continue; // nie sprawdzaj dalej tej linii
      end;


      Tokens.Clear;
      ExtractStrings([' ', #9, '(', ')', ';', ',', '='], [], PChar(CleanLine), Tokens);

      // Sprawdź deklarację zmiennej
      for j := Low(PrefixesVariables) to High(PrefixesVariables) do
      begin
     // if LowerCase(Tokens[0]) = LowerCase(PrefixesVariables[j]) then
        if (Tokens.Count > 1) and (LowerCase(Tokens[0]) = LowerCase(PrefixesVariables[j])) then
      begin
        // to jest deklaracja zmiennej
        //if Tokens.Count > 1 then
        //begin
          if Keywords.IndexOf(Tokens[1]) = -1 then
            Keywords.Add(Tokens[1]); // dodaj nazwę zmiennej jako znaną
            Break;
         end;
      end;

      LineErrors.Clear;
      LineTokens.Clear;

      for j := 0 to Tokens.Count - 1 do
      begin
        Token := Tokens[j];
        if Token = '' then Continue;

        // Usuń końcowe znaki typu ; , ) jeśli są
        while (Token <> '') and (Token[Length(Token)] in [';', ',', ')']) do
        SetLength(Token, Length(Token) - 1);

        // Ignoruj liczby
      // Ignoruj liczby
     // if IsNumberToken(Token) then Continue;

        // Ignoruj tokeny typu suma:0:2
        if Pos(':', Token) > 0 then Continue;

        // Ignoruj liczby w formacie 2.2, 3,14
        if TryStrToFloat(Token, Value) then Continue;

        // Unikaj duplikatów tokenów w tej linii
        if LineTokens.IndexOf(Token) <> -1 then Continue;
        LineTokens.Add(Token);

        // Jeśli token nie jest znany to błąd
        if Keywords.IndexOf(Token) = -1 then
        begin
          ErrorMsg := Format('[%d]: ' + TranslateUnknownName + '"%s"', [i + 1, Token]);
          if LineErrors.IndexOf(ErrorMsg) = -1 then
            LineErrors.Add(ErrorMsg);
        end;
      end;

      // Dodaj błędy z tej linii
      for j := 0 to LineErrors.Count - 1 do
      begin
        ListBoxErrCode.Items.Add(LineErrors[j]);
        FErrAll.Add(LineErrors[j]);
        FoundError := True;
      end;
    end;

  finally
    Tokens.Free;
    LineErrors.Free;
    LineTokens.Free;
    Keywords.Free;
  end;

  if FoundError then
  begin
    rezultat := MessageDlg(TranslateErrorsInTheCode ,TranslateCodeErrorsCompilationStopped, mtError,[mbOk],0);
    if rezultat = mrOk then
    begin
      PageInfo.ActivePage := TabErrors;
      ListBoxErrCode.SetFocus;
    end;
    end
  else
    MessageDlg(TranslateCodeCorrect,TranslateNoErrorsCodeReadyToCompile, mtInformation,[mbOk],0);

end;

function TFormMain.RemoveQuotes(const Line: string): string;
var
  k: Integer;
  InSingle, InDouble: Boolean;
  Ch: Char;
  ResultLine: string;
begin
  ResultLine := '';
  InSingle := False;
  InDouble := False;
  for k := 1 to Length(Line) do
  begin
    Ch := Line[k];
    if (Ch = '''') and not InDouble then
      InSingle := not InSingle
    else if (Ch = '"') and not InSingle then
      InDouble := not InDouble
    else if not InSingle and not InDouble then
      ResultLine := ResultLine + Ch;
  end;
  Result := ResultLine;
end;

function TFormMain.RemoveComments(const Line: string): string;
var
  p1, p2: Integer;
  s: string;
begin
  s := Line;

    // komentarze jednolinijkowe //
    p1 := Pos('//', s);
    if p1 > 0 then
      s := Copy(s, 1, p1 - 1);

    // komentarze { ... }
    p1 := Pos('{', s);
    while p1 > 0 do
    begin
      p2 := Pos('}', s);
      if p2 = 0 then
        p2 := Length(s);
      Delete(s, p1, p2 - p1 + 1);
      p1 := Pos('{', s);
    end;

    Result := s;
end;

procedure TFormMain.HighlightErrorLine(LineNum: Integer);
begin
  // ustaw kursora
  SynEditCode.CaretXY := Point(1, LineNum);
  SynEditCode.TopLine := LineNum;

  // zaznaczenie całej linii - podświetlenie
  SynEditCode.BlockBegin := Point(1, LineNum);
  SynEditCode.BlockEnd := Point(Length(SynEditCode.Lines[LineNum - 1]) + 1, LineNum);

  // styl zaznaczenia na czerwono
  SynEditCode.SelectedColor.Foreground := clWhite; // kolor czcionki
  SynEditCode.SelectedColor.Background := clRed;   // kolor tła
end;

procedure TFormMain.HighlithSynEditLine(LineNum: Integer);
begin
  SynEditCode.CaretXY := Point(1, LineNum);
  SynEditCode.TopLine := LineNum;

  // zaznaczenie całej linii - podświetlenie
  SynEditCode.BlockBegin := Point(1, LineNum);
  SynEditCode.BlockEnd := Point(Length(SynEditCode.Lines[LineNum - 1]) + 1, LineNum);

  // styl zaznaczenia na czerwono
  SynEditCode.SelectedColor.Foreground := clWhite; // kolor czcionki
  SynEditCode.SelectedColor.Background := $00258527;   // kolor tła
end;


procedure TFormMain.LoadTextDocumenation(FileName: string);
begin
  ListBoxSearchDocumentaion.Items.LoadFromFile(ExtractFilePath(ParamStr(0))+ '\docs\' + FileName ,TEncoding.UTF8);
end;



procedure TFormMain.LoadDocToListBox(const FileName: string;
  var Keywords: TStringList);
begin
  Keywords := TStringList.Create;
  if FileExists(FileName) then
    Keywords.LoadFromFile(FileName)
  else
    raise Exception.Create('Nie znaleziono pliku documentation.txt');
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

procedure TFormMain.DeleteFilesInDir(const APath, AMask: string);
var
  SR: TSearchRec; // Zmienna do przechowywania informacji o znalezionym pliku
  Found: Integer;
begin
  // Używamy funkcji FindFirst, aby znaleźć pierwszy plik pasujący do maski (np. '*.o')
  // Zapewniamy, że ścieżka kończy się separatorem, a następnie dodajemy maskę
  Found := FindFirst(IncludeTrailingPathDelimiter(APath) + AMask, faAnyFile - faDirectory, SR);
  try
    // Pętla wykonuje się tak długo, jak długo znajdują się pliki
    while Found = 0 do
    begin
      try
        // Usuń znaleziony plik
        DeleteFile(IncludeTrailingPathDelimiter(APath) + SR.Name);
      except
        // Ignoruj błędy usuwania (np. plik jest zablokowany)
      end;
      // Przejdź do następnego pliku
      Found := FindNext(SR);
    end;
  finally
    // ZAWSZE zamykaj wyszukiwanie
    FindClose(SR);
  end;
end;



procedure TFormMain.LoadProjectTree;
var
  RootNode: TTreeNode;
  RootPath: string;
  P: PNodeRec;
begin
  TreeView.Items.BeginUpdate;
   try
     TreeView.Items.Clear;

     if OpenFileProject = '' then Exit;

     RootPath := ExtractFilePath(OpenFileProject);
     if RootPath = '' then Exit;

     RootNode := TreeView.Items.Add(nil, ExtractFileName(ExcludeTrailingPathDelimiter(RootPath)));
     New(P);
     P^.IsFolder := True;
     P^.FullPath := IncludeTrailingPathDelimiter(RootPath);
     RootNode.Data := P;
     AddSubNodes(RootNode, P^.FullPath);
     RootNode.Expand(True);
   finally
     TreeView.Items.EndUpdate;
   end;
end;

procedure TFormMain.SaveCurrentFile;
begin
    if (OpenFileProject <> '') and FileExists(OpenFileProject) then
    SynEditCode.Lines.SaveToFile(OpenFileProject);
end;

procedure TFormMain.AddSubNodes(ParentNode: TTreeNode; const Path: string);
var
   SR: TSearchRec;
   Node: TTreeNode;
   P: PNodeRec;
   DirPath: string;
begin
  DirPath := IncludeTrailingPathDelimiter(Path);

   // Oznacz folder jako załadowany, aby nie wchodzić tu ponownie
   if Assigned(ParentNode) and Assigned(ParentNode.Data) then
     PNodeRec(ParentNode.Data)^.Loaded := True;

   // Wczytywanie folderów
   if FindFirst(DirPath + '*', faDirectory, SR) = 0 then
   try
     repeat
       if (SR.Attr and faDirectory) <> 0 then
       begin
         if (SR.Name <> '.') and (SR.Name <> '..') then
         begin

           Node := TreeView.Items.AddChild(ParentNode, SR.Name);
           New(P);
           P^.IsFolder := True;
           P^.FullPath := IncludeTrailingPathDelimiter(DirPath + SR.Name);
           P^.Loaded := False; // Folder nie jest jeszcze załadowany
           Node.Data := P;

           // Ustawienie ikon: Folder Zamknięty (0)
           Node.ImageIndex := 0;
           Node.SelectedIndex := 0;

           // Dodajemy "Dummy Node" (pusty węzeł), aby móc rozwinąć folder
           TreeView.Items.AddChild(Node, 'Ładowanie...');


           // Rekurencyjnie wchodzimy w podfoldery
           AddSubNodes(Node, P^.FullPath);
         end;
       end;
     until FindNext(SR) <> 0;
   finally
     FindClose(SR);
   end;

   //pliki .avocado
   if FindFirst(DirPath + '*.avocado', faAnyFile, SR) = 0 then
   try
     repeat
       if (SR.Attr and faDirectory) = 0 then
       begin
         // Dodawanie pliku
         Node := TreeView.Items.AddChild(ParentNode, SR.Name);
         New(P);
         P^.IsFolder := False;
         P^.FullPath := DirPath + SR.Name;
         Node.Data := P;
         // Ustawienie ikon: Plik .avocado (3)
         Node.ImageIndex := 3;
         Node.SelectedIndex := 3; // Nie zmieniaj ikony pliku po zaznaczeniu
       end;
     until FindNext(SR) <> 0;
   finally
     FindClose(SR);
   end;

end;

procedure TFormMain.FilterListBox(const FilterText: string;
  const SourceList: TStringList; ListBox: TListBox);
var
  I: Integer;
begin
    ListBox.Items.BeginUpdate;
    try
      ListBox.Items.Clear;
      for I := 0 to SourceList.Count - 1 do
        if Pos(LowerCase(FilterText), LowerCase(SourceList[I])) > 0 then
          ListBox.Items.Add(SourceList[I]);
    finally
      ListBox.Items.EndUpdate;
    end;
end;

procedure TFormMain.RunPascalInstantly(const PascalCode: string);
var
    TempFile: string;
    AProcess: TProcess;
    CommandLine: string;
begin
  // Sprawdzenie zmiennej globalnej/pola
  if (InstantFPCPath = '') or (not FileExists(InstantFPCPath)) then
  begin
    MemoLogs.Lines.Add('BŁĄD: Nie znaleziono instantfpc.exe.');
    MemoLogs.Lines.Add('Sprawdź ustawienia ścieżki.');
    PageInfo.ActivePage := TabSheetLog;
    Exit;
  end;

  // Uruchomienie wątku - "Fire and Forget"
  // Wątek sam zwolni pamięć dzięki FreeOnTerminate := True
  TRunInstantThread.Create(PascalCode, InstantFPCPath);
  {
  // 1. Sprawdź, czy ścieżka do InstantFPC jest ustawiona (zakładając, że to pole klasy/zmienna globalna)
    if (InstantFPCPath = '') or (not FileExists(InstantFPCPath)) then
    begin
      MemoLogs.Lines.Add('BŁĄD: Nie znaleziono instantfpc.exe.');
      MemoLogs.Lines.Add('Sprawdź ścieżkę w setting.ini');
      PageInfo.ActivePage := TabSheetLog;
      Exit;
    end;

    TempFile := GetTempDir + 'avocado_temp_code.pas';
    AProcess := TProcess.Create(nil);
    try
    	 // 2. Zapisz kod źródłowy do pliku tymczasowego
    	 with TStringList.Create do
    	 try
    	   Text := PascalCode;
    	   SaveToFile(TempFile);
    	 finally
    	   Free;
    	 end;

      // --- 3. POPRAWIONA LOGIKA URUCHOMIENIA ---

      // Używamy 'cmd.exe' jako programu uruchamiającego
    	 AProcess.Executable := 'cmd.exe';

      // Tworzymy linię poleceń:
      // Używamy /C (uruchom i zamknij) oraz łączymy dwa polecenia:
      // 1. Uruchom InstantFPC (w cudzysłowach, na wypadek spacji w ścieżkach)
      // 2. Uruchom PAUSE (aby konsola czekała na naciśnięcie klawisza)
      CommandLine := Format('"%s" "%s" & PAUSE', [InstantFPCPath, TempFile]);

      AProcess.Parameters.Clear;
      //AProcess.Parameters.Add('/C ' + CommandLine);
      AProcess.Parameters.Add('/C "' + CommandLine + '"');

      // Nie chcemy przechwytywać wyjścia, chcemy je zobaczyć w konsoli
    	 AProcess.Options := [poWaitOnExit]; // Usuwamy poUsePipes i poStderrToOutput

         // Pokazujemy okno konsoli
    	 AProcess.ShowWindow := swoShowNormal;

    	 MemoLogs.Lines.Add('Uruchamianie InstantFPC w nowej konsoli...');
    	 try
    	   AProcess.Execute;
         // Czekamy, aż użytkownik zamknie konsolę (dzięki poWaitOnExit)
    	   MemoLogs.Lines.Add('InstantFPC zakończył działanie.');
    	 except
    	   on E: Exception do
    	 	 MemoLogs.Lines.Add('Błąd podczas uruchamiania cmd.exe: ' + E.Message);
    	 end;

       PageInfo.ActivePage := TabSheetLog; // Pokaż logi

    finally
    	 // 4. Usuń plik tymczasowy
    	 if FileExists(TempFile) then
    	   DeleteFile(TempFile);

    	 AProcess.Free;
    end;
    }
end;

procedure TFormMain.LoadFunctionsToHighlighter(const FileName: string);
var
  FilePath: string;
  Lines: TStringList;
  i, EqPos: Integer;
  LineStr, PolishFunc, EnglishFunc: string;
begin
    FilePath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + FileName;

    if not FileExists(FilePath) then
    begin
      MemoLogs.Lines.Add('Brak pliku do podświetlania: ' + FileName);
      Exit;
    end;

    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FilePath);

      // Zatrzymujemy odświeżanie komponentu na czas ładowania (przyspiesza proces)
      SynAnySyn1.Objects.BeginUpdate;
      try
        // wyczyść starą listę przed załadowaniem nowej
        SynAnySyn1.Objects.Clear;

        for i := 0 to Lines.Count - 1 do
        begin
          LineStr := Trim(Lines[i]);

          // Ignoruj puste linie oraz komentarze komentarze to ; lub //)
          if (LineStr = '') or (LineStr[1] = ';') or (Copy(LineStr, 1, 2) = '//') then
            Continue;

          // Jeśli linia zawiera znak '=', rozdzielamy ją ( dla avoraise_tlumaczenia.ini
          EqPos := Pos('=', LineStr);
          if EqPos > 0 then
          begin
            PolishFunc := Trim(Copy(LineStr, 1, EqPos - 1));
            EnglishFunc := Trim(Copy(LineStr, EqPos + 1, MaxInt));

            if PolishFunc <> '' then SynAnySyn1.Objects.Add(PolishFunc);
            if EnglishFunc <> '' then SynAnySyn1.Objects.Add(EnglishFunc);
          end
          else
          begin
            // Zwykły plik (np. functions.txt), po prostu dodajemy linię
            SynAnySyn1.Objects.Add(LineStr);
          end;
        end;
      finally
        // Wznawiamy odświeżanie - słowa zostaną pokolorowane
        SynAnySyn1.Objects.EndUpdate;
      end;

    finally
      Lines.Free;
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
      //loads the function list from the functions.txt file / ładuje liste funkcję z pliku functions.txt
      ListFunctionsFromSynEdit;
      //updating the list of variables. / aktualizacja listy zmiennych.
      ListVariablesFromSynEdit;
      //Updating comment list. / Aktualizacja listy komentarzy.
      ListCommentsFromSynEdit;

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
    end
    //
    else
      //Sleep(10);
  end;
  FProcess.Free;
end;

end.


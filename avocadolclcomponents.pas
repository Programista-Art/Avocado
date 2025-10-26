unit AvocadoLCLComponents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Buttons,Graphics,Types;

//Constructor formy - pola formy
type
  TAvocadoFormProps = record
    // --- Podstawowe właściwości ---
    Name : String;
    Left : Integer;
    Top:Integer;
    Width: Integer;
    Height: Integer;
    Enabled: Boolean;
    Visible: Boolean;
    Tag: Integer;
    Color: TColor;
    Cursor: TCursor;
    ShowHint: Boolean;
    Hint: String;

    // --- Właściwości specyficzne dla TForm --- // POPRAWKA: Komentarz
    Caption : String;
    Scaled: Boolean;
    AutoSize: Boolean;

    // POPRAWKA: Poniżej naprawiono wiele błędów typów (było 'String')
    DefaultMonitor: TDefaultMonitor;
    DoubleBuffered: Boolean;
    Align: TAlign;
    AllowDropFiles: Boolean;
    AlphaBlend: Boolean;
    AlphaBlendValue: Byte;
    BidiMode: TBidiMode;
    BorderStyle: TFormBorderStyle;
    BorderWidth: Integer;
    DesignTimePPI: Integer;
    DockSite: Boolean;
    DragKind: TDragKind;
    DragMode: TDragMode;
    FormStyle: TFormStyle;

    ParentDoubleBuffered: Boolean;

    // Trzeba go ładować oddzielnie, np. FForm.Icon.LoadFromFile(...)

    PixelsPerInch: Integer; // Zmieniono nazwę dla jasności (było PixelPerInch)
    PopupMode: TPopupMode;
    Position: TPosition;

    ScreenSnap: Boolean;
    ShowInTaskBar: TShowInTaskbar;
    SnapBuffer: Integer;
    UseDockManager: Boolean;
    WindowState: TWindowState;
end;

type
  //Edit  - pola edit
  TAvocadoEditProps = record
    // --- Podstawowe właściwości ---
        Name : String;
        Left : Integer;
        Top:Integer;
        Width: Integer;
        Height: Integer;
        Enabled: Boolean;
        Visible: Boolean;
        Tag: Integer;
        Color: TColor;
        Cursor: TCursor;
        ShowHint: Boolean;

        // --- Właściwości specyficzne dla TEdit ---
        Text : String;
        TextHint: String;
        ReadOnly: Boolean;
        // Czy zaznaczać tekst po wejściu
        AutoSelect: Boolean;
        // Czy pozwalać tylko na cyfry
        NumbersOnly: Boolean;
        HideSelection: Boolean;
        PasswordChar: Char;
        // Wyrównanie tekstu wewnątrz pola
        Alignment: TAlignment;
        // Jak kontrolka ma się zachowywać na formularzu
        Align: TAlign;
        // Tryb wyświetlania (normalny, hasło)
        EchoMode: TEchoMode;
        // Właściwości "Parent" (czy dziedziczyć z formularza)
        ParentColor: Boolean;
        ParentShowHint: Boolean;
        ParentDoubleBuffered: Boolean;
  end;
//Button - pola przycisku
type
  TAvocadoButtonProps = record
    // --- Podstawowe właściwości ---
    Name : String;
    Left : Integer;
    Top:Integer;
    Width: Integer;
    Height: Integer;
    Enabled: Boolean;
    Visible: Boolean;
    Tag: Integer;
    Color: TColor;
    Cursor: TCursor;
    ShowHint: Boolean; // Już tu jest, SHowHint na dole był duplikatem

    // --- Właściwości specyficzne dla Button ---
    Caption : String;
    Cancel: Boolean;
    AutoSize: Boolean;
    Default: Boolean;
    DoubleBuffered: Boolean;
    Align: TAlign;
    Hint: String;

    TabOrder: Integer;
    ModalResult: TModalResult;
    // --- Właściwości "Parent" ---
    ParentColor: Boolean;
    ParentShowHint: Boolean;
    ParentDoubleBuffered: Boolean;
end;

type
  { TAvocadoFormCreator }
  TAvocadoFormCreator = class
  private
    FForm: TForm;
  public
    constructor Create(const Props: TAvocadoFormProps);
    destructor Destroy; override;
    function GetForm: TForm;

    // Zmieniono procedury na funkcje, aby zwracały utworzone kontrolki
    //Mozna wywalic stara obsluga
    function AddButton(const ACaption: string; const Left, Top, Width, Height: Integer): TButton;
    //Mozna wywalic
    function AddEdit(const ADefaultText: string; const Left, Top, Width, Height: Integer; Enabled:Boolean; tHint: String ): TEdit;
    //ListBox
    function AddListBox(const Left, Top, Width, Height: Integer): TListBox;
    //Edits
    function AddEditNew(const Props: TAvocadoEditProps): TEdit; // Używa nowej nazwy rekordu
    //Buttons
    function AddButtonNew(const Props: TAvocadoButtonProps): TButton;
    //function create_form(const Props: TAvocadoFormProps ): TForm;
    procedure ShowForm;
  end;

implementation
{ TAvocadoFormCreator }

constructor TAvocadoFormCreator.Create(const Props: TAvocadoFormProps);
begin
     FForm := TForm.Create(nil);
     // --- Podstawowe właściwości ---
     FForm.Name    := Props.Name;
     FForm.Caption := Props.Caption;
     FForm.Left    := Props.Left;
     FForm.Top     := Props.Top;
     FForm.Width   := Props.Width;
     FForm.Height  := Props.Height;
     FForm.Enabled := Props.Enabled;
    // FForm.TextHint := Props.TextHint; // Zgodnie z poprzednią poprawką
     FForm.Visible    := Props.Visible;
     FForm.Tag        := Props.Tag;
     FForm.Color      := Props.Color;
     FForm.Cursor     := Props.Cursor;
     FForm.ShowHint   := Props.ShowHint;
     FForm.Hint       := Props.Hint;
     FForm.Scaled     := Props.Scaled;
     FForm.AutoSize    := Props.AutoSize ;
     FForm.DefaultMonitor :=  Props.DefaultMonitor;
     FForm.DoubleBuffered  := Props.DoubleBuffered;


     FForm.AllowDropFiles := Props.AllowDropFiles;
     FForm.AlphaBlend := Props.AlphaBlend;
     FForm.AlphaBlendValue := Props.AlphaBlendValue;
     FForm.BidiMode := Props.BidiMode;
     FForm.BorderStyle := Props.BorderStyle;
     FForm.BorderWidth := Props.BorderWidth;
     FForm.DesignTimePPI := Props.DesignTimePPI;
     FForm.DockSite := Props.DockSite;
     FForm.DragKind := Props.DragKind;
     FForm.DragMode := Props.DragMode;
     FForm.FormStyle := Props.FormStyle;
     FForm.Align := Props.Align;
     FForm.PixelsPerInch := Props.PixelsPerInch;
     FForm.PopupMode := Props.PopupMode;
     FForm.Position := Props.Position;
     FForm.ScreenSnap := Props.ScreenSnap;
     FForm.ShowInTaskBar := Props.ShowInTaskBar;
     FForm.SnapBuffer := Props.SnapBuffer;
     FForm.UseDockManager := Props.UseDockManager;
     FForm.WindowState :=  Props.WindowState;
     FForm.ParentDoubleBuffered := Props.ParentDoubleBuffered;
  // Komponenty będą automatycznie zwolnione, gdy FForm zostanie zwolniony,
  // ponieważ przekazujemy 'FForm' jako właściciela (Owner) w T...Create(FForm)
end;

destructor TAvocadoFormCreator.Destroy;
begin
  FForm.Free; // To automatycznie zwolni wszystkie kontrolki (Button, Edit itp.)
  inherited Destroy;
end;

function TAvocadoFormCreator.GetForm: TForm;
begin
  Result := FForm;
end;

function TAvocadoFormCreator.AddButton(const ACaption: string; const Left, Top, Width, Height: Integer): TButton;
var
  Button: TButton;
begin
  Button := TButton.Create(FForm); // Ustawia FForm jako właściciela
  Button.Parent := FForm;
  Button.Caption := ACaption;
  Button.Left := Left;
  Button.Top := Top;
  Button.Width := Width;
  Button.Height := Height;
  Result := Button; // Zwraca utworzony przycisk
end;

function TAvocadoFormCreator.AddButtonNew(const Props: TAvocadoButtonProps): TButton;
var
  Button: TButton;
begin
    Button := TButton.Create(FForm);
    Button.Parent := FForm;

    // --- Podstawowe właściwości ---
    Button.Name    := Props.Name;
    Button.Caption     := Props.Caption;
    Button.Left    := Props.Left;
    Button.Top     := Props.Top;
    Button.Width   := Props.Width;
    Button.Height  := Props.Height;
    Button.Enabled := Props.Enabled;


    // --- DODANE NOWE WŁAŚCIWOŚCI (z poprawnego rekordu) ---
    Button.Visible    := Props.Visible;
    Button.Tag        := Props.Tag;
    Button.Color      := Props.Color;
    Button.Cursor     := Props.Cursor;
    Button.ShowHint   := Props.ShowHint;
    Button.Cancel := Props.Cancel;
    // --- Właściwości specyficzne dla Button ---
    Button.AutoSize   := Props.AutoSize;
    Button.Default    := Props.Default;
    Button.DoubleBuffered :=  Props.DoubleBuffered;
    Button.Hint       := Props.Hint;
    Button.Align      := Props.Align;
    Button.TabOrder := Props.TabOrder;
    Button.ModalResult  := Props.ModalResult;

    // --- Właściwości "Parent" ---
    Button.ParentShowHint := Props.ParentShowHint;
    Button.ParentDoubleBuffered := Props.ParentDoubleBuffered;

    Result := Button; // Zwraca utworzony przycisk
end;



function TAvocadoFormCreator.AddEdit(const ADefaultText: string; const Left, Top, Width, Height: Integer; Enabled:Boolean; tHint: String ): TEdit;
var
  Edit: TEdit;
begin
  Edit := TEdit.Create(FForm);
  Edit.Parent := FForm;
  Edit.Text := ADefaultText;
  Edit.Left := Left;
  Edit.Top := Top;
  Edit.Width := Width;
  Edit.Height := Height;
  Edit.Enabled := Enabled;
  Edit.TextHint := tHint; // Poprawna właściwość dla tekstu zastępczego
  Result := Edit; // Zwraca utworzone pole edycji
end;

function TAvocadoFormCreator.AddListBox(const Left, Top, Width, Height: Integer): TListBox;
var
  ListBox: TListBox;
begin
  ListBox := TListBox.Create(FForm);
  ListBox.Parent := FForm;
  ListBox.Left := Left;
  ListBox.Top := Top;
  ListBox.Width := Width;
  ListBox.Height := Height;
  Result := ListBox; // Zwraca utworzony ListBox
end;

procedure TAvocadoFormCreator.ShowForm;
begin
  FForm.ShowModal;
end;

function TAvocadoFormCreator.AddEditNew(const Props: TAvocadoEditProps): TEdit;
var
  Edit: TEdit;
begin
    Edit := TEdit.Create(FForm);
    Edit.Parent := FForm;

    // --- Podstawowe właściwości ---
    Edit.Name    := Props.Name;
    Edit.Text    := Props.Text;
    Edit.Left    := Props.Left;
    Edit.Top     := Props.Top;
    Edit.Width   := Props.Width;
    Edit.Height  := Props.Height;
    Edit.Enabled := Props.Enabled;
    Edit.TextHint := Props.TextHint; // Zgodnie z poprzednią poprawką

    // --- DODANE NOWE WŁAŚCIWOŚCI (z poprawnego rekordu) ---
    Edit.Visible    := Props.Visible;
    Edit.Tag        := Props.Tag;
    Edit.Color      := Props.Color;
    Edit.Cursor     := Props.Cursor;
    Edit.ShowHint   := Props.ShowHint;

    // --- Właściwości specyficzne dla TEdit ---
    Edit.ReadOnly     := Props.ReadOnly;
    Edit.AutoSelect   := Props.AutoSelect;
    Edit.NumbersOnly  := Props.NumbersOnly;
    Edit.HideSelection := Props.HideSelection;
    Edit.PasswordChar := Props.PasswordChar;
    Edit.Alignment    := Props.Alignment;
    Edit.Align        := Props.Align;
    Edit.EchoMode     := Props.EchoMode;

    // --- Właściwości "Parent" ---
    Edit.ParentColor    := Props.ParentColor;
    Edit.ParentShowHint := Props.ParentShowHint;
    Edit.ParentDoubleBuffered := Props.ParentDoubleBuffered;


    Result := Edit; // Zwraca utworzone pole edycji
end;

end.

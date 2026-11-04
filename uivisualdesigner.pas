unit uivisualdesigner;

{$mode objfpc}{$H+}

{ Visual UI designer for Avoraiser — based on Avocado-UI-Editor:
  TJvDesignPanel (JVCL) for drag/resize, TTIPropertyGrid for properties,
  TAvocadoWindow / TAvocadoButton component model, Avocado code generation. }

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Menus, StdCtrls, ExtCtrls, Buttons, TypInfo, Grids, Clipbrd,
  JvDesignSurface, JvDesignUtils, JvDesignImp, RTTIGrids, LCLType;

type
  { Okno aplikacji Avoraiser (jak TAvocadoWindow z Avocado-UI-Editor) }
  TAvocadoWindow = class(TPanel)
  private
    FOpacity: Byte;
    FCenterWindow: Boolean;
    FFramelessWindow: Boolean;
    FDarkMode: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Opacity: Byte read FOpacity write FOpacity default 255;
    property CenterWindow: Boolean read FCenterWindow write FCenterWindow default True;
    property FramelessWindow: Boolean read FFramelessWindow write FFramelessWindow default False;
    property DarkMode: Boolean read FDarkMode write FDarkMode default False;
    property Caption;
    property Color;
    property Width;
    property Height;
    property Left;
    property Top;
    property Name;
  end;

  { Przycisk Avoraiser z paletą kolorów }
  TAvocadoButton = class(TButton)
  private
    FColorHover: TColor;
    FColorPressed: TColor;
    FColorText: TColor;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Color;
    property ColorHover: TColor read FColorHover write FColorHover default $404040;
    property ColorPressed: TColor read FColorPressed write FColorPressed default $00AA00;
    property ColorText: TColor read FColorText write FColorText default $FFFFFF;
  end;

  TUIVisualDesigner = class(TForm)
  private
    FDesign: TJvDesignPanel;
    FProps: TTIPropertyGrid;
    FToolBar: TToolBar;
    FCodeMemo: TMemo;
    FStatus: TPanel;
    FSplit: TPanel;
    SelectButton: TToolButton;
    FDesignClass: string;
    FSticky: Boolean;

    procedure BuildUi;
    procedure SelectToolClick(Sender: TObject);
    procedure DesignGetAddClass(Sender: TObject; var ioClass: string);
    procedure DesignSelectionChange(Sender: TObject);
    procedure DesignPaint(Sender: TObject);
    procedure BtnGenerateClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnNewClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);

    function FindWindow: TAvocadoWindow;
    function EmitButton(B: TAvocadoButton; ACtrl: TControl): string;
  public
    constructor Create(AOwner: TComponent); override;
    function GenerateAvocadoCode: string;
    procedure FormCloseFree(Sender: TObject; var CloseAction: TCloseAction);
  end;

function ShowUIVisualDesigner: TUIVisualDesigner;

implementation

function ShowUIVisualDesigner: TUIVisualDesigner;
begin
  Result := TUIVisualDesigner.Create(nil);
  Result.Show;
  Result.BringToFront;
end;

{ TAvocadoWindow }

constructor TAvocadoWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'Avocado App';
  Color := $202020;
  Width := 480;
  Height := 320;
  BevelOuter := bvNone;
  Name := 'MainWindow';
  FOpacity := 255;
  FCenterWindow := True;
  FFramelessWindow := False;
  FDarkMode := False;
end;

{ TAvocadoButton }

constructor TAvocadoButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 40;
  Caption := 'Button';
  Color := $2D2D2D;
  FColorHover := $404040;
  FColorPressed := $00AA00;
  FColorText := $FFFFFF;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
end;

{ TUIVisualDesigner }

constructor TUIVisualDesigner.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Caption := 'Edytor UI Avoraiser';
  Position := poScreenCenter;
  Width := 1280;
  Height := 820;
  Constraints.MinWidth := 1000;
  Constraints.MinHeight := 640;
  OnClose := @FormCloseFree;
  BuildUi;
end;

procedure TUIVisualDesigner.FormCloseFree(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TUIVisualDesigner.BuildUi;

  procedure TB(const ACaption: string; AWidth: Integer; AClick: TNotifyEvent;
    ATag: Integer = -1);
  var
    B: TToolButton;
  begin
    B := TToolButton.Create(Self);
    B.Parent := FToolBar;
    B.Caption := ACaption;
    B.Width := AWidth;
    B.Style := tbsButton;
    B.Tag := ATag;
    B.OnClick := AClick;
  end;

var
  PanelRight: TPanel;
  Lbl: TLabel;
begin
  FToolBar := TToolBar.Create(Self);
  FToolBar.Parent := Self;
  FToolBar.Align := alTop;
  FToolBar.Height := 36;
  FToolBar.ButtonHeight := 32;
  FToolBar.ShowCaptions := True;

  SelectButton := TToolButton.Create(Self);
  SelectButton.Parent := FToolBar;
  SelectButton.Caption := 'Zaznacz';
  SelectButton.Style := tbsCheck;
  SelectButton.Down := True;
  SelectButton.Tag := 0;
  SelectButton.OnClick := @SelectToolClick;

  // Tag = indeks w cClasses (SelectToolClick)
  TB('Przycisk', 70, @SelectToolClick, 1);
  TB('Etykieta', 70, @SelectToolClick, 2);
  TB('Panel', 60, @SelectToolClick, 3);
  TB('Memo', 60, @SelectToolClick, 4);
  TB('Pole', 60, @SelectToolClick, 5);
  TB('Okno', 60, @SelectToolClick, 6);

  TB('Generuj', 70, @BtnGenerateClick);
  TB('Kopiuj', 60, @BtnCopyClick);
  TB('Zapisz', 60, @BtnSaveClick);
  TB('Nowy', 55, @BtnNewClick);

  FStatus := TPanel.Create(Self);
  FStatus.Parent := Self;
  FStatus.Align := alBottom;
  FStatus.Height := 22;
  FStatus.BevelOuter := bvNone;
  FStatus.Font.Size := 8;
  FStatus.Caption := '  Wybierz typ z paska i kliknij na powierzchni.  Przeciąganie = ruch/rozmiar (JVCL).';

  FCodeMemo := TMemo.Create(Self);
  FCodeMemo.Parent := Self;
  FCodeMemo.Align := alBottom;
  FCodeMemo.Height := 200;
  FCodeMemo.Font.Name := 'Consolas';
  FCodeMemo.Font.Size := 9;
  FCodeMemo.Color := $001E1E1E;
  FCodeMemo.Font.Color := $00D0D0D0;
  FCodeMemo.ScrollBars := ssAutoBoth;

  PanelRight := TPanel.Create(Self);
  PanelRight.Parent := Self;
  PanelRight.Align := alRight;
  PanelRight.Width := 300;
  PanelRight.BevelOuter := bvNone;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PanelRight;
  Lbl.Align := alTop;
  Lbl.Height := 22;
  Lbl.Caption := '  WŁAŚCIWOŚCI (RTTI)';
  Lbl.Font.Size := 8;
  Lbl.Font.Style := [fsBold];

  FProps := TTIPropertyGrid.Create(Self);
  FProps.Parent := PanelRight;
  FProps.Align := alClient;
  FProps.CheckboxForBoolean := False;
  FProps.ValueFont.Color := clMaroon;

  FDesign := TJvDesignPanel.Create(Self);
  FDesign.Parent := Self;
  FDesign.Align := alClient;
  FDesign.Color := clWhite;
  FDesign.DrawRules := True;
  FDesign.OnGetAddClass := @DesignGetAddClass;
  FDesign.OnSelectionChange := @DesignSelectionChange;
  FDesign.OnPaint := @DesignPaint;
end;

procedure TUIVisualDesigner.SelectToolClick(Sender: TObject);
const
  cClasses: array[0..6] of string = (
    '', 'TAvocadoButton', 'TLabel', 'TPanel', 'TMemo', 'TEdit', 'TAvocadoWindow'
  );
var
  Idx: Integer;
begin
  FSticky := False;
  Idx := TControl(Sender).Tag;
  if (Idx >= 0) and (Idx <= High(cClasses)) then
    FDesignClass := cClasses[Idx]
  else
    FDesignClass := '';
end;

procedure TUIVisualDesigner.DesignGetAddClass(Sender: TObject; var ioClass: string);
begin
  ioClass := FDesignClass;
  if not FSticky then
  begin
    FDesignClass := '';
    SelectButton.Down := True;
  end;
end;

function TUIVisualDesigner.FindWindow: TAvocadoWindow;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FDesign.ComponentCount - 1 do
    if FDesign.Components[I] is TAvocadoWindow then
      Exit(TAvocadoWindow(FDesign.Components[I]));
end;

procedure TUIVisualDesigner.DesignSelectionChange(Sender: TObject);
var
  Sel: TJvDesignObjectArray;
  Found: TAvocadoWindow;
begin
  Sel := FDesign.Surface.Selected;
  if Length(Sel) > 0 then
  begin
    if Sel[0] is TPersistent then
      FProps.TIObject := TPersistent(Sel[0]);
    Exit;
  end;
  Found := FindWindow;
  if Found <> nil then
    FProps.TIObject := Found
  else
    FProps.TIObject := FDesign;
end;

procedure TUIVisualDesigner.DesignPaint(Sender: TObject);
begin
  DesignPaintGrid(FDesign.Canvas, FDesign.ClientRect, FDesign.Color);
end;

function TUIVisualDesigner.EmitButton(B: TAvocadoButton; ACtrl: TControl): string;
begin
  Result := Format('%s = utworz_przycisk(my_window, ''%s'', %d, %d, %d, %d)',
    [B.Name, StringReplace(B.Caption, '''', '''''', [rfReplaceAll]),
     ACtrl.Left, ACtrl.Top, ACtrl.Width, ACtrl.Height]);
  Result := Result + LineEnding + Format(
    '    ustaw_kolory_przycisku(%s, $%s, $%s, $%s, $%s, $%s)',
    [B.Name,
     IntToHex(B.Color and $FFFFFF, 6),
     IntToHex(B.ColorHover and $FFFFFF, 6),
     IntToHex(B.ColorPressed and $FFFFFF, 6),
     IntToHex(B.ColorText and $FFFFFF, 6),
     IntToHex(B.ColorText and $FFFFFF, 6)]);
end;

function TUIVisualDesigner.GenerateAvocadoCode: string;
var
  SB: TStringBuilder;
  I: Integer;
  Comp: TComponent;
  Ctrl: TControl;
  W: TAvocadoWindow;
  B: TAvocadoButton;
  Units: TStringList;
  WinW, WinH, WinX, WinY: Integer;
  WinTitle: string;
  WinColor: TColor;
  WinOpacity: Byte;
  WinCenter, WinFrameless, WinDark: Boolean;
  Names: string;
begin
  W := FindWindow;
  if W <> nil then
  begin
    WinW := W.Width;
    WinH := W.Height;
    WinX := W.Left;
    WinY := W.Top;
    WinTitle := W.Caption;
    WinColor := W.Color;
    WinOpacity := W.Opacity;
    WinCenter := W.CenterWindow;
    WinFrameless := W.FramelessWindow;
    WinDark := W.DarkMode;
  end
  else
  begin
    WinW := 480; WinH := 320; WinX := 100; WinY := 100;
    WinTitle := 'Avocado App';
    WinColor := $202020;
    WinOpacity := 255;
    WinCenter := True;
    WinFrameless := False;
    WinDark := False;
  end;

  Units := TStringList.Create;
  SB := TStringBuilder.Create;
  try
    Units.Add('avoraiser.window');
    Units.Add('avoraiser.layout');
    for I := 0 to FDesign.ComponentCount - 1 do
    begin
      Comp := FDesign.Components[I];
      if Comp is TAvocadoButton then
        if Units.IndexOf('avoraiser.button') < 0 then Units.Add('avoraiser.button')
      else if Comp is TLabel then
        if Units.IndexOf('avoraiser.labels') < 0 then Units.Add('avoraiser.labels')
      else if Comp is TEdit then
        if Units.IndexOf('avoraiser.edit') < 0 then Units.Add('avoraiser.edit')
      else if Comp is TMemo then
        if Units.IndexOf('avoraiser.memo') < 0 then Units.Add('avoraiser.memo')
      else if Comp is TPanel then
        if Units.IndexOf('avoraiser.utils') < 0 then Units.Add('avoraiser.utils');
    end;
    if WinDark or (WinOpacity < 255) then
      if Units.IndexOf('avoraiser.utils') < 0 then Units.Add('avoraiser.utils');

    SB.AppendLine('// Wygenerowano przez Edytor UI Avoraiser (JVCL)');
    SB.AppendLine('program_ui moje_okno');
    SB.AppendLine;
    for I := 0 to Units.Count - 1 do
      SB.AppendLine('import ' + Units[I]);
    SB.AppendLine;
    SB.AppendLine('hwnd my_window');
    for I := 0 to FDesign.ComponentCount - 1 do
    begin
      Comp := FDesign.Components[I];
      if (Comp is TControl) and not (Comp is TAvocadoWindow) then
        SB.AppendLine('hwnd ' + Comp.Name);
    end;
    SB.AppendLine;
    SB.AppendLine('main');
    SB.AppendLine('  buduj_okno');
    SB.AppendLine('  uruchom_aplikacje');
    SB.AppendLine('end.');
    SB.AppendLine;
    SB.AppendLine('procedure buduj_okno');
    SB.AppendLine('start');
    SB.AppendLine('  ui_parameters ui');
    SB.AppendLine('  ui = Default(TAvocadoWindowParams)');
    SB.AppendLine('  ui.title = ''' + StringReplace(WinTitle, '''', '''''', [rfReplaceAll]) + '''');
    SB.AppendLine(Format('  ui.width = %d', [WinW]));
    SB.AppendLine(Format('  ui.height = %d', [WinH]));
    SB.AppendLine('  ui.visible = true');
    if WinFrameless then
      SB.AppendLine('  ui.frameless = true');
    SB.AppendLine(Format('  ui.backgroundcolor = $%s', [IntToHex(WinColor and $FFFFFF, 6)]));
    SB.AppendLine;
    SB.AppendLine('  my_window = utworz_okno(ui)');
    SB.AppendLine('  if my_window <> 0 then');
    SB.AppendLine('  start');
    SB.AppendLine('    ustaw_przycisk_maksymalizacji_okna(my_window, true)');
    if WinDark then
    begin
      SB.AppendLine('    ustaw_ciemny_motyw(my_window, true)');
      SB.AppendLine('    ustaw_cien_okna(my_window, true)');
    end;
    SB.AppendLine(Format('    ustaw_kolor_naglowka(my_window, $%s)',
      [IntToHex((WinColor + $101010) and $FFFFFF, 6)]));
    if WinOpacity < 255 then
      SB.AppendLine(Format('    ustaw_przezroczystosc(my_window, %d)', [WinOpacity]));
    if WinCenter then
      SB.AppendLine('    wysrodkuj_okno(my_window)');
    SB.AppendLine;

    for I := 0 to FDesign.ComponentCount - 1 do
    begin
      Comp := FDesign.Components[I];
      if not (Comp is TControl) or (Comp is TAvocadoWindow) then
        Continue;
      Ctrl := TControl(Comp);
      Name := Comp.Name;

      if Comp is TAvocadoButton then
      begin
        B := TAvocadoButton(Comp);
        SB.AppendLine('    ' + EmitButton(B, Ctrl));
      end
      else if Comp is TLabel then
        SB.AppendLine(Format('    %s = utworz_etykiete(my_window, ''%s'', %d, %d, %d, %d)',
          [Name, StringReplace(TLabel(Comp).Caption, '''', '''''', [rfReplaceAll]),
           Ctrl.Left, Ctrl.Top, Ctrl.Width, Ctrl.Height]))
      else if Comp is TEdit then
        SB.AppendLine(Format('    %s = utworz_pole_edycji(my_window, ''%s'', %d, %d, %d, %d)',
          [Name, StringReplace(TEdit(Comp).Text, '''', '''''', [rfReplaceAll]),
           Ctrl.Left, Ctrl.Top, Ctrl.Width, Ctrl.Height]))
      else if Comp is TMemo then
        SB.AppendLine(Format('    %s = utworz_notatnik(my_window, %d, %d, %d, %d)',
          [Name, Ctrl.Left, Ctrl.Top, Ctrl.Width, Ctrl.Height]))
      else if Comp is TPanel then
        SB.AppendLine(Format('    %s = utworz_panel(my_window, %d, %d, %d, %d, $%s)',
          [Name, Ctrl.Left, Ctrl.Top, Ctrl.Width, Ctrl.Height,
           IntToHex(TPanel(Comp).Color and $FFFFFF, 6)]));
    end;
    SB.AppendLine('  end');
    SB.AppendLine('end');
    Result := SB.ToString;
  finally
    SB.Free;
    Units.Free;
  end;
end;

procedure TUIVisualDesigner.BtnGenerateClick(Sender: TObject);
begin
  FCodeMemo.Lines.Text := GenerateAvocadoCode;
  FStatus.Caption := '  Kod Avocado wygenerowany.';
end;

procedure TUIVisualDesigner.BtnCopyClick(Sender: TObject);
begin
  if FCodeMemo.Lines.Text = '' then
    FCodeMemo.Lines.Text := GenerateAvocadoCode;
  Clipboard.AsText := FCodeMemo.Lines.Text;
  FStatus.Caption := '  Skopiowano do schowka.';
end;

procedure TUIVisualDesigner.BtnSaveClick(Sender: TObject);
var
  D: TSaveDialog;
  Base: string;
begin
  if FCodeMemo.Lines.Text = '' then
    FCodeMemo.Lines.Text := GenerateAvocadoCode;
  D := TSaveDialog.Create(nil);
  try
    D.Filter := 'Avocado|*.avocado|Projekt UI|*.gui';
    D.DefaultExt := 'avocado';
    if D.Execute then
    begin
      Base := D.FileName;
      if LowerCase(ExtractFileExt(Base)) = '.gui' then
      begin
        FDesign.SaveToFile(Base);
        Base := ChangeFileExt(Base, '.avocado');
      end;
      FCodeMemo.Lines.SaveToFile(Base);
      FStatus.Caption := '  Zapisano: ' + Base;
    end;
  finally
    D.Free;
  end;
end;

procedure TUIVisualDesigner.BtnNewClick(Sender: TObject);
begin
  FDesign.Clear;
  FCodeMemo.Clear;
  FProps.TIObject := nil;
  FStatus.Caption := '  Nowy projekt.';
end;

initialization
  RegisterClass(TAvocadoWindow);
  RegisterClass(TAvocadoButton);
  RegisterClass(TLabel);
  RegisterClass(TPanel);
  RegisterClass(TEdit);
  RegisterClass(TMemo);
end.

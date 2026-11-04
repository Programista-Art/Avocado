unit AvocadoLCLComponents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Buttons;

type
  { TAvocadoFormCreator }
  TAvocadoFormCreator = class
  private
    FForm: TForm;
  public
    constructor Create(const ACaption: string);
    destructor Destroy; override;
    function GetForm: TForm;
    procedure AddButton(const ACaption: string; const Left, Top, Width, Height: Integer);
    procedure AddEdit(const ADefaultText: string; const Left, Top, Width, Height: Integer);
    procedure AddListBox(const Left, Top, Width, Height: Integer);
    procedure ShowForm;
  end;

implementation

{ TAvocadoFormCreator }

constructor TAvocadoFormCreator.Create(const ACaption: string);
begin
  FForm := TForm.Create(nil);
  FForm.Caption := ACaption;
  FForm.Width := 400;
  FForm.Height := 300;
end;

destructor TAvocadoFormCreator.Destroy;
begin
  FForm.Free;
  inherited Destroy;
end;

function TAvocadoFormCreator.GetForm: TForm;
begin
  Result := FForm;
end;

procedure TAvocadoFormCreator.AddButton(const ACaption: string; const Left, Top, Width, Height: Integer);
var
  Button: TButton;
begin
  Button := TButton.Create(FForm);
  Button.Parent := FForm;
  Button.Caption := ACaption;
  Button.Left := Left;
  Button.Top := Top;
  Button.Width := Width;
  Button.Height := Height;
end;

procedure TAvocadoFormCreator.AddEdit(const ADefaultText: string; const Left, Top, Width, Height: Integer);
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
end;

procedure TAvocadoFormCreator.AddListBox(const Left, Top, Width, Height: Integer);
var
  ListBox: TListBox;
begin
  ListBox := TListBox.Create(FForm);
  ListBox.Parent := FForm;
  ListBox.Left := Left;
  ListBox.Top := Top;
  ListBox.Width := Width;
  ListBox.Height := Height;
end;

procedure TAvocadoFormCreator.ShowForm;
begin
  FForm.ShowModal;
end;

end.


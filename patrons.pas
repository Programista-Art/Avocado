unit patrons;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TPatronsAvocado }

  TPatronsAvocado = class(TForm)
    Button1: TButton;
    MemoPatrons: TMemo;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadFilePatrons;
  public

  end;

var
  PatronsAvocado: TPatronsAvocado;
implementation

{$R *.lfm}

{ TPatronsAvocado }

procedure TPatronsAvocado.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TPatronsAvocado.FormCreate(Sender: TObject);
begin
  LoadFilePatrons;
end;

procedure TPatronsAvocado.LoadFilePatrons;
begin
  MemoPatrons.Lines.LoadFromFile(ExtractFilePath(Application.ExeName) + 'patrons.txt');
end;

end.


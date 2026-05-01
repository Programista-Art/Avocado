unit generated_code;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  SynEdit, SynHighlighterAny, SynHighlighterPas;

type

  { TgeneratedCode }

  TgeneratedCode = class(TForm)
    Button1: TButton;
    Panel1: TPanel;
    SynEditGeneratedCode: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  generatedCode: TgeneratedCode;

implementation

{$R *.lfm}

{ TgeneratedCode }

procedure TgeneratedCode.Button1Click(Sender: TObject);
begin
  SynEditGeneratedCode.SelectAll;
  SynEditGeneratedCode.CopyToClipboard;
end;

end.


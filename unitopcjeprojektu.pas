unit unitopcjeprojektu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, LCLTranslator, DefaultTranslator, Buttons,
  StdCtrls,ShellApi;

type

  { TFormOpcjeProjektu }

  TFormOpcjeProjektu = class(TForm)
    Button1: TButton;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    sbOk: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure sbOkClick(Sender: TObject);

  private
    procedure OpenLink(link: string);

  public

  end;

var
  FormOpcjeProjektu: TFormOpcjeProjektu;

resourcestring
  TranslateLinkCannotBeOpened = 'The link cannot be opened: ';
  TranslateErrorCode = 'Error code: ';

implementation

{$R *.lfm}

{ TFormOpcjeProjektu }




procedure TFormOpcjeProjektu.sbOkClick(Sender: TObject);
begin
  Close;
end;

procedure TFormOpcjeProjektu.OpenLink(link: string);
var
  ResultCode: Integer;
begin
  ResultCode := ShellExecute(0, 'open', PChar(link), nil, nil, 1);
  if ResultCode <= 32 then
  begin
    ShowMessage(TranslateLinkCannotBeOpened + link + TranslateErrorCode + IntToStr(ResultCode));
  end;
end;

procedure TFormOpcjeProjektu.Button1Click(Sender: TObject);
var
TempDir:  String;
begin
   TempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'Avocado';
   OpenLink(TempDir)
end;

end.


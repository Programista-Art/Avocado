unit aihelper;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DefaultTranslator,
  LCLTranslator, StdCtrls, Buttons, ExtCtrls, Menus;

type

  { Taiassistant }

  Taiassistant = class(TForm)
    EditAskPromt: TEdit;
    MemoAnswerChatGPT: TMemo;
    MenuItemCopyAllPascalzCode: TMenuItem;
    MenuItemcopyPascalCode: TMenuItem;
    MenuItemOutputCodeClear: TMenuItem;
    Panel1: TPanel;
    PopupMenuOutPutPascalCode: TPopupMenu;
    sbzapytaj: TSpeedButton;
    procedure sbzapytajClick(Sender: TObject);
  private
    // Metoda callback do obsługi odpowiedzi ChatGPT
    procedure OnChatGPTResponse(const ResponseText: string);
    procedure AskChatGPT(promt:String; memopromt: TMemo);

  public

  end;

var
  aiassistant: Taiassistant;
  PromptChatGPT: String;

implementation
uses
  Unit1,chatgptavocado,uchatgpt;

{$R *.lfm}

{ Taiassistant }

procedure Taiassistant.sbzapytajClick(Sender: TObject);
begin
  PromptChatGPT := EditAskPromt.Text;
   if Trim(PromptChatGPT) = '' then
  begin
    ShowMessage(TranslateEnterQuestion);
    Exit;
  end;
  //Disable button while waiting for a response
  // Wyłącz przycisk podczas oczekiwania na odpowiedź
  sbzapytaj.Enabled := False;
  try
    ZapytajChatGPT(Unit1.Token, Unit1.ModelGPT, Unit1.PromptChatGPT, @OnChatGPTResponse);
  except
    on E: Exception do
    begin
      ShowMessage(TranslateMistake + E.Message);
      sbzapytaj.Enabled := True;
    end;
  end;
end;

procedure Taiassistant.OnChatGPTResponse(const ResponseText: string);
begin
   try
      MemoAnswerChatGPT.Clear;

    if Trim(ResponseText) <> '' then
    begin
      MemoAnswerChatGPT.Lines.Add(TranslateAnswer);
      MemoAnswerChatGPT.Lines.Add('==================');
      MemoAnswerChatGPT.Lines.Add('');
      MemoAnswerChatGPT.Lines.Add(ResponseText);
      MemoAnswerChatGPT.Lines.Add('');
      MemoAnswerChatGPT.Lines.Add('==================');
      MemoAnswerChatGPT.Lines.Add('⏰' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    end
    else
    begin
      MemoAnswerChatGPT.Lines.Add(TranslateErrEmptyResponseReceived);
      MemoAnswerChatGPT.Lines.Add(TranslateCheckApiTokenInternetCon);
    end;
  finally
    // Restore the interface to normal state / Przywróć normalny stan interfejsu
    sbzapytaj.Enabled := True;
  end;
end;

procedure Taiassistant.AskChatGPT(promt: String; memopromt: TMemo);
begin
  //Advanced prompt
  //Zaawansowany prompt
  PromptChatGPT:= promt +  ' ' + memopromt.Text;
  if Trim(PromptChatGPT) = '' then
  begin
    ShowMessage('Brak promtu!');
    Exit;
  end;
  try
    // Wywołanie funkcji
    ZapytajChatGPT(Token, ModelGPT, PromptChatGPT, @OnChatGPTResponse);
  except
    on E: Exception do
    begin
      ShowMessage(TranslateMistake + E.Message);
    end;
  end;
end;

end.


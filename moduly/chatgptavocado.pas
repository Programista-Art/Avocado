unit chatgptavocado;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, chatgpt;

type
  // Typ procedury zwrotnej (callback), który przyjmuje odpowiedź jako string
  TChatGPTResponseProc = procedure(const ResponseText: string) of object;

  // Klasa pomocnicza do zarządzania wywołaniami ChatGPT
  TChatGPTWrapper = class(TObject)
  private
    FChatGPT: TChatGPT;
    FOnComplete: TChatGPTResponseProc;
    FIsProcessing: Boolean;
  public
    constructor Create(const AToken, AModel: string; AOnComplete: TChatGPTResponseProc);
    destructor Destroy; override;
    procedure HandleResponse(Sender: TObject);
    procedure SendQuestion(const APrompt: string);
    property IsProcessing: Boolean read FIsProcessing;
  end;

// Główna procedura do wysyłania zapytania
procedure ZapytajChatGPT(const AToken, AModel, APrompt: string; OnComplete: TChatGPTResponseProc);

implementation

uses
  Dialogs;

{ TChatGPTWrapper }

constructor TChatGPTWrapper.Create(const AToken, AModel: string; AOnComplete: TChatGPTResponseProc);
begin
  inherited Create;
  FOnComplete := AOnComplete;
  FIsProcessing := False;

  // Utworzenie instancji TChatGPT
  FChatGPT := TChatGPT.Create(nil);
  FChatGPT.Token := AToken;
  FChatGPT.ChatModel := AModel;
  FChatGPT.OnResponse := @HandleResponse;
end;

destructor TChatGPTWrapper.Destroy;
begin
  if Assigned(FChatGPT) then
  begin
    FChatGPT.OnResponse := nil; // Usuń referencję do metody
    FChatGPT.Free;
  end;
  inherited Destroy;
end;

procedure TChatGPTWrapper.HandleResponse(Sender: TObject);
var
  ResponseText: string;
begin
  FIsProcessing := False;

  try
    if Assigned(Sender) and (Sender is TChatGPT) then
    begin
      ResponseText := TChatGPT(Sender).Response;

      if Assigned(FOnComplete) then
      begin
        try
          FOnComplete(ResponseText);
        except
          on E: Exception do
            ShowMessage('Błąd w procedurze zwrotnej: ' + E.Message);
        end;
      end;
    end
    else
    begin
      if Assigned(FOnComplete) then
        FOnComplete('Błąd: Nieprawidłowy obiekt odpowiedzi');
    end;
  finally
    // Automatyczne zwolnienie wrappera po obsłudze odpowiedzi
    Self.Free;
  end;
end;

procedure TChatGPTWrapper.SendQuestion(const APrompt: string);
begin
  if FIsProcessing then
  begin
    ShowMessage('Poprzednie zapytanie jest w trakcie przetwarzania...');
    Exit;
  end;

  FIsProcessing := True;

  try
    FChatGPT.SendQuestionAsync(APrompt);
  except
    on E: Exception do
    begin
      FIsProcessing := False;
      ShowMessage('Błąd podczas wysyłania zapytania: ' + E.Message);
      Self.Free;
    end;
  end;
end;

// Główna procedura - tworzy wrapper i wysyła zapytanie
procedure ZapytajChatGPT(const AToken, AModel, APrompt: string; OnComplete: TChatGPTResponseProc);
var
  Wrapper: TChatGPTWrapper;
begin
  if Trim(AToken) = '' then
  begin
    ShowMessage('Błąd: Brak tokenu API');
    Exit;
  end;

  if Trim(APrompt) = '' then
  begin
    ShowMessage('Błąd: Puste zapytanie');
    Exit;
  end;

  try
    Wrapper := TChatGPTWrapper.Create(AToken, AModel, OnComplete);
    Wrapper.SendQuestion(APrompt);
  except
    on E: Exception do
    begin
      ShowMessage('Błąd podczas inicjalizacji: ' + E.Message);
      if Assigned(Wrapper) then
        Wrapper.Free;
    end;
  end;
end;

end.

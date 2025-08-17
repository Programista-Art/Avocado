unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, fphttpclient, opensslsockets, inifiles;

type
  TChatGPT = class;

  TChatGPTThread = class(TThread)
  private
    FChatGPT: TChatGPT;
    FQuestion: String;
    FOnResponse: TNotifyEvent;
  protected
    procedure Execute; override;
    procedure DoResponse;
  public
    constructor Create(ChatGPT: TChatGPT; Question: String; OnResponse: TNotifyEvent);
  end;

  TChatGPT = class(TComponent)
  private
    FToken: String;
    FQuestion: String;
    FResponse: String;
    FChatModel: String;
    FParams: TStrings;
    FOnResponse: TNotifyEvent;
    function RequestJson(URL: String; Token: string; Question: string): String;
    function ExtractMessage(const JSON: string): string;
  public
    property Token: String read FToken write FToken;
    property Question: String read FQuestion;
    property Response: String read FResponse write FResponse;
    property ChatModel: String read FChatModel write FChatModel;
    property OnResponse: TNotifyEvent read FOnResponse write FOnResponse;
    function SendQuestion(Question1: String): boolean; // Synchronous call
    procedure SendQuestionAsync(Question1: String); // Asynchronous call
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{ TChatGPTThread }

constructor TChatGPTThread.Create(ChatGPT: TChatGPT; Question: String; OnResponse: TNotifyEvent);
begin
  inherited Create(True); // Ustawienie True, aby nie uruchamiać automatycznie
  FChatGPT := ChatGPT;
  FQuestion := Question;
  FOnResponse := OnResponse;
  FreeOnTerminate := True; // Automatyczne zwolnienie pamięci po zakończeniu wątku
end;

procedure TChatGPTThread.Execute;
begin
  // Wysyłanie pytania
  FChatGPT.SendQuestion(FQuestion);

  // Wywołanie callbacka po otrzymaniu odpowiedzi
  if Assigned(FOnResponse) then
    Synchronize(@DoResponse);
end;

procedure TChatGPTThread.DoResponse;
begin
  if Assigned(FOnResponse) then
    FOnResponse(FChatGPT);
end;

{ TChatGPT }

procedure TChatGPT.SendQuestionAsync(Question1: String);
var
  ChatGPTThread: TChatGPTThread;
begin
  // Uruchomienie wątku do asynchronicznego wysłania zapytania
  ChatGPTThread := TChatGPTThread.Create(Self, Question1, FOnResponse);
  ChatGPTThread.Start;
end;

function TChatGPT.ExtractMessage(const JSON: string): string;
var
  Data: TJSONData;
  JsonObject: TJSONObject;
begin
  Data := GetJSON(JSON);
  try
    if Data is TJSONObject then
    begin
      JsonObject := TJSONObject(Data);
      Result := JsonObject.GetPath('choices[0].message.content').AsString;
    end
    else
      Result := '';
  finally
    Data.Free;
  end;
end;

function TChatGPT.RequestJson(URL: string; Token: string; Question: string): string;
var
  HttpClient: TFPHttpClient;
  Response1: AnsiString;
  ResponseStream: TStringStream;
  Params: string;
begin
  Params := '{ "model": "' + FChatModel + '", "messages": [{"role": "user", "content": "' + Question + '"}] }';

  HttpClient := TFPHttpClient.Create(nil);
  try
    ResponseStream := TStringStream.Create('');
    HttpClient.AddHeader('Content-Type', 'application/json;');
    HttpClient.AddHeader('Authorization', 'Bearer ' + EncodeURLElement(Token));
    HttpClient.RequestBody := TRawByteStringStream.Create(Params);
    try
      Response := HttpClient.Post(URL);
    except
      on E: Exception do
        Response := '';
    end;
  finally
    HttpClient.RequestBody.Free;
    HttpClient.Free;
  end;
  Result := Response;
end;

function TChatGPT.SendQuestion(Question1: String): boolean;
var
  URL: String;
  JsonResponse: String;
begin
  URL := 'https://api.openai.com/v1/chat/completions';
  JsonResponse := RequestJson(URL, FToken, EncodeURLElement(Question1));
  try
    FResponse := ExtractMessage(JsonResponse);
  except
    FResponse := JsonResponse;
  end;
  Result := FResponse <> '';
end;

constructor TChatGPT.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChatModel := 'gpt-4o-mini'; // Domyślny model czatu
  FParams := TStringList.Create;
end;

destructor TChatGPT.Destroy;
begin
  FParams.Free;
  inherited;
end;

end.


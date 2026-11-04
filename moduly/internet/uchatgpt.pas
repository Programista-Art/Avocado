unit uchatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils,Dialogs , Classes, chatgptavocado;

var
  GlobalResponseReceived: Boolean = False;
  GlobalChatResponse: string = '';
  userQuestion, answer: string;

// Funkcja zapytaj – wysyła zapytanie do ChatGPT i zwraca otrzymaną odpowiedź
function zapytaj(const question: string): string;

implementation

// Deklaracja wstępna globalnego callbacka
procedure GlobalResponseCallback(const ResponseText: string); forward;

function zapytaj(const question: string): string;
begin
  GlobalResponseReceived := False;
  GlobalChatResponse := '';

  // Wywołanie funkcji wysyłającej zapytanie.
  // Podaj własny klucz API oraz model (tutaj przykładowo 'gpt-4o-mini').
  ZapytajChatGPT('sk-0tmz8yl8btgbMe1eQbPOEeCZ9HmjZkhHnt4jVHTvoET3BlbkFJxLdlT7wUc8Jf5ocslX4hR2p3QYo7Grr1us0cQbjzUA',
    'gpt-4o-mini', question, @GlobalResponseCallback);

  // Pętla oczekująca na odpowiedź – przetwarzanie wywołań synchronizowanych.
  while not GlobalResponseReceived do
  begin
    CheckSynchronize(100); // Przetwarzanie zadań synchronizowanych co 100 ms.
    Sleep(100);           // Krótkie opóźnienie, aby nie obciążać CPU.
  end;

  Result := GlobalChatResponse;
end;

procedure GlobalResponseCallback(const ResponseText: string);
begin
  GlobalChatResponse := ResponseText;
  GlobalResponseReceived := True;
end;

end.


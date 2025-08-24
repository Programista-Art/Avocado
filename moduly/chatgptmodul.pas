unit chatgptmodul;

{$mode ObjFPC}{$H+}
interface
uses
  SysUtils, Classes, chatgptavocado;

// Globalne zmienne przechowujące stan odpowiedzi
var
  GlobalResponseReceived: Boolean = False;
  GlobalChatResponse: string = '';
  userQuestion, answer: string;
implementation
// Callback – globalna procedura, która zostanie wywołana po otrzymaniu odpowiedzi
procedure GlobalResponseCallback(const ResponseText: string);
begin
  GlobalChatResponse := ResponseText;
  GlobalResponseReceived := True;
end;

// Funkcja zapytaj – wysyła zapytanie do ChatGPT i zwraca otrzymaną odpowiedź
function zapytaj(const question: string): string;
begin
  GlobalResponseReceived := False;
  GlobalChatResponse := '';

  // Wywołanie funkcji wysyłającej zapytanie. Upewnij się, że wstawisz poprawny klucz API.
  ZapytajChatGPT('sk-0tmz8yl8btgbMe1eQbPOEeCZ9HmjZkhHnt4jVHTvoET3BlbkFJxLdlT7wUc8Jf5ocslX4hR2p3QYo7Grr1us0cQbjzUA', 'gpt-4o-mini', userQuestion, @GlobalResponseCallback);

  // Pętla oczekująca na odpowiedź – przetwarzamy wywołania synchronizowane.
  while not GlobalResponseReceived do
  begin
    CheckSynchronize(100); // Przetwarzanie zadań synchronizowanych co 100 ms.
    Sleep(100);           // Krótka przerwa, aby nie obciążać CPU.
  end;

  Result := GlobalChatResponse;
end;


begin
  WriteLn('Wpisz pytanie do ChatGPT (język avocado):');
  ReadLn(userQuestion);

  WriteLn('Wysyłam zapytanie...');
  answer := zapytaj(userQuestion);

  WriteLn('Odpowiedź od ChatGPT:');
  WriteLn(answer);

  WriteLn('Naciśnij Enter, aby zakończyć...');
  ReadLn;
end.


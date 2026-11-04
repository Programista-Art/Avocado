unit avoraiser.webview;
{$mode objfpc}{$H+}
interface

uses
  Windows, Messages, SysUtils, Classes, CommCtrl,
  uWVLoader, uWVBrowser,uWVTypes, uWVInterfaces, uWVCoreWebView2Args,uWVTypeLibrary;
type

  { TAvoEvents }

  TAvoEvents = class
    procedure OnBrowserAfterCreated(Sender: TObject);
    procedure OnWebMessageReceived(Sender: TObject; const aWebView: ICoreWebView2; const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
  end;
type
  TAvoWebMessageCallback = procedure(const msg: String);
var
  AvoBrowser: TWVBrowser;
  AvoBrowserWindow: HWND;
  AvoBrowserEvents: TAvoEvents;
  AvoStartupURL: PChar;
// Exported functions for Avoraiser Compiler
procedure webview_create(aHandle: HWND);
procedure webview_navigate(aURL: PChar);
procedure webview_resize();
procedure webview_execute_js(aScript: PChar);
procedure webview_destroy();

// Podstawowa nawigacja
procedure webview_go_back;
procedure webview_go_forward;
procedure webview_reload;
procedure webview_stop;

// Sterowanie widokiem i narzędziami
procedure webview_show_dev_tools;
procedure webview_set_zoom(zoom_factor: Double);
procedure webview_set_muted(is_muted: Boolean);
//ukrywa przegladarke
procedure webview_hide;
//pokazuje przegladarke
procedure webview_show;
//uspienie przegladarki
procedure webview_suspend;
//obudzenie przegladarki
procedure webview_resume;
// Ładowanie i pobieranie treści
procedure webview_navigate_to_string(const html_content: PChar);
function webview_get_title: String;
function webview_get_url: String;

// Blokady i ustawienia UI (Zabezpieczenia)
procedure webview_set_context_menu_enabled(is_enabled: Boolean);
procedure webview_set_dev_tools_enabled(is_enabled: Boolean);
procedure webview_set_status_bar_enabled(is_enabled: Boolean);

// Narzędzia systemowe
procedure webview_show_print_ui;
procedure webview_clear_cache;

// Funkcja do rejestracji nasłuchiwacza w głównej aplikacji
procedure webview_set_on_message(aCallback: TAvoWebMessageCallback);

implementation
var
  GlobalWebMessageCallback: TAvoWebMessageCallback = nil;

//Nasłuchuje komunikatów okna, do którego wpięto WebView
function avocado_webview_subclass_proc(h_wnd: HWND; u_msg: UINT; w_param: WPARAM; l_param: LPARAM; u_id_subclass: UINT_PTR; dw_ref_data: DWORD_PTR): LRESULT; stdcall;
begin
  if u_msg = WM_SIZE then
  begin
    //Przeglądarka sama zmienia rozmiar, gdy użytkownik rozciąga okno!
    webview_resize();
  end
  else if u_msg = WM_DESTROY then
  begin
    // Okno jest niszczone - sprzątamy silnik!
    webview_destroy();

    // Na sam koniec zdejmujemy podsłuch, żeby nie zostawić śmieci w pamięci WinAPI
    //RemoveWindowSubclass(h_wnd, @avocado_webview_subclass_proc, u_id_subclass);
    RemoveWindowSubclass(h_wnd, SUBCLASSPROC(@avocado_webview_subclass_proc), u_id_subclass);
  end;

  // Przekazujemy resztę komunikatów z powrotem do oryginalnego okna Avoraisera
  Result := DefSubclassProc(h_wnd, u_msg, w_param, l_param);
end;
procedure webview_execute_js(aScript: PChar);
var
  jsCode: wvstring;
begin
  // Upewniamy się, że przeglądarka faktycznie istnieje i działa
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    // Odbudowujemy pamięć o kodowaniu: UTF8String(aScript)
    // Automagiczna konwersja FPC: Przypisanie do wvstring (UnicodeString)
    jsCode := wvstring(UTF8String(aScript));
    AvoBrowser.ExecuteScript(jsCode);
  end;
end;

// Event: Triggered when the physical browser window is created
procedure TAvoEvents.OnBrowserAfterCreated(Sender: TObject);
begin
    webview_resize();

    //DEBUG: Wyświetlamy systemowy komunikat, że silnik wstał!
    //MessageBox(0, 'Sukces! Silnik Chromium jest gotowy!', 'Avoraiser Debug', MB_OK);

   // AvoBrowser.Navigate('https://www.google.pl');
     //if AvoStartupURL <> nil then
     // webview_navigate(AvoStartupURL);
    if AvoStartupURL <> nil then
    begin
      AvoBrowser.Navigate(AvoStartupURL);
      AvoStartupURL := nil;
    end;
end;

procedure TAvoEvents.OnWebMessageReceived(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
var
  ArgsWrapper: TCoreWebView2WebMessageReceivedEventArgs;
  ReceivedMsg: String;
begin
    if Assigned(GlobalWebMessageCallback) then
      begin
        ArgsWrapper := TCoreWebView2WebMessageReceivedEventArgs.Create(aArgs);
        try
          ReceivedMsg := String(ArgsWrapper.WebMessageAsString);
          GlobalWebMessageCallback(ReceivedMsg);
        finally
          ArgsWrapper.Free;
        end;
      end;
end;

// 1. Create the browser and attach it to the Avoraiser Window
procedure webview_create(aHandle: HWND);
var
  Msg: TMsg;
begin
  AvoBrowserWindow := aHandle;
  //AvoStartupURL := aURL;

  while not GlobalWebView2Loader.Initialized do
  begin
    Sleep(10);

    // Zastępujemy Application.ProcessMessages naszą własną pętlą PeekMessage
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
  end;

  if AvoBrowser = nil then
    begin
      // Tworzymy naszą klasę nasłuchującą, jeśli jeszcze nie istnieje
      if AvoBrowserEvents = nil then
        AvoBrowserEvents := TAvoEvents.Create;
      AvoBrowser := TWVBrowser.Create(nil);
      AvoBrowser.OnAfterCreated := @AvoBrowserEvents.OnBrowserAfterCreated;
      AvoBrowser.OnWebMessageReceived := @AvoBrowserEvents.OnWebMessageReceived;

      AvoBrowser.CreateBrowser(AvoBrowserWindow);
      SetWindowSubclass(AvoBrowserWindow, @avocado_webview_subclass_proc, 1, 0);
    end;

end;

// 2. Navigate to a specific URL
procedure webview_navigate(aURL: PChar);
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
    begin
      AvoBrowser.Navigate(aURL);
    end
    else
    begin
      // Jeśli silnik się JESZCZE TWORZY w tle, zapisujemy link do pamięci (do zmiennej globalnej),
      AvoStartupURL := aURL;
    end;
end;

// Handle window resizing (Call this inside WM_SIZE of your main WndProc)
procedure webview_resize();
var
  ClientRect: TRect;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    //Pobieramy wymiary komponnetu np. panel
    GetClientRect(AvoBrowserWindow, ClientRect);
    // Ładujemy te wymiary do przeglądarki. Wypełni ona cały Panel.
    AvoBrowser.Bounds := ClientRect;
  end;
end;

procedure webview_destroy();
begin
  if Assigned(AvoBrowser) then
  begin
   // AvoBrowser.CloseBrowser;
    // Bezpieczne zwolnienie pamięci (ustawia wskaźnik na nil)
    //FreeAndNil(AvoBrowser);
    AvoBrowser.Free;
    AvoBrowser := nil;
  end;
  // Zwalniamy naszą klasę nasłuchującą zdarzenia
  if Assigned(AvoBrowserEvents) then
  begin
    AvoBrowserEvents.Free;
    AvoBrowserEvents := nil;
  end;
  //if Assigned(AvoBrowserEvents) then
  //  FreeAndNil(AvoBrowserEvents);
end;

procedure webview_go_back;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    if AvoBrowser.CanGoBack then
      AvoBrowser.GoBack;
  end;
end;

procedure webview_go_forward;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    if AvoBrowser.CanGoForward then
      AvoBrowser.GoForward;
  end;
end;

procedure webview_reload;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.Refresh;
  end;
end;

procedure webview_stop;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.Stop;
  end;
end;

procedure webview_show_dev_tools;
begin
  // Otwiera konsolę deweloperską (F12 w Chrome) - bezcenne przy debugowaniu JS!
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.OpenDevToolsWindow;
  end;
end;

procedure webview_set_zoom(zoom_factor: Double);
begin
 // 1.0 to 100%, 1.5 to 150% itd.
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.ZoomFactor := zoom_factor;
  end;
end;

procedure webview_set_muted(is_muted: Boolean);
begin
  // Wycisza dźwięki z przeglądarki (np. z YouTube)
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.IsMuted := is_muted;
  end;
end;

procedure webview_hide;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
     AvoBrowser.IsVisible := False;
end;

procedure webview_show;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
     AvoBrowser.IsVisible := True;
end;

procedure webview_suspend;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    // Przeglądarka musi być najpierw ukryta, aby można było ją uśpić
    AvoBrowser.IsVisible := False;
    AvoBrowser.TrySuspend;
  end;
end;

procedure webview_resume;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.Resume;
    AvoBrowser.IsVisible := True;
  end;
end;

procedure webview_navigate_to_string(const html_content: PChar);
var
  html_code: wvstring;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    html_code := wvstring(UTF8String(html_content));
    AvoBrowser.NavigateToString(html_code);
  end;
end;

function webview_get_title: String;
begin
  Result := '';
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    Result := String(AvoBrowser.DocumentTitle);
  end;
end;

function webview_get_url: String;
begin
  Result := '';
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    Result := String(AvoBrowser.Source);
  end;
end;

procedure webview_set_context_menu_enabled(is_enabled: Boolean);
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.DefaultContextMenusEnabled := is_enabled;
  end;
end;

procedure webview_set_dev_tools_enabled(is_enabled: Boolean);
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.DevToolsEnabled := is_enabled;
  end;
end;

procedure webview_set_status_bar_enabled(is_enabled: Boolean);
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.StatusBarEnabled := is_enabled;
  end;
end;

procedure webview_show_print_ui;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
    begin
      // Przekazanie False oznacza użycie nowoczesnego okna drukowania z podglądem
      AvoBrowser.ShowPrintUI(False);
    end;
end;

procedure webview_clear_cache;
begin
  if Assigned(AvoBrowser) and GlobalWebView2Loader.Initialized then
  begin
    AvoBrowser.ClearCache;
  end;
end;

procedure webview_set_on_message(aCallback: TAvoWebMessageCallback);
begin
  GlobalWebMessageCallback := aCallback;
end;

initialization
  GlobalWebView2Loader := TWVLoader.Create(nil);
  // Directory for cookies, cache, and local storage
  GlobalWebView2Loader.UserDataFolder := ExtractFilePath(ParamStr(0)) + 'AvocadoCache';
  GlobalWebView2Loader.StartWebView2;

finalization
  //if Assigned(AvoBrowserEvents) then AvoBrowserEvents.Free;
  //if Assigned(AvoBrowser) then AvoBrowser.Free;
  //if Assigned(GlobalWebView2Loader) then GlobalWebView2Loader.Free;

end.

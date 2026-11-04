{$codepage utf8}
{$mode objfpc}
{$H+}
{$APPTYPE GUI}
program demo_edytor;
uses SysUtils, Classes, StrUtils, Windows, avoraiser.window, avoraiser.layout, avoraiser.button, avoraiser.edit, avoraiser.labels, avoraiser.listbox, avoraiser.chekbox, avoraiser.radiobutton, avoraiser.groupbutton, avoraiser.utils, avoraiser.progressbar, avoraiser.trackbar, avoraiser.core;

var
  my_window: HWND;
  przycisk_1: HWND;
  pole_2: HWND;
  etykieta_3: HWND;
  lista_4: HWND;
  ptaszek_5: HWND;
  opcja_6: HWND;
  postep_7: HWND;
  suwak_8: HWND;
  panel_9: HWND;

procedure buduj_okno;
var
  ui: TAvocadoWindowParams;
begin
  ui := Default(TAvocadoWindowParams);
  ui.title := 'Demo edytora UI';
  ui.width := 640;
  ui.height := 480;
  ui.visible := True;
  my_window := create_window(ui);
  if (my_window <> 0) then
  begin
    center_window(my_window);
    etykieta_3 := create_label(my_window, 'Formularz testowy', 20, 16, 200, 20);
    pole_2 := create_edit(my_window, 'Wpisz tekst', 20, 48, 220, 26);
    przycisk_1 := create_button(my_window, 'OK', 260, 46, 100, 30);
    lista_4 := create_listbox(my_window, 20, 90, 220, 120);
    ptaszek_5 := create_checkbox(my_window, 'Zgoda', 20, 230, 140, 22, 0);
    opcja_6 := create_radio_button(my_window, 'Opcja A', 20, 260, 140, 22, 1);
    suwak_8 := create_trackbar(my_window, 20, 300, 200, 28);
    postep_7 := create_progressbar(my_window, 20, 340, 200, 22);
    panel_9 := create_panel(my_window, 280, 90, 300, 200, 15790320);
  end;
end;

begin
  buduj_okno();
  run_app();
end.

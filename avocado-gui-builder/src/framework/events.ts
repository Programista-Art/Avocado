/**
 * Avoraiser event catalog — every set_on_* from avoraiser/*.pas.
 * Names are AVOCADO identifiers (never translated in code).
 * Labels/descriptions are EN/PL for the UI.
 */
export interface AvocadoEventDef {
  id: string;
  api: string;
  labelEn: string;
  labelPl: string;
  descEn: string;
  descPl: string;
  /** which component categories support this */
  on: Array<'window' | 'button' | 'edit' | 'label' | 'list' | 'memo' | 'track' | 'progress' | 'check' | 'panel' | 'any'>;
}

const E = (
  api: string,
  labelEn: string,
  labelPl: string,
  descEn: string,
  descPl: string,
  on: AvocadoEventDef['on'],
): AvocadoEventDef => ({ id: api, api, labelEn, labelPl, descEn, descPl, on });

export const avocadoEvents: AvocadoEventDef[] = [
  E('set_on_click', 'OnClick', 'Kliknięcie', 'Left click / action', 'Kliknięcie lewym / akcja', ['button', 'edit', 'label', 'list', 'check', 'panel', 'window', 'any']),
  E('set_on_change', 'OnChange', 'Zmiana', 'Value or text changed', 'Zmiana wartości lub tekstu', ['edit', 'list', 'memo', 'track', 'progress', 'check', 'any']),
  E('set_on_color_btn', 'OnColorBtn', 'Kolor przycisku', 'Button color query (custom paint)', 'Zapytanie o kolor przycisku', ['button']),
  E('set_on_color_edit', 'OnColorEdit', 'Kolor edycji', 'Edit background color query', 'Zapytanie o kolor pola', ['edit']),

  E('set_on_key_down', 'OnKeyDown', 'Klawisz w dół', 'Key pressed', 'Wciśnięcie klawisza', ['window', 'edit', 'memo', 'any']),
  E('set_on_key_up', 'OnKeyUp', 'Klawisz w górę', 'Key released', 'Puszczenie klawisza', ['window', 'edit', 'memo', 'any']),
  E('set_on_sys_key_down', 'OnSysKeyDown', 'Klawisz systemowy w dół', 'Alt+key pressed', 'Wciśnięcie klawisza systemowego', ['window', 'any']),
  E('set_on_sys_key_up', 'OnSysKeyUp', 'Klawisz systemowy w górę', 'Alt+key released', 'Puszczenie klawisza systemowego', ['window', 'any']),
  E('set_on_char', 'OnChar', 'Znak', 'Character input', 'Znak z klawiatury', ['window', 'edit', 'memo', 'any']),
  E('set_on_sys_char', 'OnSysChar', 'Znak systemowy', 'System character', 'Znak systemowy', ['window', 'any']),
  E('set_on_dead_char', 'OnDeadChar', 'Znak martwy', 'Dead key (accent)', 'Klawisz akcentu', ['window', 'any']),
  E('set_on_uni_char', 'OnUniChar', 'Znak Unicode', 'Unicode character', 'Znak Unicode', ['window', 'any']),

  E('set_on_mouse_move', 'OnMouseMove', 'Ruch myszy', 'Mouse moved', 'Ruch myszy', ['window', 'button', 'edit', 'label', 'list', 'memo', 'panel', 'any']),
  E('set_on_mouse_down', 'OnMouseDown', 'Mysz w dół', 'Any mouse button down', 'Wciśnięcie przycisku myszy', ['window', 'button', 'edit', 'label', 'list', 'memo', 'panel', 'any']),
  E('set_on_lbutton_down', 'OnLButtonDown', 'LPM w dół', 'Left button down', 'Lewy przycisk w dół', ['window', 'button', 'edit', 'label', 'list', 'memo', 'panel', 'any']),
  E('set_on_lbutton_up', 'OnLButtonUp', 'LPM w górę', 'Left button up', 'Lewy przycisk w górę', ['window', 'button', 'edit', 'label', 'list', 'memo', 'panel', 'any']),
  E('set_on_lbutton_dbl_clk', 'OnLButtonDblClk', 'LPM dwuklik', 'Left double-click', 'Podwójne kliknięcie LPM', ['window', 'button', 'label', 'list', 'any']),
  E('set_on_rbutton_down', 'OnRButtonDown', 'PPM w dół', 'Right button down', 'Prawy przycisk w dół', ['window', 'button', 'label', 'list', 'panel', 'any']),
  E('set_on_rbutton_up', 'OnRButtonUp', 'PPM w górę', 'Right button up', 'Prawy przycisk w górę', ['window', 'button', 'label', 'list', 'panel', 'any']),
  E('set_on_rbutton_dbl_clk', 'OnRButtonDblClk', 'PPM dwuklik', 'Right double-click', 'Podwójne kliknięcie PPM', ['window', 'any']),
  E('set_on_mbutton_down', 'OnMButtonDown', 'ŚPM w dół', 'Middle button down', 'Środkowy przycisk w dół', ['window', 'any']),
  E('set_on_mbutton_up', 'OnMButtonUp', 'ŚPM w górę', 'Middle button up', 'Środkowy przycisk w górę', ['window', 'any']),
  E('set_on_mbutton_dbl_clk', 'OnMButtonDblClk', 'ŚPM dwuklik', 'Middle double-click', 'Podwójne kliknięcie ŚPM', ['window', 'any']),
  E('set_on_mouse_wheel', 'OnMouseWheel', 'Kółko myszy', 'Vertical wheel', 'Kółko myszy (pion)', ['window', 'list', 'memo', 'track', 'any']),
  E('set_on_mouse_hwheel', 'OnMouseHWheel', 'Kółko poziome', 'Horizontal wheel', 'Kółko myszy (poziom)', ['window', 'any']),

  E('set_on_paint', 'OnPaint', 'Rysowanie', 'Custom paint (GDI)', 'Rysowanie (GDI)', ['window', 'panel', 'any']),
  E('set_on_resize', 'OnResize', 'Zmiana rozmiaru', 'Resized', 'Zmiana rozmiaru', ['window', 'panel', 'any']),
  E('set_on_sizing', 'OnSizing', 'Skalowanie', 'While resizing', 'W trakcie skalowania', ['window', 'any']),
  E('set_on_move', 'OnMove', 'Przeniesiono', 'Moved', 'Przeniesienie', ['window', 'any']),
  E('set_on_moving', 'OnMoving', 'Przesuwanie', 'While moving', 'W trakcie przesuwania', ['window', 'any']),
  E('set_on_window_pos_changing', 'OnWindowPosChanging', 'Zmiana pozycji', 'Position changing', 'Zmiana pozycji okna', ['window', 'any']),

  E('set_on_set_focus', 'OnSetFocus', 'Fokus', 'Gained focus', 'Uzyskanie fokusu', ['window', 'edit', 'memo', 'any']),
  E('set_on_kill_focus', 'OnKillFocus', 'Utrata fokusu', 'Lost focus', 'Utrata fokusu', ['window', 'edit', 'memo', 'any']),
  E('set_on_timer', 'OnTimer', 'Zegar', 'Timer tick', 'Takt zegara', ['window', 'any']),
  E('set_on_drop_files', 'OnDropFiles', 'Upuszczone pliki', 'Files dropped', 'Upuszczone pliki', ['window', 'any']),
  E('set_on_enable', 'OnEnable', 'Włączenie', 'Enabled state changed', 'Zmiana stanu Enabled', ['window', 'button', 'edit', 'any']),
  E('set_on_close_query', 'OnCloseQuery', 'Pytanie o zamknięcie', 'Query before close', 'Pytanie przed zamknięciem', ['window']),
  E('set_on_get_min_max_info', 'OnGetMinMaxInfo', 'Limity rozmiaru', 'Min/max size limits', 'Limity rozmiaru', ['window']),
  E('set_on_hit_test', 'OnHitTest', 'Test trafienia', 'Hit test (frameless)', 'Test trafienia', ['window']),

  E('set_on_nc_mouse_move', 'OnNcMouseMove', 'Ruch w ramce', 'Non-client mouse move', 'Ruch myszy w ramce', ['window']),
  E('set_on_nc_left_down', 'OnNcLeftDown', 'LPM w ramce w dół', 'NC left down', 'LPM w obszarze ramki', ['window']),
  E('set_on_nc_left_up', 'OnNcLeftUp', 'LPM w ramce w górę', 'NC left up', 'LPM w górę w ramce', ['window']),
  E('set_on_nc_left_double_click', 'OnNcLeftDblClick', 'Dwuklik w ramce', 'NC left double-click', 'Dwuklik w ramce', ['window']),
  E('set_on_nc_right_down', 'OnNcRightDown', 'PPM w ramce w dół', 'NC right down', 'PPM w ramce', ['window']),
  E('set_on_nc_right_up', 'OnNcRightUp', 'PPM w ramce w górę', 'NC right up', 'PPM w górę w ramce', ['window']),

  E('set_on_vscroll', 'OnVScroll', 'Pasek pionowy', 'Vertical scroll', 'Przewijanie pionowe', ['window', 'list', 'memo', 'any']),
  E('set_on_hscroll', 'OnHScroll', 'Pasek poziomy', 'Horizontal scroll', 'Przewijanie poziome', ['window', 'list', 'memo', 'any']),
  E('set_on_notify', 'OnNotify', 'Powiadomienie', 'WM_NOTIFY', 'Powiadomienie kontrolek', ['window', 'any']),
  E('set_on_context_menu', 'OnContextMenu', 'Menu kontekstowe', 'Context menu request', 'Żądanie menu kontekstowego', ['window', 'edit', 'memo', 'any']),
  E('set_on_activate_app', 'OnActivateApp', 'Aktywacja aplikacji', 'App activation', 'Aktywacja aplikacji', ['window']),
  E('set_on_query_end_session', 'OnQueryEndSession', 'Koniec sesji (pytanie)', 'OS shutdown query', 'Pytanie o zakończenie sesji', ['window']),
  E('set_on_end_session', 'OnEndSession', 'Koniec sesji', 'OS shutdown', 'Zakończenie sesji', ['window']),
  E('set_on_power_event', 'OnPowerEvent', 'Zdarzenie zasilania', 'Power event', 'Zdarzenie zasilania', ['window']),
  E('set_on_device_event', 'OnDeviceEvent', 'Zdarzenie urządzenia', 'Device change', 'Zmiana urządzenia', ['window']),
  E('set_on_clipboard_render', 'OnClipboardRender', 'Renderowanie schowka', 'Clipboard render', 'Renderowanie schowka', ['window']),
];

export function eventsFor(kindHint: string): AvocadoEventDef[] {
  return avocadoEvents.filter((e) => {
    if (e.on.includes('any')) return true;
    return e.on.some((k) => kindHint.includes(k) || k === kindHint);
  });
}

export function eventLabel(ev: AvocadoEventDef, lang: 'en' | 'pl'): string {
  return lang === 'pl' ? ev.labelPl : ev.labelEn;
}

export function eventDesc(ev: AvocadoEventDef, lang: 'en' | 'pl'): string {
  return lang === 'pl' ? ev.descPl : ev.descEn;
}

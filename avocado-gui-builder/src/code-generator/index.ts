/**
 * Deterministic **Avocado** code generator.
 * Emits Avoraiser/Avocado APIs: 100% Polish or 100% English depending on project.settings.codeLang.
 * Guarantees NO numbers in variable and function names.
 * Ensures Edit, RichEdit, and Memo have dark backgrounds darker than the application window.
 * Strictly adheres to Avocado syntax: NO semicolons (;) at the end of statements or blocks.
 */
import type { ComponentInstance, FormModel, ProjectModel, FrameworkComponentMeta } from '@/types';
import { getComponentMeta } from '@/framework/metadata';
import { isServiceId } from '@/framework/services';

export type AvocadoLang = 'pl' | 'en';

const DIGIT_WORDS_PL: Record<string, string> = {
  '0': 'zero',
  '1': 'jeden',
  '2': 'dwa',
  '3': 'trzy',
  '4': 'cztery',
  '5': 'piec',
  '6': 'szesc',
  '7': 'siedem',
  '8': 'osiem',
  '9': 'dziewiec',
};

const DIGIT_WORDS_EN: Record<string, string> = {
  '0': 'zero',
  '1': 'one',
  '2': 'two',
  '3': 'three',
  '4': 'four',
  '5': 'five',
  '6': 'six',
  '7': 'seven',
  '8': 'eight',
  '9': 'nine',
};

/**
 * Sanitizes an identifier so that it contains ABSOLUTELY NO DIGITS/NUMBERS,
 * replacing any numbers with Polish or English word equivalents.
 */
export function sanitizeIdent(s: string, lang: AvocadoLang = 'pl'): string {
  if (!s) return lang === 'pl' ? 'zmienna' : 'variable';
  const digitMap = lang === 'en' ? DIGIT_WORDS_EN : DIGIT_WORDS_PL;
  let out = '';
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (ch >= '0' && ch <= '9') {
      out += (out.length > 0 && !out.endsWith('_') ? '_' : '') + (digitMap[ch] || 'x') + '_';
    } else if (/[a-zA-Z_]/.test(ch)) {
      out += ch;
    } else {
      out += '_';
    }
  }
  out = out.replace(/_+/g, '_').replace(/^_/, '').replace(/_$/, '');
  if (!out) out = lang === 'pl' ? 'moja_aplikacja' : 'my_app';
  if (!/^[a-zA-Z_]/.test(out)) out = (lang === 'pl' ? 'prog_' : 'app_') + out;
  return out;
}

function q(s: string): string {
  return "'" + (s ?? '').replace(/\\/g, '\\\\').replace(/'/g, "''").replace(/\r?\n/g, '\\n') + "'";
}

/**
 * Converts a CSS/HTML hex color (#RRGGBB) to Win32 / Avoraiser COLORREF hex literal ($BBGGRR).
 * In Avoraiser (ColorRefToARGB / color_to_argb / GDI), the lowest byte is Red, middle byte is Green,
 * and highest byte is Blue ($00BBGGRR).
 */
export function hexColor(c: string): string {
  if (!c) return '$000000';
  const m = c.replace('#', '').replace('$', '').padStart(6, '0').slice(0, 6).toUpperCase();
  const rr = m.slice(0, 2);
  const gg = m.slice(2, 4);
  const bb = m.slice(4, 6);
  return '$' + bb + gg + rr;
}

function num(v: string | number | boolean | undefined, def = 0): number {
  if (typeof v === 'number') return v;
  if (typeof v === 'boolean') return v ? 1 : 0;
  const n = parseInt(String(v ?? def), 10);
  return Number.isFinite(n) ? n : def;
}

function bool(v: unknown): boolean {
  return v === true || v === 'true' || v === 1 || v === '1';
}

function boolLit(v: unknown, lang: AvocadoLang): string {
  const b = bool(v);
  return lang === 'pl' ? (b ? 'prawda' : 'falsz') : (b ? 'true' : 'false');
}

/**
 * Computes a dark input background that is visibly darker than the window background.
 */
export function computeDarkerInputBg(formBg: string): { bgHex: string; bgPascal: string; textHex: string; textPascal: string } {
  const clean = (formBg || '#1E1E1E').replace('#', '').replace('$', '').padStart(6, '0').slice(0, 6);
  let numVal = parseInt(clean, 16);
  if (isNaN(numVal)) numVal = 0x1e1e1e;
  const r = (numVal >> 16) & 255;
  const g = (numVal >> 8) & 255;
  const b = numVal & 255;
  const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  const isDark = lum < 128;

  let dr: number, dg: number, db: number;
  if (isDark) {
    // 38% darker than form background, minimum level 14
    dr = Math.max(12, Math.round(r * 0.62));
    dg = Math.max(12, Math.round(g * 0.62));
    db = Math.max(12, Math.round(b * 0.62));
  } else {
    // Light form: darker control background
    dr = Math.max(0, Math.round(r * 0.85));
    dg = Math.max(0, Math.round(g * 0.85));
    db = Math.max(0, Math.round(b * 0.85));
  }

  const toHex = (n: number) => n.toString(16).padStart(2, '0').toUpperCase();
  const hex = `#${toHex(dr)}${toHex(dg)}${toHex(db)}`;
  // Win32 COLORREF is $BBGGRR
  const pascal = `$${toHex(db)}${toHex(dg)}${toHex(dr)}`;
  const textHex = isDark ? '#FFFFFF' : '#111111';
  const textPascal = isDark ? '$FFFFFF' : '$111111';

  return { bgHex: hex, bgPascal: pascal, textHex, textPascal };
}

function api(meta: FrameworkComponentMeta, lang: AvocadoLang): string {
  return lang === 'en' ? meta.createApiEn : meta.createApi;
}

const EVENT_API_PL: Record<string, string> = {
  set_on_click: 'reaguj_na_klikniecie',
  set_on_change: 'reaguj_na_zmiane',
  set_on_mouse_move: 'reaguj_na_ruch_myszy',
  set_on_mouse_down: 'reaguj_na_mysz_w_dol',
  set_on_lbutton_down: 'reaguj_na_lewy_w_dol',
  set_on_lbutton_up: 'reaguj_na_lewy_w_gore',
  set_on_lbutton_dbl_clk: 'reaguj_na_lewy_dwuklik',
  set_on_rbutton_down: 'reaguj_na_prawy_w_dol',
  set_on_rbutton_up: 'reaguj_na_prawy_w_gore',
  set_on_rbutton_dbl_clk: 'reaguj_na_prawy_dwuklik',
  set_on_key_down: 'reaguj_na_klawisz_w_dol',
  set_on_key_up: 'reaguj_na_klawisz_w_gore',
  set_on_set_focus: 'reaguj_na_ustawienie_fokusu',
  set_on_kill_focus: 'reaguj_na_utrate_fokusu',
  set_on_paint: 'reaguj_na_rysowanie',
  set_on_resize: 'reaguj_na_zmiane_rozmiaru',
  set_on_timer: 'reaguj_na_zegar',
  set_on_drop_files: 'reaguj_na_upuszczenie_plikow',
  set_on_close_query: 'reaguj_na_pytanie_o_zamkniecie',
};

function collectUnits(components: ComponentInstance[], form: FormModel): string[] {
  const units = new Set<string>(['avoraiser.window', 'avoraiser.layout', 'avoraiser.utils']);
  for (const c of components) {
    const meta = getComponentMeta(c.typeId);
    if (meta) units.add(meta.unit);
    if (c.events && Object.values(c.events).some(Boolean)) {
      units.add('avoraiser.events');
    }
  }
  return [...units].sort();
}

function createCall(meta: FrameworkComponentMeta, c: ComponentInstance, form: FormModel, lang: AvocadoLang): string {
  const x = num(c.x);
  const y = num(c.y);
  const w = num(c.w, meta.defaultSize.w);
  const h = num(c.h, meta.defaultSize.h);
  const name = sanitizeIdent(c.name, lang);
  const fn = api(meta, lang);
  const parent = c.parentId
    ? (lang === 'pl' ? 'okno_potomne' : 'child_window')
    : (lang === 'pl' ? 'moje_okno' : 'my_window');

  switch (meta.id) {
    case 'button':
      return `${name} = ${fn}(${parent}, ${q(String(c.props.Caption ?? meta.name))}, ${x}, ${y}, ${w}, ${h})`;

    case 'image-button': {
      const text = String(c.props.Caption ?? meta.name);
      const img = String(c.props.Image ?? '');
      return `${name} = ${fn}(${parent}, ${q(text)}, ${q(img)}, ${x}, ${y}, ${w}, ${h})`;
    }

    case 'edit': {
      const text = String(c.props.Text ?? '');
      return `${name} = ${fn}(${parent}, ${q(text)}, ${x}, ${y}, ${w}, ${h})`;
    }

    case 'label': {
      const text = String(c.props.Caption ?? meta.name);
      return `${name} = ${fn}(${parent}, ${q(text)}, ${x}, ${y}, ${w}, ${h})`;
    }

    case 'checkbox': {
      const text = String(c.props.Caption ?? meta.name);
      const color = hexColor(String(c.props.TextColor ?? '#FFFFFF'));
      return `${name} = ${fn}(${parent}, ${q(text)}, ${x}, ${y}, ${w}, ${h}, ${color})`;
    }

    case 'radio-button': {
      const text = String(c.props.Caption ?? meta.name);
      const id = num(c.props.Id, 1);
      return `${name} = ${fn}(${parent}, ${q(text)}, ${x}, ${y}, ${w}, ${h}, ${id})`;
    }

    case 'listbox':
    case 'memo':
    case 'trackbar':
    case 'progressbar':
    case 'spin-edit':
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h})`;

    case 'combobox': {
      const id = num(c.props.Id, 1);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${id})`;
    }

    case 'rich-edit': {
      const darker = computeDarkerInputBg(form.backgroundColor);
      const customBg = c.props.BackgroundColor ? hexColor(String(c.props.BackgroundColor)) : '';
      const bg = customBg && customBg !== '$FFFFFF' ? customBg : darker.bgPascal;
      const tx = c.props.TextColor ? hexColor(String(c.props.TextColor)) : darker.textPascal;
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${bg}, ${tx})`;
    }

    case 'panel': {
      const color = hexColor(String(c.props.Color ?? '#2A2A2A'));
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${color})`;
    }

    case 'group-box': {
      const text = String(c.props.Caption ?? meta.name);
      const color = hexColor(String(c.props.TextColor ?? '#FFFFFF'));
      return `${name} = ${fn}(${parent}, ${q(text)}, ${x}, ${y}, ${w}, ${h}, ${color})`;
    }

    case 'frame': {
      const color = hexColor(String(c.props.Color ?? '#808080'));
      const thickness = num(c.props.Thickness, 1);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${color}, ${thickness})`;
    }

    case 'line': {
      const color = hexColor(String(c.props.Color ?? '#808080'));
      const thickness = num(c.props.Thickness, 1);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${x + w}, ${y + h}, ${color}, ${thickness})`;
    }

    case 'circle-filled': {
      const color = hexColor(String(c.props.Color ?? '#66A0FF'));
      const diameter = num(c.props.Diameter, Math.max(w, h));
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${diameter}, ${color})`;
    }

    case 'circle-outline': {
      const color = hexColor(String(c.props.Color ?? '#66A0FF'));
      const diameter = num(c.props.Diameter, Math.max(w, h));
      const thickness = num(c.props.Thickness, 1);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${diameter}, ${color}, ${thickness})`;
    }

    case 'circle-image': {
      const img = String(c.props.Image ?? '');
      const size = num(c.props.Diameter, Math.max(w, h));
      return `${name} = ${fn}(${parent}, ${q(img)}, ${x}, ${y}, ${size})`;
    }

    case 'image-box': {
      const img = String(c.props.Image ?? '');
      return `${name} = ${fn}(${parent}, ${q(img)}, ${x}, ${y}, ${w}, ${h})`;
    }

    case 'gradient-panel': {
      const c1 = hexColor(String(c.props.ColorStart ?? '#1A365D'));
      const c2 = hexColor(String(c.props.ColorEnd ?? '#2B6CB0'));
      const dir = num(c.props.Direction, 1);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${c1}, ${c2}, ${dir})`;
    }

    case 'rounded-panel': {
      const color = hexColor(String(c.props.Color ?? '#2D3748'));
      const radius = num(c.props.Radius, 12);
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h}, ${color}, ${radius})`;
    }

    case 'rotated-image': {
      const img = String(c.props.Image ?? '');
      const angle = num(c.props.Angle, 0);
      return `${name} = ${fn}(${parent}, ${q(img)}, ${x}, ${y}, ${w}, ${h}, ${angle})`;
    }

    default:
      return `${name} = ${fn}(${parent}, ${x}, ${y}, ${w}, ${h})`;
  }
}

function postCreateCalls(c: ComponentInstance, meta: FrameworkComponentMeta, form: FormModel, lang: AvocadoLang): string[] {
  const out: string[] = [];
  const S = (pl: string, en: string) => (lang === 'en' ? en : pl);
  const name = sanitizeIdent(c.name, lang);
  const darker = computeDarkerInputBg(form.backgroundColor);

  // Button
  if (meta.id === 'button') {
    const n = hexColor(String(c.props.Color ?? '#2D2D2D'));
    const hv = hexColor(String(c.props.ColorHover ?? '#404040'));
    const pr = hexColor(String(c.props.ColorPressed ?? '#00AA00'));
    const tx = hexColor(String(c.props.ColorText ?? '#FFFFFF'));
    out.push(`${S('ustaw_kolory_przycisku', 'set_button_colors')}(${name}, ${n}, ${hv}, ${pr}, ${tx}, ${tx})`);
    if (c.props.Radius !== undefined)
      out.push(`${S('ustaw_promien_przycisku', 'set_button_radius')}(${name}, ${num(c.props.Radius, 8)})`);
    if (c.props.Id !== undefined)
      out.push(`${S('ustaw_id_przycisku', 'set_button_id')}(${name}, ${num(c.props.Id, 0)})`);
  }

  // Edit (must have dark background darker than form and custom text/bg color)
  if (meta.id === 'edit') {
    const rawBg = String(c.props.BackgroundColor ?? '');
    const bgCol = rawBg && rawBg.toUpperCase() !== '#141414' && rawBg.toUpperCase() !== '#FFFFFF'
      ? hexColor(rawBg)
      : darker.bgPascal;
    const txCol = c.props.TextColor
      ? hexColor(String(c.props.TextColor))
      : darker.textPascal;
    out.push(`${S('ustaw_kolor', 'set_color')}(${name}, ${bgCol})`);
    out.push(`${S('ustaw_kolor_tekstu_komponentu', 'set_component_text_color')}(${name}, ${txCol})`);
    if (bool(c.props.ReadOnly))
      out.push(`${S('ustaw_kontrolke_tylko_do_odczytu', 'set_control_read_only')}(${name}, ${boolLit(true, lang)})`);
    if (c.props.PasswordChar)
      out.push(`${S('ustaw_znak_hasla', 'set_edit_password_char')}(${name}, ${q(String(c.props.PasswordChar))})`);
    if (c.props.Placeholder)
      out.push(`${S('ustaw_tekst_zastepczy', 'set_edit_placeholder')}(${name}, ${q(String(c.props.Placeholder))})`);
    if (c.props.Alignment && c.props.Alignment !== 'left') {
      const alignVal = c.props.Alignment === 'center' ? 1 : 2;
      out.push(`${S('ustaw_wyrownanie_pola_edycji', 'set_edit_alignment')}(${name}, ${alignVal})`);
    }
  }

  // Label (text color support)
  if (meta.id === 'label' && c.props.TextColor) {
    out.push(`${S('ustaw_kolor_tekstu_komponentu', 'set_component_text_color')}(${name}, ${hexColor(String(c.props.TextColor))})`);
  }

  // Memo (darker background + custom text/bg color + set memo text support)
  if (meta.id === 'memo') {
    const rawBg = String(c.props.BackgroundColor ?? '');
    const bgCol = rawBg && rawBg.toUpperCase() !== '#141414' && rawBg.toUpperCase() !== '#FFFFFF'
      ? hexColor(rawBg)
      : darker.bgPascal;
    const txCol = c.props.TextColor
      ? hexColor(String(c.props.TextColor))
      : darker.textPascal;
    out.push(`${S('ustaw_kolor', 'set_color')}(${name}, ${bgCol})`);
    out.push(`${S('ustaw_kolor_tekstu_komponentu', 'set_component_text_color')}(${name}, ${txCol})`);
    if (c.props.Text) {
      out.push(`${S('ustaw_tekst_notatnika', 'set_memo_text')}(${name}, ${q(String(c.props.Text))})`);
    }
    if (bool(c.props.ReadOnly))
      out.push(`${S('ustaw_notatnik_tylko_do_odczytu', 'set_memo_read_only')}(${name}, ${boolLit(true, lang)})`);
  }

  // RichEdit (additional properties)
  if (meta.id === 'rich-edit') {
    if (bool(c.props.ReadOnly))
      out.push(`${S('ustaw_bogaty_tekst_tylko_do_odczytu', 'set_rich_text_read_only')}(${name}, ${boolLit(true, lang)})`);
    if (c.props.WordWrap !== undefined)
      out.push(`${S('ustaw_zawijanie_bogatego_tekstu', 'set_rich_text_word_wrap')}(${name}, ${boolLit(c.props.WordWrap, lang)})`);
    if (c.props.Border !== undefined)
      out.push(`${S('ustaw_ramke_bogatego_tekstu', 'set_rich_text_border')}(${name}, ${boolLit(c.props.Border, lang)})`);
  }

  // Trackbar
  if (meta.id === 'trackbar') {
    out.push(`${S('ustaw_zakres_suwaka', 'set_trackbar_range')}(${name}, ${num(c.props.Min, 0)}, ${num(c.props.Max, 100)})`);
    out.push(`${S('ustaw_pozycje_suwaka', 'set_trackbar_pos')}(${name}, ${num(c.props.Value, 0)})`);
    if (c.props.Step)
      out.push(`${S('ustaw_krok_suwaka', 'set_trackbar_step')}(${name}, ${num(c.props.Step, 1)})`);
  }

  // Progressbar
  if (meta.id === 'progressbar') {
    out.push(`${S('ustaw_wartosc_paska_postepu', 'set_progressbar_value')}(${name}, ${num(c.props.Value, 0)})`);
    if (c.props.Color)
      out.push(`${S('ustaw_kolor_paska_postepu', 'set_progressbar_color')}(${name}, ${hexColor(String(c.props.Color))})`);
    if (bool(c.props.ShowText))
      out.push(`${S('ustaw_pokazywanie_tekstu_paska_postepu', 'set_progressbar_show_text')}(${name}, ${boolLit(true, lang)})`);
  }

  // SpinEdit
  if (meta.id === 'spin-edit') {
    if (c.props.ArrowColor)
      out.push(`${S('ustaw_kolor_strzalki_pola_numerycznego', 'set_spin_arrow_color')}(${name}, ${hexColor(String(c.props.ArrowColor))})`);
    if (c.props.BgColor)
      out.push(`${S('ustaw_kolor_tla_pola_numerycznego', 'set_spin_background_color')}(${name}, ${hexColor(String(c.props.BgColor))})`);
  }

  // RadioButton
  if (meta.id === 'radio-button' && bool(c.props.Checked)) {
    out.push(`${S('ustaw_zaznaczenie_przycisku_opcji', 'set_radio_button_check')}(${name}, ${boolLit(true, lang)})`);
  }

  // RotatedImage
  if (meta.id === 'rotated-image' && c.props.Angle !== undefined && num(c.props.Angle) !== 0) {
    out.push(`${S('ustaw_kat_obrazu', 'set_image_angle')}(${name}, ${num(c.props.Angle)})`);
  }

  // FontSize
  if (c.props.FontSize) {
    const fontName = String(c.props.FontName ?? 'Segoe UI');
    out.push(`${S('ustaw_rozmiar_czcionki_komponentu', 'set_component_size_font')}(${name}, ${q(fontName)}, ${num(c.props.FontSize, 9)})`);
  }

  return out;
}

function windowParams(form: FormModel, lang: AvocadoLang): string[] {
  const L: string[] = [];
  const S = (pl: string, en: string) => (lang === 'en' ? en : pl);
  const typeName = S('parametry_ui', 'ui_parameters');
  const defFn = S('domyslne_parametry_okna()', 'default_window_params()');
  L.push(`  ${typeName} ui`);
  L.push(`  ui = ${defFn}`);
  L.push(`  ui.title = ${q(form.title)}`);
  L.push(`  ui.width = ${form.width}`);
  L.push(`  ui.height = ${form.height}`);
  L.push(`  ui.visible = ${boolLit(form.visible, lang)}`);
  if (form.frameless) L.push(`  ui.frameless = ${boolLit(true, lang)}`);
  if (!form.allowDrag) L.push(`  ui.allowdrag = ${boolLit(false, lang)}`);
  if (!form.allowMaximize) L.push(`  ui.allowmaximize = ${boolLit(false, lang)}`);
  L.push(`  ui.backgroundcolor = ${hexColor(form.backgroundColor)}`);
  return L;
}

function windowSetup(form: FormModel, handle: string, lang: AvocadoLang): string[] {
  const S = (pl: string, en: string) => (lang === 'en' ? en : pl);
  const L: string[] = [];
  L.push(`    ${S('ustaw_przycisk_maksymalizacji_okna', 'set_window_maximize_button')}(${handle}, ${boolLit(form.allowMaximize, lang)})`);
  if (form.darkMode) {
    L.push(`    ${S('ustaw_ciemny_motyw', 'set_dark_mode')}(${handle}, ${boolLit(true, lang)})`);
    L.push(`    ${S('ustaw_cien_okna', 'set_window_shadow')}(${handle}, ${boolLit(true, lang)})`);
  }
  L.push(`    ${S('ustaw_kolor_naglowka', 'set_caption_color')}(${handle}, ${hexColor(form.backgroundColor)})`);
  if (form.opacity < 255)
    L.push(`    ${S('ustaw_przezroczystosc', 'set_opacity')}(${handle}, ${form.opacity})`);
  if (form.onTop)
    L.push(`    ${S('ustaw_zawsze_na_wierzchu', 'set_always_on_top')}(${handle}, ${boolLit(true, lang)})`);
  if (form.centerWindow)
    L.push(`    ${S('wysrodkuj_okno', 'center_window')}(${handle})`);
  return L;
}

/** Generate Avocado source for one form (main or child window). */
export function generateAvocadoForm(project: ProjectModel, form: FormModel): string {
  const lang: AvocadoLang = project.settings.codeLang || 'pl';
  const S = (pl: string, en: string) => (lang === 'en' ? en : pl);
  const comps = [...form.components].sort((a, b) => a.zIndex - b.zIndex || a.name.localeCompare(b.name));
  const visualComps = comps.filter((c) => !isServiceId(c.typeId));
  const serviceComps = comps.filter((c) => isServiceId(c.typeId));
  const units = collectUnits(comps, form);
  const handleType = S('uchwyt_okna', 'hwnd');
  const mainHandle = S('moje_okno', 'my_window');
  const childHandle = S('okno_potomne', 'child_window');
  const handle = form.isChild ? childHandle : mainHandle;
  const L: string[] = [];

  const progName = sanitizeIdent(project.projectName, lang);

  L.push(`// ${S('Wygenerowano przez Avocado GUI Builder', 'Generated by Avocado GUI Builder')}`);
  L.push(`// Framework: Avoraiser/Avocado · ${S('język: polski', 'language: English')}`);
  L.push(`program_ui ${progName}`);
  L.push('');
  for (const u of units) {
    L.push(`${S('importuj', 'import')} ${u}`);
  }
  L.push('');
  if (form.isChild) L.push(`${handleType} ${childHandle}`);
  L.push(`${handleType} ${handle}`);
  for (const c of visualComps) {
    L.push(`${handleType} ${sanitizeIdent(c.name, lang)}`);
  }
  L.push('');
  L.push(S('glowny', 'main'));
  L.push(`  ${S('utworz_glowne_okno()', 'create_main_window()')}`);
  L.push(`  ${S('uruchom_aplikacje()', 'run_app()')}`);
  L.push(S('koniec.', 'end.'));
  L.push('');

  // main window procedure
  L.push(`${S('procedura', 'procedure')} ${S('utworz_glowne_okno', 'create_main_window')}`);
  L.push(S('poczatek', 'start'));
  L.push(...windowParams(form, lang));
  L.push('');
  L.push(`  ${handle} = ${S('utworz_okno', 'create_window')}(ui)`);
  L.push(`  ${S('jezeli', 'if')} ${handle} <> 0 ${S('wtedy', 'then')}`);
  L.push(S('  poczatek', '  start'));
  L.push(...windowSetup(form, handle, lang));
  L.push('');

  // If service-webview is on the form, initialize browser
  if (serviceComps.some((c) => c.typeId === 'service-webview')) {
    L.push(`    ${S('przegladarka_stworz', 'webview_create')}(${handle})`);
  }

  for (const c of visualComps) {
    const meta = getComponentMeta(c.typeId);
    if (!meta) {
      L.push(`    // ${S('NIEOBSŁUGIWANY', 'UNSUPPORTED')}: ${c.typeId} (${c.name})`);
      continue;
    }
    L.push(`    ${createCall(meta, c, form, lang)}`);
    for (const line of postCreateCalls(c, meta, form, lang)) {
      L.push(`    ${line}`);
    }
    for (const [evName, rawHandler] of Object.entries(c.events || {})) {
      if (!rawHandler) continue;
      const handler = sanitizeIdent(rawHandler, lang);
      const evMeta = meta.events.find((e) => e.name === evName);
      if (evMeta?.registerApi) {
        const apiEn = evMeta.registerApi;
        const reg = lang === 'en' ? apiEn : (EVENT_API_PL[apiEn] || apiEn);
        const cName = sanitizeIdent(c.name, lang);
        L.push(`    ${reg}(${cName}, @${handler})`);
      }
    }
    const items = String(c.props.Items ?? '');
    if (items && (meta.id === 'listbox' || meta.id === 'combobox')) {
      const cName = sanitizeIdent(c.name, lang);
      for (const item of items.split('\n').filter(Boolean)) {
        if (meta.id === 'listbox')
          L.push(`    ${S('dodaj_do_listy_wyboru', 'list_add')}(${cName}, ${q(item)})`);
        else
          L.push(`    ${S('dodaj_element_listy_rozwijanej', 'add_item_combo_box')}(${cName}, ${q(item)})`);
      }
    }
  }

  L.push(S('  koniec', '  end'));
  L.push(S('koniec', 'end'));

  // child windows
  const children = project.forms.filter((f) => f.isChild);
  for (const ch of children) {
    const chVisualComps = ch.components.filter((c) => !isServiceId(c.typeId));
    L.push('');
    L.push(`// --- ${S('okno potomne', 'child window')}: ${ch.title} ---`);
    L.push(`${S('procedura', 'procedure')} ${S('pokaz_okno_potomne', 'show_child_window')}_${sanitizeIdent(ch.name, lang)}`);
    L.push(S('poczatek', 'start'));
    L.push(...windowParams(ch, lang));
    L.push(`  ${childHandle} = ${S('utworz_okno', 'create_window')}(ui)`);
    L.push(`  ${S('jezeli', 'if')} ${childHandle} <> 0 ${S('wtedy', 'then')}`);
    L.push(S('  poczatek', '  start'));
    L.push(...windowSetup(ch, childHandle, lang));
    for (const c of chVisualComps) {
      const meta = getComponentMeta(c.typeId);
      if (!meta) continue;
      L.push(`    ${createCall(meta, c, ch, lang)}`);
      for (const line of postCreateCalls(c, meta, ch, lang)) {
        L.push(`    ${line}`);
      }
    }
    L.push(S('  koniec', '  end'));
    L.push(S('koniec', 'end'));
  }

  // event handlers
  const handlers = new Map<string, { comp: ComponentInstance; ev: string }>();
  for (const c of visualComps) {
    for (const [evName, rawHandler] of Object.entries(c.events || {})) {
      if (rawHandler) {
        const handler = sanitizeIdent(rawHandler, lang);
        handlers.set(handler, { comp: c, ev: evName });
      }
    }
  }
  if (handlers.size) {
    L.push('');
    const senderParam = S('nadawca', 'sender');
    for (const [handler, info] of handlers) {
      const cName = sanitizeIdent(info.comp.name, lang);
      L.push(`${S('procedura', 'procedure')} ${handler}(${senderParam}: ${handleType})`);
      L.push(S('poczatek', 'start'));
      const user = project.userCode[handler] || project.userCode[rawHandlerFrom(info.comp, info.ev)];
      if (user) {
        L.push(user.split('\n').map((l) => '  ' + l).join('\n'));
      } else {
        L.push(`  // TODO: ${info.ev} -> ${cName}`);
      }
      L.push(S('koniec', 'end'));
      L.push('');
    }
  }

  return L.join('\n') + '\n';
}

function rawHandlerFrom(comp: ComponentInstance, ev: string): string {
  return comp.events?.[ev] ?? '';
}

export function generateAvocadoSource(project: ProjectModel, form: FormModel): string {
  return generateAvocadoForm(project, form);
}

export function listEventHandlers(form: FormModel): { name: string; component: string; event: string }[] {
  const out: { name: string; component: string; event: string }[] = [];
  for (const c of form.components) {
    for (const [ev, handler] of Object.entries(c.events || {})) {
      if (handler) out.push({ name: handler, component: c.name, event: ev });
    }
  }
  return out;
}

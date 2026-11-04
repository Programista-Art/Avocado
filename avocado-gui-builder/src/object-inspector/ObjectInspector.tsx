import { useAppStore } from '@/state/store';
import { getComponentMeta } from '@/framework/metadata';
import { avocadoEvents, eventLabel, eventDesc, eventsFor } from '@/framework/events';
import { t, type Lang } from '@/i18n';
import { CodeEditorDialog } from '@/components/CodeEditorDialog';
import { useState } from 'react';
import type { FrameworkPropertyMeta, PrimitiveType } from '@/types';

const EVENT_SUFFIX_PL: Record<string, string> = {
  set_on_click: 'klikniecie',
  set_on_change: 'zmiana',
  set_on_mouse_move: 'ruch_myszy',
  set_on_mouse_down: 'mysz_w_dol',
  set_on_lbutton_down: 'lewy_w_dol',
  set_on_lbutton_up: 'lewy_w_gore',
  set_on_lbutton_dbl_clk: 'lewy_dwuklik',
  set_on_rbutton_down: 'prawy_w_dol',
  set_on_rbutton_up: 'prawy_w_gore',
  set_on_rbutton_dbl_clk: 'prawy_dwuklik',
  set_on_key_down: 'klawisz_w_dol',
  set_on_key_up: 'klawisz_w_gore',
  set_on_set_focus: 'ustawienie_fokusu',
  set_on_kill_focus: 'utrata_fokusu',
  set_on_paint: 'rysowanie',
  set_on_resize: 'zmiana_rozmiaru',
  set_on_timer: 'zegar',
  set_on_drop_files: 'upuszczenie_plikow',
  set_on_close_query: 'zamkniecie',
};

const EVENT_SUFFIX_EN: Record<string, string> = {
  set_on_click: 'on_click',
  set_on_change: 'on_change',
  set_on_mouse_move: 'on_mouse_move',
  set_on_mouse_down: 'on_mouse_down',
  set_on_lbutton_down: 'on_lbutton_down',
  set_on_lbutton_up: 'on_lbutton_up',
  set_on_lbutton_dbl_clk: 'on_lbutton_dbl_clk',
  set_on_rbutton_down: 'on_rbutton_down',
  set_on_rbutton_up: 'on_rbutton_up',
  set_on_rbutton_dbl_clk: 'on_rbutton_dbl_clk',
  set_on_key_down: 'on_key_down',
  set_on_key_up: 'on_key_up',
  set_on_set_focus: 'on_set_focus',
  set_on_kill_focus: 'on_kill_focus',
  set_on_paint: 'on_paint',
  set_on_resize: 'on_resize',
  set_on_timer: 'on_timer',
  set_on_drop_files: 'on_drop_files',
  set_on_close_query: 'on_close_query',
};

export function ObjectInspector({ lang, eventsOnly = false }: { lang: Lang; eventsOnly?: boolean }) {
  const [editHandler, setEditHandler] = useState<string | null>(null);
  const form = useAppStore((s) => s.getForm());
  const selectedIds = useAppStore((s) => s.selectedIds);
  const codeLang = useAppStore((s) => s.project.settings.codeLang) || 'pl';
  const setProp = useAppStore((s) => s.setProp);
  const setEvent = useAppStore((s) => s.setEvent);
  const updateForm = useAppStore((s) => s.updateForm);
  const userCode = useAppStore((s) => s.project.userCode);
  const setUserCode = useAppStore((s) => s.setUserCode);

  const comp = form?.components.find((c) => c.id === selectedIds[0]);

  if (!form) return <div className="empty">{t(lang, 'empty.noForm')}</div>;

  if (!comp) {
    return (
      <div>
        <div className="panel-header">Form · {form.name}</div>
        <PropRow label={t(lang, 'props.name')} value={form.name} onChange={(v) => updateForm({ name: String(v) })} type="string" />
        <PropRow label="Title" value={form.title} onChange={(v) => updateForm({ title: String(v) })} type="string" />
        <PropRow label={t(lang, 'props.width')} value={form.width} onChange={(v) => updateForm({ width: Number(v) })} type="integer" />
        <PropRow label={t(lang, 'props.height')} value={form.height} onChange={(v) => updateForm({ height: Number(v) })} type="integer" />
        <PropRow label="Bg" value={form.backgroundColor} onChange={(v) => updateForm({ backgroundColor: String(v) })} type="color" />
        <PropRow label="Frameless" value={form.frameless} onChange={(v) => updateForm({ frameless: v === true || v === 'true' })} type="boolean" />
        <PropRow label="Maximize" value={form.allowMaximize} onChange={(v) => updateForm({ allowMaximize: v === true || v === 'true' })} type="boolean" />
        <PropRow label="Drag" value={form.allowDrag} onChange={(v) => updateForm({ allowDrag: v === true || v === 'true' })} type="boolean" />
        <PropRow label="Center" value={form.centerWindow} onChange={(v) => updateForm({ centerWindow: v === true || v === 'true' })} type="boolean" />
        <PropRow label="OnTop" value={form.onTop} onChange={(v) => updateForm({ onTop: v === true || v === 'true' })} type="boolean" />
        <PropRow label="Dark" value={form.darkMode} onChange={(v) => updateForm({ darkMode: v === true || v === 'true' })} type="boolean" />
        <PropRow label="Opacity" value={form.opacity} onChange={(v) => updateForm({ opacity: Number(v) })} type="integer" />
        <div className="empty">{t(lang, 'empty.noSelection')}</div>
      </div>
    );
  }

  const meta = getComponentMeta(comp.typeId);
  if (!meta) return <div className="empty">{comp.typeId}</div>;

  // full event list for this component kind
  const kindHint = meta.id + ' ' + meta.category.toLowerCase();
  const evList = eventsFor(kindHint);

  return (
    <div>
      <div className="panel-header">
        <span className="comp-ico">{meta.icon}</span> {meta.name}
        <span className="mono muted">{comp.name}</span>
      </div>
      {!eventsOnly && (
        <>
          <PropRow
            label={t(lang, 'props.name')}
            value={comp.name}
            onChange={(v) => useAppStore.getState().renameComponent(comp.id, String(v))}
            type="string"
          />
          <PropRow label="X" value={comp.x} onChange={(v) => useAppStore.getState().moveComponent(comp.id, Number(v), comp.y)} type="integer" />
          <PropRow label="Y" value={comp.y} onChange={(v) => useAppStore.getState().moveComponent(comp.id, comp.x, Number(v))} type="integer" />
          <PropRow label="W" value={comp.w} onChange={(v) => useAppStore.getState().resizeComponent(comp.id, Number(v), comp.h)} type="integer" />
          <PropRow label="H" value={comp.h} onChange={(v) => useAppStore.getState().resizeComponent(comp.id, comp.w, Number(v))} type="integer" />
          {meta.properties.map((p) => (
            <PropRow
              key={p.name}
              label={lang === 'pl' ? p.descriptionPl || p.name : p.name}
              value={comp.props[p.name] ?? ''}
              type={p.type}
              enumValues={p.enumValues}
              lang={lang}
              previewUrl={p.type === 'image' ? String(comp.props._imagePreview || '') : undefined}
              onChange={(v) => setProp(comp.id, p.name, v)}
              onPreviewChange={
                p.type === 'image'
                  ? (dataUrl, fileName) => {
                      setProp(comp.id, '_imagePreview', dataUrl);
                      if (fileName !== undefined) setProp(comp.id, p.name, fileName);
                    }
                  : undefined
              }
            />
          ))}
          <div className="row muted mono" style={{ fontSize: 10 }}>
            {meta.createApi} · {meta.unit}
          </div>
        </>
      )}

      <div className="panel-header" style={{ marginTop: 8 }}>
        {t(lang, 'panels.events')} ({evList.length})
      </div>
      <div className="ev-list">
        {evList.map((ev) => {
          const handler = comp.events[ev.api] ?? '';
          const hasCode = Boolean((userCode[handler] ?? '').trim());
          return (
            <div
              key={ev.api}
              className={`ev-row ${hasCode ? 'ev-has-code' : ''}`}
              title={eventDesc(ev, lang)}
            >
              <div className="ev-label">
                <strong>{eventLabel(ev, lang)}</strong>
                <span className="muted mono">{ev.api}</span>
              </div>
              <div className="ev-input">
                <input
                  value={handler}
                  placeholder={t(lang, 'actions.addEvent')}
                  onChange={(e) => setEvent(comp.id, ev.api, e.target.value)}
                />
                <button
                  className="icon-btn"
                  title={t(lang, 'actions.generateHandler')}
                  onClick={() => {
                    const suffix = (codeLang === 'pl' ? EVENT_SUFFIX_PL[ev.api] : EVENT_SUFFIX_EN[ev.api]) || ev.id.replace('set_on_', '');
                    const name = handler || `${comp.name}_${suffix}`;
                    setEvent(comp.id, ev.api, name);
                    if (!useAppStore.getState().project.userCode[name])
                      useAppStore.getState().setUserCode(name, `// ${eventLabel(ev, lang)} — ${comp.name}`);
                  }}
                >
                  ✚
                </button>
                <button
                  className="icon-btn"
                  title={t(lang, 'actions.openHandler')}
                  disabled={!handler}
                  onClick={() => setEditHandler(handler)}
                >
                  ✎
                </button>
                <button
                  className="icon-btn danger"
                  title={t(lang, 'actions.removeEvent')}
                  disabled={!handler}
                  onClick={() => setEvent(comp.id, ev.api, '')}
                >
                  ×
                </button>
              </div>
              <div className="ev-desc muted">
                {eventDesc(ev, lang)}
                {hasCode && <span className="ev-code-badge">● {lang === 'pl' ? 'kod' : 'code'}</span>}
              </div>
            </div>
          );
        })}
      </div>
      {editHandler && (
        <CodeEditorDialog
          handlerName={editHandler}
          initialCode={userCode[editHandler] ?? ''}
          lang={lang}
          onSave={(code) => setUserCode(editHandler, code)}
          onClose={() => setEditHandler(null)}
        />
      )}
    </div>
  );
}

function PropRow({
  label,
  value,
  type,
  enumValues,
  lang = 'pl',
  previewUrl,
  onChange,
  onPreviewChange,
}: {
  label: string;
  value: string | number | boolean;
  type: PrimitiveType | string;
  enumValues?: string[];
  lang?: Lang;
  previewUrl?: string;
  onChange: (v: string | number | boolean) => void;
  onPreviewChange?: (dataUrl: string, fileName?: string) => void;
}) {
  const handlePickImage = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*,.png,.jpg,.jpeg,.bmp,.gif,.webp,.ico';
    input.onchange = () => {
      const file = input.files?.[0];
      if (!file) return;
      const filePath = (file as unknown as { path?: string }).path || file.name;
      const reader = new FileReader();
      reader.onload = () => {
        const dataUrl = typeof reader.result === 'string' ? reader.result : '';
        if (onPreviewChange) {
          onPreviewChange(dataUrl, filePath);
        } else {
          onChange(filePath);
        }
      };
      reader.readAsDataURL(file);
    };
    input.click();
  };

  return (
    <div className="prop-row">
      <label title={label}>{label}</label>
      {type === 'boolean' ? (
        <select value={value === true || value === 'true' ? 'true' : 'false'} onChange={(e) => onChange(e.target.value === 'true')}>
          <option value="true">True</option>
          <option value="false">False</option>
        </select>
      ) : type === 'color' ? (
        <div className="color-wrap">
          <input type="color" className="color-picker" value={normalizeColor(String(value))} onChange={(e) => onChange(e.target.value)} />
          <input
            type="text"
            className="mono"
            style={{ width: 82, padding: '4px 6px' }}
            value={String(value)}
            onChange={(e) => onChange(e.target.value)}
          />
        </div>
      ) : type === 'image' ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
            <input
              style={{ flex: 1, minWidth: 0 }}
              value={String(value)}
              placeholder={lang === 'pl' ? 'np. obrazek.png' : 'e.g. image.png'}
              onChange={(e) => onChange(e.target.value)}
            />
            {(Boolean(value) || Boolean(previewUrl)) && (
              <button
                type="button"
                className="icon-btn danger"
                title={lang === 'pl' ? 'Wyczyść obraz' : 'Clear image'}
                onClick={() => {
                  if (onPreviewChange) onPreviewChange('', '');
                  else onChange('');
                }}
              >
                ×
              </button>
            )}
          </div>
          <button
            type="button"
            onClick={handlePickImage}
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, width: '100%', padding: '5px 8px', fontWeight: 600 }}
          >
            📂 {lang === 'pl' ? 'Wgraj zdjęcie z komputera...' : 'Upload image from PC...'}
          </button>
        </div>
      ) : type === 'enum' && enumValues ? (
        <select value={String(value)} onChange={(e) => onChange(e.target.value)}>
          {enumValues.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      ) : type === 'integer' || type === 'float' ? (
        <input type="number" value={Number(value)} onChange={(e) => onChange(Number(e.target.value))} />
      ) : type === 'list' ? (
        <textarea rows={3} value={String(value)} onChange={(e) => onChange(e.target.value)} />
      ) : (
        <input value={String(value)} onChange={(e) => onChange(e.target.value)} />
      )}
    </div>
  );
}

function normalizeColor(v: string): string {
  if (/^#[0-9a-fA-F]{6}$/.test(v)) return v;
  if (/^[0-9a-fA-F]{6}$/.test(v)) return '#' + v;
  return '#202020';
}

export { avocadoEvents };

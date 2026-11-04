import { useMemo, useState } from 'react';
import { useAppStore } from '@/state/store';
import { getComponentMeta } from '@/framework/metadata';
import { t, type Lang } from '@/i18n';

const ICONS: Record<string, string> = {
  button: '🔘',
  'image-button': '🖼️',
  edit: '✏️',
  label: '🏷️',
  checkbox: '☑️',
  'radio-button': '🔘',
  listbox: '📋',
  combobox: '▾',
  memo: '📝',
  'rich-edit': '📖',
  trackbar: '🎚️',
  progressbar: '📊',
  'spin-edit': '#️⃣',
  panel: '▭',
  'group-box': '🗂️',
  frame: '⬜',
  'image-box': '🖼️',
  'circle-filled': '⬤',
  'rounded-panel': '▢',
};

export function HierarchyPanel({ lang }: { lang: Lang }) {
  const form = useAppStore((s) => s.getForm());
  const selectedIds = useAppStore((s) => s.selectedIds);
  const select = useAppStore((s) => s.select);
  const renameComponent = useAppStore((s) => s.renameComponent);
  const requestDelete = useAppStore((s) => s.requestDelete);
  const [q, setQ] = useState('');

  const comps = useMemo(() => {
    const list = form?.components.slice().sort((a, b) => a.zIndex - b.zIndex || a.name.localeCompare(b.name)) ?? [];
    const needle = q.trim().toLowerCase();
    if (!needle) return list;
    return list.filter(
      (c) =>
        c.name.toLowerCase().includes(needle) ||
        c.typeId.toLowerCase().includes(needle) ||
        (getComponentMeta(c.typeId)?.name ?? '').toLowerCase().includes(needle),
    );
  }, [form?.components, q]);

  if (!form) return <div className="empty">{t(lang, 'empty.noForm')}</div>;

  return (
    <div>
      <div className="hier-search">
        <input
          style={{ width: '100%' }}
          placeholder={lang === 'pl' ? 'Szukaj w hierarchii…' : 'Search hierarchy…'}
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>
      <div
        className={`tree-item ${selectedIds.length === 0 ? 'selected' : ''}`}
        onClick={() => select([])}
      >
        <span>🪟</span>
        <strong>{form.name}</strong>
        <span className="type">
          {form.isChild ? 'child' : 'main'} · {form.width}×{form.height}
        </span>
      </div>
      {comps.map((c) => {
        const meta = getComponentMeta(c.typeId);
        return (
          <div
            key={c.id}
            className={`tree-item ${selectedIds.includes(c.id) ? 'selected' : ''}`}
            style={{ paddingLeft: 16 }}
            onClick={() => select([c.id])}
            title={lang === 'pl' ? meta?.descriptionPl : meta?.description}
          >
            <span>{ICONS[c.typeId] ?? '▣'}</span>
            <input
              value={c.name}
              onChange={(e) => renameComponent(c.id, e.target.value)}
              style={{ width: 110, padding: '1px 4px', fontSize: 11 }}
              onMouseDown={(e) => e.stopPropagation()}
            />
            <span className="type">{meta?.name ?? c.typeId}</span>
          </div>
        );
      })}
      {!form.components.length && <div className="empty">{t(lang, 'empty.noComponents')}</div>}
      {selectedIds.length > 0 && (
        <div className="row">
          <button className="danger" onClick={() => requestDelete()}>
            {t(lang, 'actions.delete')}
          </button>
        </div>
      )}
    </div>
  );
}

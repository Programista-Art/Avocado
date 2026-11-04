import { useMemo, useState } from 'react';
import { frameworkMeta } from '@/framework/metadata';
import { useAppStore } from '@/state/store';
import { t, type Lang } from '@/i18n';
import type { ComponentCategory } from '@/types';

const CATS: ComponentCategory[] = [
  'Windows',
  'Buttons',
  'Input Controls',
  'Text and Labels',
  'Lists',
  'Containers',
  'Graphics',
  'Images',
  'Basic Controls',
  'Custom Components',
  'Layout',
  'Dialogs',
];

/** simple icon per component id */
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
  'circle-outline': '◯',
  'circle-image': '🖼️',
  'gradient-panel': '▦',
  'rounded-panel': '▢',
  line: '╱',
  'rotated-image': '🔄',
  'service-clipboard': '📋',
  'service-crypto': '🔐',
  'service-webview': '🌐',
  'service-printer': '🖨️',
  'service-dialogs': '💬',
  'service-system': '⚙️',
};

export function Toolbox({ lang }: { lang: Lang }) {
  const query = useAppStore((s) => s.toolboxQuery);
  const setQuery = useAppStore((s) => s.setToolboxQuery);
  const addComponent = useAppStore((s) => s.addComponent);

  const items = useMemo(() => {
    const q = query.trim().toLowerCase();
    return frameworkMeta.components.filter((c) => {
      if (!q) return true;
      return (
        c.name.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q) ||
        c.descriptionPl.toLowerCase().includes(q) ||
        c.createApi.includes(q) ||
        c.category.toLowerCase().includes(q)
      );
    });
  }, [query]);

  const byCat = useMemo(() => {
    const m = new Map<ComponentCategory, typeof items>();
    for (const c of items) {
      const arr = m.get(c.category) ?? [];
      arr.push(c);
      m.set(c.category, arr);
    }
    return m;
  }, [items]);

  return (
    <div>
      <div className="toolbox-search-sticky">
        <input
          style={{ width: '100%' }}
          placeholder={t(lang, 'search')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <div className="toolbox-cat">{lang === 'pl' ? 'Komponenty' : 'Components'}</div>
      {CATS.map((cat) => {
        const list = byCat.get(cat);
        if (!list?.length) return null;
        return (
          <div key={cat}>
            <div className="toolbox-cat">{cat}</div>
            {list.map((c) => (
              <div
                key={c.id}
                className="toolbox-item"
                draggable
                title={`${lang === 'pl' ? c.descriptionPl : c.description}\n${c.createApi} (${c.unit})\n${c.properties.length} props · ${c.events.length} events`}
                onDragStart={(e) => {
                  e.dataTransfer.setData('text/avocado-type', c.id);
                  e.dataTransfer.effectAllowed = 'copy';
                }}
                onDoubleClick={() => addComponent(c.id, 40 + Math.random() * 80, 40 + Math.random() * 80)}
              >
                <div className="ico">{ICONS[c.id] ?? '▣'}</div>
                <div>
                  <div className="t-name">{c.name}</div>
                  <div className="t-api">{c.createApi}</div>
                </div>
              </div>
            ))}
          </div>
        );
      })}
      {!items.length && <div className="empty">—</div>}
    </div>
  );
}

import { useMemo } from 'react';
import { useAppStore } from '@/state/store';
import type { Lang } from '@/i18n';

export function CodePanel({ lang }: { lang: Lang }) {
  const code = useAppStore((s) => s.generatedCode);
  const selectedIds = useAppStore((s) => s.selectedIds);
  const form = useAppStore((s) => s.getForm());
  const setUserCode = useAppStore((s) => s.setUserCode);

  const lines = useMemo(() => code.split('\n'), [code]);
  const handlers = useMemo(() => {
    const out: { name: string; code: string }[] = [];
    if (!form) return out;
    for (const c of form.components) {
      for (const h of Object.values(c.events || {})) {
        if (h) out.push({ name: h, code: useAppStore.getState().project.userCode[h] ?? '' });
      }
    }
    return out;
  }, [form, code]);

  // highlight lines that mention selected component
  const selNames = useMemo(() => {
    if (!form) return new Set<string>();
    return new Set(form.components.filter((c) => selectedIds.includes(c.id)).map((c) => c.name));
  }, [form, selectedIds]);

  return (
    <div style={{ display: 'flex', flex: 1, minHeight: 0 }}>
      <div className="code-view" style={{ flex: 1 }}>
        {lines.map((line, i) => {
          const hit = [...selNames].some((n) => line.includes(n));
          return (
            <div key={i} className="code-line" style={hit ? { background: 'rgba(14,99,156,0.25)' } : undefined}>
              <span className="ln">{i + 1}</span>
              <span>{line}</span>
            </div>
          );
        })}
      </div>
      {handlers.length > 0 && (
        <div style={{ width: 280, borderLeft: '1px solid var(--border)', overflow: 'auto', background: 'var(--bg-panel)' }}>
          <div className="panel-header">Event handlers</div>
          {handlers.map((h) => (
            <div key={h.name} style={{ padding: 8, borderBottom: '1px solid var(--border)' }}>
              <div className="mono" style={{ marginBottom: 4 }}>{h.name}</div>
              <textarea
                style={{ width: '100%', height: 80, fontFamily: 'var(--mono)', fontSize: 11 }}
                value={h.code}
                onChange={(e) => setUserCode(h.name, e.target.value)}
              />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

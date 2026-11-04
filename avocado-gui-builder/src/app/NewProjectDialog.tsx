import { useState } from 'react';
import { createEmptyProject, type ProjectModel } from '@/types';
import { t, type Lang } from '@/i18n';

export interface NewProjectOpts {
  name: string;
  width: number;
  height: number;
  title: string;
  backgroundColor: string;
  opacity: number;
  center: boolean;
  onTop: boolean;
  frameless: boolean;
  darkMode: boolean;
  allowMaximize: boolean;
  codeLang: 'pl' | 'en';
}

export function NewProjectDialog({
  lang,
  onConfirm,
  onCancel,
}: {
  lang: Lang;
  onConfirm: (p: ProjectModel) => void;
  onCancel: () => void;
}) {
  const [opts, setOpts] = useState<NewProjectOpts>({
    name: 'MojaAplikacja',
    width: 640,
    height: 480,
    title: 'Moja aplikacja Avocado',
    backgroundColor: '#202020',
    opacity: 255,
    center: true,
    onTop: false,
    frameless: false,
    darkMode: false,
    allowMaximize: true,
    codeLang: 'pl',
  });

  const set = <K extends keyof NewProjectOpts>(k: K, v: NewProjectOpts[K]) =>
    setOpts((o) => ({ ...o, [k]: v }));

  const create = () => {
    const p = createEmptyProject(opts.name);
    const f = p.forms[0];
    f.name = opts.name + 'Form';
    f.title = opts.title;
    f.width = opts.width;
    f.height = opts.height;
    f.backgroundColor = opts.backgroundColor;
    f.opacity = opts.opacity;
    f.centerWindow = opts.center;
    f.onTop = opts.onTop;
    f.frameless = opts.frameless;
    f.darkMode = opts.darkMode;
    f.allowMaximize = opts.allowMaximize;
    p.settings.codeLang = opts.codeLang;
    p.settings.projectName = opts.name;
    p.projectName = opts.name;
    onConfirm(p);
  };

  const L = (k: string) => t(lang, k);

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.55)',
        display: 'grid',
        placeItems: 'center',
        zIndex: 9999,
      }}
      onClick={onCancel}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: 460,
          background: 'var(--bg-panel)',
          border: '1px solid var(--border)',
          borderRadius: 8,
          boxShadow: '0 24px 64px rgba(0,0,0,0.5)',
          padding: 20,
        }}
      >
        <h2 style={{ fontSize: 16, marginBottom: 14 }}>{L('dialog.newProjectTitle')}</h2>

        <Field label={L('dialog.appName')}>
          <input value={opts.name} onChange={(e) => set('name', e.target.value)} autoFocus />
        </Field>
        <Field label={L('dialog.windowTitle')}>
          <input value={opts.title} onChange={(e) => set('title', e.target.value)} />
        </Field>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label={L('dialog.width')}>
            <input type="number" value={opts.width} onChange={(e) => set('width', Number(e.target.value))} />
          </Field>
          <Field label={L('dialog.height')}>
            <input type="number" value={opts.height} onChange={(e) => set('height', Number(e.target.value))} />
          </Field>
        </div>
        <Field label={L('dialog.bgColor')}>
          <input type="color" value={opts.backgroundColor} onChange={(e) => set('backgroundColor', e.target.value)} />
        </Field>
        <Field label={`${L('dialog.opacity')} (0–255)`}>
          <input
            type="number"
            min={0}
            max={255}
            value={opts.opacity}
            onChange={(e) => set('opacity', Math.min(255, Math.max(0, Number(e.target.value))))}
          />
        </Field>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, margin: '12px 0' }}>
          <Check label={L('dialog.center')} checked={opts.center} onChange={(v) => set('center', v)} />
          <Check label={L('dialog.onTop')} checked={opts.onTop} onChange={(v) => set('onTop', v)} />
          <Check label={L('dialog.frameless')} checked={opts.frameless} onChange={(v) => set('frameless', v)} />
          <Check label={L('dialog.dark')} checked={opts.darkMode} onChange={(v) => set('darkMode', v)} />
          <Check label={L('dialog.maximize')} checked={opts.allowMaximize} onChange={(v) => set('allowMaximize', v)} />
          <Field label={L('dialog.codeLang')}>
            <select value={opts.codeLang} onChange={(e) => set('codeLang', e.target.value as 'pl' | 'en')}>
              <option value="pl">PL — utworz_okno</option>
              <option value="en">EN — create_window</option>
            </select>
          </Field>
        </div>

        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end', marginTop: 8 }}>
          <button onClick={onCancel}>{L('dialog.cancel')}</button>
          <button className="primary" onClick={create}>
            {L('dialog.create')}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label style={{ display: 'block', marginBottom: 10 }}>
      <div style={{ color: 'var(--text-dim)', marginBottom: 4, fontSize: 11 }}>{label}</div>
      {children}
    </label>
  );
}

function Check({ label, checked, onChange }: { label: string; checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label style={{ display: 'flex', gap: 8, alignItems: 'center', fontSize: 12 }}>
      <input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      {label}
    </label>
  );
}

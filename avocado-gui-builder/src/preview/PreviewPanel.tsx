import { useAppStore } from '@/state/store';
import { getComponentMeta } from '@/framework/metadata';
import { computeDarkerInputBg } from '@/code-generator';
import type { Lang } from '@/i18n';

export function PreviewPanel({ lang }: { lang: Lang }) {
  const form = useAppStore((s) => s.getForm());
  if (!form) return <div className="empty">No form</div>;

  return (
    <div style={{ flex: 1, overflow: 'auto', background: 'var(--canvas)', padding: 16 }}>
      <div className="muted" style={{ marginBottom: 8, fontSize: 11 }}>
        Live preview · visual approximation of Avoraiser runtime (Win32) · not all native behaviors are simulated
      </div>
      <div
        className="preview-form"
        style={{
          width: form.width,
          height: form.height,
          background: form.backgroundColor,
          color: '#eee',
          border: form.frameless ? 'none' : '1px solid #000',
          borderRadius: form.frameless ? 6 : 4,
        }}
      >
        <div className="preview-title">
          <span style={{ flex: 1 }}>{form.title}</span>
          <span style={{ opacity: 0.7 }}>— □ ×</span>
        </div>
        {form.components.map((c) => {
          const meta = getComponentMeta(c.typeId);
          return (
            <div
              key={c.id}
              style={{
                position: 'absolute',
                left: c.x,
                top: c.y + 28,
                width: c.w,
                height: c.h,
              }}
            >
              <PreviewWidget typeId={c.typeId} props={c.props} name={c.name} formBg={form.backgroundColor} />
            </div>
          );
        })}
      </div>
      <div className="muted" style={{ marginTop: 12, fontSize: 11, maxWidth: 640 }}>
        Limitations: HWND handles, GDI drawing, Chromium WebView and native dialogs are not rendered in the browser.
        Generated Pascal uses real Avoraiser APIs for those cases.
      </div>
    </div>
  );
}

function PreviewWidget({
  typeId,
  props,
  formBg = '#1E1E1E',
}: {
  typeId: string;
  props: Record<string, unknown>;
  name: string;
  formBg?: string;
}) {
  const meta = getComponentMeta(typeId);
  const darker = computeDarkerInputBg(formBg);

  if (typeId.startsWith('service-')) {
    return (
      <div
        style={{
          width: '100%',
          height: '100%',
          border: '1px dashed #4fc1ff',
          borderRadius: 4,
          background: 'rgba(79,193,255,0.1)',
          color: '#4fc1ff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 10,
          gap: 4,
        }}
      >
        <span>⚙️</span>
        <span>{meta?.name ?? typeId}</span>
      </div>
    );
  }

  switch (typeId) {
    case 'button':
    case 'image-button':
      return (
        <button
          className="preview-btn"
          style={{
            width: '100%',
            height: '100%',
            background: String(props.Color ?? '#2D2D2D'),
            color: String(props.ColorText ?? '#fff'),
            border: '1px solid rgba(255,255,255,0.15)',
            borderRadius: Number(props.Radius ?? 8),
            fontWeight: 600,
          }}
        >
          {String(props.Caption ?? 'Button')}
        </button>
      );
    case 'edit':
      return (
        <input
          className="preview-input"
          style={{
            width: '100%',
            height: '100%',
            background: darker.bgHex,
            color: darker.textHex,
            textAlign: (props.Alignment as 'left' | 'center' | 'right') ?? 'left',
          }}
          readOnly={props.ReadOnly === true || props.ReadOnly === 'true'}
          placeholder={String(props.Placeholder ?? '')}
          type={props.PasswordChar ? 'password' : 'text'}
          defaultValue={String(props.Text ?? '')}
        />
      );
    case 'memo':
      return (
        <textarea
          className="preview-input"
          style={{
            width: '100%',
            height: '100%',
            background: darker.bgHex,
            color: darker.textHex,
          }}
          readOnly={props.ReadOnly === true || props.ReadOnly === 'true'}
          defaultValue={String(props.Text ?? '')}
        />
      );
    case 'rich-edit': {
      const bg = String(props.BackgroundColor ?? '') || darker.bgHex;
      const fg = String(props.TextColor ?? '') || darker.textHex;
      return (
        <div
          className="preview-input"
          style={{
            width: '100%',
            height: '100%',
            background: bg === '#FFFFFF' ? darker.bgHex : bg,
            color: fg === '#000000' ? darker.textHex : fg,
            padding: 4,
            fontSize: 11,
            fontFamily: 'serif',
            overflow: 'auto',
          }}
        >
          {String(props.Text ?? 'Rich Text')}
        </div>
      );
    }
    case 'checkbox':
      return (
        <label style={{ display: 'flex', gap: 8, alignItems: 'center', height: '100%', color: String(props.TextColor ?? '#fff') }}>
          <input type="checkbox" defaultChecked={props.Checked === true || props.Checked === 'true'} />
          {String(props.Caption ?? '')}
        </label>
      );
    case 'radio-button':
      return (
        <label style={{ display: 'flex', gap: 8, alignItems: 'center', height: '100%', color: String(props.TextColor ?? '#fff') }}>
          <input type="radio" name={`radio-${props.Id ?? 1}`} defaultChecked={props.Checked === true || props.Checked === 'true'} />
          {String(props.Caption ?? '')}
        </label>
      );
    case 'listbox':
      return (
        <select size={5} style={{ width: '100%', height: '100%', background: '#fff', color: '#111' }}>
          {String(props.Items ?? '')
            .split('\n')
            .filter(Boolean)
            .map((it) => (
              <option key={it}>{it}</option>
            ))}
        </select>
      );
    case 'combobox':
      return (
        <select style={{ width: '100%', height: '100%', background: '#fff', color: '#111' }}>
          {String(props.Items ?? '')
            .split('\n')
            .filter(Boolean)
            .map((it) => (
              <option key={it}>{it}</option>
            ))}
        </select>
      );
    case 'label':
      return <div style={{ width: '100%', height: '100%', color: String(props.TextColor ?? '#fff') }}>{String(props.Caption ?? '')}</div>;
    case 'progressbar':
      return (
        <progress value={Number(props.Value ?? 0)} max={100} style={{ width: '100%', height: '100%' }} />
      );
    case 'trackbar':
      return <input type="range" min={Number(props.Min ?? 0)} max={Number(props.Max ?? 100)} defaultValue={Number(props.Value ?? 0)} style={{ width: '100%' }} />;
    case 'spin-edit':
      return <input type="number" defaultValue={Number(props.Value ?? 0)} style={{ width: '100%', height: '100%' }} />;
    case 'panel':
      return <div style={{ width: '100%', height: '100%', background: String(props.Color ?? '#2A2A2A'), border: '1px solid rgba(255,255,255,0.1)' }} />;
    case 'gradient-panel': {
      const dir = Number(props.Direction ?? 1) === 0 ? 'to right' : 'to bottom';
      const c1 = String(props.ColorStart ?? '#1A365D');
      const c2 = String(props.ColorEnd ?? '#2B6CB0');
      return <div style={{ width: '100%', height: '100%', background: `linear-gradient(${dir}, ${c1}, ${c2})`, borderRadius: 4 }} />;
    }
    case 'rounded-panel':
      return <div style={{ width: '100%', height: '100%', background: String(props.Color ?? '#2D3748'), borderRadius: Number(props.Radius ?? 12) }} />;
    case 'group-box':
      return (
        <fieldset style={{ width: '100%', height: '100%', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 4, padding: 4, margin: 0 }}>
          <legend style={{ color: String(props.TextColor ?? '#fff'), fontSize: 10, padding: '0 4px' }}>{String(props.Caption ?? 'Group')}</legend>
        </fieldset>
      );
    case 'frame':
      return <div style={{ width: '100%', height: '100%', border: `${Number(props.Thickness ?? 1)}px solid ${String(props.Color ?? '#808080')}` }} />;
    case 'line':
      return <div style={{ width: '100%', height: '100%', borderTop: `${Number(props.Thickness ?? 1)}px solid ${String(props.Color ?? '#808080')}` }} />;
    case 'circle-filled':
      return <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: String(props.Color ?? '#66A0FF') }} />;
    case 'circle-outline':
      return <div style={{ width: '100%', height: '100%', borderRadius: '50%', border: `${Number(props.Thickness ?? 2)}px solid ${String(props.Color ?? '#66A0FF')}` }} />;
    case 'circle-image':
      return (
        <div style={{ width: '100%', height: '100%', borderRadius: '50%', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.2)', display: 'grid', placeItems: 'center', background: '#333' }}>
          {props.Image ? <img src={String(props.Image)} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" /> : '🖼️'}
        </div>
      );
    case 'image-box':
      return (
        <div style={{ width: '100%', height: '100%', border: '1px solid rgba(255,255,255,0.15)', display: 'grid', placeItems: 'center', background: '#222' }}>
          {props.Image ? <img src={String(props.Image)} style={{ width: '100%', height: '100%', objectFit: 'contain' }} alt="" /> : '🖼️ Image'}
        </div>
      );
    case 'rotated-image':
      return (
        <div style={{ width: '100%', height: '100%', border: '1px solid rgba(255,255,255,0.15)', display: 'grid', placeItems: 'center', background: '#222', transform: `rotate(${Number(props.Angle ?? 0)}deg)` }}>
          {props.Image ? <img src={String(props.Image)} style={{ width: '100%', height: '100%', objectFit: 'contain' }} alt="" /> : '🔄 Image'}
        </div>
      );
    default:
      return (
        <div
          style={{
            width: '100%',
            height: '100%',
            border: '1px dashed rgba(255,255,255,0.2)',
            display: 'grid',
            placeItems: 'center',
            color: 'rgba(255,255,255,0.5)',
            fontSize: 10,
          }}
        >
          {meta?.name ?? typeId}
        </div>
      );
  }
}

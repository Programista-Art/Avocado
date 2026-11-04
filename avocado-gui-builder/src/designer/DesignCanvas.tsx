import { useRef, useState, useCallback } from 'react';
import { useAppStore } from '@/state/store';
import { getComponentMeta } from '@/framework/metadata';
import { computeDarkerInputBg } from '@/code-generator';
import type { Lang } from '@/i18n';

type DragMode = 'move' | 'nw' | 'n' | 'ne' | 'w' | 'e' | 'sw' | 's' | 'se';

export function DesignCanvas({ lang }: { lang: Lang }) {
  const form = useAppStore((s) => s.getForm());
  const selectedIds = useAppStore((s) => s.selectedIds);
  const select = useAppStore((s) => s.select);
  const addComponent = useAppStore((s) => s.addComponent);
  const moveComponents = useAppStore((s) => s.moveComponents);
  const resizeComponent = useAppStore((s) => s.resizeComponent);
  const pushHistory = useAppStore((s) => s.pushHistory);
  const settings = useAppStore((s) => s.project.settings);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [drag, setDrag] = useState<{
    mode: DragMode;
    id: string;
    startX: number;
    startY: number;
    origX: number;
    origY: number;
    origW: number;
    origH: number;
    childrenOrig: { id: string; origX: number; origY: number }[];
  } | null>(null);

  const zoom = settings.zoom || 1;

  const snap = useCallback(
    (v: number) => (settings.snapToGrid ? Math.round(v / settings.gridSize) * settings.gridSize : Math.round(v)),
    [settings.snapToGrid, settings.gridSize],
  );

  const onCanvasDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const typeId = e.dataTransfer.getData('text/avocado-type');
    if (!typeId || !form) return;
    const gridEl = wrapRef.current?.querySelector('.canvas-grid') as HTMLElement | null;
    const rect = (gridEl ?? (e.currentTarget as HTMLElement)).getBoundingClientRect();
    const rawX = (e.clientX - rect.left) / zoom;
    const rawY = (e.clientY - rect.top) / zoom;
    addComponent(typeId, Math.max(0, snap(rawX)), Math.max(0, snap(rawY)));
  };

  const startDrag = (
    e: React.MouseEvent,
    id: string,
    mode: DragMode,
    comp: { id: string; typeId: string; x: number; y: number; w: number; h: number },
  ) => {
    e.stopPropagation();
    e.preventDefault();
    if (!selectedIds.includes(id)) select([id]);
    pushHistory();

    const childrenOrig: { id: string; origX: number; origY: number }[] = [];
    if (mode === 'move' && form) {
      const meta = getComponentMeta(comp.typeId);
      const isContainer = Boolean(meta?.isContainer || comp.typeId === 'group-box');
      if (isContainer) {
        const compArea = comp.w * comp.h;
        for (const child of form.components) {
          if (child.id === comp.id) continue;
          const childMeta = getComponentMeta(child.typeId);
          const childIsLargerContainer =
            Boolean(childMeta?.isContainer || child.typeId === 'group-box') && child.w * child.h > compArea;
          if (childIsLargerContainer) continue;

          const cx = child.x + child.w / 2;
          const cy = child.y + child.h / 2;
          const inside =
            child.parentId === comp.id ||
            (cx >= comp.x && cx <= comp.x + comp.w && cy >= comp.y && cy <= comp.y + comp.h);
          if (inside) {
            childrenOrig.push({ id: child.id, origX: child.x, origY: child.y });
          }
        }
      }
    }

    setDrag({
      mode,
      id,
      startX: e.clientX,
      startY: e.clientY,
      origX: comp.x,
      origY: comp.y,
      origW: comp.w,
      origH: comp.h,
      childrenOrig,
    });
  };

  const onMove = (e: React.MouseEvent) => {
    if (!drag) return;
    const dx = (e.clientX - drag.startX) / zoom;
    const dy = (e.clientY - drag.startY) / zoom;
    if (drag.mode === 'move') {
      const newX = snap(drag.origX + dx);
      const newY = snap(drag.origY + dy);
      const actualDx = newX - drag.origX;
      const actualDy = newY - drag.origY;
      moveComponents([
        { id: drag.id, x: newX, y: newY },
        ...drag.childrenOrig.map((ch) => ({
          id: ch.id,
          x: ch.origX + actualDx,
          y: ch.origY + actualDy,
        })),
      ]);
      return;
    }
    let { origX: x, origY: y, origW: w, origH: h } = drag;
    if (drag.mode.includes('e')) w = drag.origW + dx;
    if (drag.mode.includes('s')) h = drag.origH + dy;
    if (drag.mode.includes('w')) {
      w = drag.origW - dx;
      x = drag.origX + dx;
    }
    if (drag.mode.includes('n')) {
      h = drag.origH - dy;
      y = drag.origY + dy;
    }
    resizeComponent(drag.id, snap(w), snap(h), snap(x), snap(y));
  };

  const endDrag = () => setDrag(null);

  if (!form) return <div className="empty">No form</div>;

  return (
    <div
      ref={wrapRef}
      className="canvas-wrap"
      onDragOver={(e) => e.preventDefault()}
      onDrop={onCanvasDrop}
      onMouseMove={onMove}
      onMouseUp={endDrag}
      onMouseLeave={endDrag}
    >
      <div
        className={`canvas-grid ${settings.showGrid ? 'show-grid' : ''}`}
        style={{
          width: form.width,
          height: form.height,
          backgroundColor: form.backgroundColor,
          color: '#eee',
          backgroundSize: `${settings.gridSize}px ${settings.gridSize}px`,
          transform: zoom !== 1 ? `scale(${zoom})` : undefined,
          transformOrigin: 'top left',
        }}
        onMouseDown={() => select([])}
      >
        <div
          style={{
            position: 'absolute',
            top: -20,
            left: 0,
            fontSize: 10,
            color: 'var(--text-dim)',
          }}
        >
          {form.title} · {form.width}×{form.height}
        </div>
        {form.components.map((c) => {
          const meta = getComponentMeta(c.typeId);
          const isContainer = Boolean(meta?.isContainer || c.typeId === 'group-box');
          const selected = selectedIds.includes(c.id);
          const style: React.CSSProperties = {
            left: c.x,
            top: c.y,
            width: c.w,
            height: c.h,
            zIndex: isContainer ? Math.min(c.zIndex, 5) : Math.max(c.zIndex, 10),
          };
          return (
            <div
              key={c.id}
              className={`comp ${selected ? 'selected' : ''} ${settings.showNames || selected ? 'show-name' : ''} ${isContainer ? 'is-container' : ''}`}
              style={style}
              onMouseDown={(e) => startDrag(e, c.id, 'move', c)}
            >
              <div className="comp-name">
                {c.name} {selected ? `(${c.x}, ${c.y} · ${c.w}×${c.h})` : ''}
              </div>
              <RenderPreviewComp typeId={c.typeId} props={c.props} formBg={form.backgroundColor} />
              {selected &&
                (['nw', 'n', 'ne', 'w', 'e', 'sw', 's', 'se'] as DragMode[]).map((m) => (
                  <div key={m} className={`handle ${m}`} onMouseDown={(e) => startDrag(e, c.id, m, c)} />
                ))}
            </div>
          );
        })}
      </div>
    </div>
  );
}

function RenderPreviewComp({
  typeId,
  props,
  formBg = '#1E1E1E',
}: {
  typeId: string;
  props: Record<string, unknown>;
  formBg?: string;
}) {
  const meta = getComponentMeta(typeId);
  const color = String(props.Color ?? props.ColorText ?? '');
  const textColor = String(props.ColorText ?? '#fff');
  const darker = computeDarkerInputBg(formBg);

  if (typeId.startsWith('service-')) {
    return (
      <div style={{ width: '100%', height: '100%', border: '1px dashed #4fc1ff', borderRadius: 4, background: 'rgba(79,193,255,0.1)', color: '#4fc1ff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, gap: 4 }}>
        <span>⚙️</span>
        <span>{meta?.name ?? typeId}</span>
      </div>
    );
  }

  switch (typeId) {
    case 'button':
    case 'image-button': {
      const btnImg = String(props._imagePreview || props.Image || '');
      return (
        <div
          className="preview-btn"
          style={{
            width: '100%',
            height: '100%',
            background: String(props.Color ?? '#2D2D2D'),
            color: textColor,
            fontWeight: 600,
            gap: 6,
          }}
        >
          {btnImg && <img src={btnImg} style={{ width: 18, height: 18, objectFit: 'contain' }} alt="" />}
          <span>{String(props.Caption ?? 'Button')}</span>
        </div>
      );
    }
    case 'label':
      return (
        <div className="preview-label" style={{ width: '100%', height: '100%', color: String(props.TextColor ?? '#fff') }}>
          {String(props.Caption ?? 'Label')}
        </div>
      );
    case 'edit':
    case 'memo': {
      const rawBg = String(props.BackgroundColor ?? '');
      const bg =
        rawBg && rawBg.toUpperCase() !== '#141414' && rawBg.toUpperCase() !== '#FFFFFF'
          ? rawBg
          : darker.bgHex;
      const fg = props.TextColor ? String(props.TextColor) : darker.textHex;
      return (
        <div
          className="preview-input"
          style={{
            width: '100%',
            height: '100%',
            padding: 4,
            fontSize: 11,
            overflow: 'hidden',
            background: bg,
            color: fg,
          }}
        >
          {String(props.Text ?? '')}
        </div>
      );
    }
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
            overflow: 'hidden',
          }}
        >
          {String(props.Text ?? 'RTF Editor')}
        </div>
      );
    }
    case 'checkbox':
      return (
        <div style={{ width: '100%', height: '100%', color: String(props.TextColor ?? '#fff') }}>
          ☐ {String(props.Caption ?? 'Option')}
        </div>
      );
    case 'radio-button':
      return (
        <div style={{ width: '100%', height: '100%', color: String(props.TextColor ?? '#fff') }}>
          ○ {String(props.Caption ?? 'Option')}
        </div>
      );
    case 'listbox':
    case 'combobox':
      return (
        <div style={{ width: '100%', height: '100%', background: '#fff', color: '#111', fontSize: 11, padding: 2, overflow: 'auto' }}>
          {String(props.Items ?? '')
            .split('\n')
            .filter(Boolean)
            .map((it, i) => (
              <div key={i}>{it}</div>
            ))}
        </div>
      );
    case 'progressbar':
      return (
        <div style={{ width: '100%', height: '100%', background: '#333', borderRadius: 3, overflow: 'hidden' }}>
          <div style={{ width: `${Number(props.Value ?? 0)}%`, height: '100%', background: String(props.Color ?? '#66C2FF') }} />
        </div>
      );
    case 'trackbar':
      return (
        <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', padding: '0 6px' }}>
          <div style={{ flex: 1, height: 4, background: '#555', borderRadius: 2, position: 'relative' }}>
            <div
              style={{
                position: 'absolute',
                left: `${Number(props.Value ?? 0)}%`,
                top: -5,
                width: 12,
                height: 12,
                borderRadius: '50%',
                background: color || '#0e639c',
              }}
            />
          </div>
        </div>
      );
    case 'spin-edit':
      return (
        <div style={{ width: '100%', height: '100%', display: 'flex', border: '1px solid #555', background: String(props.BgColor ?? '#2D2D2D'), color: '#fff', fontSize: 11, alignItems: 'center', padding: '0 4px' }}>
          <span style={{ flex: 1 }}>{Number(props.Value ?? 0)}</span>
          <span style={{ fontSize: 9, opacity: 0.7 }}>▲▼</span>
        </div>
      );
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
    case 'circle-image': {
      const imgSrc = String(props._imagePreview || props.Image || '');
      return (
        <div style={{ width: '100%', height: '100%', borderRadius: '50%', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.2)', display: 'grid', placeItems: 'center', background: '#333' }}>
          {imgSrc ? <img src={imgSrc} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" /> : '🖼️'}
        </div>
      );
    }
    case 'image-box': {
      const imgSrc = String(props._imagePreview || props.Image || '');
      return (
        <div style={{ width: '100%', height: '100%', border: '1px solid rgba(255,255,255,0.15)', display: 'grid', placeItems: 'center', background: '#222' }}>
          {imgSrc ? <img src={imgSrc} style={{ width: '100%', height: '100%', objectFit: 'contain' }} alt="" /> : '🖼️ Image'}
        </div>
      );
    }
    case 'rotated-image': {
      const imgSrc = String(props._imagePreview || props.Image || '');
      return (
        <div style={{ width: '100%', height: '100%', border: '1px solid rgba(255,255,255,0.15)', display: 'grid', placeItems: 'center', background: '#222', transform: `rotate(${Number(props.Angle ?? 0)}deg)` }}>
          {imgSrc ? <img src={imgSrc} style={{ width: '100%', height: '100%', objectFit: 'contain' }} alt="" /> : '🔄 Image'}
        </div>
      );
    }
    default:
      return (
        <div
          style={{
            width: '100%',
            height: '100%',
            background: color || 'rgba(255,255,255,0.08)',
            opacity: 0.85,
            display: 'grid',
            placeItems: 'center',
            fontSize: 9,
            color: 'var(--text-dim)',
          }}
        >
          {meta?.name ?? typeId}
        </div>
      );
  }
}

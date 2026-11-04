import { useEffect, useRef, useState } from 'react';

export interface MenuAction {
  label: string;
  kbd?: string;
  onClick: () => void;
  disabled?: boolean;
  checked?: boolean;
  separatorBefore?: boolean;
}

export interface MenuDef {
  label: string;
  items: MenuAction[];
}

export function MainMenu({ menus }: { menus: MenuDef[] }) {
  const [open, setOpen] = useState<number | null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(null);
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, []);

  return (
    <div className="menubar" ref={ref}>
      {menus.map((m, i) => (
        <div key={m.label} className={`menu-item ${open === i ? 'open' : ''}`}>
          <button onClick={() => setOpen(open === i ? null : i)}>{m.label}</button>
          {open === i && (
            <div className="menu-drop">
              {m.items.map((it) => (
                <div key={it.label}>
                  {it.separatorBefore && <div className="sep" />}
                  <button
                    disabled={it.disabled}
                    onClick={() => {
                      it.onClick();
                      setOpen(null);
                    }}
                  >
                    <span>
                      {it.checked !== undefined && (it.checked ? '✓ ' : '　')}
                      {it.label}
                    </span>
                    {it.kbd && <span className="kbd">{it.kbd}</span>}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

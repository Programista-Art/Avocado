export function AboutDialog({ lang, kind, onClose }: { lang: string; kind: 'about' | 'author'; onClose: () => void }) {
  const pl = lang === 'pl';
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        {kind === 'about' ? (
          <>
            <h3>
              <span>🥑</span> {pl ? 'O programie' : 'About'}
            </h3>
            <p style={{ lineHeight: 1.6 }}>
              <strong>Avocado GUI Builder</strong> {pl ? '— wizualne IDE i generator kodu' : '— visual IDE and code generator'}{' '}
              {pl ? 'dla frameworka' : 'for the'} <strong>Avoraraiser/Avocado</strong>.
            </p>
            <p style={{ marginTop: 10, color: 'var(--text-dim)', lineHeight: 1.6 }}>
              {pl
                ? 'Projektuj okna i komponenty, generuj kod Avocado (PL/EN), zarządzaj zdarzeniami i oknami córkami.'
                : 'Design windows and components, generate Avocado code (PL/EN), manage events and child windows.'}
            </p>
            <p className="mono muted" style={{ marginTop: 12, fontSize: 11 }}>
              Version 1.0 · Framework: Avoraraiser/Avocado
            </p>
          </>
        ) : (
          <>
            <h3>
              <span>👤</span> {pl ? 'Autor' : 'Author'}
            </h3>
            <p style={{ lineHeight: 1.8 }}>
              <strong>Avocado Project</strong>
            </p>
            <p style={{ color: 'var(--text-dim)', lineHeight: 1.6, marginTop: 8 }}>
              {pl
                ? 'IDE Avocado · język Avocado · framework Avoraiser'
                : 'Avocado IDE · Avocado language · Avoraiser framework'}
            </p>
          </>
        )}
        <div className="actions">
          <button className="primary" onClick={onClose}>
            OK
          </button>
        </div>
      </div>
    </div>
  );
}

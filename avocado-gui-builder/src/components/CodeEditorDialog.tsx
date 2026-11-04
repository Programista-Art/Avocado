import { useMemo, useState } from 'react';
import Editor from '@monaco-editor/react';

const SNIPPETS = [
  {
    id: 'msg',
    labelPl: 'Pokaż wiadomość',
    labelEn: 'Show message',
    code: "pokaz_wiadomosc(my_window, 'Tytuł', 'Tekst')",
  },
  {
    id: 'ask',
    labelPl: 'Pytanie Tak/Nie',
    labelEn: 'Yes/No question',
    code: "zadaj_pytanie(my_window, 'Pytanie', 'Czy kontynuować?')",
  },
  {
    id: 'settext',
    labelPl: 'Ustaw tekst',
    labelEn: 'Set text',
    code: "ustaw_tekst(pole_1, 'Nowy tekst')",
  },
  {
    id: 'gettext',
    labelPl: 'Pobierz tekst',
    labelEn: 'Get text',
    code: 'tekst t = pobierz_tekst(pole_1)',
  },
  {
    id: 'click',
    labelPl: 'Obsługa kliknięcia',
    labelEn: 'Click handler',
    code: 'pokaz_wiadomosc(my_window, ' + "'Klik'" + ', ' + "'Kliknięto przycisk')",
  },
  {
    id: 'if',
    labelPl: 'Warunek',
    labelEn: 'If',
    code: "if a = 1 then\nstart\n  pisz_linie('Tak')\nend\ninaczej\n  pisz_linie('Nie')",
  },
  {
    id: 'for',
    labelPl: 'Pętla for',
    labelEn: 'For loop',
    code: 'for i = 1 to 10 do\nstart\n  pisz_linie(i)\nend',
  },
  {
    id: 'crypto',
    labelPl: 'Szyfruj plik',
    labelEn: 'Encrypt file',
    code: "szyfruj_plik_gcm('in.txt', 'out.enc', 'haslo')",
  },
  {
    id: 'web',
    labelPl: 'Przeglądarka URL',
    labelEn: 'Webview URL',
    code: "przegladarka_nawiguj('https://example.com')",
  },
  {
    id: 'timer',
    labelPl: 'Zegar',
    labelEn: 'Timer',
    code: 'uruchom_zegar(my_window, 1, 1000)',
  },
];

export function CodeEditorDialog({
  handlerName,
  initialCode,
  lang,
  onSave,
  onClose,
}: {
  handlerName: string;
  initialCode: string;
  lang: 'en' | 'pl';
  onSave: (code: string) => void;
  onClose: () => void;
}) {
  const [code, setCode] = useState(initialCode || `// ${handlerName}\n`);
  const [showSnippets, setShowSnippets] = useState(true);
  const pl = lang === 'pl';
  const snippets = useMemo(() => SNIPPETS, []);

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        style={{ width: 'min(920px, 96vw)', height: 'min(640px, 90vh)', display: 'flex', flexDirection: 'column', padding: 0 }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          style={{
            padding: '14px 18px',
            borderBottom: '1px solid var(--border)',
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}
        >
          <span style={{ fontSize: 18 }}>❯</span>
          <div>
            <div style={{ fontWeight: 700 }}>{handlerName}</div>
            <div className="muted" style={{ fontSize: 11 }}>
              {pl ? 'Kod procedury Avocado' : 'Avocado procedure code'}
            </div>
          </div>
          <button
            className={showSnippets ? 'primary' : ''}
            style={{ marginLeft: 'auto' }}
            onClick={() => setShowSnippets(!showSnippets)}
          >
            {pl ? 'Zdarzenia / bloki' : 'Events / blocks'}
          </button>
        </div>

        <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
          <div style={{ flex: 1, minWidth: 0, background: '#0e0e14' }}>
            <Editor
              height="100%"
              defaultLanguage="pascal"
              theme="vs-dark"
              value={code}
              onChange={(v) => setCode(v ?? '')}
              options={{
                minimap: { enabled: true },
                fontSize: 13,
                wordWrap: 'on',
                automaticLayout: true,
                tabSize: 2,
              }}
            />
          </div>
          {showSnippets && (
            <div
              style={{
                width: 220,
                borderLeft: '1px solid var(--border)',
                overflow: 'auto',
                background: 'var(--bg-panel)',
              }}
            >
              <div className="panel-header">{pl ? 'Wstaw blok' : 'Insert block'}</div>
              {snippets.map((s) => (
                <button
                  key={s.id}
                  style={{ display: 'block', width: 'calc(100% - 12px)', margin: '4px 6px', textAlign: 'left' }}
                  title={s.code}
                  onClick={() => setCode((c) => (c.trim() ? c + '\n' + s.code : s.code + '\n'))}
                >
                  {pl ? s.labelPl : s.labelEn}
                </button>
              ))}
            </div>
          )}
        </div>

        <div style={{ padding: 12, borderTop: '1px solid var(--border)', display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <button onClick={onClose}>{pl ? 'Anuluj' : 'Cancel'}</button>
          <button
            className="primary"
            onClick={() => {
              onSave(code);
              onClose();
            }}
          >
            {pl ? 'Zapisz kod' : 'Save code'}
          </button>
        </div>
      </div>
    </div>
  );
}

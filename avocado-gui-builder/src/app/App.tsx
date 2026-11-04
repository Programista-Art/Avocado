import { useCallback, useEffect, useState } from 'react';
import { useAppStore } from '@/state/store';
import { t, type Lang } from '@/i18n';
import { Toolbox } from '@/toolbox/Toolbox';
import { DesignCanvas } from '@/designer/DesignCanvas';
import { HierarchyPanel } from '@/hierarchy/HierarchyPanel';
import { ObjectInspector } from '@/object-inspector/ObjectInspector';
import { CodePanel } from '@/code-editor/CodePanel';
import { ValidationPanel } from '@/validation/ValidationPanel';
import { NewProjectDialog } from '@/app/NewProjectDialog';
import { MainMenu, type MenuDef } from '@/components/MainMenu';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { AboutDialog } from '@/components/AboutDialog';
import { exportProjectJson, downloadText } from '@/project-manager/io';
import { generateAvocadoSource } from '@/code-generator';
import type { ProjectModel } from '@/types';

export default function App() {
  const store = useAppStore();
  const [lang, setLang] = useState<Lang>(store.project.settings.language);
  const [rightTab, setRightTab] = useState<'inspector' | 'events' | 'validation'>('inspector');
  const [showNew, setShowNew] = useState(false);
  const [helpModal, setHelpModal] = useState<null | 'about' | 'author'>(null);

  useEffect(() => {
    document.documentElement.dataset.theme = store.project.settings.theme;
  }, [store.project.settings.theme]);

  useEffect(() => {
    setLang(store.project.settings.language);
  }, [store.project.settings.language]);
  const L = (k: string) => t(lang, k);

  const onSave = useCallback(() => {
    downloadText(`${store.project.projectName}.avocado.json`, exportProjectJson(store.project));
    store.setStatus(L('status.saved'));
  }, [store, lang]);

  const onOpen = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,.avocado.json';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;
      const text = await file.text();
      if (!store.loadFromJson(text)) alert('Invalid project file');
    };
    input.click();
  }, [store]);

  const onExportAvocado = useCallback(() => {
    const form = store.project.forms[0];
    downloadText(`${store.project.projectName}.avocado`, generateAvocadoSource(store.project, form));
    store.setStatus(L('status.generated'));
  }, [store, lang]);

  const onCopyCode = useCallback(() => {
    store.regenerate();
    const code = useAppStore.getState().generatedCode;
    navigator.clipboard.writeText(code);
    store.setStatus(lang === 'pl' ? 'Skopiowano kod do schowka' : 'Code copied to clipboard');
  }, [store, lang]);

  const onImportAvocado = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.avocado,.pas,.txt';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;
      alert(lang === 'pl' ? 'Import kodu Avocado — w przygotowaniu.' : 'Avocado import — coming soon.');
    };
    input.click();
  }, [lang]);

  const onAddChild = useCallback(() => {
    store.pushHistory();
    const p = JSON.parse(JSON.stringify(store.project)) as ProjectModel;
    const n = p.forms.filter((f) => f.isChild).length + 1;
    p.forms.push({
      id: 'form-child-' + n,
      name: 'ChildForm' + n,
      className: 'TChildForm' + n,
      width: 400,
      height: 300,
      title: 'Okno córka ' + n,
      backgroundColor: '#202020',
      frameless: false,
      allowMaximize: true,
      allowDrag: true,
      centerWindow: true,
      darkMode: false,
      opacity: 255,
      onTop: false,
      isChild: true,
      parentFormId: 'form-main',
      visible: true,
      components: [],
    });
    store.setProject(p);
  }, [store]);

  const selectAll = useCallback(() => {
    const form = store.getForm();
    if (form) store.select(form.components.map((c) => c.id));
  }, [store]);

  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const mod = e.ctrlKey || e.metaKey;
      const tag = (e.target as HTMLElement)?.tagName;
      const typing = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT';
      if (mod && e.key === 'z' && !e.shiftKey) { e.preventDefault(); store.undo(); }
      if (mod && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) { e.preventDefault(); store.redo(); }
      if (mod && e.key === 's') { e.preventDefault(); onSave(); }
      if (mod && e.key === 'n') { e.preventDefault(); setShowNew(true); }
      if (mod && e.key === 'o') { e.preventDefault(); onOpen(); }
      if (mod && e.key === 'g') {
        e.preventDefault();
        store.regenerate();
        store.setStatus(L('status.generated'));
      }
      if (mod && e.key === 'a' && !typing) { e.preventDefault(); selectAll(); }
      if (mod && e.key === 'd' && !typing) { e.preventDefault(); store.duplicateSelected(); }
      if (e.key === 'Delete' && !typing) store.requestDelete();
    },
    [store, onSave, onOpen, selectAll, lang],
  );

  useEffect(() => {
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onKeyDown]);

  const bringFront = useCallback(
    (dir: 1 | -1) => {
      for (const id of store.selectedIds) store.setZIndex(id, dir);
    },
    [store],
  );

  const menus: MenuDef[] = [
    {
      label: L('menu.file'),
      items: [
        { label: L('menu.newProject'), kbd: 'Ctrl+N', onClick: () => setShowNew(true) },
        { label: L('menu.openProject'), kbd: 'Ctrl+O', onClick: onOpen },
        { label: L('menu.saveProject'), kbd: 'Ctrl+S', onClick: onSave },
        { label: L('menu.importAvocado'), onClick: onImportAvocado, separatorBefore: true },
        { label: L('menu.exportAvocado'), onClick: onExportAvocado },
      ],
    },
    {
      label: L('menu.edit'),
      items: [
        { label: L('menu.undo'), kbd: 'Ctrl+Z', onClick: () => store.undo() },
        { label: L('menu.redo'), kbd: 'Ctrl+Y', onClick: () => store.redo() },
        { label: L('actions.duplicate'), kbd: 'Ctrl+D', onClick: () => store.duplicateSelected(), separatorBefore: true },
        { label: L('actions.delete'), kbd: 'Del', onClick: () => store.requestDelete() },
        { label: lang === 'pl' ? 'Zaznacz wszystko' : 'Select all', kbd: 'Ctrl+A', onClick: selectAll, separatorBefore: true },
        { label: lang === 'pl' ? 'Przesuń na wierzch' : 'Bring to front', onClick: () => bringFront(1) },
        { label: lang === 'pl' ? 'Przesuń pod spód' : 'Send to back', onClick: () => bringFront(-1) },
      ],
    },
    {
      label: L('menu.view'),
      items: [
        {
          label: lang === 'pl' ? 'Powiększ' : 'Zoom in',
          onClick: () => store.updateSettings({ zoom: Math.min(2, store.project.settings.zoom + 0.1) }),
        },
        {
          label: lang === 'pl' ? 'Pomniejsz' : 'Zoom out',
          onClick: () => store.updateSettings({ zoom: Math.max(0.3, store.project.settings.zoom - 0.1) }),
        },
        { label: 'Skala 100%', onClick: () => store.updateSettings({ zoom: 1 }) },
        {
          label: lang === 'pl' ? 'Siatka' : 'Grid',
          checked: store.project.settings.showGrid,
          onClick: () => store.updateSettings({ showGrid: !store.project.settings.showGrid }),
          separatorBefore: true,
        },
        {
          label: lang === 'pl' ? 'Przyciągaj do siatki' : 'Snap to grid',
          checked: store.project.settings.snapToGrid,
          onClick: () => store.updateSettings({ snapToGrid: !store.project.settings.snapToGrid }),
        },
        {
          label: lang === 'pl' ? 'Motyw: Ciemny' : 'Theme: Dark',
          checked: store.project.settings.theme === 'dark',
          onClick: () => store.updateSettings({ theme: 'dark' }),
          separatorBefore: true,
        },
        {
          label: lang === 'pl' ? 'Motyw: Jasny' : 'Theme: Light',
          checked: store.project.settings.theme === 'light',
          onClick: () => store.updateSettings({ theme: 'light' }),
        },
      ],
    },
    {
      label: lang === 'pl' ? 'Kod' : 'Code',
      items: [
        {
          label: L('menu.generateCode'),
          kbd: 'Ctrl+G',
          onClick: () => {
            store.regenerate();
            store.setStatus(L('status.generated'));
          },
        },
        {
          label: lang === 'pl' ? 'Kopiuj kod' : 'Copy code',
          onClick: onCopyCode,
        },
      ],
    },
    {
      label: L('menu.help'),
      items: [
        {
          label: lang === 'pl' ? 'Dokumentacja frameworka' : 'Framework documentation',
          onClick: () => window.open('https://github.com/', '_blank'),
        },
        { label: L('menu.about'), onClick: () => setHelpModal('about') },
        { label: lang === 'pl' ? 'Autor' : 'Author', onClick: () => setHelpModal('author') },
      ],
    },
  ];

  const { showGrid, snapToGrid, gridSize, zoom } = store.project.settings;

  return (
    <div className="app">
      <header className="toolbar">
        <div className="brand">
          <div className="logo">🥑</div>
          {L('appName')}
        </div>
        <div className="sep" />
        <button className="primary" onClick={() => setShowNew(true)} title="Ctrl+N">
          {L('menu.newProject')}
        </button>
        <button
          onClick={onCopyCode}
          title={lang === 'pl' ? 'Kopiuj wygenerowany kod Avocado do schowka' : 'Copy generated Avocado code to clipboard'}
        >
          📋 {lang === 'pl' ? 'Kopiuj kod' : 'Copy code'}
        </button>
        <button onClick={onExportAvocado}>{L('menu.generateCode')}</button>
        <button onClick={onAddChild}>{L('menu.addChildWindow')}</button>
        <div className="spacer" />
        <button
          onClick={() => {
            const next: Lang = lang === 'en' ? 'pl' : 'en';
            setLang(next);
            store.updateSettings({ language: next });
          }}
        >
          {lang === 'en' ? 'PL' : 'EN'}
        </button>
        <button
          onClick={() => store.updateSettings({ codeLang: store.project.settings.codeLang === 'pl' ? 'en' : 'pl' })}
          title={L('dialog.codeLang')}
        >
          kod: {store.project.settings.codeLang.toUpperCase()}
        </button>
      </header>

      <MainMenu menus={menus} />

      <div className="workspace" style={{ gridTemplateColumns: '240px 1fr 320px' }}>
        {/* LEFT: Toolbox + Hierarchy in one column */}
        <div className="col" style={{ overflow: 'auto' }}>
          <div className="panel" style={{ minHeight: 320 }}>
            <div className="panel-header">{L('panels.toolbox')}</div>
            <div className="panel-body" style={{ maxHeight: 380, overflow: 'auto' }}>
              <Toolbox lang={lang} />
            </div>
          </div>
          <div className="panel" style={{ flex: 1, minHeight: 220, borderTop: '1px solid var(--border)' }}>
            <div className="panel-header">{L('panels.hierarchy')}</div>
            <div className="panel-body">
              <HierarchyPanel lang={lang} />
            </div>
          </div>
        </div>

        {/* CENTER */}
        <div className="col" style={{ minWidth: 0 }}>
          <div className="panel" style={{ flex: 1 }}>
            <div className="panel-header" style={{ flexWrap: 'wrap', gap: 8 }}>
              <span>{L('panels.canvas')}</span>
              <span className="muted mono">
                {gridSize}px · zoom {Math.round(zoom * 100)}%
              </span>
              <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6 }}>
                <button
                  className={showGrid ? 'primary' : ''}
                  onClick={() => store.updateSettings({ showGrid: !showGrid })}
                  title={lang === 'pl' ? 'Włącz / wyłącz widoczność siatki' : 'Toggle grid visibility'}
                >
                  # {lang === 'pl' ? (showGrid ? 'Siatka: WŁ' : 'Siatka: WYŁ') : (showGrid ? 'Grid: ON' : 'Grid: OFF')}
                </button>
                <button
                  className={snapToGrid ? 'primary' : ''}
                  onClick={() => store.updateSettings({ snapToGrid: !snapToGrid })}
                  title={lang === 'pl' ? 'Przyklejaj komponenty do siatki' : 'Snap components to grid'}
                >
                  🧲 {lang === 'pl' ? (snapToGrid ? 'Przyklejanie: WŁ' : 'Przyklejanie: WYŁ') : (snapToGrid ? 'Snap: ON' : 'Snap: OFF')}
                </button>
                <select
                  value={gridSize}
                  onChange={(e) => store.updateSettings({ gridSize: Number(e.target.value) })}
                  title={lang === 'pl' ? 'Rozmiar oczka siatki' : 'Grid size'}
                  style={{ padding: '4px 6px' }}
                >
                  <option value={4}>4 px</option>
                  <option value={8}>8 px</option>
                  <option value={10}>10 px</option>
                  <option value={12}>12 px</option>
                  <option value={16}>16 px</option>
                  <option value={24}>24 px</option>
                  <option value={32}>32 px</option>
                </select>
              </div>
            </div>
            <div className="panel-body" style={{ display: 'flex', flexDirection: 'column' }}>
              <DesignCanvas lang={lang} />
            </div>
          </div>
        </div>

        {/* RIGHT */}
        <div className="col">
          <div className="panel" style={{ flex: 1, minHeight: 0 }}>
            <div className="panel-header">
              <button className={rightTab === 'inspector' ? 'primary' : ''} onClick={() => setRightTab('inspector')}>
                {L('panels.inspector')}
              </button>
              <button className={rightTab === 'events' ? 'primary' : ''} onClick={() => setRightTab('events')}>
                {L('panels.events')}
              </button>
              <button className={rightTab === 'validation' ? 'primary' : ''} onClick={() => setRightTab('validation')}>
                {L('panels.validation')}
              </button>
            </div>
            <div className="panel-body">
              {rightTab === 'inspector' && <ObjectInspector lang={lang} />}
              {rightTab === 'events' && <ObjectInspector lang={lang} eventsOnly />}
              {rightTab === 'validation' && <ValidationPanel lang={lang} />}
            </div>
          </div>
        </div>
      </div>

      <div style={{ height: 260, display: 'flex', flexDirection: 'column', borderTop: '1px solid var(--border)' }}>
        <div className="tabs">
          <div className="tab active">
            {L('panels.code')}
          </div>
        </div>
        <div style={{ flex: 1, minHeight: 0, display: 'flex' }}>
          <CodePanel lang={lang} />
        </div>
      </div>

      <footer className="status-bar">
        <span>{store.status}</span>
        <span>
          {store.selectedIds.length} selected · {store.project.forms.reduce((n, f) => n + f.components.length, 0)} components
        </span>
        <span className="mono" style={{ marginLeft: 'auto' }}>
          {store.validation.filter((v) => v.severity === 'error').length} err ·{' '}
          {store.validation.filter((v) => v.severity === 'warning').length} warn
        </span>
      </footer>

      {showNew && (
        <NewProjectDialog
          lang={lang}
          onConfirm={(p) => {
            store.setProject(p);
            setShowNew(false);
            store.setStatus(L('status.generated'));
          }}
          onCancel={() => setShowNew(false)}
        />
      )}

      {helpModal && (
        <AboutDialog lang={lang} kind={helpModal} onClose={() => setHelpModal(null)} />
      )}

      {store.deleteModalOpen && (
        <ConfirmDialog
          title={lang === 'pl' ? 'Usuwanie komponentu' : 'Delete component'}
          message={lang === 'pl' ? 'Czy usunąć zaznaczony komponent?' : 'Delete the selected component?'}
          okLabel={lang === 'pl' ? 'OK' : 'OK'}
          cancelLabel={lang === 'pl' ? 'Anuluj' : 'Cancel'}
          onConfirm={() => store.confirmDelete()}
          onCancel={() => store.cancelDelete()}
        />
      )}
    </div>
  );
}

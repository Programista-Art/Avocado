/**
 * Project + UI state store (zustand).
 * Undo/redo via snapshot history.
 */
import { create } from 'zustand';
import type { ProjectModel, ComponentInstance, FormModel, ValidationIssue, ComponentCategory } from '@/types';
import { createEmptyProject, PROJECT_FORMAT_VERSION } from '@/types';
import { generateAvocadoSource } from '@/code-generator';
import { validateProject } from '@/validation';
import { getComponentMeta } from '@/framework/metadata';

let idSeq = 1;
export function nextId(prefix: string): string {
  return `${prefix}-${idSeq++}-${Date.now().toString(36)}`;
}

export function indexToAlpha(index: number): string {
  let s = '';
  let n = Math.max(0, index);
  while (n >= 0) {
    s = String.fromCharCode(97 + (n % 26)) + s;
    n = Math.floor(n / 26) - 1;
  }
  return s;
}

export const COMP_BASE_NAMES_PL: Record<string, string> = {
  button: 'przycisk',
  'image-button': 'przycisk_obrazkowy',
  label: 'etykieta',
  edit: 'pole_edycji',
  memo: 'notatnik',
  'rich-edit': 'bogaty_tekst',
  checkbox: 'pole_wyboru',
  'radio-button': 'przycisk_opcji',
  listbox: 'lista_wyboru',
  combobox: 'lista_rozwijana',
  trackbar: 'suwak',
  progressbar: 'pasek_postepu',
  'spin-edit': 'pole_numeryczne',
  panel: 'panel',
  'group-box': 'grupa',
  frame: 'ramka',
  line: 'linia',
  'circle-filled': 'kolo_wypelnione',
  'circle-outline': 'kolo_kontur',
  'circle-image': 'kolo_obraz',
  'image-box': 'pole_obrazu',
  'gradient-panel': 'panel_gradient',
  'rounded-panel': 'panel_zaokraglony',
  'rotated-image': 'obraz_obrocony',
  'service-webview': 'usluga_webview',
  'service-timer': 'usluga_zegar',
  'service-dialog': 'usluga_dialog',
  'service-clipboard': 'usluga_schowek',
  'service-printer': 'usluga_drukarka',
  'service-crypto': 'usluga_krypto',
};

export const COMP_BASE_NAMES_EN: Record<string, string> = {
  button: 'button',
  'image-button': 'image_button',
  label: 'label',
  edit: 'edit',
  memo: 'memo',
  'rich-edit': 'rich_edit',
  checkbox: 'checkbox',
  'radio-button': 'radio_button',
  listbox: 'listbox',
  combobox: 'combobox',
  trackbar: 'trackbar',
  progressbar: 'progressbar',
  'spin-edit': 'spin_edit',
  panel: 'panel',
  'group-box': 'group_box',
  frame: 'frame',
  line: 'line',
  'circle-filled': 'circle_filled',
  'circle-outline': 'circle_outline',
  'circle-image': 'circle_image',
  'image-box': 'image_box',
  'gradient-panel': 'gradient_panel',
  'rounded-panel': 'rounded_panel',
  'rotated-image': 'rotated_image',
  'service-webview': 'service_webview',
  'service-timer': 'service_timer',
  'service-dialog': 'service_dialog',
  'service-clipboard': 'service_clipboard',
  'service-printer': 'service_printer',
  'service-crypto': 'service_crypto',
};

export function generateComponentName(typeId: string, existingNames: Set<string>, lang: 'pl' | 'en' = 'pl'): string {
  const baseMap = lang === 'en' ? COMP_BASE_NAMES_EN : COMP_BASE_NAMES_PL;
  const base = baseMap[typeId] || typeId.replace(/-/g, '_').replace(/[^a-zA-Z_]/g, '');
  let idx = 0;
  while (true) {
    const candidate = `${base}_${indexToAlpha(idx)}`;
    if (!existingNames.has(candidate)) return candidate;
    idx++;
  }
}

interface HistoryEntry {
  project: ProjectModel;
}

interface AppState {
  project: ProjectModel;
  selectedFormId: string;
  selectedIds: string[];
  generatedCode: string;
  validation: ValidationIssue[];
  undoStack: HistoryEntry[];
  redoStack: HistoryEntry[];
  status: string;
  toolboxQuery: string;
  mode: 'design' | 'preview';
  clipboard: ComponentInstance[];

  setProject: (p: ProjectModel, markStatus?: string) => void;
  newProject: (name?: string) => void;
  pushHistory: () => void;
  undo: () => void;
  redo: () => void;

  select: (ids: string[]) => void;
  addComponent: (typeId: string, x: number, y: number, parentId?: string | null) => void;
  removeSelected: () => void;
  requestDelete: () => void;
  confirmDelete: () => void;
  cancelDelete: () => void;
  deleteModalOpen: boolean;
  duplicateSelected: () => void;
  copySelected: () => void;
  paste: (x?: number, y?: number) => void;
  moveComponent: (id: string, x: number, y: number) => void;
  moveComponents: (moves: { id: string; x: number; y: number }[]) => void;
  resizeComponent: (id: string, w: number, h: number, x?: number, y?: number) => void;
  setProp: (id: string, key: string, value: string | number | boolean) => void;
  renameComponent: (id: string, name: string) => void;
  setEvent: (id: string, event: string, handler: string) => void;
  setZIndex: (id: string, dir: 1 | -1) => void;

  updateForm: (patch: Partial<FormModel>) => void;
  updateSettings: (patch: Partial<ProjectModel['settings']>) => void;
  setUserCode: (handler: string, code: string) => void;

  regenerate: () => void;
  setToolboxQuery: (q: string) => void;
  setMode: (m: 'design' | 'preview') => void;
  setStatus: (s: string) => void;
  loadFromJson: (json: string) => boolean;
  getForm: () => FormModel | undefined;
}

function cloneProject(p: ProjectModel): ProjectModel {
  return JSON.parse(JSON.stringify(p)) as ProjectModel;
}

export const useAppStore = create<AppState>((set, get) => ({
  project: createEmptyProject(),
  selectedFormId: 'form-main',
  selectedIds: [],
  generatedCode: '',
  validation: [],
  undoStack: [],
  redoStack: [],
  status: 'Ready',
  toolboxQuery: '',
  mode: 'design',
  clipboard: [],
  deleteModalOpen: false,

  getForm: () => {
    const st = get();
    return st.project.forms.find((f) => f.id === st.selectedFormId);
  },

  setProject: (p, markStatus) => {
    set({
      project: p,
      selectedFormId: p.forms[0]?.id ?? 'form-main',
      selectedIds: [],
      undoStack: [],
      redoStack: [],
      status: markStatus ?? get().status,
    });
    get().regenerate();
  },

  newProject: (name) => {
    const p = createEmptyProject(name);
    set({
      project: p,
      selectedFormId: p.forms[0].id,
      selectedIds: [],
      undoStack: [],
      redoStack: [],
      status: 'New project',
    });
    get().regenerate();
  },

  pushHistory: () => {
    const p = get().project;
    set((s) => ({
      undoStack: [...s.undoStack.slice(-49), { project: cloneProject(p) }],
      redoStack: [],
    }));
  },

  undo: () => {
    const s = get();
    if (!s.undoStack.length) return;
    const prev = s.undoStack[s.undoStack.length - 1];
    set({
      project: prev.project,
      undoStack: s.undoStack.slice(0, -1),
      redoStack: [...s.redoStack, { project: cloneProject(s.project) }],
      selectedIds: [],
    });
    get().regenerate();
  },

  redo: () => {
    const s = get();
    if (!s.redoStack.length) return;
    const next = s.redoStack[s.redoStack.length - 1];
    set({
      project: next.project,
      redoStack: s.redoStack.slice(0, -1),
      undoStack: [...s.undoStack, { project: cloneProject(s.project) }],
      selectedIds: [],
    });
    get().regenerate();
  },

  select: (ids) => set({ selectedIds: ids }),

  addComponent: (typeId, x, y, parentId) => {
    const meta = getComponentMeta(typeId);
    if (!meta) return;
    get().pushHistory();
    const form = get().getForm();
    if (!form) return;
    const lang = get().project.settings.codeLang || 'pl';
    const existingNames = new Set(form.components.map((c) => c.name));
    const name = generateComponentName(typeId, existingNames, lang);
    const isContainer = Boolean(meta.isContainer || typeId === 'group-box');
    const maxZ = form.components.reduce((m, c) => Math.max(m, c.zIndex || 0), 0);
    const comp: ComponentInstance = {
      id: nextId('c'),
      typeId,
      name,
      parentId: parentId ?? null,
      x: Math.round(x),
      y: Math.round(y),
      w: meta.defaultSize.w,
      h: meta.defaultSize.h,
      props: Object.fromEntries(meta.properties.map((p) => [p.name, p.defaultValue ?? ''])),
      events: {},
      zIndex: isContainer ? Math.max(1, form.components.filter((c) => getComponentMeta(c.typeId)?.isContainer).length + 1) : Math.max(10, maxZ + 1),
    };
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (f) f.components.push(comp);
      return { project: p, selectedIds: [comp.id] };
    });
    get().regenerate();
  },

  requestDelete: () => {
    if (get().selectedIds.length) set({ deleteModalOpen: true });
  },
  cancelDelete: () => set({ deleteModalOpen: false }),
  confirmDelete: () => {
    set({ deleteModalOpen: false });
    get().removeSelected();
  },

  removeSelected: () => {
    get().pushHistory();
    const ids = new Set(get().selectedIds);
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (f) f.components = f.components.filter((c) => !ids.has(c.id) && !ids.has(c.parentId ?? ''));
      return { project: p, selectedIds: [] };
    });
    get().regenerate();
  },

  duplicateSelected: () => {
    const sel = get().selectedIds;
    if (!sel.length) return;
    get().pushHistory();
    const lang = get().project.settings.codeLang || 'pl';
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (!f) return { project: p };
      const newIds: string[] = [];
      const existingNames = new Set(f.components.map((c) => c.name));
      for (const id of sel) {
        const src = f.components.find((c) => c.id === id);
        if (!src) continue;
        const newName = generateComponentName(src.typeId, existingNames, lang);
        existingNames.add(newName);
        const copy: ComponentInstance = {
          ...JSON.parse(JSON.stringify(src)),
          id: nextId('c'),
          name: newName,
          x: src.x + 16,
          y: src.y + 16,
          zIndex: f.components.length + 1,
        };
        f.components.push(copy);
        newIds.push(copy.id);
      }
      return { project: p, selectedIds: newIds };
    });
    get().regenerate();
  },

  copySelected: () => {
    const form = get().getForm();
    if (!form) return;
    const ids = new Set(get().selectedIds);
    set({ clipboard: form.components.filter((c) => ids.has(c.id)).map((c) => JSON.parse(JSON.stringify(c))) });
  },

  paste: (x, y) => {
    const clip = get().clipboard;
    if (!clip.length) return;
    get().pushHistory();
    const lang = get().project.settings.codeLang || 'pl';
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (!f) return { project: p };
      const newIds: string[] = [];
      const existingNames = new Set(f.components.map((c) => c.name));
      for (const src of clip) {
        const newName = generateComponentName(src.typeId, existingNames, lang);
        existingNames.add(newName);
        const copy: ComponentInstance = {
          ...JSON.parse(JSON.stringify(src)),
          id: nextId('c'),
          name: newName,
          x: x ?? src.x + 24,
          y: y ?? src.y + 24,
          zIndex: f.components.length + 1,
        };
        f.components.push(copy);
        newIds.push(copy.id);
      }
      return { project: p, selectedIds: newIds };
    });
    get().regenerate();
  },

  moveComponent: (id, x, y) => {
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c && f) {
        const newX = Math.round(x);
        const newY = Math.round(y);
        const dx = newX - c.x;
        const dy = newY - c.y;
        const meta = getComponentMeta(c.typeId);
        if (meta?.isContainer || c.typeId === 'group-box') {
          for (const child of f.components) {
            if (child.id === c.id) continue;
            const cx = child.x + child.w / 2;
            const cy = child.y + child.h / 2;
            const isInside =
              child.parentId === c.id ||
              (cx >= c.x && cx <= c.x + c.w && cy >= c.y && cy <= c.y + c.h);
            if (isInside) {
              child.x = Math.round(child.x + dx);
              child.y = Math.round(child.y + dy);
            }
          }
        }
        c.x = newX;
        c.y = newY;
      }
      return { project: p };
    });
    get().regenerate();
  },

  moveComponents: (moves) => {
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (f) {
        for (const m of moves) {
          const c = f.components.find((comp) => comp.id === m.id);
          if (c) {
            c.x = Math.round(m.x);
            c.y = Math.round(m.y);
          }
        }
      }
      return { project: p };
    });
    get().regenerate();
  },

  resizeComponent: (id, w, h, x, y) => {
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c) {
        c.w = Math.max(8, Math.round(w));
        c.h = Math.max(8, Math.round(h));
        if (x !== undefined) c.x = Math.round(x);
        if (y !== undefined) c.y = Math.round(y);
      }
      return { project: p };
    });
    get().regenerate();
  },

  setProp: (id, key, value) => {
    get().pushHistory();
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c) c.props[key] = value;
      return { project: p };
    });
    get().regenerate();
  },

  renameComponent: (id, name) => {
    get().pushHistory();
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c) c.name = name;
      return { project: p };
    });
    get().regenerate();
  },

  setEvent: (id, event, handler) => {
    get().pushHistory();
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c) {
        if (handler) c.events[event] = handler;
        else delete c.events[event];
      }
      return { project: p };
    });
    get().regenerate();
  },

  setZIndex: (id, dir) => {
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      const c = f?.components.find((c) => c.id === id);
      if (c) c.zIndex = Math.max(0, c.zIndex + dir * 10);
      return { project: p };
    });
    get().regenerate();
  },

  updateForm: (patch) => {
    get().pushHistory();
    set((s) => {
      const p = cloneProject(s.project);
      const f = p.forms.find((x) => x.id === s.selectedFormId);
      if (f) Object.assign(f, patch);
      return { project: p };
    });
    get().regenerate();
  },

  updateSettings: (patch) => {
    set((s) => {
      const p = cloneProject(s.project);
      p.settings = { ...p.settings, ...patch };
      return { project: p };
    });
    get().regenerate();
  },

  setUserCode: (handler, code) => {
    set((s) => {
      const p = cloneProject(s.project);
      p.userCode[handler] = code;
      return { project: p };
    });
    get().regenerate();
  },

  regenerate: () => {
    const s = get();
    const form = s.project.forms.find((f) => f.id === s.selectedFormId) ?? s.project.forms[0];
    if (!form) {
      set({ generatedCode: '', validation: [] });
      return;
    }
    const code = generateAvocadoSource(s.project, form);
    const validation = validateProject(s.project);
    set({ generatedCode: code, validation });
  },

  setToolboxQuery: (q) => set({ toolboxQuery: q }),
  setMode: (m) => set({ mode: m }),
  setStatus: (st) => set({ status: st }),

  loadFromJson: (json) => {
    try {
      const data = JSON.parse(json) as ProjectModel;
      if (!data || typeof data !== 'object' || !Array.isArray(data.forms)) return false;
      if (data.formatVersion > PROJECT_FORMAT_VERSION) return false;
      get().setProject(data, 'Project loaded');
      return true;
    } catch {
      return false;
    }
  },
}));

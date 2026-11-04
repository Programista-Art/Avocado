/**
 * Core TypeScript models for Avocado GUI Builder.
 * Project format + framework metadata types.
 */

export type PrimitiveType =
  | 'string'
  | 'integer'
  | 'float'
  | 'boolean'
  | 'color'
  | 'enum'
  | 'list'
  | 'font'
  | 'image'
  | 'code'
  | 'point';

export interface FrameworkPropertyMeta {
  name: string;
  type: PrimitiveType;
  defaultValue?: string | number | boolean;
  description: string;
  descriptionPl?: string;
  enumValues?: string[];
  /** Pascal property name used in generated code */
  pascalName: string;
  /** Optional setter API, e.g. set_button_radius */
  setter?: string;
  group?: string;
}

export interface FrameworkEventMeta {
  name: string;
  pascalName: string;
  description: string;
  descriptionPl?: string;
  /** Avoraiser register function e.g. set_on_click */
  registerApi?: string;
  handlerSignature: string;
}

export interface FrameworkMethodMeta {
  name: string;
  pascalName: string;
  description: string;
  descriptionPl?: string;
  args: string[];
  returnType?: string;
}

export type ComponentCategory =
  | 'Windows'
  | 'Basic Controls'
  | 'Buttons'
  | 'Input Controls'
  | 'Text and Labels'
  | 'Containers'
  | 'Lists'
  | 'Images'
  | 'Layout'
  | 'Graphics'
  | 'Dialogs'
  | 'Custom Components';

export interface FrameworkComponentMeta {
  id: string;
  name: string;
  category: ComponentCategory;
  description: string;
  descriptionPl: string;
  icon: string;
  /** Avoraiser create function, e.g. utworz_przycisk / create_button */
  createApi: string;
  createApiEn: string;
  /** Pascal unit required in uses */
  unit: string;
  /** Default size on canvas */
  defaultSize: { w: number; h: number };
  /** Extra args for create beyond (parent, x, y, w, h) */
  createArgKind:
    | 'text'
    | 'text-color'
    | 'none'
    | 'text-image'
    | 'color'
    | 'id'
    | 'text-id'
    | 'circle'
    | 'circle-outline'
    | 'circle-image'
    | 'image-box'
    | 'line'
    | 'gradient'
    | 'rounded-panel'
    | 'rotated-image'
    | 'rich-edit';
  properties: FrameworkPropertyMeta[];
  events: FrameworkEventMeta[];
  methods: FrameworkMethodMeta[];
  canHaveChildren: boolean;
  isContainer: boolean;
}

export interface FrameworkMeta {
  name: string;
  version: string;
  description: string;
  units: string[];
  windowParams: FrameworkPropertyMeta[];
  components: FrameworkComponentMeta[];
  /** Global methods not tied to a component */
  globalMethods: FrameworkMethodMeta[];
}

/* -------------------- Project model -------------------- */

export interface Vec2 {
  x: number;
  y: number;
}

export interface Size {
  w: number;
  h: number;
}

export interface ComponentInstance {
  id: string;
  typeId: string;
  name: string;
  parentId: string | null;
  x: number;
  y: number;
  w: number;
  h: number;
  props: Record<string, string | number | boolean>;
  events: Record<string, string>;
  zIndex: number;
}

export interface FormModel {
  id: string;
  name: string;
  className: string;
  width: number;
  height: number;
  title: string;
  backgroundColor: string;
  frameless: boolean;
  allowMaximize: boolean;
  allowDrag: boolean;
  centerWindow: boolean;
  darkMode: boolean;
  opacity: number;
  onTop: boolean;
  /** child window (okno córka zależne) */
  isChild: boolean;
  parentFormId: string | null;
  visible: boolean;
  components: ComponentInstance[];
}

export interface ProjectSettings {
  language: 'en' | 'pl';
  theme: 'dark' | 'light';
  gridSize: number;
  snapToGrid: boolean;
  showGrid: boolean;
  showNames: boolean;
  zoom: number;
  /** generate Avocado code with Polish or English API names */
  codeLang: 'pl' | 'en';
  codegenMode: 'full' | 'unit';
  projectName: string;
  unitName: string;
  formClassName: string;
  namePrefix: string;
  emitDefaultProps: boolean;
}

export interface ProjectModel {
  formatVersion: number;
  framework: string;
  projectName: string;
  forms: FormModel[];
  settings: ProjectSettings;
  userCode: Record<string, string>;
  assets: { id: string; name: string; data: string }[];
}

export const PROJECT_FORMAT_VERSION = 1;

export function createEmptyProject(name = 'NowaAplikacja'): ProjectModel {
  return {
    formatVersion: PROJECT_FORMAT_VERSION,
    framework: 'Avoraraiser/Avocado',
    projectName: name,
    forms: [
      {
        id: 'form-main',
        name: 'MainForm',
        className: 'TMainForm',
        width: 640,
        height: 480,
        title: name,
        backgroundColor: '#202020',
        frameless: false,
        allowMaximize: true,
        allowDrag: true,
        centerWindow: true,
        darkMode: false,
        opacity: 255,
        onTop: false,
        isChild: false,
        parentFormId: null,
        visible: true,
        components: [],
      },
    ],
    settings: {
      language: 'pl',
      theme: 'dark',
      gridSize: 8,
      snapToGrid: true,
      showGrid: true,
      showNames: true,
      zoom: 1,
      codeLang: 'pl',
      codegenMode: 'full',
      projectName: name,
      unitName: 'MainForm',
      formClassName: 'TMainForm',
      namePrefix: '',
      emitDefaultProps: false,
    },
    userCode: {},
    assets: [],
  };
}

export interface ValidationIssue {
  id: string;
  severity: 'error' | 'warning' | 'info';
  message: string;
  messagePl: string;
  componentId?: string;
  formId?: string;
}

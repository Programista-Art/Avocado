/** EN / PL localization for Avocado GUI Builder UI. Pascal identifiers are never translated. */

export type Lang = 'en' | 'pl';

export const dict = {
  en: {
    appName: 'Avocado GUI Builder',
    menu: {
      file: 'File',
      edit: 'Edit',
      view: 'View',
      generate: 'Generate',
      help: 'Help',
      newProject: 'New Project',
      openProject: 'Open Project',
      saveProject: 'Save Project',
      saveAs: 'Save As',
      importAvocado: 'Import Avocado Source',
      exportAvocado: 'Export Avocado Project',
      exportJson: 'Export Project JSON',
      undo: 'Undo',
      redo: 'Redo',
      runPreview: 'Run Preview',
      generateCode: 'Generate Avocado Code',
      formatCode: 'Format Code',
      settings: 'Settings',
      language: 'Language',
      theme: 'Theme',
      dark: 'Dark',
      light: 'Light',
      about: 'About',
      addChildWindow: 'Add Child Window',
    },
    dialog: {
      newProjectTitle: 'New Avocado Application',
      appName: 'Application name',
      windowTitle: 'Window title',
      width: 'Width',
      height: 'Height',
      bgColor: 'Background color',
      opacity: 'Opacity',
      center: 'Center window',
      onTop: 'Always on top',
      frameless: 'Borderless window',
      dark: 'Dark mode',
      maximize: 'Allow maximize',
      codeLang: 'Avocado code language',
      cancel: 'Cancel',
      create: 'Create',
    },
    panels: {
      toolbox: 'Toolbox',
      canvas: 'Design',
      inspector: 'Object Inspector',
      hierarchy: 'Hierarchy',
      code: 'Avocado Code',
      preview: 'Preview',
      validation: 'Validation',
      events: 'Events',
    },
    search: 'Search components…',
    props: {
      name: 'Name',
      caption: 'Caption',
      text: 'Text',
      x: 'X',
      y: 'Y',
      width: 'Width',
      height: 'Height',
      color: 'Color',
      items: 'Items',
      value: 'Value',
      min: 'Min',
      max: 'Max',
    },
    actions: {
      delete: 'Delete',
      duplicate: 'Duplicate',
      copy: 'Copy',
      paste: 'Paste',
      rename: 'Rename',
      addEvent: 'Add handler',
      removeEvent: 'Remove',
      openHandler: 'Open in code',
      generateHandler: 'Generate template',
    },
    empty: {
      noSelection: 'Select a component on the canvas',
      noForm: 'No form in project',
      noComponents: 'Drop a component from the Toolbox',
      noIssues: 'No validation issues',
    },
    validation: {
      title: 'Validation',
      duplicateName: 'Duplicate component name',
      invalidName: 'Invalid Avocado identifier',
      missingParent: 'Parent not found',
      unsupportedType: 'Unsupported component type',
    },
    status: {
      saved: 'Project saved',
      loaded: 'Project loaded',
      generated: 'Avocado code generated',
      preview: 'Preview mode',
      design: 'Design mode',
    },
  },
  pl: {
    appName: 'Avocado GUI Builder',
    menu: {
      file: 'Plik',
      edit: 'Edycja',
      view: 'Widok',
      generate: 'Generuj',
      help: 'Pomoc',
      newProject: 'Nowy projekt',
      openProject: 'Otwórz projekt',
      saveProject: 'Zapisz projekt',
      saveAs: 'Zapisz jako',
      importAvocado: 'Importuj kod Avocado',
      exportAvocado: 'Eksportuj projekt Avocado',
      exportJson: 'Eksportuj JSON projektu',
      undo: 'Cofnij',
      redo: 'Ponów',
      runPreview: 'Podgląd',
      generateCode: 'Generuj kod Avocado',
      formatCode: 'Formatuj kod',
      settings: 'Ustawienia',
      language: 'Język',
      theme: 'Motyw',
      dark: 'Ciemny',
      light: 'Jasny',
      about: 'O programie',
      addChildWindow: 'Dodaj okno córkę',
    },
    dialog: {
      newProjectTitle: 'Nowa aplikacja Avocado',
      appName: 'Nazwa aplikacji',
      windowTitle: 'Tytuł okna',
      width: 'Szerokość',
      height: 'Wysokość',
      bgColor: 'Kolor tła',
      opacity: 'Przezroczystość',
      center: 'Wyśrodkuj okno',
      onTop: 'Zawsze na wierzchu',
      frameless: 'Okno bez ramki',
      dark: 'Ciemny motyw',
      maximize: 'Zezwól na maksymalizację',
      codeLang: 'Język kodu Avocado',
      cancel: 'Anuluj',
      create: 'Utwórz',
    },
    panels: {
      toolbox: 'Paleta',
      canvas: 'Projekt',
      inspector: 'Właściwości',
      hierarchy: 'Hierarchia',
      code: 'Kod Avocado',
      preview: 'Podgląd',
      validation: 'Walidacja',
      events: 'Zdarzenia',
    },
    search: 'Szukaj komponentów…',
    props: {
      name: 'Nazwa',
      caption: 'Napis',
      text: 'Tekst',
      x: 'X',
      y: 'Y',
      width: 'Szerokość',
      height: 'Wysokość',
      color: 'Kolor',
      items: 'Elementy',
      value: 'Wartość',
      min: 'Min',
      max: 'Max',
    },
    actions: {
      delete: 'Usuń',
      duplicate: 'Duplikuj',
      copy: 'Kopiuj',
      paste: 'Wklej',
      rename: 'Zmień nazwę',
      addEvent: 'Dodaj handler',
      removeEvent: 'Usuń',
      openHandler: 'Otwórz w kodzie',
      generateHandler: 'Generuj szablon',
    },
    empty: {
      noSelection: 'Zaznacz komponent na powierzchni',
      noForm: 'Brak formularza w projekcie',
      noComponents: 'Przeciągnij komponent z palety',
      noIssues: 'Brak problemów',
    },
    validation: {
      title: 'Walidacja',
      duplicateName: 'Zduplikowana nazwa komponentu',
      invalidName: 'Nieprawidłowy identyfikator Avocado',
      missingParent: 'Nie znaleziono rodzica',
      unsupportedType: 'Nieobsługiwany typ komponentu',
    },
    status: {
      saved: 'Projekt zapisany',
      loaded: 'Projekt wczytany',
      generated: 'Kod Avocado wygenerowany',
      preview: 'Tryb podglądu',
      design: 'Tryb projektowania',
    },
  },
} as const;

export type Dict = typeof dict.en;

export function t(lang: Lang, key: string): string {
  const parts = key.split('.');
  let cur: unknown = dict[lang] ?? dict.en;
  for (const p of parts) {
    if (cur && typeof cur === 'object' && p in (cur as Record<string, unknown>)) {
      cur = (cur as Record<string, unknown>)[p];
    } else {
      // fallback EN
      let en: unknown = dict.en;
      for (const p2 of parts) {
        if (en && typeof en === 'object' && p2 in (en as Record<string, unknown>)) {
          en = (en as Record<string, unknown>)[p2];
        } else return key;
      }
      return typeof en === 'string' ? en : key;
    }
  }
  return typeof cur === 'string' ? cur : key;
}

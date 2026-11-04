# Avocado GUI Builder

Visual IDE and code generator for **Avoraiser/Avocado** Pascal GUI applications.

Web (React + Vite + TypeScript) and Tauri 2-ready desktop shell.

## Features

- Component toolbox from real Avoraiser APIs (`utworz_przycisk`, `create_button`, …)
- Drag-and-drop design canvas with move / 8-way resize / snap-to-grid
- Object inspector (properties + events from framework metadata)
- Hierarchy panel, validation, undo/redo
- Deterministic **Pascal/Avocado** code generation (`program_ui`, `hwnd`, `utworz_*`, `set_on_*`)
- Code view with handler editing
- Live HTML preview (visual approximation)
- EN / PL UI, dark / light theme
- JSON project save/load, Pascal export
- Tauri-ready filesystem abstraction (`src-tauri/filesystem/fs-adapter.ts`)

## Framework source of truth

Metadata in `src/framework/metadata.ts` is derived from `avoraiser/*.pas`:

| Area | Source |
|---|---|
| Window params | `TAvocadoWindowParams` (avoraiser.window.pas) |
| Create APIs | `create_*` / `utworz_*` |
| Events | `set_on_click`, `set_on_change`, … |
| Units | avoraiser.button, .edit, .listbox, … |
| Polish aliases | `avocado_avoraiser_api.pas` |

No invented APIs. Unsupported runtime (HWND, GDI, WebView) is marked in preview.

## Install & run

```bash
cd avocado-gui-builder
npm install
npm run dev        # http://localhost:5173
npm run build      # production web build
npm run typecheck
```

### Tauri desktop (optional)

```bash
npm run tauri:dev    # requires Tauri 2 CLI
npm run tauri:build
```

Until Tauri commands are fully wired, the app uses the web filesystem adapter
(download / file picker). Swap in `invoke()` without changing UI.

## Project format

JSON (`formatVersion: 1`) — see `examples/demo-project.json`:

```json
{
  "formatVersion": 1,
  "framework": "Avoraraiser/Avocado",
  "projectName": "DemoForm",
  "forms": [{ "components": [], "title": "…", "width": 520, "height": 360 }],
  "settings": { "language": "en", "theme": "dark", "gridSize": 8 },
  "userCode": { "handler_name": "pascal body" }
}
```

## Generated code example

```pascal
program_ui DemoForm
import avoraiser.window
import avoraiser.layout
import avoraiser.button
...
hwnd my_window
hwnd przycisk_ok
main
  buduj_okno
  uruchom_aplikacje
end.

procedure buduj_okno
start
  ui_parameters ui
  ui = Default(TAvocadoWindowParams)
  ui.title = 'Avocado Demo'
  my_window = utworz_okno(ui)
  if my_window <> 0 then
  start
    przycisk_ok = utworz_przycisk(my_window, 'OK', 280, 54, 120, 32)
    ustaw_kolory_przycisku(przycisk_ok, $2D2D2D, $404040, $00AA00, $FFFFFF, $FFFFFF)
    set_on_click(przycisk_ok, @po_kliknieciu_ok)
  end
end
```

## Architecture

```
src/
  types/            Project + framework types
  framework/        metadata extracted from avoraiser
  code-generator/   Avocado/Pascal emitter
  state/            zustand store + undo/redo
  designer/         canvas (move/resize/drop)
  toolbox/          searchable palette
  object-inspector/ properties + events
  hierarchy/        tree
  code-editor/      generated code + handlers
  preview/          live HTML preview
  validation/       issues panel
  i18n/             EN/PL
  project-manager/  JSON I/O, Tauri adapter hook
```

## Adding a new framework component

1. Add entry in `src/framework/metadata.ts` (create API, unit, props, events).
2. Map rendering in `designer/DesignCanvas.tsx` and `preview/PreviewPanel.tsx` (optional).
3. Codegen picks it up automatically via `createArgKind`.

## Known limitations

- Browser preview cannot render HWND/GDI/WebView; components show visual placeholders.
- Monaco Editor is a dependency for richer editing (not required for basic code view).
- Tauri commands are abstracted but not fully implemented in `src-tauri`.
- Event handlers generate Pascal skeletons; runtime wiring is Avoraiser `set_on_*`.

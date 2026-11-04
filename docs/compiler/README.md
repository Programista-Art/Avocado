# Avocado compiler frontend — architecture, build, migration

## Layout

```
compiler/
  avocado_source.pas      Source text, byte offsets, UTF-8 line/column
  avocado_diagnostics.pas Diagnostics (stable codes, Polish messages)
  avocado_tokens.pas      Token kinds and token records
  avocado_language.pas    Keywords, type aliases, built-in registry, avoraiser_translate.ini
  avocado_lexer.pas       Single lexer (tokenizer)
  avocado_ast.pas         AST nodes (every node has a source span)
  avocado_parser.pas      Recursive descent + Pratt expressions
  avocado_symbols.pas     Symbol tables and scopes
  avocado_semantics.pas   Semantic analysis
  avocado_sourcemap.pas   Generated-Pascal line -> Avocado span
  avocado_codegen.pas     Deterministic Pascal generation
  avocado_compiler.pas    Facade: TAvocadoCompiler, TAvocadoCompileResult
tests/
  avocado_tests.lpr       Unit tests (no LCL)
  examplescan.lpr         Batch-translate examples
  e2e.lpr                 Emit Pascal for sample programs
tools/
  avocado_cli.lpr         check / translate / compile CLI
docs/
  avocado-grammar.md      Grammar (source of truth = examples)
  compiler/this file
```

The frontend depends only on FPC RTL (`SysUtils`, `Classes`). No Lazarus/LCL.

## Build

Tests and CLI (from the repository root):

```bat
fpc -Px86_64 -Twin64 -Fucompiler -FEtests -otests\avocado_tests tests\avocado_tests.lpr
tests\avocado_tests.exe

fpc -Px86_64 -Twin64 -Fucompiler -FEtools -otools\avocado_cli tools\avocado_cli.lpr
tools\avocado_cli.exe translate examples\hello.avocado -o hello.pas
tools\avocado_cli.exe check examples\hello.avocado
```

E2E compile of generated Pascal (requires the bundled `fpc\` tree):

```bat
fpc -Px86_64 -Twin64 -Fufpc\units\x86_64-win64\rtl -Fufpc\units\x86_64-win64\rtl-objpas -Fufpc\units\x86_64-win64\rtl-extra -Fufpc\units\x86_64-win64\rtl-console -Fufpc\units\x86_64-win64\winunits-base hello.pas
```

IDE project: `project1.lpi` now includes `compiler` on `OtherUnitFiles`.
Build with Lazarus (`lazbuild project1.lpi`) — **not verified in this environment**
(no `lazbuild` on PATH). Unit compile of the frontend *was* verified with FPC 3.2.2.

## Pipeline

```
TStrings / file
  -> TAvocadoSource (UTF-8, BOM strip, CP1250 fallback)
  -> TAvocadoLexer   (tokens with span)
  -> TAvocadoParser  (TAvocadoProgram AST)
  -> TAvocadoSemanticAnalyzer (symbols, scopes, checks)
  -> TAvocadoCodeGenerator    (Pascal + TAvocadoSourceMap)
  -> TAvocadoCompileResult
```

Each `Compile` call is isolated: no variables, labels, errors or project
kind leak between compilations (covered by tests).

## IDE integration

- `TAvocadoTranslator.Compile` returns `TAvocadoCompileResult`.
- `TAvocadoTranslator.Translate` is a compatibility facade over `Compile`.
- `IsGUIProject` is set from the structured result (`apkGui`).
- `DoAnalyzeAndTranslate` is the single analysis entry point; it fills
  `FErrAll` / `ListBoxErrCode` from structured diagnostics and **clears**
  `FTranslatedCode` on failure so stale Pascal cannot be compiled.
- `butCompileCodeClick` refuses to compile when diagnostics contain errors.
- `CheckAvocadoCode` (dictionary word check) is no longer the authoritative
  error source; the frontend is.

## Migration decisions

1. **Lexer ≠ two tokenizers.** One lexer unit; “tokenizer” is an alias.
2. **`=` is assignment in statements, equality in expressions.** The parser
   parses statement LHS as postfix-only so `a = f(x)` is an assignment.
3. **Polish `i` is NOT the keyword `and`.** It is the standard loop variable
   in examples. Use `and` for conjunction (legacy `REPLACE_RULES` also
   disabled `i`→`and`).
4. **Unclosed blocks at `koniec.`/`end.` are closed with a warning**, so
   examples like `hello.avocado` still compile.
5. **Unknown call names warn and delegate to FPC** (Pascal RTL / foreign
   units). Unknown types without imports error; with imports they warn.
   Unknown types are never silently replaced by `Variant`.
6. **Console programs do not use LCL `Dialogs`.** Only `program_ui` adds it.
7. **Duplicate `moduly\avocadotranslator.pas` renamed** to
   `avocado_translator_legacy.pas` (unit renamed to `AvocadoTranslatorLegacy`)
   so it can no longer shadow the project unit.

## Compatibility results (examples\*.avocado, 66 files)

| Result | Count | Notes |
|---|---|---|
| OK (translate, no errors) | 61 | includes warnings for FPC-delegated names |
| FAIL | 5 | see below |

Failures (classified, not regressions to paper over):

1. `Lista tekstów.avocado` — unquoted multi-word string (`Programista Art`)
2. `Lista tekstów2.avocado` — unquoted tokens (`Ala`, `ma`, `kota`)
3. `Lista wstawianie.avocado` — undeclared identifiers as list values
4. `Porównuje tekst 2.avocado` — unbalanced `jeżeli`/`koniec` (inventory)
5. `sprawdza blędy analizator statyczny.avocado` — intentional scope error

E2E: `calculation.avocado` → Pascal → FPC → runs and prints
`Calculation result: 8`. `hello`, `While`, `Funkcje` also compile with FPC;
they block on `Readln`/`ReadKey` at exit (interactive).

## Known limitations

- GUI (`program_ui`) programs are translated but not executed here
  (need Windows + avoraiser units + display). Reported as **blocked**.
- `moduły_pas` import list is emitted into `uses`; individual foreign
  member checks remain FPC’s job.
- Pascal format specifiers (`x:0:2`) work in call arguments only.
- `(* *)` comments are supported (nested); examples use `//`.
- IDE build (`lazbuild project1.lpi`) not run in this environment.
- Legacy `ProcessLine` code remains in `avocadotranslator.pas` unused;
  it can be deleted after a review period (kept for explicit comparison).

## Diagnostic codes

See `avocado_diagnostics.pas` (`AVO0001`…`AVO0040`). Messages are Polish
`resourcestring`-ready constants in that unit.

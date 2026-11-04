# Example inventory

Classification of `examples/**/*.avocado` after the new frontend.

## Reference set

Root `examples\*.avocado` (66 files) and subdirs other than `nie działają\`
are the compatibility target. `nie działają\` is explicitly non-working.

## Root examples (66)

- **61 translate with 0 errors** (some with warnings: unclosed-block recovery,
  FPC-delegated foreign names).
- **5 fail** (correctly diagnosed):

| File | Reason |
|---|---|
| `Lista tekstów.avocado` | unquoted multi-word string `Programista Art` |
| `Lista tekstów2.avocado` | unquoted tokens `Ala`, `ma`, `kota` |
| `Lista wstawianie.avocado` | undeclared identifiers as list values |
| `Porównuje tekst 2.avocado` | unbalanced `jeżeli`/`koniec` |
| `sprawdza blędy analizator statyczny.avocado` | intentional scope error (`moj_wiek` out of scope) |

## Subdirectories (summary)

- `listy\` — list I/O; some need quoted string literals.
- `nowe\` — mixed; `Mój system OS.avocado` has unbalanced blocks and Pascal
  syntax outside `pascal{`.
- `test\`, `Testowanie\` — scratch tests; several are incomplete.
- `ui\avoraiser\` — `program_ui` GUI programs; translated, not executed here
  (need avoraiser + display) → **blocked** for run verification.
- `ui\Editor\` — larger GUI experiments.
- `gry\` — game samples using `pascal{` with nested Pascal control flow.
- `nie działają\` — 29 files, not a target.

## Intentional corrections vs legacy

1. `=` in statements is assignment (legacy text-replace often broke this).
2. Polish `i` is a normal identifier, not `and`.
3. Nested call arguments split structurally (no `SplitArguments` heuristics).
4. Empty parentheses are not globally stripped.
5. Unclosed blocks at program end are closed with a warning (hello.avocado).

## E2E evidence

| Program | Translate | FPC | Run |
|---|---|---|---|
| `calculation.avocado` | OK | OK | `Calculation result: 8` |
| `hello.avocado` | OK (warning) | OK | blocks on ReadKey/Readln (interactive) |
| `While.avocado` | OK | OK | blocks on Readln (interactive) |
| `Funkcje.avocado` | OK | OK | blocks on Readln (interactive) |
| GUI samples | OK | not run | **blocked** (avotensor/avoraiser/display) |

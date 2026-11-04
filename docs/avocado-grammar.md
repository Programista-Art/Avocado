# Avocado language grammar (as implemented)

Source of truth: `examples/**/*.avocado` (130 files) and `avocadotranslator.pas` (root).
Documentation in `docs/documentation-pl.txt` lists only type spellings and is incomplete.

## Lexical structure

- Encoding: UTF-8 preferred. UTF-8 BOM is stripped. Legacy CP1250 input is converted at
  the source-loading boundary (`TAvocadoSource`).
- Line endings: LF and CRLF both accepted.
- Comments: `//` to end of line. `(* ... *)` with nesting (legacy-compatible).
- Identifiers: start with letter or `_`; may contain Polish diacritics
  (`ą ć ę ł ń ó ś ź ż` and ASCII). Case-insensitive for keywords and type names.
- Keywords are complete tokens. A keyword is never rewritten inside a longer
  identifier, a string, a comment, or an escape block.
- Integer literals: `123`, `$2D2D2D` (hex). Float literals: `22.5`.
- String literals: single quotes `'...'` with Pascal doubled-quote escape `''`.
  Double quotes are ordinary characters inside single-quoted strings.
- Operators / separators: `+ - * / = <> < > <= >= := @ . , : ; ( ) [ ] ^`
- `;` is an optional separator. Statements are newline-terminated.
- `.` is program-terminator suffix (`koniec.`), module separator (`avoraiser.window`)
  and member access (`ui.title`).

## Program structure

```
program     := header imports? decl* main_block subroutine* EOF
header      := ('program' | 'program_ui') IDENT
imports     := ('import' | 'importuj') module (',' module)*
module      := IDENT ('.' IDENT)*
main_block  := MAIN_OPEN statements MAIN_END '.'        // '.' required
subroutine  := ('procedura'|'procedure') IDENT params? MAIN_OPEN statements BLOCK_END
             | ('funkcja'|'function') IDENT params? ':' type MAIN_OPEN statements BLOCK_END
params      := '(' param (';' param)* ')'
param       := IDENT (',' IDENT)* ':' type
MAIN_OPEN   := 'początek'|'poczatek'|'start'|'główny'|'glowny'|'main'
MAIN_END    := 'koniec'|'end'
BLOCK_END   := 'koniec'|'end'
```

- `program_ui` marks a GUI project (`{$APPTYPE GUI}`, no trailing `Readln`).
- Subroutines are declared **after** the main block.
- Main block may also be opened by `start` / `main` (same as subroutine bodies).
- If statement blocks are still open at `koniec.` / `end.`, the parser closes them
  and reports a warning (compatibility with examples that omit the inner `koniec`).

## Statements (newline-terminated)

```
statement   := declaration
             | assignment
             | call
             | if_stmt
             | for_stmt
             | while_stmt
             | repeat_stmt
             | return_stmt
             | 'przerwij'|'break'
             | 'kontynuuj'|'continue'
             | 'exit'|'wyjście'|'wyjscie'
             | pascal_block
             | asm_block
             | block                    // 'początek'|'start' ... 'koniec'|'end'
declaration := type IDENT ('=' expr)?
assignment  := lvalue '=' expr
lvalue      := IDENT | IDENT '.' IDENT | IDENT '[' expr ']'
call        := IDENT args?
args        := '(' (expr (',' expr)*)? ')'
if_stmt     := ('jeżeli'|'jezeli'|'if') expr ('wtedy'|'then') stmt_or_block
               (('inaczej'|'else') stmt_or_block)?
stmt_or_block := statement | block
for_stmt    := ('dla'|'for') IDENT '=' expr ('do') expr ('wykonaj'|'wykonać'|'do') stmt_or_block
             | ('dla'|'for') IDENT '=' expr ('malejąco'|'malejaco'|'downto') expr
               ('wykonaj'|'wykonać'|'do') stmt_or_block
             | ('dla'|'for') IDENT ('w'|'in') expr ('wykonaj'|'wykonać'|'do') stmt_or_block
while_stmt  := ('dopóki'|'dopoki'|'while') expr ('wykonaj'|'wykonać'|'do'|'make')? stmt_or_block
repeat_stmt := 'repeat' statement* ('until'|'aż'|'az') expr
return_stmt := ('zwróć'|'zwroc'|'return') expr?
pascal_block:= 'pascal{' RAW '}' | 'pascal_linia{' RAW '}'
asm_block   := 'asm{' RAW '}'
```

Polish and English aliases produce the same AST. Mixed spelling in one file is valid
(`if` + `inaczej`, `while` + `wykonać`).

## Types (aliases → Pascal)

| Avocado | Pascal |
|---|---|
| `liczba_całkowita`, `liczba_calkowita`, `lc`, `int`, `integer` | `Integer` |
| `liczba_krótka`, `liczba_krotka`, `int8`, `shortint` | `ShortInt` |
| `liczba_mała`, `liczba_mala`, `int16`, `smallint` | `SmallInt` |
| `liczba_długa`, `liczba_dluga`, `int32`, `longint` | `LongInt` |
| `bajt`, `byte` | `Byte` |
| `liczba16`, `word`, `uint16` | `Word` |
| `liczba32`, `longword`, `uint32` | `LongWord` |
| `liczba64`, `int64` | `Int64` |
| `qliczba`, `qword` | `QWord` |
| `liczba_pojedyncza`, `single` | `Single` |
| `liczba_zm`, `lzm`, `real` | `Real` |
| `liczba_podwójna`, `liczba_podwojna`, `double`, `float` | `Double` |
| `liczba_rozszerzona`, `extended`, `float80` | `Extended` |
| `liczba_waluta`, `currency` | `Currency` |
| `logiczny`, `bool`, `boolean` | `Boolean` |
| `tekst`, `string` | `String` |
| `znak`, `char` | `Char` |
| `plik`, `file` | `File` |
| `plik_tekstowy`, `textfile`, `text_file` | `TextFile` |
| `lista_tekstów`, `lista_tekstow`, `string_list` | `TStringList` |
| `strumień_pliku`, `strumien_pliku`, `file_stream` | `TFileStream` |
| `uchwyt_okna`, `hwnd` | `HWND` |
| `parametry_ui`, `ui_parameters`, `ui_params` | `TAvocadoWindowParams` |
| `dialog_komunikatu`, `msg` | `TMsg` |
| `wariant`, `variant` | `Variant` |

Unknown type names are **not** silently replaced by `Variant`. They are reported and
delegated to FPC when the program imports a foreign unit.

## Expressions (Pratt)

Precedence (low → high):

1. `or`, `lub`
2. `and`, `i`
3. `=`, `<>`, `<`, `>`, `<=`, `>=`
4. `+`, `-`
5. `*`, `/`, `div`, `mod`
6. unary `-`, `+`, `not`, `@`
7. postfix: call `f(args)`, index `a[i]`, member `a.b`

`=` is both assignment (statement) and equality (expression).
`prawda`/`true`, `fałsz`/`falsz`/`false` are boolean literals.

## Escape blocks

`pascal{ ... }`, `pascal_linia{ ... }`, `asm{ ... }` capture raw text until the
matching `}`. Contents are never alias-substituted. Unterminated blocks are
reported precisely.

## Built-in resolution

- Keyword aliases (language) are centralized in `avocado_language.pas`.
- Built-in function aliases (`pisz_linie` → `WriteLn`, …) are resolved from the
  parsed call AST, not by substring search. `avoraiser_translate.ini` is loaded
  into the same registry.
- Automatic `uses` units are derived from actually resolved operations
  (`czytaj_klawisz` → `Crt`, `create_window` → `avoraiser.window`, …).

## Example classification

- Root `examples\*.avocado` and subdirs other than `nie działają\` are the
  reference set (some still have local defects; see `docs/compiler/example-inventory.md`).
- `examples\nie działają\` is explicitly non-working and is not a compatibility target.
- Empty files and files without a `program` header are incomplete.

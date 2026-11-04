# Avoraiser — przykłady GUI (nowe)

Cztery gotowe aplikacje okienkowe w języku Avocado na framework **Avoraiser**.

Wszystkie przechodzą analizę nowego kompilatora bez błędów.

| Plik | Co pokazuje |
|---|---|
| `01-proste-okno.avocado` | `program_ui`, `Default(TAvocadoWindowParams)`, `utworz_okno`, wyśrodkowanie |
| `02-przycisk-edytuj.avocado` | pole edycji, przyciski, `@handler` zdarzenia kliknięcia, dialogi |
| `03-lista-i-dialogi.avocado` | lista wyboru, dodawanie elementów, `pokaz_wiadomosc` / `pokaz_ostrzezenie` |
| `04-ciemny-motyw.avocado` | okno bez ramki, ciemny motyw, cień, kolory przycisków |

## Sprawdzenie składni

```bat
tools\avocado_cli.exe check examples\avoraiser-nowe\01-proste-okno.avocado
tools\avocado_cli.exe translate examples\avoraiser-nowe\02-przycisk-edytuj.avocado
```

## Schemat programu GUI

```
program_ui nazwa
import avoraiser.window
hwnd my_window
main
  buduj_okno
  uruchom_aplikacje
end.

procedure buduj_okno
start
  ui_parameters ui
  ui = Default(TAvocadoWindowParams)
  ui.title = '...'
  my_window = utworz_okno(ui)
  ...
end
```

Importowane jednostki (`avoraiser.button`, `.edit`, `.listbox`, …) są dodawane
automatycznie na podstawie wywołanych funkcji.

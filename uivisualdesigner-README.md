# Wizualny edytor UI Avoraiser (LCL)

Plik: `uivisualdesigner.pas`  
Uruchomienie z IDE Avocado: **File → Wizualny edytor UI (Avoraiser)**

## Co robi

Rysujesz interfejs na powierzchni projektowej zbudowanej z komponentów **LCL**,
a edytor generuje kod **Avocado / Avoraiser**:

```
program_ui moje_okno
import avoraiser.window
...
hwnd przycisk1
main
  buduj_okno
  uruchom_aplikacje
end.

procedure buduj_okno
start
  ui_parameters ui
  ui = Default(TAvocadoWindowParams)
  ui.title = 'Moja aplikacja'
  ...
  przycisk1 = utworz_przycisk(my_window, 'OK', 10, 10, 120, 32)
end
```

## Interfejs edytora

| Obszar | Zawartość |
|---|---|
| Góra | Nowy, Generuj kod, Kopiuj, Zapisz…, Usuń |
| Lewo | Paleta: przycisk, pole edycji, etykieta, lista, checkbox, notatnik, suwak, pasek postępu, panel |
| Środek | Powierzchnia projektowa (klik = dodaj, przeciągnij = przenieś) |
| Prawo | Właściwości okna (szer/wys, ciemny motyw, bez ramki) + lista elementów + siatka właściwości |
| Dół | Podgląd wygenerowanego kodu Avocado |

## Elementy → Avoraiser

| LCL / paleta | Funkcja Avoraiser |
|---|---|
| Przycisk | `utworz_przycisk` |
| Pole edycji | `utworz_pole_edycji` |
| Etykieta | `utworz_etykiete` |
| Lista | `utworz_liste_wyboru` |
| Pole wyboru | `utworz_pole_wyboru` |
| Notatnik | `utworz_notatnik` |
| Suwak | `utworz_suwak` |
| Pasek postępu | `utworz_pasek_postepu` |
| Panel | `utworz_panel` |

Importy (`avoraiser.button`, `avoraiser.edit`, …) są dodawane automatycznie.

## Zapis do IDE

1. W edytorze kliknij **Generuj kod**
2. **Kopiuj** lub **Zapisz…** → `plik.avocado`
3. Otwórz plik w IDE Avocado i **Kompiluj** (nowy frontend + FPC)

## Przebudowa IDE

Edytor jest częścią projektu (`project1.lpi`). Po zmianach przebuduj IDE w Lazarus
(`lazbuild project1.lpi`) — w tym środowisku nie było `lazbuild`, więc kompilacja
formularza LCL nie została tu zweryfikowana.

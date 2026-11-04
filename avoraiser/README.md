# Avoraiser UI Framework
### High-Performance WinAPI UI for Avocado

**Avoraiser is a framework for creating modern user interfaces for the Polish programming language [Avocado](https://github.com/Programista-Art/Avocado).**

---

## 🚀 Dlaczego Avoraiser?

Avoraiser to ultra-lekki framework UI zbudowany od podstaw w oparciu o czyste, natywne WinAPI. Został zaprojektowany dla deweloperów, którzy stawiają na maksymalną wydajność, minimalny rozmiar pliku `.exe` oraz brak zewnętrznych zależności (Zero-Runtime).

### Kluczowe atuty:
* **Ponad 400 natywnych funkcji systemowych** – pełna kontrola nad interfejsem.
* **Natywna wydajność** – bezpośrednie wywołania systemowe bez zbędnych, ociężałych warstw abstrakcji (VCL/LCL)..
* **Czyste WinAPI & GDI+** – sprzętowe renderowanie interfejsu, antyaliasing, przezroczystości (Alpha Channel) i zaokrąglone rogi kontrolek.
* **Optymalizacja pod Avocado** – idealnie dopasowany do składni i filozofii polskiego języka programowania.
* **Modern Look & Feel** – wbudowana obsługa Dark Mode, trybu Frameless (okna bez nagłówka) i płynnego skalowania.
* **Natywny system PDF** – wbudowany moduł generowania profesjonalnych dokumentów i raportów bezpośrednio do plików PDF z zachowaniem idealnych proporcji (Aspect Ratio).
* **Pełny Unicode** – bezproblemowa obsługa polskich znaków.

---

## 📊 Bezkonkurencyjna lekkość (Benchmark)

Porównanie wagi czystej aplikacji: **Avoraiser (Avocado) vs. LCL (Lazarus)**.

| Tryb kompilacji | LCL (Lazarus) | Avoraiser (Avocado) | Wynik |
| :--- | :--- | :--- | :--- |
| **Debug** | 26.8 MB | **1.1 MB** | **~24× mniejszy** |
| **Release** | 2628 KB | **68 KB** | **~38,7 mniejszy** |

**Werdykt:** Avoraiser nie obciąża aplikacji balastem widgetsetów i stylów. To czysta moc WinAPI, co skutkuje błyskawicznym startem i idealną charakterystyką dla aplikacji typu *portable*.

---

## Architektura i Komponenty (25 modułów / 402 funkcje)

Framework oferuje kompletny zestaw narzędzi do budowy profesjonalnego oprogramowania:

## I. Serce Frameworka (Logika i Okna)
1.  **avoraiser.core** – Pętla komunikatów okna (odświeżanie UI bez zawieszeń) i podstawowe struktury.
1.  **avoraiser.window** – Zaawansowane zarządzanie oknami (systemowe, Frameless, blokady maksymalizacji).
1.  **avoraiser.events** – Przechwytywanie sygnałów WinAPI i konwersja na zdarzenia (callbacks).
1.  **avoraiser.layout** – Responsywne skalowanie i zarządzanie pozycjami (X, Y).
1.  **avoraiser.utils** – Szybkie konwersje, obliczanie proporcji grafiki i przeliczanie czcionek.
## II. Silnik Wizualny i System (Graphics & OS)
1. **avoraiser.gdi** – Niskopoziomowe rysowanie kształtów, grafiki z pamięci RAM i wygładzanie krawędzi.
1. **avoraiser.system** – Zestaw funkcji WinAPI, obsługa Drag & Drop oraz trybu Dark Mode.
1. **avoraiser.dialogs** – Systemowe komunikaty i okna dialogowe (Open/Save, Drukarka).
1. **avoraiser.clipboard** – Szybki dostęp do pamięci schowka Windows.

## III. Podstawowe Kontrolki Interfejsu (Basic UI)
1. **avoraiser.button** – Przyciski tekstowe i graficzne z obsługą stanów Hover/Pressed.
1. **avoraiser.edit / avoraiser.memo** – Wydajna obsługa jedno i wieloliniowych pól tekstowych.
1. **avoraiser.richedit** – Formatowany tekst z obsługą standardów systemowych.
1. **avoraiser.labels** – Lekkie etykiety tekstowe z przezroczystym tłem.
1. **avoraiser.shape** – Geometryczne dekoracje interfejsu (linie, koła, prostokąty).

## IV. Kontrolki Zaawansowane (Advanced UI)
1. **avoraiser.combobox / avoraiser.listbox** – Szybka obsługa rozwijanych i otwartych list danych.
1. **avoraiser.checkbox / avoraiser.radiobutton / avoraiser.groupbutton** – Przełączniki systemowe i autorskie z logicznym grupowaniem.
1. **avoraiser.progressbar** – Paski postępu wspierające nowoczesny design (tryb tekstowy i graficzny).
1. **avoraiser.trackbar** – Precyzyjne suwaki systemowe.
1. **avoraiser.spinedit** – Numeryczne pola wyboru.
1. **avoraiser.timepicker** – Natywny wybór daty i czasu.
1. **avoraiser.menu** – Klasyczne paski nawigacyjne oraz menu kontekstowe.

# 💻 Szybki Start (Przykład użycia w Avocado)

## Tworzenie interfejsu w Avoraiserze wymaga ułamka kodu w porównaniu do standardowego WinAPI C/C++.
### Kod w Avocado
``` Avocado
program_ui okno
import avoraiser.window
hwnd my_window
main 
 my_win
 run_app
end.

procedure my_win
start
  ui_parameters ui
  ui = Default(TAvocadoWindowParams)
  ui.title = 'Okno w Avoraiser - Avocado'
  ui.width = 400
  ui.height = 600
  ui.x = 200
  ui.y = 200
  ui.visible = True

  //Tworzenie Okna Main
  my_window = create_window(ui)

  if my_window <> 0 then
  begin
  //Kod aplikacji
  end
end  
```
### Kod w Free Pascal (Lazarus)
```
{$codepage cp1252}
{$mode objfpc}
{$H+}
{$APPTYPE GUI}
program okno;
uses
  Windows, avoraiser.window;

var
  my_window: HWND;


procedure my_win;
var
  ui: TAvocadoWindowParams;
begin
ui := Default(TAvocadoWindowParams);
ui.title := 'Okno w Avoraiser - Avocado';
ui.width := 400;
ui.height := 600;
ui.x := 200;
ui.y := 200;
ui.visible := True;

//Tworzenie Okna Main
my_window := create_window(ui);

if my_window <> 0 then
begin;
  //Kod aplikacji
end;
end;

begin

my_win;
run_app;
end.
```
## Galeria Komponentów

| ListBox | ProgressBar | ComboBox |
| :---: | :---: | :---: |
| ![ListBox](img/ListBox.png) | ![ProgressBar](img/Progress_bar.png) | ![ComboBox](img/ComboBox.png) |

| Edit | TrackBar |
| :---: | :---: |
| ![Komunikat](img/Edit.png) | ![Komunikaty](img/TrackBar.png) |

| Komunikaty | Input |
| :---: | :---: |
| ![Komunikat](img/Avoraiser-komunikaty.png) | ![Komunikaty](img/Komunikaty.jpg) |


| Grafika GDI | Notatnik |
| :---: | :---: |
| ![Grafika GDI](img/GDI.png) | ![notatnik](img/notatnik.png) |


| Responsywne przyciski | Memo |
| :---: | :---: |
| ![Komunikat](img/gif/Animation.gif) | ![Komunikaty](img/gif/memo.gif) |


| Modern UI | Okna dialogowe |
| :---: | :---: |
| ![ModernUI](img/gif/modern-UI.gif) | ![Oknadialogowe ](img/gif/okna-dialogowego.gif) |

| Aktywne Okno | Przyciski |
| :---: | :---: |
| ![AktywneOkno](img/gif/Pauza.gif) | ![Przyciski ](img/gif/Przyciski.gif) |

| Zdarzenia nad nagłówkiem | Drag and drop |
| :---: | :---: |
| ![Zdarzenia nad nagłówkiem](img/gif/zdarzenia-nad-nagłowkiem.gif) | ![Drag and drop ](img/gif/drag-and-drop.gif) |


| Wykrywa Pendrive / Dysk | Scroll w memo |
| :---: | :---: |
| ![Zdarzenia nad nagłówkiem](img/gif/pendrive.gif) | ![Drag and drop ](img/gif/scroll.gif) |


| Czas | RichText |
| :---: | :---: |
| ![czas](img/gif/timer.gif) | ![Drag and drop ](img/gif/RichText2.gif) |
---
## Prosty kalkulator waży 86 kb
![Drag and drop ](img/Kalkulator-Avocado.png) 

## [Link do pobrania Kalkulatora ](https://sourceforge.net/projects/aplikacje-w-avoraiser/files/Prosty%20kalkulator/)



## ⚖️ Licencja (Dual-Licensing)

### [PL] Oprogramowanie Komercyjne
Avoraiser jest udostępniany w modelu **Source-Available** do celów edukacyjnych i ewaluacyjnych.
* **Użytek Niekomercyjny:** Darmowy (zgodnie z warunkami LICENSE.md).
* **Użytek Komercyjny:** Wymaga wykupienia płatnej licencji **per-developer**. Wykorzystanie zarobkowe bez licencji skutkuje karami umownymi (50 000 PLN).

### [EN] Commercial Software
Source code is visible for evaluation purposes only.
* **Non-commercial use:** Free under specific terms.
* **Commercial use:** Requires a paid per-developer license.
See `LICENSE.md` for full legal details.

---

## 👤 Autor i Kontakt

**Dymitr Wygowski (Programista Art)**
*Projekt zapoczątkowany: 23.12.2025*

* **Facebook:** [Programista Art](https://www.facebook.com/profile.php?id=61563368962907)
* **E-Mail:** [programista.art@gmail.com](mailto:programista.art@gmail.com)
* **WWW:** [avocado-code.com](https://avocado-code.com/)

---
*Created with passion for lightweight and efficient software.*
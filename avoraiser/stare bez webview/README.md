# Avoraiser UI Framework
### High-Performance WinAPI UI for Avocado

**Avoraiser is a framework for creating modern user interfaces for the Polish programming language [Avocado](https://github.com/Programista-Art/Avocado).**

---

## 🚀 Dlaczego Avoraiser?

Avoraiser to ultra-lekki framework UI zbudowany od podstaw w oparciu o czyste, natywne WinAPI. Został zaprojektowany dla deweloperów, którzy stawiają na maksymalną wydajność, minimalny rozmiar pliku `.exe` oraz brak zewnętrznych zależności (Zero-Runtime).

### Kluczowe atuty:
* **351 natywnych funkcji systemowych** – pełna kontrola nad interfejsem.
* **Natywna wydajność** – bezpośrednie wywołania systemowe bez zbędnych warstw abstrakcji.
* **Optymalizacja pod Avocado** – idealnie dopasowany do składni i filozofii polskiego języka programowania.
* **Modern Look & Feel** – nowoczesne komponenty przy zachowaniu systemowej lekkości.
* **Pełny Unicode** – bezproblemowa obsługa polskich znaków.

---

## 📊 Bezkonkurencyjna lekkość (Benchmark)

Porównanie wagi czystej aplikacji: **Avoraiser (Avocado) vs. LCL (Lazarus)**.

| Tryb kompilacji | LCL (Lazarus) | Avoraiser (Avocado) | Wynik |
| :--- | :--- | :--- | :--- |
| **Debug** | 26.8 MB | **1.1 MB** | **~24× mniejszy** |
| **Release** | 2628 KB | **62 KB** | **~42× mniejszy** |

**Werdykt:** Avoraiser nie obciąża aplikacji balastem widgetsetów i stylów. To czysta moc WinAPI, co skutkuje błyskawicznym startem i idealną charakterystyką dla aplikacji typu *portable*.

---

## 🛠 Zrealizowane Komponenty (18 modułów / 351 funkcji)

Framework oferuje kompletny zestaw narzędzi do budowy profesjonalnego oprogramowania:

1.  **Window** – Zaawansowane zarządzanie oknami (systemowe i Frameless).
2.  **Memo / Edit** – Wydajna obsługa pól tekstowych.
3.  **RichEdit** – Formatowany tekst z obsługą standardów systemowych.
4.  **Label** – Lekkie etykiety tekstowe.
5.  **ComboBox / ListBox** – Szybka obsługa list i wyboru danych.
6.  **Custom Button** – Przyciski z możliwością pełnej personalizacji graficznej.
7.  **CheckBox (Standard & Custom)** – Przełączniki systemowe i autorskie.
8.  **RadioButton / GroupButton** – Logiczne grupowanie opcji.
9.  **ProgressBar** – Paski postępu (tryb tekstowy i graficzny).
10. **TrackBar** – Precyzyjne suwaki systemowe.
11. **SpinEdit** – Numeryczne pola wyboru.
12. **TimePicker** – Natywny wybór czasu.
13. **GDI Graphics** – Niskopoziomowe rysowanie kształtów i grafiki.
14. **Dialogs** – Systemowe komunikaty i okna dialogowe.
15. **System Utils** – Zestaw funkcji pomocniczych WinAPI.

---

## 🖼 Galeria Komponentów

| ListBox | ProgressBar | ComboBox |
| :---: | :---: | :---: |
| ![ListBox](img/ListBox.png) | ![ProgressBar](img/Progress_bar.png) | ![ComboBox](img/ComboBox.png) |

| Edit | TrackBar |
| :---: | :---: |
| ![Edit](img/Edit.png) | ![TrackBar](img/TrackBar.png) |

---

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
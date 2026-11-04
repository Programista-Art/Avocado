import os
import sys

# Próba załadowania biblioteki do obsługi PDF
try:
    from pypdf import PdfReader
except ImportError:
    print("BŁĄD KRYTYCZNY: Brak biblioteki 'pypdf'.")
    print("Otwórz konsole i wpisz: pip install pypdf")
    sys.exit(1)

katalog = "trenowanie"

# Jeśli katalog nie istnieje, nie ma czego szukać
if not os.path.exists(katalog):
    print(f"Katalog '{katalog}' nie istnieje. Konwerter konczy prace.")
    sys.exit(0)

# Znajdź wszystkie pliki .pdf w folderze "trenowanie"
pliki_pdf = [f for f in os.listdir(katalog) if f.lower().endswith('.pdf')]

if not pliki_pdf:
    print("Brak plikow PDF do konwersji w folderze 'trenowanie'.")
    sys.exit(0)

print(f"Znaleziono {len(pliki_pdf)} plikow PDF. Rozpoczynam weryfikacje i konwersje...")

for plik in pliki_pdf:
    sciezka_pdf = os.path.join(katalog, plik)
    sciezka_txt = os.path.join(katalog, os.path.splitext(plik)[0] + ".txt")

    # ENTERPRISE GUARD: Optymalizacja. Jeśli plik TXT już istnieje, pomijamy konwersję.
    if os.path.exists(sciezka_txt):
        print(f" -> Pomijam: {plik} (plik .txt juz istnieje)")
        continue

    print(f" -> Konwertowanie: {plik} do formatu .txt...")
    try:
        reader = PdfReader(sciezka_pdf)
        tekst_calkowity = ""
        
        # Wyciąganie tekstu strona po stronie
        for strona in reader.pages:
            wyciagniety_tekst = strona.extract_text()
            if wyciagniety_tekst:
                tekst_calkowity += wyciagniety_tekst + "\n"

        # Zapis do pliku TXT z bezpiecznym kodowaniem UTF-8 dla polskich znaków
        with open(sciezka_txt, "w", encoding="utf-8") as f:
            f.write(tekst_calkowity)
            
        print(f"    Sukces! Zapisano {len(tekst_calkowity)} znakow.")
        
    except Exception as e:
        print(f"    [!] BŁĄD podczas konwersji pliku {plik}: {e}")

print("Proces konwersji PDF zakonczony!")
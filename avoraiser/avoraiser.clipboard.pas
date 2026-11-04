(*
Avoraiser UI Framework - High-Performance WinAPI UI for Avocado
Avoraiser is a framework for creating modern user interfaces for the Polish programming language Avocado.
Copyright (c) 2025-2026 Dymitr Wygowski (Programista Art)
Project Created: 23.12.2025

Author:     Dymitr Wygowski (Programista Art)
Contact:    programista.art@gmail.com
GitHub:     https://github.com/Programista-Art/Avoraiser
Version:    1.0
License:    Dual-Licensed: Avoraiser Community / Commercial
            See LICENSE.md for terms and conditions.

Module:     avoraiser.clipboard
Description:
*)

unit avoraiser.clipboard;

{$mode ObjFPC}{$H+}

interface

uses
  Windows,avoraiser.core;

// Działają dla Edit, Memo, RichEdit, ComboBox

procedure copy_to_clipboard(Handle: HWND);     // Kopiuje zaznaczenie
procedure cut_to_clipboard(Handle: HWND);      // Wycina zaznaczenie
procedure paste_from_clipboard(Handle: HWND);  // Wkleja w miejscu kursora
procedure undo_last_action(Handle: HWND);      // Cofnij (Ctrl+Z)
function can_undo(Handle: HWND): Boolean;      // Czy można cofnąć?
procedure show_context_menu(HTarget: HWND);

implementation

procedure copy_to_clipboard(Handle: HWND);
begin
   if Handle <> 0 then
      SendMessage(Handle, WM_COPY, 0, 0);
end;

procedure cut_to_clipboard(Handle: HWND);
begin
   if Handle <> 0 then
       SendMessage(Handle, WM_CUT, 0, 0);
end;

procedure paste_from_clipboard(Handle: HWND);
begin
   if Handle <> 0 then
       SendMessage(Handle, WM_PASTE, 0, 0);
end;

procedure undo_last_action(Handle: HWND);
begin
   if Handle <> 0 then
       // WM_UNDO jest uniwersalnym komunikatem dla kontrolek edycyjnych
       SendMessage(Handle, WM_UNDO, 0, 0);
end;

function can_undo(Handle: HWND): Boolean;
begin
    Result := False;
    if Handle <> 0 then
      // EM_CANUNDO działa dla wszystkich standardowych pól edycyjnych (Edit/Memo)
      Result := SendMessage(Handle, EM_CANUNDO, 0, 0) <> 0;
end;

procedure show_context_menu(HTarget: HWND);
var
  myMenu: HMENU;
  Pt: TPoint;
  Selection: Integer;
begin
    if HTarget = 0 then Exit;

      // 1. Tworzymy puste, "pływające" menu
      myMenu := CreatePopupMenu();

      // 2. Dodajemy pozycje (MF_STRING to tekst, MF_SEPARATOR to cienka linia oddzielająca)
      AppendMenuW(myMenu, MF_STRING, CMD_MENU_UNDO, 'Cofnij');
      AppendMenuW(myMenu, MF_SEPARATOR, 0, nil);
      AppendMenuW(myMenu, MF_STRING, CMD_MENU_CUT, 'Wytnij');
      AppendMenuW(myMenu, MF_STRING, CMD_MENU_COPY, 'Kopiuj');
      AppendMenuW(myMenu, MF_STRING, CMD_MENU_PASTE, 'Wklej');

      // 3. Pobieramy aktualną pozycję kursora na ekranie
      GetCursorPos(@Pt);

      // 4. Wyświetlamy menu!
      // MAGIA: TPM_RETURNCMD sprawia, że funkcja "zamraża się" tutaj i czeka na kliknięcie.
      // Zwraca ID klikniętej pozycji, a jeśli klikniesz poza menu, zwraca 0.
      Selection := Integer(TrackPopupMenu(myMenu,
                                  TPM_RIGHTBUTTON or TPM_RETURNCMD or TPM_NONOTIFY,
                                  Pt.X, Pt.Y, 0, HTarget, nil));

      // 5. Niszczymy menu z pamięci (żeby nie wyciekała!)
      DestroyMenu(myMenu);

      // 6. Odpalamy odpowiednią akcję z Twojego nowego modułu
      case Selection of
        CMD_MENU_UNDO:  undo_last_action(HTarget);
        CMD_MENU_CUT:   cut_to_clipboard(HTarget);
        CMD_MENU_COPY:  copy_to_clipboard(HTarget);
        CMD_MENU_PASTE: paste_from_clipboard(HTarget);
      end;
end;

end.


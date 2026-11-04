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

Module:     avoraiser.shape
Description:
*)

unit avoraiser.shape;

{$mode ObjFPC}{$H+}

interface

uses
   Windows, avoraiser.core;
const
  AV_PROP_COLOR = 'AvColor';


function get_prop_int(hWnd: HWND; PropName: PChar; Default: Integer = 0): Integer;
procedure set_prop_int(hWnd: HWND; PropName: PChar; Value: Integer);


implementation

function get_prop_int(hWnd: HWND; PropName: PChar; Default: Integer): Integer;
var
  Data: THandle;
begin
  Data := GetProp(hWnd, PropName);
  if Data = 0 then
    Result := Default
  else
    Result := Integer(Data);
end;

procedure set_prop_int(hWnd: HWND; PropName: PChar; Value: Integer);
begin
  SetProp(hWnd, PropName, THandle(Value));
end;



end.


program dbgapi;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_language, avocado_avoraiser_api;
var
  L: TAvocadoLanguage;
  B: TAvocadoBuiltin;
  T: TAvoApiTable;
  I: Integer;
begin
  WriteLn('table...');
  T := AvoraiserApiTable;
  WriteLn('count=', High(T)+1);
  WriteLn('lang...');
  L := TAvocadoLanguage.Create;
  WriteLn('find utworz_okno...');
  WriteLn(L.FindBuiltin('utworz_okno', B), ' -> ', B.PascalName);
  WriteLn('find przegladarka_stworz...');
  WriteLn(L.FindBuiltin('przegladarka_stworz', B), ' -> ', B.PascalName, ' unit=', B.RequiredUnit);
  WriteLn('OK');
  L.Free;
end.

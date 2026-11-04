program dbgu;
{$mode objfpc}{$H+}
uses SysUtils, Classes, avocado_source, avocado_ast;
var
  U: TAvocadoUnaryExpr;
  I: TAvocadoIdentExpr;
  Sp: TAvocadoSourceSpan;
begin
  Sp := EmptySpan;
  U := TAvocadoUnaryExpr.Create(Sp);
  WriteLn('created U');
  I := TAvocadoIdentExpr.Create(Sp);
  I.Name := 'bar';
  WriteLn('created I');
  U.Op := '@';
  U.Operand := I;
  WriteLn('assigned op=', U.Op, ' operand name=', TAvocadoIdentExpr(U.Operand).Name);
  WriteLn('freeing U...');
  U.Free;
  WriteLn('ok');
end.

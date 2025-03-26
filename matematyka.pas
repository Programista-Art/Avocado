unit matematyka;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpexprpars,Math;

function ObliczWyrazenie(const Expr: string): Double;

implementation


function ObliczWyrazenie(const Expr: string): Double;
var
  Parser: TFPExpressionParser;
  Res: TFPExpressionResult;
begin
  Result := 0;
  Parser := TFPExpressionParser.Create(nil);
  try
    try
      Parser.Expression := Expr;
      Parser.BuiltIns := [bcMath];
      Res := Parser.Evaluate;

      case Res.ResultType of
        rtInteger: Result := Res.ResInteger;
        rtFloat:   Result := Res.ResFloat;
        else
          raise Exception.Create('Nieobsługiwany typ wyniku');
      end;

      // Dokładne zaokrąglenie do 2 miejsc po przecinku
      Result := Round(Result * 100) / 100; // Klasyczne zaokrąglenie matematyczne
    except
      on E: Exception do
      begin
        WriteLn('Błąd przy obliczaniu wyrażenia: ' + E.Message);
        Result := 0;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

end.

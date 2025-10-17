unit matematyka;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpexprpars;


  function ObliczWyrazenie(const Expr: string): Double;
  //Funkcja zaokraglenia
  procedure format(Value: Double; DecimalPlaces: Integer = 2);
  //Tangens
  procedure ExprTan(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //ArcSin(x: Extended): Extended;
  procedure ExprArcSin(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //ArcCos(x: Extended): Extended;
  procedure ExprArcCos(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //ArcTan(x: Extended): Extended;
  procedure ExprArcTan(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //ArcTan2(y, x: Extended): Extended;
  procedure ExprArcTan2(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //DegToRad(Degrees: Extended): Extended;
  procedure ExprDegToRad(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Konwersja radianów na stopnie
  procedure ExprRadToDeg(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //sec
  procedure ExprSec(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Cotan(x: Extended): Extended;
  procedure ExprCotan(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // SINH
  procedure ExprSinh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // COSH
  procedure ExprCosh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // TANH
  procedure ExprTanh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ARSINH
  procedure ExprArcSinh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ARCOSH (z obsługą błędu dla x < 1)
  procedure ExprArcCosh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ARTANH (z obsługą błędu dla |x| >= 1)
  procedure ExprArcTanh(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ArcCot(x) = ArcTan(1/x), z obsługą x = 0
  procedure ExprArcCot(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ArcSec(x) = ArcCos(1/x), z obsługą |x| < 1
  procedure ExprArcSec(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // ArcCsc(x) = ArcSin(1/x), z obsługą |x| < 1
  procedure ExprArcCsc(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //coth(x)
  procedure ExprCoth(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //csch(x)
  procedure ExprCsch(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //sech(x)
  procedure ExprSech(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //cot
  procedure ExprCot(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //csc(x)
  procedure ExprCsc(var Result: TFPExpressionResult; const Args: TExprParameterArray);

  // Funkcja obsługująca wartość bezwzględną w parserze wyrażeń
  procedure ExprAbs(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Funkcja obsługująca kwadrat liczby w parserze wyrażeń
  procedure ExprSqr(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Funkcja obsługująca pierwiastek kwadratowy w parserze wyrażeń
  procedure ExprPierwiastek(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Funkcja obsługująca logarytm naturalny w parserze wyrażeń
  procedure ExprLogarytmNaturalny(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Funkcja obsługująca funkcję wykładniczą w parserze wyrażeń
  procedure ExprWykladnicza(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  // Funkcja obsługująca potęgowanie (base^exponent) w parserze wyrażeń
  procedure ExprPotega(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Inkrementuje zmienną x (zwiększa o 1).
  procedure ExprIncVar(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Dekrementuje zmienną x (zmniejsza o 1). Dec(x, n)
  procedure ExprDecVar(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Frac(x): Zwraca część ułamkową liczby zmiennoprzecinkowej.
  procedure ExprFrac(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //17.10.2025
  //Zwraca część całkowitą z liczby rzeczywistej X (jako Real).
  procedure ExprInt(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Sprawdza, czy liczba całkowita X jest nieparzysta (zwraca Boolean)
  procedure ExprOdd(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprLog10(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprLog2(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Sufit: najmniejsza liczba całkowita ≥ X.
  procedure ExprCeil(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprFloor(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //Przeciwprostokątna w trójkącie prostokątnym (X2+Y2).
  procedure ExprHypot(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprMin(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprMax(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprRound(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprTrunc(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprIsNaN(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  //nowe
  procedure ExprIsInfinite(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprIsNaNOrInfinity(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprIsZero(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprIsNegative(var Result: TFPExpressionResult; const Args: TExprParameterArray);

  {PO Polsku}
  procedure ExprSufit(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprPodloga(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprZaokraglic(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprMaks(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprOdciecie(var Result: TFPExpressionResult; const Args: TExprParameterArray);
  procedure ExprCzyJestNan(var Result: TFPExpressionResult; const Args: TExprParameterArray);
   //Inkrementuje zmienną x (zwiększa o 1).
  procedure ExprZwieksz(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    //Dekrementuje zmienną x (zmniejsza o 1). Dec(x, n)
  procedure ExprZmniejsz(var Result: TFPExpressionResult; const Args: TExprParameterArray);





implementation

uses
  Math;

// Deklaracje procedur obsługujących funkcje trygonometryczne cosinus
procedure ExprCos(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.ResFloat := Cos(ArgToFloat(Args[0]));
end;

//Sinus
procedure ExprSin(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.ResFloat := Sin(ArgToFloat(Args[0]));
end;

function ObliczWyrazenie(const Expr: string): Double;
var
  Parser: TFPExpressionParser;
  Res: TFPExpressionResult;
begin
  Result := 0;
   // Sprawdź czy wyrażenie nie jest puste
  if Trim(Expr) = '' then
  begin
    WriteLn('Błąd: Puste wyrażenie');
    Exit;
  end;

  Parser := TFPExpressionParser.Create(nil);
  try
    try
      // Konfiguracja parsera
      Parser.BuiltIns := [bcMath];
      Parser.Identifiers.AddFunction('cos', 'F', 'F', @ExprCos);
      Parser.Identifiers.AddFunction('sin', 'F', 'F', @ExprSin);
      Parser.Identifiers.AddFloatVariable('pi', Pi);
      Parser.Identifiers.AddFunction('tan', 'F', 'F', @ExprTan);
      Parser.Identifiers.AddFunction('arcsin', 'F', 'F', @ExprArcSin);
      Parser.Identifiers.AddFunction('arccos', 'F', 'F', @ExprArcCos);
      Parser.Identifiers.AddFunction('arctan', 'F', 'F', @ExprArcTan);
      Parser.Identifiers.AddFunction('arctan2', 'F', 'FF', @ExprArcTan2);
      Parser.Identifiers.AddFunction('degtorad', 'F', 'F', @ExprDegToRad);
      Parser.Identifiers.AddFunction('radtodeg', 'F', 'F', @ExprRadToDeg);
      Parser.Identifiers.AddFunction('sec', 'F', 'F', @ExprSec);
      Parser.Identifiers.AddFunction('cotan', 'F', 'F', @ExprCotan);
      Parser.Identifiers.AddFloatVariable('e', Exp(1));
      // Hiperboliczne
      Parser.Identifiers.AddFunction('sinh', 'F', 'F', @ExprSinh);
      Parser.Identifiers.AddFunction('cosh', 'F', 'F', @ExprCosh);
      Parser.Identifiers.AddFunction('tanh', 'F', 'F', @ExprTanh);

      // Odwrotne hiperboliczne
      Parser.Identifiers.AddFunction('arsinh', 'F', 'F', @ExprArcSinh);
      Parser.Identifiers.AddFunction('arcosh', 'F', 'F', @ExprArcCosh);
      Parser.Identifiers.AddFunction('artanh', 'F', 'F', @ExprArcTanh);
      Parser.Identifiers.AddFunction('arccot', 'F', 'F', @ExprArcCot);
      Parser.Identifiers.AddFunction('arcsec', 'F', 'F', @ExprArcSec);
      Parser.Identifiers.AddFunction('arccsc', 'F', 'F', @ExprArcCsc);
      Parser.Identifiers.AddFunction('coth', 'F', 'F', @ExprCoth);
      Parser.Identifiers.AddFunction('csch', 'F', 'F', @ExprCsch);
      Parser.Identifiers.AddFunction('sech', 'F', 'F', @ExprSech);
      Parser.Identifiers.AddFunction('cot', 'F', 'F', @ExprCot);
      Parser.Identifiers.AddFunction('csc', 'F', 'F', @ExprCsc);
      Parser.Identifiers.AddFunction('abs', 'F', 'F', @ExprAbs);
      Parser.Identifiers.AddFunction('sqr', 'F', 'F', @ExprSqr);
      //Parser.Identifiers.AddFunction('kwadrat_liczby', 'F', 'F', @ExprSqr);
      Parser.Identifiers.AddFunction('sqrt', 'F', 'F', @ExprPierwiastek);
      Parser.Identifiers.AddFunction('ln', 'F', 'F', @ExprLogarytmNaturalny);
      Parser.Identifiers.AddFunction('exp', 'F', 'F', @ExprWykladnicza);
      Parser.Identifiers.AddFunction('power', 'F', 'FF', @ExprPotega);
      Parser.Identifiers.AddFunction('inc', 'F','F', @ExprIncVar);
      Parser.Identifiers.AddFunction('dec', 'F','F', @ExprDecVar);

      //17.10.2025
      //nowa int Zwraca część całkowitą z liczby rzeczywistej X (jako Real).
      Parser.Identifiers.AddFunction('int', 'F', 'F', @ExprInt);
      Parser.Identifiers.AddFunction('odd', 'B', 'I', @ExprOdd);
      //Logarytm dziesiętny (log10(X)).
      Parser.Identifiers.AddFunction('log10', 'F', 'F', @ExprLog10);
      //Logarytm binarny (log2(X)).
      Parser.Identifiers.AddFunction('log2', 'F', 'F', @ExprLog2);
      Parser.Identifiers.AddFunction('ceil', 'F', 'F', @ExprCeil);
      Parser.Identifiers.AddFunction('floor', 'F', 'F', @ExprFloor);
      Parser.Identifiers.AddFunction('hypot', 'F', 'FF', @ExprHypot);
      Parser.Identifiers.AddFunction('min', 'F', 'FF', @ExprMin);
      Parser.Identifiers.AddFunction('max', 'F', 'FF', @ExprMax);
      Parser.Identifiers.AddFunction('round', 'F', 'F', @ExprRound);
      Parser.Identifiers.AddFunction('trunc', 'F', 'F', @ExprTrunc);
      Parser.Identifiers.AddFunction('is_nan', 'B', 'F', @ExprIsNaN);

      //nowe
      Parser.Identifiers.AddFunction('isinfinite', 'B', 'F', @ExprIsInfinite);
      Parser.Identifiers.AddFunction('isnanorinfinity', 'B', 'F', @ExprIsNaNOrInfinity);
      Parser.Identifiers.AddFunction('isnanorinf', 'B', 'F', @ExprIsNaNOrInfinity);
      Parser.Identifiers.AddFunction('iszero', 'B', 'F', @ExprIsZero);
      Parser.Identifiers.AddFunction('isnegative', 'B', 'F', @ExprIsNegative);
      //Funkcja zaokraglij



      {PO Polsku}
      Parser.Identifiers.AddFunction('ułamek', 'F', 'F', @ExprFrac);
      Parser.Identifiers.AddFunction('sufit', 'F', 'F', @ExprSufit);
      Parser.Identifiers.AddFunction('podłoga', 'F', 'F', @ExprPodloga);
      Parser.Identifiers.AddFunction('zaokrąglić', 'F', 'F', @ExprZaokraglic);
      Parser.Identifiers.AddFunction('maks', 'F', 'FF', @ExprMaks);
      Parser.Identifiers.AddFunction('odcięcie', 'F', 'F', @ExprOdciecie);
      Parser.Identifiers.AddFunction('czy_jest_nan', 'B', 'F', @ExprCzyJestNan);
      Parser.Identifiers.AddFunction('zwiększ', 'F','F', @ExprZwieksz);
      Parser.Identifiers.AddFunction('zmniejsz', 'F','F', @ExprZmniejsz);




      Parser.Expression := Expr;
      Res := Parser.Evaluate;

      // Obsługa wyniku
      case Res.ResultType of
        rtInteger: Result := Res.ResInteger;
        rtFloat:   Result := Res.ResFloat;
        // Konwersja Boolean na Double
        rtBoolean: if Res.ResBoolean then Result := 1 else Result := 0;
        else
          raise Exception.Create('Nieobsługiwany typ wyniku');
      end;



    except
      on E: Exception do
      begin
        WriteLn('Błąd: ' + E.Message);
        Result := 0;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

procedure format(Value: Double; DecimalPlaces: Integer);
begin
  if DecimalPlaces >= 0 then
    WriteLn(Value:0:DecimalPlaces)
  else
    WriteLn(Value);
end;


procedure ExprTan(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Tan(ArgToFloat(Args[0]));
end;

procedure ExprArcSin(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := ArcSin(ArgToFloat(Args[0]));
end;

procedure ExprArcCos(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := ArcCos(ArgToFloat(Args[0]));
end;

procedure ExprArcTan(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := ArcTan(ArgToFloat(Args[0]));
end;

procedure ExprArcTan2(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := ArcTan2(ArgToFloat(Args[0]), ArgToFloat(Args[1]));
end;

procedure ExprDegToRad(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := DegToRad(ArgToFloat(Args[0])); // Konwersja stopni na radiany
end;

procedure ExprRadToDeg(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := RadToDeg(ArgToFloat(Args[0])); // Konwersja radianów na stopnie
end;

procedure ExprSec(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := 1 / Cos(ArgToFloat(Args[0]));
end;

procedure ExprCotan(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Cotan(ArgToFloat(Args[0]));
end;

procedure ExprSinh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Sinh(ArgToFloat(Args[0]));
end;

procedure ExprCosh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Cosh(ArgToFloat(Args[0]));
end;

procedure ExprTanh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Tanh(ArgToFloat(Args[0]));
end;

procedure ExprArcSinh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := ArcSinh(ArgToFloat(Args[0]));
end;

procedure ExprArcCosh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
    if x < 1 then
      raise Exception.Create('arcosh(x) wymaga x >= 1');
    Result.ResFloat := ArcCosh(x);
end;

procedure ExprArcTanh(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
    if (x <= -1) or (x >= 1) then
      raise Exception.Create('artanh(x) wymaga |x| < 1');
    Result.ResFloat := ArcTanh(x);
end;

procedure ExprArcCot(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  if IsZero(x) then
    raise Exception.Create('arccot(x) nie jest zdefiniowany dla x=0');
  Result.ResFloat := ArcTan(1 / x);
end;

procedure ExprArcSec(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  if Abs(x) < 1 then
    raise Exception.Create('arcsec(x) wymaga |x| >= 1');
  Result.ResFloat := ArcCos(1 / x);
end;

procedure ExprArcCsc(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  if Abs(x) < 1 then
    raise Exception.Create('arccsc(x) wymaga |x| >= 1');
  Result.ResFloat := ArcSin(1 / x);
end;

procedure ExprCoth(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
   if IsZero(x) then
     raise Exception.Create('coth(x) nie jest zdefiniowany dla x=0');

   // Ręczna implementacja coth(x) = 1 / tanh(x)
   Result.ResFloat := 1 / Tanh(x);
end;

procedure ExprCsch(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
    if IsZero(x) then
      raise Exception.Create('csch(x) nie jest zdefiniowany dla x=0');
    Result.ResFloat := 1 / Sinh(x);
end;

procedure ExprSech(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := 1 / Cosh(ArgToFloat(Args[0])); // sech(x) = 1 / cosh(x)
end;

procedure ExprCot(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, tanX: Double;
begin
  x := ArgToFloat(Args[0]);
   tanX := Tan(x);

   // Sprawdź, czy tan(x) jest bliski zeru (uwzględniając precyzję zmiennoprzecinkową)
   if IsZero(tanX, 1E-12) then
     raise Exception.Create('cot(x) nie jest zdefiniowany dla x = kπ');

   Result.ResFloat := 1 / tanX; // cot(x) = 1 / tan(x)
end;

procedure ExprCsc(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, sinX: Double;
begin
  x := ArgToFloat(Args[0]);
   sinX := Sin(x);

   // Sprawdź, czy sin(x) jest bliski zeru (z tolerancją 1E-12)
   if IsZero(sinX, 1E-12) then
     raise Exception.Create('csc(x) nie jest zdefiniowany dla x = kπ');

   Result.ResFloat := 1 / sinX; // csc(x) = 1 / sin(x)
end;

procedure ExprAbs(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Abs(ArgToFloat(Args[0]));
end;

procedure ExprSqr(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Sqr(ArgToFloat(Args[0]));
end;

procedure ExprPierwiastek(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  if x < 0 then
    raise Exception.Create('Pierwiastek kwadratowy z liczby ujemnej nie istnieje!')
  else
    Result.ResFloat := Sqrt(x);
end;

procedure ExprLogarytmNaturalny(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  if x <= 0 then
    raise Exception.Create('Logarytm naturalny z liczby ≤ 0 nie jest dozwolony')
  else
    Result.ResFloat := Ln(x);
end;

procedure ExprWykladnicza(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
   Result.ResFloat := Exp(ArgToFloat(Args[0]));
end;

procedure ExprPotega(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  base, exponent: Double;
begin
  base := ArgToFloat(Args[0]);
  exponent := ArgToFloat(Args[1]);
  Result.ResFloat := Power(base, exponent);
end;

procedure ExprIncVar(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, n: Int64;
begin
  if Length(Args) = 1 then
   begin
     x := Round(ArgToFloat(Args[0]));
     Result.ResFloat := x + 1;
   end
   else if Length(Args) = 2 then
   begin
     x := Round(ArgToFloat(Args[0]));
     n := Round(ArgToFloat(Args[1]));
     Result.ResFloat := x + n;
   end
   else
     raise Exception.Create('zwiększ(x [,n]): oczekiwano 1 lub 2 argumentów.');
end;

procedure ExprDecVar(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, n: Int64;
begin
  if Length(Args) = 1 then
   begin
     x := Round(ArgToFloat(Args[0]));
     Result.ResFloat := x - 1;
   end
   else if Length(Args) = 2 then
   begin
     x := Round(ArgToFloat(Args[0]));
     n := Round(ArgToFloat(Args[1]));
     Result.ResFloat := x - n;
   end
   else
     raise Exception.Create('zmniejsz(x [,n]): oczekiwano 1 lub 2 argumentów.');
end;

procedure ExprFrac(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Frac(ArgToFloat(Args[0]));
end;

procedure ExprInt(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
   Result.ResInteger := Trunc(ArgToFloat(Args[0]));
end;

procedure ExprOdd(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Int64;
begin
    x := Args[0].ResInteger; // Pobieramy wartość całkowitą
    Result.ResBoolean := Odd(x); // Wykorzystujemy wbudowaną funkcję Odd
    Result.ResultType := rtBoolean; // Ustawiamy typ wyniku na Boolean
end;

procedure ExprLog10(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);

    if x <= 0 then
      raise Exception.Create('log10(x) wymaga x > 0');

    Result.ResFloat := Log10(x);
end;

procedure ExprLog2(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);

   if x <= 0 then
     raise Exception.Create('log2(x) wymaga x > 0');

   Result.ResFloat := Log2(x);
end;

procedure ExprCeil(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Ceil(ArgToFloat(Args[0]));
end;

procedure ExprSufit(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Ceil(ArgToFloat(Args[0]));
end;

procedure ExprFloor(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Floor(ArgToFloat(Args[0]));
end;

procedure ExprHypot(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Hypot(ArgToFloat(Args[0]), ArgToFloat(Args[1]));
end;

procedure ExprMin(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, y: Double;
begin
   x := ArgToFloat(Args[0]);
   y := ArgToFloat(Args[1]);

   if x < y then
     Result.ResFloat := x
   else
     Result.ResFloat := y;
 end;

procedure ExprMax(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, y: Double;
begin
  x := ArgToFloat(Args[0]);
  y := ArgToFloat(Args[1]);

  if x > y then
    Result.ResFloat := x
  else
    Result.ResFloat := y;
end;

procedure ExprRound(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResFloat := Round(x);
end;

procedure ExprTrunc(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResFloat := Trunc(x);
end;

procedure ExprIsNaN(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
   x := ArgToFloat(Args[0]);
   Result.ResBoolean := IsNaN(x);
   Result.ResultType := rtBoolean;
end;

procedure ExprIsInfinite(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResBoolean := IsInfinite(x);
  Result.ResultType := rtBoolean;
end;

procedure ExprIsNaNOrInfinity(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResBoolean := IsNaN(x) or IsInfinite(x);
  Result.ResultType := rtBoolean;
end;

procedure ExprIsZero(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResBoolean := IsZero(x);
  Result.ResultType := rtBoolean;
end;

procedure ExprIsNegative(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResBoolean := x < 0;
  Result.ResultType := rtBoolean;
end;

procedure ExprOdciecie(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
   Result.ResFloat := Trunc(x);
end;

procedure ExprCzyJestNan(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResBoolean := IsNaN(x);
  Result.ResultType := rtBoolean;
end;

procedure ExprZwieksz(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, n: Int64;
begin
    if Length(Args) = 1 then
   begin
     x := Round(ArgToFloat(Args[0]));
     Result.ResFloat := x + 1;
   end
   else if Length(Args) = 2 then
   begin
     x := Round(ArgToFloat(Args[0]));
     n := Round(ArgToFloat(Args[1]));
     Result.ResFloat := x + n;
   end
   else
     raise Exception.Create('zwiększ(x [,n]): oczekiwano 1 lub 2 argumentów.');

end;

procedure ExprZmniejsz(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, n: Int64;
begin
  if Length(Args) = 1 then
 begin
   x := Round(ArgToFloat(Args[0]));
   Result.ResFloat := x - 1;
 end
 else if Length(Args) = 2 then
 begin
   x := Round(ArgToFloat(Args[0]));
   n := Round(ArgToFloat(Args[1]));
   Result.ResFloat := x - n;
 end
 else
   raise Exception.Create('zmniejsz(x [,n]): oczekiwano 1 lub 2 argumentów.');

end;


procedure ExprPodloga(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResFloat := Floor(ArgToFloat(Args[0]));
end;

procedure ExprZaokraglic(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x: Double;
begin
  x := ArgToFloat(Args[0]);
  Result.ResFloat := Round(x);
end;

procedure ExprMaks(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
var
  x, y: Double;
begin
  x := ArgToFloat(Args[0]);
  y := ArgToFloat(Args[1]);

  if x > y then
    Result.ResFloat := x
  else
    Result.ResFloat := y;
end;


end.

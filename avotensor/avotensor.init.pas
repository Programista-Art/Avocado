{$mode objfpc}{$H+}
unit avotensor.init;

// avotensor.init — inicjalizacja wag sieci neuronowej

interface

uses
  SysUtils, Math,
  avotensor.core;

// Xavier uniform: U(-limit, limit), limit = sqrt(6 / (FanIn + FanOut))
// Dobry dla: sigmoid, tanh, warstw liniowych
procedure InitXavierUniform(T: TAvoTensor; FanIn, FanOut: Integer);

// Xavier normal: N(0, std), std = sqrt(2 / (FanIn + FanOut))
procedure InitXavierNormal(T: TAvoTensor; FanIn, FanOut: Integer);

// He uniform: U(-limit, limit), limit = sqrt(6 / FanIn)
// Dobry dla: ReLU
procedure InitHeUniform(T: TAvoTensor; FanIn: Integer);

// He normal: N(0, std), std = sqrt(2 / FanIn)
procedure InitHeNormal(T: TAvoTensor; FanIn: Integer);

// Stala wartosc (np. 0.0 dla biasow)
procedure InitConstant(T: TAvoTensor; Value: Single);

// Losowy jednostajny z zakresu [Low, High]
procedure InitUniform(T: TAvoTensor; LowVal, HighVal: Single);

implementation

// Przyblizenie liczby losowej z rozkladu normalnego N(0,1)
// Metoda Box-Mullera (bez zewnetrznych zaleznosci)
function RandNormal: Single;
var
  U1, U2: Single;
begin
  repeat U1 := Random until U1 > 0.0;
  U2     := Random;
  Result := Sqrt(-2.0 * Ln(U1)) * Cos(2.0 * Pi * U2);
end;

// =============================================================================

procedure InitXavierUniform(T: TAvoTensor; FanIn, FanOut: Integer);
var
  i:     Integer;
  Limit: Single;
begin
  if T = nil then raise Exception.Create('InitXavierUniform: Tensor jest nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitXavierUniform: Tensor ma niespójny NumEl i Data.');
  if (FanIn + FanOut) <= 0 then raise Exception.Create('InitXavierUniform: FanIn + FanOut musi byc > 0.');

  Limit := Sqrt(6.0 / (FanIn + FanOut));
  for i := 0 to High(T.Data) do
    T.Data[i] := (Random * 2.0 * Limit) - Limit;
end;

procedure InitXavierNormal(T: TAvoTensor; FanIn, FanOut: Integer);
var
  i:   Integer;
  Std: Single;
begin
  if T = nil then raise Exception.Create('InitXavierNormal: Tensor to nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitXavierNormal: Tensor ma niespójny NumEl i Data.');
  if (FanIn + FanOut) <= 0 then raise Exception.Create('InitXavierNormal: FanIn + FanOut musi byc > 0.');

  Std := Sqrt(2.0 / (FanIn + FanOut));
  for i := 0 to High(T.Data) do
    T.Data[i] := RandNormal * Std;
end;

procedure InitHeUniform(T: TAvoTensor; FanIn: Integer);
var
  i:     Integer;
  Limit: Single;
begin
  if T = nil then raise Exception.Create('InitHeUniform: Tensor to nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitHeUniform: Tensor ma niespójny NumEl i Data.');
  if FanIn <= 0 then raise Exception.Create('InitHeUniform: FanIn musi byc > 0.');

  Limit := Sqrt(6.0 / FanIn);
  for i := 0 to High(T.Data) do
    T.Data[i] := (Random * 2.0 * Limit) - Limit;
end;

procedure InitHeNormal(T: TAvoTensor; FanIn: Integer);
var
  i:   Integer;
  Std: Single;
begin
  if T = nil then raise Exception.Create('InitHeNormal: Tensor to nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitHeNormal: Tensor ma niespójny NumEl i Data.');
  if FanIn <= 0 then raise Exception.Create('InitHeNormal: FanIn musi byc > 0.');

  Std := Sqrt(2.0 / FanIn);
  for i := 0 to High(T.Data) do
    T.Data[i] := RandNormal * Std;
end;

procedure InitConstant(T: TAvoTensor; Value: Single);
var i: Integer;
begin
  if T = nil then raise Exception.Create('InitConstant: Tensor to nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitConstant: Tensor ma niespójny NumEl i Data.');

  for i := 0 to High(T.Data) do T.Data[i] := Value;
end;

procedure InitUniform(T: TAvoTensor; LowVal, HighVal: Single);
var
  i:     Integer;
  Range: Single;
begin
  if T = nil then raise Exception.Create('InitUniform: Tensor to nil.');
  if T.NumEl <> Length(T.Data) then raise Exception.Create('InitUniform: Tensor ma niespójny NumEl i Data.');
  if HighVal < LowVal then raise Exception.Create('InitUniform: HighVal < LowVal.');

  Range := HighVal - LowVal;
  for i := 0 to High(T.Data) do
    T.Data[i] := LowVal + Random * Range;
end;

end.

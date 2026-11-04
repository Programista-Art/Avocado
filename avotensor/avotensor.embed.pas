{$mode objfpc}{$H+}
unit avotensor.embed;
// avotensor.embed — warstwa embeddingów i kodowanie pozycyjne
interface

uses
  SysUtils, Math, Types,
  avotensor.core,
  avotensor.init;

type
  TAvoEmbeddingLayer = class
  public
    Wagi:      TAvoTensor; // [VocabSize, EmbDim]
    VocabSize: Integer;
    EmbDim:    Integer;

    constructor Create(AVocabSize, AEmbDim: Integer);
    destructor  Destroy; override;

    // Zamienia sekwencję ID → macierz embeddingów [SeqLen, EmbDim]
    function Forward(const IDs: TIntegerDynArray): TAvoTensor;

    // Backward: akumuluje gradienty w Wagi.Grad
    // DOut: gradient z góry [SeqLen, EmbDim]
    procedure Backward(DOut: TAvoTensor; const IDs: TIntegerDynArray);

    // Zeruje gradienty wag
    procedure ZeroGrad;

    // Krok SGD na wagach embeddingów
    procedure Step(LearningRate: Single);
  end;

  TAvoPositionalEncoding = class
  public
    Table:  TAvoTensor; // [MaxSeqLen, EmbDim] — prekalkulowana tablica PE
    MaxSeqLen: Integer;
    EmbDim:    Integer;

    constructor Create(AMaxSeqLen, AEmbDim: Integer);
    destructor  Destroy; override;

    // Dodaje PE do macierzy embeddingów in-place
    // Input: [SeqLen, EmbDim] — modyfikowany bezpośrednio
    procedure AddTo(Embeddings: TAvoTensor);

    // Zwraca nowy tensor = Embeddings + PE (nie modyfikuje wejścia)
    function Apply(Embeddings: TAvoTensor): TAvoTensor;
  end;

implementation


// TAvoEmbeddingLayer


constructor TAvoEmbeddingLayer.Create(AVocabSize, AEmbDim: Integer);
begin
  if AVocabSize <= 0 then raise Exception.Create('EmbeddingLayer.Create: VocabSize musi byc > 0.');
  if AEmbDim <= 0 then raise Exception.Create('EmbeddingLayer.Create: EmbDim musi byc > 0.');

  VocabSize := AVocabSize;
  EmbDim    := AEmbDim;
  Wagi      := TAvoTensor.Create([AVocabSize, AEmbDim]);

  // Inicjalizacja: mała losowa wartość — standardowa dla embeddingów
  InitUniform(Wagi, -0.1, 0.1);
end;

destructor TAvoEmbeddingLayer.Destroy;
begin
  if Wagi <> nil then Wagi.Free;
  inherited Destroy;
end;

function TAvoEmbeddingLayer.Forward(const IDs: TIntegerDynArray): TAvoTensor;
var
  SeqLen, i, j, TokenID: Integer;
begin
  if Wagi = nil then raise Exception.Create('EmbeddingLayer.Forward: Wagi = nil.');
  if Wagi.NumEl <> Length(Wagi.Data) then raise Exception.Create('EmbeddingLayer.Forward: Korupcja tensora Wagi.');

  SeqLen := Length(IDs);
  if SeqLen = 0 then
    raise Exception.Create('EmbeddingLayer.Forward: Pusta sekwencja ID.');

  Result := TAvoTensor.Create([SeqLen, EmbDim]);

  for i := 0 to SeqLen - 1 do
  begin
    TokenID := IDs[i];

    if (TokenID < 0) or (TokenID >= VocabSize) then
    begin
      Result.Free;
      raise Exception.CreateFmt(
        'EmbeddingLayer.Forward: Token ID=%d poza zakresem [0,%d).',
        [TokenID, VocabSize]);
    end;

    // Skopiuj wiersz Wagi[TokenID, :] → Result[i, :]
    for j := 0 to EmbDim - 1 do
      Result.Data[i * EmbDim + j] := Wagi.Data[TokenID * EmbDim + j];
  end;
end;

procedure TAvoEmbeddingLayer.Backward(DOut: TAvoTensor; const IDs: TIntegerDynArray);
var
  SeqLen, i, j, TokenID: Integer;
begin
  if DOut = nil then raise Exception.Create('EmbeddingLayer.Backward: DOut = nil.');
  if Wagi = nil then raise Exception.Create('EmbeddingLayer.Backward: Wagi = nil.');

  if DOut.NumEl <> Length(DOut.Data) then raise Exception.Create('EmbeddingLayer.Backward: Korupcja tensora DOut.');
  if Wagi.NumEl <> Length(Wagi.Grad) then raise Exception.Create('EmbeddingLayer.Backward: Korupcja gradientu Wagi.');

  if Length(DOut.Shape) <> 2 then
    raise Exception.CreateFmt('EmbeddingLayer.Backward: DOut musi byc 2D, otrzymano %dD.', [Length(DOut.Shape)]);

  if DOut.Shape[1] <> EmbDim then
    raise Exception.CreateFmt('EmbeddingLayer.Backward: Niezgodny wymiar cech w DOut (Oczekiwano %d, jest %d).', [EmbDim, DOut.Shape[1]]);

  SeqLen := Length(IDs);
  if DOut.Shape[0] <> SeqLen then
    raise Exception.CreateFmt(
      'EmbeddingLayer.Backward: Niezgodna dlugosc — DOut.SeqLen=%d, dlugosc tablicy IDs=%d.',
      [DOut.Shape[0], SeqLen]);

  // Jeśli ten sam token pojawia się wielokrotnie — gradienty się sumują
  for i := 0 to SeqLen - 1 do
  begin
    TokenID := IDs[i];
    //if (TokenID >= 0) and (TokenID < VocabSize) then
    if (TokenID < 0) or (TokenID >= VocabSize) then
     raise Exception.CreateFmt('EmbeddingLayer.Backward: Token ID=%d poza zakresem [0,%d).',[TokenID, VocabSize]);

     for j := 0 to EmbDim - 1 do
          Wagi.Grad[TokenID * EmbDim + j] :=
          Wagi.Grad[TokenID * EmbDim + j] + DOut.Data[i * EmbDim + j];
  end;
end;

procedure TAvoEmbeddingLayer.ZeroGrad;
var i: Integer;
begin
  if Wagi = nil then raise Exception.Create('EmbeddingLayer.ZeroGrad: Wagi = nil.');
  if Wagi.NumEl <> Length(Wagi.Grad) then raise Exception.Create('EmbeddingLayer.ZeroGrad: Wagi.Grad mismatch.');

  for i := 0 to High(Wagi.Grad) do Wagi.Grad[i] := 0.0;
end;

procedure TAvoEmbeddingLayer.Step(LearningRate: Single);
var i: Integer;
begin
  if Wagi = nil then raise Exception.Create('EmbeddingLayer.Step: Wagi = nil.');
  if Wagi.NumEl <> Length(Wagi.Data) then raise Exception.Create('EmbeddingLayer.Step: Korupcja tensora Wagi.');
  if Wagi.NumEl <> Length(Wagi.Grad) then raise Exception.Create('EmbeddingLayer.Step: Korupcja gradientu Wagi.');

  for i := 0 to High(Wagi.Data) do
  begin
    Wagi.Data[i] := Wagi.Data[i] - LearningRate * Wagi.Grad[i];
    Wagi.Grad[i] := 0.0;
  end;
end;


// TAvoPositionalEncoding

constructor TAvoPositionalEncoding.Create(AMaxSeqLen, AEmbDim: Integer);
var
  pos, i:    Integer;
  Angle:     Double;
  Denom:     Double;
begin
  if AMaxSeqLen <= 0 then raise Exception.Create('PositionalEncoding.Create: MaxSeqLen musi byc > 0.');
  if AEmbDim <= 0 then raise Exception.Create('PositionalEncoding.Create: EmbDim musi byc > 0.');

  MaxSeqLen := AMaxSeqLen;
  EmbDim    := AEmbDim;
  Table     := TAvoTensor.Create([AMaxSeqLen, AEmbDim]);

  // Prekalkulacja tablicy PE
  // PE(pos, 2i)   = sin(pos / 10000^(2i/EmbDim))
  // PE(pos, 2i+1) = cos(pos / 10000^(2i/EmbDim))
  for pos := 0 to AMaxSeqLen - 1 do
    for i := 0 to (AEmbDim - 1) div 2 do
    begin
      Denom := Power(10000.0, (2.0 * i) / AEmbDim);
      Angle := pos / Denom;

      // Pozycja parzysta: sin (jeśli mieści się w EmbDim)
      if 2 * i < AEmbDim then
        Table.Data[pos * AEmbDim + 2 * i] := Sin(Angle);

      // Pozycja nieparzysta: cos (jeśli mieści się w EmbDim)
      if 2 * i + 1 < AEmbDim then
        Table.Data[pos * AEmbDim + 2 * i + 1] := Cos(Angle);
    end;
end;

destructor TAvoPositionalEncoding.Destroy;
begin
  if Table <> nil then Table.Free;
  inherited Destroy;
end;

procedure TAvoPositionalEncoding.AddTo(Embeddings: TAvoTensor);
var
  SeqLen, i, j: Integer;
begin
  if Embeddings = nil then raise Exception.Create('PositionalEncoding.AddTo: Embeddings = nil.');
  if Table = nil then raise Exception.Create('PositionalEncoding.AddTo: Wewnetrzna tablica (Table) to nil.');

  if Embeddings.NumEl <> Length(Embeddings.Data) then raise Exception.Create('PositionalEncoding.AddTo: Korupcja tensora Embeddings.');
  if Table.NumEl <> Length(Table.Data) then raise Exception.Create('PositionalEncoding.AddTo: Korupcja tensora Table.');

  if Length(Embeddings.Shape) <> 2 then
    raise Exception.CreateFmt('PositionalEncoding.AddTo: Tensor musi byc 2D [SeqLen, EmbDim], a jest %dD.', [Length(Embeddings.Shape)]);

  SeqLen := Embeddings.Shape[0];

  if SeqLen > MaxSeqLen then
    raise Exception.CreateFmt(
      'PositionalEncoding.AddTo: Przekroczono maksymalny kontekst modelu! SeqLen=%d > MaxSeqLen=%d.',
      [SeqLen, MaxSeqLen]);

  if Embeddings.Shape[1] <> EmbDim then
    raise Exception.CreateFmt(
      'PositionalEncoding.AddTo: EmbDim niezgodny — tensor=%d, PE=%d.',
      [Embeddings.Shape[1], EmbDim]);

  // Dodaj PE in-place
  for i := 0 to SeqLen - 1 do
    for j := 0 to EmbDim - 1 do
      Embeddings.Data[i * EmbDim + j] :=
        Embeddings.Data[i * EmbDim + j] + Table.Data[i * EmbDim + j];
end;

function TAvoPositionalEncoding.Apply(Embeddings: TAvoTensor): TAvoTensor;
var
  SeqLen, i, j: Integer;
begin
  if Embeddings = nil then raise Exception.Create('PositionalEncoding.Apply: Embeddings = nil.');
  if Table = nil then raise Exception.Create('PositionalEncoding.Apply: Wewnetrzna tablica (Table) to nil.');

  if Embeddings.NumEl <> Length(Embeddings.Data) then raise Exception.Create('PositionalEncoding.Apply: Korupcja tensora Embeddings.');
  if Table.NumEl <> Length(Table.Data) then raise Exception.Create('PositionalEncoding.Apply: Korupcja tensora Table.');

  if Length(Embeddings.Shape) <> 2 then
    raise Exception.CreateFmt('PositionalEncoding.Apply: Tensor musi byc 2D [SeqLen, EmbDim], a jest %dD.', [Length(Embeddings.Shape)]);

  SeqLen := Embeddings.Shape[0];

  if SeqLen > MaxSeqLen then
    raise Exception.CreateFmt(
      'PositionalEncoding.Apply: Przekroczono maksymalny kontekst modelu! SeqLen=%d > MaxSeqLen=%d.',
      [SeqLen, MaxSeqLen]);

  if Embeddings.Shape[1] <> EmbDim then
    raise Exception.CreateFmt(
      'PositionalEncoding.Apply: EmbDim niezgodny — tensor=%d, PE=%d.',
      [Embeddings.Shape[1], EmbDim]);

  //LOGIKA
  Result := TAvoTensor.Create(Embeddings.Shape);

  for i := 0 to SeqLen - 1 do
    for j := 0 to EmbDim - 1 do
      Result.Data[i * EmbDim + j] :=
        Embeddings.Data[i * EmbDim + j] + Table.Data[i * EmbDim + j];
end;

end.


{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.nn;

// avotensor.nn — podstawowe struktury sieci neuronowych (Linear, SGD)
interface

uses
  Classes,
  SysUtils,
  syncobjs,
  avotensor.core;

function ReLU(X: Single): Single;
function ReLUDerivative(X: Single): Single;

type
  TAvoLinearLayer = class
  public
    Wagi:    TAvoTensor;
    Bias:    TAvoTensor;
    Wejscie: TAvoTensor; // Zapisywane do propagacji wstecznej

    destructor Destroy; override;
    procedure  ZeroGrad;
    function   Forward(X: TAvoTensor): TAvoTensor;
    function   Backward(DOut: TAvoTensor): TAvoTensor;
  end;

  TAvoOptimizerSGD = class
  public
    LearningRate: Single;
    constructor Create(ALearningRate: Single);
    procedure Step(Layer: TAvoLinearLayer);
  end;

  TAvoTrainerMetrics = record
    Loss:     Single;
    Progress: Integer;
  end;

  TAvoTrainer = class(TThread)
  private
    FLayer:     TAvoLinearLayer;
    FOptimizer: TAvoOptimizerSGD;
    FInput:     TAvoTensor;
    FTarget:    TAvoTensor;
    FMetricsCS: TCriticalSection;
    FMetrics:   TAvoTrainerMetrics;
  protected
    procedure Execute; override;
  public
    constructor Create(ALayer: TAvoLinearLayer; AOptimizer: TAvoOptimizerSGD;
                       AInput, ATarget: TAvoTensor);
    destructor  Destroy; override;
    function GetMetrics: TAvoTrainerMetrics;
  end;

implementation

function ReLU(X: Single): Single;
begin
  if X > 0.0 then Result := X else Result := 0.0;
end;

function ReLUDerivative(X: Single): Single;
begin
  if X > 0.0 then Result := 1.0 else Result := 0.0;
end;

destructor TAvoLinearLayer.Destroy;
begin
  if Wagi <> nil then Wagi.Free;
  if Bias <> nil then Bias.Free;
  // Wejscie to jedynie referencja - zwalnia ją wywołujący
  inherited Destroy;
end;

procedure TAvoLinearLayer.ZeroGrad;
var i: Integer;
begin
  if Wagi = nil then raise Exception.Create('LinearLayer.ZeroGrad: Wagi = nil.');
  if Bias = nil then raise Exception.Create('LinearLayer.ZeroGrad: Bias = nil.');

  if Wagi.NumEl <> Length(Wagi.Grad) then
    raise Exception.Create('LinearLayer.ZeroGrad: Wagi.Grad mismatch.');
  if Bias.NumEl <> Length(Bias.Grad) then
    raise Exception.Create('LinearLayer.ZeroGrad: Bias.Grad mismatch.');

  for i := 0 to High(Wagi.Grad) do Wagi.Grad[i] := 0.0;
  for i := 0 to High(Bias.Grad) do Bias.Grad[i] := 0.0;
end;

function TAvoLinearLayer.Forward(X: TAvoTensor): TAvoTensor;
var
  XW: TAvoTensor;
  i, j, M, N: Integer;
begin
  if X = nil then raise Exception.Create('LinearLayer.Forward: Input X = nil.');
  if Wagi = nil then raise Exception.Create('LinearLayer.Forward: Wagi = nil.');
  if Bias = nil then raise Exception.Create('LinearLayer.Forward: Bias = nil.');

  if X.NumEl <> Length(X.Data) then raise Exception.Create('LinearLayer.Forward: Korupcja tensora X (NumEl mismatch).');
  if Wagi.NumEl <> Length(Wagi.Data) then raise Exception.Create('LinearLayer.Forward: Korupcja tensora Wagi.');

  if Bias.NumEl <> Length(Bias.Data) then raise Exception.Create('LinearLayer.Forward: Korupcja tensora Bias.');
  if Bias.NumEl <> Length(Bias.Grad) then raise Exception.Create('LinearLayer.Forward: Korupcja gradientu Bias.');
  if Length(Bias.Shape) <> 1 then
    raise Exception.CreateFmt('LinearLayer.Forward: Bias musi byc 1D, otrzymano %dD.', [Length(Bias.Shape)]);

  if Length(X.Shape) <> 2 then
    raise Exception.CreateFmt('LinearLayer.Forward: Wymagany tensor 2D, otrzymano %dD.', [Length(X.Shape)]);
  if Length(Wagi.Shape) <> 2 then
    raise Exception.Create('LinearLayer.Forward: Tensory wag musza byc 2D.');

  if X.Shape[1] <> Wagi.Shape[0] then
    raise Exception.CreateFmt('LinearLayer.Forward: Niezgodnosc macierzy! X.Cols(%d) <> Wagi.Rows(%d).', [X.Shape[1], Wagi.Shape[0]]);
  if Bias.Shape[0] <> Wagi.Shape[1] then
    raise Exception.CreateFmt('LinearLayer.Forward: Niezgodnosc biasow! Bias(%d) <> Wagi.Cols(%d).', [Bias.Shape[0], Wagi.Shape[1]]);


  Wejscie := X;
  XW := DotProduct(X, Wagi);
  try
    if XW = nil then
      raise Exception.Create('LinearLayer.Forward: DotProduct zwrocil nil.');

    if XW.NumEl <> Length(XW.Data) then
      raise Exception.Create('LinearLayer.Forward: DotProduct zwrocil uszkodzony tensor.');

    if Length(XW.Shape) <> 2 then
      raise Exception.CreateFmt(
        'LinearLayer.Forward: DotProduct powinien zwrocic 2D, otrzymano %dD.',
        [Length(XW.Shape)]
      );

    if XW.Shape[1] <> Bias.Shape[0] then
      raise Exception.CreateFmt(
        'LinearLayer.Forward: XW.Cols(%d) <> Bias(%d).',
        [XW.Shape[1], Bias.Shape[0]]
      );

    // Ręczne i bezpieczne dodawanie biasu uwzględniające standardowy Broadcasting [M,N] + [N]
    Result := TAvoTensor.Create(XW.Shape);
    M := XW.Shape[0];
    N := XW.Shape[1];

    for i := 0 to M - 1 do
      for j := 0 to N - 1 do
        Result.Data[i * N + j] := XW.Data[i * N + j] + Bias.Data[j];
  finally
    XW.Free;
  end;
end;

function TAvoLinearLayer.Backward(DOut: TAvoTensor): TAvoTensor;
var
  i, j, k, M, P, N: Integer;
  DX: TAvoTensor;
  Sum: Single;
begin
  if DOut = nil then raise Exception.Create('LinearLayer.Backward: DOut = nil.');
  if Wejscie = nil then raise Exception.Create('LinearLayer.Backward: Brak zapisanej aktywacji (Wejscie = nil). Uruchom Forward najpierw.');
  if Wagi = nil then raise Exception.Create('LinearLayer.Backward: Wagi = nil.');
  if Bias = nil then raise Exception.Create('LinearLayer.Backward: Bias = nil.');

  if Wagi.NumEl <> Length(Wagi.Data) then raise Exception.Create('LinearLayer.Backward: Korupcja tensora Wagi.');
  if Wagi.NumEl <> Length(Wagi.Grad) then raise Exception.Create('LinearLayer.Backward: Korupcja gradientu Wagi.');
  if Bias.NumEl <> Length(Bias.Data) then raise Exception.Create('LinearLayer.Backward: Korupcja tensora Bias.');
  if Bias.NumEl <> Length(Bias.Grad) then raise Exception.Create('LinearLayer.Backward: Korupcja gradientu Bias.');
  if Wejscie.NumEl <> Length(Wejscie.Data) then raise Exception.Create('LinearLayer.Backward: Korupcja tensora Wejscie.');
  if DOut.NumEl <> Length(DOut.Data) then raise Exception.Create('LinearLayer.Backward: Korupcja tensora DOut.');

  if Length(Wejscie.Shape) <> 2 then raise Exception.Create('LinearLayer.Backward: Wejscie musi byc 2D.');
  if Length(Wagi.Shape) <> 2 then raise Exception.Create('LinearLayer.Backward: Wagi musza byc 2D.');
  if Length(Bias.Shape) <> 1 then raise Exception.Create('LinearLayer.Backward: Bias musi byc 1D.');
  if Length(DOut.Shape) <> 2 then raise Exception.Create('LinearLayer.Backward: DOut musi byc 2D.');

  if (DOut.Shape[0] <> Wejscie.Shape[0]) or (DOut.Shape[1] <> Wagi.Shape[1]) then
    raise Exception.CreateFmt('LinearLayer.Backward: Niezgodnosc ksztaltu gradientu DOut. Oczekiwano [%d, %d].', [Wejscie.Shape[0], Wagi.Shape[1]]);

  // logika
  M := Wejscie.Shape[0]; // Batch / SeqLen
  P := Wejscie.Shape[1]; // Wejsciowe featury
  N := Wagi.Shape[1];    // Wyjsciowe featury

  DX := TAvoTensor.Create(Wejscie.Shape);

  // Gradient względem Biasu: Suma DOut wzdłuż osi batcha/sekwencji
  for j := 0 to N - 1 do
  begin
    Sum := 0.0;
    for i := 0 to M - 1 do
      Sum := Sum + DOut.Data[i * N + j];
    Bias.Grad[j] := Bias.Grad[j] + Sum;
  end;

  //Gradient względem Wag: dW = Wejscie^T * DOut
  for i := 0 to P - 1 do
    for j := 0 to N - 1 do
    begin
      Sum := 0.0;
      for k := 0 to M - 1 do
        Sum := Sum + Wejscie.Data[k * P + i] * DOut.Data[k * N + j];
      Wagi.Grad[i * N + j] := Wagi.Grad[i * N + j] + Sum;
    end;

  // Gradient względem Wejścia (DX): DX = DOut * Wagi^T
  for i := 0 to M - 1 do
    for j := 0 to P - 1 do
    begin
      Sum := 0.0;
      for k := 0 to N - 1 do
        Sum := Sum + DOut.Data[i * N + k] * Wagi.Data[j * N + k];
      DX.Data[i * P + j] := Sum;
    end;

  Result := DX;
end;


// Klasy pomocnicze i legacy (TAvoOptimizerSGD, TAvoTrainer)

constructor TAvoOptimizerSGD.Create(ALearningRate: Single);
begin
  LearningRate := ALearningRate;
end;

procedure TAvoOptimizerSGD.Step(Layer: TAvoLinearLayer);
var i: Integer;
begin
  if Layer = nil then raise Exception.Create('TAvoOptimizerSGD.Step: Layer = nil.');
  if (Layer.Wagi = nil) or (Layer.Bias = nil) then raise Exception.Create('TAvoOptimizerSGD.Step: Wagi/Bias warstwy nie sa zainicjalizowane.');

  if Layer.Wagi.NumEl <> Length(Layer.Wagi.Grad) then
    raise Exception.Create('TAvoOptimizerSGD.Step: Wagi.Grad size mismatch.');
  if Layer.Bias.NumEl <> Length(Layer.Bias.Grad) then
    raise Exception.Create('TAvoOptimizerSGD.Step: Bias.Grad size mismatch.');

  for i := 0 to High(Layer.Wagi.Data) do
  begin
    Layer.Wagi.Data[i] := Layer.Wagi.Data[i] - LearningRate * Layer.Wagi.Grad[i];
    Layer.Wagi.Grad[i] := 0.0;
  end;
  for i := 0 to High(Layer.Bias.Data) do
  begin
    Layer.Bias.Data[i] := Layer.Bias.Data[i] - LearningRate * Layer.Bias.Grad[i];
    Layer.Bias.Grad[i] := 0.0;
  end;
end;

constructor TAvoTrainer.Create(ALayer: TAvoLinearLayer; AOptimizer: TAvoOptimizerSGD;
                                AInput, ATarget: TAvoTensor);
begin
  if ALayer = nil then raise Exception.Create('TAvoTrainer.Create: Layer = nil.');
  if AOptimizer = nil then raise Exception.Create('TAvoTrainer.Create: Optimizer = nil.');
  if AInput = nil then raise Exception.Create('TAvoTrainer.Create: Input = nil.');
  if ATarget = nil then raise Exception.Create('TAvoTrainer.Create: Target = nil.');

  // Zabezpieczenie przed Race Condition: TThread.Create(True) zawiesza start wątku
  inherited Create(True);

  FLayer     := ALayer;
  FOptimizer := AOptimizer;
  FInput     := AInput;
  FTarget    := ATarget;
  FMetricsCS := TCriticalSection.Create;
  FMetrics.Loss     := 0.0;
  FMetrics.Progress := 0;
  FreeOnTerminate   := False;

  Start;
end;

destructor TAvoTrainer.Destroy;
begin
  if not Finished then
  begin
    Terminate;
    WaitFor;
  end;

  FMetricsCS.Free;
  inherited Destroy;
end;

function TAvoTrainer.GetMetrics: TAvoTrainerMetrics;
begin
  FMetricsCS.Enter;
  try
    Result := FMetrics;
  finally
    FMetricsCS.Leave;
  end;
end;

procedure TAvoTrainer.Execute;
var
  Output, DOut, DX: TAvoTensor;
  i, DataLen, StepCount: Integer;
  Loss, GradScale: Single;
begin
  StepCount := 0;
  try
    while not Terminated do
    begin
      Output := nil;
      DOut   := nil;
      DX     := nil;
      try
        Output := FLayer.Forward(FInput);

        if FTarget = nil then
          raise Exception.Create('TAvoTrainer.Execute: FTarget = nil.');

        if Length(FTarget.Data) <> Length(Output.Data) then
          raise Exception.CreateFmt('TAvoTrainer.Execute: Target size mismatch. Output=%d Target=%d',
                                    [Length(Output.Data), Length(FTarget.Data)]);

        DataLen   := Length(Output.Data);
        if DataLen > 0 then GradScale := 2.0 / DataLen
        else                GradScale := 1.0;

        DOut := TAvoTensor.Create(Output.Shape);
        Loss := 0.0;
        for i := 0 to High(Output.Data) do
        begin
          Loss         := Loss + Sqr(Output.Data[i] - FTarget.Data[i]);
          DOut.Data[i] := (Output.Data[i] - FTarget.Data[i]) * GradScale;
        end;
        if DataLen > 0 then Loss := Loss / DataLen;

        Inc(StepCount);
        FMetricsCS.Enter;
        try
          FMetrics.Loss     := Loss;
          FMetrics.Progress := StepCount mod 100;
        finally
          FMetricsCS.Leave;
        end;

        DX := FLayer.Backward(DOut);
        FOptimizer.Step(FLayer);

      finally
        if DX <> nil then DX.Free;
        if DOut <> nil then DOut.Free;
        if Output <> nil then Output.Free;
      end;

      Sleep(50);
    end;
  except
    on E: Exception do
      raise Exception.Create('Trainer Legacy Thread Exception: ' + E.Message);
  end;
end;

end.

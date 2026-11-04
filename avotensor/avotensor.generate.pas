{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.generate;
// avotensor.generate — generator tekstu (inferencja)

interface

uses
  SysUtils, Math, Types,
  avotensor.core,
  avotensor.model;

type
  TTokenProb = record
    ID: Integer;
    Logit: Single;
    Prob: Single;
  end;
  TTokenProbArray = array of TTokenProb;

  TTokenCount = record
    Stamp: Integer;
    Count: Integer;
  end;

  TAvoGenerator = class
  private
    FModel: TAvoLanguageModel;

    FSeenTokens: array of TTokenCount;
    FCurrentStamp: Integer;
    FProbs: TTokenProbArray;

    // Operacje kopca minimalnego (Min-Heap) dla strumieniowej selekcji Top-K
    procedure HeapifyUp(Idx: Integer);
    procedure HeapifyDown(Idx, HeapSize: Integer);

    function SampleNextToken(const InferenceContextIDs: TIntegerDynArray;
                             const FullHistoryIDs: TIntegerDynArray;
                             Temp, TopP: Single; TopK: Integer;
                             PresencePenalty, FrequencyPenalty: Single;
                             EOSTokenID: Integer): Integer;
  public
    constructor Create(AModel: TAvoLanguageModel);
    destructor Destroy; override;

    procedure SetSeed(ASeed: Integer);

    function Generate(const PromptIDs: TIntegerDynArray;
                      MaxNewTokens: Integer;
                      Temp: Single = 0.8;
                      TopK: Integer = 40;
                      TopP: Single = 0.9;
                      PresencePenalty: Single = 0.1;
                      FrequencyPenalty: Single = 0.1;
                      EOSTokenID: Integer = -1): TIntegerDynArray;
  end;

implementation

constructor TAvoGenerator.Create(AModel: TAvoLanguageModel);
begin
  FModel := AModel;
  SetLength(FSeenTokens, 0);
  SetLength(FProbs, 0);
  FCurrentStamp := 0;
end;

destructor TAvoGenerator.Destroy;
begin
  SetLength(FSeenTokens, 0);
  SetLength(FProbs, 0);
  inherited Destroy;
end;

procedure TAvoGenerator.SetSeed(ASeed: Integer);
begin
  RandSeed := ASeed;
end;

{Operacje Min-Heap dla O(V log K)}

procedure TAvoGenerator.HeapifyUp(Idx: Integer);
var
  Parent: Integer;
  Temp: TTokenProb;
begin
  while Idx > 0 do
  begin
    Parent := (Idx - 1) div 2;
    if FProbs[Idx].Logit < FProbs[Parent].Logit then
    begin
      Temp := FProbs[Idx];
      FProbs[Idx] := FProbs[Parent];
      FProbs[Parent] := Temp;
      Idx := Parent;
    end
    else
      Break;
  end;
end;

procedure TAvoGenerator.HeapifyDown(Idx, HeapSize: Integer);
var
  Smallest, Left, Right: Integer;
  Temp: TTokenProb;
begin
  Smallest := Idx;
  Left := 2 * Idx + 1;
  Right := 2 * Idx + 2;

  if (Left < HeapSize) and (FProbs[Left].Logit < FProbs[Smallest].Logit) then
    Smallest := Left;
  if (Right < HeapSize) and (FProbs[Right].Logit < FProbs[Smallest].Logit) then
    Smallest := Right;

  if Smallest <> Idx then
  begin
    Temp := FProbs[Idx];
    FProbs[Idx] := FProbs[Smallest];
    FProbs[Smallest] := Temp;
    HeapifyDown(Smallest, HeapSize);
  end;
end;

{Generacja Tokenu }

function TAvoGenerator.SampleNextToken(const InferenceContextIDs: TIntegerDynArray;
                                       const FullHistoryIDs: TIntegerDynArray;
                                       Temp, TopP: Single; TopK: Integer;
                                       PresencePenalty, FrequencyPenalty: Single;
                                       EOSTokenID: Integer): Integer;
var
  LogitsOut: TAvoTensor;
  VocabSize, LastRowIdx, i, c, ActualK, AdaptiveWindow: Integer;
  MaxLogit, SumExp, Cumulative, RandVal: Single;
  TargetK, SortSize: Integer;
  LogitVal, ShiftedLogit: Single;
  HistoryStart: Integer;
  CandidateCount: Integer;
  TokID: Integer;
  TempToken: TTokenProb;
begin
  if Temp < 0.01 then Temp := 0.01;
  if TopP < 0.01 then TopP := 0.01;
  if TopP > 1.0 then TopP := 1.0;

  LogitsOut := FModel.Forward(InferenceContextIDs);
  try
    VocabSize := LogitsOut.Shape[High(LogitsOut.Shape)];
    if VocabSize <= 0 then raise Exception.Create('SampleNextToken: VocabSize <= 0');
    LastRowIdx := (LogitsOut.NumEl div VocabSize) - 1;

    // 1. Obsługa okna kar (Repetition Penalties) za pomocą znaczników czasowych
    if Length(FSeenTokens) < VocabSize then
    begin
      SetLength(FSeenTokens, VocabSize);
      for i := 0 to VocabSize - 1 do
      begin
        FSeenTokens[i].Stamp := 0;
        FSeenTokens[i].Count := 0;
      end;
    end;

    // Zabezpieczenie przed overflow (wymaga jednorazowego skanu O(V))
    if FCurrentStamp >= High(Integer) - 1 then
    begin
      for i := 0 to VocabSize - 1 do
      begin
        FSeenTokens[i].Stamp := 0;
        FSeenTokens[i].Count := 0;
      end;
      FCurrentStamp := 0;
    end;
    Inc(FCurrentStamp);

    AdaptiveWindow := Min(50, Length(FullHistoryIDs) div 2);
    HistoryStart := Max(0, Length(FullHistoryIDs) - AdaptiveWindow);

    for c := HistoryStart to High(FullHistoryIDs) do
    begin
      TokID := FullHistoryIDs[c];
      if (TokID >= 0) and (TokID < VocabSize) then
      begin
        if FSeenTokens[TokID].Stamp <> FCurrentStamp then
        begin
          FSeenTokens[TokID].Stamp := FCurrentStamp;
          FSeenTokens[TokID].Count := 1;
        end
        else
          Inc(FSeenTokens[TokID].Count);
      end;
    end;

    // 2. Inicjalizacja bufora Top-K
    TargetK := TopK;
    if TargetK > VocabSize then TargetK := VocabSize;
    if TargetK < 1 then TargetK := 1;

    if Length(FProbs) < TargetK then SetLength(FProbs, TargetK);

    for i := 0 to TargetK - 1 do
    begin
      FProbs[i].ID := -1;
      FProbs[i].Logit := -1e30;
      FProbs[i].Prob := 0.0;
    end;

    CandidateCount := 0;

    // 3. Główna pętla wejściowa O(V) ograniczona do podstawowych operacji
    for i := 0 to VocabSize - 1 do
    begin
      // Zignoruj tokeny specjalne i EOF (zależne od logiki EOSTokenID)
      if (i = FModel.Config.PadTokenID) or
         (i = FModel.Config.UnkTokenID) or
         (i = FModel.Config.BosTokenID) or
         ((i = FModel.Config.EosTokenID) and (EOSTokenID < 0)) then Continue;

      LogitVal := LogitsOut.Data[LastRowIdx * VocabSize + i];

      if IsNaN(LogitVal) or IsInfinite(LogitVal) then LogitVal := -1e30;

      if FSeenTokens[i].Stamp = FCurrentStamp then
        LogitVal := LogitVal - (FSeenTokens[i].Count * FrequencyPenalty + PresencePenalty);

      // Strumieniowe uzupełnianie kopca Min-Heap
      if CandidateCount < TargetK then
      begin
        FProbs[CandidateCount].ID := i;
        FProbs[CandidateCount].Logit := LogitVal;
        HeapifyUp(CandidateCount);
        Inc(CandidateCount);
      end
      else if LogitVal > FProbs[0].Logit then
      begin
        FProbs[0].ID := i;
        FProbs[0].Logit := LogitVal;
        HeapifyDown(0, TargetK);
      end;
    end;
  finally
    LogitsOut.Free;
  end;

  TargetK := CandidateCount;

  // Wczesne wyjścia dla małej puli
  if TargetK <= 0 then Exit(FModel.Config.UnkTokenID);
  if TargetK = 1 then
  begin
    if FProbs[0].ID < 0 then Exit(FModel.Config.UnkTokenID);
    Exit(FProbs[0].ID);
  end;

  // Ekstrakcja do tablicy malejącej (Min-Heap Extraction)
  // UWAGA: Po wykonaniu tej operacji tablica FProbs traci własność kopca.
  // Wynikiem jest tablica ściśle posortowana malejąco po logitach.
  SortSize := TargetK;
  while SortSize > 1 do
  begin
    Dec(SortSize);
    TempToken := FProbs[0];
    FProbs[0] := FProbs[SortSize];
    FProbs[SortSize] := TempToken;
    HeapifyDown(0, SortSize);
  end;

  if FProbs[0].ID < 0 then Exit(FModel.Config.UnkTokenID);

  // 5. Softmax + Logit Shift
  MaxLogit := FProbs[0].Logit;
  SumExp := 0.0;
  for i := 0 to TargetK - 1 do
  begin
    if FProbs[i].ID < 0 then Continue;

    ShiftedLogit := (FProbs[i].Logit - MaxLogit) / Temp;
    if ShiftedLogit < -50.0 then ShiftedLogit := -50.0;

    FProbs[i].Prob := Exp(ShiftedLogit);

    if IsNaN(FProbs[i].Prob) then FProbs[i].Prob := 0.0;
    SumExp := SumExp + FProbs[i].Prob;
  end;

  if SumExp < 1e-12 then
  begin
    for i := 0 to TargetK - 1 do
      if FProbs[i].ID >= 0 then FProbs[i].Prob := 1.0 / TargetK;
  end
  else
  begin
    for i := 0 to TargetK - 1 do
      if FProbs[i].ID >= 0 then FProbs[i].Prob := FProbs[i].Prob / SumExp;
  end;

  // 6. Chained Sampling (Top-K -> Top-P)
  Cumulative := 0.0;
  ActualK := TargetK;
  for i := 0 to TargetK - 1 do
  begin
    if FProbs[i].ID < 0 then Continue;

    Cumulative := Cumulative + FProbs[i].Prob;
    if Cumulative >= TopP then
    begin
      ActualK := i + 1;
      Break;
    end;
  end;

  if ActualK < TargetK then
  begin
    SumExp := 0.0;
    for i := 0 to ActualK - 1 do
      if FProbs[i].ID >= 0 then SumExp := SumExp + FProbs[i].Prob;

    if SumExp > 0 then
      for i := 0 to ActualK - 1 do
        if FProbs[i].ID >= 0 then FProbs[i].Prob := FProbs[i].Prob / SumExp;
  end;

  // 7. Próbkowanie z dystrybucji prawdopodobieństw
  RandVal := Random;
  Cumulative := 0.0;
  Result := FProbs[0].ID;

  if Result < 0 then Result := FModel.Config.UnkTokenID;

  for i := 0 to ActualK - 1 do
  begin
    if FProbs[i].ID < 0 then Continue;

    Cumulative := Cumulative + FProbs[i].Prob;
    if RandVal <= Cumulative then
    begin
      Result := FProbs[i].ID;
      Break;
    end;
  end;
end;

function TAvoGenerator.Generate(const PromptIDs: TIntegerDynArray; MaxNewTokens: Integer; Temp: Single = 0.8; TopK: Integer = 40; TopP: Single = 0.9; PresencePenalty: Single = 0.1; FrequencyPenalty: Single = 0.1; EOSTokenID: Integer = -1): TIntegerDynArray;
var
  FullHistory: TIntegerDynArray;
  InferenceContext: TIntegerDynArray;
  NextToken, i: Integer;
begin


  if Length(PromptIDs) = 0 then
    raise Exception.Create('Generate: PromptIDs nie może być puste!');

  FullHistory := Copy(PromptIDs);

  for i := 1 to MaxNewTokens do
  begin
    if Length(FullHistory) > FModel.Config.MaxSeqLen then
      InferenceContext := Copy(FullHistory, Length(FullHistory) - FModel.Config.MaxSeqLen, FModel.Config.MaxSeqLen)
    else
      InferenceContext := FullHistory;

    NextToken := SampleNextToken(
    InferenceContext,
    FullHistory,
    Temp,
    TopP,
    TopK,
    PresencePenalty,
    FrequencyPenalty,
    EOSTokenID
    );

    SetLength(FullHistory, Length(FullHistory) + 1);
    FullHistory[High(FullHistory)] := NextToken;

    if (EOSTokenID >= 0) and (NextToken = EOSTokenID) then
      Break;
  end;

  Result := FullHistory;
end;

end.


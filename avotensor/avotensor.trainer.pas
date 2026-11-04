{$codepage utf8}
{$mode objfpc}{$H+}
unit avotensor.trainer;
// avotensor.trainer — pętla treningowa modelu
interface

uses
  SysUtils, Math, Types,
  avotensor.core,
  avotensor.model,
  avotensor.loss;

type
  TAvoModelTrainer = class
  private
    FModel: TAvoLanguageModel;
    FLearningRate: Single;
    FSeqLen: Integer;

    function GetScheduledLR(CurrentStep, MaxSteps, WarmupSteps: Integer): Single;

  public
    constructor Create(AModel: TAvoLanguageModel; ALearningRate: Single);

    procedure Train(const DataIDs: TIntegerDynArray;
                    Epochs: Integer;
                    CheckpointPrefix: String;
                    SaveEvery: Integer = 1);
  end;

implementation

constructor TAvoModelTrainer.Create(AModel: TAvoLanguageModel; ALearningRate: Single);
begin
  FModel := AModel;
  FLearningRate := ALearningRate;
  FSeqLen := AModel.Config.MaxSeqLen;

  if FSeqLen <= 0 then
    raise Exception.Create('Trainer: Invalid SeqLen (musi być > 0)!');
end;

function TAvoModelTrainer.GetScheduledLR(CurrentStep, MaxSteps, WarmupSteps: Integer): Single;
var
  Progress, MinLR: Single;
begin
  MinLR := FLearningRate * 0.1;

  if CurrentStep < WarmupSteps then
  begin
    if WarmupSteps = 0 then Exit(FLearningRate);
    Result := FLearningRate * (CurrentStep / WarmupSteps);
  end
  else
  begin
    if MaxSteps <= WarmupSteps then Exit(MinLR);

    Progress := EnsureRange((CurrentStep - WarmupSteps) / (MaxSteps - WarmupSteps), 0.0, 1.0);
    Result := MinLR + 0.5 * (FLearningRate - MinLR) * (1.0 + Cos(Pi * Progress));
  end;
end;

procedure TAvoModelTrainer.Train(const DataIDs: TIntegerDynArray; Epochs: Integer; CheckpointPrefix: String; SaveEvery: Integer = 1);
var
  Epoch, Iter, NumBatches, TotalSteps, CurrentStep, WarmupSteps, ValidBatches: Integer;
  StartIdx, i, TempIdx, RandIdx, TokID, MaxVocabID: Integer;

  BatchIndices: TIntegerDynArray;
  InputIDs: TIntegerDynArray;
  TargetTensor, LogitsOut, GradIn, DX: TAvoTensor;

  Loss, TotalLoss, CurrentLR, EMALoss: Single;
  SavePath, RecoverySnapshotFile, TempSnapshotFile: String;
  BadBatch: Boolean;

  // Zmienne obsługujące Full State Recovery (Zarządzanie stanem treningu)
  BackupStep, BackupValidBatches, CrashStreak: Integer;
  BackupEMA, BackupTotalLoss, LRPenaltyMultiplier: Single;
begin
  NumBatches := (Length(DataIDs) - 1) div FSeqLen;
  if NumBatches < 1 then
    raise Exception.Create('Za mało danych treningowych! Zbiór danych musi byc większy niż SeqLen.');

  TotalSteps := Epochs * NumBatches;
  WarmupSteps := TotalSteps div 10;
  MaxVocabID := FModel.Config.VocabSize - 1;

  RecoverySnapshotFile := 'recovery_snapshot.avomodel';
  TempSnapshotFile := RecoverySnapshotFile + '.tmp';

  WriteLn('─────────────────────────────────────────');
  WriteLn('Rozpoczęcie treningu AvoTensor');
  WriteLn(Format('Epoki: %d | Batche/Epoke: %d | Max LR: %.5f | Total Steps: %d',
                 [Epochs, NumBatches, FLearningRate, TotalSteps]));
  WriteLn('─────────────────────────────────────────');

  SetLength(InputIDs, FSeqLen);
  TargetTensor := TAvoTensor.Create([FSeqLen]);

  if (Length(InputIDs) <> FSeqLen) or (Length(TargetTensor.Data) <> FSeqLen) then
    raise Exception.Create('Trainer: Buffer allocation failed!');

  SetLength(BatchIndices, NumBatches);
  for i := 0 to NumBatches - 1 do
    BatchIndices[i] := i * FSeqLen;

  // Inicjalizacja stanu bazowego
  CurrentStep := 0;
  EMALoss := -1.0;
  CrashStreak := 0;
  LRPenaltyMultiplier := 1.0;

  BackupStep := 0;
  BackupEMA := -1.0;
  BackupValidBatches := 0;
  BackupTotalLoss := 0.0;

  // ATOMIC WRITE: Inicjalny zrzut modelu do ewentualnego odzyskiwania
  FModel.SaveWeights(TempSnapshotFile);
  if FileExists(RecoverySnapshotFile) then DeleteFile(RecoverySnapshotFile);
  RenameFile(TempSnapshotFile, RecoverySnapshotFile);

  try
    for Epoch := 1 to Epochs do
    begin
      TotalLoss := 0.0;
      ValidBatches := 0;

      // Odświeżenie backupów na start nowej epoki, by uniknąć desynchronizacji epokowej
      BackupValidBatches := 0;
      BackupTotalLoss := 0.0;

      for i := NumBatches - 1 downto 1 do
      begin
        RandIdx := Random(i + 1);
        TempIdx := BatchIndices[i];
        BatchIndices[i] := BatchIndices[RandIdx];
        BatchIndices[RandIdx] := TempIdx;
      end;

      for Iter := 0 to NumBatches - 1 do
      begin
        StartIdx := BatchIndices[Iter];

        if (StartIdx < 0) or (StartIdx + FSeqLen + 1 > Length(DataIDs)) then Continue;

        Inc(CurrentStep);
        BadBatch := False;

        for i := 0 to FSeqLen - 1 do
        begin
          InputIDs[i] := DataIDs[StartIdx + i];

          TokID := DataIDs[StartIdx + 1 + i];
          if (TokID < 0) or (TokID > MaxVocabID) then
            TokID := 0;
          TargetTensor.Data[i] := Single(TokID);
        end;

        CurrentLR := GetScheduledLR(CurrentStep, TotalSteps, WarmupSteps) * LRPenaltyMultiplier;

        LogitsOut := nil;
        GradIn := nil;
        DX := nil;

        try
          LogitsOut := FModel.Forward(InputIDs);
          LossCrossEntropy(LogitsOut, TargetTensor, Loss, GradIn);


          // full state recovery & anti-oscillation

          if IsNaN(Loss) or IsInfinite(Loss) then
          begin
            WriteLn('!!! KRYTYCZNY BLAD: Wykryto uszkodzony Loss (NaN/Inf).');
            Inc(CrashStreak);

            if CrashStreak >= 5 then
              raise Exception.Create('Trainer: Krytyczna degeneracja modelu. Wykryto Oscillation Loop. Przerwano trening!');

            WriteLn('!!! INICJOWANIE FULL ROLLBACK: Przywracanie zsynchronizowanego stanu...');
            try
              FModel.LoadWeights(RecoverySnapshotFile);

              // Pełna synchronizacja stanu pętli i statystyk
              CurrentStep := BackupStep;
              EMALoss := BackupEMA;
              ValidBatches := BackupValidBatches;
              TotalLoss := BackupTotalLoss;

              LRPenaltyMultiplier := LRPenaltyMultiplier * 0.8;
              WriteLn(Format('!!! Zabezpieczenie: Zredukowano efektywny LR (mnoznik: %.2fx) by uniknac oscylacji.', [LRPenaltyMultiplier]));
            except
              on E: Exception do
                WriteLn('!!! BLAD ROLLBACKU: Nie udalo sie wczytac pliku odzyskiwania! ' + E.Message);
            end;

            BadBatch := True;
          end
          else
          begin
            FModel.ZeroGrad;
            DX := FModel.Backward(GradIn);
            FModel.ClipGradients(1.0);
            FModel.Step(CurrentLR);

            // Poprawny krok zeruje serię awarii
            CrashStreak := 0;

            // ATOMIC STATE CHECKPOINTING
            if (ValidBatches > 0) and (ValidBatches mod 50 = 0) then
            begin
              // Zapis atomowy zapobiegający korupcji w trakcie zapisu na dysk
              FModel.SaveWeights(TempSnapshotFile);
              if FileExists(RecoverySnapshotFile) then DeleteFile(RecoverySnapshotFile);
              RenameFile(TempSnapshotFile, RecoverySnapshotFile);

              BackupStep := CurrentStep;
              BackupEMA := EMALoss;
              BackupValidBatches := ValidBatches;
              BackupTotalLoss := TotalLoss;
            end;
          end;

        finally
          if DX <> nil then DX.Free;
          if GradIn <> nil then GradIn.Free;
          if LogitsOut <> nil then LogitsOut.Free;
        end;

        if BadBatch then
        begin
          // W przypadku Rollbacku wyczyszczono już CurrentStep i statystyki do stanu z Backup,
          // więc od razu kontynuujemy próbując wyuczyć kolejny (lub ten sam, jeśli zmienimy logikę) batch
          Continue;
        end;

        Inc(ValidBatches);

        if EMALoss < 0 then EMALoss := Loss
        else EMALoss := 0.99 * EMALoss + 0.01 * Loss;
        TotalLoss := TotalLoss + Loss;
        //Jeśli chcesz logować rzadziej, zmień na 100 lub 50 wczesniej bylo 10
        if (Iter + 1) mod 100 = 0 then
          WriteLn(Format('Epoka [%d/%d], Batch [%d/%d] | EMA Loss: %.4f (Batch: %.4f) | LR: %.6f',
                         [Epoch, Epochs, Iter + 1, NumBatches, EMALoss, Loss, CurrentLR]));
      end;

      WriteLn('─────────────────────────────────────────');
      WriteLn(Format('Koniec epoki %d. Średnia strata całkowita (Total Loss): %.4f',
                     [Epoch, TotalLoss / Max(1, ValidBatches)]));

      if Epoch mod SaveEvery = 0 then
      begin
        SavePath := Format('%s_epoka_%d.avomodel', [CheckpointPrefix, Epoch]);
        // Zapis głównych epok może pozostać standardowy lub również stać się atomowy
        FModel.SaveWeights(SavePath);
      end;
    end;

    WriteLn('Trening zakończony pomyślnie! Architektura działa bez zarzutu.');

  finally
    TargetTensor.Free;
    if FileExists(RecoverySnapshotFile) then DeleteFile(RecoverySnapshotFile);
    if FileExists(TempSnapshotFile) then DeleteFile(TempSnapshotFile);
  end;
end;

end.


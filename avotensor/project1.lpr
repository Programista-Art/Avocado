{$codepage utf8}
{$mode objfpc}{$H+}
 program project1;

uses
  SysUtils, Classes, Math, Types, DateUtils, Process,
  MTProcs,
  avotensor.core,
  avotensor.nn,
  avotensor.ops,
  avotensor.init,
  avotensor.embed,
  avotensor.attention,
  avotensor.transformer,
  avotensor.loss,
  avotensor.model,
  avotensor.generate,
  avotensor.trainer,
  avotensor.tokenizer,
  avotensor.gpu;

procedure PrintSep;
begin
  WriteLn('─────────────────────────────────────────');
end;

// AUTOMATYCZNY KONWERTER PDF DO TXT
procedure UruchomKonwerterPDF;
var
  Proc: TProcess;
begin
  WriteLn('   Sprawdzam nowe pliki PDF i uruchamiam konwerter...');
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := 'python';
    Proc.Parameters.Add('konwerter.py');
    Proc.Options := [poWaitOnExit, poNoConsole];
    try
      Proc.Execute;
      WriteLn('   Konwersja PDF (skrypt) zakończona sukcesem.');
    except
      on E: Exception do
        WriteLn('   [Info] Nie znaleziono skryptu konwertujacego lub Pythona. Przechodzę dalej.');
    end;
  finally
    Proc.Free;
  end;
end;

var
  Config:       TAvoModelConfig;
  Model:        TAvoLanguageModel;
  Trainer:      TAvoModelTrainer;
  TrainData:    TIntegerDynArray;
  Generator:    TAvoGenerator;
  PromptIDs:    TIntegerDynArray;
  GeneratedIDs: TIntegerDynArray;

  TotalData:    UnicodeString;
  DirPath:      String;
  SearchRec:    TSearchRec;
  PromptStr:    UnicodeString;

  i:            Integer;
  SeqLen:       Integer;
  VocabSize:    Integer;
  Params:       Integer;

  TotalStartTime: TDateTime;
  TotalTrainTime: Int64;

  Tokenizer:    TAvoTokenizer;
  ModelDir: String;

  TestIDs: TIntegerDynArray;


begin
  Tokenizer := nil;
  Model := nil;
  Generator := nil;


  try
    try



    WriteLn('=== Trening AvoTensor ===');
    // WYMUSZAMY 24 WĄTKI DLA RYZENA 9 3900X
   // SetAvoTensorThreadCount(24);
     SetAvoTensorThreadCount(24);

    // --- ENTERPRISE GUARD: WERYFIKACJA MOCY OBLICZENIOWEJ ---
    // Wymuszamy 24 wątki, jeśli z jakiegoś powodu system dałby mniej
   { if ProcThreadPool.MaxThreadCount < 24 then
      ProcThreadPool.MaxThreadCount := 24;
      }


    try
      //Próba uruchomienia GPU/OpenCL
      InitAvoGPU;

      if GPUEnabled then
        WriteLn('[SYSTEM] GPU OpenCL AKTYWNE.')
        //WriteLn('[TEST] GPU aktywne, uruchamiam test DotProductGPU...')
      else
        WriteLn('[SYSTEM] GPU OpenCL NIEAKTYWNE. Używam CPU.');
    except
      on E: Exception do
      begin
        WriteLn('[SYSTEM] GPU OpenCL nie wystartowało: ', E.Message);
        WriteLn('[SYSTEM] Przechodzę na CPU.');
        GPUEnabled := False;
        AvoGPUDotProductFallback := nil;
      end;
    end;

    // 2. CPU fallback / CPU multicore
    SetAvoTensorThreadCount(24);

    WriteLn(Format(
      '[SYSTEM] Akceleracja Multi-Core AKTYWNA. Przydzielono watkow: %d (AMD Ryzen Power)',
      [ProcThreadPool.MaxThreadCount]
    ));

    //WriteLn;
    //WriteLn(Format('   [SYSTEM] Akceleracja Multi-Core AKTYWNA. Przydzielono watkow: %d (AMD Ryzen Power)', [ProcThreadPool.MaxThreadCount]));
    //WriteLn;

    RandSeed := 7;

    PrintSep;
    WriteLn('Wczytywanie folderu "trenowanie" i budowa słownika słów...');

    DirPath := 'trenowanie' + DirectorySeparator;
    if not DirectoryExists('trenowanie') then CreateDir('trenowanie');

    ModelDir := 'Model' + DirectorySeparator;
    if not DirectoryExists('Model') then CreateDir('Model');

    //UruchomKonwerterPDF;

    TotalData := '';

    if FindFirst(DirPath + '*.txt', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          TotalData := TotalData + ReadRawUTF8File(DirPath + SearchRec.Name) + ' ';
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

    if FindFirst(DirPath + '*.avocado', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          TotalData := TotalData + ReadRawUTF8File(DirPath + SearchRec.Name) + ' ';
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

    if Trim(TotalData) = '' then
      raise Exception.Create('Brak danych tekstowych w folderze "trenowanie"!');

    Tokenizer := TAvoTokenizer.Create;
    Tokenizer.CaseSensitive := True;

    WriteLn('   Budowanie słownika NLP...');
    Tokenizer.BuildFromText(TotalData, 1);

    VocabSize := Tokenizer.VocabSize;
    WriteLn(Format('   Wczytano lacznie %d znakow Unicode.', [Length(TotalData)]));
    WriteLn(Format('   Zbudowano słownik słów. Unikalnych tokenów: %d', [VocabSize]));

    Tokenizer.SaveVocabBin(ModelDir + 'slownik_vocab.vocabbin');
    Tokenizer.SaveVocab(ModelDir + 'slownik_vocab.txt');

    TrainData := Tokenizer.Encode(TotalData);
    WriteLn(Format('   Cały tekst treningowy złożono z %d tokenów.', [Length(TrainData)]));

    PrintSep;
    WriteLn('Tworzenie i trenowanie modelu...');
    //Lekka
    SeqLen    := 64;
    Config    := MakeConfig(VocabSize, 128, 4, 2, SeqLen);

    //Lekka
    //SeqLen    := 32;
    //Config    := MakeConfig(VocabSize, 64, 4, 2, SeqLen);
    //dla matematyki lepsze wyniki
   { SeqLen := 32;
     Config := MakeConfig(VocabSize, 128, 4, 3, SeqLen);
   }
     // O wiele większy kontekst dla tekstów
    //SeqLen    := 256;
    // Rozmiar wagi 256, 8 głów uwagi, 4 warstwy transformera
   // Config    := MakeConfig(VocabSize, 256, 8, 4, SeqLen);
   // SeqLen := 512;
    //Config := MakeConfig(VocabSize, 512, 8, 4, SeqLen);
   // Klasyczna architektura "GPT-Micro" (Zalecane na start):
    //Config :=  MakeConfig(VocabSize, 512, 8, 6, SeqLen);

    //Wąski, ale bardzo głęboki model (Głęboka logika):
    //Config := MakeConfig(VocabSize, 256, 8, 12, SeqLen);

    //za duzo
    //SeqLen := 1024;

    // MakeConfig(VocabSize, EmbDim, NumHeads, NumLayers, SeqLen)
    // EmbDim 1024 musi dzielić się przez NumHeads (16)
   // Config := MakeConfig(VocabSize, 1024, 16, 6, SeqLen);
   //za dlugo generuje odpowiedz z 8 minut
   //SeqLen := 256;
   //Config := MakeConfig(VocabSize, 512, 8, 6, SeqLen);
    {OSTATNIO UZYTE}
    //SeqLen := 128;
   // Config := MakeConfig(Tokenizer.VocabSize, 128, 8, 6, 128);

    //dla testów na Ryzen
   //SeqLen := 1024;
    // MakeConfig(VocabSize, EmbDim, NumHeads, NumLayers, SeqLen)
   //Config := MakeConfig(VocabSize, 1024, 16, 6, SeqLen);

   //Bardzo ciężka, testowa
   //SeqLen := 1024;
  //  Config := MakeConfig(VocabSize, 512, 8, 6, SeqLen);

  {  WriteLn('--- STRESS TEST PROCESORA (Sprawdz Menedzer Zadan!) ---');
    WriteLn('Generuje macierze 4096 x 4096...');

    // Tworzymy dwie ogromne macierze
    TestA := TAvoTensor.Create([4096, 4096]);
    TestB := TAvoTensor.Create([4096, 4096]);


    // Wypelniamy jedynkami
    for i := 0 to TestA.NumEl - 1 do TestA.Data[i] := 1.0;
    for i := 0 to TestB.NumEl - 1 do TestB.Data[i] := 1.0;

    WriteLn('Odpalam wielowatkowy DotProduct (to potrwa pare sekund)...');
    TestC := DotProduct(TestA, TestB);
    WriteLn('Stress test zakonczony!');

    TestA.Free; TestB.Free; TestC.Free;
    }


    Model := TAvoLanguageModel.Create(Config);

    Params := Model.CountParams;
    WriteLn(Format('   Liczba parametrow: %d (%.1f K)', [Params, Params / 1000.0]));

    if Length(TrainData) > SeqLen then
    begin
      WriteLn('   Zaczynam trenowanie (50 epok)...');
      TotalStartTime := Now;

      Trainer := TAvoModelTrainer.Create(Model, 0.0003);
      try
        Trainer.Train(TrainData, 50, ModelDir + 'model', 1);
      finally
        Trainer.Free;
      end;

      TotalTrainTime := SecondsBetween(Now, TotalStartTime);
      WriteLn(Format('   Trening ukończony pomyślnie! Całkowity czas: %d sekund (ok. %d min).',
                     [TotalTrainTime, TotalTrainTime div 60]));
    end
    else
      WriteLn('   Za malo danych do treningu!');

    PrintSep;
    WriteLn('Testowanie modułu TAvoGenerator (Inferencja)...');

    PromptStr := 'oblicz: 2 + 2 =';
    PromptIDs := Tokenizer.Encode(PromptStr);

    Write('   Zakodowany Prompt: [');
    for i := 0 to High(PromptIDs) do Write(IntToStr(PromptIDs[i]), ' ');
    WriteLn(']');

    Generator := TAvoGenerator.Create(Model);

    GeneratedIDs := Generator.Generate(
     // PromptIDs, 40, 0.8, 40, 0.9, 0.1, 0.1, -1
      {PromptIDs,
      40,
      0.0,
      40,
      0.9,
      0.1,
      0.1,
      TOKEN_EOS
    );
    }
    //dla testu matematyki
    PromptIDs,
      64,
      0.0, //Temperatura
      1,   //TopK - musi być Integer, nie 1.0
      1.0,  // TopP
      0.0, // PresencePenalty
      0.0, // FrequencyPenalty
      TOKEN_EOS
    );

    Write('   Wygenerowane Tokeny (przez AI): [');
    for i := 0 to High(GeneratedIDs) do Write(IntToStr(GeneratedIDs[i]), ' ');
    WriteLn(']');

    Write('   Zdekodowany, wymyslony przez AI tekst: ');
    WriteLn;
    WriteLn('   ----------------------------------------');
    Write(UTF8Encode(Tokenizer.Decode(GeneratedIDs)));
    WriteLn;
    WriteLn('   ----------------------------------------');

    WriteLn('   Generowanie dziala poprawnie OK');

    WriteLn;
    PrintSep;
    WriteLn('Wszystkie testy zakonczone pomyslnie.');
    WriteLn('Nacisnij Enter aby wyjsc...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('─────────────────────────────────────────');
      WriteLn('!!! KRYTYCZNY BŁĄD APLIKACJI !!!');
      WriteLn(E.Message);
      WriteLn('─────────────────────────────────────────');
      WriteLn('Nacisnij Enter aby zamknac konsole...');
      ReadLn;
    end;
  end;
finally
  if Generator <> nil then Generator.Free;
  if Model <> nil then Model.Free;
  if Tokenizer <> nil then Tokenizer.Free;
  FreeAvoGPU;
end;
end.


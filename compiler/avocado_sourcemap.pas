unit avocado_sourcemap;

{$mode objfpc}{$H+}

{ Mapping from generated Pascal lines back to Avocado source spans. }

interface

uses
  SysUtils, Classes, avocado_source;

type
  TAvocadoMapEntry = record
    GeneratedLine: Integer; // 1-based line in generated Pascal
    Span: TAvocadoSourceSpan;
    IsScaffold: Boolean;    // generated helper / uses / var section
  end;

  TAvocadoSourceMap = class
  private
    FEntries: array of TAvocadoMapEntry;
    FCount: Integer;
  public
    constructor Create;
    procedure Map(AGeneratedLine: Integer; const ASpan: TAvocadoSourceSpan;
      AIsScaffold: Boolean = False);
    procedure MapScaffold(AGeneratedLine: Integer);
    function Count: Integer;
    function Get(AIndex: Integer): TAvocadoMapEntry;
    { Find the best Avocado span for a generated line (exact or nearest previous). }
    function Lookup(AGeneratedLine: Integer): TAvocadoMapEntry;
    function HasMapping: Boolean;
  end;

implementation

constructor TAvocadoSourceMap.Create;
begin
  inherited Create;
  FCount := 0;
  SetLength(FEntries, 0);
end;

procedure TAvocadoSourceMap.Map(AGeneratedLine: Integer;
  const ASpan: TAvocadoSourceSpan; AIsScaffold: Boolean);
begin
  if FCount >= Length(FEntries) then
    SetLength(FEntries, (FCount + 16) * 2);
  FEntries[FCount].GeneratedLine := AGeneratedLine;
  FEntries[FCount].Span := ASpan;
  FEntries[FCount].IsScaffold := AIsScaffold;
  Inc(FCount);
end;

procedure TAvocadoSourceMap.MapScaffold(AGeneratedLine: Integer);
begin
  Map(AGeneratedLine, EmptySpan, True);
end;

function TAvocadoSourceMap.Count: Integer;
begin
  Result := FCount;
end;

function TAvocadoSourceMap.Get(AIndex: Integer): TAvocadoMapEntry;
begin
  Result := FEntries[AIndex];
end;

function TAvocadoSourceMap.HasMapping: Boolean;
begin
  Result := FCount > 0;
end;

function TAvocadoSourceMap.Lookup(AGeneratedLine: Integer): TAvocadoMapEntry;
var
  I, Best: Integer;
begin
  Best := -1;
  for I := 0 to FCount - 1 do
    if FEntries[I].GeneratedLine = AGeneratedLine then
      Exit(FEntries[I])
    else if (FEntries[I].GeneratedLine <= AGeneratedLine) and
            ((Best < 0) or (FEntries[I].GeneratedLine > FEntries[Best].GeneratedLine)) then
      Best := I;
  if Best >= 0 then
    Result := FEntries[Best]
  else
  begin
    Result.GeneratedLine := AGeneratedLine;
    Result.Span := EmptySpan;
    Result.IsScaffold := True;
  end;
end;

end.

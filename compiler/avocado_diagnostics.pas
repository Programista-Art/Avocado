unit avocado_diagnostics;

{$mode objfpc}{$H+}

{ Structured diagnostics with stable codes and Polish messages. }

interface

uses
  SysUtils, Classes, avocado_source;

type
  TAvocadoDiagSeverity = (adsError, adsWarning, adsHint, adsNote);

  TAvocadoDiagnostic = class
  public
    Code: string;          // stable code, e.g. 'AVO0001'
    Severity: TAvocadoDiagSeverity;
    MessageText: string;   // Polish message
    Span: TAvocadoSourceSpan;
    FileName: string;
    constructor Create(const ACode: string; ASeverity: TAvocadoDiagSeverity;
      const AMessage: string; const ASpan: TAvocadoSourceSpan; const AFileName: string);
    function FormatText: string;
    function Line: Integer;
    function Col: Integer;
  end;

  TAvocadoDiagnosticList = class
  private
    FItems: TFPList;
    function GetItem(AIndex: Integer): TAvocadoDiagnostic;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ADiag: TAvocadoDiagnostic); // takes ownership
    procedure AddError(const ACode, AMessage: string; const ASpan: TAvocadoSourceSpan;
      const AFileName: string = '');
    procedure AddWarning(const ACode, AMessage: string; const ASpan: TAvocadoSourceSpan;
      const AFileName: string = '');
    function Count: Integer;
    function ErrorCount: Integer;
    function HasErrors: Boolean;
    property Items[AIndex: Integer]: TAvocadoDiagnostic read GetItem; default;
    procedure Clear;
    procedure AddList(AList: TAvocadoDiagnosticList); // moves items
    procedure AppendTo(AStrings: TStrings);
  end;

const
  // Stable diagnostic codes
  AVOK_LexInvalidChar       = 'AVO0001';
  AVOK_LexUnterminatedString= 'AVO0002';
  AVOK_LexUnterminatedComment='AVO0003';
  AVOK_LexUnterminatedEscape= 'AVO0004';
  AVOK_LexBadNumber         = 'AVO0005';
  AVOK_ParseUnexpectedToken = 'AVO0010';
  AVOK_ParseExpectedToken   = 'AVO0011';
  AVOK_ParseExpectedExpr    = 'AVO0012';
  AVOK_ParseExpectedIdent   = 'AVO0013';
  AVOK_ParseExpectedStmt    = 'AVO0014';
  AVOK_ParseUnclosedBlock   = 'AVO0015';
  AVOK_ParseMissingProgramEnd='AVO0016';
  AVOK_ParseBadDeclaration  = 'AVO0017';
  AVOK_ParseBadParameter    = 'AVO0018';
  AVOK_ParseBlockClosedAtEof='AVO0019';
  AVOK_SemUnknownType       = 'AVO0020';
  AVOK_SemUnknownName       = 'AVO0021';
  AVOK_SemDuplicateName     = 'AVO0022';
  AVOK_SemAssignIncompatible= 'AVO0023';
  AVOK_SemArgCount          = 'AVO0024';
  AVOK_SemReturnOutsideFunc = 'AVO0025';
  AVOK_SemBreakOutsideLoop  = 'AVO0026';
  AVOK_SemContinueOutsideLoop='AVO0027';
  AVOK_SemCallNotCallable   = 'AVO0028';
  AVOK_SemReturnValueMissing= 'AVO0029';
  AVOK_SemIndexNotIndexable = 'AVO0030';
  AVOK_SemMemberOnUnknown   = 'AVO0031';
  AVOK_GenInternal          = 'AVO0040';

implementation

{ TAvocadoDiagnostic }

constructor TAvocadoDiagnostic.Create(const ACode: string; ASeverity: TAvocadoDiagSeverity;
  const AMessage: string; const ASpan: TAvocadoSourceSpan; const AFileName: string);
begin
  inherited Create;
  Code := ACode;
  Severity := ASeverity;
  MessageText := AMessage;
  Span := ASpan;
  FileName := AFileName;
end;

function TAvocadoDiagnostic.Line: Integer;
begin
  Result := Span.StartPos.Line;
end;

function TAvocadoDiagnostic.Col: Integer;
begin
  Result := Span.StartPos.Col;
end;

function TAvocadoDiagnostic.FormatText: string;
const
  SevName: array[TAvocadoDiagSeverity] of string = ('Błąd', 'Ostrzeżenie', 'Wskazówka', 'Info');
begin
  if FileName <> '' then
    Result := Format('%s(%d,%d): %s %s: %s', [FileName, Line, Col, SevName[Severity], Code, MessageText])
  else
    Result := Format('%d,%d: %s %s: %s', [Line, Col, SevName[Severity], Code, MessageText]);
end;

{ TAvocadoDiagnosticList }

constructor TAvocadoDiagnosticList.Create;
begin
  inherited Create;
  FItems := TFPList.Create;
end;

destructor TAvocadoDiagnosticList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TAvocadoDiagnosticList.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;
  FItems.Clear;
end;

function TAvocadoDiagnosticList.Count: Integer;
begin
  Result := FItems.Count;
end;

function TAvocadoDiagnosticList.GetItem(AIndex: Integer): TAvocadoDiagnostic;
begin
  Result := TAvocadoDiagnostic(FItems[AIndex]);
end;

procedure TAvocadoDiagnosticList.Add(ADiag: TAvocadoDiagnostic);
begin
  FItems.Add(ADiag);
end;

procedure TAvocadoDiagnosticList.AddError(const ACode, AMessage: string;
  const ASpan: TAvocadoSourceSpan; const AFileName: string);
begin
  Add(TAvocadoDiagnostic.Create(ACode, adsError, AMessage, ASpan, AFileName));
end;

procedure TAvocadoDiagnosticList.AddWarning(const ACode, AMessage: string;
  const ASpan: TAvocadoSourceSpan; const AFileName: string);
begin
  Add(TAvocadoDiagnostic.Create(ACode, adsWarning, AMessage, ASpan, AFileName));
end;

function TAvocadoDiagnosticList.ErrorCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
    if Items[I].Severity = adsError then
      Inc(Result);
end;

function TAvocadoDiagnosticList.HasErrors: Boolean;
begin
  Result := ErrorCount > 0;
end;

procedure TAvocadoDiagnosticList.AddList(AList: TAvocadoDiagnosticList);
var
  I: Integer;
begin
  if AList = nil then Exit;
  for I := 0 to AList.Count - 1 do
    FItems.Add(AList.FItems[I]);
  AList.FItems.Clear;
end;

procedure TAvocadoDiagnosticList.AppendTo(AStrings: TStrings);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    AStrings.Add(Items[I].FormatText);
end;

end.

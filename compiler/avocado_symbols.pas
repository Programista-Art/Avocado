unit avocado_symbols;

{$mode objfpc}{$H+}

{ Symbol tables and scope rules for Avocado semantic analysis. }

interface

uses
  SysUtils, Classes, avocado_ast;

type
  TAvocadoSymbolKind = (
    askVariable,
    askParameter,
    askFunction,
    askProcedure,
    askBuiltin,
    askType
  );

  TAvocadoSymbol = class
  public
    Name: string;
    Kind: TAvocadoSymbolKind;
    TypeName: string;       // resolved Pascal type name
    RawTypeName: string;    // as written
    DeclNode: TAvocadoNode;
    IsGlobal: Boolean;
    constructor Create(const AName: string; AKind: TAvocadoSymbolKind;
      const ATypeName: string);
  end;

  TAvocadoScope = class
  private
    FSymbols: TStringList; // name(lower) -> TAvocadoSymbol
    FParent: TAvocadoScope;
  public
    constructor Create(AParent: TAvocadoScope);
    destructor Destroy; override;
    function Declare(ASym: TAvocadoSymbol): Boolean; // False if duplicate in this scope
    function Lookup(const AName: string): TAvocadoSymbol;
    function LookupLocal(const AName: string): TAvocadoSymbol;
    property Parent: TAvocadoScope read FParent;
  end;

  TAvocadoSymbolTable = class
  private
    FGlobal: TAvocadoScope;
    FStack: TFPList; // stack of scopes, top = current
    function Current: TAvocadoScope;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PushScope;
    procedure PopScope;
    function DeclareGlobal(ASym: TAvocadoSymbol): Boolean;
    function Declare(ASym: TAvocadoSymbol): Boolean;
    function Lookup(const AName: string): TAvocadoSymbol;
    property GlobalScope: TAvocadoScope read FGlobal;
  end;

implementation

constructor TAvocadoSymbol.Create(const AName: string; AKind: TAvocadoSymbolKind;
  const ATypeName: string);
begin
  inherited Create;
  Name := AName;
  Kind := AKind;
  TypeName := ATypeName;
  RawTypeName := '';
  DeclNode := nil;
  IsGlobal := False;
end;

constructor TAvocadoScope.Create(AParent: TAvocadoScope);
begin
  inherited Create;
  FParent := AParent;
  FSymbols := TStringList.Create;
  FSymbols.CaseSensitive := False;
  FSymbols.Sorted := True;
  FSymbols.Duplicates := dupError;
end;

destructor TAvocadoScope.Destroy;
var
  I: Integer;
begin
  for I := 0 to FSymbols.Count - 1 do
    FSymbols.Objects[I].Free;
  FSymbols.Free;
  inherited Destroy;
end;

function TAvocadoScope.Declare(ASym: TAvocadoSymbol): Boolean;
begin
  Result := False;
  if FSymbols.IndexOf(ASym.Name) >= 0 then Exit;
  FSymbols.AddObject(ASym.Name, ASym);
  Result := True;
end;

function TAvocadoScope.LookupLocal(const AName: string): TAvocadoSymbol;
var
  I: Integer;
begin
  I := FSymbols.IndexOf(AName);
  if I >= 0 then
    Result := TAvocadoSymbol(FSymbols.Objects[I])
  else
    Result := nil;
end;

function TAvocadoScope.Lookup(const AName: string): TAvocadoSymbol;
var
  S: TAvocadoScope;
begin
  S := Self;
  while S <> nil do
  begin
    Result := S.LookupLocal(AName);
    if Result <> nil then Exit;
    S := S.FParent;
  end;
  Result := nil;
end;

constructor TAvocadoSymbolTable.Create;
begin
  inherited Create;
  FGlobal := TAvocadoScope.Create(nil);
  FStack := TFPList.Create;
  FStack.Add(FGlobal);
end;

destructor TAvocadoSymbolTable.Destroy;
begin
  while FStack.Count > 1 do
    PopScope;
  FStack.Free;
  FGlobal.Free;
  inherited Destroy;
end;

function TAvocadoSymbolTable.Current: TAvocadoScope;
begin
  Result := TAvocadoScope(FStack[FStack.Count - 1]);
end;

procedure TAvocadoSymbolTable.PushScope;
begin
  FStack.Add(TAvocadoScope.Create(Current));
end;

procedure TAvocadoSymbolTable.PopScope;
var
  S: TAvocadoScope;
begin
  if FStack.Count <= 1 then Exit;
  S := TAvocadoScope(FStack[FStack.Count - 1]);
  FStack.Delete(FStack.Count - 1);
  S.Free;
end;

function TAvocadoSymbolTable.DeclareGlobal(ASym: TAvocadoSymbol): Boolean;
begin
  ASym.IsGlobal := True;
  Result := FGlobal.Declare(ASym);
  if not Result then
    ASym.Free;
end;

function TAvocadoSymbolTable.Declare(ASym: TAvocadoSymbol): Boolean;
begin
  Result := Current.Declare(ASym);
  if not Result then
    ASym.Free;
end;

function TAvocadoSymbolTable.Lookup(const AName: string): TAvocadoSymbol;
begin
  Result := Current.Lookup(AName);
end;

end.

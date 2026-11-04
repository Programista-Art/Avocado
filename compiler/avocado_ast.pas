unit avocado_ast;

{$mode objfpc}{$H+}

{ Abstract syntax tree nodes. Every node keeps a source span.
  The parser owns the tree; TAvocadoProgram owns all nodes via Child lists. }

interface

uses
  SysUtils, Classes, avocado_source;

type
  TAvocadoNode = class;

  TAvocadoNodeArray = array of TAvocadoNode;

  TAvocadoNode = class
  public
    Span: TAvocadoSourceSpan;
    constructor Create(const ASpan: TAvocadoSourceSpan);
    destructor Destroy; override;
  end;

  TAvocadoExpr = class(TAvocadoNode)
  end;

  TAvocadoStmt = class(TAvocadoNode)
  end;

  { Declarations appear as statements in Avocado (type name = value). }
  TAvocadoDecl = class(TAvocadoStmt)
  end;

  { Expressions }
  TAvocadoIntegerLit = class(TAvocadoExpr)
  public
    Value: Int64;
  end;

  TAvocadoFloatLit = class(TAvocadoExpr)
  public
    Value: Double;
  end;

  TAvocadoStringLit = class(TAvocadoExpr)
  public
    Value: string;
  end;

  TAvocadoBoolLit = class(TAvocadoExpr)
  public
    Value: Boolean;
  end;

  TAvocadoNilLit = class(TAvocadoExpr)
  end;

  TAvocadoIdentExpr = class(TAvocadoExpr)
  public
    Name: string;
  end;

  TAvocadoUnaryExpr = class(TAvocadoExpr)
  public
    Op: string; // '-', '+', 'not', '@'
    Operand: TAvocadoExpr;
    destructor Destroy; override;
  end;

  TAvocadoBinaryExpr = class(TAvocadoExpr)
  public
    Op: string; // '+', '-', '*', '/', 'div', 'mod', '=', '<>', '<', '>', '<=', '>=', 'and', 'or'
    Left, Right: TAvocadoExpr;
    destructor Destroy; override;
  end;

  TAvocadoCallExpr = class(TAvocadoExpr)
  public
    CalleeName: string;   // raw name as written
    ResolvedName: string; // Pascal name after alias resolution (codegen/semantics)
    Args: TAvocadoNodeArray; // TAvocadoExpr
    destructor Destroy; override;
    procedure AddArg(AExpr: TAvocadoExpr);
    function ArgCount: Integer;
  end;

  TAvocadoIndexExpr = class(TAvocadoExpr)
  public
    Base: TAvocadoExpr;
    Index: TAvocadoExpr;
    destructor Destroy; override;
  end;

  TAvocadoMemberExpr = class(TAvocadoExpr)
  public
    Base: TAvocadoExpr;
    MemberName: string;
    destructor Destroy; override;
  end;

  TAvocadoSetExpr = class(TAvocadoExpr)
  public
    Items: TAvocadoNodeArray;
    destructor Destroy; override;
    procedure AddItem(AExpr: TAvocadoExpr);
  end;

  { Pascal Write-style format: value:width:decimals }
  TAvocadoFormatExpr = class(TAvocadoExpr)
  public
    Value: TAvocadoExpr;
    Width: Integer;
    Decimals: Integer;
    HasWidth: Boolean;
    HasDecimals: Boolean;
    destructor Destroy; override;
  end;

  { Statements }
  TAvocadoBlockStmt = class(TAvocadoStmt)
  public
    Stmts: TAvocadoNodeArray;
    destructor Destroy; override;
    procedure Add(AStmt: TAvocadoStmt);
  end;

  TAvocadoVarDecl = class(TAvocadoDecl)
  public
    TypeName: string;      // as written
    ResolvedTypeName: string; // Pascal type after alias resolution
    VarName: string;
    InitValue: TAvocadoExpr;
    IsLocal: Boolean;
    destructor Destroy; override;
  end;

  TAvocadoAssignStmt = class(TAvocadoStmt)
  public
    Target: TAvocadoExpr;
    Value: TAvocadoExpr;
    destructor Destroy; override;
  end;

  TAvocadoCallStmt = class(TAvocadoStmt)
  public
    Call: TAvocadoCallExpr;
    destructor Destroy; override;
  end;

  TAvocadoIfStmt = class(TAvocadoStmt)
  public
    Condition: TAvocadoExpr;
    ThenBranch: TAvocadoStmt;
    ElseBranch: TAvocadoStmt; // may be nil
    destructor Destroy; override;
  end;

  TAvocadoForStmt = class(TAvocadoStmt)
  public
    VarName: string;
    StartExpr: TAvocadoExpr;
    StopExpr: TAvocadoExpr;
    IsDownto: Boolean;
    Body: TAvocadoStmt;
    destructor Destroy; override;
  end;

  TAvocadoForInStmt = class(TAvocadoStmt)
  public
    VarName: string;
    Collection: TAvocadoExpr;
    Body: TAvocadoStmt;
    destructor Destroy; override;
  end;

  TAvocadoWhileStmt = class(TAvocadoStmt)
  public
    Condition: TAvocadoExpr;
    Body: TAvocadoStmt;
    destructor Destroy; override;
  end;

  TAvocadoRepeatStmt = class(TAvocadoStmt)
  public
    Body: TAvocadoStmt;
    Condition: TAvocadoExpr;
    destructor Destroy; override;
  end;

  TAvocadoReturnStmt = class(TAvocadoStmt)
  public
    Value: TAvocadoExpr; // nil for bare return
    destructor Destroy; override;
  end;

  TAvocadoBreakStmt = class(TAvocadoStmt)
  end;

  TAvocadoContinueStmt = class(TAvocadoStmt)
  end;

  TAvocadoExitStmt = class(TAvocadoStmt)
  end;

  TAvocadoPascalBlockStmt = class(TAvocadoStmt)
  public
    RawCode: string;
    IsSingleLine: Boolean;
  end;

  TAvocadoAsmBlockStmt = class(TAvocadoStmt)
  public
    RawCode: string;
  end;

  { Top-level }
  TAvocadoParam = class(TAvocadoNode)
  public
    Names: TStringList; // one or more names sharing TypeName
    TypeName: string;
    ResolvedTypeName: string;
    constructor Create(const ASpan: TAvocadoSourceSpan);
    destructor Destroy; override;
  end;

  TAvocadoRoutine = class(TAvocadoNode)
  public
    Name: string;
    IsFunction: Boolean;
    Params: TAvocadoNodeArray; // TAvocadoParam
    ReturnTypeName: string;
    ResolvedReturnTypeName: string;
    Body: TAvocadoBlockStmt;
    LocalVars: TAvocadoNodeArray; // TAvocadoVarDecl (collected)
    destructor Destroy; override;
    procedure AddParam(AParam: TAvocadoParam);
    procedure AddLocalVar(AVar: TAvocadoVarDecl);
  end;

  TAvocadoProgram = class(TAvocadoNode)
  public
    ProgramName: string;
    IsGui: Boolean;
    Imports: TStringList;       // as written, e.g. 'avoraiser.window'
    ImplementationUnits: TStringList; // moduły_pas
    GlobalVars: TAvocadoNodeArray;    // TAvocadoVarDecl
    MainBlock: TAvocadoBlockStmt;
    Routines: TAvocadoNodeArray;      // TAvocadoRoutine
    constructor Create(const ASpan: TAvocadoSourceSpan);
    destructor Destroy; override;
    procedure AddGlobalVar(AVar: TAvocadoVarDecl);
    procedure AddRoutine(ARoutine: TAvocadoRoutine);
  end;

implementation

{ TAvocadoNode }

constructor TAvocadoNode.Create(const ASpan: TAvocadoSourceSpan);
begin
  inherited Create;
  Span := ASpan;
end;

destructor TAvocadoNode.Destroy;
begin
  inherited Destroy;
end;

{ TAvocadoUnaryExpr }

destructor TAvocadoUnaryExpr.Destroy;
begin
  Operand.Free;
  inherited Destroy;
end;

{ TAvocadoBinaryExpr }

destructor TAvocadoBinaryExpr.Destroy;
begin
  Left.Free;
  Right.Free;
  inherited Destroy;
end;

{ TAvocadoCallExpr }

destructor TAvocadoCallExpr.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Args) do
    Args[I].Free;
  inherited Destroy;
end;

procedure TAvocadoCallExpr.AddArg(AExpr: TAvocadoExpr);
var
  N: Integer;
begin
  N := Length(Args);
  SetLength(Args, N + 1);
  Args[N] := AExpr;
end;

function TAvocadoCallExpr.ArgCount: Integer;
begin
  Result := Length(Args);
end;

{ TAvocadoIndexExpr }

destructor TAvocadoIndexExpr.Destroy;
begin
  Base.Free;
  Index.Free;
  inherited Destroy;
end;

{ TAvocadoMemberExpr }

destructor TAvocadoMemberExpr.Destroy;
begin
  Base.Free;
  inherited Destroy;
end;

{ TAvocadoSetExpr }

destructor TAvocadoSetExpr.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Items) do
    Items[I].Free;
  inherited Destroy;
end;

procedure TAvocadoSetExpr.AddItem(AExpr: TAvocadoExpr);
var
  N: Integer;
begin
  N := Length(Items);
  SetLength(Items, N + 1);
  Items[N] := AExpr;
end;

destructor TAvocadoFormatExpr.Destroy;
begin
  Value.Free;
  inherited Destroy;
end;

{ TAvocadoBlockStmt }

destructor TAvocadoBlockStmt.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Stmts) do
    Stmts[I].Free;
  inherited Destroy;
end;

procedure TAvocadoBlockStmt.Add(AStmt: TAvocadoStmt);
var
  N: Integer;
begin
  N := Length(Stmts);
  SetLength(Stmts, N + 1);
  Stmts[N] := AStmt;
end;

{ TAvocadoVarDecl }

destructor TAvocadoVarDecl.Destroy;
begin
  InitValue.Free;
  inherited Destroy;
end;

{ TAvocadoAssignStmt }

destructor TAvocadoAssignStmt.Destroy;
begin
  Target.Free;
  Value.Free;
  inherited Destroy;
end;

{ TAvocadoCallStmt }

destructor TAvocadoCallStmt.Destroy;
begin
  Call.Free;
  inherited Destroy;
end;

{ TAvocadoIfStmt }

destructor TAvocadoIfStmt.Destroy;
begin
  Condition.Free;
  ThenBranch.Free;
  ElseBranch.Free;
  inherited Destroy;
end;

{ TAvocadoForStmt }

destructor TAvocadoForStmt.Destroy;
begin
  StartExpr.Free;
  StopExpr.Free;
  Body.Free;
  inherited Destroy;
end;

{ TAvocadoForInStmt }

destructor TAvocadoForInStmt.Destroy;
begin
  Collection.Free;
  Body.Free;
  inherited Destroy;
end;

{ TAvocadoWhileStmt }

destructor TAvocadoWhileStmt.Destroy;
begin
  Condition.Free;
  Body.Free;
  inherited Destroy;
end;

{ TAvocadoRepeatStmt }

destructor TAvocadoRepeatStmt.Destroy;
begin
  Body.Free;
  Condition.Free;
  inherited Destroy;
end;

{ TAvocadoReturnStmt }

destructor TAvocadoReturnStmt.Destroy;
begin
  Value.Free;
  inherited Destroy;
end;

{ TAvocadoParam }

constructor TAvocadoParam.Create(const ASpan: TAvocadoSourceSpan);
begin
  inherited Create(ASpan);
  Names := TStringList.Create;
end;

destructor TAvocadoParam.Destroy;
begin
  Names.Free;
  inherited Destroy;
end;

{ TAvocadoRoutine }

destructor TAvocadoRoutine.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Params) do
    Params[I].Free;
  for I := 0 to High(LocalVars) do
    LocalVars[I].Free;
  Body.Free;
  inherited Destroy;
end;

procedure TAvocadoRoutine.AddParam(AParam: TAvocadoParam);
var
  N: Integer;
begin
  N := Length(Params);
  SetLength(Params, N + 1);
  Params[N] := AParam;
end;

procedure TAvocadoRoutine.AddLocalVar(AVar: TAvocadoVarDecl);
var
  N: Integer;
begin
  N := Length(LocalVars);
  SetLength(LocalVars, N + 1);
  LocalVars[N] := AVar;
end;

{ TAvocadoProgram }

constructor TAvocadoProgram.Create(const ASpan: TAvocadoSourceSpan);
begin
  inherited Create(ASpan);
  Imports := TStringList.Create;
  ImplementationUnits := TStringList.Create;
  MainBlock := nil;
  IsGui := False;
  ProgramName := '';
end;

destructor TAvocadoProgram.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(GlobalVars) do
    GlobalVars[I].Free;
  for I := 0 to High(Routines) do
    Routines[I].Free;
  MainBlock.Free;
  Imports.Free;
  ImplementationUnits.Free;
  inherited Destroy;
end;

procedure TAvocadoProgram.AddGlobalVar(AVar: TAvocadoVarDecl);
var
  N: Integer;
begin
  N := Length(GlobalVars);
  SetLength(GlobalVars, N + 1);
  GlobalVars[N] := AVar;
end;

procedure TAvocadoProgram.AddRoutine(ARoutine: TAvocadoRoutine);
var
  N: Integer;
begin
  N := Length(Routines);
  SetLength(Routines, N + 1);
  Routines[N] := ARoutine;
end;

end.

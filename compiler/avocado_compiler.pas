unit avocado_compiler;

{$mode objfpc}{$H+}

{ Frontend facade: source -> tokens -> AST -> semantics -> Pascal + source map.
  Each compilation is isolated; repeated calls must not retain state. }

interface

uses
  SysUtils, Classes,
  avocado_source, avocado_diagnostics, avocado_tokens, avocado_language,
  avocado_lexer, avocado_ast, avocado_parser, avocado_semantics,
  avocado_codegen, avocado_sourcemap;

type
  TAvocadoProjectKind = (apkConsole, apkGui, apkUnknown);

  TAvocadoCompileResult = class
  private
    FSuccess: Boolean;
    FGeneratedPascal: TStringList;
    FDiagnostics: TAvocadoDiagnosticList;
    FProjectKind: TAvocadoProjectKind;
    FSourceMap: TAvocadoSourceMap;
    FProgramName: string;
  public
    constructor Create;
    destructor Destroy; override;
    property Success: Boolean read FSuccess write FSuccess;
    property GeneratedPascal: TStringList read FGeneratedPascal;
    property Diagnostics: TAvocadoDiagnosticList read FDiagnostics;
    property ProjectKind: TAvocadoProjectKind read FProjectKind write FProjectKind;
    property SourceMap: TAvocadoSourceMap read FSourceMap;
    property ProgramName: string read FProgramName write FProgramName;
    function IsGui: Boolean;
  end;

  TAvocadoCompiler = class
  private
    FLang: TAvocadoLanguage;
  public
    constructor Create;
    destructor Destroy; override;
    { Compile UTF-8 source text. Caller owns the result. }
    function CompileSource(const AFileName, AText: string): TAvocadoCompileResult;
    function CompileFile(const AFileName: string): TAvocadoCompileResult;
    property Language: TAvocadoLanguage read FLang;
  end;

implementation

{ TAvocadoCompileResult }

constructor TAvocadoCompileResult.Create;
begin
  inherited Create;
  FGeneratedPascal := TStringList.Create;
  FDiagnostics := TAvocadoDiagnosticList.Create;
  FSourceMap := TAvocadoSourceMap.Create;
  FProjectKind := apkUnknown;
  FSuccess := False;
  FProgramName := '';
end;

destructor TAvocadoCompileResult.Destroy;
begin
  FGeneratedPascal.Free;
  FDiagnostics.Free;
  FSourceMap.Free;
  inherited Destroy;
end;

function TAvocadoCompileResult.IsGui: Boolean;
begin
  Result := FProjectKind = apkGui;
end;

{ TAvocadoCompiler }

constructor TAvocadoCompiler.Create;
var
  Dict: string;
begin
  inherited Create;
  FLang := TAvocadoLanguage.Create;
  Dict := ExtractFilePath(ParamStr(0)) + 'avoraiser_translate.ini';
  if FileExists(Dict) then
    FLang.LoadFunctionMap(Dict);
end;

destructor TAvocadoCompiler.Destroy;
begin
  FLang.Free;
  inherited Destroy;
end;

function TAvocadoCompiler.CompileFile(const AFileName: string): TAvocadoCompileResult;
var
  Src: TAvocadoSource;
begin
  Src := TAvocadoSource.LoadFromFile(AFileName);
  try
    Result := CompileSource(AFileName, Src.Text);
  finally
    Src.Free;
  end;
end;

function TAvocadoCompiler.CompileSource(const AFileName, AText: string): TAvocadoCompileResult;
var
  Src: TAvocadoSource;
  Lexer: TAvocadoLexer;
  Parser: TAvocadoParser;
  Sem: TAvocadoSemanticAnalyzer;
  Gen: TAvocadoCodeGenerator;
  Prog: TAvocadoProgram;
  Tokens: TAvocadoTokenArray;
  Lines: TStringList;
begin
  Result := TAvocadoCompileResult.Create;
  Result.GeneratedPascal.Clear;

  // isolated state: no fields kept across calls
  Src := TAvocadoSource.Create(AFileName, AText);
  Prog := nil;
  Lexer := nil;
  Parser := nil;
  Sem := nil;
  Gen := nil;
  try
    try
      Lexer := TAvocadoLexer.Create(Src, FLang, Result.Diagnostics);
      Tokens := Lexer.Tokenize;

      Parser := TAvocadoParser.Create(Tokens, FLang, Result.Diagnostics, Src);
      Prog := Parser.ParseProgram;

      if Prog <> nil then
      begin
        if Prog.IsGui then
          Result.ProjectKind := apkGui
        else
          Result.ProjectKind := apkConsole;
        Result.ProgramName := Prog.ProgramName;

        Sem := TAvocadoSemanticAnalyzer.Create(FLang, Result.Diagnostics, Src);
        Sem.Analyze(Prog);

        Gen := TAvocadoCodeGenerator.Create(FLang, Result.Diagnostics, Src, Result.SourceMap);
        Lines := Gen.Generate(Prog);
        Result.GeneratedPascal.Assign(Lines);

        Result.Success := not Result.Diagnostics.HasErrors;
      end
      else
      begin
        Result.Success := False;
        if Result.Diagnostics.Count = 0 then
          Result.Diagnostics.AddError('AVO0099', 'Nie udało się utworzyć AST',
            EmptySpan, AFileName);
      end;
    except
      on E: Exception do
      begin
        Result.Success := False;
        Result.Diagnostics.AddError('AVO0098', 'Błąd wewnętrzny: ' + E.Message,
          EmptySpan, AFileName);
      end;
    end;
  finally
    Prog.Free;
    Gen.Free;
    Sem.Free;
    Parser.Free;
    Lexer.Free;
    Src.Free;
  end;
end;

end.

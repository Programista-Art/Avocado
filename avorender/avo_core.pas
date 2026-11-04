unit avo_core;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, avo_types, avo_tokenizer, avo_parser, avo_dom, avo_codegen;

// Main compiler entry point: translates Avocado script to JS
function compile_avocado_to_js(const source: string): string;

implementation

function compile_avocado_to_js(const source: string): string;
var
  p: parser_t;
  ast: past_node_t;
  cg: codegen_t;
begin
  if Trim(source) = '' then Exit('');
  
  // 1. Parse the source into an AST
  parser_init(p, source);
  ast := parse_program(p);
  
  // 2. Generate JS code from AST
  codegen_init(cg);
  Result := generate_js_from_ast(cg, ast);
end;

end.

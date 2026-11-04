unit avo_codegen;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, avo_types;

type
  codegen_t = record
    output: string;
    indent_level: integer;
  end;

procedure codegen_init(var cg: codegen_t);
function generate_js_from_ast(var cg: codegen_t; ast: past_node_t): string;

implementation

procedure codegen_init(var cg: codegen_t);
begin
  cg.output := '';
  cg.indent_level := 0;
end;

procedure append_line(var cg: codegen_t; const line: string);
var
  i: integer;
  prefix: string;
begin
  prefix := '';
  for i := 1 to cg.indent_level do
    prefix := prefix + '  ';
  cg.output := cg.output + prefix + line + #10;
end;

function eval_expression(expr: past_node_t): string;
begin
  if expr = nil then Exit('');
  
  case expr^.kind of
    nk_string_literal: Result := '''' + StringReplace(expr^.value, '''', '\''', [rfReplaceAll]) + ''''; // wrap in single quotes and escape
    nk_identifier: Result := expr^.value;
    nk_number_literal: Result := expr^.value;
    nk_get_body: Result := 'document.body';
    nk_dom_create: Result := 'document.createElement(' + eval_expression(expr^.right) + ')';
    nk_binary_expr: Result := eval_expression(expr^.left) + ' ' + expr^.value + ' ' + eval_expression(expr^.right);
    nk_dom_get_value: Result := eval_expression(expr^.right) + '.value';
    nk_json_parse: Result := 'JSON.parse(' + eval_expression(expr^.right) + ')';
    nk_get_field: Result := eval_expression(expr^.left) + '[' + eval_expression(expr^.right) + ']';
    nk_dom_query_selector: Result := 'document.querySelector(' + eval_expression(expr^.right) + ')';
    nk_safe_string: Result := 'String(' + eval_expression(expr^.right) + ').replace(/\\/g, "\\\\").replace(/"/g, "\\\"")';
    nk_random_number: Result := '(Math.floor(Math.random() * (' + eval_expression(expr^.right) + ' - ' + eval_expression(expr^.left) + ' + 1)) + ' + eval_expression(expr^.left) + ')';
    nk_local_storage_get: Result := 'localStorage.getItem(' + eval_expression(expr^.right) + ')';
    nk_list_length: Result := eval_expression(expr^.right) + '.length';
    else Result := '';
  end;
end;

procedure generate_node(var cg: codegen_t; node: past_node_t);
var
  left_val, right_val: string;
  param_node: past_node_t;
  arg_node: past_node_t;
begin
  if node = nil then Exit;
  
  case node^.kind of
    nk_program:
      begin
        // Iterate through the list of statements in node^.right
        node := node^.right;
        while node <> nil do
        begin
          generate_node(cg, node);
          node := node^.next;
        end;
      end;
      
    nk_var_decl:
      begin
        if node^.right <> nil then
        begin
          if node^.right^.kind = nk_set_interval then
          begin
             right_val := eval_expression(node^.right^.left);
             append_line(cg, 'let ' + node^.value + ' = setInterval(() => {');
             Inc(cg.indent_level);
             generate_node(cg, node^.right^.right);
             Dec(cg.indent_level);
             append_line(cg, '}, ' + right_val + ');');
          end
          else if node^.right^.kind = nk_set_timeout then
          begin
             right_val := eval_expression(node^.right^.left);
             append_line(cg, 'let ' + node^.value + ' = setTimeout(() => {');
             Inc(cg.indent_level);
             generate_node(cg, node^.right^.right);
             Dec(cg.indent_level);
             append_line(cg, '}, ' + right_val + ');');
          end
          else
          begin
             right_val := eval_expression(node^.right);
             append_line(cg, 'let ' + node^.value + ' = ' + right_val + ';');
          end;
        end
        else
        begin
          append_line(cg, 'let ' + node^.value + ';');
        end;
      end;
      
    nk_const_decl:
      begin
        if node^.right <> nil then
        begin
          right_val := eval_expression(node^.right);
          append_line(cg, 'const ' + node^.value + ' = ' + right_val + ';');
        end
        else
        begin
          append_line(cg, 'const ' + node^.value + ';'); // Technically invalid JS without assign, but matches AST fallback
        end;
      end;
      
    nk_if:
      begin
        left_val := eval_expression(node^.left); // condition
        append_line(cg, 'if (' + left_val + ') {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // block
        Dec(cg.indent_level);
        
        if node^.alternate <> nil then
        begin
          append_line(cg, '} else {');
          Inc(cg.indent_level);
          generate_node(cg, node^.alternate); // else block
          Dec(cg.indent_level);
          append_line(cg, '}');
        end
        else
        begin
          append_line(cg, '}');
        end;
      end;
      
    nk_loop_repeat:
      begin
        left_val := eval_expression(node^.left); // count
        // Create an arbitrary variable name assuming basic context safely (could use UUID but random integer is fine for JS)
        append_line(cg, 'for (let i = 0; i < ' + left_val + '; i++) {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // block
        Dec(cg.indent_level);
        append_line(cg, '}');
      end;
      
    nk_assignment:
      begin
        left_val := eval_expression(node^.left);
        if (node^.right <> nil) and (node^.right^.kind = nk_set_interval) then
        begin
           right_val := eval_expression(node^.right^.left);
           append_line(cg, left_val + ' = setInterval(() => {');
           Inc(cg.indent_level);
           generate_node(cg, node^.right^.right);
           Dec(cg.indent_level);
           append_line(cg, '}, ' + right_val + ');');
        end
        else if (node^.right <> nil) and (node^.right^.kind = nk_set_timeout) then
        begin
           right_val := eval_expression(node^.right^.left);
           append_line(cg, left_val + ' = setTimeout(() => {');
           Inc(cg.indent_level);
           generate_node(cg, node^.right^.right);
           Dec(cg.indent_level);
           append_line(cg, '}, ' + right_val + ');');
        end
        else
        begin
          right_val := eval_expression(node^.right);
          append_line(cg, left_val + ' = ' + right_val + ';');
        end;
      end;
      
    nk_function_decl:
      begin
        // Iterate through parameters
        left_val := '';
        param_node := node^.left;
        while param_node <> nil do
        begin
          if left_val <> '' then left_val := left_val + ', ';
          left_val := left_val + param_node^.value;
          param_node := param_node^.next;
        end;
        
        append_line(cg, 'function ' + node^.value + '(' + left_val + ') {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // block
        Dec(cg.indent_level);
        append_line(cg, '}');
      end;
      
    nk_function_call:
      begin
        // Iterate through arguments
        left_val := '';
        arg_node := node^.left;
        while arg_node <> nil do
        begin
          if left_val <> '' then left_val := left_val + ', ';
          left_val := left_val + eval_expression(arg_node);
          arg_node := arg_node^.next;
        end;
        
        append_line(cg, node^.value + '(' + left_val + ');');
      end;
      
    nk_post_message:
      begin
        right_val := eval_expression(node^.right);
        append_line(cg, 'window.chrome.webview.postMessage(' + right_val + ');');
      end;
      
    nk_set_timeout:
      begin
        left_val := eval_expression(node^.left); // time ms
        append_line(cg, 'setTimeout(() => {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // block code
        Dec(cg.indent_level);
        append_line(cg, '}, ' + left_val + ');');
      end;
      
    nk_set_interval:
      begin
        left_val := eval_expression(node^.left); // time ms
        // Evaluate interval assignment assuming handled as expression fallback if mapped, 
        // but interval doesn't output an expression natively yet. Quick fix to ensure variable assignment picks it up:
        // Actually, because `wykonuj_co` is a statement block in parsing, let's just emit it. 
        // If it's attached as an assignment right hand, we need to assign it.
        // The parser builds nk_set_interval as a statement node.
        append_line(cg, 'setInterval(() => {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // block code
        Dec(cg.indent_level);
        append_line(cg, '}, ' + left_val + ');');
      end;
      
    nk_fetch:
      begin
        left_val := eval_expression(node^.left); // URL
        
        append_line(cg, 'fetch(' + left_val + ').then(res => res.text()).then(' + node^.value + ' => {');
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // Callback block
        Dec(cg.indent_level);
        append_line(cg, '}).catch(err => console.error("Blad sieci:", err));');
      end;
      
    nk_fetch_post:
      begin
        left_val := eval_expression(node^.left);             // URL
        right_val := eval_expression(node^.left^.next);      // DANE
        
        // Tworzymy asynchroniczne zapytanie POST w JS
        append_line(cg, 'fetch(' + left_val + ', {');
        Inc(cg.indent_level);
        append_line(cg, 'method: "POST",');
        append_line(cg, 'headers: { "Content-Type": "application/json" },');
        // Upewniamy się, że dane zostaną rzucone jako string (nawet jeśli to JSON/Obiekt)
        append_line(cg, 'body: typeof ' + right_val + ' === "string" ? ' + right_val + ' : JSON.stringify(' + right_val + ')');
        Dec(cg.indent_level);
        append_line(cg, '}).then(res => res.text()).then(' + node^.value + ' => {');
        
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // Wygeneruj kod wewnątrz callbacka
        Dec(cg.indent_level);
        append_line(cg, '}).catch(err => console.error("Blad sieci POST:", err));');
      end;
      
    nk_dom_set_style:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.style.cssText += ' + right_val + ';');
      end;
      
    nk_dom_set_value:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.value = ' + right_val + ';');
      end;
      
    nk_clear_interval:
      begin
        right_val := eval_expression(node^.right);
        append_line(cg, 'clearInterval(' + right_val + ');');
      end;
      
    nk_dom_remove:
      begin
        right_val := eval_expression(node^.right);
        append_line(cg, right_val + '.remove();');
      end;
      
    nk_local_storage_set:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, 'localStorage.setItem(' + left_val + ', ' + right_val + ');');
      end;
      
    nk_list_push:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.push(' + right_val + ');');
      end;
      
    nk_dom_append:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.appendChild(' + right_val + ');');
      end;
      
    nk_dom_set_text:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.innerText = ' + right_val + ';');
      end;
      
    nk_dom_set_attr:
      begin
        left_val := eval_expression(node^.left);
        right_val := eval_expression(node^.right);
        append_line(cg, left_val + '.setAttribute(''' + node^.value + ''', ' + right_val + ');');
      end;
      
    nk_event_listener:
      begin
        left_val := eval_expression(node^.left);
        
        // Map Polish event names to standard DOM events
        if LowerCase(node^.value) = 'klikniecie' then
          right_val := 'click'
        else if LowerCase(node^.value) = 'klawisz_w_gore' then
          right_val := 'keyup'
        else
          right_val := node^.value;
          
        if node^.callback_arg <> '' then
          append_line(cg, left_val + '.addEventListener(''' + right_val + ''', (' + node^.callback_arg + ') => {')
        else
          append_line(cg, left_val + '.addEventListener(''' + right_val + ''', () => {');
          
        Inc(cg.indent_level);
        generate_node(cg, node^.right); // generate the block
        Dec(cg.indent_level);
        append_line(cg, '});');
      end;
      
    nk_block:
      begin
        // Iterate through statements inside the block
        node := node^.right;
        while node <> nil do
        begin
          generate_node(cg, node);
          node := node^.next;
        end;
      end;
  end;
end;

function generate_js_from_ast(var cg: codegen_t; ast: past_node_t): string;
begin
  if ast <> nil then
  begin
    append_line(cg, '// Generated by Avocado Framework');
    append_line(cg, 'document.addEventListener("DOMContentLoaded", () => {');
    Inc(cg.indent_level);
    
    generate_node(cg, ast);
    
    Dec(cg.indent_level);
    append_line(cg, '});');
  end;
  Result := cg.output;
end;

end.

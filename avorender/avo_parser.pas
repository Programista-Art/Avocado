unit avo_parser;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, avo_types, avo_tokenizer;

type
  parser_t = record
    t: tokenizer_t;
    current_token: token_t;
  end;

procedure parser_init(var p: parser_t; const source: string);
function parse_program(var p: parser_t): past_node_t;

implementation

procedure advance_token(var p: parser_t);
begin
  p.current_token := tokenizer_next_token(p.t);
end;

procedure parser_init(var p: parser_t; const source: string);
begin
  tokenizer_init(p.t, source);
  advance_token(p);
end;

function parse_expression(var p: parser_t): past_node_t; forward;
function parse_statement(var p: parser_t): past_node_t; forward;
function parse_block(var p: parser_t): past_node_t; forward;

// Parse expression needs to handle za_czas and wykonuj_co since they return values that we assign
function parse_expression(var p: parser_t): past_node_t;
var
  op_node: past_node_t;
  func_name: string;
  arg1, arg2: past_node_t;
begin
  Result := nil;
  
  if p.current_token.kind = tk_keyword then
  begin
    if LowerCase(p.current_token.value) = 'pobierz_cialo' then
    begin
      advance_token(p); // skip 'pobierz_cialo'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p);
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p);
        
      Result := create_ast_node(nk_get_body);
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'stworz_element' then
    begin
      advance_token(p); // skip 'stworz_element'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_dom_create);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'losuj_liczbe' then
    begin
      advance_token(p); // skip 'losuj_liczbe'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_random_number);
        Result^.left := parse_expression(p); // min
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
          
        Result^.right := parse_expression(p); // max
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'odczytaj_lokalnie' then
    begin
      advance_token(p); // skip 'odczytaj_lokalnie'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_local_storage_get);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'rozmiar_listy' then
    begin
      advance_token(p); // skip 'rozmiar_listy'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_list_length);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'pobierz_wartosc' then
    begin
      advance_token(p); // skip 'pobierz_wartosc'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_dom_get_value);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'parsuj_json' then
    begin
      advance_token(p); // skip 'parsuj_json'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_json_parse);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'pobierz_pole' then
    begin
      advance_token(p); // skip 'pobierz_pole'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_get_field);
        Result^.left := parse_expression(p); // object
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
          
        Result^.right := parse_expression(p); // field name
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'wyszukaj_element' then
    begin
      advance_token(p); // skip 'wyszukaj_element'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_dom_query_selector);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if LowerCase(p.current_token.value) = 'bezpieczny_tekst' then
    begin
      advance_token(p); // skip 'bezpieczny_tekst'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_safe_string);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
      Exit;
    end
    else if (LowerCase(p.current_token.value) = 'za_czas') or (LowerCase(p.current_token.value) = 'wykonuj_co') then
    begin
      func_name := LowerCase(p.current_token.value);
      advance_token(p); // skip 'za_czas' or 'wykonuj_co'
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      arg1 := parse_expression(p); // czas w ms
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
        advance_token(p); // skip ','
        
      if (p.current_token.kind = tk_keyword) and (LowerCase(p.current_token.value) = 'funkcja') then
        advance_token(p); // skip 'funkcja'
        
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      arg2 := nil;
      // Parse block
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg2 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      if func_name = 'za_czas' then
        Result := create_ast_node(nk_set_timeout)
      else
        Result := create_ast_node(nk_set_interval);
        
      Result^.left := arg1; // time ms
      Result^.right := arg2; // block
      Exit;
    end;
  end;

  if p.current_token.kind = tk_string then
  begin
    Result := create_ast_node(nk_string_literal, p.current_token.value);
    advance_token(p);
  end
  else if p.current_token.kind = tk_identifier then
  begin
    Result := create_ast_node(nk_identifier, p.current_token.value);
    advance_token(p);
  end
  else if p.current_token.kind = tk_number then
  begin
    Result := create_ast_node(nk_number_literal, p.current_token.value);
    advance_token(p);
  end;
  
  // Quick hack for simple binary expressions without full precedence parsing
  if (p.current_token.kind = tk_operator) and (p.current_token.value <> '=') then
  begin
    op_node := create_ast_node(nk_binary_expr, p.current_token.value);
    op_node^.left := Result;
    advance_token(p); // skip operator
    op_node^.right := parse_expression(p);
    Result := op_node;
  end;
end;

function parse_statement(var p: parser_t): past_node_t;
var
  var_name: string;
  arg1, arg2, arg3: past_node_t;
  param_head, param_tail, param_node: past_node_t;
begin
  Result := nil;
  arg1 := nil;
  arg2 := nil;
  arg3 := nil;
  
  if p.current_token.kind = tk_keyword then
  begin
    if LowerCase(p.current_token.value) = 'zmienna' then
    begin
      advance_token(p); // skip 'zmienna'
      if p.current_token.kind = tk_identifier then
      begin
        var_name := p.current_token.value;
        advance_token(p); // skip identifier
        
        Result := create_ast_node(nk_var_decl, var_name);
        
        if (p.current_token.kind = tk_operator) and (p.current_token.value = '=') then
        begin
          advance_token(p); // skip '='
          
          Result^.right := parse_expression(p);
        end;
      end;
    end
    else if LowerCase(p.current_token.value) = 'stala' then
    begin
      advance_token(p); // skip 'stala'
      if p.current_token.kind = tk_identifier then
      begin
        var_name := p.current_token.value;
        advance_token(p); // skip identifier
        
        Result := create_ast_node(nk_const_decl, var_name);
        
        if (p.current_token.kind = tk_operator) and (p.current_token.value = '=') then
        begin
          advance_token(p); // skip '='
          Result^.right := parse_expression(p);
        end;
      end;
    end
    else if LowerCase(p.current_token.value) = 'dodaj_dziecko' then
    begin
      advance_token(p); // skip 'dodaj_dziecko'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // parent element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // child element
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_dom_append);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'ustaw_styl' then
    begin
      advance_token(p); // skip 'ustaw_styl'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // style string
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_dom_set_style);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'ustaw_tekst' then
    begin
      advance_token(p); // skip 'ustaw_tekst'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // text string
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_dom_set_text);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'ustaw_atrybut' then
    begin
      advance_token(p); // skip 'ustaw_atrybut'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // attribute name (string)
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg3 := parse_expression(p); // attribute value (string)
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_dom_set_attr);
        Result^.left := arg1; // Element
        Result^.value := arg2^.value; // Attribute Name
        Result^.right := arg3; // Attribute Value
        
        Dispose(arg2); // We copied the value, clean up the dummy node
      end;
    end
    else if LowerCase(p.current_token.value) = 'ustaw_wartosc' then
    begin
      advance_token(p); // skip 'ustaw_wartosc'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // value
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_dom_set_value);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'zatrzymaj_wykonywanie' then
    begin
      advance_token(p); // skip 'zatrzymaj_wykonywanie'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_clear_interval);
        Result^.right := parse_expression(p); // timer handle
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
    end
    else if LowerCase(p.current_token.value) = 'zapisz_lokalnie' then
    begin
      advance_token(p); // skip 'zapisz_lokalnie'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // key
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // value
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_local_storage_set);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'dodaj_do_listy' then
    begin
      advance_token(p); // skip 'dodaj_do_listy'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // array/list
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // element
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_list_push);
        Result^.left := arg1;
        Result^.right := arg2;
      end;
    end
    else if LowerCase(p.current_token.value) = 'usun_element' then
    begin
      advance_token(p); // skip 'usun_element'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        Result := create_ast_node(nk_dom_remove);
        Result^.right := parse_expression(p); // element
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
    end
    else if LowerCase(p.current_token.value) = 'jesli' then
    begin
      advance_token(p); // skip 'jesli'
      
      // Parse condition
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      arg1 := parse_expression(p);
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      // Parse block
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg2 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      arg3 := nil;
      
      // Skips optional semicolon before checking for 'w_przeciwnym_razie' since it might be parsed accidentally
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ';') then
        advance_token(p);

      // Parse optional else block
      if (p.current_token.kind = tk_keyword) and (LowerCase(p.current_token.value) = 'w_przeciwnym_razie') then
      begin
        advance_token(p); // skip w_przeciwnym_razie
        
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'start') or 
            (LowerCase(p.current_token.value) = 'początek') or 
            (LowerCase(p.current_token.value) = 'poczatek')) then
        begin
          advance_token(p); // skip start keyword
          arg3 := parse_block(p); // Parse statements for else branch
          if (p.current_token.kind = tk_keyword) and 
             ((LowerCase(p.current_token.value) = 'end') or 
              (LowerCase(p.current_token.value) = 'koniec')) then
            advance_token(p); // skip end keyword
        end;
        
        // Ensure any trailing semicolon inside or outside the block is also skipped 
        // to prevent it bleeding out and breaking further else-checks of the parent
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ';') then
          advance_token(p);
      end;
      
      Result := create_ast_node(nk_if);
      Result^.left := arg1; // condition
      Result^.right := arg2; // block
      Result^.alternate := arg3; // else block
      Exit; // Must exit immediately so outer loops don't absorb trailing identifiers
    end
    else if LowerCase(p.current_token.value) = 'powtarzaj' then
    begin
      advance_token(p); // skip 'powtarzaj'
      
      // Parse loop count
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      arg1 := parse_expression(p);
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      // Parse block
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg2 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      Result := create_ast_node(nk_loop_repeat);
      Result^.left := arg1; // condition/count
      Result^.right := arg2; // block
    end
    else if LowerCase(p.current_token.value) = 'pobierz_z_sieci' then
    begin
      advance_token(p); // skip 'pobierz_z_sieci'
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      arg1 := parse_expression(p); // parse URL
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
        advance_token(p); // skip ','
        
      if (p.current_token.kind = tk_keyword) and (LowerCase(p.current_token.value) = 'funkcja') then
        advance_token(p); // skip 'funkcja'
        
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      var_name := '';
      if p.current_token.kind = tk_identifier then
      begin
        var_name := p.current_token.value;
        advance_token(p);
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      // Parse block (poczatek ... koniec)
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg2 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      Result := create_ast_node(nk_fetch);
      Result^.left := arg1; // URL
      Result^.value := var_name; // Respose variable name
      Result^.right := arg2; // Block code
    end
    else if LowerCase(p.current_token.value) = 'wyslij_do_sieci' then
    begin
      advance_token(p); // skip 'wyslij_do_sieci'
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      arg1 := parse_expression(p); // parse URL
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
        advance_token(p); // skip ','
        
      arg2 := parse_expression(p); // parse DATA
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
        advance_token(p); // skip ','
        
      if (p.current_token.kind = tk_keyword) and (LowerCase(p.current_token.value) = 'funkcja') then
        advance_token(p); // skip 'funkcja'
        
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      var_name := '';
      if p.current_token.kind = tk_identifier then
      begin
        var_name := p.current_token.value;
        advance_token(p);
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      // Parse block (poczatek ... koniec)
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg3 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      Result := create_ast_node(nk_fetch_post);
      Result^.value := var_name; // Nazwa zmiennej callback
      if arg1 <> nil then arg1^.next := arg2; // Doczepiamy dane pod URL
      Result^.left := arg1;      // Głowa argumentów (URL -> Dane)
      Result^.right := arg3;     // Blok kodu
    end
    else if LowerCase(p.current_token.value) = 'wyslij_sygnal' then
    begin
      advance_token(p); // skip 'wyslij_sygnal'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        
        Result := create_ast_node(nk_post_message);
        Result^.right := parse_expression(p);
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
      end;
    end
    else if LowerCase(p.current_token.value) = 'funkcja' then
    begin
      advance_token(p); // skip 'funkcja'
      
      var_name := p.current_token.value; // function name
      advance_token(p); // skip name
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
        advance_token(p); // skip '('
        
      param_head := nil;
      param_tail := nil;
      
      while (p.current_token.kind <> tk_eof) and not ((p.current_token.kind = tk_symbol) and (p.current_token.value = ')')) do
      begin
        if p.current_token.kind = tk_identifier then
        begin
          param_node := create_ast_node(nk_identifier, p.current_token.value);
          if param_head = nil then
          begin
            param_head := param_node;
            param_tail := param_node;
          end
          else
          begin
            param_tail^.next := param_node;
            param_tail := param_node;
          end;
          advance_token(p); // skip parameter
        end;
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      // Parse block
      if (p.current_token.kind = tk_keyword) and 
         ((LowerCase(p.current_token.value) = 'start') or 
          (LowerCase(p.current_token.value) = 'początek') or 
          (LowerCase(p.current_token.value) = 'poczatek')) then
      begin
        advance_token(p); // skip start keyword
        arg1 := parse_block(p); // Parse statements
        if (p.current_token.kind = tk_keyword) and 
           ((LowerCase(p.current_token.value) = 'end') or 
            (LowerCase(p.current_token.value) = 'koniec')) then
          advance_token(p); // skip end keyword
      end;
      
      Result := create_ast_node(nk_function_decl, var_name);
      Result^.left := param_head; // parameters
      Result^.right := arg1; // block
    end
    else if LowerCase(p.current_token.value) = 'nasluchuj_zdarzenia' then
    begin
      advance_token(p); // skip 'nasluchuj_zdarzenia'
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
      begin
        advance_token(p); // skip '('
        arg1 := parse_expression(p); // element
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
        arg2 := parse_expression(p); // event name (string)
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
          
        var_name := ''; // Optional callback argument for funkcja(e)
          
        // Expect: funkcja(arg) poczatek ... koniec
        if (p.current_token.kind = tk_keyword) and (LowerCase(p.current_token.value) = 'funkcja') then
        begin
          advance_token(p); // skip 'funkcja'
          if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
          begin
            advance_token(p); // skip '('
            
            // Check for optional callback argument
            if p.current_token.kind = tk_identifier then
            begin
              var_name := p.current_token.value;
              advance_token(p); // skip argument identifier
            end;
            
            if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
              advance_token(p); // skip ')'
          end;
            
          if (p.current_token.kind = tk_keyword) and 
             ((LowerCase(p.current_token.value) = 'start') or 
              (LowerCase(p.current_token.value) = 'początek') or 
              (LowerCase(p.current_token.value) = 'poczatek')) then
          begin
            advance_token(p); // skip start keyword
            arg3 := parse_block(p); // Parse statements until 'end/koniec'
            if (p.current_token.kind = tk_keyword) and 
               ((LowerCase(p.current_token.value) = 'end') or 
                (LowerCase(p.current_token.value) = 'koniec')) then
              advance_token(p); // skip end keyword
          end;
        end;
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
          advance_token(p); // skip ')'
          
        Result := create_ast_node(nk_event_listener);
        Result^.left := arg1; // Element
        Result^.value := arg2^.value; // Event Name
        Result^.right := arg3; // Block (nk_block)
        Result^.callback_arg := var_name; // Set the callback argument e.g. "e"
        
        Dispose(arg2);
      end;
    end;
  end
  else if p.current_token.kind = tk_identifier then
  begin
    var_name := p.current_token.value;
    advance_token(p);
    
    // Assigment
    if (p.current_token.kind = tk_operator) and (p.current_token.value = '=') then
    begin
      advance_token(p); // skip '='
      Result := create_ast_node(nk_assignment);
      Result^.left := create_ast_node(nk_identifier, var_name);
      Result^.right := parse_expression(p);
    end
    // Function Call
    else if (p.current_token.kind = tk_symbol) and (p.current_token.value = '(') then
    begin
      advance_token(p); // skip '('
      
      param_head := nil;
      param_tail := nil;
      
      while (p.current_token.kind <> tk_eof) and not ((p.current_token.kind = tk_symbol) and (p.current_token.value = ')')) do
      begin
        param_node := parse_expression(p);
        if param_node <> nil then
        begin
          if param_head = nil then
          begin
            param_head := param_node;
            param_tail := param_node;
          end
          else
          begin
            param_tail^.next := param_node;
            param_tail := param_node;
          end;
        end;
        
        if (p.current_token.kind = tk_symbol) and (p.current_token.value = ',') then
          advance_token(p); // skip ','
      end;
      
      if (p.current_token.kind = tk_symbol) and (p.current_token.value = ')') then
        advance_token(p); // skip ')'
        
      Result := create_ast_node(nk_function_call, var_name);
      Result^.left := param_head; // arguments
    end;
  end;

  // skip semicolon
  if (p.current_token.kind = tk_symbol) and (p.current_token.value = ';') then
    advance_token(p);
end;

function parse_block(var p: parser_t): past_node_t;
var
  head, tail, stmt: past_node_t;
begin
  head := nil;
  tail := nil;

  while (p.current_token.kind <> tk_eof) and 
        not ((p.current_token.kind = tk_keyword) and 
             ((LowerCase(p.current_token.value) = 'end') or 
              (LowerCase(p.current_token.value) = 'koniec'))) do
  begin
    stmt := parse_statement(p);
    if stmt <> nil then
    begin
      if head = nil then
      begin
        head := stmt;
        tail := stmt;
      end
      else
      begin
        tail^.next := stmt;
        tail := stmt;
      end;
    end
    else
    begin
      // Skip unexpected token to avoid infinite loop
      advance_token(p);
    end;
  end;

  Result := create_ast_node(nk_block);
  Result^.right := head; // Store statements list in right pointer
end;

function parse_program(var p: parser_t): past_node_t;
var
  head, tail, stmt: past_node_t;
begin
  head := nil;
  tail := nil;

  while p.current_token.kind <> tk_eof do
  begin
    stmt := parse_statement(p);
    if stmt <> nil then
    begin
      if head = nil then
      begin
        head := stmt;
        tail := stmt;
      end
      else
      begin
        tail^.next := stmt;
        tail := stmt;
      end;
    end
    else
    begin
      // Skip unexpected token to avoid infinite loop
      advance_token(p);
    end;
  end;

  Result := create_ast_node(nk_program);
  Result^.right := head; // Store statements list in right pointer
end;

end.

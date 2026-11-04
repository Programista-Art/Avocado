unit avo_types;

{$mode objfpc}{$H+}

interface

type
  token_kind_t = (
    tk_eof,
    tk_identifier,
    tk_string,
    tk_number,
    tk_symbol,
    tk_keyword,
    tk_operator
  );

  token_t = record
    kind: token_kind_t;
    value: string;
    line: integer;
    column: integer;
  end;

  ast_node_kind_t = (
    nk_program,
    nk_var_decl,
    nk_assignment,
    nk_function_call,
    nk_dom_create,
    nk_dom_set_style,
    nk_dom_append,
    nk_string_literal,
    nk_identifier,
    nk_dom_set_text,
    nk_dom_set_attr,
    nk_event_listener,
    nk_block,
    nk_get_body,
    nk_const_decl,
    nk_if,
    nk_loop_repeat,
    nk_number_literal,
    nk_binary_expr,
    nk_post_message,
    nk_dom_get_value,
    nk_function_decl,
    nk_fetch,
    nk_json_parse,
    nk_get_field,
    nk_set_timeout,
    nk_set_interval,
    nk_dom_query_selector,
    nk_fetch_post,
    nk_safe_string,
    nk_dom_set_value,
    nk_clear_interval,
    nk_dom_remove,
    nk_random_number,
    nk_local_storage_set,
    nk_local_storage_get,
    nk_list_push,
    nk_list_length
  );

  ast_node_t = record
    kind: ast_node_kind_t;
    value: string;         // e.g. variable name or string value
    callback_arg: string;  // e.g. 'e' in funkcja(e)
    left: ^ast_node_t;     // e.g. target of assignment or function name
    right: ^ast_node_t;    // e.g. assigned value or function argument
    alternate: ^ast_node_t;// e.g. else block for if statements
    next: ^ast_node_t;     // for lists of statements
  end;
  past_node_t = ^ast_node_t;

  dom_node_kind_t = (
    dk_element,
    dk_text
  );

  dom_node_t = record
    kind: dom_node_kind_t;
    tag_name: string;
    id: string;
    classes: string;
    text_content: string;
    style: string;
    children: ^dom_node_list_t;
    next: ^dom_node_t;
  end;
  pdom_node_t = ^dom_node_t;

  dom_node_list_t = record
    head: pdom_node_t;
    tail: pdom_node_t;
  end;
  pdom_node_list_t = ^dom_node_list_t;

function create_token(kind: token_kind_t; const value: string; line, column: integer): token_t;
function create_ast_node(kind: ast_node_kind_t; const value: string = ''): past_node_t;

implementation

function create_token(kind: token_kind_t; const value: string; line, column: integer): token_t;
begin
  Result.kind := kind;
  Result.value := value;
  Result.line := line;
  Result.column := column;
end;

function create_ast_node(kind: ast_node_kind_t; const value: string = ''): past_node_t;
begin
  New(Result);
  Result^.kind := kind;
  Result^.value := value;
  Result^.callback_arg := '';
  Result^.left := nil;
  Result^.right := nil;
  Result^.alternate := nil;
  Result^.next := nil;
end;

end.

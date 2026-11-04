unit avo_dom;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, avo_types;

type
  dom_t = record
    root: pdom_node_t;
  end;

procedure dom_init(var d: dom_t);
function dom_create_element(const tag_name: string): pdom_node_t;
function dom_create_text_node(const text: string): pdom_node_t;
procedure dom_append_child(parent, child: pdom_node_t);
procedure dom_set_style(node: pdom_node_t; const style_string: string);
procedure dom_set_id(node: pdom_node_t; const id: string);
procedure dom_add_class(node: pdom_node_t; const class_name: string);
function dom_to_html(node: pdom_node_t): string;

implementation

procedure dom_init(var d: dom_t);
begin
  d.root := dom_create_element('html');
end;

function dom_create_element(const tag_name: string): pdom_node_t;
begin
  New(Result);
  Result^.kind := dk_element;
  Result^.tag_name := tag_name;
  Result^.id := '';
  Result^.classes := '';
  Result^.text_content := '';
  Result^.style := '';
  New(Result^.children);
  Result^.children^.head := nil;
  Result^.children^.tail := nil;
  Result^.next := nil;
end;

function dom_create_text_node(const text: string): pdom_node_t;
begin
  New(Result);
  Result^.kind := dk_text;
  Result^.tag_name := '';
  Result^.text_content := text;
  Result^.children := nil;
  Result^.next := nil;
end;

procedure dom_append_child(parent, child: pdom_node_t);
begin
  if parent = nil then Exit;
  if parent^.kind <> dk_element then Exit;
  if parent^.children = nil then Exit;
  
  if parent^.children^.head = nil then
  begin
    parent^.children^.head := child;
    parent^.children^.tail := child;
  end
  else
  begin
    parent^.children^.tail^.next := child;
    parent^.children^.tail := child;
  end;
end;

procedure dom_set_style(node: pdom_node_t; const style_string: string);
begin
  if node = nil then Exit;
  if node^.style <> '' then
    node^.style := node^.style + '; ' + style_string
  else
    node^.style := style_string;
end;

procedure dom_set_id(node: pdom_node_t; const id: string);
begin
  if node = nil then Exit;
  node^.id := id;
end;

procedure dom_add_class(node: pdom_node_t; const class_name: string);
begin
  if node = nil then Exit;
  if node^.classes <> '' then
    node^.classes := node^.classes + ' ' + class_name
  else
    node^.classes := class_name;
end;

function dom_to_html(node: pdom_node_t): string;
var
  html: string;
  child: pdom_node_t;
begin
  if node = nil then Exit('');
  
  if node^.kind = dk_text then
  begin
    Result := node^.text_content;
    Exit;
  end;

  html := '<' + node^.tag_name;
  
  if node^.id <> '' then
    html := html + ' id="' + node^.id + '"';
    
  if node^.classes <> '' then
    html := html + ' class="' + node^.classes + '"';
    
  if node^.style <> '' then
    html := html + ' style="' + node^.style + '"';
    
  html := html + '>';
  
  if node^.children <> nil then
  begin
    child := node^.children^.head;
    while child <> nil do
    begin
      html := html + dom_to_html(child);
      child := child^.next;
    end;
  end;
  
  html := html + '</' + node^.tag_name + '>';
  Result := html;
end;

end.

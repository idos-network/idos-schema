# sql-function.ne

@{%
const lexer = require("./lexer.cjs");
%}

@lexer lexer

main -> line:* {% d => d[0].filter(Boolean) %}

line -> actionLine {% d => d[0] %}
    | otherLine {% () => null %}

actionLine -> CREATE _ orReplace:? ACTION _ IDENT _ LPAREN wsOrNl:* args:* wsOrNl:* RPAREN wsOrNl:* owner:? public:? private:? view:? public:? returns:? LBRACE _ NL
  {% (d) => {
    const fields = d.flat(50).filter(Boolean);

    const name = fields.find(f => f.type === "IDENT");
    const args = fields.filter(f => f.type === "arg");
    const public = fields.find(f => f.type === "public");
    const private = fields.find(f => f.type === "private");
    const view = fields.find(f => f.type === "view");
    const orReplace = fields.find(f => f.type === "orReplace");
    const returns = fields.find(f => f.type === "returns");

    return {
      type: "action",
      name: name?.value,
      args: args?.[0]?.values || [],
      public: !!public,
      private: !!private,
      view: !!view,
      orReplace: !!orReplace,
      returnsArray: returns?.table ?? false,
      returns: returns?.args || [],
    }
  } %}

returns -> RETURNS _ wsOrNl:* table:? LPAREN wsOrNl:* identArgs:* wsOrNl:* RPAREN wsOrNl:*
   {% d => {
    const fields = d.flat(1000).filter(Boolean);
    const args = fields.filter(f => f.type === "arg");
    const table = fields.find(f => f.type === "table");

    return {
      type: "returns",
      table: !!table,
      args: args.map(a => a.values).flat(),
    }
    
   } %}

table -> TABLE wsOrNl:* {% () => ({ type: "table", value: true }) %}

identArgs -> identArg (COMMA wsOrNl:* identArg):*
  {% d => {
    const fields = d.flat(50).filter(Boolean).filter(x => x.type !== "COMMA");

    return {
      type: "arg",
      values: fields,
    }
  }
  %}

identArg -> IDENT _ TYPE
  {% d => {
    const fields = d.flat(50).filter(Boolean);
    const name = fields.find(f => f.type === "IDENT");
    const type = fields.find(f => f.type === "TYPE");

    return {
      name: name?.value,
      type: type?.value,
    }
  } %}

args -> arg (COMMA wsOrNl:* arg):*
  {% d => {
    const fields = d.flat(50).filter(Boolean).filter(x => x.type !== "COMMA");

    return {
      type: "arg",
      values: fields,
    }
  }
  %}

arg -> DOLLAR_IDENT _ TYPE
  {% d => {
    const fields = d.flat(50).filter(Boolean);
    const name = fields.find(f => f.type === "DOLLAR_IDENT");
    const type = fields.find(f => f.type === "TYPE");

    return {
      name: name?.value.slice(1),
      type: type?.value,
    }
  } %}

orReplace -> OR _ REPLACE _ {% () => ({ type: "orReplace", value: true }) %}

public -> PUBLIC wsOrNl:* {% () => ({ type: "public", value: true }) %}
view -> VIEW wsOrNl:* {% () => ({ type: "view", value: true }) %}
owner -> OWNER wsOrNl:* {% () => ({ type: "owner", value: true }) %}
private -> PRIVATE wsOrNl:* {% () => ({ type: "private", value: true }) %}

otherLine -> token:* NL  {% () => null %}

token ->  WORD | WS | IDENT | TABLE | LPAREN | RPAREN | DOLLAR_IDENT | COMMA | TYPE | PUBLIC | VIEW | OR | LBRACE | OWNER {% () => null %} 

wsOrNl -> WS {% () => null %}
        | NL {% () => null %}

_ -> WS:* {% () => null %}

WORD -> %WORD
WS -> %WS
NL -> %NL
CREATE -> %CREATE
OR -> %OR
REPLACE -> %REPLACE
ACTION -> %ACTION
TABLE -> %TABLE
IDENT -> %IDENT
LPAREN -> %LPAREN
RPAREN -> %RPAREN
DOLLAR_IDENT -> %DOLLAR_IDENT
COMMA -> %COMMA
TYPE -> %TYPE
PUBLIC -> %PUBLIC
VIEW -> %VIEW
RETURNS -> %RETURNS
TABLE -> %TABLE
LBRACE -> %LBRACE
OWNER -> %OWNER
PRIVATE -> %PRIVATE
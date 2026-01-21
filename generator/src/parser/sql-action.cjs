// Generated automatically by nearley, version 2.20.1
// http://github.com/Hardmath123/nearley
(function () {
function id(x) { return x[0]; }

const lexer = require("./lexer.cjs");
var grammar = {
    Lexer: lexer,
    ParserRules: [
    {"name": "main$ebnf$1", "symbols": []},
    {"name": "main$ebnf$1", "symbols": ["main$ebnf$1", "line"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "main", "symbols": ["main$ebnf$1"], "postprocess": d => d[0].filter(Boolean)},
    {"name": "line", "symbols": ["actionLine"], "postprocess": d => d[0]},
    {"name": "line", "symbols": ["otherLine"], "postprocess": () => null},
    {"name": "actionLine$ebnf$1", "symbols": ["orReplace"], "postprocess": id},
    {"name": "actionLine$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$2", "symbols": []},
    {"name": "actionLine$ebnf$2", "symbols": ["actionLine$ebnf$2", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "actionLine$ebnf$3", "symbols": []},
    {"name": "actionLine$ebnf$3", "symbols": ["actionLine$ebnf$3", "args"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "actionLine$ebnf$4", "symbols": []},
    {"name": "actionLine$ebnf$4", "symbols": ["actionLine$ebnf$4", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "actionLine$ebnf$5", "symbols": []},
    {"name": "actionLine$ebnf$5", "symbols": ["actionLine$ebnf$5", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "actionLine$ebnf$6", "symbols": ["owner"], "postprocess": id},
    {"name": "actionLine$ebnf$6", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$7", "symbols": ["public"], "postprocess": id},
    {"name": "actionLine$ebnf$7", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$8", "symbols": ["private"], "postprocess": id},
    {"name": "actionLine$ebnf$8", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$9", "symbols": ["view"], "postprocess": id},
    {"name": "actionLine$ebnf$9", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$10", "symbols": ["public"], "postprocess": id},
    {"name": "actionLine$ebnf$10", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine$ebnf$11", "symbols": ["returns"], "postprocess": id},
    {"name": "actionLine$ebnf$11", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "actionLine", "symbols": ["CREATE", "_", "actionLine$ebnf$1", "ACTION", "_", "IDENT", "_", "LPAREN", "actionLine$ebnf$2", "actionLine$ebnf$3", "actionLine$ebnf$4", "RPAREN", "actionLine$ebnf$5", "actionLine$ebnf$6", "actionLine$ebnf$7", "actionLine$ebnf$8", "actionLine$ebnf$9", "actionLine$ebnf$10", "actionLine$ebnf$11", "LBRACE", "_", "NL"], "postprocess":  (d) => {
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
        } },
    {"name": "returns$ebnf$1", "symbols": []},
    {"name": "returns$ebnf$1", "symbols": ["returns$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "returns$ebnf$2", "symbols": ["table"], "postprocess": id},
    {"name": "returns$ebnf$2", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "returns$ebnf$3", "symbols": []},
    {"name": "returns$ebnf$3", "symbols": ["returns$ebnf$3", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "returns$ebnf$4", "symbols": []},
    {"name": "returns$ebnf$4", "symbols": ["returns$ebnf$4", "args"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "returns$ebnf$5", "symbols": []},
    {"name": "returns$ebnf$5", "symbols": ["returns$ebnf$5", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "returns$ebnf$6", "symbols": []},
    {"name": "returns$ebnf$6", "symbols": ["returns$ebnf$6", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "returns", "symbols": ["RETURNS", "_", "returns$ebnf$1", "returns$ebnf$2", "LPAREN", "returns$ebnf$3", "returns$ebnf$4", "returns$ebnf$5", "RPAREN", "returns$ebnf$6"], "postprocess":  d => {
         const fields = d.flat(1000).filter(Boolean);
         const args = fields.filter(f => f.type === "arg");
         const table = fields.find(f => f.type === "table");
        
         return {
           type: "returns",
           table: !!table,
           args: args.map(a => a.values).flat(),
         }
         
        } },
    {"name": "table$ebnf$1", "symbols": []},
    {"name": "table$ebnf$1", "symbols": ["table$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "table", "symbols": ["TABLE", "table$ebnf$1"], "postprocess": () => ({ type: "table", value: true })},
    {"name": "args$ebnf$1", "symbols": []},
    {"name": "args$ebnf$1$subexpression$1$ebnf$1", "symbols": []},
    {"name": "args$ebnf$1$subexpression$1$ebnf$1", "symbols": ["args$ebnf$1$subexpression$1$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "args$ebnf$1$subexpression$1", "symbols": ["COMMA", "args$ebnf$1$subexpression$1$ebnf$1", "arg"]},
    {"name": "args$ebnf$1", "symbols": ["args$ebnf$1", "args$ebnf$1$subexpression$1"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "args", "symbols": ["arg", "args$ebnf$1"], "postprocess":  d => {
          const fields = d.flat(50).filter(Boolean).filter(x => x.type !== "COMMA");
        
          return {
            type: "arg",
            values: fields,
          }
        }
        },
    {"name": "arg$ebnf$1", "symbols": ["withPrecision"], "postprocess": id},
    {"name": "arg$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "arg", "symbols": ["IDENT", "_", "TYPE", "arg$ebnf$1"], "postprocess":  d => {
          const fields = d.flat(50).filter(Boolean);
          const name = fields.find(f => f.type === "IDENT");
          const type = fields.find(f => f.type === "TYPE");
        
          return {
            name: name?.value.startsWith("$") ? name?.value.slice(1) : name?.value,
            type: type?.value,
          }
        } },
    {"name": "withPrecision", "symbols": ["LPAREN", "_", "PRECISION", "_", "RPAREN"], "postprocess": () => null},
    {"name": "orReplace", "symbols": ["OR", "_", "REPLACE", "_"], "postprocess": () => ({ type: "orReplace", value: true })},
    {"name": "public$ebnf$1", "symbols": []},
    {"name": "public$ebnf$1", "symbols": ["public$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "public", "symbols": ["PUBLIC", "public$ebnf$1"], "postprocess": () => ({ type: "public", value: true })},
    {"name": "view$ebnf$1", "symbols": []},
    {"name": "view$ebnf$1", "symbols": ["view$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "view", "symbols": ["VIEW", "view$ebnf$1"], "postprocess": () => ({ type: "view", value: true })},
    {"name": "owner$ebnf$1", "symbols": []},
    {"name": "owner$ebnf$1", "symbols": ["owner$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "owner", "symbols": ["OWNER", "owner$ebnf$1"], "postprocess": () => ({ type: "owner", value: true })},
    {"name": "private$ebnf$1", "symbols": []},
    {"name": "private$ebnf$1", "symbols": ["private$ebnf$1", "wsOrNl"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "private", "symbols": ["PRIVATE", "private$ebnf$1"], "postprocess": () => ({ type: "private", value: true })},
    {"name": "otherLine$ebnf$1", "symbols": []},
    {"name": "otherLine$ebnf$1", "symbols": ["otherLine$ebnf$1", "token"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "otherLine", "symbols": ["otherLine$ebnf$1", "NL"], "postprocess": () => null},
    {"name": "token", "symbols": ["WORD"]},
    {"name": "token", "symbols": ["WS"]},
    {"name": "token", "symbols": ["IDENT"]},
    {"name": "token", "symbols": ["TABLE"]},
    {"name": "token", "symbols": ["LPAREN"]},
    {"name": "token", "symbols": ["RPAREN"]},
    {"name": "token", "symbols": ["COMMA"]},
    {"name": "token", "symbols": ["TYPE"]},
    {"name": "token", "symbols": ["PUBLIC"]},
    {"name": "token", "symbols": ["VIEW"]},
    {"name": "token", "symbols": ["OR"]},
    {"name": "token", "symbols": ["LBRACE"]},
    {"name": "token", "symbols": ["PRECISION"]},
    {"name": "token", "symbols": ["OWNER"], "postprocess": () => null},
    {"name": "wsOrNl", "symbols": ["WS"], "postprocess": () => null},
    {"name": "wsOrNl", "symbols": ["NL"], "postprocess": () => null},
    {"name": "_$ebnf$1", "symbols": []},
    {"name": "_$ebnf$1", "symbols": ["_$ebnf$1", "WS"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "_", "symbols": ["_$ebnf$1"], "postprocess": () => null},
    {"name": "WORD", "symbols": [(lexer.has("WORD") ? {type: "WORD"} : WORD)]},
    {"name": "WS", "symbols": [(lexer.has("WS") ? {type: "WS"} : WS)]},
    {"name": "NL", "symbols": [(lexer.has("NL") ? {type: "NL"} : NL)]},
    {"name": "CREATE", "symbols": [(lexer.has("CREATE") ? {type: "CREATE"} : CREATE)]},
    {"name": "OR", "symbols": [(lexer.has("OR") ? {type: "OR"} : OR)]},
    {"name": "REPLACE", "symbols": [(lexer.has("REPLACE") ? {type: "REPLACE"} : REPLACE)]},
    {"name": "ACTION", "symbols": [(lexer.has("ACTION") ? {type: "ACTION"} : ACTION)]},
    {"name": "TABLE", "symbols": [(lexer.has("TABLE") ? {type: "TABLE"} : TABLE)]},
    {"name": "IDENT", "symbols": [(lexer.has("IDENT") ? {type: "IDENT"} : IDENT)]},
    {"name": "LPAREN", "symbols": [(lexer.has("LPAREN") ? {type: "LPAREN"} : LPAREN)]},
    {"name": "RPAREN", "symbols": [(lexer.has("RPAREN") ? {type: "RPAREN"} : RPAREN)]},
    {"name": "COMMA", "symbols": [(lexer.has("COMMA") ? {type: "COMMA"} : COMMA)]},
    {"name": "TYPE", "symbols": [(lexer.has("TYPE") ? {type: "TYPE"} : TYPE)]},
    {"name": "PUBLIC", "symbols": [(lexer.has("PUBLIC") ? {type: "PUBLIC"} : PUBLIC)]},
    {"name": "VIEW", "symbols": [(lexer.has("VIEW") ? {type: "VIEW"} : VIEW)]},
    {"name": "RETURNS", "symbols": [(lexer.has("RETURNS") ? {type: "RETURNS"} : RETURNS)]},
    {"name": "TABLE", "symbols": [(lexer.has("TABLE") ? {type: "TABLE"} : TABLE)]},
    {"name": "LBRACE", "symbols": [(lexer.has("LBRACE") ? {type: "LBRACE"} : LBRACE)]},
    {"name": "OWNER", "symbols": [(lexer.has("OWNER") ? {type: "OWNER"} : OWNER)]},
    {"name": "PRECISION", "symbols": [(lexer.has("PRECISION") ? {type: "PRECISION"} : PRECISION)]},
    {"name": "PRIVATE", "symbols": [(lexer.has("PRIVATE") ? {type: "PRIVATE"} : PRIVATE)]}
]
  , ParserStart: "main"
}
if (typeof module !== 'undefined'&& typeof module.exports !== 'undefined') {
   module.exports = grammar;
} else {
   window.grammar = grammar;
}
})();

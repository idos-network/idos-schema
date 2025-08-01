const moo = require("moo");

const test = moo.compile({
  WS: /[ \t]+/,
  NL: { match: /\r?\n/, lineBreaks: true },
  COMMENT: /--\s+/,  // Bez newline na konci!
  CREATE: "CREATE",
  OR: "OR",
  REPLACE: "REPLACE",
  ACTION: "ACTION",
  PUBLIC: "PUBLIC",
  PRIVATE: "PRIVATE",
  VIEW: "VIEW",
  OWNER: "OWNER",
  TABLE: /table|TABLE/,
  TYPE: ['TEXT', 'UUID', 'INT', 'BOOLEAN', 'BOOL', 'INT8'],
  RETURNS: /returns|RETURNS/,
  DOLLAR_IDENT: /\$[a-zA-Z_][a-zA-Z0-9_]*/,
  IDENT:     /[a-zA-Z_][a-zA-Z0-9_]*/,
  COMMA:     ',',
  LPAREN:    '(',
  RPAREN:    ')',
  LBRACE:    '{',
  WORD:    /[^\s][^\s]*/,
});

module.exports = test;

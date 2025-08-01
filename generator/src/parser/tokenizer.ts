import moo from "moo";

const lexer = moo.compile({
  WS:      /[ \t]+/,
  COMMENT:   { match: /--.*?$/, lineBreaks: false },
  BLOCK_COMMENT: { match: /\/\*[^]*?\*\//, lineBreaks: true },
  STRING:  /'(?:\\['\\]|[^\n'])*'/, 
  DQSTRING: /"(?:\\["\\]|[^\n"])*"/,
  IDENT:   /[a-zA-Z_][a-zA-Z0-9_]*/,
  NUMBER:  /0|[1-9][0-9]*/,
  OP:      /[<>!=~]+/,
  SEMICOLON: ';',
  LPAREN:  '(',
  RPAREN:  ')',
  LBRACE:  '{',
  RBRACE:  '}',
  NL:      { match: /\n/, lineBreaks: true },
  OTHER:   /[^ \t\n]+/,
});

export const parseStatements = (file: string) => {
  const statementTokens = lexer.reset(file);

  let currentStatement = "";
  let currentCommentBlock = [];
  let deepLevel = 0;
  const blocks = []; // [{ type: "comment" | "sql", content: string }]

  for (const token of statementTokens) {
    if (token.type === "COMMENT" || token.type === "BLOCK_COMMENT") {
      currentCommentBlock.push(token.value.replace(/^--/, ""));
    } else if (token.type === "SEMICOLON" && deepLevel === 0) {
      currentStatement += token.value;

      let currentContent = currentStatement.trim();
      if (currentContent && currentContent.includes("CREATE") && currentContent.includes("ACTION")) {
        blocks.push({
          type: "sql",
          content: currentStatement.trim(),
          comments: currentCommentBlock,
        });
      }

      currentStatement = "";
      currentCommentBlock = [];
    } else if (token.type === "LBRACE") {
      currentStatement += token.value;
      deepLevel++;
    } else if (token.type === "RBRACE") {
      currentStatement += token.value;
      deepLevel--;
    } else {
      currentStatement += token.value;
    }
  }

  let currentContent = currentStatement.trim();

  if (currentContent && currentContent.includes("CREATE") && currentContent.includes("ACTION")) {
    blocks.push({
      type: "sql",
      content: currentStatement.trim(),
      comments: currentCommentBlock,
    });
  }

  return blocks;
}
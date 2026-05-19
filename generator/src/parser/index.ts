import fs from 'node:fs';
import nearley from 'nearley';

import { parseStatements } from './tokenizer';

// @ts-expect-error no types for nearley
import grammar from './sql-action.cjs';

export type KwilActionType = "TEXT" | "UUID" | "INT" | "BOOLEAN" | "BOOL" | "INT8";

export interface KwilAction {
  type: 'action';
  name: string;
  args: Value[];
  public: boolean;
  private: boolean;
  view: boolean;
  orReplace: boolean;
  returnsArray: boolean;
  returns: Value[];
  comments: string[];
  generatorComments: GeneratorComments;
}

export interface GeneratorComments {
  ignore: boolean;
  notAuthorized: boolean;
  description: string;
  paramOptional: string[];
  returnOptional: string[];
}

export interface Value {
  name: string;
  type: KwilActionType;
}

function parseArrayDescription(input: string): string[] {
  return input.replace(/\"/g, "").split(",").map(s => s.trim()).filter(s => s.length > 0);
}

function applyGeneratorComment(acc: GeneratorComments, directive: string, rawValue: string): GeneratorComments {
  const value = rawValue.trim();

  if (directive === "paramOptional") {
    if (!acc.paramOptional) {
      acc.paramOptional = [];
    }

    acc.paramOptional.push(...parseArrayDescription(value));
  } else if (directive === "returnOptional") {
    if (!acc.returnOptional) {
      acc.returnOptional = [];
    }

    acc.returnOptional.push(...parseArrayDescription(value));
  } else if (directive === "notAuthorized") {
    acc.notAuthorized = true;
  } else if (directive === "ignore") {
    acc.ignore = true;
  } else {
    // @ts-expect-error No infer types
    acc[directive] = value?.replace(/\"/g, "");
  }

  return acc;
}

export function parseSchema(schemaPath: string): KwilAction[] {
  const sql = fs.readFileSync(schemaPath, 'utf8');

  // First get statements with comments from the file
  const statements = parseStatements(sql);

  const actions: KwilAction[] = [];

  for (const statement of statements) {
    const parser = new nearley.Parser(nearley.Grammar.fromCompiled(grammar), { keepHistory: false });
    parser.feed(`\n${statement.content}\n`);

    // parse comments
    const generatorComments = statement
      .comments
      .filter(comment => comment.trim().startsWith("@generator.")) // @generator.ignore, @generator.not_authorized etc...
      .reduce((acc, comment) => {
        const trimmedComment = comment.trim();
        const results = [...trimmedComment.matchAll(/@generator\.([a-zA-Z_-]+)/gm)];

        if (results.length === 0) {
          console.error("Invalid comment format:", comment);
          return acc;
        }

        for (const [index, result] of results.entries()) {
          const valueStart = (result.index ?? 0) + result[0].length;
          const valueEnd = results[index + 1]?.index ?? trimmedComment.length;

          applyGeneratorComment(acc, result[1], trimmedComment.slice(valueStart, valueEnd));
        }

        return acc;
      }, {} as GeneratorComments);

    actions.push({
      ...parser.results[0][0],
      comments: statement.comments.filter(comment => !comment.trim().startsWith("@generator.")),
      generatorComments,
    });
  }

  return actions;
}

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
      .filter(comment => comment.trim().startsWith("@generator.")) // @generator.skip, @generator.not_authorized etc...
      .reduce((acc, comment) => {
        const result = [...comment.trim().matchAll(/@generator\.([a-zA-Z_-]*)\s*(([^\n])*){0,1}/gm)].flat();

        if (result.length === 0) {
          console.error("Invalid comment format:", comment);
          return acc;
        }
        if (result[1] === "paramOptional") {
          if (!acc.paramOptional) {
            acc.paramOptional = [];
          }


          acc.paramOptional.push(...parseArrayDescription(result[2]));
        } else if (result[1] === "returnOptional") {
          if (!acc.returnOptional) {
            acc.returnOptional = [];
          }

          acc.returnOptional.push(...parseArrayDescription(result[2]));
        } else if (["notAuthorized"].includes(result[1])) {
          // @ts-expect-error No infer types
          acc[result[1]] = result[2] || true;
        } else {
          // @ts-expect-error No infer types
          acc[result[1]] = result[2]?.replace(/\"/g, "");
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

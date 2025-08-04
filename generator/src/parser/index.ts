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
  skip: boolean;
  notAuthorized: boolean;
  description: string;
  name?: string;
  inputName?: string;
  itemName?: string;
  forceReturn?: string;
  paramOptional: string[];
}

export interface Value {
  name: string;
  type: KwilActionType;
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
      .filter(comment => comment.includes("@generator.")) // @generator.skip, @generator.not_authorized, @generator.description MESSAGE
      .reduce((acc, comment) => {
        const result = [...comment.trim().matchAll(/@generator\.([a-zA-Z_-]*)\s*(\"([^"])*\"){0,1}/gm)].flat();

        if (result.length === 0) {
          console.error("Invalid comment format:", comment);
          return acc;
        }
        if (["description", "inputName", "itemName", "name", "forceReturn"].includes(result[1])) {
          // @ts-expect-error No infer types
          acc[result[1]] = result[2]?.replace(/\"/g, "");
        } else if (result[1] === "paramOptional") {
          if (!acc.paramOptional) {
            acc.paramOptional = [];
          }

          acc.paramOptional.push(result[2]?.replace(/\"/g, ""));
        } else {
          // @ts-expect-error No infer types
          acc[result[1]] = result[2] || true;
        }

        return acc;
      }, {} as GeneratorComments);

    actions.push({
      ...parser.results[0][0],
      comments: statement.comments.filter(comment => !comment.includes("@generator.")),
      generatorComments,
    });
  }

  return actions.filter(action => !action.generatorComments.skip);
}

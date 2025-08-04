# SQL Action Parser & TypeScript Client Generator

A powerful parser that reads `CREATE ACTION` statements from SQL files and generates fully-typed TypeScript clients with Zod validation schemas.

## Features

- **SQL Action Parsing**: Parses `CREATE ACTION` statements using a custom Nearley grammar
- **TypeScript Generation**: Generates fully-typed TypeScript client code
- **Zod Validation**: Automatically creates Zod schemas for runtime validation
- **Comment Processing**: Supports generator directives via SQL comments
- **Multiple Output Formats**: Extensible template system (currently TypeScript)

## Quick Start

```bash
# Install dependencies
npm install

# Build the parser grammar
npm run parser:build

# Generate TypeScript client from SQL schema
npm run start generate
```

### SQL Action Format

The parser expects SQL files containing `CREATE ACTION` statements. Here's an example:

```sql
-- @generator.description "Create a new user"
-- @generator.name "createUser"
-- @generator.inputName "CreateUserInput"
-- @generator.paramOptional "email"
CREATE ACTION create_user(
    user_id UUID,
    email TEXT,
    name TEXT
) AS $$
    INSERT INTO users (id, email, name) VALUES ($user_id, $email, $name);
$$;
```

### Generator Directives

Use SQL comments to control code generation:

- `@generator.skip` - Skip this action in generation
- `@generator.description "text"` - Add description for the action
- `@generator.name "CustomName"` - Override the generated function name
- `@generator.inputName "InputType"` - Custom input type name
- `@generator.itemName "ItemType"` - Custom item type name for arrays
- `@generator.paramOptional "paramName"` - Mark parameter as optional
- `@generator.notAuthorized` - Mark action as requiring authorization
- `@generator.forceReturn "type"` - Force return type

### Example TypeScript Generated Code

```typescript
// Generated action schema
export const actionSchema = {
  create_user: [
    { name: "user_id", type: DataType.Uuid },
    { name: "email", type: DataType.Text },
    { name: "name", type: DataType.Text },
  ],
};

// Generated Zod schema
export const CreateUserInputSchema = z.object({
  user_id: z.string().uuid(),
  email: z.string().optional(),
  name: z.string(),
});

// Generated client function
export async function createUser(
  client: KwilActionClient,
  input: z.infer<typeof CreateUserInputSchema>
): Promise<void> {
  // Implementation...
}
```

## Project Structure

```
generator/
├── src/
│   ├── index.ts              # CLI entry point
│   ├── parser/
│   │   ├── index.ts          # Main parser logic
│   │   ├── sql-action.ne     # Nearley grammar
│   │   ├── sql-action.cjs    # Compiled grammar
│   │   └── tokenizer.ts      # SQL tokenization
│   └── templates/
│       └── typescript.ts     # TypeScript code generator
├── package.json
└── README.md
```

## Development

### Building the Grammar

The parser uses Nearley for grammar parsing. To modify the grammar:

1. Edit `src/parser/sql-action.ne`
2. Rebuild with: `npm run parser:build`

### Adding New Output Formats

1. Create a new template file in `src/templates/`
2. Implement the generation function
3. Add format support in `src/index.ts`

### Supported Data Types

- `TEXT` → `string`
- `UUID` → `uuid`
- `INT` / `INT8` → `number`
- `BOOLEAN` / `BOOL` → `boolean`


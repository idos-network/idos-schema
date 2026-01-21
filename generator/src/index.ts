import { Command } from 'commander';
import chalk from 'chalk';

import { parseSchema } from './parser';
import { generateTypescript } from './templates/typescript';
import { generateKotlin } from './templates/kotlin';

const program = new Command();

program
  .name('generator')
  .description('Generator for the KWIL-Actions')
  .version('1.0.0');

program
  .command('generate')
  .description('Generate a new KWIL-Actions')
  .option('-i, --input <file>', 'SQL schema file', '../schema.sql')
  .option('-f, --format <format>', 'Format for the output files (ts, kotlin, python, go)', 'ts')
  .action((options) => {
    console.log(`Generating KWIL-Actions from ${chalk.green(options.input)} in ${chalk.green(options.format)} format`);
    const ast = parseSchema(options.input).filter(x => x.private === false);

    if (options.format === 'ts') {
      console.log(chalk.green('Generating TypeScript...'));
      generateTypescript(ast);
    } else if (options.format === 'kotlin') {
      console.log(chalk.green('Generating Kotlin...'));
      generateKotlin(ast);
    }
  });

console.log(chalk.blue('KWIL-Actions Generator'));
program.parse(process.argv);

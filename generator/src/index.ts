import { Command } from 'commander';
import chalk from 'chalk';

import { parseSchema } from './parser';
import { generateTypescript } from './templates/typescript';

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
    const ast = parseSchema(options.input);
    generateTypescript(ast);
  });

program.parse(process.argv);

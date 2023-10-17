# frozen_string_literal: true

require 'csv'
require 'open3'
require 'tempfile'

ACTION_NAMES = {
  'wallets' => 'add_wallet_as_owner',
  'humans' => 'add_human_as_owner',
  'human_attributes' => 'add_attribute_as_owner',
  'credentials' => 'upsert_credential_as_owner',
  'shared_credentials' => 'add_shared_credential',
  'shared_human_attributes' => 'add_shared_attribute'
}.freeze

IMPORT_ORDER = {
  'humans' => 0,
  'credentials' => 1,
  'wallets' => 2,
  'human_attributes' => 3,
  'shared_credentials' => 4,
  'shared_human_attributes' => 5
}.freeze

BATCHES_DIRECTORY = ARGV[0]

def run_kwil_cli(action_name, filepath, mappings)
  cmd = "kwil-cli database batch --name=idos --action=#{action_name} --path=#{filepath}  #{mappings}"

  puts "Running `#{cmd}`"

  Open3.capture3(cmd)
end

def print_transaction_result(transaction_string)
  transaction = transaction_string.chomp.gsub('TxHash: ', '')
  puts "Getting result for transaction `#{transaction}`"

  stdout, stderr = nil
  while (stdout.nil? || stdout.empty?) && (stderr.nil? || stderr.empty?)
    stdout, stderr, status = Open3.capture3("kwil-cli utils query-tx #{transaction}")

    sleep(3)
  end

  if status.exitstatus.zero?
    puts stdout
  else
    puts stderr
  end
end

def import_batch(action_name, filepath, mappings)  
  stdout = nil
  stderr = nil

  while (stdout.nil? || stdout.empty?) && (stderr.nil? || stderr.empty?)
    stdout, stderr, status = run_kwil_cli(action_name, filepath, mappings)
    sleep(3)
  end

  if status.exitstatus.zero?
    print_transaction_result(stdout)
  else
    puts "Error running `#{action_name}`:\n#{stderr}"
  end
end


files = Dir.entries(BATCHES_DIRECTORY).delete_if { |f| File.extname(f) != '.csv' }

MAX_BATCH_SIZE = 5_000

files.sort_by { |f| IMPORT_ORDER[File.basename(f, '.csv')] }.each do |filename|
  filepath = BATCHES_DIRECTORY + filename
  table_name = File.basename(filename, '.csv')
  action_name = ACTION_NAMES[table_name]
  csv = CSV.read(filepath, headers: true)
  mappings = csv.headers.map { |h| "-m=#{h}:#{h}" }.join(' ')

  csv.each_slice(MAX_BATCH_SIZE).with_index do |batch, idx|
    tempfile = Tempfile.new(["#{table_name}-#{idx}", '.csv'])

    batch_csv = CSV.new(
      tempfile,
      write_headers: true,
      headers: csv.headers,
      force_quotes: true
    )

    batch.each { |row| batch_csv << row }
    
    tempfile.close
    import_batch(action_name, tempfile.path, mappings)
  ensure
    tempfile.unlink
  end

  sleep(5)
end


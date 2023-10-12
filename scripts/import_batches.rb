# frozen_string_literal: true

require 'csv'
require 'open3'

ACTION_NAMES = {
  'wallets' => 'add_wallet_as_owner',
  'humans' => 'add_human_as_owner',
  'human_attributes' => 'add_attribute_as_owner',
  'credentials' => 'upsert_credential_as_owner'
}.freeze

IMPORT_ORDER = {
  'humans' => 0,
  'credentials' => 1,
  'wallets' => 2,
  'human_attributes' => 3
}.freeze

batches_directory = ARGV[0]

files = Dir.entries(batches_directory).delete_if { |f| File.extname(f) != '.csv' }

files.sort_by { |f| IMPORT_ORDER[File.basename(f, '.csv')] }.each do |filename|
  filepath = batches_directory + filename
  table_name = File.basename(filename, '.csv')
  action_name = ACTION_NAMES[table_name]
  headers = CSV.read(filepath, headers: true).headers
  mappings = headers.map { |h| "-m=#{h}:#{h}" }.join(' ')

  cmd = "kwil-cli database batch --name=idos --action=#{action_name} --path=#{filepath}  #{mappings}"
  stdout, stderr, status = Open3.capture3(cmd)

  if status.exitstatus.zero?
    puts "#{cmd}: #{stdout}"
  else
    puts "Error running `#{cmd}`:\n#{stderr}"
  end

  sleep(3)
end

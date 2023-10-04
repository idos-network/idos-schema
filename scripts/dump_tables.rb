# frozen_string_literal: true

require 'json'
require 'open3'

local_db = ARGV[0]
target_dir = ARGV[1]
schema_file = ARGV[2]

schema = JSON.load_file(schema_file)

schema.each do |table|
  table_name = table['name']

  stdout, stderr, status = Open3.capture3("sqlite3 -json #{local_db} \"SELECT * FROM #{table_name};\"")

  if status.exitstatus.zero?
    File.write("#{target_dir}/#{table_name}.json", stdout) unless stdout.empty?
  else
    puts "Error dumping #{table_name}:\n#{stderr}"
  end
end

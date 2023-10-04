# frozen_string_literal: true

require 'json'
require 'csv'
require 'readline'

def schema_diffs(old_schema, new_schema)
  new_schema.each_with_object({}) do |updated_table, memo|
    table_name = updated_table['name']
    new_columns = updated_table['columns'].to_a

    old_table = old_schema.find { |t| t['name'] == table_name }
    old_columns = old_table['columns'].to_a

    added_changes = new_columns - old_columns
    removed_changes = old_columns - new_columns

    memo[table_name] = {}
    memo[table_name][:added] = added_changes if added_changes.any?
    memo[table_name][:removed] = removed_changes if removed_changes.any?
  end
end

def new_required_fields(diffs)
  diffs.each_with_object({}) do |(table_name, diff), memo|
    diff[:added]&.each do |added|
      not_null = added['attributes']&.any? { |attr| attr['type'] == 'NOT_NULL' }
      next unless not_null

      memo[table_name] ||= [] << added['name']
    end
  end
end

def removed_fields(diffs)
  diffs.each_with_object({}) do |(table_name, diff), memo|
    diff[:removed]&.each do |removed|
      memo[table_name] ||= [] << removed['name']
    end
  end
end

def write_csv_from_json(csv_directory, json_content, table_name)
  CSV.open(
    "#{csv_directory}/#{table_name}.csv",
    'wb',
    write_headers: true,
    headers: json_content.first.keys,
    force_quotes: true
  ) do |csv|
    json_content.each do |row|
      csv << row.values.map { |v| v.gsub(/\n/, '\\n') }
    end
  end
end

def add_required_fields_to_json(json_file, table_name, new_required_fields)
  new_required_fields.each do |required_field|
    next if json_file.first.keys.include?(required_field)

    default_value = Readline.readline("Default value for `#{table_name}.#{required_field}`: ")
    json_file.each do |payload|
      current_value = payload[required_field]

      payload[required_field] = default_value if current_value.nil? || current_value.empty?
    end
  end

  json_file
end

def remove_from_json(json_file, new_schema, table_name, removed_fields)
  removed_fields.each do |removed_field|
    table = new_schema.find { |s| s['name'] == table_name }

    next if table && table['columns'].any? { |c| c['name'] == removed_field }

    json_file.each do |payload|
      payload.delete(removed_field)
    end
  end

  json_file
end

old_schema_file = ARGV[0]
new_schema_file = ARGV[1]
json_directory = ARGV[2]
csv_directory = ARGV[3]

old_schema = JSON.load_file(old_schema_file)
new_schema = JSON.load_file(new_schema_file)

diffs = schema_diffs(old_schema, new_schema)
new_required_fields = new_required_fields(diffs)
removed_fields = removed_fields(diffs)

Dir.foreach(json_directory) do |filename|
  next unless File.extname(filename) == '.json'

  table_name = File.basename(filename, '.json')
  puts "trying to open #{json_directory + filename}"
  json_file = JSON.load_file(json_directory + filename)

  if (required = new_required_fields[table_name])
    json_file = add_required_fields_to_json(json_file, table_name, required)
  end

  if (removed = removed_fields[table_name])
    json_file = remove_from_json(json_file, new_schema, table_name, removed)
  end

  write_csv_from_json(csv_directory, json_file, table_name)
end

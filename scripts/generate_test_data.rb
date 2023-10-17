require 'csv'
require 'securerandom'

NUMBER_OF_RECORDS = 10_000

def generate_attribute(attribute_id, human_id)
  {
    id: attribute_id,
    human_id: human_id,
    attribute_key: "MigrationTestAttribute",
    value: "foo" # TODO: must be encrypted 
  }
end

def generate_credential(credential_id, human_id)
  {
    id: credential_id, 
    human_id: human_id,
    issuer: "MigrationTest",
    credential_type: "Migrated",
    content: "foo", # TODO: must be encrypted
    encryption_public_key: "FOO", # TODO
  }
end

def generate_wallet(human_id)
  {
    id: SecureRandom.uuid,
    human_id: human_id,
    address: "FOO", # TODO
    public_key: "asdasd", # TODO
    message: "Migration test message",
    signature: "FOO", # TODO
  }
end

def generate_shared_attribute(original_id, duplicate_id)
  {
    original_id: original_id,
    duplicate_id: duplicate_id
  }
end

def generate_shared_credential(original_id, duplicate_id)
  {
    original_id: original_id,
    duplicate_id: duplicate_id
  }
end

TEST_DATA_FOLDER = ARGV[0]

puts "Generating at #{TEST_DATA_FOLDER}"
# humans
human_ids = NUMBER_OF_RECORDS.times.map { SecureRandom.uuid }
humans_file = File.new("#{TEST_DATA_FOLDER}/humans.csv", 'w')
humans_csv = CSV.new(
  humans_file,
  write_headers: true,
  headers: %i[id],
  force_quotes: true
)

attribute_ids = NUMBER_OF_RECORDS.times.map { SecureRandom.uuid }
attributes_file = File.new("#{TEST_DATA_FOLDER}/human_attributes.csv", 'w')
attributes_csv = CSV.new(
  attributes_file,
  write_headers: true,
  headers: %i[id human_id attribute_key value], # this is positional
  force_quotes: true
)

credential_ids = NUMBER_OF_RECORDS.times.map { SecureRandom.uuid }
credentials_file = File.new("#{TEST_DATA_FOLDER}/credentials.csv", 'w')
credentials_csv = CSV.new(
  credentials_file,
  write_headers: true,
  headers: %i[id human_id issuer credential_type content encryption_public_key], # this is positional
  force_quotes: true
)

wallets_file = File.new("#{TEST_DATA_FOLDER}/wallets.csv", 'w')
wallets_csv = CSV.new(
  wallets_file,
  write_headers: true,
  headers: %i[id human_id address public_key message signature], # this is positional
  force_quotes: true
)

shared_attributes_file = File.new("#{TEST_DATA_FOLDER}/shared_human_attributes.csv", 'w')
shared_attributes_csv = CSV.new(
  shared_attributes_file,
  write_headers: true,
  headers: %i[original_id duplicate_id],
  force_quotes: true
)

shared_credentials_file = File.new("#{TEST_DATA_FOLDER}/shared_credentials.csv", 'w')
shared_credentials_csv = CSV.new(
  shared_credentials_file,
  write_headers: true,
  headers: %i[original_id duplicate_id],
  force_quotes: true
)

human_ids.each_with_index do |human_id, idx|
  humans_csv << [human_id]
  wallets_csv << generate_wallet(human_id)
  attributes_csv << generate_attribute(attribute_ids[idx], human_id)
  credentials_csv << generate_credential(credential_ids[idx], human_id)
end

attribute_ids.each_slice(2) do |original_id, duplicate_id|
  shared_attributes_csv << generate_shared_attribute(original_id, duplicate_id)
end

credential_ids.each_slice(2) do |original_id, duplicate_id|
  shared_credentials_csv << generate_shared_credential(original_id, duplicate_id)
end

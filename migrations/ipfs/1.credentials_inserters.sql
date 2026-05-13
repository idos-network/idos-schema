ALTER TABLE credentials ADD COLUMN inserter_type TEXT;
ALTER TABLE credentials RENAME COLUMN inserter TO inserter_id;


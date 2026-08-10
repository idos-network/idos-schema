ALTER TABLE credentials ADD COLUMN inserter_type TEXT;
ALTER TABLE credentials RENAME COLUMN inserter TO inserter_id;
ALTER TABLE credentials ALTER COLUMN content DROP NOT NULL;
ALTER TABLE credentials ADD COLUMN content_uri TEXT;
ALTER TABLE credentials ADD COLUMN content_size INT8;
ALTER TABLE credentials ADD CHECK (content IS NOT NULL OR content_uri IS NOT NULL);
ALTER TABLE credentials ADD CHECK (content_size IS NULL OR content_size > 0);
CREATE INDEX IF NOT EXISTS credentials_content_uri ON credentials(content_uri);

ALTER TABLE credentials ADD COLUMN content_uri TEXT;
ALTER TABLE credentials ADD COLUMN content_size INT8;
ALTER TABLE credentials ADD CHECK (content_size IS NULL OR content_size > 0);
CREATE INDEX IF NOT EXISTS credentials_content_uri ON credentials(content_uri);

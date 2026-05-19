ALTER TABLE credentials ADD CHECK (content IS NOT NULL OR content_uri IS NOT NULL);

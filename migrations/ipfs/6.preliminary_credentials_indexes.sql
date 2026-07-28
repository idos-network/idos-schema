CREATE INDEX IF NOT EXISTS preliminary_credentials_original_id_copy_id ON preliminary_credentials(original_id, copy_id);
CREATE INDEX IF NOT EXISTS preliminary_credentials_copy_id ON preliminary_credentials(copy_id);
CREATE INDEX IF NOT EXISTS preliminary_credentials_original_content_uri ON preliminary_credentials(original_content_uri);
CREATE INDEX IF NOT EXISTS preliminary_credentials_copy_content_uri ON preliminary_credentials(copy_content_uri);
CREATE INDEX IF NOT EXISTS preliminary_credentials_created_at ON preliminary_credentials(created_at);

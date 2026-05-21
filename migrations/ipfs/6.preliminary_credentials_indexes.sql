CREATE INDEX IF NOT EXISTS prelim_cred_original_id_copy_id ON preliminary_credentials(original_id, copy_id);
CREATE INDEX IF NOT EXISTS prelim_cred_copy_id ON preliminary_credentials(copy_id);
CREATE INDEX IF NOT EXISTS prelim_cred_original_content_uri ON preliminary_credentials(original_content_uri);
CREATE INDEX IF NOT EXISTS prelim_cred_copy_content_uri ON preliminary_credentials(copy_content_uri);

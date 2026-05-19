CREATE TABLE IF NOT EXISTS preliminary_credentials (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    original_id UUID,
    original_content_uri TEXT,
    original_content_size INT CHECK (original_content_size IS NULL OR original_content_size > 0),
    original_encryptor_public_key TEXT,
    copy_id UUID,
    copy_content_uri TEXT,
    copy_content_size INT CHECK (copy_content_size IS NULL OR copy_content_size > 0),
    copy_encryptor_public_key TEXT,
    verifiable_credential_id TEXT,
    content_hash TEXT,
    public_notes TEXT,
    issuer_auth_public_key TEXT NOT NULL,
    grantee_wallet_identifier TEXT,
    locked_until INT8,
    original_id_for_copy UUID, -- it is needed for share_credential action
    inserter_type TEXT NOT NULL,
    inserter_id TEXT NOT NULL,
    created_at INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS preliminary_credentials_user_id ON preliminary_credentials(user_id);

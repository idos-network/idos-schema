ALTER TABLE users ADD COLUMN encryption_public_key_store_type TEXT;
ALTER TABLE users ADD CHECK (encryption_public_key_store_type IN ('password', 'mpc'));
UPDATE users SET encryption_public_key_store_type = 'password';
ALTER TABLE users ALTER COLUMN encryption_public_key_store_type SET NOT NULL;

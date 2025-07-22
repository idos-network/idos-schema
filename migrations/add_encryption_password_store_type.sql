ALTER TABLE users ADD COLUMN encryption_password_store_type TEXT;
ALTER TABLE users ADD CHECK (encryption_password_store_type IN ('user', 'mpc'));
UPDATE users SET encryption_password_store_type = 'user';
ALTER TABLE users ALTER COLUMN encryption_password_store_type SET NOT NULL;

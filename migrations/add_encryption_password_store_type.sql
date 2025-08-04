ALTER TABLE users ADD COLUMN encryption_password_store TEXT;
ALTER TABLE users ADD CHECK (encryption_password_store IN ('user', 'mpc'));
UPDATE users SET encryption_password_store = 'user';
ALTER TABLE users ALTER COLUMN encryption_password_store SET NOT NULL;

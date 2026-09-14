ALTER TABLE users DROP CONSTRAINT users_encryption_password_store_check;
ALTER TABLE users ADD CHECK (encryption_password_store IN ('user', 'mpc', 'mm'));

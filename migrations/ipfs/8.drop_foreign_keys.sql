-- TO make it work we have to remove 32 symbols name restriction on KwilDB
-- Or we have to drop consumed_write_grants table and create a new one without foreign keys

ALTER TABLE consumed_write_grants DROP CONSTRAINT consumed_write_grants_original_credential_id_fkey;
ALTER TABLE consumed_write_grants DROP CONSTRAINT consumed_write_grants_copy_credential_id_fkey;

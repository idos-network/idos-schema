-- Remove public_notes column from credentials
-- ATTENTION! This causes irreversible data loss. Be sure the migration went well and all data are in the place before.
ALTER TABLE credentials DROP COLUMN IF EXISTS public_notes;

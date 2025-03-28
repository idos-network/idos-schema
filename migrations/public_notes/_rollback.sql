DROP TABLE IF EXISTS public_notes;
ALTER TABLE credentials DROP COLUMN IF EXISTS public_notes_id;

-- THis won't get back the data. Only for a structural rollback.
ALTER TABLE credentials ADD COLUMN IF NOT EXISTS public_notes;

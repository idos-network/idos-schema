-- create table public_notes
CREATE TABLE public_notes (
  id UUID PRIMARY KEY,
  notes TEXT NOT NULL
);

-- add public_notes_id column into credentials
ALTER TABLE credentials ADD COLUMN public_notes_id UUID;

-- for each original credential create a record in public_notes with id generated from the credential's id
INSERT INTO public_notes (id, notes)
  SELECT uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, c.id::TEXT), c.public_notes FROM credentials as c
    LEFT JOIN shared_credentials as sc ON c.id = sc.copy_id
    WHERE sc.copy_id is null;


-- for original credentials set public_notes_id by generating it the same deterministic way as for public_notes
UPDATE credentials
  SET public_notes_id = uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, id::TEXT)
  WHERE uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, id::TEXT) IN (SELECT id FROM public_notes);


-- copy original credential's public_notes_id to copies
WITH ids AS (
  SELECT id as idd, sc.original_id FROM credentials as c
    INNER JOIN shared_credentials as sc ON c.id = sc.copy_id
)
UPDATE credentials
  SET public_notes_id = uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, ids.original_id::TEXT)
  FROM ids
  WHERE id = ids.idd;

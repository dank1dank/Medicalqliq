ALTER TABLE mediafiles ADD COLUMN file_name TEXT;
UPDATE mediafiles SET file_name = (SELECT original_path FROM message_attachment WHERE mediafile_id = mediafiles.id);

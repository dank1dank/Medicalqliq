ALTER TABLE message ADD COLUMN acked_recipient_count INTEGER;
UPDATE message SET acked_recipient_count = -1;

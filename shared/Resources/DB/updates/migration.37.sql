ALTER TABLE message ADD COLUMN opened_recipient_count INTEGER;
UPDATE message SET opened_recipient_count = -1;

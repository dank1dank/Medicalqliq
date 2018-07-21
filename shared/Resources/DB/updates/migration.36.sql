ALTER TABLE message ADD COLUMN opened_sent INTEGER;
CREATE INDEX message_opened_sent_idx ON message(opened_sent);
UPDATE message SET opened_sent = 1;

ALTER TABLE message ADD COLUMN server_context TEXT;

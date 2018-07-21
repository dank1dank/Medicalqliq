ALTER TABLE message ADD COLUMN recall_status INTEGER;
CREATE INDEX message_recall_status_idx ON message(recall_status);
UPDATE message SET recall_status = 0;

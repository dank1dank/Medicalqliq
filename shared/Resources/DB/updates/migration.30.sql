ALTER TABLE message ADD COLUMN total_recipient_count INTEGER;
ALTER TABLE message ADD COLUMN delivered_recipient_count INTEGER;
ALTER TABLE message_status_log ADD COLUMN qliq_id VARCHAR(10);

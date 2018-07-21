ALTER TABLE message ADD COLUMN self_delivery_status INTEGER;
CREATE INDEX message_self_delivery_status_idx ON message(self_delivery_status);
UPDATE message SET self_delivery_status = 200;

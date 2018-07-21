ALTER TABLE message ADD COLUMN ack_sent_to_server_at DATETIME;
CREATE INDEX message_ack_required_idx ON message(ack_required);
CREATE INDEX message_ack_sent_at_idx ON message(ack_sent_at);
CREATE INDEX message_ack_sent_to_server_at_idx ON message(ack_sent_to_server_at);

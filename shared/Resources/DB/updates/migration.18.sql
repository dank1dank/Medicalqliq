ALTER TABLE message ADD COLUMN priority INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS message_priority_idx ON message(priority);

CREATE INDEX IF NOT EXISTS message_timestamp_idx ON message(timestamp);
CREATE INDEX IF NOT EXISTS message_conversation_id_idx ON message(conversation_id);
CREATE INDEX IF NOT EXISTS message_from_qliq_id_idx ON message(from_qliq_id);
CREATE INDEX IF NOT EXISTS message_uuid_idx ON message(uuid);
CREATE INDEX IF NOT EXISTS message_is_rev_dirty_idx ON message(is_rev_dirty);
CREATE INDEX IF NOT EXISTS message_read_at_idx ON message(read_at);
CREATE INDEX IF NOT EXISTS message_call_id_idx ON message(call_id);
CREATE INDEX IF NOT EXISTS message_delivery_status_idx ON message(delivery_status);
CREATE INDEX IF NOT EXISTS message_to_qliq_id_idx ON message(to_qliq_id);
CREATE INDEX IF NOT EXISTS message_acks_idx ON message(ack_required, ack_received_at, ack_sent_at);

CREATE INDEX IF NOT EXISTS conversation_last_updated_idx ON conversation(last_updated);
CREATE INDEX IF NOT EXISTS conversation_subject_idx ON conversation(subject);

CREATE INDEX IF NOT EXISTS qliq_user_status_idx ON qliq_user(status);
CREATE INDEX IF NOT EXISTS qliq_user_sip_uri_idx ON qliq_user(sip_uri);

CREATE INDEX IF NOT EXISTS message_attachment_uuid_idx ON message_attachment(uuid);
CREATE INDEX IF NOT EXISTS message_attachment_status_idx ON message_attachment(status);
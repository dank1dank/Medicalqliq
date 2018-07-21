ALTER TABLE conversation ADD COLUMN conversation_uuid TEXT;
CREATE INDEX conversation_conversation_uuid_idx ON conversation(conversation_uuid);
ALTER TABLE encrypted_sip_message ADD COLUMN mime TEXT;
ALTER TABLE encrypted_sip_message ADD COLUMN extra_headers TEXT;

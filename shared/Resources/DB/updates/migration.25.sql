# Deleted status for message retention and type for events.
ALTER TABLE message ADD COLUMN deleted INTEGER DEFAULT 0;
ALTER TABLE message ADD COLUMN type INTEGER DEFAULT 0;
CREATE INDEX message_deleted_idx ON message(deleted);

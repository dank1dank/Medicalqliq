ALTER TABLE mediafiles ADD COLUMN deleted INTEGER DEFAULT 0;
ALTER TABLE mediafiles ADD COLUMN archived INTEGER DEFAULT 0;
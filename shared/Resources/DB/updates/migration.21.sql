ALTER TABLE conversation ADD COLUMN recipients_id INTEGER;

CREATE TABLE IF NOT EXISTS recipients (recipients_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
CREATE TABLE IF NOT EXISTS recipients_qliq_id (recipients_id INT, recipient_id TEXT, recipient_class TEXT);
CREATE UNIQUE INDEX IF NOT EXISTS recipients_qliq_id_idx ON recipients_qliq_id(recipients_id, recipient_id);
ALTER TABLE conversation ADD COLUMN multiparty_id INTEGER;

CREATE TABLE IF NOT EXISTS multiparty (qliq_id TEXT  NOT NULL PRIMARY KEY,name TEXT,public_key TEXT,private_key TEXT,sip_uri TEXT);
CREATE INDEX IF NOT EXISTS mp_qliq_id_idx_unique ON multiparty(qliq_id);
CREATE TABLE IF NOT EXISTS multiparty_participants (multiparty_qliq_id TEXT DEFAULT NULL,participant_qliq_id TEXT);
CREATE INDEX IF NOT EXISTS mp_qliq_id_idx ON multiparty_participants(multiparty_qliq_id);

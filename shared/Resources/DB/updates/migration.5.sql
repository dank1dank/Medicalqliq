DROP TABLE IF EXISTS qliq_group;
CREATE TABLE IF NOT EXISTS qliq_group (qliq_id varchar(10) NOT NULL PRIMARY KEY, parent_qliq_id varchar(10), name text,acronym text,address text,city text,state text,zip text,phone text,fax text,sip_uri text, npi text,taxonomy_code text);

DROP TABLE IF EXISTS user_group;
CREATE TABLE IF NOT EXISTS user_group (user_qliq_id text, group_qliq_id text, access_type text, FOREIGN KEY (user_qliq_id) REFERENCES qliq_user (qliq_id), FOREIGN KEY (group_qliq_id) REFERENCES qliq_group (qliq_id) );

DROP TABLE IF EXISTS conversation_leg;
CREATE TABLE IF NOT EXISTS conversation_leg (id integer NOT NULL PRIMARY KEY AUTOINCREMENT,conversation_id integer NOT NULL,qliq_id text NOT NULL,joined_at datetime NOT NULL,left_at datetime); CREATE INDEX IF NOT EXISTS conversation_id_idx ON conversation_leg (conversation_id); CREATE INDEX IF NOT EXISTS qliq_id_idx ON conversation_leg (qliq_id);

DROP TABLE IF EXISTS message;
CREATE TABLE IF NOT EXISTS message ( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, conversation_id INTEGER, from_qliq_id TEXT, to_qliq_id TEXT, message TEXT, uuid TEXT, ack_required INTEGER, timestamp DATETIME, delivery_status INTEGER, failed_attempts INTEGER, last_sent_at DATETIME, ack_received_at DATETIME, received_at DATETIME, read_at DATETIME, ack_sent_at DATETIME, rev text, author text, seq text, is_rev_dirty INTEGER,  local_created_time DATE DEFAULT (datetime('now','localtime')), call_id TEXT, CONSTRAINT conversation_id_fk FOREIGN KEY (conversation_id) REFERENCES conversation (id) ); CREATE INDEX IF NOT EXISTS conversation_id_idx ON message (conversation_id); CREATE INDEX IF NOT EXISTS from_qliq_id_idx ON message (from_qliq_id); CREATE INDEX IF NOT EXISTS to_qliq_id_idx ON message (to_qliq_id);
ALTER TABLE message ADD COLUMN has_attachment INTEGER;

CREATE TABLE IF NOT EXISTS device ( uuid VARCHAR(10) NOT NULL PRIMARY KEY, qliq_id VARCHAR(10) NOT NULL,platform text, public_key text);

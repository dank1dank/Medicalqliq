CREATE TABLE IF NOT EXISTS encrypted_sip_message (	id INTEGER PRIMARY KEY AUTOINCREMENT,	from_uri TEXT, to_uri TEXT, body TEXT, timestamp DATETIME);

CREATE INDEX IF NOT EXISTS encrypted_sip_message_to_uri_idx ON encrypted_sip_message(to_uri);
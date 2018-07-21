CREATE TABLE IF NOT EXISTS web_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	session DATETIME,
	sequence_id INTEGER,
	timestamp DATETIME,
	method INTEGER,
	url TEXT,
	response_code INTEGER,
	duration INTEGER,
	json_error INTEGER,
	request TEXT,
	response TEXT
);
CREATE INDEX IF NOT EXISTS web_log_session_idx ON web_log(session);

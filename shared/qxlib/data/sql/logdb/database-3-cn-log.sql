CREATE TABLE IF NOT EXISTS cn_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	session DATETIME,
	sequence_id INTEGER,
	timestamp DATETIME,
	subject TEXT,
	qliq_id TEXT,
	feature TEXT,
	json TEXT,
	processing_status INTEGER
);
CREATE INDEX IF NOT EXISTS cn_log_session_idx ON cn_log(session);
CREATE INDEX IF NOT EXISTS cn_log_qliq_id_idx ON cn_log(qliq_id);
CREATE INDEX IF NOT EXISTS cn_log_session_processing_status ON cn_log(processing_status);

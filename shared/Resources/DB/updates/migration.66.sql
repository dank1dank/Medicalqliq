CREATE TABLE IF NOT EXISTS qx_change_notification (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	subject TEXT,
	qliq_id TEXT,
	json TEXT,
	has_payload INTEGER,
	timestamp DATEIME,
	errors TEXT,
	UNIQUE(subject, qliq_id) ON CONFLICT REPLACE
);

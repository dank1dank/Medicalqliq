CREATE TABLE IF NOT EXISTS push_notification_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	session DATETIME,
	sequence_id INTEGER,
	timestamp DATETIME,
	call_id TEXT,
	body TEXT
);
CREATE INDEX IF NOT EXISTS push_notification_log_session_idx ON push_notification_log(session);
CREATE INDEX IF NOT EXISTS push_notification_log_call_id_idx ON push_notification_log(call_id);

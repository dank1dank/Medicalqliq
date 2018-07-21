CREATE TABLE IF NOT EXISTS received_push_notification (
	call_id TEXT PRIMARY KEY,
	received_at DATETIME,
	sent_to_server INTEGER DEFAULT 0
);

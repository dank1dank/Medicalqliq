CREATE TABLE IF NOT EXISTS qx_web_request (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
	server_type INTEGER NOT NULL,
	path TEXT NOT NULL,
	json TEXT,
	uuid TEXT
);
CREATE INDEX IF NOT EXISTS qx_web_request_uuid_idx ON qx_web_request(uuid);

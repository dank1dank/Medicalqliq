CREATE TABLE IF NOT EXISTS 'qx_media_file_upload_event' (
        'id' INTEGER PRIMARY KEY AUTOINCREMENT,
	'upload_id' INTEGER NOT NULL,
	'type' INTEGER NOT NULL,
	'timestamp' DATEIME NOT NULL,
	'message' TEXT,
	FOREIGN KEY (upload_id) REFERENCES qx_media_file_upload(id) ON DELETE CASCADE
);
CREATE INDEX qx_media_file_upload_event_upload_id_idx ON qx_media_file_upload_event(upload_id);


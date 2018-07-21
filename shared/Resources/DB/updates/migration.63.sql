CREATE TABLE IF NOT EXISTS qx_media_file (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	mime TEXT,
	key TEXT,
	file_name TEXT,
	size INTEGER,
	checksum TEXT,
	thumbnail TEXT,
	url TEXT,
	encrypted_file_path TEXT,
	decrypted_file_path TEXT,
	status INTEGER,
	timestamp DATEIME
);
CREATE INDEX qx_media_file_status_idx ON qx_media_file(status);

CREATE TABLE IF NOT EXISTS qx_media_file_upload (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	upload_uuid TEXT,
	qliqstor_qliq_id TEXT,
	share_type INTEGER,
	media_file_id INTEGER,
	raw_upload_target_json TEXT,
	status INTEGER,
	status_message TEXT
);
CREATE INDEX qx_media_file_upload_upload_uuid_idx ON qx_media_file_upload(upload_uuid);
CREATE INDEX qx_media_file_upload_media_file_id_idx ON qx_media_file_upload(media_file_id);
CREATE INDEX qx_media_file_upload_status_idx ON qx_media_file_upload(status);


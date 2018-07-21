CREATE TABLE IF NOT EXISTS sip_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	session DATETIME,
	sequence_id INTEGER,
	timestamp DATETIME,
	direction INTEGER,
	method TEXT,
	from_ TEXT,
	to_ TEXT,
	status_code INTEGER,
	duration INTEGER,
	call_id TEXT,
	cseq TEXT,
	request TEXT,
	response TEXT,
	plaintext_request_body TEXT,
	plaintext_response_body TEXT,
	decryption_status INTEGER
);
CREATE INDEX IF NOT EXISTS sip_log_session_idx ON sip_log(session);
CREATE INDEX IF NOT EXISTS sip_log_direction_idx ON sip_log(direction);
CREATE INDEX IF NOT EXISTS sip_log_method_idx ON sip_log(method);
CREATE INDEX IF NOT EXISTS sip_log_from_idx ON sip_log(from_);
CREATE INDEX IF NOT EXISTS sip_log_to_idx ON sip_log(to_);
CREATE INDEX IF NOT EXISTS sip_log_status_code_idx ON sip_log(status_code);
CREATE INDEX IF NOT EXISTS sip_log_call_id_idx ON sip_log(call_id);
CREATE INDEX IF NOT EXISTS sip_log_session_cseq_call_id_idx ON sip_log(session, cseq, call_id);
CREATE INDEX IF NOT EXISTS sip_log_decryption_status_idx ON sip_log(decryption_status);

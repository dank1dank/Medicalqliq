CREATE INDEX IF NOT EXISTS sip_log_timestamp_idx ON sip_log(timestamp);
CREATE INDEX IF NOT EXISTS web_log_timestamp_idx ON web_log(timestamp);
CREATE INDEX IF NOT EXISTS cn_log_timestamp_idx ON cn_log(timestamp);
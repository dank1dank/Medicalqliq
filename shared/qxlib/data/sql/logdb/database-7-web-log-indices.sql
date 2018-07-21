CREATE INDEX IF NOT EXISTS web_log_url_idx ON web_log(url);
CREATE INDEX IF NOT EXISTS web_log_response_code_idx ON web_log(response_code);
CREATE INDEX IF NOT EXISTS web_log_json_error_idx ON web_log(json_error);
CREATE INDEX IF NOT EXISTS web_log_duration_idx ON web_log(duration);

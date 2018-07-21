ALTER TABLE web_log ADD COLUMN module INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS web_log_module_idx ON web_log(module);
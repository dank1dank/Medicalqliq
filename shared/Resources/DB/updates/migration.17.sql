CREATE TABLE IF NOT EXISTS group_qliqstor (	group_qliq_id VARCHAR(10) NOT NULL PRIMARY KEY, qliq_id VARCHAR(10) NOT NULL, FOREIGN KEY (group_qliq_id) REFERENCES qliq_group(qliq_id));
CREATE TABLE IF NOT EXISTS message_qliqstor_status (message_id INTEGER NOT NULL, qliqstor_qliq_id VARCHAR(10) NOT NULL, status INTEGER, PRIMARY KEY (message_id, qliqstor_qliq_id), FOREIGN KEY (message_id) REFERENCES message(id), FOREIGN KEY (qliqstor_qliq_id) REFERENCES qliq_user(qliq_id));
CREATE INDEX message_qliqstor_status_message_id_idx ON message_qliqstor_status(message_id);
CREATE INDEX message_qliqstor_status_qliqstor_qliq_id_idx ON message_qliqstor_status(qliqstor_qliq_id);
CREATE INDEX message_qliqstor_status_status_idx ON message_qliqstor_status(status);
CREATE INDEX user_group_user_qliq_id_idx ON user_group(user_qliq_id);
CREATE INDEX user_group_group_qliq_id_idx ON user_group(group_qliq_id);

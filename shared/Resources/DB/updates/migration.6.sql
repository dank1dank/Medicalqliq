ALTER TABLE message_status_log RENAME TO message_status_log_db5;

CREATE TABLE IF NOT EXISTS message_status_log (message_id integer,timestamp DATETIME, status integer);

INSERT INTO message_status_log (message_id, timestamp) SELECT message_id, timestamp FROM message_status_log_db5;

UPDATE message_status_log SET status = 1 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Created');
UPDATE message_status_log SET status = 2 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Sent');
UPDATE message_status_log SET status = 3 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Received');
UPDATE message_status_log SET status = 4 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Ack Sent');
UPDATE message_status_log SET status = 5 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Ack Received');
UPDATE message_status_log SET status = 6 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Read');
UPDATE message_status_log SET status = 200 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Delivered');
UPDATE message_status_log SET status = 202 WHERE rowid IN (SELECT rowid FROM message_status_log_db5 WHERE status_msg = 'Pending');

DROP TABLE message_status_log_db5;
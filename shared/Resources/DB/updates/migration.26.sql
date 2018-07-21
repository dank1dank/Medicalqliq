ALTER TABLE qliq_user ADD COLUMN presence_message TEXT;
ALTER TABLE qliq_user ADD COLUMN presence_status INTEGER DEFAULT 0;
ALTER TABLE qliq_user ADD COLUMN forwarding_qliq_id VARCHAR(10);
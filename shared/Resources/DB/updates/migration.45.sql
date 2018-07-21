ALTER TABLE qliq_group ADD COLUMN deleted INTEGER;
CREATE INDEX qliq_group_deleted_idx ON qliq_group(deleted);
UPDATE qliq_group SET deleted = 0;


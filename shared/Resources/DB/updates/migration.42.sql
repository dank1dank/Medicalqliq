ALTER TABLE qliq_group ADD COLUMN can_broadcast INTEGER;
ALTER TABLE qliq_group ADD COLUMN can_message INTEGER;
ALTER TABLE conversation ADD COLUMN is_broadcast INTEGER;
UPDATE conversation SET is_broadcast = 0;

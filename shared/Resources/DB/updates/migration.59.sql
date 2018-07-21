ALTER TABLE qliq_user ADD COLUMN is_pager_only_user INTEGER DEFAULT 0;
ALTER TABLE qliq_user ADD COLUMN pager_info TEXT;
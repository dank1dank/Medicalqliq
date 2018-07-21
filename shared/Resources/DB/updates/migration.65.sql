ALTER TABLE qx_media_file ADD COLUMN encryption_method TEXT;
ALTER TABLE qx_media_file ADD COLUMN encrypted_key TEXT;
ALTER TABLE qx_media_file ADD COLUMN public_key_md5 TEXT;
ALTER TABLE qx_media_file ADD COLUMN extra_key_encrypted_key TEXT;
ALTER TABLE qx_media_file ADD COLUMN extra_key_public_key_md5 TEXT;
ALTER TABLE qx_media_file ADD COLUMN extra_key_qliq_id TEXT;

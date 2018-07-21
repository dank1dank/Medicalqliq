ALTER TABLE message ADD COLUMN has_attachment INTEGER;

CREATE TABLE IF NOT EXISTS "message_attachment" (id integer PRIMARY KEY AUTOINCREMENT,uuid TEXT,url TEXT,file_path TEXT,file_mime_type text,enc_key TEXT,enc_method INTEGER,file_size INTEGER,local_path TEXT,original_path TEXT,thumbnail TEXT,status INTEGER,mediafile_id integer DEFAULT 0);

CREATE TABLE IF NOT EXISTS mediafiles (id integer PRIMARY KEY AUTOINCREMENT,file_mime_type text,file_path text,encryption_key text);
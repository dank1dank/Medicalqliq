DROP TABLE IF EXISTS quick_message;
CREATE TABLE IF NOT EXISTS quick_message (id integer PRIMARY KEY AUTOINCREMENT,message text NOT NULL,display_order integer);
ALTER TABLE mediafiles ADD COLUMN file_size text;
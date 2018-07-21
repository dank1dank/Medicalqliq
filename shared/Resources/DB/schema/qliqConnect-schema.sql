"favorite_contacts","CREATE TABLE IF NOT EXISTS favorite_contacts(id  INTEGER PRIMARY KEY,contact_type INTEGER,contact_id NUMERIC)";
"last_subject_seq","CREATE TABLE IF NOT EXISTS last_subject_seq (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, subject TEXT, last_update DATE, seq INTEGER, operation INTEGER, database_uuid TEXT)";
"last_updated_subject","CREATE TABLE IF NOT EXISTS last_updated_subject ( id integer NOT NULL, username varchar(50,0) NOT NULL, subject varchar(50,0) NOT NULL, last_update date NOT NULL, PRIMARY KEY(id) )";
"quick_message","CREATE TABLE IF NOT EXISTS quick_message (id integer PRIMARY KEY AUTOINCREMENT,message text NOT NULL,display_order TEXT)";

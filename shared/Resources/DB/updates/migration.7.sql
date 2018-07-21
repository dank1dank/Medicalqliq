CREATE TABLE IF NOT EXISTS contact (contact_id INTEGER PRIMARY KEY AUTOINCREMENT,first_name TEXT,middle_name TEXT,last_name TEXT,group_name TEXT,email TEXT,address TEXT,city TEXT,state TEXT,zip TEXT, mobile TEXT,phone TEXT,fax TEXT,avatar BLOB,status INTEGER,type INTEGER);

CREATE TABLE IF NOT EXISTS contactlist (contactlist_id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT);

CREATE TABLE IF NOT EXISTS contact_contactlist (contactlist_id INTEGER, contact_id INTEGER);

CREATE TABLE IF NOT EXISTS invitation (uuid TEXT NOT NULL PRIMARY KEY,url TEXT NOT NULL,contact_id INTEGER,status TEXT, invited_at DATETIME,operation INTEGER);

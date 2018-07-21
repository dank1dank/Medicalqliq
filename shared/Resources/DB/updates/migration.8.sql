DROP TABLE IF EXISTS qliq_user;

CREATE TABLE IF NOT EXISTS qliq_user (qliq_id varchar(10) NOT NULL PRIMARY KEY, contact_id INTEGER NOT NULL,profession text, credentials text, sip_uri text, npi text,taxonomy_code text, status text);

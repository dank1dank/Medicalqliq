CREATE TABLE IF NOT EXISTS sip_contact (
	contact_qliq_id VARCHAR(10) NOT NULL PRIMARY KEY,
	sip_uri TEXT,
	private_key TEXT,
	public_key TEXT,
	type INTEGER
);
CREATE INDEX IF NOT EXISTS sip_contact_sip_uri_idx ON sip_contact(sip_uri);

INSERT INTO sip_contact(contact_qliq_id, sip_uri, public_key, type)
SELECT qliq_user.qliq_id, sip_uri, public_key, 1 FROM qliq_user LEFT OUTER JOIN device ON (device.qliq_id = qliq_user.qliq_id) GROUP BY qliq_user.qliq_id;

INSERT INTO sip_contact(contact_qliq_id, sip_uri, type)
SELECT qliq_id, sip_uri, 2 FROM qliq_group;

INSERT INTO sip_contact(contact_qliq_id, sip_uri, private_key, public_key, type)
SELECT qliq_id, sip_uri, private_key, public_key, 3 FROM multiparty;

ALTER TABLE qliq_user RENAME to qliq_user_db22;
CREATE TABLE qliq_user (
	qliq_id VARCHAR(10) NOT NULL PRIMARY KEY,
	contact_id INTEGER,
	profession TEXT,
	credentials TEXT,
	npi TEXT,
	taxonomy_code TEXT,
	status TEXT
);
INSERT INTO qliq_user(qliq_id, contact_id, profession, credentials, npi, taxonomy_code, status)  SELECT qliq_id, contact_id, profession, credentials, npi, taxonomy_code, status FROM qliq_user_db22;
DROP TABLE qliq_user_db22;
DROP TABLE device;
CREATE INDEX qliq_user_status_idx ON qliq_user(status);

ALTER TABLE qliq_group RENAME to qliq_group_db22;
CREATE TABLE qliq_group (
	qliq_id VARCHAR(10) NOT NULL PRIMARY KEY,
	parent_qliq_id VARCHAR(10),
	name TEXT,
	address TEXT,
	city TEXT,
	state TEXT,
	zip TEXT,
	phone TEXT,
	fax TEXT,
	npi TEXT,
	taxonomy_code TEXT,
	acronym TEXT
);
INSERT INTO qliq_group(qliq_id, parent_qliq_id, name, address, city, state, zip, phone, fax, npi, taxonomy_code, acronym) SELECT qliq_id, parent_qliq_id, name, address, city, state, zip, phone, fax, npi, taxonomy_code, acronym FROM qliq_group_db22;
DROP TABLE qliq_group_db22;

ALTER TABLE multiparty RENAME TO multiparty_db22;
CREATE TABLE multiparty (
    qliq_id VARCHAR(10) NOT NULL PRIMARY KEY,
    name TEXT,
    participants TEXT,
    is_owner INTEGER
);
INSERT INTO multiparty(qliq_id, name) SELECT qliq_id, name FROM multiparty_db22;
DROP TABLE multiparty_db22;

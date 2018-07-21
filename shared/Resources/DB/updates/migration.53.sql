CREATE TABLE IF NOT EXISTS fhir_patient (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	uuid TEXT NOT NULL,
	hl7id TEXT,
	first_name TEXT,
	middle_name TEXT,
	last_name TEXT,
	date_of_birth DATETIME,
	date_of_death DATETIME,
	deceased INTEGER,
	gender INTEGER,
	race TEXT,
	phone_home TEXT,
	phone_work TEXT,
	email TEXT,
	insurance TEXT,
	address TEXT,
	patient_account_number TEXT,
	social_security_number TEXT,
	drivers_license_number TEXT,
	nationality TEXT,
	language TEXT,
	marital_status TEXT
);
CREATE INDEX fhir_patient_uuid ON fhir_patient(uuid);

CREATE TABLE IF NOT EXISTS fhir_practitioner (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	uuid TEXT NOT NULL,
	hl7id TEXT,
	first_name TEXT,
	middle_name TEXT,
	last_name TEXT
);
CREATE INDEX fhir_practitioner_uuid ON fhir_practitioner(uuid);

CREATE TABLE IF NOT EXISTS fhir_encounter (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	uuid TEXT NOT NULL,
	hl7id TEXT,
	patient INTEGER NOT NULL,
	attending_doctor INTEGER,
	period_start DATETIME,
	period_end DATETIME,
	status INTEGER,
	location_point_of_care TEXT,
	location_room TEXT,
	location_bed TEXT,
	location_facility TEXT,
	location_building TEXT,
	location_floor TEXT
);
CREATE INDEX fhir_encounter_uuid ON fhir_encounter(uuid);

CREATE TABLE IF NOT EXISTS fhir_encounter_participant (
	encounter_id INTEGER NOT NULL,
	participant_id INTEGER NOT NULL,
	participant_type TEXT
);

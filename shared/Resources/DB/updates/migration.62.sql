ALTER TABLE fhir_patient ADD COLUMN last_update_reason TEXT;

ALTER TABLE fhir_patient ADD COLUMN alternate_patient_id TEXT COLLATE NOCASE;

-- general search field indices
CREATE INDEX fhir_patient_first_name_idx ON fhir_patient(first_name);
CREATE INDEX fhir_patient_last_name_idx ON fhir_patient(last_name);
CREATE INDEX fhir_patient_date_of_birth_idx ON fhir_patient(date_of_birth);
-- various numbers and ids indices
CREATE INDEX fhir_patient_hl7id_idx ON fhir_patient(hl7id);
CREATE INDEX fhir_patient_alternate_patient_id_idx ON fhir_patient(alternate_patient_id);
CREATE INDEX fhir_patient_master_patient_index_idx ON fhir_patient(master_patient_index);
CREATE INDEX fhir_patient_medical_record_number_idx ON fhir_patient(medical_record_number);
CREATE INDEX fhir_patient_patient_account_number_idx ON fhir_patient(patient_account_number);
CREATE INDEX fhir_patient_social_security_number_idx ON fhir_patient(social_security_number);
CREATE INDEX fhir_patient_drivers_license_number_idx ON fhir_patient(drivers_license_number);


ALTER TABLE fhir_encounter ADD COLUMN alternate_visit_id TEXT COLLATE NOCASE;
ALTER TABLE fhir_encounter ADD COLUMN preadmit_number TEXT COLLATE NOCASE;
ALTER TABLE fhir_encounter ADD COLUMN last_update_reason TEXT;

-- general search field indices
CREATE INDEX fhir_encounter_patient_idx ON fhir_encounter(patient);
CREATE INDEX fhir_encounter_period_start_idx ON fhir_encounter(period_start);
CREATE INDEX fhir_encounter_period_end_idx ON fhir_encounter(period_end);
CREATE INDEX fhir_encounter_status_idx ON fhir_encounter(status);

-- various numbers and ids indices
CREATE INDEX fhir_encounter_visit_number_idx ON fhir_encounter(visit_number);
CREATE INDEX fhir_encounter_alternate_visit_id_idx ON fhir_encounter(alternate_visit_id);
CREATE INDEX fhir_encounter_preadmit_number_idx ON fhir_encounter(preadmit_number);


CREATE INDEX fhir_encounter_participant_encounter_id_idx ON fhir_encounter_participant(encounter_id);
CREATE INDEX fhir_encounter_participant_participant_id_idx ON fhir_encounter_participant(participant_id);


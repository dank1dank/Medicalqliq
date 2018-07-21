ALTER TABLE fhir_patient ADD COLUMN master_patient_index TEXT;
ALTER TABLE fhir_patient ADD COLUMN medical_record_number TEXT;
ALTER TABLE fhir_encounter ADD COLUMN visit_number TEXT;
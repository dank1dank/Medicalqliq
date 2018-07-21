#include "FhirProcessor.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/dao/fhir/FhirResourceDao.hpp"
#include "qxlib/util/RapidJsonHelper.hpp"

using namespace rapidjson::helper;

bool FhirProcessor::processFhirAttachment(const char *json)
{
    bool ret = false;
    try {
        auto doc = stringToDocument(json);
        if (doc) {
            if (getOptString(*doc, "resourceType") == "Encounter") {
                fhir::Encounter e = fhir::Encounter::fromJson(*doc, json);

                // Try to find the patient based on HL7 id and if found then reuse PK and uuid
                fhir::Patient existingPatient = fhir::PatientDao::selectOneBy(fhir::PatientDao::UuidColumn, e.patient.uuid);
                if (existingPatient.isEmpty()) {
                    e.patient.lastUpdateReason = "fhir-insert";
                    fhir::PatientDao::insert(&e.patient);
                } else {
                    e.patient.id = existingPatient.id;
                    e.patient.uuid = existingPatient.uuid;
                    e.patient.lastUpdateReason = "fhir-update";
                    fhir::PatientDao::update(e.patient);
                }

                fhir::Encounter existingEncounter = fhir::EncounterDao::selectOneBy(fhir::EncounterDao::UuidColumn, e.uuid);
                if (existingEncounter.isEmpty()) {
                    fhir::EncounterDao::insert(&e);
                } else {
                    e.id = existingEncounter.id;
                    e.uuid = existingEncounter.uuid;
                    fhir::EncounterDao::update(e);
                }
                ret = true;
            }
            delete doc;
        }
    } catch (const std::exception& ex) {
        QXLOG_ERROR("Cannot process FHIR attachment: %s", ex.what());
    }
    return ret;
}

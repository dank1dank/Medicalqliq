#include "QxCareChannelDao.hpp"
#include "qxlib/dao/fhir/FhirResourceDao.hpp"

bool qx::CareChannelDao::hasAny()
{
    bool ret = false;
    const std::string sql = "SELECT conversation.id FROM conversation JOIN fhir_encounter ON (conversation.conversation_uuid = fhir_encounter.uuid) LIMIT 1";
    try {
        SQLite::Database& db = QxDatabase::database();
        SQLite::Statement q(db, sql);
        if (q.executeStep()) {
            ret = true;
        }
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool qx::CareChannelDao::existsWithUuid(const std::string &uuid)
{
    return fhir::EncounterDao::exists(fhir::EncounterDao::UuidColumn, uuid);
}

void qx::CareChannelDao::remove(const std::string &uuid)
{
    auto encounter = fhir::EncounterDao::selectOneBy(fhir::EncounterDao::UuidColumn, uuid);
    if (!encounter.isEmpty()) {
        fhir::EncounterDao::delete_(fhir::EncounterDao::IdColumn, std::to_string(encounter.id));
        int count = fhir::EncounterDao::count(fhir::EncounterDao::PatientColumn, std::to_string(encounter.patient.id));
        if (count == 0) {
            fhir::PatientDao::delete_(fhir::PatientDao::IdColumn, std::to_string(encounter.patient.id));
        }
    }
}

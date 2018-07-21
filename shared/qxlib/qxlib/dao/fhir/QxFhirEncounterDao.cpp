#include "QxFhirEncounterDao.hpp"
#include "qxlib/dao/fhir/FhirResourceDao.hpp"

fhir::Encounter qx::fhir::EncounterDao::selectOneByUuid(const std::string &uuid)
{
    ::fhir::Encounter ret = ::fhir::EncounterDao::selectOneBy(::fhir::EncounterDao::UuidColumn, uuid);
    if (!ret.isEmpty()) {
        ::fhir::EncounterDao::loadChildren(&ret);
    }
    return ret;
}

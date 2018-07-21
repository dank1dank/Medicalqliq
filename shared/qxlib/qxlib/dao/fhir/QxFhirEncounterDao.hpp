#ifndef QXFHIRENCOUNTERDAO_HPP
#define QXFHIRENCOUNTERDAO_HPP
#include "qxlib/model/fhir/FhirResources.hpp"

namespace qx {
namespace fhir {

class EncounterDao
{
public:
    static ::fhir::Encounter selectOneByUuid(const std::string& uuid);
};

} // fhir
} // qx

#endif // QXFHIRENCOUNTERDAO_HPP

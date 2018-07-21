#ifndef QXFHIRRESOURCEDAO_H
#define QXFHIRRESOURCEDAO_H
#include <set>
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/model/fhir/FhirResources.hpp"

namespace fhir {

class PatientDao : public QxBaseDao<fhir::Patient>
{
public:
    enum Column {
        IdColumn,
        UuidColumn,
        Hl7IdColumn,
        FirstNameColumn,
        MiddleNameColumn,
        LastNameColumn,
        DateOfBirthColumn,
        DateOfDeathColumn,
        DeceasedColumn,
        GenderColumn,
        RaceColumn,
        PhoneHomeColumn,
        PhoneWorkColumn,
        EmailColumn,
        InsuranceColumn,
        AddressColumn,
        PatientAccountNumberColumn,
        SocialSecurityNumberColumn,
        DriversLicenseNumberColumn,
        NationalityColumn,
        LanguageColumn,
        MaritalStatusColumn,
        PhotoDataColumn,
        MasterPatientIndexColumn,
        MedicalRecordNumberColumn,
        LastUpdateReasonColumn,
        AlternatePatientIdColumn,
        ColumnCount
    };
};

class EncounterDao : public QxBaseDao<fhir::Encounter>
{
public:
    enum Column {
        IdColumn,
        UuidColumn,
        PatientColumn,
        PeriodStartColumn,
        PeriodEndColumn,
        StatusColumn,
        LocationPointOfCareColumn,
        LocationRoomColumn,
        LocationBedColumn,
        LocationFacilityColumn,
        LocationBuildingColumn,
        LocationFloorColumn,
        VisitNumberColumn,
        RawJsonColumn,
        AlternateVisitIdColumn,
        PreadmitNumberColumn,
        LastUpdateReasonColumn,
        ColumnCount
    };

    static void loadChildren(fhir::Encounter *encounter);
};

class ParticipantsDao {
public:
    static std::set<Participant> selectByMultipartyQliqId(const std::string& qliqId);
};

} // namespace fhir

#endif // QXFHIRRESOURCEDAO_H

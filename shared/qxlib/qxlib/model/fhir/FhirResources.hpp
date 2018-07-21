#ifndef FHIRRESOURCES_H
#define FHIRRESOURCES_H
#include <string>
#include <stdexcept>
#include <set>
#include "qxlib/util/RapidJsonHelper.hpp"

namespace qx {
class QliqUser;
}

///
/// Website with nice HL7 data fields definitions:
/// http://hl7-definition.caristix.com:9010/Default.aspx?version=HL7%20v2.5.1
///
namespace fhir {

class Attachment {
public:
    std::string contentType;
    std::string data; // base64 encoded when in JSON, binary data in RAM (this field)
    std::string url;
    unsigned int size;  // size of data where the url points to
    std::string hash;

    Attachment();
    bool isEmpty() const;
#ifndef SWIG
    void serialize(rapidjson::helper::StringWriter& writer) const;

    static Attachment fromJson(const rapidjson::Value& jsonObject);
#endif // !SWIG
};

enum class Gender : char {
    Unknown = 'U',
    Male = 'M',
    Female = 'F',
    Other = 'O'
};

class Patient {
public:
    unsigned long id;        // local database id
    std::string uuid;       // FHIR 'id' inside qliq system, used by clients

    // HL7 support fields (used on qliqStor)
    std::string hl7Id;              // PID-3.1 (possibly MRN)
    std::string hl7RawPid;          // Complete PID-3 segment
    std::string alternatePatientId; // PID-4.1

    std::string firstName;
    std::string middleName;
    std::string lastName;
    std::string dateOfBirth;
    std::string dateOfDeath;
    bool deceased;
    Gender gender;
    std::string race;
    std::string phoneHome;
    std::string phoneWork;
    std::string email;
    std::string insurance;
    std::string address;
    std::string masterPatientIndex; // EMPI
    std::string medicalRecordNumber; // MRN
    std::string patientAccountNumber;
    std::string socialSecurityNumber;
    std::string driversLicenseNumber;
    std::string nationality;
    std::string language;
    std::string maritalStatus;
    Attachment photo;
    std::string lastUpdateReason;   // csv-(insert|update), hl7-(insert|update), fhir-(insert|update)

    Patient();
    bool isEmpty() const;
    /// Full name with age and gender
    std::string displayName() const;
    /// Full name
    std::string fullName() const;
    int age() const;
    std::string demographicsText() const;
    std::string toLogString() const;
#ifndef SWIG
    /// Tests if patient has all required fields for patients coming from an HL7 system
    bool isValidFromHl7(std::string *errorMessage = nullptr, bool breakOnFirstMissingField = false) const;

    void serialize(rapidjson::helper::StringWriter& writer, bool dontEndObject = false) const;

    static Patient fromJson(const rapidjson::Value& jsonObject);
    static Gender genderFromString(const std::string& str);
    static std::string genderToString(Gender gender);

    static void test();
#endif // !SWIG
};

class Practitioner {
public:
    unsigned long id; // local database id
    std::string uuid;
    std::string firstName;
    std::string middleName;
    std::string lastName;
    // HL7 support fields
    std::string hl7Id;
    std::string qliqId;

    Practitioner();
#ifndef SWIG
    explicit Practitioner(const qx::QliqUser& user);
    void serialize(rapidjson::helper::StringWriter& writer) const;
    bool operator<(const Practitioner& other) const;
    bool operator==(const Practitioner& other) const;

    static Practitioner fromJson(const rapidjson::Value& jsonObject);
#endif // !SWIG

    bool isEmpty() const;
};

class Participant {
public:
    enum Type {
        Unknown,
        AdmittingDoctor,
        AttendingDoctor,
        ConsultingDoctor,
        ReferringDoctor,
        TypeCount
    };

    Type type;
    std::string typeText;
    Practitioner doctor;

    Participant();
    bool isEmpty() const;
#ifndef SWIG
    // Tries to parse this string to find a standard defined type
    void setTypeFromText(const std::string& text);
    void serializeContained(rapidjson::helper::StringWriter& writer) const;
    void serialize(rapidjson::helper::StringWriter& writer) const;

    bool operator<(const Participant& other) const;
    bool operator==(const Participant& other) const;

    static std::string typeToString(Type type);
    static Type typeFromString(const std::string& str);
    static const std::string typeNames[TypeCount];
#endif // !SWIG
};

/// This is not a FHIR standard location, but a helper class that maps directly to HL7 location concepts
class LocationHl7 {
public:
    std::string pointOfCare;
    std::string room;
    std::string bed;
    std::string facility;
    std::string building;
    std::string floor;

    bool isEmpty() const;
    std::string singleLineString() const;
#ifndef SWIG
    void serializeContained(rapidjson::helper::StringWriter& writer) const;
    void serialize(rapidjson::helper::StringWriter& writer) const;
    static LocationHl7 fromJson(const rapidjson::Value& jsonObject);
#endif // !SWIG
};

class Encounter {
public:
    enum Status {
        UnknownStatus = 0,
        PlannedStatus = 1,
        ArrivedStatus = 2,
        InProgressStatus = 3,
        OnLeaveStatus = 4,
        FinishedStatus = 5,
        CancelledStatus = 6
    };

    unsigned long id; // local database id
    std::string uuid;
    std::string visitNumber;        // PV1-19.1
    // HL7 support fields
    std::string alternateVisitId;   // PV1-50.1
    std::string preadmitNumber;     // PV1-5.1

    Patient patient;
    std::string periodStart;
    std::string periodEnd;
    int status;
#ifndef SWIG
    std::set<Participant> participants;
#endif // !SWIG
    LocationHl7 location;

    std::string rawJson;    // complete JSON received
    std::string lastUpdateReason;   // csv-(insert|update), hl7-(insert|update), fhir-(insert|update)

    Encounter();
    bool isEmpty() const;
    std::string summaryTextForRecentsList() const;
#ifndef SWIG
    /// Tests if encounter (and optionally patient) has all required fields for patients coming from an HL7 system
    bool isValidFromHl7(bool validatePatient = true, std::string *errorMessage = nullptr, bool breakOnFirstMissingField = false) const;

    std::string rawJsonWithReplacedParticipants(const std::set<Participant>& newParticipants);
    void serialize(rapidjson::helper::StringWriter& writer) const;
    static Encounter fromJson(const rapidjson::Value& jsonObject, const char *rawJson = nullptr);

    static std::string statusToString(Status status);
    static Status statusFromString(const std::string& str);
#endif // !SWIG
};

} // namespace fhir

#endif // FHIRRESOURCES_H

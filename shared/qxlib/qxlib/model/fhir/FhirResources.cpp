#include "FhirResources.hpp"
#include <ctime>
#include <iomanip> // get_time, put_time
#include <sstream>
#ifdef _WIN32
#include "qxlib/util/strptime.h"
#endif
#include <b64/encode.hpp>
#include <b64/decode.h>
#include "json11/json11.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/model/QxQliqUser.hpp"
#include "qxlib/log/QxLog.hpp"

#define KEY_RESOURCE_TYPE "resourceType"
#define CODING_SYSTEM_QLIQSTOR_HL7 "http://qliqsoft.com/qliqStor/HL7"
#define IDENTIFIER_SYSTEM_QLIQSTOR_HL7 "http://qliqsoft.com/qliqStor/HL7"
#define IDENTIFIER_SYSTEM_HL7_PHYSICIAN_ID "HL7-physician-id"
#define IDENTIFIER_SYSTEM_PV1_ID "http://qliqsoft.com/fhir/pv1-id"
// Encounter
#define IDENTIFIER_SYSTEM_VISIT_NUMBER "http://qliqsoft.com/fhir/visit-number"
#define IDENTIFIER_SYSTEM_ALTERNATE_VISIT_ID "http://qliqsoft.com/fhir/alternate-visit-id"
#define IDENTIFIER_SYSTEM_PREADMIT_NUMBER "http://qliqsoft.com/fhir/preadmit-number"
// Patient
#define IDENTIFIER_SYSTEM_ALTERNATE_PATIENT_ID "http://qliqsoft.com/fhir/alternate-patient-id"

#define CHECK_FIELD(FIELD, MSG) \
    if (FIELD.empty()) { \
        ret = false; \
        if (errorMessage) { \
            errorMessage->append(MSG); \
            errorMessage->append(", "); \
        } \
        if (breakOnFirstMissingField) { \
            goto fix_message_and_return; \
        } \
    }

using namespace rapidjson::helper;

namespace {

void insertNotEmpty(json11::Json::object& obj, const char *name, const std::string& value)
{
    if (!value.empty()) {
        obj[name] = value;
    }
}

void appendNotEmpty(json11::Json::array& arr, const std::string& value)
{
    if (!value.empty()) {
        arr.push_back(value);
    }
}

/// Returns json['identifier'][N]['value'] if json['identifier'][N]['system'] == 'systemValue'
std::string optIdentifierValueOfSystem(const rapidjson::Value &json, const char *systemValue)
{
    return optStringInObjectArrayWhereSelector(json, "value", "identifier", "system", systemValue);
}

} // anonymous namespace

namespace fhir {

Patient::Patient() :
    id(0),
    deceased(false),
    gender(Gender::Unknown)
{
}

bool Patient::isEmpty() const
{
    return (id == 0) && uuid.empty() && hl7Id.empty();
}

std::string Patient::displayName() const
{
    std::string ret = fullName();

    bool hasAge = false;
    int years = age();
    if (years > 0) {
        hasAge = true;
        if (!ret.empty()) {
            ret.push_back(' ');
        }
        ret.append(std::to_string(years));
    }

    if (gender != Gender::Unknown) {
        if (!ret.empty() && !hasAge) {
            ret.push_back(' ');
        }
        ret.push_back(static_cast<char>(gender));
    }

    return ret;
}

std::string Patient::fullName() const
{
    std::string ret;
    bool useLastFirstOrder = true;

    if (useLastFirstOrder) {
        if (!lastName.empty()) {
            ret = lastName;
        }

        if (!firstName.empty()) {
            if (!ret.empty()) {
                ret.append(", ");
            }
            ret.append(firstName);
        }

        if (!middleName.empty()) {
            if (!ret.empty()) {
                ret.push_back(' ');
            }
            ret.push_back(middleName[0]);
            ret.push_back('.');
        }
    } else {
        if (!firstName.empty()) {
            ret = firstName;
        }

        if (!middleName.empty()) {
            if (!ret.empty()) {
                ret.push_back(' ');
            }
            ret.push_back(middleName[0]);
            ret.push_back('.');
        }

        if (!lastName.empty()) {
            if (!ret.empty()) {
                ret.push_back(' ');
            }
            ret.append(lastName);
        }
    }
    return ret;
}

int Patient::age() const
{
    int ret = 0;
    if (!dateOfBirth.empty()) {
        struct tm dobTm;
        if (strptime(dateOfBirth.c_str(), "%Y-%m-%d", &dobTm)) {
            std::time_t now = time(nullptr);
            struct tm *nowTm = localtime(&now);
            if (nowTm->tm_mon < dobTm.tm_mon) {
                nowTm->tm_year--;
            } else if ((nowTm->tm_mon == dobTm.tm_mon) && (nowTm->tm_mday < dobTm.tm_mday)) {
                nowTm->tm_year--;
            }
            ret = std::max(0, nowTm->tm_year - dobTm.tm_year);
        }
    }
    return ret;
}

namespace {
#define SYSTEM_FHIR_V2_0203 "http://hl7.org/fhir/v2/0203"

void serializeIdentifier(rapidjson::helper::StringWriter& writer, const std::string& value, const char *code, const char *system = SYSTEM_FHIR_V2_0203)
{
    writer.StartObject();

        if (system && std::strlen(system) > 0) {
            writer.Key("system");
            writer.String(system);
        }
        writer.Key("value");
        writer.String(value);

        if (code && std::strlen(code) > 0) {
            writer.Key("type");
            writer.StartObject();
                writer.Key("coding");
                writer.StartArray();
                    writer.StartObject();
                        writer.Key("system");
                        writer.String(SYSTEM_FHIR_V2_0203);
                        writer.Key("code");
                        writer.String(code);
                    writer.EndObject();
                writer.EndArray();
            writer.EndObject();
        }
    writer.EndObject();
}

} // namespace {

void Patient::serialize(rapidjson::helper::StringWriter& writer, bool dontEndObject) const
{
    writer.StartObject();
    writer.Key(KEY_RESOURCE_TYPE);
    writer.String("Patient");

    if (!uuid.empty()) {
        writer.Key("id");
        writer.String(uuid);
    }
    if (!hl7Id.empty() || !masterPatientIndex.empty() || !medicalRecordNumber.empty() ||
        !socialSecurityNumber.empty() || !driversLicenseNumber.empty() || !patientAccountNumber.empty()) {

        writer.Key("identifier");
        writer.StartArray();

        if (!hl7Id.empty()) {
            serializeIdentifier(writer, hl7Id, "PI", IDENTIFIER_SYSTEM_QLIQSTOR_HL7);
        }

        if (!masterPatientIndex.empty()) {
            serializeIdentifier(writer, masterPatientIndex, "PT"); // External ID (EMPI)
        }

        if (!medicalRecordNumber.empty()) {
            serializeIdentifier(writer, medicalRecordNumber, "MR");   // Medical Record Number (MRN)
        }

        if (!socialSecurityNumber.empty()) {
            serializeIdentifier(writer, socialSecurityNumber, "SS");
        }

        if (!driversLicenseNumber.empty()) {
            serializeIdentifier(writer, driversLicenseNumber, "DL");
        }

        if (!patientAccountNumber.empty()) {
            serializeIdentifier(writer, patientAccountNumber, "AN");
        }

        writer.EndArray();
    }

    if (!firstName.empty() || !middleName.empty() || !lastName.empty()) {
        writer.Key("name");
        writer.StartArray();
            writer.StartObject();
                if (!firstName.empty() || !middleName.empty()) {
                    writer.Key("given");
                    writer.StartArray();
                        if (!firstName.empty()) {
                            writer.String(firstName);
                        }
                        if (!middleName.empty()) {
                            writer.String(middleName);
                        }
                    writer.EndArray();
                }
                if (!lastName.empty()) {
                    writer.Key("family");
                    writer.StartArray();
                        writer.String(lastName);
                    writer.EndArray();
                }
            writer.EndObject();
        writer.EndArray();
    }

    if (!dateOfBirth.empty()) {
        writer.Key("birthDate");
        writer.String(dateOfBirth);
    }
    if (!dateOfDeath.empty()) {
        writer.Key("deceasedDateTime");
        writer.String(dateOfDeath);
    }
    if (deceased || !dateOfDeath.empty()) {
        writer.Key("deceased");
        writer.Bool(true);
    }

    if (gender != Gender::Unknown) {
        writer.Key("gender");
        writer.String(genderToString(gender));
    }

    if (!race.empty()) {
        writer.Key("race");
        writer.String(race);
    }

    if (!phoneHome.empty() || !phoneWork.empty() || !email.empty()) {
        writer.Key("telecom");
        writer.StartArray();
        if (!phoneHome.empty()) {
            writer.StartObject();
                writer.Key("system");
                writer.String("phone");
                writer.Key("use");
                writer.String("home");
                writer.Key("value");
                writer.String(phoneHome);
            writer.EndObject();
        }
        if (!phoneWork.empty()) {
            writer.StartObject();
                writer.Key("system");
                writer.String("phone");
                writer.Key("use");
                writer.String("work");
                writer.Key("value");
                writer.String(phoneWork);
            writer.EndObject();
        }
        if (!email.empty()) {
            writer.StartObject();
                writer.Key("system");
                writer.String("email");
                writer.Key("value");
                writer.String(email);
            writer.EndObject();
        }
        writer.EndArray();
    }

    if (!photo.isEmpty()) {
        writer.Key("photo");
        photo.serialize(writer);
    }

    if (!dontEndObject) {
        writer.EndObject();
    }
}

std::string Patient::demographicsText() const
{
    std::string ret;
    int _age = age();
    if (_age > 0) {
        ret = std::to_string(_age);
    }
    
    if (gender != fhir::Gender::Unknown) {
        ret.push_back(static_cast<char>(gender));
    }
    
#if 0
    if (!dateOfBirth.empty()) {
        if (!ret.empty()) {
            ret += ", ";
        }
        ret += "DOB ";
        
        {
            // Convert string to tm and then format as a different string
            std::tm t = {};
            std::istringstream is(dateOfBirth);
#if defined(__GNUC__) && (__GNUC__ < 5)
            // GCC prior to 5.0 does not implement get_time, put_time yet
            ret += dateOfBirth;
#else
            is >> std::get_time(&t, "%Y-%m-%d");
            if (is.fail()) {
                ret += dateOfBirth;
            } else {
                std::ostringstream os;
                os << std::put_time(&t, "%d %b %Y");
                ret += os.str();
            }
#endif
        }
    }
#endif
    return ret;
}

std::string Patient::toLogString() const
{
    std::string ret;
    const auto& fn = fullName();
    if (!fn.empty()) {
        ret.append(fn);
    }
    if (!uuid.empty()) {
        if (!ret.empty()) {
            ret.push_back(' ');
        }
        ret.push_back('(');
        ret = "uuid: ";
        ret.append(uuid);
        ret.push_back(')');
    }
    return ret;
}

bool Patient::isValidFromHl7(std::string *errorMessage, bool breakOnFirstMissingField) const
{
    bool ret = true;

    CHECK_FIELD(firstName, "First Name is required");
    CHECK_FIELD(lastName, "Last Name is required");
    CHECK_FIELD(dateOfBirth, "Date of Birth is required");
    CHECK_FIELD(hl7Id, "HL7 Id is required");

    if (medicalRecordNumber.empty() && socialSecurityNumber.empty() && driversLicenseNumber.empty()) {
        ret = false;
        if (errorMessage) {
            errorMessage->append("At least one of: Medical Record Number, Social Security Number, Driver's License Number is required");
            errorMessage->append(", ");
        }
        if (breakOnFirstMissingField) {
            goto fix_message_and_return;
        }
    }

fix_message_and_return:
    if (errorMessage) {
        auto size = errorMessage->size();
        if (size > 2 && (*errorMessage)[size-2] == ',' && (*errorMessage)[size-1] == ' ') {
            errorMessage->erase(size - 2);
        }
    }
    return ret;
}

Patient Patient::fromJson(const rapidjson::Value &json)
{
    try {
        Patient p;
        if (getOptString(json, KEY_RESOURCE_TYPE) != "Patient") {
            return p;
        }

        p.uuid = getOptString(json, "id");
        p.hl7Id = optStringInObjectArrayWhereSelector(json, "value", "identifier", "system",
                                                      IDENTIFIER_SYSTEM_QLIQSTOR_HL7);
        //p.hl7Id = optStringInObjectArrayWhereSelectors(json, "value", "identifier", Selectors{{"system", IDENTIFIER_SYSTEM_QLIQSTOR_HL7}, {"type/coding/0/code", "PI"}});
        p.alternatePatientId = optIdentifierValueOfSystem(json, IDENTIFIER_SYSTEM_ALTERNATE_PATIENT_ID);

        p.firstName = getOptString(json, "name/0/given/0");
        p.middleName = getOptString(json, "name/0/given/1");
        p.lastName = getOptString(json, "name/0/family/0");
        p.dateOfBirth = getOptString(json, "birthDate");
        p.dateOfDeath = getOptString(json, "deceasedDateTime");
        p.deceased = (!getOptString(json, "deceasedDateTime").empty() ||
                      !getOptString(json, "deceased").empty());
        p.gender = genderFromString(getOptString(json, "gender"));
        p.race = getOptString(json, "race");

        p.phoneHome = optStringInObjectArrayWhereSelectors(json, "value", "telecom",
                                                           Selectors{{"system", "phone"},
                                                                     {"use",    "home"}});
        p.phoneWork = optStringInObjectArrayWhereSelectors(json, "value", "telecom",
                                                           Selectors{{"system", "phone"},
                                                                     {"use",    "work"}});
        if (p.phoneHome.empty() && p.phoneWork.empty()) {
            // if cannot find phone with expected 'use' field then try to find any phone
            p.phoneHome = optStringInObjectArrayWhereSelector(json, "value", "telecom", "system",
                                                              "phone");
        }
        p.email = optStringInObjectArrayWhereSelector(json, "value", "telecom", "system", "email");

        p.masterPatientIndex = optStringInObjectArrayWhereSelector(json, "value", "identifier",
                                                                   "type/coding/0/code", "PT");
        p.medicalRecordNumber = optStringInObjectArrayWhereSelector(json, "value", "identifier",
                                                                    "type/coding/0/code", "MR");
        p.patientAccountNumber = optStringInObjectArrayWhereSelector(json, "value", "identifier",
                                                                     "type/coding/0/code", "AN");
        p.socialSecurityNumber = optStringInObjectArrayWhereSelector(json, "value", "identifier",
                                                                     "type/coding/0/code", "SS");
        p.driversLicenseNumber = optStringInObjectArrayWhereSelector(json, "value", "identifier",
                                                                     "type/coding/0/code", "DL");

        std::string aggregatedAddress;
        appendNotEmpty(&aggregatedAddress, getOptString(json, "address/0/line/0"), "\n");
        appendNotEmpty(&aggregatedAddress, getOptString(json, "address/0/city"), "\n");
        appendNotEmpty(&aggregatedAddress, getOptString(json, "address/0/state"), "\n");
        appendNotEmpty(&aggregatedAddress, getOptString(json, "address/0/postalCode"), "\n");
        appendNotEmpty(&aggregatedAddress, getOptString(json, "address/0/country"), "\n");
        p.address = aggregatedAddress;

        // TODO:
        // p.maritalStatus

        // TODO: implement full support for fhir Attachment
        p.photo.data = getOptString(json, "photo/data");
        if (!p.photo.data.empty()) {
            p.photo.data = base64::decode(p.photo.data);
        }

        return p;
    } catch (...) {
        QXLOG_ERROR("Unknown C++ exception in Patient::fromJson()", nullptr);
        return Patient();
    }
}

Gender Patient::genderFromString(const std::string& str)
{
    char c = 'U';
    if (!str.empty()) {
        c = std::toupper(str[0]);
    }

    switch (c) {
    case 'M':
        return Gender::Male;
    case 'F':
        return Gender::Female;
    case 'O':
        return Gender::Other;
    default:
        return Gender::Unknown;
    }
}

std::string Patient::genderToString(Gender gender)
{
    if (gender == Gender::Male) {
        return "male";
    } else if (gender == Gender::Female) {
        return "female";
    } if (gender == Gender::Other) {
        return "other";
    } else {
        return "unknown";
    }
}

void Patient::test()
{
    //const char *path = "patient.json";
    const char *path = "encounter-included.json";
    rapidjson::Document *document(fileToDocument(path));
    if (!document) {
        throw std::runtime_error(std::string("Cannot open file: ") + path);
    }

    //Patient p = Patient::fromJson(*document);
    Encounter e = Encounter::fromJson(*document);

    delete document;
}

Practitioner::Practitioner() :
    id(0)
{
}

Practitioner::Practitioner(const qx::QliqUser &user)
{
    uuid = user.qliqId;
    qliqId = user.qliqId;
    firstName = user.firstName;
    middleName = user.middleName;
    lastName = user.lastName;
}

bool Practitioner::isEmpty() const
{
    return uuid.empty() && hl7Id.empty() && qliqId.empty();
}

json11::Json toJson(const Practitioner& p)
{
    using namespace json11;
    auto ret = Json::object {
        {KEY_RESOURCE_TYPE, "Practitioner" }
    };

    insertNotEmpty(ret, "id", p.uuid);
    insertNotEmpty(ret, "qliqId", p.qliqId);

    if (!p.firstName.empty() || !p.middleName.empty() || !p.lastName.empty()) {
        auto obj = Json::object();
        if (!p.firstName.empty() || !p.middleName.empty()) {
            auto array = Json::array();
            appendNotEmpty(array, p.firstName);
            appendNotEmpty(array, p.middleName);
            obj["given"] = array;
        }
        if (!p.lastName.empty()) {
            obj["family"] = Json::array { p.lastName };
        }
        ret["name"] = obj;
    }
    return ret;
}

void Practitioner::serialize(StringWriter &writer) const
{
    writer.StartObject();
    writer.Key(KEY_RESOURCE_TYPE);
    writer.String("Practitioner");

    if (!uuid.empty()) {
        writer.Key("id");
        writer.String(uuid);
    }

    if (!firstName.empty() || !middleName.empty() || !lastName.empty()) {
        writer.Key("name");
        writer.StartArray();
            writer.StartObject();
                if (!firstName.empty() || !middleName.empty()) {
                    writer.Key("given");
                    writer.StartArray();
                        if (!firstName.empty()) {
                            writer.String(firstName);
                        }
                        if (!middleName.empty()) {
                            writer.String(middleName);
                        }
                    writer.EndArray();
                }
                if (!lastName.empty()) {
                    writer.Key("family");
                    writer.StartArray();
                        writer.String(lastName);
                    writer.EndArray();
                }
            writer.EndObject();
        writer.EndArray();
    }

    if (!qliqId.empty()) {
        writer.Key("qliqId");
        writer.String(qliqId);
    }

    writer.EndObject();
}

bool Practitioner::operator<(const Practitioner &other) const
{
    return qliqId < other.qliqId;
}

bool Practitioner::operator==(const Practitioner &other) const
{
    return qliqId == other.qliqId;
}

Practitioner Practitioner::fromJson(const rapidjson::Value &json)
{
    try {
        Practitioner p;
        if (getOptString(json, KEY_RESOURCE_TYPE) != "Practitioner") {
            return p;
        }

        p.uuid = getOptString(json, "id");
        p.qliqId = getOptString(json, "qliqId");
        p.firstName = getOptString(json, "name/0/given/0");
        p.middleName = getOptString(json, "name/0/given/1");
        p.lastName = getOptString(json, "name/0/family/0");
        p.hl7Id = optStringInObjectArrayWhereSelector(json, "value", "identifier", "system",
                                                      IDENTIFIER_SYSTEM_HL7_PHYSICIAN_ID);
        return p;
    } catch (...) {
        QXLOG_ERROR("Unknown C++ exception in Practitioner::fromJson()", nullptr);
        return Practitioner();
    }
}

Encounter::Encounter() :
    id(0),
    status(0)
{
}

bool Encounter::isEmpty() const
{
    return (id == 0) && uuid.empty() && visitNumber.empty() && alternateVisitId.empty() && preadmitNumber.empty();
}

void Encounter::serialize(StringWriter &writer) const
{
    writer.StartObject();
        writer.Key("resourceType");
        writer.String("Encounter");

        writer.Key("contained");
        writer.StartArray();
            patient.serialize(writer);

            if (!location.isEmpty()) {
                location.serializeContained(writer);
            }

            for (const auto& p: participants) {
                p.serializeContained(writer);
            }
        writer.EndArray();

        if (!visitNumber.empty() || !alternateVisitId.empty() || !preadmitNumber.empty()) {
            writer.Key("identifier");
            writer.StartArray();
                if (!visitNumber.empty()) {
                    serializeIdentifier(writer, visitNumber, "VN", IDENTIFIER_SYSTEM_VISIT_NUMBER);
                }
                if (!alternateVisitId.empty()) {
                    serializeIdentifier(writer, alternateVisitId, "", IDENTIFIER_SYSTEM_ALTERNATE_VISIT_ID);
                }
                if (!preadmitNumber.empty()) {
                    serializeIdentifier(writer, preadmitNumber, "", IDENTIFIER_SYSTEM_PREADMIT_NUMBER);
                }

            writer.EndArray();
        }

        writer.Key("patient");
        writer.StartObject();
            writer.Key("reference");
            writer.String("#" + patient.uuid);
        writer.EndObject();

        // TODO:
        // status

        if (!periodStart.empty() || !periodEnd.empty()) {
            writer.Key("period");
            writer.StartObject();
                if (!periodStart.empty()) {
                    writer.Key("start");
                    writer.String(periodStart);
                }
                if (!periodEnd.empty()) {
                    writer.Key("end");
                    writer.String(periodEnd);
                }
            writer.EndObject();
        }

        if (!location.isEmpty()) {
            writer.Key("location");
            location.serialize(writer);
        }

        if (!participants.empty()) {
            writer.Key("participant");
            writer.StartArray();

            for (const auto& p: participants) {
                p.serialize(writer);
            }

            writer.EndArray();
        }

        writer.EndObject();
}

std::string Encounter::summaryTextForRecentsList() const
{
    std::string ret = patient.demographicsText();

    if (!location.floor.empty()) {
        if (!ret.empty()) {
            ret += ", ";
        }

        ret += "Floor ";
        ret += location.floor;
    }

    if (!location.room.empty()) {
        if (!ret.empty()) {
            ret += ", ";
        }

        ret += "Room ";
        ret += location.room;
    }

    return ret;
}

bool Encounter::isValidFromHl7(bool validatePatient, std::string *errorMessage, bool breakOnFirstMissingField) const
{
    bool ret = true;

    if (validatePatient) {
        if (!patient.isValidFromHl7(errorMessage, breakOnFirstMissingField)) {
            ret = false;
            if (breakOnFirstMissingField) {
                goto fix_message_and_return;
            }
        }
    }

    if (visitNumber.empty() && alternateVisitId.empty() && preadmitNumber.empty()) {
        ret = false;
        if (errorMessage) {
            errorMessage->append("At least one of: Visit Number, Alternate Visit Id, Preadmit Number is required");
            errorMessage->append(", ");
        }
        if (breakOnFirstMissingField) {
            goto fix_message_and_return;
        }
    }

fix_message_and_return:
    if (errorMessage) {
        auto size = errorMessage->size();
        if (size > 2 && (*errorMessage)[size-2] == ',' && (*errorMessage)[size-1] == ' ') {
            errorMessage->erase(size - 2);
        }
    }
    return ret;
}

json11::Json toJson(const Participant& p)
{
    using namespace json11;

    if (p.doctor.isEmpty()) {
        return Json(); // null
    }

    auto ret = Json::object {
        {"individual", Json::object { {"reference", "#" + p.doctor.uuid} } }
    };

    std::string typeText = p.typeText;
    if (typeText.empty() && p.type != Participant::Unknown) {
        typeText = Participant::typeToString(p.type);
    }
    if (p.type != Participant::Unknown || !typeText.empty()) {
        auto typeObject = Json::object();
        if (p.type != Participant::Unknown) {
            typeObject["coding"] = Json::array {
                Json::object {
                    {"system", "http://hl7.org/fhir/v3/ParticipationType"},
                    {"code", Participant::typeToString(p.type)}
                }
            };
        }
        if (!typeText.empty()) {
            typeObject["text"] = typeText;
        }
        ret["type"] = typeObject;
    }

    return ret;
}

std::string Encounter::rawJsonWithReplacedParticipants(const std::set<Participant>& newParticipants)
{
    std::string errorMsg;
    using namespace json11;
    Json json = Json::parse(rawJson, errorMsg);
    if (!json.is_null()) {
        auto obj = json.object_items();

        auto contained = obj["contained"].array_items();
        for (int i = 0; i < contained.size(); ) {
            if (contained[i][KEY_RESOURCE_TYPE] == "Practitioner") {
                contained.erase(contained.begin() + i);
            } else {
                ++i;
            }
        }

        auto participants = Json::array();
        for (const auto& p: newParticipants) {
            participants.push_back(toJson(p));
            contained.push_back(toJson(p.doctor));
        }

        auto it = obj.find("controller");
        if (it != obj.end()) {
            obj.erase(it);
        }

        // Due to bug webserve sends the complete json again inside 'encounter' key
        it = obj.find("encounter");
        if (it != obj.end()) {
            obj.erase(it);
        }

        obj["contained"] = contained;
        obj["participant"] = participants;

        return Json(obj).dump();
    } else {
        return "";
    }
}

Encounter Encounter::fromJson(const rapidjson::Value &json, const char *rawJson)
{
    try {
        Encounter e;
        if (getOptString(json, KEY_RESOURCE_TYPE) != "Encounter") {
            return e;
        }
        e.uuid = getOptString(json, "id");
        //e.hl7Id = optStringInObjectArrayWhereSelector(json, "value", "identifier", "system", IDENTIFIER_SYSTEM_QLIQSTOR_HL7);
        e.alternateVisitId = optIdentifierValueOfSystem(json, IDENTIFIER_SYSTEM_ALTERNATE_VISIT_ID);
        e.preadmitNumber = optIdentifierValueOfSystem(json, IDENTIFIER_SYSTEM_PREADMIT_NUMBER);
        e.visitNumber = optIdentifierValueOfSystem(json, IDENTIFIER_SYSTEM_VISIT_NUMBER);

        e.periodStart = getOptString(json, "period/start");
        e.periodEnd = getOptString(json, "period/end");
        e.status = Encounter::statusFromString(getOptString(json, "status"));

        std::string reference = getOptString(json, "patient/reference");
        if (!reference.empty()) {
            if (reference[0] == '#') {
                reference.erase(reference.begin());
            }

            const rapidjson::Value *object = findObjectInObjectArrayWhereSelector(json, "contained", "id", reference.c_str());
            if (object) {
                e.patient = Patient::fromJson(*object);
            } else {
                e.patient.uuid = reference;
            }
        }

        // Search 'participant' array for objects that are of all supported types
        for (int i = 0; i < Participant::TypeCount; ++i) {
            Participant::Type type = static_cast<Participant::Type>(i);
            const std::string typeName = Participant::typeToString(type);

            reference = optStringInObjectArrayWhereSelector(json, "individual/reference", "participant", "type/coding/0/code", typeName.c_str());
            if (!reference.empty()) {
                Participant p;
                p.type = type;

                if (reference[0] == '#') {
                    reference.erase(reference.begin());
                }

                const rapidjson::Value *object = findObjectInObjectArrayWhereSelector(json, "contained", "id", reference.c_str());
                if (object) {
                    p.doctor = Practitioner::fromJson(*object);
                } else {
                    p.doctor.uuid = reference;
                }

                e.participants.insert(p);
            }
        }

        e.location = LocationHl7::fromJson(json);

        if (rawJson) {
            e.rawJson = rawJson;
        } else {
            // TODO: get string from 'json' object
        }

        return e;
    } catch (...) {
        QXLOG_ERROR("Unknown C++ exception in Encounter::fromJson()", nullptr);
        return Encounter();
    }
}

std::string Encounter::statusToString(Encounter::Status status)
{
    // If you change this, change also qS Manager Hl7PatientViewerWidget.cpp encounterStatusToString()
    switch (status) {
    case PlannedStatus:
        return "planned";
    case ArrivedStatus:
        return "arrived";
    case InProgressStatus:
        return "in-progress";
    case OnLeaveStatus:
        return "onleave";
    case FinishedStatus:
        return "finished";
    case CancelledStatus:
        return "cancelled";
    case UnknownStatus:
    default:
        return "";
    }
}

Encounter::Status Encounter::statusFromString(const std::string &str)
{
    Status ret = UnknownStatus;
    if (str == "planned") {
        ret = PlannedStatus;
    } else if (str == "arrived") {
        ret = ArrivedStatus;
    } else if (str == "in-progress") {
        ret = InProgressStatus;
    } else if (str == "onleave") {
        ret = OnLeaveStatus;
    } else if (str == "finished") {
        ret = FinishedStatus;
    } else if (str == "cancelled") {
        ret = CancelledStatus;
    }
    return ret;
}

const std::string Participant::typeNames[Participant::TypeCount] = {
    "UNKNOWN", "ADM", "ATND", "CON", "REF"
};

Participant::Participant() :
    type(Unknown)
{
}

bool Participant::isEmpty() const
{
    return doctor.isEmpty();
}

void Participant::setTypeFromText(const std::string &text)
{
    type = Unknown;
    typeText = text;

    bool hasPhysician = StringUtils::containsCaseInsensitive(text, "physician") || StringUtils::containsCaseInsensitive(text, "doctor");
    if (hasPhysician) {
        if (StringUtils::findCaseInsensitive(text, "admitting") == 0) {
            type = AdmittingDoctor;
        } else if (StringUtils::findCaseInsensitive(text, "attending") == 0) {
            type = AttendingDoctor;
        } else if (StringUtils::findCaseInsensitive(text, "consulting") == 0) {
            type = ConsultingDoctor;
        } else if (StringUtils::findCaseInsensitive(text, "referring") == 0) {
            type = ReferringDoctor;
        }
    }
}

void Participant::serializeContained(StringWriter &writer) const
{
    if (!doctor.isEmpty()) {
        doctor.serialize(writer);
    }
}

void Participant::serialize(StringWriter &writer) const
{
    if (!doctor.isEmpty()) {
        writer.StartObject();
            writer.Key("individual");
            writer.StartObject();
                writer.Key("reference");
                writer.String("#" + doctor.uuid);
            writer.EndObject();

            std::string typeText = this->typeText;
            if (typeText.empty()) {
                typeText = typeToString(type);
            }
            if (type != Unknown || !typeText.empty()) {
                writer.Key("type");
                writer.StartObject();
                    if (type != Unknown) {
                        writer.Key("coding");
                        writer.StartArray();
                            writer.StartObject();
                                writer.Key("system");
                                writer.String("http://hl7.org/fhir/v3/ParticipationType");
                                writer.Key("code");
                                writer.String(typeToString(type));
                            writer.EndObject();
                        writer.EndArray();
                    }
                    if (!typeText.empty()) {
                        writer.Key("text");
                        writer.String(typeText);
                    }
                writer.EndObject();
            }
        writer.EndObject();
    }
}

bool Participant::operator<(const Participant &other) const
{
    return doctor < other.doctor;
}

bool Participant::operator==(const Participant &other) const
{
    return doctor == other.doctor && typeText == other.typeText;
}

std::string Participant::typeToString(Participant::Type type)
{
    return typeNames[type];
}

Participant::Type Participant::typeFromString(const std::string &str)
{
    for (int i = 0; i < TypeCount; ++i) {
        if (str == typeNames[i]) {
            return static_cast<Participant::Type>(i);
        }
    }
    return Unknown;
}

bool LocationHl7::isEmpty() const
{
    return pointOfCare.empty() && room.empty() && bed.empty() && facility.empty() && building.empty() && floor.empty();
}

/*
    std::string pointOfCare;
    std::string room;
    std::string bed;
    std::string facility;
    std::string building;
    std::string floor;
*/

std::string LocationHl7::singleLineString() const
{
    std::string ret;
    std::string field;

    appendNotEmpty(&ret, facility, ", ");
    appendNotEmpty(&ret, building, ", ");

    field = floor;
    if (isDigits(field)) {
        field.insert(0, "#");
    }
    appendNotEmpty(&ret, field, ", floor ");

    field = room;
    if (isDigits(field)) {
        field.insert(0, "#");
    }
    appendNotEmpty(&ret, field, ", room ");

    field = bed;
    if (isDigits(field)) {
        field.insert(0, "#");
    }
    appendNotEmpty(&ret, field, ", bed ");

    return ret;
}

namespace {

void serializeContainedLocation(rapidjson::helper::StringWriter& writer, const char *id, const std::string& name)
{
    if (!name.empty()) {
        writer.StartObject();
            writer.Key("resourceType");
            writer.String("Location");
            writer.Key("id");
            writer.String(id);
            writer.Key("name");
            writer.String(name);
        writer.EndObject();
    }
}

void serializeLocationReference(rapidjson::helper::StringWriter& writer, const std::string& reference)
{
    if  (!reference.empty()) {
        writer.StartObject();
            writer.Key("location");
            writer.StartObject();
                writer.Key("reference");
                writer.String(reference);
            writer.EndObject();
        writer.EndObject();
    }
}

} // namespace {

void LocationHl7::serializeContained(StringWriter &writer) const
{
    if (!isEmpty()) {
        serializeContainedLocation(writer, "location-point-of-care", pointOfCare);
        serializeContainedLocation(writer, "location-room", room);
        serializeContainedLocation(writer, "location-bed", bed);
        serializeContainedLocation(writer, "location-facility", facility);
        serializeContainedLocation(writer, "location-building",  building);
        serializeContainedLocation(writer, "location-floor", floor);
    }
}

void LocationHl7::serialize(StringWriter &writer) const
{
    if (isEmpty()) {
        writer.Null();
    } else {
        writer.StartArray();
            serializeLocationReference(writer, "#location-point-of-care");
            serializeLocationReference(writer, "#location-room");
            serializeLocationReference(writer, "#location-bed");
            serializeLocationReference(writer, "#location-facility");
            serializeLocationReference(writer, "#location-building");
            serializeLocationReference(writer, "#location-floor");
        writer.EndArray();
    }
}

LocationHl7 LocationHl7::fromJson(const rapidjson::Value &json)
{
    try {
        LocationHl7 location;
        location.pointOfCare =  optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-point-of-care");
        location.room =         optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-room");
        location.bed =          optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-bed");
        location.facility =     optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-facility");
        location.building =     optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-building");
        location.floor =        optStringInObjectArrayWhereSelector(json, "name", "contained", "id", "location-floor");
        return location;
    } catch (...) {
        QXLOG_ERROR("Unknown C++ exception in LocationHl7::fromJson()", nullptr);
        return LocationHl7();
    }
}

Attachment::Attachment() :
    size(0)
{
}

bool Attachment::isEmpty() const
{
    return data.empty() && url.empty();
}

void Attachment::serialize(StringWriter &writer) const
{
    writer.StartObject();
        writeNotEmpty(writer, "contentType", contentType);
        if (!data.empty()) {
            std::string b64Data = base64::encode(data);
            writeNotEmpty(writer, "data", b64Data);
        }
        writeNotEmpty(writer, "url", url);
        writeNotZero (writer, "size", size);
        writeNotEmpty(writer, "hash", hash);
    writer.EndObject();
}

Attachment Attachment::fromJson(const rapidjson::Value &json)
{
    try {
        Attachment a;
        a.contentType = getOptString(json, "contentType");
        a.data = getOptString(json, "data");
        a.url = getOptString(json, "url");
        // TODO:
        //a.size = getOptString(json, "size");
        a.hash = getOptString(json, "hash");

        if (!a.data.empty()) {
            a.data = base64::decode(a.data);
        }
        return a;
    } catch (...) {
        QXLOG_ERROR("Unknown C++ exception in Attachment::fromJson()", nullptr);
        return Attachment();
    }
}

} // namespace fhir

#include "QxSearchPatientsWebService.hpp"
#include <memory>
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/util/QxCompression.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/util/RapidJsonHelper.hpp"
#ifdef QXL_HAS_QT
#ifndef QT_NO_DEBUG
#include <QFile>
#endif
#endif

namespace qx {
namespace web {

SearchPatientsWebService::SearchPatientsWebService() :
    BaseWebService(nullptr),
    m_crypto(qx::Crypto::instance())
{
}

SearchPatientsWebService::SearchPatientsWebService(qx::Crypto *crypto, WebClient *webClient) :
    BaseWebService(webClient),
    m_crypto(crypto)
{
}

void SearchPatientsWebService::call(const SearchPatientsWebService::Query &query, int page, int perPage, ResultFunction resultCallback, WebClient::IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json::object searchBy;
    if (!query.lastName.empty()) {
        searchBy["last_name"] = query.lastName;
    }
    if (!query.firstName.empty()) {
        searchBy["first_name"] = query.firstName;
    }
    if (!query.mrnOrVisitId.empty()) {
        // Current version of client has single fields which is MRN/Visit Number
        // so correct name for this field is "mrn_or_visit_id"
        // but since there is app in appstore already that has only "mrn"
        // and we want it to work the same way, to be compatible we send this
        // as "mrn" too.
        searchBy["mrn"] = query.mrnOrVisitId;
        searchBy["mrn_or_visit_id"] = query.mrnOrVisitId;
    }
    if (!query.dob.empty()) {
        searchBy["dob"] = query.dob;
    }
    if (!query.lastVisit.empty()) {
        searchBy["last_visit"] = query.lastVisit;
    }
    searchBy["my_patients_only"] = query.myPatientsOnly;


    auto json = Json::object {
        {"search_by", searchBy},
        {"search_uuid", query.searchUuid},
        {"per_page", perPage},
        {"page", page},
//#if defined(QXL_HAS_QT) && !defined(QT_NO_DEBUG)
//        {"content_type", "application/json"},
//#else
        {"content_type", "encrypted+zlib"},
//#endif
    };

    if (!query.qliqStorQliq.empty()) {
        json["qliqstor_qliq_id"] = query.qliqStorQliq;
    }

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/search_patients", json, [this,resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, resultCallback);
    }, "", "", isCancelledFun);
}

void SearchPatientsWebService::call(const Query& query, int page, int perPage, ResultCallback *resultCallback)
{
    call(query, page, perPage, [resultCallback](const QliqWebError& error, const Result& result) {
        resultCallback->run(new QliqWebError(error), new Result(result));
    });
}

void SearchPatientsWebService::handleResponse(const qx::web::QliqWebError &error, const json11::Json &json, const SearchPatientsWebService::ResultFunction &resultCallback)
{
    // Local exception to use in this method only
    // The pattern is we throw on error to avoid deep if {} else {} blocks
    struct SearchPatientsLocalException {
        const std::string msg;

        SearchPatientsLocalException(const std::string& msg) :
                msg(msg)
        {}

        const std::string& what() const { return msg; }
    };
    // Helper macro to throw and log we correct line number at the same time
#define THROW_LOCAL_AND_LOG(userMsg) \
    QXLOG_ERROR("%s", userMsg); \
    throw SearchPatientsLocalException(userMsg); \
    return;

    try {
        if (error) {
            QXLOG_ERROR("%s", error.toString().c_str());
            throw error;
        }

        Result r;
        std::string contentType = json["content_type"].string_value();
        std::string content = json["content"].string_value();
        r.searchUuid = json["search_uuid"].string_value();
        r.totalCount = json["total_count"].int_value();
        r.currentPage = json["page"].int_value();
        r.totalPages = json["total_pages"].int_value();
        r.perPage = json["per_page"].int_value();

        const auto& emrSourceJson = json["emr_source"];
        r.emrSource.qliqId = emrSourceJson["qliq_id"].string_value();
        r.emrSource.name = emrSourceJson["name"].string_value();
        r.emrSource.deviceUuid = emrSourceJson["device_uuid"].string_value();
        r.emrSource.publicKey = emrSourceJson["pub_key"].string_value();
        r.emrSource.publicKeyMd5 = emrSourceJson["pk_hash"].string_value();

        json11::Json::array patientJsonArray;

        if (contentType == "application/json") {
            patientJsonArray = json["content"].array_items();
            json["content"].dump(content);
        } else {
            if (StringUtils::contains(contentType, "encrypted")) {
                std::string pkHash = json["pk_hash"].string_value();
                std::string myPkHash = m_crypto->publicKeyMd5();

                if (pkHash != myPkHash) {
                    QXLOG_ERROR("Received pk_hash: '%s' but expected: '%s'", pkHash.c_str(), myPkHash.c_str());
                    THROW_LOCAL_AND_LOG("The received 'pk_hash' doesn't match");
                }

                bool ok;
                content = m_crypto->decryptFromBase64ToString(content, &ok);
                if (!ok) {
                    THROW_LOCAL_AND_LOG("Cannot decrypt 'content'");
                }
            }

            if (StringUtils::contains(contentType, "zlib")) {
                const auto MAX_SIP_MSG_SIZE = (32 * 1024);
                const auto MAX_EXPECTED_COMPRESSION_RATIO = 5;
                const auto bufferSize = MAX_SIP_MSG_SIZE * MAX_EXPECTED_COMPRESSION_RATIO;
                std::unique_ptr<unsigned char[]> buffer(new unsigned char[bufferSize]);
                int decompressedLen = QxZlib::decompress((const unsigned char *)content.c_str(), content.size(), buffer.get(), bufferSize);
                if (decompressedLen < 1) {
                    THROW_LOCAL_AND_LOG("Cannot decompress 'content'");
                }
                content = std::string((const char *)buffer.get(), decompressedLen);
            }

#ifdef QXL_HAS_QT
#ifndef QT_NO_DEBUG
            QFile debugFile("c:\\temp\\search_patients_decrypted_content.json");
            if (debugFile.open(QIODevice::WriteOnly)) {
                debugFile.write(content.c_str(), content.size());
                debugFile.close();
            }
#endif
#endif

            std::string parsingError;
            patientJsonArray = json11::Json::parse(content, parsingError).array_items();
            if (!parsingError.empty()) {
                THROW_LOCAL_AND_LOG("Cannot parse 'content' as JSON");
            }
        }

        // At this point we have the final 'patientJsonArray'

#ifndef FHIR_PATIENT_PARSE_JSON11
        rapidjson::Document patientsArray;
        patientsArray.Parse(content);
        if (!patientsArray.IsArray()) {
            THROW_LOCAL_AND_LOG("Cannot parse 'content' as JSON array");
        }

        if (!patientsArray.Empty()) {
            r.patients.reserve(patientsArray.Size());

            for (auto itr = patientsArray.Begin(); itr != patientsArray.End(); ++itr) {
                const fhir::Patient p = fhir::Patient::fromJson(itr->GetObject());
                r.patients.push_back(p);
            }
        }
#else
        if (!patientJsonArray.empty()) {
            r.patients.reserve(patientJsonArray.size());

            for (const auto& jsonPatient: patientJsonArray) {
                const fhir::Patient p = fhir::Patient::fromJson(jsonPatient);
                r.patients.push_back(p);
            }
        }
#endif

        resultCallback(QliqWebError(), r);

    } catch (const qx::web::QliqWebError& e) {
        resultCallback(e, Result());
    } catch (const SearchPatientsLocalException& ex) {
        resultCallback(QliqWebError::applicationError(ex.what()), Result());
    } catch (...) {
        resultCallback(QliqWebError::applicationError("Unexpected C++ exception (...)"), Result());
    }
}

bool SearchPatientsWebService::Query::isEmpty() const
{
    return lastName.empty() && firstName.empty() && dob.empty() && mrnOrVisitId.empty() && lastVisit.empty();
}

void SearchPatientsWebService::Query::clear()
{
    searchUuid.clear();
    lastName.clear();
    firstName.clear();
    dob.clear();
    mrnOrVisitId.clear();
    lastVisit.clear();
    myPatientsOnly = false;

}

bool SearchPatientsWebService::Query::operator==(const SearchPatientsWebService::Query &other) const
{
    return lastName == other.lastName && firstName == other.firstName &&
           dob == other.dob && mrnOrVisitId == other.mrnOrVisitId && lastVisit == other.lastVisit &&
            myPatientsOnly == other.myPatientsOnly;
}

bool SearchPatientsWebService::Query::operator!=(const SearchPatientsWebService::Query &other) const
{
    return !(*this == other);
}

#ifdef ANDROID_DEBUG_SWIG_OBJECT_LIFETIME

SearchPatientsWebService::Result::Result()
{
    QXLOG_ERROR("Result::Result(): 0x%x", this);
}

SearchPatientsWebService::Result::Result(const Result& r)
{
    QXLOG_ERROR("Result::Result(const Result&): 0x%x", this);
    this->searchUuid = r.searchUuid;
    this->totalCount = r.totalCount;
    this->perPage = r.perPage;
    this->currentPage = r.currentPage;
    this->totalPages = r.totalPages;
    this->patients = r.patients;
}

SearchPatientsWebService::Result::~Result()
{
    QXLOG_ERROR("Result::~Result(): 0x%x", this);
}

SearchPatientsWebService::Result& SearchPatientsWebService::Result::operator=(const Result& r)
{
    QXLOG_ERROR("Result::operator=(): 0x%x", this);

    this->searchUuid = r.searchUuid;
    this->totalCount = r.totalCount;
    this->perPage = r.perPage;
    this->currentPage = r.currentPage;
    this->totalPages = r.totalPages;
    this->patients = r.patients;
    return *this;
}

#endif // ANDROID_DEBUG_SWIG_OBJECT_LIFETIME

} // web
} // qx

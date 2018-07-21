#ifndef QXSEARCHPATIENTSWEBSERVICE_HPP
#define QXSEARCHPATIENTSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/fhir/FhirResources.hpp"

namespace qx {

class Crypto;

namespace web {

class SearchPatientsWebService : public BaseWebService
{
public:
    struct Query {
        std::string qliqStorQliq; // optional
        std::string searchUuid;
        std::string lastName;
        std::string firstName;
        std::string dob;
        std::string mrnOrVisitId;
        std::string lastVisit;
        bool myPatientsOnly;

        bool isEmpty() const;
        void clear();

#ifndef SWIG
        bool operator==(const Query &) const;
        bool operator!=(const Query &) const;
#endif // !SWIG
    };

    struct EmrSource {
        std::string qliqId;
        std::string name;
        std::string deviceUuid;
        std::string publicKey;
        std::string publicKeyMd5;
    };

    struct Result {
        std::string searchUuid;
        int totalCount;
        // TODO: refactor to use just: skip and count instead of pages
        int perPage;
        int currentPage;
        int totalPages;
        std::vector<fhir::Patient> patients;
        EmrSource emrSource;

#ifdef ANDROID_DEBUG_SWIG_OBJECT_LIFETIME
        Result();
        Result(const Result& r);
        ~Result();
        Result& operator=(const Result&);
#endif
    };

    // Constructor for Java uses default crypto and webClient
    SearchPatientsWebService();
#ifndef SWIG
    SearchPatientsWebService(qx::Crypto *crypto, WebClient *webClient = nullptr);

    typedef std::function<void(const QliqWebError& error, const Result& result)> ResultFunction;
    void call(const Query& query, int page, int perPage, ResultFunction resultCallback, WebClient::IsCancelledFunction isCancelledFun = WebClient::IsCancelledFunction());
#endif

    class ResultCallback {
    public:
            virtual ~ResultCallback() {}
            virtual void run(QliqWebError *error, Result *result) = 0;
    };
    void call(const Query& query, int page, int perPage, ResultCallback *resultCallback);

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultFunction& resultCallback);

    qx::Crypto *m_crypto;
};

} // web
} // qx

#endif // QXSEARCHPATIENTSWEBSERVICE_HPP

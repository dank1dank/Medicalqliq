#ifndef QXUPLOADTOEMRWEBSERVICE_HPP
#define QXUPLOADTOEMRWEBSERVICE_HPP
#include "qxlib/web/qliqstor/QxUploadToQliqStorWebService.hpp"

namespace fhir {
class Patient;
}
namespace qx {

class Crypto;

namespace web {

class UploadToEmrWebService : public UploadToQliqStorWebService
{
public:
    struct ConversationMessageList {
        std::string conversationUuid;
        std::vector<std::string> messageUuids;
    };

    UploadToEmrWebService(WebClient *webClient = nullptr);

#ifdef SWIG
    struct UploadParams : public UploadToQliqStorWebService::UploadParams {};
#endif // !SWIG

#ifndef SWIG
    // public because needed by qx::UploadToQliqStorTask class
    json11::Json::object targetJson(const UploadParams& uploadParams) override;

    static void setEmrTarget(UploadParams *up, const fhir::Patient& patient);
#endif

protected:
    const char *serverPath() const override;
    const char *uploadTypeString() const override;
    const char *uploadTargetKeyString() const override;
};

} // web
} // qx

#endif // QXUPLOADTOEMRWEBSERVICE_HPP

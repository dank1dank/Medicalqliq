#ifndef QXUPLOADTOFAXWEBSERVICE_HPP
#define QXUPLOADTOFAXWEBSERVICE_HPP
#include "qxlib/web/qliqstor/QxUploadToQliqStorWebService.hpp"

namespace qx {
namespace web {

class UploadToFaxWebService : public UploadToQliqStorWebService
{
public:
    UploadToFaxWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    // public because needed by qx::UploadToQliqStorTask class
    json11::Json::object targetJson(const UploadParams& uploadParams) override;
#endif

protected:
    const char *serverPath() const override;
    const char *uploadTypeString() const override;
    const char *uploadTargetKeyString() const override;
};

} // web
} // qx

#endif // QXUPLOADTOFAXWEBSERVICE_HPP

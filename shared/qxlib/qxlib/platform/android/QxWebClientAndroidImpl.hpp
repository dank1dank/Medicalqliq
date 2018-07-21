#ifndef QXANDROIDWEBCLIENT_HPP
#define QXANDROIDWEBCLIENT_HPP
#include "qxlib/web/QxWebClient.hpp"

namespace qx {
namespace web {

class AndroidWebClient : public WebClient
{
public:
    virtual void postJsonRequest(const std::string& serverPath, const json11::Json& json,
                                 JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override;

    virtual void postMultipartRequest(const std::string& serverPath, const json11::Json& json,
                                      const std::string& fileMimeType, const std::string& fileName, const std::string& filePath,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override;
};

} // web
} // qx

#endif // QXANDROIDWEBCLIENT_HPP

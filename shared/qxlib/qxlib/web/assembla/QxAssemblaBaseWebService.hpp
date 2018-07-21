#ifndef QXASSEMBLABASEWEBSERVICE_HPP
#define QXASSEMBLABASEWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/debug/QxAssemblaConfig.hpp"

namespace qx {
namespace web {

class AssemblaBaseWebService : public BaseWebService
{
public:
    typedef std::function<void(const QliqWebError& error)> DeleteResultCallback;

    AssemblaBaseWebService(WebClient *webClient = nullptr);

protected:
    void getJsonPath(const std::string& path, WebClient::JsonCallback callback);

    static void insertApiHeaders(std::map<std::string, std::string> *headers);
};

} // web
} // qx

#endif // QXASSEMBLABASEWEBSERVICE_HPP

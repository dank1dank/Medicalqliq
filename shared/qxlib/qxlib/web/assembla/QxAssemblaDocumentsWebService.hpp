#ifndef QXASSEMBLADOCUMENTSWEBSERVICE_HPP
#define QXASSEMBLADOCUMENTSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/debug/QxAssemblaConfig.hpp"

namespace qx {
namespace web {

class AssemblaDocumentsWebService : public BaseWebService
{
public:
    typedef std::function<void(const QliqWebError& error, const AssemblaDocument& document)> ResultCallback;

    AssemblaDocumentsWebService(WebClient *webClient = nullptr);

    void call(const AssemblaDocument& document, ResultCallback resultCallback, const std::string& folderName = {}, IsCancelledFunction isCancelledFun = IsCancelledFunction());

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultCallback& resultCallback);
};

} // web
} // qx

#endif // QXASSEMBLADOCUMENTSWEBSERVICE_HPP

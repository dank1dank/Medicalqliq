#ifndef QXASSEMBLAGETUSERSWEBSERVICE_HPP
#define QXASSEMBLAGETUSERSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/debug/QxAssemblaConfig.hpp"

namespace qx {
namespace web {

class AssemblaGetUsersWebService : public BaseWebService
{
public:
    typedef std::function<void(const QliqWebError& error, const std::vector<AssemblaUser>& users)> ResultCallback;

    AssemblaGetUsersWebService(WebClient *webClient = nullptr);
    void call(ResultCallback resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultCallback& resultCallback);
};

} // web
} // qx

#endif // QXASSEMBLAGETUSERSWEBSERVICE_HPP

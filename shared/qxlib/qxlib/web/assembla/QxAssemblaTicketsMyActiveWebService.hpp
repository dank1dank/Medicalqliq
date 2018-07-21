#ifndef QXASSEMBLATICKETSMYACTIVEWEBSERVICE_HPP
#define QXASSEMBLATICKETSMYACTIVEWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/debug/QxAssemblaConfig.hpp"

namespace qx {
namespace web {

class AssemblaTicketsMyActiveWebService : public BaseWebService
{
public:
    typedef std::function<void(const QliqWebError& error, const std::vector<AssemblaTicket>& users)> ResultCallback;

    AssemblaTicketsMyActiveWebService(WebClient *webClient = nullptr);

    void call(ResultCallback resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultCallback& resultCallback);
};

} // web
} // qx

#endif // QXASSEMBLATICKETSMYACTIVEWEBSERVICE_HPP

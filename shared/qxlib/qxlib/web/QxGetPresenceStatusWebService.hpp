#ifndef QXGETPRESENCESTATUSWEBSERVICE_HPP
#define QXGETPRESENCESTATUSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/QxQliqUser.hpp"

namespace qx {
namespace web {

class GetPresenceStatusWebService : public BaseWebService
{
public:
    GetPresenceStatusWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error, const Presence& presence)> ResultFunction;
    void call(const std::string& qliqId, ResultFunction resultFunction = ResultFunction(), IsCancelledFunction isCancelledFun = IsCancelledFunction());
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error, const Presence& presence) = 0;
    };
    void call(const std::string& qliqId, ResultCallback *callback);

    static bool processPresenceData(const json11::Json& json, const std::string& userUpdateReason, Presence *result);
};

} // web
} // qx

#endif // QXGETPRESENCESTATUSWEBSERVICE_HPP

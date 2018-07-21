#ifndef QXGETFAXCONTACTSWEBSERVICE_HPP
#define QXGETFAXCONTACTSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/fax/QxFaxContact.hpp"

namespace qx {
namespace web {

class GetFaxContactsWebService : public BaseWebService
{
public:
    GetFaxContactsWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error)> ResultFunction;
    void call(ResultFunction ResultFunction, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    static FaxContact contactFromJson(const json11::Json& json);
    static json11::Json::object contactToJson(const FaxContact& contact);
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error) = 0;
    };
    void call(ResultCallback *callback);

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultFunction& ResultFunction);
};

} // web
} // qx

#endif // QXGETFAXCONTACTSWEBSERVICE_HPP

#ifndef QXGETCONTACTPUBKEYWEBSERVICE_HPP
#define QXGETCONTACTPUBKEYWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"

namespace qx {
namespace web {

class GetContactPubKeyWebService : public BaseWebService
{
public:
    // TODO: add support for background SQLite connection
    GetContactPubKeyWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error, const std::string& pubKey)> ResultFunction;
    void call(const std::string& qliqId, ResultFunction ResultFunction, IsCancelledFunction isCancelledFun = IsCancelledFunction());
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error, const std::string& pubKey) = 0;
    };
    void call(const std::string& qliqId, ResultCallback *callback);

    // TODO: add static method with lambda body to retrieve PK from db or web and continue
private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultFunction& ResultFunction);
};

} // web
} // qx

#endif // QXGETCONTACTPUBKEYWEBSERVICE_HPP

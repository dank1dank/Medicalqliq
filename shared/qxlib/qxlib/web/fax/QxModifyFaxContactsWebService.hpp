#ifndef QXMODIFYFAXCONTACTSWEBSERVICE_HPP
#define QXMODIFYFAXCONTACTSWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/fax/QxFaxContact.hpp"

namespace qx {
namespace web {

class ModifyFaxContactsWebService : public BaseWebService
{
public:
    enum class Operation {
        Add,
        Remove
    };

    ModifyFaxContactsWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error)> ResultFunction;
    void call(const FaxContact& contact, Operation operation, ResultFunction ResultFunction = {}, IsCancelledFunction isCancelledFun = IsCancelledFunction());
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error) = 0;
    };
    void call(const FaxContact& contact, Operation operation, ResultCallback *callback);

private:
    void handleResponse(const QliqWebError& error, const FaxContact& contact, Operation operation, const ResultFunction& resultFunction);
    static const char *toString(Operation op);
};

} // web
} // qx

#endif // QXMODIFYFAXCONTACTSWEBSERVICE_HPP

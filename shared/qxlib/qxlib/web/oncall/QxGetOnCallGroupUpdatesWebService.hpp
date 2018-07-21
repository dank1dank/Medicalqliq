#ifndef QXGETONCALLGROUPUPDATESWEBSERVICE_H
#define QXGETONCALLGROUPUPDATESWEBSERVICE_H
#include "qxlib/web/QxWebClient.hpp"

namespace qx {
namespace web {

class GetOnCallGroupUpdatesWebService : public BaseWebService
{
public:
    typedef std::function<void(const QliqWebError& error, bool hasChanges)> ResultCallback;

    void call(const ResultCallback& resultCallback);

private:
    void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultCallback& resultCallback);
};

} // web
} // qx

#endif // QXGETONCALLGROUPUPDATESWEBSERVICE_H

#ifndef QXDATABASEWEBCLIENT_HPP
#define QXDATABASEWEBCLIENT_HPP
#include <set>
#include <string>
#include "qxlib/model/QxSessionListener.hpp"
#include "qxlib/util/QxNetworkMonitor.hpp"

namespace json11 {
class Json;
}

namespace qx {

namespace web {
class WebClient;
}
class WebRequest;

class DatabaseWebClient : public SessionListener, public NetworkListener
{
public:
    DatabaseWebClient(web::WebClient *webClient);
    virtual ~DatabaseWebClient();

    /// JSON request to qliq webserver (based on path) that is saved to db and retried until success
    void postJsonRequest(const char *path, const json11::Json& json, const std::string& uuid = {});

    void onRequestFinished(int networkError, int httpStatus);
    void onSessionStarted() override;
    void onNetworkChanged(bool isOnline) override;

    static DatabaseWebClient *defaultInstance();
    static void setDefaultInstance(DatabaseWebClient *wc);

private:
    void processOne(int sinceId = 0);
    void postRequest(const WebRequest& request);

    web::WebClient *m_webClient;
    std::set<int> m_outstandingIds;
    bool m_dontLoadNextFromDatabase = false;
};

} // qx

#endif // QXDATABASEWEBCLIENT_HPP

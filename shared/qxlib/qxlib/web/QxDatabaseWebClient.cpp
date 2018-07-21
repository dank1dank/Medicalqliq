#include "QxDatabaseWebClient.hpp"
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/dao/web/QxWebRequestDao.hpp"
#include "qxlib/model/QxSession.hpp"

namespace qx {

namespace {
DatabaseWebClient *s_defaultInstance = nullptr;
}

DatabaseWebClient::DatabaseWebClient(web::WebClient *webClient) :
    m_webClient(webClient)
{
    Session::instance().addListener(this);
}

DatabaseWebClient::~DatabaseWebClient()
{
    Session::instance().removeListener(this);
    if (NetworkMonitor::instance()) {
        NetworkMonitor::instance()->removeListener(this);
    }

    if (s_defaultInstance == this) {
        s_defaultInstance = nullptr;
    }
}

void DatabaseWebClient::postJsonRequest(const char *path, const json11::Json &json, const std::string& uuid)
{
    auto serverType = web::WebClient::RegularServer;
    WebRequest request;
    request.serverType = serverType;
    request.path = path;
    request.uuid = uuid;
    json.dump(request.json);

    WebRequestDao::insertOrUpdate(&request);
    postRequest(request);
}

void DatabaseWebClient::onRequestFinished(int networkError, int httpStatus)
{
    if (networkError == 0 && (httpStatus / 100 != 5)) {
        QXLOG_SUPPORT("Some web request finished started, attempting to process any pending web requests", nullptr);
        processOne();
    }
}

void DatabaseWebClient::onSessionStarted()
{
    if (NetworkMonitor::instance()) {
        NetworkMonitor::instance()->addListener(this);
    } else {
        QXLOG_WARN("No NetworkMonitor instance", nullptr);
    }

    QXLOG_SUPPORT("Session started, attempting to process any pending web requests", nullptr);
    processOne();
}

void DatabaseWebClient::onNetworkChanged(bool isOnline)
{
    if (isOnline) {
        QXLOG_SUPPORT("Online, attempting to process any pending web requests", nullptr);
        processOne();
    }
}

DatabaseWebClient *DatabaseWebClient::defaultInstance()
{
    return s_defaultInstance;
}

void DatabaseWebClient::setDefaultInstance(DatabaseWebClient *wc)
{
    s_defaultInstance = wc;
}

void DatabaseWebClient::processOne(int sinceId)
{
    std::string where;
    dao::Query q;
    if (!m_outstandingIds.empty()) {
        where = WebRequestDao::columnNames[WebRequestDao::IdColumn] +
            " NOT IN (";
        int i = 0;
        for (int id: m_outstandingIds) {
            if (i++ > 0) {
                where += ", ";
            }
            where += std::to_string(id);
        }
        where += ")";
    }
    if (sinceId > 0) {
        if (!where.empty()) {
            where += " AND ";
        }
        where += WebRequestDao::columnNames[WebRequestDao::IdColumn];
        where += " > ";
        where += std::to_string(sinceId);
    }
    if (!where.empty()) {
        q.appendCustomWhere(where);
    }
    q.appendOrder(WebRequestDao::IdColumn);

    auto request = WebRequestDao::selectOne(q);
    if (request.isEmpty()) {
        QXLOG_SUPPORT("No pending db web requests matching: %s", where.c_str());
    } else {
        postRequest(request);
    }
}

void DatabaseWebClient::postRequest(const WebRequest &request)
{
    if (m_outstandingIds.find(request.databaseId) != m_outstandingIds.end()) {
        return;
    }

    m_outstandingIds.insert(request.databaseId);
    int databaseId = request.databaseId;
    std::string path = request.path;
    std::string uuid = request.uuid;
    auto serverType = static_cast<web::WebClient::ServerType>(request.serverType);
    QXLOG_SUPPORT("Sending db web request(%d, %s, %s)", databaseId, path.c_str(), uuid.c_str());
    std::string err;
    json11::Json json = json11::Json::parse(request.json, err);
    m_webClient->postJsonRequest(serverType, request.path, json, [this, databaseId,path,uuid](const web::QliqWebError& error, const json11::Json&) {
        this->m_outstandingIds.erase(databaseId);

        if (error.networkError() == 0 && error.httpStatus() == 200) {
            QXLOG_SUPPORT("Completed db web request (%d, %s, %s)", databaseId, path.c_str(), uuid.c_str());
            WebRequestDao::remove(databaseId);
            // TODO: move to callback of WebClient::requestFinished
            //processOne();
        }
    });
}

} // qx

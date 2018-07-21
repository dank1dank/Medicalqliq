#ifndef QXWEBREQUESTDAO_HPP
#define QXWEBREQUESTDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/web/QxWebClient.hpp"

namespace qx {

struct WebRequest {
    int databaseId = 0;
    web::WebClient::ServerType serverType = web::WebClient::RegularServer;
    std::string path;
    std::string json;
    std::string uuid; // optional, can be empty

    WebRequest() = default;
    WebRequest(const char *path, std::string json) :
        path(path), json(json)
    {}
    bool isEmpty() const;
};

class WebRequestDao : public QxBaseDao<WebRequest>
{
public:
    enum Column {
        IdColumn,
        ServerTypeColumn,
        PathColumn,
        JsonColumn,
        UuidColumn,
    };

    static int insertOrUpdate(WebRequest *request, SQLite::Database& db = QxDatabase::database());
    static void remove(int id, SQLite::Database& db = QxDatabase::database());
};

} // qx

#endif // QXWEBREQUESTDAO_HPP

#include "QxWebLogRecordDao.hpp"
#include <map>
#ifdef DB_LOG_USE_ZSTD
#include "qxlib/util/QxZstd.hpp"
#endif

namespace {
std::map<int, qx::WebLogRecord> s_recordQueue;
}

#ifdef QXL_APP_QLIQ_CONNECT
//template<> std::vector<RowDataObserver *> RowDataObservableStatic<WebLogRecordDao>::s_observers;
std::vector<qx::RowDataObserver *> qx::WebLogRecordDao::s_observers;
#endif

template<> const bool QxBaseDao<qx::WebLogRecord>::autogeneratedPrimaryKey = true;
template<> const std::string QxBaseDao<qx::WebLogRecord>::tableName = "web_log";
template<> const std::vector<std::string> QxBaseDao<qx::WebLogRecord>::columnNames = {
    "id", "module", "session", "sequence_id", "timestamp",
    "method", "url", "response_code", "duration", "json_error",  "request", "response"
};

template<>
QxBaseDao<qx::WebLogRecord>::variant QxBaseDao<qx::WebLogRecord>::primaryKey(const qx::WebLogRecord& u)
{
    return std::to_string(u.id);
}

template<>
void QxBaseDao<qx::WebLogRecord>::setPrimaryKey(qx::WebLogRecord *obj, const QxBaseDao<qx::WebLogRecord>::variant& key)
{
    obj->id = std::stoi(key);
}

template<>
void QxBaseDao<qx::WebLogRecord>::bind(SQLite::Statement& q, const qx::WebLogRecord& obj, bool skipPrimaryKey)
{
    if (!skipPrimaryKey) {
        q.bind(":id", obj.id);
    }
    q.bind(":module", obj.module);
    q.bind(":session", static_cast<int>(obj.session));
    q.bind(":sequence_id", obj.sequenceId);
    q.bind(":timestamp", static_cast<int>(obj.time));
    q.bind(":method", obj.method);
    q.bind(":url", obj.url);
    q.bind(":response_code", obj.responseCode);
    q.bind(":duration", obj.duration);
    q.bind(":json_error", obj.jsonError);
    q.bind(":request", obj.request);
    q.bind(":response", obj.response);
}

template<>
void QxBaseDao<qx::WebLogRecord>::fillFromQuery(qx::WebLogRecord *obj, SQLite::Statement& record)
{
    obj->id = record.getColumn("id").getInt();
    obj->module = record.getColumn("module").getInt();
    obj->session = record.getColumn("session").getInt();
    obj->sequenceId = record.getColumn("sequence_id").getInt();
    obj->time = record.getColumn("timestamp").getInt();
    obj->method = static_cast<qx::WebLogRecord::HttpMethod>(record.getColumn("method").getInt());
    obj->url = record.getColumn("url").getText();
    obj->responseCode = record.getColumn("response_code").getInt();
    obj->duration = record.getColumn("duration").getInt();
    obj->jsonError = record.getColumn("json_error").getInt();
    obj->request = record.getColumn("request").getText();
    obj->response = record.getColumn("response").getText();
}

template<>
qx::WebLogRecord QxBaseDao<qx::WebLogRecord>::fromQuery(SQLite::Statement &record)
{
    qx::WebLogRecord obj;
    fillFromQuery(&obj, record);
    return obj;
}

int qx::WebLogRecordDao::insertRequest(int module, qx::WebLogRecord::HttpMethod method, const char *url, const char *request, SQLite::Database& db)
{
    qx::WebLogRecord record;
    record.module = module;
    record.session = qxlog::Logger::instance().sessionId();
    record.sequenceId = qxlog::Logger::instance().nextSequenceId();
    record.time = std::time(nullptr);

    record.method = method;
    record.url = url;
#ifndef DB_LOG_USE_ZSTD
    record.request = request;
#else
    Zstd::compress(request, &record.request);
#endif
    int id = WebLogRecordDao::insert(&record, db);
#ifdef QXL_APP_QLIQ_CONNECT
    notifyObservers(Event::Inserted, id);
#endif
    return id;
}

bool qx::WebLogRecordDao::updateResponse(int id, int duration, int responseCode, int jsonError, const char *response, SQLite::Database &db)
{
    bool ret = false;
    std::string sql = "UPDATE " + tableName + " SET duration = :duration, response_code = :response_code, json_error = :json_error, response = :response "
        " WHERE id = :id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":id", id);
        q.bind(":duration", duration);
        q.bind(":response_code", responseCode);
        q.bind(":json_error", jsonError);
#ifndef DB_LOG_USE_ZSTD
        q.bind(":response", response);
#else
        std::string compressedResponse;
        Zstd::compress(response, &compressedResponse);
        q.bind(":response", compressedResponse);
#endif
        ret = q.exec();
#ifdef QXL_APP_QLIQ_CONNECT
        if (ret) {
            notifyObservers(Event::Changed, id);
        }
#endif
    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
    }
    return ret;
}

bool qx::WebLogRecordDao::updateJsonError(int id, int jsonError, SQLite::Database &db)
{
    bool ret = false;
    std::string sql = "UPDATE " + tableName + " SET json_error = :json_error "
        " WHERE id = :id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":id", id);
        q.bind(":json_error", jsonError);
        ret = q.exec();
#ifdef QXL_APP_QLIQ_CONNECT
        if (ret) {
            notifyObservers(Event::Changed, id);
        }
#endif
    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
    }
    return ret;
}

void qx::WebLogRecordDao::insertRequestToQueue(int id, int module, qx::WebLogRecord::HttpMethod method, const char *url, const char *request)
{
    qx::WebLogRecord record;
    record.module = module;
    record.id = id;
    record.session = qxlog::Logger::instance().sessionId();
    record.sequenceId = qxlog::Logger::instance().nextSequenceId();
    record.time = std::time(nullptr);

    record.method = method;
    record.url = url;
#ifndef DB_LOG_USE_ZSTD
    record.request = request;
#else
    Zstd::compress(request, &record.request);
#endif

    s_recordQueue[record.id] = record;
}

void qx::WebLogRecordDao::updateResponseInQueue(int id, int duration, int responseCode, int jsonError, const char *response)
{
    if (s_recordQueue.count(id) == 1) {
        auto& r = s_recordQueue[id];
        r.duration = duration;
        r.responseCode = responseCode;
        r.jsonError = jsonError;
#ifndef DB_LOG_USE_ZSTD
        r.response = response;
#else
        Zstd::compress(response, &r.response);
#endif
    }
}

void qx::WebLogRecordDao::updateJsonErrorInQueue(int id, int jsonError)
{
    if (s_recordQueue.count(id) == 1) {
        auto& r = s_recordQueue[id];
        r.jsonError = jsonError;
    }
}

bool qx::WebLogRecordDao::flushQueueToDatabase(SQLite::Database &db)
{
    bool error = false;
    for (auto& pair: s_recordQueue) {
        WebLogRecord& record = pair.second;
        int id = WebLogRecordDao::insert(&record, db);
        if (id < 1) {
            error = true;
        }
    }
    if (!error) {
        s_recordQueue.clear();
    }
    return !error;
}

#ifdef QXL_APP_QLIQ_CONNECT

void qx::WebLogRecordDao::addRowDataObserver(qx::RowDataObserver *observer)
{
    auto it = std::find(s_observers.begin(), s_observers.end(), observer);
    if (it == s_observers.end()) {
        s_observers.push_back(observer);
    }
}

void qx::WebLogRecordDao::removeRowDataObserver(qx::RowDataObserver *observer)
{
    auto it = std::find(s_observers.begin(), s_observers.end(), observer);
    if (it != s_observers.end()) {
        s_observers.erase(it);
    }
}

void qx::WebLogRecordDao::notifyObservers(qx::WebLogRecordDao::Event event, int rowId)
{
    switch (event) {
    case Event::Inserted:
        for (RowDataObserver *o: s_observers) {
            o->onRowInserted(rowId);
        }
    case Event::Changed:
        for (RowDataObserver *o: s_observers) {
            o->onRowChanged(rowId);
        }
    case Event::Removed:
        for (RowDataObserver *o: s_observers) {
            o->onRowRemoved(rowId);
        }
    }
}

#endif // QXL_APP_QLIQ_CONNECT

#ifndef QX_WEBLOGRECORDDAO_H
#define QX_WEBLOGRECORDDAO_H
#include "qxlib/log/QxDbLogRecordBaseDao.hpp"
#include "qxlib/log/web/QxWebLogRecord.hpp"
#include "qxlib/db/QxLogDatabase.hpp"
#ifdef QXL_APP_QLIQ_CONNECT
#include "qxlib/util/QxRowDataObserver.hpp"
#endif

namespace qx {

class WebLogRecordDao : public DbLogRecordBaseDao<WebLogRecord>
//#ifdef QXL_APP_QLIQ_CONNECT
//        , public RowDataObservableStatic<WebLogRecordDao>
//#endif
{
public:
    enum Column {
        IdColumn,
        ModuleColumn,
        SessionColumn,
        SequenceIdColumn,
        TimeColumn,
        VerbColumn,
        UrlColumn,
        ResponseCodeColumn,
        DurationColumn,
        JsonErrorColumn,
        RequestColumn,
        ResponseColumn,
    };

    static int insertRequest(int module, WebLogRecord::HttpMethod method, const char *url, const char *request, SQLite::Database& db = LogDatabase::database());
    static bool updateResponse(int id, int duration, int responseCode, int jsonError, const char *response, SQLite::Database& db = LogDatabase::database());
    static bool updateJsonError(int id, int jsonError, SQLite::Database& db = LogDatabase::database());

    // The below methods are used to cache initial (most likely /services/login) request and response
    // in memory while database is not yet open because user is not logged in
    static void insertRequestToQueue(int id, int module, WebLogRecord::HttpMethod method, const char *url, const char *request);
    static void updateResponseInQueue(int id, int duration, int responseCode, int jsonError, const char *response);
    static void updateJsonErrorInQueue(int id, int jsonError);
    static bool flushQueueToDatabase(SQLite::Database& db = LogDatabase::database());

#ifdef QXL_APP_QLIQ_CONNECT
    static void addRowDataObserver(RowDataObserver *observer);
    static void removeRowDataObserver(RowDataObserver *observer);

protected:
    enum class Event {
        Inserted,
        Changed,
        Removed
    };
    static void notifyObservers(Event event, int rowId);
private:
    static std::vector<RowDataObserver *> s_observers;
#endif // QXL_APP_QLIQ_CONNECT
};

} // namespace qx

#endif // QX_WEBLOGRECORDDAO_H

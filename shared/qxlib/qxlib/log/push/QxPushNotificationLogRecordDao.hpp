#ifndef QXPUSHNOTIFICATIONLOGRECORDDAO_HPP
#define QXPUSHNOTIFICATIONLOGRECORDDAO_HPP
#include "qxlib/log/QxDbLogRecordBaseDao.hpp"
#include "qxlib/db/QxLogDatabase.hpp"

namespace qx {

struct PushNotificationLogRecord {
    int id = 0; // database id
    std::time_t session = 0;
    int sequenceId = 0;
    std::time_t time = 0;
    std::string callId;
    std::string body;
};

class PushNotificationLogRecordDao : public DbLogRecordBaseDao<PushNotificationLogRecord>
{
public:
    enum Column {
        IdColumn,
        SessionColumn,
        SequenceIdColumn,
        TimeColumn,
        CallIdColumn,
        BodyColumn,
    };

    // The below methods are used to cache initial (most likely /services/login) request and response
    // in memory while database is not yet open because user is not logged in
    static void insertToDatabaseOrQueue(const std::string& body, const std::string& callId = {});
    static bool flushQueueToDatabase(SQLite::Database& db = LogDatabase::database());
};

} // namespace qx

#endif // QXPUSHNOTIFICATIONLOGRECORDDAO_HPP

#ifndef QX_CHANGENOTIFICATIONLOGDAO_H
#define QX_CHANGENOTIFICATIONLOGDAO_H
#include "qxlib/log/QxDbLogRecordBaseDao.hpp"
#include "qxlib/db/QxLogDatabase.hpp"

namespace qx {

struct ChangeNotificationLogRecord {
    enum ProcessingStatus {
        UnprocessedStatus = 0,
        ProcessedStatus = 1,
        ErrorStatus = 2
    };

    int id; // database id
    std::time_t session;
    int sequenceId;
    std::time_t time;
    std::string subject;
    std::string qliqId;
    std::string feature;
    std::string json;
    ProcessingStatus status;

    ChangeNotificationLogRecord();
};

class ChangeNotificationLogDao : public DbLogRecordBaseDao<ChangeNotificationLogRecord>
{
public:
    enum Column {
        IdColumn,
        SessionColumn,
        SequenceIdColumn,
        TimeColumn,
        SubjectColumn,
        QliqIdColumn,
        FeatureColumn,
        JsonColumn,
        ProcessingStatusColumn
    };
};

} // namespace qx

#endif // QX_CHANGENOTIFICATIONLOGDAO_H

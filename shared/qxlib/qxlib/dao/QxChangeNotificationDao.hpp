#ifndef QX_CHANGENOTIFICATIONDAO_HPP
#define QX_CHANGENOTIFICATIONDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"

class json;

namespace qx {

struct ChangeNotification {
    int databaseId;
    std::string subject;
    std::string qliqId;
    std::string json;
    bool hasPayload;
    time_t timestamp;
    std::string errors;

    ChangeNotification();
    bool isEmpty() const;
    void clear();
};

class ChangeNotificationDao : public QxBaseDao<ChangeNotification>
{
public:
#ifndef SWIG
    enum Column {
        IdColumn,
        SubjectColumn,
        QliqIdColumn,
        JsonColumn,
        HasPayloadColumn,
        TimestampColumn,
        ErrorsColumn,
    };
#endif //!SWIG

    //static int insert(const std::string &subject, const std::string &qliqId, const std::string& json, SQLite::Database& db = QxDatabase::database());
    static int insert(ChangeNotification *cn, SQLite::Database& db = QxDatabase::database());
    static void remove(int id, SQLite::Database& db = QxDatabase::database());
    static void updateErrorCode(int id, int errorCode, SQLite::Database& db = QxDatabase::database());
};

} // namespace qx

#endif // QX_CHANGENOTIFICATIONDAO_HPP

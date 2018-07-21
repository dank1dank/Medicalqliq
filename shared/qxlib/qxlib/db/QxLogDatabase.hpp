#ifndef QXLOGDATABASE_HPP
#define QXLOGDATABASE_HPP
#include "qxlib/db/QxDatabase.hpp"

namespace qx {

/// Separate db connection for logdb.
///
///
class LogDatabase
{
public:
    LogDatabase();
    ~LogDatabase();

    bool open(const char *fileName, const char *key, const char *pragma = nullptr, bool readOnly = false);
    bool openNextToDefaultDatabase();
    bool isOpen() const;
    bool update(const std::string files[], size_t filesCount, const QxDatabase::FileReaderCallback& fileReader);
    void close();
    bool deleteRowsOlderThen(int timestamp);
    bool deleteRowsOlderThenRetentionPeriod();
    bool vacuum();

    const std::string& fileName() const;
    SQLite::Database& databaseConnection();

    static SQLite::Database& database();
    static LogDatabase *instance();
    static bool isDefaultInstanceOpen();

    static void setAllLogsEnabled(bool value);

    static bool isWebEnabled();
    static void setWebEnabled(bool value);

    static bool isSipEnabled();
    static void setSipEnabled(bool value);

    static bool isChangeNotificationEnabled();
    static void setChangeNotificationEnabled(bool value);

    static bool isPushNotificationEnabled();
    static void setPushNotificationEnabled(bool value);

    static void setRetentionPeriod(int hours);
    static int retentionPeriod();

    static std::string defaultPath(const std::string& folderOrFileName);

private:
    int execLogException(const char *sql);
    void onDatabaseReady();

    QxDatabase m_db;

    static bool m_isWebEnabled;
    static bool m_isSipEnabled;
    static bool m_isChangeNotificationEnabled;
    static bool m_isPushNotificationEnabled;
    static int m_retentionPeriod;
};

} // qx

#endif // QXLOGDATABASE_HPP

#include "QxLogDatabase.hpp"
#include "QxLogDatabase.hpp"
#include <cstring>
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/log/push/QxPushNotificationLogRecordDao.hpp"
#include "qxlib/log/web/QxWebLogRecordDao.hpp"

namespace qx {

bool LogDatabase::m_isWebEnabled = false;
bool LogDatabase::m_isSipEnabled = false;
#ifdef QXL_APP_QLIQ_CONNECT
bool LogDatabase::m_isChangeNotificationEnabled = true;
#else
bool LogDatabase::m_isChangeNotificationEnabled = false;
#endif
bool LogDatabase::m_isPushNotificationEnabled = false;
int LogDatabase::m_retentionPeriod = 72;

namespace {
    LogDatabase *s_defaultInstance = nullptr;
}

LogDatabase::LogDatabase()
{
    if (!s_defaultInstance) {
        s_defaultInstance = this;
    }
}

LogDatabase::~LogDatabase()
{
    close();
    if (s_defaultInstance == this) {
        s_defaultInstance = nullptr;
    }
}

bool LogDatabase::open(const char *fileName, const char *key, const char *pragma, bool readOnly)
{
    bool ret = m_db.open(fileName, key, pragma, readOnly);
    if (ret) {
        bool isPragmaEmpty = (!pragma || std::strlen(pragma) == 0);
        if (!readOnly && isPragmaEmpty) {
            execLogException("PRAGMA auto_vacuum = 1");
        }
    } else {
        if (!readOnly && Filesystem::exists(fileName)) {
            QXLOG_ERROR("Failed to open logdb, trying to delete it and create a new one", nullptr);
            if (Filesystem::removeFile(fileName)) {
                return open(fileName, key, pragma, readOnly);
            } else {
                QXLOG_ERROR("Failed to delete logdb file", nullptr);
            }
        }
    }
    return ret;
}

bool LogDatabase::openNextToDefaultDatabase()
{
    std::string defaultDbPath = QxDatabase::defaultInstance().fileName();
    std::string path = defaultPath(defaultDbPath);
    std::string dbKey = QxDatabase::defaultInstance().encryptionKey();
    std::string pragmas = QxDatabase::defaultInstance().extraPragmas();
    return open(path.c_str(), dbKey.c_str(), pragmas.c_str());
}

bool LogDatabase::isOpen() const
{
    return m_db.isOpen();
}

bool LogDatabase::update(const std::string files[], size_t filesCount, const QxDatabase::FileReaderCallback &fileReader)
{
    bool ret = m_db.update(files, filesCount, fileReader);
    onDatabaseReady();
    return ret;
}

void LogDatabase::close()
{
    m_db.close();
}

bool LogDatabase::deleteRowsOlderThen(int timestamp)
{
    bool ret = true;
    int hours = static_cast<int>(std::difftime(std::time(nullptr), timestamp)) / 60 / 60;
    QXLOG_SUPPORT("Starting transaction to delete rows older then %d hours", hours);
    execLogException("BEGIN TRANSACTION");

    for (const std::string& tableName: {"web_log", "sip_log", "cn_log"}) {
        std::string sql = "DELETE FROM " + tableName + " WHERE timestamp < :timestamp";
        try {
            SQLite::Statement q(m_db.database2(), sql);
            q.bind(":timestamp", timestamp);
            int count = q.exec();
            QXLOG_SUPPORT("Deleted %d rows from %s table", count, tableName.c_str());
        } catch (const SQLite::Exception& ex) {
            ret = false;
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
    }

    execLogException("COMMIT TRANSACTION");
    QXLOG_SUPPORT("Transaction commited", nullptr);
    return ret;
}

bool LogDatabase::deleteRowsOlderThenRetentionPeriod()
{
    if (m_retentionPeriod < 1) {
        QXLOG_ERROR("m_retentionPeriod is invalid: %d", m_retentionPeriod);
        return false;
    } else {
        std::time_t timestamp = std::time(nullptr) - (m_retentionPeriod * 60 * 60);
        return deleteRowsOlderThen(timestamp);
    }
}

bool LogDatabase::vacuum()
{
    int ret = m_db.database2().exec("VACUUM");
    return ret > -1;
}

const std::string &LogDatabase::fileName() const
{
    return m_db.fileName();
}

SQLite::Database &LogDatabase::databaseConnection()
{
    return m_db.database2();
}

SQLite::Database &LogDatabase::database()
{
    if (!s_defaultInstance) {
        QXLOG_FATAL("No LogDatabase::s_defaultInstance, creating new instance to avoid crash", nullptr);
        s_defaultInstance = new LogDatabase();
    }
    return s_defaultInstance->m_db.database2();
}

LogDatabase *LogDatabase::instance()
{
    return s_defaultInstance;
}

bool LogDatabase::isDefaultInstanceOpen()
{
    if (s_defaultInstance) {
        return s_defaultInstance->isOpen();
    } else {
        return false;
    }
}

void LogDatabase::setAllLogsEnabled(bool value)
{
    setWebEnabled(value);
    setSipEnabled(value);
    setChangeNotificationEnabled(value);
    setPushNotificationEnabled(value);
}

bool LogDatabase::isWebEnabled()
{
    return m_isWebEnabled;
}

void LogDatabase::setWebEnabled(bool value)
{
    m_isWebEnabled = value;
}

bool LogDatabase::isSipEnabled()
{
    return m_isSipEnabled;
}

void LogDatabase::setSipEnabled(bool value)
{
    m_isSipEnabled = value;
}

bool LogDatabase::isChangeNotificationEnabled()
{
    return m_isChangeNotificationEnabled;
}

void LogDatabase::setChangeNotificationEnabled(bool value)
{
    m_isChangeNotificationEnabled = value;
}

bool LogDatabase::isPushNotificationEnabled()
{
    return m_isPushNotificationEnabled;
}

void LogDatabase::setPushNotificationEnabled(bool value)
{
    m_isPushNotificationEnabled = value;
}

void LogDatabase::setRetentionPeriod(int hours)
{
    m_retentionPeriod = hours;
}

int LogDatabase::retentionPeriod()
{
    return m_retentionPeriod;
}

std::string LogDatabase::defaultPath(const std::string &folderOrFileName)
{
    return qx::FileInfo(folderOrFileName).dirPath() + qx::Filesystem::separator() + "log.db";
}

int LogDatabase::execLogException(const char *sql)
{
    int ret = 0;
    try {
        ret = m_db.database2().exec(sql);
    } QX_DAO_CATCH_BLOCK_CSTR
            return ret;
}

void LogDatabase::onDatabaseReady()
{
    PushNotificationLogRecordDao::flushQueueToDatabase(m_db.database2());
    WebLogRecordDao::flushQueueToDatabase(m_db.database2());
}

} // qx

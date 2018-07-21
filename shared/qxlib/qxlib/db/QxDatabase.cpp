#include "QxDatabase.hpp"
#include <cstring>
#include <regex>
#include <iostream>
#include <SQLiteCpp/Transaction.h>
#include "qxlib/debug/QxAssert.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/StringUtils.hpp"

namespace {
    SQLite::Database *s_database = nullptr;
    SQLite::Database *s_crashPreventionDatabase = nullptr;
    QxDatabase *s_defaultInstance = nullptr;
    const int DEFAULT_BUSY_TIMEOUT_MS = 3000;
}

struct QxDatabase::Private {
    SQLite::Database *db;
    std::string fileName;
    std::string encryptionKey;
    std::string extraPragmas;
    int initialDbVersion;
    bool isNewDatabase;

    Private() :
        db(nullptr), initialDbVersion(0), isNewDatabase(true)
    {}

    void executeMultipleStatementsInTransaction(const std::string& sql, int *numRowsAffected);
};

QxDatabase::QxDatabase() :
    d(new Private())
{
    d->db = nullptr;
}

QxDatabase::~QxDatabase()
{
    close();
    if (s_defaultInstance == this) {
        s_defaultInstance = nullptr;
    }
    delete d;
}

bool QxDatabase::open(const char *fileName, const char *key, const char *pragma, bool readOnly)
{
    QXLOG_SUPPORT("Attempting to open database at: %s", fileName);

    try {
        d->fileName = fileName;
        d->encryptionKey = key ? key : "";
        d->extraPragmas = pragma ? pragma : "";

        d->db = new SQLite::Database(fileName, (readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE), DEFAULT_BUSY_TIMEOUT_MS);
        if (key && std::strlen(key) > 0) {
#ifdef QXL_HAS_QT
            std::string pragma = "PRAGMA KEY = \"x";
#else
            std::string pragma = "PRAGMA KEY = ";
#endif
            pragma += "'";
            pragma += key;
            pragma += "'";
#ifdef QXL_HAS_QT
            pragma += "\"";
#endif
            QXLOG_SUPPORT("Configuring db key", nullptr);
            d->db->exec(pragma);
        }

        if (pragma && std::strlen(pragma) > 0) {
            QXLOG_SUPPORT("Executing custom: %s", pragma);
            d->db->exec(pragma);
        } else {
            for (const std::string& p: defaultPragmas(readOnly)) {
                QXLOG_SUPPORT("Executing default: %s", p.c_str());
                d->db->exec(p);
            }
        }

        // Execute dummy query to verify db connection is valid
        //d->db->execAndGet("SELECT type FROM sqlite_master WHERE type = 'table' LIMIT 1");
        {
            SQLite::Statement query(*d->db, "SELECT type FROM sqlite_master WHERE type = 'table' LIMIT 1");
            if (!query.executeStep()) {
                // TODO: throw if encryption error or if required non-empty db
            }
        }


        // TODO: set busy timeout or make cross platform code retry forever as desktop does
        QXLOG_SUPPORT("Opened database for cross platform library", nullptr);
        return true;

    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("Cannot open QxDatabase: %s", ex.what());
        delete d->db;
        d->db = nullptr;
        return false;
    }
}

bool QxDatabase::isOpen() const
{
    return (d->db != nullptr);
}

void QxDatabase::deleteDefaultInstance()
{
    if (s_defaultInstance) {
        delete s_defaultInstance;
        s_defaultInstance = nullptr;
    }
}

QxDatabase& QxDatabase::defaultInstance()
{
    qx_assert(s_defaultInstance != nullptr);
    return *s_defaultInstance;
}

std::string QxDatabase::decryptDatabaseToPlaintext(const std::string &encryptedDbPath, const std::string &plainTextDbPath, const std::string &dbKey)
{
    std::string errorMsg;

    try {
        QXLOG_SUPPORT("Attempting to export encrypted database to plain text one. From: %s, to: %s", encryptedDbPath.c_str(), plainTextDbPath.c_str());

        SQLite::Database db(encryptedDbPath, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, DEFAULT_BUSY_TIMEOUT_MS);
#ifdef QXL_HAS_QT
        std::string pragma = "PRAGMA KEY = \"x";
#else
        std::string pragma = "PRAGMA KEY = ";
#endif
        pragma += "'";
        pragma += dbKey;
        pragma += "'";
#ifdef QXL_HAS_QT
        pragma += "\"";
#endif
        db.exec(pragma);

        {
            std::string test;
            SQLite::Statement query(db, "SELECT type FROM sqlite_master WHERE type = 'table' LIMIT 1");
            if (query.executeStep()) {
                test = query.getColumn(0).getText();
            } else {
                throw SQLite::Exception("Cannot decrypt the database");
            }
        }

        int userVersion = 0;
        {
            SQLite::Statement query(db, "PRAGMA user_version");
            if (query.executeStep()) {
                userVersion = query.getColumn(0).getInt();
            }
        }

        db.exec("ATTACH DATABASE '" + plainTextDbPath + "' AS plaintext KEY ''");
        db.exec("SELECT sqlcipher_export('plaintext')");

        if (userVersion > 0) {
            db.exec("PRAGMA plaintext.user_version = " + std::to_string(userVersion));
        }

        db.exec("DETACH DATABASE plaintext");
    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("Cannot decrypt: %s", ex.what());
        errorMsg = ex.what();
    }
    return errorMsg;
}

std::vector<std::string> QxDatabase::defaultPragmas(bool readOnlyDatabase)
{
    std::vector<std::string> pragmas;
    if (readOnlyDatabase == false) {
        // Without WAL journal mode db changes aren't visible immediately between threads
        pragmas.push_back("PRAGMA journal_mode = WAL");
        // According to offical docs database integrity is guaranteed with NORMAL in WAL mode
        pragmas.push_back("PRAGMA synchronous = NORMAL");
//#if defined(QXL_HAS_QT) && !defined(QXL_OS_MAC)
//      pragmas.push_back("PRAGMA synchronous = OFF");
//#endif
#ifdef QXL_OS_MAC
        // We need to enable use of F_FULLFSYNC on Mac which doesn't have proper fsync()
        pragmas.push_back("PRAGMA fullfsync = ON");
#endif
    } else {
        // In this mode SQLite will not aquire read lock on table when reading.
        // This will make sure we don't prevent any write operation on other connections.
        // However this can yield inconsistent read data in some cases.
        pragmas.push_back("PRAGMA read_uncommitted = 1");
    }

    return pragmas;
}

bool QxDatabase::integrityCheck()
{
    bool ret = false;
    if (d->db) {
        std::string sql = "PRAGMA integrity_check";
        try {
            SQLite::Statement q(*d->db, sql);
            if (q.executeStep()) {
                std::string result = q.getColumn(0).getText();
                if (result == std::string("ok")) {
                    ret = true;
                } else {
                    QXLOG_ERROR("PRAGMA integrity_check; error: %s", result.c_str());
                }
            } else {
                QXLOG_ERROR("Could not sqlite_step() for PRAGMA integrity_check", nullptr);
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
    } else {
        QXLOG_ERROR("Could not sqlite_step() for PRAGMA integrity_check because database is not open", nullptr);
    }

    if (!ret) {
        close();
    }

    return ret;
}

bool QxDatabase::update(const std::string files[], size_t filesCount, const FileReaderCallback& fileReader)
{
    std::size_t i = static_cast<std::size_t>(-1);
    int numRowsAffected = 0;

    try {
        // We use user_version pragma to store the db version
        d->initialDbVersion = d->db->execAndGet("PRAGMA user_version").getInt();

        // Optional code to print sqlite lib version
        // QXLOG_SUPPORT("SQLite version: %s", d->db->execAndGet("SELECT sqlite_version() AS sqlite_version").getText().c_str());

        d->isNewDatabase = (d->initialDbVersion == 0);

        for (i = 0; i < filesCount; ++i) {
            int updateFileDbVersion = i + 1;
            if (d->initialDbVersion < updateFileDbVersion) {

                QXLOG_SUPPORT("Updating database to version %d", updateFileDbVersion);

                if (files[i].empty()) {
                    // Skip "gap" files (workaround for a bug in sql file ordering)
                    continue;
                }

                std::string sql = fileReader(files[i]);
                d->executeMultipleStatementsInTransaction(sql, &numRowsAffected);
                d->db->exec("PRAGMA user_version = " + std::to_string(updateFileDbVersion));

                if (numRowsAffected > 0) {
                    QXLOG_SUPPORT("number of rows affected: %d", numRowsAffected);
                }
            }
        }

        return true;

    } catch (const SQLite::Exception& ex) {
        const std::string& fileName = (i == static_cast<std::size_t>(-1) ? std::string("<no file>") : files[i]);
        QXLOG_ERROR("Database update failed in %d-ith file (%s), number of rows affected: %d", i, fileName.c_str(), numRowsAffected);
    }

    return false;
}

void QxDatabase::close()
{
    if (d->db) {
        if (s_database == d->db) {
            s_database = nullptr;
        }
        if (s_crashPreventionDatabase == d->db) {
            s_crashPreventionDatabase = nullptr;
        }
        delete d->db;
        d->db = nullptr;
    }
}

const std::string &QxDatabase::fileName() const
{
    return d->fileName;
}

const std::string &QxDatabase::encryptionKey() const
{
    return d->encryptionKey;
}

const std::string &QxDatabase::extraPragmas() const
{
    return d->extraPragmas;
}

SQLite::Database &QxDatabase::database2()
{
    return *d->db;
}

SQLite::Database *QxDatabase::cloneDatabase(bool readOnly) const
{
    QxDatabase clone;
    clone.open(d->fileName.c_str(), d->encryptionKey.c_str(), d->extraPragmas.c_str(), readOnly);
    return clone.takeDatabase();
}

SQLite::Database *QxDatabase::takeDatabase()
{
    auto tmp = d->db;
    d->db = nullptr;
    return tmp;
}

SQLite::Database &QxDatabase::database()
{
    if (!s_database) {
        s_crashPreventionDatabase = new SQLite::Database(":memory:");
        s_database = s_crashPreventionDatabase;
    }
    if (s_database == s_crashPreventionDatabase) {
        QXLOG_FATAL("Using crash prevention database", nullptr);
    }
    return *s_database;
}

bool QxDatabase::openDefaultInstance(const char *fileName, const char *key, const char *pragma, bool readOnly)
{
    if (s_defaultInstance) {
        QXLOG_ERROR("ERROR: default instance is already open, closing it now", nullptr);
        deleteDefaultInstance();
    }
    s_defaultInstance = new QxDatabase();
    bool ret = s_defaultInstance->open(fileName, key, pragma, readOnly);
    s_database = s_defaultInstance->d->db;
    return ret;
}

bool QxDatabase::isDefaultInstanceOpen()
{
    return (s_defaultInstance != nullptr);
}

bool QxDatabase::isDefaultInstanceCrashPrevention()
{
    return (s_database != nullptr) && (s_database == s_crashPreventionDatabase);
}

void QxDatabase::Private::executeMultipleStatementsInTransaction(const std::string &sql, int *numRowsAffected)
{
    if (StringUtils::contains(sql, "{my_qliq_id}")) {
        throw std::runtime_error("Variable {my_qliq_id} interpolatino is not implemented yet");
    }
//    if (sql.contains(VARIABLE_MY_QLIQ_ID)) {
//        if (!m_myQliqId.isEmpty()) {
//            sql.replace(VARIABLE_MY_QLIQ_ID, m_myQliqId);
//        } else {
//            QLOG_ERROR() << "Cannot replace variable" << VARIABLE_MY_QLIQ_ID << "in SQL update script because m_myQliqId is empty";
//        }
//    }

    SQLite::Transaction transaction(*db);

    *numRowsAffected = 0;

#ifdef COMPILER_PROPERLY_IMPLEMENTS_REGEX
    std::regex commentRx("--[^\n]*\n");
#endif
    std::vector<std::string> statements = StringUtils::split(sql, ';');
    int lineNo = 0;
    for (auto statement: statements) {
        lineNo++;
#ifdef COMPILER_PROPERLY_IMPLEMENTS_REGEX
        statement = std::regex_replace(statement, commentRx, std::string(""));
#endif
        statement = StringUtils::trim(statement);
        if (statement.empty())
            continue;

        try {
            SQLite::Statement stmt(*db, statement);
            *numRowsAffected += stmt.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("Error in statement #%d of sql file: %s", lineNo, statement.c_str());
            throw;
        }
    }

    transaction.commit();
}

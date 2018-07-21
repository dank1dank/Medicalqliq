#ifndef QXDATABASE_H
#define QXDATABASE_H
#include <string>
#include <functional>
#include <vector>
#include <SQLiteCpp/SQLiteDatabase.h>

class QxDatabase
{
public:
    typedef std::function<std::string(const std::string&)> FileReaderCallback;

    QxDatabase();
    ~QxDatabase();

    bool open(const char *fileName, const char *key, const char *pragma = nullptr, bool readOnly = false);
    bool isOpen() const;
    bool integrityCheck();
    bool update(const std::string files[], size_t filesCount, const FileReaderCallback& fileReader);

    void close();

    const std::string& fileName() const;
    const std::string& encryptionKey() const;
    const std::string& extraPragmas() const;

    SQLite::Database& database2();

    /// Creates a new database object using the same file, encryption key and pragmas as this one
    /// \return nullptr on error
    SQLite::Database *cloneDatabase(bool readOnly = true) const;

    /// Transfers ownership of this db (if any) to the caller
    SQLite::Database *takeDatabase();

    // TODO: rename to defaultDatabase()
    static SQLite::Database& database();
    static bool openDefaultInstance(const char *fileName, const char *key, const char *pragma = nullptr, bool readOnly = false);
    static bool isDefaultInstanceOpen();
    static bool isDefaultInstanceCrashPrevention();
    static void deleteDefaultInstance();
    static QxDatabase& defaultInstance();

    static std::string decryptDatabaseToPlaintext(const std::string& encryptedDbPath, const std::string& plainTextDbPath, const std::string& dbKey);
    static std::vector<std::string> defaultPragmas(bool readOnlyDatabase = false);

private:
    struct Private;
    Private *d;
};

#endif // QXDATABASE_H

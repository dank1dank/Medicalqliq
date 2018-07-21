#ifndef QXKEYVALUEDAO_HPP
#define QXKEYVALUEDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"

namespace qx {

class KeyValueDao
{
public:
    static bool insert(const std::string& key, const std::string& value, SQLite::Database& db = QxDatabase::database());
    static bool update(const std::string& key, const std::string& value, SQLite::Database& db = QxDatabase::database());
    static bool insertOrUpdate(const std::string& key, const std::string& value, SQLite::Database& db = QxDatabase::database());
    static std::string select(const std::string& key, SQLite::Database& db = QxDatabase::database());
    static bool exists(const std::string& key, SQLite::Database& db = QxDatabase::database());
    static bool delete_(const std::string& key, SQLite::Database& db = QxDatabase::database());
    static bool deleteKeysStartingWith(const std::string& key, SQLite::Database& db = QxDatabase::database());
};

} // qx

#endif // QXKEYVALUEDAO_HPP

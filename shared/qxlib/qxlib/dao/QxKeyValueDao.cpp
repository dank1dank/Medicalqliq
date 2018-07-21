#include "QxKeyValueDao.hpp"

#define TABLE_NAME "key_value"

namespace qx {

bool KeyValueDao::insert(const std::string &key, const std::string &value, SQLite::Database &db)
{
    bool ret = false;
    std::string sql;
    try {
        sql = "INSERT INTO key_value (key, value) VALUES (:key, :value)";
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        q.bind(":value", value);
        if (q.exec()) {
            ret = true;
        }
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool KeyValueDao::update(const std::string &key, const std::string &value, SQLite::Database &db)
{
    bool ret = false;
    std::string sql;
    try {
        sql = "UPDATE key_value SET value = :value WHERE key = :key";
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        q.bind(":value", value);
        if (q.exec()) {
            ret = true;
        }
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool KeyValueDao::insertOrUpdate(const std::string &key, const std::string &value, SQLite::Database &db)
{
    bool ret = false;
    std::string sql;
    try {
        sql = "INSERT OR REPLACE INTO key_value (key, value) VALUES (:key, :value)";
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        q.bind(":value", value);
        if (q.exec()) {
            ret = true;
        }
    } QX_DAO_CATCH_BLOCK
    return ret;
}

std::string KeyValueDao::select(const std::string &key, SQLite::Database &db)
{
    std::string ret;
    const std::string& sql = "SELECT value FROM key_value WHERE key = :key LIMIT 1";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        if (q.executeStep()) {
            ret = q.getColumn(0).getText();
        }
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool KeyValueDao::exists(const std::string &key, SQLite::Database &db)
{
    bool ret = false;
    const std::string sql = "SELECT key FROM key_value WHERE key = :key LIMIT 1";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        ret = q.executeStep();
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool KeyValueDao::delete_(const std::string &key, SQLite::Database &db)
{
    bool ret = false;
    const std::string sql = "DELETE FROM key_value WHERE key = :key";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":key", key);
        ret = q.exec();
    } QX_DAO_CATCH_BLOCK
    return ret;
}

bool KeyValueDao::deleteKeysStartingWith(const std::string &key, SQLite::Database &db)
{
    bool ret = false;
    const std::string sql = "DELETE FROM key_value WHERE key LIKE '" + key + "%'";
    try {
        SQLite::Statement q(db, sql);
        ret = q.exec();
    } QX_DAO_CATCH_BLOCK
    return ret;
}

} // qx

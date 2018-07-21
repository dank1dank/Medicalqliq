#ifndef QXONCALLGROUPSDAO_HPP
#define QXONCALLGROUPSDAO_HPP
#include <string>
#include <vector>
#include "json11/json11.hpp"
#include "qxlib/dao/QxBaseDao.hpp"

namespace qx {

struct OnCallGroup
{
    std::string qliqId;
    int lastUpdatedOnServer;

    OnCallGroup();
    bool isEmpty() const;

    static OnCallGroup fromJson(const json11::Json& json);
};

class OnCallGroupsDao
{
public:
    static const std::vector<OnCallGroup>& selectAll(SQLite::Database& db = QxDatabase::database());
    static OnCallGroup groupWithId(const std::string& qliqId);
    static unsigned int lastUpdated(const std::string& qliqId);
    // Modification
    static OnCallGroup saveOneGroup(const json11::Json& json);
    static bool deleteWithId(const std::string& qliqId);
    static void clearCache();

private:
    static std::vector<OnCallGroup> parseJsonArray(const std::string& str);
};

} // qx

#endif // QXONCALLGROUPSDAO_HPP

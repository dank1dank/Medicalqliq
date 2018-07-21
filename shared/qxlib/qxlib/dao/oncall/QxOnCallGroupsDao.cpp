#include "QxOnCallGroupsDao.hpp"
#include "qxlib/dao/QxKeyValueDao.hpp"

#define KEY_ONCALL_GROUP_LIST "oncall_group_list"

namespace qx {

namespace {
std::vector<OnCallGroup> s_groups;
}


OnCallGroup::OnCallGroup() :
    lastUpdatedOnServer(0)
{}

bool OnCallGroup::isEmpty() const
{
    return qliqId.empty();
}

OnCallGroup OnCallGroup::fromJson(const json11::Json &json)
{
    OnCallGroup g;
    g.qliqId = json["qliq_id"].string_value();
    g.lastUpdatedOnServer = json["last_updated_epoch"].int_value();
}

const std::vector<OnCallGroup> &OnCallGroupsDao::selectAll(SQLite::Database& db)
{
    if (s_groups.empty()) {
        std::string json = KeyValueDao::select(KEY_ONCALL_GROUP_LIST, db);
        s_groups = parseJsonArray(json);
    }
    return s_groups;
}

std::vector<OnCallGroup> OnCallGroupsDao::parseJsonArray(const std::string &str)
{
    std::vector<OnCallGroup> ret;
    std::string parsingError;
    json11::Json json = json11::Json::parse(str, parsingError);
    if (json.type() == json11::Json::ARRAY) {
        ret.reserve(json.array_items().size());
        for (const auto& jsonItem: json.array_items()) {
            OnCallGroup g = OnCallGroup::fromJson(jsonItem);
            if (!g.isEmpty()) {
                ret.push_back(g);
            }
        }
    }
    return ret;
}

} // qx

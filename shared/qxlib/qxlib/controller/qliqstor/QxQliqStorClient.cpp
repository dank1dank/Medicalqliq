#include "QxQliqStorClient.hpp"
#include "qxlib/dao/QxKeyValueDao.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/model/QxSession.hpp"

#define DEFAULT_QLIQSTOR_GROUP_QLIQ_ID "settings_qliqstor_default_group_qliq_id"

namespace qx {

std::vector<QliqStorClient::QliqStorPerGroup> QliqStorClient::qliqStors(SQLite::Database &db)
{
    std::vector<QliqStorPerGroup> ret;
    std::string myQliqId = Session::instance().myQliqId();
    std::string sql = "SELECT DISTINCT gq.qliq_id, g.name, g.qliq_id FROM group_qliqstor gq "
        " JOIN qliq_group g ON (gq.group_qliq_id = g.qliq_id) "
        " WHERE gq.group_qliq_id IN "
        "  (SELECT group_qliq_id FROM user_group WHERE user_qliq_id = :user_qliq_id) "
        "  AND g.parent_qliq_id IS NULL "
        " ORDER BY g.name";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":user_qliq_id", myQliqId);
        while (q.executeStep()) {
            QliqStorPerGroup qg;
            qg.qliqStorQliqId = q.getColumn(0).getText();
            qg.groupName = q.getColumn(1).getText();
            qg.groupQliqId = q.getColumn(2).getText();
            ret.push_back(qg);
        }
    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
    }
    return ret;
}

void QliqStorClient::setDefaultQliqStor(const QliqStorClient::QliqStorPerGroup &qg, SQLite::Database& db)
{
    setDefaultGroupQliqId(qg.groupQliqId, db);
}

bool QliqStorClient::shouldShowQliqStorSelectionDialog(SQLite::Database &db)
{
    return defaultQliqStor(db).isEmpty();
}

QliqStorClient::QliqStorPerGroup QliqStorClient::defaultQliqStor(SQLite::Database &db)
{
    QliqStorPerGroup ret;
    std::string myQliqId = Session::instance().myQliqId();
    std::string groupQliqId = defaultGroupQliqId(db);
    if (!groupQliqId.empty()) {
        std::string sql = "SELECT gq.qliq_id, g.name, g.qliq_id FROM group_qliqstor gq "
            " JOIN qliq_group g  ON (gq.group_qliq_id = g.qliq_id) "
            " JOIN user_group ug ON (ug.group_qliq_id = gq.group_qliq_id) "
            " WHERE gq.group_qliq_id = :group_qliq_id AND ug.user_qliq_id = :my_qliq_id ";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":group_qliq_id", groupQliqId);
            q.bind(":my_qliq_id", myQliqId);
            if (q.executeStep()) {
                ret.qliqStorQliqId = q.getColumn(0).getText();
                ret.groupName = q.getColumn(1).getText();
                ret.groupQliqId = q.getColumn(2).getText();
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
    } else {
        const auto& vec = qliqStors(db);
        if (vec.size() == 1) {
            ret = vec[0];
        }
    }
    return ret;
}

std::string QliqStorClient::defaultGroupQliqId(SQLite::Database &db)
{
    return KeyValueDao::select(DEFAULT_QLIQSTOR_GROUP_QLIQ_ID, db);
}

bool QliqStorClient::setDefaultGroupQliqId(const std::string &groupQliqId, SQLite::Database &db)
{
    return KeyValueDao::insertOrUpdate(DEFAULT_QLIQSTOR_GROUP_QLIQ_ID, groupQliqId, db);
}

bool QliqStorClient::QliqStorPerGroup::isEmpty() const
{
    return qliqStorQliqId.empty();
}

std::string QliqStorClient::QliqStorPerGroup::displayName() const
{
    return groupName + " (" + qliqStorQliqId + ")";
}

} // qx

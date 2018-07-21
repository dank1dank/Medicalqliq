#include "QxQliqStorDao.hpp"
#include "qxlib/dao/QxQliqUserDao.hpp"
#include "qxlib/dao/chat/QxMultipartyDao.hpp"
#include "qxlib/dao/sip/QxSipContactDao.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/util/VectorUtils.hpp"

namespace qx {
    
bool QliqStorDao::insertQliqStorForGroup(const std::string& qliqStorQliqId, const std::string& groupQliqId)
{
    bool ret = false;
    auto& db = QxDatabase::database();
    std::string sql = "INSERT INTO group_qliqstor(qliq_id, group_qliq_id) VALUES (:qliq_id, :group_qliq_id)";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":qliq_id", qliqStorQliqId);
        q.bind(":group_qliq_id", groupQliqId);
        ret = q.exec();
    } QX_DAO_CATCH_BLOCK;
    return ret;
}

std::vector<std::string> QliqStorDao::qliqStorsForQliqId(const std::string &qliqId)
{
    std::vector<std::string> qliqStors;
    const SipContact sipContact = SipContactDao::selectOneBy(SipContactDao::QliqIdColumn, qliqId);

    if (sipContact.type == SipContact::Type::User) {
        const QliqUser& u = QliqUserDao::selectOneBy(QliqUserDao::QliqIdColumn, qliqId);
        if (!u.isEmpty()) {
            qliqStors = qliqStorsForUser(u.qliqId);
        }
        auto myQliqStors = qliqStorsForUser(Session::instance().myQliqId());
        VectorUtils::union_sorted(&qliqStors, myQliqStors);

    } else if (sipContact.type == SipContact::Type::Group) {
        // debug query to display all groups and matching qliqStor (or none)
        // SELECT gq.qliq_id as qliqstor_id, g.qliq_id as group_id, g.name, g.type FROM qliq_group g LEFT OUTER JOIN group_qliqstor gq ON (g.qliq_id = gq.group_qliq_id)
        QliqGroup g = QliqGroupDao::selectOneBy(QliqGroupDao::QliqIdColumn, qliqId);
        if (!g.isEmpty()) {
            qliqStors = qliqStorsForGroup(g.qliqId);
            if (qliqStors.empty() && g.groupType == QliqGroup::Type::OnCall) {
                // OnCall groups are missing qS info, so we check the parent
                g = QliqGroupDao::selectOneBy(QliqGroupDao::QliqIdColumn, g.parentQliqId);
                qliqStors = qliqStorsForGroup(g.qliqId);
            }
        }

    } else if (sipContact.type == SipContact::Type::MultiParty) {
        qliqStors = qliqStorsForUser(Session::instance().myQliqId());
        Multiparty mp = MultipartyDao::selectOneByQliqId(qliqId);
        if (!mp.isEmpty()) {
            for (const auto& participant: mp.participants) {
                auto participantQliqStors = qliqStorsForUser(participant.qliqId);
                VectorUtils::union_sorted(&qliqStors, participantQliqStors);
            }
        }
    }

    return qliqStors;
}

std::vector<std::string> QliqStorDao::qliqStorsForUser(const std::string &qliqId)
{
    std::vector<std::string> ret;
    auto& db = QxDatabase::database();
    std::string sql = "SELECT DISTINCT qliq_id FROM group_qliqstor WHERE group_qliq_id IN (SELECT group_qliq_id FROM user_group WHERE user_qliq_id = :user_qliq_id) ORDER BY qliq_id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":user_qliq_id", qliqId);
        while (q.executeStep()) {
            ret.push_back(q.getColumn(0).getText());
        }
    } QX_DAO_CATCH_BLOCK;

    return ret;
}

std::vector<std::string> QliqStorDao::qliqStorsForGroup(const std::string &qliqId)
{
    std::vector<std::string> ret;
    auto& db = QxDatabase::database();
    std::string sql = "SELECT DISTINCT qliq_id FROM group_qliqstor WHERE group_qliq_id = :group_qliq_id ORDER BY qliq_id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":group_qliq_id", qliqId);
        while (q.executeStep()) {
            ret.push_back(q.getColumn(0).getText());
        }
    } QX_DAO_CATCH_BLOCK;

    return ret;
}
    
bool QliqStorDao::deleteQliqStor(const std::string& qliqId)
{
    bool ret = false;
    auto& db = QxDatabase::database();
    std::string sql = "DELETE FROM group_qliqstor WHERE qliq_id = :qliq_id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":qliq_id", qliqId);
        ret = q.exec();
    } QX_DAO_CATCH_BLOCK;
    
    return ret;
}

} // qx

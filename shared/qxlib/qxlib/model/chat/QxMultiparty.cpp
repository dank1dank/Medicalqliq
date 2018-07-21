#include "qxlib/model/chat/QxMultiparty.hpp"
#include <algorithm>
#include "json11/json11.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/dao/QxQliqUserDao.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/StringUtils.hpp"

namespace qx {

Multiparty::Multiparty(SipContact &sipContact) :
    SipContact(sipContact)
{
    if (sipContact.type != SipContact::Type::MultiParty) {
        // Revert the initialization
        qliqId = "";
        privateKey = "";
        publicKey = "";
        type = SipContact::Type::MultiParty;
    }
}

bool Multiparty::isEmpty() const
{
    return qliqId.empty();
}

bool Multiparty::contains(std::string qliqId) const
{
    return participants.find(qliqId) != participants.end();
}

std::string Multiparty::displayName() const
{
    if (m_cachedDisplayName.empty()) {
        std::vector<std::string> names;
        names.reserve(participants.size());
        for (const auto& p: participants) {
            names.emplace_back(p.qliqId);
        }

        std::string sql = "SELECT u.display_name FROM qliq_user u WHERE u.qliq_id IN "
            + qx::dao::Query::formatSet(names);
        names.clear();

        try {
            SQLite::Database& db = QxDatabase::database();
            SQLite::Statement q(db, sql);
            while (q.executeStep()) {
                names.emplace_back(q.getColumn(0).getText());
            }

        } QX_DAO_CATCH_BLOCK

        std::sort(names.begin(), names.end());
        m_cachedDisplayName = StringUtils::join(names, "; ");
    }
    return m_cachedDisplayName;
}

std::vector<Multiparty::Participant> Multiparty::getParticipants()
{
    std::vector<Multiparty::Participant> ret;
    if (!participants.empty()) {
        ret.reserve(participants.size());
        std::copy(participants.begin(), participants.end(), std::back_inserter(ret));
    }
    return ret;
}

Multiparty Multiparty::parseJson(const std::string &str)
{
    std::string errorMsg;
    using namespace json11;
    Json json = Json::parse(str, errorMsg);

    Multiparty ret;
    ret.qliqId = json["qliq_id"].string_value();
    ret.privateKey = json["private_key"].string_value();
    ret.publicKey = json["public_key"].string_value();

    ret.name = json["name"].string_value();

    bool isNewResponseFormat = false;
    const auto& participants = json["participants"].array_items();
    for (const auto& obj: participants) {
        Participant p;
        p.qliqId = obj["qliq_id"].string_value();
        p.role = obj["role"].string_value();

        if (!p.isEmpty()) {
            ret.participants.insert(p);
        }

        if (!p.role.empty()) {
            isNewResponseFormat = true;
        }
    }

#ifndef NO_GUI
    if (!isNewResponseFormat) {
        // New format is for Care Channels and contains current user
        // old format is for regular MP and does not contain current user
        bool hasMyself = false;
        const std::string myQliqId = qx::Session::instance().myQliqId();
        if (myQliqId.empty()) {
            QXLOG_ERROR("BUG: qx::Session is not initalized, myQliqId is empty", nullptr);
        }
        for (const auto& p: ret.participants) {
            if (p.qliqId == myQliqId) {
                hasMyself = true;
                break;
            }
        }

        if (!hasMyself) {
            Participant p;
            p.qliqId = myQliqId;
            ret.participants.insert(p);
        }
    }
#endif
    return ret;
}

} // namespace qx

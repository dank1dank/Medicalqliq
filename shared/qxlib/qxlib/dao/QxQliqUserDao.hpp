#ifndef QXQLIQUSERDAO_HPP
#define QXQLIQUSERDAO_HPP
#include <map>
#include "qxlib/model/QxQliqUser.hpp"
#include "qxlib/dao/QxBaseDao.hpp"

namespace qx {

class QliqUserDao : public QxBaseDao<QliqUser>
{
public:
    enum Column {
        QliqIdColumn,
        FirstNameColumn,
        MiddleNameColumn,
        LastNameColumn,
        EmailColumn,
        MobileColumn
    };
    static QliqUser selectOneBy(Column column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database());

    static Presence selectPresenceById(const std::string& qliqId, SQLite::Database& db = QxDatabase::database());
    static bool updatePresence(const Presence& p, SQLite::Database& db = QxDatabase::database());

#if defined(QXL_DEVICE_PC) && !defined(QT_NO_DEBUG)
    static void test();
#endif
};

class QliqGroupDao : public QxBaseDao<QliqGroup>
{
public:
    enum Column {
        QliqIdColumn,
        ParentQliqIdColumn,
        NameColumn,
        AcronymColumn,
        // TODO: add missing columns address, fax, npi etc.
        OpenMembershipColumn,
        BelongsColumn,
        CanBroadcastColumn,
        CanMessageColumn,
        DeletedColumn,
        // Only on desktop
        // TypeColumn
    };
};

// This is a helper class that provides cached db access to QliqUser, QliqGroup or Multiparty
class ContactEntityProvider {
public:
    const ContactEntity& byQliqId(const std::string& qliqId, SipContact::Type type = SipContact::Type::Uknown);

private:
    std::map<std::string, ContactEntity> m_entities;
};

class PersonalGroupDao : public QxBaseDao<PersonalGroup> {
public:
    enum Column {
        IdColumn,
        NameColumn,
    };

    static bool updateMembers(int groupId, const std::vector<std::string> qliqIds, SQLite::Database& db = QxDatabase::database());
    static bool selectMembers(PersonalGroup *group, SQLite::Database& db = QxDatabase::database());
};

} // qx

#endif // QXQLIQUSERDAO_HPP

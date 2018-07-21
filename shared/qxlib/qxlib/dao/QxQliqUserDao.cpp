#include "QxQliqUserDao.hpp"
#include "qxlib/dao/chat/QxMultipartyDao.hpp" // for ContactEntityProvider

template<> const bool QxBaseDao<qx::QliqUser>::autogeneratedPrimaryKey = false;
template<> const std::string QxBaseDao<qx::QliqUser>::tableName = "qliq_user";
template<> const std::vector<std::string> QxBaseDao<qx::QliqUser>::columnNames = {
    "qliq_id", "first_name", "middle_name", "last_name", "email", "mobile"
};

#if defined(QXL_DEVICE_PC) && !defined(TEST_MOBILE_DB)
#define OPTIONAL_JOIN_FOR_SELECT ""
#else
#define OPTIONAL_JOIN_FOR_SELECT " JOIN contact ON (contact.contact_id = qliq_user.contact_id)"
#endif

template<>
QxBaseDao<qx::QliqUser>::variant QxBaseDao<qx::QliqUser>::primaryKey(const qx::QliqUser& u)
{
    return u.qliqId;
}

template<>
void QxBaseDao<qx::QliqUser>::setPrimaryKey(qx::QliqUser *obj, const QxBaseDao<qx::QliqUser>::variant& key)
{
    obj->qliqId = key;
}

template<>
void QxBaseDao<qx::QliqUser>::bind(SQLite::Statement& q, const qx::QliqUser& mp, bool skipPrimaryKey)
{
    if (!skipPrimaryKey) {
        q.bind(":qliq_id", mp.qliqId);
    }
    q.bind(":first_name", mp.firstName);
    q.bind(":middle_name", mp.middleName);
    q.bind(":last_name", mp.lastName);
    q.bind(":email", mp.email);
    q.bind(":mobile", mp.mobile);
}

template<>
void QxBaseDao<qx::QliqUser>::fillFromQuery(qx::QliqUser *obj, SQLite::Statement& record)
{
    obj->qliqId = record.getColumn("qliq_id").getText();
    obj->firstName = record.getColumn("first_name").getText();
    obj->middleName = record.getColumn("middle_name").getText();
    obj->lastName = record.getColumn("last_name").getText();
    obj->email = record.getColumn("email").getText();
    obj->mobile = record.getColumn("mobile").getText();
}

template<>
qx::QliqUser QxBaseDao<qx::QliqUser>::fromQuery(SQLite::Statement &record)
{
    qx::QliqUser obj;
    fillFromQuery(&obj, record);
    return obj;
}

qx::QliqUser qx::QliqUserDao::selectOneBy(qx::QliqUserDao::Column column, const QxBaseDao::variant &value, int skip, SQLite::Database &db)
{
    QliqUser ret;
    std::string sql = "SELECT * FROM " + tableName + " " + OPTIONAL_JOIN_FOR_SELECT + " WHERE qliq_user." + columnNames[column] + " = :qvalue LIMIT 1 OFFSET " + std::to_string(skip);
    try {
        SQLite::Statement q(db, sql);
        q.bind(":qvalue", value);
        if (q.executeStep()) {
            ret = fromQuery(q);
        }
    } catch (const SQLite::Exception& ex) {
        QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
    }
    return ret;
}

qx::Presence qx::QliqUserDao::selectPresenceById(const std::string &qliqId, SQLite::Database &db)
{
    Presence ret;
    std::string sql = "SELECT presence_status, presence_message, forwarding_qliq_id "
        "FROM qliq_user WHERE qliq_id = :qliq_id LIMIT 1";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":qliq_id", qliqId);
        if (q.executeStep()) {
            ret.qliqId = qliqId;
            ret.status = static_cast<Presence::Status>(q.getColumn(0).getInt());
            ret.message = q.getColumn(1).getText();
            ret.forwardToQliqId = q.getColumn(2).getText();
        }
    } QX_DAO_CATCH_BLOCK;
    return ret;
}

bool qx::QliqUserDao::updatePresence(const qx::Presence &p, SQLite::Database &db)
{
    bool ret = false;
    std::string sql = "UPDATE qliq_user SET presence_status = :presence_status, "
        "presence_message = :presence_message, forwarding_qliq_id = :forwarding_qliq_id "
        "WHERE qliq_id = :qliq_id AND (presence_status != :presence_status OR "
        "presence_message != :presence_message OR forwarding_qliq_id != :forwarding_qliq_id)";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":presence_status", p.status);
        q.bind(":presence_message", p.message);
        q.bind(":forwarding_qliq_id", p.forwardToQliqId);
        q.bind(":qliq_id", p.qliqId);
        ret = (q.exec() > 0);
    } QX_DAO_CATCH_BLOCK;
    return ret;
}

#if defined(QXL_DEVICE_PC) && !defined(QT_NO_DEBUG)

void qx::QliqUserDao::test()
{
#ifdef TEST_IPHONE_DB
    SQLite::Database db("c:\\temp\\assembla\\iphone\\upload wrong status\\iphone\\847222992-plain.sqlite");
    QliqUser u = selectOneBy(QliqIdColumn, "847222992", 0, db);
    QliqGroup g = QliqGroupDao::selectOneBy(QliqIdColumn, "783975978", 0, db);
#else
    QliqUser u = selectOneBy(QliqIdColumn, "336211885");
#endif
    if (!u.isEmpty()) {
    }
}

#endif

////////////////////////////////////////////////////////////////////////////////
// QliqGroup
//
template<> const bool QxBaseDao<qx::QliqGroup>::autogeneratedPrimaryKey = false;
template<> const std::string QxBaseDao<qx::QliqGroup>::tableName = "qliq_group";
template<> const std::vector<std::string> QxBaseDao<qx::QliqGroup>::columnNames = {
    "qliq_id", "parent_qliq_id", "name", "acronym", "open_membership",
    "belongs", "can_broadcast", "can_message", "deleted"
};

template<>
QxBaseDao<qx::QliqGroup>::variant QxBaseDao<qx::QliqGroup>::primaryKey(const qx::QliqGroup& u)
{
    return u.qliqId;
}

template<>
void QxBaseDao<qx::QliqGroup>::setPrimaryKey(qx::QliqGroup *obj, const QxBaseDao<qx::QliqGroup>::variant& key)
{
    obj->qliqId = key;
}

template<>
void QxBaseDao<qx::QliqGroup>::bind(SQLite::Statement& q, const qx::QliqGroup& mp, bool skipPrimaryKey)
{
    if (!skipPrimaryKey) {
        q.bind(":qliq_id", mp.qliqId);
    }
    q.bind(":parent_qliq_id", mp.parentQliqId);
    q.bind(":name", mp.name);
    q.bind(":acronym", mp.acronym);
    q.bind(":open_membership", mp.openMembership);
    q.bind(":belongs", mp.belongs);
    q.bind(":can_broadcast", mp.canBroadcast);
    q.bind(":can_message", mp.canMessage);
    q.bind(":deleted", mp.isDeleted);
}

template<>
void QxBaseDao<qx::QliqGroup>::fillFromQuery(qx::QliqGroup *obj, SQLite::Statement& record)
{
    obj->qliqId = record.getColumn("qliq_id").getText();
    obj->parentQliqId = record.getColumn("parent_qliq_id").getText();
    obj->name = record.getColumn("name").getText();
    obj->acronym = record.getColumn("acronym").getText();
    obj->openMembership = record.getColumn("open_membership").getInt();
    obj->belongs = record.getColumn("belongs").getInt();
    obj->canBroadcast = record.getColumn("can_broadcast").getInt();
    obj->canMessage = record.getColumn("can_message").getInt();
    obj->isDeleted = record.getColumn("deleted").getInt();
}

template<>
qx::QliqGroup QxBaseDao<qx::QliqGroup>::fromQuery(SQLite::Statement &record)
{
    qx::QliqGroup obj;
    fillFromQuery(&obj, record);
    return obj;
}

const qx::ContactEntity& qx::ContactEntityProvider::byQliqId(const std::string& qliqId, SipContact::Type type)
{
    if (m_entities.find(qliqId) == m_entities.end()) {
        ContactEntity e;

        if (type == SipContact::Type::User || type == SipContact::Type::Uknown) {
            auto u = QliqUserDao::selectOneBy(QliqUserDao::QliqIdColumn, qliqId);
            if (!u.isEmpty()) {
                e = ContactEntity(u);
            }
        }
        if (type == SipContact::Type::Group || (type == SipContact::Type::Uknown && e.isEmpty())) {
            auto g = QliqGroupDao::selectOneBy(QliqGroupDao::QliqIdColumn, qliqId);
            if (!g.isEmpty()) {
                e = ContactEntity(g);
            }
        }
        if (type == SipContact::Type::MultiParty || (type == SipContact::Type::Uknown && e.isEmpty())) {
            auto mp = MultipartyDao::selectOneByQliqId(qliqId);
            if (!mp.isEmpty()) {
                e = ContactEntity(mp);
            }
        }
        m_entities[qliqId] = e;
    }
    return m_entities[qliqId];
}

////////////////////////////////////////////////////////////////////////////////
// PersonalGroup
//
template<> const bool QxBaseDao<qx::PersonalGroup>::autogeneratedPrimaryKey = true;
template<> const std::string QxBaseDao<qx::PersonalGroup>::tableName = "personal_group";
template<> const std::vector<std::string> QxBaseDao<qx::PersonalGroup>::columnNames = {
    "id", "name",
};

template<>
QxBaseDao<qx::PersonalGroup>::variant QxBaseDao<qx::PersonalGroup>::primaryKey(const qx::PersonalGroup& u)
{
    return std::to_string(u.databaseId);
}

template<>
void QxBaseDao<qx::PersonalGroup>::setPrimaryKey(qx::PersonalGroup *obj, const QxBaseDao<qx::PersonalGroup>::variant& key)
{
    obj->databaseId = std::atoi(key.c_str());
}

template<>
void QxBaseDao<qx::PersonalGroup>::bind(SQLite::Statement& q, const qx::PersonalGroup& obj, bool skipPrimaryKey)
{
    if (!skipPrimaryKey) {
        q.bind(":id", obj.databaseId);
    }
    q.bind(":name", obj.name);
}

template<>
void QxBaseDao<qx::PersonalGroup>::fillFromQuery(qx::PersonalGroup *obj, SQLite::Statement& record)
{
    obj->databaseId = record.getColumn("id").getInt();
    obj->name = record.getColumn("name").getText();
}

template<>
qx::PersonalGroup QxBaseDao<qx::PersonalGroup>::fromQuery(SQLite::Statement &record)
{
    qx::PersonalGroup obj;
    fillFromQuery(&obj, record);
    return obj;
}

bool qx::PersonalGroupDao::updateMembers(int groupId, const std::vector<std::string> qliqIds, SQLite::Database &db)
{
    bool ret = true;
    std::string sql;
    try {
        {
            sql = "DELETE FROM personal_group_user WHERE personal_group_id = :personal_group_id";
            SQLite::Statement q(db, sql);
            q.bind(":personal_group_id", groupId);
            q.exec();
        }
        {
            sql = "INSERT INTO personal_group_user(personal_group_id, user_qliq_id) VALUES (:personal_group_id, :user_qliq_id)";
            SQLite::Statement q(db, sql);
            q.bind(":personal_group_id", groupId);
            for (const auto& qliqId: qliqIds) {
                q.bind(":user_qliq_id", qliqId);
                ret &= (q.exec() > 0);
                q.reset();
            }
        }
    } QX_DAO_CATCH_BLOCK;
    return ret;
}

bool qx::PersonalGroupDao::selectMembers(qx::PersonalGroup *group, SQLite::Database &db)
{
    bool ret = false;
    group->usersIds.clear();
    std::string sql = "SELECT user_qliq_id FROM personal_group_user WHERE personal_group_id = :personal_group_id";
    try {
        SQLite::Statement q(db, sql);
        q.bind(":personal_group_id", group->databaseId);
        while (q.executeStep()) {
            group->usersIds.emplace_back(q.getColumn(0).getText());
            ret = true;
        }
    } QX_DAO_CATCH_BLOCK;
    return ret;
}

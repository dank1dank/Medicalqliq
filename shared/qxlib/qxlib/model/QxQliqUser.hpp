#ifndef QX_QLIQUSER_H
#define QX_QLIQUSER_H
#include <string>
#include "qxlib/model/sip/QxSipContact.hpp"
#include "qxlib/model/chat/QxMultiparty.hpp"

namespace qx {

enum class ContactType {
    Unknown = 0,
    User = 1,
    Group = 2,
    Multiparty = 3
};

struct Presence {
    enum Status {
        OfflineStatus = 0,
        OnlineStatus = 1,
#ifdef QXL_OS_ANDROID
        AwayStatus = 3,
        DoNotDisturbStatus = 2,
#else
        AwayStatus = 2,
        DoNotDisturbStatus = 3,
#endif
#ifndef QXL_DEVICE_PC
        PagerStatus = 4
#else
        PagerStatus = 5
#endif
    };
    Status status;
    std::string qliqId;
    std::string message;
    std::string forwardToQliqId;

    Presence();
    bool isEmpty() const;
    static Status statusFromString(const std::string& str);
    static std::string statusToString(Status status);
};

class QliqUser : public SipContact
{
public:
    std::string email;
    std::string firstName;
    std::string middleName;
    std::string lastName;
    std::string mobile;
    Presence presence;

    QliqUser();
    std::string displayName() const;
};

struct QliqGroup : public SipContact {
    enum class Type {
        Regular = 0,
        OnCall = 1,
    };

    std::string parentQliqId;
    std::string name;
    std::string acronym;

    std::string address;
    std::string city;
    std::string state;
    std::string zip;

    std::string phone;
    std::string fax;

    std::string taxonomyCode;
    std::string npi;

    bool belongs = false;
    bool openMembership = false;
    bool canBroadcast = false;
    bool canMessage = false;
    bool isDeleted = false;
    Type groupType = Type::Regular;

    QliqGroup();
    std::string displayName() const;
};

struct ContactEntity {
    SipContact::Type type = SipContact::Type::Uknown;
    //union {
        QliqUser user;
        QliqGroup group;
        qx::Multiparty multiparty;
    //};

    ContactEntity() = default;
    ContactEntity(const QliqUser& u);
    ContactEntity(const QliqGroup& g);
    ContactEntity(const qx::Multiparty& mp);
    bool isEmpty() const;
    std::string displayName() const;
};

struct PersonalGroup {
    int databaseId = 0;
    std::string name;
    std::vector<std::string> usersIds;
};

} // namespace qx

#endif // QX_QLIQUSER_H

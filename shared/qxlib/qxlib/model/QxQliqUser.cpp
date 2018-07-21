#include "QxQliqUser.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/log/QxLog.hpp"

namespace qx {

QliqUser::QliqUser() :
    SipContact(SipContact::Type::User)
{}

std::string QliqUser::displayName() const
{
    // Last, First M.
    std::string ret = lastName;

    if (!firstName.empty()) {
        if (!ret.empty()) {
            ret.append(", ");
        }
        ret.append(firstName);

        if (!middleName.empty()) {
            ret.push_back(' ');
            ret.push_back(middleName[0]);
            ret.push_back('.');
        }
    }

    if (ret.empty()) {
        // This logic if for invitations
        if (!email.empty()) {
            ret = email;
        } else if (!mobile.empty()) {
            ret = "Phone " + mobile;
        } else {
            ret = "";
        }
    }
    return ret;
}

Presence::Presence() : status(OfflineStatus)
{}

bool Presence::isEmpty() const
{
    return qliqId.empty();
}

Presence::Status Presence::statusFromString(const std::string &status)
{
    Status ret = OfflineStatus;

    using namespace StringUtils;

    // Testing with startsWith because sometimes server sends trailing space (ie SIP status)
    if (startsWith(status, "online", CaseInsensitive))
        ret = OnlineStatus;
    else if (startsWith(status, "away", CaseInsensitive))
        ret = AwayStatus;
    else if (startsWith(status, "dnd", CaseInsensitive) || startsWith(status, "do not disturb", CaseInsensitive))
        ret = DoNotDisturbStatus;
    else if (startsWith(status, "offline", CaseInsensitive))
        ret = OfflineStatus;
    else if (startsWith(status, "pager", CaseInsensitive))
        ret = PagerStatus;
    else
        QXLOG_ERROR("Unsupported presence status: '%s'", status.c_str());

    return ret;
}

std::string Presence::statusToString(Presence::Status status)
{
    switch (status) {
    case OnlineStatus:
        return "Online";
    case AwayStatus:
        return "Away";
    case DoNotDisturbStatus:
        return "Do Not Disturb";
    case OfflineStatus:
        return "Offline";
    case PagerStatus:
        return "Pager";
    }
    return "";
}

QliqGroup::QliqGroup() :
    SipContact(SipContact::Type::Group)
{}

std::string QliqGroup::displayName() const
{
    return name;
}

ContactEntity::ContactEntity(const QliqUser &u) :
    type(SipContact::Type::User),
    user(u)
{
}

ContactEntity::ContactEntity(const QliqGroup &g) :
    type(SipContact::Type::Group),
    group(g)
{
}

ContactEntity::ContactEntity(const Multiparty &mp) :
    type(SipContact::Type::MultiParty),
    multiparty(mp)
{
}

bool ContactEntity::isEmpty() const
{
    switch (type) {
    case SipContact::Type::Uknown:
        return true;
    case SipContact::Type::User:
        return user.isEmpty();
    case SipContact::Type::Group:
        return group.isEmpty();
    case SipContact::Type::MultiParty:
        return multiparty.isEmpty();
    }
}

std::string ContactEntity::displayName() const
{
    switch (type) {
    case SipContact::Type::Uknown:
        return "unknown";
    case SipContact::Type::User:
        return user.displayName();
    case SipContact::Type::Group:
        return group.displayName();
    case SipContact::Type::MultiParty:
        return multiparty.displayName();
    }
}

} // namespace qx

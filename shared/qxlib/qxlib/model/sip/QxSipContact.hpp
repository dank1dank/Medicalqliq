#ifndef QXSIPCONTACT_H
#define QXSIPCONTACT_H
#include <string>

namespace qx {

struct SipContact {
    enum class Type {
        Uknown = 0,
        User = 1,
        Group = 2,
        MultiParty = 3
    };

    std::string qliqId;
    std::string privateKey;
    std::string publicKey;
    Type type = Type::Uknown;

    SipContact()
    {}

    explicit SipContact(Type type) :
        type(type)
    {}

    inline bool isEmpty() const
    {
        return qliqId.empty();
    }

    inline bool operator<(const SipContact& other) const
    {
        return qliqId < other.qliqId;
    }

    inline bool operator==(const SipContact& other) const
    {
        return qliqId == other.qliqId;
    }

    inline bool operator!=(const SipContact& other) const
    {
        return qliqId != other.qliqId;
    }
};

} // namespace qx

#endif // QXSIPCONTACT_H

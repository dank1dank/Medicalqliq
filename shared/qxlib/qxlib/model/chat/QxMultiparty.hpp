#ifndef QXMULTIPARTY_H
#define QXMULTIPARTY_H
#include <string>
#include <set>
#include <vector>
#include "qxlib/model/sip/QxSipContact.hpp"

namespace qx {

class Multiparty : public SipContact
{
public:
    struct Participant {
        std::string qliqId;
        std::string role;

        Participant() {}

        Participant(const std::string& qliqId, const std::string& role = std::string()) :
            qliqId(qliqId),
            role(role)
        {}

        bool isEmpty() const
        {
            return qliqId.empty();
        }

        bool operator<(const Participant& p) const
        {
            return this->qliqId < p.qliqId;
        }
    };

    std::string name;
#ifndef SWIG
    std::set<Participant> participants;
#endif

    Multiparty() :
        SipContact(Type::MultiParty)
    {}

    explicit Multiparty(SipContact &sipContact);

    bool isEmpty() const;
    bool contains(std::string qliqId) const;
    std::string displayName() const;
    // This method is for Java only
    std::vector<Participant> getParticipants();

    static Multiparty parseJson(const std::string& json);

private:
    mutable std::string m_cachedDisplayName;
};

} // namespace qx

#endif // QXMULTIPARTY_H

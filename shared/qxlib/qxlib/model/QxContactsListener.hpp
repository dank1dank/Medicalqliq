#ifndef QXCONTACTSLISTENER_HPP
#define QXCONTACTSLISTENER_HPP
#include "qxlib/util/QxDestructionNotifier.hpp"

namespace qx {

struct Presence;

class ContactsListener : public DestructionNotifier {
public:
//    enum ChangeReason {
//        NotSpecifiedChangeReason = 0,
//        PresenceChangeReason = 0x2
//    };
//    virtual void onContactsChanged(const std::vector<QliqUser>& contacts, int changeReason);
    virtual void onPresenceChanged(const Presence& p);

protected:
    ~ContactsListener();
};

} // qx

#endif // QXCONTACTSLISTENER_HPP

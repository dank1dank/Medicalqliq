#include "QxContactsModel.hpp"
#include <set>
#include "qxlib/log/QxLog.hpp"
#include "qxlib/model/QxContactsListener.hpp"

namespace qx {

struct ContactsModel::Private : public DestructionListener {
    std::set<ContactsListener *> listeners;

    virtual ~Private()
    {
        for (auto l: listeners) {
            DestructionNotifier *dn = static_cast<DestructionNotifier *>(l);
            dn->removeDestructionListener(this);
        }
    }

    void addListener(ContactsListener *listener)
    {
        listeners.insert(listener);
        DestructionNotifier *dn = static_cast<DestructionNotifier *>(listener);
        dn->addDestructionListener(this);
    }

    void removeListener(ContactsListener *listener)
    {
        listeners.erase(listener);
        DestructionNotifier *dn = static_cast<DestructionNotifier *>(listener);
        dn->removeDestructionListener(this);
    }

    void onDestructed(DestructionNotifier *obj) override
    {
        ContactsListener *l = static_cast<ContactsListener *>(obj);
        listeners.erase(l);
    }
};

static ContactsModel *s_instance = nullptr;

ContactsModel::ContactsModel() :
    d(new Private())
{
    if (!s_instance) {
        s_instance = this;
    }
}

ContactsModel::~ContactsModel()
{
    if (s_instance == this) {
        s_instance = nullptr;
    }
    delete d;
}

void ContactsModel::addListener(ContactsListener *listener)
{
    d->addListener(listener);
}

void ContactsModel::removeListener(ContactsListener *listener)
{
    d->removeListener(listener);
}

void ContactsModel::notifyPresenceChanged(const Presence &p)
{
    for (auto l: d->listeners) {
        l->onPresenceChanged(p);
    }
    if (d->listeners.empty()) {
        QXLOG_ERROR("No ContactsListeners to invoke onPresenceChanged()", nullptr);
    }
}

ContactsModel *ContactsModel::instance()
{
    if (!s_instance) {
        QXLOG_FATAL("s_instance is null, creating new ContactsModel instance to avoid crash", nullptr);
        // TODO: log stack trace
        s_instance = new ContactsModel();
    }
    return s_instance;
}

//void ContactsListener::onContactsChanged(const std::vector<QliqUser>&, int)
//{
//}

void ContactsListener::onPresenceChanged(const Presence &)
{
}

ContactsListener::~ContactsListener()
{
}

} // qx

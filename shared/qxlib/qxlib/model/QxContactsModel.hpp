#ifndef QXCONTACTSMODEL_HPP
#define QXCONTACTSMODEL_HPP
#include <vector>
#include "qxlib/model/QxQliqUser.hpp"

namespace qx {

class ContactsListener;

class ContactsModel
{
public:
    ContactsModel();
    ~ContactsModel();

    void onChatMessageStatusChanged();
    void onChatMessageReceived();

    void addListener(ContactsListener *listener);
    void removeListener(ContactsListener *listener);

    void notifyPresenceChanged(const Presence& p);

    static ContactsModel *instance();

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QXCONTACTSMODEL_HPP

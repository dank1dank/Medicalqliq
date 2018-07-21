#ifndef QX_DESTRUCTIONNOTIFIER_HPP
#define QX_DESTRUCTIONNOTIFIER_HPP
#include <set>

namespace qx {

class DestructionNotifier;

class DestructionListener {
public:
    virtual void onDestructed(DestructionNotifier *obj) = 0;

protected:
    ~DestructionListener();
};

class DestructionNotifier
{
public:
    ~DestructionNotifier();

    void addDestructionListener(DestructionListener *listener);
    void removeDestructionListener(DestructionListener *listener);

    void notifyDestructed();

private:
    // TODO: change to vector of default size of 1
    std::set<DestructionListener *> m_listeners;
};

} // qx

#endif // QX_DESTRUCTIONNOTIFIER_HPP

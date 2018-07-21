#include "QxDestructionNotifier.hpp"

namespace qx {

DestructionNotifier::~DestructionNotifier()
{
    notifyDestructed();
}

void DestructionNotifier::addDestructionListener(DestructionListener *listener)
{
    m_listeners.insert(listener);
}

void DestructionNotifier::removeDestructionListener(DestructionListener *listener)
{
    m_listeners.erase(listener);
}

void DestructionNotifier::notifyDestructed()
{
    for (auto l: m_listeners) {
        l->onDestructed(this);
    }
}

DestructionListener::~DestructionListener()
{
}

} // qx

#include "QxNetworkMonitor.hpp"

namespace qx {

namespace {
NetworkMonitor *s_instance = nullptr;
} // anonymous namespace

NetworkMonitor::NetworkMonitor()
{
    if (!s_instance) {
        s_instance = this;
    }
}

NetworkMonitor::~NetworkMonitor()
{
    if(s_instance == this) {
        s_instance = nullptr;
    }
}

void NetworkMonitor::addListener(NetworkListener *listener)
{
    m_listeners.insert(listener);
}

void NetworkMonitor::removeListener(NetworkListener *listener)
{
    m_listeners.erase(listener);
}

void NetworkMonitor::notifyNetworkChanged(bool isOnline)
{
    for (auto l: m_listeners) {
        l->onNetworkChanged(isOnline);
    }
}

NetworkMonitor *NetworkMonitor::instance()
{
    return s_instance;
}

} // namespace qx

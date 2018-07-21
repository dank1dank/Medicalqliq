#ifndef QX_NETWORKMONITOR_HPP
#define QX_NETWORKMONITOR_HPP
#include <set>

namespace qx {

#ifndef SWIG

class NetworkListener {
public:
    virtual void onNetworkChanged(bool isOnline) = 0;
};

#endif // !SWIG

class NetworkMonitor
{
public:
    NetworkMonitor();
    ~NetworkMonitor();

#ifndef SWIG
    void addListener(NetworkListener *listener);
    void removeListener(NetworkListener *listener);
#endif
    void notifyNetworkChanged(bool isOnline);

    static NetworkMonitor *instance();

private:
    std::set<NetworkListener *> m_listeners;
};

} // namespace qx

#endif // QX_NETWORKMONITOR_HPP

#ifndef QXSESSION_H
#define QXSESSION_H
#include <string>
#include "QxSessionListener.hpp"

namespace qx {

class Session
{
public:
    std::string myQliqId() const;
    void setMyQliqId(const std::string& qliqId);
    std::string myEmail() const;
    void setMyEmail(const std::string& email);
    std::string myDisplayName() const;
    void setMyDisplayName(const std::string& displayName);

    std::string userName() const;
    void setUserName(const std::string& userName);

    std::string password() const;
    std::string passwordWeb() const;
    void setPassword(const std::string& password);

    std::string deviceName() const;
    void setDeviceName(const std::string& deviceName);

    bool isTesterMode() const;
    void setIsTesterMode(bool on);
    void reset();

    std::string dataDirectoryPath();

#ifndef SWIG
    void addListener(SessionListener *listener);
    void removeListener(SessionListener *listener);
#endif
    void notifySessionStarted();
    void notifySessionFinishing();
    void notifySessionFinished();
    void notifyForegroundStatusChanged(bool isForegroundApp);

    static Session& instance();

private:
    Session();
    ~Session();

    struct Private;
    Private *d;
};

} // namespace qx

#endif // QXSESSION_H

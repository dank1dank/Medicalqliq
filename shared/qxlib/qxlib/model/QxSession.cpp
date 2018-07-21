#include "QxSession.hpp"
#include <set>
#include "qxlib/debug/QxAssert.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/crypto/QxBase64.hpp"

std::string qx_Session_dataDirectoryRootPath_impl();

namespace qx {

struct Session::Private {
    std::string myQliqId;
    std::string myEmail;
    std::string myDisplayName;
    std::string userName;
    std::string password;
    bool testerMode;
    std::string deviceName;
    std::set<SessionListener *> listeners;

    Private()
    {
        reset();
    }

    void reset()
    {
        myQliqId.clear();
        myDisplayName.clear();
        testerMode = false;
    }
};

std::string Session::myQliqId() const
{
    qx_assert(!d->myQliqId.empty());
    return d->myQliqId;
}

void Session::setMyQliqId(const std::string &qliqId)
{
    d->myQliqId = qliqId;
}

std::string Session::myEmail() const
{
    qx_assert(!d->myEmail.empty());
    return d->myEmail;
}

void Session::setMyEmail(const std::string &email)
{
    d->myEmail = email;
}

std::string Session::myDisplayName() const
{
    qx_assert(!d->myDisplayName.empty());
    return d->myDisplayName;;
}

void Session::setMyDisplayName(const std::string &displayName)
{
    d->myDisplayName = displayName;
}

std::string Session::userName() const
{
    return d->userName;
}

void Session::setUserName(const std::string& userName)
{
    d->userName = userName;
}

void Session::setPassword(const std::string &password)
{
    d->password = password;
}

std::string Session::password() const
{
    return d->password;
}

std::string Session::passwordWeb() const
{
    std::string base64;
    qx::base64::encode(d->password.c_str(), d->password.size(), &base64);
    return base64;
}

std::string Session::deviceName() const
{
    qx_assert(!d->deviceName.empty());
    return d->deviceName;
}

void Session::setDeviceName(const std::string &deviceName)
{
    d->deviceName = deviceName;
}

bool Session::isTesterMode() const
{
    return d->testerMode;
}

void Session::setIsTesterMode(bool on)
{
    d->testerMode = on;
    if (on) {
        QXLOG_SUPPORT("Tester Mode is enabled", nullptr);
    }
}

void Session::reset()
{
    d->reset();
}

std::string Session::dataDirectoryPath()
{
    return Filesystem::join(qx_Session_dataDirectoryRootPath_impl(), d->myQliqId);
}

void Session::addListener(SessionListener *listener)
{
    d->listeners.insert(listener);
}

void Session::removeListener(SessionListener *listener)
{
    d->listeners.erase(listener);
}

void Session::notifySessionStarted()
{
    for (auto l: d->listeners) {
        l->onSessionStarted();
    }
}

void Session::notifySessionFinishing()
{
    for (auto l: d->listeners) {
        l->onSessionFinishing();
    }
}

void Session::notifySessionFinished()
{
    for (auto l: d->listeners) {
        l->onSessionFinished();
    }
}

void Session::notifyForegroundStatusChanged(bool isForegroundApp)
{
    for (auto l: d->listeners) {
        l->onForegroundStatusChanged(isForegroundApp);
    }
}

Session &Session::instance()
{
    static Session s;
    return s;
}

Session::Session() :
    d(new Private())
{
}

Session::~Session()
{
    delete d;
}

SessionListener::~SessionListener()
{
}

void SessionListener::onSessionStarted()
{
}

void SessionListener::onSessionFinishing()
{
}

void SessionListener::onSessionFinished()
{
}

void SessionListener::onForegroundStatusChanged(bool /*isForegroundApp*/)
{
}

} // namespace qx

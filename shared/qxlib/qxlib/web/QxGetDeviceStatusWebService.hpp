#ifndef QXGETDEVICESTATUS_HPP
#define QXGETDEVICESTATUS_HPP
#include <string>
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/log/QxLog.hpp"

namespace qx {

struct DeviceStatus {
    enum class LockState {
        Unlocked,
        Locked
    };
    enum class WipeState {
        None,
        Wiped
    };

    LockState lockState = LockState::Unlocked;
    WipeState wipeState = WipeState::None;
    bool isBatterySaveMode = false;
    LogConfig logConfig;
};

namespace web {

class GetDeviceStatusWebService : public BaseWebService
{
public:
    GetDeviceStatusWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error, const DeviceStatus& deviceStatus)> ResultFunction;
    void call(ResultFunction ResultFunction);

    static void processResponse(const std::string& json);
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error, const DeviceStatus& deviceStatus) = 0;
    };
    void call(ResultCallback *callback);

private:
    static void handleResponse(const QliqWebError& error, const json11::Json& json, const ResultFunction& callback);
};

} // web
} // qx

#endif // QXGETDEVICESTATUS_HPP

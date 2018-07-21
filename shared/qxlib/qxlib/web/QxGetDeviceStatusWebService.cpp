#include "QxGetDeviceStatusWebService.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/db/QxLogDatabase.hpp"
#include "qxlib/util/QxSettings.hpp"

// Helper method to be used by ObjC GetDeviceStatusService
extern "C" void qx_GetDeviceStatusWebService_processResponse(const char *json)
{
    qx::web::GetDeviceStatusWebService::processResponse(json);
}

namespace qx {
namespace web {

GetDeviceStatusWebService::GetDeviceStatusWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void GetDeviceStatusWebService::call(GetDeviceStatusWebService::ResultFunction ResultFunction)
{
    using namespace json11;

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/get_device_status", Json(), [this,ResultFunction](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, ResultFunction);
    });
}

void GetDeviceStatusWebService::processResponse(const std::string &json)
{
    using namespace json11;
    std::string errorMessage;
    Json jsonObject = Json::parse(json, errorMessage);
    jsonObject = jsonObject["Message"]["Data"];
    GetDeviceStatusWebService::handleResponse(QliqWebError(), jsonObject, [](const QliqWebError&, const DeviceStatus&) {
    });
}

void GetDeviceStatusWebService::call(GetDeviceStatusWebService::ResultCallback *callback)
{
    call([callback](const QliqWebError& error, const DeviceStatus& deviceStatus) {
        callback->run(new QliqWebError(error), deviceStatus);
    });
}

void GetDeviceStatusWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const GetDeviceStatusWebService::ResultFunction &callback)
{
    DeviceStatus deviceStatus;
    if (!error) {
        std::string str = json["lock_state"].string_value();
        if (str == "locked" || str == "locking") {
            deviceStatus.lockState = DeviceStatus::LockState::Locked;
        }

        str = json["wipe_state"].string_value();
        if (/*str == "wiped" ||*/ str == "wiping") {
            deviceStatus.wipeState = DeviceStatus::WipeState::Wiped;
        }

        int logLevel = json["log_level"].int_value();
        if (static_cast<int>(LogLevel::Normal) <= logLevel && logLevel <= static_cast<int>(LogLevel::Debug)) {
            deviceStatus.logConfig.logLevel = static_cast<LogLevel>(logLevel);
        }

        if (json.object_items().count("logdb_enabled") > 0) {
            deviceStatus.logConfig.isLogDatabaseEnabled = json["logdb_enabled"].bool_value();
        }

        LogConfig::save(deviceStatus.logConfig);
    }

    if (callback) {
        callback(error, deviceStatus);
    }
}

} // web
} // qx

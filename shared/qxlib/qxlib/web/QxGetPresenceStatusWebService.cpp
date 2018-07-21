#include "QxGetPresenceStatusWebService.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/dao/QxQliqUserDao.hpp"
#include "qxlib/model/QxContactsModel.hpp"

namespace qx {
namespace web {

GetPresenceStatusWebService::GetPresenceStatusWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void GetPresenceStatusWebService::call(const std::string &qliqId, ResultFunction resultFunction, BaseWebService::IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json json = Json::object {
        {"qliq_id", qliqId}
    };

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/get_presence_status", json, [resultFunction](const QliqWebError& error, const json11::Json& json) {
        Presence result;
        bool changed = false;
        if (!error) {
            changed = processPresenceData(json, "", &result);
        }
        if (resultFunction) {
            resultFunction(error, result);
        }
    }, "", "", isCancelledFun);
}

bool GetPresenceStatusWebService::processPresenceData(const json11::Json &json, const std::string &userUpdateReason, Presence *result)
{
    result->qliqId = json["qliq_id"].string_value();
    result->status = Presence::statusFromString(json["presence_status"].string_value());
    result->message = json["presence_message"].string_value();
    result->forwardToQliqId = json["forwarding_qliq_id"].string_value();
    bool changed = QliqUserDao::updatePresence(*result);
    if (changed) {
        // TODO: possible design issue
        // lower level class GetPresenceStatusWebService calls higher level ContactsModel
        // should this be inverted?
        ContactsModel::instance()->notifyPresenceChanged(*result);
    } else {
        QXLOG_WARN("Skipping presence change notification because new value equals db value for qliq id: %s", result->qliqId.c_str());
    }
    return changed;
}

} // web
} // qx

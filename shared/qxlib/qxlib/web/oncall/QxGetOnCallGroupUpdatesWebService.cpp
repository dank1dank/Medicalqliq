#include "QxGetOnCallGroupUpdatesWebService.hpp"
#include "qxlib/dao/oncall/QxOnCallGroupsDao.hpp"

namespace qx {
namespace web {

void GetOnCallGroupUpdatesWebService::call(const GetOnCallGroupUpdatesWebService::ResultCallback &resultCallback)
{
    using namespace json11;
    Json::array array;

    for (const auto& g: qx::OnCallGroupsDao::selectAll()) {
        Json::object obj;
        obj["qliq_id"] = g.qliqId;
        obj["last_updated_epoch"] = g.lastUpdatedOnServer;
        array.push_back(obj);
    }

    Json json = Json::object {
        {"reason", "view-oncall"},
        {"oncall_groups", array}
    };

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/get_oncall_group_updates", json, [this,resultCallback](const QliqWebError& error, const Json& json) {
        for (const auto& jsonItem: json.array_items()) {

        }
        handleResponse(error, json, resultCallback);
    });
}

void GetOnCallGroupUpdatesWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const GetOnCallGroupUpdatesWebService::ResultCallback &resultCallback)
{

}

} // web
} // qx

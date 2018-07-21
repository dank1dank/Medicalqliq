#include "QxAssemblaGetUsersWebService.hpp"

namespace qx {
namespace web {

AssemblaGetUsersWebService::AssemblaGetUsersWebService(WebClient *webClient) :
    BaseWebService(webClient)
{}

void AssemblaGetUsersWebService::call(AssemblaGetUsersWebService::ResultCallback resultCallback, BaseWebService::IsCancelledFunction isCancelledFun)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/users.json";
    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    m_webClient->getJsonUrl(url, headers, [this,resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, resultCallback);
    }, isCancelledFun);
}

void AssemblaGetUsersWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const AssemblaGetUsersWebService::ResultCallback &resultCallback)
{
    std::vector<AssemblaUser> users;
    if (!error) {
        for (const auto& jsonObj: json.array_items()) {
            AssemblaUser u = AssemblaUser::fromJson(jsonObj);
            if (!u.isEmpty()) {
                users.push_back(u);
            }
        }
    }
    resultCallback(error, users);
}

} // web
} // qx

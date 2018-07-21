#include "QxAssemblaTicketsMyActiveWebService.hpp"

namespace qx {
namespace web {

AssemblaTicketsMyActiveWebService::AssemblaTicketsMyActiveWebService(qx::web::WebClient *webClient) :
    BaseWebService(webClient)
{}

void AssemblaTicketsMyActiveWebService::call(AssemblaTicketsMyActiveWebService::ResultCallback resultCallback, BaseWebService::IsCancelledFunction isCancelledFun)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/tickets/my_active.json";
    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    m_webClient->getJsonUrl(url, headers, [this,resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, resultCallback);
    }, isCancelledFun);
}

void AssemblaTicketsMyActiveWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const AssemblaTicketsMyActiveWebService::ResultCallback &resultCallback)
{
    std::vector<AssemblaTicket> tickets;
    if (!error) {
        for (const auto& jsonObj: json.array_items()) {
            AssemblaTicket t = AssemblaTicket::fromJson(jsonObj);
            if (!t.isEmpty()) {
                tickets.push_back(t);
            }
        }
    }
    resultCallback(error, tickets);
}

} // web
} // qx

#include "QxAssemblaTicketsWebService.hpp"
#include "qxlib/util/StringUtils.hpp"

namespace qx {
namespace web {

AssemblaTicketsWebService::AssemblaTicketsWebService(qx::web::WebClient *webClient) :
    AssemblaBaseWebService(webClient)
{}

void AssemblaTicketsWebService::create(const AssemblaTicket &ticket, TicketResultCallback resultCallback, IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json json = Json::object {
        {"ticket", ticket.toJson()}
    };

    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/tickets.json";
    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    m_webClient->postJsonRequestToUrl(url, json, headers, [resultCallback](const QliqWebError& error, const json11::Json& json) {
        // Location is a 'Location' HTTP header in response, which is inaccessible by current qxlib API

        AssemblaTicket ticket;
        if (!error) {
            ticket = AssemblaTicket::fromJson(json);
        }
        resultCallback(error, ticket);

    }, isCancelledFun);
}

void AssemblaTicketsWebService::ticketByNumber(int number, TicketResultCallback resultCallback)
{
    const std::string path ="/tickets/" + std::to_string(number) + ".json";
    getJsonPath(path, [this, resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleTicketResponse(error, json, resultCallback);
    });
}

void AssemblaTicketsWebService::ticketById(int id, AssemblaTicketsWebService::TicketResultCallback resultCallback)
{
    const std::string path ="/tickets/id/" + std::to_string(id) + ".json";
    getJsonPath(path, [this, resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleTicketResponse(error, json, resultCallback);
    });
}

void AssemblaTicketsWebService::tickets(const Params& params, TicketsResultCallback resultCallback, IsCancelledFunction isCancelledFun)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/tickets.json";
    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    std::vector<std::string> paramsVec;
    if (params.report) {
        paramsVec.emplace_back("report=" + std::to_string(static_cast<int>(params.report.value())));
    }
    if (params.page) {
        paramsVec.emplace_back("page=" + std::to_string(params.page.value()));
    }
    if (params.perPage) {
        paramsVec.emplace_back("per_page=" + std::to_string(params.perPage.value()));
    }
    if (params.sortOrder) {
        paramsVec.emplace_back("sort_order=" + std::to_string(static_cast<int>(params.sortOrder.value())));
    }
    std::string queryPart;
    if (!paramsVec.empty()) {
        queryPart = "?" + StringUtils::join(paramsVec, "&");
    }

    m_webClient->getJsonUrl(url + queryPart, headers, [this,resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleTicketsResponse(error, json, resultCallback);
    }, isCancelledFun);
}

void AssemblaTicketsWebService::delete_(int number, DeleteResultCallback resultCallback)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/tickets/" + std::to_string(number) + ".json";
    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    m_webClient->jsonRequestToUrl(WebClient::HttpMethod::Delete, url, {}, headers, [resultCallback](const QliqWebError& error, const json11::Json& json) {
        resultCallback(error);
    });
}

void AssemblaTicketsWebService::delete_(const AssemblaTicket &ticket, DeleteResultCallback resultCallback)
{
    return delete_(ticket.number, resultCallback);
}

void AssemblaTicketsWebService::handleTicketsResponse(const QliqWebError &error, const json11::Json &json, const TicketsResultCallback &resultCallback)
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

void AssemblaTicketsWebService::handleTicketResponse(const QliqWebError &error, const json11::Json &json, const TicketResultCallback &resultCallback)
{
    AssemblaTicket ticket;
    if (!error) {
        ticket = AssemblaTicket::fromJson(json);
    }
    resultCallback(error, ticket);
}

} // web
} // qx

#include "QxAssemblaBaseWebService.hpp"

namespace qx {
namespace web {

AssemblaBaseWebService::AssemblaBaseWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void AssemblaBaseWebService::getJsonPath(const std::string &path, WebClient::JsonCallback callback)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + path;
    std::map<std::string, std::string> headers;
    insertApiHeaders(&headers);

    m_webClient->getJsonUrl(url, headers, callback);
}

void AssemblaBaseWebService::insertApiHeaders(std::map<std::string, std::string> *headers)
{
    (*headers)["X-Api-Key"] = AssemblaConfig::apiKey();
    (*headers)["X-Api-Secret"] = AssemblaConfig::apiSecret();
}

} // web
} // qx

#include "QxWebClient.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/debug/QxAssert.hpp"
#include "qxlib/web/QxDatabaseWebClient.hpp"

namespace qx {
namespace web {

namespace {
WebClient *s_defaultInstance = nullptr;
}

WebClient::WebClient()
{}

WebClient::~WebClient()
{
    if (s_defaultInstance == this) {
        s_defaultInstance = nullptr;

        // TODO: maybe find a better place to delete
        delete DatabaseWebClient::defaultInstance();
        DatabaseWebClient::setDefaultInstance(nullptr);
    }
}

void WebClient::postMultipartRequestToUrl(const std::string&, const std::vector<WebClient::MultipartFormData>&, const std::map<std::string, std::string>&, WebClient::JsonCallback, WebClient::IsCancelledFunction)
{
    QXLOG_FATAL("WebClient::postMultipartRequestToUrl is not implemented for this platform!", nullptr);
}

void WebClient::onRequestFinished(int networkError, int httpStatus)
{
    if (this == s_defaultInstance) {
        DatabaseWebClient::defaultInstance()->onRequestFinished(networkError, httpStatus);
    }
}

WebClient *WebClient::defaultInstance()
{
    return s_defaultInstance;
}

void WebClient::setDefaultInstance(WebClient *wc)
{
    s_defaultInstance = wc;

    if (wc) {
        // TODO: maybe find a better place to instantiate
        auto dbWebClient = new DatabaseWebClient(wc);
        DatabaseWebClient::setDefaultInstance(dbWebClient);
    } else {
        auto dbWebClient = DatabaseWebClient::defaultInstance();
        if (dbWebClient) {
            delete dbWebClient;
        }
    }
}

bool WebClient::isCancelled(const WebClient::IsCancelledFunction &isCancelledFun)
{
    return isCancelledFun && isCancelledFun();
}
    
void WebClient::handlePostJsonResponse(int networkError, const std::string& networkErrorMessage,
                                       int httpStatus, const std::string& responseBody,
                                       const WebClient::JsonCallback &callback, const IsCancelledFunction& isCancelledFun)
{
    if (isCancelled(isCancelledFun)) {
        QXLOG_WARN("Ignoring response because the request was cancelled", nullptr);
        return;
    }

    QliqWebError qwe(networkError != 0 ? networkError : httpStatus);
    qwe.message = networkErrorMessage;
    
    std::string parsingError;
    json11::Json finalJson;
    json11::Json json = json11::Json::parse(responseBody, parsingError);
    
    if (httpStatus == 200) {
        finalJson = json["Message"]["Data"];
        if (finalJson.is_null()) {
            finalJson = json["Message"]["Error"];
            if (!finalJson.is_null()) {
                // error_code should be number but webserver sends as string
                auto errorCodeJson = finalJson["error_code"];
                if (errorCodeJson.is_number()) {
                    qwe.code = errorCodeJson.int_value();
                } else {
                    qwe.code = std::stoi(errorCodeJson.string_value());
                }
                qwe.message = finalJson["error_msg"].string_value();
                finalJson = json11::Json();
            }
        }
    }
    callback(qwe, finalJson);

    onRequestFinished(networkError, httpStatus);
}

////////////////////////////////////////////////////////////////////////////////
/// BaseWebService
///
BaseWebService::BaseWebService(WebClient *webClient) :
    m_webClient(webClient)
{
    if (!m_webClient) {
        m_webClient = WebClient::defaultInstance();
    }
    qx_assert(m_webClient != nullptr);
}

////////////////////////////////////////////////////////////////////////////////
/// IsCancelledFunctor
///
IsCancelledFunctor::~IsCancelledFunctor()
{}

bool IsCancelledFunctor::operator()() const
{
    return false;
}

WebClient::MultipartFormData::MultipartFormData(const std::string &name, const std::string &value, const std::string& fileName) :
    name(name), body(value), fileName(fileName)
{
}

} // web
} // qx

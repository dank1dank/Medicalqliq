#include "QxAssemblaDocumentsWebService.hpp"
#include <cstring>

#define ADD_NON_EMPTY(key, field) if (!document.field.empty()) { formData.push_back({"document[" key "]", document.field}); }

using namespace json11;

namespace qx {
namespace web {

AssemblaDocumentsWebService::AssemblaDocumentsWebService(WebClient *webClient) :
    BaseWebService(webClient)
{}

void AssemblaDocumentsWebService::call(const AssemblaDocument &document, ResultCallback resultCallback, const std::string& folderName, IsCancelledFunction isCancelledFun)
{
    std::string url = AssemblaConfig::baseUrlWithNamespace() + "/documents.json";
    url.erase(0, std::strlen("https://api"));
    url = "https://bigfiles" + url;

    std::string attachableType = AssemblaDocument::toString(document.attachableType);
    std::vector<WebClient::MultipartFormData> formData;
    if (!attachableType.empty()) {
        formData.push_back({"document[attachable_type]", attachableType});
        ADD_NON_EMPTY("attachable_guid", attachableGuid);
        if (document.attachableId != 0) {
            formData.push_back({"document[attachable_id]", std::to_string(document.attachableId)});
        }
    }
    if (!document.file.empty() || !document.filePath.empty()) {
        WebClient::MultipartFormData fileData;
        fileData.name = "document[file]";
        fileData.fileName = document.fileName;
        if (!document.file.empty()) {
            fileData.body = document.file;
        } else {
            fileData.filePath = document.filePath;
        }
        formData.emplace_back(fileData);
    }
    ADD_NON_EMPTY("filename", fileName);
    ADD_NON_EMPTY("name", name);
    ADD_NON_EMPTY("description", description);
    if (document.position != 0) {
        formData.push_back({"document[position]", std::to_string(document.position)});
    }
    if (!folderName.empty()) {
        formData.push_back({"folder_name", folderName});
    }

    std::map<std::string, std::string> headers;
    headers["X-Api-Key"] = AssemblaConfig::apiKey();
    headers["X-Api-Secret"] = AssemblaConfig::apiSecret();

    m_webClient->postMultipartRequestToUrl(url, formData, headers, [this,resultCallback](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, resultCallback);
    }, isCancelledFun);
}

void AssemblaDocumentsWebService::handleResponse(const QliqWebError &error, const Json &json, const AssemblaDocumentsWebService::ResultCallback &resultCallback)
{
    // Location is a 'Location' HTTP header in response, which is inaccessible by current qxlib API

    AssemblaDocument document;
    if (!error) {
        document = AssemblaDocument::fromJson(json);
    }
    resultCallback(error, document);
}

} // web
} // qx

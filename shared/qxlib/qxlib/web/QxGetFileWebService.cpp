#include "QxGetFileWebService.hpp"
#include "qxlib/util/QxFilesystem.hpp"

namespace qx {
namespace web {

GetFileWebService::GetFileWebService(qx::web::WebClient *webClient) :
    BaseWebService(webClient)
{

}

void GetFileWebService::call(const std::string &serverFileName, const std::string& savedFilePath, GetFileWebService::ResultFunction resultFunction, BaseWebService::IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json json = Json::object {
        {"file_name", serverFileName}
    };

    m_webClient->postJsonRequest(WebClient::FileServer, "/services/get_file", json, [savedFilePath,resultFunction](const QliqWebError& errorArg, const json11::Json& /*jsonArg*/) {
        QliqWebError error = errorArg;
        if (!error) {
            // If there is an error (file not found, server error) then webserver will still
            // return 200 OK and the error will be send as JSON body
            // so there is no way to tell if that is file content or error JSON

            FileInfo fi(savedFilePath);
            auto fileSize = fi.size();
            if (0 < fileSize && fileSize < 500) {
                // if file is small we try to parse is as JSON
                std::string body = Filesystem::readWholeFile(savedFilePath);

                std::string parsingError;
                json11::Json json = json11::Json::parse(body, parsingError);
                if (parsingError.empty()) {
                    json = json["Message"]["Error"];
                    if (!json.is_null()) {
                        // error_code should be number but webserver sends as string
                        auto errorCodeJson = json["error_code"];
                        if (errorCodeJson.is_number()) {
                            error.code = errorCodeJson.int_value();
                        } else {
                            error.code = std::stoi(errorCodeJson.string_value());
                        }
                        error.message = json["error_msg"].string_value();
                    }
                }
            }
        }
        resultFunction(error, savedFilePath);
    }, savedFilePath, serverFileName, isCancelledFun);
}

void GetFileWebService::call(const std::string &serverFileName, const std::string &savedFilePath, GetFileWebService::ResultCallback *callback)
{
    call(serverFileName, savedFilePath, [callback](const QliqWebError& error, const std::string& savedFilePath2) {
        callback->run(new web::QliqWebError(error), savedFilePath2);
    });
}

GetFileWebService::ResultCallback::~ResultCallback()
{
}

} // web
} // qx

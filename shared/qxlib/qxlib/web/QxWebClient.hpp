#ifndef QXWEBCLIENT_HPP
#define QXWEBCLIENT_HPP
#include <functional>
#include "json11/json11.hpp"
#include "qxlib/web/QxQliqWebError.hpp"

namespace qx {
namespace web {

#ifndef SWIG
class IsCancelledFunctor {
public:
    virtual ~IsCancelledFunctor();

    virtual bool operator()() const;
};
#endif // !SWIG

/**
 * @brief The WebClient class is a small interface around native platform HTTP implementation
 */
class WebClient
{
protected:
    WebClient();
    virtual ~WebClient();

public:
    enum class HttpMethod {
        Get,
        Put,
        Post,
        Delete
    };

    enum ServerType {
        RegularServer,
        FileServer
    };

#ifndef SWIG
    /// \brief Callback function to process JSON result
    ///
    /// \param error will contain network, http or qliq JSON error
    /// \param json will be Message.Data or empty in case of error
    typedef std::function<void(const QliqWebError& error, const json11::Json& json)> JsonCallback;

    /// \brief Optional function that returns true to cancel handling of response
    ///
    /// It is used when the caller may be already destroyed by the time response is received.
    /// This can happen in UI when user closes window or changes screen while request is still pending.
    typedef std::function<bool()> IsCancelledFunction;

    struct MultipartFormData {
        // Required fields
        std::string name;
        std::string body;
        // Optional fields
        std::string contentType;
        std::string fileName;
        /// if specified then 'body' is ignored and the data is read from 'filePath' file
        /// however 'fileName' is not derrived from this field
        std::string filePath;

        MultipartFormData() = default;
        MultipartFormData(const std::string& name, const std::string& value, const std::string& fileName = {});
    };

    /// JSON request to qliq webserver (based on path), response is extracted Message.Data
    virtual void postJsonRequest(ServerType serverType, const std::string& serverPath, const json11::Json& json,
                                 JsonCallback callback, const std::string& downloadFilePath = {}, const std::string& downloadUuid = {},
                                 IsCancelledFunction isCancelledFun = {}) = 0;

    /// JSON request to any webserver (url based), response is original parsed JSON
    virtual void postJsonRequestToUrl(const std::string& url, const json11::Json& json, const std::map<std::string, std::string>& extraHeaders,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) = 0;

    /// JSON request to any webserver (url based), response is original parsed JSON
    virtual void jsonRequestToUrl(HttpMethod method, const std::string& url, const json11::Json& json, const std::map<std::string, std::string>& extraHeaders,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) = 0;

    /// Multipart JSON request to qliq webserver (based on path), response is extracted Message.Data
    virtual void postMultipartRequest(ServerType serverType, const std::string& serverPath, const json11::Json& json,
                                      const std::string& fileMimeType, const std::string& fileName, const std::string& filePath,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) = 0;

    /// Multipart JSON request to any webserver (url based), response is original parsed JSON
    virtual void postMultipartRequestToUrl(const std::string& url, const std::vector<MultipartFormData>& parts, const std::map<std::string, std::string>& extraHeaders,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    /// Request to any webserver (url based) with a parsed JSON response
    virtual void getJsonUrl(const std::string& url, const std::map<std::string, std::string>& extraHeaders,
                            JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) = 0;

    void onRequestFinished(int networkError, int httpStatus);

    static WebClient *defaultInstance();
    static void setDefaultInstance(WebClient *wc);
    
    /// Helper that will execute the function if non empty and return result
    static bool isCancelled(const IsCancelledFunction& isAlive);
#endif // !SWIG
protected:
    /// Per platform implementation should call this method to parse response
    void handlePostJsonResponse(int networkError, const std::string& networkErrorMessage,
                                int httpStatus, const std::string& responseBody,
                                const JsonCallback& callback, const IsCancelledFunction& isCancelledFun);
};

/**
 * @brief The BaseWebService class is a base class for web services.
 *
 * The class contains pointer to a WebClient so it is possible to configure
 * it with a different WebClient for background threads.
 *
 * The rest of functionality is specific to each subclass as each service
 * has different input/output data.
 */
class BaseWebService {
public:
    typedef WebClient::IsCancelledFunction IsCancelledFunction;
protected:
    BaseWebService(WebClient *webClient = nullptr);
    virtual ~BaseWebService() {}

    WebClient *m_webClient;
};

} // web
} // qx

#endif // QXWEBCLIENT_HPP

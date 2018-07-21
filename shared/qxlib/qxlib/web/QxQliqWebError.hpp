#ifndef QXQLIQWEBERROR_HPP
#define QXQLIQWEBERROR_HPP
#include <string>
#include <system_error>

namespace qx {
namespace web {

#ifndef SWIG

// When working with web services there are 4 possible error domains (sources):
// 1. Network error - cannot transmit request or response
// 2. Http error - either client (non authorized) or server error
// 3. Json parsing error - not parsable json or not matching schema
// 4. Qliq server error - web app error code in 'Error' object of json response
// 5. Qliq app error - request or response cannot be processed due to bug in code

enum class NetworkError {

};

enum class HttpStatusCode {
    Ok = 200,
    InternalServerError = 500,
};

enum class JsonParsingError {
    ParsingFailed = 1,
    InvalidSchema = 2,
};

enum class QliqServerErrorCode {
    JsonSchemaValidationFailed = 99,
    InvalidCredentials = 100,
    EnforceVersionUpgrade = 101,
    MiscIssue = 102,
    ClientHasStaleData = 103,
    NotContactAnymore = 104,
    NotMemberOfGroup = 105,
    PublicKeyNotSet = 106,
    AccessDenied = 107,
    NoUpdateSinceLastUpdatedEpoch = 110,
    // Server errors
    ServerUpgradeInProgress = 503,
};

enum class QliqAppErrorCode {
    RemoteWipe = 1001,
};

class WebServiceError {
public:
    std::error_code errorCode;
    std::string message;

    std::string toString() const;
};
#endif // !SWIG

class QliqWebError {
public:
    enum CustomErrorCode {
        ApplicationError = 999999,
        SubError = 999998
    };

    int networkErrorOrHttpStatus;
    int code;
    std::string message;

    QliqWebError(int networkErrorOrHttpStatus = 200);
    QliqWebError(int code, const std::string& message);
    QliqWebError(const std::string& message, const QliqWebError& reasonError);

#ifndef SWIG
    operator bool() const { return isError(); }
#endif
    bool isError() const { return code != 0 || (networkErrorOrHttpStatus != 0 && networkErrorOrHttpStatus / 100 != 2); }
    int jsonError() const;
    int networkError() const;
    int httpStatus() const;

    void setNetworkError(int error);
    void setHttpStatus(int status);

    std::string toString() const;
    //static QliqWebError fromMap(const QVariantMap& map);
    static QliqWebError applicationError(const std::string& message);
    static QliqWebError fromMessage(const std::string& message);
};

} // web
} // qx

namespace std {
    template <>
    struct is_error_code_enum<qx::web::NetworkError> : true_type {};

    template <>
    struct is_error_code_enum<qx::web::HttpStatusCode> : true_type {};

    template <>
    struct is_error_code_enum<qx::web::JsonParsingError> : true_type {};

    template <>
    struct is_error_code_enum<qx::web::QliqServerErrorCode> : true_type {};

    template <>
    struct is_error_code_enum<qx::web::QliqAppErrorCode> : true_type {};
}

#endif // QXQLIQWEBERROR_HPP

//#include "qxlib/web/QxQliqWebError.hpp"
#include "QxQliqWebError.hpp"

namespace qx {
namespace web {

QliqWebError::QliqWebError(int networkErrorOrHttpStatus) :
    networkErrorOrHttpStatus(networkErrorOrHttpStatus), code(0)
{}

QliqWebError::QliqWebError(int code, const std::string& message) :
    networkErrorOrHttpStatus(200), code(code), message(message)
{}

QliqWebError::QliqWebError(const std::string &message, const QliqWebError &reasonError) :
    networkErrorOrHttpStatus(SubError), code(0)
{
    this->message = message + ": " + reasonError.toString();
}

int QliqWebError::jsonError() const
{
    return code;
}

int QliqWebError::networkError() const
{
    if (networkErrorOrHttpStatus < 0) {
        return networkErrorOrHttpStatus;
    } else {
        return 0;
    }
}

int QliqWebError::httpStatus() const
{
    if (networkErrorOrHttpStatus > 0) {
        return networkErrorOrHttpStatus;
    } else {
        return 0;
    }
}

void QliqWebError::setNetworkError(int error)
{
    networkErrorOrHttpStatus = -error;
}

void QliqWebError::setHttpStatus(int status)
{
    networkErrorOrHttpStatus = status;
}

std::string QliqWebError::toString() const
{
    if (isError()) {
        std::string msg = message;

        if (code != 0) {
            if (msg.empty()) {
                msg = "JSON error";
            }
            msg += " (code " + std::to_string(code) + ")";
        } else {
            if (msg.empty()) {
                if (httpStatus() > 0) {
                    msg = "HTTP error: " + std::to_string(httpStatus());
                } else {
                    msg = "Network error: " + std::to_string(networkError());
                }
            }
        }

        return msg;
    } else {
        return "Success";
    }
}

QliqWebError QliqWebError::applicationError(const std::string &message)
{
    QliqWebError ret(ApplicationError);
    ret.message = "Application error: " + message;
    return ret;
}

QliqWebError QliqWebError::fromMessage(const std::string &message)
{
    QliqWebError ret(ApplicationError);
    ret.message = message;
    return ret;
}

/*
QliqWebError QliqWebError::fromMap(const QVariantMap &map)
{
    QliqWebError err;

    if (map.contains("Error")) {
        const QVariantMap& map2 = map.value("Error").toMap();
        err.code = map2.value("error_code").toInt();
        err.message = map2.value("error_msg").toString();

    } else {
        err.code = map.value("error_code").toInt();
        err.message = map.value("error_msg").toString();
    }

    return err;
}
*/
} // web
} // qx

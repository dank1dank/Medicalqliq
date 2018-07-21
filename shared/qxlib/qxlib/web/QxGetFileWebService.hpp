#ifndef QXGETFILEWEBSERVICE_HPP
#define QXGETFILEWEBSERVICE_HPP
#include "qxlib/web/QxWebClient.hpp"

namespace qx {
namespace web {

class GetFileWebService : public BaseWebService
{
public:
    GetFileWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error, const std::string& savedFilePath)> ResultFunction;
    void call(const std::string& serverFileName, const std::string& savedFilePath, ResultFunction ResultFunction, IsCancelledFunction isCancelledFun = IsCancelledFunction());
#endif // !SWIG

    class ResultCallback {
    public:
            virtual ~ResultCallback();
            virtual void run(QliqWebError *error, const std::string& savedFilePath) = 0;
    };
    void call(const std::string& serverFileName, const std::string& savedFilePath, ResultCallback *callback);
};

} // web
} // qx

#endif // QXGETFILEWEBSERVICE_HPP

#ifndef QX_WEBLOGRECORD_H
#define QX_WEBLOGRECORD_H
#include <string>
#include <ctime>

namespace qx {

struct WebLogRecord {

    enum HttpMethod {
        NoneHttpMethod = 0,
        GetHttpMethod = 1,
        PostHttpMethod = 2,
        PutHttpMethod = 3,
        DeleteHttpMethod = 4
    };

    int id; // database id
    int module = 0;
    std::time_t session;
    int sequenceId;
    std::time_t time;
    HttpMethod method;
    std::string url;
    int responseCode;
    int duration;
    int jsonError;
    std::string request;
    std::string response;

    WebLogRecord();
};

} // namespace qx

#endif // QX_WEBLOGRECORD_H

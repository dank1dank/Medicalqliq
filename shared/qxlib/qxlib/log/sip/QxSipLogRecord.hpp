#ifndef QXSIPLOGRECORD_H
#define QXSIPLOGRECORD_H
#include <string>
#include <ctime>

namespace qx {

struct SipLogRecord {
    enum Direction {
        Inbound,
        Outbound
    };
    enum DecryptionStatus {
        UnknownDecryptionStatus = 0,
        PlainTextDecryptionStatus = 1,
        DecryptedDecryptionStatus = 2,
        PendingDecryptionStatus = 3,
        PermanentErrorDecryptionStatus = 4
    };

    int id; // database id
    std::time_t session;
    int sequenceId;
    std::time_t time;
    Direction direction;
    std::string method;
    std::string from;
    std::string to;
    std::string callId;
    std::string cseq;
    int statusCode;
    int duration;
    std::string request;
    std::string plainTextRequestBody;
    std::string response;
    DecryptionStatus decryptionStatus;

    SipLogRecord();
};

} // namespace qx

#endif // QXSIPLOGRECORD_H

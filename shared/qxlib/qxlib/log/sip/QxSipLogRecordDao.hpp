#ifndef QX_SIPLOGRECORDDAO_H
#define QX_SIPLOGRECORDDAO_H
#include <functional>
#include "qxlib/log/QxDbLogRecordBaseDao.hpp"
#include "qxlib/log/sip/QxSipLogRecord.hpp"
#include "qxlib/db/QxLogDatabase.hpp"

namespace qx {

class SipLogRecordDao : public DbLogRecordBaseDao<SipLogRecord>
{
public:
    enum Column {
        IdColumn,
        SessionColumn,
        SequenceIdColumn,
        TimeColumn,
        DirectionColumn,
        MethodColumn,
        FromColumn,
        ToColumn,
        CallIdColumn,
        CseqColumn,
        StatusCodeColumn,
        DurationColumn,
        RequestColumn,
        ResponseColumn,
        PlainTextRequestColumn,
        DecryptionStatusColumn,
    };
    typedef std::function<bool(const char *privKey, const char *encrypted, std::string *decrypted)> DecryptionCallback;

    static bool parse(qx::SipLogRecord *record, const char *msg, std::size_t msgLen, SipLogRecord::Direction direction, bool isRequest, const char *plainText = nullptr);
    static bool save(const qx::SipLogRecord& record, bool isRequest, SQLite::Database& db = LogDatabase::database());
    static int parseAndSave(const char *msg, std::size_t msgLen, SipLogRecord::Direction direction, bool isRequest, const char *plainText = nullptr, SQLite::Database& db = LogDatabase::database());
    static bool decryptMessagesWithNewKey(const char *privKey, const char *xhash, const char *qliqId, DecryptionCallback decryptionCallback, SQLite::Database& db = LogDatabase::database());
    static bool updateDebugExtra(const std::string& callId, const std::string& cseq, const std::string& debugExtra, SQLite::Database& db = LogDatabase::database());

private:
    static bool updateResponse(const qx::SipLogRecord &obj, SQLite::Database& db = LogDatabase::database());
};

} // namespace qx

#endif // QX_SIPLOGRECORDDAO_H

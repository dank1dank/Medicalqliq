#include "QxSipLogRecord.hpp"

namespace qx {

SipLogRecord::SipLogRecord() :
    id(0), session(0), sequenceId(0), time(0), direction(Direction::Inbound), statusCode(0), duration(0), decryptionStatus(UnknownDecryptionStatus)
{}

} // namespace qx

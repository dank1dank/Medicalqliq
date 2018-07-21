#include "QxWebLogRecord.hpp"

namespace qx {

WebLogRecord::WebLogRecord() :
        id(0), session(0), sequenceId(0), time(0), method(NoneHttpMethod), responseCode(0), duration(0), jsonError(0)
{

}

} // namespace qx

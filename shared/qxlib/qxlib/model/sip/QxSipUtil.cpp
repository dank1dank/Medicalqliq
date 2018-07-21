#include "QxSipUtil.hpp"

namespace qx {
namespace SipUtil {

std::string qliqIdFromSipUri(const std::string &sipUri)
{
    auto pos = sipUri.find('@');
    return std::string(sipUri, 0, pos);
}

std::string stripSip(const std::string &text)
{
    std::string sipUri = text;
    if (sipUri[0] == '<') {
        sipUri.erase(0, 1);
        // // There can be more data after the closing >;tag=...
        sipUri.erase(sipUri.find('>'), std::string::npos);
    }
    if (sipUri[0] == 's' && sipUri.find("sip:") == 0) {
        sipUri.erase(0, 4);
    }

    return sipUri;
}

} // SipUtil
} // qx

#ifndef QXSIPUTIL_HPP
#define QXSIPUTIL_HPP
#include <string>

namespace qx {
namespace SipUtil {

std::string qliqIdFromSipUri(const std::string &sipUri);
std::string stripSip(const std::string &sipUri);


} // SipUtil
} // qx

#endif // QXSIPUTIL_HPP

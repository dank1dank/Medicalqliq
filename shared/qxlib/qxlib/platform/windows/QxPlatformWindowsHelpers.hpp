#ifndef QXPLATFORMWINDOWSHELPERS_HPP
#define QXPLATFORMWINDOWSHELPERS_HPP
#include <string>

namespace qx {

std::string convertFromUtf16ToUtf8(const std::wstring& wstr);
std::wstring convertFromUtf8ToUtf16(const std::string& str);

} // qx

#endif // QXPLATFORMWINDOWSHELPERS_HPP

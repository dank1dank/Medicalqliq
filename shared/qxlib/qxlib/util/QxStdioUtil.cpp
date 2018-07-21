#include "QxStdioUtil.hpp"
#ifdef _WIN32
#include "qxlib/platform/windows/QxPlatformWindowsHelpers.hpp"
#else
#include <string>
#include <cstdio>
#endif

namespace qx {

unique_file_ptr fopen_utf8(const std::string& path, const std::string& mode)
{
#ifdef _WIN32
    std::wstring wpath = qx::convertFromUtf8ToUtf16(path);
    std::wstring wmode = qx::convertFromUtf8ToUtf16(mode);
    return unique_file_ptr{_wfopen(wpath.c_str(), wmode.c_str())};
#else
    return unique_file_ptr{std::fopen(path.c_str(), mode.c_str())};
#endif
}

} // qx

#ifndef PARTIAL_STRINGSPRINTF_H
#define PARTIAL_STRINGSPRINTF_H
#include <string>

namespace base {
// Return a C++ string given printf-like input.
std::string StringPrintf(const char* format, ...);

}

#endif

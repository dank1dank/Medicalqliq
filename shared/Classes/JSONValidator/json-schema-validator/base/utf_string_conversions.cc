#include "utf_string_conversions.h"
#include "UtfConverter.h"

namespace base {

std::string UTF16ToUTF8(const string16& utf16) {
  return UtfConverter::ToUtf8(utf16);
}

std::wstring UTF8ToUTF16(const std::string& utf8) {
    return UtfConverter::FromUtf8(utf8);
}

std::wstring UTF8ToWide(const std::string& utf8) {
    return UtfConverter::FromUtf8(utf8);
}

std::string WideToUTF8(const std::wstring& wide) {
    return UtfConverter::ToUtf8(wide);
}

} // namespace base

#ifndef PARTIAL_UTF_STRING_CONVERSIONS_H
#define PARTIAL_UTF_STRING_CONVERSIONS_H
#include <string>

namespace base {

typedef wchar_t char16;
typedef std::wstring string16;

bool UTF8ToUTF16(const char* src, size_t src_len, string16* output);
std::wstring UTF8ToUTF16(const std::string& src);
bool UTF16ToUTF8(const char16* src, size_t src_len,
                          std::string* output);
std::string UTF16ToUTF8(const string16& utf16);

std::wstring UTF8ToWide(const std::string& utf8);
std::string WideToUTF8(const std::wstring& wide);

}

#endif

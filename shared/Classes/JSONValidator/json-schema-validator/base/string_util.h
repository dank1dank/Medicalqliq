#ifndef PARTIAL_STRING_UTIL_H
#define PARTIAL_STRING_UTIL_H
#include <string>

typedef std::wstring string16;

namespace base {

// Starting at |start_offset| (usually 0), replace the first instance of
// |find_this| with |replace_with|.
void ReplaceFirstSubstringAfterOffset(string16* str,
                                               string16::size_type start_offset,
                                               const string16& find_this,
                                               const string16& replace_with);
void ReplaceFirstSubstringAfterOffset(
    std::string* str,
    std::string::size_type start_offset,
    const std::string& find_this,
    const std::string& replace_with);

bool IsStringASCII(const std::string& str);
bool IsStringASCII(const string16& str);

template <typename Char>
inline Char HexDigitToInt(Char c) {
  //DCHECK(IsHexDigit(c));
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  return 0;
}

}

#endif

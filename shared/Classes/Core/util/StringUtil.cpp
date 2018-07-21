#include "StringUtil.hpp"
#include <algorithm>
#include <sstream>
#ifdef WIN32
#include <windows.h>
#endif

namespace core {

#ifdef WIN32 // or Mac desktop
std::string StringUtil::fromQString(const QString& str)
{
    QByteArray utf8 = str.toUtf8();
    return std::string(utf8.data(), utf8.size());
}

QString StringUtil::toQString(const std::string& str)
{
    return QString::fromUtf8(str.c_str(), str.size());
}
#endif

// http://stackoverflow.com/questions/215963/how-do-you-properly-use-widechartomultibyte
#ifdef WIN32_XXX

std::string StringUtil::toUtf8(const String &wstr)
{
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

String StringUtil::fromUtf8(const std::string &str)
{
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

std::string StringUtil::toStdString(const std::wstring &wstr)
{
    // CP_UTF8?
    int size_needed = WideCharToMultiByte(CP_ACP, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_ACP, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

String StringUtil::toString(const std::string &str)
{
    // CP_UTF8?
    int size_needed = MultiByteToWideChar(CP_ACP, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_ACP, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

String StringUtil::fromQString(const QString& str)
{
    return str.toStdWString();
}

QString StringUtil::toQString(const String& str)
{
    return QString::fromStdWString(str);
}

#endif

std::vector<std::string> StringUtil::split(const std::string &s, char delim, bool keepEmptyTokens)
{
    std::vector<std::string> elems;
    std::stringstream ss(s);
    std::string item;
    while(std::getline(ss, item, delim))
    {
        if (keepEmptyTokens || !item.empty())
            elems.push_back(item);
    }
    return elems;
}

std::string StringUtil::toLower(const std::string &str)
{
    std::string lower = str;
    std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);
    return lower;
}

std::string StringUtil::toUpper(const std::string &str)
{
    std::string upper = str;
    std::transform(upper.begin(), upper.end(), upper.begin(), ::toupper);
    return upper;
}

/**
 * C++ version 0.4 std::string style "itoa":
 */
std::string StringUtil::itoa(int value, int base)
{
    std::string buf;

    // check that the base if valid
    if (base < 2 || base > 16) return buf;

    enum { kMaxDigits = 35 };
    buf.reserve( kMaxDigits ); // Pre-allocate enough space.

    int quotient = value;

    // Translating number to string with base:
    do {
	buf += "0123456789abcdef"[ std::abs( quotient % base ) ];
	quotient /= base;
    } while ( quotient );

    // Append the negative sign
    if ( value < 0) buf += '-';

    std::reverse( buf.begin(), buf.end() );
    return buf;
}


} // namespace core

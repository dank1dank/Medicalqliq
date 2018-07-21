#ifndef STRING_H
#define STRING_H
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdio>
#ifdef QLIQ_CORE_QT
#include <QString>
#endif
#include "util/StringUtil.hpp"

namespace core {

#ifdef WIN32_XXX
typedef std::wstring String;
#else
typedef std::string String;
#endif

class StringUtil
{
public:

    //static std::string toStdString(const std::wstring& wstr);
    //static std::wstring toWStdString(const std::string& str);

    static std::string itoa(int value, int base);
#ifdef WIN32 // or Mac desktop
    static std::string fromQString(const QString& str);
    static QString toQString(const std::string& str);
#endif

#ifdef WIN32_XXX
    static std::string toUtf8(const String& str);
    static String fromUtf8(const std::string& str);

    static std::string toStdString(const String& str);
    static String toString(const std::string& str);

    static String fromQString(const QString& str);
    static QString toQString(const String& str);
#else
    static inline std::string toUtf8(const String& str) { return str; }
    static inline String fromUtf8(const std::string& str) { return str; }

    static inline std::string toStdString(const String& str) { return str; }
    static inline String toString(const std::string& str) { return str; }
#endif

    static std::vector<std::string> split(const std::string &s, char delim, bool keepEmptyToken = true);

    /// Returns the index position of the first occurrence of the \arg needle in \arg haystack, searching forward from index position from. Returns -1 if str is not found.
    static std::size_t indexOf(const std::string& haystack, char needle, int from = 0)
    {
        std::size_t len = haystack.size();
        std::size_t i;
        for (i = from; i < len; ++i)
        {
            if (haystack[i] == needle)
                break;
        }

        return (i < len) ? i : -1;
    }

    /// Returns the index position of the first occurrence of the \arg needle in \arg haystack, searching forward from index position from. Returns -1 if str is not found.
    static std::size_t indexOf(const std::string& haystack, const std::string& needle, int from = 0)
    {
        return haystack.find(needle, from);
    }

    /// Returns a string that contains \arg n characters of \arg str, starting at the specified \arg pos index.
    static std::string mid(const std::string& str, int pos, int n = -1)
    {
        return str.substr(pos, n);
    }

    /// Returns true if \arg str starts with \arg needle; otherwise returns false.
    static bool startsWith(const std::string& str, const std::string& needle)
    {
        std::size_t slen = str.size();
        std::size_t nlen = needle.size();

        if (nlen > slen)
            return false;
        else
        {
            for (std::size_t i = 0; i < nlen; ++i)
            {
                if (str[i] != needle[i])
                    return false;
            }
            return true;
        }
    }

    static std::string number(int num)
    {
        return itoa(num, 10);
    }

    static std::string toLower(const std::string& str);
    static std::string toUpper(const std::string& str);
};

}

#endif // STRING_H

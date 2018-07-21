#pragma once
#include <string>
#include <vector>

namespace StringUtils
{
    enum CaseSensitivity {
        CaseSensitive,
        CaseInsensitive
    };

    std::string toUpperCase(std::string input);
    std::string toLowerCase(std::string input);

    // Searching
    std::size_t findCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos = 0);
    std::size_t findCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos, std::size_t patternLen);
    int indexOf(const std::string& str, char c, int pos = 0);
    const char *strnstr(const char *haystack, const char *needle, std::size_t len);
    const char *strrstr(const char *haystack, const char *needle);

    void replace(std::string& source, const std::string& from, const std::string& to);

    // Test for contains, starts, ends
    bool contains(const std::string &str, const std::string &pattern, std::size_t startPos = 0);
    bool containsCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos = 0);
    bool containsCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos, std::size_t patternLen);
    bool startsWith(const std::string &str, const std::string &needle, CaseSensitivity caseSensitivity = CaseSensitive);
    bool startsWith(const std::string &str, const char *needle, CaseSensitivity caseSensitivity = CaseSensitive);
    bool startsWith(const char *str, std::size_t strLen, const char *needle, std::size_t needleLen, CaseSensitivity caseSensitivity = CaseSensitive);

    // Compare
    int compareCaseInsensitive(const char *str1, const char *str2, std::size_t len);
    int compareCaseInsensitive(const char *str1, const char *str2);
    int compareCaseInsensitive(const std::string& str1, const std::string& str2);

    // Extract
    std::string extractRegion(const std::string & str, int from, int to);
    std::string left(const std::string& str, int len = -1);

    // Split
    std::vector<std::string> split(const std::string & str, const std::vector<std::string> & delimiters);
    std::vector<std::string> split(const std::string & str, const std::string & delimiter);
    std::vector<std::string> split(const std::string &s, char delim);

    // Trim
    std::string& ltrim(std::string& str);
    std::string& rtrim(std::string& str);
    std::string& trim(std::string& str);

    std::string join(const std::vector<std::string>& tokens, const std::string& delimiter);

    std::string escapeChar(char character);
    std::string escapeString(const std::string& str);
    std::vector<std::string> escapeStrings(const std::vector<std::string>& strs);

    bool isAnInteger(const std::string& token);
    int convertToInt(const std::string& str);
}

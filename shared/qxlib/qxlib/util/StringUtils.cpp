#include "qxlib/util/StringUtils.hpp"
#ifdef QXL_OS_WIN
#include <string.h>
#else
#include <strings.h>
#endif
#include <unordered_map>
#include <regex>
#include <sstream>
#include <cstring>
#include "qxlib/util/VectorUtils.hpp"

std::string StringUtils::join(const std::vector<std::string> & tokens, 
  const std::string & delimiter) {
  std::stringstream stream;
  stream << tokens.front();
  std::for_each(
    begin(tokens) + 1,
    end(tokens),
    [&](const std::string &elem) { stream << delimiter << elem; }
  );
  return stream.str();
}
/*
std::vector<std::string> StringUtils::split(const std::string & str,
  const std::vector<std::string> & delimiters) {

  std::regex rgx(join(escapeStrings(delimiters), "|"));

  std::sregex_token_iterator
    first{begin(str), end(str), rgx, -1},
    last;

  return{first, last};
}

std::vector<std::string> StringUtils::split(const std::string & str,
  const std::string & delimiter) {
  std::vector<std::string> delimiters = {delimiter};
  return split(str, delimiters);
}
*/
std::vector<std::string> StringUtils::split(const std::string &s, char delim) {
    std::stringstream ss(s);
    std::string item;
    std::vector<std::string> tokens;
    while (getline(ss, item, delim)) {
        tokens.push_back(item);
    }
    return tokens;
}

std::string StringUtils::escapeChar(char character) {
  const std::unordered_map<char, std::string> ScapedSpecialCharacters = {
    {'.', "\\."}, {'|', "\\|"}, {'*', "\\*"}, {'?', "\\?"},
    {'+', "\\+"}, {'(', "\\("}, {')', "\\)"}, {'{', "\\{"},
    {'}', "\\}"}, {'[', "\\["}, {']', "\\]"}, {'^', "\\^"},
    {'$', "\\$"}, {'\\', "\\\\"}
  };

  auto it = ScapedSpecialCharacters.find(character);

  if (it == ScapedSpecialCharacters.end())
    return std::string(1, character);

  return it->second;
}

std::string StringUtils::escapeString(const std::string & str) {
  std::stringstream stream;
  std::for_each(begin(str), end(str),
    [&stream](const char character) { stream << escapeChar(character); }
  );
  return stream.str();
}

std::vector<std::string> StringUtils::escapeStrings(
  const std::vector<std::string> & delimiters) {
  return VectorUtils::map<std::string>(delimiters, escapeString);
}

bool StringUtils::isAnInteger(const std::string & token) {
  const std::regex e("\\s*[+-]?([1-9][0-9]*|0[0-7]*|0[xX][0-9a-fA-F]+)");
  return std::regex_match(token, e);
}

std::string StringUtils::extractRegion(const std::string & str,
  int from, int to) {
  std::string region = "";
  int regionSize = to - from;
  return str.substr(from, regionSize);
}

int StringUtils::convertToInt(const std::string & str) {
  std::string::size_type sz;
  return std::stoi(str, &sz);
}

std::string StringUtils::toUpperCase(std::string input)
{
    for (std::string::iterator it = input.begin(); it != input.end(); ++ it) {
        *it = std::toupper(*it);
    }
    return input;
}


std::string StringUtils::toLowerCase(std::string input)
{
    for (std::string::iterator it = input.begin(); it != input.end(); ++ it) {
        *it = std::tolower(*it);
    }
    return input;
}

std::size_t StringUtils::findCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos, std::size_t patternLen)
{
    const auto strSize = str.size();
    const auto strData = str.c_str();

    if (patternLen == 0) {
        return startPos <= strSize ? startPos : std::string::npos;
    }

    if (patternLen <= strSize) {
        for (; startPos <= strSize - patternLen; ++startPos) {
            if (std::tolower(strData[startPos]) == std::tolower(pattern[0]) &&
                    compareCaseInsensitive(strData + startPos + 1, pattern.c_str() + 1, patternLen - 1) == 0) {
                return startPos;
            }
        }
    }
    return std::string::npos;
}

std::size_t StringUtils::findCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos)
{
    return findCaseInsensitive(str, pattern, startPos, pattern.size());
}

bool StringUtils::containsCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos)
{
    return containsCaseInsensitive(str, pattern, startPos, pattern.size());
}

bool StringUtils::containsCaseInsensitive(const std::string &str, const std::string &pattern, std::size_t startPos, std::size_t patternLen)
{
    return findCaseInsensitive(str, pattern, startPos, patternLen) != std::string::npos;
}

int StringUtils::compareCaseInsensitive(const char *str1, const char *str2, std::size_t len)
{
   for (std::size_t i = 0; i < len; ++i) {
       int ret = std::tolower(str1[i]) - std::tolower(str2[i]);
       if (ret != 0) {
           return ret;
       }
   }
   return 0;
}

int StringUtils::compareCaseInsensitive(const char *str1, const char *str2)
{
#ifdef QXL_OS_WIN
    return _stricmp(str1, str2);
#else
    return strcasecmp(str1, str2);
#endif
}

int StringUtils::compareCaseInsensitive(const std::string &str1, const std::string &str2)
{
    return compareCaseInsensitive(str1.c_str(), str2.c_str());
}

const char *StringUtils::strnstr(const char *haystack, const char *needle, std::size_t len)
{
    if (len == 0) {
        return haystack; /* degenerate edge case */
    }

    const char *newhaystack;
    while ((newhaystack = static_cast<const char *>(std::memchr(haystack, needle[0], len)))) {
        len -= std::distance(haystack, newhaystack);
        haystack = newhaystack;
        if (!std::strncmp(haystack, needle, len)) {
            return haystack;
        }
        haystack++;
        len--;
    }

    return 0;
}

const char *StringUtils::strrstr(const char *haystack, const char *needle)
{
    const char *r = NULL;

    if (!needle[0]) {
        return (char *) haystack + strlen(haystack);
    }
    while (1) {
        const char *p = strstr(haystack, needle);
        if (!p) {
            return r;
        }
        r = p;
        haystack = p + 1;
    }
}

bool StringUtils::startsWith(const char *str, std::size_t strLen, const char *needle, std::size_t needleLen, CaseSensitivity caseSensitivity)
{
    if (needleLen > strLen) {
        return false;
    } else {
        if (caseSensitivity == CaseSensitive) {
            for (std::size_t i = 0; i < needleLen; ++i) {
                if (str[i] != needle[i]) {
                    return false;
                }
            }
        } else {
            for (std::size_t i = 0; i < needleLen; ++i) {
                if (std::tolower(str[i]) != std::tolower(needle[i])) {
                    return false;
                }
            }
        }
        return true;
    }
}

bool StringUtils::startsWith(const std::string &str, const std::string &needle, CaseSensitivity caseSensitivity)
{
    return startsWith(str.c_str(), str.size(), needle.c_str(), needle.size(), caseSensitivity);
}

bool StringUtils::startsWith(const std::string &str, const char *needle, CaseSensitivity caseSensitivity)
{
    return startsWith(str.c_str(), str.size(), needle, needle ? std::strlen(needle) : 0, caseSensitivity);
}

std::string& StringUtils::ltrim(std::string& str)
{
    auto it2 = std::find_if(str.begin(), str.end(), [](char ch){ return !std::isspace<char>(ch, std::locale::classic()); });
    str.erase(str.begin(), it2);
    return str;
}

std::string& StringUtils::rtrim(std::string& str)
{
    auto it1 =  std::find_if(str.rbegin(), str.rend(), [](char ch){ return !std::isspace<char>(ch, std::locale::classic()); });
    str.erase(it1.base(), str.end());
    return str;
}
std::string &StringUtils::trim(std::string &str)
{
    return ltrim(rtrim(str));
}

bool StringUtils::contains(const std::string &str, const std::string &pattern, std::size_t startPos)
{
    return (str.find(pattern, startPos) != std::string::npos);
}

std::string StringUtils::left(const std::string &str, int len)
{
    if (len == -1) {
        len = str.size();
    }
    return str.substr(0, len);
}

int StringUtils::indexOf(const std::string &str, char c, int startPos)
{
    auto pos = str.find(c, startPos);
    if (pos == std::string::npos) {
        return -1;
    } else {
        return pos;
    }
}

void StringUtils::replace(std::string &source, const std::string &from, const std::string &to)
{
    std::string newString;
    newString.reserve(source.length());  // avoids a few memory allocations

    std::string::size_type lastPos = 0;
    std::string::size_type findPos;

    while(std::string::npos != (findPos = source.find(from, lastPos)))
    {
        newString.append(source, lastPos, findPos - lastPos);
        newString += to;
        lastPos = findPos + from.length();
    }

    // Care for the rest after last occurrence
    newString += source.substr(lastPos);

    source.swap(newString);
}

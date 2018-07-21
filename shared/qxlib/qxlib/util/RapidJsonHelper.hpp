#ifndef RAPIDJSONHELPER_H
#define RAPIDJSONHELPER_H
#include <string>
#include <vector>
#include <stdexcept>
#define RAPIDJSON_HAS_STDSTRING 1
#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>

class JsonParsingException : public std::runtime_error {
public:
    JsonParsingException(const std::string& what);
};

namespace rapidjson {
namespace helper  {

#if 1 || defined(NDEBUG) || defined(QT_NO_DEBUG)
typedef rapidjson::Writer<rapidjson::StringBuffer> StringWriter;
#else
typedef rapidjson::PrettyWriter<rapidjson::StringBuffer> StringWriter;
#endif

struct SelectorDescriptor {
    std::string selectorKeyOrPath;
    std::string selectorValue;

    SelectorDescriptor()
    {}

    SelectorDescriptor(const char *selectorKeyOrPath, const char *selectorValue) :
        selectorKeyOrPath(selectorKeyOrPath),
        selectorValue(selectorValue)
    {}

    SelectorDescriptor(const std::string& selectorKeyOrPath, const std::string& selectorValue) :
        selectorKeyOrPath(selectorKeyOrPath),
        selectorValue(selectorValue)
    {}
};
typedef std::vector<SelectorDescriptor> Selectors;

rapidjson::Document *fileToDocument(const char *path);
rapidjson::Document *stringToDocument(const char *str);

std::string getOptString(const rapidjson::Value &json, const char *name);
std::string getString(const rapidjson::Value &json, const char *name);
const rapidjson::Value *optArray(const rapidjson::Value &json, const char *name);

/// Returns json[arrayKey][N] if json[arrayKey][N][selectorKeyOrPath] == selectorValue
const rapidjson::Value *findObjectInObjectArrayWhereSelector(const rapidjson::Value &json, const char *arrayKey, const char *selectorKeyOrPath, const char *selectorValue);
/// Returns json[arrayKey][N][keyOrPath] if json[arrayKey][N][selectorKeyOrPath] == selectorValue
std::string optStringInObjectArrayWhereSelector(const rapidjson::Value &json, const char *keyOrPath, const char *arrayKey, const char *selectorKeyOrPath, const char *selectorValue);
std::string optStringInObjectArrayWhereSelectors(const rapidjson::Value &json, const char *keyOrPath, const char *arrayKey, const std::vector<SelectorDescriptor>& selectors);

// String functions
std::string& appendNotEmpty(std::string *out, const std::string& value, const std::string& separator);
bool isDigits(const std::string &str);

std::string prettify(const char *json);

// Serialization (writing)

bool writeNotEmpty(StringWriter &writer, const char *key, const std::string& value);
bool writeNotZero(StringWriter &writer, const char *key, unsigned int value);
bool writeNotZero(StringWriter &writer, const char *key, int value);

///////////////////////////////////////////////////////////////////////////////
// qliqSOFT specifc JSON utils
//
void writeQliqError(StringWriter& writer, int code, const char *msg);
void writeQliqError(StringWriter& writer, int code, const std::string& msg);

} // namespace helper
} // namespace rapidjson

#endif // RAPIDJSONHELPER_H

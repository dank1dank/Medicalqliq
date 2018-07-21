#include "RapidJsonHelper.hpp"
#include <algorithm>
#include <clocale>
#include <rapidjson/filereadstream.h>
#include "qxlib/model/fhir/FhirResources.hpp"

JsonParsingException::JsonParsingException(const std::string &what) :
    std::runtime_error(what)
{
}

namespace rapidjson {
namespace helper  {

rapidjson::Document *fileToDocument(const char *path)
{
    FILE *fp = std::fopen(path, "rb");
    if (!fp) {
        return nullptr;
    }
    const std::size_t BUFFER_SIZE = 65536;
    char *readBuffer(new char[BUFFER_SIZE]);
    rapidjson::FileReadStream is(fp, readBuffer, BUFFER_SIZE);
    auto document = new rapidjson::Document();
    document->ParseStream(is);
    std::fclose(fp);
    delete [] readBuffer;
    return document;
}

Document *stringToDocument(const char *str)
{
    auto document = new rapidjson::Document();
    document->Parse(str);
    return document;
}

std::string getOptString(const rapidjson::Value &json, const char *name)
{
    const rapidjson::Value *currentValue = &json;

    while (const char *sep = std::strchr(name, '/')) {
        if (!(currentValue->IsObject() || currentValue->IsArray())) {
            return "";
        }

        std::string key(name, sep - name);
        name = sep + 1;
        if (currentValue->IsObject()) {
            rapidjson::Value::ConstMemberIterator memberItr = currentValue->FindMember(key.c_str());
            if (memberItr != currentValue->MemberEnd()) {
                currentValue = &(memberItr->value);
            } else {
                return "";
            }
        } else if (currentValue->IsArray()) {
            for (const char c: key) {
                if (!std::isdigit(c)) {
                    return "";
                }
            }
            int index = std::atoi(key.c_str());
            if (index >= 0 && index < (int)currentValue->Capacity()) {
                currentValue = &(currentValue->operator [](index));
            } else {
                return "";
            }
        }
    }

    std::string key = name;
    if (currentValue->IsObject()) {
        rapidjson::Value::ConstMemberIterator memberItr = currentValue->FindMember(key.c_str());
        if (memberItr != currentValue->MemberEnd()) {
            currentValue = &(memberItr->value);
        } else {
            currentValue = nullptr;
        }
    } else if (currentValue->IsArray()) {
        for (const char c: key) {
            if (!std::isdigit(c)) {
                return "";
            }
        }
        int index = std::atoi(key.c_str());
        if (index >= 0 && index < (int)currentValue->Capacity()) {
            currentValue = &(currentValue->operator [](index));
        } else {
            currentValue = nullptr;
        }
    }

    if (currentValue && currentValue->IsString()) {
        return currentValue->GetString();
    } else {
        return "";
    }
}

std::string getString(const rapidjson::Value &json, const char *name)
{
    rapidjson::Value::ConstMemberIterator itr = json.FindMember(name);
    if (itr == json.MemberEnd()) {
        throw JsonParsingException("Cannot find key '" + std::string(name) + "'");
    } else if (!itr->value.IsString()) {
        throw JsonParsingException("The value of key '" + std::string(name) + "' is not string type");
    } else {
        return itr->value.GetString();
    }
}

const rapidjson::Value *optArray(const rapidjson::Value &json, const char *name)
{
    rapidjson::Value::ConstMemberIterator itr = json.FindMember(name);
    if (itr != json.MemberEnd() && itr->value.IsArray()) {
        return &(itr->value);
    } else {
        return nullptr;
    }
}

/// Returns json[arrayKey][N] if json[arrayKey][N][selectorKeyOrPath] == selectorValue
const rapidjson::Value *findObjectInObjectArrayWhereSelector(const rapidjson::Value &json, const char *arrayKey, const char *selectorKeyOrPath, const char *selectorValue)
{
    const rapidjson::Value *array = optArray(json, arrayKey);
    if (array) {
        for (rapidjson::Value::ConstValueIterator itr = array->Begin(); itr != array->End(); ++itr) {
            if (getOptString(*itr, selectorKeyOrPath) == selectorValue) {
                return &(*itr);
            }
        }
    }
    return nullptr;
}
/// Returns json[arrayKey][N][keyOrPath] if json[arrayKey][N][selectorKeyOrPath] == selectorValue
std::string optStringInObjectArrayWhereSelector(const rapidjson::Value &json, const char *keyOrPath, const char *arrayKey, const char *selectorKeyOrPath, const char *selectorValue)
{
    const rapidjson::Value *array = optArray(json, arrayKey);
    if (array) {
        for (rapidjson::Value::ConstValueIterator itr = array->Begin(); itr != array->End(); ++itr) {
            if (getOptString(*itr, selectorKeyOrPath) == selectorValue) {
                return getOptString(*itr, keyOrPath);
            }
        }
    }
    return "";
}

/// Returns json[arrayKey][N][keyOrPath] if json[arrayKey][N][selectorKeyOrPath] == selectorValue
std::string optStringInObjectArrayWhereSelectors(const rapidjson::Value &json, const char *keyOrPath, const char *arrayKey, const std::vector<SelectorDescriptor>& selectors)
{
    const rapidjson::Value *array = optArray(json, arrayKey);
    if (array) {
        std::vector<SelectorDescriptor>::size_type selectorIndex = 0;
        for (rapidjson::Value::ConstValueIterator itr = array->Begin(); itr != array->End(); ++itr) {
            for (selectorIndex = 0; selectorIndex < selectors.size(); ++selectorIndex) {
                const SelectorDescriptor& s = selectors[selectorIndex];
                if (getOptString(*itr, s.selectorKeyOrPath.c_str()) != s.selectorValue) {
                    break;
                }
            }
            if (selectorIndex == selectors.size()) {
                return getOptString(*itr, keyOrPath);
            }
        }
    }
    return "";
}

std::string& appendNotEmpty(std::string *out, const std::string &value, const std::string &separator)
{
    if (value.find_first_not_of(" \t\n\v\f\r") != std::string::npos) {
        if (!out->empty()) {
            out->append(separator);
        }
        out->append(value);
    }
    return *out;
}

bool isDigits(const std::string &str)
{
    return !str.empty() && std::all_of(str.begin(), str.end(), ::isdigit);
}

std::string prettify(const char *json)
{
    Reader reader;
    StringStream is(json);

    rapidjson::StringBuffer sb;
    rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(sb);

    // JSON reader parse from the input stream and let writer generate the output.
    if (!reader.Parse<kParseValidateEncodingFlag>(is, writer)) {
        //fprintf(stderr, "\nError(%u): %s\n", static_cast<unsigned>(reader.GetErrorOffset()), GetParseError_En(reader.GetParseErrorCode()));
        return "";
    }

    return sb.GetString();
}

bool writeNotEmpty(StringWriter &writer, const char *key, const std::string &value)
{
    if (!value.empty()) {
        writer.Key(key);
        writer.String(value);
        return true;
    } else {
        return false;
    }
}

bool writeNotZero(StringWriter &writer, const char *key, unsigned int value)
{
    if (value != 0) {
        writer.Key(key);
        writer.Uint(value);
        return true;
    } else {
        return false;
    }
}

bool writeNotZero(StringWriter &writer, const char *key, int value)
{
    if (value != 0) {
        writer.Key(key);
        writer.Int(value);
        return true;
    } else {
        return false;
    }
}

void writeQliqError(StringWriter &writer, int code, const char *msg)
{
    writer.Key("Error");
    writer.StartObject();
        writer.Key("error_msg");
        writer.String(msg);
        writer.Key("error_code");
        writer.Int(code);
    writer.EndObject();
}

void writeQliqError(StringWriter &writer, int code, const std::string &msg)
{
    writeQliqError(writer, code, msg.c_str());
}

} // namespace helper
} // namespace rapidjson

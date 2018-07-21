#include "QxSettings.hpp"

namespace qx {

void Settings::setValue(const std::string &key, int value)
{
    return setValue(key, std::to_string(value));
}

void Settings::setValue(const std::string &key, bool value)
{
    std::string str = value ? "true" : "false";
    return setValue(key, str);
}

int Settings::valueAsInt(const std::string &key, int defaultValue) const
{
    int ret = defaultValue;
    if (contains(key)) {
        const std::string& str = valueAsString(key);
        ret = std::atoi(str.c_str());
    }
    return ret;
}

bool Settings::valueAsBool(const std::string &key, bool defaultValue) const
{
    bool ret = defaultValue;
    if (contains(key)) {
        const std::string& str = valueAsString(key);
        ret = (str == "true");
    }
    return ret;
}

} // qx

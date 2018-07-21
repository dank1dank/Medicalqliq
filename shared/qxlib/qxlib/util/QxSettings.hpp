#ifndef QXSETTINGS_HPP
#define QXSETTINGS_HPP
#include <string>

namespace qx {

class Settings
{
public:
    // Below functions must be implemented in per platform specific files
    Settings();
    ~Settings();
    void setValue(const std::string& key, const std::string& value);
    std::string valueAsString(const std::string& key, const std::string& defaultValue = "") const;
    bool contains(const std::string& key) const;
    void remove(const std::string& key);

    void setValue(const std::string& key, int value);
    void setValue(const std::string& key, bool value);

    int valueAsInt(const std::string& key, int defaultValue = 0) const;
    bool valueAsBool(const std::string& key, bool defaultValue = false) const;

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QXSETTINGS_HPP

#ifndef QX_SIP_H
#define QX_SIP_H
#include <string>
#include <map>
#include "qxlib/model/QxQliqUser.hpp"

namespace qx {

namespace map_helpers {

template <typename Map, typename Key>
bool erase(Map& map, const Key& key)
{
    auto it = map.find(key);
    if (it != map.end()) {
        map.erase(it);
        return true;
    } else {
        return false;
    }
}

template <typename Key, typename Value>
const Value& value(const std::map<Key, Value>& map, const Key& key, const Value& defaultValue = Value())
{
    auto it = map.find(key);
    if (it != map.end()) {
        return it->second;
    } else {
        return defaultValue;
    }
}

} // map_helpers

typedef std::map<std::string, std::string> StringMap;

class SipHeaders {
public:
    enum Header {
        XOffline,
        XPagerInfo
    };

    static const std::string& name(Header header);
};

struct SipMessage {
    StringMap extraHeaders;

    intptr_t seq;
    std::string toQliqId;
    std::string fromQliqId;
    bool isOurMessage;
    std::string content;
    std::string plainContent;
    std::string usedPublicKey;
    void *userData;
    bool offlineMode;
    bool pushNotify;
    bool groupMode;
    bool multiParty;
    std::string recipientScope;
    std::string displayName;
//    SipMessageStatusCallback *callback;
    std::string callId;
//    core::connect::ChatMessage::Priority priority;
    std::string status;
    std::string serverContext;
    std::string alsoNotify;
//    QDateTime createdAt;
    std::string conversationUuid;
    bool isBroadcast;

    void setPagerInfo(const std::string& value)
    {
        setHeader(SipHeaders::XPagerInfo, value);
    }

    void setOfflineMode(bool on)
    {
        if (on) {
            extraHeaders[SipHeaders::name(SipHeaders::XPagerInfo)] = "yes";
        } else {
            map_helpers::erase(extraHeaders, SipHeaders::name(SipHeaders::XOffline));
        }
    }

    void setHeader(SipHeaders::Header header, const std::string& value)
    {
        extraHeaders[SipHeaders::name(header)] = value;
    }

};

struct SipServerInfo {
    std::string url;
    int port;
    std::string transport;

    SipServerInfo();
    bool isEmpty() const;
    StringMap toMap() const;
    static SipServerInfo fromMap(const StringMap& map);
};

struct SipAccountSettings {
    SipServerInfo serverInfo;
    QliqUser user;
    std::string password;
};


class Sip
{
public:
    Sip();
    ~Sip();

    void setSettings(const SipAccountSettings& settings);
    void start();
    void stop();

    // Method only for log db
    std::string lastMessagePlainTextBody(const std::string& callId = {}) const;

    static Sip *instance();
    // Helper methods used also by other code
    static std::string defaultGroupKeyPassword();

private:
    struct Private;
    Private *d;
};

} // namespace qx

#endif // QX_SIP_H

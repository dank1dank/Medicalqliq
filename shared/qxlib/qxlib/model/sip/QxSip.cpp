#include "QxSip.hpp"

std::string qx_sip_last_message_plain_text_body_impl(const std::string& callId);

namespace qx {

namespace  {
    Sip *s_instance = nullptr;
}

struct Sip::Private {
    SipAccountSettings settings;
};

Sip::Sip() :
    d(new Private())
{
    if (!s_instance) {
        s_instance = this;
    }
}

Sip::~Sip()
{
    delete d;
    d = nullptr;

    if (s_instance == this) {
        s_instance = nullptr;
    }
}

void Sip::setSettings(const SipAccountSettings &settings)
{
    d->settings = settings;
}

void Sip::start()
{

}

std::string Sip::lastMessagePlainTextBody(const std::string& callId) const
{
    return qx_sip_last_message_plain_text_body_impl(callId);
}

Sip *Sip::instance()
{
    return s_instance;
}

std::string Sip::defaultGroupKeyPassword()
{
    return "groupchat";
}

const std::string& SipHeaders::name(SipHeaders::Header header)
{
    static std::string null;
    static std::map<SipHeaders::Header, std::string> map;
    if (map.empty()) {
        map[SipHeaders::XOffline] = "X-offline";
        map[SipHeaders::XPagerInfo] = "X-pager-info";
    }
    auto it = map.find(header);
    if (it != map.end()) {
        return it->second;
    } else {
        return null;
    }
}

SipServerInfo::SipServerInfo() :
    port(0)
{}

bool SipServerInfo::isEmpty() const
{
    return url.empty();
}

StringMap SipServerInfo::toMap() const
{
    StringMap map;
    map["url"] = url;
    map["port"] = std::to_string(port);
    map["transport"] = transport;
    return map;
}

SipServerInfo SipServerInfo::fromMap(const StringMap &map)
{
    SipServerInfo ret;
    ret.url = map_helpers::value(map, std::string("url"));
    ret.port = std::stoi(map_helpers::value(map, std::string("port")));
    ret.transport = map_helpers::value(map, std::string("transport"));
    return ret;
}

} // namespace qx

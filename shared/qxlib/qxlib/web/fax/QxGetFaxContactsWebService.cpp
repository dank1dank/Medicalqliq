#include "QxGetFaxContactsWebService.hpp"
#include "qxlib/dao/fax/QxFaxContactDao.hpp"

namespace qx {
namespace web {

GetFaxContactsWebService::GetFaxContactsWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void GetFaxContactsWebService::call(GetFaxContactsWebService::ResultFunction ResultFunction, BaseWebService::IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json::object json;

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/get_fax_contacts", json, [this,ResultFunction](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, ResultFunction);
    }, "", "", isCancelledFun);
}

FaxContact GetFaxContactsWebService::contactFromJson(const json11::Json &json)
{
    FaxContact c;
    c.faxNumber = json["fax_number"].string_value();
    c.voiceNumber = json["voice_number"].string_value();
    c.organization = json["organization_name"].string_value();
    c.contactName = json["contact_name"].string_value();
    c.uuid = json["uuid"].string_value();
    c.groupQliqId = json["group_qliq_id"].string_value();
    c.isCreatedByUser = json["user_created"].bool_value();
    return c;
}

json11::Json::object GetFaxContactsWebService::contactToJson(const FaxContact &contact)
{
    json11::Json::object json;
    json["uuid"] = contact.uuid;
    json["fax_number"] = contact.faxNumber;
    json["user_created"] = contact.isCreatedByUser;

    if (!contact.voiceNumber.empty()) {
        json["voice_number"] = contact.voiceNumber;
    }
    if (!contact.organization.empty()) {
        json["organization_name"] = contact.organization;
    }
    if (!contact.contactName.empty()) {
        json["contact_name"] = contact.contactName;
    }
    if (!contact.groupQliqId.empty()) {
        json["group_qliq_id"] = contact.groupQliqId;
    }
    return json;
}

void GetFaxContactsWebService::call(GetFaxContactsWebService::ResultCallback *callback)
{
    call([callback](const QliqWebError& error) {
        callback->run(new QliqWebError(error));
    });
}

void GetFaxContactsWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const GetFaxContactsWebService::ResultFunction &resultFunction)
{
    std::vector<FaxContact> contacts;
    if (!error) {
        for (const auto& item: json["fax_contacts"].array_items()) {
            FaxContact c = contactFromJson(item);
            if (!c.faxNumber.empty() && !c.uuid.empty()) {
                FaxContact existing = FaxContactDao::selectOneBy(FaxContactDao::UuidColumn, c.uuid);
                if (existing.isEmpty()) {
                    FaxContactDao::insert(&c);
                } else {
                    c.databaseId = existing.databaseId;
                    FaxContactDao::update(c);
                }
                contacts.push_back(c);
            }
        }
        FaxContactDao::deleteNotIn(contacts);
    }

    resultFunction(error);
}

GetFaxContactsWebService::ResultCallback::~ResultCallback()
{
}

} // web
} // qx

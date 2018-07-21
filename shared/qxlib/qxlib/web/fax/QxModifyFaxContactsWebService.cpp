#include "QxModifyFaxContactsWebService.hpp"
#include "QxGetFaxContactsWebService.hpp"
#include "qxlib/dao/fax/QxFaxContactDao.hpp"
#include "qxlib/util/QxUuid.hpp"

namespace qx {
namespace web {

ModifyFaxContactsWebService::ModifyFaxContactsWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void ModifyFaxContactsWebService::call(const FaxContact &contact, ModifyFaxContactsWebService::Operation operation, ModifyFaxContactsWebService::ResultFunction resultFunction, BaseWebService::IsCancelledFunction isCancelledFun)
{
    if (!contact.isCreatedByUser) {
        const char *errorMessage = "Trying to modify fax contact that was not created by user";
        QXLOG_FATAL(errorMessage, nullptr);
        if (resultFunction) {
            resultFunction(QliqWebError::applicationError(errorMessage));
        }
        return;
    }

    FaxContact contactCopy = contact;
    if (contactCopy.uuid.empty()) {
        contactCopy.uuid = Uuid::generate();
    }

    using namespace json11;

    Json::object item = GetFaxContactsWebService::contactToJson(contactCopy);
    item["operation"] = toString(operation);

    Json::array array = Json::array();
    array.push_back(item);

    Json json = Json::object {
        {"fax_contacts", array}
    };


    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/modify_fax_contacts", json, [this,resultFunction,contactCopy,operation](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, contactCopy, operation, resultFunction);
    }, "", "", isCancelledFun);
}

void ModifyFaxContactsWebService::call(const FaxContact &contact, ModifyFaxContactsWebService::Operation operation, ModifyFaxContactsWebService::ResultCallback *callback)
{
    call(contact, operation, [callback](const QliqWebError& error) {
        callback->run(new QliqWebError(error));
    });
}

void ModifyFaxContactsWebService::handleResponse(const QliqWebError &error, const FaxContact& contact, Operation operation, const ModifyFaxContactsWebService::ResultFunction &resultFunction)
{
    if (!error) {
        if (operation == Operation::Add) {
            FaxContactDao::insert(contact);
        } else if (operation == Operation::Remove) {
            FaxContactDao::delete_(FaxContactDao::IdColumn, std::to_string(contact.databaseId));
        }
    }
    if (resultFunction) {
        resultFunction(error);
    }
}

const char *ModifyFaxContactsWebService::toString(ModifyFaxContactsWebService::Operation op)
{
    switch (op) {
    case Operation::Add:
        return "add";
    case Operation::Remove:
        return "remove";
    }
    return "unknown";
}

ModifyFaxContactsWebService::ResultCallback::~ResultCallback()
{
}

} // web
} // qx

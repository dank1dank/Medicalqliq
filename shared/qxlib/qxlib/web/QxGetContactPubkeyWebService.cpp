#include "QxGetContactPubkeyWebService.hpp"
#include "qxlib/dao/sip/QxSipContactDao.hpp"
#include "qxlib/log/QxLog.hpp"

namespace qx {
namespace web {

GetContactPubKeyWebService::GetContactPubKeyWebService(WebClient *webClient) :
    BaseWebService(webClient)
{
}

void GetContactPubKeyWebService::call(const std::string &qliqId, GetContactPubKeyWebService::ResultFunction ResultFunction, BaseWebService::IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json json = Json::object {
        {"qliq_id", qliqId}
    };

    m_webClient->postJsonRequest(WebClient::RegularServer, "/services/get_contact_pubkey", json, [this,ResultFunction](const QliqWebError& error, const json11::Json& json) {
        handleResponse(error, json, ResultFunction);
    }, "", "", isCancelledFun);
}

void GetContactPubKeyWebService::call(const std::string &qliqId, ResultCallback *callback)
{
    call(qliqId, [callback](const QliqWebError& error, const std::string& pubKey) {
        callback->run(new QliqWebError(error), pubKey);
    });
}

void GetContactPubKeyWebService::handleResponse(const QliqWebError &error, const json11::Json &json, const GetContactPubKeyWebService::ResultFunction &ResultFunction)
{
    std::string pubKey;
    if (!error) {
        std::string qliqId = json["qliq_id"].string_value();
        pubKey = json["public_key"].string_value();

        SipContact contact = SipContactDao::selectOneBy(SipContactDao::QliqIdColumn, qliqId);
        if (contact.isEmpty()) {
            QXLOG_ERROR("Cannot find SipContact in db for qliq_id: %s", qliqId.c_str());
        } else {
            SipContactDao::updateColumn(SipContactDao::PublicKeyColumn, pubKey, contact);
        }
    }

    ResultFunction(error, pubKey);
}

GetContactPubKeyWebService::ResultCallback::~ResultCallback()
{
}

//void GetContactPubKeyWebService::ResultCallback::run(const QliqWebError& error, const std::string &pubKey)
//{
//}

} // web
} // qx

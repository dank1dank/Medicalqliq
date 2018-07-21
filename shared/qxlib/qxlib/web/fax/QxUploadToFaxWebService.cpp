#include "QxUploadToFaxWebService.hpp"

namespace qx {
namespace web {

UploadToFaxWebService::UploadToFaxWebService(WebClient *webClient) :
    UploadToQliqStorWebService(webClient)
{}

const char *UploadToFaxWebService::serverPath() const
{
    // Not implemented on server yet
    //return "/services/upload_to_fax";
    return UploadToQliqStorWebService::serverPath();
}

const char *UploadToFaxWebService::uploadTypeString() const
{
    return JSON_VALUE_UPLOAD_TARGET_FAX;
}

const char *UploadToFaxWebService::uploadTargetKeyString() const
{
    return "upload_target";
}

json11::Json::object UploadToFaxWebService::targetJson(const UploadToFaxWebService::UploadParams &up)
{
    json11::Json::object faxTarget = UploadToQliqStorWebService::targetJson(up);
    faxTarget["number"] = up.fax.number;
    if (!up.fax.voiceNumber.empty()) {
        faxTarget["voice_number"] = up.fax.voiceNumber;
    }
    if (!up.fax.organization.empty()) {
        faxTarget["organization"] = up.fax.organization;
    }
    if (!up.fax.contactName.empty()) {
        faxTarget["contact_name"] = up.fax.contactName;
    }
    if (!up.fax.subject.empty()) {
        faxTarget["subject"] = up.fax.subject;
    }
    if (!up.fax.body.empty()) {
        faxTarget["body"] = up.fax.body;
    }

    return faxTarget;
}

} // web
} // qx

#include "QxUploadToEmrWebService.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/model/fhir/FhirResources.hpp"

namespace qx {
namespace web {

UploadToEmrWebService::UploadToEmrWebService(WebClient *webClient) :
    UploadToQliqStorWebService(webClient)
{}

const char *UploadToEmrWebService::serverPath() const
{
    return "/services/upload_to_emr";
}

const char *UploadToEmrWebService::uploadTypeString() const
{
    return "EMR";
}

const char *UploadToEmrWebService::uploadTargetKeyString() const
{
    return "emr_target";
}

json11::Json::object UploadToEmrWebService::targetJson(const UploadToEmrWebService::UploadParams &up)
{
    json11::Json::object emrTarget = UploadToQliqStorWebService::targetJson(up);
    emrTarget["type"] = up.emr.type;
    emrTarget["uuid"] = up.emr.uuid;
    emrTarget["hl7id"] = up.emr.hl7Id;
    emrTarget["name"] = up.emr.name;
    return emrTarget;
}

void UploadToEmrWebService::setEmrTarget(UploadToQliqStorWebService::UploadParams *up, const fhir::Patient &patient)
{
    up->emr.type = "patient";
    up->emr.hl7Id = patient.hl7Id;
    up->emr.uuid = patient.uuid;
    up->emr.name = patient.displayName();
}

} // web
} // qx

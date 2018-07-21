#include "QxUploadToQliqStorWebService.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/log/QxLog.hpp"

namespace qx {
namespace web {

UploadToQliqStorWebService::UploadToQliqStorWebService(WebClient *webClient) :
    BaseWebService(webClient)
{}

void UploadToQliqStorWebService::uploadFile(const UploadParams &up, const MediaFile &file,
                                            ResultFunction resultCallback, IsCancelledFunction isCancelledFun)
{
    using namespace json11;

    Json::object json = requestJson(up);
    json["media_files"] = Json::array(1, file.toJson());

    m_webClient->postMultipartRequest(WebClient::FileServer, serverPath(), json,
                                      file.mime, file.fileName, file.encryptedFilePath,
                                      [this,resultCallback](const QliqWebError& error, const json11::Json& ) {
        resultCallback(error);
    }, isCancelledFun);
}

void UploadToQliqStorWebService::uploadFile(const UploadParams& uploadParams, const MediaFile& file, ResultCallback *resultCallback)
{
    uploadFile(uploadParams, file, [resultCallback](const QliqWebError& error) {
        resultCallback->run(new QliqWebError(error));
    });
}

json11::Json::object UploadToQliqStorWebService::requestJson(const UploadParams& up)
{
    using namespace json11;

    Json::object uploadedBy;
    uploadedBy["qliq_id"] = Session::instance().myQliqId();
    uploadedBy["user_name"] = Session::instance().myDisplayName();
    uploadedBy["user_email"] = Session::instance().myEmail();
    uploadedBy["user_agent"] = Session::instance().deviceName();

    Json::object json;
    json["uploaded_by"] = uploadedBy;
    json[uploadTargetKeyString()] = targetJson(up);
    json["upload_uuid"] = up.uploadUuid;
    json["upload_type"] = uploadTypeString();
    json["__debug_qliqstor_qliq_id"] = up.qliqStorQliqId;
    return json;
}

const char *UploadToQliqStorWebService::uploadTypeString() const
{
    return JSON_VALUE_UPLOAD_TARGET_QLIQSTOR;
}

const char *UploadToQliqStorWebService::uploadTargetKeyString() const
{
    return "upload_target";
}

json11::Json::object UploadToQliqStorWebService::targetJson(const UploadToQliqStorWebService::UploadParams &up)
{
    json11::Json::object uploadTarget;
    uploadTarget["qliqstor_qliq_id"] = up.qliqStorQliqId;
    if (!up.qliqStorDeviceUuid.empty()) {
        uploadTarget["device_uuid"] = up.qliqStorDeviceUuid;
    }
    return uploadTarget;
}

const char *UploadToQliqStorWebService::serverPath() const
{
    return "/services/upload_to_qliqstor";
}

bool UploadToQliqStorWebService::UploadParams::isEmrUpload() const
{
    return !emr.type.empty();
}

bool UploadToQliqStorWebService::UploadParams::isFaxUpload() const
{
    return !fax.number.empty();
}

UploadToQliqStorWebService::UploadParams UploadToQliqStorWebService::UploadParams::fromJson(const json11::Json &json)
{
    UploadParams ret;
    ret.uploadUuid = json["upload_uuid"].string_value();

    MediaFileUpload::ShareType shareType;
    json11::Json uploadTarget;
    std::string str = json["upload_type"].string_value();
    if (str == JSON_VALUE_UPLOAD_TARGET_FAX) {
        shareType = MediaFileUpload::ShareType::QliqStor;
        uploadTarget = json["upload_target"];
    } else if (str == JSON_VALUE_UPLOAD_TARGET_EMR) {
        shareType = MediaFileUpload::ShareType::Emr;
        uploadTarget = json["emr_target"];
    } else if (str == JSON_VALUE_UPLOAD_TARGET_FAX) {
        shareType = MediaFileUpload::ShareType::Fax;
        uploadTarget = json["emr_target"];
    } else {
        QXLOG_FATAL("Unexpected 'upload_type': %s", str.c_str());
        shareType = MediaFileUpload::ShareType::QliqStor;
    }
    ret.parseUploadTarget(json, shareType);
    return ret;
}

void UploadToQliqStorWebService::UploadParams::parseUploadTarget(const json11::Json &uploadTarget, MediaFileUpload::ShareType shareType)
{
    if (shareType == MediaFileUpload::ShareType::Emr) {
        emr.name = uploadTarget["name"].string_value();
        emr.hl7Id = uploadTarget["hl7id"].string_value();
        emr.uuid = uploadTarget["uuid"].string_value();
        emr.type = uploadTarget["type"].string_value();
    } else if (shareType == MediaFileUpload::ShareType::Fax) {
        fax.number = uploadTarget["number"].string_value();
        fax.voiceNumber = uploadTarget["voice_number"].string_value();
        fax.organization = uploadTarget["organization"].string_value();
        fax.contactName = uploadTarget["contact_name"].string_value();
        fax.subject = uploadTarget["subject"].string_value();
        fax.body = uploadTarget["body"].string_value();
    }
    qliqStorQliqId = uploadTarget["qliqstor_qliq_id"].string_value();
    qliqStorDeviceUuid = uploadTarget["device_uuid"].string_value();
}

void UploadToQliqStorWebService::UploadParams::parseUploadTarget(const std::string &jsonString, MediaFileUpload::ShareType shareType)
{
    std::string parsingError;
    auto json = json11::Json::parse(jsonString, parsingError);
    if (parsingError.empty()) {
        parseUploadTarget(json, shareType);
    } else {
        QXLOG_ERROR("Cannot parse upload target from JSON: %s", parsingError.c_str());
    }
}

UploadToQliqStorWebService::UploadParams UploadToQliqStorWebService::UploadParams::fromJsonString(const std::string &jsonString)
{
    UploadParams ret;
    std::string parsingError;
    auto json = json11::Json::parse(jsonString, parsingError);
    if (parsingError.empty()) {
        ret = fromJson(json);
    } else {
        QXLOG_ERROR("Cannot parse UploadParams from JSON: %s", parsingError.c_str());
    }
    return ret;
}

UploadToQliqStorWebService::UploadParams::UploadedBy UploadToQliqStorWebService::UploadParams::UploadedBy::fromJson(const json11::Json &json)
{
    UploadedBy ret;
    ret.name = json["user_name"].string_value();
    ret.qliqId = json["qliq_id"].string_value();
    ret.email = json["user_email"].string_value();
    ret.device = json["user_agent"].string_value();
    return ret;
}

UploadToQliqStorWebService::UploadParams::UploadedBy UploadToQliqStorWebService::UploadParams::UploadedBy::fromJsonString(const std::string &jsonString)
{
    UploadedBy ret;
    std::string parsingError;
    auto json = json11::Json::parse(jsonString, parsingError);
    if (parsingError.empty()) {
        ret = fromJson(json);
    } else {
        QXLOG_ERROR("Cannot parse UploadedBy from JSON: %s", parsingError.c_str());
    }
    return ret;
}

} // web
} // qx

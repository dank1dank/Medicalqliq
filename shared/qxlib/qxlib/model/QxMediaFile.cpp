#include "QxMediaFile.hpp"
#include "json11/json11.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/log/QxLog.hpp"
#ifdef _WIN32
#include "qxlib/util/strptime.h"
#endif
#define ISO_8601_TIMEFORMAT "%Y-%m-%dT%H:%M:%S"

namespace {

std::string helperTimestampToUiText(std::time_t timestamp)
{
    if (timestamp != 0) {
        std::tm *ptm = std::localtime(&timestamp);
        char buffer[32];
        // Mar 17, 2017\n4:15 PM
        //std::strftime(buffer, sizeof buffer, "%b %e, %Y\n%I:%M %p", ptm);
        std::strftime(buffer, sizeof buffer, "%b %d, %Y\n%I:%M %p", ptm);
        return reinterpret_cast<char *>(buffer);
    } else {
        return "";
    }
}

}

namespace qx  {

MediaFile::MediaFile() :
    databaseId(0), size(0), status(NormalStatus), timestamp(0)
{
}

bool MediaFile::isEmpty() const
{
    return fileName.empty();
}

std::string MediaFile::timestampToUiText() const
{
    return helperTimestampToUiText(timestamp);
}

std::string MediaFile::filePathForView() const
{
    if (!originalFilePath.empty() && Filesystem::exists(originalFilePath)) {
        return originalFilePath;
    } else if (!decryptedFilePath.empty() && Filesystem::exists(decryptedFilePath)) {
        return decryptedFilePath;
    } else {
        return "";
    }
}

bool MediaFile::isCanView() const
{
    bool ret = false;
    if (!originalFilePath.empty() && Filesystem::exists(originalFilePath)) {
        ret = true;
    } else if (!decryptedFilePath.empty() && Filesystem::exists(decryptedFilePath)) {
        ret = true;
    }
    return ret;
}

bool MediaFile::isCanDecrypt() const
{
    return (!encryptedFilePath.empty() && !key.empty() && Filesystem::exists(encryptedFilePath));
}

bool MediaFile::isCanDownload() const
{
    return !url.empty();
}

json11::Json MediaFile::toJson() const
{
    json11::Json::object json;
    json["mime"] = mime;
    json["encryptedKey"] = encryptedKey;
    json["publicKeyMd5"] = publicKeyMd5;
    json["mime"] = mime;
    json["fileName"] = fileName;
    json["encryptionMethod"] = encryptionMethod;
    json["size"] = (int)size;
    if (!checksum.empty()) {
        json["checksum"] = checksum;
    }
    if (!thumbnail.empty()) {
        json["thumbnail"] = thumbnail;
    }
    if (!url.empty()) {
        json["url"] = url;
    }

    if (!extraKeys.empty()) {
        json11::Json::array array;
        for (const ExtraKeyDescriptor& ek: extraKeys) {
            json11::Json::object obj;
            obj["encryptedKey"] = ek.encryptedKey;
            obj["qliqId"] = ek.qliqId;
            obj["publicKeyMd5"] = ek.publicKeyMd5;
            array.emplace_back(obj);
        }
        json["extraKeys"] = array;
    }

    if (timestamp != 0) {
        std::tm *ptm = std::localtime(&timestamp);
        char buffer[32];
        std::strftime(buffer, 32, ISO_8601_TIMEFORMAT, ptm);
        json["timestamp"] = buffer;
    }

    return json;
}

MediaFile MediaFile::fromJson(const json11::Json &json)
{
    MediaFile ret;
    ret.mime = json["mime"].string_value();
    ret.encryptedKey = json["encryptedKey"].string_value();
    ret.publicKeyMd5 = json["publicKeyMd5"].string_value();
    ret.key = json["key"].string_value();
    ret.fileName = json["fileName"].string_value();
    ret.encryptionMethod = json["encryptionMethod"].string_value();
    ret.checksum = json["checksum"].string_value();
    ret.thumbnail = json["thumbnail"].string_value();
    ret.url = json["url"].string_value();
    ret.size = json["size"].int_value();

    std::string timestampStr = json["timestamp"].string_value();
    if (!timestampStr.empty()) {
        struct tm tm;
        strptime(timestampStr.c_str(), ISO_8601_TIMEFORMAT, &tm);
        ret.timestamp = mktime(&tm);
    } else {
        ret.timestamp = std::time(nullptr);
    }

    json11::Json extraKeysJson = json["extraKeys"];
    if (extraKeysJson.is_array()) {
        for (const auto& ekJson: extraKeysJson.array_items()) {
            ExtraKeyDescriptor ek;
            ek.encryptedKey = ekJson["encryptedKey"].string_value();
            ek.qliqId = ekJson["qliqId"].string_value();
            ek.publicKeyMd5 = ekJson["publicKeyMd5"].string_value();
            ret.extraKeys.emplace_back(ek);
        }
    }

    return ret;
}

bool MediaFileUpload::isEmpty() const
{
    return uploadUuid.empty();
}

#ifndef QLIQ_STOR_CONTEXT

bool MediaFileUpload::isUploaded() const
{
    return status == FinalProcessingSuccesfulStatus;
}

bool MediaFileUpload::isFailed() const
{
    switch (status) {
    case UploadToCloudFailedStatus:
    case TargetNotFoundStatus:
    case PermanentQliqStorFailureErrorStatus:
    case TemporaryQliqStorFailureErrorStatus:
    case ThirdPartyFailureStatus:
        return true;
        break;
    default:
        return false;
    }
}

bool MediaFileUpload::canRetry() const
{
    return isFailed();// && (status != PermanentQliqStorFailureErrorStatus);
}

#endif // !QLIQ_STOR_CONTEXT

std::string MediaFileUpload::statusToUiText() const
{
    return statusToUiText(status, shareType);
}

std::string MediaFileUpload::statusToUiText(OnClientStatus status, ShareType shareType)
{
    switch (status) {
    case UnknownStatus:
        return "Unknown";    // this should not happen
    case PendingUploadStatus:
        return "Pending";
    case UploadingStatus:
        return "Uploading";
    case UploadedToCloudStatus:
        return "Uploaded to Qliq Cloud";
    case FinalProcessingSuccesfulStatus:
        return "Uploaded to QliqSTOR";
    case UploadToCloudFailedStatus:
        return "Uploading Failed (Network Error)";
    case TargetNotFoundStatus:
    case PermanentQliqStorFailureErrorStatus:
    case TemporaryQliqStorFailureErrorStatus:
        return "Uploading Failed (QliqSTOR Error)";
    case ThirdPartySuccessStatus:
        if (shareType == ShareType::Emr) {
            return "Uploaded to EMR";
        } else if (shareType == ShareType::Fax) {
            return "Fax Sent";
        } else {
            return "Uploaded to third party system";
        }
    case ThirdPartyFailureStatus:
        if (shareType == ShareType::Emr) {
            return "Uploading Failed (EMR Error)";
        } else if (shareType == ShareType::Fax) {
            return "Fax Failed";
        } else {
            return "Uploaded to third party system";
        }
    }
    return "Unknown (" + std::to_string(status) + ")";
}

MediaFileUpload::OnClientStatus MediaFileUpload::qliqStorStatusCodeToUploadStatus(MediaFileUpload::StatusForClient qliqStorCode)
{
    switch (qliqStorCode) {
    case StatusForClient::None:
        break;
    case StatusForClient::Success:
        return FinalProcessingSuccesfulStatus;
    case StatusForClient::ThirdPartySuccess:
        return ThirdPartySuccessStatus;
    case StatusForClient::ThirdPartyFailure:
        return ThirdPartyFailureStatus;
    case StatusForClient::PermanentFailure:
        return PermanentQliqStorFailureErrorStatus;
    case StatusForClient::TemporaryFailure:
        return TemporaryQliqStorFailureErrorStatus;
    }

    QXLOG_FATAL("Unexepcted QliqStorStatusCode: %d", qliqStorCode);
    return UnknownStatus;
}

#ifdef QLIQ_STOR_CONTEXT

std::string MediaFileUpload::statusToUiText(OnQliqStorStatus status, ShareType shareType)
{
    switch (status) {
    case OnQliqStorStatus::None:
        return "None";
    case OnQliqStorStatus::BadRequest:
        return "Failed (bad request from client)";
    case OnQliqStorStatus::Misconfiguration:
        return "Failed (misconfiguration)";
    case OnQliqStorStatus::TargetObjectNotFound:
        return "Failed (target object not found)";
    case OnQliqStorStatus::PublicKeyMismatch:
        return "Failed (public key mismatch)";
    case OnQliqStorStatus::QueuedForDownload:
        return "Queued (for download)";
    case OnQliqStorStatus::Downloading:
        return "Downloading";
    case OnQliqStorStatus::QueuedForThirdPartyUpload:
        return "Queued (for sending to third party)";
    case OnQliqStorStatus::RequestToThirdPartyFailed:
        return "Failed (could not send to third party)";
    case OnQliqStorStatus::WaitingForThirdPartyNotification:
        return "Waiting for confirmation (from third party)";
    case OnQliqStorStatus::DownloadFailed:
        return "Failed (download)";
    case OnQliqStorStatus::DecryptionFailed:
        return "Failed (decryption)";
    case OnQliqStorStatus::IOError:
        return "Failed (I/O error)";
    case OnQliqStorStatus::Stored:
        return "Stored";
    case OnQliqStorStatus::ThirdPartyFailed:
        if (shareType == ShareType::Emr) {
            return "Failed (EMR failure)";
        } else if (shareType == ShareType::Fax) {
            return "Failed (Fax failed)";
        } else {
            return "Failed (third party failure)";
        }
    case OnQliqStorStatus::ThirdPartySuccess:
        if (shareType == ShareType::Emr) {
            return "Uploaded to EMR";
        } else if (shareType == ShareType::Fax) {
            return "Fax Sent";
        } else {
            return "Success (third party confirmed)";
        }
    }
    return "Unknown (" + std::to_string(static_cast<int>(status)) + ")";
}

#endif // QLIQ_STOR_CONTEXT

MediaFileUpload MediaFileUpload::fromJson(const json11::Json &json)
{
    MediaFileUpload ret;
    ret.uploadUuid = json["upload_uuid"].string_value();
    ret.mediaFile = MediaFile::fromJson(json["media_files"][0]);

    json11::Json uploadTargetJson;
    std::string uploadType = json["upload_type"].string_value();
    if (uploadType == JSON_VALUE_UPLOAD_TARGET_QLIQSTOR) {
        uploadTargetJson = json["upload_target"];
        ret.shareType = ShareType::QliqStor;
        ret.mediaFile.status = MediaFile::UploadedToQliqStorStatus;
    } else if (uploadType == JSON_VALUE_UPLOAD_TARGET_EMR) {
        uploadTargetJson = json["emr_target"];
        ret.shareType = ShareType::Emr;
        ret.mediaFile.status = MediaFile::UploadedToEmrStatus;
    } else if (uploadType == JSON_VALUE_UPLOAD_TARGET_FAX) {
        uploadTargetJson = json["upload_target"];
        ret.shareType = ShareType::Fax;
        ret.mediaFile.status = MediaFile::UploadedToFaxStatus;
#if defined(QLIQ_SERVICE) || defined(QLIQ_STOR_MANAGER)
        ret.extra = uploadTargetJson["number"].string_value();
#endif
    } else {
        QXLOG_FATAL("Unsupported upload_type: '%s'", uploadType.c_str());
    }

    if (!uploadTargetJson.is_null()) {
        ret.rawUploadTargetJson = uploadTargetJson.dump();
        ret.qliqStorQliqId = uploadTargetJson["qliqstor_qliq_id"].string_value();
    }

#ifdef QLIQ_STOR_SERVICE
    const json11::Json& uploadedByJson = json["uploaded_by"];
    ret.rawUploadedByJson = uploadedByJson.dump();
    ret.uploadedByName = uploadedByJson["user_name"].string_value();
    ret.json = json.dump();
#endif
    return ret;
}

const char *MediaFileUpload::shareTypeToString(MediaFileUpload::ShareType shareType)
{
    switch (shareType) {
    case ShareType::QliqStor:
        return "qliqSTOR";
    case ShareType::Emr:
        return "EMR";
    case ShareType::Fax:
        return "FAX";
    default:
        return "Unknown";
    }
}

MediaFileUploadSubscriber::~MediaFileUploadSubscriber()
{

}

void MediaFileUploadNotifier::subscribe(MediaFileUploadSubscriber *subscriber)
{
    for (auto existing: m_subscribers) {
        if (existing == subscriber) {
            return;
        }
    }

    m_subscribers.push_back(subscriber);
}

void MediaFileUploadNotifier::unsubscribe(MediaFileUploadSubscriber *subscriber)
{
    for (auto it = m_subscribers.begin(); it != m_subscribers.end(); ++it) {
        if (*it == subscriber) {
            m_subscribers.erase(it);
            break;
        }
    }
}

MediaFileUploadNotifier *MediaFileUploadNotifier::instance()
{
    static MediaFileUploadNotifier inst;
    return &inst;
}

void MediaFileUploadNotifier::notify(MediaFileUploadSubscriber::Event event, int databaseId)
{
    for (auto sub: m_subscribers) {
        sub->onMediaFileUploadEvent(event, databaseId);
    }
}

MediaFileUploadEvent::MediaFileUploadEvent() :
    databaseId(0), uploadDatabaseId(0), type(NoneType), timestamp(0)
{
}

bool MediaFileUploadEvent::isEmpty() const
{
    return databaseId == 0;
}

std::string MediaFileUploadEvent::typeToString() const
{
    return MediaFileUploadEvent::typeToString(type);
}

std::string MediaFileUploadEvent::timestampToUiText() const
{
    return helperTimestampToUiText(timestamp);
}

std::string MediaFileUploadEvent::typeToString(MediaFileUploadEvent::Type type, MediaFileUpload::ShareType shareType)
{
    switch (type) {
#ifndef QLIQ_STOR_CONTEXT
    case CreatedType:
        return "Created";
    case SyncedType:
        return "Synced";
    case StartedType:
        return "Started Uploading";
    case CloudFailedType:
        return "Failed (Qliq Cloud)";
    case CloudSucceededType:
        return "Uploaded to Qliq Cloud";
    case QliqStorFailedType:
        return "Failed (QliqSTOR)";
    case QliqStorSucceededType:
        return "Uploaded to QliqSTOR";
    case ThirdPartyFailedType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "EMR upload failed";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Fax sending failed";
        } else {
            return "Third party failure";
        }
    case ThirdPartySucceededType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "EMR upload succeeded";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Fax sent";
        } else {
            return "Third party success";
        }
#else
    case QliqStorReceivedType:
        return "Received by QliqSTOR";
        break;
    case QliqStorReceivedDuplicateType:
        return "Duplicate Received by QliqSTOR";
        break;
    case QliqStorDownloadStartedType:
        return "Download Started";
        break;
    case QliqStorDownloadSucceededType:
        return "Download Succeeded";
        break;
    case QliqStorDownloadFailedType:
        return "Download Failed";
        break;
    case QliqStorFileDecryptedType:
        return "File Decrypted";
        break;
        // Events on qliqSTOR only (not available on clients)
    case QliqStorDecryptionFailedType:
        return "Decryption Failed";
        break;
    case QliqStorIOErrorType:
        return "I/O Error";
        break;
    case QliqStorEmrUploadFailedType:
        return "EMR Upload Failed";
        break;
    case QliqStorEmrUploadSucceededType:
        return "EMR Upload Succeeded";
        break;
    case QliqStorRequestToThirdPartyFailedType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "Could not send EMR request";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Could not send fax request";
        } else {
            return "Could not send request to third party";
        }
    case QliqStorRequestToThirdPartySentType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "Request sent to EMR";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Fax request sent";
        } else {
            return "Request sent to third party";
        }
    case QliqStorThirdPartyFailureType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "EMR upload failed";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Fax sending failed";
        } else {
            return "Third party failure";
        }
    case QliqStorThirdPartySucceessType:
        if (shareType == MediaFileUpload::ShareType::Emr) {
            return "EMR upload succeeded";
        } else if (shareType == MediaFileUpload::ShareType::Fax) {
            return "Fax sent";
        } else {
            return "Third party success";
        }
    case QliqStorTargetObjectNotFound:
        return "Target object not found";
#endif // QLIQ_STOR_CONTEXT
    }
    return "Unknown (" + std::to_string(type) + ")";
}

} // qx

#include "QxUploadToQliqStorTask.hpp"
#include "qxlib/controller/EncryptMediaFileTask.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/crypto/QxMd5.hpp"
#include "qxlib/dao/QxMediaFileDao.hpp"
#include "qxlib/dao/QxMediaFileUploadDao.hpp"
#include "qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp"
#include "qxlib/dao/sip/QxSipContactDao.hpp"
#include "qxlib/web/QxGetFileWebService.hpp"
#include "qxlib/web/emr/QxUploadToEmrWebService.hpp"
#include "qxlib/web/fax/QxUploadToFaxWebService.hpp"
#include "qxlib/controller/QxMediaFileManager.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/util/StringUtils.hpp"

namespace qx {

struct UploadToQliqStorTask::Private {
    UploadToQliqStorTask *parent;
    EncryptMediaFileTask encryptFileTask;
    web::UploadToQliqStorWebService uploadWebService;
    web::UploadToEmrWebService emrWebService;
    web::UploadToFaxWebService faxWebService;
    web::GetFileWebService getFileWebService;

    Private(UploadToQliqStorTask *parent) :
        parent(parent)
    {}

    int saveUpload(const UploadToQliqStorTask::UploadParams &up, const MediaFile& mediaFile, const web::QliqWebError& encryptionError);
    void continueWithEncryptedFile(const UploadToQliqStorTask::UploadParams &up, const MediaFile& mediaFile, int uploadDatabaseId, UploadToQliqStorTask::ResultFunction resultCallback);
    void continueWithDownloadedFile(MediaFileUpload upload, std::string publicKey, std::string savedFilePath, UploadToQliqStorTask::ResultFunction resultCallback);
    void onUploadToWebserverFinished(const MediaFile& mediaFile, int uploadDatabaseId, const std::string& uploadUuid, const web::QliqWebError& error, UploadToQliqStorTask::ResultFunction resultCallback);
};

UploadToQliqStorTask::UploadToQliqStorTask() :
    d(new Private(this))
{
}

UploadToQliqStorTask::~UploadToQliqStorTask()
{
    delete d;
}

void UploadToQliqStorTask::uploadConversation(const UploadToQliqStorTask::UploadParams &up, const ExportConversation::ConversationMessageList &list, const std::string &publicKey, UploadToQliqStorTask::ResultFunction resultCallback, UploadToQliqStorTask::IsCancelledFunction isCancelledFun)
{
    QXLOG_SUPPORT("Uploading conversation to qliqStor %s, upload uuid: %s", up.qliqStorQliqId.c_str(), up.uploadUuid.c_str());

    std::string rtfFilePath = MediaFileManager::randomEncryptedPath(up.uploadUuid) + ".rtf";
    bool ok = ExportConversation::toRtf(list, rtfFilePath);
    if (ok) {
        std::string fileName;
        if (!up.emr.name.empty()) {
            fileName = up.emr.name + " ";
        }
        if (!up.emr.hl7Id.empty()) {
            fileName += "(" + up.emr.hl7Id + ") ";
        } else if (!up.emr.uuid.empty()) {
            std::string uuid = up.emr.uuid;
            const std::string greenwayPrefix = "greenway-";
            if (StringUtils::startsWith(uuid, greenwayPrefix)) {
                uuid = uuid.substr(greenwayPrefix.size());
            }
            fileName += "(" + uuid + ") ";
        }
        fileName += "conversation.rtf";

        uploadFile(up, rtfFilePath, fileName, "", publicKey, [rtfFilePath, resultCallback](const web::QliqWebError& error) {
            Filesystem::removeFile(rtfFilePath);
            resultCallback(error);
        }, isCancelledFun);
    } else {
        if (resultCallback) {
            resultCallback(web::QliqWebError::applicationError("Cannot create RTF file of the conversation"));
        }
    }
}

void UploadToQliqStorTask::uploadFile(const UploadToQliqStorTask::UploadParams &up, const std::string &filePath, const std::string &displayFileName, const std::string &thumbnail, const std::string &publicKey, UploadToQliqStorTask::ResultFunction resultCallback, UploadToQliqStorTask::IsCancelledFunction isCancelledFun)
{
    QXLOG_SUPPORT("Uploading to qliqStor %s, upload uuid: %s, file name: %s, path: %s", up.qliqStorQliqId.c_str(), up.uploadUuid.c_str(), displayFileName.c_str(), filePath.c_str());

    std::string encryptedFilePath = MediaFileManager::randomEncryptedPath(up.uploadUuid);
    d->encryptFileTask.encrypt(filePath, encryptedFilePath, displayFileName, thumbnail, up.qliqStorQliqId, publicKey,
                               [=](const MediaFile& mediaFile, const web::QliqWebError& encryptionError) {

        int uploadDatabaseId = d->saveUpload(up, mediaFile, encryptionError);

        if (!encryptionError) {
            d->continueWithEncryptedFile(up, mediaFile, uploadDatabaseId, resultCallback);
        }
    }, [=](const web::QliqWebError& error) {
        resultCallback(error);
    });
}

void UploadToQliqStorTask::reuploadFile(const MediaFileUpload &upload, const std::string &publicKey, UploadToQliqStorTask::ResultFunction resultCallback, UploadToQliqStorTask::IsCancelledFunction isCancelledFun)
{
    QXLOG_SUPPORT("Reuploading to qliqStor %s, upload uuid: %s, file name: %s, status: %d", upload.qliqStorQliqId.c_str(), upload.uploadUuid.c_str(), upload.mediaFile.fileName.c_str(), upload.status);

    bool needToEncrypt = false;
    switch (upload.status) {
    case MediaFileUpload::TemporaryQliqStorFailureErrorStatus:
        needToEncrypt = true;
        break;
#ifdef QT_NO_DEBUG
    case MediaFileUpload::FinalProcessingSuccesfulStatus:
        resultCallback(web::QliqWebError::applicationError("This upload was successful. It does not need to be repeated."));
        return;
        break;
#endif
    case MediaFileUpload::PermanentQliqStorFailureErrorStatus:
    case MediaFileUpload::TargetNotFoundStatus:
        resultCallback(web::QliqWebError::applicationError("This is a permanent error. It cannot be retried."));
        return;
        break;
    }

    if (!needToEncrypt) {
        const MediaFile& mf = upload.mediaFile;
        if (!Filesystem::exists(mf.encryptedFilePath)) {
            QXLOG_SUPPORT("The encryptedFilePath does not exist", nullptr);
            needToEncrypt = true;
        }
    }

    UploadParams up;
    up.uploadUuid = upload.uploadUuid;
    up.parseUploadTarget(upload.rawUploadTargetJson, upload.shareType);

    if (needToEncrypt) {
        const MediaFile& mf = upload.mediaFile;
        std::string decryptedFilePath;

        if (Filesystem::exists(mf.originalFilePath)) {
            decryptedFilePath = mf.originalFilePath;
        } else if (Filesystem::exists(mf.decryptedFilePath)) {
            decryptedFilePath = mf.decryptedFilePath;
        } else {
            if (mf.url.empty()) {
                const char *message = "The decryptedFilePath does not exists and url is empty. Cannot continue";
                web::QliqWebError error = web::QliqWebError::applicationError(message);
                QXLOG_ERROR(message, nullptr);
                resultCallback(error);
                return;
            }
            QXLOG_SUPPORT("The decryptedFilePath does not exists, need to download file from url: %s", mf.url.c_str());

            MediaFileUploadDao::updateStatus(upload.databaseId, MediaFileUpload::PendingUploadStatus, "Downloading the file from web (device synced)");
            auto event = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
            MediaFileUploadNotifier::instance()->notify(event, upload.databaseId);

            std::string downloadedFilePath = Filesystem::temporaryFilePath();
            d->getFileWebService.call(mf.url, downloadedFilePath, [=](const web::QliqWebError& error, const std::string& savedFilePath) {
                if (error) {
                    QXLOG_ERROR("Cannot download file for upload uuid: %s, error: %s", up.uploadUuid.c_str(), error.toString().c_str());
                    resultCallback(error);
                } else {
                    d->continueWithDownloadedFile(upload, publicKey, savedFilePath, resultCallback);
                }
            });
            return;
        }

        std::string encryptedFilePath = MediaFileManager::randomEncryptedPath(up.uploadUuid);
        d->encryptFileTask.encrypt(mf.decryptedFilePath, encryptedFilePath, mf.fileName, mf.thumbnail, up.qliqStorQliqId, publicKey,
                                   [=](const MediaFile& mediaFile, const web::QliqWebError& error) {

            if (!error) {
                d->continueWithEncryptedFile(up, mediaFile, upload.databaseId, resultCallback);
            }

        }, [=](const web::QliqWebError& error) {
            resultCallback(error);
        });
    } else {
        d->continueWithEncryptedFile(up, upload.mediaFile, upload.databaseId, resultCallback);
    }
}

void UploadToQliqStorTask::uploadConversation(const UploadToQliqStorTask::UploadParams &uploadParams, const ExportConversation::ConversationMessageList &list, const std::string &publicKey, web::UploadToQliqStorWebService::ResultCallback *resultCallback)
{
    try {
        uploadConversation(uploadParams, list, publicKey, [resultCallback](const web::QliqWebError &error) {
            resultCallback->run(new web::QliqWebError(error));
        }, IsCancelledFunction());
    } catch(const std::exception& ex) {
        resultCallback->run(new web::QliqWebError(web::QliqWebError::applicationError(ex.what())));
    }
}

void UploadToQliqStorTask::uploadFile(const web::UploadToQliqStorWebService::UploadParams &uploadParams, const std::string &filePath, const std::string &displayFileName, const std::string &thumbnail, const std::string &publicKey, web::UploadToQliqStorWebService::ResultCallback *resultCallback)
{
    try {
        uploadFile(uploadParams, filePath, displayFileName, thumbnail, publicKey, [resultCallback](const web::QliqWebError &error) {
            resultCallback->run(new web::QliqWebError(error));
        }, IsCancelledFunction());
    } catch(const std::exception& ex) {
        resultCallback->run(new web::QliqWebError(web::QliqWebError::applicationError(ex.what())));
    }
}

void UploadToQliqStorTask::reupload(const MediaFileUpload &upload, const std::string &publicKey, web::UploadToQliqStorWebService::ResultCallback *resultCallback)
{
    try {
        reuploadFile(upload, publicKey, [resultCallback](const web::QliqWebError &error) {
            resultCallback->run(new web::QliqWebError(error));
        }, IsCancelledFunction());
    } catch(const std::exception& ex) {
        resultCallback->run(new web::QliqWebError(web::QliqWebError::applicationError(ex.what())));
    }
}

void UploadToQliqStorTask::processChangeNotification(const std::string &subject, const std::string &payload)
{
    if (subject != "qliqstor-upload-status") {
        QXLOG_ERROR("Unsupported CN subject: %s", subject.c_str());
        return;
    }

    std::string parsingError;
    json11::Json json = json11::Json::parse(payload, parsingError);
    if (!parsingError.empty()) {
        QXLOG_ERROR("Cannot parse CN payload JSON: %s", parsingError.c_str());
        return;
    }

    std::string uploadType = json["upload_type"].string_value();
    if (uploadType != "qliqStor" && uploadType != "EMR" && uploadType != "FAX") {
        QXLOG_ERROR("Unsupported upload_type: '%s'", uploadType.c_str());
        return;
    }

    MediaFileUpload upload = MediaFileUpload::fromJson(json);

    MediaFileUpload::StatusForClient statusForClient = static_cast<MediaFileUpload::StatusForClient>(json["status"]["code"].int_value());
    upload.status = MediaFileUpload::qliqStorStatusCodeToUploadStatus(statusForClient);

    int detailCode = json["status"]["detailCode"].int_value();
    if (detailCode == 422) {
        bool shouldDeletePublicKey = true;
        // TODO: check mediaFiles[0].publicKeyMd5 with PK in database before deleting it
//        if (!upload.mediaFile.publicKeyMd5.empty()) {
//            auto qliqStorContact = sip::QxSipContactDao::selectOneBy(sip::QxSipContactDao::QliqIdColumn, upload.qliqStorQliqId);
//            if (!qliqStorContact.publicKey.isEmpty()) {
//                if (md5(qliqStorContact.publicKey) != upload.mediaFile.publicKeyMd5) {
//                    shouldDeletePublicKey = false;
//                }
//            }
//        }

        if (shouldDeletePublicKey) {
            // We used wrong public key, let's delete it immediately
            qx::SipContactDao::deletePublicKey(upload.qliqStorQliqId);
        }
    }

    upload.statusMessage = "qliqSTOR: " + json["status"]["message"].string_value();
    upload.statusMessage += " (code: " + std::to_string(static_cast<int>(statusForClient));
    upload.statusMessage += ", detail code: " + std::to_string(detailCode) + ")";

    Crypto *crypto = Crypto::instance();
    if (crypto) {
        for (const MediaFile::ExtraKeyDescriptor& ek: upload.mediaFile.extraKeys) {
            if (ek.publicKeyMd5 == crypto->publicKeyMd5()) {
                bool ok;
                upload.mediaFile.key = crypto->decryptFromBase64ToString(ek.encryptedKey, &ok);
                if (!ok) {
                    QXLOG_ERROR("Could not decrypt key from extraKeys", nullptr);
                }
            }
        }
    }
    
    QXLOG_SUPPORT("Got qliqstor-upload-status CN for upload uuid: %s, code: %d, detail: %d, message: %s", upload.uploadUuid.c_str(), static_cast<int>(statusForClient), detailCode, upload.statusMessage.c_str());

    MediaFileUploadSubscriber::Event subscriberEvent;
    MediaFileUpload existingUpload = MediaFileUploadDao::selectOneBy(MediaFileUploadDao::UploadUuidColumn, upload.uploadUuid);
    if (existingUpload.isEmpty()) {
        // This upload was created on another device
        MediaFileDao::insert(&upload.mediaFile);
        MediaFileUploadDao::insert(&upload);
        subscriberEvent = MediaFileUploadSubscriber::CreatedMediaFileUploadEvent;
    } else {
        upload.databaseId = existingUpload.databaseId;
        upload.mediaFile.databaseId = existingUpload.mediaFile.databaseId;
        existingUpload.mediaFile = MediaFileDao::selectOneBy(MediaFileDao::IdColumn, std::to_string(existingUpload.mediaFile.databaseId));
        if (upload.mediaFile.checksum == existingUpload.mediaFile.checksum) {
            // This is the same file we have, only update url in case it is empty
            MediaFileDao::updateUrl(existingUpload.mediaFile.databaseId, upload.mediaFile.url);
        } else {
            // The file was re-encrytped, so update key also
            Filesystem::removeFile(existingUpload.mediaFile.encryptedFilePath);
            MediaFileDao::update(upload.mediaFile);
        }
        MediaFileUploadDao::updateStatus(upload);
        subscriberEvent = MediaFileUploadSubscriber::UpdatedMediaFileUploadEvent;
    }

    MediaFileUploadEvent uploadEvent;
    uploadEvent.uploadDatabaseId = upload.databaseId;
    uploadEvent.timestamp = std::time(nullptr);

    if (subscriberEvent == MediaFileUploadSubscriber::CreatedMediaFileUploadEvent) {
        uploadEvent.type = MediaFileUploadEvent::SyncedType;
        MediaFileUploadEventDao::insert(&uploadEvent);
        uploadEvent.databaseId = 0;
    }
    uploadEvent.message = upload.statusMessage;

    switch (statusForClient) {
    case qx::MediaFileUpload::StatusForClient::Success:
        uploadEvent.type = MediaFileUploadEvent::QliqStorSucceededType;
        break;
    case qx::MediaFileUpload::StatusForClient::ThirdPartySuccess:
        uploadEvent.type = MediaFileUploadEvent::ThirdPartySucceededType;
        break;
    case qx::MediaFileUpload::StatusForClient::ThirdPartyFailure:
        uploadEvent.type = MediaFileUploadEvent::ThirdPartyFailedType;
        break;
    case qx::MediaFileUpload::StatusForClient::PermanentFailure:
    case qx::MediaFileUpload::StatusForClient::TemporaryFailure:
        uploadEvent.type = MediaFileUploadEvent::QliqStorFailedType;
        break;
    case qx::MediaFileUpload::StatusForClient::None:
    default:
        // should never happen
        QXLOG_FATAL("Received unexpected StatusForClient: %d for upload uuid: %s", static_cast<int>(statusForClient), upload.uploadUuid.c_str());
        uploadEvent.type = MediaFileUploadEvent::NoneType;
        break;
    }
    MediaFileUploadEventDao::insert(&uploadEvent);

    MediaFileUploadNotifier::instance()->notify(subscriberEvent, upload.databaseId);
}

int UploadToQliqStorTask::Private::saveUpload(const UploadToQliqStorTask::UploadParams &up, const MediaFile &mediaFile, const web::QliqWebError& encryptionError)
{
    MediaFileUpload upload;
    upload.uploadUuid = up.uploadUuid;
    upload.qliqStorQliqId = up.qliqStorQliqId;
    {
        json11::Json uploadTargetJson;
        if (up.isEmrUpload()) {
            upload.shareType = MediaFileUpload::ShareType::Emr;
            uploadTargetJson = emrWebService.targetJson(up);
        } else if (up.isFaxUpload()) {
            upload.shareType = MediaFileUpload::ShareType::Fax;
            uploadTargetJson = faxWebService.targetJson(up);
        } else {
            upload.shareType = MediaFileUpload::ShareType::QliqStor;
            uploadTargetJson = uploadWebService.targetJson(up);
        }
        upload.rawUploadTargetJson = uploadTargetJson.dump();
    }

    upload.mediaFile = mediaFile;
    if (up.isEmrUpload()) {
        upload.mediaFile.status = MediaFile::UploadedToEmrStatus;
    } else {
        upload.mediaFile.status = MediaFile::UploadedToQliqStorStatus;
    }
    upload.status = encryptionError ? MediaFileUpload::UploadToCloudFailedStatus : MediaFileUpload::PendingUploadStatus;
    upload.statusMessage = "";

    MediaFileDao::insert(&upload.mediaFile);
    MediaFileUploadDao::insert(&upload);

    MediaFileUploadEvent uploadEvent;
    uploadEvent.uploadDatabaseId = upload.databaseId;
    uploadEvent.timestamp = std::time(nullptr);
    uploadEvent.type = MediaFileUploadEvent::CreatedType;
    MediaFileUploadEventDao::insert(&uploadEvent);

    if (encryptionError) {
        uploadEvent.databaseId = 0;
        uploadEvent.type = MediaFileUploadEvent::CloudFailedType;
        uploadEvent.message = encryptionError.toString();
        MediaFileUploadEventDao::insert(&uploadEvent);
    }

    auto subscriberEvent = MediaFileUploadSubscriber::Event::CreatedMediaFileUploadEvent;
    MediaFileUploadNotifier::instance()->notify(subscriberEvent, upload.databaseId);

    return upload.databaseId;
}

void UploadToQliqStorTask::Private::continueWithEncryptedFile(const UploadToQliqStorTask::UploadParams &up, const MediaFile &mediaFile, int uploadDatabaseId, UploadToQliqStorTask::ResultFunction resultCallback)
{
    MediaFileUpload upload = MediaFileUploadDao::selectOneBy(MediaFileUploadDao::IdColumn, std::to_string(uploadDatabaseId));
    if (upload.isEmpty()) {
        QXLOG_ERROR("Cannot load MediaFileUpload with id: %d", uploadDatabaseId);
        resultCallback(web::QliqWebError::applicationError("Cannot load MediaFileUpload from database"));
        return;
    }

    upload.mediaFile = mediaFile;
    MediaFileDao::update(upload.mediaFile);

    upload.status = MediaFileUpload::UploadingStatus;
    upload.statusMessage = "";
    MediaFileUploadDao::updateStatus(upload);

    MediaFileUploadEvent uploadEvent;
    uploadEvent.uploadDatabaseId = uploadDatabaseId;
    uploadEvent.timestamp = std::time(nullptr);
    uploadEvent.type = MediaFileUploadEvent::StartedType;
    MediaFileUploadEventDao::insert(&uploadEvent);

    auto subscriberEvent = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
    MediaFileUploadNotifier::instance()->notify(subscriberEvent, upload.databaseId);

    web::UploadToQliqStorWebService *serviceImpl = &uploadWebService;

    if (up.isEmrUpload()) {
        serviceImpl = &emrWebService;
    } else if (up.isFaxUpload()) {
        serviceImpl = &faxWebService;
    }

    serviceImpl->uploadFile(up, mediaFile, [=](const web::QliqWebError& error) {
        onUploadToWebserverFinished(mediaFile, uploadDatabaseId, up.uploadUuid, error, resultCallback);
    });
}

void UploadToQliqStorTask::Private::continueWithDownloadedFile(MediaFileUpload upload, std::string publicKey, std::string savedFilePath, UploadToQliqStorTask::ResultFunction resultCallback)
{
    upload.mediaFile.decryptedFilePath = Filesystem::temporaryFilePath("." + FileInfo(upload.mediaFile.fileName).extension());
    auto size = Crypto::aesDecryptFile(savedFilePath, upload.mediaFile.decryptedFilePath, upload.mediaFile.key, nullptr);
    if (size <= 0) {
        QXLOG_ERROR("Cannot decrypt file", nullptr);

        MediaFileUploadDao::updateStatus(upload.databaseId, MediaFileUpload::UploadToCloudFailedStatus, "Cannot decrypt the downloade file (device sync)");
        auto event = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
        MediaFileUploadNotifier::instance()->notify(event, upload.databaseId);
        return;
    } else {
        MediaFileDao::update(upload.mediaFile);
        parent->reuploadFile(upload, publicKey, resultCallback);
    }
}

void UploadToQliqStorTask::Private::onUploadToWebserverFinished(const MediaFile &mediaFile, int uploadDatabaseId, const std::string& uploadUuid, const web::QliqWebError &error, UploadToQliqStorTask::ResultFunction resultCallback)
{
    MediaFileUpload::OnClientStatus status;
    std::string message;
    if (error) {
        status = MediaFileUpload::UploadToCloudFailedStatus;
        message = "Upload to cloud failed: " + error.toString();
        QXLOG_ERROR("Upload to webserver failed, upload uuid: %s, file name: %s, error: %s", uploadUuid.c_str(), mediaFile.fileName.c_str(), error.toString().c_str());
    } else {
        status = MediaFileUpload::UploadedToCloudStatus;
    }
    MediaFileUploadDao::updateStatus(uploadDatabaseId, status, message);

    MediaFileUploadEvent uploadEvent;
    uploadEvent.uploadDatabaseId = uploadDatabaseId;
    uploadEvent.timestamp = std::time(nullptr);
    if (error) {
        uploadEvent.type = MediaFileUploadEvent::CloudFailedType;
        uploadEvent.message = message;
    } else {
        uploadEvent.type = MediaFileUploadEvent::CloudSucceededType;
    }
    MediaFileUploadEventDao::insert(&uploadEvent);

    resultCallback(error);

    auto subscriberEvent = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
    MediaFileUploadNotifier::instance()->notify(subscriberEvent, uploadDatabaseId);
}

} // qx

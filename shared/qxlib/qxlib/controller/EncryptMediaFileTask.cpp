#include "EncryptMediaFileTask.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/crypto/QxMd5.hpp"
#include "qxlib/web/QxGetContactPubkeyWebService.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/dao/sip/QxSipContactDao.hpp"
#include "qxlib/controller/QxMediaFileManager.hpp"

namespace qx {

struct EncryptMediaFileTask::Private {
    web::GetContactPubKeyWebService *getPubKeyService;

    Private() :
        getPubKeyService(nullptr)
    {}

    ~Private()
    {
        delete getPubKeyService;
    }
};

EncryptMediaFileTask::EncryptMediaFileTask() :
    d(new Private())
{}

EncryptMediaFileTask::~EncryptMediaFileTask()
{
    delete d;
}

void EncryptMediaFileTask::encrypt(const std::string &filePath, const std::string& encryptedFilePath,
                                   const std::string &displayFileName, const std::string& thumbnail,
                                   const std::string& recipientQliqId, std::string publicKey,
                                   SuccessFunction successCallback, ErrorFunction errorCallback)
{
    auto makeMediaFile = [](const std::string &filePath, const std::string &displayFileName, const std::string& thumbnail) {
        FileInfo fileInfo{filePath};
        MediaFile mediaFile;
        mediaFile.timestamp = std::time(nullptr);
        mediaFile.encryptionMethod = "1";
        mediaFile.fileName = displayFileName.empty() ? fileInfo.fileName() : displayFileName;
        mediaFile.originalFilePath = filePath;
        mediaFile.thumbnail = thumbnail;
        mediaFile.mime = fileInfo.mime();
        return mediaFile;
    };

    if (publicKey.empty()) {
        auto qliqStorContact = qx::SipContactDao::selectOneBy(qx::SipContactDao::QliqIdColumn, recipientQliqId);
        if (qliqStorContact.isEmpty()) {
            QXLOG_ERROR("Cannot find SipContact in db for qliq_id: %s", recipientQliqId.c_str());
        }
        if (qliqStorContact.publicKey.empty()) {
            QXLOG_SUPPORT("Cannot find pubkey in db for qliq_id: %s, will try to download now", recipientQliqId.c_str());

            if (!d->getPubKeyService) {
                d->getPubKeyService = new web::GetContactPubKeyWebService();
            }

            d->getPubKeyService->call(recipientQliqId, [=](const web::QliqWebError& error, const std::string& pubKey) {
                if (error) {
                    QXLOG_ERROR("Cannot get qliqStor's pubkey from webserver: %s", error.toString().c_str());

                    MediaFile mediaFile = makeMediaFile(filePath, displayFileName, thumbnail);
                    mediaFile.decryptedFilePath = MediaFileManager::computeDecryptedPath(&mediaFile);
                    try {
                        Filesystem::copy(filePath, mediaFile.decryptedFilePath);
                        auto encryptionError = web::QliqWebError::fromMessage("Cannot get qliqSTOR's (" + recipientQliqId + ") public key: " + error.toString());
                        successCallback(mediaFile, encryptionError);

                    } catch (const std::runtime_error& ex) {
                        errorCallback(web::QliqWebError::applicationError(std::string("Cannot save file: ") + ex.what()));
                    }
                } else {
                    encrypt(filePath, encryptedFilePath, displayFileName, thumbnail, recipientQliqId, pubKey, successCallback, errorCallback);
                }
            });
            return;
        }

        publicKey = qliqStorContact.publicKey;
    }

    bool ok;
    std::string base64KeyString;
    try {
        MediaFile mediaFile = makeMediaFile(filePath, displayFileName, thumbnail);
        mediaFile.size = Crypto::aesEncryptFile(filePath, encryptedFilePath, &base64KeyString, &mediaFile.checksum);
        mediaFile.encryptedFilePath = encryptedFilePath;

        mediaFile.encryptedKey = Crypto::encryptToBase64WithKey(base64KeyString.c_str(),
                                                                base64KeyString.size(), publicKey,
                                                                &ok);
        if (!ok) {
            throw std::runtime_error("Cannot encrypt AES key using qliqStor's PubKey");
        }
        mediaFile.publicKeyMd5 = md5(publicKey);
        mediaFile.key = base64KeyString;

        MediaFile::ExtraKeyDescriptor ek;
        ek.qliqId = Session::instance().myQliqId();
        ek.publicKeyMd5 = Crypto::instance()->publicKeyMd5();
        ek.encryptedKey = Crypto::encryptToBase64WithKey(base64KeyString.c_str(),
                                                         base64KeyString.size(), Crypto::instance()->publicKey(),
                                                         &ok);
        if (ok) {
            mediaFile.extraKeys.emplace_back(ek);
        } else {
            QXLOG_ERROR("Cannot encrypt AES key using my public key", nullptr);
        }

        successCallback(mediaFile, web::QliqWebError());

    } catch (const std::runtime_error& e) {
        Filesystem::removeFile(encryptedFilePath);
        web::QliqWebError qwe;
        qwe.networkErrorOrHttpStatus = web::QliqWebError::ApplicationError;
        qwe.message = "C++ exception: ";
        qwe.message += e.what();
        QXLOG_ERROR("Cannot encrypt file: %s, C++ exception: %s", filePath.c_str(), e.what());
        errorCallback(qwe);
    } catch (...) {
        Filesystem::removeFile(encryptedFilePath);
        web::QliqWebError qwe;
        qwe.networkErrorOrHttpStatus = web::QliqWebError::ApplicationError;
        qwe.message = "Cannot encryptfile (c++ unknown exception (...))";
        QXLOG_ERROR("Cannot encrypt file: %s, unknown C++ exception", filePath.c_str());
        errorCallback(qwe);
    }
}

} // qx

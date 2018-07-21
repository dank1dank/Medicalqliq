#include "QxMediaFileManager.hpp"
#include "qxlib/dao/QxMediaFileDao.hpp"
#include "qxlib/dao/QxMediaFileUploadDao.hpp"
#include "qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/web/QxGetFileWebService.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/log/QxLog.hpp"

namespace qx {

namespace {

std::string s_mediaFilesDirPath;
std::string s_decryptedDirPath;

} // anonymous namespace

MediaFileManager::MediaFileManager()
{

}

bool MediaFileManager::decrypt(MediaFile *mediaFile)
{
    if (!mediaFile->isCanDecrypt()) {
        return false;
    }

    auto decryptedPath = computeDecryptedPath(mediaFile);
    int size = 0;
    try {
        size = Crypto::aesDecryptFile(mediaFile->encryptedFilePath, decryptedPath, mediaFile->key);
    } catch (const std::exception& ex) {
        QXLOG_ERROR("Cannot decrypt QxMediaFile: %s", ex.what());
    }

    if (size <= 0) {
        Filesystem::removeFile(decryptedPath);
        return false;
    }

    mediaFile->decryptedFilePath = decryptedPath;
    MediaFileDao::updateDecryptedFilePath(mediaFile->databaseId, decryptedPath);
    notifyUploadUpdatedOfMediaFile(mediaFile->databaseId);
    return true;
}

bool MediaFileManager::download(MediaFile *mediaFile, ResultFunction callback)
{
    if (!mediaFile->isCanDownload()) {
        callback(mediaFile->databaseId, "The file is no longer available (no URL)");
        return false;
    }

    // if present, delete existing file
    removeDecrypted(mediaFile);

    int databaseId = mediaFile->databaseId;
    std::string downloadToPath = computeEncryptedPath(mediaFile);
    web::GetFileWebService *service = new web::GetFileWebService();
    service->call(mediaFile->url, downloadToPath, [=](const web::QliqWebError& error, const std::string& savedFilePath) {
        std::string errorMessage;
        if (error) {
            errorMessage = error.toString();
        } else {
            MediaFileDao::updateEncryptedFilePath(databaseId, savedFilePath);
            notifyUploadUpdatedOfMediaFile(databaseId);
        }
        callback(databaseId, errorMessage);
        delete service;
    });
    return true;
}

bool MediaFileManager::download(MediaFile *mediaFile, MediaFileManager::ResultCallback *resultCallback)
{
    return download(mediaFile, [resultCallback](int mediaFileId, const std::string& error) {
        resultCallback->run(mediaFileId, error);
    });
}

bool MediaFileManager::removeDecrypted(MediaFile *mediaFile)
{
    if (mediaFile->decryptedFilePath.empty()) {
        return true;
    } else {
        Filesystem::removeFile(mediaFile->decryptedFilePath);
        mediaFile->decryptedFilePath = "";
        return MediaFileDao::updateDecryptedFilePath(mediaFile->databaseId, mediaFile->decryptedFilePath);
    }
}

bool MediaFileManager::remove(MediaFile *mediaFile)
{
    Filesystem::removeFile(mediaFile->encryptedFilePath);
    Filesystem::removeFile(mediaFile->decryptedFilePath);
    mediaFile->encryptedFilePath.clear();
    mediaFile->decryptedFilePath.clear();

    bool ok = MediaFileDao::delete_(MediaFileDao::IdColumn, std::to_string(mediaFile->databaseId));
    mediaFile->databaseId = 0;
    return ok;
}

bool MediaFileManager::remove(MediaFileUpload *upload)
{
    bool ok;
    ok = MediaFileUploadDao::delete_(MediaFileUploadDao::IdColumn, std::to_string(upload->databaseId));
    if (ok) {
        ok &= MediaFileUploadEventDao::delete_(MediaFileUploadEventDao::UploadIdColumn, std::to_string(upload->databaseId));
        ok &= remove(&upload->mediaFile);

        auto event = MediaFileUploadSubscriber::Event::DeletedMediaFileUploadEvent;
        MediaFileUploadNotifier::instance()->notify(event, upload->databaseId);
    }
    return ok;
}

bool MediaFileManager::setArchived(MediaFileUpload *upload, bool archived)
{
    bool ok = false;
    if (archived) {
        ok = MediaFileDao::updateColumn(MediaFileDao::StatusColumn, std::to_string(MediaFile::ArchivedStatus), upload->mediaFile);
    } else {
        // This is simplification as it doesn't restor the orignal UploadedToXStatus
        // but we don't make use of it anyway
        ok = MediaFileDao::updateColumn(MediaFileDao::StatusColumn, std::to_string(MediaFile::NormalStatus), upload->mediaFile);
    }
    if (ok) {
        auto event = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
        MediaFileUploadNotifier::instance()->notify(event, upload->databaseId);
    }
    return ok;
}

std::string MediaFileManager::randomEncryptedPath(std::string proposedFileName)
{
    std::string uniquePart = proposedFileName;
    if (uniquePart.empty()) {
        uniquePart = Filesystem::randomFileName(10);
    }
    std::string encryptedPath = Filesystem::join(mediaFilesDirPath(), uniquePart);

    if (!Filesystem::exists(encryptedPath)) {
        return encryptedPath;
    } else {
        return randomEncryptedPath();
    }
}

std::string MediaFileManager::computeEncryptedPath(const MediaFile *mediaFile)
{
    return randomEncryptedPath(mediaFile->url);
}

std::string MediaFileManager::computeDecryptedPath(const MediaFile *mediaFile)
{
    std::string uniquePart = mediaFile->url;
    if (uniquePart.empty()) {
        uniquePart = Filesystem::randomFileName(10);
    }
    FileInfo fileInfo(mediaFile->fileName);
    std::string fileName = fileInfo.baseName() + "-" + uniquePart + fileInfo.extension(true);
    std::string decryptedDir = decryptedDirPath();
    if (!Filesystem::existsDir(decryptedDir)) {
        Filesystem::mkpath(decryptedDir);
    }
    return Filesystem::join(decryptedDir, fileName);
}

std::string MediaFileManager::mediaFilesDirPath()
{
    if (!s_mediaFilesDirPath.empty()) {
        return s_mediaFilesDirPath;
    } else {
        std::string ret = Filesystem::join(Session::instance().dataDirectoryPath(), "media_files");
        if (!Filesystem::existsDir(ret)) {
            Filesystem::mkpath(ret);
        }
        return ret;
    }
}

void MediaFileManager::setMediaFilesDirPath(const std::string &path)
{
    s_mediaFilesDirPath = path;
}

std::string MediaFileManager::decryptedDirPath()
{
    std::string ret = s_decryptedDirPath;

    if (ret.empty()) {
        ret = Filesystem::join(mediaFilesDirPath(), "decrypted");
    }

    return ret;
}

void MediaFileManager::setDecryptedDirPath(const std::string &path)
{
    s_decryptedDirPath = path;
}

void MediaFileManager::onUserSessionStarted()
{
#ifndef QLIQ_STOR_CONTEXT
    MediaFileUploadDao::updateUploadingStatusToFailedStatus();
#endif
}

void MediaFileManager::notifyUploadUpdatedOfMediaFile(int mediaFileId)
{
    auto upload = MediaFileUploadDao::selectOneWithMediaFileId(mediaFileId);
    if (!upload.isEmpty()) {
        auto event = MediaFileUploadSubscriber::Event::UpdatedMediaFileUploadEvent;
        MediaFileUploadNotifier::instance()->notify(event, upload.databaseId);
    }
}

} // qx

#ifndef QXMEDIAFILEMANAGER_HPP
#define QXMEDIAFILEMANAGER_HPP
#include <functional>
#include  "qxlib/model/QxMediaFile.hpp"

namespace qx {

class MediaFileManager
{
public:
    MediaFileManager();

#ifndef SWIG
    typedef std::function<void(int mediaFileId, const std::string& error)> ResultFunction;
    static bool download(MediaFile *mediaFile, ResultFunction callback);
#endif
    class ResultCallback {
    public:
        virtual ~ResultCallback() {}
        virtual void run(int mediaFileId, const std::string& error) = 0;
    };
    static bool download(MediaFile *mediaFile, ResultCallback *resultCallback);

    static bool decrypt(MediaFile *mediaFile);

    /// Removes the decrypted file from disk and updates QxMediaFile in database
    static bool removeDecrypted(MediaFile *mediaFile);
    /// Removes the QxMediaFile from database and related files from disk
    static bool remove(MediaFile *mediaFile);
    /// Removes the QxMediaFileUpload, child QxMediaFile from database and related files from disk
    static bool remove(MediaFileUpload *upload);

    /// Actually we archive MediaFile not upload but this method takes upload
    /// so it can send notification to UI about update
    static bool setArchived(MediaFileUpload *upload, bool archived);

    static std::string randomEncryptedPath(std::string proposedFileName = "");
    static std::string computeEncryptedPath(const MediaFile *mediaFile);
    static std::string computeDecryptedPath(const MediaFile *mediaFile);

    /// Returns path to directory when encrypted media files are stored
    static std::string mediaFilesDirPath();
    static void setMediaFilesDirPath(const std::string& path);

    /// Returns path to directory when decrypted media files are stored
    static std::string decryptedDirPath();
    static void setDecryptedDirPath(const std::string& path);

    static void onUserSessionStarted();

private:
    static void notifyUploadUpdatedOfMediaFile(int mediaFileId);
};

} // qx

#endif // QXMEDIAFILEMANAGER_HPP

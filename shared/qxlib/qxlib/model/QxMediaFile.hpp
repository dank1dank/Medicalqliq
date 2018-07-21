#ifndef QXMEDIAFILE_HPP
#define QXMEDIAFILE_HPP
#include <string>
#include <vector>
#include <ctime>

#ifndef SWIG
#define JSON_VALUE_UPLOAD_TARGET_QLIQSTOR "qliqStor"
#define JSON_VALUE_UPLOAD_TARGET_EMR "EMR"
#define JSON_VALUE_UPLOAD_TARGET_FAX "FAX"
#endif // !SWIG

#if defined(QLIQ_SERVICE) || defined(QLIQ_STOR_MANAGER)
#define QLIQ_STOR_CONTEXT
#endif

namespace json11 {
class Json;
}

namespace qx  {

enum Params {
    FilePath,
};

struct MediaFile {
    enum MediaType {
        UnknownMediaType,
        DocumentMediaType,
        AllMediaType,
        ImageMediaType,
        AudioMediaType,
        VideoMediaType
    };
    enum Direction {
        SentDirection,
        ReceivedDirection
    };

    // This enum is used to identify actual media file type
    // i.e. image, txt, pdf, audio, video etc.
    enum FileType {
        Unknown,
        PlainText,
        Pdf,
        Ppt,
        Excel,
        Rtf,
        Doc,
        Binary,
        Zip,
        Image,
        Audio,
        Video
    };

    int databaseId;
    std::string mime;
    std::string key;                    // decrypted key
    std::string fileName;
    unsigned long size;
    std::string checksum;
    std::string thumbnail;
    std::string url;

    /*
     * We have 3 file paths related to single QxMediaFile:
     * 1. encrypted - the file encrypted for upload (owned by qliq app, delete with QxMediaFile)
     * 2. decrypted - the file decrypted for viewing (owned by qliq app, delete with QxMediaFile)
     * 3. original - the original (source) file (NOT owned by qliq app, do NOT delete with QxMediaFile)
     *
     * Example:
     * qxMediaFile.originalFilePath = "<user folder>\camera\photo1.jpg";    // not managed by qliq app!
     * qxMediaFile.encryptedFilePath = "<qliq app folder>\uploads\<uuid>.bin";
     * qxMediaFile.decryptedFilePath = "<qliq temp folder>\photo1.jpg";
     *
     * When trying to open QxMediaFile:
     * 1. Check if originalFilePath exists
     * 1.1 Open (do NOT delete on exit, this file is not ours)
     *
     * 2. Check if decryptedFilePath exists
     * 2.1 Open (can delete on exit or keep to reuse later)
     * 2.2 If you decide to delete on exit then set decryptedFilePath=null and save in db
     *
     * 3. Check if encryptedFilePath exists
     * 3.1 Decrypt to decryptedFilePath using 'key' attribute and save to db
     * 3.2 Open
     * 3.3 Goto case 2.2
     *
     * 4. if none of 3 paths exists:
     * 4.1 Download the file from 'url' attribute to encryptedFilePath and save in db
     * 4.2 Goto case 3.1
     */
    std::string encryptedFilePath;
    std::string decryptedFilePath;
    std::string originalFilePath;

    enum Status {
        NormalStatus = 0,
        ArchivedStatus = 1,
        DeletedStatus = 2,
        // TODO: do we need seperate values per share type?
        // maybe replace with single UploadedStatus
        UploadedToQliqStorStatus = 3,
        UploadedToEmrStatus = 4,
        UploadedToFaxStatus = 5
    };
    Status status;
#ifndef SWIG
    std::time_t timestamp;
#endif
    std::string encryptionMethod;
    std::string encryptedKey;
    std::string publicKeyMd5;           // md5 of PK used to encrypt key
#ifndef SWIG
    struct ExtraKeyDescriptor {
        std::string encryptedKey;
        std::string qliqId;
        std::string publicKeyMd5;
    };
    std::vector<ExtraKeyDescriptor> extraKeys;
#endif

    MediaFile();
    bool isEmpty() const;
    std::string timestampToUiText() const;

    // Methods for viewer, use MediaFileManager to operate on file on disk
    //
    /// Returns path of file ready to open or null
    std::string filePathForView() const;
    /// Returns true if file can be opened immediately
    bool isCanView() const;
    /// Returns true if file is on disk and can be decrypted
    bool isCanDecrypt() const;
    /// Returns true if the \ref url is not empty and file can be downloaded
    bool isCanDownload() const;

#ifndef SWIG
    json11::Json toJson() const;
    static MediaFile fromJson(const json11::Json& json);
#endif // !SWIG
};

struct MediaFileUpload {
    enum class ShareType {
        Unknown = 0,
        QliqStor = 1,
        Emr = 2,
        Fax = 3
    };

    // This is status assigned on client
    enum OnClientStatus {
        UnknownStatus = 0,                  // uknown, ie. comes from newer app
        PendingUploadStatus = 1,            // waiting for upload to cloud
        UploadingStatus = 2,                // uploading to cloud right now
        UploadToCloudFailedStatus = 3,      // either network or cloud error
        UploadedToCloudStatus = 4,          // uploaded to cloud (200 OK)
        FinalProcessingSuccesfulStatus = 5, // stored on qS or uploaded to EMR system
        TemporaryQliqStorFailureErrorStatus = 6,
        TargetNotFoundStatus = 7,           // EMR target (ie patient, encounter) not found, sender should not reply
        PermanentQliqStorFailureErrorStatus = 8,
        ThirdPartySuccessStatus = 9,
        ThirdPartyFailureStatus = 10,
    };
#ifdef QLIQ_STOR_CONTEXT
    enum class OnQliqStorStatus {
        None = 0,
        // Initial errors, preventing the upload from being processed
        BadRequest = 50,                // any error in request from client
        Misconfiguration = 51,          // qS configuration prevents processing
        TargetObjectNotFound = 52,      // ie patient not found in local db or external system
        PublicKeyMismatch = 53,
        //
        QueuedForDownload = 100,
        Downloading = 101,
        QueuedForThirdPartyUpload = 102,    // waiting for sending to EMR or Fax third party system
        RequestToThirdPartyFailed = 103,    // request to HL7 or Fax failed, that is we don't have error from that system because cannot contact it
        WaitingForThirdPartyNotification = 104, // ie. fax request sent, waiting for fax status notification
        // Final error
        DownloadFailed = 130,
        DecryptionFailed = 131,
        ThirdPartyFailed = 132,
        IOError = 133,
        // Final success
        Stored = 150,
        ThirdPartySuccess = 151,
    };
#endif
    // This is status received from qliqStor
    enum class StatusForClient {
        None = 0,
        Success = 200,             // upload finished (store on qS or in EMR)
        ThirdPartySuccess = 201,
        PermanentFailure = 400,          // either bug on sender or format not supported, sender should not retry
        ThirdPartyFailure = 401,
        TemporaryFailure = 500            // uploader did the right thing, either qS or EMR failed
    };

    int databaseId = 0;
    std::string uploadUuid;
    std::string qliqStorQliqId;
    ShareType shareType = ShareType::Unknown;
    MediaFile mediaFile;
    std::string rawUploadTargetJson;
    std::string statusMessage;
#ifndef QLIQ_STOR_CONTEXT
    OnClientStatus status = UnknownStatus;
#else
    OnQliqStorStatus status = OnQliqStorStatus::None;
    std::string rawUploadedByJson;
    std::string uploadedByName;
    std::string json;
    StatusForClient statusForClient = StatusForClient::None; // status sent to client
    std::string extra;
#endif

    bool isEmpty() const;
    bool isUploaded() const;
    bool isFailed() const;
    bool canRetry() const;
    std::string statusToUiText() const;

#ifndef SWIG
    static std::string statusToUiText(OnClientStatus status, ShareType shareType = ShareType::Unknown);
    static OnClientStatus qliqStorStatusCodeToUploadStatus(StatusForClient qliqStorCode);
#ifdef QLIQ_STOR_CONTEXT
    static std::string statusToUiText(OnQliqStorStatus status, ShareType shareType = ShareType::Unknown);
#endif
    static MediaFileUpload fromJson(const json11::Json& json);
    static const char *shareTypeToString(ShareType shareType);
#endif // !SWIG
};

class MediaFileUploadSubscriber {
public:
    enum Event {
        CreatedMediaFileUploadEvent,
        UpdatedMediaFileUploadEvent,
        DeletedMediaFileUploadEvent,
    };

    virtual ~MediaFileUploadSubscriber();

    virtual void onMediaFileUploadEvent(Event event, int databaseId) = 0;
};

class MediaFileUploadNotifier {
public:
    void subscribe(MediaFileUploadSubscriber *subscriber);
    void unsubscribe(MediaFileUploadSubscriber *subscriber);

    static MediaFileUploadNotifier *instance();

private:
    friend class UploadToQliqStorTask;
    friend class MediaFileManager;

    void notify(MediaFileUploadSubscriber::Event event, int databaseId);

    std::vector<MediaFileUploadSubscriber *> m_subscribers;
};

struct MediaFileUploadEvent {
    enum Type {
        NoneType = -1,
#ifndef QLIQ_STOR_CONTEXT
        CreatedType = 0,            // user created the upload
        SyncedType = 1,             // synced from other device
        StartedType = 2,            // started or restarted (retry)
        CloudFailedType = 3,
        CloudSucceededType = 4,     // uploaded to cloud
        QliqStorFailedType = 5,
        QliqStorSucceededType = 6,   // uploaded to qliqStor (final state)
        ThirdPartyFailedType = 7,       // EMR or Fax failed
        ThirdPartySucceededType = 8,   // uploaded to EMR or Faxed (final state)
#else
        // Events on qliqSTOR only (not available on clients)
        QliqStorReceivedType = 100,
        QliqStorDownloadStartedType = 101,
        QliqStorDownloadSucceededType = 102,
        QliqStorDownloadFailedType = 103,
        QliqStorFileDecryptedType = 104,
        QliqStorDecryptionFailedType = 105,
        QliqStorIOErrorType = 106,
        QliqStorEmrUploadFailedType = 107,
        QliqStorEmrUploadSucceededType = 108,
        QliqStorReceivedDuplicateType = 109,
        // Status of Fax request that is qliqStor's attempt to external system
        QliqStorRequestToThirdPartyFailedType = 110,
        QliqStorRequestToThirdPartySentType = 111,
        // Status of the actual Fax, that is coming from the faxing system
        QliqStorThirdPartyFailureType = 112,
        QliqStorThirdPartySucceessType = 113,
        QliqStorTargetObjectNotFound = 114,
#endif // QLIQ_STOR_CONTEXT
    };
    int databaseId;
    int uploadDatabaseId;
    Type type;
#ifndef SWIG
    std::time_t timestamp;
#endif
    std::string message;

    MediaFileUploadEvent();
    bool isEmpty() const;
    std::string typeToString() const;
    std::string timestampToUiText() const;

    static std::string typeToString(Type type, MediaFileUpload::ShareType shareType = MediaFileUpload::ShareType::Unknown);
};

} // qx

#endif // QXMEDIAFILE_HPP

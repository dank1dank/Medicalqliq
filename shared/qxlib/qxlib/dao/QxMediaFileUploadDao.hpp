#ifndef QXMEDIAFILEUPLOADDAO_HPP
#define QXMEDIAFILEUPLOADDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/dao/QxMediaFileDao.hpp"

namespace qx {

class MediaFileUploadDao : public QxJoinedDao<qx::MediaFileUpload, qx::MediaFileDao>
{
public:
#ifndef SWIG
    enum Column {
        IdColumn,
        UploadUuidColumn,
        QliqStorQliqIdColumn,
        ShareTypeColumn,
        MediaFileIdColumn,
        RawUploadTargetJsonColumn,
        StatusColumn,
        StatusMessageColumn,
#ifdef QLIQ_STOR_CONTEXT
        // for qliqStor
        RawUploadedByColumn,
        UploadedByNameColumn,
        JsonColumn,
        QliqStorStatusColumn,
//        UploadedTargetNameColumn,
#endif
        ColumnCount
    };
#endif // !SWIG

    //static bool updateQliqStorStatus(int id, qx::MediaFileUpload::StatusForClient status, const std::string& statusMessage, SQLite::Database& db = QxDatabase::database());
#ifdef QLIQ_STOR_CONTEXT
    static bool eraseJson(int id, SQLite::Database& db = QxDatabase::database());
    static bool updateStatus(int id, qx::MediaFileUpload::StatusForClient qliqStorStatus, qx::MediaFileUpload::OnQliqStorStatus status, const std::string& statusMessage, SQLite::Database& db = QxDatabase::database());
    static bool updateDownloadingStatusToQueuedStatus(SQLite::Database& db = QxDatabase::database());
    static int replaceDecryptedFilePath(MediaFileUpload::ShareType shareType, const std::string& oldDir, const std::string& newDir, SQLite::Database& db = QxDatabase::database());
#elif !defined(SWIG)
    static bool updateStatus(int id, qx::MediaFileUpload::OnClientStatus status, const std::string& statusMessage, SQLite::Database& db = QxDatabase::database());
    static bool updateUploadingStatusToFailedStatus(SQLite::Database& db = QxDatabase::database());
#endif

    static MediaFileUpload selectOneWithId(int id);
    static MediaFileUpload selectOneWithMediaFileId(int mediaFileId);
    static std::vector<MediaFileUpload> selectWithShareType(MediaFileUpload::ShareType shareType, int skip, int limit);
    static int countWithShareType(MediaFileUpload::ShareType shareType);
#ifndef QLIQ_STOR_CONTEXT
    static int countWithShareTypeAndStatus(MediaFileUpload::ShareType shareType, MediaFileUpload::OnClientStatus status);
    static int countWithShareType(MediaFileUpload::ShareType shareType, bool archived);
    static int countSuccessfulWithShareType(MediaFileUpload::ShareType shareType, bool archived);
#endif
    static bool updateStatus(const qx::MediaFileUpload& upload, SQLite::Database& db = QxDatabase::database());
};

} // namespace qx

#endif // QXMEDIAFILEUPLOADDAO_HPP

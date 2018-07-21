#ifndef QXMEDIAFILEDAO_HPP
#define QXMEDIAFILEDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/model/QxMediaFile.hpp"

namespace qx {

class MediaFileDao : public QxBaseDao<qx::MediaFile>
{
public:
#ifndef SWIG
    enum Column {
        IdColumn,
        MimeColumn,
        KeyColumn,
        FileNameColumn,
        SizeColumn,
        ChecksumColumn,
        ThumbnailColumn,
        UrlColumn,
        EncryptedFilePathColumn,
        DecryptedFilePathColumn,
//        OriginalFilePath,
        StatusColumn,
        TimestampColumn,
        EncryptionMethodColumn,
        EncryptedKeyColumn,
        PublicKeyMd5Column,
        ExtraKeyEncryptedKeyColumn,
        ExtraKeyPublicKeyMd5Column,
        ExtraKeyQliqIdColumn,
        ColumnCount
    };
    static void fillFromQuery(qx::MediaFile *obj, SQLite::Statement& record, const std::string& prefix);

    static bool updateUrl(int databaseId, const std::string& url, SQLite::Database& db = QxDatabase::database());
    static bool updateEncryptedFilePath(int databaseId, const std::string& filePath, SQLite::Database& db = QxDatabase::database());
    static bool updateDecryptedFilePath(int databaseId, const std::string& filePath, SQLite::Database& db = QxDatabase::database());
#endif //!SWIG
    static MediaFile selectOneWithId(int databaseId);
};

} // namespace qx

#endif // QXMEDIAFILEDAO_HPP

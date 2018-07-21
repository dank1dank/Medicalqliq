#ifndef QXMEDIAFILEUPLOADEVENTDAO_HPP
#define QXMEDIAFILEUPLOADEVENTDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/model/QxMediaFile.hpp"

namespace qx {

class MediaFileUploadEventDao : public QxBaseDao<qx::MediaFileUploadEvent>
{
public:
#ifndef SWIG
    enum Column {
        IdColumn,
        UploadIdColumn,
        TypeColumn,
        TimestampColumn,
        MessageColumn,
        ColumnCount
    };
#endif // !SWIG
    static std::vector<MediaFileUploadEvent> selectWithUploadId(int id);
};

} // namespace qx

#endif // QXMEDIAFILEUPLOADEVENTDAO_HPP

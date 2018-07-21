#ifndef QX_FAXCONTACTDAO_HPP
#define QX_FAXCONTACTDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/model/fax/QxFaxContact.hpp"

namespace qx {

class FaxContactDao : public QxBaseDao<FaxContact>
{
public:
#ifndef SWIG
    enum Column {
    IdColumn,
    UuidColumn,
    FaxNumberColumn,
    VoiceNumberColumn,
    OrganizationColumn,
    ContactNameColumn,
    IsCreatedByUserColumn,
    GroupQliqIdColumn,
    };

    static int deleteNotIn(const std::vector<FaxContact>& contacts, SQLite::Database& db = QxDatabase::database());
#endif //!SWIG
    static std::vector<FaxContact> search(const std::string& filter, int limit = 0, int skip = 0, SQLite::Database& db = QxDatabase::database());
};

} // namespace qx

#endif // QX_FAXCONTACTDAO_HPP

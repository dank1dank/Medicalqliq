#ifndef QXSIPCONTACTDAO_H
#define QXSIPCONTACTDAO_H
#include "qxlib/model/sip/QxSipContact.hpp"
#include "qxlib/dao/QxBaseDao.hpp"

namespace qx {

class SipContactDao : public QxBaseDao<qx::SipContact>
{
public:
    enum Column {
        QliqIdColumn,
        PrivateKeyColumn,
        PublicKeyColumn,
        TypeColumn
    };

    static bool deletePublicKey(const std::string& qliqId, SQLite::Database &db = QxDatabase::database());
};

} // namespace sip

#endif // QXSIPCONTACTDAO_H

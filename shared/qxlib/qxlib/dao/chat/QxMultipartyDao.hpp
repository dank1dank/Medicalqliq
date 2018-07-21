#ifndef QXMULTIPARTYDAO_H
#define QXMULTIPARTYDAO_H
#include "qxlib/model/chat/QxMultiparty.hpp"
#include "qxlib/dao/QxBaseDao.hpp"

namespace qx {

class MultipartyDao : public QxBaseDao<qx::Multiparty>
{
public:
    enum Column {
        QliqIdColumn,
        NameColumn,
        ParticipantsColumn,
//        RolesColumn
    };

    // for Java
    static Multiparty selectOneByQliqId(const std::string& qliqId);
};

} // namespace qx

#endif // QXMULTIPARTYDAO_H

#ifndef QXQLIQSTORDAO_HPP
#define QXQLIQSTORDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
//#include "qxlib/model/QxQliqStor.hpp"

namespace qx {

class QliqStorDao {
public:
    static bool insertQliqStorForGroup(const std::string& qliqStorQliqId, const std::string& groupQliqId);
    
    static std::vector<std::string> qliqStorsForQliqId(const std::string& qliqId);
    static std::vector<std::string> qliqStorsForUser(const std::string& qliqId);
    static std::vector<std::string> qliqStorsForGroup(const std::string& qliqId);
    
    static bool deleteQliqStor(const std::string& qliqId);
};

} // qx

#endif // QXQLIQSTORDAO_HPP

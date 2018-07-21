#ifndef QXCARECHANNELDAO_HPP
#define QXCARECHANNELDAO_HPP
#include <string>

namespace qx {

class CareChannelDao
{
public:
    static bool hasAny();
    static bool existsWithUuid(const std::string& uuid);
    static void remove(const std::string& uuid);
};

} // qx

#endif // QXCARECHANNELDAO_HPP

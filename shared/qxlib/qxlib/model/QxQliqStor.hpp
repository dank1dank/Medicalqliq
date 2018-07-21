#ifndef QXQLIQSTOR_HPP
#define QXQLIQSTOR_HPP
#include <string>

namespace qx {

struct QliqStor {
    std::string qliqId;
    std::string deviceUuid;
    std::string publicKey;

    bool isEmpty() const;
};

} // qx

#endif // QXQLIQSTOR_HPP

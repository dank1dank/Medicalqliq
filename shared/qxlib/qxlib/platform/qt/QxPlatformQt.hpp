#ifndef QXPLATFORMQT_HPP
#define QXPLATFORMQT_HPP
#include <QString>

struct evp_pkey_st;

namespace qx {

class PlatformQt
{
public:
    PlatformQt();
    ~PlatformQt();

    void setMyUser(const QString& qliqId, const QString &email, const QString& displayName);
    void setDeviceName(const QString& deviceName);
    void setKeyPair(evp_pkey_st *pubKey, const std::string& publicKeyString, evp_pkey_st *privKey);

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QXPLATFORMQT_HPP

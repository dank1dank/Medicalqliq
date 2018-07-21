#ifndef QXCRYPTO_HPP
#define QXCRYPTO_HPP
#include <string>
#include <memory>
#include <stdexcept>

struct evp_pkey_st;

namespace qx {

class Crypto
{
public:
    Crypto();
    ~Crypto();

#ifndef SWIG
    static void initializeOpenSSL();
    static void cleanUpOpenSSL();
#endif

    /// Sets the keys without taking ownership (will not call EVP_PKEY_free)
    void setKeys(evp_pkey_st *pubKey, const std::string& publicKeyString, evp_pkey_st *privKey);
    bool setKeys(const std::string& publicKeyString, const std::string& privateKeyString, const std::string& password);
    std::string publicKey() const;
    std::string publicKeyMd5() const;

    // Public-Private key encryption
    std::string decryptFromBase64ToString(const std::string& encrypted, bool *ok) const;
    static std::string decryptWithKeyFromBase64ToString(const std::string& encrypted, const std::string& privateKey, const std::string& password, bool *ok);
    static std::string encryptToBase64WithKey(const char *data, std::size_t len, evp_pkey_st *pubKey, bool *ok);
    static std::string encryptToBase64WithKey(const char *data, std::size_t len, const std::string& pubKeyString, bool *ok);

    // AES - symmetric key encryption
    static int aesEncryptFile(const std::string& inPath, const std::string& outPath, std::string *base64KeyString, std::string *checksum = nullptr);
    static int aesDecryptFile(const std::string& inPath, const std::string& outPath, const std::string& base64KeyString, std::string *checksum = nullptr);

    static Crypto *instance();
    static void setInstance(Crypto *crypto);

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QXCRYPTO_HPP

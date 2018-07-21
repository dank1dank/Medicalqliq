#ifndef CORE_CRYPTO_H
#define CORE_CRYPTO_H
#include <string>
#include <vector>
#include "String.hpp"

namespace core {

class CryptoKeyStore;


class Crypto
{
public:
    /// This class takes ownership of \arg keyStore.
    Crypto(CryptoKeyStore *keyStore);
    ~Crypto();

    void initForUser(const String& userName, const String& password);
    bool openForUser(const String& userName, const String& password);
    std::string publicKey() const;

    /// Encrypts a string.
    bool encrypt(const String& plainData, std::vector<char> *encrypted) const;
    /// Encrypts arbitrary byte data.
    bool encrypt(const std::vector<char>& plainData, std::vector<char> *encrypted) const;
    /// Encrypts a string to base-64 encoded string.
    /// The return value is a std::string because it is guaranteed to be an ASCII string.
    bool encryptToBase64(const String& plainData, std::string *encrypted) const;
    /// Encrypts arbitrary byte data to base-64 encoded string.
    /// The return value is a std::string because it is guaranteed to be an ASCII string.
    bool encryptToBase64(const std::vector<char>& plainData, std::string *encrypted) const;

    bool encryptWithKey(const String& plainData, const std::string& pubKey, std::vector<char> *encrypted) const;
    bool encryptWithKey(const std::vector<char>& plainData, const std::string& pubKey, std::vector<char> *encrypted) const;

    bool encryptWithKeyToBase64(const String& plainData, const std::string& pubKey, std::string *encrypted) const;
    bool encryptWithKeyToBase64(const std::vector<char>& plainData, const std::string& pubKey, std::string *encrypted) const;


    bool decrypt(const std::vector<char>& encryptedData, std::vector<char> *plainData);
    String decrypt(const std::vector<char>& encryptedData, bool *ok = NULL) const;
    String decryptFromBase64(const std::string& encryptedData, bool *ok = NULL) const;

    std::string digest(const String& message) const;

    static bool isValidPublicKey(const std::string& pubKey);
//    bool isValidDigestWithKey(const String& digest, const String& pubKey) const;

    // Base64
    static void base64Encode(const std::vector<char>& plainData, std::string *base64);
    static void base64Decode(const std::string& base64, std::vector<char> *plainData);

    // DES - symmetric key encryption
    static int encryptFile(const char *inPath, const char *outPath, std::string *base64KeyString);
    static int decryptFile(const char *inPath, const char *outPath, const std::string& base64KeyString);

    // AES - symmetric key encryption
    static int aesEncryptFile(const char *inPath, const char *outPath, std::string *base64KeyString, std::string *checksum = NULL);
    static int aesDecryptFile(const char *inPath, const char *outPath, const std::string& base64KeyString, std::string *checksum = NULL);

    static void test();
    static void desTest();

    static void init();

    // Utils
    static void randomBytes(char *buffer, size_t len);

private:
    struct Private;
    Private *d;
};

} // namespace core

#endif // CORE_CRYPTO_H

#ifndef CORE_CRYPTOKEYSTORE_H
#define CORE_CRYPTOKEYSTORE_H
#include <string>
#include <openssl/evp.h>
#include "String.hpp"

namespace core {

/// Abstract class that provides store for crypto keys.
/// On PC a subclass that stores file on disk will be used,
/// while on Mac the keys will be stored in keychain.
class CryptoKeyStore
{
public:
    enum KeyType
    {
        PrivateKey,
        PublicKey
    };

    virtual ~CryptoKeyStore() {}

    /// Stores a key in the keystore and optionally encrypts it with \arg password.
    virtual bool store(EVP_PKEY *key, KeyType type, const String& userName, const String& password) = 0;

    /// Loads a key into \arg key and \arg keyString.
    /// \arg keyString can be NULL.
    virtual bool load(EVP_PKEY **key, std::string *keyString, KeyType type, const String& userName, const String& password) = 0;
};

/// Stores keys as files on disk.
class FileCryptoKeyStore : public CryptoKeyStore
{
public:
    /// The baseDir is a path to a directory where the keys will be stored.
    /// The path needs to be in OS specific format (backslash on Windows, slash on Unix)
    FileCryptoKeyStore(const String& baseDir);

    virtual bool store(EVP_PKEY *key, KeyType type, const String& userName, const String& password);
    virtual bool load(EVP_PKEY **key, std::string *keyString, KeyType type, const String& userName, const String& password);

private:
    std::string pathForUser(const String& userName) const;
    std::string pathForType(const String& userName, KeyType type) const;
    bool createPathIfDoesntExist(const std::string& path);

    std::string _baseDir;
};

} // namespace core

#endif // CORE_CRYPTOKEYSTORE_H

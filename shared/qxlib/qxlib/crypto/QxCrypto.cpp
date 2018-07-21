#include "QxCrypto.hpp"
#include <cmath>
#include <mutex>
#include <vector>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/rand.h>
#ifndef OPENSSL_NO_ENGINE
#include <openssl/engine.h>
#endif
#ifdef OPENSSL_VERSION_1_1_0
#include <openssl/evp_int.h>
#include <openssl/evp_locl.h>
#endif
#include "qxlib/debug/QxAssert.hpp"
#include "qxlib/crypto/QxMd5.hpp"
#include "qxlib/crypto/QxBase64.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/util/QxSpan.hpp"
#include "qxlib/util/QxStdioUtil.hpp"
#ifdef _WIN32
#include "qxlib/platform/windows/QxPlatformWindowsHelpers.hpp"
#endif

namespace {

struct EvpPKeyDeleter {
    void operator()(EVP_PKEY *key) const
    {
        EVP_PKEY_free(key);
    }
};
typedef std::unique_ptr<EVP_PKEY, EvpPKeyDeleter> EvpPKeyUniquePtr;

qx::Crypto *s_defaultInstance = nullptr;
int s_OpenSSLUsageCount = 0;

} // anonymous

namespace qx {

struct Crypto::Private {
    // Because app can download a new keypair at any time, we need to protect this class by lock
    std::mutex mutex;
    std::string publicKeyString;
    std::string publicKeyMd5;
    EVP_PKEY *privKey = nullptr;
    EVP_PKEY *pubKey = nullptr;
    bool ownKeys = false;

    ~Private()
    {
        freeKeys();
        cleanUpOpenSSL();
    }

    static void initializeOpenSSL();
    static void cleanUpOpenSSL();
    void freeKeys();

    typedef int (*RsaFunction)(int flen, const unsigned char *from, unsigned char *to, RSA *rsa,int padding);

    static std::size_t decryptWithKey(const unsigned char *encrypted, std::size_t encryptedLen,
                                      std::unique_ptr<unsigned char[]> *decrypted, EVP_PKEY *privKey);
    static std::size_t encryptWithKey(const unsigned char *plain, std::size_t planLen,
                                      std::unique_ptr<unsigned char[]> *encrypted, EVP_PKEY *privKey);
    static std::size_t rsaTransform(span<const unsigned char> input,
                                    span<unsigned char> output,
                                    RSA *rsa, RsaFunction fun, const char *errorLogMessage);

    static evp_pkey_st *readKeyFromString(const std::string& keyString, bool isPrivate = false, const std::string& password = "");
    static void logAndClearError(const char *message);

    static void aesGenerateKeyAndIv(span<unsigned char> key, span<unsigned char> iv);
    static std::string aesKeyAndIvToBase64(span<unsigned char> key, span<unsigned char> iv);
    static bool aesKeyAndIvFromBase64(const std::string& b64, std::vector<unsigned char> *key, std::vector<unsigned char> *iv);
    static int aesEncryptDecryptFile(const std::string& inPath, const std::string& outPath, span<unsigned char> key, span<unsigned char> iv, bool encrypt, std::string *digest = nullptr);
};

Crypto::Crypto() :
    d(new Private())
{
}

Crypto::~Crypto()
{
    delete d;

    if (s_defaultInstance == this) {
        s_defaultInstance = nullptr;
    }
}

void Crypto::initializeOpenSSL()
{
    Private::initializeOpenSSL();
}

void Crypto::cleanUpOpenSSL()
{
    Private::cleanUpOpenSSL();
}

void Crypto::setKeys(EVP_PKEY *pubKey, const std::string &publicKeyString, EVP_PKEY *privKey)
{
    std::lock_guard<std::mutex> lock{d->mutex};
    d->freeKeys();
    d->ownKeys = false;
    d->pubKey = pubKey;
    d->privKey = privKey;
    d->publicKeyString = publicKeyString;
    d->publicKeyMd5 = md5(publicKeyString);
}

bool Crypto::setKeys(const std::string &publicKeyString, const std::string &privateKeyString, const std::string &password)
{
    std::lock_guard<std::mutex> lock{d->mutex};
    d->freeKeys();
    d->ownKeys = true;
    d->pubKey = Private::readKeyFromString(publicKeyString, false);
    d->privKey = Private::readKeyFromString(privateKeyString, true, password);
    d->publicKeyString = publicKeyString;
    d->publicKeyMd5 = md5(publicKeyString);
    return (d->pubKey && d->privKey);
}

std::string Crypto::publicKey() const
{
    std::lock_guard<std::mutex> lock{d->mutex};
    return d->publicKeyString;
}

std::string Crypto::publicKeyMd5() const
{
    std::lock_guard<std::mutex> lock{d->mutex};
    return d->publicKeyMd5;
}

std::string Crypto::decryptFromBase64ToString(const std::string &encryptedBase64, bool *ok) const
{
    qx_assert(d->privKey != nullptr);
    qx_assert(ok != nullptr);

    *ok = false;

    std::unique_ptr<unsigned char[]> encrypted;
    std::size_t encryptedLen = base64::decode(encryptedBase64.c_str(), encryptedBase64.size(), &encrypted);
    if (encryptedLen == 0) {
        QXLOG_ERROR("Cannot Base64 decode data: '%s'", encryptedBase64.c_str());
        return "";
    }

    std::unique_ptr<unsigned char[]> decrypted;
    std::size_t decryptedLen = 0;
    {
        std::lock_guard<std::mutex> lock{d->mutex};
        decryptedLen = d->decryptWithKey(encrypted.get(), encryptedLen, &decrypted, d->privKey);
    }

    if (decryptedLen == 0) {
        QXLOG_ERROR("Cannot decrypt data", nullptr);
        return "";
    }

    *ok = true;
    return std::string(reinterpret_cast<const char *>(decrypted.get()), decryptedLen);
}

std::string Crypto::decryptWithKeyFromBase64ToString(const std::string &encryptedBase64, const std::string &privateKeyString, const std::string &password, bool *ok)
{
    qx_assert(ok != nullptr);

    std::unique_ptr<unsigned char[]> encrypted;
    std::size_t encryptedLen = base64::decode(encryptedBase64.c_str(), encryptedBase64.size(), &encrypted);
    if (encryptedLen == 0) {
        QXLOG_ERROR("Cannot Base64 decode data: '%s'", encryptedBase64.c_str());
        return "";
    }

    EvpPKeyUniquePtr privateKey{Private::readKeyFromString(privateKeyString, true, password)};
    if (!privateKey) {
        QXLOG_ERROR("Cannot read private key from string", nullptr);
        return "";
    }

    std::unique_ptr<unsigned char[]> decrypted;
    std::size_t decryptedLen = Private::decryptWithKey(encrypted.get(), encryptedLen, &decrypted, privateKey.get());

    if (decryptedLen == 0) {
        QXLOG_ERROR("Cannot decrypt data", nullptr);
        return "";
    }

    *ok = true;
    return std::string(reinterpret_cast<const char *>(decrypted.get()), decryptedLen);
}

std::string Crypto::encryptToBase64WithKey(const char *plain, std::size_t plainLen, evp_pkey_st *pubKey, bool *ok)
{
    qx_assert(pubKey != nullptr);
    qx_assert(ok != nullptr);

    *ok = false;

    std::unique_ptr<unsigned char[]> encrypted;
    std::size_t encryptedLen = Private::encryptWithKey(reinterpret_cast<const unsigned char *>(plain), plainLen, &encrypted, pubKey);

    if (encryptedLen == 0) {
        QXLOG_ERROR("Cannot encrypt data", nullptr);
        return "";
    }

    std::string base64Encoded;
    std::size_t encodedLen = base64::encode(encrypted.get(), encryptedLen, &base64Encoded);
    if (encodedLen == 0) {
        QXLOG_ERROR("Cannot Base64 encode data", nullptr);
        return "";
    }

    *ok = true;
    return base64Encoded;
}

std::string Crypto::encryptToBase64WithKey(const char *plain, std::size_t plainLen, const std::string &pubKeyString, bool *ok)
{
    std::string ret;
    evp_pkey_st *pubKey = Private::readKeyFromString(pubKeyString);
    if (!pubKey) {
        QXLOG_ERROR("Cannot read public key: %s", pubKeyString.c_str());
        return "";
    } else {
        ret = encryptToBase64WithKey(plain, plainLen, pubKey, ok);
        EVP_PKEY_free(pubKey);
    }
    return ret;
}

int Crypto::aesEncryptFile(const std::string& inPath, const std::string& outPath, std::string *base64KeyString, std::string *checksum)
{
    Private::initializeOpenSSL();

    const size_t KEY_LEN = 32; // 256 bit
    const size_t IV_LEN = 16; // required by BouncyCastle
    unsigned char key[KEY_LEN], iv[IV_LEN];
    auto key_span = make_span(key, KEY_LEN);
    auto iv_span = make_span(iv, IV_LEN);

    Private::aesGenerateKeyAndIv(key_span, iv_span);
    *base64KeyString = Private::aesKeyAndIvToBase64(key_span, iv_span);

    return Private::aesEncryptDecryptFile(inPath, outPath, key_span, iv_span, true, checksum);
}

int Crypto::aesDecryptFile(const std::string &inPath, const std::string &outPath, const std::string &base64KeyString, std::string *checksum)
{
    Private::initializeOpenSSL();

    std::vector<unsigned char> key, iv;

    if (Private::aesKeyAndIvFromBase64(base64KeyString, &key, &iv)) {
        auto key_span = make_span(key.data(), key.size());
        auto iv_span = make_span(iv.data(), iv.size());
        return Private::aesEncryptDecryptFile(inPath, outPath, key_span, iv_span, false, checksum);
    } else {
        return -1;
    }
}

Crypto *Crypto::instance()
{
    return s_defaultInstance;
}

void Crypto::setInstance(Crypto *crypto)
{
    s_defaultInstance = crypto;
}

std::size_t Crypto::Private::rsaTransform(span<const unsigned char> input,
                                span<unsigned char> output,
                                RSA *rsa, RsaFunction fun, const char *errorLogMessage)
{
    const std::size_t blockLen = RSA_size(rsa);
    std::size_t inPos = 0;
    std::size_t outPos = 0;

    while (inPos < input.size()) {
        std::size_t bytesToProcess = std::min(blockLen, input.size() - inPos);

        if (outPos + bytesToProcess > output.size()) {
            // Avoid buffer overflow, this should never happen but just in case
            QXLOG_FATAL("%s buffer overflow", errorLogMessage);
            qx_assert(outPos + bytesToProcess <= output.size());
            outPos = 0;
            break;
        }

        int processedLen = fun(bytesToProcess, input.get() + inPos, output.get() + outPos, rsa, RSA_PKCS1_PADDING);
        if (processedLen == -1) {
            logAndClearError(errorLogMessage);
            outPos = 0;
            break;
        }

        inPos += bytesToProcess;
        outPos += processedLen;
    }

    return outPos;
}

evp_pkey_st *Crypto::Private::readKeyFromString(const std::string &keyString, bool isPrivate, const std::string &password)
{
    const char *RSA_KEY_HEADER_PREFIX = "-----BEGIN RSA ";

    initializeOpenSSL();

    BIO *bio = BIO_new_mem_buf(const_cast<char *>(keyString.c_str()), keyString.size());
    EVP_PKEY *key = NULL;

    if (StringUtils::startsWith(keyString, RSA_KEY_HEADER_PREFIX)) {
        // RSA format key
        RSA *rsa = NULL;
        if (isPrivate) {
            rsa = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, (void *)password.c_str());
        } else {
            rsa = PEM_read_bio_RSAPublicKey(bio, NULL, NULL, NULL);
        }
        if (rsa) {
            key = EVP_PKEY_new();
            if (key)
                EVP_PKEY_set1_RSA(key, rsa);
            RSA_free(rsa);
        } else {
            char buffer[120];
            ERR_error_string(ERR_get_error(), buffer);
            buffer[0] = '\0';
        }
    } else {
        // Must be a  PKCS#8 key
        if (isPrivate) {
            key = PEM_read_bio_PrivateKey(bio, NULL, NULL, (void *)password.c_str());
        } else {
            key = PEM_read_bio_PUBKEY(bio, NULL, NULL, 0);
        }
    }

    BIO_free(bio);
    return key;
}

void Crypto::Private::initializeOpenSSL()
{
    if (s_OpenSSLUsageCount++ == 0) {
#ifndef OPENSSL_VERSION_1_1_0
        CRYPTO_malloc_init();
#endif
        CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
        OpenSSL_add_all_algorithms();
        OpenSSL_add_all_digests();
    }
}

void Crypto::Private::cleanUpOpenSSL()
{
    if (--s_OpenSSLUsageCount == 0) {
#ifndef OPENSSL_NO_ENGINE
        ENGINE_cleanup();
#endif
        CRYPTO_cleanup_all_ex_data();
    }
}

void Crypto::Private::freeKeys()
{
    if (ownKeys) {
        if (privKey) {
            EVP_PKEY_free(privKey);
            privKey = nullptr;
        }
        if (pubKey) {
            EVP_PKEY_free(pubKey);
            pubKey = nullptr;
        }
        ownKeys = false;
    }
}

std::size_t Crypto::Private::decryptWithKey(const unsigned char *encrypted, std::size_t encryptedLen,
                                            std::unique_ptr<unsigned char[]> *decrypted, EVP_PKEY *privKey)
{
    *decrypted = std::unique_ptr<unsigned char[]>{new unsigned char[encryptedLen]};
    return rsaTransform(make_span(encrypted, encryptedLen),
                        make_span(decrypted->get(), encryptedLen),
                        privKey->pkey.rsa, &RSA_private_decrypt, "Error in RSA_private_decrypt:");
}

std::size_t Crypto::Private::encryptWithKey(const unsigned char *plain, std::size_t plainLen, std::unique_ptr<unsigned char[]> *output, EVP_PKEY *pubKey)
{
    const std::size_t blockLen = RSA_size(pubKey->pkey.rsa);
    const std::size_t maxEncryptedLen = std::ceil(static_cast<float>(plainLen) / blockLen) * blockLen;
    *output = std::unique_ptr<unsigned char[]>{new unsigned char[maxEncryptedLen]};

    return rsaTransform(make_span(plain, plainLen),
                        make_span(output->get(), maxEncryptedLen),
                        pubKey->pkey.rsa, &RSA_public_encrypt, "Error in RSA_public_encrypt:");
}

void Crypto::Private::logAndClearError(const char *message)
{
    // We need to clear the OpenSSL error so it is not propagated to pjproject or elsewhere
    int errLevel = 0;
    unsigned long errCode = ERR_get_error();
    while (errCode != 0) {
        QXLOG_ERROR("%s %u %s, level: %d", message, errCode, ERR_error_string(errCode, nullptr), errLevel);
        errCode = ERR_get_error();
        errLevel++;
    }
}

void Crypto::Private::aesGenerateKeyAndIv(span<unsigned char> key, span<unsigned char> iv)
{
    RAND_bytes(key.get(), key.size());
    RAND_bytes(iv.get(), iv.size());
}

std::string Crypto::Private::aesKeyAndIvToBase64(span<unsigned char> key, span<unsigned char> iv)
{
    std::string ret, b64str;

    base64::encode(key.get(), key.size(), &b64str);
    ret = b64str;
    ret.push_back('|');

    base64::encode(iv.get(), iv.size(), &b64str);
    ret.append(b64str);
    return ret;
}

bool Crypto::Private::aesKeyAndIvFromBase64(const std::string &b64, std::vector<unsigned char> *key, std::vector<unsigned char> *iv)
{
    bool ret = false;
    std::vector<std::string> parts = StringUtils::split(b64, '|');
    if (parts.size() == 2) {
        std::string keyStr, ivStr;
        base64::decode(parts[0], &keyStr);
        base64::decode(parts[1], &ivStr);
        ret = (!keyStr.empty() && !ivStr.empty());
        if (ret) {
            key->resize(keyStr.size());
            memcpy(key->data(), keyStr.c_str(), keyStr.size());
            iv->resize(ivStr.size());
            memcpy(iv->data(), ivStr.c_str(), ivStr.size());
        }
    }
    return ret;
}

int Crypto::Private::aesEncryptDecryptFile(const std::string &inPath, const std::string &outPath, span<unsigned char> key, span<unsigned char> iv, bool encrypt, std::string *digest)
{
    const size_t BLOCK_SIZE = 4096;
    const size_t MAX_PADDING_LEN = 16;
    const EVP_CIPHER *cipher_type;

    switch (key.size()) {
    case 16:
        cipher_type = EVP_aes_128_cbc();
        break;
    case 24:
        cipher_type = EVP_aes_192_cbc();
        break;
    case 32:
        cipher_type = EVP_aes_256_cbc();
        break;
    default:
        //QLOG_ERROR() << "Invalid key size specified:" << key.size();
        throw std::runtime_error("Invalid key size specified: " + std::to_string(key.size()));
    }

    unique_file_ptr inFile{fopen_utf8(inPath, "rb")};
    if (!inFile) {
        //QLOG_ERROR() << "Cannot open input file:" << inPath;
        throw std::runtime_error("Cannot open input file: " + inPath + ", error: " + std::strerror(errno));
    }

    unique_file_ptr outFile{fopen_utf8(outPath, "wb")};
    if (!outFile) {
        //QLOG_ERROR() << "Cannot open output file:" << inPath;
        throw std::runtime_error("Cannot open output file: " + outPath + ", error: " + std::strerror(errno));
    }

    fseek(inFile.get(), 0, SEEK_END);
    size_t fileSize = ftell(inFile.get());
    fseek(inFile.get(), 0, SEEK_SET);

    if (fileSize == 0) {
//        QLOG_ERROR() << "The input file is empty";
        throw std::runtime_error("The input file is empty");
    }

    struct EvpCtxCleanupDeleter {
        void operator()(EVP_CIPHER_CTX *ctx) const
        {
            EVP_CIPHER_CTX_cleanup(ctx);
            delete ctx;
        }
    };
    std::unique_ptr<EVP_CIPHER_CTX, EvpCtxCleanupDeleter> ctx{new EVP_CIPHER_CTX};
    EVP_CIPHER_CTX_init(ctx.get());

    int ret;
    if (encrypt)
        ret = EVP_EncryptInit_ex(ctx.get(), cipher_type, NULL, key.get(), iv.get());
    else
        ret = EVP_DecryptInit_ex(ctx.get(), cipher_type, NULL, key.get(), iv.get());

    if (!ret) {
        logAndClearError("Invalid encryption key:");
        throw std::runtime_error("Invalid encryption key");
    }

    EVP_MD_CTX digestCtx;
    const EVP_MD *md = NULL;

    if (digest) {
        md = EVP_get_digestbyname("md5");
        if (md) {
            EVP_MD_CTX_init(&digestCtx);
            EVP_DigestInit_ex(&digestCtx, md, NULL);
        }
    }

    std::unique_ptr<unsigned char[]>  inBuffer{new unsigned char[BLOCK_SIZE]};
    std::unique_ptr<unsigned char[]> outBuffer{new unsigned char[BLOCK_SIZE + MAX_PADDING_LEN]};

    unsigned long totalWritten = 0;
    for (size_t pos = 0; pos < fileSize; ) {

        size_t toRead = std::min(BLOCK_SIZE, fileSize - pos);
        size_t read = fread(inBuffer.get(), 1, toRead, inFile.get());
        if (read < toRead) {
            throw std::runtime_error(std::string("File read error: ") + std::strerror(errno));
        }

        int decodedLen;

        if (encrypt)
            ret = EVP_EncryptUpdate(ctx.get(), outBuffer.get(), &decodedLen, inBuffer.get(), read);
        else
            ret = EVP_DecryptUpdate(ctx.get(), outBuffer.get(), &decodedLen, inBuffer.get(), read);

        if (!ret) {
            logAndClearError("Encryption error (1):");
            throw std::runtime_error("Encryption error (at update)");
        }

        pos += read;

        if (pos == fileSize) {
            int paddingWritten;

            if (encrypt)
                ret = EVP_EncryptFinal_ex(ctx.get(), outBuffer.get() + decodedLen, &paddingWritten);
            else
                ret = EVP_DecryptFinal_ex(ctx.get(), outBuffer.get() + decodedLen, &paddingWritten);

            if (!ret) {
                logAndClearError("Encryption error (2):");
                throw std::runtime_error("Encryption error (at final)");
            }

            decodedLen += paddingWritten;
        }

        if (md) {
            EVP_DigestUpdate(&digestCtx, outBuffer.get(), decodedLen);

            if (pos == fileSize) {
                std::unique_ptr<unsigned char[]> digestValue{new unsigned char[EVP_MAX_MD_SIZE]};
                unsigned int digestLen = 0;

                EVP_DigestFinal_ex(&digestCtx, digestValue.get(), &digestLen);
#ifndef OPENSSL_VERSION_1_1_0
                EVP_MD_CTX_cleanup(&digestCtx);
#endif
                digest->reserve(digestLen * 2);
                char buff[3];
                for (unsigned int i = 0; i < digestLen; i++) {
                    sprintf(buff, "%02x", (unsigned int)digestValue[i]);
                    digest->push_back(buff[0]);
                    digest->push_back(buff[1]);
                }
            }
        }


        size_t written = fwrite(outBuffer.get(), 1, decodedLen, outFile.get());
        if  (written < (size_t) decodedLen) {
            throw std::runtime_error(std::string("File write error: ") + std::strerror(errno));
        }

        totalWritten += written;
    }

    return totalWritten;
}

} // qx

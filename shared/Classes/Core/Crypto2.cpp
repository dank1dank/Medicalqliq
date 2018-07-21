#include "Crypto2.hpp"
#include <vector>
#include <cstdio>
#include <cassert>
#include <cstring>
#include <cstdlib>
#include <openssl/pem.h>
#include <openssl/conf.h>
#include <openssl/x509v3.h>
#include <openssl/des.h>
#include <openssl/rand.h>
#ifndef OPENSSL_NO_ENGINE
#include <openssl/engine.h>
#endif
//#include <openssl/applink.c>
#include "CryptoKeyStore.hpp"
#include "util/StringUtil.hpp"

//#include <QDebug>
//#include <QsLog.h>
#include <iostream>

#define KEY_BIT_SIZE 2048

namespace b64 {

template <typename C>
void base64Encode(const C *plainData, size_t len, std::string *base64)
{
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());
    mem = BIO_push(b64, mem);
    BIO_write(mem, plainData, len);
    BIO_flush(mem);
    C *base64Pointer;
    long base64Length = BIO_get_mem_data(mem, &base64Pointer);
    base64->clear();
    base64->append((const char *)base64Pointer, base64Length);
    BIO_free_all(mem);
}

template <typename C>
void base64Encode(const std::vector<C>& plainData, std::string *base64)
{
    base64Encode(plainData.data(), plainData.size(), base64);
}

template <typename C>
void base64Decode(const std::string& base64, std::vector<C> *plainData)
{
    BIO *mem = BIO_new_mem_buf((void *)base64.c_str(), base64.size());
    BIO *b64 = BIO_new(BIO_f_base64());
    mem = BIO_push(b64, mem);

    plainData->clear();
    char inbuf[512];
    int inlen;
    while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
    {
        for (int i = 0; i < inlen; ++i)
            plainData->push_back(inbuf[i]);
    }

    BIO_free_all(mem);
}

}

namespace {

static void callback(int p, int n, void *arg)
{
    char c='B';

    if (p == 0) c='.';
    if (p == 1) c='+';
    if (p == 2) c='*';
    if (p == 3) c='\n';
    fputc(c,stderr);
}

/* Add extension using V3 code: we can set the config file as NULL
 * because we wont reference any other sections.
 */

static int add_ext(X509 *cert, int nid, const char *value)
{
    X509_EXTENSION *ex;
    X509V3_CTX ctx;
    /* This sets the 'context' of the extensions. */
    /* No configuration database */
    X509V3_set_ctx_nodb(&ctx);
    /* Issuer and subject certs: both the target since it is self signed,
     * no request and no CRL
     */
    X509V3_set_ctx(&ctx, cert, cert, NULL, NULL, 0);
    ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, (char *)value);
    if (!ex)
        return 0;

    X509_add_ext(cert,ex,-1);
    X509_EXTENSION_free(ex);
    return 1;
}

int mkcert(X509 **x509p, EVP_PKEY **pkeyp, int bits, int serial, int days)
{
    X509 *x;
    EVP_PKEY *pk;
    RSA *rsa;
    X509_NAME *name=NULL;

    if ((pkeyp == NULL) || (*pkeyp == NULL))
    {
        if ((pk=EVP_PKEY_new()) == NULL)
        {
            abort();
            return(0);
        }
    }
    else
        pk= *pkeyp;

    if ((x509p == NULL) || (*x509p == NULL))
    {
        if ((x=X509_new()) == NULL)
            goto err;
    }
    else
        x= *x509p;

    rsa=RSA_generate_key(bits,RSA_F4,callback,NULL);
        if (!EVP_PKEY_assign_RSA(pk,rsa))
    {
        abort();
        goto err;
    }
    rsa=NULL;

    X509_set_version(x,2);
    ASN1_INTEGER_set(X509_get_serialNumber(x),serial);
    X509_gmtime_adj(X509_get_notBefore(x),0);
    X509_gmtime_adj(X509_get_notAfter(x),(long)60*60*24*days);
    X509_set_pubkey(x,pk);

    name=X509_get_subject_name(x);

    /* This function creates and adds the entry, working out the
     * correct string type and performing checks on its length.
     * Normally we'd check the return value for errors...
     */
        X509_NAME_add_entry_by_txt(name,"O",
                                                           MBSTRING_ASC, (const unsigned char *)"Ardensys Inc", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"L",
                                                           MBSTRING_ASC, (const unsigned char *)"Richardson", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"S",
                                                           MBSTRING_ASC, (const unsigned char *)"TX", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"C",
                                                           MBSTRING_ASC, (const unsigned char *)"USA", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"CN",
                                                           MBSTRING_ASC, (const unsigned char *)"qliqsoft.com", -1, -1, 0);

        /* Its self signed so set the issuer name to be the same as the
     * subject.
     */
    X509_set_issuer_name(x,name);

    /* Add various extensions: standard extensions */
    add_ext(x, NID_basic_constraints, "critical,CA:TRUE");
    add_ext(x, NID_key_usage, "critical,keyCertSign,cRLSign");

    add_ext(x, NID_subject_key_identifier, "hash");

#ifdef CUSTOM_EXT
    /* Maybe even add our own extension based on existing */
    {
        int nid;
        nid = OBJ_create("1.2.3.4", "MyAlias", "My Test Alias Extension");
        X509V3_EXT_add_alias(nid, NID_netscape_comment);
        add_ext(x, nid, "example comment alias");
    }
#endif


    if (!X509_sign(x,pk,EVP_md5()))
        goto err;

    *x509p=x;
    *pkeyp=pk;

    return(1);
err:
    return(0);
}

} // namespace anonym

namespace core {

struct Crypto::Private
{
    CryptoKeyStore *keyStore;
    std::string certPath;
    std::string keyPath;
    std::string pubKeyPath;
    EVP_PKEY *privKey;
    EVP_PKEY *pubKey;
    std::string publicKeyString;

    Private(CryptoKeyStore *keyStore) :
        keyStore(keyStore),
        privKey(0),
        pubKey(0)
    {}

    ~Private()
    {
        EVP_PKEY_free(pubKey);
        EVP_PKEY_free(privKey);
    }

    void generateKeys(const String& userName, const String& password)
    {
        X509 *x509 = NULL;
        mkcert(&x509, &privKey, KEY_BIT_SIZE, 0, 365);
        pubKey = X509_get_pubkey(x509);
        writeKeys(userName, password);
        X509_free(x509);
        readKeys(userName, password);
    }

    bool writeKeys(const String& userName, const String& password)
    {
        bool ret = keyStore->store(privKey, CryptoKeyStore::PrivateKey, userName, password);
        if (ret)
            ret = keyStore->store(pubKey, CryptoKeyStore::PublicKey, userName, password);

        return ret;
    }

    bool readKeys(const String& userName, const String& password)
    {
        privKey = NULL;
        pubKey = NULL;

        bool ret = keyStore->load(&privKey, NULL, CryptoKeyStore::PrivateKey, userName, password);
        if (ret) {
            ret = keyStore->load(&pubKey, &publicKeyString, CryptoKeyStore::PublicKey, userName, password);
            if (ret) {
                int keyBitSize = RSA_size(pubKey->pkey.rsa) * 8;
                if (keyBitSize < KEY_BIT_SIZE) {
                    EVP_PKEY_free(pubKey);
                    EVP_PKEY_free(privKey);
                    pubKey = privKey = NULL;
                    ret = false;
                }
            }
        }

        return ret;
    }

    static EVP_PKEY *readKeyFromString(const std::string& keyString, CryptoKeyStore::KeyType type)
    {
        BIO *bio = BIO_new_mem_buf(const_cast<char *>(keyString.c_str()), keyString.size());
        EVP_PKEY *key = NULL;

        if (type == CryptoKeyStore::PrivateKey)
            key = PEM_read_bio_PrivateKey(bio, NULL, NULL, 0);
        else
            key = PEM_read_bio_PUBKEY(bio, NULL, NULL, 0);

//        if (key == NULL)
//            qDebug() << __PRETTY_FUNCTION__ << "Cannot read public key from string:" << keyString;

        BIO_free(bio);
        return key;
    }

    bool encryptWithKey(const std::vector<char>& plainData, EVP_PKEY *pubKey, std::vector<char> *encrypted) const
    {
        assert(pubKey != NULL);
        assert(encrypted != NULL);

        const int len = RSA_size(pubKey->pkey.rsa);
        const int blockLen = len - 12; // space for RSA_PKCS1_PADDING
        std::vector<char> buffer(len, '\0');

        encrypted->reserve(plainData.size());
        encrypted->clear();

        int totalBytes = plainData.size();
        int pos = 0;

        while (pos < (int) plainData.size()) {
            int bytesToEnc = std::min(blockLen, totalBytes - pos);
            int encLen = RSA_public_encrypt (bytesToEnc, (const unsigned char *)plainData.data() + pos, (unsigned char *) buffer.data(), pubKey->pkey.rsa, RSA_PKCS1_PADDING);
            if (encLen == -1) {
                //unsigned long errorCode = ERR_get_error();
                //const char *errorString = ERR_error_string(errorCode, NULL);
                // TODO: implement logging for qliqCore
                //QLOG_ERROR() << "Error in RSA_public_encrypt: " << errorString;

                encrypted->clear();
                return false;
            }

            for (int i = 0; i < encLen; ++i)
                encrypted->push_back(static_cast<char>(buffer[i]));

            pos += bytesToEnc;
        }

        return true;
    }

    bool encryptWithKeyToBase64(const std::vector<char>& plainData, EVP_PKEY *pubKey, std::string *encrypted) const
    {
        assert(pubKey != NULL);
        assert(encrypted != NULL);

        const int len = RSA_size(pubKey->pkey.rsa);
        const int blockLen = len - 12; // space for RSA_PKCS1_PADDING
        std::vector<char> buffer(len, '\0');

        BIO *mem = BIO_new(BIO_s_mem());
        BIO *b64 = BIO_new(BIO_f_base64());
        mem = BIO_push(b64, mem);

        encrypted->reserve(plainData.size());
        encrypted->clear();

        int totalBytes = plainData.size();
        int pos = 0;
        bool error = false;

        while (pos < (int) plainData.size())
        {
            int bytesToEnc = std::min(blockLen, totalBytes - pos);
            int encLen = RSA_public_encrypt (bytesToEnc, (const unsigned char *)plainData.data() + pos, (unsigned char *) buffer.data(), pubKey->pkey.rsa, RSA_PKCS1_PADDING);
            if (encLen == -1)
            {
                //unsigned long errorCode = ERR_get_error();
                //const char *errorString = ERR_error_string(errorCode, NULL);
                // TODO: implement logging for qliqCore
                //QLOG_ERROR() << "Error in RSA_private_decrypt: " << errorString;

                encrypted->clear();
                error = true;
                break;
            }
// TODO: disable, this code breaks encryption on purpose!
//            if (encLen > 0)
//                buffer[0] = '5';

            BIO_write(mem, buffer.data(), encLen);
            pos += bytesToEnc;
        }
        BIO_flush(mem);

        if (!error)
        {
            char *base64Pointer;
            long base64Length = BIO_get_mem_data(mem, &base64Pointer);
            encrypted->append(base64Pointer, base64Length);
        }

        BIO_free_all(mem);
        return true;
    }

    bool decrypt(const std::vector<char>& encryptedData, std::vector<char> *output) const
    {
        int len = RSA_size(pubKey->pkey.rsa);
        std::vector<char> buffer(len, '\0');
        std::string decrypted;
        decrypted.reserve(encryptedData.size());

        bool ret = true;
        output->clear();

        int totalBytes = encryptedData.size();
        int pos = 0;

        while (pos < totalBytes)
        {
            int bytesToDecrypt = std::min(len, totalBytes - pos);
            int decrLen = RSA_private_decrypt(bytesToDecrypt, (const unsigned char *)encryptedData.data() + pos, (unsigned char *) buffer.data(), privKey->pkey.rsa, RSA_PKCS1_PADDING);
            if (decrLen == -1)
            {
                //unsigned long errorCode = ERR_get_error();
                //const char *errorString = ERR_error_string(errorCode, NULL);
                // TODO: implement logging for qliqCore
                //QLOG_ERROR() << "Error in RSA_private_decrypt: " << errorString;

                ret = false;
                break;
            }

            for (int i = 0; i < decrLen; ++i)
                output->push_back(buffer[i]);

            pos += bytesToDecrypt;
        }

        return ret;
    }

    String decrypt(const std::vector<char>& encryptedData, bool *ok = 0) const
    {
        int len = RSA_size(pubKey->pkey.rsa);
        std::vector<char> buffer(len, '\0');
        std::string decrypted;
        decrypted.reserve(encryptedData.size());

        if (ok)
            *ok = true;

        int totalBytes = encryptedData.size();
        int pos = 0;

        while (pos < totalBytes)
        {
            int bytesToDecrypt = std::min(len, totalBytes - pos);
            int decrLen = RSA_private_decrypt(bytesToDecrypt, (const unsigned char *)encryptedData.data() + pos, (unsigned char *) buffer.data(), privKey->pkey.rsa, RSA_PKCS1_PADDING);
            if (decrLen == -1)
            {
                //unsigned long errorCode = ERR_get_error();
                //const char *errorString = ERR_error_string(errorCode, NULL);
                // TODO: implement logging for qliqCore
                //QLOG_ERROR() << "Error in RSA_private_decrypt: " << errorString;

                if (ok)
                    *ok = false;
                break;
            }

            decrypted.append((const char *)buffer.data(), decrLen);
            pos += bytesToDecrypt;
        }

        return StringUtil::fromUtf8(decrypted);
    }

    String decryptFromBase64(const std::string& encryptedBase64, bool *ok = 0) const
    {
        BIO *mem = BIO_new_mem_buf((void *)encryptedBase64.c_str(), encryptedBase64.size());
        BIO *b64 = BIO_new(BIO_f_base64());
        mem = BIO_push(b64, mem);

        std::vector<char> encryptedData;
        char inbuf[512];
        int inlen;
        while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        {
            for (int i = 0; i < inlen; ++i)
                encryptedData.push_back(inbuf[i]);
        }

        BIO_free_all(mem);

        return decrypt(encryptedData, ok);
    }

    static bool fromBase64(const std::string& base64, std::vector<char> *data)
    {
        assert(data != NULL);
        data->clear();

        BIO *mem = BIO_new_mem_buf((void *)base64.c_str(), base64.size());
        BIO *b64 = BIO_new(BIO_f_base64());
        mem = BIO_push(b64, mem);

        char inbuf[512];
        int inlen;
        while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        {
            for (int i = 0; i < inlen; ++i)
                data->push_back(inbuf[i]);
        }

        BIO_free_all(mem);
        return (inlen != -1);
    }

    static std::string toBase64(const std::vector<char>& data)
    {
        BIO *mem = BIO_new(BIO_s_mem());
        BIO *b64 = BIO_new(BIO_f_base64());
        mem = BIO_push(b64, mem);

        BIO_write(mem, data.data(), data.size());
        BIO_flush(mem);

        char *base64Pointer;
        long base64Length = BIO_get_mem_data(mem, &base64Pointer);

        std::string base64;
        base64.append(base64Pointer, base64Length);
        BIO_free_all(mem);
        return base64;
    }

    void desTest();
};

Crypto::Crypto(CryptoKeyStore *keyStore) :
    d(new Private(keyStore))
{
    CRYPTO_malloc_init();
    CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
    OpenSSL_add_all_algorithms();
    OpenSSL_add_all_digests();
}

Crypto::~Crypto()
{
    delete d;

#ifndef OPENSSL_NO_ENGINE
    ENGINE_cleanup();
#endif
    CRYPTO_cleanup_all_ex_data();
}

void Crypto::initForUser(const String& userName, const String& password)
{
    if (!openForUser(userName, password))
        d->generateKeys(userName, password);
}

bool Crypto::openForUser(const String& userName, const String& password)
{
    return d->readKeys(userName, password);
}

std::string Crypto::publicKey() const
{
    return d->publicKeyString;
}

bool Crypto::isValidPublicKey(const std::string& pubKeyString)
{
    EVP_PKEY *pubKey = Private::readKeyFromString(pubKeyString, CryptoKeyStore::PublicKey);
    bool ret = (pubKey != NULL);
    EVP_PKEY_free(pubKey);
    return ret;
}

void Crypto::base64Encode(const std::vector<char> &plainData, std::string *base64)
{
    return b64::base64Encode(plainData, base64);
}

void Crypto::base64Decode(const std::string &base64, std::vector<char> *plainData)
{
    return b64::base64Decode(base64, plainData);
}

void Crypto::test()
{
    std::string testStr = "Ala ma kota. Kot ma Ale mleko.";
    std::vector<char> testInputData(testStr.begin(), testStr.end() + 1);
    std::string base64 = Private::toBase64(testInputData);
    std::vector<char> testOutputData;
    bool ok = Private::fromBase64(base64, &testOutputData);
    assert(ok == true);
    std::string testOutputStr = testOutputData.data();
    assert(testOutputStr == testStr);
}

bool Crypto::encrypt(const String &plainData, std::vector<char> *encrypted) const
{
    std::string plainDataUtf8 = StringUtil::toUtf8(plainData);
    std::vector<char> data(plainDataUtf8.begin(), plainDataUtf8.end());
    return encrypt(data, encrypted);
}

bool Crypto::encrypt(const std::vector<char> &plainData, std::vector<char> *encrypted) const
{
    return d->encryptWithKey(plainData, d->pubKey, encrypted);
}

bool Crypto::encryptToBase64(const String &plainData, std::string *encrypted) const
{
    assert(encrypted != NULL);

    if (plainData.empty())
    {
        encrypted->clear();
        return true;
    }
    else
    {
        std::string plainDataUtf8 = StringUtil::toUtf8(plainData);
        std::vector<char> data(plainDataUtf8.begin(), plainDataUtf8.end());
        return encryptToBase64(data, encrypted);
    }
}

bool Crypto::encryptToBase64(const std::vector<char>& plainData, std::string *encrypted) const
{
    return d->encryptWithKeyToBase64(plainData, d->pubKey, encrypted);
}

bool Crypto::encryptWithKey(const String& plainData, const std::string& pubKeyString, std::vector<char> *encrypted) const
{
    std::string plainDataUtf8 = StringUtil::toUtf8(plainData);
    std::vector<char> data(plainDataUtf8.begin(), plainDataUtf8.end());
    return encryptWithKey(data, pubKeyString, encrypted);
}

bool Crypto::encryptWithKey(const std::vector<char> &plainData, const std::string &pubKeyString, std::vector<char> *encrypted) const
{
    bool ret = false;
    EVP_PKEY *pubKey = d->readKeyFromString(pubKeyString, CryptoKeyStore::PublicKey);
    if (pubKey != NULL)
    {
        ret = d->encryptWithKey(plainData, pubKey, encrypted);
        EVP_PKEY_free(pubKey);
    }
    return ret;
}

bool Crypto::encryptWithKeyToBase64(const String& plainData, const std::string& pubKeyString, std::string *encrypted) const
{
    std::string plainDataUtf8 = StringUtil::toUtf8(plainData);
    std::vector<char> data(plainDataUtf8.begin(), plainDataUtf8.end());
    return encryptWithKeyToBase64(data, pubKeyString, encrypted);
}

bool Crypto::encryptWithKeyToBase64(const std::vector<char> &plainData, const std::string &pubKeyString, std::string *encrypted) const
{
    bool ret = false;
    EVP_PKEY *pubKey = d->readKeyFromString(pubKeyString, CryptoKeyStore::PublicKey);
    if (pubKey != NULL)
    {
        ret = d->encryptWithKeyToBase64(plainData, pubKey, encrypted);
        EVP_PKEY_free(pubKey);
    }
    return ret;
}

bool Crypto::decrypt(const std::vector<char> &encryptedData, std::vector<char> *plainData)
{
    return d->decrypt(encryptedData, plainData);
}

String Crypto::decrypt(const std::vector<char>& encryptedData, bool *ok) const
{
    return d->decrypt(encryptedData, ok);
}

String Crypto::decryptFromBase64(const std::string& encryptedData, bool *ok) const
{
    return d->decryptFromBase64(encryptedData, ok);
}

std::string Crypto::digest(const String& message) const
{
    const char *algorithmName = "SHA1";
    EVP_MD_CTX mdctx;
    const EVP_MD *md;
    unsigned char md_value[EVP_MAX_MD_SIZE];
    unsigned int md_len = 0;

    md = EVP_get_digestbyname(algorithmName);
    if (md)
    {
        EVP_MD_CTX_init(&mdctx);
        EVP_DigestInit_ex(&mdctx, md, NULL);
        EVP_DigestUpdate(&mdctx, message.c_str(), (message.size() * sizeof(String::value_type)));
        EVP_DigestFinal_ex(&mdctx, md_value, &md_len);
        EVP_MD_CTX_cleanup(&mdctx);
    }
    else
    {
    //    qDebug() << __PRETTY_FUNCTION__ << "Cannot get digest by name:" << algorithmName;
    }

    char digit[4];
    std::string ret;
    for (unsigned int i = 0; i < md_len; i++) {
        sprintf(digit, "%02x", md_value[i]);
        ret.append(digit);
    }
    return ret;
}

#define BUFSIZE 512

namespace {
    // Good description of OpenSSL DES API:
    // http://blog.fpmurphy.com/2010/04/openssl-des-api.html
    //
    const DES_cblock DES_IVSETUP = {0xE3, 0xE2, 0xE1, 0xD4, 0xD5, 0xC6, 0xC7, 0xA8};

    std::string desKeysToBase64(const_DES_cblock keys[3])
    {
        std::string ret;
        for (int i = 0; i < 3; ++i) {
            std::vector<char> keyData(keys[i], keys[i]+8);
            std::string b64;
            Crypto::base64Encode(keyData, &b64);
            ret += b64;
            if (i < 2)
                ret.push_back('|');
        }
        return ret;
    }

    bool desKeysFromBase64(const std::string& b64, DES_cblock *keys)
    {
        bool ret = false;
        std::vector<std::string> parts = StringUtil::split(b64, '|', false);
        if (parts.size() == 3) {
            std::vector<char> data;
            DES_key_schedule ks;

            ret = true;
            for (int i = 0; i < 3; ++i) {
                Crypto::base64Decode(parts[i], &data);
                memcpy(keys[i], data.data(), 8);

                if (DES_set_key_checked(&keys[i], &ks) != 0) {
                    ret = false;
                    break;
                }
            }
        }
        return ret;
    }

    void desGenerateKeys(DES_cblock *keys)
    {
        const DES_cblock seed = {0xFE, 0xDC, 0xBA, 0x84, 0x76, 0x99, 0x32, 0x10};

        RAND_seed(seed, sizeof(DES_cblock));

        for (int i = 0; i < 3; ++i)
            DES_random_key(&keys[i]);
    }

    void aesGenerateKeyAndIv(unsigned char *key, unsigned char *iv, size_t len, size_t ivLen)
    {
        RAND_bytes(key, len);
        RAND_bytes(iv, ivLen);
    }

    std::string aesKeyAndIvToBase64(unsigned char *key, unsigned char *iv, size_t len, size_t ivLen)
    {
        std::string ret, b64str;

        b64::base64Encode(key, len, &b64str);
        ret = b64str;
        ret.push_back('|');

        b64::base64Encode(iv, ivLen, &b64str);
        ret.append(b64str);
        return ret;
    }

    bool aesKeyAndIvFromBase64(const std::string& b64, std::vector<unsigned char> *key, std::vector<unsigned char> *iv)
    {
        bool ret = false;
        std::vector<std::string> parts = StringUtil::split(b64, '|', false);
        if (parts.size() == 2) {
            b64::base64Decode(parts[0], key);
            b64::base64Decode(parts[1], iv);
            //ret = (!key->empty() && key->size() == iv->size());
            ret = (!key->empty() && !iv->empty());
        }
        return ret;
    }

    enum DesErrors {
        NoDesError,
        InvalidKeyDesError,
        CannotOpenInputFileDesError,
        CannotOpenOutputFileDesError,
        FileReadDesError,
        FileWriteDesError,
        InputFileIsEmptyDesError,
        EncryptedDataIsNotPaddedDesError,
        EncryptionDesError,
        DecryptionDesError,
        InvalidKeySizeDesError
    };

    int aesEncryptDecryptFile(const char *inPath, const char *outPath, const unsigned char *key, const unsigned char *iv, size_t keySize, bool encrypt, std::string *digest = NULL)
    {
        const size_t BLOCK_SIZE = 4096;
        const size_t MAX_PADDING_LEN = 16;
        const EVP_CIPHER *cipher_type;

        switch (keySize) {
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
            return InvalidKeySizeDesError;
        }

        FILE *inFile = fopen(inPath, "rb");
        if (!inFile)
            return CannotOpenInputFileDesError;

        FILE *outFile = fopen(outPath, "wb");
        if (!outFile) {
            fclose(inFile);
            return CannotOpenOutputFileDesError;
        }

        fseek(inFile, 0, SEEK_END);
        size_t fileSize = ftell(inFile);
        fseek(inFile, 0, SEEK_SET);

        if (fileSize == 0) {
            fclose(inFile);
            fclose(outFile);
            return InputFileIsEmptyDesError;
        }

        EVP_CIPHER_CTX ctx;
        EVP_CIPHER_CTX_init(&ctx);

        int ret;
        if (encrypt)
            ret = EVP_EncryptInit_ex(&ctx, cipher_type, NULL, key, iv);
        else
            ret = EVP_DecryptInit_ex(&ctx, cipher_type, NULL, key, iv);

        if (!ret)
            return InvalidKeyDesError;

        EVP_MD_CTX digestCtx;
        const EVP_MD *md = NULL;

        if (digest) {
            md = EVP_get_digestbyname("md5");
            if (md) {
                EVP_MD_CTX_init(&digestCtx);
                EVP_DigestInit_ex(&digestCtx, md, NULL);
            }
        }

        unsigned char *inBuffer = new unsigned char[BLOCK_SIZE];
        unsigned char *outBuffer = new unsigned char[BLOCK_SIZE + MAX_PADDING_LEN];

        ret = 0;
        for (size_t pos = 0; pos < fileSize; ) {

            size_t toRead = std::min(BLOCK_SIZE, fileSize - pos);
            size_t read = fread(inBuffer, 1, toRead, inFile);
            if (read < toRead) {
                ret = FileReadDesError;
                int errorCode = ferror(inFile);
                std::cerr << "File read error: " << errorCode << ": " << strerror(errorCode) << '\n';
                break;
            }

            int decodedLen;

            if (encrypt)
                ret = EVP_EncryptUpdate(&ctx, outBuffer, &decodedLen, inBuffer, read);
            else
                ret = EVP_DecryptUpdate(&ctx, outBuffer, &decodedLen, inBuffer, read);

            if (!ret) {
                ret = EncryptionDesError;
                break;
            }

            pos += read;

            if (pos == fileSize) {
                int paddingWritten;

                if (encrypt)
                    ret = EVP_EncryptFinal_ex(&ctx, outBuffer + decodedLen, &paddingWritten);
                else
                    ret = EVP_DecryptFinal_ex(&ctx, outBuffer + decodedLen, &paddingWritten);

                if (!ret) {
                    ret = EncryptionDesError;
                    break;
                }

                decodedLen += paddingWritten;
            }

            if (md) {
                EVP_DigestUpdate(&digestCtx, outBuffer, decodedLen);

                if (pos == fileSize) {
                    unsigned char *digestValue = new unsigned char[EVP_MAX_MD_SIZE];
                    unsigned int digestLen = 0;

                    EVP_DigestFinal_ex(&digestCtx, digestValue, &digestLen);
                    EVP_MD_CTX_cleanup(&digestCtx);

                    digest->reserve(digestLen * 2);
                    char buff[3];
                    for (unsigned int i = 0; i < digestLen; i++) {
                        sprintf(buff, "%02x", (unsigned int)digestValue[i]);
                        digest->push_back(buff[0]);
                        digest->push_back(buff[1]);
                    }
                    delete [] digestValue;
                }
            }


            size_t written = fwrite(outBuffer, 1, decodedLen, outFile);
            if  (written < (size_t) decodedLen) {
                ret = FileWriteDesError;
                int errorCode = ferror(outFile);
                std::cerr << "File write error: " << errorCode << ": " << strerror(errorCode) << '\n';
                break;
            }

            ret = 0;
        }

        delete [] inBuffer;
        delete [] outBuffer;
        fclose(inFile);
        fclose(outFile);

        EVP_CIPHER_CTX_cleanup(&ctx);

        return ret;
    }


    // Triple CBC DES encryption with three keys. This means that each DES operation inside the CBC mode is C=E(ks3,D(ks2,E(ks1,M))). This is the mode is used by SSL.
    //
    // The data must be in 8 byte blocks. This means that the last block may be padded by this function.
    // Extra block (8 bytes) is always padded at the end and contains the number of padded bytes in the last byte.
    int desEncryptDecryptFile(const char *inPath, const char *outPath, const_DES_cblock keys[3], bool encrypt)
    {
        const size_t BLOCK_SIZE = 4096;

        FILE *inFile = fopen(inPath, "rb");
        if (!inFile)
            return CannotOpenInputFileDesError;

        FILE *outFile = fopen(outPath, "wb");
        if (!outFile) {
            fclose(inFile);
            return CannotOpenOutputFileDesError;
        }

        fseek(inFile, 0, SEEK_END);
        size_t fileSize = ftell(inFile);
        fseek(inFile, 0, SEEK_SET);

        if (fileSize == 0) {
            fclose(inFile);
            fclose(outFile);
            return InputFileIsEmptyDesError;
        }

        DES_key_schedule ks[3];
        DES_cblock ivec;

        for (int i = 0; i < 3; ++i) {
            DES_set_key(&keys[i], &ks[i]);
        }
        memcpy(ivec, DES_IVSETUP, sizeof(DES_IVSETUP));

        unsigned char *inBuffer = new unsigned char[BLOCK_SIZE + 8];
        unsigned char *outBuffer = new unsigned char[BLOCK_SIZE + 8];

        int ret = 0;
        for (size_t pos = 0; pos < fileSize; ) {

            size_t toRead = std::min(BLOCK_SIZE, fileSize - pos);
            size_t read = fread(inBuffer, 1, toRead, inFile);
            if (read < toRead) {
                ret = FileReadDesError;
                int errorCode = ferror(inFile);
                std::cerr << "File read error: " << errorCode << ": " << strerror(errorCode) << '\n';
                break;
            }

            size_t toEncrypt = read;
            if (read % 8 != 0) {
                if (!encrypt) {
                    ret = EncryptedDataIsNotPaddedDesError;
                    break;
                }

                // Pad to 8 bytes boundary. This will be filled with zeros below.
                toEncrypt = ((read / 8) + 1) * 8;
                std::cerr << "read: " << read << " => " << toEncrypt << '\n';
            }

            pos += read;

            if (pos == fileSize) {
                if (encrypt) {
                    // Always add 8 bytes padding with the number of padded bytes
                    // saved in the last byte of the padding.
                    int padding = toEncrypt - read + 8;
                    toEncrypt += 8;
                    memset(inBuffer + read, 0, padding);
                    unsigned char cpadding = (unsigned char) padding; // cannot be bigger then 15
                    *(inBuffer + toEncrypt - 1) = cpadding;
                    std::cerr << "total padding: " << padding << '\n';
                }
            }

            DES_ede3_cbc_encrypt(inBuffer, outBuffer, toEncrypt, &ks[0], &ks[1], &ks[2], &ivec, (encrypt ? DES_ENCRYPT : DES_DECRYPT));
            size_t decodedLen = toEncrypt;

            if (pos == fileSize) {
                if (!encrypt) {
                    // If this was the last block, then skip padding.
                    unsigned char cpadding = outBuffer[toEncrypt - 1];
                    int padding = (int)cpadding;
                    std::cerr << "read total padding: " << padding << '\n';
                    decodedLen -= padding;
                }
            }

            size_t written = fwrite(outBuffer, 1, decodedLen, outFile);
            if  (written < decodedLen) {
                ret = FileWriteDesError;
                int errorCode = ferror(outFile);
                std::cerr << "File write error: " << errorCode << ": " << strerror(errorCode) << '\n';
                break;
            }


        }

        delete [] inBuffer;
        delete [] outBuffer;
        fclose(inFile);
        fclose(outFile);
        return ret;
    }
}

int Crypto::encryptFile(const char *inPath, const char *outPath, std::string *base64KeyString)
{
    DES_cblock keys[3];
    desGenerateKeys(keys);
    *base64KeyString = desKeysToBase64(keys);

    return desEncryptDecryptFile(inPath, outPath, keys, true);
}

int Crypto::decryptFile(const char *inPath, const char *outPath, const std::string &base64KeyString)
{
    DES_cblock keys[3];

    if (desKeysFromBase64(base64KeyString, keys))
        return desEncryptDecryptFile(inPath, outPath, keys, false);
    else
        return InvalidKeyDesError;
}

int Crypto::aesEncryptFile(const char *inPath, const char *outPath, std::string *base64KeyString, std::string *checksum)
{
    const size_t KEY_LEN = 32; // 256 bit
    const size_t IV_LEN = 16; // required by BouncyCastle
    unsigned char key[KEY_LEN], iv[IV_LEN];
    aesGenerateKeyAndIv(key, iv, KEY_LEN, IV_LEN);
    *base64KeyString = aesKeyAndIvToBase64(key, iv, KEY_LEN, IV_LEN);

    return aesEncryptDecryptFile(inPath, outPath, key, iv, KEY_LEN, true, checksum);
}

int Crypto::aesDecryptFile(const char *inPath, const char *outPath, const std::string &base64KeyString, std::string *checksum)
{
    std::vector<unsigned char> key, iv;

    if (aesKeyAndIvFromBase64(base64KeyString, &key, &iv))
        return aesEncryptDecryptFile(inPath, outPath, key.data(), iv.data(), key.size(), false, checksum);
    else
        return InvalidKeyDesError;
}

// CBC DES encryption with three keys (used by SSL).
void Crypto::desTest()
{
    std::vector<char> data;
    data.push_back('A');
    data.push_back('l');
    data.push_back('a');
    data.push_back(' ');
    data.push_back('m');
    data.push_back('a');
    data.push_back(' ');
    data.push_back('k');
    data.push_back('o');
    data.push_back('t');
    data.push_back('a');

    std::string base64;
    b64::base64Encode(data, &base64);
    std::vector<char> decoded;
    b64::base64Decode(base64, &decoded);

    std::cerr << "Org data:";
    for (std::size_t i = 0; i < data.size(); ++i)
        std::cerr << data[i];
    std::cerr << '\n';

    std::cerr << "Encoded data:" << base64;

    std::cerr << "Decoded data:";
    for (std::size_t i = 0; i < data.size(); ++i)
        std::cerr << data[i];
    std::cerr << '\n';

    //const DES_cblock seed = {0xFE, 0xDC, 0xBA, 0x84, 0x76, 0x99, 0x32, 0x10};

    unsigned char in[BUFSIZE], out[BUFSIZE], back[BUFSIZE];
    unsigned char *e = out;
    int len;

    DES_cblock inKeys[3];
    DES_cblock keys[3];
    DES_key_schedule ks[3];
    DES_cblock ivec;

    memset(in, 0, sizeof(in));
    memset(out, 0, sizeof(out));
    memset(back, 0, sizeof(back));

    //RAND_seed(seed, sizeof(DES_cblock));
    desGenerateKeys(inKeys);

    std::string keysB64 = desKeysToBase64(keys);
    std::cerr << "keys 64: " << keysB64;

    desKeysFromBase64(keysB64, keys);


    for (int i = 0; i < 3; ++i) {
        //DES_random_key(&keys[i]);
        DES_set_key((const_DES_cblock *)inKeys[i], &ks[i]);
    }



    /* 64 bytes of plaintext */
    strcpy((char *)in, "Now is the time for all men to stand up and be counted");

    printf("Plaintext: [%s]\n", (char *)in);

    len = strlen((char *)in);
    memcpy(ivec, DES_IVSETUP, sizeof(DES_IVSETUP));
    DES_ede3_cbc_encrypt(in, out, len, &ks[0], &ks[1], &ks[2], &ivec, DES_ENCRYPT);

    printf("Ciphertext:");
    while (*e) printf(" [%02x]", *e++);
    printf("\n");

    for (int i = 0; i < 3; ++i) {
        DES_set_key((const_DES_cblock *)keys[i], &ks[i]);
    }

    len = strlen((char *)out);
    memcpy(ivec, DES_IVSETUP, sizeof(DES_IVSETUP));
    DES_ede3_cbc_encrypt(out, back, len, &ks[0], &ks[1], &ks[2], &ivec, DES_DECRYPT);

    printf("Decrypted Text: [%s]\n", back);
}

void Crypto::init()
{
    OpenSSL_add_all_algorithms();
}

void Crypto::randomBytes(char *buffer, size_t len)
{
    RAND_bytes((unsigned char *)buffer, len);
}

} // namespace core

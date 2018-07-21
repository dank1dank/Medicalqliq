#include "CryptoKeyStore.hpp"
#include <cstdio>
#include <cassert>
#if defined(WIN32)
#include <direct.h>
#elif defined(__APPLE__) && defined(__GNUC__)
#include <sys/types.h>
#include <sys/stat.h>
#endif
#include <errno.h>
#include <openssl/pem.h>
#include "util/StringUtil.hpp"

#ifdef WIN32
#include <windows.h>

#define PATH_SEPARATOR '\\'
#define WPATH_SEPARATOR L'\\'

#else
#define PATH_SEPARATOR '/'
#define WPATH_SEPARATOR L'/'
#endif

namespace core {

FileCryptoKeyStore::FileCryptoKeyStore(const String& baseDir) :
    _baseDir(StringUtil::toStdString(baseDir))
{
    if (!_baseDir.empty())
        if (_baseDir[_baseDir.size() - 1] != PATH_SEPARATOR)
            _baseDir.push_back(PATH_SEPARATOR);
}

bool FileCryptoKeyStore::store(EVP_PKEY *key, KeyType type, const String& userName, const String& aPassword)
{
    bool ret = false;
    if (createPathIfDoesntExist(pathForUser(userName)))
    {
        std::string path = pathForType(userName, type);
        std::string password = StringUtil::toStdString(aPassword);

        FILE *f = fopen(path.c_str(), "w");
        if (f)
        {
            if (type == PrivateKey)
                ret = PEM_write_PrivateKey(f, key, EVP_des_ede3_cbc(), NULL, 0, NULL, (void *)password.c_str());
            else
                ret = PEM_write_PUBKEY(f, key);

            fclose(f);
        }
    }
    return ret;
}

bool FileCryptoKeyStore::load(EVP_PKEY **key, std::string *keyString, KeyType type, const String& userName, const String& aPassword)
{
    assert(key != NULL);
    *key = NULL;

    std::string path = pathForType(userName, type);
    std::string password = StringUtil::toStdString(aPassword);

    FILE *f = fopen(path.c_str(), "r");
    if (f)
    {
        if (type == PrivateKey)
            PEM_read_PrivateKey(f, key, NULL, (void *)password.c_str());
        else
            PEM_read_PUBKEY(f, key, NULL, (void *)password.c_str());

        if (keyString != NULL)
        {
            // Read the raw bytes also
            fseek(f, 0, SEEK_END);
            size_t len = ftell(f);
            fseek(f, 0, SEEK_SET);

            std::string buffer(len, 0);
            fread(&buffer[0], len, 1, f);
            fclose(f);

            *keyString = buffer;
        }
    }

    return (*key != NULL);
}

std::string FileCryptoKeyStore::pathForUser(const String &userName) const
{
    // _baseDir has separator at the end
    std::string stdUserName = StringUtil::toStdString(userName);
    return _baseDir + stdUserName;
}

std::string FileCryptoKeyStore::pathForType(const String& userName, CryptoKeyStore::KeyType type) const
{
    return pathForUser(userName) + PATH_SEPARATOR + (type == PublicKey ? "public_key" : "private_key");
}

static bool createDirectory(const std::string& path)
{
    bool ret = true;
#ifdef WIN32
    ret = CreateDirectoryA(path.c_str(), NULL);
    if (!ret)
    {
        DWORD error = GetLastError();
        if (error == ERROR_ALREADY_EXISTS)
            ret = true;
    }
#else

#if defined(__APPLE__) && defined(__GNUC__)
    int err = mkdir(path.c_str(), S_IRWXU | S_IRWXG | S_IRWXO );
#else
    int err = mkdir(path.c_str() );
#endif

    if (err != 0)
    {
        if (errno == EEXIST)
            ret = true;
        else
            ret = false;
    }
#endif
    return ret;
}

bool FileCryptoKeyStore::createPathIfDoesntExist(const std::string &destPath)
{
    bool ret = true;

    if (!createDirectory(destPath))
    {
        std::string path;
        std::vector<std::string> elems = StringUtil::split(destPath, PATH_SEPARATOR, false);
        for (std::size_t i = 0; i < elems.size(); ++i)
        {
            path += elems[i];
            path += PATH_SEPARATOR;

            if (!createDirectory(path))
            {
                ret = false;
                break;
            }
        }
    }

    return ret;
}

} // namespace core

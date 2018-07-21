#include "QxLogArchive.hpp"
#include <vector>
#include <map>
#include <fstream>
#include <ctime>
#include <memory>
#include <sstream>
#include "qxlib/util/compress/zip/zip.h"
#include "qxlib/util/QxFilesystem.hpp"
#include "qxlib/db/QxDatabase.hpp"

namespace {
static zlib_filefunc_def s_zlibFileFunctions = {0};
}

namespace qx {

struct LogArchive::Private {
    struct FileDesc {
        std::string fileName;
        std::string password;

        FileDesc()
        {}

        FileDesc(const std::string& fileName, const std::string& password) :
            fileName(fileName), password(password)
        {}
    };

    struct VirtualFileDesc : public FileDesc {
        std::string data;

        VirtualFileDesc()
        {}

        VirtualFileDesc(const std::string& fileName, const std::string& password, const std::string& data) :
            FileDesc(fileName, password),
            data(data)
        {}
    };

    struct TempFileDesc : public FileDesc {
        std::string customFileName;

        TempFileDesc()
        {}

        TempFileDesc(const std::string& fileName, const std::string& password, const std::string& customFileName) :
            FileDesc(fileName, password),
            customFileName(customFileName)
        {}
    };

    void *zipFile;
    std::string path;
    std::string dbKey;
    std::vector<FileDesc> dbFiles;
    std::vector<FileDesc> files;
    std::map<std::string, VirtualFileDesc> virtualFiles;
    std::vector<std::string> filesToRemove;
    std::vector<TempFileDesc> tempFiles;
    bool decryptDatabase;

    Private() :
        zipFile(nullptr), decryptDatabase(false)
    {}

    ~Private()
    {
        closeFile();
        removeTemporaryFiles();
    }

    void closeFile()
    {
        if (zipFile) {
            zipClose(zipFile, nullptr);
            zipFile = nullptr;
        }
    }

    void removeTemporaryFiles();
    //static bool addEntryFile(QuaZip *zip, const std::string& entryFileName, QFile *inputFile, const std::string& password = "");
//    static bool addEntryData(QuaZip *zip, const std::string& entryFileName, QByteArray& data, const std::string& password = "");
    //static bool addEntry(const QuaZipNewInfo& info, QIODevice *inputDevice, const std::string& password = "");
    bool addEntry(const std::string& entryFileName, std::istream& input, const std::string& password = "");
    bool addEntryData(const std::string& entryFileName, const std::string& input, const std::string& password = "");
    bool addEntryInZip(const std::string& entryFileName, const std::string& password = "");
    bool writeData(std::istream& input);
};

LogArchive::LogArchive() :
    d(new Private())
{
    if (s_zlibFileFunctions.zopen_file == nullptr) {
        fill_fopen_filefunc(&s_zlibFileFunctions);
    }
}

LogArchive::~LogArchive()
{
    delete d;
}

bool LogArchive::open()
{
    close();
    d->path = Filesystem::temporaryFilePath(".zip");
    d->zipFile = zipOpen2((voidpf)d->path.c_str(), APPEND_STATUS_CREATE, nullptr, &s_zlibFileFunctions);
    return d->zipFile != nullptr;
}

bool LogArchive::isOpen() const
{
    return d->zipFile != nullptr;
}

void LogArchive::close()
{
    d->closeFile();
    d->path.clear();
}

bool LogArchive::compress()
{
    if (!isOpen()) {
        if (!open()) {
            return false;
        }
    }

#ifdef NO_SQL
    for (std::size_t i = 0, size = d->dbFiles.size(); i < size; ++i) {
        d->files.push_back(d->dbFiles[i]);
    }
    addFile("db-key.txt", d->dbKey);
#else
    if (!isDecryptDatabase()) {
        d->files.reserve(d->files.size() + d->dbFiles.size());
        for (const auto& fileDesc: d->dbFiles) {
            d->files.push_back(fileDesc);
        }
    } else {
        for (const auto& fileDesc: d->dbFiles) {
            FileInfo fileInfo(fileDesc.fileName);
            std::string tempPath = Filesystem::temporaryFilePath(".db");
            std::string errorMsg = QxDatabase::decryptDatabaseToPlaintext(fileDesc.fileName, tempPath, d->dbKey);
            if (errorMsg.empty()) {
                addTemporaryFile(fileInfo.fileName(), tempPath, fileDesc.password);
            } else {
                d->files.push_back(fileDesc);
                d->files.push_back({fileDesc.fileName + "-wal", fileDesc.password});
                d->files.push_back({fileDesc.fileName + "-shm", fileDesc.password});
            }
        }
    }
#endif

    for (const auto& fileDesc: d->files) {
        std::ifstream inputFileStream(fileDesc.fileName.c_str(), std::ios_base::in | std::ios_base::binary);
        if (inputFileStream.is_open()) {
            FileInfo inputFileInfo(fileDesc.fileName);

            if (!d->addEntry(inputFileInfo.fileName(), inputFileStream, fileDesc.password)) {
                goto zipping_error;
            }
        }
    }

    for (const auto& tempDesc: d->tempFiles) {
        std::ifstream inputFileStream(tempDesc.fileName.c_str(), std::ios_base::in | std::ios_base::binary);
        if (inputFileStream.is_open()) {
            if (!d->addEntry(tempDesc.customFileName, inputFileStream, tempDesc.password)) {
                goto zipping_error;
            }
        }
    }

    for (auto it: d->virtualFiles) {
        Private::VirtualFileDesc& virtDesc = it.second;
        if (!d->addEntryData(virtDesc.fileName, virtDesc.data, virtDesc.password)) {
            goto zipping_error;
        }
    }


    for (const auto& path: d->filesToRemove) {
        Filesystem::removeFile(path);
    }

    d->tempFiles.clear();

    return true;
zipping_error:
    return false;
}

void LogArchive::addFile(const std::string &path, const std::string &password)
{
    d->files.push_back({path, password});
}

void LogArchive::addVirtualFile(const std::string &fileName, const std::string &content, const std::string &password)
{
    if (!content.empty()) {
        d->virtualFiles[fileName] = Private::VirtualFileDesc(fileName, password, content);
    }
}

void LogArchive::addVersionedFiles(const std::string &path, int count, const std::string &password)
{
    d->files.push_back({path, password});

    for (int i = 1; i < count; ++i) {
        std::string versionedPath = path + std::to_string(i);
        d->files.push_back({versionedPath, password});
        d->filesToRemove.push_back(versionedPath);
    }
}

void LogArchive::addFileToRemove(const std::string &path, const std::string &password)
{
    d->files.push_back({path, password});
    d->filesToRemove.push_back(path);
}

void LogArchive::addTemporaryFile(const std::string &fileName, const std::string &tempPath, const std::string &password)
{
    d->tempFiles.push_back({tempPath, password, fileName});
    d->filesToRemove.push_back(tempPath);
}

void LogArchive::addDatabaseFile(const std::string &path, const std::string &password)
{
    d->dbFiles.push_back({path, password});
    if (!isDecryptDatabase()) {
        d->dbFiles.push_back({path + "-wal", password});
        d->dbFiles.push_back({path + "-shm", password});
    }
}

void LogArchive::setDatabaseKey(const std::string &key)
{
    d->dbKey = key;
}

void LogArchive::setDecryptDatabase(bool value)
{
    d->decryptDatabase = value;
}

bool LogArchive::isDecryptDatabase() const
{
    return d->decryptDatabase && !d->dbKey.empty();
}

void LogArchive::Private::removeTemporaryFiles()
{
    for (const auto& tempDesc: tempFiles) {
        Filesystem::removeFile(tempDesc.fileName);
    }
}

bool LogArchive::Private::addEntry(const std::string &entryFileName, std::istream &input, const std::string &password)
{
    bool ret = false;
    if (addEntryInZip(entryFileName, password)) {
        ret = writeData(input);
    }
    return ret;
}

bool LogArchive::Private::addEntryData(const std::string &entryFileName, const std::string &data, const std::string &password)
{
    bool ret = false;
    if (addEntryInZip(entryFileName, password)) {
        std::istringstream input(data);
        ret = writeData(input);
    }
    return ret;
}

bool LogArchive::Private::addEntryInZip(const std::string &entryFileName, const std::string &password)
{
    std::time_t rawTime;
    std::time(&rawTime);
    std::tm *timeInfo = std::localtime(&rawTime);

    zip_fileinfo zipFileInfo = {0};
    zipFileInfo.tmz_date.tm_year = timeInfo->tm_year;
    zipFileInfo.tmz_date.tm_mon = timeInfo->tm_mon;
    zipFileInfo.tmz_date.tm_mday = timeInfo->tm_mday;
    zipFileInfo.tmz_date.tm_hour = timeInfo->tm_hour;
    zipFileInfo.tmz_date.tm_min = timeInfo->tm_min;
    zipFileInfo.tmz_date.tm_sec = timeInfo->tm_sec;

    int ret = zipOpenNewFileInZip3(zipFile, entryFileName.c_str(), &zipFileInfo, nullptr, 0, nullptr, 0,
                                   nullptr, Z_DEFLATED, Z_DEFAULT_COMPRESSION, 0,
                                   MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, (!password.empty() ? password.c_str() : nullptr), 0);
    return ret == 0;
}

bool LogArchive::Private::writeData(std::istream &input)
{
    if (!input) {
        return false;
    }

    const std::size_t bufferSize = 1024 * 128;
    std::unique_ptr<char[]> buffer(new char[bufferSize]);
    std::size_t read;

    while ((read = input.readsome(buffer.get(), bufferSize)) > 0) {
        int ret = zipWriteInFileInZip(zipFile, buffer.get(), read);
        if (ret != 0) {
            return false;
        }
    }
    return true;
}

} // qx

#ifndef QXLOGARCHIVE_HPP
#define QXLOGARCHIVE_HPP
#include <string>

namespace qx {

class LogArchive
{
public:
    LogArchive();
    ~LogArchive();

    bool open();
    bool isOpen() const;
    void close();
    bool compress();
    std::string filePath();

    void addFile(const std::string& path, const std::string& password = "");
    void addVirtualFile(const std::string& fileName, const std::string& content, const std::string& password = "");
    void addVersionedFiles(const std::string& path, int count, const std::string& password = "");
    void addFileToRemove(const std::string& path, const std::string& password = "");
    void addTemporaryFile(const std::string& fileName, const std::string& tempPath, const std::string& password = "");

    void addDatabaseFile(const std::string& path, const std::string& password = "");
    void setDatabaseKey(const std::string& key);
    void setDecryptDatabase(bool value);
    bool isDecryptDatabase() const;

    // Returns defaut password, method renamed for security reasons
    static std::string method1();

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QXLOGARCHIVE_HPP

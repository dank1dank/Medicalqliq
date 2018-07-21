#ifndef QXFILESYSTEM_HPP
#define QXFILESYSTEM_HPP
#include <string>
#include <initializer_list>
#include <vector>

namespace qx {

class FileInfo {
public:
    FileInfo(const std::string& path);

    std::string fileName() const;
    std::string extension(bool includeDot = false) const;
    std::string baseName() const;
    std::string dirPath() const;
    unsigned long size() const;
    std::string mime() const;

private:
    std::string m_path;
};

class Filesystem
{
public:
    Filesystem();

    // path joining and splitting
    static char separator();
    static const std::string& separatorString();
    static std::string join(const std::string& dir, const std::string& file);
    static std::string join(const std::initializer_list<std::string>& parts);
    static std::vector<std::string> split(const std::string& path);

    // temporary dir and files
    static std::string temporaryDirPath();
    static std::string temporaryFilePath(const std::string& suffix = "");
    static std::string randomFileName(std::size_t len, const std::string& suffix = "");

    static bool removeFile(const std::string& path);
    static bool exists(const std::string& path);
    static bool existsDir(const std::string& path);
    static bool existsFile(const std::string& path);

    static std::string readWholeFile(const std::string& path);

    // make directory or tree
    static bool mkdir(const std::string& path);
    static bool mkpath(const std::string& path);

    // throws std::runtime_error
    static void copy(const std::string& fromPath, const std::string& toPath);
};

} // qx

#endif // QXFILESYSTEM_HPP

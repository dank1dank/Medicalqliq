#include "QxFilesystem.hpp"
#include <sys/stat.h>
#include <random>
#include <ctime>
#include <fstream>
#include <sstream>
#include <cstring>
#include "qxlib/util/QxStdioUtil.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/log/QxLog.hpp"
#ifdef _WIN32
#include "qxlib/platform/windows/QxPlatformWindowsHelpers.hpp"
#endif

extern std::string qx_filesystem_temporaryDirPath_impl();
extern std::string qx_FileInfo_mime_impl(const std::string& path);

namespace qx {

namespace {

std::string::size_type findLastSeparator(const std::string& path) {
    auto pos = path.find_last_of(Filesystem::separator());
#ifdef _WIN32
    if (pos == std::string::npos) {
        // Extra check for Qt style path
        pos = path.find_last_of('/');
    }
#endif
    return pos;
}

int stat_utf8(const std::string& path, struct stat *_stat)
{
#ifdef _WIN32
    std::wstring wpath = qx::convertFromUtf8ToUtf16(path);
    return wstat(wpath.c_str(), _stat);
#else
    return stat(path.c_str(), _stat);
#endif
}

} // namespace

Filesystem::Filesystem()
{

}

char Filesystem::separator()
{
#if defined(Q_OS_WIN) || defined(_WIN32)
    return '\\';
#else
    return '/';
#endif
}

const std::string &Filesystem::separatorString()
{
    static std::string sep(1, separator());
    return sep;
}

std::string Filesystem::join(const std::string &dir, const std::string &file)
{
    std::string ret = dir;
    const char sep = separator();
    ret.reserve(dir.size() + file.size() + 1);

    if (!ret.empty() && !file.empty() && ret[ret.size() - 1] != sep) {
        ret.push_back(sep);
    }
    ret.append(file);
    return ret;
}

std::string Filesystem::join(const std::initializer_list<std::string> &parts)
{
    std::string ret;
    const char sep = separator();

    for (const auto& part: parts) {
        if (!ret.empty() && ret[ret.size() - 1] != sep) {
            ret.push_back(sep);
        }
        ret.append(part);
    }
    return ret;
}

std::vector<std::string> Filesystem::split(const std::string &path)
{
    std::vector<std::string> dirs = StringUtils::split(path, separator());
#ifdef _WIN32
    if (!dirs.empty() && dirs[0].size() == 2 && dirs[0][1] == ':') {
        // This is a drive letter, we need to append '\'
        dirs[0].push_back('\\');
    }
#else
    if (!dirs.empty() && dirs[0].empty()) {
        // This is the root / directory
        dirs[0] = "/";
    }
#endif
    return dirs;
}

std::string Filesystem::temporaryDirPath()
{
    return qx_filesystem_temporaryDirPath_impl();
}

std::string Filesystem::temporaryFilePath(const std::string& suffix)
{
    return temporaryDirPath() + separatorString() + randomFileName(10, suffix);
}

std::string Filesystem::randomFileName(std::size_t len, const std::string &suffix)
{
    std::string fileName;
    fileName.reserve(len + suffix.size());

    std::default_random_engine rng(time(nullptr));
    std::uniform_int_distribution<char> rng_dist('a', 'z');
    for (std::size_t i = 0; i < len; ++i) {
        fileName.push_back(rng_dist(rng));
    }

    if (!suffix.empty()) {
        fileName.append(suffix);
    }
    return fileName;
}

bool Filesystem::removeFile(const std::string &path)
{
    return remove(path.c_str()) == 0;
}

bool Filesystem::exists(const std::string &path)
{
    struct stat buffer;
    return (stat_utf8(path, &buffer) == 0);
}

bool Filesystem::existsDir(const std::string &path)
{
    bool ret = false;
    struct stat buffer;
    if (stat_utf8(path, &buffer) == 0) {
         ret = ((buffer.st_mode & S_IFDIR) == S_IFDIR);
    }
    return ret;
}

bool Filesystem::existsFile(const std::string &path)
{
    bool ret = false;
    struct stat buffer;
    if (stat_utf8(path, &buffer) == 0) {
         ret = ((buffer.st_mode & S_IFREG) == S_IFREG);
#ifndef _WIN32
         ret |= ((buffer.st_mode & S_IFLNK) == S_IFLNK);
#endif
    }
    return ret;
}

std::string Filesystem::readWholeFile(const std::string &path)
{
    std::ostringstream ss;
    std::ifstream ifs(path);
    if (ifs.is_open()) {
        ss << ifs.rdbuf();
    }
    return ss.str();
}

bool Filesystem::mkdir(const std::string &path)
{
#ifdef _WIN32
    std::wstring wpath = qx::convertFromUtf8ToUtf16(path);
    bool ret = (::_wmkdir(wpath.c_str()) == 0);
#else
    bool ret = (::mkdir(path.c_str(), 0755) == 0);
#endif
    if (!ret) {
        if (errno == EEXIST && existsDir(path)) {
            ret = true;
        } else {
            QXLOG_ERROR("Cannot create directory \"%s\", error: %s", path.c_str(), strerror(errno));
        }
    }
    return ret;
}

bool Filesystem::mkpath(const std::string &path)
{
    if (existsDir(path)) {
        return true;
    }

    std::vector<std::string> dirs = split(path);
    std::string iteratedPath;
    for (const auto& dir: dirs) {
        iteratedPath = join(iteratedPath, dir);
        if (!Filesystem::existsDir(iteratedPath)) {
            if (!mkdir(iteratedPath)) {
                return false;
            }
        }
    }

    return true;
}

void Filesystem::copy(const std::string &fromPath, const std::string &toPath)
{
    unique_file_ptr inFile{fopen_utf8(fromPath, "rb")};
    if (!inFile) {
        std::string what = "Cannot open input file: " + fromPath + ", error: " + std::strerror(errno);
        QXLOG_ERROR("%s", what.c_str());
        throw std::runtime_error(what);
    }

    unique_file_ptr outFile{fopen_utf8(toPath, "wb")};
    if (!outFile) {
        std::string what = "Cannot open output file: " + toPath + ", error: " + std::strerror(errno);
        QXLOG_ERROR("%s", what.c_str());
        throw std::runtime_error(what);
    }

    std::unique_ptr<char[]> buffer{new char[BUFSIZ]};
    size_t size;

    while ((size = std::fread(buffer.get(), 1, BUFSIZ, inFile.get()))) {
        if (std::fwrite(buffer.get(), 1, size, outFile.get()) != size) {
           std::string what = "Error writing to file: " + toPath + ", error: " + std::strerror(errno);
           QXLOG_ERROR("%s", what.c_str());
           throw std::runtime_error(what);
        }
    };

    if (std::ferror(inFile.get()) != 0) {
        std::string what = "Error reading from file: " + fromPath + ", error: " + std::strerror(errno);
        QXLOG_ERROR("%s", what.c_str());
        throw std::runtime_error(what);
    }
}

FileInfo::FileInfo(const std::string &path) :
    m_path(path)
{}

std::string FileInfo::fileName() const
{
    auto pos = findLastSeparator(m_path);
    if (pos != std::string::npos) {
        return m_path.substr(pos + 1);
    } else {
        return m_path;
    }
}

std::string FileInfo::baseName() const
{
    auto fn = fileName();
    auto pos = fn.find('.');
    if (pos != std::string::npos) {
        return m_path.substr(0, pos);
    } else {
        return fn;
    }
}

std::string FileInfo::dirPath() const
{
    auto pos = findLastSeparator(m_path);
    if (pos != std::string::npos) {
        return m_path.substr(0, pos);
    } else {
        return "";
    }
}

std::string FileInfo::extension(bool includeDot) const
{
    std::string::size_type pos = m_path.find_last_of('.');

    if (pos != std::string::npos) {
        // Check for case when '.' is present in directory path
        std::string::size_type lastSeparatorPos = findLastSeparator(m_path);
        if (lastSeparatorPos != std::string::npos && pos < lastSeparatorPos) {
            pos = m_path.substr(lastSeparatorPos).find_last_of('.');
        }
    }

    if (pos != std::string::npos) {
        return m_path.substr(pos + (includeDot ? 0 : 1));
    } else {
        return "";
    }
}

unsigned long FileInfo::size() const
{
    unsigned long ret = 0;
    unique_file_ptr f{fopen_utf8(m_path, "rb")};
    if (f) {
        fseek(f.get(), 0, SEEK_END);
        ret = ftell(f.get());
    }
    return ret;
}

std::string FileInfo::mime() const
{
    return qx_FileInfo_mime_impl(m_path);
}

} // qx

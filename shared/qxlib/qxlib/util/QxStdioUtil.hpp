#ifndef QXSTDIOUTIL_HPP
#define QXSTDIOUTIL_HPP
#include <cstdio>
#include <memory>

namespace qx {

struct FcloseDeleter {
    void operator()(FILE *f) const
    {
    fclose(f);
    }
};
typedef std::unique_ptr<FILE, FcloseDeleter> unique_file_ptr;

// This function will open correctly files on Windows when path is in UTF-8 encoding
// It will internally convert path to wide string
unique_file_ptr fopen_utf8(const std::string& path, const std::string& mode);

} // qx

#endif // QXSTDIOUTIL_HPP

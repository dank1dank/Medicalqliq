#ifndef QXZSTD_HPP
#define QXZSTD_HPP
#include <memory>
#include <string>
namespace qx {

class Zstd
{
public:

    static std::size_t   compress(const void *input, std::size_t inputLen, std::unique_ptr<char[]> *output);
    static std::size_t   compress(const std::string& input, std::string *output);
    static std::size_t   compress(const char *input, std::size_t inputLen, std::string *output);

    static std::size_t decompress(const void *input, std::size_t inputLen, std::unique_ptr<char[]> *output);
};

} // qx

#endif // QXZSTD_HPP

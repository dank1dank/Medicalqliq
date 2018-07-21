#include "qxlib/crypto/QxBase64.hpp"
#include "qxlib/debug/QxAssert.hpp"

namespace qx {
namespace base64 {

std::size_t decode(const char *base64message, std::size_t len, std::string *output)
{
    std::unique_ptr<char[]> buffer;
    std::size_t decodedLength = decode(base64message, len, &buffer);

    output->reserve(decodedLength);
    output->clear();
    output->append(buffer.get(), decodedLength);

    return decodedLength;
}

std::size_t decode(const std::string &base64message, std::string *output)
{
    return decode(base64message.c_str(), base64message.size(), output);
}

std::size_t calcDecodedLength(const char *b64input, const size_t length)
{
    qx_assert(b64input != nullptr);
    qx_assert(length > 0);

    std::size_t padding = 0;

    // Check for trailing '=''s as padding
    if (b64input[length-1] == '=' && b64input[length-2] == '=')
        padding = 2;
    else if (b64input[length-1] == '=')
        padding = 1;

    return static_cast<std::size_t>(length * 0.75) - padding;
}

} // base64
} // qx

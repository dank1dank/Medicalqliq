#ifndef QX_BASE64_HPP
#define QX_BASE64_HPP
#include <string>
#include <memory>
#include <openssl/evp.h>

namespace qx {
namespace base64 {

std::size_t decode(const char *base64message, std::size_t len, std::string *output);
std::size_t decode(const std::string& base64message, std::string *output);
std::size_t calcDecodedLength(const char *b64input, const size_t length);

/**
 * Base encoding method, takes any array and invokes callback(char *b64, size_t len)
 */
template <typename C, typename Callback>
std::size_t encode(const C *plainData, size_t len, const Callback& callback)
{
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());
    mem = BIO_push(b64, mem);
    BIO_write(mem, plainData, len);
    BIO_flush(mem);

    char *base64Pointer;
    std::size_t base64Length = BIO_get_mem_data(mem, &base64Pointer);
    callback(base64Pointer, base64Length);

    BIO_free_all(mem);
    return base64Length;
}

template <typename C>
std::size_t encode(const C *plainData, size_t len, std::string *base64)
{
    return encode(plainData, len, [base64](const char *encoded, std::size_t encodedLen) {
        base64->clear();
        base64->reserve(encodedLen);
        base64->append(encoded, encodedLen);
    });
}

template <typename C>
std::size_t decode(const char *base64message, std::size_t len, std::unique_ptr<C[]> *output)
{
    BIO *mem = BIO_new_mem_buf((void *)base64message, len);
    BIO *b64 = BIO_new(BIO_f_base64());
    mem = BIO_push(b64, mem);

    std::size_t decodedLength = calcDecodedLength(base64message, len);
    *output = std::unique_ptr<C[]>{new C[decodedLength]};
    decodedLength = BIO_read(mem, output->get(), len);
    BIO_free_all(mem);
    return decodedLength;
}

} // base64
} // qx

#endif // QX_BASE64_HPP

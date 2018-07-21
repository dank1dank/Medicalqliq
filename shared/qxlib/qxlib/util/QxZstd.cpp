#include "QxZstd.hpp"
#define ZSTD_STATIC_LINKING_ONLY
#include <zstd.h>
#include "qxlib/log/QxLog.hpp"

namespace qx {

std::size_t Zstd::compress(const void *input, std::size_t inputLen, std::unique_ptr<char[]> *output)
{
    size_t const cBuffSize = ZSTD_compressBound(inputLen);
    output->reset(new char[(size_t)cBuffSize]);
    void* const cBuff = output->get();

    size_t const cSize = ZSTD_compress(cBuff, cBuffSize, input, inputLen, 1);
    if (ZSTD_isError(cSize)) {
        //fprintf(stderr, "error compressing %s : %s \n", fname, ZSTD_getErrorName(cSize));
        output->reset(nullptr);
        return 0;
    }
    return cSize;
}

std::size_t Zstd::compress(const std::string &input, std::string *output)
{
    return Zstd::compress(input.c_str(), input.size(), output);
}

std::size_t Zstd::compress(const char *input, std::size_t inputLen, std::string *output)
{
    std::unique_ptr<char[]> compressed;
    auto size = Zstd::compress(input, inputLen, &compressed);
    if (size > 0) {
        *output = std::string(compressed.get(), size);
    } else {
        QXLOG_ERROR("Cannot compress: %ld", size);
    }
    return size;
}

std::size_t Zstd::decompress(const void *input, std::size_t inputLen, std::unique_ptr<char[]> *output)
{
    unsigned long long const rSize = ZSTD_findDecompressedSize(input, inputLen);

    if (rSize == ZSTD_CONTENTSIZE_ERROR) {
        //fprintf(stderr, "%s : it was not compressed by zstd.\n", fname);
        return rSize;
    } else if (rSize==ZSTD_CONTENTSIZE_UNKNOWN) {
        //fprintf(stderr, "%s : original size unknown. Use streaming decompression instead.\n", fname);
        return rSize;
    }

    output->reset(new char[(size_t)rSize]);
    void* const rBuff = output->get();

    size_t const dSize = ZSTD_decompress(rBuff, rSize, input, inputLen);

    if (dSize != rSize) {
        //fprintf(stderr, "error decoding %s : %s \n", fname, ZSTD_getErrorName(dSize));
        output->reset(nullptr);
        return 0;
    }

    /* success */
    //printf("%25s : %6u -> %7u \n", fname, (unsigned)cSize, (unsigned)rSize);
    return dSize;
}

} // qx

#include "QxCompression.hpp"
#include "zlib.h"
#include "qxlib/debug/QxAssert.hpp"

#define CHUNK 32768

int QxZlib::compress(const char *inputBuffer, unsigned int inputLen, std::vector<char> *outputBuffer, int level)
{
    if (outputBuffer->capacity() < inputLen) {
        outputBuffer->reserve(inputLen);
    }

    int ret = compress((const unsigned char *)inputBuffer, inputLen, (unsigned char *)outputBuffer->data(), outputBuffer->capacity(), level);
    const char *data = outputBuffer->data();
    if (ret > 0) {
        outputBuffer->resize(ret);
    } else {
        outputBuffer->clear();
    }

    return ret;
}

int QxZlib::decompress(const char *inputBuffer, unsigned int inputLen, std::vector<char> *outputBuffer)
{
    if (outputBuffer->capacity() < CHUNK * 2) {
        outputBuffer->reserve(CHUNK * 2);
    }

    int ret = decompress((const unsigned char *)inputBuffer, inputLen, (unsigned char *)outputBuffer->data(), outputBuffer->capacity());
    if (ret > 0) {
        outputBuffer->resize(ret);
    } else {
        outputBuffer->clear();
    }

    return ret;
}

int QxZlib::compress(const unsigned char *inputBuffer, unsigned int inputLen, unsigned char *outputBuffer, unsigned int outputLen, int level)
{
    int ret, flush;
    unsigned have;
    z_stream strm;
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];

    /* allocate deflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    ret = deflateInit(&strm, level);
    if (ret != Z_OK)
        return ret;

    /* compress until end of file */
    //do {

        strm.avail_in = inputLen;
        flush = Z_FINISH;
        strm.next_in = (Bytef *)inputBuffer;



        /* run deflate() on input until output buffer not full, finish
           compression if all of source has been read in */
        do {
            strm.avail_out = outputLen;
            strm.next_out = outputBuffer;

            ret = deflate(&strm, flush);    /* no bad return value */
            qx_assert(ret != Z_STREAM_ERROR);  /* state not clobbered */

        } while (strm.avail_out == 0);
        qx_assert(strm.avail_in == 0);     /* all input will be used */


        /* done when last data in file processed */
//    } while (flush != Z_FINISH);
    //qx_assert(ret == Z_STREAM_END);        /* stream will be complete */

    /* clean up and return */
    (void)deflateEnd(&strm);
        //return Z_OK;
        return (outputLen - strm.avail_out);
}

int QxZlib::decompress(const unsigned char *inputBuffer, unsigned int inputLen, unsigned char *outputBuffer, unsigned int outputLen)
{
    int ret;
    unsigned have;
    z_stream strm;

    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    ret = inflateInit(&strm);
    if (ret != Z_OK)
        return ret;

    /* decompress until deflate stream ends or end of file */
    do {
        strm.avail_in = inputLen;
        strm.next_in = (Bytef *)inputBuffer;

        /* run inflate() on input until output buffer not full */
        do {
            strm.avail_out = outputLen;
            strm.next_out = outputBuffer;

            ret = inflate(&strm, Z_NO_FLUSH);
            qx_assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            switch (ret) {
            case Z_NEED_DICT:
                ret = Z_DATA_ERROR;     /* and fall through */
            case Z_DATA_ERROR:
            case Z_MEM_ERROR:
                (void)inflateEnd(&strm);
                return ret;
            }

        } while (strm.avail_out == 0);

        /* done when inflate() says it's done */
    } while (ret != Z_STREAM_END);

    /* clean up and return */
    (void)inflateEnd(&strm);
    //return ret == Z_STREAM_END ? Z_OK : Z_DATA_ERROR;
    return (outputLen - strm.avail_out);
}

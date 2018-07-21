#ifndef QXCOMPRESSION_H
#define QXCOMPRESSION_H
#include <vector>

class QxZlib
{
public:
    // Lowest level method
    static int   compress(const unsigned char *inputBuffer, unsigned int inputLen, unsigned char *outputBuffer, unsigned int outputLen, int level = -1);
    static int decompress(const unsigned char *inputBuffer, unsigned int inputLen, unsigned char *outputBuffer, unsigned int outputLen);

    // C++ style helper method
    static int   compress(const char *inputBuffer, unsigned int inputLen, std::vector<char> *outputBuffer, int level = -1);
    static int decompress(const char *inputBuffer, unsigned int inputLen, std::vector<char> *outputBuffer);

};

#endif // QXCOMPRESSION_H

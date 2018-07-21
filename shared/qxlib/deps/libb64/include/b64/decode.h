// :mode=c++:
/*
decode.h - c++ wrapper for a base64 decoding algorithm

This is part of the libb64 project, and has been placed in the public domain.
For details, see http://sourceforge.net/projects/libb64
*/
#ifndef BASE64_DECODE_H
#define BASE64_DECODE_H

#include <iostream>

namespace base64
{
	extern "C"
	{
		#include "cdecode.h"
	}

	struct decoder
	{
		base64_decodestate _state;
		int _buffersize;

        decoder(int buffersize_in = (32 * 1024))
		: _buffersize(buffersize_in)
        {
            base64_init_decodestate(&_state);
        }

		int decode(char value_in)
		{
			return base64_decode_value(value_in);
		}

		int decode(const char* code_in, const int length_in, char* plaintext_out)
		{
			return base64_decode_block(code_in, length_in, plaintext_out, &_state);
		}

		void decode(std::istream& istream_in, std::ostream& ostream_in)
		{
			base64_init_decodestate(&_state);
			//
			const int N = _buffersize;
			char* code = new char[N];
			char* plaintext = new char[N];
			int codelength;
			int plainlength;

			do
			{
				istream_in.read((char*)code, N);
				codelength = istream_in.gcount();
				plainlength = decode(code, codelength, plaintext);
				ostream_in.write((const char*)plaintext, plainlength);
			}
			while (istream_in.good() && codelength > 0);
			//
			base64_init_decodestate(&_state);

			delete [] code;
			delete [] plaintext;
		}
	};

    std::string decode(const std::string& in)
    {
        std::string ret;
        if (in.size() > 0) {
            char *binary = new char[in.size()];
            base64::decoder d;
            int len = d.decode(in.c_str(), static_cast<int>(in.size()), binary);
            if (len > 0) {
                ret = std::string(binary, len);
            }
            delete [] binary;
        }
        return ret;
    }

} // namespace base64



#endif // BASE64_DECODE_H


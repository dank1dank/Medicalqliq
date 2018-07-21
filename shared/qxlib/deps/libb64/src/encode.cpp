// :mode=c++:
/*
encode.h - c++ wrapper for a base64 encoding algorithm

This is part of the libb64 project, and has been placed in the public domain.
For details, see http://sourceforge.net/projects/libb64
*/
#include "b64/encode.hpp"

namespace base64
{
        encoder::encoder(int buffersize_in)
		: _buffersize(buffersize_in)
        {
            base64_init_encodestate(&_state);
        }

		int encoder::encode(char value_in)
		{
			return base64_encode_value(value_in);
		}

		int encoder::encode(const char* code_in, const int length_in, char* plaintext_out)
		{
			return base64_encode_block(code_in, length_in, plaintext_out, &_state);
		}

		int encoder::encode_end(char* plaintext_out)
		{
			return base64_encode_blockend(plaintext_out, &_state);
		}

		void encoder::encode(std::istream& istream_in, std::ostream& ostream_in)
		{
			base64_init_encodestate(&_state);
			//
			const int N = _buffersize;
			char* plaintext = new char[N];
			char* code = new char[2*N];
			int plainlength;
			int codelength;

			do
			{
				istream_in.read(plaintext, N);
				plainlength = istream_in.gcount();
				//
				codelength = encode(plaintext, plainlength, code);
				ostream_in.write(code, codelength);
			}
			while (istream_in.good() && plainlength > 0);

			codelength = encode_end(code);
			ostream_in.write(code, codelength);
			//
			base64_init_encodestate(&_state);

			delete [] code;
			delete [] plaintext;
		}

    std::string encode(const std::string& in)
    {
        std::string ret;
        if (in.size() > 0) {
            char *out = new char[in.size() * 2];
            encoder e;
            int len = e.encode(in.c_str(), static_cast<int>(in.size()), out);
            if (len > 0) {
                ret = std::string(out, len);
            }
            delete [] out;
        }
        return ret;
    }

} // namespace base64

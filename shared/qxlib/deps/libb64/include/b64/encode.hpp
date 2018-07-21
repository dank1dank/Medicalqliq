// :mode=c++:
/*
encode.h - c++ wrapper for a base64 encoding algorithm

This is part of the libb64 project, and has been placed in the public domain.
For details, see http://sourceforge.net/projects/libb64
*/
#ifndef BASE64_ENCODE_H
#define BASE64_ENCODE_H

#include <iostream>

namespace base64
{
	extern "C" 
	{
		#include "cencode.h"
	}

	struct encoder
	{
		base64_encodestate _state;
		int _buffersize;

	        encoder(int buffersize_in = (32 * 1024));

		int encode(char value_in);

		int encode(const char* code_in, const int length_in, char* plaintext_out);

		int encode_end(char* plaintext_out);

		void encode(std::istream& istream_in, std::ostream& ostream_in);
	};

    std::string encode(const std::string& in);

} // namespace base64

#endif // BASE64_ENCODE_H


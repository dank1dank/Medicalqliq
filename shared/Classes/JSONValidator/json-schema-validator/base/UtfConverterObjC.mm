// Source:
// http://www.codeproject.com/KB/string/UtfConverter.aspx
//
// Modified by Adam Sowa on 8/9/2011
//
#import "UtfConverterObjC.h"

@implementation UtfConverterObjC

#if TARGET_RT_BIG_ENDIAN
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE);
#else
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE);
#endif

namespace UtfConverter
{

	std::wstring FromUtf8(const std::string& utf8string)
	{
        NSString *str = [[NSString alloc] initWithUTF8String:utf8string.c_str()];
        NSData *data = [str dataUsingEncoding:kEncoding_wchar_t];
        return std::wstring((wchar_t*)[data bytes], [data length] / sizeof(wchar_t));
	}

	std::string ToUtf8(const std::wstring& widestring)
	{
        char *wideData = (char *)widestring.data();
        unsigned long size = widestring.size() * sizeof(wchar_t);
        NSString *str = [[NSString alloc] initWithBytes:wideData length:size encoding:kEncoding_wchar_t];
        
        if (!str)
            str = [[NSString alloc] initWithFormat:@"%s", wideData];
        
        if (!str)
            str = @"";
        
        return std::string([str UTF8String]);
	}
}

@end

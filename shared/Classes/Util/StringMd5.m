//
//  StringMd5.m
//  CCiPhoneApp
//
//  Created by Admin on 03/05/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "StringMd5.h"


#import <CommonCrypto/CommonDigest.h>

@implementation NSString (md5)

+ (NSString *) md5:(NSString *)str
{
    if([str length] == 0)
    {
        return @"";
    }
	const char *cStr = [str UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];	
}

@end

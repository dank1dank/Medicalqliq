//
//  CryptoWrapper.m
//  qliq
//
//  Created by Paul Bar on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CryptoWrapper.h"
#import "Crypto2.hpp"
#import "String.hpp"

@implementation CryptoWrapper

-(NSString*) encryptFileAtPath:(NSString *)filePath andSaveToPath:(NSString*)outputFilePath outChecksum:(NSString **)outChecksum
{
    NSString *rez = nil;
    std::string keyString;
    std::string checksum;
    int encRet = core::Crypto::aesEncryptFile([filePath UTF8String], [outputFilePath UTF8String], &keyString, &checksum);
    if (encRet == 0) {
        rez = [[NSString stringWithCString:keyString.c_str() encoding:NSUTF8StringEncoding] copy];
        *outChecksum = [NSString stringWithUTF8String:checksum.c_str()];
    } else {
        *outChecksum = nil;
    }
    return [rez autorelease];
}

-(BOOL) decryptFileAthPath:(NSString *)filePath withKey:(NSString *)key andSaveToPath:(NSString *)outputFile
{
    BOOL rez = NO;
    std::string keyString = [key cStringUsingEncoding:NSUTF8StringEncoding];
    int decRet = core::Crypto::aesDecryptFile([filePath UTF8String], [outputFile UTF8String], keyString);
    if(decRet == 0)
    {
        rez = YES;
    }
    return rez;
}

@end

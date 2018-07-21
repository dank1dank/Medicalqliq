//
//  GenKeyPair.m
//  CCiPhoneApp
//
//  Created by Admin on 05/05/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "GenKeyPair.h"


@implementation GenKeyPair

static const UInt8 publicKeyIdentifier[] = "com.apple.ardensys.publickey\0";
static const UInt8 privateKeyIdentifier[] = "com.apple.ardensys.privatekey\0";

-(BOOL)GenerateKeyPair {
	OSStatus status = noErr;
	NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
	// 2
	
	NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
										length:strlen((const char *)publicKeyIdentifier)];
	NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
										 length:strlen((const char *)privateKeyIdentifier)];
	// 3
	
	SecKeyRef publicKey = NULL;
	SecKeyRef privateKey = NULL;                                // 4
	
	[keyPairAttr setObject:(id)kSecAttrKeyTypeRSA
					forKey:(id)kSecAttrKeyType]; // 5
	[keyPairAttr setObject:[NSNumber numberWithInt:1024]
					forKey:(id)kSecAttrKeySizeInBits]; // 6
	
	[privateKeyAttr setObject:[NSNumber numberWithBool:YES]
					   forKey:(id)kSecAttrIsPermanent]; // 7
	[privateKeyAttr setObject:privateTag
					   forKey:(id)kSecAttrApplicationTag]; // 8
	
	[publicKeyAttr setObject:[NSNumber numberWithBool:YES]
					  forKey:(id)kSecAttrIsPermanent]; // 9
	[publicKeyAttr setObject:publicTag
					  forKey:(id)kSecAttrApplicationTag]; // 10
	
	[keyPairAttr setObject:privateKeyAttr
					forKey:(id)kSecPrivateKeyAttrs]; // 11
	[keyPairAttr setObject:publicKeyAttr
					forKey:(id)kSecPublicKeyAttrs]; // 12
	
	status = SecKeyGeneratePair((CFDictionaryRef)keyPairAttr,
								&publicKey, &privateKey); // 13
	//    error handling...
	
	
	if(privateKeyAttr) [privateKeyAttr release];
	if(publicKeyAttr) [publicKeyAttr release];
	if(keyPairAttr) [keyPairAttr release];
	if(publicKey) CFRelease(publicKey);
	if(privateKey) CFRelease(privateKey); 
	
	if (status == 0) {
		return YES;
	}
	return NO;
}

-(NSData*)PublicKey {
	OSStatus status = noErr;
	NSData* data = NULL; 
	// 3
	
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
										length:strlen((const char *)publicKeyIdentifier)]; // 4
	
    NSMutableDictionary *queryPublicKey =
	[[NSMutableDictionary alloc] init]; // 5
	
    [queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    //[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
	[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
	// 6
	
    status = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&data);

	return data;
//	NSString *messageString = [NSString stringWithCString:CFDataGetBytePtr(data)];
	
//	NSString* newStr = [[NSString alloc] initWithData:data
//											 encoding:NSUnicodeStringEncoding];
//	NSString* aStr;
//	aStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
}


@end

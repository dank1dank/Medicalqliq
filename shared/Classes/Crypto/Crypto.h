//
//  Crypto.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+DirectoryLocations.h"
#import "QliqKeychainUtils.h"
#include <openssl/pem.h>
#include <openssl/conf.h>
#include <openssl/x509v3.h>
#ifndef OPENSSL_NO_ENGINE
#include <openssl/engine.h>
#import "Log.h"
#endif

typedef enum {
	PrivateKey,
	PublicKey
} KeyType;

@interface Crypto : NSObject {
	NSString *privateKeyPath;
	NSString *publicKeyPath;
	void *privateKey;
	void *publicKey;
	NSString *publicKeyString;
	NSString *privateKeyString;
    NSString *currentUserName;
}

@property (nonatomic, retain) NSString *publicKeyString;
@property (nonatomic, retain) NSString *privateKeyString;
@property (nonatomic, retain) NSString *currentUserName;

- (void) initForUser: (NSString *)userName : (NSString *)password __attribute__ ((deprecated));
- (BOOL) openForUser: (NSString *)userName withPassword: (NSString *)password;
- (BOOL) saveKeysForUser:(NSString *)userName : (NSString *)password privateKey :(NSString *)privKey publicKey :(NSString *)pubKey;
- (void) deleteKeysForUser : (NSString *)userName;
- (void) debugDumpKeysToFiles;
- (NSString *) decryptFromBase64: (NSString *) encryptedBase64 wasOk :(BOOL *)ok;

+ (id) instance;
+ (BOOL) isValidPublicKey: (NSString *)pubKeyString;
+ (BOOL) isValidPrivateKey: (NSString *)pubKeyString withPassword :(NSString *)password;
+ (NSString *) privateKeyRepassword: (NSString *)keyString oldPassword :(NSString *)oldPassword newPassword:(NSString *)newPassword;

+ (NSString *) decryptFromBase64: (NSString *) encryptedBase64 privateKey:(NSString *)privateKey password:(NSString *)password wasOk:(BOOL *)ok;

@end

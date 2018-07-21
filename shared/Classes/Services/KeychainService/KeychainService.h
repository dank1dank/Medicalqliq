//
//  KeychainService.h
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqKeychainUtils.h"

@interface KeychainService : NSObject
+ (KeychainService *) sharedService;

-(BOOL) pinAvailable;
-(NSString*) getPin;
-(BOOL) savePin:(NSString*)pin;
-(BOOL) clearPin;

-(NSString*)getUsername;
-(BOOL) saveUsername:(NSString*)username;
-(BOOL) clearUsername;

-(NSString*)getPassword;
-(BOOL)savePassword:(NSString*)password;
-(BOOL) clearPassword;

-(NSString*)getApiKey;
-(BOOL)saveApiKey:(NSString*)key;
-(BOOL) clearApiKey;

- (NSString *) getFileServerUrl;
- (BOOL) saveFileServerUrl:(NSString*)key;
- (BOOL) clearFileServerUrl;

-(BOOL) clearUserData;

-(NSString*) dbKeyForUserWithId:(NSString*)qliqId;

-(NSString*) stringToBase64:(NSString*)string;
-(NSString*) stringFromBase64:(NSString*)string;
-(NSString*) base64ToMd5:(NSString*)string;

-(NSString*)getLockState;
-(BOOL) saveLockState:(NSString*)lockState;

-(NSString*)getWipeState;
-(BOOL) saveWipeState:(NSString*)wipeState;

-(BOOL) isDeviceLockEnabled;
-(void) saveDeviceLockEnabled:(BOOL)enabled;

-(void) clearCache;
-(BOOL) isWhenUnlockedItemAccessible;

-(BOOL) pinAlreadyUsed:(NSString *)pin;
-(void) archivePin:(NSString *)pin listSize:(NSInteger)size;
-(BOOL) clearArchivedPins;
-(NSDate *) getPinLastSetTime;

@end

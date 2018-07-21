//
//  KeychainService.m
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeychainService.h"
#import "StringMd5.h"
#import "NSString+Base64.h"
#import "Helper.h"
#import "UIDevice+UUID.h"
#import "UIDevice+PasscodeStatus.h"
#import "Lockbox.h"

@interface KeychainService()
@property (nonatomic, strong) NSString *cachedPin;
@property (nonatomic, strong) NSString *cachedUsername;
@property (nonatomic, strong) NSString *cachedPassword;
@property (nonatomic, strong) NSString *cachedApiKey;
@property (nonatomic, strong) NSString *cachedFileServerUrl;
@property (nonatomic, strong) NSString *cachedLockState;
@property (nonatomic, strong) NSString *cachedWipeState;
@property (nonatomic, assign) NSInteger cachedDeviceLockEnabled;

-(NSString*) generateUniqueKey;
-(void) saveWhenUnlockedItem;
@end

@implementation KeychainService

@synthesize cachedPin, cachedUsername, cachedPassword, cachedApiKey, cachedFileServerUrl, cachedLockState, cachedWipeState, cachedDeviceLockEnabled;

-(id) init
{
    if (self = [super init]) {
        cachedDeviceLockEnabled = -1;
    }
    return self;
}

-(void) dealloc
{
    NSLog(@"KeychainService dealloced");
}

-(void) clearCache
{
    self.cachedPin = nil;
    self.cachedUsername = nil;
    self.cachedPassword = nil;
    self.cachedApiKey = nil;
    self.cachedFileServerUrl = nil;
    self.cachedLockState = nil;
    self.cachedWipeState = nil;
}

+ (KeychainService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[KeychainService alloc] init];
        [shared saveWhenUnlockedItem];
    });
    return shared;
}


-(BOOL) clearUserData
{
    BOOL success = YES;
    success &= [self clearPin];
    success &= [self clearUsername];
    success &= [self clearPassword];
    success &= [self clearApiKey];
    success &= [self clearFileServerUrl];
    success &= [self clearArchivedPins];
    
    DDLogSupport(@"User data cleared %@",success?@"successfully":@"with error");
    return success;
}

-(NSString*)dbKeyForUserWithId:(NSString *)qliqId
{
	NSString *dbKey=nil; 
#ifdef NO_DB_ENCRYPTION
    dbKey = nil;
#else
    NSString *keychainKey = [NSString stringWithFormat:@"%@%@", KS_DBKEY_PREFIX, qliqId];
    dbKey = [QliqKeychainUtils getItemForKey:keychainKey error:nil];
    
    if(dbKey == nil)
    {
        dbKey = [self generateUniqueKey];
        [QliqKeychainUtils storeItemForKey:keychainKey andValue:dbKey error:nil];
    }
    
    NSLog(@"dbKey = %@", dbKey);
#endif
    
    return dbKey;
}

#pragma mark - UserName -

-(NSString*) getUsername {

    if (self.cachedUsername == nil || [self.cachedUsername isEqualToString:@""]) {
        NSError *error = nil;
        self.cachedUsername = [[QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error] copy];
        DDLogSupport(@"getUsername (from keystore): '%@'", self.cachedUsername);
    }
    DDLogSupport(@"getUsername (cached): '%@'", self.cachedUsername);
    return self.cachedUsername;
}

-(BOOL) saveUsername:(NSString *)username
{
    BOOL success = NO;
    if ([username length] > 0) {
        NSError *error;
        success = [QliqKeychainUtils storeItemForKey:KS_KEY_USERNAME andValue:username error:&error];
        self.cachedUsername = username;
        DDLogSupport(@"saveUsername: '%@'", username);
    } else {
        DDLogError(@"saveUsername called with null username, not saving");
    }
    return success;
}

-(BOOL) clearUsername
{
    BOOL success = NO;
    NSError *error;
    success = [QliqKeychainUtils storeItemForKey:KS_KEY_USERNAME andValue:@"" error:&error];
    self.cachedUsername = @"";
    DDLogSupport(@"Clearing username, result: %d", success);
    return success;
}

#pragma mark - Password -

-(NSString*) getPassword {
    
    if (self.cachedPassword == nil || [self.cachedPassword isEqualToString:@""]) {
        NSError *error = nil;
        self.cachedPassword = [QliqKeychainUtils getItemForKey:KS_KEY_PASSWORD error:&error];
        DDLogSupport(@"getPassword (from keystore): [BLOCKED]");
    }
    DDLogSupport(@"getPassword (cached): [BLOCKED]");
    return self.cachedPassword;
}

-(BOOL) savePassword:(NSString *)password
{
    BOOL success = NO;
    if ([password length] > 0) {
        NSError *error;
        success = [QliqKeychainUtils storeItemForKey:KS_KEY_PASSWORD andValue:password error:&error];
        self.cachedPassword = password;
        DDLogSupport(@"savePassword: [BLOCKED]");
    } else {
        DDLogError(@"savePassword called with null password, not saving");
    }
    return success;
}

-(BOOL) clearPassword
{
    BOOL success = NO;
    NSError *error;
    success = [QliqKeychainUtils storeItemForKey:KS_KEY_PASSWORD andValue:@"" error:&error];
    self.cachedPassword = @"";
    DDLogSupport(@"Clearing password, result: %d", success);
    return success;
}

#pragma mark - API Key -

-(NSString*) getApiKey
{
    if (self.cachedApiKey == nil) {
        NSError *error = nil;
        self.cachedApiKey = [QliqKeychainUtils getItemForKey:KS_KEY_API_KEY error:&error];
        DDLogSupport(@"getApiKey (from keystore): [BLOCKED]");
    }
    DDLogSupport(@"getApiKey (cached): [BLOCKED]");
    return self.cachedApiKey;
}

-(BOOL) saveApiKey:(NSString *)value
{
    BOOL success = NO;
    if ([value length] > 0) {
        NSError *error;
        success = [QliqKeychainUtils storeItemForKey:KS_KEY_API_KEY andValue:value error:&error];
        self.cachedApiKey = value;
        DDLogSupport(@"saveApiKey: [BLOCKED]");
    } else {
        DDLogError(@"saveApiKey called with null value, not saving");
    }
    return success;
}

-(BOOL) clearApiKey
{
    BOOL success = NO;
    NSError *error;
    success = [QliqKeychainUtils storeItemForKey:KS_KEY_API_KEY andValue:@"" error:&error];
    self.cachedApiKey = @"";
    DDLogSupport(@"Clearing API key, result: %d", success);
    return success;
}

#pragma mark - File Server URL -

- (NSString *) getFileServerUrl
{
    if (self.cachedFileServerUrl == nil) {
        NSError *error = nil;
        self.cachedFileServerUrl = [QliqKeychainUtils getItemForKey:KS_KEY_FILE_SERVER_URL error:&error];
        DDLogSupport(@"getFileServerUrl (from keystore): %@", self.cachedFileServerUrl);
    }
    DDLogSupport(@"getFileServerUrl (cached): %@", self.cachedFileServerUrl);
    return self.cachedFileServerUrl;
}

- (BOOL) saveFileServerUrl:(NSString*)value
{
    BOOL success = NO;
    if ([value length] > 0) {
        NSError *error;
        success = [QliqKeychainUtils storeItemForKey:KS_KEY_FILE_SERVER_URL andValue:value error:&error];
        self.cachedFileServerUrl = value;
        DDLogSupport(@"saveFileServerUrl: %@", value);
    } else {
        DDLogError(@"saveFileServerUrl called with null value, not saving");
    }
    return success;
}

- (BOOL) clearFileServerUrl
{
    BOOL success = NO;
    NSError *error;
    success = [QliqKeychainUtils storeItemForKey:KS_KEY_FILE_SERVER_URL andValue:@"" error:&error];
    self.cachedFileServerUrl = @"";
    DDLogSupport(@"Clearing file server url key, result: %d", success);
    return success;
}

#pragma mark - Pin -

-(BOOL) pinAvailable
{
    NSString *pin = [self getPin];
    return ([pin length] > 0);
}

-(NSString*) getPin {
    
    if (self.cachedPin == nil || [self.cachedPin isEqualToString:@""]) {
        NSError *error = nil;
        self.cachedPin = [QliqKeychainUtils getItemForKey:KS_KEY_PIN error:&error];
        DDLogSupport(@"getPin (from keystore): [BLOCKED]");
    }
    DDLogSupport(@"getPin (cached): [BLOCKED]");
    return self.cachedPin;
}

-(BOOL) savePin:(NSString *)pin
{
    NSString *encodedPin = [self stringToBase64:pin];
    // NSLog(@"savePin: '%@'", pin);
    
    BOOL success = NO;
    if ([pin length] > 0) {
        NSError *error;
        success = [QliqKeychainUtils storeItemForKey:KS_KEY_PIN andValue:encodedPin error:&error];
        self.cachedPin = encodedPin;
        DDLogSupport(@"Saving PIN: [BLOCKED], result: %d", success);
        [self archivePin: pin listSize: [UserSessionService currentUserSession].userSettings.securitySettings.denyReusePinCount];
        DDLogSupport(@"Archived PIN: [BLOCKED], result: %d", success);
        [self updatePinLastSetTime];
    } else {
        DDLogError(@"savePin called with PIN: [BLOCKED], not saving");
    }
    
    return success;
}

-(BOOL) clearPin
{
    BOOL success = NO;
    NSError *error;
    success = [QliqKeychainUtils storeItemForKey:KS_KEY_PIN andValue:@"" error:&error];
    self.cachedPin = nil;
    DDLogSupport(@"Clearing PIN, result: %d", success);
    return success;
}

-(BOOL) pinAlreadyUsed: (NSString *)pin
{
    NSArray *archivedPins = [Lockbox arrayForKey:KS_KEY_ARCHIVED_PINS];
    
    if ([archivedPins containsObject:pin]) {
        return YES;
    }
    return NO;
}

-(void) archivePin:(NSString *)pin listSize:(NSInteger)size
{
    if (size < 1)
        return;
    
    NSMutableArray *archivedPins = [[Lockbox arrayForKey:KS_KEY_ARCHIVED_PINS] mutableCopy];
    
    if (archivedPins == NULL) archivedPins = [[NSMutableArray alloc] init];
    
    if ([archivedPins count] >= size)
    {
        // Remove the last one
        [archivedPins removeLastObject];
    }
    // Add the new one as first one.
    [archivedPins insertObject:pin atIndex:0];
    
    [Lockbox setArray:archivedPins forKey:KS_KEY_ARCHIVED_PINS];
}

-(void) updatePinLastSetTime
{
    [Lockbox setDate:[NSDate date] forKey:KS_KEY_PIN_LAST_SET_TIME];
}

- (NSDate *) getPinLastSetTime
{
    return [Lockbox dateForKey:KS_KEY_PIN_LAST_SET_TIME];
}

-(BOOL) clearArchivedPins
{
    return [Lockbox setArray:nil forKey:KS_KEY_ARCHIVED_PINS];
}

#pragma mark - State -

-(NSString*)getLockState;
{
    if (self.cachedLockState == nil) {
        NSError *error = nil;
        self.cachedLockState = [QliqKeychainUtils getItemForKey:KS_KEY_LOCKED error:&error];
    }
    return self.cachedLockState;
}

-(BOOL) saveLockState:(NSString*)lockState;
{
    NSError *error;
    self.cachedLockState = lockState;
    return [QliqKeychainUtils storeItemForKey:KS_KEY_LOCKED andValue:lockState error:&error];
}

-(NSString*)getWipeState;
{
    if (self.cachedWipeState == nil) {
        NSError *error = nil;
        self.cachedWipeState = [QliqKeychainUtils getItemForKey:KS_KEY_WIPED error:&error];
    }
    return self.cachedWipeState;
}

-(BOOL) saveWipeState:(NSString*)wipeState;
{
    NSError *error;
    self.cachedWipeState = wipeState;
    return [QliqKeychainUtils storeItemForKey:KS_KEY_WIPED andValue:wipeState error:&error];
}

#pragma mark - Private -

-(NSString*) generateUniqueKey
{
    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    return uuid;
}


-(NSString*) stringToBase64:(NSString*)string
{
	return [string base64EncodedString];
	//return [NSString md5:string];
}

-(NSString*) stringFromBase64:(NSString*)string
{
    return [string base64DecodedString];
}

-(NSString*) base64ToMd5:(NSString*)string
{
	NSString *decodedPswd = [string base64DecodedString];
	return [NSString md5:decodedPswd];
	
}

-(BOOL) isDeviceLockEnabled
{
    if ([[UIDevice currentDevice] passcodeStatusSupported])
        return [[UIDevice currentDevice] passcodeStatus] == LNPasscodeStatusEnabled;
    else
        return self.isDeviceLockEnabledIOS8minus;
}

-(BOOL) isDeviceLockEnabledIOS8minus
{
    if (self.cachedDeviceLockEnabled == -1) {
        NSError *error = nil;
        self.cachedDeviceLockEnabled = [[QliqKeychainUtils getItemForKey:KS_KEY_DEVICE_LOCK_ENABLED error:&error] integerValue];
    }
    return self.cachedDeviceLockEnabled == 1;
}

-(void) saveDeviceLockEnabled:(BOOL)enabled
{
	NSError *error;
    [QliqKeychainUtils storeItemForKey:KS_KEY_DEVICE_LOCK_ENABLED andValue:[NSString stringWithFormat:@"%d", (enabled ? 1 : 0)] error:&error];
    self.cachedDeviceLockEnabled = enabled;
}

-(void) saveWhenUnlockedItem
{
    NSError *error = nil;
    [QliqKeychainUtils storeItemForKey:KS_KEY_WHEN_UNLOCKED_ITEM andValue:@"UNLOCKED" error:&error withAttrAccessible:kSecAttrAccessibleWhenUnlockedThisDeviceOnly];
    
}

-(BOOL) isWhenUnlockedItemAccessible
{
    BOOL unLocked = NO;
    NSError *error = nil;
    NSString *value = [QliqKeychainUtils getItemForKey:KS_KEY_WHEN_UNLOCKED_ITEM error:&error];
    if ([value isEqualToString:@"UNLOCKED"])
        unLocked = YES;
    return unLocked;
}


@end

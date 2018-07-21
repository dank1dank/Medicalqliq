//
//  QliqStorage.m
//  qliq
//
//  Created by Valerii Lider on 01/02/16.
//
//

#import "QliqStorage.h"

@implementation QliqStorage

static QliqStorage *instance = nil;

#pragma mark - Life Cycle -

+ (QliqStorage *)sharedInstance
{
    @synchronized(self) {
        if (!instance) {
            DDLogSupport(@"instance is nil. Intializing QliqStorage");
            // Since instance is set inside initializer, not doing any assignment here.
            instance = [[QliqStorage alloc] init];
        }
        return instance;
    }
}

#pragma mark - Private -

- (void)put:(id)value forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

- (id)getForKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    id value = [userDefaults objectForKey:key];
    return value;
}

- (void)putBool:(BOOL)value forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:value forKey:key];
    [userDefaults synchronize];
}

- (BOOL)getBoolForKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:key];
}

- (void)putNumber:(NSNumber *)value forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

- (NSNumber *)getNumberForKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

#pragma mark - Storage -

//------------------------------------------------------------
#pragma mark Devices Values
//------------------------------------------------------------

#define kKeyDeviceKey @"DeviceKey"
#define kKeyVoipDeviceKey @"VoipDeviceKey"

- (void)setDeviceToken:(NSString *)deviceToken {
    [self put:deviceToken forKey:kKeyDeviceKey];
}

- (NSString *)deviceToken {
    return [self getForKey:kKeyDeviceKey];
}

- (void)setVoipDeviceToken:(NSString *)deviceToken {
    [self put:deviceToken forKey:kKeyVoipDeviceKey];
}

- (NSString *)voipDeviceToken {
    return [self getForKey:kKeyVoipDeviceKey];
}

//------------------------------------------------------------
#pragma mark Application States
//------------------------------------------------------------

#define kKeyDontShowAlertsOffPopup @"dontShowAlertsOffPopup"

- (void)setDontShowAlertsOffPopup:(NSNumber *)dontShowAlertsOffPopup {
    [self putNumber:dontShowAlertsOffPopup forKey:kKeyDontShowAlertsOffPopup];
}

- (NSNumber *)dontShowAlertsOffPopup {
    return [self getNumberForKey:kKeyDontShowAlertsOffPopup];
}

//------------------------------------------------------------
#pragma mark Idle Lock Values
//------------------------------------------------------------

#define kKeyLastUserTouchTime @"LastUserTouchTime"

- (void)setLastUserTouchTime:(NSDate *)lastUserTouchTime {
    [self put:lastUserTouchTime forKey:kKeyLastUserTouchTime];
}

- (NSDate *)lastUserTouchTime {
    return [self getForKey:kKeyLastUserTouchTime];
}

#define kKeyAppIdleLockedState @"appIdleLockedState"

- (void)setAppIdleLockedState:(BOOL)appIdleLockedState {
    [self put:[NSNumber numberWithBool:appIdleLockedState] forKey:kKeyAppIdleLockedState];
}

- (BOOL)appIdleLockedState {
    return [[self getNumberForKey:kKeyAppIdleLockedState] boolValue];
}


//------------------------------------------------------------
#pragma mark User Info Values
//------------------------------------------------------------

#define kKeyUserLoggedOut @"UserLoggedOut"

- (void)setUserLoggedOut:(BOOL)value {
    [self putBool:value forKey:kKeyUserLoggedOut];
}

// Should return YES if user was never logged in (first run) or was explicitly logged out
- (BOOL)userLoggedOut {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *value = [userDefaults objectForKey:kKeyUserLoggedOut];
    if (value == nil) {
        return YES;
    } else {
        return [value boolValue];
    }
}

//------------------------------------------------------------
#pragma mark Expire Values
//------------------------------------------------------------

#define kDeleteMediaUponExpiryKey @"DeleteMediaUponExpiryKey"

- (void)setDeleteMediaUponExpiryKey:(NSNumber *)deleteMediaUponExpiryKey {
    [self putNumber:deleteMediaUponExpiryKey forKey:kDeleteMediaUponExpiryKey];
}

- (NSNumber *)deleteMediaUponExpiryKey {
    return [self getNumberForKey:kDeleteMediaUponExpiryKey];
}

//------------------------------------------------------------
#pragma mark Login Cedentials
//------------------------------------------------------------
#define kLoginCredentialsWasChanged @"LoginCredentialsWasChanged"

- (void)setWasLoginCredentintialsChanged:(BOOL)wasLoginCredentintialsChanged {
    [self putBool:wasLoginCredentintialsChanged forKey:kLoginCredentialsWasChanged];
}

- (BOOL)wasLoginCredentintialsChanged {
    return [self getBoolForKey:kLoginCredentialsWasChanged];
}

#define kFailedToDecryptPushPayload @"FailedToDecryptPushPayload"

- (void)setFailedToDecryptPushPayload:(BOOL)failedToDecryptPushPayload {
    [self putBool:failedToDecryptPushPayload forKey:kFailedToDecryptPushPayload];
}

- (BOOL)failedToDecryptPushPayload {
    return [self getBoolForKey:kFailedToDecryptPushPayload];
}

//------------------------------------------------------------
#pragma mark App Info Values
//------------------------------------------------------------

#define kKeyAppWasCrashed @"WasCrashed"
#define kKeyAppStackTrace @"StackTrace"
#define kKeyAppHasWarning @"warning"
#define kKeyDateWarning @"dateWarning"
#define kKeyDateCrash @"dateCrash"
#define kKeyBufferedCrashes @"bufferedCrashes"

- (void)storeAppCrashEventWithStackTrace:(NSString *)stackTrace {
    
    /* Store was crashed event */
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@YES forKey:kKeyAppWasCrashed];
    
    NSMutableArray *bufferedCrashes = [[self bufferedAppCrashes] mutableCopy];
    if (!bufferedCrashes) {
        bufferedCrashes = [[NSMutableArray alloc] init];
    }
    
    NSDictionary *crashDict = [self crashInfoDictionaryWithStackTrace:stackTrace];
    [bufferedCrashes addObject:crashDict];
    [userDefaults setObject:bufferedCrashes forKey:kKeyBufferedCrashes];
    [userDefaults synchronize];
}

- (void)restoreAppCrashEvent {
    
    /* Restore was crashed event */
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@NO forKey:kKeyAppWasCrashed];
    [userDefaults removeObjectForKey:kKeyBufferedCrashes];
    [userDefaults synchronize];
}

- (void)storeAppMemoryWarningEvent {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@YES forKey:kKeyAppHasWarning];
    [userDefaults setObject:[NSDate date] forKey:kKeyDateWarning];
    [userDefaults synchronize];
}

- (void)restoreAppMemoryWarning {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kKeyAppHasWarning];
    [userDefaults removeObjectForKey:kKeyDateWarning];
    [userDefaults synchronize];
}

- (BOOL)appWasCrashed {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kKeyAppWasCrashed] boolValue];
};

- (NSString *)appStackTraceForCrashInfoDictionary:(NSDictionary *)crashInfoDict {
    return [crashInfoDict valueForKey:kKeyAppStackTrace];
}

- (NSDate *)dateInLastAppCrash:(BOOL)isLastCrash {
    
    NSDate *appCrashDate = nil;
    
    NSMutableArray *bufferedCrashes = [[self bufferedAppCrashes] mutableCopy];
    if (bufferedCrashes) {
        NSDictionary *crashDict = isLastCrash ? [bufferedCrashes lastObject] : [bufferedCrashes firstObject];
        if (crashDict) {
            appCrashDate = [crashDict valueForKey:kKeyDateCrash];
        }
    }
    return appCrashDate;
}

- (NSArray *)bufferedAppCrashes {
    return [self getForKey:kKeyBufferedCrashes];
}

- (NSMutableDictionary *)crashInfoDictionaryWithStackTrace:(NSString *)stackTrace {
    
    NSMutableDictionary *crashInfo = [[NSMutableDictionary alloc] init];
    [crashInfo setValue:[NSString stringWithFormat:@"Stack Trace: %@", stackTrace] forKey:kKeyAppStackTrace];
    [crashInfo setValue:@YES forKey:kKeyAppHasWarning];
    NSDate *date = [NSDate date];
    [crashInfo setValue:date forKey:kKeyDateWarning];
    [crashInfo setValue:date forKey:kKeyDateCrash];
    return crashInfo;
}

@end

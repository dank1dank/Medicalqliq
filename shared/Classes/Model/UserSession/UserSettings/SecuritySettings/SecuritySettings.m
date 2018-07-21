//
//  SecuritySettings.m
//  qliq
//
//  Created by Paul Bar on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SecuritySettings.h"

#import "QliqJsonSchemaHeader.h"

static NSString *key_MaxInactivityTime  = @"key_maxInactivityTime";
static NSString *key_InactivityLock     = @"key_InactivityLock";
static NSString *key_RememberPassword   = @"key_RememberPassword";
static NSString *key_EnforcePinLogin    = @"key_EnforcePinLogin";
static NSString *key_KeepMessageFor     = @"key_KeepMessagFor";
static NSString *key_PinSetTime         = @"key_PinSetTime";
static NSString *key_ExpirePinAfter     = @"key_ExpirePinAfter";
static NSString *key_DenyReusePinCount  = @"key_DenyReusePinCount";
static NSString *key_IsEnabledTouchId   = @"key_IsEnabledTouchId";
static NSString *key_PersonalContacts   = @"key_PersonalContacts";
static NSString *key_BlockScreenshots   = @"key_BlockScreenshots";
static NSString *key_BlockCallerId      = @"key_BlockCallerId";
static NSString *key_BlockCameraRoll    = @"key_BlockCameraRoll";

@implementation SecuritySettings

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if(self) {
        self.blockScreenshots   = [aDecoder decodeBoolForKey:key_BlockScreenshots];
        self.blockCallerId      = [aDecoder containsValueForKey:key_IsEnabledTouchId] ? [aDecoder decodeBoolForKey:key_BlockCallerId] : YES;
        self.blockCameraRoll    = [aDecoder containsValueForKey:key_IsEnabledTouchId] ? [aDecoder decodeBoolForKey:key_BlockCameraRoll] : NO;
        self.rememberPassword   = [aDecoder decodeBoolForKey:key_RememberPassword];
        self.inactivityLock     = [aDecoder decodeBoolForKey:key_InactivityLock];
        self.isEnabledTouchId   = [aDecoder containsValueForKey:key_IsEnabledTouchId] ? [aDecoder decodeBoolForKey:key_IsEnabledTouchId] : NO;
        self.personalContacts   = [aDecoder containsValueForKey:key_PersonalContacts] ? [aDecoder decodeBoolForKey:key_PersonalContacts] : YES;
        self.enforcePinLogin    = [aDecoder containsValueForKey:key_EnforcePinLogin]  ? [aDecoder decodeBoolForKey:key_EnforcePinLogin]  : NO;
        self.denyReusePinCount  = [aDecoder decodeIntForKey:key_DenyReusePinCount];
        self.maxInactivityTime  = [aDecoder decodeDoubleForKey:key_MaxInactivityTime];
        self.keepMessageFor     = [aDecoder decodeDoubleForKey:key_KeepMessageFor];
        self.expirePinAfter     = [aDecoder decodeDoubleForKey:key_ExpirePinAfter];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.blockScreenshots        forKey:key_BlockScreenshots];
    [aCoder encodeBool:self.blockCallerId           forKey:key_BlockCallerId];
    [aCoder encodeBool:self.blockCameraRoll         forKey:key_BlockCameraRoll];
    [aCoder encodeBool:self.rememberPassword        forKey:key_RememberPassword];
    [aCoder encodeBool:self.inactivityLock      	forKey:key_InactivityLock];
    [aCoder encodeBool:self.enforcePinLogin         forKey:key_EnforcePinLogin];
    [aCoder encodeBool:self.isEnabledTouchId        forKey:key_IsEnabledTouchId];
    [aCoder encodeBool:self.personalContacts        forKey:key_PersonalContacts];
    [aCoder encodeInteger:self.denyReusePinCount    forKey:key_DenyReusePinCount];
    [aCoder encodeDouble:self.maxInactivityTime     forKey:key_MaxInactivityTime];
    [aCoder encodeDouble:self.keepMessageFor        forKey:key_KeepMessageFor];
    [aCoder encodeDouble:self.expirePinAfter        forKey:key_ExpirePinAfter];
}

#pragma mark - Public

+ (SecuritySettings *)securitySettingsWithDictionary:(NSDictionary *)dict
{
    SecuritySettings *securitySettings = [[SecuritySettings alloc] init];
    
    // maxInactivityTime
    {
        securitySettings.maxInactivityTime = ([[dict objectForKey:INACTIVITY_TIME] intValue]) * 60;
    }
    
    // inactivityLock
    {
        securitySettings.inactivityLock = [[dict objectForKey:INACTIVITY_LOCK] boolValue];
    }
    
    // rememberPassword
    {
        // Check if the key exists to make the app work with old server also.
        id rememberPasswordValue = [dict objectForKey:REMEMBER_PASSWORD];
        if ([rememberPasswordValue isKindOfClass:[NSNumber class]]) {
            securitySettings.rememberPassword = [rememberPasswordValue boolValue];
        }
    }
    
    // inactivityLock
    {
        // Krishna wants to replace inactivity_lock with remember_password
        securitySettings.inactivityLock = !securitySettings.rememberPassword;
    }
    
    // personalContacts
    {
        id pesonalContactsValue = [dict objectForKey:PERSONAL_CONTACTS];
        securitySettings.personalContacts = pesonalContactsValue ? [pesonalContactsValue boolValue] : true;
    }
    
    // keepMessageFor
    {
        securitySettings.keepMessageFor = [[dict objectForKey:KEEP_MESSAGES_FOR] intValue] * [SecuritySettings getSecondsPerDay];
    }
    
    // enforcePinLogin
    {
        securitySettings.enforcePinLogin = [[dict objectForKey:ENFORCE_PIN] boolValue];
    }
    
    // expirePinAfter
    {
        // Krishna - 8/14/2014
        // PIN Expiry feature
        NSNumber *expirePinAfterNumber = [dict objectForKey:EXPIRE_PIN_AFTER];
        int expirePinAfter = expirePinAfterNumber ? [expirePinAfterNumber intValue] : 90;
        securitySettings.expirePinAfter = expirePinAfter * [SecuritySettings getSecondsPerDay];
    }
    
    // Block Screenshots
    {
        id blockScreenshotsValue = [dict objectForKey:BLOCK_SCREENSHOTS];
        if ([blockScreenshotsValue isKindOfClass:[NSNumber class]]) {
            securitySettings.blockScreenshots = [blockScreenshotsValue boolValue];
        }
    }
    
    // Block Caller Id
    {
        id blockCallerIdValue = [dict objectForKey:BLOCK_CALLERID];
        if (blockCallerIdValue && [blockCallerIdValue isKindOfClass:[NSNumber class]]) {
            securitySettings.blockCallerId = [blockCallerIdValue boolValue];
        } else {
            securitySettings.blockCallerId = NO;
        }
    }
    
    // Block Camera Roll
    {
        id blockCameraRollValue = [dict objectForKey:BLOCK_CAMERA_ROLL];
        if (blockCameraRollValue && [blockCameraRollValue isKindOfClass:[NSNumber class]]) {
            securitySettings.blockCameraRoll = [blockCameraRollValue boolValue];
        } else {
            securitySettings.blockCameraRoll = NO;
        }
    }
    
    // denyReusePinCount
    {
        NSNumber *valueNumber = [dict objectForKey:DENY_REUSE_PIN_COUNT];
        int value = valueNumber ? [valueNumber intValue] : 1;
        securitySettings.denyReusePinCount = value;
    }
    
    {
        [[NSUserDefaults standardUserDefaults] setDouble:[[dict objectForKey:LOCK_OUT_TIME] doubleValue] * 60 forKey:@"login_failed_lock_timeinterval"];
        [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:LOGIN_FAILURE_ATTEMPTS] integerValue] forKey:@"login_failed_max_attemps"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return securitySettings;
}
    
#pragma mark - Private 
    
+ (NSInteger)getSecondsPerDay {
    NSInteger hoursInDay = 24;
    NSInteger minutesInHour = 60;
    NSInteger secondsInMinute = 60;
    return secondsInMinute * minutesInHour * hoursInDay;
}

@end

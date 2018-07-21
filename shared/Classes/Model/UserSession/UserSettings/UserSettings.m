//
//  UserSettings.m
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserSettings.h"

#import "UserSessionService.h"
#import "UserSettingsService.h"

#define kShowAvatarsInContactsListKey      @"key_showAvatarsInContactsList"
#define kIsBatterySavingModeEnabledKey     @"key_isBatterySavingModeEnabled"
#define kIsTouchIdEnabledKey               @"key_isTouchIdEnabled"
#define kCurrentAppVersionFromWebServerKey @"key_currentAppVersionFromWebServer"
#define kLastUpgradeAlertDateKey           @"key_lastUpgradeAlertDate"
#define kSecuritySettingsKey               @"key_securitySettings"
#define kSoundSettingsKey                  @"kSoundSettingsKey"
#define kPresenceSettingsKey               @"kPresenceSettingsKey"
#define kEscalatedSettingsKey              @"kEscalatedSettingsKey"
#define kUserFeaturesInfo                  @"kUserFeaturesInfo"
#define kUsersCallBackNumber               @"kUsersCallBackNumber"

@implementation UserSettings

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if(self) {
        self.showAvatarsInContactsList      = [aDecoder decodeBoolForKey:kShowAvatarsInContactsListKey];
        self.isBatterySavingModeEnabled     = [aDecoder decodeBoolForKey:kIsBatterySavingModeEnabledKey];
        self.isTouchIdEnabled               = [aDecoder decodeBoolForKey:kIsTouchIdEnabledKey];
        self.currentAppVersionFromWebServer = [aDecoder decodeIntegerForKey:kCurrentAppVersionFromWebServerKey];
        self.lastUpgradeAlertDate           = [aDecoder decodeObjectForKey:kLastUpgradeAlertDateKey];
        self.usersCallbackNumber            = [aDecoder decodeObjectForKey:kUsersCallBackNumber];
        
        self.securitySettings = [aDecoder decodeObjectForKey:kSecuritySettingsKey];

        if ([aDecoder containsValueForKey:kSoundSettingsKey]) {
            self.soundSettings = [aDecoder decodeObjectForKey:kSoundSettingsKey];
        }
        if ([aDecoder containsValueForKey:kPresenceSettingsKey]) {
            self.presenceSettings = [aDecoder decodeObjectForKey:kPresenceSettingsKey];
        }
        if ([aDecoder containsValueForKey:kEscalatedSettingsKey]) {
            self.escalatedCallnotifyInfo = [aDecoder decodeObjectForKey:kEscalatedSettingsKey];
        }
        if ([aDecoder containsValueForKey:kUserFeaturesInfo]) {
            self.userFeatureInfo = [aDecoder decodeObjectForKey:kUserFeaturesInfo];
        }
        
        if (!self.soundSettings) {
            self.soundSettings = [[SoundSettings alloc] init];
        }
        
        if (!self.presenceSettings){
            self.presenceSettings = [[PresenceSettings alloc] init];
        }
        
        if (!self.escalatedCallnotifyInfo) {
            self.escalatedCallnotifyInfo = [[EscalatedCallnotifyInfo alloc] init];
        }
        
        if (!self.userFeatureInfo) {
            self.userFeatureInfo = [[UserFeatureInfo alloc] init];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.showAvatarsInContactsList           forKey:kShowAvatarsInContactsListKey];
    [aCoder encodeBool:self.isBatterySavingModeEnabled          forKey:kIsBatterySavingModeEnabledKey];
    [aCoder encodeBool:self.isTouchIdEnabled                    forKey:kIsTouchIdEnabledKey];
    [aCoder encodeInteger:self.currentAppVersionFromWebServer   forKey:kCurrentAppVersionFromWebServerKey];
    [aCoder encodeObject:self.lastUpgradeAlertDate              forKey:kLastUpgradeAlertDateKey];
    [aCoder encodeObject:self.securitySettings                  forKey:kSecuritySettingsKey];
    [aCoder encodeObject:self.soundSettings                     forKey:kSoundSettingsKey];
    [aCoder encodeObject:self.presenceSettings                  forKey:kPresenceSettingsKey];
    [aCoder encodeObject:self.escalatedCallnotifyInfo           forKey:kEscalatedSettingsKey];
    [aCoder encodeObject:self.userFeatureInfo                   forKey:kUserFeaturesInfo];
    [aCoder encodeObject:self.usersCallbackNumber               forKey:kUsersCallBackNumber];
}

#pragma mark - Public

+ (UserSettings *)defaultSettings {
    UserSettings *defaultSettings = [[UserSettings alloc] init];
    defaultSettings.soundSettings               = [[SoundSettings alloc] init];
    defaultSettings.securitySettings            = [[SecuritySettings alloc] init];
    defaultSettings.presenceSettings            = [[PresenceSettings alloc] init];
    defaultSettings.escalatedCallnotifyInfo     = [[EscalatedCallnotifyInfo alloc] init];
    defaultSettings.userFeatureInfo             = [[UserFeatureInfo alloc] init];
    defaultSettings.showAvatarsInContactsList   = YES;
    defaultSettings.isBatterySavingModeEnabled  = NO;
    defaultSettings.isTouchIdEnabled            = YES;
    defaultSettings.lastUpgradeAlertDate        = nil;
    defaultSettings.currentAppVersionFromWebServer = 0;
    defaultSettings.usersCallbackNumber = nil;
    return defaultSettings;
}

- (void)write {
    UserSettingsService * service = [[UserSettingsService alloc] init];
    [service saveUserSettings:self forUser:[UserSessionService currentUserSession].user];
}

@end

//
//  UserSettingsService.m
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserSettingsService.h"
#import "QliqUser.h"
#import "QliqJsonSchemaHeader.h"

static NSString *key_userSettings = @"key_userSettings";

@interface UserSettingsService()

@end

@implementation UserSettingsService

+ (void )parseAndUpdateFeatureInfo:(NSDictionary *)featureInfoDict forUserSettings:(UserSettings *)userSettings {
    
    userSettings.userFeatureInfo.isEMRIntegated           = [featureInfoDict[EMR_INTEGRATION]       boolValue];
    userSettings.userFeatureInfo.isFAXIntegated           = [featureInfoDict[FAX_INTEGRATION]       boolValue];
    userSettings.userFeatureInfo.isOnCallGroupsAllowed    = [featureInfoDict[ONCALL_GROUPS]         boolValue];
    userSettings.userFeatureInfo.isKiteworksIntegrated    = [featureInfoDict[KITEWORKS_INTEGRATION] boolValue];
    userSettings.userFeatureInfo.isCareChannelsIntegrated = [featureInfoDict[CARE_CHANNELS]         boolValue];
    userSettings.userFeatureInfo.isFillAndSignAvailable   = [featureInfoDict[FILL_AND_SIGN]         boolValue];
    return;
}


-(id) init
{
    self = [super init];
    if(self)
    {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (UserSettings *) getSettingsForUser:(QliqUser *)user {
    UserSettings * settings = nil;
    
    if ([[user qliqId] length] > 0) {
        NSString * key = [NSString stringWithFormat:@"%@-%@", [user qliqId], key_userSettings];
        NSData * archivedSettings = [userDefaults objectForKey:key];
        
        /* try to load settings */
        if (key && archivedSettings) {
            @try {
                settings = [NSKeyedUnarchiver unarchiveObjectWithData:archivedSettings];
            }
            @catch (NSException *exception) {
                DDLogSupport(@"Error during loading settings: %@ %@. Using default settings.",[exception name],[exception reason]);
            }
        }
    }
    
    /* if not loaded - use default */
    if (!settings) {
        settings = [UserSettings defaultSettings];
        [self saveUserSettings:settings forUser:user];
    }
    
    return settings;
}

-(void) saveUserSettings:(UserSettings *)userSettings forUser:(QliqUser *)user
{
    NSData *archivedSettings = [NSKeyedArchiver archivedDataWithRootObject:userSettings];
    NSString *key = [NSString stringWithFormat:@"%@-%@",[user qliqId], key_userSettings];
    [userDefaults setObject:archivedSettings forKey:key];
    
    [userDefaults synchronize];
}

@end

//
//  UserSettings.h
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SoundSettings.h"
#import "SecuritySettings.h"
#import "PresenceSettings.h"
#import "EscalatedCallnotifyInfo.h"
#import "UserFeatureInfo.h"

@interface UserSettings : NSObject <NSCoding>

@property (nonatomic, unsafe_unretained) BOOL showAvatarsInContactsList;
@property (nonatomic, unsafe_unretained) BOOL isBatterySavingModeEnabled;
@property (nonatomic, unsafe_unretained) BOOL isTouchIdEnabled;
@property (nonatomic, unsafe_unretained) NSInteger currentAppVersionFromWebServer;

@property (nonatomic, strong) NSString *usersCallbackNumber;

@property (nonatomic, strong) NSDate *lastUpgradeAlertDate;

@property (nonatomic, strong) SecuritySettings * securitySettings;
@property (nonatomic, strong) SoundSettings * soundSettings;
@property (nonatomic, strong) PresenceSettings * presenceSettings;
@property (nonatomic, strong) EscalatedCallnotifyInfo *escalatedCallnotifyInfo;
@property (nonatomic, strong) UserFeatureInfo *userFeatureInfo;

+ (UserSettings *)defaultSettings;

- (void)write;

@end

//
//  UserSettingsService.h
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserSettings.h"

@class QliqUser;

@interface UserSettingsService : NSObject
{
    NSUserDefaults *userDefaults;
}

+ (void )parseAndUpdateFeatureInfo:(NSDictionary *)featureInfoDict forUserSettings:(UserSettings *)userSettings;

-(UserSettings*) getSettingsForUser:(QliqUser*)user;
-(void) saveUserSettings:(UserSettings*)userSettings forUser:(QliqUser*)user;

@end

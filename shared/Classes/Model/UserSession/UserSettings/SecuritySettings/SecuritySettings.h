//
//  SecuritySettings.h
//  qliq
//
//  Created by Paul Bar on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SecuritySettings : NSObject <NSCoding>

@property (nonatomic, assign) BOOL inactivityLock;
@property (nonatomic, assign) BOOL enforcePinLogin;
@property (nonatomic, assign) BOOL rememberPassword;
@property (nonatomic, assign) BOOL personalContacts;
@property (nonatomic, assign) BOOL isEnabledTouchId;
@property (nonatomic, assign) BOOL blockScreenshots;
@property (nonatomic, assign) BOOL blockCallerId;
@property (nonatomic, assign) BOOL blockCameraRoll;

@property (nonatomic, assign) NSInteger denyReusePinCount;

@property (nonatomic, assign) NSTimeInterval maxInactivityTime;
@property (nonatomic, assign) NSTimeInterval keepMessageFor;
@property (nonatomic, assign) NSTimeInterval expirePinAfter;

+ (SecuritySettings *)securitySettingsWithDictionary:(NSDictionary *)dict;

@end

//
//  LoginService.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "LoginService.h"

#import "AppDelegate.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "Helper.h"
#import "DeviceInfo.h"
#import "UserSessionService.h"
#import "KeychainService.h"
#import "UIDevice-Hardware.h"
#import "UIDevice+UUID.h"
#import "NSDate+Helper.h"

@implementation LoginService

@synthesize username, password;

- (id)initWithUsername:(NSString *)_username andPassword:(NSString *)_password {
    self = [super init];
    if (self) {
        self.username = _username;
        self.password = _password;
    }
    return self;
}

- (NSString *)serviceName {
    return @"services/login";
}

- (Schema)requestSchema {
    return LoginRequestSchema;
}

- (Schema)responseSchema {
    return LoginResponseSchema;
}

- (NSDictionary *)requestJson {
   
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    NSString *deviceKey = [QliqStorage sharedInstance].deviceToken;
    NSString *voipDeviceKey = [QliqStorage sharedInstance].voipDeviceToken;
    
    NSNumber *deviceMuted = @([DeviceInfo sharedInfo].isMuted);
    NSString *deviceVolume = [NSString stringWithFormat:@"%d%%", (int)(100.f * [DeviceInfo sharedInfo].outputVolume)];
    
    deviceName = [deviceName stringByAppendingFormat:@" (%@)", [[UIDevice currentDevice] platformString]];
    
    NSNumber *timestamp = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
    
 
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    
    //Extract UTC Time OFFSET
    [formatter setDateFormat:@"ZZZ"];
    
    //Get the string date
    NSString *timezone_utc_offset = [formatter stringFromDate:date];
    
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];

    NSString *pass = password;
    if (!pass) {
        pass = @"";
    }
    
    NSMutableDictionary * dataDict = [@{PASSWORD            : pass,
                                        USERNAME            : username,
                                        TIMESTAMP           : timestamp,
                                        APP_NAME            : @"qliq_connect",
                                        APP_VERSION         : [AppDelegate currentBuildVersion],
                                        APP_PLATFORM        : @"iOS",
                                        DEVICE_NAME         : deviceName,
                                        TIMEZONE_UTC_OFFSET : timezone_utc_offset,
                                        TIMEZONE            : currentTimeZone.name,
                                        OS_VERSION          : osVersion,
                                        DEVICE_UUID         : deviceUUID,
                                        DEVICE_MUTED        : deviceMuted,
                                        DEVICE_RINGER_VOLUME: deviceVolume} mutableCopy];
    
    // On the simulator 'deviceKey' is nil
    if (deviceKey.length > 0) {
        dataDict[DEVICE_KEY] = deviceKey;
    }
    
    if (voipDeviceKey.length > 0) {
        dataDict[VOIP_DEVICE_KEY] = voipDeviceKey;
    }
    
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    if (userSettings.isBatterySavingModeEnabled) {
        dataDict[BATTERY_SAVE] = @YES;
    }
    
    return @{ MESSAGE : @{ DATA : dataDict } };
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, dataDict, nil);
    }
}


@end

//
//  SetDeviceStatus.m
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "SetDeviceStatus.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "KeychainService.h"
#import "UIDevice+UUID.h"
#import "GetDeviceStatus.h"
#import "ReceivedPushNotificationDBService.h"

@interface SetDeviceStatus ()

-(BOOL) processResponseString:(NSString *)responseString onCompletion:(void(^)(BOOL success, NSError * error)) block;
-(BOOL) isJsonResponseValid:(NSString *)responseString;

@end

@implementation SetDeviceStatus

+ (SetDeviceStatus *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[SetDeviceStatus alloc] init];
        
    });
    return shared;
}

+ (void)setDeviceStatusCurrentAppStateWithCompletion:(void(^)(BOOL success, NSError * error)) block
{
    NSString *lock = [[KeychainService sharedService] getLockState];
    NSString *wipe = [[KeychainService sharedService] getWipeState];
    
    if (lock.length == 0) {
        lock = GetDeviceStatusUnlocked;
    }
    if (wipe.length == 0) {
        wipe = GetDeviceStatusNone;
    }
    
    [[SetDeviceStatus sharedService] setDeviceStatusLock:lock wipeState:wipe onCompletion:block];
}

- (void)setDeviceStatusLock:(NSString*)lockState wipeState:(NSString*)wipeState onCompletion:(void(^)(BOOL success, NSError * error)) block {
    
    NSString *username, *password, *uuid;
    //UserSession *currentSession = [UserSessionService currentUserSession];
    //username = currentSession.sipAccountSettings.username;
    // password = currentSession.sipAccountSettings.password;
    uuid = [[UIDevice currentDevice] qliqUUID];
    
    //if([username length]==0)
        username = [[KeychainService sharedService] getUsername];
    //if([password length]==0)
    password = [[KeychainService sharedService] getPassword];
    
    BOOL isAppInBg = ([AppDelegate applicationState] == UIApplicationStateBackground);
    
    NSMutableDictionary *contentDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        password, PASSWORD,
                                        username, USERNAME,
                                        uuid, DEVICE_UUID,
                                        lockState, LOCK_STATE,
                                        wipeState, WIPE_STATE,
                                        [NSNumber numberWithBool:isAppInBg], @"app_in_background",
                                        nil];
        
    NSArray *receivedPushNotifications = [ReceivedPushNotificationDBService selectNoSentToServer];
    if ([receivedPushNotifications count] > 0) {
        NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
        for (ReceivedPushNotification *notif in receivedPushNotifications) {
            NSDictionary *jsonDict = @{
                @"call_id": notif.callId,
                @"received_at": [NSNumber numberWithDouble:notif.receivedAt]
            };
            [jsonArray addObject:jsonDict];
        }
        [contentDict setObject:jsonArray forKey:@"received_push_notifies"];
    }
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:SetDeviceStatusRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        
        [restClient postDataToServer:RegularWebServerType path:@"services/set_device_status" jsonToPost:jsonDict onCompletion:^(NSString * responseDict) {
            
            BOOL ok = [self processResponseString:responseDict onCompletion:block];
             
             if (ok && [receivedPushNotifications count] > 0) {
                 DDLogSupport(@"Removing push notifications");
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                     for (ReceivedPushNotification *notif in receivedPushNotifications) {
                         [ReceivedPushNotificationDBService remove:notif.callId];
                     }
                 });
             }
         }
        onError:^(NSError* error) {
             if (block) block(NO, error);
             
		 }];
	}else{
		DDLogSupport(@"setDeviceStatusLock: Invalid request sent to server");
        if (block) block(NO, [NSError errorWithDomain:@"SetDeviceStatusError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"SetDeviceStatusError: Invalid request sent to server" forKey:@"error"]]);
	}
}

-(BOOL) processResponseString:(NSString *)responseString onCompletion:(void(^)(BOOL success, NSError * error)) block
{
    DDLogSupport(@"set_device_status responseString : %@ ",responseString);
    BOOL ret = NO;
    
    if([self isJsonResponseValid:responseString]){
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
        
        NSDictionary *dataDict = [message objectForKey:DATA];
        if (dataDict)
        {
            DDLogSupport(@"dataDict: %@", dataDict);
            
            if (block) block(YES, nil);
            ret = YES;
        }else{
            NSDictionary *errorDict = [message objectForKey:ERROR];
            DDLogError(@"errorDict: %@", errorDict);
            if (block) block(NO, [NSError errorWithDomain:@"SetDeviceStatusError" code:200 userInfo:errorDict]);
        }
    }else{
        DDLogError(@"Invalid JSON received from server");
        if (block) block(NO, [NSError errorWithDomain:@"SetDeviceStatusError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"Invalid JSON received from server" forKey:@"error"]]);
    }
    return ret;
}

-(BOOL) isJsonResponseValid:(NSString *)responseString
{
    BOOL rez = YES;
    rez &= [responseString length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:responseString embeddedSchema:SetDeviceStatusResponseSchema];
    rez &= validJson;
	
    return rez;
}


@end

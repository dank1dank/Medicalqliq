//
//  GetDeviceStatus.m
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "GetDeviceStatus.h"
#import "NotificationUtils.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "KeychainService.h"
#import "QliqConnectModule.h"
#import "SetDeviceStatus.h"
#import "UIDevice+UUID.h"

void qx_GetDeviceStatusWebService_processResponse(const char *json);

NSString *DeviceStatusNotification = @"DeviceStatus";

@interface GetDeviceStatus ()

@end

@implementation GetDeviceStatus

+ (GetDeviceStatus *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetDeviceStatus alloc] init];
        
    });
    return shared;
}

#pragma mark - Public

- (BOOL)isLockedInKeychain {
    NSString *lockState = [[KeychainService sharedService] getLockState];
    return [lockState isEqual:GetDeviceStatusLocked] || [lockState isEqual:GetDeviceStatusLocking];
}

/**
 Checking device status for Locked or Wiped state. This method handles network errors and 
 if network problem occured - return last statuses that stored in keychain with error.
 */
- (void) isDeviceLockedCompletition:(void(^)(BOOL locked, BOOL wiped, NSError * error))completitionBlock{
    
    [self getDeviceStatusOnCompletion:^(BOOL lock, BOOL wipeData) {
        if (completitionBlock) completitionBlock(lock, wipeData, nil);
    } onError:^(NSError *error) {
        BOOL lockedInKeychain = [self isLockedInKeychain];
        if (completitionBlock) completitionBlock(lockedInKeychain, NO, error);
    }];
}

- (void)getDeviceStatusOnCompletion:(void (^)(BOOL lock, BOOL wipeData))completionBlock onError:(void (^)(NSError *error)) errorBlock
{
    __block BOOL hasRequiredValues = YES;
    
    void (^errorHandler)(NSError * error) = ^(NSError * error){
        
        //calling service
        if (hasRequiredValues) {
            [[SetDeviceStatus sharedService] setDeviceStatusLock:GetDeviceStatusLockFailed wipeState:GetDeviceStatusWipeFailed onCompletion:nil];
        }
        //
        if (errorBlock) errorBlock(error);
    };
    void (^successHandler)(NSString * lockStatus, NSString * wipeStatus) = ^(NSString * lockStatus, NSString * wipeStatus){
        
        if ([lockStatus isEqualToString:GetDeviceStatusUnlocking]){
            lockStatus = GetDeviceStatusUnlocked;
        }
        
        DDLogSupport(@"getDeviceStatus ended with lockStatus: %@, wipeStatus: %@",lockStatus,wipeStatus);
        if (completionBlock) {
            BOOL lock = [lockStatus isEqual:GetDeviceStatusLocking] || [lockStatus isEqual:GetDeviceStatusLocked];
            BOOL wipeData = [wipeStatus isEqual:GetDeviceStatusWiping] || [wipeStatus isEqualToString:GetDeviceStatusWiped];
            completionBlock(lock,wipeData);
        }
        if (hasRequiredValues) {
            [[SetDeviceStatus sharedService] setDeviceStatusLock:lockStatus wipeState:wipeStatus onCompletion:nil];
        }
    };
    
    NSString *username, *password, *uuid;
    //UserSession *currentSession = [UserSessionService currentUserSession];
    //username = currentSession.sipAccountSettings.username;
    //password = currentSession.sipAccountSettings.password;
    uuid = [[UIDevice currentDevice] qliqUUID];
    
    //if([username length]==0)
    username = [[KeychainService sharedService] getUsername];
    //if([password length]==0)
    password = [[KeychainService sharedService] getPassword];
    
    // Adam Sowa:
    // we disovered in the field that in some corner cases device lock state can be present in keychain
    // but username or password is missing. In this case device is stuck because cannnot call the service.
    // This is why we simply unlock locally if values are missing.
    NSString *missingField = nil;
    if ([username length] == 0) {
        missingField = @"username";
        hasRequiredValues = NO;
    }
    else if ([password length] == 0) {
        missingField = @"password";
        hasRequiredValues = NO;
    }
    else if ([uuid length] == 0) {
        missingField = @"uuid";
        hasRequiredValues = NO;
    }
    if (hasRequiredValues == NO) {
        DDLogError(@"Cannot call get_device_status because %@ is missing. Unlocking device locally", missingField);
        
        [self processDeviceLockState:GetDeviceStatusUnlocked wipeState:GetDeviceStatusNone onCompletion:successHandler onError:errorHandler];
        return;
    }
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 uuid, DEVICE_UUID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    DDLogInfo(@"get_device_status request: %@ ",[jsonDict JSONString]);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetDeviceStatusRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_device_status"
                          jsonToPost:jsonDict onCompletion:^(NSString * responseDict)
		 {
             [self processResponseString:responseDict onCompletion:successHandler onError:errorHandler];
		 }
                             onError:^(NSError* error)
		 {
             errorHandler(error);
		 }];
	}else{
		DDLogError(@"GetDeviceStatus: Invalid request sent to server");
        errorHandler([NSError errorWithDomain:@"GetDeviceStatusError" code:200 userInfo:userInfoWithDescription(@"GetDeviceStatusError: Invalid request sent to server")]);
	}
}

#pragma mark - Private

- (void)processDeviceLockState:(NSString *)lockState wipeState:(NSString *)wipeState onCompletion:(void(^)(NSString *lockStatus, NSString *wipeStatus))completionBlock onError:(void (^)(NSError *error)) errorBlock
{
    //writing status to keychain
    BOOL writinSuccess = YES;
    // Don't write username and password
    //
    //NSString *username, *password;
    //UserSession *currentSession = [UserSessionService currentUserSession];
    //username = currentSession.sipAccountSettings.username;
    //password = currentSession.sipAccountSettings.password;
    
    //if([username length]==0)
    //    username = [[KeychainService sharedService] getUsername];
    //if([password length]==0)
    //    password = [[KeychainService sharedService] getPassword];
    
    //writinSuccess &= [[KeychainService sharedService] saveUsername:username];
    //writinSuccess &= [[KeychainService sharedService] savePassword:password];
    
    
    // The '..ing' states are only temporary in the response from web, once received it becomes "..ed"
    if ([lockState isEqualToString:@"locking"]) {
        lockState = @"locked";
    }
    else if ([lockState isEqualToString:@"unlocking"]) {
        lockState = @"unlocked";
    }
    writinSuccess &= [[KeychainService sharedService] saveLockState:lockState];
    writinSuccess &= [[KeychainService sharedService] saveWipeState:wipeState];
    
    if (!writinSuccess) {
        if (errorBlock) errorBlock ([NSError errorWithDomain:@"GetDeviceStatusError" code:200 userInfo:userInfoWithDescription(@"Can't write to keychain")]);
    }
    else {
        //notify about changed status
        [GetDeviceStatus notifyDeviceStatusLocked:[lockState isEqual:GetDeviceStatusLocking]
                                             wipe:[wipeState isEqual:GetDeviceStatusWiping]];
        //callback
        completionBlock(lockState, wipeState);
    }
}

- (void)processResponseString:(NSString *)responseString onCompletion:(void(^)(NSString *lockStatus, NSString *wipeStatus))completionBlock onError:(void (^)(NSError *error))errorBlock
{
    DDLogInfo(@"get_device_status responseString : %@ ",responseString);

    if([self isJsonResponseValid:responseString]) {

        // Call qxlib implementation which will parse and save log config from response
        qx_GetDeviceStatusWebService_processResponse([responseString UTF8String]);
        
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
        
        NSDictionary *dataDict = [message objectForKey:DATA];
        if (dataDict) {
            DDLogInfo(@"dataDict: %@", dataDict);
            
            NSString *lockState = dataDict[LOCK_STATE];
            NSString *wipeState = dataDict[WIPE_STATE];
            
            [self processDeviceLockState:lockState wipeState:wipeState onCompletion:completionBlock onError:errorBlock];
        }
        else {
            NSDictionary *errorDict = [message objectForKey:ERROR];
            NSString *errorMsg = errorDict[ERROR_MSG];
            DDLogError(@"Cannot get device status: errorDict: %@", errorDict);
            if (errorBlock) {
                errorBlock ([NSError errorWithDomain:@"GetDeviceStatusError" code:200 userInfo:userInfoWithDescription(errorMsg)]);
            }
        }
    }
    else {
        DDLogError(@"Invalid JSON received from server");
        if (errorBlock) {
            errorBlock ([NSError errorWithDomain:@"GetDeviceStatusError" code:200 userInfo:userInfoWithDescription(@"Invalid JSON received from server")]);
        }
    }
}

+ (void)notifyDeviceStatusLocked:(BOOL)aLocked wipe:(BOOL)aWipe
{
    NSDictionary *userinfo = @{GetDeviceStatusLocked : [NSNumber numberWithBool:aLocked],
                               GetDeviceStatusWiped : [NSNumber numberWithBool:aWipe]};
    
    [NSNotificationCenter postNotificationToMainThread:DeviceStatusNotification userInfo:userinfo];
}

- (BOOL)isJsonResponseValid:(NSString *)responseString
{
    BOOL rez = YES;
    rez &= responseString.length > 0;
    
    BOOL validJson = [JSONSchemaValidator validate:responseString embeddedSchema:GetDeviceStatusResponseSchema];
    rez &= validJson;
    
    return rez;
}

@end

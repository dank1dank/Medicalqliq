//
//  LogoutService.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "LogoutService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "NSDate+Helper.h"
#import "UIDevice+UUID.h"

@interface LogoutService()

- (void)processResponseString:(NSString *)responseString;

@end

@implementation LogoutService

@synthesize delegate;

+ (LogoutService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[LogoutService alloc] init];
        
    });
    return shared;
}

#pragma mark - Public

- (void)sentLogoutRequest
{
	UserSession *userSession = [UserSessionService currentUserSession]; 
    NSString *username = userSession.sipAccountSettings.username;
    NSString *password = userSession.sipAccountSettings.password;
	
    //TODO: get the qliq_id, device UUID and, current timestamp on the device
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 password, PASSWORD,
                                 username, USERNAME,
                                 [[UIDevice currentDevice] qliqUUID], UUID,
                                 [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]], TIMESTAMP,
                                 userSession.user.qliqId, QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:contentDict, DATA, nil];
    
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:dataDict, MESSAGE, nil];
	
 	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:LogoutRequestSchema]) {
        
		RestClient *restClient = [RestClient clientForCurrentUser];
		
        [restClient postDataToServer:RegularWebServerType path:@"services/logout" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            [self processResponseString:responseString];
        } onError:^(NSError* error) {
            [UIAlertView showWithError:error];
        }];
	}
    else {
		NSLog(@"LogoutService: Invalid request sent to server");
	}
}

#pragma mark - Private

- (void)processResponseString:(NSString *)responseString
{
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
    
	//TODO: process Data if data json object is present, otherwise process error json
	NSDictionary *dataDict = [message objectForKey:DATA];
    if (dataDict) {
        DDLogSupport(@"dataDict: %@", dataDict);
    }
    else {
		NSDictionary *errorDict = [message objectForKey:ERROR];
        DDLogError(@"errorDict: %@", errorDict);
	}
}

@end

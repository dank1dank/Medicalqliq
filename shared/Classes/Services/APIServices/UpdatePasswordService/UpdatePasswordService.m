//
//  UpdatePasswordService.m
//  qliq
//
//  Created by Developer on 15.11.13.
//
//

#import "UpdatePasswordService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "QliqUser.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "DBUtil.h"
#import "UIDevice+UUID.h"

@implementation UpdatePasswordService

+ (instancetype) sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[UpdatePasswordService alloc] init];
        
    });
    return shared;
}

-(void)processResponseString:(NSString *)responseString completitionBlock:(void (^)(NSError *))completeBlock
{
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error = nil;
	NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSDictionary *getContactInfoMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
	NSDictionary *errorDict = [[getContactInfoMessage valueForKey:MESSAGE] valueForKey:ERROR];
    
    if (completeBlock) {
        if (errorDict != nil)
            completeBlock([NSError errorWithDomain:@"com.qliq.updatePasswordService" code:UpdatePasswordErrorCodeWebserverError userInfo:nil]);
        else
            completeBlock(nil);
    }
}

- (void)setNewPassword:(NSString *)newPassword withCompletion:(void(^)(NSError *))completionBlock {
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];

    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 deviceUUID, DEVICE_UUID,
                                 newPassword, NEW_PASSWORD, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]){
        
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/update_password"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString) {
                            [self processResponseString:responseString completitionBlock:completionBlock];
                        }
							 onError:^(NSError* error) {
                                 if (completionBlock) completionBlock(error);
                             }];
	}else{
        if (completionBlock) completionBlock([NSError errorWithDomain:@"com.qliq.updatePasswordService" code:UpdatePasswordeErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"UpdatePassword: Invalid request sent to server")]);
	}
}

@end

//
//  UpdateSipCredentials.m
//  qliq
//
//  Created by Adam Sowa on 30/12/2013.
//
//

#import "UpdateSipCredentials.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "QliqUser.h"
#import "UIDevice+UUID.h"
#import "UserSessionService.h"

@implementation UpdateSipCredentialsService

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
            completeBlock([NSError errorWithDomain:@"com.qliq.updateSipCredentialsService" code:1 userInfo:nil]);
        else
            completeBlock(nil);
    }
}

- (void)update:(void(^)(NSError *))completionBlock {
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    NSString *qliqId = currentSession.user.qliqId;
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 deviceUUID, UUID,
                                 qliqId, QLIQ_ID, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];

    RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/update_sip_credentials"
                      jsonToPost:jsonDict
                    onCompletion:^(NSString *responseString) {
                        [self processResponseString:responseString completitionBlock:completionBlock];
                    }
                         onError:^(NSError* error) {
                             if (completionBlock) completionBlock(error);
                         }];
}

@end

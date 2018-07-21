//
//  UpdateProfileService.m
//  qliq
//
//  Created by Developer on 12.11.13.
//
//

#import "UpdateProfileService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "QliqUser.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "DBUtil.h"

@implementation UpdateProfileService

+ (instancetype) sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[UpdateProfileService alloc] init];
        
    });
    return shared;
}

-(void)processResponseString:(NSString *)responseString completitionBlock:(void (^)(NSError *))completeBlock
{
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error=nil;
	NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSDictionary *getContactInfoMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
	NSDictionary *errorDict = [[getContactInfoMessage valueForKey:MESSAGE] valueForKey:ERROR];
    
    if (completeBlock) {
        if (errorDict != nil)
            completeBlock([NSError errorWithDomain:@"com.qliq.updateProfileService" code:UpdateProfileErrorCodeWebserverError userInfo:nil]);
        else
            completeBlock(nil);
    }
}

- (void)sendUpdateInfoWithCompletion:(void(^)(NSError *error))completionBlock {
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    QliqUser* loggingUser = currentSession.user;
    
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
    
    NSString *title = loggingUser.profession;
    NSString *organization = loggingUser.organization;
    NSString *city = loggingUser.city;
    NSString *zip = loggingUser.zip;
    NSString *state = loggingUser.state;
    NSString *firstName = loggingUser.firstName;
    NSString *lastName = loggingUser.lastName;
    NSString *mobile = loggingUser.mobile;
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 title,TITLE,
                                 city, CITY,
                                 state, STATE,
                                 mobile, MOBILE,
                                 firstName, FIRST_NAME,
                                 lastName, LAST_NAME,
                                 organization, ORGANIZATION,
                                 zip, ZIP, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/update_profile"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString)
		 {
             [self processResponseString:responseString completitionBlock:completionBlock];
		 }
							 onError:^(NSError* error)
		 {
             if (completionBlock) completionBlock(error);
		 }];
	}else{
        if (completionBlock) completionBlock([NSError errorWithDomain:@"com.qliq.updateProfileService" code:UpdateProfileErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"UpdateProfile: Invalid request sent to server")]);
	}
}

@end

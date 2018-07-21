//
//  Click2CallService.m
//  qliq
//
//  Created by Valerii Lider on 5/16/16.
//
//

#import "Click2CallService.h"
#import "QliqJsonSchemaHeader.h"
#import "RestClient.h"
#import "JSONKit.h"
#import "UIDevice+UUID.h"
#import "JSONSchemaValidator.h"
#import "KeychainService.h"

@implementation Click2CallService

- (void)requestCallbackForCallerNumber:(NSString *)callerPhoneNumber toCalle:(NSString *)calleePhoneNumber withCompletionBlock:(CompletionBlock)completion
{
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 username, USERNAME,
                                 password, PASSWORD,
                                 deviceUUID, DEVICE_UUID,
                                 callerPhoneNumber, CALLER_PHONE_NUMBER,
                                 calleePhoneNumber, CALLEE_PHONE_NUMBER,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"x", COMMAND,
                              @"x", SUBJECT,
                              @"x", TYPE,
                              contentDict, DATA,
                              nil];
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    
//    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:Click2CallRequestSchema]) {
    
        RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/click2call"
                          jsonToPost:jsonDict
                        onCompletion:^(NSString *responseString)
         {
             NSStringEncoding dataEncoding = NSUTF8StringEncoding;
             NSError *error=nil;
             NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
             JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
             NSDictionary *jsonDict = [jsonKitDecoder objectWithData:jsonData error:&error];
             NSDictionary *errorDict = [[jsonDict valueForKey:MESSAGE] valueForKey:ERROR];
             
             DDLogSupport(@"JSON dictionary: %@", jsonDict);
             
             if (errorDict && errorDict[@"error_code"]) {
                 
                 DDLogError(@"%@",[errorDict valueForKey:@"error_msg"]);
                 
                 NSString *errCode = errorDict[@"error_code"];

                 NSError *error = [NSError errorWithDomain:errorCurrentDomain
                                                      code:errCode.intValue
                                                  userInfo:userInfoWithDescription(errorDict[@"error_msg"])];
                 
                 completion(CompletitionStatusError, nil, error);
                 
             } else if (jsonDict) {
                 completion(CompletitionStatusSuccess, [jsonDict objectForKey:DATA], nil);
                
             }
         }
                             onError:^(NSError* error)
         {
             DDLogError(@"%@",[error localizedDescription]);
             completion(CompletitionStatusError, nil, error);
         }];
//    } else {
//        NSError *error = [NSError errorWithDomain:errorDomain
//                                             code:0
//                                         userInfo:userInfoWithDescription(@"Click2CallService: Invalid request sent to server")];
//        if (completion) {
//            completion(CompletitionStatusError, nil, error);
//        }
//    }
}
@end

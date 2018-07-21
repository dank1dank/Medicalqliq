//
//  GetAllOnCallGroupsService.m
//  qliq
//
//  Created by Adam on 10/08/15.
//
//

#import "GetAllOnCallGroupsService.h"

#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"
#import "OnCallGroup.h"

#define errorDomain @"GetAllOnCallGroupsService"

@implementation GetAllOnCallGroupsService

- (void) getWithCompletionBlock:(CompletionBlock) completion
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 password, PASSWORD,
                                 username, USERNAME,
                                 deviceUUID, DEVICE_UUID,
                                 nil];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              contentDict, DATA,
                              nil];
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    
    RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/get_all_oncall_groups"
                      jsonToPost:jsonDict
                    onCompletion:^(NSString *responseString)
     {
         NSStringEncoding dataEncoding = NSUTF8StringEncoding;
         NSError *error=nil;
         NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
         JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
         NSDictionary *jsonDict = [jsonKitDecoder objectWithData:jsonData error:&error];
         NSDictionary *errorDict = [[jsonDict valueForKey:MESSAGE] valueForKey:ERROR];
         
         if (errorDict != nil) {
             DDLogError(@"%@",[(NSError *)[errorDict valueForKey:@"error"] localizedDescription]);
         } else {
             NSArray *data = [[jsonDict valueForKey:MESSAGE] valueForKey:DATA];
             dispatch_async_background(^{
                 [OnCallGroup processAllGroupsJson:data];
             });
         }
     }
                         onError:^(NSError* error)
     {
         DDLogError(@"%@",[error localizedDescription]);
     }];
}

@end

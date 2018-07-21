//
//  GetOnCallGroupUpdates.m
//  qliq
//
//  Created by Adam Sowa on 10/01/17.
//
//

#import "GetOnCallUpdatesService.h"
#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"
#import "OnCallGroup.h"

#define errorDomain @"GetOnCallUpdatesService"

@implementation GetOnCallUpdatesService

- (void) getWithCompletionBlock:(CompletionBlock) completion
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    
    NSMutableArray *groupArray = [NSMutableArray new];
    for (OnCallGroup *g in [OnCallGroup onCallGroups]) {
        [groupArray addObject:@{
            @"qliq_id": g.qliqId,
            @"last_updated_epoch": [NSNumber numberWithUnsignedInteger:g.lastUpdated]
        }];
    }
    
    NSDictionary *contentDict = @{
        PASSWORD: password,
        USERNAME: username,
        DEVICE_UUID: deviceUUID,
        @"oncall_groups": groupArray,
        @"reason": @"view-oncall"
    };
    NSDictionary *jsonDict = @{
        MESSAGE: @{
            DATA: contentDict
        }
    };
    
    RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/get_oncall_updates"
                      jsonToPost:jsonDict
                    onCompletion:^(NSString *responseString)
     {
         NSStringEncoding dataEncoding = NSUTF8StringEncoding;
         NSError *error=nil;
         NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
         JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
         NSDictionary *jsonDict = [jsonKitDecoder objectWithData:jsonData error:&error];
         NSArray *data = [[jsonDict valueForKey:MESSAGE] valueForKey:DATA];
         NSDictionary *errorDict = [[jsonDict valueForKey:MESSAGE] valueForKey:ERROR];
         
         if ([data count] > 0) {
             // Krishna 2/28/2017
             // Process it in the Background so that it does not freeze UI
             dispatch_async_background(^{
                 [OnCallGroup processBulkJsonUpdate:data];
                 if (completion) {
                     completion(CompletitionStatusSuccess, nil, nil);
                 }
             });
         } else if (errorDict != nil) {
             DDLogError(@"Error calling get_oncall_group_updates: %@", errorDict);
             
             if ([errorDict[@"error_code"] isEqualToString:@"103"] || [errorDict[@"error_code"] isEqualToString:@"110"]) {
                 if (completion) {
                     completion(CompletitionStatusSuccess, nil, nil);
                 }
             }
             else {
                 if (completion) {
                     completion(CompletitionStatusError, nil, nil);
                 }
             }
         }
         else {
             if (completion) {
                 completion(CompletitionStatusSuccess, nil, nil);
             }
         }
     }
    onError:^(NSError* error)
     {
         if (completion) {
             completion(CompletitionStatusError, nil, nil);
         }
     }];
}

@end

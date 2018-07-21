//
//  GetAllOnCallGroupsService.m
//  qliq
//
//  Created by Adam on 10/08/15.
//
//

#import "GetOnCallGroupService.h"

#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"
#import "OnCallGroup.h"

#define errorDomain @"GetOnCallGroupService"

@implementation GetOnCallGroupService

- (void) get:(NSString *)qliqId reason:(OnCallGroupRequestReason)reason withCompletionBlock:(CompletionBlock) completion;
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    NSUInteger lastUpdated = [OnCallGroup lastUpdated:qliqId];
    
    NSString *reasonStr = @"";
    switch (reason) {
        case ViewRequestReason:
            reasonStr = @"view-oncall";
            break;
        case ChangeNotificationRequestReason:
            reasonStr = @"change-notification";
            break;
    }
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 password, PASSWORD,
                                 username, USERNAME,
                                 deviceUUID, DEVICE_UUID,
                                 qliqId, @"group_qliq_id",
                                 [NSNumber numberWithUnsignedInteger:lastUpdated], @"last_updated_epoch",
                                 reasonStr, @"reason",
                                 nil];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              contentDict, DATA,
                              nil];
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    
    RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/get_oncall_group"
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
             DDLogError(@"%@", errorDict);
             if ([errorDict[@"error_code"] isEqualToString:@"103"]) {
                 [OnCallGroup deleteOnCallGroupWithQliqId:qliqId];
                 if (completion) {
                     completion(CompletitionStatusSuccess, nil, nil);
                 }
             } else if ([errorDict[@"error_code"] isEqualToString:@"110"]) {
                 if (completion) {
                     completion(CompletitionStatusCancel, nil, nil);
                 }
             } else {
                 if (completion) {
                     DDLogSupport(@"CompletitionStatusError - %@", errorDict[@"error_code"]);
                     completion(CompletitionStatusError, nil, nil);
                 }
             }
         } else {
             NSDictionary *data = [[jsonDict valueForKey:MESSAGE] valueForKey:DATA];
             //Need to save to DB
             // Krishna 2/28/2017
             // Push this in the Background processing so that it does not freeze the UI
             dispatch_async_background(^{
                 [OnCallGroup processSingleGroupJson:data];
                 if (completion) {
                     completion(CompletitionStatusSuccess, nil, nil);
                 }
             });
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

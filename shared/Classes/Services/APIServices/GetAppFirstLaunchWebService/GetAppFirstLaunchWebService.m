//
//  GetAppFirstLaunchWebService.m
//  qliq
//
//  Created by Valerii Lider on 19/09/15.
//
//

#import "GetAppFirstLaunchWebService.h"

#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"

#import "DBUtil.h"


#import "QliqConnectModule.h"

@implementation GetAppFirstLaunchWebService

- (NSString *)serviceName {
    return @"services/get_app_first_launch_info";
}

- (Schema)requestSchema {
    return GetAppFirstLaunchInfoRequestSchema;
}

- (Schema)responseSchema {
    return GetAppFirstLaunchInfoResponceSchema;
}

- (NSDictionary *)requestJson{
    
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[@"app_platform"] = @"iOS";
    dataDict[@"app_name"] = @"qliqConnect";
    dataDict[@"app_version"] = build;
    
    return @{ MESSAGE : @{ DATA : dataDict } };
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    
    NSString *version = [[dataDict valueForKey:@"app_released_version"] stringValue];
    NSNumber *appReleasedVersion = [NSNumber numberWithInteger:[version integerValue]];
    
    if (completitionBlock)
        completitionBlock(CompletitionStatusSuccess, appReleasedVersion, nil);
}

- (void) handleError:(NSError*) error
{
    NSLog(@"");
}

@end

//
//  FeatureRatingService.m
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeatureRequestService.h"
#import "FeatureRequest.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "SipAccountSettings.h"
#import "Feature.h"
#import "JSONKit.h"
#import "QliqJsonSchemaHeader.h"
#import "RestClient.h"

@interface FeatureRequestService()

-(void) processResponseString:(NSString *)responseString;

@end

@implementation FeatureRequestService

@synthesize delegate;

-(void) requestFeature:(FeatureRequest *)feature_request
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *pwdBase64 = [UserSessionService currentUserSession].sipAccountSettings.password;
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 username, USERNAME,
                                 pwdBase64, PASSWORD,
                                 feature_request.feature.name, FEATURE,
                                 feature_request.requestType, REQUEST_TYPE,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              contentDict, @"Data",
                              nil];
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 dataDict, @"Message",
                                 nil];
    
    NSLog(@"%@",[jsonDict JSONString]);
    
	RestClient *restClient = [RestClient clientForCurrentUser];
    [restClient postDataToServer:RegularWebServerType
                            path:@"services/feature_request"
					  jsonToPost:jsonDict 
					onCompletion:^(NSString *responseString)
	 {
		 [self processResponseString:responseString];
	 } 
						 onError:^(NSError* error)
	 {
		 [UIAlertView showWithError:error];
	 }];

}

-(void) processResponseString:(NSString *)responseString
{
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
    
	NSDictionary *dataDict = [message objectForKey:DATA];
    if (dataDict)
    {
        DDLogSupport(@"dataDict: %@", dataDict);
    }else{
		NSDictionary *errorDict = [message objectForKey:ERROR];
        DDLogError(@"errorDict: %@", errorDict);
	}
}

@end

//
//  UpdateEscalatedCallnotifyInfoService.m
//  qliq
//
//  Created by Valerii Lider on 7/15/14.
//
//

#import "UpdateEscalatedCallnotifyInfoService.h"

#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"

#define errorDomain @"com.qliq.UpdateEscalatedCallnotifyInfoService"

@implementation UpdateEscalatedCallnotifyInfoService

+ (UpdateEscalatedCallnotifyInfoService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[UpdateEscalatedCallnotifyInfoService alloc] init];
        
    });
    return shared;
}

#pragma mark -
#pragma mark Private

- (void)updateEscalatedCallnotifyInfoEscalationNumber:(NSString*)escalationNumber
                                     escalateWeekends:(BOOL)escalateWeekends
                                   escalateWeeknights:(BOOL)escalateWeeknights
                                     escalateWeekdays:(BOOL)escalateWeekdays
                                withCompletitionBlock:(CompletionBlock) completition
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
	
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 deviceUUID, DEVICE_UUID,
                                 escalationNumber, ESCALATION_NUMBER,
                                 @(escalateWeekends), ESCALATE_WEEKENDS,
                                 @(escalateWeeknights), ESCALATE_WEEKNIGHTS,
                                 @(escalateWeekdays), ESCALATE_WEEKDAYS,
								 nil];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:UpdateEscalatedCallnotifyInfoRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/update_escalated_callnotify_info"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString)
		 {
			 [self updateEscalatedCallnotifyInfoRequestFinished:responseString completitionBlock:completition];
             
		 }
							 onError:^(NSError* error)
		 {
			 [UIAlertView showWithError:error];
		 }];
	}else{
        completition(CompletitionStatusError,nil,[NSError errorWithCode:0 description:@"UpdateEsclatedCallnotifyInfoService: Invalid request sent to server"]);
	}
}

- (void)updateEscalatedCallnotifyInfoRequestFinished:(NSString *)responseString completitionBlock:(CompletionBlock)completition
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSStringEncoding dataEncoding = NSUTF8StringEncoding;
        NSError *error=nil;
        NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSDictionary *getUserConfigData = [jsonKitDecoder objectWithData:jsonData error:&error];
        NSDictionary *errorDict = [[getUserConfigData valueForKey:MESSAGE] valueForKey:ERROR];
        
        if(errorDict != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                DDLogError(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
                NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
                if (completition) completition(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:1 userInfo:userInfoWithDescription(reason)]);
            });
            
            return;
        }
        
        if(![self responceValid:responseString])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *reason = [NSString stringWithFormat:@"Invalid Escalated Callnotify Info"];
                if (completition) completition(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
            });
            
            return;
        }
        
        NSDictionary *data = [[getUserConfigData valueForKey:MESSAGE] valueForKey:DATA];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completition) completition(CompletitionStatusSuccess, data, nil);
        });
    });
}

- (BOOL)responceValid:(NSString *)userConfigJson
{
    BOOL rez = YES;
    rez &= [userConfigJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:userConfigJson embeddedSchema:UpdateEscalatedCallnotifyInfoResponceSchema];
    rez &= validJson;
	
    return rez;
}

@end

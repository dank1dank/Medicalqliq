//
//  GetGroupContactsService.m
//  qliq
//
//  Created by Adam on 3/5/13.
//
//

#import "GetGroupContactsService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "QliqUser.h"
#import "QliqUserDBService.h"
#import "QliqGroup.h"
#import "QliqGroupDBService.h"
#import "QliqSip.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "SipAccountSettings.h"
#import "Contact.h"
#import "ContactDBService.h"
#import "AvatarDownloadService.h"
#import "AppDelegate.h"
#import "DBUtil.h"
#import "SipContact.h"
#import "SipContactDBService.h"

#define errorDomain @"com.qliq.GetGroupContacts"

@interface GetGroupContactsService()
-(BOOL) isJsonValid:(NSString *)allContactsJson;
-(BOOL) storeGroupContacts:(NSDictionary *)dataDict;
-(void) processResponseString:(NSString *)responseString completition:(CompletionBlock) completetion;

@end

@implementation GetGroupContactsService


+ (GetGroupContactsService *) sharedService
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetGroupContactsService alloc] init];
        
    });
    return shared;
}

-(void) getGroupContactsForQliqId:(NSString *)qliqId withCompletition:(CompletionBlock) completetion
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 qliqId, GROUP_QLIQID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetGroupContactsRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_group_contacts"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString)
		 {
			 [self processResponseString:responseString completition:completetion];
		 }
							 onError:^(NSError* error)
		 {
             if (completetion) completetion(CompletitionStatusSuccess, nil, error);
             
		 }];
	}else{
        if (completetion) completetion(CompletitionStatusSuccess, nil, [NSError errorWithDomain:errorDomain code:0 userInfo:userInfoWithDescription(@"GetGroupContacts: Invalid request sent to server")]);
	}
}

#pragma mark -
#pragma mark Private

-(void) processResponseString:(NSString *)responseString completition:(CompletionBlock)completetion
{
	
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error=nil;
	NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSDictionary *getAllContactsMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
	NSDictionary *errorDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:ERROR];
	
	if(errorDict != nil)
	{
		DDLogSupport(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
		NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
        if (completetion) completetion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:1 userInfo:userInfoWithDescription(reason)]);
		return;
	}
	
	
	if(![self isJsonValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid group info"];
        if (completetion) completetion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
		return;
	}
	
	NSDictionary *getAllContacts = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
	[self storeGroupContacts:getAllContacts];
    if (completetion) completetion(CompletitionStatusSuccess, getAllContacts, nil);
}


-(BOOL) isJsonValid:(NSString *)allContactsJson
{
    BOOL rez = YES;
    rez &= [allContactsJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:allContactsJson embeddedSchema:GetGroupContactsResponseSchema];
    rez &= validJson;
	
    return rez;
}

-(BOOL) storeGroupContacts:(NSDictionary *)dataDict
{
	DDLogSupport(@"GET GROUP CONTACTS : processing started");
	
    BOOL success = YES;
	
	DDLogVerbose(@"Data %@",dataDict);
    
	NSMutableArray *usersArray = [dataDict objectForKey:QLIQ_USERS];
    
    for (NSMutableDictionary *userInfoDict in usersArray)
    {
        [[QliqUserDBService sharedService] saveContactFromJsonDictionary:userInfoDict andNotifyAboutNew:YES];
	}
	
	DDLogSupport(@"GET GROUP CONTACTS : processing finished");
	return success;
}

@end

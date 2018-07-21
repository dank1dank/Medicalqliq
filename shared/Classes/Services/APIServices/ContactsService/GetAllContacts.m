//
//  GetAllContacts.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetAllContacts.h"
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

#define errorDomain @"com.qliq.GetAllContacts"

@interface GetAllContacts()
-(BOOL) allContactsValid:(NSString *)allContactsJson;
-(BOOL) storeAllContacts:(NSDictionary *)dataDict;
-(void) processResponseString:(NSString *)responseString completition:(CompletionBlock) completetion;

@end

@implementation GetAllContacts

@synthesize delegate;

+ (GetAllContacts *) sharedService
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetAllContacts alloc] init];
        
    });
    return shared;
}

-(void) getAllContactsWithCompletition:(CompletionBlock) completetion{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetAllContactsRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_all_contacts"
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
        if (completetion) completetion(CompletitionStatusSuccess, nil, [NSError errorWithDomain:errorDomain code:0 userInfo:userInfoWithDescription(@"GetAllContacts: Invalid request sent to server")]);
	}
}

-(void) getAllContacts
{
    [self getAllContactsWithCompletition:nil];
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
	
	
	if(![self allContactsValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid group info"];
        if (completetion) completetion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
		return;
	}
	
	NSDictionary *getAllContacts = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
	[self storeAllContacts:getAllContacts];
    if (completetion) completetion(CompletitionStatusSuccess, getAllContacts, nil);
}


-(BOOL) allContactsValid:(NSString *)allContactsJson
{
    BOOL rez = YES;
    rez &= [allContactsJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:allContactsJson embeddedSchema:GetAllContactsResponseSchema];
    rez &= validJson;
	
    return rez;
}

-(BOOL) storeAllContacts:(NSDictionary *)dataDict
{
	DDLogSupport(@"GET ALL CONTACTS : processing started");
	
    BOOL success = YES;
	
	DDLogVerbose(@"Data %@",dataDict);
    
	NSMutableArray *usersArray = [dataDict objectForKey:QLIQ_USERS];
    
	NSMutableSet *activeUserIds = [[NSMutableSet alloc] init];
    
    for(NSMutableDictionary *userInfoDict in usersArray)
    {
        QliqUser *user = [[QliqUserDBService sharedService] saveContactFromJsonDictionary:userInfoDict andNotifyAboutNew:NO];
        if (user) {
            [activeUserIds addObject:user.qliqId];
        }
	}
    [[QliqUserDBService sharedService] setAllOtherUsersAsDeleted:activeUserIds];
	
	DDLogSupport(@"GET ALL CONTACTS : processing finished");
	return success;
}
@end

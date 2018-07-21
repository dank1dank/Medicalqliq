//
//  SearchContactsService.m
//  qliq
//
//  Created by Adam Sowa on 26.11.2015.
//
//

#import "SearchContactsService.h"
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
#import "UIDevice+UUID.h"
#import "GetContactsPaged.h"

#define errorDomain @"com.qliq.SearchContactsService"

static NSString *s_recentFilter;

@implementation SearchContactsService

+ (SearchContactsService *)sharedService
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        
        shared = [[SearchContactsService alloc] init];
    });
    return shared;
}

+ (BOOL)searchContactsIfNeeded:(NSString *)filter count:(NSInteger)count completion:(CompletionBlock)completion
{
    if (![GetContactsPaged isComplete]) {
        [[self sharedService] searchContacts:filter count:count completion:completion];
        return YES;
    }
    return NO;
}

- (void)searchContacts:(NSString *)filter count:(NSInteger)count completion:(CompletionBlock)completion
{
    
    if (filter.length < 1 || count < 1) {
        return;
    }
    
    if ([s_recentFilter hasPrefix:filter]) {
        return;
    }
    
    DDLogSupport(@"Sending contacts search request to server");
    
    s_recentFilter = filter;
    
    NSString *username      = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password      = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *qliqId        = [UserSessionService currentUserSession].user.qliqId;
    NSString *deviceUUID    = [[UIDevice currentDevice] qliqUUID];
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								    password, PASSWORD,
                                    username, USERNAME,
                                  deviceUUID, DEVICE_UUID,
                                     filter, @"search_by",
                                    @(count), PER_PAGE, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:contentDict, DATA, nil];
    
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:dataDict, MESSAGE, nil];
   
//	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetPagedContactsRequestSchema])
//    {
		RestClient *restClient = [RestClient clientForCurrentUser];
		[restClient postDataToServer:RegularWebServerType
                                path:@"services/search_contacts" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                 // Fragment to retrieve next page before processing this one
                 /*
                 NSStringEncoding dataEncoding = NSUTF8StringEncoding;
                 NSError *error=nil;
                 NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
                 JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
                
                 NSDictionary *getAllContactsMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
                 
                 NSDictionary *errorDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:ERROR];
                 NSDictionary *dataDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
                */
                  
                 [self processResponseString:responseString completition:completion page:1 myQliqId:qliqId];
             });
             
		 } onError:^(NSError* error) {
             if (completion) completion(CompletitionStatusSuccess, nil, error);
		 }];
//	} else {
//        if (completion) completion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:0 userInfo:userInfoWithDescription(@"SearchContacts: Invalid request sent to server")]);
//	}
}

#pragma mark -
#pragma mark Private

-(BOOL) processResponseString:(NSString *)responseString completition:(CompletionBlock)completion page:(NSInteger)currentPage myQliqId:(NSString *)qliqId
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
        if (completion) completion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:1 userInfo:userInfoWithDescription(reason)]);
		return NO;
	}
	
	
	if(![self allContactsValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid group info"];
        if (completion) completion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
		return NO;
	}
	
	NSDictionary *getAllContacts = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
    NSArray *users = [self storeAllContacts:getAllContacts];
    if (completion) completion(CompletitionStatusSuccess, users, nil);
    return (users.count > 0);
}

- (BOOL)allContactsValid:(NSString *)allContactsJson
{
    BOOL rez = YES;
    rez &= [allContactsJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:allContactsJson embeddedSchema:GetPagedContactsResponseSchema];
    rez &= validJson;
	
    return rez;
}

- (NSArray *)storeAllContacts:(NSDictionary *)dataDict
{
	DDLogSupport(@"SearchContacts processing started");
	
    NSMutableArray *users = [[NSMutableArray alloc] init];
	
	DDLogVerbose(@"Data %@",dataDict);
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
       
        [db beginTransaction];
        
        for (NSDictionary *item in dataDict[QLIQ_USERS]) {
            
            QliqUser *u = [[QliqUserDBService sharedService] saveContactFromJsonDictionary:item andNotifyAboutNew:NO];
            if (u != nil) {
                [users addObject:u];
            }
        }
        
        [db commit];
    }];
	
	DDLogSupport(@"SearchContacts processing finished");
	return users;
}

@end

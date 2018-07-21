//
//  GetGroupContactsPagedService.m
//  qliq
//
//  Created by Adam Sowa on 17/12/2014.
//
//

#import "GetGroupContactsPagedService.h"
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

#define errorDomain @"com.qliq.GetGroupContacts"

@interface GetGroupContactsPagedService()

@property (nonatomic, strong) NSString *groupQliqId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-property-synthesis"
@property (nonatomic, copy) CompletionBlock completionBlock;
#pragma clang diagnostic pop

@property (nonatomic, readwrite) NSInteger perPage;
@property (nonatomic, strong) GetGroupContactsPagedService *this;

-(BOOL) isJsonValid:(NSString *)allContactsJson;
-(BOOL) storeGroupContacts:(NSDictionary *)dataDict;
-(void) processResponseString:(NSString *)responseString completition:(CompletionBlock) completion;

@end

@implementation GetGroupContactsPagedService



-(void) getGroupContactsForQliqId:(NSString *)qliqId withCompletition:(CompletionBlock) completion
{
    self.groupQliqId = qliqId;
    self.completionBlock = completion;
    self.perPage = 200;
    self.this = self;
    
    [self getPage:1];
}

-(void) getPage:(NSInteger)page
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
    if (username && password)
    {
        NSDictionary *dataDict = @{
                                   PASSWORD: password,
                                   USERNAME: username,
                                   GROUP_QLIQID: self.groupQliqId,
                                   DEVICE_UUID: [[UIDevice currentDevice] qliqUUID],
                                   @"per_page": [NSNumber numberWithInteger: self.perPage],
                                   @"page": [NSNumber numberWithInteger: page]
                                   };
        
        NSDictionary *jsonDict = @{
                                   MESSAGE: @{
                                           DATA: dataDict
                                           }
                                   };
        
        if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetGroupContactsRequestSchema])
        {
            RestClient *restClient = [RestClient clientForCurrentUser];
            [restClient postDataToServer:RegularWebServerType
                                    path:@"services/get_group_paged_contacts"
                              jsonToPost:jsonDict
                            onCompletion:^(NSString *responseString)
             {
                 dispatch_async_background(^{
                     [self processResponseString:responseString completition:self.completionBlock];
                 });
             }
                                 onError:^(NSError* error)
             {
                 if (self.completionBlock) self.completionBlock(CompletitionStatusError, nil, error);
                 self.this = nil;
                 
             }];
        }
        else
        {
            if (self.completionBlock) self.completionBlock(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:0 userInfo:userInfoWithDescription(@"GetGroupContacts: Invalid request sent to server")]);
            self.this = nil;
        }
    }
}

#pragma mark -
#pragma mark Private

-(void) processResponseString:(NSString *)responseString completition:(CompletionBlock)completion
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
        self.this = nil;
		return;
	}
	
	
	if(![self isJsonValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid group info"];
        if (completion) completion(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
        self.this = nil;
		return;
	}
	
	NSDictionary *dataDict = [[getAllContactsMessage valueForKey:MESSAGE] valueForKey:DATA];
    NSInteger currentPage = [dataDict[@"current_page"] integerValue];
    NSInteger totalPages = [dataDict[@"total_pages"] integerValue];
    BOOL isLastPage = (currentPage == totalPages);
    if (!isLastPage) {
        // Send request for next page immediately so webserver sends it while we process this one
        [self getPage:(currentPage+1)];
    }
    
    [self storeGroupContacts:dataDict];
    
    if (isLastPage) {
        if (completion) completion(CompletitionStatusSuccess, dataDict, nil);
        self.this = nil;
    }
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

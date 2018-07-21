//
//  GetGroupInfoService.m
//  qliq
//
//  Created by Ravi Ada on 08/01/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetGroupInfoService.h"
#import "QliqApiManager.h"
#import "JSONKit.h"
#import "JSONSchemaValidator.h"
#import "QliqUser.h"
#import "QliqUserDBService.h"
#import "QliqGroup.h"
#import "QliqGroupDBService.h"
#import "QliqSip.h"
#import "SipServerInfo.h"
#import "UserSettingsService.h"
#import "RestClient.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "SipAccountSettings.h"
#import "Metadata.h"
#import "Contact.h"
#import "ContactDBService.h"
#import "SipContactDBService.h"
#import "DBUtil.h"
#import "QliqApiService.h"

@interface GetGroupInfoService(Private)

- (void)getGroupInfoRequestFinished:(NSString *)responseString forQliqId:(NSString *)qliqId withCompletion:(void(^)(QliqGroup *group, NSError *error))completeBlock;
- (BOOL)groupInfoValid:(NSString *)userDetailsJson;

@end

@implementation GetGroupInfoService

@synthesize delegate;

+ (GetGroupInfoService *)sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetGroupInfoService alloc] init];
    });
    return shared;
}

#pragma mark - Public

- (void)getGroupInfo:(NSString *)qliqId {
    [self getGroupInfo:qliqId withCompletion:nil];
}

- (void)getGroupInfo:(NSString *)qliqId withCompletion:(void(^)(QliqGroup *group, NSError *error))completeBlock {
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    NSDictionary *contentDict = @{PASSWORD : password,
                                  USERNAME : username,
                                  QLIQ_ID : qliqId};
    NSDictionary *dataDict = @{DATA : contentDict};
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:dataDict, MESSAGE, nil];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetGroupInfoRequestSchema]) {
        
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_group_info"
						  jsonToPost:jsonDict 
						onCompletion:^(NSString *responseString)
		 {
             [self getGroupInfoRequestFinished:responseString forQliqId:qliqId withCompletion:completeBlock];
             
		 }  onError:^(NSError* error) {
             
             [self getGroupInfoRequestFinished:nil forQliqId:qliqId withCompletion:completeBlock];
		 }];
	}
    else {
		[self.delegate didFailToGetGroupInfoWithReason:@"GetGroupInfoService: Invalid request sent to server"];
	}
}

+ (QliqGroup *)parseGroupJson:(NSDictionary *)thisGroup andSaveInDb:(BOOL)saveInDb {
    if (saveInDb)
        DDLogSupport(@"GET GROUP INFO: processing started");
    DDLogVerbose(@"Data %@", thisGroup);
    
    //NSDictionary *thisGroup = [groupDict objectForKey:GROUP];
    QliqGroup *group = [[QliqGroup alloc] init];
    NSDictionary *parentGroupDict = [thisGroup objectForKey:PARENT_GROUP];
    
    if(parentGroupDict != nil) {
        NSString *parentQliqId = [parentGroupDict objectForKey:QLIQ_ID];
        QliqGroup *parentGroup = [[QliqGroupDBService sharedService] getGroupWithId:parentQliqId];
        
        if (parentGroup == nil) {
            QliqGroup *parentGroup = [[QliqGroup alloc] init];
            parentGroup.qliqId = parentQliqId;
            parentGroup.name = [parentGroupDict objectForKey:NAME];
            parentGroup.acronym = [parentGroupDict objectForKey:ACRONYM];
            
            if (saveInDb && ![[QliqGroupDBService sharedService] saveGroup:parentGroup]){
                DDLogError(@"Cant save group: %@", parentGroup);
                parentGroup = nil;
            }
        }
        if (parentGroup != nil) {
            group.parentQliqId = parentGroup.qliqId;
        }
    }
    group.qliqId = [thisGroup objectForKey:QLIQ_ID];
    group.name = [thisGroup objectForKey:NAME];
    group.acronym =  [thisGroup objectForKey:ACRONYM];
    group.address = [thisGroup objectForKey:ADDRESS];
    group.city = [thisGroup objectForKey:CITY];
    group.state = [thisGroup objectForKey:STATE];
    group.zip= [thisGroup objectForKey:ZIP];
    group.phone = [thisGroup objectForKey:PHONE];
    group.fax = [thisGroup objectForKey:FAX];
    group.npi = [thisGroup objectForKey:NPI];
    group.taxonomyCode = [thisGroup objectForKey:TAXONOMY_CODE];
    group.accessType = [thisGroup objectForKey:ACCESS_TYPE];
    
    SipContactDBService *sipContactDBService = [[SipContactDBService alloc] init];
    // Load existing SipContact (if exists) to preserve keys
    SipContact *sipContact = [sipContactDBService sipContactForQliqId:group.qliqId];
    if (sipContact == nil) {
        sipContact = [[SipContact alloc] init];
        sipContact.qliqId = [thisGroup objectForKey:QLIQ_ID];
        sipContact.sipContactType = SipContactTypeGroup;
    }
    sipContact.sipUri = [thisGroup objectForKey:SIP_URI];
    
    if (saveInDb) {
        [sipContactDBService save:sipContact completion:nil];
        
        if(![[QliqGroupDBService sharedService] saveGroup:group]){
            DDLogError(@"Cant save group: %@", group);
        }
    }
    
    if (saveInDb)
        DDLogSupport(@"GET GROUP INFO: processing finished");
    
    return group;
}

#pragma mark - Private

- (void)getGroupInfoRequestFinished:(NSString *)responseString forQliqId:(NSString *)qliqId withCompletion:(void(^)(QliqGroup *group, NSError *error))completeBlock {
    
    QliqGroup *group = nil;
    NSError *error = nil;
    NSString *reason = nil;
    int errorCode = 0;

    if ([responseString length] == 0) {
        reason = @"Cannot contact server";
        errorCode = -1;
    }
    else {
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSDictionary *getGroupInfoData = [jsonKitDecoder objectWithData:jsonData error:&error];
        NSDictionary *errorDict = [[getGroupInfoData valueForKey:MESSAGE] valueForKey:ERROR];
        
        if (errorDict) {
            reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
            errorCode = [[errorDict objectForKey:ERROR_CODE] intValue];
            
            if (errorCode == 0) {
                DDLogError(@"Cannot read error_code from web response: '%@'", responseString);
                errorCode = -3;
            }
            
            if (errorCode == ErrorCodeStaleData || errorCode == ErrorCodeNotContact) {
                [[QliqGroupDBService sharedService] safeDeleteUsersForGroupID:qliqId];
                [[QliqGroupDBService sharedService] safeDeleteGroup:qliqId];
            }
        }
        else if (![self groupInfoValid:responseString]) {
            reason = @"Invalid respoonse from server";
            errorCode = -2;
        }
        else {
            NSDictionary *getGroupInfo = [[getGroupInfoData valueForKey:MESSAGE] valueForKey:DATA];
            group = [GetGroupInfoService parseGroupJson:getGroupInfo andSaveInDb:YES];
            if (group == nil) {
                reason = @"BUG: Cannot parse group";
                errorCode = -4;
            }
        }
    }
    
	if (reason) {
        DDLogError(@"Cannot get_group_info: code: %d, error: %@", errorCode, reason);
		[self.delegate didFailToGetGroupInfoWithReason:reason];
    }
    else {
        [self.delegate getGroupInfoSuccess];
    }
    
    //AII When Add Subgroup on Server, group is parsed but not save to DB
    
    /* Call block
     */
    if (completeBlock) {
        if (errorCode != 0) {
            error = [NSError errorWithDomain:@"com.qliq.getGroupInfoService" code:errorCode userInfo:userInfoWithDescription(reason)];
        }
        completeBlock(group, error);
    }
}

- (BOOL)groupInfoValid:(NSString *)groupInfoJson
{
    BOOL rez = YES;
    rez &= [groupInfoJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:groupInfoJson embeddedSchema:GetGroupInfoResponseSchema];
    rez &= validJson;
	
    return rez;
}

@end

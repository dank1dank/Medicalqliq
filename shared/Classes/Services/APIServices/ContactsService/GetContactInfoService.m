//
//  GetContactInfo.m
//  qliq
//
//  Created by Ravi Ada on 08/01/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetContactInfoService.h"
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
#import "AppDelegate.h"

#import "DBUtil.h"
#import "SipContactDBService.h"
#import "AvatarDownloadService.h"

@interface GetContactInfoService()
-(BOOL) contactInfoValid:(NSString *)contactInfoJson;
-(BOOL) storeContactInfo:(NSDictionary *)dataDict;
-(void) processResponseString:(NSString *)responseString forQliqId:(NSString *)qliqId completitionBlock:(void(^)(QliqUser *, NSError * error))completeBlock;

@end

@implementation GetContactInfoService

+ (GetContactInfoService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetContactInfoService alloc] init];
        
    });
    return shared;
}

- (void)getInfoForContact:(Contact *)contact withReason:(NSString*)reason conpletionBlock:(void(^)(QliqUser *contact, NSError *error))completionBlock {

    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    
    NSMutableDictionary *contentDict = [@{PASSWORD : password,
                                          USERNAME : username} mutableCopy];
    
    if ([contact isKindOfClass:[QliqUser class]] || contact.contactType == ContactTypeIPhoneContact) {
        if (contact.mobile.length) {
            
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&error];
            NSString *contactMobile = [regex stringByReplacingMatchesInString:contact.mobile
                                                                      options:0
                                                                        range:NSMakeRange(0, contact.mobile.length)
                                                                 withTemplate:@""];
            contentDict[MOBILE] = contactMobile;
        }
    }
    
    if (contact.email.length)
        contentDict[EMAIL] = contact.email;
    if (reason) {
        contentDict[REASON] = reason;
    }
    
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA, nil];
    
    
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE, nil];
    
    
    
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]) {
        
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType path:@"services/get_contact_info" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            
			 [self processResponseString:responseString forQliqId:nil completitionBlock:completionBlock];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserConfigDidRefreshedNotification object:nil];
		 } onError:^(NSError* error) {
             
             if (completionBlock)
                 completionBlock(nil, error);
		 }];
	}
    else {
        if (completionBlock) {
            completionBlock(nil, [NSError errorWithDomain:@"com.qliq.getContactInfoService" code:GetContactInfoErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"GetContactInfo: Invalid request sent to server")]);
        }
	}
}

- (void)getContactInfo:(NSString *)qliqId completitionBlock:(void(^)(QliqUser *contact, NSError * error))completeBlock {
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 qliqId,QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]) {
        RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType path:@"services/get_contact_info" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
            [self processResponseString:responseString forQliqId:qliqId completitionBlock:completeBlock];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserConfigDidRefreshedNotification object:nil];
        } onError:^(NSError *error) {
            
            if (completeBlock) {
                completeBlock(nil, error);
            }
        }];
	}
    else {
        NSError *error = [NSError errorWithDomain:@"com.qliq.getContactInfoService"
                                             code:GetContactInfoErrorCodeInvalidRequest
                                         userInfo:userInfoWithDescription(@"GetContactInfo: Invalid request sent to server")];
        if (completeBlock) {
            completeBlock(nil, error);
        }
	}
}

-(void) getContactInfo:(NSString*) qliqId
{
    [self getContactInfo:qliqId completitionBlock:nil];
    
}

- (void)getContactByEmail:(NSString*)email completitionBlock:(void(^)(QliqUser *contact, NSError *error))completeBlock {
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 email, EMAIL, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType path:@"services/get_contact_info" jsonToPost:jsonDict onCompletion:^(NSString *responseString) {
                            
			 [self processResponseString:responseString forQliqId:nil completitionBlock:completeBlock];
            
		 } onError:^(NSError* error) {
             
             if (completeBlock) completeBlock(nil, error);
		 }];
	}else{
        if (completeBlock) completeBlock(nil, [NSError errorWithDomain:@"com.qliq.getContactInfoService" code:GetContactInfoErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"GetContactInfo: Invalid request sent to server")]);
	}
}

- (void)getContactByPhone:(NSString*)phone completitionBlock:(void(^)(QliqUser *contact, NSError *error))completeBlock {
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
	
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *contactMobile = [regex stringByReplacingMatchesInString:phone
                                                              options:0
                                                                range:NSMakeRange(0, phone.length)
                                                         withTemplate:@""];
    
    //TODO: get the appversion from user defaults or plist, and device UUID, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 contactMobile, MOBILE, nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactInfoRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_contact_info"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString)
		 {
			 [self processResponseString:responseString forQliqId:nil completitionBlock:completeBlock];
		 }
							 onError:^(NSError* error)
		 {
             if (completeBlock) completeBlock(nil, error);
		 }];
	}else{
        if (completeBlock) completeBlock(nil, [NSError errorWithDomain:@"com.qliq.getContactInfoService" code:GetContactInfoErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"GetContactInfo: Invalid request sent to server")]);
	}
}

#pragma mark -
#pragma mark Private

-(void) processResponseString:(NSString *)responseString forQliqId:(NSString *)qliqId completitionBlock:(void (^)(QliqUser *, NSError *))completeBlock
{
    NSStringEncoding dataEncoding = NSUTF8StringEncoding;
    NSError *error=nil;
    NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSDictionary *getContactInfoMessage = [jsonKitDecoder objectWithData:jsonData error:&error];
    NSDictionary *errorDict = [[getContactInfoMessage valueForKey:MESSAGE] valueForKey:ERROR];
    
    if (errorDict != nil)
    {
        QliqUser *contact = nil;
        DDLogError(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
        NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
        NSString *errorCodeStr = [errorDict objectForKey:ERROR_CODE];
        int errorCode = [errorCodeStr intValue];
        
        //If server returned error, that means that contact is removed and we will remove him from db
        if (errorCode == ErrorCodeStaleData || errorCode == ErrorCodeNotContact) {
            if (qliqId) {
                QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
                if (user) {
                    [[QliqUserDBService sharedService] setUserDeleted:user];
                }
            }
            //            Contact *contact = [[ContactService sharedService] getContactByQliqId:qliqId];
            //            if (contact) {
            //                [[ContactService sharedService] deleteContact:contact];
            //                [[ContactService sharedService] notifyAboutNewContact:contact];
            //            }
            
            if (errorCode == ErrorCodeNotContact) {
                contact = [[QliqUser alloc] init];
                
                /*
                 * Service may return null instead of empty string
                 * So need to check parameters type
                 */
                if ([errorDict[FIRST_NAME] isKindOfClass:[NSString class]]) {
                    contact.firstName = errorDict[FIRST_NAME];
                } else {
                    contact.firstName = @"";
                }
                
                if ([errorDict[LAST_NAME] isKindOfClass:[NSString class]]) {
                    contact.lastName = errorDict[LAST_NAME];
                } else {
                    contact.lastName = @"";
                }
                
                if ([errorDict[TITLE] isKindOfClass:[NSString class]]) {
                    contact.profession = errorDict[TITLE];
                } else {
                    contact.profession = @"";
                }
                
                if ([errorDict[ORGANIZATION] isKindOfClass:[NSString class]]) {
                    contact.organization = errorDict[ORGANIZATION];
                } else {
                    contact.organization = @"";
                }
                
                if (errorDict[AVATAR_URL]) {
                    AvatarDownloadService *service = [[AvatarDownloadService alloc] initWithUser:contact andUrlString:errorDict[AVATAR_URL]];
                    
                    [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                        if (CompletitionStatusSuccess == status) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateContactsAvatarNotificationName
                                                                                object:nil
                                                                              userInfo:@{@"contact":contact}];
                        }
                    }];
                }
            }
        }
        
        if (completeBlock) completeBlock(contact, [NSError errorWithDomain:@"com.qliq.getContactInfoService" code:errorCode userInfo:userInfoWithDescription(reason)]);
        return;
    }
    
    DDLogInfo(@"get contact info response: %@",getContactInfoMessage);
    
    if(![self contactInfoValid:responseString])
    {
        NSString *reason = [NSString stringWithFormat:@"Invalid contact info"];
        if (completeBlock) completeBlock(nil, [NSError errorWithDomain:@"com.qliq.getContactInfoService" code:GetContactInfoErrorCodeInvalidInfo userInfo:userInfoWithDescription(reason)]);
        return;
    }
    
    NSDictionary *getContactInfo = [[getContactInfoMessage valueForKey:MESSAGE] valueForKey:DATA];
    [self storeContactInfo:getContactInfo];
    
    QliqUser *user = nil;
    if (getContactInfo[QLIQ_USER][QLIQ_ID])
        user = [[QliqUserDBService sharedService] getUserWithId:getContactInfo[QLIQ_USER][QLIQ_ID]];

    if (completeBlock && user) {
        completeBlock(user, nil);
        
    } else if (completeBlock) {
        DDLogSupport(@"Error. DB does not contain user with qliqID:%@",getContactInfo[QLIQ_USER][QLIQ_ID]);
        
        error = [NSError errorWithCode:ErrorCodeStaleData description:@"DB does not contain invited user"];
        completeBlock(nil, error);
    }
}


-(BOOL) contactInfoValid:(NSString *)contactInfoJson
{
    BOOL rez = YES;
    rez &= [contactInfoJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:contactInfoJson embeddedSchema:GetContactInfoResponseSchema];
    rez &= validJson;
	
    return rez;
}

- (void) saveSipContactFromUserDict:(NSDictionary *) userInfoDict{
    SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
    SipContact * sipContact = [[SipContact alloc] init];
    sipContact.qliqId = [userInfoDict objectForKey:QLIQ_ID];
    sipContact.sipUri = [userInfoDict objectForKey:SIP_URI];
    sipContact.sipContactType = SipContactTypeUser;
    [sipContactService save:sipContact completion:nil];
}

-(BOOL) storeContactInfo:(NSDictionary *)dataDict
{
	DDLogSupport(@"GET CONTACT INFO : processing started");
	
    BOOL success = YES;
	
	DDLogInfo(@"Data %@",dataDict);

	NSMutableDictionary *userInfoDict = [dataDict objectForKey:QLIQ_USER];
    [[QliqUserDBService sharedService] saveContactFromJsonDictionary:userInfoDict andNotifyAboutNew:YES];
    
	DDLogSupport(@"GET CONTACT INFO : processing finished");
	return success;
}
@end

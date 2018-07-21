//
//  FindQliqUser.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "FindQliqUser.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"

#import "ContactDBService.h"

#import "QliqUser.h"
#import "QliqUserDBService.h"

@interface FindQliqUser()


- (BOOL) findQliqUserValid:(NSString *)findQliqUserJson;
- (BOOL) isQliqUserInResponceString:(NSString *) responseString;

- (QliqUser *) qliqUserForResponceString:(NSString *) responseString andContact:(Contact *)contact;

- (void) processContactDictionary:(NSDictionary *) contactsDict withResponceString:(NSString *) responseString completitionBlock:(void(^)(NSError *))block;

@end

@implementation FindQliqUser


+ (FindQliqUser *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[FindQliqUser alloc] init];
        
    });
    return shared;
}

- (void) getQliqUserForContact:(Contact *) contact completition:(void(^)(QliqUser * user, NSError * error)) block{
    if (contact.mobile.length == 0 && contact.email.length == 0){
        if (block) block(nil,nil);
        return;
    }
    
    UserSession *currentSession = [UserSessionService currentUserSession]; 
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;            
	
    //TODO: get the qliq_id, device UUID and, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 contact.email, RECIPIENT_EMAIL,
								 contact.mobile, RECIPIENT_VERIFIED_MOBILE,
								 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:FindQliqUserRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/find_qliq_user"
						  jsonToPost:jsonDict 
						onCompletion:^(NSString *responseString)
		 {
			 QliqUser * qliqUser = [self qliqUserForResponceString:responseString andContact:contact];
             if (block) block(qliqUser, nil);
		 } 
							 onError:^(NSError* error)
		 {
             if (block) block(nil, error);
		 }];
	}else{
		DDLogSupport(@"IsQliqMemberService: Invalid request sent to server");
	}
}


- (void) checkForQliqUserContact:(Contact *) contact completition:(void(^)(BOOL isMember, NSError * error)) block{
    
    if (contact.mobile.length == 0 && contact.email.length == 0){
        if (block) block(NO,nil);
        return;
    }
    
    UserSession *currentSession = [UserSessionService currentUserSession]; 
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;            
	
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 contact.email, RECIPIENT_EMAIL,
								 contact.mobile, RECIPIENT_VERIFIED_MOBILE,
								 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:FindQliqUserRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/find_qliq_user"
						  jsonToPost:jsonDict 
						onCompletion:^(NSString *responseString)
		 {
			 BOOL isQliqUser = [self isQliqUserInResponceString:responseString];
             if (block) block(isQliqUser, nil);
		 } 
							 onError:^(NSError* error)
		 {
             if (block) block(NO, error);
		 }];
	}else{
		DDLogSupport(@"IsQliqMemberService: Invalid request sent to server");
	}
}

- (NSDictionary *) contactsDictionaryFromArray:(NSArray *) array{
    NSMutableArray * keys = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (Contact * contact in array){
        [keys addObject:[NSString stringWithFormat:@"%ld",(long)contact.contactId]];
    }
    return [NSDictionary dictionaryWithObjects:array forKeys:keys];
}

- (void) checkForQliqUsers:(NSArray *) contactsArray completitionBlock:(void(^)(NSError *))block
{
    
    UserSession *currentSession = [UserSessionService currentUserSession]; 
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password; 
    
    NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:[contactsArray count]]; 
    
    NSDictionary * contactsDict = [self contactsDictionaryFromArray:contactsArray];
    for ( NSString * contactId in [contactsDict allKeys]){
        NSMutableDictionary * contactJSONDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:contactId, CONTACT_ID, nil];
        Contact * contact = [contactsDict objectForKey:contactId];
        if (contact.email.length > 0) 
            [contactJSONDict setValue:contact.email forKey:EMAIL];
        
        if (contact.mobile.length > 0) 
            [contactJSONDict setValue:contact.mobile forKey:MOBILE];
        
        if (contact.contactType != ContactTypeQliqUser && (contact.mobile.length > 0 || contact.email.length > 0))
            [contacts addObject:contactJSONDict];   
    }
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 password, PASSWORD,
                                 username, USERNAME,
                                 contacts, CONTACTS,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              contentDict, DATA,
                              nil];
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    
    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:FindAllQliqUsersRequestSchema]){
        RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/find_all_qliq_users"
                          jsonToPost:jsonDict 
                        onCompletion:^(NSString *responseString)
         {
             
             [self processContactDictionary:contactsDict withResponceString:responseString completitionBlock:block];
             
         } 
                             onError:^(NSError* error)
         {
             block(error);
         }];
    }else{
        block([NSError errorWithDomain:errorDomainForModule(@"FindQliqUser") code:1 userInfo:userInfoWithDescription(@"IsQliqMemberService: Invalid request sent to server")]);
    }
	
}




#pragma mark -
#pragma mark Private

- (void) processContactDictionary:(NSDictionary *) contactsDict withResponceString:(NSString *) responseString completitionBlock:(void(^)(NSError *))block{
    
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:nil] objectForKey:MESSAGE];
    NSMutableDictionary * data = [message valueForKey:DATA];
    NSMutableDictionary * contacts = [data valueForKey:CONTACTS];
    
    if (!contacts){
        block([NSError errorWithDomain:errorDomainForModule(@"FindQliqUser") code:1 userInfo:userInfoWithDescription(@"Response haven't \"contacts\" key")]);
        return;
    }
    
    for (NSDictionary * contact in contacts){
        Contact * qliq_member_contact = [contactsDict valueForKey:[contact valueForKey:CONTACT_ID]];
        qliq_member_contact.contactType = ContactTypeQliqUser;
		qliq_member_contact.qliqId = [contact valueForKey:QLIQ_ID];
        if ([[QliqUserDBService sharedService] getUserWithId:[contact valueForKey:QLIQ_ID]]){
            qliq_member_contact.contactType = ContactTypeQliqDuplicate;
        }

        if (![[ContactDBService sharedService] saveContact:qliq_member_contact]){
            NSString * description = [NSString stringWithFormat:@"Can't save contact with ID: %ld",(long)qliq_member_contact.contactId];
            block([NSError errorWithDomain:errorDomainForModule(@"FindQliqUser") code:1 userInfo:userInfoWithDescription(description)]);
            return;
        }
        NSLog(@"%@ is qliq member",qliq_member_contact.email);
    }
    block(nil);
}


- (QliqUser *) qliqUserForResponceString:(NSString *) responseString andContact:(Contact *)contact{
    
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
 	NSDictionary *errorDict = [message valueForKey:ERROR];
        
    if(errorDict != nil){
        
       // NSLog(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
        
	}else{
        
		if(![self findQliqUserValid:responseString]){
            DDLogSupport(@"Found user is invalid");
		}else{
			NSDictionary *getDataInfo = [message valueForKey:DATA];
			NSDictionary *userInfo = [getDataInfo valueForKey:USER];
			if(userInfo != nil){
                QliqUser * user = [[QliqUser alloc] init];
                
                user.qliqId = [userInfo valueForKey:QLIQ_ID];
                user.contactId = contact.contactId;
                user.contactStatus = contact.contactStatus;
                
                user.firstName = [userInfo valueForKey:FIRST_NAME];
                user.lastName = [userInfo valueForKey:LAST_NAME];
                user.middleName = [userInfo valueForKey:MIDDLE];
                user.phone =  [userInfo valueForKey:PHONE];
                user.mobile =  [userInfo valueForKey:MOBILE];
                user.email =  [userInfo valueForKey:PRIMARY_EMAIL];
                user.profession = [userInfo valueForKey:PROFESSION];
                user.credentials = [userInfo valueForKey:CREDENTIALS]; 
                user.fax = [userInfo valueForKey:FAX];
                user.address = [userInfo valueForKey:ADDRESS];
                user.city = [userInfo valueForKey:CITY];
                user.state = [userInfo valueForKey:STATE];
                user.zip = [userInfo valueForKey:ZIP];

                
				// - don't save qliq user to qliq_user table until they are not accept invitation
                //[[QliqUserService sharedService] saveUser:user]; 

                return user;
			}
		}
	}
    return nil;
    
}

- (BOOL) isQliqUserInResponceString:(NSString *) responseString{
    
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
 	NSDictionary *errorDict = [message valueForKey:ERROR];
    
	if(errorDict != nil)
	{
//		NSLog(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
		//NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
	} else{
		if(![self findQliqUserValid:responseString])
		{
//			NSString *reason = [NSString stringWithFormat:@"Invalid response info"];
//			NSLog(@"%@",reason);
		}else{
			NSDictionary *getDataInfo = [message valueForKey:DATA];
			NSDictionary *userInfo = [getDataInfo valueForKey:USER];
			if(userInfo != nil){
				NSString *qliqId = [userInfo valueForKey:QLIQ_ID];
				if(qliqId != nil){
                    return YES;
				}
			}
		}
	}
    return NO;
}

-(BOOL) findQliqUserValid:(NSString *)findQliqUserJson
{
    BOOL rez = YES;
    rez &= [findQliqUserJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:findQliqUserJson embeddedSchema:FindQliqUserResponseSchema];
    rez &= validJson;
	
    return rez;
}

@end

//
//  GetUserConfigService.m
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetUserConfigService.h"
#import "QliqApiManager.h"
#import "JSONKit.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONSchemaValidator.h"
#import "QliqUser.h"
#import "QliqGroup.h"
#import "QliqSip.h"
#import "QliqUserDBService.h"
#import "QliqGroupDBService.h"
#import "SipServerInfo.h"
#import "UserSettingsService.h"
#import "RestClient.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "SipAccountSettings.h"
#import "Metadata.h"
#import "Contact.h"
#import "ContactDBService.h"
#import "AvatarDownloadService.h"
#import "GetGroupContactsPagedService.h"
#import "DBUtil.h"
#import "SipContactDBService.h"
#import "UIDevice+UUID.h"
#import "NotificationUtils.h"
#import "GetContactsPaged.h"

#import <AddressBook/AddressBook.h>

#define errorDomain @"com.qliq.GetUserConfigService"

NSString *UserConfigDidRefreshedNotification = @"UserConfigDidRefreshedNotification";
NSString *SipServerFqdnChangedKey = @"SipServerFqdnChanged";
NSString *SipServerConfigChangedKey = @"SipServerConfigChanged";

@interface GetUserConfigService(Private)

- (void)getUserConfigRequestFinished:(NSString *)responseString
                   completitionBlock:(CompletionBlock)completition
                callGetGroupContacts:(BOOL)callGetGroupContacts;

- (BOOL)userConfigValid:(NSString *)userDetailsJson;

- (BOOL)storeUserConfig:(NSDictionary *)dataDict callGetGroupContacts:(BOOL)callGetGroupContacts hasSipServerFqdnChanged:(BOOL *)aHasSipServerFqdnChanged hasSipServerConfigChanged:(BOOL *)aHasSipServerConfigChanged;

@end


@implementation GetUserConfigService

@synthesize delegate;

+ (GetUserConfigService *)sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetUserConfigService alloc] init];
    });
    return shared;
}

#pragma mark - Public

- (void)getUserConfig:(BOOL)callGetGroupContacts {
    [self getUserConfig:callGetGroupContacts withCompletitionBlock:nil];
}

- (void)getUserConfig:(BOOL)callGetGroupContacts withCompletitionBlock:(CompletionBlock) completition {
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    
    BOOL empty_database = [[DBUtil sharedInstance] isNewDatabase];
    
    NSDictionary *contentDict = @{PASSWORD : password,
                                  USERNAME : username,
                                  DEVICE_UUID : deviceUUID,
                                  EMPTY_DATABASE : @(empty_database)};
    NSDictionary *dataDict = @{DATA : contentDict};
    NSDictionary *jsonDict = @{MESSAGE : dataDict};
    
    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetUserConfigRequestSchema]) {
        
        RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_user_config"
                          jsonToPost:jsonDict
                        onCompletion:^(NSString *responseString)
         {
             [self getUserConfigRequestFinished:responseString
                              completitionBlock:completition
                           callGetGroupContacts:callGetGroupContacts];
             
         } onError:^(NSError *error) {
             if (completition) {
                 completition(CompletitionStatusError, nil, error);
             }
         }];
    }
    else {
        NSError *error = [NSError errorWithDomain:errorDomain
                                             code:0
                                         userInfo:userInfoWithDescription(@"GetUserConfigService: Invalid request sent to server")];
        if (completition) {
            completition(CompletitionStatusError, nil, error);
        }
    }
}

- (void)getUserConfigFromDB {
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    currentSession.sipAccountSettings.serverInfo = [[[SipServerInfo getSipServerInfo] objectEnumerator] nextObject];
    
    NSString * qliqId = currentSession.user.qliqId;
    SipContact *me = [[[SipContactDBService alloc] init] sipContactForQliqId:qliqId];
    currentSession.sipAccountSettings.sipUri = me.sipUri;

    [Metadata setDefaultAuthor:qliqId];
    
    //Fill .user only if it was not previously set
    if (nil == currentSession.user) {
        currentSession.user = [[QliqUserDBService sharedService] getUserWithId:qliqId]; // fill all fields from db
    }
}

+ (SipServerInfo *)parseAndSaveSipServerInfo:(NSDictionary *)sipServerDict
                     hasSipServerFqdnChanged:(BOOL *)aHasSipServerFqdnChanged
                   hasSipServerConfigChanged:(BOOL *)aHasSipServerConfigChanged {
    
    DDLogSupport(@"sip-url %@",[sipServerDict objectForKey:URL]);
    
    SipServerInfo *previousSipServer = [SipServerInfo getRecentSipServerInfo];
    
    //adding sip server configuration
    SipServerInfo *sipServerObj = [[SipServerInfo alloc] init];
    sipServerObj.fqdn = [sipServerDict objectForKey:URL];
    sipServerObj.port = [[sipServerDict objectForKey:PORT] intValue];
    sipServerObj.transport = [sipServerDict objectForKey:TRANSPORT];
    sipServerObj.multiDevice = [[sipServerDict objectForKey:MULTI_DEVICE] boolValue];
    
    // Delete old SIP configuration so we keep only 1 server in db
    [SipServerInfo deleteAllSipServerInfo];
    [SipServerInfo addSipServerInfo:sipServerObj];
    
    if (previousSipServer == nil) {
        *aHasSipServerFqdnChanged = NO;
        *aHasSipServerConfigChanged = NO;
    }
    else {
        *aHasSipServerFqdnChanged = ![sipServerObj.fqdn isEqualToString:previousSipServer.fqdn];
    
        if (*aHasSipServerFqdnChanged) {
            *aHasSipServerConfigChanged = YES;
        }
        else {
            *aHasSipServerConfigChanged = (sipServerObj.port != previousSipServer.port) ||
            (![sipServerObj.transport isEqualToString:previousSipServer.transport]);
        }
    }
    
    return sipServerObj;
}

+ (QliqUser *)parseAndSaveUser:(NSDictionary *)userInfoDict {
    
    QliqUser *loggingUser = [UserSessionService currentUserSession].user;
    loggingUser.email           = [userInfoDict objectForKey:PRIMARY_EMAIL];
    loggingUser.firstName       = [userInfoDict objectForKey:FIRST_NAME];
    loggingUser.middleName      = [userInfoDict objectForKey:MIDDLE];
    loggingUser.lastName        = [userInfoDict objectForKey:LAST_NAME];
    loggingUser.address         = [userInfoDict objectForKey:ADDRESS];
    loggingUser.city            = [userInfoDict objectForKey:CITY];
    loggingUser.state           = [userInfoDict objectForKey:STATE];
    loggingUser.zip             = [userInfoDict objectForKey:ZIP];
    loggingUser.mobile          = [userInfoDict objectForKey:MOBILE];
    loggingUser.phone           = [userInfoDict objectForKey:PHONE];
    loggingUser.fax             = [userInfoDict objectForKey:FAX];
    loggingUser.qliqId          = [userInfoDict objectForKey:QLIQ_ID];
    loggingUser.profession      = [userInfoDict objectForKey:PROFESSION];
    loggingUser.credentials     = [userInfoDict objectForKey:CREDENTIALS];
    loggingUser.taxonomyCode    = [userInfoDict objectForKey:TAXONOMY_CODE];
    loggingUser.organization    = [userInfoDict objectForKey:ORGANIZATION];
    loggingUser.npi             = [userInfoDict objectForKey:NPI];
    loggingUser.isPagerUser     = [[userInfoDict objectForKey:PAGER_USER] boolValue];
    loggingUser.pagerInfo       = [userInfoDict objectForKey:PAGER_INFO];
    
    [UserSessionService currentUserSession].user = loggingUser;
    
    UserSessionService *session = [[UserSessionService alloc] init];
    [session saveLastLoggedInUser:loggingUser];
    [session saveLastUserSession:[UserSessionService currentUserSession]];
    
    /* Save SIP-related info about logged user */
    [GetUserConfigService saveSipContactWithQliqId:loggingUser.qliqId
                                         andSipURI:[userInfoDict objectForKey:SIP_URI]
                                              type:SipContactTypeUser];
    
    if(![[QliqUserDBService sharedService] saveUser:loggingUser]) {
        DDLogError(@"Cant save logging user: %@", loggingUser);
    }
    
    NSString *avatarURLString = [userInfoDict objectForKey:AVATAR_URL];

    AvatarDownloadService *avatarService = [[AvatarDownloadService alloc] initWithUser:loggingUser andUrlString:avatarURLString];
    [avatarService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        DDLogError(@"service: %d, error: %@",status, error);
    }];
    
    return loggingUser;
}


#pragma mark - Private

- (void)getUserConfigRequestFinished:(NSString *)responseString
                   completitionBlock:(CompletionBlock)completition
                callGetGroupContacts:(BOOL)callGetGroupContacts {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSStringEncoding dataEncoding = NSUTF8StringEncoding;
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSDictionary *getUserConfigData = [jsonKitDecoder objectWithData:jsonData error:&error];
        NSDictionary *errorDict = [[getUserConfigData valueForKey:MESSAGE] valueForKey:ERROR];
        
        if(errorDict != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogError(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
                
                NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
                if (completition) {
                    completition(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:1 userInfo:userInfoWithDescription(reason)]);
                }
            });
            
            return;
        }
        
        if(![self userConfigValid:responseString]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *reason = @"Invalid user config";
                if (completition) {
                    completition(CompletitionStatusError, nil, [NSError errorWithDomain:errorDomain code:2 userInfo:userInfoWithDescription(reason)]);
                }
            });
            
            return;
        }
        
        NSDictionary *getUserConfig = [[getUserConfigData valueForKey:MESSAGE] valueForKey:DATA];
        BOOL hasSipServerFqdnChanged = NO;
        BOOL hasSipServerConfigChanged = NO;
        
        [self storeUserConfig:getUserConfig callGetGroupContacts:callGetGroupContacts hasSipServerFqdnChanged:&hasSipServerFqdnChanged hasSipServerConfigChanged:&hasSipServerConfigChanged completitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSDictionary *dict = @{SipServerFqdnChangedKey : [NSNumber numberWithBool:hasSipServerFqdnChanged],
                                           SipServerConfigChangedKey : [NSNumber numberWithBool:hasSipServerConfigChanged]};
                    if (completition) {
                        completition(CompletitionStatusSuccess, dict, nil);
                    }
                });
            }
        }];
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:UserConfigDidRefreshedNotification object:nil userInfo:nil];
    });
}

- (BOOL)userConfigValid:(NSString *)userConfigJson
{
    BOOL rez = YES;
    rez &= [userConfigJson length] > 0;
    
    BOOL validJson = [JSONSchemaValidator validate:userConfigJson embeddedSchema:GetUserConfigResponseSchema];
    rez &= validJson;
	
    return rez;
}

+ (void)saveSipContactWithQliqId:(NSString *)qliqId andSipURI:(NSString *)sipUri type:(SipContactType)type {

    SipContactDBService *sipContactDBService = [[SipContactDBService alloc] init];
    
    // Load existing SipContact (if exists) to preserve keys
    SipContact *sipContact = [sipContactDBService sipContactForQliqId:qliqId];
    if (sipContact == nil) {
        sipContact = [[SipContact alloc] init];
        sipContact.qliqId = qliqId;
    }
    
    //Saving sip related info
    sipContact.sipUri = sipUri;
    sipContact.sipContactType = type;
    [sipContactDBService save:sipContact completion:nil];
}

- (BOOL)storeUserConfig:(NSDictionary *)dataDict callGetGroupContacts:(BOOL)shouldCallGetGroupContacts hasSipServerFqdnChanged:(BOOL *)aHasSipServerFqdnChanged hasSipServerConfigChanged:(BOOL *)aHasSipServerConfigChanged completitionBlock:(CompletionBlock)completition{
    
	DDLogSupport(@"GET USER DETAILS: processing started");
	
    BOOL success = YES;
    
    UserSession *currentSession = [UserSessionService currentUserSession];	
	DDLogSupport(@"--> User Data \n\n%@",dataDict);
    
    if (!currentSession.userSettings.escalatedCallnotifyInfo) {
        currentSession.userSettings.escalatedCallnotifyInfo = [[EscalatedCallnotifyInfo alloc] init];
    }
    currentSession.userSettings.escalatedCallnotifyInfo.calleridNumber = dataDict[ESCALATED_CALLNOTIFY_INFO][CALLERID_NUMBER];
    currentSession.userSettings.escalatedCallnotifyInfo.calleridName = dataDict[ESCALATED_CALLNOTIFY_INFO][CALLERID_NAME];
    currentSession.userSettings.escalatedCallnotifyInfo.escalationNumber = dataDict[ESCALATED_CALLNOTIFY_INFO][ESCALATION_NUMBER];
    currentSession.userSettings.escalatedCallnotifyInfo.escalateWeekends = [dataDict[ESCALATED_CALLNOTIFY_INFO][ESCALATE_WEEKENDS] boolValue];
    currentSession.userSettings.escalatedCallnotifyInfo.escalateWeeknights = [dataDict[ESCALATED_CALLNOTIFY_INFO][ESCALATE_WEEKNIGHTS] boolValue];
    currentSession.userSettings.escalatedCallnotifyInfo.escalateWeekdays = [dataDict[ESCALATED_CALLNOTIFY_INFO][ESCALATE_WEEKDAYS] boolValue];
    
    [UserSettingsService parseAndUpdateFeatureInfo:dataDict[FEATURES_INFO] forUserSettings:currentSession.userSettings];

    NSNumber *isCareChannelsIntegrated = [NSNumber numberWithBool:currentSession.userSettings.userFeatureInfo.isCareChannelsIntegrated];
    [NSNotificationCenter postNotificationToMainThread:@"IsCareChannelIntegrated" withObject:isCareChannelsIntegrated];
    
    
	NSMutableArray *groupsArray = [dataDict objectForKey:QLIQ_GROUPS];
	
    NSMutableDictionary *sipServerDict = [dataDict objectForKey:SIP_SERVER_INFO];
    
    SipServerInfo *sipServerInfo = [GetUserConfigService parseAndSaveSipServerInfo:sipServerDict
                                                           hasSipServerFqdnChanged:aHasSipServerFqdnChanged
                                                         hasSipServerConfigChanged:aHasSipServerConfigChanged];
    currentSession.sipAccountSettings.serverInfo = sipServerInfo;
    
    [UserSessionService saveFileServerInfo:dataDict];
    
    //saving the contact and user
    NSMutableDictionary *userInfoDict = [dataDict objectForKey:USER];
    QliqUser *loggingUser = [GetUserConfigService parseAndSaveUser:userInfoDict];
    
    if (loggingUser.mobile.length) {
        currentSession.userSettings.usersCallbackNumber = loggingUser.mobile;
    }

    [currentSession.userSettings write];
    [self escalatedCallnotifyInfo:dataDict];
    
    // Krishn 2/16/2017
    // We have three set
    // #1 Newly Added Groups
    // #2 Old Groups - means removed
    // #3 All Groups in the user_config
    //
    NSMutableSet *newGroupIds = [[NSMutableSet alloc] init];
    NSMutableSet *allOldGroupIds = [[NSMutableSet alloc] init];
    NSMutableSet *allGroupIds = [[NSMutableSet alloc] init];
    {
        NSArray *allOldGroups = [[QliqGroupDBService sharedService] getGroups];
        for (QliqGroup *group in allOldGroups) {
            [allOldGroupIds addObject:group.qliqId];
        }
    }
    
    //remove all group memberships first
    [[QliqGroupDBService sharedService] removeAllGroupMembershipsForUser:loggingUser.qliqId];

    for(NSMutableDictionary *thisGroup in groupsArray)
    {
        //NSDictionary *thisGroup = [groupDict objectForKey:GROUP];
        QliqGroup *group = [[QliqGroup alloc] init];
        NSDictionary *parentGroupDict = [thisGroup objectForKey:PARENT_GROUP];
        
        if(parentGroupDict != nil) {
            
            NSString *parentQliqId = [parentGroupDict objectForKey:QLIQ_ID];
            QliqGroup *parentGroup = [[QliqGroupDBService sharedService] getGroupWithId:parentQliqId];
            
            if (parentGroup == nil) {
                QliqGroup *parentGroup = [[QliqGroup alloc] init];
                parentGroup.qliqId      = [parentGroupDict objectForKey:QLIQ_ID];
                parentGroup.name        = [parentGroupDict objectForKey:NAME];
                parentGroup.acronym     = [parentGroupDict objectForKey:ACRONYM];
                parentGroup.accessType  = [thisGroup objectForKey:ACCESS_TYPE];
                
                if(![[QliqGroupDBService sharedService] saveGroup:parentGroup]) {
                    DDLogError(@"Cant save group: %@", parentGroup);
                    parentGroup = nil;
                }
                else {
                    [newGroupIds addObject:parentGroup.qliqId];
                }
            }
            else {
                
                //add the logging in user to group
                if(![[QliqGroupDBService sharedService] addUser:loggingUser toGroup:parentGroup]) {
                    DDLogError(@"Cant add user: %@ to group: %@", loggingUser, parentGroup);
                }
                group.parentQliqId = parentGroup.qliqId;
            }
        }
        
        group.qliqId = [thisGroup objectForKey:QLIQ_ID];
        group.name = [thisGroup objectForKey:NAME];
        group.acronym =  [thisGroup objectForKey:ACRONYM]; 
        group.address = [thisGroup objectForKey:ADDRESS];
        group.city = [thisGroup objectForKey:CITY];
        group.state = [thisGroup objectForKey:STATE];
        group.zip = [thisGroup objectForKey:ZIP];
        group.phone = [thisGroup objectForKey:PHONE];
        group.fax = [thisGroup objectForKey:FAX];
        group.npi = [thisGroup objectForKey:NPI];
        group.taxonomyCode = [thisGroup objectForKey:TAXONOMY_CODE];
        group.accessType = [thisGroup objectForKey:ACCESS_TYPE];
        group.openMembership = [[thisGroup objectForKey:OPEN_MEMBERSHIP] boolValue];
        group.belongs = [[thisGroup objectForKey:BELONGS] boolValue];
        group.canBroadcast = [[thisGroup objectForKey:CAN_BROADCAST] boolValue];
        group.canMessage = [[thisGroup objectForKey:CAN_GROUP_MESSAGE] boolValue];

        /* Save SIP-related info about group */
        [GetUserConfigService saveSipContactWithQliqId:group.qliqId andSipURI:[thisGroup objectForKey:SIP_URI] type:SipContactTypeGroup];
        
        if(![[QliqGroupDBService sharedService] saveGroup:group]) {
            DDLogError(@"Cant save group: %@", group);
        }
        
        //add the logging in user to group
        if(![[QliqGroupDBService sharedService] addUser:loggingUser toGroup:group]) {
            DDLogError(@"Cant add user: %@ to group: %@", loggingUser, group);
        }
        
        NSDictionary *qliqStorDict = [thisGroup objectForKey:QLIQ_STOR_INFO];
        if (qliqStorDict != nil) {
            QliqUser *storUser = [[QliqUser alloc] init];
            storUser.qliqId = [qliqStorDict objectForKey:QLIQ_ID];
            storUser.email = [storUser.qliqId stringByAppendingString:@"@qliqstor.net"];
            storUser.status = QliqUserStateQliqStor;
            
            [[QliqUserDBService sharedService] saveUser:storUser];
            [[QliqGroupDBService sharedService] setQliqStorForGroup: group qliqStor:storUser];
            
            /* Save SIP-related info about storUser user */
            [GetUserConfigService saveSipContactWithQliqId:storUser.qliqId andSipURI:[qliqStorDict objectForKey:SIP_URI] type:SipContactTypeUser];
        }
        else {
            [[QliqGroupDBService sharedService] deleteQliqStorForGroup:group];
        }
        
        if ([allOldGroupIds containsObject:group.qliqId]) {
            [allOldGroupIds removeObject:group.qliqId];
        } else {
            [newGroupIds addObject:group.qliqId];
        }
        [allGroupIds addObject:group.qliqId];
    }
    
    SipContact *me = [[[SipContactDBService alloc] init] sipContactForQliqId:loggingUser.qliqId];
    currentSession.sipAccountSettings.sipUri = me.sipUri;
    [Metadata setDefaultAuthor:loggingUser.qliqId];
    
    // Krishna - 2/16/2017
    // We need to mark all users who are through user_group relationship that
    // do not belonging to the list of groups
    // If the users are a contact through the user_groups in the past but
    // and are not related through newGroupIds, we must mark them "deleted".
    // This will take care of the issue when the user is removed from the Group
    // And all contacts through that group should be removed.
    //
    [[QliqUserDBService sharedService] updateStatusAsDeletedForUsersWithoutSharedGroups:me.qliqId];
    [[ContactDBService sharedService] updateStatusAsDeletedForContactsWithoutSharedGroups:me.qliqId];
    
    for (NSString *groupQliqId in allOldGroupIds) {
        // See above
        // [[QliqGroupDBService sharedService] safeDeleteUsersForGroupID:groupQliqId];

        //if deleted group has subgroups, subgroups deleted too.
        NSArray *subgroups = [[QliqGroupDBService sharedService] getSubGroupsWithParentId:groupQliqId];
        
        for (QliqGroup *subgroup in subgroups){
            [[QliqGroupDBService sharedService] safeDeleteGroup:subgroup.qliqId];
        }
        [[QliqGroupDBService sharedService] safeDeleteGroup:groupQliqId];
    }
    
    if (shouldCallGetGroupContacts) {
       
        for (NSString *groupQliqId in newGroupIds) {
            
            dispatch_async_background(^{
                [[[GetGroupContactsPagedService alloc] init] getGroupContactsForQliqId:groupQliqId withCompletition:^(CompletitionStatus status, id result, NSError *error){
                    [NSNotificationCenter postNotificationToMainThread:UserConfigDidRefreshedNotification withObject:nil userInfo:nil];
                }];
            });
        }
    }
    
    [NSNotificationCenter postNotificationToMainThread:UserConfigDidRefreshedNotification withObject:nil userInfo:nil];
 
    DDLogSupport(@"GET USER DETAILS: processing finished");
    success = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completition) {
            completition(CompletitionStatusSuccess, nil, nil);
        }
    });
	return success;
}

#pragma mark - EscalatedCallnotifyInfo -

- (void)escalatedCallnotifyInfo:(NSDictionary*)info {
    
    [self getAddressBookInfoCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
        
        NSArray *phones = (NSArray*)result;
        
        NSString *phone = [info[@"escalated_callnotify_info"][@"callerid_number"] stringValue];
        NSString *fName = info[@"escalated_callnotify_info"][@"callerid_name"];
        
        if (phone.length) {
            
            if (![phones containsObject:phone]) {
                
                
                ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL); // create address book record
                ABRecordRef person = ABPersonCreate(); // create a person
                
                //Phone number is a list of phone number, so create a multivalue
                ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABPersonPhoneProperty);
                ABMultiValueAddValueAndLabel(phoneNumberMultiValue ,(__bridge CFTypeRef)(phone),kABPersonPhoneMainLabel, NULL);
                
                ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(fName) , nil); // first name of the new person
                ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil); // set the phone number property
                
                ABRecordSetValue(person,  kABPersonKindProperty, kABPersonKindOrganization, nil); // THe contact type will be organization
                //ABRecordSetValue(person, kABPersonOrganizationProperty, @"qliqSOFT, Inc", nil); // Organization Name
                
                //URL is a list of URLs, so create a multivalue
                ABMutableMultiValueRef urlMultiValue = ABMultiValueCreateMutable(kABPersonURLProperty);
                ABMultiValueAddValueAndLabel(urlMultiValue ,(__bridge CFTypeRef)(@"qliqsoft.com"),kABPersonHomePageLabel, NULL);

                ABRecordSetValue(person, kABPersonURLProperty, urlMultiValue, nil); // URL
                
                ABRecordSetValue(person, kABPersonNoteProperty, @"This contact is added by Qliq Secure Textng App. You will receive a call from this contact when there is a pending message on the server. You should open the app to check for messages. If you see a missed call from this number, please do not call back.", nil);
                ABAddressBookAddRecord(addressBook, person, nil); //add the new person to the record
                
                
                ABAddressBookSave(addressBook, nil); //save the record
                
                CFRelease(urlMultiValue);
                //Crashing 'CFRelease(phoneNumberMultiValue);' - commented by Valerii Lider 05/15/2017
//                CFRelease(phoneNumberMultiValue);
                CFRelease(person); // relase the ABRecordRef  variable
                CFRelease(addressBook);
            }
        }
    }];
}

- (void)getAddressBookInfoCompletitionBlock:(CompletionBlock)completition
{
    NSMutableArray *arrayCompliteAddressBook = [ @[] mutableCopy ];
    
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(nil, nil);
    
    if (&ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            
            if (granted) {
                
                CFArrayRef people  = ABAddressBookCopyArrayOfAllPeople(addressBook);
                
                for(int i = 0;i < CFArrayGetCount(people); i++)
                {
                    ABRecordRef person = CFArrayGetValueAtIndex(people, i);
                    if (person && CFArrayGetCount(people)) {
                        
                        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
                        //int countT = ABMultiValueGetCount(phones);
                        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
                        {
                            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                            NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
                            
                            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
                            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
                            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
                            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
                            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
                            [arrayCompliteAddressBook addObject:phoneNumber];
                            
                            CFRelease(phoneNumberRef);
                        }
                        CFRelease(phones);
                    }
                }
                CFRelease(people);
                
                completition(CompletitionStatusSuccess, arrayCompliteAddressBook, nil);
            }
        });
    }
}

@end

//
//  QliqUserService.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqUserDBService.h"
#import "Taxonomy.h"
#import "TaxonomyDbService.h"
#import "UserSessionService.h"
#import "UserSession.h"

#import "ContactDBService.h"

#import "AppDelegate.h"
#import "DBUtil.h"
#import "SipContactDBService.h"
#import "QliqGroupDBService.h"
#import "AvatarDownloadService.h"
#import "QliqJsonSchemaHeader.h"
#import "NotificationUtils.h"
#import "ABTimeCounter.h"

NSString *QliqUserDBServiceNotificationCurrentUserDidSaved = @"QliqUserDBServiceNotificationCurrentUserDidSaved";

@interface QliqUserDBService()

@property (nonatomic, strong) ABTimeCounter *saveUserCounter;
@property (nonatomic, strong) ABTimeCounter *saveContactCounter;
@property (nonatomic, strong) ABTimeCounter *deleteFromGroupCounter;
@property (nonatomic, strong) ABTimeCounter *saveGroupsCounter;
@property (nonatomic, strong) ABTimeCounter *userGetCounter;
@property (nonatomic, strong) ABTimeCounter *presenceCounter;
@property (nonatomic, strong) ABTimeCounter *avatarCounter;
@property (nonatomic, strong) ABTimeCounter *totalCounter;

- (NSUInteger) contactIdForQliqId:(NSString *) qlidId;

@end

@implementation QliqUserDBService

- (id) init
{
    self = [super init];
    if (self) {
        self.saveUserCounter = [ABTimeCounter new];
        self.saveContactCounter = [ABTimeCounter new];
        self.deleteFromGroupCounter = [ABTimeCounter new];
        self.saveGroupsCounter = [ABTimeCounter new];
        self.userGetCounter = [ABTimeCounter new];
        self.presenceCounter = [ABTimeCounter new];
        self.avatarCounter = [ABTimeCounter new];
        self.totalCounter = [ABTimeCounter new];
    }
    return self;
}

+ (QliqUserDBService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[QliqUserDBService alloc] init];
        
    });
    return shared;
}

- (BOOL) isCurrentUser:(QliqUser *)user
{
    return [[UserSessionService currentUserSession].user.qliqId isEqualToString:user.qliqId];
}

- (void) notifyCurrentUserChanged:(QliqUser *)user
{
    [NSNotificationCenter postNotificationToMainThread:QliqUserDBServiceNotificationCurrentUserDidSaved withObject:user];
}

- (BOOL) saveUser:(QliqUser *)qliqUser
{
    if (qliqUser.contactId == 0) {
        // The DBCoder's logic will create a duplicate in contact table unless we provide the contact_id
        Contact *existingContact = [[ContactDBService sharedService] getContactByQliqId:qliqUser.qliqId];
        if (existingContact != nil) {
            qliqUser.contactId = existingContact.contactId;
        }
    }
    
    __block BOOL success = YES;
   
    [self save:qliqUser completion:^(BOOL wasInserted, id objectId, NSError * error) {
        if (error){
            DDLogError(@"error while saving user: %@",error);
            success = NO;
        }
    }];
    
    if (success) {
        [[ContactDBService sharedService] saveContact:qliqUser.contact];
        
        if ([self isCurrentUser:qliqUser]) {
            [self notifyCurrentUserChanged:qliqUser];
        }
    }
    
    return success;
}

- (QliqUser *)saveContactFromJsonDictionary:(NSDictionary *)userInfoDict andNotifyAboutNew:(BOOL)notifyAboutNew
{
    [self.totalCounter resume];
    
    BOOL isNewContact = NO;
    if (notifyAboutNew) {
        
        NSString *newStatus = [userInfoDict objectForKey:USER_STATUS];
        QliqUser *existingContact = [self getUserWithId:[userInfoDict objectForKey:QLIQ_ID]];
        
        if (existingContact == nil || ([existingContact.status isEqualToString:@"deleted"] && ![newStatus isEqualToString:@"deleted"])) {
            isNewContact = YES;
        }
    }

    /*
     * Saving Contact.
     * First of all we need to check if contact already exists, and only if doesn't - create new record.
     */
    
    [self.userGetCounter resume];
    
    QliqUser *contact = [self getUserWithId:[userInfoDict objectForKey:QLIQ_ID]];
    
    [self.userGetCounter pause];
    
    if (!contact) {
        contact = [[QliqUser alloc] init];
    }
    contact.email              = [userInfoDict objectForKey:PRIMARY_EMAIL];
    contact.firstName          = [userInfoDict objectForKey:FIRST_NAME];
    contact.middleName         = [userInfoDict objectForKey:MIDDLE];
    contact.lastName           = [userInfoDict objectForKey:LAST_NAME];
    contact.address            = [userInfoDict objectForKey:ADDRESS];
    contact.city               = [userInfoDict objectForKey:CITY];
    contact.state              = [userInfoDict objectForKey:STATE];
    contact.zip                = [userInfoDict objectForKey:ZIP];
    contact.mobile             = [userInfoDict objectForKey:MOBILE];
    contact.phone              = [userInfoDict objectForKey:PHONE];
    contact.fax                = [userInfoDict objectForKey:FAX];
    contact.qliqId             = [userInfoDict objectForKey:QLIQ_ID];
    contact.profession         = [userInfoDict objectForKey:PROFESSION];
    contact.credentials        = [userInfoDict objectForKey:CREDENTIALS];
    contact.taxonomyCode       = [userInfoDict objectForKey:TAXONOMY_CODE];
    contact.npi                = [userInfoDict objectForKey:NPI];
    contact.status             = [userInfoDict objectForKey:USER_STATUS];
    contact.presenceMessage    = [userInfoDict objectForKey:PRESENCE_MESSAGE];
    contact.presenceStatus     = [QliqUser presenceStatusFromString: [userInfoDict objectForKey:PRESENCE_STATUS]];
    contact.forwardingQliqId   = [userInfoDict objectForKey:FORWARDING_QLIQ_ID];
    contact.isPagerUser        = [[userInfoDict objectForKey:PAGER_USER] boolValue];
    contact.pagerInfo          = [userInfoDict objectForKey:PAGER_INFO];
    
    if ([contact.status isEqualToString:@"active"]) {
        contact.contactStatus = ContactStatusDefault;
    }
    else if ([contact.status isEqualToString:@"deleted"]) {
        contact.contactStatus = ContactStatusDeleted;
    }
    
    if (notifyAboutNew && isNewContact) {
        contact.contactStatus = ContactStatusNew;
    }
    
    /**
     Now set the presence because something could have changed.
     */
    {
        [self.presenceCounter resume];
        
        Presence * presence = [[Presence alloc] init];
        presence.presenceType   = [userInfoDict objectForKey:PRESENCE_STATUS];
        presence.message        = [userInfoDict objectForKey:PRESENCE_MESSAGE];
        presence.forwardingUser = [[QliqUserDBService sharedService] getUserWithId:[userInfoDict objectForKey:FORWARDING_QLIQ_ID]];
        [appDelegate.network.presences setPresence:presence forUser:contact];
        
        [self.presenceCounter pause];
    }
    
    /**
     Saving sip related info
     */
    {
        [self.saveContactCounter resume];
        
        SipContactDBService *sipContactService = [[SipContactDBService alloc] initWithDatabase:self.database];
        
        /**
         Try to load existing SipContact to keep existing public key
         */
        SipContact *sipContact = [sipContactService sipContactForQliqId:contact.qliqId];
        if (sipContact == nil) {
            sipContact = [[SipContact alloc] init];
        }
        sipContact.qliqId           = contact.qliqId;
        sipContact.sipUri           = [userInfoDict objectForKey:SIP_URI];
        sipContact.sipContactType   = SipContactTypeUser;
        [sipContactService save:sipContact completion:nil];
        
        [self.saveContactCounter pause];
    }
    
    [self.saveUserCounter resume];
    
    if (![[QliqUserDBService sharedService] saveUser:contact]) {
        [self.saveUserCounter pause];
        DDLogSupport(@"Cant save contact: %@", contact);
    }
    else {
        
        [self.saveUserCounter pause];
        
        NSMutableArray *groupsArrayFromDict = [userInfoDict objectForKey:SHARED_GROUPS];
        NSMutableArray *groupsArrayFromDB = [[[QliqGroupDBService sharedService] getGroupsOfUser:contact] mutableCopy];
        NSMutableArray *groupQliqIdArrayFromDict = [[NSMutableArray alloc] init];
        
        // 1. Add or update the group membership for each of the groups present in the Dictionary
        //
        for (NSMutableDictionary *groupDict in groupsArrayFromDict)
        {
            NSString *sharedGroupQliqId = [groupDict objectForKey:QLIQ_ID];
            NSString *accessType        = [groupDict objectForKey:ACCESS_TYPE];
            
            // Add to the list of QliqIDs from the dictionary. Later it will be
            // used deleted the group associations.
            //
            [groupQliqIdArrayFromDict addObject:sharedGroupQliqId];
            
            [self.saveGroupsCounter resume];
        
            QliqGroup *group = [[QliqGroupDBService sharedService] getGroupWithId:sharedGroupQliqId];
            // If the group exists
            if (group)
            {
                group.accessType = accessType;
                // add the user to the group or update the user info such as access type. addUser does this.
                if (![[QliqGroupDBService sharedService] addUser:contact toGroup:group]) {
                    DDLogSupport(@"Cant add contact: %@ to group: %@", contact, group);
                }
            }
            [self.saveGroupsCounter pause];
        }
        // 2. Remove any group memberships that are present in the DB but not present in the Dictionary
        // Iterate through groups in DB and see if it is missing from the Dictionary. If it is remove it
        
        for (QliqGroup *group in groupsArrayFromDB) {
            // If the group present in DB but not in the Dictionary, removed group membership.
            
            //[indexOfObjectIdenticalTo] method is not working, because users of gpoup has been deleting after adding.
            //Valerii Lider 07/19/17
            //if ([groupQliqIdArrayFromDict indexOfObjectIdenticalTo:group.qliqId] == NSNotFound) {
            
            if (![groupQliqIdArrayFromDict containsObject:group.qliqId]) {
                //remove group membership from DB
                if ([[QliqGroupDBService sharedService] removeGroupMembershipForUser:contact.qliqId inGroup:group] == FALSE) {
                    DDLogSupport(@"Cant remove contact: %@ from group: %@", contact, group);
                }
            }
        }
        
        
        //Downloading avatar by URL
        NSString * avatarURLString = [userInfoDict objectForKey:AVATAR_URL];
        //NSLog(@"avatar URL: %@",avatarURLString);
        
        [self.avatarCounter resume];
        
        AvatarDownloadService *service =  [[AvatarDownloadService alloc] initWithUser:contact andUrlString:avatarURLString];
        [service callServiceWithCompletition:nil];
        [self.avatarCounter pause];
        
        if (notifyAboutNew && isNewContact) {
            dispatch_async_main(^{
                [[ContactDBService sharedService] notifyAboutNewContact:contact];
            });
        }
    }
    
    [self.totalCounter pause];
    
    return contact;
}

- (void) resetCounterTimes
{
    [self.saveContactCounter reset];
    [self.userGetCounter reset];
    [self.saveUserCounter reset];
    [self.presenceCounter reset];
    [self.deleteFromGroupCounter reset];
    [self.saveGroupsCounter reset];
    [self.avatarCounter reset];
    [self.totalCounter reset];
}

- (void) printCounterTimes
{
    DDLogSupport(@"SipContact saving time        : %f sec", self.saveContactCounter.measuredTime);
    DDLogSupport(@"User geting time              : %f sec", self.userGetCounter.measuredTime);
    DDLogSupport(@"User saving time              : %f sec", self.saveUserCounter.measuredTime);
    DDLogSupport(@"Presence time                 : %f sec", self.presenceCounter.measuredTime);
    DDLogSupport(@"Group membership removing time: %f sec", self.deleteFromGroupCounter.measuredTime);
    DDLogSupport(@"Group saving time             : %f sec", self.saveGroupsCounter.measuredTime);
    DDLogSupport(@"Avatar time                   : %f sec", self.avatarCounter.measuredTime);
    DDLogSupport(@"Total method time             : %f sec", self.totalCounter.measuredTime);
    
}

- (NSArray *) usersFromDecoders:(NSArray *) decoders{
    
    NSMutableArray * users = [[NSMutableArray alloc] init];
    for (DBCoder * decoder in decoders){
        [users addObject:[self objectOfClass:[QliqUser class] fromDecoder:decoder]];
    }
    return users;

}

- (QliqUser *) userFromDecoders:(NSArray *) decoders{
   
    QliqUser * user = nil;
    
    if (decoders.count > 0){
        user = [self objectOfClass:[QliqUser class] fromDecoder:decoders[0]];
    }
    
    return user;
}

- (NSArray *) getUsers {
   
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user" withArgs:nil];

    return [self usersFromDecoders:decoders];
}

- (NSArray *) getAllOtherVisibleUsers{

    QliqUser *currentUser = [UserSessionService currentUserSession].user;

    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE qliq_id != ? AND status != ?" withArgs:@[currentUser.qliqId,QliqUserStateInvitationPending]];
    return [self usersFromDecoders:decoders];
}

- (NSArray *) getAllOtherUsers{
    
	QliqUser *currentUser = [UserSessionService currentUserSession].user;
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE qliq_id != ?" withArgs:@[currentUser.qliqId]];
    return [self usersFromDecoders:decoders];
}

- (NSInteger) getAllOtherUsersCount {

    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    __block NSInteger ret = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(qliq_id) FROM qliq_user WHERE qliq_id != ?", currentUser.qliqId];
        if ([rs next]) {
            ret = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
    
}

- (QliqUser *) getUserForContact:(Contact *)contact{
    return [self getUserWithContactId:contact.contactId];
}

- (QliqUser *) getUserWithContactId:(NSInteger)contactId{
    
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE contact_id = ?" withArgs:@[[NSNumber numberWithInteger:contactId]]];
    QliqUser * user = [self userFromDecoders:decoders];

    if ([user.status isEqualToString:QliqUserStateInvitationPending]) user = nil;
    
    return user;
}

- (QliqUser *) getUserMinInfoWithContactId:(NSInteger)contactId{
    
     NSArray * decoders = [self decodersFromSQLQuery:@"SELECT contact_id, profession, presence_status, presence_message, status, qliq_id, pager_info, is_pager_only_user FROM qliq_user WHERE contact_id = ?" withArgs:@[[NSNumber numberWithInteger:contactId]]];
    QliqUser * user = [self userFromDecoders:decoders];
    
    if ([user.status isEqualToString:QliqUserStateInvitationPending]) user = nil;
    
    return user;
}

- (NSUInteger) contactIdForQliqId:(NSString *) qlidId{
    
	NSUInteger contactId = 0;
    
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE contact_id = ?" withArgs:@[[NSNumber numberWithInteger:contactId]]];
    
    if (decoders.count > 0){
        DBCoder * decoder = decoders[0];
        contactId = [[decoder decodeObjectForColumn:@"contact_id"] intValue];
    }

    return contactId;
}

- (QliqUser *) getUserWithId:(NSString *)qliqId{
    
    if (!qliqId)
        return nil;
    
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE qliq_id = ?" withArgs:@[qliqId]];
    
    QliqUser * user = [self userFromDecoders:decoders];
    
	return user;
}

- (QliqUser*) getUserWithEmail:(NSString*)email{
    QliqUser *user = nil;
    Contact *contact = [[ContactDBService sharedService] getContactByEmail:email];
    if (contact)
        user = [self getUserWithContactId:contact.contactId];
    return user;
}

-(QliqUser*) getUserWithMobile:(NSString*)mobile{
    QliqUser *user = nil;
    Contact *contact = [[ContactDBService sharedService] getContactByMobile:mobile];
    if (contact)
        user = [self getUserWithContactId:contact.contactId];
    return user;
}

- (QliqUser *) getUserWithSipUri:(NSString *)sipUri{
    
    QliqUser * user = nil;
        
    SipContactDBService * sipDbService = [[SipContactDBService alloc] initWithDatabase:self.database];
    SipContact * sipContact = [sipDbService sipContactForSipUri:sipUri];
    
    if (sipContact){
        user = [self getUserWithId:sipContact.qliqId];
    }else{
        DDLogError(@"SipContact is not exist for sipUri: %@",sipUri);
    }
    
	return user;
}

#pragma mark -
#pragma mark Private


-(BOOL) setAllOtherUsersAsDeleted:(NSSet *)activeUserQliqIds
{
    if ([activeUserQliqIds count] == 0)
        return YES;
    
    __block NSString *sql = @"UPDATE qliq_user SET status = 'deleted' WHERE status != 'qliqstor' AND qliq_id NOT IN (";
    
//    NSSet *activeUserQliqIdsLocal = [NSSet setWithSet:activeUserQliqIds];
    
    for (NSString *qliqId in activeUserQliqIds) {
        @autoreleasepool {
            sql = [NSString stringWithFormat:@"%@ '%@',", sql, qliqId];

        }
    }
    
    // Remove the last ','
    sql = [sql substringToIndex:[sql length] - 1];
    sql = [sql stringByAppendingString:@")"];
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql];
        sql = nil;
    }];
    return ret;
}

-(BOOL) setUsersBelongingToThisGroupOnlyAsDeleted:(NSString *)groupQliqId
{
    NSString *sql = @"UPDATE qliq_user SET status = 'deleted' WHERE status != 'qliqstor' AND "
        " qliq_id     IN (SELECT DISTINCT user_qliq_id FROM user_group WHERE group_qliq_id  = ?) AND "
        " qliq_id NOT IN (SELECT DISTINCT user_qliq_id FROM user_group WHERE group_qliq_id != ?)";
   
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql, groupQliqId, groupQliqId];
    }];
    return ret;
}

- (BOOL) updateStatusAsDeletedForUsersWithoutSharedGroups:(NSString *)myQliqId
{
    // Select qliq id of my groups
#define SELECT_MY_USER_GROUP_IDS "(SELECT group_qliq_id FROM user_group WHERE user_qliq_id = ?)"
    
    // Contacts who belong to shared groups (q1)
#define SELECT_USERS_OF_SHARED_GROUPS      "SELECT DISTINCT user_qliq_id FROM user_group WHERE group_qliq_id     IN " SELECT_MY_USER_GROUP_IDS
    
    // Contacts who belong to non-shared groups (q2)
#define SELECT_USERS_OF_NON_SHARED_GROUPS  "SELECT DISTINCT user_qliq_id FROM user_group WHERE group_qliq_id NOT IN " SELECT_MY_USER_GROUP_IDS
    
    // Contacts who belong to non-shared groups AND do not belong to shared groups (q2 - q1)
#define FINAL_SELECT SELECT_USERS_OF_NON_SHARED_GROUPS " AND user_qliq_id NOT IN (" SELECT_USERS_OF_SHARED_GROUPS ")"
    
    // TODO: optimize the query, find the correct, SQL efficient way
    NSString *sql = @"UPDATE qliq_user SET status = 'deleted' "
        " WHERE (status != 'deleted' AND status != 'qliqstor') AND qliq_id IN (" FINAL_SELECT ")";
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql, myQliqId, myQliqId];
    }];
    return ret;
}

- (NSMutableSet *) getGroupIds:(QliqUser *)qliqUser{
    
    NSMutableSet * groups = [[NSMutableSet alloc] init];
    
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT group_qliq_id FROM user_group WHERE user_qliq_id = ?" withArgs:@[qliqUser.qliqId]];
    
    for (DBCoder * decoder in decoders) {
        [groups addObject:[decoder decodeObjectForColumn:@"group_qliq_id"]];
    }
    
    return groups;
}

+ (NSString *) getFirstQliqStorIdForUserId:(NSString *)qliqId
{
    __block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT qliq_id FROM group_qliqstor WHERE group_qliq_id IN (SELECT group_qliq_id FROM user_group WHERE user_qliq_id = ?)";
        
        FMResultSet *rs = [db executeQuery:sql, qliqId];
        while ([rs next]) {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

- (NSMutableSet *) qliqStorsForUserId:(NSString *)qliqId{

    NSMutableSet *qliqStors = [[NSMutableSet alloc] init];
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT qliq_id FROM group_qliqstor WHERE group_qliq_id IN (SELECT group_qliq_id FROM user_group WHERE user_qliq_id = ?)" withArgs:@[qliqId]];
    
    for (DBCoder * decoder in decoders) {
        NSString * userId = [decoder decodeObjectForColumn:@"qliq_id"];
        QliqUser * user = [self getUserWithId:userId];
        if (user){
            [qliqStors addObject:user];
        }else{
            DDLogError(@"Cannot get qliqStor user for id: %@", userId);
        }
    }
    return qliqStors;
}

- (NSMutableSet *) qliqStorsForGroupId:(NSString *)qliqId{
    
    NSMutableSet *qliqStors = [[NSMutableSet alloc] init];
    NSArray * decoders = [self decodersFromSQLQuery:@"SELECT qliq_id FROM group_qliqstor WHERE group_qliq_id = ?" withArgs:@[qliqId]];
    
    for (DBCoder * decoder in decoders) {
        NSString * userId = [decoder decodeObjectForColumn:@"qliq_id"];
        QliqUser * user = [self getUserWithId:userId];
        if (user){
            [qliqStors addObject:user];
        }else{
            DDLogError(@"Cannot get qliqStor user for id: %@", userId);
        }
    }
    return qliqStors;
}

-(void) setUserDeleted:(QliqUser *)user
{
    if (user) {
        user.status = @"deleted";
        user.contactStatus = ContactStatusDeleted;
        [[QliqUserDBService sharedService] saveUser:user];
        
        //remove all group memberships
        [[QliqGroupDBService sharedService] removeAllGroupMembershipsForUser:user.qliqId];
    }
}

- (BOOL) containsQliqUsersWitoutContactRows
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(qliq_id) FROM qliq_user WHERE contact_id NOT IN (SELECT contact_id FROM contact) LIMIT 1"];
        while ([rs next]) {
            ret = ([rs intForColumnIndex:0] > 0);
        }
        [rs close];
    }];
    return ret;
}

@end

	//
//  QliqGroupService.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqGroupDBService.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "QliqUser.h"
#import "DBUtil.h"
#import "SipContactDBService.h"
#import "QliqUserDBService.h"
#import "ConversationDBService.h"

#define JOIN_SIP_CONTACT " JOIN sip_contact ON (sip_contact.contact_qliq_id = qliq_group.qliq_id) "
#define JOIN_SIP_CONTACT_FOR_USER " JOIN sip_contact ON (sip_contact.contact_qliq_id = qliq_user.qliq_id) "

@interface QliqGroupDBService()

- (BOOL)groupExists:(QliqGroup *)group;
- (BOOL)insertGroup:(QliqGroup *)group;
- (BOOL)updateGroup:(QliqGroup *)group;
- (BOOL)deleteGroup:(QliqGroup *)group;
- (NSArray *)getGroupsWhere:(NSString *)where;

@end

@implementation QliqGroupDBService

+ (QliqGroupDBService *)sharedService {
    static dispatch_once_t pred;
    static QliqGroupDBService * shared = nil;
    dispatch_once(&pred, ^{
        shared = [[QliqGroupDBService alloc] init];
    });
    return shared;
}

#pragma mark - Public

- (BOOL)saveGroup:(QliqGroup *)group {
    
    if([self groupExists:group]) {
        return [self updateGroup:group];
    }
    else {
        return [self insertGroup:group];
    }
}

- (void)safeDeleteUsersForGroupID:(NSString *)groupQliqId {
    
    QliqGroup *deleteGroup = [[QliqGroupDBService sharedService] getGroupWithId:groupQliqId];
    NSArray *deleteUsers = [[QliqGroupDBService sharedService] getUsersOfGroup:deleteGroup];
    
    for (QliqUser *user in deleteUsers) {
        
        NSArray *groupsOfUser = [[QliqGroupDBService sharedService] getGroupsOfUser:user];
        
        if (groupsOfUser.count == 1 && ![[groupsOfUser objectAtIndex:0] isDeleted]) {
            user.status = @"deleted";
            user.contactStatus = ContactStatusDeleted;
            [[QliqUserDBService sharedService] saveUser:user];
        }
    }
}

- (BOOL) safeDeleteGroup:(NSString *)groupQliqId
{
    DDLogSupport(@"Deleting group %@", groupQliqId);
    
    NSString *where = [NSString stringWithFormat:@"qliq_id = '%@' AND deleted = 0 LIMIT 1", groupQliqId];
    NSArray *groups = [self getGroupsWhere:where];
    
    if (groups.count > 0) {
        QliqGroup *group = groups[0];
        [[QliqUserDBService sharedService] setUsersBelongingToThisGroupOnlyAsDeleted:groupQliqId];
        [self removeAllUsersFromGroup:groupQliqId];
        
        NSArray *conversations = [[ConversationDBService sharedService] getConversationsWithQliqId:groupQliqId];
        if ([conversations count] == 0) {
            [self deleteGroup:group];
            SipContactDBService *sipContactService = [[SipContactDBService alloc] init];
            SipContact *sipContactToDelete = [sipContactService sipContactForQliqId:groupQliqId];
            if (sipContactToDelete) {
                [sipContactService deleteObject:sipContactToDelete mode:DBModeSingle completion:^(NSError *error) {
                    if (error) DDLogError(@"Cannot delete SipContact of group: %@",error);
                }];
            }
        } else {
            group.canBroadcast = NO;
            group.canMessage = NO;
            group.isDeleted = YES;
            [self updateGroup:group];
        }
    }
    return YES;
}

- (BOOL) removeAllUsersFromGroup:(NSString *)groupQliqId
{
    NSString *sql = @"DELETE FROM user_group WHERE group_qliq_id = ?";
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql, groupQliqId];
    }];
    return ret;
}

- (NSArray *)getGroups {
    return [self getGroupsWhere:@"deleted = 0"];
}

- (NSArray *)getGroupsOfUser:(QliqUser *)user {
    
    NSString *where = [NSString stringWithFormat:@"qliq_id IN"
                       " (SELECT group_qliq_id FROM user_group WHERE user_qliq_id = '%@') AND deleted = 0", user.qliqId];
    return [self getGroupsWhere:where];
}

- (NSArray *)getJoinGroups {
    return [self getGroupsWhere:@"open_membership = 1 and belongs = 0 AND deleted = 0"];
}

- (NSArray *)getLeaveGroups {
    return [self getGroupsWhere:@"open_membership = 1 and belongs = 1 AND deleted = 0"];
}

- (QliqGroup *)getGroupWithId:(NSString *)qliqId {
    
    NSString *where = [NSString stringWithFormat:@"qliq_id = '%@' LIMIT 1", qliqId];
    NSArray *groups = [self getGroupsWhere:where];
    
    if (groups.count > 0) {
        return [groups objectAtIndex:0];
    }
    else {
        return nil;
    }
}


- (NSArray *)getSubGroupsWithParentId:(NSString *)parentId {
        
    NSString *where = [NSString stringWithFormat:@"parent_qliq_id = '%@' AND deleted = 0", parentId];
    NSArray *groups = [self getGroupsWhere:where];
    
    return groups;
}

- (BOOL)addUser:(QliqUser *)user toGroup:(QliqGroup *)group
{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @"INSERT OR REPLACE INTO user_group (user_qliq_id, group_qliq_id, access_type) VALUES (?,?,?)";
        rez = [db executeUpdate:updateQuery, user.qliqId, group.qliqId, group.accessType];
    }];
    return rez;
}

- (NSArray *)getVisibleUsersOfGroup:(QliqGroup *)group {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    if (!user)	 {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE qliq_id IN"
    " (SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?) AND status != ?";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[group.qliqId, user.qliqId, QliqUserStateInvitationPending]];
    
    return [self usersFromDecoders:decoders];
}

- (NSArray *)getUsersOfGroup:(QliqGroup *)group withLimit:(NSUInteger)limit {
    
    QliqUser * user = [UserSessionService currentUserSession].user;
    
    if (!user) {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString * selectQuery = [NSString stringWithFormat:
                              @""
                              "SELECT * FROM qliq_user WHERE qliq_id IN "
                              "(SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?) LIMIT %lu"
                              , (unsigned long)limit];
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[group.qliqId, user.qliqId]];
    
    return [self usersFromDecoders:decoders];
}

- (NSArray *)getOnlyUsersOfGroup:(QliqGroup *)group {
    
    QliqUser * user = [UserSessionService currentUserSession].user;
    
    if (!user) {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString * selectQuery = @""
    "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status "
    "FROM contact "
    "WHERE contact_id != ? AND type != ? AND status != ? AND qliq_id IN "
    "(SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?)";
    
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[@(user.contact.contactId),
                                                                           @(ContactTypeIPhoneContact),
                                                                           @(ContactStatusDeleted),
                                                                           group.qliqId,
                                                                           user.qliqId]];
    
    NSMutableArray *contacts = [@[] mutableCopy];
   
    for (DBCoder *object in decoders) {
        [contacts addObject:[self objectOfClass:[Contact class] fromDecoder:object]];
    }
    
    return contacts;
    //    return [self usersFromDecoders:decoders];
}

- (NSArray *)getUsersOfGroup:(QliqGroup *)group {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    if (!user) {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString * selectQuery = @""
    "SELECT * FROM qliq_user WHERE qliq_id IN "
    "(SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?)";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[group.qliqId, user.qliqId]];
    
    return [self usersFromDecoders:decoders];
}

- (BOOL)isPagerUsersContainsInGroup:(QliqGroup *)group {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    if (!user) {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString * query = @"SELECT COUNT(is_pager_only_user) AS PAGER_USERS_COUNT FROM (SELECT * FROM qliq_user WHERE qliq_id IN (SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?)) WHERE is_pager_only_user = 1";
    
    
    NSArray * decoders = [self decodersFromSQLQuery:query withArgs:@[group.qliqId, user.qliqId]];
    NSInteger res = 0;
    if (decoders.count != 0) {
        
        id result = [((DBCoder *)decoders.firstObject) decodeObjectForColumn:@"PAGER_USERS_COUNT"];
        res = [result integerValue];
    }
    return res != 0;
}

- (NSUInteger)getCountOfParticipantsFor:(QliqGroup *)group {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    if (!user) {
        DDLogError(@"Can't get users of groups, since current user = %@",user);
        return [NSArray array];
    }
    if (!group) {
        DDLogError(@"Can't get users for group. Group = %@",group);
        return [NSArray array];
    }
    
    NSString * query = @"SELECT COUNT(user_qliq_id) AS PARTICIPANTS_COUNT FROM (SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ? and user_qliq_id != ?)";
    
    
    NSArray * decoders = [self decodersFromSQLQuery:query withArgs:@[group.qliqId, user.qliqId]];
    NSInteger res = 0;
    if (decoders.count != 0) {
        
        id result = [((DBCoder *)decoders.firstObject) decodeObjectForColumn:@"PARTICIPANTS_COUNT"];
        res = [result unsignedIntegerValue];
    }
    return res;
}

- (NSArray *)getGroupmatesOfUser:(QliqUser *)user inGroup:(QliqGroup *)group
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user " JOIN_SIP_CONTACT_FOR_USER " WHERE qliq_id != ? AND qliq_id IN"
    " (SELECT user_qliq_id FROM user_group WHERE group_qliq_id = ?)";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[user.qliqId, group.qliqId]];
    
    return [self usersFromDecoders:decoders];
}


- (BOOL)removeAllGroupMembershipsForUser:(NSString *)qliqId {
    
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @""
        " DELETE FROM user_group "
        " WHERE user_qliq_id = ?";
        
        rez = [db executeUpdate:updateQuery,qliqId];
    }];
    return rez;
}

- (BOOL)removeGroupMembershipForUser:(NSString *)qliqId inGroup:(QliqGroup *)group
{
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @""
        " DELETE FROM user_group "
        " WHERE user_qliq_id = ? AND group_qliq_id =?";
        
        rez = [db executeUpdate:updateQuery,qliqId, group.qliqId];
    }];
    
    return rez;
}

- (BOOL)setQliqStorForGroup:(QliqGroup *)group qliqStor:(QliqUser *)aStor {
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"INSERT OR REPLACE INTO group_qliqstor (group_qliq_id, qliq_id) VALUES (?, ?)";
        ret = [db executeUpdate:sql, group.qliqId, aStor.qliqId];
    }];
    return ret;
}

- (BOOL)deleteQliqStorForGroup:(QliqGroup *)group {
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM group_qliqstor WHERE group_qliq_id = ?";
        ret = [db executeUpdate:sql, group.qliqId];
    }];
    return ret;
}

+ (NSString *)getQliqStorIdForGroup:(QliqGroup *)group
{
    __block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT gq.qliq_id FROM group_qliqstor gq WHERE gq.group_qliq_id = ? ";
        
        FMResultSet *rs = [db executeQuery:sql, group.qliqId];
        if ([rs next]) {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

+ (NSSet *)getAllQliqStorIds
{
    __block NSMutableSet *ret = [NSMutableSet new];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT DISTINCT gq.qliq_id FROM group_qliqstor gq JOIN qliq_group g ON (g.qliq_id = gq.group_qliq_id)";
        
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString *qliqId = [rs stringForColumnIndex:0];
            [ret addObject:qliqId];
        }
        [rs close];
    }];
    return ret;
}

+ (NSString *)getFirstQliqStorId
{
    __block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT DISTINCT gq.qliq_id FROM group_qliqstor gq JOIN qliq_group g ON (g.qliq_id = gq.group_qliq_id) WHERE g.deleted = 0 AND gq.qliq_id NOT NULL ";
        
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next]) {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

+ (BOOL) hasAnyQliqStor
{
    NSString *qliqId = [self getFirstQliqStorId];
    return qliqId.length > 0;
}

#pragma mark - Private

- (NSArray *)getGroupsWhere:(NSString *)where {
    
    __block NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
       
        NSString *selectQuery = @"SELECT * FROM qliq_group " JOIN_SIP_CONTACT;
        
        if (where.length > 0) {
            selectQuery = [selectQuery stringByAppendingFormat:@" WHERE %@", where];
        }
        
        FMResultSet *rs = [db executeQuery:selectQuery];
        while ([rs next]) {
            QliqGroup *qliqGroup = [QliqGroup groupWithResultSet:rs];
            [mutableRez addObject:qliqGroup];
        }
        [rs close];
    }];
     
    // To avoid nested sqlite queries we fetch parent groups in this loop instead of the above one
    for (QliqGroup *qliqGroup in mutableRez)
    {
        if (qliqGroup.parentQliqId != nil) {
            QliqGroup *parentGroup = [self getGroupWithId:qliqGroup.parentQliqId];
            qliqGroup.name = [NSString stringWithFormat:@"%@ • %@", parentGroup.acronym, qliqGroup.name];
        }
    }
    
    return mutableRez;
}

- (NSArray *)usersFromDecoders:(NSArray *)userDecoders {
    
    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:userDecoders.count];
    
    for (DBCoder *decoder in userDecoders)
    {
        QliqUser *user = [self objectOfClass:[QliqUser class] fromDecoder:decoder];
        if (user != nil) {
            [users addObject:user];
        }
        else {
            DDLogError(@"Cannot decode QliqUser from coder");
        }
    }
    
    return users;
}

- (BOOL)groupExists:(QliqGroup *)group {
    
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        "SELECT qliq_id FROM qliq_group WHERE qliq_id = ?";
        
        FMResultSet *rs = [db executeQuery:selectQuery, group.qliqId];
        
        if([rs next]) {
            rez = YES;
        }
        
        [rs close];
    }];
    return rez;
}

- (BOOL)insertGroup:(QliqGroup *)group {
    
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *insertQuery = @""
        "INSERT INTO qliq_group ("
        " qliq_id, "
        " parent_qliq_id, "
        " name, "
        " acronym, "
        " address, "
        " city, "
        " state, "
        " zip, "
        " phone, "
        " fax, "
        " npi, "
        " open_membership, "
        " belongs, "
        " taxonomy_code, "
        " can_broadcast, "
        " can_message, "
        " deleted "
        " ) " 
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        
        rez = [db executeUpdate:insertQuery,
               group.qliqId,
               group.parentQliqId,
               group.name,
               group.acronym,
               group.address,
               group.city,
               group.state,
               group.zip,
               group.phone,
               group.fax,
               group.npi,
               [NSNumber numberWithBool:group.openMembership],
               [NSNumber numberWithBool:group.belongs],
               group.taxonomyCode,
               [NSNumber numberWithBool:group.canBroadcast],
               [NSNumber numberWithBool:group.canMessage],
               [NSNumber numberWithBool:group.isDeleted]
               ];
    }];

    return rez;
}

- (BOOL)updateGroup:(QliqGroup *)group {
    
    __block BOOL rez = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @""
        " UPDATE qliq_group SET "
        " parent_qliq_id = ?, "
        " name = ?, "
        " acronym = ?, "
        " address = ?, "
        " city = ?, "
        " state = ?, "
        " zip = ?, "
        " phone = ?, "
        " fax = ?, "
        " npi = ?, "
        " open_membership = ?, "
        " belongs = ?, "
        " taxonomy_code = ?, "
        " can_broadcast = ?, "
        " can_message = ?, "
        " deleted = ? "
        " WHERE qliq_id = ?";
        
        rez = [db executeUpdate:updateQuery,
               group.parentQliqId,
               group.name,
               group.acronym,
               group.address,
               group.city,
               group.state,
               group.zip,
               group.phone,
               group.fax,
               group.npi,
               [NSNumber numberWithBool:group.openMembership],
               [NSNumber numberWithBool:group.belongs],
               group.taxonomyCode,
               [NSNumber numberWithBool:group.canBroadcast],
               [NSNumber numberWithBool:group.canMessage],
               [NSNumber numberWithBool:group.isDeleted],
               group.qliqId];
    }];
    
    return rez;
}

- (BOOL)deleteGroup:(QliqGroup *)group
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM user_group WHERE group_qliq_id = ?", group.qliqId];
        ret = [db executeUpdate:@"DELETE FROM qliq_group WHERE qliq_id = ?", group.qliqId];
    }];
    return ret;
}

- (NSSet *)groupsForQliqStor:(QliqUser *)qliqStor {
    
    __block NSMutableSet *ret = [[NSMutableSet alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        
        NSString *sql = @"SELECT group_qliq_id FROM group_qliqstor WHERE qliq_id = ?";
      
        FMResultSet *rs = [db executeQuery:sql, qliqStor.qliqId];

        while ([rs next])
        {
            NSString *groupId = [rs stringForColumnIndex:0];
            QliqGroup *group = [self getGroupWithId:groupId];
            if (group) {
                [ret addObject:group];
            }
        }
        [rs close];
    }];
    
    return ret;
}

@end

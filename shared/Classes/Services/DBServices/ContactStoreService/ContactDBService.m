//
//  ContactStoreService.m
//  qliq
//
//  Created by Aleksey Garbarev on 25.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContactDBService.h"
#import "DBUtil.h"
#import "NotificationUtils.h"

NSString * ContactServiceNewContactNotification = @"ContactServiceNewContactNotification";

@implementation ContactDBService

+ (ContactDBService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ContactDBService alloc] init];
        
    });
    return shared;
}

- (BOOL) deleteContact:(Contact *) contact{
    NSString *selectQuery = @""
    "DELETE FROM contact WHERE contact_id = ?";

    __block BOOL ret = NO;
    void (^body)(FMDatabase *db) = ^(FMDatabase *db) {
        ret = [db executeUpdate:selectQuery, @(contact.contactId)];
    };

    if (self.database) {
        body(self.database);
    } else {
        [[DBUtil sharedQueue] inDatabase:body];
    }
    return ret;
}

- (BOOL) saveContact:(Contact *) contact
{
    __block BOOL success = NO;
    
    [self save:contact completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
    }];

	return success;
}

- (void) notifyAboutNewContact:(id)contact
{
    NSDictionary * userInfoDict = @{@"Contact" : contact, @"NewContactsCount" : @([self getNewContactsCount])};
    [NSNotificationCenter postNotificationToMainThread:ContactServiceNewContactNotification userInfo:userInfoDict];
}

- (NSUInteger) getNewContactsCount
{
    NSUInteger newContactsCount = 0;
    
    NSString *selectQuery = @""
    @"SELECT count(distinct(contact_id)) AS count FROM contact WHERE  status = ?";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[@(ContactStatusNew)]];
    
    if ([decoders count] > 0) {
        DBCoder *decoder = decoders[0];
        newContactsCount = [[decoder decodeObjectForColumn:@"count"] integerValue];
    }

    return newContactsCount;
}

- (Contact *) getContactById:(NSInteger) contactId
{
    return [self objectWithId:@(contactId) andClass:[Contact class]];
}

- (Contact *) getContactByQliqId:(NSString*) qliqId
{
    if (!qliqId)
        return nil;
        
    NSString *selectQuery = @""
    " SELECT * FROM contact WHERE qliq_id = ?";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[qliqId]];

    NSArray *contacts = [self contactsFromDecoders:decoders];
    
    return [contacts lastObject];
}

- (Contact *) getContactByEmail:(NSString *) email
{
    NSString *selectQuery = @""
    " SELECT * FROM contact WHERE email = ? COLLATE NOCASE";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[email]];
    
    NSArray *contacts = [self contactsFromDecoders:decoders];
    
    return [contacts lastObject];
}

-(BOOL) updateStatusAsDeletedForContactsWithoutSharedGroups:(NSString *)myQliqId
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
    NSString *sql = @"UPDATE contact SET status = ? "
        " WHERE status != ? AND qliq_id IN (" FINAL_SELECT ")";
    
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSNumber *deletedStatus = [NSNumber numberWithInt:(int)ContactStatusDeleted];
        ret = [db executeUpdate:sql, deletedStatus, deletedStatus, myQliqId, myQliqId];
    }];
    return ret;
}

- (Contact *) getContactByMobile:(NSString *) mobile
{
    NSString *selectQuery = @""
    " SELECT * FROM contact WHERE mobile = ?";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[mobile]];
    
    NSArray *contacts = [self contactsFromDecoders:decoders];
    
    return [contacts lastObject];
}



#pragma mark - Objects decoding

- (NSArray *) contactsFromDecoders:(NSArray *)decoders
{
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    for (DBCoder *decoder in decoders) {
        Contact *contact = [self objectOfClass:[Contact class] fromDecoder:decoder];
        [results addObject:contact];
    }
    return results;
}

@end

//
//  QliqListService.m
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "QliqListService.h"
#import "ContactList.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "QliqUser.h"
#import "DBUtil.h"
#import "QliqUserDBService.h"

@implementation QliqListService

+ (QliqListService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[QliqListService alloc] init];
        
    });
    return shared;
}

- (ContactList*)getContactListWithConversationId:(NSInteger)conversationId
{
    __block NSMutableArray *mutableRez = [NSMutableArray array];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        " SELECT * FROM contactlist WHERE conversation_id =?";
        
        FMResultSet *rs = [db executeQuery:selectQuery, [NSNumber numberWithInteger:conversationId]];
        while ([rs next])
        {
            ContactList *list = [ContactList listWithResultSet:rs];
            
            [mutableRez addObject:list];
        }
        [rs close];
    }];
    
    ContactList *list = mutableRez.count > 0 ? [mutableRez firstObject] : nil;

    return list;
}

-(NSArray*) getLists {
    __block NSMutableArray *mutableRez = [NSMutableArray array];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        " SELECT * FROM contactlist ORDER BY UPPER(name)";
        
        FMResultSet *rs = [db executeQuery:selectQuery];
        while ([rs next])
        {
            ContactList *list = [ContactList listWithResultSet:rs];
            
            [mutableRez addObject:list];
        }
        [rs close];
    }];
    return mutableRez;
}

- (NSArray*)getContactsAndUsersOfList:(ContactList*)list withLimit:(NSUInteger)limit
{
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    NSString *selectQuery = [NSString stringWithFormat:
    @""
    "SELECT * FROM contact WHERE contact_id IN"
    " (SELECT contact_id FROM contact_contactlist WHERE contactlist_id = ? and contact_id != ?) LIMIT %lu"
                             , (unsigned long)limit];
    
    QliqUserDBService * userDBService = [[QliqUserDBService alloc] init];
    NSArray * contactsDecoders = [userDBService decodersFromSQLQuery:selectQuery withArgs:@[[NSNumber numberWithInteger:list.contactListId], [NSNumber numberWithInteger:user.contactId]]];
    
    return [self usersAndContactsFromContactsDecoders:contactsDecoders];
}

-(NSArray*) getOnlyUsersOfList:(ContactList*)list {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    NSString *selectQuery = @""
    "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
    "FROM contact "
    "WHERE contact_id IN "
    " (SELECT contact_id FROM contact_contactlist WHERE contactlist_id = ? and contact_id != ?)";
    
    QliqUserDBService * userDBService = [[QliqUserDBService alloc] init];
    NSArray * contactsDecoders = [userDBService decodersFromSQLQuery:selectQuery
                                                            withArgs:@[[NSNumber numberWithInteger:list.contactListId],
                                                                       [NSNumber numberWithInteger:user.contactId]]];
    
    NSMutableArray *contacts = [@[] mutableCopy];
    for (DBCoder *object in contactsDecoders) {
        [contacts addObject:[userDBService objectOfClass:[Contact class] fromDecoder:object]];
    }
    
    return contacts;
//    return [self usersAndContactsFromContactsDecoders:contactsDecoders];
}


- (NSArray*) getContactsAndUsersOfList:(ContactList*)list
{
    QliqUser *user = [UserSessionService currentUserSession].user;
	
    NSString *selectQuery = @""
    "SELECT * FROM contact WHERE contact_id IN"
    " (SELECT contact_id FROM contact_contactlist WHERE contactlist_id = ? and contact_id != ?)";
    
    QliqUserDBService * userDBService = [[QliqUserDBService alloc] init];
    NSArray * contactsDecoders = [userDBService decodersFromSQLQuery:selectQuery withArgs:@[[NSNumber numberWithInteger:list.contactListId], [NSNumber numberWithInteger:user.contactId]]];
    
    return [self usersAndContactsFromContactsDecoders:contactsDecoders];
}

- (NSArray*) getUsersOfList:(ContactList*)list
{
    QliqUser *user = [UserSessionService currentUserSession].user;
	
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE contact_id IN"
    " (SELECT contact_id FROM contact_contactlist WHERE contactlist_id = ? and contact_id != ?)";
    
    QliqUserDBService * userDBService = [[QliqUserDBService alloc] init];
    
    NSArray *usersDecoders = [userDBService decodersFromSQLQuery:selectQuery withArgs:@[@(list.contactListId), @(user.contactId)]];

    return [self usersFromUsersDecoders:usersDecoders];
}

-(NSArray*) getListsOfUser:(NSInteger)contactId {
    __block NSMutableArray *mutableRez = [NSMutableArray array];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        "SELECT * FROM contactlist WHERE contactlist_id IN (SELECT contactlist_id FROM contact_contactlist WHERE contact_id = ?)";
        
        FMResultSet *rs = [db  executeQuery:selectQuery, [NSNumber numberWithInteger:contactId]];
        while ([rs next]) {
            [mutableRez addObject:[ContactList listWithResultSet:rs]];
        }
        [rs close];
    }];
    return mutableRez;
}

- (BOOL) isListExistWithName:(NSString *) name{
    __block BOOL exist = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * selectQuery = @"SELECT * FROM contactlist WHERE name = trim(?)";
        FMResultSet * result = [db executeQuery:selectQuery,name];
        if  ([result next]){
            exist = YES;
        }
        [result close];
    }];
    return exist;
}

-(BOOL) addListWithName:(NSString*)name {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * insertQuery = @""
        "INSERT INTO contactlist (name) VALUES (trim(?))";
        ret = [db executeUpdate:insertQuery, name];
    }];
    return ret;
}

-(BOOL) addListWithName:(NSString*)name andConversationId:(NSInteger)conversationId {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * insertQuery = @""
        "INSERT INTO contactlist "
        "(name, conversation_id) "
        "VALUES (?,?)";
        ret = [db executeUpdate:insertQuery, name, [NSNumber numberWithInteger:conversationId]];
    }];
    return ret;
}

-(BOOL) removeList:(ContactList*)list {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
    
        NSString * deleteQuery = @""
        "DELETE FROM contactlist WHERE contactlist_id = ?";
        
        ret = [db executeUpdate:deleteQuery, [NSNumber numberWithInteger:list.contactListId]];
        
        NSString * deleteUsersQuery = @""
        "DELETE FROM contact_contactlist WHERE contactlist_id = ?";
        
        ret &= [db executeUpdate:deleteUsersQuery, [NSNumber numberWithInteger:list.contactListId]];
    }];
    return ret;
}

-(BOOL) updateQliqId:(NSString *)qliqId forList:(ContactList *)list {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        
        NSString * insertQuery = @""
        "UPDATE contactlist "
        "SET qliq_id=? "
        "WHERE contactlist_id=?";
        
        ret = [db executeUpdate:insertQuery, qliqId, [NSNumber numberWithInteger:list.contactListId]];
    }];
    return ret;
}

-(BOOL) addUserWithContactId:(NSInteger)contactId toList:(ContactList*)list {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * insertQuery = @""
        "INSERT INTO contact_contactlist (contact_id, contactlist_id) VALUES (?, ?)";
        
        ret=  [db executeUpdate:insertQuery, [NSNumber numberWithInteger:contactId], [NSNumber numberWithInteger:list.contactListId]];
    }];
    return ret;
}

-(BOOL) removeUserWithContactId:(NSInteger)contactId fromList:(ContactList*)list {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
         NSString * deleteQuery = @""
        "DELETE FROM contact_contactlist WHERE contact_id = ? AND contactlist_id = ?";
        
        ret = [db executeUpdate:deleteQuery, [NSNumber numberWithInteger:contactId], [NSNumber numberWithInteger:list.contactListId]];
    }];
    return ret;
}

-(BOOL) removeAllUsersFromList:(ContactList*)list
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * deleteQuery = @""
        "DELETE FROM contact_contactlist WHERE contactlist_id = ?";
        
        ret = [db executeUpdate:deleteQuery, [NSNumber numberWithInteger:list.contactListId]];
    }];
    return ret;
}

#pragma mark - Decoding objects

- (NSArray *) usersFromUsersDecoders:(NSArray *)usersDecoders
{
    QliqUserDBService *userDBService = [QliqUserDBService sharedService];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[usersDecoders count]];
    
    for (DBCoder *decoder in usersDecoders) {
        QliqUser *user = [userDBService objectOfClass:[QliqUser class] fromDecoder:decoder];
        [results addObject:user];
    }
    
    return results;
}

- (NSArray *) usersAndContactsFromContactsDecoders:(NSArray *)contactsDecoders
{
    QliqUserDBService *userDBService = [QliqUserDBService sharedService];
    NSMutableArray * results = [[NSMutableArray alloc] initWithCapacity:[contactsDecoders count]];
    
    for (DBCoder * contactDecoder in contactsDecoders)
    {
        NSInteger contact_id = [[contactDecoder decodeObjectForColumn:@"contact_id"] integerValue];
        QliqUser * userForContact = [userDBService getUserWithContactId:contact_id];
        
        if (userForContact) {
            [results addObject:userForContact];
        } else {
            Contact * contact = [userDBService objectOfClass:[Contact class] fromDecoder:contactDecoder];
            [results addObject:contact];
        }
    }
    
    return results;
}

@end

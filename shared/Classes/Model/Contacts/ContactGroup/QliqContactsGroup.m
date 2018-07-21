//
//  QliqContactsGroup.m
//  qliq
//
//  Created by Valerii Lider on 12/5/13.
//
//

#import "QliqContactsGroup.h"
#import "QliqUserDBService.h"
#import "DBUtil.h"
#import "ContactDBService.h"
#import "QliqDBService.h"
#import "UserSessionService.h"

@interface QliqAllContactsGroup ()

- (NSArray *)contactsAndUsersFromContactDecoders:(NSArray *)decoders onlyVisible:(BOOL)onlyVisible;

@end

@implementation QliqContactsGroup

- (NSString *)name {
    return @"My qliqNETWORK";
}

- (NSArray *)contactsAndUsersOnlyVisible:(BOOL)onlyVisible
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
    NSString *query = @"SELECT * FROM contact WHERE contact_id != ? AND type != ? AND status != ?";
    NSArray * decoders = [dBService decodersFromSQLQuery:query
                                                withArgs:@[@(currentUser.contactId),
                                                           @(ContactTypeIPhoneContact),
                                                           @(ContactStatusDeleted)]];
    
    return [self contactsAndUsersFromContactDecoders:decoders onlyVisible:onlyVisible];
}

- (NSArray *)contactsAndUsersOnlyVisible:(BOOL)onlyVisible withLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
    NSString *query = @"SELECT * FROM contact WHERE contact_id != ? AND status < ? ORDER by last_name LIMIT ?, ?";
    NSArray * decoders = [dBService decodersFromSQLQuery:query
                                                withArgs:@[@(currentUser.contactId),
                                                           @(ContactStatusInvitationInProcess),
                                                           @(startIndex),
                                                           @(countIndex)]];
    
    return [self contactsAndUsersFromContactDecoders:decoders onlyVisible:onlyVisible];
}

- (NSArray *)contactsOnly
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;

    NSString *table = [[Contact class] dbTable];

    
//     NSString *query = [NSString stringWithFormat:@"SELECT contact_id, qliq_id, first_name, last_name, middle_name, group_name, email, status, type FROM %@ WHERE contact_id != ? AND type != ? AND status != ? ORDER BY UPPER(last_name) ASC, UPPER(first_name) ASC", table];
     NSString *query = [NSString stringWithFormat:@"SELECT contact_id, qliq_id, first_name, last_name, status, type FROM %@ WHERE contact_id != ? AND type != ? AND status != ? ORDER BY UPPER(last_name) ASC, UPPER(first_name) ASC", table];
    
    NSArray *decoders = [dBService decodersFromSQLQuery:query
                                               withArgs:@[@(currentUser.contact.contactId),
                                                          @(ContactTypeIPhoneContact),
                                                          @(ContactStatusDeleted)]];

     
    NSMutableArray *contacts = [@[] mutableCopy];
    for (DBCoder *object in decoders) {
        [contacts addObject:[dBService objectOfClass:[Contact class] fromDecoder:object]];
    }
    
    return contacts;
}

- (NSArray *)contactsSearchWithSearchString:(NSString*)searchString
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
//    NSString *query = [NSString stringWithFormat:@""
//                       "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
//                       "FROM contact "
//                       "WHERE contact_id != ? AND type != ? AND status != ? AND contact_id IN "
//                       "(SELECT contact_id FROM qliq_user WHERE presence_status = ?)"];
//    
//    NSArray *decoders = [dBService decodersFromSQLQuery:query
//                                               withArgs:@[@(currentUser.contact.contactId),
//                                                          @(ContactTypeIPhoneContact),
//                                                          @(ContactStatusDeleted),
//                                                          [NSNumber numberWithInteger:self.pressenceStatus]]];
    
    
    NSString *table = [[Contact class] dbTable];
    NSString *query = [NSString stringWithFormat:@""
                       "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
                       "FROM %@ "
                       "WHERE contact_id != ? AND type != ? AND status != ? AND "
                       "(first_name LIKE '%@%%' OR last_name LIKE '%@%%') OR contact_id IN"
                       "(SELECT contact_id FROM qliq_user WHERE (profession LIKE '%@%%'))", table, searchString, searchString, searchString];
    
    
    NSArray *decoders = [dBService decodersFromSQLQuery:query
                                               withArgs:@[@(currentUser.contact.contactId),
                                                          @(ContactTypeIPhoneContact),
                                                          @(ContactStatusDeleted)]];
    
    NSMutableArray *contacts = [@[] mutableCopy];
    for (DBCoder *object in decoders) {
        [contacts addObject:[dBService objectOfClass:[Contact class] fromDecoder:object]];
    }
    
    return contacts;
}

- (NSArray *)getSearchContactsWithSearchString:(NSString*)searchString
{
    NSArray *rezult = [self contactsSearchWithSearchString:searchString];
    return rezult;
}

- (NSArray *)getOnlyContacts
{
    NSArray *rezult = [self contactsOnly];
    return rezult;
}

- (NSArray *)getVisibleContacts
{
    NSArray *rez = [self contactsAndUsersOnlyVisible:YES];
    return rez;
}

- (NSArray*)getContacts
{
    NSArray *rez = [self contactsAndUsersOnlyVisible:YES];
    return rez;
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible
{
    NSArray *rez = [self contactsAndUsersOnlyVisible:onlyVisible withLimitFrom:startIndex to:countIndex];
    return rez;
}

@end

//
//  QliqContactsGroup.m
//  qliq
//
//  Created by Valerii Lider on 12/5/13.
//
//

#import "QliqDndContactsGroup.h"
#import "QliqUserDBService.h"
#import "DBUtil.h"
#import "ContactDBService.h"
#import "QliqDBService.h"
#import "UserSessionService.h"

@interface QliqDndContactsGroup ()

- (NSArray *)contactsAndUsersDndFromContactDecoders:(NSArray *)decoders onlyVisible:(BOOL)onlyVisible withPresenceStatus:(PresenceStatus)presenceStatus;

@end

@implementation QliqDndContactsGroup


- (NSString *) name {
    return @"DND";
}

- (void)addContact:(Contact *)contact{
    
}

- (NSArray *)contactsAndUsersOnlyVisible:(BOOL) onlyVisible {
    
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    //AND presence_status == ?
    //status should be less than ContactStatusInvitationInProcess
    NSArray * decoders = [dBService decodersFromSQLQuery:@"SELECT * FROM contact WHERE contact_id != ? AND type != ? AND status != ?"
                                                withArgs:@[@(currentUser.contactId),
                                                           @(ContactTypeIPhoneContact),
                                                           @(ContactStatusDeleted)]];
//    NSArray * decoders = [dBService decodersFromSQLQuery:@"SELECT * FROM qliq_user WHERE qliq_id != ? presence_status == ?"
//                                                withArgs:@[@(currentUser.contactId),
//                                                           @(AwayPresenceStatus)]];
    
    return [self contactsAndUsersDndFromContactDecoders:decoders onlyVisible:onlyVisible withPresenceStatus:self.pressenceStatus];
}

- (NSArray *)contactsOnly
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
     NSString *query = [NSString stringWithFormat:@""
     "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
     "FROM contact "
     "WHERE contact_id != ? AND type != ? AND status != ? AND contact_id IN "
     "(SELECT contact_id FROM qliq_user WHERE presence_status = ?) ORDER BY UPPER(last_name) ASC, UPPER(first_name) ASC"];
     
     NSArray *decoders = [dBService decodersFromSQLQuery:query
                                                withArgs:@[@(currentUser.contact.contactId),
                                                           @(ContactTypeIPhoneContact),
                                                           @(ContactStatusDeleted),
                                                           [NSNumber numberWithInteger:self.pressenceStatus]]];
    
    NSMutableArray *contacts = [@[] mutableCopy];
    for (DBCoder *object in decoders) {
        [contacts addObject:[dBService objectOfClass:[Contact class] fromDecoder:object]];
    }
    
    return contacts;
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

- (NSArray *)contactsAndUsersOnlyVisible:(BOOL)onlyVisible withLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex {
    
    QliqDBService * dBService = [[QliqDBService alloc] init];
    
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
    //status should be less than ContactStatusInvitationInProcess
    NSArray * decoders = [dBService decodersFromSQLQuery:@"SELECT * FROM contact WHERE contact_id != ? AND status < ? ORDER by last_name LIMIT ?, ?"
                                                withArgs:@[@(currentUser.contactId),
                                                           @(ContactStatusInvitationInProcess),
                                                           @(startIndex),
                                                           @(countIndex)]];
    
    return [self contactsAndUsersDndFromContactDecoders:decoders onlyVisible:onlyVisible withPresenceStatus:self.pressenceStatus];
}

- (NSArray *)contactsAndUsersDndFromContactDecoders:(NSArray *)decoders onlyVisible:(BOOL)onlyVisible withPresenceStatus:(PresenceStatus)presenceStatus
{
    NSMutableArray *result = [NSMutableArray new];
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    NSMutableSet *existingQliqIds = [NSMutableSet new];
    QliqUserDBService *userDBService = [[QliqUserDBService alloc] init];
    
    [existingQliqIds addObject:myQliqId];
    
    for (DBCoder *contactDecoder in decoders) {
        
        id contactToAdd = nil;
        NSInteger contact_id = [[contactDecoder decodeObjectForColumn:@"contact_id"] integerValue];
        QliqUser *userForContact = [userDBService getUserWithContactId:contact_id];
        if (userForContact)
        {
            if (![userForContact.status isEqualToString:@"deleted"] &&
                userForContact.presenceStatus == presenceStatus &&
                (!onlyVisible || ![userForContact.status isEqualToString:QliqUserStateInvitationPending]))
            {
                contactToAdd = userForContact;
            }
        }
        else
        {
            Contact *contact = [userDBService objectOfClass:[Contact class] fromDecoder:contactDecoder];
            if (contact != nil)
                contactToAdd = contact;
        }
        
        // The code that creates Contact rows in db is buggy so we have a workaround below
        // Don't show empty contacts and don't show duplicates
        
        if (contactToAdd != nil && ![existingQliqIds containsObject:[contactToAdd qliqId]] &&
            ([[contactToAdd firstName] length] > 0 || [[contactToAdd lastName ] length] > 0))
        {
            
            [result addObject:contactToAdd];
            if ([[contactToAdd qliqId] length] > 0) {
                
                [existingQliqIds addObject:[contactToAdd qliqId]];
            }
        }
        
    }
    
    return result;
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible
{
    NSArray *rez = [self contactsAndUsersOnlyVisible:onlyVisible withLimitFrom:startIndex to:countIndex];
    return rez;
}

@end

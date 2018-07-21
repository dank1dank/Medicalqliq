//
//  QliqAllContactsGroup.m
//  qliqConnect
//
//  Created by Paul Bar on 12/8/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqAllContactsGroup.h"
//#import "QliqReferralsGroup.h"
#import "QliqAddressBookContactGroup.h"
#import "MockContactGroup.h"
#import "QliqGroupDBService.h"
#import "QliqUserDBService.h"
#import "DBUtil.h"
#import "ContactDBService.h"
#import "QliqDBService.h"

#import "UserSessionService.h"

@implementation QliqAllContactsGroup

- (instancetype)init {
    
    self = [super init];
    if(self) {
    }
    return self;
}

- (NSString *)name {
    return @"All Contacts";
}

- (BOOL)locked {
    return NO;
}

- (NSUInteger)getPendingCount {
    
    return [[ContactDBService sharedService] getNewContactsCount];
}

- (NSArray *)getNewContacts {
    
    NSMutableArray *newContacts = [[NSMutableArray alloc] init];
    NSArray *contacts = [self getContacts];
    for (Contact *contact in contacts) {
        
        if (contact.contactStatus == ContactStatusNew)
            [newContacts addObject:contact];
    }
    
    if (newContacts.count == 0) {
        newContacts = nil;
    }
    
    return newContacts;
}

- (NSArray *)contactsAndUsersFromContactDecoders:(NSArray *)decoders onlyVisible:(BOOL)onlyVisible {
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    NSMutableSet *existingQliqIds = [[NSMutableSet alloc] init];
    QliqUserDBService *userDBService = [[QliqUserDBService alloc] init];
    
    [existingQliqIds addObject:myQliqId];
    
    for (DBCoder *contactDecoder in decoders) {
        
        id contactToAdd = nil;
        
        id valueLocal = [contactDecoder decodeObjectForColumn:@"contact_id"];
        NSInteger contact_id = [valueLocal integerValue];
        
        QliqUser *userForContact = [userDBService getUserWithContactId:contact_id];
        if (!userForContact) {
            if (![userForContact.status isEqualToString:@"deleted"] && (!onlyVisible || ![userForContact.status isEqualToString:QliqUserStateInvitationPending])) {
                contactToAdd = userForContact;
            }
        } else {
            
            contactToAdd = [userDBService objectOfClass:[Contact class] fromDecoder:contactDecoder];
        }

        // The code that creates Contact rows in db is buggy so we have a workaround below
        // Don't show empty contacts and don't show duplicates
        if (contactToAdd != nil && ![existingQliqIds containsObject:[contactToAdd qliqId]] &&
            ([[contactToAdd firstName] length] > 0 || [[contactToAdd lastName] length] > 0))
        {
            [result addObject:contactToAdd];
            
            if ([[contactToAdd qliqId] length] > 0) {
                [existingQliqIds addObject:[contactToAdd qliqId]];
            }
        }
    }

    return result;
}

//Move to contactDBService? or to qliqUserDBService?
- (NSArray *)contactsAndUsersOnlyVisible:(BOOL)onlyVisible
{
    QliqDBService * dBService = [[QliqDBService alloc] init];
    QliqUser *currentUser = [UserSessionService currentUserSession].user;
    
    NSString *query = @"SELECT * FROM contact WHERE contact_id != ? AND status < ?";
    NSArray * decoders = [dBService decodersFromSQLQuery:query
                                                withArgs:@[@(currentUser.contactId),
                                                           @(ContactStatusInvitationInProcess)]];

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
    
//    NSString *query = [NSString stringWithFormat:@""
//                       "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
//                       "FROM %@ WHERE contact_id != ? AND status != ?", table];
//    
//    NSArray *decoders = [dBService decodersFromSQLQuery:query
//                                               withArgs:@[@(currentUser.contact.contactId),
//                                                          @(ContactStatusDeleted)]];
    
    NSString *query = [NSString stringWithFormat:@""
                       "SELECT contact_id, first_name, last_name, middle_name, group_name, email, status, type "
                       "FROM %@ WHERE contact_id != ? AND status < ?", table];
    
    NSArray *decoders = [dBService decodersFromSQLQuery:query
                                               withArgs:@[@(currentUser.contact.contactId),
                                                          @(ContactStatusInvitationInProcess)]];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    for (DBCoder *object in decoders) {
        id<DBCoding> objectLocal = [dBService objectOfClass:[Contact class] fromDecoder:object];
        [contacts addObject:objectLocal];
    }

    
    return contacts;
}

- (NSArray *)getOnlyContacts
{
    NSMutableArray *mutableResult = [NSMutableArray arrayWithArray:[self contactsOnly]];
    
    QliqAddressBookContactGroup *iPhoneAddressBookContactsGroup = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObjectsFromArray:[iPhoneAddressBookContactsGroup getVisibleContacts]];
    
    return mutableResult;
}

- (NSArray *)getVisibleContacts
{
    NSMutableArray *mutableResult = [[NSMutableArray alloc] init];
    [mutableResult addObjectsFromArray:[self contactsAndUsersOnlyVisible:YES]];
    
    QliqAddressBookContactGroup *iPhoneAddressBookContactsGroup = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObjectsFromArray:[iPhoneAddressBookContactsGroup getVisibleContacts]];
    
    return mutableResult;
}

- (NSArray*)getContacts
{
    NSMutableArray *mutableResult = [[NSMutableArray alloc] init];
    [mutableResult addObjectsFromArray:[self contactsAndUsersOnlyVisible:NO]];
    
    QliqAddressBookContactGroup *iPhoneAddressBookContactsGroup = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObjectsFromArray:[iPhoneAddressBookContactsGroup getContacts]];
    
    return mutableResult;
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible
{
    NSMutableArray *mutableResult = [[NSMutableArray alloc] init];
    [mutableResult addObjectsFromArray:[self contactsAndUsersOnlyVisible:onlyVisible withLimitFrom:startIndex to:countIndex]];
    
    QliqAddressBookContactGroup *iPhoneAddressBookContactsGroup = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObjectsFromArray:[iPhoneAddressBookContactsGroup getVisibleContacts]];
    
    return mutableResult;
}

- (void)addContact:(Contact *)contact {
}

@end

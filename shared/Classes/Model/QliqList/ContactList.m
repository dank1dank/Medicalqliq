//
//  QliqList.m
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "ContactList.h"
#import "QliqListService.h"

@implementation ContactList

@synthesize contactListId, name;

+ (ContactList*)listWithResultSet:(FMResultSet*)resultSet
{
    ContactList *list = [[ContactList alloc] init];
    list.contactListId = [resultSet intForColumn:@"contactlist_id"];
    list.qliqId = [resultSet stringForColumn:@"qliq_id"];
    list.name = [resultSet stringForColumn:@"name"];
    
    return list;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ContactList class]])
    {
        ContactList * list = (ContactList*)object;
        return ((list.contactListId == self.contactListId) && ([list.name isEqualToString:self.name]) && (list.qliqId == self.qliqId));
    }
    return NO;
}

- (NSUInteger)getPendingCount{
    return 0;
}

- (NSString *)recipientQliqId {
    return self.qliqId;
}

#pragma mark - ContactQliqGroup

- (BOOL)locked {
    return NO;
}

- (NSArray *)getNewContacts {
    return [NSArray array];
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible {
    return [self getContacts];
}

- (NSArray *)getVisibleContacts {
    return [self getContacts];
}

- (NSArray *)getOnlyContacts {
    NSArray *rezult = [[QliqListService sharedService] getOnlyUsersOfList:self];
    return rezult;
}

- (NSArray*)getContacts {
    return [[QliqListService sharedService] getContactsAndUsersOfList:self];
}

#pragma mark - Recipient protocol

- (BOOL)isRecipientEnabled {
    return YES;
}

- (NSString *)recipientTitle {
    return self.name;
}

#pragma mark - Searchable protocol

- (NSString *)searchDescription {
    return self.name;
}

@end

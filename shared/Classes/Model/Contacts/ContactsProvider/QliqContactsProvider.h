//
//  QliqContactsProvider.h
//  qliqConnect
//
//  Created by Ravi Ada on 12/7/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsProvider.h"

@protocol ContactGroup;

@interface QliqContactsProvider : NSObject <ContactsProvider>
{
    NSMutableArray *contactsForSearching;
}

- (NSObject <ContactGroup>*) getAllContactsGroup;
- (NSObject <ContactGroup> *)getOnlyQliqUsersGroup;
- (NSObject <ContactGroup>*) getIPhoneContactsGroup;
- (NSObject <ContactGroup>*) getDndQliqUsersGroup;
- (NSObject <ContactGroup> *)getOnlineQliqUsersGroup;
- (NSObject <ContactGroup>*) getAwayQliqUsersGroup;
- (NSArray *) getUserGroups;
- (NSArray *) getUserLists;
- (NSArray *) getOnCallGroups;
- (NSObject <ContactGroup>*) getInvitationGroup;
@end

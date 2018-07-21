//
//  ContactGroup.h
//  qliqConnect
//
//  Created by Paul Bar on 11/30/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "SearchOperation.h"

@class Contact;

//Protocol that should be implemented by all items in group list
@protocol GroupListItem <NSObject>

@optional
- (NSString*) name;
- (NSUInteger) getPendingCount; 

@end

@protocol ContactGroup <GroupListItem>

@optional

- (BOOL) locked;

- (void) addContact:(Contact *)contact;

- (NSArray*) getContacts;
- (NSArray*) getNewContacts;
- (NSArray*) getOnlyContacts;
- (NSArray*) getVisibleContacts;
- (NSArray*) getSearchContactsWithSearchString:(NSString*)searchString;
- (NSArray*) getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible;

@end

@protocol InvitationGroup <GroupListItem>

- (NSArray*) getSentInvitations;
- (NSArray*) getReceivedInvitations;

@end
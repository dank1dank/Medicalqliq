//
//  QliqContactsProvider.m
//  qliqConnect
//
//  Created by Ravi Ada on 12/7/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqContactsProvider.h"
#import "QliqAddressBookContactGroup.h"
#import "QliqContactsGroup.h"
#import "QliqDndContactsGroup.h"

#import "ContactsDBObjects.h"
#import "QliqAllContactsGroup.h"
//#import "QliqReferralsGroup.h"
#import "MockContactGroup.h"
#import "QliqGroupDBService.h"
#import "QliqInvitationGroup.h"
#import "QliqListService.h"

#import "QliqUserDBService.h"
#import "UserSessionService.h"
#import "OnCallGroup.h"

@interface NSString ( containsCategory )

- (BOOL) containsString: (NSString*) substring;

@end

// - - - - 

@implementation NSString ( containsCategory )

- (BOOL) containsString: (NSString*) substring
{    
    NSRange range = [self rangeOfString : substring options:NSCaseInsensitiveSearch];
    
    BOOL found = ( range.location != NSNotFound );
    
    return found;
}

@end

@implementation QliqContactsProvider

-(id) init
{
    self = [super init];
    if(self)
    {
        contactsForSearching = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [contactsForSearching release];
    [super dealloc];
}

- (NSObject <ContactGroup> *)getAllContactsGroup {
    return [[[QliqAllContactsGroup alloc] init] autorelease];
}

- (NSObject <ContactGroup> *)getOnlyQliqUsersGroup {
    return [[[QliqContactsGroup alloc] init] autorelease];
}

- (NSObject <ContactGroup> *) getIPhoneContactsGroup {
    return [[[QliqAddressBookContactGroup alloc] init] autorelease];
}

- (NSObject <ContactGroup> *)getDndQliqUsersGroup {
    QliqDndContactsGroup *group = [[[QliqDndContactsGroup alloc] init] autorelease];
    group.pressenceStatus = DoNotDisturbPresenceStatus;
    return group;
}

- (NSObject <ContactGroup> *)getAwayQliqUsersGroup {
    QliqDndContactsGroup *group = [[[QliqDndContactsGroup alloc] init] autorelease];
    group.pressenceStatus = AwayPresenceStatus;
    return group;
}

- (NSObject <ContactGroup> *)getOnlineQliqUsersGroup {
    QliqDndContactsGroup *group = [[[QliqDndContactsGroup alloc] init] autorelease];
    group.pressenceStatus = OnlinePresenceStatus;
    return group;
}

//- (NSObject <ContactGroup> *)getAwayQliqUsersGroup {
//    return [[[QliqContactsGroup alloc] init] autorelease];
//}

- (NSArray *)getUserGroups
{
    NSArray * userGroups = [[QliqGroupDBService sharedService] getGroupsOfUser:[UserSessionService currentUserSession].user];
    return [userGroups sortedArrayWithOptions:NSOrderedAscending usingComparator:^NSComparisonResult(QliqGroup * obj1, QliqGroup * obj2) {
        return [[obj1.name uppercaseString] compare:[obj2.name uppercaseString]];
    }];
}

- (NSArray *) getUserLists {
    return [[QliqListService sharedService] getLists];
}

- (NSArray *) getOnCallGroups {
    NSArray *groups = [OnCallGroup onCallGroups];
    return [groups sortedArrayWithOptions:NSOrderedAscending usingComparator:^NSComparisonResult(QliqGroup * obj1, QliqGroup * obj2) {
        return [obj1.name caseInsensitiveCompare:obj2.name];
    }];
}

- (NSObject <InvitationGroup> *) getInvitationGroup{
    return [[[QliqInvitationGroup alloc] init] autorelease];
}


-(NSArray*) getContactGroups
{
    NSMutableArray *mutableResult = [[NSMutableArray alloc] init];
    
    //All contacts
    QliqAllContactsGroup *allContactsGroup = [[QliqAllContactsGroup alloc] init];
    [mutableResult addObject:allContactsGroup];
    [allContactsGroup release];
    
    //qliq user groups
    [mutableResult addObjectsFromArray:[[QliqGroupDBService sharedService] getGroups]];
    
    //iPhone address book
    QliqAddressBookContactGroup *cg = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObject:cg];
    [cg release];
    
    NSArray *rez = [NSArray arrayWithArray:mutableResult];
    [mutableResult release];
    return rez;
}

- (void)searchContactsAsync:(NSString *)predicate{
    [NSException raise:@"Incoplete implementation" format:@"method 'searchContactsAsync' is not impelmented in qliqContactsProviedr"];
}

-(NSArray*) searchContacts:(NSString *)predicate
{
	QliqAllContactsGroup *allContactsGroup = [[QliqAllContactsGroup alloc] init];
    NSArray *contacts = [allContactsGroup getVisibleContacts];
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:[contacts count]];

    for(Contact * contact in contacts)
    {
        if([[contact nameDescription] containsString:predicate]
           || [[contact email] containsString:predicate])
        {
            [mutableRez addObject:contact];
        }
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
	[allContactsGroup release];
    return  rez;
}

-(NSArray*)getContactRequests
{
    NSMutableArray *contactRequests = [[NSMutableArray alloc] init];
    /*
    QliqContact *contact = [[QliqContact alloc] init];
    contact.firstName = @"Request";
    contact.lastName = @"Test";
    
    [contactRequests addObject:contact];
    */
    NSArray *rez = [NSArray arrayWithArray:contactRequests];
    [contactRequests release];
    return rez;
}

@end

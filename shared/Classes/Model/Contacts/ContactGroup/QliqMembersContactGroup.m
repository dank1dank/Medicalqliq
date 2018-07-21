//
//  QliqMembersContactGroup.m
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqMembersContactGroup.h"
#import "QliqGroupDBService.h"
//#import "ReferringProviderDbService.h"
#import "QliqGroup.h"

@implementation QliqMembersContactGroup

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible{return nil;}

-(NSString*) name
{
    return @"Qliq Members";
}

- (BOOL)locked
{
    return FALSE;
}


-(void) addContact:(Contact *)contact
{
    
}

- (NSUInteger)getPendingCount{
    uint count = 0;
    NSArray * contacts = [self getContacts];
    for (Contact *contact in contacts){
        if (contact.contactStatus == ContactStatusNew) count++;
    }
    return count;
}

- (NSArray *)getNewContacts{
    NSMutableArray * newContacts = [[NSMutableArray alloc] init];
    NSArray * contacts = [self getContacts];
    for (Contact * contact in contacts){
        if (contact.contactStatus == ContactStatusNew)
            [newContacts addObject:contact];
    }
    
    if ([newContacts count] == 0) {
        [newContacts release];
        newContacts = nil;
    } else {
        [newContacts autorelease];
    }
    return newContacts;
}

- (NSArray *) getOnlyContacts{
    return [self getContacts];
}

- (NSArray *) getVisibleContacts{
    return [self getContacts];
}


-(NSArray*) getContacts
{    
    NSMutableArray * resultArray = [NSMutableArray array];
    
    NSArray *qliqUserGroups = [[QliqGroupDBService sharedService] getGroups];
    for (QliqGroup *group in qliqUserGroups) {
        
        for (Contact * contact in [group getContacts]){
            if (![resultArray containsObject:contact]){ 
                [resultArray addObject:contact];
            }
        }
    }
    
    /*ReferringProviderDbService *referralsService = [[ReferringProviderDbService alloc] init];
    NSArray *referrals = [referralsService getReferringProviders];
    [referralsService release];
    
    for(ReferringProvider *provider in referrals)
    {
        if([provider isQliqMember])
        {
            [mutableResult addObject:provider];
        }
    }*/

    return resultArray;//[resultSet allObjects];
}

@end

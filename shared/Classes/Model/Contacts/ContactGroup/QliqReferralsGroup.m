//
//  QliqReferralsGroup.m
//  qliqConnect
//
//  Created by Ravi Ada on 12/8/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqReferralsGroup.h"
#import "ContactsDBObjects.h"
#import "Physician.h"
#import "ReferringProvider.h"
#import "ReferringProviderDbService.h"

#define ARC4RANDOM_MAX      0x100000000

@interface QliqReferralsGroup()

-(BOOL) alreadyInReferrals:(id<Contact>) contact;

@end

@implementation QliqReferralsGroup
@synthesize name;

-(id) init
{
    self = [super init];
    if(self)
    {
        self.name = @"Referrals";
    }
    return self;
}

-(NSArray*) getContacts
{
    //NSArray *rez = [ReferringPhysician getReferralPhysiciansToDisplay];
	ReferringProviderDbService *rpDbService = [[ReferringProviderDbService alloc] init];
    NSArray *rez = [rpDbService getReferringProviders];

    for(id<Contact> contact in rez)
    {
        [contact setGroupName:self.name];
    }
	[rpDbService release];
    return rez;
}


-(void) addContact:(id<Contact>)contact
{
    if(![self alreadyInReferrals:contact])
    {
		ReferringProviderDbService *rpDbService = [[ReferringProviderDbService alloc] init];
        ReferringProvider *refProvider = [[ReferringProvider alloc] init];
        refProvider.firstName = [contact firstName];
		refProvider.lastName = [contact lastName];
		refProvider.middleName = [contact middleName];
		refProvider.credentials = [contact credentials];
        refProvider.phone = [contact phone];
        refProvider.mobile = [contact mobile];
        refProvider.email = [contact email];
        refProvider.taxonomyCode = [contact taxonomyCode];
        //TIP:
        //we need to get NPI somehow...
		double val = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 9000000000.0f);
		refProvider.npi = val;
        [rpDbService saveReferringProvider:refProvider];
        [refProvider release];
		[rpDbService release];
    }
}

#pragma mark -
#pragma mark Private

-(BOOL) alreadyInReferrals:(id<Contact>)contact //TODO this method needs optimization
{
    NSArray *referrals = [self getContacts]; //right here
    for(id<Contact> referral in referrals)
    {
        if([[referral nameDescription] isEqualToString:[contact nameDescription]])
        {
            return YES;
        }
    }
    return NO;
}

@end

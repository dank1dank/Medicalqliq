//
//  ApplicationsSubscription.m
//  qliq
//
//  Created by Paul Bar on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ApplicationsSubscription.h"
#import "GetGroupInfoResponseSchema.h"

@interface ApplicationsSubscription()

-(id) initWithArray:(NSArray *)array;

@end

@implementation ApplicationsSubscription

+(ApplicationsSubscription *)applicationSubscriptionWithArray:(NSArray *)appSubscription
{
    ApplicationsSubscription *rez = [[ApplicationsSubscription alloc] initWithArray:appSubscription];
    return [rez autorelease];
}

-(id) initWithArray:(NSArray *)array
{
    self = [super init];
    if(self)
    {
        applicationSubscriprions = [[NSMutableArray alloc] init];
        [applicationSubscriprions addObjectsFromArray:array];
    }
    return self;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        applicationSubscriprions = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [applicationSubscriprions release];
    [super dealloc];
}

-(BOOL) subscriptionContains:(EAplicationsSubscriprion)application
{
    BOOL result = NO;
    
    switch (application)
    {
        case ApplicationsSubscriptionQliqCharge:
        {
            if([applicationSubscriprions containsObject:@"qliq_charge"])
            {
                result = YES;
            }
        }break;
        case ApplicationsSubscriptionQliqCare:
        {
            if([applicationSubscriprions containsObject:@"qliq_care"])
            {
                result = YES;
            }
        }break;
        case ApplicationsSubscriptionQliqConnect:
        {
            if([applicationSubscriprions containsObject:@"qliq_connect"])
            {
                result = YES;
            }
        }break;
            
        default:
            break;
    }
    
    return result;
}

#pragma mark -
#pragma mark serialization

static NSString *key_subscriptions = @"key_subscriptions";

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:applicationSubscriprions forKey:key_subscriptions];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        applicationSubscriprions = [aDecoder decodeObjectForKey:key_subscriptions];
        [applicationSubscriprions retain];
    }
    return self;
}


@end
//
//  ApplicationsSubscription.h
//  qliq
//
//  Created by Paul Bar on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    ApplicationsSubscriptionQliqCharge = 0,
    ApplicationsSubscriptionQliqCare = 1,
    ApplicationsSubscriptionQliqConnect = 2
}EAplicationsSubscriprion;

@interface ApplicationsSubscription : NSObject<NSCoding>
{
    NSMutableArray *applicationSubscriprions;
}

+(ApplicationsSubscription*) applicationSubscriptionWithArray:(NSArray*)appSubscription;

-(BOOL) subscriptionContains:(EAplicationsSubscriprion)application;

@end



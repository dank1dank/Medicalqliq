//
//  FeatiureRate.m
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeatureRequest.h"
#import "Feature.h"

@implementation FeatureRequest

@synthesize feature;
@synthesize requestType;

-(id) initWithFeature:(Feature *)_feature andRequestType:(NSString *)_rate
{
    self = [super init];
    if(self)
    {
        feature = [_feature retain];
        requestType = [_rate retain];
    }
    return self;
}

-(void) dealloc
{
    [feature release];
    [requestType release];
    [super dealloc];
}

@end

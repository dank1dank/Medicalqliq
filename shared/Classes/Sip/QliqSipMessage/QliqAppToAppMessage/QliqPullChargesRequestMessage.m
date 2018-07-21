//
//  QliqPushChargesRequest.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqPullChargesRequestMessage.h"
#import "ChargesRequestSchema.h"

@implementation QliqPullChargesRequestMessage

@synthesize dataDict;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.dataDict = [dict objectForKey: CHARGES_REQUEST_MESSAGE_DATA];
    }
    return self;
}

-(void) dealloc
{
    [self.dataDict release];
    [super dealloc];
}

@end

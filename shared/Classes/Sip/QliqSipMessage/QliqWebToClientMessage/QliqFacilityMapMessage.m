//
//  QliqFacilityMapMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqFacilityMapMessage.h"
#import "GetFacilityMapResponseSchema.h"

@implementation QliqFacilityMapMessage
@synthesize dataArray;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.dataArray = [dict objectForKey:GET_FACILITY_MAP_RESPONSE_MESSAGE_DATA];
    }
    return self;
}

-(void)dealloc
{
    [self.dataArray release];
    [super dealloc];
}

@end

//
//  PushAppointmentsMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqPushAppointmentsMessage.h"

@implementation QliqPushAppointmentsMessage
@synthesize dataArray;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.dataArray = [dict objectForKey:@"Data"];
    }
    return self;
}


-(void) dealloc
{
    [self.dataArray release];
    [super dealloc];
}



@end

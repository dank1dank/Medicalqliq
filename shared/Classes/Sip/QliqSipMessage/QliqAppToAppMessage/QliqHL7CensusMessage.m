//
//  QliqHL7CensusMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqHL7CensusMessage.h"
#import "Hl7MessageSchema.h"

@implementation QliqHL7CensusMessage
@synthesize censuses;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.censuses = [dict objectForKey:HL7_MESSAGE_MESSAGE_DATA];
    }
    return self;
}

-(void) dealloc
{
    [self.censuses release];
    [super dealloc];
}
@end

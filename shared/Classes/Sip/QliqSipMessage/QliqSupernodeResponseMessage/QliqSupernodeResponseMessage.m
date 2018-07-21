//
//  QliqSupernodeResponseMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSupernodeResponseMessage.h"
#import "MessageSchema.h"
#import "Buddy.h"

#import "QliqAppointmentMessage.h"
#import "QliqCensusMessage.h"
#import "QliqPutCensusRequest.h"

@implementation QliqSupernodeResponseMessage

+(QliqSupernodeResponseMessage*) qliqSupernodeResponseMessageWithDictionary:(NSDictionary *)dict
{
    NSString *command = [dict objectForKey:MESSAGE_MESSAGE_COMMAND];
	NSString *subject = [dict objectForKey:MESSAGE_MESSAGE_SUBJECT];
    
    QliqSupernodeResponseMessage *rez = nil;
    
    if ([command compare:@"query"] == NSOrderedSame)
    {
        if ([subject compare:@"census"] == NSOrderedSame)
        {
            rez = [[QliqCensusMessage alloc] initWithDictionary:dict];
        }
        else if ([subject compare:@"appointment"] == NSOrderedSame)
        {
            rez = [[QliqAppointmentMessage alloc] initWithDictionary:dict];
        }
    }
    else if ([command compare:@"put"] == NSOrderedSame)
    {
        if ([subject compare:@"census"] == NSOrderedSame)
        {
            rez = [[QliqPutCensusRequest alloc] initWithDictionary:dict];
        }
    }
    return [rez autorelease];
}

@end

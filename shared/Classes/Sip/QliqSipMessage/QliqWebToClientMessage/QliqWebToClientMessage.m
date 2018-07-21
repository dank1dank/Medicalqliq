//
//  QliqWebToClientMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqWebToClientMessage.h"
#import "MessageSchema.h"
#import "GetFacilityMapResponseSchema.h"
#import "QliqFacilityMapMessage.h"

@implementation QliqWebToClientMessage

+(QliqWebToClientMessage*) qliqWebToClientMessageWithDictionary:(NSDictionary *)dict
{
    NSString *command = [dict objectForKey:MESSAGE_MESSAGE_COMMAND];
	NSString *subject = [dict objectForKey:MESSAGE_MESSAGE_SUBJECT];
    
    QliqWebToClientMessage *rez = nil;
    
    if ([command compare:GET_FACILITY_MAP_RESPONSE_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
        [subject compare:GET_FACILITY_MAP_RESPONSE_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        rez = [[QliqFacilityMapMessage alloc] initWithDictionary:dict];
    }
    
    return [rez autorelease];
}

@end

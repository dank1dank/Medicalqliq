//
//  QliqAppToAppMessage.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqAppToAppMessage.h"
#import "MessageSchema.h"
#import "ChargesRequestSchema.h"
#import "Hl7MessageSchema.h"
#import "JSONSchemaValidator.h"
#import "QliqHL7CensusMessage.h"
#import "PublickeyChangedNotificationSchema.h"

#import "QliqPushAppointmentsMessage.h"
#import "QliqPullChargesRequestMessage.h"
#import "QliqSupernodeNotificationMessage.h"

@implementation QliqAppToAppMessage

+(QliqAppToAppMessage*)qliqAppToAppMessageWithDictionary:(NSDictionary *)dict
{
    NSString *command = [dict objectForKey:MESSAGE_MESSAGE_COMMAND];
	NSString *subject = [dict objectForKey:MESSAGE_MESSAGE_SUBJECT];
    
    QliqAppToAppMessage *rez = nil;
    
    if ([command compare:@"push"] == NSOrderedSame && [subject compare:@"appointments"] == NSOrderedSame)
    {
        rez = [[QliqPushAppointmentsMessage alloc] initWithDictionary:dict];
    }
    else if ([command compare:CHARGES_REQUEST_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
        [subject compare:CHARGES_REQUEST_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        rez = [[QliqPullChargesRequestMessage alloc] initWithDictionary:dict];
    }
    else if ([command compare:HL7_MESSAGE_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
             [subject compare:HL7_MESSAGE_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        rez = [[QliqPullChargesRequestMessage alloc] initWithDictionary:dict];
    }
    else if ([command compare:PUBLICKEY_CHANGED_NOTIFICATION_MESSAGE_COMMAND_PATTERN] == NSOrderedSame)
    {
        rez = [[QliqSupernodeNotificationMessage alloc] initWithDictionary:dict];
    }    
    return [rez autorelease];
}

@end

//
//  QliqUserToUserMessage.m
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqUserToUserMessage.h"
#import "JsonSchemas.h"
#import "QliqSipChatMessage.h"
#import "QliqSipExtendedChatMessage.h"

@implementation QliqUserToUserMessage

+(QliqUserToUserMessage*) qliqUserToUserMessageWithDictionary:(NSDictionary *)dict
{
    NSString *command = [dict objectForKey:MESSAGE_MESSAGE_COMMAND];
    NSString *subject = [dict objectForKey:MESSAGE_MESSAGE_SUBJECT];
    QliqUserToUserMessage *rez = nil;

    if ([command isEqualToString:CHAT_MESSAGE_MESSAGE_COMMAND_PATTERN] &&
        [subject isEqualToString:CHAT_MESSAGE_MESSAGE_SUBJECT_PATTERN])
    {
        rez = [[QliqSipChatMessage alloc] initWithDictionary:dict];
    }
    else if ([command isEqualToString:EXTENDED_CHAT_MESSAGE_MESSAGE_COMMAND_PATTERN] &&
             [subject isEqualToString:EXTENDED_CHAT_MESSAGE_MESSAGE_SUBJECT_PATTERN])
    {	
        rez = [[QliqSipExtendedChatMessage alloc] initWithDictionary:dict];
    }
    
    return [rez autorelease];
}
 
-(id) init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
    }
    return self;
}


@end

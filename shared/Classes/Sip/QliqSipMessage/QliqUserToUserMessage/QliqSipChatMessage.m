//
//  QliqSipChatMessage.m
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipChatMessage.h"
#import "ChatMessageSchema.h"

@implementation QliqSipChatMessage
@synthesize messageText;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.messageText = [dict objectForKey:CHAT_MESSAGE_MESSAGE_DATA];
    }
    return self;
}

-(void)dealloc
{
    [messageText release];
    [super dealloc];
}

@end

//
//  QliqSipExtendedChatMessage.m
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipExtendedChatMessage.h"
#import "ExtendedChatMessageSchema.h"
#import "Helper.h"

@implementation QliqSipExtendedChatMessage

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        NSDictionary *data = [dict objectForKey:EXTENDED_CHAT_MESSAGE_MESSAGE_DATA];
        self.messageText = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_TEXT];
        self.messageId = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_MESSAGE_ID];
        self.conversationSubject = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_CONVERSATION_SUBJECT];
        self.conversationUuid = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_CONVERSATION_UUID];
        self.recipientType = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_RECIPIENT_TYPE];
       
        NSNumber *requireAck_ =  [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_REQUIRES_ACKNOWLEDGEMENT];
        
        self.requireAck = [requireAck_ boolValue];
        self.priority = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_PRIORITY];
        self.dataType = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_TYPE];

        NSString *toUserIdStr = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_TO_USER_ID];
       
        if ([toUserIdStr isKindOfClass:[NSNumber class]]) {
            toUserIdStr = [(NSNumber *)toUserIdStr stringValue];
        }
        
        if ([toUserIdStr length] > 0)
            self.toUserId = toUserIdStr;
        
        NSString *createdAtStr = [data objectForKey:EXTENDED_CHAT_MESSAGE_DATA_CREATED_AT];
        
        if ([createdAtStr isKindOfClass:[NSNumber class]]) {
            createdAtStr = [(NSNumber *)createdAtStr stringValue];
        }
        
        if ([createdAtStr length] > 0)
            self.createdAt = [Helper strDateTimeISO8601ToInterval:createdAtStr];

    }
    return self;
}

- (void)setConversationUuid:(NSString *)conversationUuid {

    if ([conversationUuid isKindOfClass:[NSString class]]) {
        _conversationUuid = conversationUuid;
    }
}

@end

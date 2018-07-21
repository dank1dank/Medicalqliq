//
//  QliqSipExtendedChatMessage.h
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqUserToUserMessage.h"

@interface QliqSipExtendedChatMessage : QliqUserToUserMessage

@property (nonatomic, retain) NSString *messageId;
@property (nonatomic, retain) NSString *messageText;
@property (nonatomic, retain) NSString *conversationSubject;
@property (nonatomic, retain) NSString *conversationUuid;
@property (nonatomic, readwrite) BOOL requireAck;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *dataType;
@property (nonatomic, readwrite) NSTimeInterval createdAt;
@property (nonatomic, retain) NSString *toUserId;
@property (nonatomic, retain) NSString *recipientType;

@end

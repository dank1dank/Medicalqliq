//
//  MessageStatusLogDBService.h
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "MessageStatusLog.h"
#import "FMDatabase.h"

@class ChatMessage;

@interface MessageStatusLogDBService : NSObject 
+ (MessageStatusLogDBService *) sharedService;

- (NSArray*) getMessageStatusLogForMessage:(ChatMessage*)message;

- (BOOL) saveMessageStatusLog:(MessageStatusLog*)messageStatusLog;
- (BOOL) deleteWithMessageId:(int)messageId inDB:(FMDatabase *)database;
- (BOOL) deleteMessageStatusLogForMessage:(ChatMessage *)message withStatus:(NSInteger)status inDB:(FMDatabase *)database;

@end

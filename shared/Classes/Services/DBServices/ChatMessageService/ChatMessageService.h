//
//  ChatMessageService.h
//  qliq
//
//  Created by Paul Bar on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



@class ChatMessage, Conversation, FMDatabase;

#define DBHelperConversationDidAddMessage @"DBHelperConversationDidAddMessage"

#define kMessageSavedAsRead @"MessageSavedAsRead"
#define kMessagesSavedAsRead @"MessagesSavedAsRead"

@interface ChatMessageService : NSObject
+ (ChatMessageService *) sharedService;

- (BOOL) messageExists:(ChatMessage *)chatMessage;
- (BOOL) saveMessage:(ChatMessage*)chatMessage;
- (BOOL) saveMessage:(ChatMessage *)chatMessage inConversation:(Conversation *)conversation;
- (NSString *) uuidForMessageId:(int)messageId;
- (BOOL) deleteWithMessageId:(int)messageId;
- (BOOL) markAsDeletedMessagesOlderThenAndDirty:(NSTimeInterval)timestamp;
- (void) markAllSendingMessagesAsTimedOutForUser:(NSString *) qliqId;

- (void)markMessageAsRead:(ChatMessage *)message withDelay:(double)delay;
- (void)markMessagesAsRead:(NSArray *)messages withDelay:(double)delay;

+ (ChatMessage *) getMessageWithUuid:(NSString *)uuid;
+ (ChatMessage *) getMessage:(NSInteger)messageId;
- (ChatMessage *) getLatestMessageInConversation:(NSInteger)conversationId;
- (NSArray *) getMessagesForConversation:(NSInteger)conversationId pageSize:(NSInteger)pageSize pageOffset:(NSInteger)pageOffset;

- (void) setRevisionDirtyForUuid:(NSString *)uuid dirty:(BOOL)aDirty;
- (void) setRevisionDirtyForMessageId:(NSInteger)messageId dirty:(BOOL)aDirty;
- (NSArray *) getMessageIdsOlderThenAndNotDirty:(NSTimeInterval)timestamp inDB:(FMDatabase *)database;

@end

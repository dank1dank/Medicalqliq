//
//  DBHelperConversation.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/13/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"
#import "MessageAttachment.h"
#import "Conversation.h"


@interface DBHelperConversation : NSObject

/* Conversation-related tasks
 * TODO: Move to ConversationDBService */

+ (NSInteger) getLastUpdatedConversationId:(NSString *) qliqId andSubject:(NSString *) subject;
+ (NSInteger) getLastUpdatedConversationId:(NSString *) qliqId andSubject:(NSString *) subject inDB:(FMDatabase *)dbFromQueue;
+ (BOOL) deleteAllConversations:(FMDatabase *)database;
+ (BOOL) hasUserWithId:(NSString *)qliqId alreadySentMessageForConversation:(NSInteger)conversationId;

/* ChatMessage-related tasks
 * TODO: Move to ChatMessageDBService */

+ (NSMutableArray *) getMessagesForConversation:(NSInteger)conversationId limit:(NSUInteger) _limit;
+ (NSMutableArray*) getMessagesForConversation:(NSInteger)conversationId pageSize:(NSInteger)pageSize pageOffset:(NSInteger)pageOffset;
+ (ChatMessage *) getLatestMsg:(NSInteger) conversationId;
+ (NSMutableArray *) getMessagesForConversation:(NSInteger)conversationId limit:(NSUInteger) _limit inDB:(FMDatabase*)database;
+ (NSArray *) getUndeliveredAcksToQliqId:(NSString *)qliqId limit:(NSInteger)aLimit offset:(NSInteger)anOffset;
+ (NSArray *) getUndeliveredAcksFromQliqId:(NSString *)qliqId limit:(NSInteger)aLimit offset:(NSInteger)anOffset;
+ (NSArray *) getUndeliveredOpenedStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset;
+ (NSArray *) getUndeliveredDeletedStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset;
+ (NSArray *) getUndeliveredRecalledStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset;

+ (ChatMessage*) getMessageWithGuid:(NSString *)guid inDB:(FMDatabase*) database;
+ (ChatMessage*) getMessage:(NSInteger)messageId inDB:(FMDatabase*) database;

+ (ChatMessage*) getMessage:(NSInteger)messageId;
+ (ChatMessage*) getMessageWithGuid:(NSString *)guid;

+ (BOOL) deleteAllMessages:(FMDatabase *)database;

+ (NSArray *) getUndeliveredMessagesWithStatusNotIn:(NSSet *)statuses toQliqId:(NSString *)toQliqId limit:(int)aLimit offset:(int)aOnffset;

+ (NSInteger) getOneUnpushedMessageIdFromUserWhereQliqStorNotIn :(NSString *)userId : (NSArray *)qliqStorIds;

+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt;
+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty;
+ (BOOL) saveAllUnreadMessagesInConversationAsRead:(NSInteger)conversationId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty;

@end

//
//  ConversationService.h
//  qliq
//
//  Created by Paul Bar on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FMDatabase.h"
#import "QliqDBService.h"

extern NSString *ConversationDidReadMessagesNotification;

@class Conversation;

@interface ConversationDBService : QliqDBService

+ (ConversationDBService *)sharedService;

- (BOOL)isRead:(Conversation *)conversation;
- (BOOL) isMuted:(NSInteger)conversationId;
- (void) updateMuted:(NSInteger)conversationId withMuted:(BOOL)muted;

- (NSInteger)countOfUnreadMessages:(Conversation *)conversation;
- (NSInteger)countOfUndeliveredMessages:(Conversation *)conversation;

- (NSUInteger)numberOfConversations; // TODO: CC
- (NSUInteger)numberOfArchivedConversations; // TODO: CC

- (NSUInteger)sizeOfAllConversations;

@end

@interface ConversationDBService (ManagedConversations)
/*
 For Single Conversation
 */
- (BOOL)saveConversation:(Conversation *)conversation;
- (void)deleteConversationButNotMessages:(Conversation *)conversation;
- (void)setDeleteFlag:(BOOL)deleted forConversationId:(NSInteger)conversationId;
- (void)markAllMessagesAsRead:(Conversation *)conversation;

/*
 For Multiply Conversations
 */
- (void)archiveConversations:(NSArray *)conversations;
- (void)restoreConversations:(NSArray *)conversations;
- (void)deleteConversations:(NSArray *)conversations;
- (void)deleteConversationsForUsers:(NSArray*)users; //delete all conversations, messages for users // TODO: CC

@end

@interface ConversationDBService (GetConversations)

- (NSInteger)getConversationId:(NSString *)qliqId andSubject:(NSString *)subject; // TODO: CC

- (Conversation *)getConversationWithId:(NSNumber *)conversationId;
- (Conversation *)getConversationWithUuid:(NSString *)uuid;

// Returns an array of Conversations that have displayable message for Recents list
// WARNING: only the fields required for the Recents view are populated
- (NSMutableArray *) getConversationsForRecentsViewArchived:(BOOL)archived careChannel:(BOOL)careChannel;
// Returns count of Conversations that have displayable message for Recents list
- (NSUInteger) countConversationsForRecentsViewArchived:(BOOL)archived careChannel:(BOOL)careChannel;

// Used only by [DBHelperConversation deleteAllConversations]: refactor and delete
- (NSArray *)getNotDeletedConversationsAndCareChannels;
- (NSArray *)getConversationsWithQliqId:(NSString *)qliqId;
- (NSArray *)getCareChannelsForPatient:(NSString *)patientUuid;
- (NSArray *)getConversationsWithoutQliqId;
- (NSArray *)getConversationsWithoutMessages;
- (NSArray *)getConversationsWithOnlyDeletedMessages;

@end

//
//  ChatMessageService.m
//  qliq
//
//  Created by Paul Bar on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatMessageService.h"
#import "ConversationDBService.h"
#import "DBHelperConversation.h"
#import "ChatMessage.h"
#import "Metadata.h"

#import "QliqConnectModule.h"

//AvailableNotifications
//extern NSString* DBHelperConversationDidAddMessage;


@interface ChatMessageService()

-(BOOL) messageExists:(ChatMessage*)chatMessage inDB:(FMDatabase*) dbParam;
-(BOOL) insertMessage:(ChatMessage*)chatMessage inDB:(FMDatabase*) dbParam;
-(BOOL) updateMessage:(ChatMessage*)chatMessage inDB:(FMDatabase*) dbParam;

@end

@implementation ChatMessageService

+ (ChatMessageService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ChatMessageService alloc] init];
        
    });
    return shared;
}

-(BOOL) saveMessage:(ChatMessage *)chatMessage
{
    Conversation * converstaion = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:chatMessage.conversationId]];
                                   
    return [self saveMessage:chatMessage inConversation:converstaion];
}

- (BOOL) saveMessage:(ChatMessage *)chatMessage inConversation:(Conversation *)conversation{
    __block BOOL messageSaved = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        if (chatMessage.messageId != 0 && [self messageExists:chatMessage inDB:db])
        {
            messageSaved = [self updateMessage:chatMessage inDB:db];
        }
        else
        {
            messageSaved = [self insertMessage:chatMessage inDB:db];
            
            if (messageSaved) {
//#warning RETURN
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatMessageStatus"
                                                                    object:nil
                                                                  userInfo:@{@"Message":chatMessage}];

                DDLogSupport(@"New chat message saved in DB with: id: %ld; uuid: %@; in conv_id = %ld; attachment = %i; subject: '%@';", (long)chatMessage.messageId,
                             chatMessage.metadata.uuid,
                             (long)chatMessage.conversationId,
                             chatMessage.hasAttachment,
                             chatMessage.subject.length <1 ? (conversation.subject.length <1 ? @"without subject" : conversation.subject) : chatMessage.subject);
                
                
                if ([chatMessage isNormalChatMessage]) {
                    DDLogSupport(@"Posting notification about new chat message saved in db");
                    NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation,@"Conversation",chatMessage,@"ChatMessage",nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:DBHelperConversationDidAddMessage object:nil userInfo:info];
                    [info release];
                } else {
                    DDLogSupport(@"Not posting notification about new chat message saved in db, because it's not a normal message");
                }
            }
        }

        if (!messageSaved) {
            DDLogError(@"Failed to save chat message in db. id: %ld, uuid: %@ in conv_id=%ld", (long)chatMessage.messageId, chatMessage.metadata.uuid, (long)chatMessage.conversationId);
        }
        
        //Save attachments
        if (messageSaved){
            for(MessageAttachment *attachment in chatMessage.attachments){
                attachment.messageUuid = chatMessage.uuid;
                if(![attachment save]){
                    DDLogError(@"Error during saving attachment for message: %ld",(long)chatMessage.messageId);
                }
            }
        }
    }];
    
    return messageSaved;
}

- (BOOL) messageExists:(ChatMessage *)chatMessage {
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self messageExists:chatMessage inDB:db];
    }];
    return ret;
}

- (NSString *) uuidForMessageId:(int)messageId
{
    __block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = [NSString stringWithFormat:@"SELECT uuid FROM message WHERE id = %d", messageId];
        FMResultSet *rs = [db executeQuery:selectQuery];
        if ([rs next]) {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

- (BOOL) deleteWithMessageId:(int)messageId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM message WHERE id = ?", [NSNumber numberWithInt:messageId]];
    }];
    return ret;
}

- (BOOL) markAsDeletedMessagesOlderThenAndDirty:(NSTimeInterval)timestamp
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"UPDATE message SET deleted = 1 WHERE is_rev_dirty = 'true' AND last_sent_at < ?";
        ret = [db executeUpdate:sql, [NSNumber numberWithDouble:timestamp]];
    }];
    return ret;
}

- (void)markMessageAsRead:(ChatMessage *)message withDelay:(double)delay {
    
    if ([message isRead]) {
        return;
    }
    
    if ([AppDelegate applicationState] == UIApplicationStateActive) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[QliqConnectModule sharedQliqConnectModule] saveMessageAsRead:message.messageId];
            [ChatMessage updateUnreadCountAsync];
           
            NSDictionary *info = @{@"messageUuid": message.uuid};
            [[NSNotificationCenter defaultCenter] postNotificationName:kMessageSavedAsRead object:nil userInfo:info];
        });
    }
}

- (void)markMessagesAsRead:(NSArray *)messages withDelay:(double)delay {
    
    if ([AppDelegate applicationState] == UIApplicationStateActive) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            for (ChatMessage *message in messages) {
                if ([message isRead] || [message isMyMessage])
                    continue;
                
                [[QliqConnectModule sharedQliqConnectModule] saveMessageAsRead:message.messageId];
            }
            
            [ChatMessage updateUnreadCountAsync];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMessagesSavedAsRead object:nil userInfo:nil];
        });
    }
}

#pragma mark -
#pragma mark Private

-(BOOL) messageExists:(ChatMessage *)chatMessage inDB:(FMDatabase *)db
{
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT message.id FROM message WHERE message.id = %ld",(long)chatMessage.messageId];
    FMResultSet *rs = [db executeQuery:selectQuery];
    BOOL ret = NO;
    if([rs next])
    {
        ret = YES;
    }
    [rs close];
    return ret;
}

-(BOOL) insertMessage:(ChatMessage *)chatMessage inDB:(FMDatabase *)dbParam
{
    if ([chatMessage.uuid length] == 0){
        chatMessage.uuid = [Metadata generateUuid];
    }

    NSString *insertQuery = @""
    " INSERT INTO message ( "
    " conversation_id, "
    " from_qliq_id, "
    " to_qliq_id, "
    " message, "
    " uuid, "
    " ack_required, "
    " priority, "
    " timestamp, "
    " self_delivery_status, "    
    " delivery_status, "
    " status_text, "
    " failed_attempts, "
    " last_sent_at, "
    " ack_received_at, " 
    " received_at, "
    " read_at, "
    " ack_sent_at, "
    " ack_sent_to_server_at, "
    " opened_sent, "
    " local_created_time, "
    " call_id, "
    " server_context, "
    " has_attachment, "
    " deleted, "
    " recall_status, "
    " type, "
    " total_recipient_count, "
    " delivered_recipient_count, "
    " opened_recipient_count, "
    " acked_recipient_count, "
    " text_height, "
    " uuid, "
    " rev, "
    " author, "
    " seq, "
    " is_rev_dirty "
    ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    BOOL rez = NO;
    
    
    
    // Set this field to YES if no set for any reason (bug) but has attachments
    if (chatMessage.hasAttachment == NO && [chatMessage.attachments count] > 0)
        chatMessage.hasAttachment = YES;
    
    rez = [dbParam executeUpdate:insertQuery,
           [NSNumber numberWithInteger:chatMessage.conversationId],
           chatMessage.fromQliqId,
           chatMessage.toQliqId,
           chatMessage.text,
           [chatMessage uuid],
           [NSNumber numberWithInt:chatMessage.ackRequired],
           [NSNumber numberWithInt: chatMessage.priority],
           [NSNumber numberWithDouble: chatMessage.timestamp],
           [NSNumber numberWithInteger: chatMessage.selfDeliveryStatus],
           [NSNumber numberWithInteger: chatMessage.deliveryStatus],
           chatMessage.statusText,
           [NSNumber numberWithInteger: chatMessage.failedAttempts],
           [NSNumber numberWithDouble: chatMessage.createdAt],
           [NSNumber numberWithDouble: chatMessage.ackReceivedAt],
           [NSNumber numberWithDouble: chatMessage.receivedAt],
           [NSNumber numberWithDouble: chatMessage.readAt],
           [NSNumber numberWithDouble: chatMessage.ackSentAt],
           [NSNumber numberWithDouble: chatMessage.ackSentToServerAt],
           [NSNumber numberWithBool: chatMessage.isOpenedSent],
           [NSNumber numberWithDouble: chatMessage.localCreationTimestamp],
           chatMessage.callId,
           chatMessage.serverContext,
           [NSNumber numberWithBool: chatMessage.hasAttachment],
           [NSNumber numberWithInt: chatMessage.deletedStatus],
           [NSNumber numberWithInt: chatMessage.recalledStatus],
           [NSNumber numberWithInt: chatMessage.type],
           [NSNumber numberWithInteger: chatMessage.totalRecipientCount],
           [NSNumber numberWithInteger: chatMessage.deliveredRecipientCount],
           [NSNumber numberWithInteger: chatMessage.openedRecipientCount],
           [NSNumber numberWithInteger: chatMessage.ackedRecipientCount],
           [NSNumber numberWithDouble: chatMessage.textHeight],
           chatMessage.metadata.uuid,
           chatMessage.metadata.rev,
           chatMessage.metadata.author,
           [NSNumber numberWithInt:chatMessage.metadata.seq],
           [NSNumber numberWithBool:chatMessage.metadata.isRevisionDirty]
           ];
    if(rez)
    {
        chatMessage.messageId = [dbParam lastInsertRowId];
        rez = YES;
    }
    return rez;
}

-(BOOL) updateMessage:(ChatMessage *)chatMessage inDB:(FMDatabase *)dbParam
{
    NSString *updateQuery = @""
    " UPDATE message SET "
    " conversation_id = ?,"
    " from_qliq_id = ?,"
    " to_qliq_id = ?,"
    " message = ?, "
    " uuid = ?, "
    " ack_required = ?, "
    " priority = ?, "
    " timestamp = ?, "
    " self_delivery_status = ?, "    
    " delivery_status = ?, "
    " status_text = ?, "
    " failed_attempts = ?, "
    " last_sent_at = ?, "
    " ack_received_at = ?, " 
    " received_at = ?, "
    " read_at = ?, "
    " ack_sent_at = ?, "
    " ack_sent_to_server_at = ?, "
    " opened_sent = ?, "
    " local_created_time = ?, "
    " call_id = ?, "
    " server_context = ?, "
    " has_attachment = ?, "
    " deleted = ?, "
    " recall_status = ?, "
    " type = ?, "
    " total_recipient_count = ?, "
    " delivered_recipient_count = ?, "
    " opened_recipient_count = ?, "
    " acked_recipient_count = ?, "
    " text_height = ?, "
    " uuid = ?, "
    " rev = ?, "
    " author = ?, "
    " seq = ?, "
    " is_rev_dirty = ? "
    " WHERE id = ? ";
    
    BOOL rez = NO;
    
    // Set this field to YES if no set for any reason (bug) but has attachments
    if (chatMessage.hasAttachment == NO && [chatMessage.attachments count] > 0)
        chatMessage.hasAttachment = YES;
    
    rez = [dbParam executeUpdate:updateQuery,
           [NSNumber numberWithInteger:chatMessage.conversationId],
           chatMessage.fromQliqId,
           chatMessage.toQliqId,
           chatMessage.text,
           [chatMessage uuid],
           [NSNumber numberWithInt:chatMessage.ackRequired],
           [NSNumber numberWithInt: chatMessage.priority],           
           [NSNumber numberWithDouble: chatMessage.timestamp],
           [NSNumber numberWithInteger: chatMessage.selfDeliveryStatus],
           [NSNumber numberWithInteger: chatMessage.deliveryStatus],
           chatMessage.statusText,
           [NSNumber numberWithInteger: chatMessage.failedAttempts],
           [NSNumber numberWithDouble: chatMessage.createdAt],
           [NSNumber numberWithDouble: chatMessage.ackReceivedAt],
           [NSNumber numberWithDouble: chatMessage.receivedAt],
           [NSNumber numberWithDouble: chatMessage.readAt],
           [NSNumber numberWithDouble: chatMessage.ackSentAt],
           [NSNumber numberWithDouble: chatMessage.ackSentToServerAt],
           [NSNumber numberWithBool: chatMessage.isOpenedSent],
           [NSNumber numberWithDouble: chatMessage.localCreationTimestamp],
           chatMessage.callId,
           chatMessage.serverContext,
           [NSNumber numberWithBool: chatMessage.hasAttachment],
           [NSNumber numberWithInt: chatMessage.deletedStatus],
           [NSNumber numberWithInt: chatMessage.recalledStatus],
           [NSNumber numberWithInt: chatMessage.type],
           [NSNumber numberWithInteger: chatMessage.totalRecipientCount],
           [NSNumber numberWithInteger: chatMessage.deliveredRecipientCount],
           [NSNumber numberWithInteger: chatMessage.openedRecipientCount],
           [NSNumber numberWithInteger: chatMessage.ackedRecipientCount],
           [NSNumber numberWithDouble: chatMessage.textHeight],
           chatMessage.metadata.uuid,
           chatMessage.metadata.rev,
           chatMessage.metadata.author,
           [NSNumber numberWithInt:chatMessage.metadata.seq],
           [NSNumber numberWithBool:chatMessage.metadata.isRevisionDirty],
           [NSNumber numberWithInteger:chatMessage.messageId]
           ];
    
    return rez;
}

+ (ChatMessage *) getMessageWithUuid:(NSString *)uuid
{
    __block ChatMessage *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [DBHelperConversation getMessageWithGuid:uuid inDB:db];
    }];
    return ret;
}

+ (ChatMessage *) getMessage:(NSInteger)messageId
{
    __block ChatMessage *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [DBHelperConversation getMessage:messageId inDB:db];
    }];
    return ret;
}

- (void) markAllSendingMessagesAsTimedOutForUser:(NSString *) qliqId
{
	NSString *updateQuery = @"UPDATE message SET delivery_status = 408, failed_attempts = (failed_attempts + 1) WHERE delivery_status = 0 AND from_qliq_id = ?";
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        [db executeUpdate:updateQuery, qliqId];
    }];
}

- (ChatMessage *) getLatestMessageInConversation:(NSInteger)conversationId
{
    return [DBHelperConversation getLatestMsg:conversationId];
}

- (void) setRevisionDirtyForUuid:(NSString *)uuid dirty:(BOOL)aDirty
{
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @"UPDATE message SET is_rev_dirty = ? WHERE uuid = ?";
        [db executeUpdate:updateQuery, [NSNumber numberWithBool:aDirty], uuid];
    }];
}

- (void) setRevisionDirtyForMessageId:(NSInteger)messageId dirty:(BOOL)aDirty
{
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @"UPDATE message SET is_rev_dirty = ? WHERE id = ?";
        [db executeUpdate:updateQuery, [NSNumber numberWithBool:aDirty], [NSNumber numberWithInteger:messageId]];
    }];
}

- (NSArray *) getMessagesForConversation:(NSInteger)conversationId pageSize:(NSInteger)aPageSize pageOffset:(NSInteger)pageOffset
{
    return [DBHelperConversation getMessagesForConversation:conversationId pageSize:aPageSize pageOffset:pageOffset];
}

- (NSArray *) getMessageIdsOlderThenAndNotDirty:(NSTimeInterval)timestamp inDB:(FMDatabase *)database
{
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    NSString *query = @"SELECT id FROM message WHERE is_rev_dirty = 0 AND last_sent_at < ?";
    FMResultSet *rs = [database executeQuery:query, [NSNumber numberWithDouble:timestamp]];
    while ([rs next])
    {
        [array addObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]]];
    }
    [rs close];
    return array;
}

@end

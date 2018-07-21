	//
//  DBHelperConversation.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/13/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "DBHelperConversation.h"
#import "DBUtil.h"
#import "Helper.h"
#import "MessageAttachmentDBService.h"
#import "NSDate+Helper.h"
#import "MediaFile.h"
#import "QliqUserDBService.h"
#import "ChatMessageService.h"

#import "ConversationDBService.h"

#import "QliqConnectModule.h"

#define METADATA_COLUMNS " uuid, rev, author, seq, is_rev_dirty "

// Defined in one place because shared between getChatMessagesWhere and getMessagesForConversation
//
// If you change this, change also allocChatMessageFromResultSet and chatMessageColumnArgs and add '?' in addMessage
#define MESSAGE_TABLE_COLUMNS "message.id, message.conversation_id, from_qliq_id, to_qliq_id, message, uuid, ack_required, priority, timestamp, " \
    " self_delivery_status, delivery_status, status_text, failed_attempts, last_sent_at, ack_received_at, received_at, read_at, ack_sent_at, ack_sent_to_server_at, opened_sent, local_created_time, call_id, server_context, has_attachment, message.deleted, recall_status, message.type, message.total_recipient_count, message.delivered_recipient_count, message.opened_recipient_count, message.acked_recipient_count, text_height, " METADATA_COLUMNS

typedef struct {
    NSInteger offset;
    NSInteger size;
} Limit;

typedef enum {
    ASC, DESC
} Order;

@interface DBHelperConversation()


+ (NSArray*) getMessagesWhere:(NSString *)whereQueue argumentsArray:(NSArray *)arguments order:(Order)order limit:(Limit)limit;

+ (void) fixDeliveryErrorCode: (ChatMessage *)message;
+ (NSMutableArray *) getChatMessagesWhere: (NSString *)whereQuery withArgumentsInArray:(NSArray *)arguments;

// The caller must release the ChatMessage object!
+ (ChatMessage *) allocChatMessageFromResultSet: (FMResultSet *) rs;
+ (NSMutableArray *) chatMessageColumnArgs: (ChatMessage *)msg;

@end

@implementation DBHelperConversation

#pragma mark -
#pragma mark Chat Messages


//Common method to get messages. To place request to database for messages in one place
+ (NSArray*) getMessagesWhere:(NSString *)whereQueue argumentsArray:(NSArray *)arguments order:(Order)order limit:(Limit)limit{
    
//    NSDate * startTime = [NSDate date];
	NSString *query = [NSString stringWithFormat:@"SELECT * from ( SELECT "
                       MESSAGE_TABLE_COLUMNS ", "
                       " conversation.subject, "
                       " trim(contact.first_name || ' ' || contact.last_name || '  ' || "
                       " CASE WHEN length(qliq_user.credentials) > 0 THEN qliq_user.credentials ELSE ' ' END) as display_name,  "
                       " sip_uri  "
                       " FROM message  "
                       " INNER JOIN conversation ON (message.conversation_id = conversation.id)  "// " INNER JOIN conversation_leg ON (conversation_leg.conversation_id = conversation.id)  "
                       " INNER JOIN qliq_user ON (message.from_qliq_id = qliq_user.qliq_id)  "
                       " INNER JOIN contact ON (qliq_user.contact_id = contact.contact_id)  "
                       " INNER JOIN sip_contact ON (qliq_user.qliq_id = sip_contact.contact_qliq_id)  "                       
                       " WHERE %@ "
                       " ORDER BY message.last_sent_at %@ "                                         //" ORDER BY message.timestamp %@ "
                       " LIMIT %ld,%ld ) t ORDER BY t.last_sent_at",                                //" LIMIT %ld,%ld ) t ORDER BY t.timestamp",
                       whereQueue,(order==ASC?@"ASC":@"DESC"),(long)limit.offset,(long)limit.size]; //SELECT * from ( ) t order by t.timestamp
    
    __block NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        while ([rs next]) {
            ChatMessage *message = [[self allocChatMessageFromResultSet:rs] autorelease];
            [results addObject:message];
            
            // As it is leaking about 144 bytes per call.
//            [message release];
        }
        [rs close];
    }];
    
    /* Load attachments for message */
    for (ChatMessage *message in results) {
        message.attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMessage:message];
    }
    
//    NSLog(@"Loaded %d messages from db for %g. WHERE %@ , %@",limit.size,-[startTime timeIntervalSinceNow], whereQueue,[arguments lastObject]);
	return results;
}

+ (NSArray*)getMessagesWhere:(NSString *)whereQueue argumentsArray:(NSArray *)arguments {
    
    NSString *query = [NSString stringWithFormat:@"SELECT * from ( SELECT "MESSAGE_TABLE_COLUMNS", conversation.subject, "
                       " trim(contact.first_name || ' ' || contact.last_name || ' ' || "
                       " CASE WHEN length(qliq_user.credentials) > 0 THEN qliq_user.credentials ELSE ' ' END) as display_name, sip_uri  "
                       " FROM message  "
                       " INNER JOIN conversation ON (message.conversation_id = conversation.id)  "
                       " INNER JOIN qliq_user ON (message.from_qliq_id = qliq_user.qliq_id)  "
                       " INNER JOIN contact ON (qliq_user.contact_id = contact.contact_id)  "
                       " INNER JOIN sip_contact ON (qliq_user.qliq_id = sip_contact.contact_qliq_id)  "
                       " WHERE %@) t ORDER BY t.last_sent_at", whereQueue];
    
    __block NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        while ([rs next]) {
            ChatMessage *message = [self allocChatMessageFromResultSet:rs];
            [results addObject:message];
            [message release];
        }
        [rs close];
    }];
    
    /* Load attachments for message */
    for (ChatMessage *message in results) {
        message.attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMessage:message];
    }
    
    return results;
}

+ (NSArray*)getOnlyMessageIDsFor:(NSString *)whereQueue argumentsArray:(NSArray *)arguments {
    
    NSString *query = [NSString stringWithFormat:@"SELECT * from ( SELECT call_id, "
                       " trim(contact.first_name || ' ' || contact.last_name || ' ' || "
                       " CASE WHEN length(qliq_user.credentials) > 0 THEN qliq_user.credentials ELSE ' ' END) as display_name, sip_uri  "
                       " FROM message  "
                       " INNER JOIN conversation ON (message.conversation_id = conversation.id)  "
                       " INNER JOIN qliq_user ON (message.from_qliq_id = qliq_user.qliq_id)  "
                       " INNER JOIN contact ON (qliq_user.contact_id = contact.contact_id)  "
                       " INNER JOIN sip_contact ON (qliq_user.qliq_id = sip_contact.contact_qliq_id)  "
                       " WHERE %@)", whereQueue];
    
    __block NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        while ([rs next]) {
            ChatMessage *message = [self allocChatMessageFromResultSet:rs];
            [results addObject:message];
            [message release];
        }
        [rs close];
    }];
    
    return results;
}

//
//Helper methods to get messages
//
+ (NSArray *) getMessagesForConversation:(NSInteger)conversationId pageSize:(NSInteger)pageSize pageOffset:(NSInteger)pageOffset{
    Limit limit = {.offset = pageOffset, .size = pageSize};
	return [self getMessagesWhere:@"message.conversation_id =? AND message.deleted = 0" argumentsArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:conversationId]] order:DESC limit:limit];
}

+ (BOOL) hasUserWithId:(NSString *)qliqId alreadySentMessageForConversation:(NSInteger)conversationId {
    BOOL userHasAlreadySent = NO;
    if (conversationId) {
        NSArray *messageIDs = [self getOnlyMessageIDsFor:@"message.conversation_id =? AND message.from_qliq_id =?" argumentsArray:[NSArray arrayWithObjects:[NSNumber numberWithInteger:conversationId], qliqId, nil]];
        userHasAlreadySent =  messageIDs && ([messageIDs count] > 0);
    }
    
    return userHasAlreadySent;
}

+ (NSArray *) getChatMessagesWhere: (NSString *)whereQuery withArgumentsInArray:(NSArray *)arguments{
    Limit limit = {.offset = 0, .size = -1};
    return [self getMessagesWhere:whereQuery argumentsArray:arguments order:DESC limit:limit];
}

+ (NSArray *) getMessagesForConversation:(NSInteger)conversationId limit:(NSUInteger) _limit inDB:(FMDatabase *)database {
    
    Limit limit = {.offset = 0, .size = _limit};
    return [self getMessagesWhere:@"message.conversation_id =? AND message.deleted = 0" argumentsArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:conversationId]] order:DESC limit:limit];
}



+ (NSArray *) getMessagesForConversation:(NSInteger)conversationId limit:(NSUInteger) _limit{
    __block NSArray *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self getMessagesForConversation:conversationId limit:_limit inDB:db];
    }];
	return ret;
}

+ (ChatMessage *) getLatestMsg:(NSInteger) conversationId
{
    ChatMessage *message = nil;
    Limit limit = {.offset = 0, .size = 1};
	NSArray *results = [self getMessagesWhere:@"message.conversation_id =? AND message.type = 0 AND message.deleted = 0" argumentsArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:conversationId]] order:DESC limit:limit];
    
    if ([results count] > 0)
        message = [results objectAtIndex:0];
    
	return message;
}

+ (ChatMessage*) getMessage:(NSInteger)messageId
{
    __block ChatMessage *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self getMessage:messageId inDB:db];
    }];
	return ret;
}

+ (ChatMessage*) getMessage:(NSInteger)messageId inDB:(FMDatabase *)database
{
    ChatMessage *message = nil;
    
    Limit limit = {.offset = 0, .size = 1};
    NSArray *results = [DBHelperConversation getMessagesWhere:@"message.id = ?" argumentsArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:messageId]] order:DESC limit:limit];
    
    if ([results count] > 0)
        message = [results objectAtIndex:0];
    
	return message;
}

+ (ChatMessage*) getMessageWithGuid:(NSString *)guid
{
    __block ChatMessage *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self getMessageWithGuid:guid inDB:db];
    }];
	return ret;
}

+ (ChatMessage*) getMessageWithGuid:(NSString *)guid inDB:(FMDatabase *)database
{
	NSString *query = @"SELECT "
	" id "
	" FROM message "
	" WHERE uuid = ? "
	" LIMIT 1";

    NSInteger messageId = 0;
	FMResultSet *message_rs = [database executeQuery:query, guid];
	ChatMessage *messageObj = nil;
	if ([message_rs next]) {
		messageId = [message_rs intForColumnIndex:0];
	}
	[message_rs close];
    
    // Avoid executing another query when FMResultSet is still open
    if (messageId > 0) {
        messageObj = [self getMessage:messageId inDB:database];
    }
	return messageObj;
}

+ (Metadata *) loadMetadataFromResultSet: (FMResultSet *)rs
{
    Metadata *md = nil;
    NSString *uuid = [rs stringForColumn:@"uuid"];
    if ([uuid length] > 0) {
        md = [[[Metadata alloc] init] autorelease];
        md.uuid = uuid;
        md.rev = [rs stringForColumn:@"rev"];
        md.author = [rs stringForColumn:@"author"];
        md.seq = [rs intForColumn:@"seq"];
        md.isRevisionDirty = [rs boolForColumn:@"is_rev_dirty"];
    }
    return md;
}

// The caller must release the ChatMessage object!
+ (ChatMessage *) allocChatMessageFromResultSet: (FMResultSet *) rs
{
    NSInteger messageId             = [rs intForColumn:@"id"];
    ChatMessage *message            = [[ChatMessage alloc] initWithPrimaryKey:messageId];
    message.conversationId          = [rs intForColumn:@"conversation_id"];
    message.fromQliqId              = [rs stringForColumn:@"from_qliq_id"];
    message.toQliqId                = [rs stringForColumn:@"to_qliq_id"];
    message.text                    = [rs stringForColumn:@"message"];
    message.subject                 = [rs stringForColumn:@"subject"];
    message.ackRequired             = [rs boolForColumn:@"ack_required"];
    message.priority                = [rs intForColumn:@"priority"];
    message.timestamp               = [rs doubleForColumn:@"timestamp"];
    message.selfDeliveryStatus      = [rs intForColumn:@"self_delivery_status"];
    message.deliveryStatus          = [rs intForColumn:@"delivery_status"];
    message.statusText              = [rs stringForColumn:@"status_text"];
    message.failedAttempts          = [rs intForColumn:@"failed_attempts"];
    message.createdAt               = [rs doubleForColumn:@"last_sent_at"];
    message.ackReceivedAt           = [rs doubleForColumn:@"ack_received_at"];
    message.receivedAt              = [rs doubleForColumn:@"received_at"];
    message.readAt                  = [rs doubleForColumn:@"read_at"];
    message.ackSentAt               = [rs doubleForColumn:@"ack_sent_at"];
    message.ackSentToServerAt       = [rs doubleForColumn:@"ack_sent_to_server_at"];
    message.isOpenedSent            = [rs boolForColumn:@"opened_sent"];
    message.localCreationTimestamp  = [rs doubleForColumn:@"local_created_time"];
    message.callId                  = [rs stringForColumn:@"call_id"];
    message.serverContext           = [rs stringForColumn:@"server_context"];
    message.hasAttachment           = [rs boolForColumn:@"has_attachment"];
    message.deletedStatus           = [rs intForColumn:@"deleted"];
    message.recalledStatus          = [rs intForColumn:@"recall_status"];
    message.deleted                 = message.deletedStatus != NotDeletedStatus;
    message.type                    = [rs intForColumn:@"type"];
    message.totalRecipientCount     = [rs intForColumn:@"total_recipient_count"];
    message.deliveredRecipientCount = [rs intForColumn:@"delivered_recipient_count"];
    message.openedRecipientCount    = [rs intForColumn:@"opened_recipient_count"];
    message.ackedRecipientCount     = [rs intForColumn:@"acked_recipient_count"];
    message.textHeight              = [rs doubleForColumn:@"text_height"];
    message.metadata                = [self loadMetadataFromResultSet:rs];
    
    message.toUserDisplayName = [rs stringForColumn:@"display_name"];
    message.toUserSipUri = [rs stringForColumn:@"sip_uri"];
    
    if (message.priority == ChatMessagePriorityUrgen && !message.ackRequired) {
        // First version of iPhone app was buggy and didn't set require ack for urgent messages
        message.ackRequired = YES;
    }
    
    if (message.createdAt == 0) {
        // For messages saved by older version of the app
        message.createdAt = message.timestamp;
    }
    
    // [self fixDeliveryErrorCode: messageObj];
    return message;
}

// Arguments for INSERT or UPDATE statement
+ (NSMutableArray *) chatMessageColumnArgs: (ChatMessage *)msg
{
    // The order needs to match MESSAGE_TABLE_COLUMNS
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:20];
//    [ret addObject: [NSNumber numberWithInt:msg.messageId]];
    [ret addObject: [NSNumber numberWithInteger:msg.conversationId]];
    [ret addObject: msg.fromQliqId ? msg.fromQliqId : [NSNull null]];
    [ret addObject: msg.toQliqId ? msg.toQliqId : [NSNull null]];
    [ret addObject: msg.text ? msg.text : [NSNull null]];    
    [ret addObject: [msg uuid] ? [msg uuid] : [NSNull null]];
    [ret addObject: [NSNumber numberWithBool: msg.ackRequired]];
    [ret addObject: [NSNumber numberWithInt: msg.priority]];
    [ret addObject: [NSNumber numberWithDouble: msg.timestamp]];
    [ret addObject: [NSNumber numberWithInteger: msg.selfDeliveryStatus]];
    [ret addObject: [NSNumber numberWithInteger: msg.deliveryStatus]];
    [ret addObject: msg.statusText ? msg.statusText : [NSNull null]];
    [ret addObject: [NSNumber numberWithInteger: msg.failedAttempts]];
    [ret addObject: [NSNumber numberWithDouble: msg.createdAt]];
    [ret addObject: [NSNumber numberWithDouble: msg.ackReceivedAt]];
    [ret addObject: [NSNumber numberWithDouble: msg.receivedAt]];
    [ret addObject: [NSNumber numberWithDouble: msg.readAt]];
    [ret addObject: [NSNumber numberWithDouble: msg.ackSentAt]];
    [ret addObject: [NSNumber numberWithDouble: msg.ackSentToServerAt]];
    [ret addObject: [NSNumber numberWithBool: msg.isOpenedSent]];
    [ret addObject: [NSNumber numberWithDouble: msg.localCreationTimestamp]];
    [ret addObject: msg.callId ? msg.callId : [NSNull null]];
    [ret addObject: msg.serverContext ? msg.serverContext : [NSNull null]];
    [ret addObject: [NSNumber numberWithBool: msg.hasAttachment]];
    [ret addObject: [NSNumber numberWithInt: msg.deletedStatus]];
    [ret addObject: [NSNumber numberWithInt: msg.recalledStatus]];
    [ret addObject: [NSNumber numberWithInt: msg.type]];
    [ret addObject: [NSNumber numberWithInteger: msg.totalRecipientCount]];
    [ret addObject: [NSNumber numberWithInteger: msg.deliveredRecipientCount]];
    [ret addObject: [NSNumber numberWithInteger: msg.openedRecipientCount]];
    [ret addObject: [NSNumber numberWithInteger: msg.ackedRecipientCount]];
    [ret addObject: [NSNumber numberWithDouble: msg.textHeight]];
    [ret addObject: msg.metadata.uuid ? msg.metadata.uuid : [NSNull null]];
    [ret addObject: msg.metadata.rev  ? msg.metadata.rev : [NSNull null]];
    [ret addObject: msg.metadata.author ? msg.metadata.author : [NSNull null]];    
    [ret addObject: [NSNumber numberWithInt:msg.metadata.seq]];
    [ret addObject: [NSNumber numberWithBool:msg.metadata.isRevisionDirty]];
    return ret;
}

+ (NSArray *) getUndeliveredMessagesWithStatusNotIn:(NSSet *)statuses toQliqId:(NSString *)toQliqId limit:(int)aLimit offset:(int)aOnffset
{
    NSString *query = @"(delivery_status / 100 != 2) AND from_qliq_id = ? AND message.deleted = 0";
    if ([toQliqId length] > 0) {
        query = [query stringByAppendingFormat:@" AND to_qliq_id = '%@'", toQliqId];
    }
    if ([statuses count] > 0) {
        NSString *notIn = @" AND delivery_status NOT IN (";
        int i = 0;
        for (NSNumber *status in statuses) {
            notIn = [notIn stringByAppendingFormat:(i == 0 ? @"%d" : @", %d"), [status intValue]];
            ++i;
        }
        notIn = [notIn stringByAppendingString:@")"];
        query = [query stringByAppendingString:notIn];
    }
    NSString *me = [Helper getMyQliqId];
    Limit limit = {.offset = aOnffset, .size = aLimit};
    
    NSArray *results = [NSArray array];
    if (me) {
        results = [DBHelperConversation getMessagesWhere:query argumentsArray:[NSArray arrayWithObject:me] order:ASC limit:limit];
    }
    return results;
}

//     NSArray *messages = [DBHelperConversation getUndeliveredMessagesWithStatusNotIn: permanentFailureStatusSet toQliqId:toQliqId limit:10000 offset:0 inDB:database];

+ (NSArray *) getUndeliveredAcksToQliqId:(NSString *)qliqId limit:(NSInteger)aLimit offset:(NSInteger)anOffset
{
    NSString *query = @"ack_required = 1 AND ack_sent_at != 0 AND (ack_sent_to_server_at = 0 OR ack_sent_to_server_at = -1) AND message.deleted = 0";
 
    NSArray *arguments = nil;
    if ([qliqId length] > 0) {
        query = [query stringByAppendingString:@" AND to_qliq_id = ?"];
        arguments = [NSArray arrayWithObject:qliqId];
    }
    
    Limit limit = {.offset = anOffset, .size = aLimit};
    NSArray *results = [DBHelperConversation getMessagesWhere:query argumentsArray:arguments order:ASC limit:limit];
    return results;    
}

+ (NSArray *) getUndeliveredOpenedStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset
{
    NSString *query = @"from_qliq_id != ? AND read_at != 0 AND opened_sent = 0 AND message.deleted = 0";
    
    NSArray *arguments = [NSArray arrayWithObject:[Helper getMyQliqId]];
    Limit limit = {.offset = anOffset, .size = aLimit};
    NSArray *results = [DBHelperConversation getMessagesWhere:query argumentsArray:arguments order:ASC limit:limit];
    return results;
}

+ (NSArray *) getUndeliveredDeletedStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset
{
    NSString *query = [NSString stringWithFormat:@"message.deleted = %d", DeletedAndNotSentStatus];
    
    NSArray *arguments = [NSArray arrayWithObject:[Helper getMyQliqId]];
    Limit limit = {.offset = anOffset, .size = aLimit};
    NSArray *results = [DBHelperConversation getMessagesWhere:query argumentsArray:arguments order:ASC limit:limit];
    return results;
}

+ (NSArray *) getUndeliveredRecalledStatusWithLimit:(NSInteger)aLimit offset:(NSInteger)anOffset
{
    NSString *query = [NSString stringWithFormat:@"message.recall_status = %d", RecalledAndNotSentStatus];
    
    NSArray *arguments = [NSArray arrayWithObject:[Helper getMyQliqId]];
    Limit limit = {.offset = anOffset, .size = aLimit};
    NSArray *results = [DBHelperConversation getMessagesWhere:query argumentsArray:arguments order:ASC limit:limit];
    return results;
}

+ (NSArray *) getUndeliveredAcksFromQliqId:(NSString *)qliqId limit:(NSInteger)aLimit offset:(NSInteger)anOffset
{
    NSString *query = @"ack_required = 1 AND ack_sent_at != 0 AND (ack_sent_to_server_at = 0 OR ack_sent_to_server_at = -1) AND message.deleted = 0";
    
    NSArray *arguments = nil;
    if ([qliqId length] > 0) {
        query = [query stringByAppendingString:@" AND from_qliq_id = ?"];
        arguments = [NSArray arrayWithObject:qliqId];
    }
    
    Limit limit = {.offset = anOffset, .size = aLimit};
    NSArray *results = [DBHelperConversation getMessagesWhere:query argumentsArray:arguments order:ASC limit:limit];
    return results;
}

+ (NSInteger) getOneUnpushedMessageIdFromUserWhereQliqStorNotIn:(NSString *)userId : (NSArray *)qliqStorIds
{
    NSString *sql = @"SELECT DISTINCT m.id FROM message m JOIN message_qliqstor_status s ON (s.message_id = id) WHERE "
                    @"from_qliq_id = ? AND (s.status != 1 ";
    
    if ([qliqStorIds count] > 0)
    {
        sql = [sql stringByAppendingString:@" AND s.qliqstor_qliq_id NOT IN ("];
        for (NSString *qliqId in qliqStorIds)
        {
            sql = [sql stringByAppendingFormat:@"'%@',", qliqId];
        }
        // Remove the last comma
        sql = [sql substringToIndex:[sql length] - 1];
        sql = [sql stringByAppendingString:@")"];
    }
    sql = [sql stringByAppendingString:@")"];
    
    __block NSInteger ret = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql, userId];
        if ([rs next]) {
            ret = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

+ (NSString *) columnNamesForInsert:(NSString *)columnNames forTable:(NSString *)tableName
{
    NSString *dotTableName = [NSString stringWithFormat:@"%@.", tableName];
    NSString *idCol = [NSString stringWithFormat:@"%@.id,", tableName];
    columnNames = [columnNames stringByReplacingOccurrencesOfString:idCol withString:@""];
    return [columnNames stringByReplacingOccurrencesOfString:dotTableName withString:@""];
}
+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt
{
	return [self saveMessageAsRead:messageId at:readAt andRevisionDirty:NO];
}
+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty
{
    __block BOOL ret = NO;
    DDLogSupport(@"Saving Message %lu as Read", (long)messageId);
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *updateQuery = @"UPDATE message SET read_at=?, is_rev_dirty=? WHERE id = ?";
        DDLogVerbose(@"saveMessageAsRead: readAt:%f dirty:%d messageId:%ld",readAt,dirty,(long)messageId);
        ret = [db executeUpdate:updateQuery,
                [NSNumber numberWithDouble:readAt],
                [NSNumber numberWithBool:dirty],
                [NSNumber numberWithInteger:messageId]];
        [ChatMessage updateUnreadCountInDb:db];
    }];
    return ret;
}

+ (BOOL) saveAllUnreadMessagesInConversationAsRead:(NSInteger)conversationId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty
{
	NSString *updateQuery = @"UPDATE message SET read_at=?, is_rev_dirty=? WHERE read_at = 0 AND conversation_id = ?";
	DDLogVerbose(@"saveAllUnreadMessagesInConversationAsRead: readAt:%f dirty:%d conversationId:%ld",readAt,dirty,(long)conversationId);
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:updateQuery,
               [NSNumber numberWithDouble:readAt],
               [NSNumber numberWithBool:dirty],
               [NSNumber numberWithInteger:conversationId]];
        [ChatMessage updateUnreadCountInDb:db];
    }];
    return ret;
}

+ (void) fixDeliveryErrorCode: (ChatMessage *)message
{
    if (message.deliveryStatus == 0)
    {
        // If the message wasn't delivered in the previous session then it's a timout,
        // but we change the status to failed (recipient offline)
        message.deliveryStatus = 404;
    }
}

#pragma mark -
#pragma mark Conversations

+ (NSInteger) getLastUpdatedConversationId:(NSString *) qliqId andSubject:(NSString *) subject
{
    __block NSInteger primaryKey = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        primaryKey = [self getLastUpdatedConversationId:qliqId andSubject:subject inDB:db];
    }];
    return primaryKey;
}

+ (NSInteger) getLastUpdatedConversationId:(NSString *) qliqId andSubject:(NSString *) subject inDB:(FMDatabase *)dbFromQueue
{
    if (!subject) subject = @"";
    NSInteger primaryKey=0;
	NSString *selectConversationQuery = @"SELECT "
	" conversation.id as conversation_id "
	" FROM conversation "
	" INNER JOIN recipients ON (recipients.recipients_id = conversation.recipients_id) "
	" WHERE recipients.recipients_qliq_id = ? "
	" AND trim(conversation.subject) = trim(?)"
    " ORDER BY last_updated DESC LIMIT 1";
	
	FMResultSet *conversation_rs = [dbFromQueue executeQuery:selectConversationQuery,qliqId,subject];
	
	if ([conversation_rs next])
	{
		primaryKey = [conversation_rs intForColumn:@"conversation_id"];
	}
	[conversation_rs close];
	return primaryKey;
}

+ (BOOL) deleteAllMessages:(FMDatabase *)database
{
    BOOL ret = [database executeUpdate:@"DELETE FROM message"];
    return ret;
}

+ (BOOL) deleteAllConversations:(FMDatabase *)database
{
    ConversationDBService * dbService = [[ConversationDBService alloc] initWithDatabase:database];
    NSArray * conversations = [dbService getNotDeletedConversationsAndCareChannels];
    [dbService deleteConversations:conversations];
    
    // Delete conversations that became empty now
    conversations = [dbService getConversationsWithoutMessages];
    for (Conversation *conv in conversations) {
        // If it was a mp conversation, then ConversationDBService should automatically
        // delete the recipients and sip_contact rows.
        [dbService deleteConversationButNotMessages:conv];
    }
    [dbService release];
    [ChatMessage updateUnreadCountInDb:database];
    return YES;
}

@end

//
//  ConversationService.m
//  qliq
//
//  Created by Paul Bar on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConversationDBService.h"

#import "QliqUserDBService.h"
#import "SipContactDBService.h"
#import "ChatMessageService.h"
#import "MessageAttachmentDBService.h"

#import "Conversation.h"
#import "ChatMessage.h"
#import "Recipients.h"

#import "DBHelperConversation.h"
#import "QliqConnectModule.h"

NSString *ConversationDidReadMessagesNotification = @"ConversationDidReadMessagesNotification";

@interface ConversationDBService()

- (NSUInteger)sizeOfWholeResultSet:(FMResultSet *)resultSet;
- (NSUInteger)sizeOfCurrentResultSet:(FMResultSet *)resultSet;

@end

@implementation ConversationDBService

+ (ConversationDBService *)sharedService {
    static dispatch_once_t pred;
    static ConversationDBService * shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ConversationDBService alloc] init];
        
    });
    return shared;
}

#pragma mark Public

- (BOOL)isRead:(Conversation *)conversation
{
    NSString *sql = @"SELECT id FROM message WHERE (read_at = 0 OR read_at = NULL) AND (conversation_id = ?) AND message.deleted = 0";
    
    __block BOOL haveUnreadMessages = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:sql,[NSNumber numberWithInteger:conversation.conversationId]];
        haveUnreadMessages = [result next];
        [result close];
    }];
    
    return !haveUnreadMessages;
}

- (BOOL) isMuted:(NSInteger)conversationId
{
    NSString *sql = @"SELECT is_muted FROM conversation WHERE id = ?";
    
    __block BOOL muted = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:sql, [NSNumber numberWithInteger:conversationId]];
        if ([result next]) {
            muted = [result boolForColumn:0];
        }
        [result close];
    }];
    
    return muted;
}

- (void) updateMuted:(NSInteger)conversationId withMuted:(BOOL)muted
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE conversation SET is_muted = ? WHERE id = ?"];
    
    if (self.database) {
        [self.database executeUpdate:sql, [NSNumber numberWithBool:muted], [NSNumber numberWithInteger:conversationId]];
    }
    else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:sql, [NSNumber numberWithBool:muted], [NSNumber numberWithInteger:conversationId]];
        }];
    }
}


- (NSInteger)countOfUnreadMessages:(Conversation *)conversation
{
    __block NSInteger message_read = 0;
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * undreadMessagesQueue = @"SELECT COUNT(*) FROM message WHERE (read_at = 0 OR read_at = NULL) AND (conversation_id = ?) AND message.deleted = 0";
        FMResultSet * result = [db executeQuery:undreadMessagesQueue,[NSNumber numberWithInteger:conversation.conversationId]];
        
        if ([result next]) {
            message_read = [result intForColumnIndex:0];
        }
        [result close];
    }];
    
    return message_read;
}

- (NSInteger)countOfUndeliveredMessages:(Conversation *)conversation
{
    __block NSInteger message_delivered = 0;
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * undeliveredMessagesQueue = @"SELECT COUNT(*) FROM message WHERE (received_at = 0 OR received_at = NULL) AND (conversation_id = ?) AND message.deleted = 0";
        FMResultSet * result = [db executeQuery:undeliveredMessagesQueue,[NSNumber numberWithInteger:conversation.conversationId]];
        
        if ([result next]) {
            message_delivered = [result intForColumnIndex:0];
        }
        [result close];
    }];
    
    return message_delivered;
}

- (NSUInteger)numberOfConversations
{
    __block NSUInteger conversationsCount = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) FROM conversation WHERE deleted = 0"];
        if ([rs next]){
            conversationsCount = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    DDLogSupport(@"Conversation count: %lu", (unsigned long)conversationsCount);
    return conversationsCount;
}

- (NSUInteger)numberOfArchivedConversations
{
    __block NSUInteger conversationsCount = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) FROM conversation WHERE deleted = 0 AND archived = 1"];
        if ([rs next]){
            conversationsCount = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    DDLogSupport(@"Archived Conversation count: %lu", (unsigned long)conversationsCount);
    return conversationsCount;

}

- (NSUInteger)sizeOfAllConversations
{
    __block NSUInteger totalBytes = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM conversation"];
        
        while ([rs next]){
            
            totalBytes += [self sizeOfCurrentResultSet:rs];
            
            NSNumber * conversationID = [rs objectForColumnIndex:0];
            FMResultSet * messages = [db executeQuery:@"SELECT * FROM message WHERE conversation_id = (?)",conversationID];
            
            while ([messages next]){
                totalBytes += [self sizeOfCurrentResultSet:messages];
                
                FMResultSet * attachments = [db executeQuery:@"SELECT * FROM message_attachment WHERE uuid = (?)",[messages stringForColumn:@"uuid"]];
                totalBytes += [self sizeOfWholeResultSet:attachments];
            }
            
        }
        [rs close];
    }];
    return totalBytes;
}

#pragma mark Private

- (BOOL) shouldDeleteRecipients:(Recipients *)recipients
{
    BOOL shouldDeleteRecipients = NO;
    
    if ([recipients isMultiparty]) {
        NSNumber *recipientsId = [recipients valueForKey:recipients.dbPKProperty];
        NSString *selectQuery = @"SELECT * FROM conversation WHERE recipients_id = ?";
        NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[recipientsId]];
        shouldDeleteRecipients = [decoders count] == 1;
    }
    
    return shouldDeleteRecipients;
}

- (void)deleteSipContactForRecipients:(Recipients *)recipients
{
    SipContactDBService * sipContactService = [[SipContactDBService alloc] initWithDatabase:self.database];
    SipContact * sipContactToDelete = [sipContactService sipContactForQliqId:recipients.qliqId];
    if (sipContactToDelete){
        [sipContactService deleteObject:sipContactToDelete mode:DBModeSingle completion:^(NSError *error) {
            if (error) DDLogError(@"%@",error);
        }];
    }
}

/* Overriding superclass deleteObject:as:mode:completion: method to delete sip_contact for MP recipients when removing conversation */
- (void)deleteObject:(id<DBCoding>)object as:(Class)objectClass mode:(DBMode)mode completion:(DBDeleteCompletion)completion{
    
    Conversation * conversation = (Conversation *) object;
    
    if (mode & DBModeToOne){
    
        if ([self shouldDeleteRecipients:conversation.recipients]) {
            [self deleteSipContactForRecipients:conversation.recipients];
        } else {
            mode &= !DBModeToOne; 
        }
    }
    
    [super deleteObject:object as:objectClass mode:mode completion:completion];
}

- (NSUInteger) sizeOfWholeResultSet:(FMResultSet *) resultSet
{
    NSUInteger totalBytes = 0;
    
    while ([resultSet next]) {
        totalBytes += [self sizeOfCurrentResultSet:resultSet];
    }
    
    return totalBytes;
}

- (NSUInteger) sizeOfCurrentResultSet:(FMResultSet *) resultSet
{
    NSUInteger totalBytes = 0;
    
    for (int i = 0; i < [resultSet columnCount]; i++){
        id object = [resultSet objectForColumnIndex:i];
        
        if ([object isKindOfClass:[NSString class]]){
            totalBytes += [object length];
        }else if ([object isKindOfClass:[NSNumber class]]){
            totalBytes += sizeof(long long int); //maximum of number data
        }else if ([object isKindOfClass:[NSData class]]){
            totalBytes += [object length];
        }
    }
    
    return totalBytes;
}

@end

#pragma mark - Managed Conversations -

@implementation ConversationDBService (ManagedConversations)

#pragma mark Public

- (BOOL)saveConversation:(Conversation *)conversation {
    __block BOOL success = NO;
    
    [self save:conversation completion:^(BOOL wasInserted, id objectId, NSError *error) {
        if (wasInserted) {
            DDLogSupport(@"Inserting new conversation: id: %@, uuid: %@",objectId, conversation.uuid);
        }
        else {
            DDLogSupport(@"Saving existing conversation: id: %@, uuid: %@",objectId, conversation.uuid);
        }
        success = (error == nil);
    }];
    
    return success;
}

- (void)deleteConversationButNotMessages:(Conversation *)conversation {
    [self deleteObject:conversation mode:DBModeToOne completion:nil];
}

- (void)setDeleteFlag:(BOOL)deleted forConversationId:(NSInteger)conversationId {
    
    NSString *updateRequest = [NSString stringWithFormat:@"UPDATE conversation SET deleted = %d WHERE id = %ld", deleted, (long)conversationId];
    
    if (self.database) {
        [self.database executeUpdate:updateRequest];
    }
    else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:updateRequest];
        }];
    }
}

- (void)markAllMessagesAsRead:(Conversation *)conversation
{
//    BOOL isActive = [AppDelegate applicationState] == UIApplicationStateActive;
    //No need to use state app and marked messages as read for all case
    if (/*isActive &&*/ conversation)
    {
        __block NSMutableArray *unreadIds = [[NSMutableArray alloc] init];
        __block BOOL success = YES;
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            NSString * undreadMessagesQueue = @"SELECT id FROM message WHERE (read_at = 0 OR read_at = NULL) AND (conversation_id = ?) AND message.deleted = 0";
            FMResultSet * result = [db executeQuery:undreadMessagesQueue,[NSNumber numberWithInteger:conversation.conversationId]];
            while ([result next]) {
                [unreadIds addObject:[NSNumber numberWithInteger:[result intForColumnIndex:0]]];
            }
            [result close];
        }];
        
        NSMutableArray *readMsgIds = unreadIds.mutableCopy;
        
        NSInteger timeInterval = -1;
        for (NSNumber *num in unreadIds) {
            
            NSInteger messageId = [num integerValue];
            
            timeInterval += 1.0f;
            
            //Added time interval for sending unread messages 4/6/2017
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                success = success && [[QliqConnectModule sharedQliqConnectModule] saveMessageAsRead:messageId];
                [[NSNotificationCenter defaultCenter] postNotificationName:kMessagesSavedAsRead object:nil userInfo:nil];
                
                [readMsgIds removeObject:num];
                
                //For synchronasing updating unread messages counts in bage updating unread messages counts in bage ('RECENTS', 'Conversations' and 'Conversation' in RecentTableViewCell)
                //Valerii Lider 05/24/2017
                
//                if (readMsgIds.count == 0) {
                    conversation.isRead = success;
                    
                    NSDictionary *info = @{@"Conversation": conversation};
                    [[NSNotificationCenter defaultCenter] postNotificationName:ConversationDidReadMessagesNotification object:nil userInfo:info];
//                }
            });
        }
        
        /*
        for (NSNumber *num in unreadIds)
        {
            NSInteger messageId = [num integerValue];
            success = success && [[QliqConnectModule sharedQliqConnectModule] saveMessageAsRead:messageId];
        }

        conversation.isRead = success;
        
        NSDictionary *info = @{@"Conversation": conversation};
        [[NSNotificationCenter defaultCenter] postNotificationName:ConversationDidReadMessagesNotification object:nil userInfo:info];
         */
    }
    else
    {
        if (!conversation) {
             DDLogError(@"Try to mark messages as read in the NIL conversation");
        }
    }
}

- (void)archiveConversations:(NSArray *)conversations {
    
    NSString *idsStr = [self conversationsIdsFromArray:conversations];
    
    if(!idsStr){
        return;
    }
    
    [self clearUndreadMessagesFromConversations:conversations];
    
    NSString *updateRequest = [NSString stringWithFormat:@"UPDATE conversation SET archived = 1 WHERE id IN (%@)", idsStr];
    DDLogInfo(@"%@", updateRequest);
    
    if (self.database) {
        [self.database executeUpdate:updateRequest];
    }
    else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:updateRequest];
        }];
    }
}

- (void)restoreConversations:(NSArray *)conversations {
    
    NSString *idsStr = [self conversationsIdsFromArray:conversations];
    
    if(!idsStr){
        return;
    }
    
    NSString *updateRequest = [NSString stringWithFormat:@"UPDATE conversation SET archived = 0, deleted = 0 WHERE id IN (%@)", idsStr];
    DDLogInfo(@"%@", updateRequest);
    
    if (self.database) {
        [self.database executeUpdate:updateRequest];
    }
    else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:updateRequest];
        }];
    }
}

//FIXME: Change removing messages and attachments to use QliqDBService
- (void)deleteConversations:(NSArray *)conversations {
    
    NSString *idsStr = [self conversationsIdsFromArray:conversations];
    
    if(!idsStr) {
        return;
    }
    
    [self clearUndreadMessagesFromConversations:conversations];
    
    /* Delete messages and attachments for required conversations */
    //    NSString * deleteMessagesQuery = [NSString stringWithFormat:@"DELETE FROM message WHERE conversation_id IN (%@)", idsStr];
    
    
    //    NSString * deleteMessageStatusLog = @"DELETE FROM message_status_log WHERE message_id = ?";
    
    //    MessageAttachmentDBService *attachmentService = [MessageAttachmentDBService sharedService];
    
    //    __block NSMutableArray *uuids = [[NSMutableArray alloc] init];
    __block NSString *firstMessageUuid = nil;
    
    void (^body)(FMDatabase *db) = ^(FMDatabase *db) {
        for (Conversation * conversation in conversations) {
            
            // Get uuid for just one message (can be random one)
            if (firstMessageUuid == nil) {
                NSString *selectMessagesQuery = @"SELECT uuid FROM message WHERE conversation_id = ? AND deleted = 0 LIMIT 1";
                FMResultSet *messagesRs = [db executeQuery: selectMessagesQuery, [NSNumber numberWithInteger:conversation.conversationId]];
                if ([messagesRs next]) {
                    firstMessageUuid = [messagesRs stringForColumn:@"uuid"];
                    [messagesRs close];
                }
                [messagesRs close];
            }
            
            NSString *markAsDeletedQuery = @"UPDATE message SET deleted = ? WHERE conversation_id = ? and deleted = 0";
            [db executeUpdate:markAsDeletedQuery, [NSNumber numberWithInteger:DeletedAndNotSentStatus], [NSNumber numberWithInteger:conversation.conversationId]];
            
            conversation.deleted = YES;
            [self saveConversation:conversation];
        }
        
        
        //                NSArray *attachments = [attachmentService getAttachmentsForMessageUuid:uuid];
        //                for (MessageAttachment *attachment in attachments) {
        //                    [attachmentService deleteAttachment:attachment];
        //                }
        //
        //                NSInteger messageId = [messagesRs intForColumn:@"id"];
        //                [db executeUpdate:deleteMessageStatusLog, [NSNumber numberWithInt:messageId]];
        //            }
        //        }
        //[db executeUpdate:deleteMessagesQuery];
    };
    
    if (self.database) {
        body(self.database);
    } else {
        [[DBUtil sharedQueue] inDatabase:body];
    }
    
    // Send 'deleted' status just for the first message, rest will be sent by resending undelivered method
    if (firstMessageUuid != nil) {
        ChatMessage *msg = [ChatMessageService getMessageWithUuid:firstMessageUuid];
        if (msg) {
            [[QliqConnectModule sharedQliqConnectModule] sendDeletedStatus:msg];
        }
    }
    
    /* Delete conversations */
    //    for (Conversation * conversation in conversations){
    //        [self deleteObject:conversation mode:DBModeToMany | DBModeToOne completion:^(NSError *error) {
    //            if (error) DDLogError(@"deleting error: %@",error);
    //        }];
    //    }
}

- (void)deleteConversationsForUsers:(NSArray*)users {
    NSMutableArray * conversations = [NSMutableArray new];
    
    for (QliqUser * user in users) {
        [conversations addObjectsFromArray:[self getConversationsWithQliqId:user.qliqId]];
    }
    
    [self deleteConversations:conversations];
}

#pragma mark Private

/**
 Get All conversation id from each conversation
 */
- (NSString *)conversationsIdsFromArray:(NSArray *)conversations {
    
    if([conversations count] == 0){
        return nil;
    }
    
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:conversations.count];

    for(Conversation * conversation in conversations) {
        [ids addObject:[NSNumber numberWithInteger:conversation.conversationId]];
    }
    
    return [ids componentsJoinedByString:@","];
}

- (void)clearUndreadMessagesFromConversations:(NSArray *)conversations
{
    for (Conversation *conversation in conversations) {
        [self markAllMessagesAsRead:conversation];
    }
}

@end

#pragma mark - Get Conversations -

@implementation ConversationDBService (GetConversations)

#pragma mark Public

- (NSInteger)getConversationId:(NSString *)qliqId andSubject:(NSString *)subject
{
    if (!subject) {
        subject = @"";
    }
    
    __block NSInteger primaryKey = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectConversationQuery = @"SELECT "
        " conversation.id as conversation_id "
        " FROM conversation "
        " INNER JOIN recipients ON (recipients.recipients_id = conversation.recipients_id) "
        " WHERE recipients.recipients_qliq_id = ? "
        " AND trim(conversation.subject) = trim(?) LIMIT 1";
        
        FMResultSet *conversation_rs = [db executeQuery:selectConversationQuery,qliqId,subject];
        
        if ([conversation_rs next]) {
            primaryKey = [conversation_rs intForColumn:@"conversation_id"];
        }
        
        [conversation_rs close];
    }];
    return primaryKey;
}

- (Conversation *)getConversationWithId:(NSNumber *)conversationId {
    return [self objectWithId:conversationId andClass:[Conversation class]];
}

- (Conversation *)getConversationWithUuid:(NSString *)uuid
{
    NSString * selectQuery =
    @"SELECT * FROM conversation "
    "INNER JOIN recipients ON (conversation.recipients_id = recipients.recipients_id)"
    "INNER JOIN recipients_qliq_id ON (recipients.recipients_id = recipients_qliq_id.recipients_id)"
    "WHERE conversation_uuid = ? LIMIT 1";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[uuid]];
    NSArray *convs = [self conversationFromDecoders:decoders];
    
    if ([convs count] > 0) {
        return [convs objectAtIndex:0];
    }
    else {
        return nil;
    }
}

- (NSUInteger) countConversationsForRecentsViewArchived:(BOOL)archived careChannel:(BOOL)careChannel
{
    __block NSUInteger ret = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        // WARNING: Keep this query in sync with getConversationsForRecentsViewArchived
        NSString *sql = @"SELECT COUNT(*) FROM conversation c"
            // That has a displayable message for recents list
            " JOIN (SELECT DISTINCT conversation_id FROM message WHERE type = 0 AND deleted = 0) AS displayable_message ON c.id = displayable_message.conversation_id"
            // WHERE conversation is not archived or deleted
            " WHERE c.archived = ? AND c.deleted = 0"
            // AND conversation is not a Care Channel
            " AND conversation_uuid NOT IN (SELECT uuid FROM fhir_encounter)";

        
        if (careChannel) {
            sql = [sql stringByReplacingOccurrencesOfString:@" NOT IN " withString:@" IN "];
        }
        
        FMResultSet *rs = [db executeQuery:sql, [NSNumber numberWithBool:archived]];
        while ([rs next]) {
            ret = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

- (NSMutableArray *) getConversationsForRecentsViewArchived:(BOOL)archived careChannel:(BOOL)careChannel
{
    __block NSMutableArray *array = [[NSMutableArray alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        // WARNING: Keep this query in sync with countConversationsForRecentsViewArchived
        NSString *sql = @"SELECT c.id, c.recipients_id, c.subject, c.conversation_uuid, c.is_broadcast, c.is_muted,"
            // message columns
            " last_message.message, last_message.last_sent_at,"
            // uread count column
            " IFNULL(unread.cnt, 0) AS unread_count FROM conversation c"
            // JOIN most recent, regular and not deleted message
            " JOIN (SELECT max(last_sent_at) AS latest_sent_at, * FROM message WHERE type = 0 AND deleted = 0 GROUP BY conversation_id) AS last_message ON c.id = last_message.conversation_id"
            // JOIN unread message count (if any)
            " LEFT OUTER JOIN (SELECT conversation_id, COUNT(*) AS cnt FROM message WHERE (read_at = 0 OR read_at = NULL) AND message.deleted = 0 GROUP BY conversation_id) AS unread ON c.id = unread.conversation_id"
            // WHERE conversation is not archived or deleted
            " WHERE c.archived = ? AND c.deleted = 0"
            // AND conversation is not a Care Channel
            " AND conversation_uuid NOT IN (SELECT uuid FROM fhir_encounter)"
            " ORDER BY last_message.last_sent_at DESC";
        
        if (careChannel) {
            sql = [sql stringByReplacingOccurrencesOfString:@" NOT IN " withString:@" IN "];
        }
        
        NSMutableDictionary *recipientsIdsDict = [[NSMutableDictionary alloc] init];
        
        FMResultSet *rs = [db executeQuery:sql, [NSNumber numberWithBool:archived]];
        while ([rs next]) {
            int column = 0;
            Conversation *conv = [[Conversation alloc] init];
            conv.conversationId = [rs intForColumnIndex:column++];

            // We don't want to execute queries to load recipients while we are iterating this query
            // So we cache recipientsId in numberUndeliveredMessages and load recipients outside this loop
            int recipientsId = [rs intForColumnIndex:column++];
            conv.numberUndeliveredMessages = recipientsId;
            [recipientsIdsDict setObject:[NSNull null] forKey:[NSNumber numberWithInteger:recipientsId]];

            conv.subject = [rs stringForColumnIndex:column++];
            conv.uuid = [rs stringForColumnIndex:column++];
            conv.broadcastType = [rs intForColumnIndex:column++];
            conv.isMuted = [rs boolForColumnIndex:column++];
            conv.isCareChannel = careChannel;
            conv.archived = archived;
            
            conv.lastMsg = [rs stringForColumnIndex:column++];
            conv.lastUpdated = [rs doubleForColumnIndex:column++];
            
            conv.numberUnreadMessages = [rs intForColumnIndex:column++];
            conv.isRead = (conv.numberUnreadMessages == 0);
            
            [array addObject:conv];
        }
        [rs close];
        
        for (NSNumber *recipientsId in [recipientsIdsDict allKeys]) {
            Recipients *recipients = [self objectWithId:recipientsId andClass:[Recipients class]];
            if (recipients) {
                [recipientsIdsDict setObject:recipients forKey:recipientsId];
            }
        }
        for (Conversation *conv in array) {
            id recipients = [recipientsIdsDict objectForKey:[NSNumber numberWithInteger:conv.numberUndeliveredMessages]];
            if ([recipients isKindOfClass:[Recipients class]]) {
                conv.recipients = recipients;
            } else {
                // This should not happen but actually does in Krishna's db
                DDLogError(@"Cannot load recipients with id: %d for conversation: %@ with subject: %@", (int)conv.numberUndeliveredMessages, conv.uuid, conv.subject);
            }
            conv.numberUndeliveredMessages = 0;
        }
    }];

    return array;
}

- (NSArray *) getCareChannelsForPatient:(NSString *)patientUuid
{
    NSString *selectQuery =
    @"SELECT * FROM conversation "
    "INNER JOIN fhir_encounter ON (conversation.conversation_uuid = fhir_encounter.uuid) "
    "INNER JOIN recipients ON (conversation.recipients_id = recipients.recipients_id)"
    "WHERE fhir_encounter.patient = (SELECT id FROM fhir_patient WHERE uuid = ?) AND conversation.deleted = ? AND conversation.archived = ? "
    "ORDER BY conversation.last_updated DESC";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[patientUuid,
                                                                          [NSNumber numberWithBool:NO],
                                                                          [NSNumber numberWithBool:NO]]];
    return [self conversationFromDecoders:decoders];
}

- (NSArray *)getConversationsWithQliqId:(NSString *)qliqId {
    return [self getConversationsWithQliqId:qliqId archived:NO deleted:NO];
}

- (NSArray *)getConversationsWithoutQliqId
{
    NSString *selectQuery =
    @"SELECT * FROM conversation INNER JOIN recipients ON (conversation.recipients_id = recipients.recipients_id)"
    " INNER JOIN recipients_qliq_id ON (recipients.recipients_id = recipients_qliq_id.recipients_id)"
    " WHERE (recipients.recipients_qliq_id IS NULL OR recipients_qliq_id.recipient_id IS NULL) AND conversation.deleted = 0 AND conversation.archived = 0"
    " ORDER BY conversation.last_updated DESC";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    
    return [self conversationFromDecoders:decoders];
}

- (NSArray *)getConversationsWithoutMessages
{
    NSString *selectQuery =
    @"SELECT * FROM conversation WHERE id NOT IN (SELECT DISTINCT conversation_id FROM message)";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    
    return [self conversationFromDecoders:decoders];
}

- (NSArray *)getConversationsWithOnlyDeletedMessages
{
    NSString *selectQuery =
    @"SELECT * FROM conversation WHERE deleted = 0 AND id NOT IN (SELECT DISTINCT conversation_id FROM message WHERE deleted = 0)";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    
    return [self conversationFromDecoders:decoders];
}

#pragma mark Private

- (NSArray *)conversationFromDecoders:(NSArray *)decoders {
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:decoders.count];
    
    for (DBCoder *decoder in decoders) {
        Conversation *conversation = [self objectOfClass:[Conversation class] fromDecoder:decoder];
        [results addObject:conversation];
    }
    
    return results;
}

- (NSArray *) getNotDeletedConversationsAndCareChannels
{
    NSString *selectQuery = @"SELECT * FROM conversation WHERE deleted = 0";
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    return [self conversationFromDecoders:decoders];
}

- (NSArray *)getConversationsWithQliqId:(NSString *)qliqId archived:(BOOL)archived deleted:(BOOL)deleted {
    
    ///TODO: Maybe better return nil, check it
    if (!qliqId)
        qliqId = @"";
    
    NSString *selectQuery =
    @"SELECT * FROM conversation "
    "INNER JOIN recipients ON (conversation.recipients_id = recipients.recipients_id)"
    "INNER JOIN recipients_qliq_id ON (recipients.recipients_id = recipients_qliq_id.recipients_id)"
    "WHERE (recipients.recipients_qliq_id = ? OR recipients_qliq_id.recipient_id = ?) AND conversation.deleted = ? AND conversation.archived = ?"
    "ORDER BY conversation.last_updated DESC";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[qliqId,
                                                                          qliqId,
                                                                          [NSNumber numberWithBool:deleted],
                                                                          [NSNumber numberWithBool:archived]]];
    return [self conversationFromDecoders:decoders];
}

#pragma mark Necessary to complete

- (NSArray *)getConversationsWithRecipientName:(NSString *)name deleted:(BOOL)deleted {
    
    if (!name)
        name = @"";
    
    NSString *selectQuery =
    @"SELECT * FROM conversation "
    "INNER JOIN recipients ON (conversation.recipients_id = recipients.recipients_id)"
    "INNER JOIN recipients_qliq_id ON (recipients.recipients_id = recipients_qliq_id.recipients_id)"
    "WHERE (recipients.recipients_qliq_id = ? OR recipients_qliq_id.recipient_id = ?) AND conversation.deleted = ?"
    "ORDER BY conversation.last_updated DESC";
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[name, name, [NSNumber numberWithBool:deleted]]];
    
    return [self conversationFromDecoders:decoders];
}

@end

	//
//  PushMessageToQliqStorHelper.m
//  qliq
//
//  Created by Adam Sowa on 10/18/12.
//
//

#import "PushMessageToQliqStorHelper.h"
#import "QliqStorClient.h"
#import "DBHelperConversation.h"
#import "QliqUserDBService.h"
#import "MessageQliqStorStatusDBService.h"
#import "MessageAttachmentDBService.h"
#import "ChatMessageTypeSchema.h"
#import "Helper.h"
#import "MediaFile.h"
#import "NSData+Base64.h"
#import "QliqUserDBService.h"
#import "MessageStatusLogDBService.h"
#import "SipContactDBService.h"
#import "ConversationDBService.h"
#import "Recipients.h"
#import "QliqSip.h"
#import "RecipientsDBService.h"
#import "ChatMessageService.h"
#import "UserSessionService.h"
#import "QxPlatfromIOSHelpers.h"
#include "qxlib/dao/qliqstor/QxQliqStorDao.hpp"

#define QLIQSTOR_AFTER_FAILURE_WAIT_INTERVAL_SECS (5 * 60)
#define QLIQSTOR_SELF_PUSH_INTERVAL_MSECS (1000 * 60 * 60 * 24)

@interface PushMessageToQliqStorHelper()<QliqStoreUpdateDelegate> {
    QliqStorClient *qliqStorClient;
}

@property (nonatomic, strong) QliqStorClient *qliqStorClient;
@property (nonatomic, strong) QliqUser *myUser;
@property (nonatomic, assign) BOOL isPushingDisabled;
@property (nonatomic, strong) NSTimer *selfTriggeredPushTimer;
@property (nonatomic, strong) NSMutableDictionary *failedQliqStorLastPushTimes;

// Active push
@property (nonatomic, strong) ChatMessage *pushedMessage;
@property (nonatomic, strong) NSDictionary *pushedMessageDoc;
@property (nonatomic, strong) NSString *pushedRequestId;
@property (nonatomic, strong) QliqUser *pushedQliqStor;
@property (nonatomic, strong) NSMutableArray *unpushedQliqStors;

- (void) pushJustOneUnpushedMessage;
- (void) removeFailedQliqStorsThatAreAfterWaitTime;
- (BOOL) pushMessageToQliqStors: (ChatMessage *)msg;
- (void) onMessagePushedToAllQliqStors;
- (void) pushMessageToNextQliqStor;
- (NSDictionary *) messageToQLiqStorDoc: (ChatMessage *)msg;
- (NSString *) displayNameForQliqId:(NSString *)qliqId inConversation:(NSInteger)conversationId;

@end

@implementation PushMessageToQliqStorHelper

@synthesize myUser, isPushingDisabled, selfTriggeredPushTimer, failedQliqStorLastPushTimes;
@synthesize pushedMessage, pushedMessageDoc, pushedRequestId, pushedQliqStor, unpushedQliqStors;
@synthesize qliqStorClient = _qliqStorClient;

// TESTING ONLY!
static PushMessageToQliqStorHelper *s_instance;

- (id) init
{
    if (self = [super init])
    {
        failedQliqStorLastPushTimes = [[NSMutableDictionary alloc] init];
        unpushedQliqStors = [[NSMutableArray alloc] init];
        
        NSTimeInterval interval = QLIQSTOR_SELF_PUSH_INTERVAL_MSECS / 1000;
        selfTriggeredPushTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(startPushing)userInfo:nil repeats:YES];
        
        self.qliqStorClient = [QliqStorClient sharedDataServerClient];
        s_instance = self;
    }
    return self;
}

- (void) startPushing
{
    //return; // TODO: disabled!
    
    isPushingDisabled = NO;
    if (![self isPushInProgress]) {
        // Since QliqSip uses its own bg thread we don't need to call this on main thread anymore
        //
        //Check if current thread is not main then switch to main thread because PJSip registered on main thread only
//        if (![NSThread isMainThread]) {
//            [self performSelectorOnMainThread:@selector(startPushing) withObject:nil waitUntilDone:NO];
//            return;
//        } else {
            [self pushJustOneUnpushedMessage];
//        }
    }
}

- (void) stopPushing
{
    isPushingDisabled = YES;
}

- (BOOL) isPushInProgress
{
    return [pushedRequestId length] > 0;
}

+ (NSSet *) qliqStorsForMessage: (ChatMessage *)msg
{
    NSMutableSet *qliqStors = [[NSMutableSet alloc] init];
    std::vector<std::string> qliqStorIds = qx::QliqStorDao::qliqStorsForQliqId(qx::toStdString(msg.toQliqId));
    for (const auto& qliqId: qliqStorIds) {
        QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qx::toNSString(qliqId)];
        if (user) {
            [qliqStors addObject:user];
        }
    }
    return qliqStors;
}

+ (void) setMessageUnpushedToAllQliqStors: (ChatMessage *)msg
{
    DDLogSupport(@"Marking message %@ as unpushed", msg.metadata.uuid);
    
    NSSet *qliqStors = [self qliqStorsForMessage:msg];
    if  ([qliqStors count] > 0) {
        NSMutableSet *ids = [[NSMutableSet alloc] init];
        
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = msg.messageId;
        statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
        statusLog.status = PendingForQliqStorMessageStatus;

        for (QliqUser *u in qliqStors) {
            [ids addObject:u.qliqId];
            
            statusLog.qliqId = u.qliqId;
            [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
        }
        
        [MessageQliqStorStatusDBService insertOrUpdateRowsForMessageId:msg.messageId qliqStorIds:ids status:NotPushedQliqStorMessagePushStatus];
        [[ChatMessageService sharedService] setRevisionDirtyForMessageId:msg.messageId dirty:YES];
    } else {
        // No qliqStor(s) to push to
        msg.metadata.isRevisionDirty = NO;
        [[ChatMessageService sharedService] setRevisionDirtyForMessageId:msg.messageId dirty:NO];
    }
}

//////////////////////////////////////////////////////////////////
// Private

- (void) pushJustOneUnpushedMessage
{
    [self removeFailedQliqStorsThatAreAfterWaitTime];
    
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    // Get first unpushed message but skip message which are unpushed only to qliqStors which are on our pause (offline) list.
    NSInteger messageId = [DBHelperConversation getOneUnpushedMessageIdFromUserWhereQliqStorNotIn:myQliqId: [failedQliqStorLastPushTimes allKeys]];
    
    if (messageId > 0) {
        ChatMessage *msg = [DBHelperConversation getMessage:messageId];
        [self pushMessageToQliqStors:msg];
    }
}

- (void) removeFailedQliqStorsThatAreAfterWaitTime
{
    NSDate *now = [NSDate date];
    
    NSArray *ids = [failedQliqStorLastPushTimes allKeys];
    for (NSString *qliqStorId in ids) {
        NSDate *date = [failedQliqStorLastPushTimes objectForKey:qliqStorId];
        NSTimeInterval secondsSince = [now timeIntervalSinceDate:date];
        if (secondsSince > QLIQSTOR_AFTER_FAILURE_WAIT_INTERVAL_SECS) {
            DDLogSupport(@"Removing %@ from the list of offline qliqStors", qliqStorId);
            [failedQliqStorLastPushTimes removeObjectForKey:qliqStorId];
        }
    }
}

- (BOOL) pushMessageToQliqStors: (ChatMessage *)msg
{
    if (pushedMessage != nil) {
        DDLogError(@"There is already an outstanding chat-message push to qliqStor, skipping");
        return false;
    }
    
    [self.unpushedQliqStors removeAllObjects];
    self.pushedMessage = msg;
    
    NSArray *unpushedQliqStorIds = [MessageQliqStorStatusDBService qliqStorIdsForMessageIdAndStatusNotEqual:msg.messageId status:PushedQliqStorMessagePushStatus];
    for (NSString *qliqId in unpushedQliqStorIds)
    {
        QliqUser *u = [[QliqUserDBService sharedService] getUserWithId:qliqId];
        if (u != nil)
        {
            [self.unpushedQliqStors addObject:u];
        }
    }
    
    if ([self.unpushedQliqStors count] == 0)
    {
        DDLogSupport(@"No (more) qliqStors to push the message to");
        [self onMessagePushedToAllQliqStors];
        return true;
    }
    else
    {
        DDLogSupport(@"Initiating message push %@ to qliqStors", msg.metadata.uuid);
        self.pushedMessageDoc = [self messageToQLiqStorDoc:msg];
        [self pushMessageToNextQliqStor];
        return true;
    }
}

- (void) pushMessageToNextQliqStor
{
    if ([self.unpushedQliqStors count] == 0)
    {
        [self onMessagePushedToAllQliqStors];
    }
    else
    {
        self.pushedQliqStor = [self.unpushedQliqStors objectAtIndex:0];
        [self.unpushedQliqStors removeObjectAtIndex:0];
        DDLogSupport(@"Pushing message to next qliqStor: %@", self.pushedQliqStor.qliqId);
        // TODO: refactor QliqStorClient to support multiple qliqStors
        SipContact * pushedQliqStorSipContact = [[[SipContactDBService alloc] init] sipContactForQliqId:self.pushedQliqStor.qliqId];
        self.pushedRequestId = [_qliqStorClient sendUpdate:pushedQliqStorSipContact.qliqId document:self.pushedMessageDoc forUuid:self.pushedMessage.metadata.uuid forSubject:@"chat-message" delegate:self requireResponse:NO];
        if (self.pushedRequestId == nil)
            [self pushMessageToNextQliqStor];
    }
}

- (void) onMessagePushedToAllQliqStors
{
    self.pushedMessageDoc = nil;
    pushedQliqStor = [[QliqUser alloc] init];
    
    if (self.pushedMessage != nil)
    {
        DDLogSupport(@"Message: %@ has been pushed to all qliqStors", self.pushedMessage.metadata.uuid);
        [[ChatMessageService sharedService] setRevisionDirtyForUuid:self.pushedMessage.metadata.uuid dirty:NO];
        [MessageQliqStorStatusDBService deleteRowsForMessageId:self.pushedMessage.messageId];
        self.pushedMessage = nil;
    }
    
    if (!self.isPushingDisabled)
        [self pushJustOneUnpushedMessage];
}

- (NSDictionary *) messageToQLiqStorDoc: (ChatMessage *)msg
{
    NSString *uuid = [msg uuid];
    Metadata *md = [Metadata createNew];
    md.uuid = uuid; // preserve uuid
    md.version = 1;
    NSMutableDictionary *mdDict = [md toDict];
    // We don't want to override seq
    [mdDict removeObjectForKey:@"seq"];
    
    NSMutableDictionary *chatDoc = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    msg.toQliqId, CHAT_MESSAGE_TO_USER_ID,
                                    msg.fromQliqId, CHAT_MESSAGE_FROM_USER_ID,
                                    msg.text, CHAT_MESSAGE_TEXT,
                                    [msg uuid], CHAT_MESSAGE_UUID,
                                    [NSNumber numberWithBool:msg.ackRequired], CHAT_MESSAGE_REQUIRES_ACK,
                                    msg.subject ? msg.subject : @"", CHAT_MESSAGE_SUBJECT,
                                    mdDict, @"metadata",
                                    nil];
    
    if (msg.priority != ChatMessagePriorityNormal) {
        [chatDoc setObject:[msg priorityToString] forKey:CHAT_MESSAGE_PRIORITY];
    }
    
    // Add display names
    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
    if (conversation) {
        NSString *displayName = [conversation.recipients displayName];
        if ([displayName length] > 0) {
            if ([conversation.recipients isGroup]) {
                displayName = [displayName stringByReplacingOccurrencesOfString:@" • " withString:@" - "];
                displayName = [NSString stringWithFormat:@"Group: %@", displayName];
            }
            [chatDoc setObject:displayName forKey:CHAT_MESSAGE_TO_USER_NAME];
        }
        
        if ([conversation.uuid length] > 0) {
            [chatDoc setObject:conversation.uuid forKey:CHAT_MESSAGE_CONVERSATION_UUID];
        }
    }
    
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:msg.fromQliqId];
    if (user)
        [chatDoc setObject:user.displayName forKey:CHAT_MESSAGE_FROM_USER_NAME];
    
    // Add status log array
    NSArray *logEntries = [[MessageStatusLogDBService sharedService] getMessageStatusLogForMessage: msg];
    if ([logEntries count] > 0)
    {
        NSMutableArray *logArray = [NSMutableArray array];
        for (MessageStatusLog *entry in logEntries)
        {
            NSString *statusStr = [MessageStatusLog statusMessage:entry.status];
            NSTimeInterval timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:entry.timestamp];
            NSString *timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
            NSMutableDictionary *logDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                               timeStr, CHAT_MESSAGE_STATUS_LOG_TIME,
                                               statusStr, CHAT_MESSAGE_STATUS_LOG_STATUS,
                                               nil];
            [logArray addObject:logDict];
        }
        [chatDoc setObject:logArray forKey:CHAT_MESSAGE_STATUS_LOG];
    }
    
#ifdef INCLUDE_TIMESTAMP_FIELDS
    NSString *timeStr = nil;
#endif
    
    if ([msg isSentByUser])
    {
#ifdef INCLUDE_TIMESTAMP_FIELDS
        NSTimeInterval timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.timestamp];
        timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
        [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_CREATED_AT];

        timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.lastSentAt];
        timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
        [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_LAST_SENT_AT];
#endif
        [chatDoc setObject:@"iPhone" forKey:CHAT_MESSAGE_SENT_FROM_DEVICE];
        
        [chatDoc setObject:[msg deliveryStatusToString] forKey:CHAT_MESSAGE_DELIVERY_STATUS];
        
        if (msg.failedAttempts > 0)
            [chatDoc setObject:[NSNumber numberWithInteger:msg.failedAttempts] forKey:CHAT_MESSAGE_FAILED_ATTEMPTS];
        
        if (msg.recalledStatus != NotRecalledStatus) {
            [chatDoc setObject:[NSNumber numberWithBool:YES] forKey:CHAT_MESSAGE_RECALLED];
        }
      
#ifdef INCLUDE_TIMESTAMP_FIELDS
        if (msg.ackRequired && msg.ackReceivedAt)
        {
            NSTimeInterval timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.ackReceivedAt];
            timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
            [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_ACK_RECEIVED_AT];
        }
#endif
    }
    else
    {
#ifdef INCLUDE_TIMESTAMP_FIELDS
        // Add lastSentAt that is actuall createAt from extended chat message.
        // Tkt #708
        NSTimeInterval timestamp;
        if (msg.lastSentAt > 0)
        {
            timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.lastSentAt];
            timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
            [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_LAST_SENT_AT];
        }
        
        timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.receivedAt];
        timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
        [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_RECEIVED_AT];
#endif
        [chatDoc setObject:@"iPhone" forKey:CHAT_MESSAGE_RECEIVED_ON_DEVICE];
        
#ifdef INCLUDE_TIMESTAMP_FIELDS
        if (msg.ackRequired && msg.ackSentAt)
        {
            timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.ackSentAt];
            timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
            [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_ACK_SENT_AT];
        }
        
        if (msg.readAt)
        {
            timestamp = [[QliqSip sharedQliqSip] adjustTimeForNetwork:msg.readAt];
            timeStr = [Helper intervalToISO8601DateTimeString:timestamp];
            [chatDoc setObject:timeStr forKey:CHAT_MESSAGE_READ_AT];
        }
#endif
    }

    // Attachments
    MessageAttachmentDBService *attachmentDb = [MessageAttachmentDBService sharedService];
    NSArray *attachments = [attachmentDb getAttachmentsForMessage: msg];
    if ([attachments count] > 0)
    {
        NSMutableArray *attachmentsJsonArray = [[NSMutableArray alloc] init];
        
        for (MessageAttachment *a in attachments)
        {
            NSMutableDictionary *attachDict = [[NSMutableDictionary alloc] init];
            if (!a.mediaFile) {
                DDLogError(@"Media File missing for attachment for URL %@. Ignoring...", a.url);
                continue;
            }
            if ([a.url length] > 0) {
                // Can be nil if upload failed
                [attachDict setObject:a.url forKey:CHAT_MESSAGE_ATTACHMENTS_URL];
            }
            [attachDict setObject:a.mediaFile.fileName forKey:CHAT_MESSAGE_ATTACHMENTS_FILE_NAME];
            [attachDict setObject:a.mediaFile.mimeType forKey:CHAT_MESSAGE_ATTACHMENTS_MIME];
            [attachDict setObject:[a.mediaFile encryptedFileSizeNumber] forKey:CHAT_MESSAGE_ATTACHMENTS_SIZE];
            
            [attachDict setObject:[NSNumber numberWithInt:1] forKey:CHAT_MESSAGE_ATTACHMENTS_ENCRYPTION_METHOD];
            [attachDict setObject:a.mediaFile.encryptionKey forKey:CHAT_MESSAGE_ATTACHMENTS_KEY];
            if (a.mediaFile.checksum.length > 0) {
                [attachDict setObject:a.mediaFile.checksum forKey:CHAT_MESSAGE_ATTACHMENTS_CHECKSUM];
            }
            
            NSString *thumb = [UIImagePNGRepresentation([a thumbnailStyled:NO]) base64EncodedString];
            [attachDict setObject:thumb forKey:CHAT_MESSAGE_ATTACHMENTS_THUMBNAIL];
            
            [attachmentsJsonArray addObject:attachDict];
        }
        
        [chatDoc setObject:attachmentsJsonArray forKey:CHAT_MESSAGE_ATTACHMENTS];
    }
    
    return chatDoc;
}

// QliqStoreUpdateDelegate
- (void) onUpdateSuccessful: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid metadata:(Metadata *)aMetadata
{
    if (self.pushedMessage && [self.pushedMessage.metadata.uuid isEqualToString:uuid] && [self.pushedRequestId isEqualToString:requestId])
    {
        DDLogSupport(@"Update for %@, uuid: %@ to: %@ was succesful", subject, uuid, self.pushedQliqStor.qliqId);
        [MessageQliqStorStatusDBService setStatusForMessageId:self.pushedMessage.messageId qliqStorId:self.pushedQliqStor.qliqId status:PushedQliqStorMessagePushStatus];
        
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = self.pushedMessage.messageId;
        statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
        statusLog.status = SentToQliqStorMessageStatus;
        statusLog.qliqId = self.pushedQliqStor.qliqId;
        [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
        
        if ([self.failedQliqStorLastPushTimes objectForKey:self.pushedQliqStor.qliqId] != nil)
        {
            [self.failedQliqStorLastPushTimes removeObjectForKey:self.pushedQliqStor.qliqId];
        }
    }
}

- (void) onUpdateFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid errorCode:(int)anErrorCode errorMessage:(NSString *)anErrorMessage
{
    if (self.pushedMessage && [self.pushedRequestId isEqualToString:requestId])
    {
        DDLogError(@"Update for %@, uuid: %@ failed on the qliqStor: %@", subject, uuid, self.pushedQliqStor.qliqId);
        [MessageQliqStorStatusDBService setStatusForMessageId:self.pushedMessage.messageId qliqStorId:self.pushedQliqStor.qliqId status:ErrorQliqStorMessagePushStatus];
        
        if ([self.failedQliqStorLastPushTimes objectForKey:self.pushedQliqStor.qliqId] == nil)
        {
            [self.failedQliqStorLastPushTimes setObject:[NSDate date] forKey:self.pushedQliqStor.qliqId];
        }
    }
}

- (void) onUpdateSendingFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid withSipStatus:(int)status
{
    if (self.pushedMessage && [self.pushedRequestId isEqualToString:requestId])
    {
        DDLogError(@"Update for %@, uuid: %@ failed to send to: %@", subject, uuid, self.pushedQliqStor.qliqId);
        [MessageQliqStorStatusDBService setStatusForMessageId:self.pushedMessage.messageId qliqStorId:self.pushedQliqStor.qliqId status:ErrorQliqStorMessagePushStatus];
        
        if ([self.failedQliqStorLastPushTimes objectForKey:self.pushedQliqStor.qliqId] == nil)
        {
            [self.failedQliqStorLastPushTimes setObject:[NSDate date] forKey:self.pushedQliqStor.qliqId];
        }
    }
    
    if (status == MessageStatusNotContact || status == MessageStatusNotMemberOfGroup || status == MessageStatusCantDetermineContactType) {
        DDLogWarn(@"qliqSTOR %@ has been removed (status: %d) from our contacts, deleting it and pending message for it", qliqId, status);
        qx::QliqStorDao::deleteQliqStor(qx::toStdString(qliqId));
        [MessageQliqStorStatusDBService deleteForQliqStorId:qliqId];
        
        if (self.pushedMessage && [self.pushedRequestId isEqualToString:requestId]) {
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = self.pushedMessage.messageId;
            statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
            statusLog.status = PermanentQliqStorFailureMessageStatus;
            statusLog.qliqId = self.pushedQliqStor.qliqId;
            [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
        }
        [failedQliqStorLastPushTimes removeObjectForKey:qliqId];
    }
}

// Called when the request is finished (after a successful response or error)
- (void) onUpdateFinished: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid withStatus:(int)status
{
    if ([self.pushedRequestId isEqualToString:requestId]) {
        self.pushedRequestId = nil;
    }

    if (self.pushedMessage && [self.pushedMessage.metadata.uuid isEqualToString:uuid])
    {
        if (status == CompletedRequestStatus) {
            [self pushMessageToNextQliqStor];
        } else if (status == RequestSendingFailedStatus) {
            self.pushedMessage = nil;
        }
    }
}

- (NSString *) displayNameForQliqId:(NSString *)qliqId inConversation:(NSInteger)conversationId
{
    NSString *ret = nil;
    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:conversationId]];
    if (conversation) {
        
    }
    return ret;
}

@end

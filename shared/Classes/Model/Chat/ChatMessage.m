//
//  Message.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/12/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "ChatMessage.h"
#import "MessageAttachment.h"
#import "DBHelperConversation.h"
#import "NotificationUtils.h"
#import "Helper.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "ChatMessageService.h"
#import "SoundSettings.h"

#import "QliqUserNotifications.h"

#import "DeviceInfo.h"

@interface ChatMessage()

@end

@implementation ChatMessage
@synthesize messageId; 
@synthesize conversationId;
@synthesize fromQliqId;
@synthesize toQliqId;
@synthesize text;
@synthesize subject;
@synthesize ackRequired;
@synthesize priority;
@synthesize type;
@synthesize metadata;
@synthesize timestamp;
@synthesize selfDeliveryStatus;
@synthesize deliveryStatus;
@synthesize statusText;
@synthesize failedAttempts;
@synthesize createdAt;
@synthesize ackReceivedAt;
@synthesize totalRecipientCount;
@synthesize deliveredRecipientCount;
@synthesize receivedAt;
@synthesize readAt;
@synthesize ackSentAt;
@synthesize ackSentToServerAt;
@synthesize isOpenedSent;
@synthesize toUserDisplayName;
@synthesize toUserSipUri;
@synthesize localCreationTimestamp;
@synthesize callId;
@synthesize serverContext;
@synthesize attachments;
@synthesize hasAttachment;
@synthesize deleted;
@synthesize deletedStatus;
@synthesize textHeight;

NSInteger s_unreadConversationMessagesCount = -1;
NSInteger s_unreadCareChannelMessagesCount = -1;

NSString *ChatBadgeValueNotification = @"ChatBadgeValue";

+(void) updateUnreadCountInDb:(FMDatabase *)db
{
    NSInteger unreadConversationMessagesCount = [ChatMessage unreadConversationMessagesCount:db];
    NSInteger unreadCareChannelMessagesCount = [ChatMessage unreadCareChannelMessagesCount:db];
    
    if ((s_unreadConversationMessagesCount != unreadConversationMessagesCount) || (s_unreadCareChannelMessagesCount != unreadCareChannelMessagesCount))
    {
        s_unreadConversationMessagesCount = unreadConversationMessagesCount;
        s_unreadCareChannelMessagesCount = unreadCareChannelMessagesCount;
        NSNumber *newBadgeValue = [NSNumber numberWithInteger:(unreadConversationMessagesCount + unreadCareChannelMessagesCount)];
        NSNumber *newConversationBadgeValue = [NSNumber numberWithInteger:unreadConversationMessagesCount];
        NSNumber *newCareChannelBadgeValue = [NSNumber numberWithInteger:unreadCareChannelMessagesCount];
        NSDictionary *userInfo = @{
            @"newBadgeValue": newBadgeValue,
            @"newConversationBadgeValue": newConversationBadgeValue,
            @"newCareChannelBadgeValue":newCareChannelBadgeValue
        };
        [NSNotificationCenter postNotificationToMainThread:ChatBadgeValueNotification withObject:nil userInfo:userInfo];
    }
}

+(void) updateUnreadCountAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            [self updateUnreadCountInDb:db];            
        }];
    });
}

- (NSUInteger) hash{
    return [[NSString stringWithFormat:@"%@",metadata.uuid] hash];
}

- (BOOL)isEqual:(id)object{

    return [object hash] == [self hash];
}

+(NSInteger) unreadMessagesCount
{
    __block NSInteger count = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        count = [self unreadMessagesCount:db];
    }];
	return count;
}

+ (NSInteger)unreadMessagesFromQliqId:(NSString *)qliqId {
    
    __block NSInteger rez = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @"SELECT count(distinct(m.id)) AS count FROM message m, conversation c WHERE m.conversation_id = c.id AND (m.read_at = 0 OR m.read_at IS NULL) AND m.deleted = 0 AND c.archived=0 AND c.deleted=0 AND from_qliq_id = ?";
        FMResultSet *resultSet = [db executeQuery:selectQuery, qliqId];
        
        if([resultSet next])
        {
            rez = [resultSet intForColumn:@"count"];
        }
        [resultSet close];
    }];
    return rez;
}


+ (NSInteger)unreadMessagesCount:(FMDatabase *)database withExtraWhere:(NSString *)extraWhere
{
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    NSString *selectQuery = @"SELECT count(distinct(m.id)) AS count FROM message m, conversation c WHERE m.conversation_id = c.id AND (m.read_at = 0 OR m.read_at IS NULL) AND m.deleted = 0 AND c.archived=0 AND c.deleted=0 AND from_qliq_id != ? ";
    
    if (extraWhere.length > 0) {
        selectQuery = [selectQuery stringByAppendingFormat:@" AND %@", extraWhere];
    }
    
    FMResultSet *resultSet = [database executeQuery:selectQuery, myQliqId];
    NSInteger rez = 0;
    if([resultSet next])
    {
        rez = [resultSet intForColumn:@"count"];
    }
    [resultSet close];
    return rez;
}

+ (NSInteger)unreadMessagesCount:(FMDatabase *)database
{
    return [self unreadMessagesCount:database withExtraWhere:nil];
}

+ (NSInteger) unreadConversationMessagesCount:(FMDatabase *)database
{
    return [self unreadMessagesCount:database withExtraWhere:@"m.conversation_id NOT IN (SELECT conversation.id FROM conversation JOIN fhir_encounter ON conversation.conversation_uuid = fhir_encounter.uuid)"];
}

+ (NSInteger) unreadCareChannelMessagesCount:(FMDatabase *)database
{
    return [self unreadMessagesCount:database withExtraWhere:@"m.conversation_id IN (SELECT conversation.id FROM conversation JOIN fhir_encounter ON conversation.conversation_uuid = fhir_encounter.uuid)"];
}

+ (NSInteger) unreadConversationMessagesCount
{
    __block NSInteger count = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        count = [self unreadConversationMessagesCount:db];
    }];
    return count;
}

+ (NSInteger) unreadCareChannelMessagesCount
{
    __block NSInteger count = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        count = [self unreadCareChannelMessagesCount:db];
    }];
    return count;
}

+ (ChatMessagePriority) highestPriorityOfUnreadMessages
{
    __block int priority = -1;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
        NSString *selectQuery = @"SELECT distinct(m.priority) FROM message m, conversation c WHERE m.conversation_id = c.id AND (m.read_at = 0 OR m.read_at IS NULL) AND m.deleted = 0 AND c.archived=0 AND c.deleted=0 AND from_qliq_id != ?";
        FMResultSet *resultSet = [db executeQuery:selectQuery, myQliqId];
        while ([resultSet next])
        {
            int prio = [resultSet intForColumnIndex:0];
            if (prio > priority) {
                if (prio > ChatMessagePriorityForYourInformation) {
                    priority = prio;
                } else if (prio == ChatMessagePriorityForYourInformation) {
                    if (priority == -1) {
                        priority = prio;
                    }
                } else {
                    priority = prio;
                }
            }
        }
        [resultSet close];
    }];

    if (priority == -1) {
        priority = ChatMessagePriorityNormal;
    }
    return (ChatMessagePriority) priority;
}

+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt
{
	return [DBHelperConversation saveMessageAsRead:messageId at:readAt];
}	

+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty
{
    BOOL success = [DBHelperConversation saveMessageAsRead:messageId at:readAt andRevisionDirty:dirty];
    if (success) {
        [[QliqUserNotifications getInstance] cancelChimeNotificationsForMessageWithID:messageId];
    }
    return success;
}	

- (id) initWithPrimaryKey:(NSInteger) pk
{
    if (self = [super init]) {
        messageId = pk;
        metadata = [[Metadata alloc] init];
    }
    return self;
}

- (id) init
{
    return [self initWithPrimaryKey:0];
}

-(void) dealloc
{
    [fromQliqId release];
    [toQliqId release];
    [text release];
    [subject release];
    [metadata release];
    [toUserDisplayName release];
    [toUserSipUri release];
    [callId release];
    [attachments release];
    [super dealloc];
}

- (BOOL) isMessageHaveAttachment
{
    return hasAttachment && attachments.count != 0;
}

- (BOOL) isDelivered
{
    return (receivedAt != 0);
}

- (BOOL) isAcked
{
    return (ackReceivedAt || ackSentAt);
}

- (BOOL) isSentByUser
{
    return fromQliqId && ([fromQliqId isEqualToString:[Helper getMyQliqId]]);
}

- (BOOL) isRead
{
    return readAt != 0;
}

- (BOOL) isAckDelivered
{
    return ackReceivedAt != 0;
}

- (BOOL) isNormalChatMessage
{
    BOOL ret = (type == ChatMessageTypeNormal);
    return ret;
}

- (BOOL) isDeletedSent
{
    return deletedStatus == DeletedAndSentStatus;
}

- (NSString *) uuid
{
    return metadata.uuid;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"{ ChatMessage %p, deliveryStatus = %@}",self,[ChatMessage deliveryStatusToString:self.deliveryStatus includeCode:YES]];
}

+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode forReceivedMessage: (BOOL) isReceived
{
    return [self deliveryStatusToString:deliveryStatus includeCode:includeCode forReceivedMessage:isReceived message:nil outTimestamp:nil statusText:nil];
}

+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode forReceivedMessage: (BOOL) isReceived message:(ChatMessage *)msg outTimestamp:(NSTimeInterval *)timestamp statusText:(NSString *)aStatusText
{
    
    if (msg && timestamp) {
        *timestamp = msg.timestamp;
    }
    
    if (aStatusText.length > 0) {
        return aStatusText;
    }
    
    NSString *ret = nil;
    switch (deliveryStatus) {
        case 0:
            ret = QliqLocalizedString(@"1919-StatusSending");
            break;
        case 200:
            ret = isReceived ? QliqLocalizedString(@"1920-StatusReceived") : QliqLocalizedString(@"1921-StatusDelivered");
            if (msg && timestamp) {
                *timestamp = msg.receivedAt;
            }
            break;
        case 202:
            ret = QliqLocalizedString(@"1922-StatusWaitingForRecipient");
            if (msg && timestamp) {
                *timestamp = msg.receivedAt;
            }
            break;
        case MessageStatusRead:
            ret = QliqLocalizedString(@"1923-StatusRead");
            if (msg && timestamp) {
                *timestamp = msg.readAt;
            }
            break;
        case MessageStatusSynced:
            ret = QliqLocalizedString(@"1924-StatusSynced");
            break;
        case -1:
        case 408:
        case 503:
            ret = QliqLocalizedString(@"1925-StatusNoConnection");
            break;
        case 404:
            ret = QliqLocalizedString(@"1926-StatusRecipientNotFound");
            break;
        case 407:
            ret = QliqLocalizedString(@"1927-StatusAuthfailedPending");
            break;
        case 491:
            ret = QliqLocalizedString(@"1928-StatusNetworkError");
            break;
        case 493:
            ret = QliqLocalizedString(@"1929-StatusEncryptionError");
            break;
        case MessageStatusCannotGetPublicKey:
            ret = QliqLocalizedString(@"1930-StatusCannotGetPK");
            break;
        case MessageStatusNotContact:
            ret = QliqLocalizedString(@"1931-StatusErrorRecipientNotContact");
            break;
        case MessageStatusNotMemberOfGroup:
            ret = QliqLocalizedString(@"1932-StatusErrorNotMemberOfGroup");
            break;
        case MessageStatusPublicKeyNotSet:
            ret = QliqLocalizedString(@"1933-StatusErrorPKNotSetForContact");
            break;
        case MessageStatusPublicKeyMismatch:
            ret = QliqLocalizedString(@"1934-StatusPKMismatch");
            break;
        case MessageStatusTooManyRetries:
            ret = QliqLocalizedString(@"1935-StatusErrorTooManyRetries");
            break;
        case MessageStatusCannotUploadAttachment:          //2000..2100 attachment related errors
            ret = QliqLocalizedString(@"1936-StatusErrorCannotUploadAttachment");
            break;
        case MessageStatusAttachmentUploadCancelled:
            ret = QliqLocalizedString(@"1937-StatusСanceled");
            break;
        case MessageStatusAttachmentUploadAttachmentNotFound:
            ret = QliqLocalizedString(@"1938-StatusErrorCannotFindAttachment");
            break;
        default:
//            if (deliveryStatus / 100 == 5)
//                ret = @"Server error. Pending";
//            else
            ret = QliqFormatLocalizedString1(@"1939-StatusError{Code}Pending", (long)deliveryStatus);
    }
    
    if (includeCode)
        return [NSString stringWithFormat:@"%@ (%ld)", ret, (long)deliveryStatus];
    else
        return ret;
}

+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode
{
    return [self deliveryStatusToString:deliveryStatus includeCode:includeCode forReceivedMessage:NO];
}

- (NSString *) priorityToString
{
    switch (priority) {
        case ChatMessagePriorityForYourInformation:
            return @"fyi";
            break;
        case ChatMessagePriorityAsSoonAsPossible:
            return @"asap";
            break;
        case ChatMessagePriorityUrgen:
            return @"urgent";
            break;
        case ChatMessagePriorityNormal:
        default:
            return @"normal";
            break;
    }
}

+ (NSString *) priorityToString:(ChatMessagePriority)priority
{
    switch (priority) {
        case ChatMessagePriorityForYourInformation:
            return @"fyi";
            break;
        case ChatMessagePriorityAsSoonAsPossible:
            return @"asap";
            break;
        case ChatMessagePriorityUrgen:
            return @"urgent";
            break;
        case ChatMessagePriorityNormal:
        default:
            return @"normal";
            break;
    }
}

- (NSString *) typeString
{
    switch (type) {
        case ChatMessageTypeEvent:
            return @"event";
            break;
        case ChatMessageTypeNormal:
            // we don't want to send this type, only receive, so empty string here
        default:
            return @"";
            break;
    }
}

- (void)calculateHeight
{
    self.textHeight = [ChatMessage messageTextSizeForText:self.text ].height;
}

+ (CGSize) messageTextSizeForText:(NSString *) _textMessage{

    CGFloat kMessageTextWidth = 234.f;
    
    __block CGSize textSize = CGSizeMake(kMessageTextWidth, CGFLOAT_MAX);
    
    //for correctly calculate size for specified text need to use sizeThatFits method of UITextView
    static UITextView *textView = nil;
    if (nil == textView) {
        
        textView = [[UITextView alloc] init];
        textView.font = [UIFont systemFontOfSize:16.f];
        textView.scrollEnabled = NO;
        textView.textAlignment = NSTextAlignmentLeft;
        textView.editable = NO;
        textView.userInteractionEnabled = NO;
        textView.dataDetectorTypes = UIDataDetectorTypeAll;
        textView.userInteractionEnabled = YES;
        if ([textView respondsToSelector:@selector(setTextContainerInset:)]) {
            
            textView.textContainerInset = UIEdgeInsetsMake(4.f, 2.f, 0.f, 0.f);
        }
    }
    
    //this block MUST BE performed in MAIN thread only
    void (^doBlock)() = ^() {
        
        textView.text = _textMessage;
        textSize = [textView sizeThatFits:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)];
    };
    
    
    //if (dispatch_get_main_queue() != dispatch_get_current_queue()) { /* dispatch_get_current_queue is depreceted */
    if ([NSOperationQueue mainQueue] != [NSOperationQueue currentQueue]) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            doBlock();
        });
    } else {
        
        doBlock();
    }
    
    if (textSize.width < kMessageTextWidth) {
        textSize.width = kMessageTextWidth;
    }
    
    if ([DeviceInfo sharedInfo].iosVersionMajor < 7) {
        textSize.height -= [self textPadding].top + [self textPadding].bottom;
    }
    return textSize;
}

+ (UIEdgeInsets) textPadding{
    UIEdgeInsets textPadding;
    textPadding.left = textPadding.right = 8.0f;
    textPadding.top = textPadding.bottom = 4.0f;
    return textPadding;
}


+ (ChatMessageType) typeFromString: (NSString *)str
{
    if ([str isEqualToString:@"event"]) {
        return ChatMessageTypeEvent;
    } else if ([str length] == 0) {
        return ChatMessageTypeNormal;
    } else {
        return ChatMessageTypeUnknown;
    }
}

- (NSString *) priorityString{
    
    NSString * priorityString = nil;
    
    switch (priority) {
        case ChatMessagePriorityAsSoonAsPossible:
            priorityString = NotificationPriorityASAP;
            break;
        case ChatMessagePriorityForYourInformation:
            priorityString = NotificationPriorityFYI;
            break;
        case ChatMessagePriorityUrgen:
            priorityString = NotificationPriorityUrgent;
            break;
        default:
        case ChatMessagePriorityNormal:
            priorityString = NotificationPriorityNormal;
            break;
    }
    
    return priorityString;
}

- (NSString *) priorityStringCareChannel{
    
    NSString * priorityString = nil;
    
    switch (priority) {
        case ChatMessagePriorityAsSoonAsPossible:
            priorityString = NotificationPriorityASAPCareChannel;
            break;
        case ChatMessagePriorityForYourInformation:
            priorityString = NotificationPriorityFYICareChannel;
            break;
        case ChatMessagePriorityUrgen:
            priorityString = NotificationPriorityUrgentCareChannel;
            break;
        default:
        case ChatMessagePriorityNormal:
            priorityString = NotificationPriorityNormalCareChannel;
            break;
    }
    
    return priorityString;
}

+ (ChatMessagePriority) priorityFromString: (NSString *)str
{
    if ([str isEqualToString:@"fyi"] || [str isEqualToString:@"fiy"]) { // the second one is sent by qliqDesktop < 64
        return ChatMessagePriorityForYourInformation;
    } else if ([str isEqualToString:@"asap"]) {
        return ChatMessagePriorityAsSoonAsPossible;
    } else if ([str isEqualToString:@"urgent"]) {
        return ChatMessagePriorityUrgen;
    } else {
        return ChatMessagePriorityNormal;
    }
}

- (NSString *) deliveryStatusToString
{
    return [self deliveryStatusToStringWithTimestamp:nil];
}

- (NSString *) deliveryStatusToStringWithTimestamp:(NSTimeInterval *)timestampArg
{
    BOOL isMine = [self isMyMessage];
    NSString *ret = [ChatMessage deliveryStatusToString:deliveryStatus includeCode:NO forReceivedMessage:!isMine message:self outTimestamp:timestampArg statusText:statusText];
    
    if (deliveryStatus == 202 && deliveredRecipientCount > 0 && deliveredRecipientCount < totalRecipientCount)
    {
        ret = [ChatMessage deliveryStatusToString:200 includeCode:NO forReceivedMessage:!isMine message:self outTimestamp:timestampArg statusText:statusText];
        ret = [ret stringByAppendingFormat:@" to %ld of %ld", (long) deliveredRecipientCount, (long)totalRecipientCount];

        if (self.openedRecipientCount > 0)
            ret = [ret stringByAppendingFormat:@" (read by %ld)", (long)self.openedRecipientCount];
    }
    else if ((deliveryStatus == MessageStatusDelivered || deliveryStatus == MessageStatusRead) && self.openedRecipientCount > 0)
    {
        ret = [ChatMessage deliveryStatusToString:MessageStatusRead includeCode:NO forReceivedMessage:!isMine message:self outTimestamp:timestampArg statusText:statusText];

        if (self.openedRecipientCount > 0 && self.openedRecipientCount < totalRecipientCount)
            ret = [ret stringByAppendingFormat:@" by %ld of %ld", (long)self.openedRecipientCount, (long)totalRecipientCount];
        
        /* else if (self.openedRecipientCount > 0 && self.openedRecipientCount == totalRecipientCount) {
            ret = [ret stringByAppendingFormat:@" by all"];
        }*/
    }

    return ret;
}

- (void) setUuid: (NSString *)newUuid
{
    metadata.uuid = newUuid;
}

-(BOOL) isMyMessage
{
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    if (!myQliqId) {
        
        DDLogSupport(@"Did not get current user qliqID");
        return NO;
    } else {
        return ([myQliqId isEqualToString:[self fromQliqId]]);
    }
}

@end

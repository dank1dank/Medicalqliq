//
//  Message.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/12/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Metadata.h"
#import "DBUtil.h"

extern NSString *ChatBadgeValueNotification;

extern NSInteger s_unreadMessageCount;
//extern NSInteger s_unreadConversationCount;

@class MessageAttachment;

// Special message status code defined for our app
typedef enum  {
    MessageStatusSipNotStarted                      = -1,
    MessageStatusDelivered                          = 200,
    MessageStatusPending                            = 202,
    MessageStatusAway                               = 205,
    MessageStatusRead                               = 298,
    MessageStatusSynced                             = 299,
    MessageStatusCannotGetPublicKey                 = 1000,
    MessageStatusPublicKeyMismatch                  = 1001,
    MessageStatusTooManyRetries                     = 1002,
    MessageStatusNotContact                         = 1104,
    MessageStatusNotMemberOfGroup                   = 1105,
    MessageStatusPublicKeyNotSet                    = 1106,
    MessageStatusAttachmentUploadAttachmentNotFound = 1107,
    MessageStatusCantDetermineContactType           = 1108,
    MessageStatusCannotUploadAttachment             = 2001,
    MessageStatusAttachmentUploadCancelled          = 2002
} QliqMessageStatus;

typedef enum {
    ChatMessagePriorityUnknown              = -1,
    ChatMessagePriorityNormal               = 0,
    ChatMessagePriorityForYourInformation   = 1,
    ChatMessagePriorityAsSoonAsPossible     = 2,
    ChatMessagePriorityUrgen                = 3
} ChatMessagePriority;

typedef enum {
    ChatMessageTypeUnknown  = -1,
    ChatMessageTypeNormal   = 0,
    ChatMessageTypeEvent    = 1
} ChatMessageType;

typedef enum {
    NotDeletedStatus        = 0,
    DeletedAndNotSentStatus = 1,
    DeletedAndSentStatus    = 2
} ChatMessageDeletedStatus;

typedef enum {
    NotRecalledStatus           = 0,
    RecalledAndNotSentStatus    = 1,
    RecalledAndSentStatus       = 2,
} ChatMessageRecalledStatus;

@interface ChatMessage : NSObject
{
    NSInteger messageId;
    NSInteger conversationId;

    NSString *fromQliqId;
    NSString *toQliqId;
    NSString *text;
    NSString *subject;
    BOOL ackRequired;
    ChatMessagePriority priority;
    ChatMessageType type;
    Metadata *metadata;    

    // Used to order messages in UI. For sent messages it is createdAt, for received it is receivedAt.
    // If a message is received from qliqStor then it will be createdAt of the sender.
    NSTimeInterval timestamp;

    // Sender only
    NSInteger selfDeliveryStatus;
    NSInteger deliveryStatus;
    NSString *statusText;
    NSInteger failedAttempts;
    NSTimeInterval createdAt;
    NSTimeInterval ackReceivedAt;   // for recipient it is the time ack was delivered

    // Recipient only
    NSTimeInterval receivedAt;
    NSTimeInterval readAt;    
    NSTimeInterval ackSentAt;
    NSTimeInterval ackSentToServerAt;   // 0 means not yet delivered to server (and recipient), -1 means sending error
    BOOL isOpenedSent;

	NSString *toUserDisplayName;
	NSString *toUserSipUri;

	// Ravi: I don't know why we need this - Adam Sowa
    //
    //This is always the timestamp when the message is inserted into the db on the device.
	NSTimeInterval localCreationTimestamp;
    
    // Saved call-id only if the message was queued on the server
    NSString *callId;
    NSString *serverContext;
    
    BOOL hasAttachment;
    BOOL deleted;
    ChatMessageDeletedStatus deletedStatus;
    MessageAttachment *attachment; 
}
@property (nonatomic, readwrite) NSInteger messageId;
@property (nonatomic, readwrite) NSInteger conversationId;
@property (nonatomic, retain) NSString  *fromQliqId;
@property (nonatomic, retain) NSString  *toQliqId;
@property (nonatomic, retain) NSString  *text;
@property (nonatomic, retain) NSString  *subject;
@property (nonatomic, readwrite) BOOL ackRequired;
@property (nonatomic, readwrite) ChatMessagePriority priority;
@property (nonatomic, readwrite) ChatMessageType type;
@property (nonatomic, retain) Metadata *metadata;

@property (nonatomic, readwrite) NSTimeInterval timestamp;
@property (nonatomic, readwrite) NSInteger selfDeliveryStatus;
@property (nonatomic, retain) NSString *statusText;
@property (nonatomic, readwrite) NSInteger deliveryStatus;
@property (nonatomic, readwrite) NSInteger failedAttempts;
@property (nonatomic, readwrite) NSTimeInterval createdAt;
@property (nonatomic, readwrite) NSTimeInterval ackReceivedAt;

@property (nonatomic, readwrite) NSInteger totalRecipientCount;
@property (nonatomic, readwrite) NSInteger deliveredRecipientCount;
@property (nonatomic, readwrite) NSInteger openedRecipientCount;
@property (nonatomic, readwrite) NSInteger ackedRecipientCount;

@property (nonatomic, readwrite) NSTimeInterval receivedAt;
@property (nonatomic, readwrite) NSTimeInterval readAt;
@property (nonatomic, readwrite) NSTimeInterval ackSentAt;
@property (nonatomic, readwrite) NSTimeInterval ackSentToServerAt;
@property (nonatomic, readwrite) BOOL isOpenedSent;

@property (nonatomic, retain) NSString  *toUserDisplayName;
@property (nonatomic, retain) NSString  *toUserSipUri;
@property (nonatomic, readwrite) NSTimeInterval localCreationTimestamp;
@property (nonatomic, retain) NSString *callId;
@property (nonatomic, retain) NSString *serverContext;

@property (nonatomic, retain) NSArray *attachments;
@property (nonatomic, readwrite) BOOL hasAttachment;
@property (nonatomic, readwrite) BOOL deleted;
@property (nonatomic, readwrite) ChatMessageDeletedStatus deletedStatus;
@property (nonatomic, readwrite) ChatMessageRecalledStatus recalledStatus;

// To speed up rendering we cache the bubble's text height here
@property (nonatomic, readwrite) double textHeight;

//Static methods.
+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt;
+ (BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt andRevisionDirty:(BOOL)dirty;

+ (NSInteger) unreadMessagesCount;
+ (NSInteger) unreadConversationMessagesCount;
+ (NSInteger) unreadCareChannelMessagesCount;
+ (NSInteger) unreadMessagesFromQliqId:(NSString *)qliqId;

+ (void) updateUnreadCountAsync;
// Use the method without 'db' arg unless you want to call it from an already updating db method
+ (void) updateUnreadCountInDb:(FMDatabase *)db;

+ (ChatMessagePriority) highestPriorityOfUnreadMessages;
+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode;
+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode forReceivedMessage: (BOOL) isReceived;
+ (NSString *) deliveryStatusToString: (NSInteger)deliveryStatus includeCode:(BOOL)includeCode forReceivedMessage: (BOOL) isReceived message:(ChatMessage *)msg outTimestamp:(NSTimeInterval *)timestamp statusText:(NSString *)aStatusText;
+ (ChatMessagePriority) priorityFromString: (NSString *)str;
+ (ChatMessageType) typeFromString: (NSString *)str;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
- (BOOL) isDelivered;
- (BOOL) isAcked;
- (BOOL) isSentByUser;
- (BOOL) isRead;
- (BOOL) isAckDelivered;
- (BOOL) isDeletedSent;
- (BOOL) isNormalChatMessage;
- (BOOL) isMessageHaveAttachment;
- (NSString *) uuid;
- (void) setUuid: (NSString *)newUuid;
- (NSString *) deliveryStatusToString;
- (NSString *) deliveryStatusToStringWithTimestamp:(NSTimeInterval *)timestamp;
- (NSString *) priorityToString;
/* Returns priority string compatible with NotificationSettings priorities */
- (NSString *) priorityString;
- (NSString *) priorityStringCareChannel;
- (NSString *) typeString;
- (void)calculateHeight;

- (BOOL) isMyMessage;
+ (NSInteger) unreadMessagesCount:(FMDatabase*)database;
+ (NSString *) priorityToString:(ChatMessagePriority)priority;

+ (NSInteger) unreadConversationMessagesCount;
+ (NSInteger) unreadCareChannelMessagesCount;
@end


//
//  QliqConnectModule.h
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqModuleBase.h"
#import "MessageAttachmentApiService.h"
#import "MessageAttachmentDBService.h"
#import "CryptoWrapper.h"
#import "Contact.h"
#import "Recipients.h"
#import "Conversation.h"
#import "QliqConnectModuleTypes.h"

@class Invitation;
@class ChatMessage;
@class MessageAttachment;
@class Conversation;
@class ChatMessageAttachmentService;
@class PushMessageToQliqStorHelper;
@class QliqSipExtendedChatMessage;
@protocol Contact;

extern NSString *ChatMessageStatusNotification; // notfies about chat msg status change
extern NSString *NewChatMessagesNotification; // notifies that there is one or more new chat msgs
extern NSString *ChatMessageAttachmentStatusNotification; // chat message attachment status change
extern NSString *RecipientsChangedNotification;
extern NSString *ConversationMutedChangedNotification;
extern NSString *ConversationDeletedNotification; // when an old conversation is deleted
extern NSString *PresenceChangeStatusNotification; // when presence changed from another device
extern NSString *QliqConnectDidDeleteMessagesInConversationNotification;
extern NSString *ChatMessageRecalledInConversationNotification;


@protocol qConnectAttachmentsDelegate <NSObject>

- (void)didDownloadAttachment:(MessageAttachment *)attachment;

@optional

- (void)didFailDownloadAttachment:(MessageAttachment *)attachment;

- (void)willUploadAttachment:(MessageAttachment *)attachment;
- (void)didUploadAttachment:(MessageAttachment *)attachment;
- (void)didFailUploadAttachment:(MessageAttachment *)attachment;

@end


@interface QliqConnectModule : QliqModuleBase
{
//    NSMutableSet *sentChatMessages;
//    NSMutableSet *sentAcks;
    
    ChatMessage *pushedMessage;
    int pulledNewMessagesCount;
    ChatMessage *justReceivedMessage;
    BOOL isQliqStorReset;
    
    NSMutableDictionary *sentAttachments;
    unsigned int attachmentTag;
   
    BOOL currentReachability;
    NSDate *lastQliqStorPushDate;
    PushMessageToQliqStorHelper *qliqStorPusher;
    int messageRetentionPeriod;
    NSTimer *deleteOldMessagesTimer;
    NSMutableSet *permanentFailureStatusSet;
    NSInteger resendingMessageId;
    NSString *resendingMessageStatusUuid;
    int maximumRetryCount;
    BOOL wasRegInfoReceived;
}

@property(nonatomic, strong) NSMutableSet *sentChatMessages;
@property(nonatomic, strong) NSMutableSet *sentAcks;

@property(nonatomic, assign) id<qConnectAttachmentsDelegate> attachmentDelegate;

@property(nonatomic, strong) NSDate *lastQliqStorPushDate;

+ (QliqConnectModule *)sharedQliqConnectModule;

+ (BOOL)wipeData; // wipes all chat data!

- (void) processPendingRemoteNotifications;
+ (BOOL)processRemoteNotification:(NSDictionary *)aps isVoip:(BOOL)isVoip;
+ (BOOL)processRemoteNotificationWithQliqMessage:(NSDictionary *)aps isVoip:(BOOL)isVoip;
- (void)processLogoutResponseToPush:(NSString *)reason completion:(VoidBlock)completion;

#pragma mark *** Work with contacts ***

+ (void)syncContacts:(BOOL)showHUD;

#pragma mark *** Work with messages ***

- (void)sendMessage:(ChatMessage *)chatMessage;
- (void)sendMessage:(ChatMessage *)chatMessage completition:(CompletionBlock)completeBlock;
- (void)sendMessage:(NSString *)messageText
             toUser:(Contact *)userContact
            subject:(NSString *)subject
        ackRequired:(BOOL)ack
           priority:(ChatMessagePriority)aPriority
               type:(ChatMessageType)aType;

//- (ChatMessage *)sendMessage:(NSString *)messageText toQliqId:(NSString *)aQliqId inConversation:(Conversation *)conversation acknowledgeRequired:(BOOL)ack;
//- (ChatMessage *)sendMessageWithAttachment:(NSString *)messageText toQliqId:(NSString *)aQliqId inConversation:(Conversation *)conversation acknowledgeRequired:(BOOL)ack attachmentPath:(NSString *)attachmentPath;

- (BOOL)sendAck:(ChatMessage *)message;
- (void)sendDeletedStatus:(ChatMessage *)msg;
- (void)sendRecalledStatus:(ChatMessage *)msg;

- (BOOL)saveMessageAsRead:(NSInteger)messageId;
- (BOOL)saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt;

- (void)deleteOldMessages;

- (void)setMessageRetentionPeriod:(int)periodInSeconds;

#pragma mark *** Work with attachments ***

- (void)downloadAttachment:(MessageAttachment *)attachment completion:(CompletionBlock)completitionBlock;

#pragma mark *** Work with conversations ***

- (Conversation *)createConversationWithUser:(Contact *)userContact subject:(NSString *)subject UNAVAILABLE_ATTRIBUTE;
- (Conversation *)createConversationWithRecipients:(Recipients *)recipients subject:(NSString *)subject broadcastType:(BroadcastType)broadcastType uuid:(NSString *)uuid;

- (void)modifyConversation:(Conversation *)conversation byRecipients:(Recipients *)newRecipients andSubject:(NSString *)newSubject complete:(CompletionBlock)complete; /* Returns Conversation as result in callback */

// At least one of conversationId or uuid must be provided
+ (void) setConversationMuted:(NSInteger)conversationId withUuid:(NSString *)uuid withMuted:(BOOL)muted withCallWebService:(BOOL)callWebService;

#pragma mark *** Work with multiparty ***

+ (void)notifyMultipartyWithQliqId:(NSString *)qliqId;

/* Multiparty chat
*/
- (void)sendParticipantsChangedEventMessage:(NSString *)toQliqId
                               conversation:(Conversation *)aConversation
                                      added:(NSArray *)addedArray
                                    removed:(NSArray *)removedArray UNAVAILABLE_ATTRIBUTE;


#pragma mark *** Work with Invitations ***

#define qliqErrorCodeUserNotActive 123

typedef NS_ENUM(NSInteger, InvitationAction) {
    InvitationActionInvite,
    InvitationActionCancel
};

- (void) sendInvitation:(Invitation *)invitation action:(InvitationAction)_action completitionBlock:(void(^)(NSError * error))block;
+ (void) processInvitationResponse:(NSDictionary *)invitationResponse;
+ (void) processInvitationRequest:(NSDictionary *)invitationRequest completitionBlock:(void(^)(QliqUser *contact, NSError * error))completeBlock;

@end


#pragma mark - GetSipContactContext -

typedef void(^GetSipContactFinishedBlock)(NSInteger webErrorCode);

typedef NS_ENUM(NSInteger, ProbableContactType)  {
    UnknownProbableContactType,
    UserProbableContactType,
    GroupProbableContactType,
    MultipartyProbableContactType,
    MultipartyOrGroupProbableContactType // we don't know which one is this, need to test both
};

@interface GetSipContactContext : NSObject

@property (nonatomic, copy) GetSipContactFinishedBlock completion;

@property (nonatomic, assign) BOOL isAwaitingResponse;
@property (nonatomic, assign) BOOL isGetPrivateKeyAction;

@property (nonatomic, assign) ProbableContactType probableContactType;
@property (nonatomic, assign) ProbableContactType lastTriedContactType;

@property (nonatomic, strong) NSString *qliqId;

@property (nonatomic, strong) QliqSipExtendedChatMessage *chatMessage;

@property (nonatomic, strong) NSMutableArray *triedServices;

@end

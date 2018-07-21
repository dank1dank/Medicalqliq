//  qliq
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqConnectModule.h"
#import "QliqModuleBase+Protected.h"
#import "JsonSchemas.h"
#import "QliqSipMessage.h"
#import "QliqSipChatMessage.h"
#import "QliqSipExtendedChatMessage.h"
#import "ChatMessage.h"
#import "Helper.h"
#import "QliqSip.h"
#import "NotificationUtils.h"
#import "QliqUserNotifications.h"
#import "Log.h"
#import "NSThread_backtrace.h"
#import "ChatMessageTypeSchema.h"
#import "Metadata.h"
#import "DBHelperConversation.h"
#import "JSONKit.h"
#import "ContactsDBObjects.h"
#import "AppDelegate.h"
#import "DBUtil.h"
#import "GetPublickeyResponseSchema.h"
#import "Crypto.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "AppDelegate.h"
#import "ConversationDBService.h"
#import "PutFileRequestSchema.h"
#import "GetFileRequestSchema.h"
#import "InvitationMessageSchema.h"
#import "JSONSchemaValidator.h"
#import "MediaFile.h"
#import "ChatMessageService.h"
#import "NSData+Base64.h"
#import "MessageStatusLogDBService.h"
#import "MessageStatusLog.h"
#import "Invitation.h"
#import "MediaFile.h"
#import "FindQliqUser.h"
#import "QliqUserDBService.h"
#import "InvitationService.h"
#import "ContactDBService.h"
#import "GetGroupInfoService.h"
#import "GetContactInfoService.h"
#import "KeychainService.h"
#import "DeviceStatusController.h"
#import "PushMessageToQliqStorHelper.h"
#import "CreateMultiPartyService.h"
#import "QliqGroupDBService.h"
#import "GetMultiPartyService.h"
#import "SipContactDBService.h"
#import "RecipientsDBService.h"
#import "ModifyMultiPartyService.h"
#import "MediaFileService.h"
#import "ChatEventHelper.h"
#import "ChatEventMessageSchema.h"
#import "EncryptedSipMessageDBService.h"
#import "MessageQliqStorStatusDBService.h"
#import "GetGroupKeyPair.h"
#import "QliqGroupDBService.h"
#import "MediaFileDBService.h"
#import "QliqJsonSchemaHeader.h"
#import "GetContactsPaged.h"
#import "ReceivedPushNotificationDBService.h"
#import "NSString+MKNetworkKitAdditions.h"
#import "ModifyConversationStatusService.h"
#import "qxlib/platform/ios/QxPlatfromIOS.h"
#import "Login.h"
#import "ChangeNotificationProcessor.h"
#import "GetQliqMessageForPushService.h"
#import "AlertController.h"

// Only the sender pushes message to qliqStor
#define SENDER_PUSHES_TO_QLIQSTOR 1

// The UI will be notified about new chat messages pulled from qliqStor if the count exceeds this threshold
#define PULLED_MESSAGES_NOTIFICATION_THRESHOLD 5
#define SIP_UNDECIPHERABLE_STATUS 493
#define QLIQSTOR_NOTIFY_IMPLEMENTATION 1

static QliqConnectModule *s_instance;
// We use static array because items can be added to it during app initialization before QliqConnect is instantiated
static NSMutableArray *s_pendingRemotePushNotifications;

NSString *ChatMessageStatusNotification = @"ChatMessageStatus";
NSString *NewChatMessagesNotification = @"NewChatMessages";
NSString *ChatMessageAttachmentStatusNotification = @"ChatMessageAttachmentStatus";
NSString *RecipientsChangedNotification = @"RecipientsChangedNotification";
NSString *ConversationMutedChangedNotification = @"ConversationMutedChangedNotification";
NSString *ConversationDeletedNotification = @"ConversationDeletedNotification";
NSString *QliqConnectDidDeleteMessagesInConversationNotification = @"QliqConnectDidDeleteMessagesInConversationNotification";
NSString *ChatMessageRecalledInConversationNotification = @"ChatMessageRecalledInConversationNotification";

@interface QliqConnectModule()

- (void)processExtendedChatMessage:(QliqSipExtendedChatMessage*)message;
- (void) processStructuredAttachments:(NSArray *)structuredAttachments;
- (void) sipSendMessage: (ChatMessage *)message;
- (void) sendOpenedStatus: (ChatMessage *)message;

- (void) notifyChatMessageStatus:(ChatMessage *)message;
- (void) notifyChatMessageAttachmentStatus:(MessageAttachment *)attachment;
- (void) notifyChatAck:(ChatMessage *)message withSound:(BOOL)playSound;
- (void) notifyNewChatMessagesWithConversation:(Conversation *) conversation;
- (void) notifyConversationDeleted:(NSInteger)conversationId;

- (void)processMessageStatus:(ChatMessage *)mmsg status:(int)status callId:(NSString *)aCallId qliqId:(NSString *)aQliqId deliveredRecipientCount:(int)aDeliveredRecipientCount totalRecipientCount:(int)aTotalRecipientCount deliveredAt:(long)aDeliveredAt;
- (void)processPermanentErrorMessageStatus:(NSInteger)status toQliqId:(NSString *)toQliqId;
- (void)processMessageStatusNotification:(NSNotification *)notification;
- (void)processPendingMessageStatusNotification:(NSNotification *)notification;
- (void)processOpenedMessageStatusNotification:(NSNotification *)notification;
- (void)processInvitation:(NSDictionary *)data;

// Resending messages
- (void) resendOneUndeliveredMessage;
- (void) recreateFailedMultiparties;

- (NSInteger) numberOfDaysBetweenDates:(NSDate *)d1 :(NSDate *)d2;
- (void) onPrivateKeyNeeded:(NSNotification *)notification;
- (void) onRegInfoReceivedNotification:(NSNotification *)notification;
- (void) onMessageDumpFinished:(NSNotification *)notification;
- (NSTimeInterval) parseAtTimeFromExtraHeader:(NSDictionary *)extraHeaders name:(NSString *)headerName wasFound:(BOOL *)found;

@property (nonatomic, strong) MessageAttachmentApiService *attachmentApiService;
@property (nonatomic, strong) ChatMessageService *chatMessageService;
@property (nonatomic, strong) MessageStatusLogDBService *statusLogDbService;
@property (nonatomic, strong) ChangeNotificationProcessor *cnProcessor;

@property (nonatomic, strong) NSOperationQueue *qliqConnectOperationQueue;
//@property (nonatomic, strong) dispatch_queue_t qliqConnectDispatchQueue;

@property (nonatomic, strong) NSMutableDictionary *getSipContactContexts;
@end

@implementation QliqConnectModule

@synthesize attachmentApiService;
@synthesize attachmentDelegate;

//@synthesize chatMessageService;
//@synthesize statusLogDbService;

@synthesize lastQliqStorPushDate;
@synthesize getSipContactContexts;

- (id)init
{
    self = [super init];
    if (self)
    {
        if (s_pendingRemotePushNotifications == nil) {
            s_pendingRemotePushNotifications = [[NSMutableArray alloc] init];
        }
        
        self.name = QliqConnectModuleName;
//        sentChatMessages = [[NSMutableSet alloc] init];
//        sentAcks = [[NSMutableSet alloc] init];
        self.sentChatMessages = [[NSMutableSet alloc] init];
        self.sentAcks = [[NSMutableSet alloc] init];
        sentAttachments = [[NSMutableDictionary alloc] init];
        s_instance = self;
        getSipContactContexts = [[NSMutableDictionary alloc] init];
        
        attachmentApiService = [[MessageAttachmentApiService alloc] init];
//        self.statusLogDbService = [[MessageStatusLogDBService alloc] init];
//        self.chatMessageService = [ChatMessageService sharedService];
        self.statusLogDbService = [[MessageStatusLogDBService alloc] init];
        self.cnProcessor = [[ChangeNotificationProcessor alloc] init];
        self.chatMessageService = [ChatMessageService sharedService];
        
        NSString *qliqId = [Helper getMyQliqId];
        if ([qliqId length] > 0)
        {
            [[ChatMessageService sharedService] markAllSendingMessagesAsTimedOutForUser:qliqId];
        }
        
        qliqStorPusher = [[PushMessageToQliqStorHelper alloc] init];
        
        NSTimeInterval oneDayInterval = 60 * 60 * 24;
        deleteOldMessagesTimer = [NSTimer scheduledTimerWithTimeInterval:oneDayInterval target:self selector:@selector(deleteOldMessages) userInfo:nil repeats:YES];
        
        maximumRetryCount = 3;
        permanentFailureStatusSet = [[NSMutableSet alloc] init];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:404]];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:MessageStatusNotContact]];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:MessageStatusNotMemberOfGroup]];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:MessageStatusPublicKeyNotSet]];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:MessageStatusTooManyRetries]];
        [permanentFailureStatusSet addObject:[NSNumber numberWithInt:MessageStatusAttachmentUploadAttachmentNotFound]];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processMessageStatusNotification:)
													 name: SIPMessageStatusNotification
												   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processPendingMessageStatusNotification:)
													 name: SIPPendingMessageStatusNotification
												   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processOpenedMessageStatusNotification:)
													 name: SIPOpenedMessageStatusNotification
												   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processAckedMessageStatusNotification:)
													 name: SIPAckedMessageStatusNotification
												   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processDeletedMessageStatusNotification:)
													 name: SIPDeletedMessageStatusNotification
												   object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(processRecalledMessageStatusNotification:)
													 name: SIPRecalledMessageStatusNotification
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(processRecipientStatusStatusNotification:)
                                                     name: SIPRecipientStatusNotification
                                                   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onRegInfoReceivedNotification:)
													 name: SIPRegInfoReceivedNotification
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onMessageDumpFinished:)
                                                     name: SipMessageDumpFinishedNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(removeNotificationObserver)
                                                     name: @"RemoveNotifications"
                                                   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onPrivateKeyNeeded:)
													 name: SIPPrivateKeyNeededNotification
												   object: nil];
        
      //  self.qliqConnectDispatchQueue = dispatch_queue_create("qliqconnect.queue", NULL);
        
        self.qliqConnectOperationQueue = [[NSOperationQueue alloc] init];
        self.qliqConnectOperationQueue.name = @"qliqconnect.queue";
        self.qliqConnectOperationQueue.maxConcurrentOperationCount = 1;
        
        [ChatMessage updateUnreadCountAsync];
    }
    return self;
    
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void) dealloc
{
//	dispatch_release(self.qliqConnectDispatchQueue);

    //    [attachmentApiService release];
    //    [attachmentDbService release];
    //	[statusLogDbService release];
    //    [conversationService release];
    [self.qliqConnectOperationQueue cancelAllOperations];
    self.qliqConnectOperationQueue = nil;
    
    [self removeNotificationObserver];
    //    [sentChatMessages release];
    //    [sentAcks release];
    //    [sentAttachments release];
    //    [pushedMessage release];
    //    [super dealloc];
}

- (UIImage *)moduleLogo {
    return [UIImage new];
}

/* Update qliq_id for messages in conversation with recipients.qliq_id and resend */
- (void)resendMessagesForMPConversation:(Conversation *)conversation
{
    NSArray * messages = [DBHelperConversation getMessagesForConversation:conversation.conversationId limit:-1];
    NSString *mpQliqId = conversation.recipients.qliqId;
    BOOL error = ([mpQliqId length] == 0);
    
    for (ChatMessage * message in messages)
    {
        if ([message.toQliqId length] == 0) {
            
            if (!error) {
                message.toQliqId = mpQliqId;
                [self sendMessage:message];
            }
            else {
                
                BOOL isBeginSent = NO;
                for (ChatMessage *sentMsg in self.sentChatMessages)
                {
                    if (sentMsg.messageId == message.messageId) {
                        isBeginSent = YES;
                        break;
                    }
                }
                
                if (!isBeginSent) {
                    [self.sentChatMessages addObject:message];
                }
                
                [self processMessageStatus:message status:503 callId:message.metadata.uuid qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
            }
        }
    }
}

/* Create Mutliparty via service and resend messages */
- (void)createMultiPartyForConversation:(Conversation *)multipartyConversation
{
    if (![CreateMultiPartyService hasOutstandingRequestForConversationId:multipartyConversation.conversationId]) {
        
        CreateMultiPartyService * createService = [[CreateMultiPartyService alloc] initWithRecipients:multipartyConversation.recipients andConversationId:multipartyConversation.conversationId];
        
        __block __weak typeof(self) weakSelf = self;
        [createService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            DDLogInfo(@"Multiparty created. QliqId: %@, error: %@", result, error);
            
            /* Resending messages with received qliq_id */
            [strongSelf resendMessagesForMPConversation:multipartyConversation];
        }];
    }
}

/* Trying to get conversation with recipients and subject */
- (Conversation *)conversationWithRecipients:(Recipients *)recipients andSubject:(NSString *)subject {
    
    Conversation * conversation = nil;
    
    if ([recipients isSingleUser] || [recipients isGroup]){
        
        NSInteger conversationId = [[ConversationDBService sharedService] getConversationId:recipients.qliqId andSubject:subject];
        if (conversationId != 0) {
            conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:conversationId]];
        }
    }
    return conversation;
}

- (Conversation *)newConversationWithRecipients:(Recipients *)recipients subject:(NSString *)subject broadcastType:(BroadcastType)broadcastType uuid:(NSString *)uuid
{
    if (uuid.length == 0) {
        uuid = [Metadata generateUuid];
    }
    Conversation *newConversation = [[Conversation alloc] initWithPrimaryKey:0];
	newConversation.subject     = subject;
    newConversation.recipients  = recipients;
    newConversation.uuid        = uuid;
    newConversation.broadcastType = broadcastType;
    
    if (![[ConversationDBService sharedService] saveConversation:newConversation]){
        newConversation = nil;
    }
    DDLogSupport(@"Save new conversation on DB with uuid - %@, subject - %@", newConversation.uuid, newConversation.subject.length<1 ? @"without subject" : newConversation.subject);
    
    return newConversation;
}

/* General method to create conversation */
- (Conversation *)createConversationWithRecipients:(Recipients *)recipients subject:(NSString *)subject broadcastType:(BroadcastType)broadcastType uuid:(NSString *)uuid
{
    // Since we have conversatio uuid we always create a new conversation
    /* Trying to get existing conversation */
//    Conversation * conversation = [self conversationWithRecipients:recipients andSubject:subject];
//    
//    if (!conversation){
    
    Conversation *conversation = [self newConversationWithRecipients:recipients subject:subject broadcastType:broadcastType uuid:uuid];
    
        if (conversation && [recipients isMultiparty]) {
            /* Create Multiparty via service */
            [self createMultiPartyForConversation:conversation];
        }
//    }
    
    return conversation;
}

- (void)setRecipients:(Recipients *)newRecipients toConversation:(Conversation *)conversation
{
    ConversationDBService * conversationDBService = [[ConversationDBService alloc] init];
    RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] init];
    
     //Modify conversation in transaction to avoid empty participants on error
    __block BOOL success = NO;
    Recipients *oldRecipients = conversation.recipients;
    
    [[DBUtil sharedQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        /* Remove old recipients to replace with new one */ //AII remove recipients problem
        [recipientsDBService deleteObject:conversation.recipients mode:(DBModeToMany | DBModeToOne) completion:nil];
        
        //Add Self user to recipients as needed
        QliqUser *selfUser = [UserSessionService currentUserSession].user;
        if (![newRecipients containsRecipient:selfUser]) {
            [newRecipients addRecipient:selfUser];
        }

        conversation.recipients = newRecipients;
        
        /* Save conversation with new recipients */
        if (![conversationDBService saveConversation:conversation]) {
            *rollback = YES;
        } else {
            success = YES;
        }
    }];

    if (success) {
        /* Send changed event */
        [self sendParticipantsChangedEventMessageForConversation:conversation withOldRecipients:oldRecipients withNewRecipients:newRecipients];
    }
}

- (void)modifyConversation:(Conversation *)conversation byRecipients:(Recipients *)newRecipients andSubject:(NSString *)newSubject complete:(CompletionBlock)complete{
    
    ConversationDBService * conversationDBService = [[ConversationDBService alloc] init];
    
    BOOL recipientsChanged = ![newRecipients isEqual:conversation.recipients];
    BOOL subjectChanged = ![newSubject isEqualToString:conversation.subject];
    
    /* Nothing changes */
    if (!recipientsChanged && !subjectChanged){
        /* Return as is */
        if (complete)
            complete(CompletitionStatusSuccess, conversation, nil);
    }
    /* Subject changed - create a new conversation */
    else if (subjectChanged) {
        conversation = [[QliqConnectModule sharedQliqConnectModule] createConversationWithRecipients:newRecipients subject:newSubject broadcastType:conversation.broadcastType uuid:nil];
        [conversationDBService saveConversation:conversation];
        if (complete) complete(CompletitionStatusSuccess, conversation, nil);
    }
    /* MP -> MP */
    else if ([conversation.recipients isMultiparty] && [newRecipients isMultiparty]) {
        
        ModifyMultiPartyService * modifyMPService = [[ModifyMultiPartyService alloc] initWithRecipients:conversation.recipients modifiedRecipients:newRecipients];
        
        __block __weak typeof(self) weakSelf = self;
        [modifyMPService callServiceWithCompletition:^(CompletitionStatus status, Recipients *result, NSError *error) {

            if (status == CompletitionStatusSuccess) {
                [weakSelf setRecipients:result toConversation:conversation];
            }
            if (complete) complete(status, conversation, error);
        }];
    }
    /* SP -> MP */
    else if ([newRecipients isMultiparty]){
        
        CreateMultiPartyService * createService = [[CreateMultiPartyService alloc] initWithRecipients:newRecipients andConversationId:conversation.conversationId];
        
        __block __weak typeof(self) weakSelf = self;
        [createService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess) {
                [weakSelf setRecipients:newRecipients toConversation:conversation];
            }
            if (complete) complete(status, conversation, error);
        }];
    }
    /* else: SP -> SP OR MP -> SP */
    else {
        [self setRecipients:newRecipients toConversation:conversation];
        if (complete) complete(CompletitionStatusSuccess, conversation, nil);
    }
}

+ (void) setConversationMuted:(NSInteger)conversationId withUuid:(NSString *)uuid withMuted:(BOOL)muted withCallWebService:(BOOL)callWebService
{
    ConversationDBService *conversationDb = [ConversationDBService sharedService];
    Conversation *conv = nil;
    
    if (conversationId > 0) {
        conv = [conversationDb getConversationWithId:[NSNumber numberWithInteger:conversationId]];
    }
    
    if (!conv && uuid.length > 0) {
        conv = [conversationDb getConversationWithUuid:uuid];
    }
    
    if (conv) {
        BOOL oldMuted = conv.isMuted;
        if (oldMuted != muted) {
            [conversationDb updateMuted:conv.conversationId withMuted:muted];
            if (callWebService) {
                ModifyConversationStatusService *service = [[ModifyConversationStatusService alloc] initWithConversationUuid:conv.uuid withMuted:muted];
                [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                    // TODO: show error if any
                }];
            }
            conv.isMuted = muted;
            [NSNotificationCenter postNotificationToMainThread:ConversationMutedChangedNotification  withObject:conv userInfo:nil];
        }
    } else {
        DDLogError(@"Cannot get conversation to mute with either id: %ld or uuid: %@", (long)conversationId, uuid);
    }
}

#pragma mark - Protected
//AII
- (BOOL)handleSipMessage:(QliqSipMessage *)message {

    BOOL result = NO;
    
    DDLogSupport(@"QliqConnect received message, command: '%@', subject: '%@'", message.command, message.subject);
    
    if ([message.command isEqualToString:EXTENDED_CHAT_MESSAGE_MESSAGE_COMMAND_PATTERN] &&
        [message.subject isEqualToString:EXTENDED_CHAT_MESSAGE_MESSAGE_SUBJECT_PATTERN]) {
        
        QliqSipExtendedChatMessage *chatMessage = (QliqSipExtendedChatMessage *)message;
        [self processExtendedChatMessage:chatMessage];
        
        result = YES;
    }
    else if ([message.command isEqualToString:INVITATION_MESSAGE_COMMAND_PATTERN] &&
             [message.subject isEqualToString:INVITATION_MESSAGE_SUBJECT_PATTERN]) {

        NSDictionary *dataDict = (NSDictionary *)message.data;
        [self processInvitation:dataDict];
        
        result = YES;
    }
    else if ([message.command isEqualToString:@"hl7message"]) {
        DDLogSupport(@"hl7message");
    } else {
        result = [self.cnProcessor handleSipMessage:message];
    }

    if (![UserSessionService isLogoutInProgress]) { 
        [self resendOneUndeliveredMessage];
    }
    
    return result;
}

- (void)onSipRegistrationStatusChanged:(BOOL)registered status:(NSInteger)status isReRegistration:(BOOL)reregistration {
    // KK - 9/23/2015
    //
    // Changed to status 200
    //
    //if (registered && [QliqSip sharedQliqSip].lastRegistrationResponseCode==200 &&
    if (registered && status==200 &&
        (![[QliqSip sharedQliqSip] isMultiDeviceSupported] || wasRegInfoReceived)) {
        
        DDLogInfo(@"Registration changed to on and successful, resending messages");
        
        [self recreateFailedMultiparties];
        [self resendOneUndeliveredMessage];
        [qliqStorPusher startPushing];
    }
}

- (void)onRegInfoReceivedNotification:(NSNotification *)notification {
    wasRegInfoReceived = YES;
    [self onSipRegistrationStatusChanged:YES status:200 isReRegistration:NO];
}

- (void)onMessageDumpFinished:(NSNotification *)notification {
    DDLogSupport(@"->> On message dumb finished");
    NSInteger unreadCount = [ChatMessage unreadMessagesCount] + appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt;
    [[QliqUserNotifications getInstance] refreshAppBadge:unreadCount];
    
    NSNumber *error = notification.userInfo[@"error"];
    if ([error boolValue] == NO && [UserSessionService isOfflineDueToBatterySavingMode] == NO) {
        [self resendOneUndeliveredMessage];
    }
}

#pragma mark - Private

#pragma mark *** Process ***

/* Clean code went away. TODO: Refactor into small obvious methods
*/
- (void)processExtendedChatMessage:(QliqSipExtendedChatMessage *)sipMessage {
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
       
        __strong typeof(self) strongSelf = weakSelf;
        
        ChatMessage *existingMsg = nil;
        NSInteger newMsgId = 0;
        SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
        SipContact * myContact = [sipContactService sipContactForQliqId:[UserSessionService currentUserSession].user.qliqId];
        
        /* Get SIP info from URI */
        SipContact *fromContact = [sipContactService sipContactForQliqId:sipMessage.fromQliqId];
        SipContact *toContact   = [sipContactService sipContactForQliqId:sipMessage.toQliqId];
        NSString *recipients_qliqId = fromContact.qliqId;
        
        if (fromContact.qliqId.length == 0) {
            DDLogError(@"Cannot find a SIP contact for 'from qliq id': %@", sipMessage.fromQliqId);
            [strongSelf getAnySipContact:sipMessage.fromQliqId probableType:UserProbableContactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
            return;
        }
        
        if (toContact.qliqId.length == 0) {
            NSString *recipientType = sipMessage.recipientType;
            ProbableContactType contactType = UnknownProbableContactType;
            if ([@"user" isEqualToString:recipientType]) {
                contactType = UserProbableContactType;
            } else if ([@"group" isEqualToString:recipientType]) {
                contactType = GroupProbableContactType;
            } if ([@"mp" isEqualToString:recipientType]) {
                contactType = MultipartyProbableContactType;
            }
            
            DDLogError(@"Cannot find a SIP contact for 'to qliq id': %@", sipMessage.toQliqId);
            [strongSelf getAnySipContact:sipMessage.toQliqId probableType:contactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
            return;
        }
        
        BOOL isSenderSync = NO;
        
        if ([toContact.qliqId isEqualToString: myContact.qliqId]) {
            if ([fromContact.qliqId isEqualToString: myContact.qliqId]) {
                if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
                    // Sender sync message
                    if (!sipMessage.toUserId) {
                        DDLogError(@"QliqSipExtendedChatMessage.toUserID is nil for sender sync, message: %@",sipMessage);
                        DDLogError(@"Callstack: %@",[NSThread callStackSymbolsWithLimit:0]);
                        return;
                    }
                    
                    isSenderSync = YES;
                    toContact = [sipContactService sipContactForQliqId:sipMessage.toUserId];
                    
                    if (toContact.qliqId.length == 0) {
                        DDLogError(@"Cannot find a SIP contact for 'to qliq id' (sender sync): %@", sipMessage.toUserId);
                        sipMessage.extraHeaders[@"X-sender-sync"] = @"yes";
                        [strongSelf getAnySipContact:sipMessage.toUserId probableType:UnknownProbableContactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
                        return;
                    }
                    
                    recipients_qliqId = toContact.qliqId;
                }
            }
        } else if (toContact.sipContactType == SipContactTypeMultiPartyChat) {
            recipients_qliqId = toContact.qliqId;
        } else if (toContact.sipContactType == SipContactTypeGroup) {
            recipients_qliqId = toContact.qliqId;
        } else if (toContact.sipContactType == SipContactTypeUser) {
            DDLogError(@"The to URI: %@ doesn't match mine", toContact.sipUri);
            return;
        }
        
        if ([fromContact.qliqId isEqualToString: myContact.qliqId] && [sipMessage.extraHeaders[@"X-no-sender-sync"] isEqualToString:@"yes"]) {
            isSenderSync = true;
        }
        
        // Check if we already have this message. This can happen if a message is resent
        existingMsg = [ChatMessageService getMessageWithUuid:sipMessage.messageId];
        
        if (existingMsg == nil){
            
            Conversation * conversation = [strongSelf conversationForReceivedMessage:sipMessage fromQliqId:recipients_qliqId toQliqId:toContact.qliqId];
            
            //Broadcasting type
            {
                BroadcastType broadcastType = NotBroadcastType;
                NSString *groupBroadcast = [sipMessage.extraHeaders objectForKey:@"X-group-broadcast"];
                
                if (groupBroadcast && [@"yes" isEqualToString:groupBroadcast]) {
                    sipMessage.toQliqId = myContact.qliqId;
                    if (isSenderSync) {
                        if ([sipMessage.extraHeaders[@"Content-Type"] isEqualToString:@"text/plain"]) {
                            broadcastType = PlainTextBroadcastType;
                        } else {
                            broadcastType = EncryptedBroadcastType;
                        }
                    } else {
                        conversation.redirectQliqId = sipMessage.fromQliqId;
                        broadcastType = ReceivedBroadcastType;
                    }
                }
                
                if (conversation.broadcastType != broadcastType)
                {
                    if (conversation.isBroadcast && broadcastType == NotBroadcastType)
                    {
                        DDLogError(@"Trying to change BC conversation to NotBroadcastType. X-group-broadcast: %@. Skip changing. If conversation created as BC, it should stay BC.", groupBroadcast);
                    }
                    else
                    {
                        conversation.broadcastType = broadcastType;
                        [[ConversationDBService sharedService] saveConversation:conversation];
                    }
                }
            }
            
            BOOL isMuted = NO;
            if (sipMessage.extraHeaders[@"X-conversation-muted"] && [sipMessage.extraHeaders[@"X-conversation-muted"] isEqualToString:@"yes"]) {
                isMuted = YES;
            }
            else if (sipMessage.extraHeaders[@"X-conversation-muted"] == nil) {
                isMuted = conversation.isMuted;
            }
            
            conversation.isMuted = isMuted;
            [QliqConnectModule setConversationMuted:conversation.conversationId withUuid:conversation.uuid withMuted:conversation.isMuted withCallWebService:NO];
            
            ChatMessage *newMessage = nil;
            if(conversation.conversationId>0)
            {
                // Create new message and save to database.
                newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
                newMessage.conversationId = conversation.conversationId;
                newMessage.fromQliqId = fromContact.qliqId;
                newMessage.toQliqId = toContact.qliqId;
                newMessage.text = sipMessage.messageText;
                newMessage.deliveryStatus = MessageStatusDelivered;
                
                //we wanted the timestamp and receivedAt being the same value
                NSTimeInterval receivedTime = [[NSDate date] timeIntervalSince1970];
                newMessage.timestamp = receivedTime;
                newMessage.receivedAt = receivedTime;
                newMessage.ackRequired = sipMessage.requireAck;
                newMessage.priority = [ChatMessage priorityFromString:sipMessage.priority];

                if (newMessage.priority == ChatMessagePriorityUrgen && !newMessage.ackRequired) {
                    // First version of iPhone app was buggy and didn't set require ack for urgent messages
                    newMessage.ackRequired = YES;
                }
                newMessage.type = [ChatMessage typeFromString:sipMessage.dataType];
                newMessage.createdAt = [[QliqSip sharedQliqSip] adjustedTimeFromNetwork:sipMessage.createdAt];
                
                newMessage.metadata = [Metadata createNew];
                newMessage.metadata.uuid = sipMessage.messageId;
                newMessage.metadata.isRevisionDirty = NO; // the recipient doesn't push to qliqStor
                
                NSString *serverContext = [sipMessage.extraHeaders objectForKey:@"X-server-context"];
                if ([serverContext length] > 0) {
                    newMessage.serverContext = serverContext;
                }
                
                if (newMessage.type == ChatMessageTypeUnknown) {
                    DDLogError(@"A chat message with unknown type received: %@", sipMessage.dataType);
                    return;
                } else if (newMessage.type != ChatMessageTypeNormal) {
                    // TODO: should Care Team updated message be unread? (Adam Sowa)
                    // Only normal messages are marked as unread.
                    newMessage.readAt = newMessage.receivedAt;
                }
                
                //Attachments
                {
                    NSArray *attachments = [sipMessage.data objectForKey:@"attachments"];
                    NSMutableArray *messageAttachments = [[NSMutableArray alloc] initWithCapacity:[attachments count]];
                    
                    for(NSDictionary *attachment in attachments)
                    {
                        MessageAttachment *chatMessageAttachment = [[MessageAttachment alloc] initWithDictionary:attachment];
                        chatMessageAttachment.messageUuid = [newMessage uuid];
                        
                        if([chatMessageAttachment save])
                            [messageAttachments addObject:chatMessageAttachment];
                    }
                    
                    newMessage.attachments = [NSArray arrayWithArray:messageAttachments];
                }
                
                NSTimeInterval timestamp = 0;
                BOOL wasTimestampFound = NO;
                BOOL createReadStatusLog = NO;
                if (isSenderSync) {
                    //newMessage.timestamp = sipMessage.createdAt;
                    newMessage.readAt = newMessage.timestamp;
                    newMessage.createdAt = newMessage.timestamp;
                    newMessage.selfDeliveryStatus = MessageStatusSynced;
                    newMessage.deliveryStatus = MessageStatusSynced;
                } else {
                    timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-opened" wasFound:&wasTimestampFound];
                    if (wasTimestampFound) {
                        newMessage.readAt = timestamp;
                        newMessage.isOpenedSent = YES;
                        createReadStatusLog = YES;
                    }
                    if (newMessage.isRead == 0) {
                        conversation.isRead = NO;
                        [[ConversationDBService sharedService] saveConversation:conversation];
                    }
                }
                
                //timestamp = 0;
                wasTimestampFound = NO;
                timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-created" wasFound:&wasTimestampFound];
                if (wasTimestampFound) {
                    newMessage.createdAt = timestamp;
                }
                
                conversation.lastMsg = newMessage.text;
                conversation.lastUpdated = newMessage.createdAt;
                
                if(conversation.archived || conversation.deleted) {
                    DDLogSupport(@"Restoring conversation id: %ld", (long)conversation.conversationId);
                    [[ConversationDBService sharedService] restoreConversations:[NSArray arrayWithObject:conversation]];
                    conversation.archived = conversation.deleted = NO;
                }
                
                // [ChatMessageService saveMessage] emits notification to UI,
                // that is why we process structured attechments before hand so UI can load the related data of conversation on notification
                NSArray *structuredAttachments = [sipMessage.data objectForKey:@"structuredAttachments"];
                if ([structuredAttachments count] > 0) {
                    [strongSelf processStructuredAttachments:structuredAttachments];
                    
                    NSDictionary *firstAttachment = [structuredAttachments objectAtIndex:0];
                    if ([firstAttachment[@"type"] isEqualToString:@"fhir/json"]) {
                        conversation.isCareChannel = YES;
                    }
                }
                
                [weakSelf.chatMessageService saveMessage:newMessage inConversation:conversation];
                BOOL wereMessageTimesModified = NO;
                
                // Save the status message
                // the status is sent with createdAt timestamp
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = newMessage.messageId;
                statusLog.timestamp = newMessage.createdAt;
                statusLog.status = CreatedMessageStatus;
                [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                
                timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-sent" wasFound:&wasTimestampFound];
                if (wasTimestampFound) {
                    statusLog.timestamp = timestamp;
                    statusLog.status = SentMessageStatus;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                }
                
                NSString *headerValue = [sipMessage.extraHeaders objectForKey:@"X-pushnotifies-sent-at"];
                if (headerValue.length > 0) {
                    NSArray *timestampStrings = [headerValue componentsSeparatedByString:@";"];
                    for (NSString *str in timestampStrings) {
                        NSTimeInterval timestamp = [str longLongValue];
                        timestamp += [[QliqSip sharedQliqSip]serverTimeDelta];
                        
                        if (timestamp > 0) {
                            statusLog.timestamp = timestamp;
                            statusLog.status = PushNotificationSentByServerStatus;
                            statusLog.qliqId = nil;
                            [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                        }
                    }
                }
                
                ReceivedPushNotification *receivedPush = [ReceivedPushNotificationDBService selectWithCallId:newMessage.metadata.uuid];
                if (receivedPush != nil) {
                    statusLog.messageId = newMessage.messageId;
                    statusLog.timestamp = newMessage.createdAt;
                    statusLog.status = PushNotificationReceivedMessageStatus;
                    statusLog.qliqId = nil;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                    
                    if (receivedPush.isSentToServer) {
                        [ReceivedPushNotificationDBService remove:receivedPush.callId];
                    }
                }
                
                BOOL wasReceivedOnOtherDevice = NO;
                if (isSenderSync) {
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = SyncedMessageStatus;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                } else {
                    timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
                    if (wasTimestampFound) {
                        // Change received timestamp only if the message was read already
                        [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
                        if (wasTimestampFound) {
                            newMessage.receivedAt = timestamp;
                        }
                        statusLog.status = ReceivedByAnotherDeviceMessageStatus;
                        wasReceivedOnOtherDevice = YES;
                        wereMessageTimesModified = YES;
                    } else {
                        statusLog.status = ReceivedMessageStatus;
                    }
                    
                    // the status is receibed with receivedAt timestamp
                    statusLog.messageId = newMessage.messageId;
                    statusLog.timestamp = newMessage.receivedAt;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                    
                    if (createReadStatusLog) {
                        timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-opened" wasFound:&wasTimestampFound];
                        if (wasTimestampFound) {
                            newMessage.readAt = timestamp;
                            wereMessageTimesModified = YES;
                        }
                        statusLog.timestamp = newMessage.readAt;
                        statusLog.status = ReadMessageStatus;
                        [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                    }
                }
                
                if (wasReceivedOnOtherDevice) {
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = ReceivedMessageStatus;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                }
                
                if (wereMessageTimesModified) {
                    [weakSelf.chatMessageService saveMessage:newMessage inConversation:conversation];
                }
                
                if (newMessage.messageId == 0)
                {
                    // TODO: Handle the error appropriately.
                    //DDLogSupport(@"sendMessage error %d", newMsgId);
                    DDLogError(@"Error inserting new message %ld", (long)newMsgId);
                }
            }
            
            // Optimization for a case when we are already chatting with the sender.
            // The view will call our method saveMessageAsRead,
            // in this method we will mark this message as read so we will push this field
            // in the first push to qliqStor
            justReceivedMessage = newMessage;
            
            [strongSelf notifyNewChatMessagesWithConversation:conversation];
            
            if (newMessage.type == ChatMessageTypeEvent) {
                NSDictionary *eventDictionary = [ChatEventHelper eventDictFromString:newMessage.text];
                
                if ([eventDictionary[CHAT_EVENT_MESSAGE_EVENT_TYPE] isEqualToString:@"participants-changed"]) {
                    [NSNotificationCenter postNotificationToMainThread:RecipientsChangedNotification  withObject:conversation userInfo:nil];
                }
            }
            
            DDLogSupport(@"processExtendedChatMessage: senderSync=%d, normalMessage=%d", isSenderSync, [newMessage isNormalChatMessage]);
            if (!isSenderSync && [newMessage isNormalChatMessage]) {
                NSString *noSoundString = [sipMessage.extraHeaders objectForKey:@"X-nosound"];
                BOOL noSound = noSoundString.length > 0 && ([noSoundString compare:@"yes" options:NSCaseInsensitiveSearch] == NSOrderedSame);
                if (conversation.isMuted && !noSound) {
                    noSound = YES;
                }
                [[QliqUserNotifications getInstance] notifyIncomingChatMessage:newMessage forCareChannel:[conversation isCareChannel] withoutSound:noSound];
            }
            
            if ([AppDelegate applicationState] == UIApplicationStateBackground)
            {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[NSNumber numberWithInteger:newMessage.conversationId] forKey:@"lastActiveConversationId"];
                [defaults synchronize];
            }
            
            justReceivedMessage = nil;
        }
        else
        {
            BOOL isDuplicate = ([fromContact.qliqId isEqualToString:existingMsg.fromQliqId] &&
                                [existingMsg.subject isEqualToString:sipMessage.conversationSubject] &&
                                [existingMsg.text isEqualToString:sipMessage.messageText]);
            if (isDuplicate) {
                
                if (existingMsg.type == ChatMessageTypeEvent) {
                    NSDictionary *eventDictionary = [ChatEventHelper eventDictFromString:existingMsg.text];
                    if ([eventDictionary[CHAT_EVENT_MESSAGE_EVENT_TYPE] isEqualToString:@"participants-changed"] && eventDictionary[CHAT_EVENT_MESSAGE_REMOVED]) {
                        Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:existingMsg.conversationId]];
                        [NSNotificationCenter postNotificationToMainThread:RecipientsChangedNotification  withObject:conversation userInfo:nil];
                    }
                } else {
                    DDLogSupport(@"Ignoring incoming chat message duplicate, uuid: %@, from: %@", sipMessage.messageId, fromContact.qliqId);
                }
            } else {
                DDLogError(@"Received a different message with an existing uuid: %@, new from: %@, exsting from: %@"
#ifdef DEBUG
                           " new subject: '%@', existing subject: '%@', new text: '%@', existing text: '%@'"
#endif
                           , sipMessage.messageId, fromContact.qliqId, existingMsg.fromQliqId
#ifdef DEBUG
                           , sipMessage.conversationSubject, existingMsg.subject, sipMessage.messageText, existingMsg.text
#endif
                           );
            }
        }
        
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        ChatMessage *existingMsg = nil;
//        NSInteger newMsgId = 0;
//        SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
//        
//        SipContact * myContact = [sipContactService sipContactForQliqId:[UserSessionService currentUserSession].user.qliqId];
//        
//        BOOL isBroadcast = NO;
//        {
//            NSString *groupBroadcast = [sipMessage.extraHeaders objectForKey:@"X-group-broadcast"];
//            if (groupBroadcast && [@"yes" isEqualToString:groupBroadcast]) {
//                sipMessage.toQliqId = myContact.qliqId;
//                isBroadcast = YES;
//            }
//        }
//        
//        /* Get SIP info from URI */
//        SipContact *fromContact = [sipContactService sipContactForQliqId:sipMessage.fromQliqId];
//        SipContact *toContact   = [sipContactService sipContactForQliqId:sipMessage.toQliqId];
//        NSString *recipients_qliqId = fromContact.qliqId;
//        
//        if (fromContact.qliqId.length == 0) {
//            DDLogError(@"Cannot find a SIP contact for 'from qliq id': %@", sipMessage.fromQliqId);
//            [strongSelf getAnySipContact:sipMessage.fromQliqId probableType:UnknownProbableContactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
//            return;
//        }
//        
//        if (toContact.qliqId.length == 0) {
//            DDLogError(@"Cannot find a SIP contact for 'to qliq id': %@", sipMessage.toQliqId);
//            [strongSelf getAnySipContact:sipMessage.toQliqId probableType:UnknownProbableContactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
//            return;
//        }
//        
//        BOOL isSenderSync = NO;
//        
//        if ([toContact.qliqId isEqualToString: myContact.qliqId]) {
//            if ([fromContact.qliqId isEqualToString: myContact.qliqId]) {
//                if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
//                    // Sender sync message
//                    if (!sipMessage.toUserId) {
//                        DDLogError(@"QliqSipExtendedChatMessage.toUserID is nil for sender sync, message: %@",sipMessage);
//                        DDLogError(@"Callstack: %@",[NSThread callStackSymbolsWithLimit:0]);
//                        return;
//                    }
//                    
//                    isSenderSync = YES;
//                    toContact = [sipContactService sipContactForQliqId:sipMessage.toUserId];
//                    
//                    if (toContact.qliqId.length == 0) {
//                        DDLogError(@"Cannot find a SIP contact for 'to qliq id' (sender sync): %@", sipMessage.toUserId);
//                        sipMessage.extraHeaders[@"X-sender-sync"] = @"yes";
//                        [strongSelf getAnySipContact:sipMessage.toUserId probableType:UnknownProbableContactType isGetPrivateKeyAction:NO chatMessage:sipMessage extraHeaders:sipMessage.extraHeaders withCompletion:nil];
//                        return;
//                    }
//                    
//                    recipients_qliqId = toContact.qliqId;
//                }
//            }
//        } else if (toContact.sipContactType == SipContactTypeMultiPartyChat) {
//            recipients_qliqId = toContact.qliqId;
//        } else if (toContact.sipContactType == SipContactTypeGroup) {
//            recipients_qliqId = toContact.qliqId;
//        } else if (toContact.sipContactType == SipContactTypeUser) {
//            DDLogError(@"The to URI: %@ doesn't match mine", toContact.sipUri);
//            return;
//        }
//        
//        // Check if we already have this message. This can happen if a message is resent
//        existingMsg = [ChatMessageService getMessageWithUuid:sipMessage.messageId];
//        
//        if (existingMsg == nil){
//            
//            Conversation * conversation = [strongSelf conversationForReceivedMessage:sipMessage fromQliqId:recipients_qliqId];
//            
//            if (isSenderSync && isBroadcast) {
//                conversation.isBroadcast = YES;
//                [[ConversationDBService sharedService] saveConversation:conversation];
//            }
//            
//            ChatMessage *newMessage = nil;
//            if(conversation.conversationId>0)
//            {
//                // Create new message and save to database.
//                newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
//                newMessage.conversationId = conversation.conversationId;
//                newMessage.fromQliqId = fromContact.qliqId;
//                newMessage.toQliqId = toContact.qliqId;
//                newMessage.text = sipMessage.messageText;
//                newMessage.deliveryStatus = MessageStatusDelivered;
//                
//                //we wanted the timestamp and receivedAt being the same value
//                NSTimeInterval receivedTime = [[NSDate date] timeIntervalSince1970];
//                newMessage.timestamp = receivedTime;
//                newMessage.receivedAt = receivedTime;
//                newMessage.ackRequired = sipMessage.requireAck;
//                newMessage.priority = [ChatMessage priorityFromString:sipMessage.priority];
//                if (newMessage.priority == ChatMessagePriorityUrgen && !newMessage.ackRequired) {
//                    // First version of iPhone app was buggy and didn't set require ack for urgent messages
//                    newMessage.ackRequired = YES;
//                }
//                newMessage.type = [ChatMessage typeFromString:sipMessage.dataType];
//                newMessage.createdAt = [[QliqSip sharedQliqSip] adjustedTimeFromNetwork:sipMessage.createdAt];
//                
//                newMessage.metadata = [Metadata createNew];
//                newMessage.metadata.uuid = sipMessage.messageId;
//                newMessage.metadata.isRevisionDirty = NO; // the recipient doesn't push to qliqStor
//                
//                NSString *serverContext = [sipMessage.extraHeaders objectForKey:@"X-server-context"];
//                if ([serverContext length] > 0) {
//                    newMessage.serverContext = serverContext;
//                }
//                
//                if (newMessage.type == ChatMessageTypeUnknown) {
//                    DDLogError(@"A chat message with unknown type received: %@", sipMessage.dataType);
//                    return;
//                } else if (newMessage.type != ChatMessageTypeNormal) {
//                    // Only normal messages are marked as unread.
//                    newMessage.readAt = newMessage.receivedAt;
//                }
//                
//                //Attachments
//                {
//                    NSArray *attachments = [sipMessage.data objectForKey:@"attachments"];
//                    NSMutableArray *messageAttachments = [[NSMutableArray alloc] initWithCapacity:[attachments count]];
//                    
//                    for(NSDictionary *attachment in attachments)
//                    {
//                        MessageAttachment *chatMessageAttachment = [[MessageAttachment alloc] initWithDictionary:attachment];
//                        chatMessageAttachment.messageUuid = [newMessage uuid];
//                        
//                        if([chatMessageAttachment save])
//                            [messageAttachments addObject:chatMessageAttachment];
//                    }
//                    
//                    newMessage.attachments = [NSArray arrayWithArray:messageAttachments];
//                }
//                
//                NSTimeInterval timestamp = 0;
//                BOOL wasTimestampFound = NO;
//                BOOL createReadStatusLog = NO;
//                if (isSenderSync) {
//                    //newMessage.timestamp = sipMessage.createdAt;
//                    newMessage.readAt = newMessage.timestamp;
//                    newMessage.createdAt = newMessage.timestamp;
//                    newMessage.selfDeliveryStatus = MessageStatusSynced;
//                    newMessage.deliveryStatus = MessageStatusSynced;
//                } else {
//                    timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-opened" wasFound:&wasTimestampFound];
//                    if (wasTimestampFound) {
//                        newMessage.readAt = timestamp;
//                        newMessage.isOpenedSent = YES;
//                        createReadStatusLog = YES;
//                    }
//                    if (newMessage.isRead == 0) {
//                        conversation.isRead = NO;
//                        [[ConversationDBService sharedService] saveConversation:conversation];
//                    }
//                }
//                
//                //timestamp = 0;
//                wasTimestampFound = NO;
//                timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-created" wasFound:&wasTimestampFound];
//                if (wasTimestampFound) {
//                    newMessage.createdAt = timestamp;
//                }
//                
//                conversation.lastMsg = newMessage.text;
//                conversation.lastUpdated = newMessage.createdAt;
//                
//                if(conversation.archived || conversation.deleted) {
//                    NSLog(@"Restoring conversation id: %ld", (long)conversation.conversationId);
//                    [[ConversationDBService sharedService] restoreConversations:[NSArray arrayWithObject:conversation]];
//                    conversation.archived = conversation.deleted = NO;
//                }
//                
//                [chatMessageService saveMessage:newMessage inConversation:conversation];
//                BOOL wereMessageTimesModified = NO;
//                
//                // Save the status message
//                // the status is sent with createdAt timestamp
//                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                statusLog.messageId = newMessage.messageId;
//                statusLog.timestamp = newMessage.createdAt;
//                statusLog.status = CreatedMessageStatus;
//                [statusLogDbService saveMessageStatusLog:statusLog];
//                
//                timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-sent" wasFound:&wasTimestampFound];
//                if (wasTimestampFound) {
//                    statusLog.timestamp = timestamp;
//                    statusLog.status = SentMessageStatus;
//                    [statusLogDbService saveMessageStatusLog:statusLog];
//                }
//                
//                NSString *headerValue = [sipMessage.extraHeaders objectForKey:@"X-pushnotifies-sent-at"];
//                if (headerValue.length > 0) {
//                    NSArray *timestampStrings = [headerValue componentsSeparatedByString:@";"];
//                    for (NSString *str in timestampStrings) {
//                        NSTimeInterval timestamp = [str longLongValue];
//                        timestamp += [[QliqSip sharedQliqSip]serverTimeDelta];
//                        
//                        if (timestamp > 0) {
//                            statusLog.timestamp = timestamp;
//                            statusLog.status = PushNotificationSentByServerStatus;
//                            statusLog.qliqId = nil;
//                            [statusLogDbService saveMessageStatusLog:statusLog];
//                        }
//                    }
//                }
//                
//                ReceivedPushNotification *receivedPush = [ReceivedPushNotificationDBService selectWithCallId:newMessage.metadata.uuid];
//                if (receivedPush != nil) {
//                    statusLog.messageId = newMessage.messageId;
//                    statusLog.timestamp = newMessage.createdAt;
//                    statusLog.status = PushNotificationReceivedMessageStatus;
//                    statusLog.qliqId = nil;
//                    [statusLogDbService saveMessageStatusLog:statusLog];
//                    
//                    if (receivedPush.isSentToServer) {
//                        [ReceivedPushNotificationDBService remove:receivedPush.callId];
//                    }
//                }
//                
//                BOOL wasReceivedOnOtherDevice = NO;
//                if (isSenderSync) {
//                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
//                    statusLog.status = SyncedMessageStatus;
//                    [statusLogDbService saveMessageStatusLog:statusLog];
//                } else {
//                    timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
//                    if (wasTimestampFound) {
//                        // Change received timestamp only if the message was read already
//                        [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
//                        if (wasTimestampFound) {
//                            newMessage.receivedAt = timestamp;
//                        }
//                        statusLog.status = ReceivedByAnotherDeviceMessageStatus;
//                        wasReceivedOnOtherDevice = YES;
//                        wereMessageTimesModified = YES;
//                    } else {
//                        statusLog.status = ReceivedMessageStatus;
//                    }
//                    
//                    // the status is receibed with receivedAt timestamp
//                    statusLog.messageId = newMessage.messageId;
//                    statusLog.timestamp = newMessage.receivedAt;
//                    [statusLogDbService saveMessageStatusLog:statusLog];
//                    
//                    if (createReadStatusLog) {
//                        timestamp = [strongSelf parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-opened" wasFound:&wasTimestampFound];
//                        if (wasTimestampFound) {
//                            newMessage.readAt = timestamp;
//                            wereMessageTimesModified = YES;
//                        }
//                        statusLog.timestamp = newMessage.readAt;
//                        statusLog.status = ReadMessageStatus;
//                        [statusLogDbService saveMessageStatusLog:statusLog];
//                    }
//                }
//                
//                if (wasReceivedOnOtherDevice) {
//                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
//                    statusLog.status = ReceivedMessageStatus;
//                    [statusLogDbService saveMessageStatusLog:statusLog];
//                }
//                
//                if (wereMessageTimesModified) {
//                    [chatMessageService saveMessage:newMessage inConversation:conversation];
//                }
//                
//                if (newMessage.messageId == 0)
//                {
//                    // TODO: Handle the error appropriately.
//                    //DDLogSupport(@"sendMessage error %d", newMsgId);
//                    DDLogError(@"Error inserting new message %ld", (long)newMsgId);
//                }
//            }
//            
//            // Optimization for a case when we are already chatting with the sender.
//            // The view will call our method saveMessageAsRead,
//            // in this method we will mark this message as read so we will push this field
//            // in the first push to qliqStor
//            justReceivedMessage = newMessage;
//            
//            [strongSelf notifyNewChatMessagesWithConversation:conversation];
//            
//            DDLogSupport(@"processExtendedChatMessage: senderSync=%d, normalMessage=%d", isSenderSync, [newMessage isNormalChatMessage]);
//            if (!isSenderSync && [newMessage isNormalChatMessage]) {
//                NSString *noSoundString = [sipMessage.extraHeaders objectForKey:@"X-nosound"];
//                BOOL noSound = noSoundString.length > 0 && [noSoundString compare:@"yes" options:NSCaseInsensitiveSearch] == NSOrderedSame;
//                [[UserNotifications getInstance] notifyIncomingChatMessage:newMessage withoutSound:noSound];
//            }
//            
//            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
//            {
//                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                [defaults setObject:[NSNumber numberWithInteger:newMessage.conversationId] forKey:@"lastActiveConversationId"];
//                [defaults synchronize];
//            }
//            
//            justReceivedMessage = nil;
//        }
//        else
//        {
//            BOOL isDuplicate = ([fromContact.qliqId isEqualToString:existingMsg.fromQliqId] &&
//                                [existingMsg.subject isEqualToString:sipMessage.conversationSubject] &&
//                                [existingMsg.text isEqualToString:sipMessage.messageText]);
//            if (isDuplicate) {
//                DDLogSupport(@"Ignoring incoming chat message duplicate, uuid: %@, from: %@", sipMessage.messageId, fromContact.qliqId);
//            } else {
//                DDLogError(@"Received a different message with an existing uuid: %@, new from: %@, exsting from: %@"
//#ifdef DEBUG
//                           " new subject: '%@', existing subject: '%@', new text: '%@', existing text: '%@'"
//#endif
//                           , sipMessage.messageId, fromContact.qliqId, existingMsg.fromQliqId
//#ifdef DEBUG
//                           , sipMessage.conversationSubject, existingMsg.subject, sipMessage.messageText, existingMsg.text
//#endif
//                           );
//            }
//        }
//        
//    });
}

- (void) processStructuredAttachments:(NSArray *)structuredAttachments
{
    for (NSDictionary *attachment in structuredAttachments) {
        if ([attachment[@"type"] isEqualToString:@"fhir/json"]) {
            [self processFhirAttachment:attachment[@"data"]];
        }
    }
}

- (void) processFhirAttachment:(NSDictionary *)attachment
{
    NSString *json = [attachment JSONString];
    [QxPlatfromIOS processFhirAttachment:json];
}

- (void)processInvitation:(NSDictionary *)data {
    
    //NSString *uuid = [data objectForKey:INVITATION_DATA_INVITATION_UUID];
    NSDictionary *userInfoDict = [data objectForKey:INVITATION_DATA_SENDER_INFO];
    QliqUser *user = [QliqUser userFromDict:userInfoDict];
    
    Invitation * invitation = [[Invitation alloc] init];
    
    invitation.uuid = [data objectForKey:INVITATION_DATA_INVITATION_UUID];
    invitation.invitedAt = [NSDate timeIntervalSinceReferenceDate];
    invitation.status = InvitationStatusNew;
    invitation.operation = InvitationOperationReceived;
    invitation.url = [data objectForKey:INVITATION_DATA_INVITATION_URL];
    
    [self getQliqUserForID:user.qliqId andEmail:user.email completition:^(QliqUser *user)
     {
         invitation.contact = (Contact*)user;
         invitation.contact.contactStatus = ContactStatusInvitationInProcess;
         
         if ([[data objectForKey:INVITATION_DATA_ACTION] isEqualToString:INVITATION_DATA_ACTION_INVITE]) {
             if ([[InvitationService sharedService] isInvitationExists:invitation]) {
                 
                 UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:nil message:[NSString stringWithFormat:NSLocalizedString(@"1169-Text{UserName}RemindInvitation", nil), [user nameDescription]] delegate:nil cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil) otherButtonTitles: nil];
                 
                 [alert showWithDissmissBlock:NULL];
             }
         
             [[InvitationService sharedService] saveInvitation:invitation];
         }
         else if ([[data objectForKey:INVITATION_DATA_ACTION] isEqualToString:INVITATION_DATA_ACTION_CANCEL]) {
             [[InvitationService sharedService] deleteInvitation:invitation];
         }
         
     }];
}

- (void)processMessageStatusNotification:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    int status = [userInfo[@"Status"] intValue];
    NSString *aCallId = userInfo[@"CallId"];
    id context = userInfo[@"context"];
    UIApplicationState state = [AppDelegate applicationState];
    DDLogSupport(@"Processing Message Status Notification for callid: %@, status: %d, app state: %ld", aCallId, status, (long)state);
    
    if ([self isChatMessageNotification:notification]) {
        if ([self.sentChatMessages count] > 0 || [self.sentAcks count] > 0) {
            ChatMessage *changedMessage = context;
            [self processMessageStatus:changedMessage status:status callId:aCallId qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
        }
    }
    else if ([self isOpenedStatusMessageNotification:notification]) {
        [self processMessageStatus:nil status:status callId:aCallId qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
    }
    if (context == nil) {
        if ([aCallId isEqualToString:resendingMessageStatusUuid]) {
            resendingMessageId = 0;
            resendingMessageStatusUuid = nil;
        }
    }
    
    // These two statuses are passed to the application only if pjproject contains our patch.
    // Normally pjproject resends the message with authorization header by itself.
    if (status == 401 || status == 407 || status == 503) {
        // If no authorization for the message (of any type) then trigger re-registration
        DDLogSupport(@"Trying to re-register in response for message status: %d", status);
        [[QliqSip sharedQliqSip] setRegistered:YES];
    }
    else if (status == 408) {
        // Before registration, try to shutdown the trasports. Just in case there
        // are dangling transports
        
        DDLogSupport(@"Message Sending Timedout. Restarting the transport and registering again");
        [[QliqSip sharedQliqSip] shutdownTransport];
        [[QliqSip sharedQliqSip] setRegistered:YES];
    }
}

- (void)processOpenedMessageStatusNotification:(NSNotification *)notification {
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        NSString *aCallId = [[notification userInfo] objectForKey:@"CallId"];
        NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
        NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
        NSNumber *aOpenedRecipientCount = [[notification userInfo] objectForKey:@"OpenedRecipientCount"];
        
        [weakSelf addToSerialQueue:weakSelf.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            DDLogSupport(@"aTotalRecipientCount = %@, OpenedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
            NSNumber *aOpenedAt = [[notification userInfo] objectForKey:@"OpenedAt"];
            ChatMessage *msg = [DBHelperConversation getMessageWithGuid:aCallId];
            if (msg) {
                NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
                if ([aQliqId isEqualToString:myQliqId]) {
                    if (msg.readAt == 0 && ![msg.fromQliqId isEqualToString:myQliqId]) {
                        msg.isOpenedSent = YES;
                        [[ChatMessageService sharedService] saveMessage:msg];
                        
                        [strongSelf saveMessageAsRead:msg.messageId at:[aOpenedAt longValue]];
                        
                        // Post a notification for recents view (ConversationListViewController)
                        // to clear the conversation unread badge
                        Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
                        NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation,@"Conversation", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:ConversationDidReadMessagesNotification object:nil userInfo:info];
                    }
                } else if ([msg.fromQliqId isEqualToString:myQliqId]) {
                    // Read by recipient
                    if (msg.openedRecipientCount == [aOpenedRecipientCount intValue]) {
                        // repeated message, ignore
                        return;
                    }
                    msg.openedRecipientCount = [aOpenedRecipientCount intValue];
                    msg.totalRecipientCount = [aTotalRecipientCount intValue];
                    
                    if (msg.openedRecipientCount == msg.totalRecipientCount && msg.totalRecipientCount > 0 &&
                        msg.deliveryStatus != MessageStatusRead) {
                        msg.deliveryStatus = MessageStatusRead;
                        msg.statusText = nil;
                        long valueOpenedAt = [aOpenedAt longValue];
                        valueOpenedAt += 1;
                        aOpenedAt = [NSNumber numberWithLong:valueOpenedAt];
                        msg.readAt = [aOpenedAt longValue];
                    }
                    [[ChatMessageService sharedService] saveMessage:msg];
                    [strongSelf notifyChatMessageStatus:msg];
                    
                    // Save the status message
                    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                    statusLog.messageId = msg.messageId;
                    statusLog.timestamp = [aOpenedAt longValue];
                    statusLog.status = ReadMessageStatus;
                    statusLog.qliqId = aQliqId;
                    [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
                }
            } else {
                DDLogError(@"Cannot process 'opened' status because cannot find message with uuid: %@", aCallId);
            }
        }];
        
//        dispatch_async(self.qliqConnectDispatchQueue, ^{
//            __strong typeof(self) strongSelf = weakSelf;
//            DDLogSupport(@"aTotalRecipientCount = %@, OpenedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
//            NSNumber *aOpenedAt = [[notification userInfo] objectForKey:@"OpenedAt"];
//            ChatMessage *msg = [DBHelperConversation getMessageWithGuid:aCallId];
//            if (msg) {
//                NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
//                if ([aQliqId isEqualToString:myQliqId]) {
//                    if (msg.readAt == 0 && ![msg.fromQliqId isEqualToString:myQliqId]) {
//                        msg.isOpenedSent = YES;
//                        [[ChatMessageService sharedService] saveMessage:msg];
//                        
//                        [strongSelf saveMessageAsRead:msg.messageId at:[aOpenedAt longValue]];
//                        
//                        // Post a notification for recents view (ConversationListViewController)
//                        // to clear the conversation unread badge
//                        Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
//                        NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation,@"Conversation", nil];
//                        [[NSNotificationCenter defaultCenter] postNotificationName:ConversationDidReadMessagesNotification object:nil userInfo:info];
//                    }
//                } else if ([msg.fromQliqId isEqualToString:myQliqId]) {
//                    // Read by recipient
//                    if (msg.openedRecipientCount == [aOpenedRecipientCount intValue]) {
//                        // repeated message, ignore
//                        return;
//                    }
//                    msg.openedRecipientCount = [aOpenedRecipientCount intValue];
//                    msg.totalRecipientCount = [aTotalRecipientCount intValue];
//                    
//                    if (msg.openedRecipientCount == msg.totalRecipientCount && msg.totalRecipientCount > 0 &&
//                        msg.deliveryStatus != MessageStatusRead) {
//                        msg.deliveryStatus = MessageStatusRead;
//                        msg.statusText = nil;
//                        long valueOpenedAt = [aOpenedAt longValue];
//                        valueOpenedAt += 1;
//                        aOpenedAt = [NSNumber numberWithLong:valueOpenedAt];
//                        msg.readAt = [aOpenedAt longValue];
//                    }
//                    [[ChatMessageService sharedService] saveMessage:msg];
//                    [strongSelf notifyChatMessageStatus:msg];
//                    
//                    // Save the status message
//                    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                    statusLog.messageId = msg.messageId;
//                    statusLog.timestamp = [aOpenedAt longValue];
//                    statusLog.status = ReadMessageStatus;
//                    statusLog.qliqId = aQliqId;
//                    [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
//                }
//            } else {
//                DDLogError(@"Cannot process 'opened' status because cannot find message with uuid: %@", aCallId);
//            }
//        });
    });
}

- (void)processDeletedMessageStatusNotification:(NSNotification *)notification {
    
    NSString *callId = [[notification userInfo] objectForKey:@"CallId"];
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        DDLogSupport(@"Deleted status notification for message %@", callId);
        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
        if (msg) {
            if (msg.deletedStatus != DeletedAndSentStatus) {
                msg.deletedStatus = DeletedAndSentStatus;
                [strongSelf deleteAttachmentsOfMessage:msg];
                [[ChatMessageService sharedService] saveMessage:msg];
                
                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
                ChatMessage *latestMsg = [[ChatMessageService sharedService] getLatestMessageInConversation:msg.conversationId];
                if (!latestMsg) {
                    conversation.deleted = YES;
                    [[ConversationDBService sharedService] saveConversation:conversation];
                }
                
                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation, @"Conversation", [NSNumber numberWithInteger:msg.messageId], @"MessageId", [NSNumber numberWithBool:YES], @"RemoteDelete", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:QliqConnectDidDeleteMessagesInConversationNotification object:nil userInfo:info];
            }
        } else {
            DDLogError(@"Cannot find message with uuid: %@", callId);
        }
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        DDLogSupport(@"Deleted status notification for message %@", callId);
//        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
//        if (msg) {
//            if (msg.deletedStatus != DeletedAndSentStatus) {
//                msg.deletedStatus = DeletedAndSentStatus;
//                [strongSelf deleteAttachmentsOfMessage:msg];
//                [[ChatMessageService sharedService] saveMessage:msg];
//                
//                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
//                ChatMessage *latestMsg = [[ChatMessageService sharedService] getLatestMessageInConversation:msg.conversationId];
//                if (!latestMsg) {
//                    conversation.deleted = YES;
//                    [[ConversationDBService sharedService] saveConversation:conversation];
//                }
//                
//                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation, @"Conversation", [NSNumber numberWithInteger:msg.messageId], @"MessageId", [NSNumber numberWithBool:YES], @"RemoteDelete", nil];
//                [[NSNotificationCenter defaultCenter] postNotificationName:QliqConnectDidDeleteMessagesInConversationNotification object:nil userInfo:info];
//            }
//        } else {
//            DDLogError(@"Cannot find message with uuid: %@", callId);
//        }
//    });
}

- (void)processRecipientStatusStatusNotification:(NSNotification *)notification {
    
    NSString *callId = notification.userInfo[@"CallId"];
    NSString *qliqId = notification.userInfo[@"QliqId"];
    NSString *statusText = notification.userInfo[@"StatusText"];
    int statusCode = [notification.userInfo[@"StatusCode"] intValue];
    __block long at = [notification.userInfo[@"At"] longValue];
    int recipientCount = [notification.userInfo[@"RecipientCount"] intValue];
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        
        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
        if (msg) {
            DDLogSupport(@"Recipient status notification for message %@ qliq id: %@, status: %d", callId, qliqId, statusCode);
            NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
            if ([qliqId isEqualToString:myQliqId] == NO) {
                if (at == 0) {
                    at = (long)[[NSDate date] timeIntervalSince1970];
                }
                
                if (recipientCount == 1) {
                    msg.deliveryStatus = statusCode;
                    msg.statusText = statusText;
                    [[ChatMessageService sharedService] saveMessage:msg];
                    [strongSelf notifyChatMessageStatus:msg];
                }
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = msg.messageId;
                statusLog.timestamp = at;
                statusLog.status = statusCode;
                statusLog.statusText = statusText;
                statusLog.qliqId = qliqId;
                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
            }
        } else {
            DDLogError(@"Cannot find message for recipient status with call id: %@", callId);
        }
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
//        if (msg) {
//            DDLogSupport(@"Recipient status notification for message %@ qliq id: %@, status: %d", callId, qliqId, statusCode);
//            NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
//            if ([qliqId isEqualToString:myQliqId] == NO) {
//                if (at == 0) {
//                    at = (long)[[NSDate date] timeIntervalSince1970];
//                }
//                
//                if (recipientCount == 1) {
//                    msg.deliveryStatus = statusCode;
//                    msg.statusText = statusText;
//                    [[ChatMessageService sharedService] saveMessage:msg];
//                    [strongSelf notifyChatMessageStatus:msg];
//                }
//                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                statusLog.messageId = msg.messageId;
//                statusLog.timestamp = at;
//                statusLog.status = statusCode;
//                statusLog.statusText = statusText;
//                statusLog.qliqId = qliqId;
//                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
//            }
//        } else {
//            DDLogError(@"Cannot find message for recipient status with call id: %@", callId);
//        }
//    });
}

- (void)processRecalledMessageStatusNotification:(NSNotification *)notification {
    
    NSString *callId = [[notification userInfo] objectForKey:@"CallId"];
    NSNumber *aRecalledAt = [[notification userInfo] objectForKey:@"RecalledAt"];
    __block NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        
        DDLogSupport(@"Recalled status notification for message %@", callId);
        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
        if (msg) {
            if (msg.recalledStatus != RecalledAndSentStatus) {
                NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
                if ([aQliqId isEqualToString:myQliqId]) {
                    aQliqId = nil;
                } else {
                    [strongSelf deleteAttachmentsOfMessage:msg];
                    msg.text = QliqLocalizedString(@"2408-TextMessageRecalled");
                    msg.ackRequired = NO;
                    msg.priority = ChatMessagePriorityNormal;
                    // TODO: Not sure if it is safe to call this when app in bg
                    //                    [msg calculateHeight];
                }
                
                msg.recalledStatus = RecalledAndSentStatus;
                [[ChatMessageService sharedService] saveMessage:msg];
                
                // Save the status message
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = msg.messageId;
                statusLog.timestamp = [aRecalledAt longValue];
                statusLog.status = RecalledMessageStatus;
                statusLog.qliqId = aQliqId;
                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
                
                // ConversationList depends on this notification
                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:msg.messageId], @"MessageId", conversation, @"Conversation", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ChatMessageRecalledInConversationNotification object:nil userInfo:info];
                
                // ChatView uses regular notification to refresh
                [strongSelf notifyChatMessageStatus:msg];
            }
        } else {
            DDLogError(@"Cannot find message with uuid: %@", callId);
        }
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        DDLogSupport(@"Recalled status notification for message %@", callId);
//        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:callId];
//        if (msg) {
//            if (msg.recalledStatus != RecalledAndSentStatus) {
//                NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
//                if ([aQliqId isEqualToString:myQliqId]) {
//                    aQliqId = nil;
//                } else {
//                    [strongSelf deleteAttachmentsOfMessage:msg];
//                    msg.text = @"Message recalled by sender";
//                    msg.ackRequired = NO;
//                    msg.priority = ChatMessagePriorityNormal;
//                    // TODO: Not sure if it is safe to call this when app in bg
//                    //                    [msg calculateHeight];
//                }
//                
//                msg.recalledStatus = RecalledAndSentStatus;
//                [[ChatMessageService sharedService] saveMessage:msg];
//                
//                // Save the status message
//                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                statusLog.messageId = msg.messageId;
//                statusLog.timestamp = [aRecalledAt longValue];
//                statusLog.status = RecalledMessageStatus;
//                statusLog.qliqId = aQliqId;
//                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
//                
//                // ConversationList depends on this notification
//                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
//                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:msg.messageId], @"MessageId", conversation, @"Conversation", nil];
//                [[NSNotificationCenter defaultCenter] postNotificationName:ChatMessageRecalledInConversationNotification object:nil userInfo:info];
//                
//                // ChatView uses regular notification to refresh
//                [strongSelf notifyChatMessageStatus:msg];
//            }
//        } else {
//            DDLogError(@"Cannot find message with uuid: %@", callId);
//        }
//    });
}

- (void)processAckedMessageStatusNotification:(NSNotification *)notification {
    
    NSString *aCallIdArg = [[notification userInfo] objectForKey:@"CallId"];
    NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
    NSNumber *aOpenedRecipientCount = [[notification userInfo] objectForKey:@"AckedRecipientCount"];
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        
        DDLogSupport(@"aTotalRecipientCount = %@, AckedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
        NSString *aCallId = aCallIdArg;
        NSNumber *aOpenedAt = [[notification userInfo] objectForKey:@"AckedAt"];
        
        NSRange range = [aCallId rangeOfString:@"ac-"];
        if (range.location == 0) {
            aCallId = [aCallId substringFromIndex:3];
        }
        
        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:aCallId];
        if (msg && msg.ackRequired) {
            NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
            if ([aQliqId isEqualToString:myQliqId]) {
                msg.ackSentAt = [aOpenedAt longValue];
                msg.ackSentToServerAt = [aOpenedAt longValue];
                [[ChatMessageService sharedService] saveMessage:msg];
                
                // Save the status message
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = msg.messageId;
                statusLog.timestamp = [aOpenedAt longValue];
                //statusLog.status = AckSyncedStatus;
                statusLog.status = AckPendingMessageStatus;
                [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                
                [strongSelf notifyChatAck:msg withSound:NO];
                
            } else if (![msg.toQliqId isEqualToString:myQliqId]) {
                // Acked by recipient
                if (msg.ackedRecipientCount == [aOpenedRecipientCount intValue]) {
                    // repeated message, ignore
                    return;
                }
                msg.ackedRecipientCount = [aOpenedRecipientCount intValue];
                msg.totalRecipientCount = [aTotalRecipientCount intValue];
                
                // Save the status message
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = msg.messageId;
                statusLog.timestamp = [aOpenedAt longValue];
                statusLog.status = AckReceivedMessageStatus;
                statusLog.qliqId = aQliqId;
                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
                
                if (msg.ackedRecipientCount == msg.totalRecipientCount && msg.totalRecipientCount > 0) {
                    msg.ackReceivedAt = [aOpenedAt longValue];
                    
                    if (msg.totalRecipientCount > 1) {
                        // Insert 'Acked by all' marker
                        statusLog.qliqId = nil;
                        [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
                    }
                }
                [[ChatMessageService sharedService] saveMessage:msg];
                
                [strongSelf notifyChatAck:msg withSound:YES];
            }
        } else if (!msg) {
            DDLogError(@"Cannot process 'acked' status because cannot find message with uuid: %@", aCallId);
        }
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        DDLogSupport(@"aTotalRecipientCount = %@, AckedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
//        NSString *aCallId = aCallIdArg;
//        NSNumber *aOpenedAt = [[notification userInfo] objectForKey:@"AckedAt"];
//        
//        NSRange range = [aCallId rangeOfString:@"ac-"];
//        if (range.location == 0) {
//            aCallId = [aCallId substringFromIndex:3];
//        }
//        
//        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:aCallId];
//        if (msg && msg.ackRequired) {
//            NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
//            if ([aQliqId isEqualToString:myQliqId]) {
//                msg.ackSentAt = [aOpenedAt longValue];
//                msg.ackSentToServerAt = [aOpenedAt longValue];
//                [[ChatMessageService sharedService] saveMessage:msg];
//                
//                // Save the status message
//                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                statusLog.messageId = msg.messageId;
//                statusLog.timestamp = [aOpenedAt longValue];
//                //statusLog.status = AckSyncedStatus;
//                statusLog.status = AckPendingMessageStatus;
//                [statusLogDbService saveMessageStatusLog:statusLog];
//                
//                [strongSelf notifyChatAck:msg withSound:NO];
//                
//            } else if (![msg.toQliqId isEqualToString:myQliqId]) {
//                // Acked by recipient
//                if (msg.ackedRecipientCount == [aOpenedRecipientCount intValue]) {
//                    // repeated message, ignore
//                    return;
//                }
//                msg.ackedRecipientCount = [aOpenedRecipientCount intValue];
//                msg.totalRecipientCount = [aTotalRecipientCount intValue];
//                
//                // Save the status message
//                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
//                statusLog.messageId = msg.messageId;
//                statusLog.timestamp = [aOpenedAt longValue];
//                statusLog.status = AckReceivedMessageStatus;
//                statusLog.qliqId = aQliqId;
//                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
//                
//                if (msg.ackedRecipientCount == msg.totalRecipientCount && msg.totalRecipientCount > 0) {
//                    msg.ackReceivedAt = [aOpenedAt longValue];
//                    
//                    if (msg.totalRecipientCount > 1) {
//                        // Insert 'Acked by all' marker
//                        statusLog.qliqId = nil;
//                        [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
//                    }
//                }
//                [[ChatMessageService sharedService] saveMessage:msg];
//                
//                [strongSelf notifyChatAck:msg withSound:YES];
//            }
//        } else if (!msg) {
//            DDLogError(@"Cannot process 'acked' status because cannot find message with uuid: %@", aCallId);
//        }
//    });
}

- (void)processPendingMessageStatusNotification:(NSNotification *)notification {
    
    int status = [[[notification userInfo ] objectForKey: @"Status"] intValue];
    NSString *aCallId = [[notification userInfo] objectForKey:@"CallId"];
    NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
    NSNumber *aDeliveredRecipientCount = [[notification userInfo] objectForKey:@"DeliveredRecipientCount"];
    NSNumber *aDeliveredAt = [[notification userInfo] objectForKey:@"DeliveredAt"];
    
    __block __weak typeof(self) weakSelf = self;
    
    [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        
        ChatMessage *msg = nil;
        
        BOOL isAck = NO;
        NSRange range = [aCallId rangeOfString:@"ac-"];
        if (range.location == 0) {
            NSString *callId = [aCallId substringFromIndex:3];
            msg = [DBHelperConversation getMessageWithGuid:callId];
            if (msg) {
                isAck = YES;
            }
        }
        
        if (isAck == NO) {
            msg = [DBHelperConversation getMessageWithGuid:aCallId];
        }
        
        if (msg) {
            if (isAck == NO && msg.deliveryStatus == 200) {
                DDLogError(@"Ignoring NOTIFY with status: %d for already delivered message uuid: %@", status, msg.metadata.uuid);
            } else {
                
                NSMutableSet *sentSet = (isAck ? weakSelf.sentAcks : weakSelf.sentChatMessages);
                BOOL isBeginSent = NO;
                for (ChatMessage *sentMsg in sentSet) {
                    if (sentMsg.messageId == msg.messageId) {
                        isBeginSent = YES;
                        break;
                    }
                }
                
                if (!isBeginSent) {
                    [sentSet addObject:msg];
                }
                
                [strongSelf processMessageStatus:msg status:status callId:aCallId qliqId:aQliqId deliveredRecipientCount:[aDeliveredRecipientCount intValue] totalRecipientCount:[aTotalRecipientCount intValue] deliveredAt:[aDeliveredAt longValue]];
            }
        } else {
            DDLogError(@"Cannot find message for NOTIFY with status: %d, call-id: %@", status, aCallId);
        }
    }];
    
//    dispatch_async(self.qliqConnectDispatchQueue, ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        ChatMessage *msg = nil;
//        
//        BOOL isAck = NO;
//        NSRange range = [aCallId rangeOfString:@"ac-"];
//        if (range.location == 0) {
//            NSString *callId = [aCallId substringFromIndex:3];
//            msg = [DBHelperConversation getMessageWithGuid:callId];
//            if (msg) {
//                isAck = YES;
//            }
//        }
//        
//        if (isAck == NO) {
//            msg = [DBHelperConversation getMessageWithGuid:aCallId];
//        }
//        
//        if (msg) {
//            if (isAck == NO && msg.deliveryStatus == 200) {
//                DDLogError(@"Ignoring NOTIFY with status: %d for already delivered message uuid: %@", status, msg.metadata.uuid);
//            } else {
//                NSMutableSet *sentSet = (isAck ? sentAcks : sentChatMessages);
//                BOOL isBeginSent = NO;
//                for (ChatMessage *sentMsg in sentSet) {
//                    if (sentMsg.messageId == msg.messageId) {
//                        isBeginSent = YES;
//                        break;
//                    }
//                }
//                
//                if (!isBeginSent) {
//                    [sentSet addObject:msg];
//                }
//                
//                [strongSelf processMessageStatus:msg status:status callId:aCallId qliqId:aQliqId deliveredRecipientCount:[aDeliveredRecipientCount intValue] totalRecipientCount:[aTotalRecipientCount intValue] deliveredAt:[aDeliveredAt longValue]];
//            }
//        } else {
//            DDLogError(@"Cannot find message for NOTIFY with status: %d, call-id: %@", status, aCallId);
//        }
//    });
}

- (void)processMessageStatus:(ChatMessage *)msgArg
                      status:(int)statusArg
                      callId:(NSString *)aCallId
                      qliqId:(NSString *)aQliqId
     deliveredRecipientCount:(int)aDeliveredRecipientCount
         totalRecipientCount:(int)aTotalRecipientCount
                 deliveredAt:(long)aDeliveredAt {

    __block __weak typeof(self) weakSelf = self;
    
    void (^thisMethodBody)() = ^{
        BOOL wasDeliveredNow = NO;
        BOOL isValidMessageObject = NO; 
        // Copies for the block
        ChatMessage *msg = msgArg;
        int status = statusArg;
        
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        if (status == 200 && aDeliveredAt != 0) {
            timeStamp = aDeliveredAt;
        }
        
        if ([weakSelf.sentChatMessages containsObject:msg])
        {
            isValidMessageObject = YES;
            
            if (resendingMessageId == msg.messageId) {
                resendingMessageId = 0;
                resendingMessageStatusUuid = nil;
            }
            
            if (msg.selfDeliveryStatus / 100 != 2) {
                msg.selfDeliveryStatus = status;
                [[ChatMessageService sharedService] saveMessage:msg];
                [weakSelf.sentChatMessages removeObject:msg];
                if (status / 100 == 2) {
                    [self sipSendMessage:msg];
                    return;
                }
            }
            
            if (status / 100 == 2)
            {
                msg.receivedAt = timeStamp;
                wasDeliveredNow = YES;
                
                if (status == 202)
                {
                    // Save the call id
                    if ([aCallId length] > 0)
                        msg.callId = aCallId;
                }
                msg.totalRecipientCount = aTotalRecipientCount;
                msg.deliveredRecipientCount = aDeliveredRecipientCount;
            }
            else if (status != MessageStatusSipNotStarted) {
                msg.failedAttempts = msg.failedAttempts + 1;
            }
            
            // Save the status message
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = msg.messageId;
            statusLog.timestamp = timeStamp;
            statusLog.status = status;
            statusLog.qliqId = aQliqId;
            [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
            
            if (!wasDeliveredNow && msg.failedAttempts > maximumRetryCount) {
                status = MessageStatusTooManyRetries;
                statusLog.status = status;
                [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
            }
            
            if (status == 200) {
                // Delete
                if (msg.totalRecipientCount > 1) {
                    // Change status to Delivered only if delivered to all recipients
                    if (aDeliveredRecipientCount == aTotalRecipientCount) {
                        msg.deliveryStatus = status;
                        msg.statusText = nil;
                        
                        if ([aQliqId length] > 0) {
                            // Insert 'Delivered to all' marker
                            statusLog = [[MessageStatusLog alloc] init];
                            statusLog.messageId = msg.messageId;
                            statusLog.timestamp = timeStamp;
                            statusLog.status = status;
                            
                            statusLog.qliqId = nil;
                            [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                        }
                    } else if (msg.deliveryStatus == 299) {
                        // For synced MP messages change status to 202
                        msg.deliveryStatus = 202;
                        msg.statusText = nil;
                    }
                } else {
                    // If a SP message then always changes status to 200
                    msg.deliveryStatus = status;
                    msg.statusText = nil;
                }
            } else {
                msg.deliveryStatus = status;
                msg.statusText = nil;
            }
            
#ifdef SENDER_PUSHES_TO_QLIQSTOR
#ifdef PUSH_ONLY_ONCE_AND_WHEN_DELIVERED
            if (([msg.metadata.rev length] == 0) || wasDeliveredNow)
#else
                // Push always, this will increase load on the server but Krishna wants it.
                if (msg.selfDeliveryStatus != MessageStatusSynced) // don't push synced messages
#endif
                {
#ifndef QLIQSTOR_NOTIFY_IMPLEMENTATION
                    // Message needs push if its a new one or if delivery status changes
                    msg.metadata.isRevisionDirty = YES;
                    msg.metadata.author = [Helper getMyQliqId];
                    [PushMessageToQliqStorHelper setMessageUnpushedToAllQliqStors:msg];
#endif
                }
#endif
            [[ChatMessageService sharedService] saveMessage:msg];
            
            [self notifyChatMessageStatus:msg];
            
#ifdef SENDER_PUSHES_TO_QLIQSTOR
            // Tkt #708 the sender doesn't push the message anymore
            //        if (msg.metadata.isRevisionDirty)
            //            [self pushMessageToDataServer:msg];
#endif
            [weakSelf.sentChatMessages removeObject:msg];
            
#ifndef QLIQSTOR_NOTIFY_IMPLEMENTATION
            if (status != 202 && msg.selfDeliveryStatus != MessageStatusSynced) {
                [qliqStorPusher startPushing];
            }
#else
            [qliqStorPusher startPushing];
#endif
            
            if (status == SIP_UNDECIPHERABLE_STATUS) {
                [self sendMessage:msg];
            }
            
        }
        else if ([weakSelf.sentAcks containsObject:msg])
        {
            isValidMessageObject = YES;
            NSInteger statusLogStatus = status;
            
            if (resendingMessageId == msg.messageId) {
                resendingMessageId = 0;
                resendingMessageStatusUuid = nil;
            }
            
            // Determine if the ack was sent from this device or this is a NOTIFY synced from other device
            BOOL wasAckSentOnThisDevice = NO;
            if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
                NSArray *statusLogs = [[MessageStatusLogDBService sharedService] getMessageStatusLogForMessage:msg];
                
                for (MessageStatusLog *entry in statusLogs) {
                    if (entry.status == SendingAckMessageStatus) {
                        wasAckSentOnThisDevice = YES;
                        break;
                    }
                }
            }
            
            if (wasAckSentOnThisDevice && msg.selfDeliveryStatus / 100 != 2) {
                msg.selfDeliveryStatus = status;
                [[ChatMessageService sharedService] saveMessage:msg];
                [weakSelf.sentAcks removeObject:msg];
                if (status / 100 == 2) {
                    [self sendAck:msg];
                }
                return;
            }
            
            if (status / 100 == 2)
            {
                if (status == 202 || status == 220) {
                    msg.ackSentToServerAt = [[NSDate date] timeIntervalSince1970];
                    statusLogStatus = AckPendingMessageStatus;
                } else if (status == 200) {
                    // For not our messages we store ack delivered at time in this field.
                    msg.ackReceivedAt = timeStamp;
                    if (msg.ackSentToServerAt == 0 || msg.ackSentToServerAt == -1) {
                        msg.ackSentToServerAt = msg.ackReceivedAt;
                    }
                    statusLogStatus = AckDeliveredMessageStatus;
                }
                wasDeliveredNow = YES;
            }
            else {
                msg.ackSentToServerAt = -1;
                if (status != MessageStatusSipNotStarted) {
                    msg.failedAttempts = msg.failedAttempts + 1;
                }
            }
            
            // Save the status message
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = msg.messageId;
            statusLog.timestamp = timeStamp;
            statusLog.status = statusLogStatus;
            [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
            
            if (!wasDeliveredNow && msg.failedAttempts > maximumRetryCount) {
                msg.ackSentToServerAt = -1;
                statusLog.status = MessageStatusTooManyRetries;
                [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
            }
            [[ChatMessageService sharedService] saveMessage:msg];
            
            [self notifyChatMessageStatus:msg];
            
            [weakSelf.sentAcks removeObject:msg];
            
            if (status == SIP_UNDECIPHERABLE_STATUS) {
                [self sendAck:msg];
            }
        }
        else if (status == 220 && !msg) {
            msg = [DBHelperConversation getMessageWithGuid:aCallId];
            if (msg) {
                if (resendingMessageId == msg.messageId) {
                    resendingMessageId = 0;
                    resendingMessageStatusUuid = nil;
                }
                if (msg.deletedStatus == DeletedAndNotSentStatus) {
                    msg.deletedStatus = DeletedAndSentStatus;
                } else if (msg.recalledStatus == RecalledAndNotSentStatus) {
                    msg.recalledStatus = RecalledAndSentStatus;
                } else if (msg.isRead) {
                    msg.isOpenedSent = YES;
                }
                
                if (![[ChatMessageService sharedService] saveMessage:msg]) {
                    DDLogError(@"Cannot save message after sending status, uuid: %@", aCallId);
                }
            } else {
                DDLogError(@"Cannot find message for status confirmation (220) call-id: %@", aCallId);
            }
            wasDeliveredNow = true;
        }
        else
        {   // Tkt #693 This isn't confirmed but maybe sometimes garbage is interpreted as ChatMessage object,
            // this is why we don't touch the object if it doesn't belong to the containers.
            // DDLogError(@"neither sentChatMessages nor sentAcks contains object, status: %d, text: %@", status, msg.text);
        }
        
        if (wasDeliveredNow)
        {
            DDLogVerbose(@"message delivered, will resend other");
            [self resendOneUndeliveredMessage];
        }
        else if (isValidMessageObject)
        {
            NSNumber *statusNumber = [NSNumber numberWithInt:status];
            if ([permanentFailureStatusSet containsObject:statusNumber]) {
                [self processPermanentErrorMessageStatus:status toQliqId:msg.toQliqId];
                // Other errors can happen only online
                if (status != MessageStatusTooManyRetries) {
                    [self resendOneUndeliveredMessage];
                }
            }
        }
    };
    
    // This method may be called already from our queue (in processPendingMessageStatusNotification) // AD

//    if (dispatch_get_current_queue() == self.qliqConnectDispatchQueue) {
        
    if ([NSOperationQueue currentQueue] == self.qliqConnectOperationQueue) {
        thisMethodBody();
    } else {
        
        [self addToSerialQueue:self.qliqConnectOperationQueue asyncFIFOoperationWithBlock:thisMethodBody];
        
       // dispatch_async(self.qliqConnectDispatchQueue, thisMethodBody);
    }
}

- (void)processPermanentErrorMessageStatus:(NSInteger)status toQliqId:(NSString *)toQliqId {
    
    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
    statusLog.status = status;
    
    NSArray *messages = [DBHelperConversation getUndeliveredMessagesWithStatusNotIn:permanentFailureStatusSet toQliqId:toQliqId limit:10000 offset:0];
    
    for (ChatMessage *msg in messages) {
        // Save the status message
        statusLog.messageId = msg.messageId;
        [self.statusLogDbService saveMessageStatusLog:statusLog];
        
        msg.deliveryStatus = status;
        msg.statusText = nil;
        // Message needs push if its a new one or if delivery status changes
        msg.metadata.isRevisionDirty = YES;
        msg.metadata.author = [Helper getMyQliqId];
        [[ChatMessageService sharedService] saveMessage:msg];
#ifndef QLIQSTOR_NOTIFY_IMPLEMENTATION
        [PushMessageToQliqStorHelper setMessageUnpushedToAllQliqStors:msg];
#endif
        
        for (ChatMessage *sentMsg in self.sentChatMessages) {
            if (sentMsg.messageId == msg.messageId) {
                [self.sentChatMessages removeObject:sentMsg];
                break;
            }
        }
        
        [self notifyChatMessageStatus:msg];
    }
    
    // Process undelivered acks
    messages = [DBHelperConversation getUndeliveredAcksToQliqId:toQliqId limit:10000 offset:0];
    
    for (ChatMessage *msg in messages) {
        // Save the status message
        statusLog.messageId = msg.messageId;
        [self.statusLogDbService saveMessageStatusLog:statusLog];
        
        msg.ackSentToServerAt = -1;
        [[ChatMessageService sharedService] saveMessage:msg];
        
        for (ChatMessage *sentMsg in self.sentAcks) {
            if (sentMsg.messageId == msg.messageId) {
                [self.sentAcks removeObject:sentMsg];
                break;
            }
        }
        
        [self notifyChatMessageStatus:msg];
    }
}

- (void)processLogoutResponseToPush:(NSString *)reason completion:(VoidBlock)completion {
    DDLogSupport(@"processLogoutResponseToPush: Logging out");
    
    /*Clear login credentials and logout*/
    [[KeychainService sharedService] clearPin];
    [[KeychainService sharedService] clearPassword];
    // Old keys are invalid
    [[Crypto instance] deleteKeysForUser: [UserSessionService currentUserSession].sipAccountSettings.username];
    // Clear last login date, so we don't do local login next time
    [UserSessionService clearLastLoginDate];
    
    [[Login sharedService] startLogoutWithCompletition:^{
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(reason)
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (completion)
                                         completion();
                                 }];
    }];
}

+ (void) processInvitationResponse:(NSDictionary *)invitationResponse
{
    NSString *connectionState = invitationResponse[INVITATION_SENDER_INFO_CONNECTION_STATE];
    
    if (connectionState.length > 0 && NSOrderedSame == [connectionState compare:@"accepted" options:NSCaseInsensitiveSearch]) {
        //accepted, the client has to do is get_contact_info on the qliq_id and mark the invitation as accepted
        
        [[GetContactInfoService sharedService] getContactInfo:invitationResponse[INVITATION_SENDER_INFO_QLIQ_ID] completitionBlock:^(QliqUser *contact, NSError *error) {
            
        }];
        
        Invitation *invitation = [[InvitationService sharedService] getInvitationWithUuid:invitationResponse[INVITATION_DATA_INVITATION_GUID]];
        if (invitation) {
            
            invitation.status = InvitationStatusAccepted;
            [[InvitationService sharedService] saveInvitation:invitation];
            
            //Retrieving QliqUser related to invitation, and updating his status
            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:invitation.contact.qliqId];
            user.status = @"active";
            user.contactStatus = ContactStatusNew;
            user.contactType = ContactTypeQliqUser;
            [[QliqUserDBService sharedService] saveUser:user];
            
            dispatch_async_main(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:InvitationServiceInvitationsChangedNotification object:nil userInfo:nil];
            });
        }
    } else if (connectionState.length > 0 && NSOrderedSame == [connectionState compare:@"declined" options:NSCaseInsensitiveSearch]) {
        //declined, user should mark contact as "deleted" and mark the invitation as declined.
        
        QliqUser *contact = [[QliqUserDBService sharedService] getUserWithId:invitationResponse[INVITATION_SENDER_INFO_QLIQ_ID]];
        if (contact) {
            
            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:contact.qliqId];
            [[QliqUserDBService sharedService] saveUser:user];
            
            [[QliqUserDBService sharedService] setUserDeleted:contact];
        }
        
        Invitation *invitation = [[InvitationService sharedService] getInvitationWithUuid:invitationResponse[INVITATION_DATA_INVITATION_GUID]];
        if (invitation) {
            
            invitation.status = InvitationStatusDeclined;
            [[InvitationService sharedService] saveInvitation:invitation];
            
            dispatch_async_main(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:InvitationServiceInvitationsChangedNotification object:nil userInfo:nil];
            });
        }
    }
}

+ (void) processInvitationRequest:(NSDictionary *)invitationRequest completitionBlock:(void(^)(QliqUser *contact, NSError * error))completeBlock {
    
    [[GetContactInfoService sharedService] getContactInfo:invitationRequest[@"qliq_id"] completitionBlock:^(QliqUser *contact, NSError *error) {
        
        if (nil == error) {
            
            contact.contactStatus = ContactStatusInvitationInProcess;
            
            Invitation *invitation = [[Invitation alloc] init];
            invitation.uuid = invitationRequest[@"invitation_guid"];
            invitation.operation = InvitationOperationReceived;
            invitation.status = InvitationStatusNew;
            invitation.url = invitationRequest[INVITATION_DATA_INVITATION_URL];
            invitation.invitedAt = [invitationRequest[INVITATION_DATA_INVITED_AT] doubleValue];
            invitation.contact = (Contact*)contact;
            
            [[InvitationService sharedService] saveInvitation:invitation];
        }
        if (completeBlock) {
            completeBlock(contact, error);
        }
    }];
}

- (void) processPendingRemoteNotifications
{
    if ([s_pendingRemotePushNotifications count] == 0) {
        return;
    }
    
    DDLogSupport(@"Processing %d pending (stored) remote notifications", (int)[s_pendingRemotePushNotifications count]);
    for (NSDictionary *aps in s_pendingRemotePushNotifications) {
        BOOL isVoip = [aps[@"is_voip"] boolValue];
        [QliqConnectModule processRemoteNotificationWithQliqMessage:aps isVoip:isVoip];
    }
}

+ (BOOL) isValidRemotePushNotification:(NSDictionary *)aps
{
    DDLogSupport(@"Validating remote notification: %@", aps);
    
    NSString *ruser = [aps valueForKey:@"ruser"];
    if (ruser.length == 0) {
        DDLogError(@"Remote notification does not have 'ruser' key. Ignoring.");
        return NO;
    }
    
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    if (![myQliqId isEqualToString:ruser]) {
        DDLogError(@"The ruser %@ from Remote Notification does not match current user: %@. Ignoring.", ruser, myQliqId);
        return NO;
    }
    
    NSString *toQliqId = aps[@"touser"];
    if (toQliqId.length == 0) {
        DDLogError(@"Remote notification does not have 'touser' key. Ignoring.");
        return NO;
    }
    
    NSString *fromQliqId = aps[@"fuser"];
    if (fromQliqId.length == 0) {
        DDLogError(@"Remote notification does not have 'fuser' key. Ignoring.");
        return NO;
    }
    
    NSString *callId = aps[@"call_id"];
    if (callId.length == 0) {
        DDLogError(@"Remote notification does not have 'call_id' key. Ignoring.");
        return NO;
    }

    return YES;
}

+ (BOOL) processRemoteNotification:(NSDictionary *)aps isVoip:(BOOL)isVoip
{
    NSString *callId = aps[@"call_id"];
    DDLogSupport(@"Processing Remote Push Notification with call_id: %@, isVoip: %d", callId, isVoip);
    
    if (![self isValidRemotePushNotification:aps]) {
        return YES;
    }
    
    // Only store the PUSH notifications that are not silent
    // Non-silent notifications have badge associated with them
    // Otherwise Silient PUSH notification due to Change Notifications are
    // Piling up in DB - KK
    if (aps[@"badge"] != nil) {
        [ReceivedPushNotificationDBService insert:callId];
    }
    
    if (aps[@"msg"] != nil) {
        return [QliqConnectModule processRemoteNotificationWithQliqMessage:aps isVoip:isVoip];
    } else {
        DDLogSupport(@"There is no 'msg' in the Remote Push Notification, calling get_qliq_message_for_push");
        [GetQliqMessageForPushService handlePushNotification:aps];
        return YES;
    }
}

+ (BOOL)processRemoteNotificationWithQliqMessage:(NSDictionary *)aps isVoip:(BOOL)isVoip {
    
    if ([UserSessionService currentUserSession].isLoginSeqeuenceFinished == NO) {
        DDLogSupport(@"Cannot process remote notification because app is not initialized yet, storing for later processing");
        NSMutableDictionary *apsCopy = [aps mutableCopy];
        [apsCopy setObject:[NSNumber numberWithBool:isVoip] forKey:@"is_voip"];
        
        if (s_pendingRemotePushNotifications == nil) {
            s_pendingRemotePushNotifications = [[NSMutableArray alloc] init];
        }
        [s_pendingRemotePushNotifications addObject:apsCopy];
        
        if (![[Login sharedService] isLoginRunning]) {
            [[Login sharedService] startLoginInResponseToRemotePush];
        }
        return YES;
    }
    
    DDLogSupport(@"Processing remote notification with 'msg'");
    
    if (![self isValidRemotePushNotification:aps]) {
        return YES;
    }
    
    NSString *callId = aps[@"call_id"];
    ChatMessage *existingMsg = [ChatMessageService getMessageWithUuid:callId];
    if (existingMsg != nil) {
        DDLogSupport(@"Already have the message from remote notification");
        if (!isVoip && ![existingMsg isRead]) {
            [[QliqUserNotifications getInstance] rescheduleChimeNotificationsForMessage:existingMsg];
        }
        return YES;
    }
    
    if (!isVoip) {
        [[QliqUserNotifications getInstance] addRemoteNotificationToChimed:aps[@"push_id"] callId:aps[@"call_id"]];
    }
    
    if (![QxPlatfromIOS isUserSessionStarted]) {
        DDLogWarn(@"Attempting to process message from remote notification, but qxlib session not started. Starting now");
        [QxPlatfromIOS onUserSessionStarted];
    }
    
    NSString *base64Message = aps[@"msg"];
    NSString *xHeadersString = aps[@"xheaders"];
    xHeadersString = [xHeadersString stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSStringEncoding dataEncoding = stringEncoding;
    NSError *error=nil;
    NSData *jsonData = [xHeadersString dataUsingEncoding:dataEncoding];
    
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSDictionary *xHeaders = [jsonKitDecoder objectWithData:jsonData error:&error];
    
    
    NSString *contentType = aps[@"content_type"];
    NSString *fromQliqId = aps[@"fuser"];
    NSString *toQliqId = aps[@"touser"];
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    
    if ([myQliqId isEqualToString:toQliqId]) {
        // If this is encrypted SP message to ourself, then decrypt here
        if ([contentType isEqualToString:@"application/octet-stream"]) {
            BOOL ok = NO;
            base64Message = [[Crypto instance] decryptFromBase64:base64Message wasOk:&ok];
            if (base64Message == nil || base64Message.length == 0 || !ok) {
                DDLogError(@"Cannot decrypt qliq message from remote notification. App should Notify The user");
                return NO;
            }
            contentType = @"text/plain";
        }
    }
    
    
    [[QliqSip sharedQliqSip] onMessageReceived:base64Message fromQliqId:fromQliqId toQliqId:toQliqId mime:contentType rxdata:nil extraHeaders:xHeaders];
    
    return YES;
}

#pragma mark *** Other ***

- (void)addToSerialQueue:(NSOperationQueue *)serialQueue asyncFIFOoperationWithBlock:(VoidBlock)block {
    
    if (serialQueue.maxConcurrentOperationCount != 1) {
        
        DDLogError(@"Error: You try to use non Serial QUEUE\nOperation IS NOT added to queue!");
        
    } else {
    
        if (block) {

            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
            operation.queuePriority = NSOperationQueuePriorityVeryHigh;
            
//            if (serialQueue.operations.count != 0) {
//            
//                [operation addDependency:serialQueue.operations.lastObject];
//            }
            
            [serialQueue addOperation:operation];
            
        } else {
        
         DDLogError(@"Error: You try to use NIL block\nOperation IS NOT added to queue!");
        
        }
    }
}

- (void) onPrivateKeyNeeded:(NSNotification *)notification
{
    NSString *qliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSDictionary *extraHeaders = [[notification userInfo] objectForKey:@"ExtraHeaders"];

	[self getAnySipContact:qliqId probableType:UnknownProbableContactType isGetPrivateKeyAction:YES chatMessage:nil extraHeaders:extraHeaders withCompletion:nil];
}

- (void) getAnySipContact:(NSString *)qliqId probableType:(ProbableContactType)type isGetPrivateKeyAction:(BOOL)isGetPrivateKeyAction chatMessage:(QliqSipExtendedChatMessage *)chatMessage extraHeaders:(NSDictionary *)extraHeaders withCompletion:(GetSipContactFinishedBlock)block;
{
    // TODO: thread safety!
    // TODO: save the message in a new db table until webservice finishes
    // (for cases when we cannot contact webserver at the time of receiving the msg.

    // Sanity check
    if (chatMessage && block) {
        DDLogError(@"BUG: The API is designed so either completion block or chat message is used");
    }
    
    // If type is not specified try to deduce based on headers
    if (type == UnknownProbableContactType && extraHeaders != nil) {
        BOOL isMultiparty = (extraHeaders[@"X-multiparty"] != nil);
        
        if (isMultiparty == NO) {
            if ([extraHeaders[@"X-sender-sync"] isEqualToString:@"yes"]) {
                // Sender sync message doesn't have X-multiparty of X-groupmessage headers
                // so we cannot assume anything
                type = UnknownProbableContactType;
            } else  if (isGetPrivateKeyAction == NO) {
                // This is a message to an user (contact)
                type = UserProbableContactType;
            } else {
                // Trying to get private key for an user doesn't make sense
                //
                // We can end here because previously SIP server was stripping the X-multiparty header
                // so we add it here
                isMultiparty = YES;
            }
        }
        
        if (isMultiparty) {
            // This can be to a group or MP
            type = MultipartyOrGroupProbableContactType;
            NSString *groupMessage = [extraHeaders objectForKey:@"X-groupmessage"];
            if (groupMessage != nil) {
                if ([groupMessage isEqualToString:@"yes"]) {
                    type = GroupProbableContactType;
                } else if ([groupMessage isEqualToString:@"no"]) {
                    type = MultipartyProbableContactType;
                } else {
                    DDLogError(@"BUG: invalid value for X-groupmessage header: '%@'", groupMessage);
                }
            } else {
                // Older clients don't send this header, this can be either group or MP
                type = MultipartyOrGroupProbableContactType;
            }
        }
    }

    GetSipContactContext *context = [[GetSipContactContext alloc] init];
    context.qliqId = qliqId;
    context.probableContactType = type;
    context.lastTriedContactType = UnknownProbableContactType;
    context.completion = block;
    context.chatMessage = chatMessage;
    context.isGetPrivateKeyAction = isGetPrivateKeyAction;
    context.triedServices = [[NSMutableArray alloc] init];
    
    NSString *key;
    if (context.isGetPrivateKeyAction) {
        key = [@"privkey-" stringByAppendingString:context.qliqId];
    } else {
        key = context.qliqId;
    }
    // TODO: synchronize we have own queue and webservice calls?
    BOOL isFirstRequest = NO;
    
    @synchronized(getSipContactContexts) {
        NSMutableArray *array = [getSipContactContexts objectForKey:key];
        if (!array) {
            array = [[NSMutableArray alloc] init];
            [getSipContactContexts setObject:array forKey:key];
            isFirstRequest = YES;
        } else {
            GetSipContactContext *firstContext = [array objectAtIndex:0];
            isFirstRequest = !firstContext.isAwaitingResponse;
        }
        [array addObject:context];
    }
    if (isFirstRequest == NO) {
        // We already have outstanding request for this qliq id,
        // just add to the queue and we are done here.
        return;
    }
    
    [self sendGetAnySipContact:context];
}

- (void) sendGetAnySipContact:(GetSipContactContext *)context
{
    // Here we choose which webservice to call for this qliq id
    // There are 3 cases possible
    // 1. We know the type of the qliq id - no ambiguity
    // 2. We know this is X-multiparty but not sure if MP or group
    // 3. We know nothing
    //
    // If there is any ambiguity call the services in the order based on probability
    // 1. Try get_mp
    // 2. Try get_contact_info
    // 3. Try get_group_info
    
    context.isAwaitingResponse = YES;
    
    // If we know this is a MP
    // or we know this is a MP or a group and didn't try any service call yet
    // or we know nothing                 and didn't try any service call yet
    if ( context.probableContactType == MultipartyProbableContactType ||
        (context.probableContactType == MultipartyOrGroupProbableContactType && context.lastTriedContactType == UnknownProbableContactType) ||
        (context.probableContactType == UnknownProbableContactType           && context.lastTriedContactType == UnknownProbableContactType)) {
        context.lastTriedContactType = MultipartyProbableContactType;
        [context.triedServices addObject:@"MP"];
        
        DDLogSupport(@"Trying to get MP for contact type: %ld, qliq id: %@", (long)context.probableContactType, context.qliqId);
        GetMultiPartyService *getMp = [[GetMultiPartyService alloc] initWithQliqId: context.qliqId];
        
        __block __weak typeof(self) weakSelf = self;
        [getMp callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            NSInteger errorCode = 0;
            NSString *errorMsg = nil;
            if (status == CompletitionStatusSuccess) {
            } else {
                errorCode = -1;
                errorMsg = error.localizedDescription;
                NSDictionary *userInfo = error.userInfo;
                NSDictionary *webserverErrorDict = userInfo[@"received_error_dictionary"];
                if (webserverErrorDict != nil) {
                    errorCode = [webserverErrorDict[@"error_code"] integerValue];
                    
                    if (errorCode == 103) {
                        if (context.probableContactType != MultipartyProbableContactType) {
                            // Retry with another webservice type
                            DDLogSupport(@"MP not found on server, retrying other contact type, qliq id: %@", context.qliqId);
                            [weakSelf sendGetAnySipContact:context];
                            return;
                        }
                    }
                }
            }
            DDLogSupport(@"get_multiparty finished with error? %d, code: %ld", (error != nil), (long)errorCode);
            context.isAwaitingResponse = NO;
            [weakSelf handleGetAnySipContactFinished:context webErrorCode:errorCode errorMessage:errorMsg];
        }];
    
    } else if (!context.isGetPrivateKeyAction && 
    		   (context.probableContactType == UserProbableContactType ||
        	   (context.probableContactType == UnknownProbableContactType && context.lastTriedContactType == MultipartyProbableContactType))) {
        context.lastTriedContactType = UserProbableContactType;
        [context.triedServices addObject:@"user"];
                   
        DDLogSupport(@"Trying to get user (get_contact_info) for contact type: %ld, qliq id: %@", (long)context.probableContactType, context.qliqId);
                   __block __weak typeof(self) weakSelf = self;
        [[GetContactInfoService sharedService] getContactInfo:context.qliqId completitionBlock:^(QliqUser *contact, NSError *error) {
            NSInteger errorCode = 0;
            NSString *errorMsg = nil;
            if (error) {
                errorMsg = error.localizedDescription;
                errorCode = error.code;
                if (!errorCode) {
                    errorCode = -1;
                }
                
                if (errorCode == 103) {
                    if (context.probableContactType != UserProbableContactType) {
                        // Retry with another webservice type
                        DDLogSupport(@"User (get_contact_info) not found on server, retrying other contact type, qliq id: %@", context.qliqId);
                        [weakSelf sendGetAnySipContact:context];
                        return;
                    }
                }
            }
            DDLogSupport(@"get_contact_info finished with error? %d, code: %ld", (error != nil), (long)errorCode);
            context.isAwaitingResponse = NO;
            [self handleGetAnySipContactFinished:context webErrorCode:errorCode errorMessage:errorMsg];
        }];

    // If we know this a group OR we know nothing and we already tried 'user'
    } else if (context.probableContactType == GroupProbableContactType ||
              (context.probableContactType == MultipartyOrGroupProbableContactType && context.lastTriedContactType == MultipartyProbableContactType) ||
              (context.probableContactType == UnknownProbableContactType && context.lastTriedContactType == UserProbableContactType)) {
        context.lastTriedContactType = GroupProbableContactType;

        QliqGroup *group = [[QliqGroupDBService sharedService] getGroupWithId:context.qliqId];
        BOOL hasGroup = (group.qliqId.length > 0);
        
		if (context.isGetPrivateKeyAction && hasGroup) {
            [context.triedServices addObject:@"group priv key"];
		    DDLogSupport(@"Trying to get group private key for contact type: %ld, qliq id: %@", (long)context.probableContactType, context.qliqId);
			GetGroupKeyPair *getGKP = [[GetGroupKeyPair alloc] init];
            __block __weak typeof(self) weakSelf = self;
			[getGKP getGroupKeyPairCompletitionBlock:context.qliqId completionBlock:^(CompletitionStatus status, id result, NSError *error) {
                NSInteger errorCode = 0;
                NSString *errorMsg = nil;
				if (error) {
                    errorMsg = error.localizedDescription;
                    errorCode = error.code;
                }
                SipContact *contact = nil;
				if (status == CompletitionStatusSuccess) {
				    SipContactDBService *sipContactDBService = [[SipContactDBService alloc] init];
				    contact = [sipContactDBService sipContactForQliqId:context.qliqId];
				}
				
				if ([contact.privateKey length] == 0) {
					errorCode = -5;
                    DDLogError(@"Cannot retrieve group key pair for: %@", context.qliqId);
				}
                context.isAwaitingResponse = NO;
                [weakSelf handleGetAnySipContactFinished:context webErrorCode:errorCode errorMessage:errorMsg];
			}];
		} else {
            [context.triedServices addObject:@"group"];
		    DDLogSupport(@"Trying to get group for contact type: %ld, qliq id: %@", (long)context.probableContactType, context.qliqId);
		    [[GetGroupInfoService sharedService] getGroupInfo:context.qliqId withCompletion:^(QliqGroup *group, NSError *error) {
		        NSInteger errorCode = 0;
                NSString *errorMsg = nil;
		        if (error) {
                    errorMsg = error.localizedDescription;
		            errorCode = error.code;
		            if (!errorCode) {
		                errorCode = -1;
		            }
		            
		            if (errorCode == 103) {
		                DDLogSupport(@"Group not found on server, qliq id: %@", context.qliqId);
		            }
		        }
		        DDLogSupport(@"get_group_info finished with error? %d, code: %ld", (error != nil), (long)errorCode);
                
                if (context.isGetPrivateKeyAction && errorCode == 0) {
                    // Only after we retrieved the group we can ask for private key
                    // Reset last tried field so we end up in this if {} block again
                    if (context.probableContactType == MultipartyOrGroupProbableContactType) {
                        context.lastTriedContactType = MultipartyProbableContactType;
                    } else if (context.probableContactType == UnknownProbableContactType) {
                        context.lastTriedContactType = UserProbableContactType;
                    }
                    
                    [self sendGetAnySipContact:context];
                } else {
                    context.isAwaitingResponse = NO;
                    [self handleGetAnySipContactFinished:context webErrorCode:errorCode errorMessage:errorMsg];
                }
		    }];
		}
    } else {
        context.isAwaitingResponse = NO;
        DDLogError(@"BUG: code should never reach this line");
    }
}

- (void) handleGetAnySipContactFinished:(GetSipContactContext *)context webErrorCode:(NSInteger)errorCode errorMessage:(NSString *)errorMsg
{
    NSString *key;
    if (context.isGetPrivateKeyAction) {
        key = [@"privkey-" stringByAppendingString:context.qliqId];
    } else {
        key = context.qliqId;
    }

    NSMutableArray *array = nil;
    // Make the synchronized block as small as possible
    @synchronized(getSipContactContexts) {
        array = [getSipContactContexts objectForKey:key];
        
        if (errorCode == 0 || errorCode == 103) {
            [getSipContactContexts removeObjectForKey:key];
        }
    }

    if (!array || [array count] == 0) {
        DDLogError(@"Webservice call finished but we don't have any context to work with");
        return;
    }
    
    NSString *privateKey = nil;
	GetSipContactContext *firstContext = [array objectAtIndex:0];
	if (firstContext.isGetPrivateKeyAction) {
	    SipContactDBService *sipContactDBService = [[SipContactDBService alloc] init];
	    SipContact *contact = [sipContactDBService sipContactForQliqId:context.qliqId];
		privateKey = contact.privateKey;
	}

    if (errorCode == 0) {
        for (GetSipContactContext *context in array) {
            if (context.completion != nil) {
                context.completion(errorCode);
            } else if (context.chatMessage != nil) {
                [self processExtendedChatMessage:context.chatMessage];
            } else if (context.isGetPrivateKeyAction) {
			    [[QliqSip sharedQliqSip] onPrivateKeyReceived:privateKey qliqId:context.qliqId];            	
            }
        }
    } else if (errorCode == 103) {
        // The contact was not found, call any completions and drop the messages
        for (GetSipContactContext *context in array) {
            if (context.completion != nil) {
                context.completion(errorCode);
            }
        }
    } else {
        // Other error. What to do here?
        // Right now we just keep the contexts in memory in case the webservice call is retried
        // when triggered by a new message
        NSString *subject = (context.isGetPrivateKeyAction ? @"private key" : @"contact");
        DDLogError(@"Couldn't get %@ for qliq id: %@, probable type: %ld, last tried type: %ld, error: %@", subject, context.qliqId, (long)context.probableContactType, (long)context.lastTriedContactType, errorMsg);
    }
}

- (NSString *) extractSipUriFromString:(NSString *) sipContainedString{

    NSString * sipString = [sipContainedString stringByReplacingOccurrencesOfString: @"sip:" withString: @""];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    return [sipString stringByTrimmingCharactersInSet:charSet];

}

/* clean code went away. TODO: Refactor into small obvious methods */ //aii create conversations
- (Conversation *) conversationForReceivedMessage:(QliqSipExtendedChatMessage *) sipMessage fromQliqId:(NSString *) recipients_qliqId toQliqId:(NSString *) toQliqId
{
    @synchronized (self) {
        Conversation * conversation = nil;
        
        NSInteger existingConversationId = 0;
        
        if ([sipMessage.conversationUuid length] == 0) {
            // If no conversationUuid in json then look for X-header as fallback
            sipMessage.conversationUuid = [sipMessage.extraHeaders objectForKey:@"X-conversation-uuid"];
        }
        
        if ([sipMessage.conversationUuid length] > 0) {
            conversation = [[ConversationDBService sharedService] getConversationWithUuid:sipMessage.conversationUuid];
            if (conversation != nil) {
                existingConversationId = conversation.conversationId;
            } else {
                if ([sipMessage.fromQliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                    // Sender sync message
                    existingConversationId = [DBHelperConversation getLastUpdatedConversationId:recipients_qliqId andSubject:sipMessage.conversationSubject];
                    if (existingConversationId > 0) {
                        conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:existingConversationId]];
                        conversation.uuid = sipMessage.conversationUuid;
                        [[ConversationDBService sharedService] saveConversation:conversation];
                        DDLogSupport(@"Updated (sender sync) uuid for old conversation id: %ld, uuid: %@", (long)conversation.conversationId, conversation.uuid);
                    }
                }
                
                if (existingConversationId == 0) {
                    // -1 means don't look for existing based on recipient and subject
                    existingConversationId = -1;
                }
            }
        }
        
        RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] init];
        
        /* If event occured */
        BOOL isChatEvent = NO;
        if ([ChatMessage typeFromString:sipMessage.dataType] == ChatMessageTypeEvent){
            isChatEvent = YES;
            NSDictionary * event = [ChatEventHelper eventDictFromString:sipMessage.messageText];
            
            NSString * qliq_id_before = event[CHAT_EVENT_MESSAGE_RECIPIENT_QLIQ_ID_BEFORE];
            
            if (existingConversationId == 0) {
                /* Get current conversation */
                existingConversationId = [DBHelperConversation getLastUpdatedConversationId:qliq_id_before andSubject:sipMessage.conversationSubject];
            }
            
            /* Set recipients_qliq_id from event dict. Will be used below to load/create recipients */
            recipients_qliqId = event[CHAT_EVENT_MESSAGE_RECIPIENT_QLIQ_ID_AFTER];
            
            if (existingConversationId > 0){
                /* mark conversation as deleted(or not) if used was removed/added */
                BOOL userRemoved = [event[CHAT_EVENT_MESSAGE_REMOVED] containsObject:[UserSessionService currentUserSession].user.qliqId];
                [[ConversationDBService sharedService] setDeleteFlag:userRemoved forConversationId:existingConversationId];
            }
                    
        }else{
            if (existingConversationId == 0) {
                /* Check for existing conversation by qliq_id and subject */
                existingConversationId = [DBHelperConversation getLastUpdatedConversationId:recipients_qliqId andSubject:sipMessage.conversationSubject];
            }
        }
        
        /* Create new one */
        if (existingConversationId <= 0) {
            conversation = [[Conversation alloc] initWithPrimaryKey:0];
            conversation.subject = sipMessage.conversationSubject;
            conversation.uuid = sipMessage.conversationUuid;
            conversation.redirectQliqId = [sipMessage.extraHeaders objectForKey:@"X-redirect"];
            conversation.isRead = YES;
            
        }else{
            conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:existingConversationId]];
            
            if ([sipMessage.conversationUuid length] > 0) {
                if ([toQliqId isEqualToString:[Helper getMyQliqId]] == NO) {
                    // TODO: SP to MP upgrade handling
                }
            }
        }
        
        /* If haven't recipients object or have but with incorrect qliq_id, then reload from db new one */
        if (([conversation.recipients count] == 0) || (isChatEvent && ![conversation.recipients.qliqId isEqualToString:recipients_qliqId])) {

            /* remove existing recipients to replace with new */
            if (conversation.recipients) {
                [recipientsDBService deleteObject:conversation.recipients mode:DBModeToMany | DBModeToOne completion:nil];
            }
            
            /* Try to load existing recipients for qliq_id (usually for MP) */
            conversation.recipients = [recipientsDBService recipientsWithQliqId:recipients_qliqId];

            // Adam Sowa: why this if code? I commented it out
            /* If loaded SP recipients - remove to create new */
//            if (conversation.recipients && ![conversation.recipients isMultiparty]){
//                conversation.recipients = nil;
//            }
            
            
            /* .. or create new with one recipient (for SP) */
            if (!conversation.recipients || !conversation.recipients.qliqId || [conversation.recipients.qliqId isEqualToString:@""] || conversation.recipients.qliqId.length == 0 || [conversation.recipients.recipientsArray count] == 0){
                conversation.recipients = [[Recipients alloc] init];
                QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:recipients_qliqId];
                if (user) {
                    [conversation.recipients addRecipient:user];
                } else {
                    QliqGroup *group = [[QliqGroupDBService sharedService] getGroupWithId:recipients_qliqId];
                    if (group) {
                        [conversation.recipients addRecipient:group];
                    } else {
                        DDLogError(@"Cannot determine recipient for new conversation, qliq id: %@", recipients_qliqId);
                    }
                }
            }
            
            [[ConversationDBService sharedService] saveConversation:conversation];
            /* Post notification to update UI */
            DDLogSupport(@"Save new conversation on DB with id - %li, with subject - '%@'", (long)conversation.conversationId, conversation.subject.length < 1 ? @"without subject" : conversation.subject);
            
            if (existingConversationId > 0 && [conversation.recipients isMultiparty]) {
                [QliqConnectModule notifyMultipartyWithQliqId:recipients_qliqId];
            }
        }
        DDLogSupport(@"Returning conversation with id: %ld", (long)conversation.conversationId);
        return conversation;
    }
}

-(BOOL) saveMessageAsRead:(NSInteger)messageId
{
    NSTimeInterval readAt = [[NSDate date] timeIntervalSince1970];
    ChatMessage *msg = [DBHelperConversation getMessage:messageId];
    if (msg) {
        [self sendOpenedStatus:msg];
    }
    return [self saveMessageAsRead:messageId at:readAt];
}

-(BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt
{
    BOOL ret = [ChatMessage saveMessageAsRead:messageId at:readAt andRevisionDirty:NO]; // the recipient doesn't push to qliqStor
    if(ret){
		// Save the status message
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = messageId;
        statusLog.timestamp = readAt;
        statusLog.status = ReadMessageStatus;
        [self.statusLogDbService saveMessageStatusLog:statusLog];
    }
	
    if (ret && justReceivedMessage && justReceivedMessage.messageId == messageId)
    {
        justReceivedMessage.readAt = readAt;
    }

    return ret;
}

-(void) notifyChatAck:(ChatMessage *)message withSound:(BOOL)playSound
{
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message.uuid forKey:@"messageGuid"];
    [NSNotificationCenter postNotificationToMainThread:SIPChatMessageAckNotification userInfo:userInfo];

    if (playSound) {
        [[QliqUserNotifications getInstance] notifyAckGotForMessage:message];
    }    
}

-(void) sendMessage:(NSString *)messageText toUser:(Contact *)userContact subject:(NSString *)subject ackRequired:(BOOL)ack priority:(ChatMessagePriority)aPriority type:(ChatMessageType)aType
{
    QliqUserDBService * userService = [[QliqUserDBService alloc] init];
    QliqUser * user = [userService getUserForContact:userContact];
    
    Recipients * recipients = [[Recipients alloc] init];
    [recipients addRecipient:user];
    
    Conversation *conv = [self newConversationWithRecipients:recipients subject:subject broadcastType:NotBroadcastType uuid:nil];
    [self sendMessage:messageText toQliqId:[userContact qliqId] inConversation:conv acknowledgeRequired:ack priority:aPriority type:aType];
    
}


- (void) saveStatus:(MessageStatus)status forMessage:(ChatMessage *) message{
    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
    statusLog.messageId = message.messageId;
    statusLog.timestamp = message.createdAt;
    statusLog.status = status;
    [self.statusLogDbService saveMessageStatusLog:statusLog];
}


- (void)sendMessage:(ChatMessage *)chatMessage completition:(CompletionBlock)completeBlock {
    
    chatMessage.deliveryStatus = 0; //Set 'Sending' status
    chatMessage.statusText = nil;
    
    BOOL messageExists = [self.chatMessageService messageExists:chatMessage];
    
    if([self.chatMessageService saveMessage:chatMessage]) {
        // If message was inserted - then save status as Created
        if (!messageExists) {
            [self saveStatus:CreatedMessageStatus forMessage:chatMessage];
        }
    }
    else {
        DDLogError(@"Cant save message: %@", chatMessage);
    }
    
    /* Cancel if no qliqId */
    if (chatMessage.toQliqId.length == 0){
        DDLogWarn(@"%@, qliqId = %@. Will cancel sending message for now..", chatMessage, chatMessage.toQliqId);
        return;
    }
    
    
    if([chatMessage attachments].count > 0) {
        __block __weak typeof(self) weakSelf = self;
        
		[attachmentApiService uploadAllAttachmentsForMessage:chatMessage completition:^(CompletitionStatus status, id result, NSError *error) {
            switch (status) {
                case CompletitionStatusSuccess: {
                    
                    [weakSelf sipSendMessage:chatMessage];
                    break;
                }
                case CompletitionStatusCancel: {
                    
                    chatMessage.deliveryStatus = MessageStatusAttachmentUploadCancelled;   //Set 'Canceled' status
                    chatMessage.statusText = nil;
                   
                    [weakSelf.chatMessageService saveMessage:chatMessage];
                    break;
                }
                case CompletitionStatusError: {
                    
                    if ([error code] == 103) {
                        chatMessage.deliveryStatus = MessageStatusAttachmentUploadAttachmentNotFound;
                    }
                    else {
                        chatMessage.deliveryStatus = MessageStatusCannotUploadAttachment;   //Set 'Error uploading' status
                    }
                    chatMessage.statusText = nil;

                    // Save the status message
                    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                    statusLog.messageId = chatMessage.messageId;
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = chatMessage.deliveryStatus;
                    [weakSelf.statusLogDbService saveMessageStatusLog:statusLog];
                    
                    [weakSelf.chatMessageService saveMessage:chatMessage];
                    break;
                }
            }
            
            if (completeBlock) {
                completeBlock(status, chatMessage, error);
            }
        }];
	}
    else {
        [self sipSendMessage:chatMessage];
        
        if (completeBlock) {
            completeBlock(CompletitionStatusSuccess, chatMessage, nil);
        }
    }
}

- (void)sendMessage:(ChatMessage *)chatMessage {
    [self sendMessage:chatMessage completition:nil];
}

-(ChatMessage*)sendMessage:(NSString *)messageText toQliqId:(NSString *)toQliqId inConversation:(Conversation *)conversation acknowledgeRequired:(BOOL)ack priority:(ChatMessagePriority)aPriority type:(ChatMessageType)aType
{
    
    SipContact *toContact = [[SipContactDBService sharedService] sipContactForQliqId:toQliqId];
    if (!toContact) {
        DDLogError(@"Cannot find SipContact for qliq id: %@", toQliqId);
        return nil;
    }
    
	NSString *myQliqId = [Helper getMyQliqId];
	
    // Create new message and save to database.
	ChatMessage *newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
	newMessage.conversationId = conversation.conversationId;
	newMessage.fromQliqId = myQliqId;
	newMessage.toQliqId = toQliqId;
	newMessage.text = messageText;
	newMessage.timestamp = [[NSDate date] timeIntervalSince1970];
	newMessage.readAt = newMessage.timestamp;
    newMessage.createdAt = newMessage.timestamp;
	newMessage.ackRequired = ack;
    newMessage.priority = aPriority;
    newMessage.type = aType;
    newMessage.subject = conversation.subject;
    newMessage.metadata = [Metadata createNew];
    newMessage.metadata.isRevisionDirty = YES;
    
	[self sendMessage:newMessage];
    return newMessage;
}

- (NSString *) createdAtStringFromTimestamp:(NSTimeInterval)timeInterval
{
    NSTimeInterval createdAt = [[QliqSip sharedQliqSip] adjustTimeForNetwork:timeInterval];
    return [Helper intervalToISO8601DateTimeString:createdAt];
}

- (NSDictionary *) dictionaryRepresentationFromAttachment:(MessageAttachment *)attachment error:(NSError **)error
{
    NSMutableDictionary *attachmentDictionary = [NSMutableDictionary new];
    
    attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_URL] = attachment.url ? attachment.url : @"";
    attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_MIME] = attachment.mediaFile.mimeType;
    attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_FILE_NAME] = attachment.mediaFile.fileName;

    if (attachment.mediaFile.encryptionKey) {
        attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_KEY] = attachment.mediaFile.encryptionKey;
        attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_ENCRYPTION_METHOD] = @(1);
    }
    if (attachment.mediaFile.checksum.length > 0) {
        attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_CHECKSUM] = attachment.mediaFile.checksum;
    }
    
    attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_SIZE] = [attachment.mediaFile encryptedFileSizeNumber];
    
    if ([MessageAttachment shouldSendThumbnailForFileName:attachment.mediaFile.fileName]) {
        NSString *thumbnailBase64String = [attachment thumbnailBase64Encoded];
        
        if (thumbnailBase64String.length > 0) {
            attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_THUMBNAIL] = thumbnailBase64String;
        } else {
            attachment.status = AttachmentStatusDeclined;
            [attachment save];
            if (error != nil) {
                *error = [NSError errorWithCode:0 description:[NSString stringWithFormat:@"Can't generate thumbnail for attachment: %@",attachment]];
            }
            return nil;
        }
    }
    
    return attachmentDictionary;
}

- (NSDictionary *) dictionaryRepresentationFromMessage:(ChatMessage *)message conversationUuid:(NSString *)conversationUuid toContactType:(SipContactType)toContactType error:(NSError **)error
{
    NSMutableDictionary *messageDictionary = [NSMutableDictionary new];
    
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_TEXT] = message.text;
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_REQUIRES_ACKNOWLEDGEMENT] = @(message.ackRequired);
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_CONVERSATION_SUBJECT] = message.subject;
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_TO_USER_ID] = message.toQliqId;
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_MESSAGE_ID] = message.uuid;
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_CREATED_AT] = [self createdAtStringFromTimestamp:message.timestamp];
    
    if ([conversationUuid length] > 0) {
        messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_CONVERSATION_UUID] = conversationUuid;
    }
    
    if (message.priority != ChatMessagePriorityNormal) {
        messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_PRIORITY] = [message priorityToString];
    }
    
    if (message.type != ChatMessageTypeNormal) {
        messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_TYPE] = [message typeString];
    }
    
    NSString *recipientType = nil;
    if (toContactType == SipContactTypeGroup) {
        recipientType = @"group";
    } else if (toContactType == SipContactTypeMultiPartyChat) {
        recipientType = @"mp";
    } else if (toContactType == SipContactTypeUser) {
        recipientType = @"user";
    }
    if (recipientType.length > 0) {
        messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_RECIPIENT_TYPE] = recipientType;
    }

    NSMutableArray *attachmentsArray = [[NSMutableArray alloc] initWithCapacity:[message.attachments count]];
    
    for(MessageAttachment *attachment in message.attachments)
    {
        NSError *attachmentError = nil;
        NSDictionary *attachmentsDictionary = [self dictionaryRepresentationFromAttachment:attachment error:&attachmentError];
        if (!attachmentError) {
            [attachmentsArray addObject:attachmentsDictionary];
        } else {
            *error = attachmentError;
            return nil;
        }
    }
    
    messageDictionary[EXTENDED_CHAT_MESSAGE_DATA_ATTACHMENTS] = attachmentsArray;
    
    return messageDictionary;
}

- (NSString *) jsonStringFromExtendedMessageData:(NSDictionary *)extendedMessageData
{
    NSDictionary *extendedMessageDictionary = @{ EXTENDED_CHAT_MESSAGE_MESSAGE_TYPE : EXTENDED_CHAT_MESSAGE_MESSAGE_TYPE_PATTERN,
                                                 EXTENDED_CHAT_MESSAGE_MESSAGE_COMMAND : EXTENDED_CHAT_MESSAGE_MESSAGE_COMMAND_PATTERN,
                                                 EXTENDED_CHAT_MESSAGE_MESSAGE_SUBJECT: EXTENDED_CHAT_MESSAGE_MESSAGE_SUBJECT_PATTERN,
                                                 EXTENDED_CHAT_MESSAGE_MESSAGE_DATA : extendedMessageData
                                                 };
    
    NSDictionary *jsonDict = @{ EXTENDED_CHAT_MESSAGE_MESSAGE : extendedMessageDictionary};
    
    return [jsonDict JSONString];
}

- (void) sipSendMessage: (ChatMessage *)message
{
    
	BOOL isReachable = [[QliqReachability sharedInstance] isReachable];
	if (!isReachable){
        DDLogError(@"Internet is not reachable during sending message. In old implmentation it should be marked as network error..but now we'll try to send it anyway");
//		message.deliveryStatus = 491;
//		[chatMessageService saveMessage:message];
//        return;
	}

    // Since QliqSip uses its own bg thread we don't need to call this on main thread anymore
    //
    //Check if current thread is not main then switch to main thread because PJSip registered on main thread only
//    if (![NSThread isMainThread]) {
//        [self performSelectorOnMainThread:@selector(sipSendMessage:) withObject:message waitUntilDone:YES];
//        return;
//    }
    
    
    //    NSLog(@"SIP Notification: sending message (%d: \"%@\") to qliq_id: %@",message.messageId, message.text, message.toQliqId);
    
    //Check if message already sending
    for (ChatMessage * _tmpMessage in self.sentChatMessages){
        if (_tmpMessage.messageId == message.messageId && _tmpMessage.deliveryStatus == 0){
            //            NSLog(@"SIP Notification: message already in sending process. Aborting retrying.");
            return;
        }
    }
    //Mark message as sending
    message.deliveryStatus = 0;
    message.statusText = nil;
    
    SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
    SipContact *toContactInsideMessage = [sipContactService sipContactForQliqId:message.toQliqId];
    SipContact *toContact = toContactInsideMessage;
    
    if ([toContact.sipUri length] == 0) {
        DDLogError(@"Cannot find SIP URI for qliq id: %@", message.toQliqId);
        return;
    }
    
    BOOL isSelfSync = NO;
    if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
        if (message.selfDeliveryStatus / 100 != 2) {
            isSelfSync = YES;
            toContact = [sipContactService sipContactForQliqId:[UserSessionService currentUserSession].user.qliqId];
        }
    } else {
        message.selfDeliveryStatus = 200;
    }
    
    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:message.conversationId]];
    if (conversation.uuid.length == 0) {
        // Generate uuid for old conversation
        conversation.uuid = [Metadata generateUuid];
        DDLogSupport(@"Generated uuid for old conversation id: %ld, uuid: %@", (long)conversation.conversationId, conversation.uuid);
        
        if (![[ConversationDBService sharedService] saveConversation:conversation]) {
            // Shouldn't ever happen
            conversation.uuid = nil;
            DDLogError(@"Cannot save conversation");
        }
    }
    
    if (!isSelfSync && conversation.redirectQliqId.length > 0) {
        toContact = [sipContactService sipContactForQliqId:conversation.redirectQliqId];
        if ([toContact.sipUri length] == 0) {
            DDLogError(@"Cannot find SIP URI for redirect qliq id: %@", conversation.redirectQliqId);
            return;
        }
        
    }
    
    NSError *messageCreationError = nil;
    NSDictionary *messageData = [self dictionaryRepresentationFromMessage:message conversationUuid:conversation.uuid toContactType:toContactInsideMessage.sipContactType error:&messageCreationError];
    
    if (messageCreationError) {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1023-TextError", nil)
                                                                      message:[messageCreationError localizedDescription] delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil) otherButtonTitles:nil];
        [alert showWithDissmissBlock:NULL];
        return;
    }
    
    NSString *messageJsonString = [self jsonStringFromExtendedMessageData:messageData];
    
    if (![self.sentChatMessages containsObject:message])
    {
        [self.sentChatMessages addObject:message];
    }
    
    NSString *qliqStorIds = @"";
    if (!isSelfSync) {
        // Save the status message
        [self saveStatus:SendingMessageStatus forMessage:message];
        
        [PushMessageToQliqStorHelper setMessageUnpushedToAllQliqStors:message];
        
        NSSet *qliqStors = [PushMessageToQliqStorHelper qliqStorsForMessage:message];
        for (QliqUser *u in qliqStors) {
            qliqStorIds = [qliqStorIds stringByAppendingFormat:@"%@;", u.qliqId];
        }
    }
    
    NSString *myDisplayName = [[UserSessionService currentUserSession].user displayName];
    DDLogSupport(@"Create Sip message with UUId:%@, from contact:%@, to contact:%@ conv-uuid:%ld, with attachment: %i", message.metadata.uuid, message.fromQliqId, message.toQliqId, (long)message.conversationId, (BOOL)message.hasAttachment);
    SipMessage *sipMsg = [[QliqSip sharedQliqSip] toSipMessage:messageJsonString toQliqId:toContact.qliqId withContext:message offlineMode:YES pushNotify:!isSelfSync withDisplayName:myDisplayName withCallId:message.metadata.uuid withPriority:message.priority alsoNotify:qliqStorIds extraHeaders:nil withMessageStatusChangedBlock:nil];
    
    sipMsg.createdAt = [[QliqSip sharedQliqSip] adjustTimeForNetwork:message.timestamp];
    
    if (conversation.uuid.length > 0) {
        sipMsg.conversationUuid = conversation.uuid;
    }
    
    if ([conversation isSentBroadcast]) {
        sipMsg.isBroadcast = YES;
    }
    
    if (!isSelfSync && toContact.sipContactType == SipContactTypeUser) {
        QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:toContact.qliqId];
        if (user.isPagerUser) {
            sipMsg.pagerInfo = user.pagerInfo;
        }
    }
    
    if (conversation.broadcastType == PlainTextBroadcastType) {
        [[QliqSip sharedQliqSip] sendPlainTextMessage:sipMsg];
    } else {
        [[QliqSip sharedQliqSip] sendMessage:sipMsg];
    }
}

- (void) sendOpenedStatus: (ChatMessage *)msg
{
    if ([[QliqSip sharedQliqSip] isMultiDeviceSupported] && !msg.isOpenedSent && ![msg isSentByUser]) {
        
        // Since QliqSip uses its own bg thread we don't need to call this on main thread anymore
        //
        //Check if current thread is not main then switch to main thread because PJSip registered on main thread only
//        if (![NSThread isMainThread]) {
//            [self performSelectorOnMainThread:@selector(sendOpenedStatus:) withObject:msg waitUntilDone:NO];
//            return;
//        }
        
        SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
        SipContact *fromContact = [sipContactService sipContactForQliqId:msg.fromQliqId];
        if ([fromContact.sipUri length] == 0) {
            DDLogError(@"Cannot send opened status: cannot get sip uri for qliq id: %@", msg.fromQliqId);
            msg.isOpenedSent = YES;
            [[ChatMessageService sharedService] saveMessage:msg];
        } else {
            [[QliqSip sharedQliqSip] sendOpenedStatus:fromContact.qliqId callId:msg.metadata.uuid serverContext:msg.serverContext];
        }
    }
}

- (void) sendDeletedStatus: (ChatMessage *)msg
{
    if (![msg isDeletedSent]) {
//        SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
//        SipContact *fromContact = [sipContactService sipContactForQliqId:msg.fromQliqId];
//        if ([fromContact.sipUri length] == 0) {
//            DDLogError(@"Cannot send deleted status: cannot get sip uri for qliq id: %@", msg.fromQliqId);
//            msg.deletedStatus = DeletedAndSentStatus;
//            [[ChatMessageService sharedService] saveMessage:msg];
//        } else {
            if (msg.deletedStatus != DeletedAndNotSentStatus) {
                msg.deletedStatus = DeletedAndNotSentStatus;
                [self deleteAttachmentsOfMessage:msg];
                [[ChatMessageService sharedService] saveMessage:msg];
                [self notifyChatMessageStatus:msg];
                
                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:msg.conversationId]];
                ChatMessage *latestMsg = [[ChatMessageService sharedService] getLatestMessageInConversation:msg.conversationId];
                if (!latestMsg) {
                    conversation.deleted = YES;
                    [[ConversationDBService sharedService] saveConversation:conversation];
                }
                
                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation, @"Conversation", [NSNumber numberWithInteger:msg.messageId], @"MessageId", [NSNumber numberWithBool:YES], @"Local", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:QliqConnectDidDeleteMessagesInConversationNotification object:nil userInfo:info];
                
            }
            NSString *serverContext = msg.serverContext;
            QliqUser *me = [UserSessionService currentUserSession].user;
        if ([msg.fromQliqId isEqualToString:me.qliqId]) {
            // For sender sync message don't send serverContext which is invalid in this case
            serverContext = nil;
        }
            [[QliqSip sharedQliqSip] sendDeletedStatus:nil callId:msg.metadata.uuid serverContext:serverContext];
//        }
    }
}

- (void) sendRecalledStatus: (ChatMessage *)msg
{
    if (msg.recalledStatus != RecalledAndSentStatus) {
        SipContactDBService *sipContactService = [[SipContactDBService alloc] init];
        SipContact *toContact = [sipContactService sipContactForQliqId:msg.toQliqId];
        if ([toContact.sipUri length] == 0) {
            DDLogError(@"Cannot send recalled status: cannot get sip uri for qliq id: %@", msg.toQliqId);
            msg.recalledStatus = RecalledAndSentStatus;
            [[ChatMessageService sharedService] saveMessage:msg];
        } else {
            if (msg.recalledStatus != RecalledAndNotSentStatus) {
                msg.recalledStatus = RecalledAndNotSentStatus;
                [[ChatMessageService sharedService] saveMessage:msg];
                [self notifyChatMessageStatus:msg];
                
                // Save the status message
                //NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
                MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                statusLog.messageId = msg.messageId;
                statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                statusLog.status = RecalledMessageStatus;
                //statusLog.qliqId = myQliqId;
                [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog];
            }
            NSString *qliqStorIds = @"";
            NSSet *qliqStors = [PushMessageToQliqStorHelper qliqStorsForMessage:msg];
            for (QliqUser *u in qliqStors) {
                qliqStorIds = [qliqStorIds stringByAppendingFormat:@"%@;", u.qliqId];
            }

            [[QliqSip sharedQliqSip] sendRecalledStatus:toContact.qliqId callId:msg.metadata.uuid serverContext:nil alsoNotify:qliqStorIds];
        }
    }
}

+ (QliqConnectModule *) sharedQliqConnectModule
{
    if (!s_instance) {
        DDLogSupport(@"s_instance is nil. Intializing QliqConnectModule");
        // Since s_instance is set inside initializer, not doing any assignment here.
        s_instance = [[QliqConnectModule alloc] init];
    }
    return s_instance;
}

- (BOOL) isOpenedStatusMessageNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    id context = userInfo[@"context"];
    int status = [userInfo[@"Status"] intValue];
    return (context == nil) && status == 220;
}

- (BOOL) isChatMessageNotification:(NSNotification *)notification
{
    id context = [notification userInfo][@"context"];
    return context && [context isKindOfClass:[ChatMessage class]];
}

-(void) deleteAttachmentsOfMessage:(ChatMessage *)msg
{
    NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMessageUuid:msg.metadata.uuid];
    for (MessageAttachment *attachment in attachments) {
        MediaFile *mediaFile = attachment.mediaFile;
        if (mediaFile) {
            [self deleteFileIfExists:mediaFile.decryptedPath fileManager:[NSFileManager defaultManager]];
            [self deleteFileIfExists:mediaFile.encryptedPath fileManager:[NSFileManager defaultManager]];
        }
        // This will delete from the media_file table also
        [[MessageAttachmentDBService sharedService] deleteAttachment:attachment];
    }
    msg.hasAttachment = NO;
    msg.attachments = nil;
}

- (void) notifyChatMessageStatus:(ChatMessage *)message
{
    
    //    NSLog(@"SIP Notification: message (%d: \"%@\") have status: %d",message.messageId, message.text, message.deliveryStatus);
    
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:message forKey:@"Message"];
    [NSNotificationCenter postNotificationToMainThread:ChatMessageStatusNotification userInfo:userinfo];
    
}

- (void) notifyChatMessageAttachmentStatus:(MessageAttachment *)attachment
{
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:attachment forKey:@"Attachment"];
    [NSNotificationCenter postNotificationToMainThread:ChatMessageStatusNotification userInfo:userinfo];
}

- (void) notifyNewChatMessagesWithConversation:(Conversation *) conversation
{
    [ChatMessage updateUnreadCountAsync];
    [NSNotificationCenter postNotificationToMainThread:NewChatMessagesNotification withObject:conversation];
}

-(BOOL) sendAck:(ChatMessage *)message
{
    
    DDLogSupport(@"Trying to send ACKNOWLEGEMENT for message with uuid: %@, from: %@, to: %@, in conversation: %ld", message.metadata.uuid, message.fromQliqId, message.toQliqId, (long)message.conversationId);
    // Since QliqSip uses its own bg thread we don't need to call this on main thread anymore
//    if (![NSThread isMainThread]) {
//        [self performSelectorOnMainThread:@selector(sendAck:) withObject:message waitUntilDone:YES];
//        return;
//    }
    
    //Check if message already sending
    for (ChatMessage * _tmpMessage in self.sentAcks){
        if (_tmpMessage.messageId == message.messageId && _tmpMessage.deliveryStatus == 0){
            //            NSLog(@"SIP Notification: ack already in sending process. Aborting retrying.");
            return YES;
        }
    }
    //mark message as sending
    //message.deliveryStatus = 0;
    

    NSString *qliqId = message.fromQliqId;
    SipContactDBService *sipContactService = [[SipContactDBService alloc] init];
    SipContact *toContact = [sipContactService sipContactForQliqId:qliqId];
    if ([toContact.sipUri length] == 0) {
        DDLogError(@"Cannot send message ack: Cannot find SIP URI for qliq id: %@", qliqId);
        return NO;
    }
    BOOL isSenderSync = NO;
    if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
        if (message.selfDeliveryStatus / 100 != 2) {
            isSenderSync = YES;
            toContact = [sipContactService sipContactForQliqId:[UserSessionService currentUserSession].user.qliqId];
        }
    }
#ifndef SENDER_PUSHES_TO_QLIQSTOR
    // Tkt #708 the sender doesn't push the message anymore
    message.ackSentAt = [[NSDate date] timeIntervalSince1970];
    [[ChatMessageService sharedService] saveMessage:message];
#else
    message.ackSentAt = [[NSDate date] timeIntervalSince1970];
    //    message.metadata.isRevisionDirty = NO; // // the recipient doesn't push to qliqStor
    //    message.metadata.author = [Helper getMyQliqId];
    [[ChatMessageService sharedService] saveMessage:message];
	
    //[self pushMessageToDataServer:message];
#endif
    
    if (![[QliqSip sharedQliqSip] isMultiDeviceSupported] || isSenderSync) {
        // Save the status message
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = message.messageId;
        statusLog.timestamp = message.ackSentAt;
        statusLog.status = SendingAckMessageStatus;
        [self.statusLogDbService saveMessageStatusLog:statusLog];
    }
    
    NSDictionary* dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              message.metadata.uuid, EXTENDED_CHAT_ACKNOWLEDGEMENT_DATA_MESSAGE_ID,
                              nil];
    
    NSDictionary* messageDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 dataDict, EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_DATA,
                                 EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_TYPE_PATTERN, EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_TYPE,
                                 EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_COMMAND_PATTERN, EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_COMMAND,
                                 EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_SUBJECT_PATTERN, EXTENDED_CHAT_ACKNOWLEDGEMENT_MESSAGE_SUBJECT,
                                 nil];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              messageDict, EXTENDED_CHAT_MESSAGE_MESSAGE,
                              nil];
    
    [self.sentAcks addObject:message];
    NSString *myDisplayName = [[UserSessionService currentUserSession].user displayName];
    NSString *callId = [@"ac-" stringByAppendingString:message.metadata.uuid];

    NSMutableDictionary *extraHeaders = [[NSMutableDictionary alloc] init];
    if (!isSenderSync) {
        [extraHeaders setObject:@"acked" forKey:@"X-status"];
        if (message.serverContext)
            [extraHeaders setObject:message.serverContext forKey:@"X-server-context"];
    }

    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:message.conversationId]];
    if ([conversation.uuid length] > 0) {
        [extraHeaders setObject:conversation.uuid forKey:@"X-conversation-uuid"];
    }
    
   BOOL res = [[QliqSip sharedQliqSip] sendMessage:[jsonDict JSONString] toQliqId:toContact.qliqId withContext:message offlineMode:YES pushNotify:NO withDisplayName:myDisplayName withCallId:callId withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:extraHeaders withMessageStatusChangedBlock:nil];
    
    return res;
}

- (void) resendOneUndeliveredMessage
{
    if (resendingMessageId != 0) {
        // Already waiting for status change for a previous resent message
        return;
    }
    
    if ([[QliqSip sharedQliqSip] pendingMessagesCount] > 0) {
        DDLogSupport(@"Not resending messages because message dump is in progress");
        return;
    }
    
    int offset = 0;
    
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredMessagesWithStatusNotIn:permanentFailureStatusSet toQliqId:nil limit:1 offset:offset];
        if ([messages count] == 0) {
            //DDLogSupport(@"No (more) messages to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        
        if ([msg.toQliqId length] == 0) {
            DDLogSupport(@"Skipping undelivered message because to qliq id is empty (%ld, %@)", (long)msg.messageId, msg.metadata.uuid);
            offset++;
            msg = nil;
            continue;
        }

        
        for (ChatMessage *sentMsg in self.sentChatMessages) {
            if (sentMsg.messageId == msg.messageId) {
                DDLogSupport(@"Skipping undelivered message because it is already being sent (%ld, %@)", (long)msg.messageId, msg.metadata.uuid);
                offset++;
                msg = nil;
                break;
            }
        }
        
        for (MessageAttachment *attachment in msg.attachments) {
            if (attachment.status == AttachmentStatusUploading) {
                DDLogSupport(@"Skipping undelivered message because it attachment uploading progress");
                offset++;
                msg = nil;
                break;
            }
        }
        
        if (msg != nil) {
            DDLogSupport(@"Resending message to: %@, id: %ld, call-id: %@", msg.toQliqId, (long)msg.messageId, msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            resendingMessageStatusUuid = nil;
            [self sendMessage:msg];
            break;
        }
    }
    
    if (resendingMessageId != 0) {
        return;
    }
    
    // If no more messages to resend then check for acks to resend
    offset = 0;
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredAcksFromQliqId:nil limit:1 offset:offset];
        if ([messages count] == 0) {
            //DDLogSupport(@"No (more) acks to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        for (ChatMessage *sentAck in self.sentAcks) {
            if (sentAck.messageId == msg.messageId) {
                DDLogSupport(@"Skipping undelivered ack because it is already being sent (%ld, ac-%@)", (long)msg.messageId, msg.metadata.uuid);
                offset++;
                msg = nil;
                break;
            }
        }
        if (msg != nil) {
            DDLogSupport(@"Resending ack to: %@, id: %ld, call-id: ac-%@", msg.toQliqId, (long)msg.messageId, msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            resendingMessageStatusUuid = nil;
            [self sendAck:msg];
            break;
        }
    }
    
    if (resendingMessageId != 0) {
        return;
    }
    
    // If no more asks to resend then check for opened status
    offset = 0;
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredOpenedStatusWithLimit:1 offset:offset];
        if ([messages count] == 0) {
            //DDLogSupport(@"No (more) opened status to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        if (msg != nil) {
            DDLogSupport(@"Resending opened status call-id: %@", msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            resendingMessageStatusUuid = msg.metadata.uuid;
            [self sendOpenedStatus:msg];
            break;
        }
    }
    
    if (resendingMessageId != 0) {
        return;
    }
    
    // Check for deleted status
    offset = 0;
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredDeletedStatusWithLimit:1 offset:offset];
        if ([messages count] == 0) {
            //DDLogSupport(@"No (more) opened status to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        if (msg != nil) {
            DDLogSupport(@"Resending deleted status call-id: %@", msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            resendingMessageStatusUuid = msg.metadata.uuid;
            [self sendDeletedStatus:msg];
            break;
        }
    }
    
    if (resendingMessageId != 0) {
        return;
    }
    
    // Check for recalled status
    offset = 0;
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredRecalledStatusWithLimit:1 offset:offset];
        if ([messages count] == 0) {
            //DDLogSupport(@"No (more) recalled status to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        if (msg != nil) {
            DDLogSupport(@"Resending recalled status call-id: %@", msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            resendingMessageStatusUuid = msg.metadata.uuid;
            [self sendRecalledStatus:msg];
            break;
        }
    }
}

- (void) recreateFailedMultiparties
{
    /* Re-create multiparties */
    ConversationDBService * conversationDBService = [[ConversationDBService alloc] init];
    NSArray * undeliveredMPConversations = [conversationDBService getConversationsWithoutQliqId];
    for (Conversation * mpConversation in undeliveredMPConversations){
        [self createMultiPartyForConversation:mpConversation];
    }    
}

#pragma mark -
#pragma mark Attachments


- (void) downloadAttachment:(MessageAttachment *) attachment completion:(CompletionBlock)completition{
    [attachmentApiService downloadAttachment:attachment completion:completition];
}

#pragma mark -


- (void) getQliqUserForID:(NSString *) qliqID andEmail:(NSString *) email completition:(void(^)(QliqUser * user)) block{
    
    QliqUser * user = [[QliqUserDBService sharedService] getUserWithId:qliqID];
    if (user){
        if (block) block(user);
    }else{

        [[GetContactInfoService sharedService] getContactByEmail:email completitionBlock:^(QliqUser *contact, NSError *error) {
            
            DDLogInfo(@"found qliq user: %@",user);
            if (!error){
                block(user);
            }else{
                DDLogError(@"Error during 'getQliqUserForContact': %@",error);
            }
        }];
    }
    
}

- (void) sendInvitation:(Invitation *)invitation action:(InvitationAction) _action completitionBlock:(void(^)(NSError * error))block{
    
    void (^localCompletionBlock)(QliqUser *, NSError *) = ^(QliqUser *recipient, NSError *error) {
        
        if (!error) {
            
            if (recipient.status && ![recipient.status isEqualToString:QliqUserStateActive]) {
                NSString * errorDescription = [NSString stringWithFormat:@"User %@ is not \"Active\". User is \"%@\"",recipient.email,recipient.status];
                NSError * error = [NSError errorWithDomain:errorDomainForModule(@"qliqconnect") code:qliqErrorCodeUserNotActive userInfo:userInfoWithDescription(errorDescription)];
                if (block) block(error);
                return;
            }
            
            recipient.status = QliqUserStateInvitationPending;
            [[QliqUserDBService sharedService] saveUser:recipient];
            
            QliqUser * me = [UserSessionService currentUserSession].user;
            
            NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
            
            [dataDict setObject:invitation.uuid forKey:INVITATION_DATA_INVITATION_UUID];
            [dataDict setObject:invitation.url forKey:INVITATION_DATA_INVITATION_URL];
            [dataDict setObject:[me toDict] forKey:INVITATION_DATA_SENDER_INFO];
			
            NSString * action = nil;
            if (_action == InvitationActionCancel) action = INVITATION_DATA_ACTION_CANCEL;
            if (_action == InvitationActionInvite) action = INVITATION_DATA_ACTION_INVITE;
            
            if (action != nil) {
                [dataDict setObject:action forKey:INVITATION_DATA_ACTION];
            }
            
            NSDictionary* messageDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         dataDict, INVITATION_MESSAGE_DATA,
                                         INVITATION_MESSAGE_TYPE_PATTERN, INVITATION_MESSAGE_TYPE,
                                         INVITATION_MESSAGE_COMMAND_PATTERN, INVITATION_MESSAGE_COMMAND,
                                         INVITATION_MESSAGE_SUBJECT_PATTERN, INVITATION_MESSAGE_SUBJECT,
                                         nil];
            
            NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      messageDict, INVITATION_MESSAGE,
                                      nil];
            
            NSString *myDisplayName = [me displayName];
			
            SipContactDBService * sipContactDBService = [[SipContactDBService alloc] init];
            SipContact * recipientContact = [sipContactDBService sipContactForQliqId:recipient.qliqId];
            
			BOOL success = [[QliqSip sharedQliqSip] sendMessage:[jsonDict JSONString] toQliqId:recipientContact.qliqId withContext:nil offlineMode:YES pushNotify:NO withDisplayName:myDisplayName withCallId:nil withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:nil withMessageStatusChangedBlock:nil];
            
            if (success) {
                
                block(nil);
            }
            else {
                
                block([[NSError alloc] initWithDomain:@"QliqSip couldn't send message" code:0 userInfo:nil]);
            }
        } else {
            
            block(error);
        }
    };
    
    if (invitation.contact.email
        && [invitation.contact.email isKindOfClass:[NSString class]]
        && invitation.contact.email.length) {
        
        [[GetContactInfoService sharedService] getContactByEmail:invitation.contact.email
                                               completitionBlock:localCompletionBlock];
    } else if (invitation.contact.mobile
               && [invitation.contact.mobile isKindOfClass:[NSString class]]
               && invitation.contact.email.length) {
        
            [[GetContactInfoService sharedService] getContactByPhone:invitation.contact.mobile
                                                   completitionBlock:localCompletionBlock];
        } else if(invitation.contact.qliqId
                  && [invitation.contact.qliqId isKindOfClass:[NSString class]]
                  && invitation.contact.qliqId.length) {
            
            [[GetContactInfoService sharedService] getContactInfo:invitation.contact.qliqId
                                                completitionBlock:localCompletionBlock];
        }
}



+ (void)getAllContactsPaged:(dispatch_group_t)dispatchGroup
{
//    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
//    unsigned int startPage = (unsigned int)[GetContactsPaged lastSavedPageForQliqId:qliqId];
    
//    BOOL wasStopped = [GetContactsPaged getPageContactsOperationStateForQliqId:qliqId];
//
//    if (startPage > 0 && wasStopped) {
//        BOOL wasStopped = NO;
//        [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:qliqId];
//    } else {
      unsigned int startPage = 0;
//    }
    
    [GetContactsPaged getAllPagesStartingFrom:startPage completion:^(CompletitionStatus status, id result, NSError *error) {
        
        if (error || CompletitionStatusError == status) {
        
        }
        if (dispatchGroup != nil) {
            dispatch_group_leave(dispatchGroup);
        }
    }];
}

+ (void) syncContacts:(BOOL)showHUD
{
    if (showHUD) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"1916-StatusSyncing", nil) maskType:SVProgressHUDMaskTypeGradient];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    /* Updating security settings */
    LoginService * loginService = [[LoginService alloc] initWithUsername:[KeychainService sharedService].getUsername andPassword:[KeychainService sharedService].getPassword];
    [loginService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    
    /* Updating user configuration */
    // Since we are going to get all contacts below. THere is no need to get
    // Group COntacts part of getUserConfig
    //
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[GetUserConfigService sharedService] getUserConfig:NO withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            NSDictionary  *dict = (NSDictionary *)result;
            BOOL hasSipServerConfigChanged = [[dict objectForKey:SipServerConfigChangedKey] boolValue];
            if (hasSipServerConfigChanged) {
                DDLogSupport(@"SIP server config change detected (sync contacts button) trying to restart SIP");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[QliqSip sharedQliqSip] handleNetworkUp];
                });
            }
            dispatch_group_leave(group);
        }];
    });
    
    dispatch_group_enter(group);
    /* Updating users contacts. Downloading all avatars also here */
    [self getAllContactsPaged:group];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (showHUD) {
            [SVProgressHUD dismiss];
        }
    });
}

+ (void) notifyMultipartyWithQliqId:(NSString *) qliqId{
    
    Conversation *conversation = nil;

    if (qliqId) {
        NSArray *convs = [[ConversationDBService sharedService] getConversationsWithQliqId:qliqId];
        if ([convs count] > 0) {
            conversation = [convs objectAtIndex:0];
        }
    }
    
    [NSNotificationCenter postNotificationToMainThread:RecipientsChangedNotification withObject:conversation userInfo:nil];
}

+ (BOOL) wipeMediafiles{
    
    return [[MediaFileService getInstance] wipeMediafiles];
}

+ (BOOL) wipeData
{
    __block BOOL wipeSuccess = YES;

    wipeSuccess &= [[MessageAttachmentDBService sharedService] deleteAllAttachments];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        wipeSuccess &= [DBHelperConversation deleteAllMessages:db];
        wipeSuccess &= [DBHelperConversation deleteAllConversations:db];
    }];
    wipeSuccess &= [self wipeMediafiles];
    
    return wipeSuccess;
}

- (NSInteger) numberOfDaysBetweenDates :(NSDate *)d1 : (NSDate *)d2
{
    const NSInteger secondsPerMinute = 60;
    const NSInteger minutePerHour = 60;
     
    NSInteger timeInterval = [d2 timeIntervalSinceDate:d1];
    return labs(timeInterval / (secondsPerMinute * minutePerHour));
}

- (void) sendParticipantsChangedEventMessageForConversation:(Conversation *)aConversation withOldRecipients:(Recipients *) oldRecipients withNewRecipients:(Recipients *) newRecipients{

    NSString *text = [ChatEventHelper participantsChangedEventFromRecipients:oldRecipients toRecipients:newRecipients];
    
    /* Prefer to use MP qliq_id to norify deleted recipients about deletion */

    NSString * toQliqId = oldRecipients.qliqId;
    
    if ([newRecipients isMultiparty]){
        toQliqId = newRecipients.qliqId;
    }
    
    [self sendMessage:text toQliqId:toQliqId inConversation:aConversation acknowledgeRequired:NO priority:ChatMessagePriorityNormal type:ChatMessageTypeEvent];
}

- (void) setMessageRetentionPeriod:(int)periodInSeconds
{
    const int secondsPerDay = 60 * 60 * 24;
    if (periodInSeconds < secondsPerDay) {
        periodInSeconds = 0;
    }
    messageRetentionPeriod = periodInSeconds;
}

- (void) deleteFileIfExists:(NSString *)path fileManager:(NSFileManager *)fileManager
{
    NSError *error;
    
    if ([fileManager fileExistsAtPath:path]) {
        BOOL success = [fileManager removeItemAtPath:path error:&error];
        if (!success) {
            DDLogError(@"Cannot delete file: %@: %@", path, [error localizedDescription]);
        }
    }
}

- (void)deleteOldMessages {
    dispatch_async_background(^{
    // • Check if retention period > 0
    if (messageRetentionPeriod <= 0)
        return;
    
    DDLogSupport(@"Deleting old messages");

    // • Get timeinterval
    NSDate *dt = [[NSDate date] dateByAddingTimeInterval:-messageRetentionPeriod];
    NSTimeInterval timestamp = [dt timeIntervalSince1970];

    DDLogSupport(@"Message retantion period: %@", dt);
  
    [[DBUtil sharedQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        // • Delete orphaned media files
//        [[[MediaFileDBService alloc] initWithDatabase:db] deleteMediaFilesWithoutAttachments]; // Commented it because to avoid deleting media files if the user creates it customly beyond chats
        
        // • Delete Media Files Upon Expired Data
        if ([[QliqStorage sharedInstance].deleteMediaUponExpiryKey boolValue] == YES) {
            [[[MediaFileDBService alloc] initWithDatabase:db] deleteMediaFilesOlderThan:timestamp];
        }
        
        // • This is lower level table/concept but so far there is no better place to call it.
        [[[EncryptedSipMessageDBService alloc] initWithDatabase:db] deleteOlderThen:timestamp];
        
        // • Delete Received PushNotification
        [ReceivedPushNotificationDBService deleteOlderThen:timestamp];
     
        // • Delete ChatMessages
        MessageAttachmentDBService *attachmentDbService = [[MessageAttachmentDBService alloc] initWithDatabase:db];

        // Get ids of the messages that are old enough and not dirty (are pushed to qliqStor)
        NSArray *messageIds = [[ChatMessageService sharedService] getMessageIdsOlderThenAndNotDirty:timestamp inDB:db];
       
        for (NSNumber *messageIdNum in messageIds)
        {
            int messageId = [messageIdNum intValue];
            NSString *uuid = [[ChatMessageService sharedService] uuidForMessageId:messageId];

            // 1. First delete attachments
            NSArray *attachments = [attachmentDbService getAttachmentsForMessageUuid:uuid];
            for (MessageAttachment *attachment in attachments)
            {
                [attachmentDbService deleteAttachment:attachment];
            }
            
            // 2. Delete status log for that message
            [[MessageStatusLogDBService sharedService] deleteWithMessageId:messageId inDB:db];
            
            // 3. Delete message's qliqstor status (it shouldn't exist for the message, but just in case)
            [MessageQliqStorStatusDBService deleteRowsForMessageId:messageId];
            
            // 4. Delete the message itself
            [[ChatMessageService sharedService] deleteWithMessageId:messageId];
        }
        
        // 5. Delete conversations that became empty now
        NSArray *conversations = [[ConversationDBService sharedService] getConversationsWithoutMessages];
        for (Conversation *conv in conversations) {
            // 6. It was a mp conversation, then ConversationDBService should automatically
            // delete the recipients and sip_contact rows.
            
            [[ConversationDBService sharedService] deleteConversationButNotMessages:conv];
            
            // Notify the UI if by any chance this conversation is displayed
            [self notifyConversationDeleted:conv.conversationId];
        }
        
        // 7. There can be conversations with old messages ONLY (< timestamp) that are non empty
        // because some of the message aren't pushed to qliqStor yet.
        // We should probably set a status to archived or deleted.
        //
        // Take care of messages that are old but not pushed
        [[ChatMessageService sharedService] markAsDeletedMessagesOlderThenAndDirty:timestamp];

        // 8. There can be conversations with old messages ONLY (all deleted=1) that are non empty
        // because some of the messages aren't pushed to qliqStor yet.
        // We should probably set a status to archived or deleted.
        conversations = [[ConversationDBService sharedService] getConversationsWithOnlyDeletedMessages];
        for (Conversation *conv in conversations) {
            if (conv.createdAt < timestamp) {
                [[ConversationDBService sharedService] setDeleteFlag:YES forConversationId:conv.conversationId];
                
                // Notify the UI if by any chance this conversation is displayed
                [self notifyConversationDeleted:conv.conversationId];
            }
        }
        
        // Update unread badge since unread messages could be just deleted
        [ChatMessage updateUnreadCountInDb:db];
    }];
        
    });
}

- (void)notifyConversationDeleted:(NSInteger)conversationId
{
    NSDictionary *userInfo = @{@"conversationId": [NSNumber numberWithInteger:conversationId]};
    [NSNotificationCenter postNotificationToMainThread:ConversationDeletedNotification userInfo:userInfo];
}

- (NSTimeInterval) parseAtTimeFromExtraHeader:(NSDictionary *)extraHeaders name:(NSString *)headerName wasFound:(BOOL *)found
{
    NSTimeInterval ret = 0;
    *found = NO;
    NSString *headerValue = [extraHeaders objectForKey:headerName];
    if ([headerValue length] > 0) {
        NSString *atStr = [QliqSip captureRegExp:headerValue withPattern:@"at=(\\d+);"];
        if ([atStr length] > 0) {
            ret = [atStr longLongValue];
            ret += [[QliqSip sharedQliqSip] serverTimeDelta];
            *found = true;
        }
    }
    return ret;
}

@end

@implementation GetSipContactContext

@synthesize isAwaitingResponse;
@synthesize qliqId;
@synthesize probableContactType;
@synthesize lastTriedContactType;
@synthesize completion;
@synthesize chatMessage;
@synthesize isGetPrivateKeyAction;
@synthesize triedServices;

@end

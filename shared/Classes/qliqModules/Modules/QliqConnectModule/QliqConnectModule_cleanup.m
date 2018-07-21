//
//  QliqConnectModule.m
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
#import "UserNotifications.h"
#import "Log.h"
#import "NSThread_backtrace.h"
#import "ChatMessageTypeSchema.h"
#import "Metadata.h"
#import "Outbound.h"
#import "Inbound.h"
#import "DBHelperConversation.h"
#import "DBPersist.h"
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
#import "BuddyList.h"
#import "Invitation.h"
#import "MediaFile.h"
#import "FindQliqUser.h"
#import "QliqUserDBService.h"
#import "InvitationService.h"
#import "ContactDBService.h"
#import "ChangeNotificationSchema.h"
#import "GetGroupInfoService.h"
#import "GetContactInfoService.h"
#import "KeychainService.h"
#import "DeviceStatusController.h"
#import "PushMessageToQliqStorHelper.h"
#import "CreateMultiPartyService.h"
#import "QliqGroupDBService.h"
#import "GetMultiPartyService.h"
#import "SipContactDBService.h"
#import "CreateMultiPartyService.h"
#import "RecipientsDBService.h"

#import "ModifyMultiPartyService.h"
#import "MediaFileService.h"
#import "ChatEventHelper.h"
#import "ChatEventMessageSchema.h"
#import "EncryptedSipMessageDBService.h"
#import "ChatMessageService.h"
#import "MessageQliqStorStatusDBService.h"
#import "GetPresenceStatusService.h"
#import "GetSecuritySettingsService.h"
#import "GetGroupKeyPair.h"
#import "QliqGroupDBService.h"
#import "GetQuickMessagesService.h"
#import "GetAllContacts.h"
#import "MediaFileDBService.h"
#import "UIDevice+UUID.h"

// Only the sender pushes message to qliqStor
#define SENDER_PUSHES_TO_QLIQSTOR 1

// The UI will be notified about new chat messages pulled from qliqStor if the count exceeds this threshold
#define PULLED_MESSAGES_NOTIFICATION_THRESHOLD 5
#define SIP_UNDECIPHERABLE_STATUS 493
#define QLIQSTOR_NOTIFY_IMPLEMENTATION 1

static QliqConnectModule *s_instance;

NSString *ChatMessageStatusNotification = @"ChatMessageStatus";
NSString *NewChatMessagesNotification = @"NewChatMessages";
NSString *ChatMessageAttachmentStatusNotification = @"ChatMessageAttachmentStatus";
NSString *RecipientsChangedNotification = @"RecipientsChangedNotification";
NSString *ConversationDeletedNotification = @"ConversationDeletedNotification";
NSString *PresenceChangeStatusNotification = @"PresenceChangeStatusNotification";

extern NSString* DBHelperConversationDidReadMessages;

@interface QliqConnectModule()

- (void) processExtendedChatMessage:(QliqSipExtendedChatMessage*)message;
- (void) processChatUpdateResponseMessage:(QliqSipMessage *) message;
- (void) sipSendMessage: (ChatMessage *)message;
- (void) sipSendMessage: (ChatMessage *)message inDB:(FMDatabase*)database;
- (void) sendOpenedStatus: (ChatMessage *)message;

- (void) pushMessageToDataServer:(ChatMessage *)message;
- (void) notifyChatMessageStatus:(ChatMessage *)message;
- (void) notifyChatMessageAttachmentStatus:(MessageAttachment *)attachment;
- (void) notifyChatAck:(ChatMessage *)message withSound:(BOOL)playSound;
- (void) notifyNewChatMessages;
- (void) notifyNewChatMessagesWithConversation:(Conversation *) conversation inDB:(FMDatabase*) database;
- (void) notifyConversationDeleted:(int)conversationId;
- (BOOL) processPublicKey:(NSDictionary *)dataDict;

- (void) processMessageStatus:(ChatMessage *)mmsg status:(int)status callId:(NSString *)aCallId qliqId:(NSString *)aQliqId deliveredRecipientCount:(int)aDeliveredRecipientCount totalRecipientCount:(int)aTotalRecipientCount deliveredAt:(long)aDeliveredAt;
- (void) processPermanentErrorMessageStatus:(NSInteger)status toQliqId:(NSString *)toQliqId;
- (void) processMessageStatusNotification:(NSNotification *)notification;
- (void) processPendingMessageStatusNotification:(NSNotification *)notification;
-(void) processOpenedMessageStatusNotification:(NSNotification *)notification;
- (void) processInvitation:(NSDictionary *)data;

//Processing notifications
- (void) processSipConfigChange;
- (void) processUserChangeNotification:(NSString *)qliqId;
- (void) processGroupChangeNotification:(NSString *)qliqId;
- (void) processDeviceChangeNotification:(NSString *)uuid;
- (void) processApplicationChangeNotification:(NSString *)version;
- (void) processLoginCredentialsNotification:(NSString *)qliqId;
- (void) processMultiPartyChangeNotification:(NSString *)qliqId;
- (void) processPresenceChangeNotification:(NSString *)qliqId;
- (void) processQuickMessagesChangeNotification:(NSString *)qliqId;

// Resending messages
- (void) onBuddyStatusChanged:(NSNotification *)notification;
- (void) resendUndeliveredMessagesForQliqId: (NSString *)qliqId;
- (void) resendUndeliveredAcksForQliqId: (NSString *)qliqId;
- (void) resendUndeliveredMessagesAndAcksForQliqId: (NSString *)qliqId;
- (void) resendUndeliveredMessagesForQliqId: (NSString *)qliqId inDB:(FMDatabase*)database;
- (void) resendUndeliveredAcksForQliqId: (NSString *)qliqId inDB:(FMDatabase*)database;
- (void) resendUndeliveredMessagesAndAcksForQliqId: (NSString *)qliqId inDB:(FMDatabase*)database;
- (void) resendOneUndeliveredMessage;
//- (void) resendUndeliveredMessagesAndAcks;
- (void) initiateResendingOfUndeliveredMessages;
- (void) recreateFailedMultiparties;

- (NSInteger) numberOfDaysBetweenDates:(NSDate *)d1 :(NSDate *)d2;
- (void) onPrivateKeyNeeded:(NSNotification *)notification;
- (void) onRegInfoReceivedNotification:(NSNotification *)notification;
- (void) onMessageDumpFinished:(NSNotification *)notification;
- (NSTimeInterval) parseAtTimeFromExtraHeader:(NSDictionary *)extraHeaders name:(NSString *)headerName wasFound:(BOOL *)found;
- (void) getMultipartyFromWebservice:(NSString *)qliqId;

@property (nonatomic, strong) MessageAttachmentApiService *attachmentApiService;
@property (nonatomic, strong) ChatMessageService *chatMessageService;
@property (nonatomic, strong) MessageStatusLogDBService *statusLogDbService;
@property (nonatomic, assign) dispatch_queue_t qliqConnectDispatchQueue;

@end

@implementation QliqConnectModule
@synthesize attachmentApiService;
@synthesize attachmentDelegate;
@synthesize chatMessageService;
@synthesize statusLogDbService;
@synthesize lastQliqStorPushDate;

-(id) init
{
    self = [super init];
    if(self)
    {
        self.name = QliqConnectModuleName;
        sentChatMessages = [[NSMutableSet alloc] init];
        sentAcks = [[NSMutableSet alloc] init];
        sentAttachments = [[NSMutableDictionary alloc] init];
        s_instance = self;
        messagesToUnknownUsersByQliqId = [[NSMutableDictionary alloc] init];
        
        attachmentApiService = [[MessageAttachmentApiService alloc] init];
        statusLogDbService = [[MessageStatusLogDBService alloc] init];
        chatMessageService = [ChatMessageService sharedService];
        
        NSString *qliqId = [Helper getMyQliqId];
        if ([qliqId length] > 0)
        {
            [DBHelperConversation markAllSendingMessagesAsTimedOutForUser:qliqId inDB:[DBUtil sharedDBConnection]];
        }
        
        qliqStorPusher = [[PushMessageToQliqStorHelper alloc] init];
        [qliqStorPusher setQliqStorClient:[DataServerClient sharedDataServerClient]];
        
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
												 selector: @selector(onRegInfoReceivedNotification:)
													 name: SIPRegInfoReceivedNotification
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onMessageDumpFinished:)
                                                     name: SipMessageDumpFinishedNotification
                                                   object: nil];
        
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onBuddyStatusChanged:)
													 name: SIPBuddyStateNotification
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(removeNotificationObserver)
                                                     name: @"RemoveNotifications"
                                                   object: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onPrivateKeyNeeded:)
													 name: SIPPrivateKeyNeededNotification
												   object: nil];
        
        self.qliqConnectDispatchQueue = dispatch_queue_create("qliqconnect.queue", NULL);
        
        [ChatMessage updateUnreadCountInDb:[DBUtil sharedDBConnection]];
    }
    return self;
    
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void) dealloc
{
	dispatch_release(self.qliqConnectDispatchQueue);

    //    [attachmentApiService release];
    //    [attachmentDbService release];
    //	[statusLogDbService release];
    //    [conversationService release];
    [self removeNotificationObserver];
    //    [sentChatMessages release];
    //    [sentAcks release];
    //    [sentAttachments release];
    //    [pushedMessage release];
    //    [super dealloc];
}

-(UIImage *) moduleLogo
{
    return [UIImage imageNamed:@"qliqConnect_logo.png"];
}

/* Update qliq_id for messages in conversation with recipients.qliq_id and resend */
- (void) resendMessagesForMPConversation:(Conversation *) conversation{
    
    NSArray * messages = [DBHelperConversation getMessagesForConversation:conversation.conversationId limit:-1];
    NSString *mpQliqId = conversation.recipients.qliqId;
    BOOL error = ([mpQliqId length] == 0);
    
    for (ChatMessage * message in messages){
        
        if ([message.toQliqId length] == 0) {
            if (!error) {
                message.toQliqId = mpQliqId;
                [self sendMessage:message];
            } else {
                BOOL isBeginSent = NO;
                for (ChatMessage *sentMsg in sentChatMessages) {
                    if (sentMsg.messageId == message.messageId) {
                        isBeginSent = YES;
                        break;
                    }
                }
                
                if (!isBeginSent) {
                    [sentChatMessages addObject:message];
                }
                
                [self processMessageStatus:message status:503 callId:message.metadata.uuid qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
            }
        }
    }
}

/* Create Mutliparty via service and resend messages */
- (void) createMultiPartyForConversation:(Conversation *) multipartyConversation
{
    if (![CreateMultiPartyService hasOutstandingRequestForConversationId:multipartyConversation.conversationId]) {
        CreateMultiPartyService * createService = [[CreateMultiPartyService alloc] initWithRecipients:multipartyConversation.recipients andConversationId:multipartyConversation.conversationId];
        
        [createService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            DDLogInfo(@"Multiparty created. QliqId: %@, error: %@", result, error);
            
            /* Resending messages with received qliq_id */
            [self resendMessagesForMPConversation:multipartyConversation];
        }];
    }
}

/* Trying to get conversation with recipients and subject */
- (Conversation *) conversationWithRecipients:(Recipients *) recipients andSubject:(NSString *) subject{
    
    Conversation * conversation = nil;
    
    if ([recipients isSingleUser] || [recipients isGroup]){
        
        NSInteger conversationId = [DBHelperConversation getConversationId:recipients.qliqId andSubject:subject];
        if (conversationId != 0){
            conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:conversationId]];
        }
    }
    return conversation;
}

- (Conversation *) newConversationWithRecipients:(Recipients *) recipients subject:(NSString *) subject{
    
    Conversation *newConversation = [[Conversation alloc] initWithPrimaryKey:0];
	newConversation.subject = subject;
    newConversation.recipients = recipients;
    newConversation.uuid = [Metadata generateUuid];
    
    if (![[ConversationDBService sharedService] saveConversation:newConversation]){
        newConversation = nil;
    }
    
    return newConversation;
}

/* General method to create conversation */
- (Conversation *) createConversationWithRecipients:(Recipients *) recipients subject:(NSString *)subject{
    
    /* Trying to get existing conversation */
    Conversation * conversation = [self conversationWithRecipients:recipients andSubject:subject];
    
    if (!conversation){
        
        conversation = [self newConversationWithRecipients:recipients subject:subject];
        
        if (conversation && [recipients isMultiparty]){
            /* Create Multiparty via service */
            [self createMultiPartyForConversation:conversation];
        }
        
    }
    
    return conversation;
}

- (void) setRecipients:(Recipients *) recipients toConversation:(Conversation *) conversation{
    
    ConversationDBService * conversationDBService = [[ConversationDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
    RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
    
    /* Remove old recipients to replace with new one */
    [recipientsDBService deleteObject:conversation.recipients mode:(DBModeToMany | DBModeToOne) completion:nil];

    /* Send changed event */
    [self sendParticipantsChangedEventMessageForConversation:conversation withNewRecipients:recipients];

    conversation.recipients = recipients;
    
    /* Save conversation with new recipients */
    [conversationDBService saveConversation:conversation];
}

- (void)modifyConversation:(Conversation *)conversation byRecipients:(Recipients *)newRecipients andSubject:(NSString *)newSubject complete:(CompletionBlock)complete{
    
    ConversationDBService * conversationDBService = [[ConversationDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
    
    BOOL recipientsChanged = ![newRecipients isEqual:conversation.recipients];
    BOOL subjectChanged = ![newSubject isEqualToString:conversation.subject];
    
    /* Nothing changes */
    if (!recipientsChanged && !subjectChanged){
        /* Return as is */
        if (complete) complete(CompletitionStatusSuccess, conversation, nil);
    }
    /* Subject changed - create a new conversation */
    else if (subjectChanged){
        conversation = [[QliqConnectModule sharedQliqConnectModule] createConversationWithRecipients:newRecipients subject:newSubject];
        [conversationDBService saveConversation:conversation];
        if (complete) complete(CompletitionStatusSuccess, conversation, nil);
    }
    /* MP -> MP */
    else if ([conversation.recipients isMultiparty] && [newRecipients isMultiparty]){
        
        ModifyMultiPartyService * modifyMPService = [[ModifyMultiPartyService alloc] initWithRecipients:conversation.recipients modifiedRecipients:newRecipients];
        [modifyMPService callServiceWithCompletition:^(CompletitionStatus status, Recipients * result, NSError *error) {

            if (status == CompletitionStatusSuccess){
                [self setRecipients:result toConversation:conversation];
            }
            if (complete) complete(status, conversation, error);
        }];
    }
    /* SP -> MP */
    else if ([newRecipients isMultiparty]){
        
        CreateMultiPartyService * createService = [[CreateMultiPartyService alloc] initWithRecipients:newRecipients andConversationId:conversation.conversationId];
        
        [createService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess){
                [self setRecipients:newRecipients toConversation:conversation];
            }
            if (complete) complete(status, conversation, error);
        }];
    }
    /* else: SP -> SP OR MP -> SP */
    else{
        [self setRecipients:newRecipients toConversation:conversation];
        if (complete) complete(CompletitionStatusSuccess, conversation, nil);
    }

    
}

#pragma mark -
#pragma mark Protected

-(BOOL) handleSipMessage:(QliqSipMessage *)message
{
    BOOL result = NO;
    
	
    if ([message.command compare:EXTENDED_CHAT_MESSAGE_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
        [message.subject compare:EXTENDED_CHAT_MESSAGE_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        QliqSipExtendedChatMessage *chatMessage = (QliqSipExtendedChatMessage*)message;
        [self processExtendedChatMessage:chatMessage];
        result = YES;
    }
    else if ([message.command compare:GET_PUBLICKEY_RESPONSE_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
             [message.subject compare:GET_PUBLICKEY_RESPONSE_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        NSDictionary *dataDict = (NSDictionary *)message.data;
        [self processPublicKey:dataDict];
        result = YES;
    }
    else if ([message.command compare:INVITATION_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
             [message.subject compare:INVITATION_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        NSDictionary *dataDict = (NSDictionary *)message.data;
        [self processInvitation:dataDict];
        result = YES;
    }
    else if ([message.command compare:CHANGE_NOTIFICATION_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
             [message.type compare:CHANGE_NOTIFICATION_MESSAGE_TYPE_PATTERN] == NSOrderedSame)
    {
        NSDictionary *dataDict = (NSDictionary *)message.data;
        NSString *qliqId = [dataDict objectForKey:CHANGE_NOTIFICATION_DATA_QLIQ_ID];
        
        if ([message.subject compare:@"user"] == NSOrderedSame) {
            [self processUserChangeNotification: qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"group"] == NSOrderedSame) {
            [self processGroupChangeNotification: qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"device"] == NSOrderedSame) {
            NSString *uuid = [dataDict objectForKey:@"device_uuid"];
            [self processDeviceChangeNotification: uuid];
            result = YES;
        }
        else if ([message.subject compare:@"application"] == NSOrderedSame) {
            NSString *version = [dataDict objectForKey:@"version"];
            [self processApplicationChangeNotification: version];
            result = YES;
        }
        else if ([message.subject compare:@"login_credentials"] == NSOrderedSame) {
            [self processLoginCredentialsNotification:qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"multiparty"] == NSOrderedSame) {
            [self processMultiPartyChangeNotification:qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"presence"] == NSOrderedSame) {
            [self processPresenceChangeNotification:qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"security_settings"] == NSOrderedSame) {
            NSString *deviceUuid = [[UIDevice currentDevice] uuid];
            [self processSecuritySettingsNotification:deviceUuid];
            result = YES;
        }
        else if ([message.subject compare:@"quick_messages"] == NSOrderedSame) {
            [self processQuickMessagesChangeNotification:qliqId];
            result = YES;
        }
        else if ([message.subject compare:@"invitation-response"] == NSOrderedSame) {
            [self processInvitationResponse:message.data];
            result = YES;
        }
        else if ([message.subject compare:@"invitation-request"] == NSOrderedSame) {
            [self processInvitationRequest:message.data];
            result = YES;
        }
    }
    DDLogSupport(@"QliqConnect received message, command: '%@', subject: '%@'", message.command, message.subject);
    [self resendOneUndeliveredMessage];
    
    return result;
}

-(void) onSipRegistrationStatusChanged:(BOOL)registered status:(NSInteger)status isReRegistration:(BOOL)reregistration
{
    
    if (registered && [QliqSip sharedQliqSip].lastRegistrationResponseCode==200 &&
        (![[QliqSip sharedQliqSip] isMultiDeviceSupported] || wasRegInfoReceived))
    {
        DDLogInfo(@"Registration changed to on and successful, resending messages");
        
        [self recreateFailedMultiparties];
        [self resendOneUndeliveredMessage];
        //[self initiateResendingOfUndeliveredMessages];
        
        if (!lastQliqStorPushDate || [self numberOfDaysBetweenDates:lastQliqStorPushDate: [NSDate date]] > 0)
        {
            lastQliqStorPushDate = [NSDate date];
            [qliqStorPusher startPushing];
        }
    }
    
}

- (void) onRegInfoReceivedNotification:(NSNotification *)notification
{
    wasRegInfoReceived = YES;
    [self onSipRegistrationStatusChanged:YES status:200 isReRegistration:NO];
}

- (void) onMessageDumpFinished:(NSNotification *)notification
{
    NSNumber *error = notification.userInfo[@"error"];
    if ([error boolValue] == NO && [UserSessionService isOfflineDueToBatterySavingMode] == NO) {
        [self resendOneUndeliveredMessage];
    }
}

#pragma mark -
#pragma mark Private

static NSUInteger attempt = 0;
static NSUInteger maxAttempts = 3;

- (void) getAllContactsAndTryProcessMessage:(QliqSipExtendedChatMessage *)sipMessage{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[GetAllContacts sharedService] getAllContactsWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            if (error){
                DDLogError(@"Error during getting all contacts: %@",error);
            }
            
            if (attempt < maxAttempts){
                attempt += 1;
                [self processExtendedChatMessage:sipMessage];
            }else{
                DDLogError(@"Error: QliqId for sip URI %@ is NIL, after trying 'getAllContacts' call %d times",sipMessage.fromUri,attempt);
            }
        }];
    });
}

- (NSString *) extractSipUriFromString:(NSString *) sipContainedString{

    NSString * sipString = [sipContainedString stringByReplacingOccurrencesOfString: @"sip:" withString: @""];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    return [sipString stringByTrimmingCharactersInSet:charSet];

}

/* clean code went away. TODO: Refactor into small obvious methods */
- (Conversation *) conversationForReceivedMessage:(QliqSipExtendedChatMessage *) sipMessage fromQliqId:(NSString *) recipients_qliqId mySipUri:(NSString *)mySipUri
{
    Conversation * conversation = nil;
    
    NSInteger existingConversationId = 0;
    
    if ([sipMessage.conversationUuid length] > 0) {
        conversation = [[ConversationDBService sharedService] getConversationWithUuid:sipMessage.conversationUuid];
        if (conversation != nil) {
            existingConversationId = conversation.conversationId;
        } else {
            if ([sipMessage.fromUri isEqualToString:mySipUri]) {
                // Sender sync message
                existingConversationId = [DBHelperConversation getLastUpdatedConversationId:recipients_qliqId andSubject:sipMessage.conversationSubject inDB:[DBUtil sharedDBConnection]];
                if (existingConversationId > 0) {
                    conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInt:existingConversationId]];
                    conversation.uuid = sipMessage.conversationUuid;
                    [[ConversationDBService sharedService] saveConversation:conversation];
                    DDLogSupport(@"Updated (sender sync) uuid for old conversation id: %d, uuid: %@", conversation.conversationId, conversation.uuid);
                }
            }
            
            if (existingConversationId == 0) {
                // -1 means don't look for existing based on recipient and subject
                existingConversationId = -1;
            }
        }
    }
    
    RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
    
    /* If event occured */
    if ([ChatMessage typeFromString:sipMessage.dataType] == ChatMessageTypeEvent){
      
        NSDictionary * event = [ChatEventHelper eventDictFromString:sipMessage.messageText];
        
        NSString * qliq_id_before = event[CHAT_EVENT_MESSAGE_RECIPIENT_QLIQ_ID_BEFORE];
        
        if (existingConversationId == 0) {
            /* Get current conversation */
            existingConversationId = [DBHelperConversation getLastUpdatedConversationId:qliq_id_before andSubject:sipMessage.conversationSubject inDB:[DBUtil sharedDBConnection]];
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
            existingConversationId = [DBHelperConversation getLastUpdatedConversationId:recipients_qliqId andSubject:sipMessage.conversationSubject inDB:[DBUtil sharedDBConnection]];
        }
    }
    
    /* Create new one */
    if (existingConversationId <= 0) {
        conversation = [[Conversation alloc] initWithPrimaryKey:0];
        conversation.subject = sipMessage.conversationSubject;
        conversation.uuid = sipMessage.conversationUuid;
    }else{
        conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:existingConversationId]];
    }
    
    /* If haven't recipients object or have but with incorrect qliq_id, then reload from db new one */
    if (!conversation.recipients || ![conversation.recipients.qliqId isEqualToString:recipients_qliqId]){

        /* remove existing recipients to replace with new */
        if (conversation.recipients) {
            [recipientsDBService deleteObject:conversation.recipients mode:DBModeToMany | DBModeToOne completion:nil];
        }
        
        /* Try to load existing recipients for qliq_id (usually for MP) */
        conversation.recipients = [recipientsDBService recipientsWithQliqId:recipients_qliqId];
        
        /* If loaded SP recipients - remove to create new */
        if (conversation.recipients && ![conversation.recipients isMultiparty]){
            conversation.recipients = nil;
        }
        
        /* .. or create new with one recipient (for SP) */
        if (!conversation.recipients){
            conversation.recipients = [[Recipients alloc] init];
            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:recipients_qliqId];
            if (user != nil) {
                [conversation.recipients addRecipient:user];
            } else {
                QliqGroup *group = [[QliqGroupDBService sharedService] getGroupWithId:recipients_qliqId];
                if (group != nil) {
                    [conversation.recipients addRecipient:group];
                } else {
                    DDLogError(@"Cannot determine recipient for new conversation, qliq id: %@", recipients_qliqId);
                }
            }
        }
        
        [[ConversationDBService sharedService] saveConversation:conversation];
        /* Post notification to update UI */
        [self notifyMultipartyWithQliqId:recipients_qliqId];
    }
    
    if (conversation.conversationId <= 0) {
        // Should never happen
        DDLogError(@"BUG: Returning unsaved conversation");
    }
    return conversation;
}
/* clean code went away. TODO: Refactor into small obvious methods */
-(void) processExtendedChatMessage:(QliqSipExtendedChatMessage *)sipMessage
{
	FMDatabase *database = [DBUtil sharedDBConnection];
	__block ChatMessage *existingMsg=nil;
	__block NSInteger newMsgId=0;
	
    __block SipContactDBService * sipContactService = [[SipContactDBService alloc] initWithDatabase:database];
	
	dispatch_async(self.qliqConnectDispatchQueue, ^{

        SipContact * myContact   = [sipContactService sipContactForQliqId:[UserSessionService currentUserSession].user.qliqId];
        
        {
            NSString *groupBroadcast = [sipMessage.extraHeaders objectForKey:@"X-group-broadcast"];
            if ([@"yes" isEqualToString:groupBroadcast]) {
                sipMessage.toUri = myContact.sipUri;
            }
        }
        
        /* Get SIP info from URI */
        SipContact * fromContact = [sipContactService sipContactForSipUri:[self extractSipUriFromString:sipMessage.fromUri]];
        SipContact * toContact   = [sipContactService sipContactForSipUri:[self extractSipUriFromString:sipMessage.toUri]];
        
		//get the userid from fromUri
        
        if ([fromContact.qliqId length] == 0) {
            DDLogSupport(@"QliqId is nil for sip uri '%@'",fromContact.sipUri);
            [self getAllContactsAndTryProcessMessage:sipMessage];
            return;
        }else{
            attempt = 0;
        }

        NSString * recipients_qliqId = fromContact.qliqId;

        if ([toContact.qliqId length] == 0) {
            DDLogError(@"Cannot find a SIP contact (user, group or mp chat) for to URI: %@", toContact.sipUri);
            return;
        }
        
        BOOL isSenderSync = NO;

        if ([toContact.sipUri compare: myContact.sipUri] == NSOrderedSame) {
            if ([fromContact.sipUri compare: myContact.sipUri] == NSOrderedSame) {
                if ([[QliqSip sharedQliqSip] isMultiDeviceSupported]) {
                    // Sender sync message
                    if (!sipMessage.toUserId) {
                        DDLogError(@"QliqSipExtendedChatMessage.toUserID is nil for sender sync, message: %@",sipMessage);
                        DDLogError(@"Callstack: %@",[NSThread callStackSymbolsWithLimit:0]);
                        return;
                    }
                    
                    isSenderSync = YES;
                    toContact.qliqId = sipMessage.toUserId;
                    recipients_qliqId = toContact.qliqId;
                    
                    SipContact *testContact = [sipContactService sipContactForQliqId:sipMessage.toUserId];
                    if ([testContact.sipUri length] == 0) {
                        // To contact not found, assume this is a MP conversation
                       
                        __block NSMutableArray *array = [messagesToUnknownUsersByQliqId objectForKey:sipMessage.toUserId];
                        if (!array)
                        {
                            array = [[NSMutableArray alloc] init];
                            [messagesToUnknownUsersByQliqId setObject:array forKey:sipMessage.toUserId];
                        }
                        [array addObject:sipMessage];
                        
                        [self getMultipartyFromWebservice:sipMessage.toUserId];
                        return;
                    }
                    
                }
            } else {
                toContact.qliqId = myContact.qliqId;
            }
        } else if (toContact.sipContactType == SipContactTypeMultiPartyChat) {
            recipients_qliqId = toContact.qliqId;
        } else if (toContact.sipContactType == SipContactTypeGroup) {
            recipients_qliqId = toContact.qliqId;
        } else if (toContact.sipContactType == SipContactTypeUser) {
            DDLogError(@"The to URI: %@ doesn't match mine", toContact.sipUri);
            return;
        }
                
		// Check if we already have this message. This can happen if a message is resent
		existingMsg = [DBHelperConversation getMessageWithGuid:sipMessage.messageId inDB:database];
		
		if (existingMsg == nil){

            Conversation * conversation = [self conversationForReceivedMessage:sipMessage fromQliqId:recipients_qliqId mySipUri:myContact.sipUri];

			ChatMessage *newMessage = nil;
			if(conversation.conversationId>0)
			{
				// Create new message and save to database.
				newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
				newMessage.conversationId = conversation.conversationId;
				newMessage.fromQliqId = fromContact.qliqId;
				newMessage.toQliqId = toContact.qliqId;
				newMessage.text = sipMessage.messageText;
                newMessage.deliveryStatus = 200;
				
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
				newMessage.lastSentAt = [[QliqSip sharedQliqSip] adjustedTimeFromNetwork:sipMessage.createdAt];
				
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
                    // Only normal messages are marked as unread.
                    newMessage.readAt = newMessage.receivedAt;
                }
				
				NSArray *attachments = [sipMessage.data objectForKey:@"attachments"];
				NSMutableArray *messageAttachments = [[NSMutableArray alloc] initWithCapacity:[attachments count]];
				
				for(NSDictionary *attachment in attachments)
				{
					MessageAttachment *chatMessageAttachment = [[MessageAttachment alloc] initWithDictionary:attachment];
					chatMessageAttachment.messageUuid = [newMessage uuid];
					if([chatMessageAttachment save])
					{
						[messageAttachments addObject:chatMessageAttachment];
					}
				}
				newMessage.attachments = [NSArray arrayWithArray:messageAttachments];

                BOOL createReadStatusLog = NO;
                if (isSenderSync) {
                    //newMessage.timestamp = sipMessage.createdAt;
                    newMessage.readAt = newMessage.timestamp;
                    newMessage.lastSentAt = newMessage.timestamp;
                    newMessage.selfDeliveryStatus = MessageStatusSynced;
                    newMessage.deliveryStatus = MessageStatusSynced;
                } else {
                    NSString *xstatus = [sipMessage.extraHeaders objectForKey:@"X-status"];
                    if ([xstatus hasPrefix:@"opened"]) {
                        NSString *atStr = [QliqSip captureRegExp:xstatus withPattern:@" at=(\\d+);"];
                        if ([atStr length] > 0) {
                            newMessage.readAt = [atStr intValue];
                            createReadStatusLog = YES;
                        }
                    }
                    conversation.isRead = newMessage.isRead;
                }
				conversation.lastMsg = newMessage.text;
                conversation.lastUpdated = newMessage.timestamp;

                if(conversation.archived || conversation.deleted) {
					[[ConversationDBService sharedService] restoreConversations:[NSArray arrayWithObject:conversation]];
					conversation.archived = NO;
				}
                
                NSTimeInterval timestamp = 0;
                BOOL wasTimestampFound = NO;
                timestamp = [self parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-created" wasFound:&wasTimestampFound];
                if (wasTimestampFound) {
                    newMessage.lastSentAt = timestamp;
                }
                
                [chatMessageService saveMessage:newMessage inConversation:conversation];
                BOOL wereMessageTimesModified = NO;
                
				// Save the status message
				// the status is sent with lastSentAt timestamp
				MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
				statusLog.messageId = newMessage.messageId;
				statusLog.timestamp = newMessage.lastSentAt;
				statusLog.status = CreatedMessageStatus;
				[statusLogDbService saveMessageStatusLog:statusLog inDB:database];
			
                timestamp = [self parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-sent" wasFound:&wasTimestampFound];
                if (wasTimestampFound) {
                    statusLog.timestamp = timestamp;
                    statusLog.status = SentMessageStatus;
                    [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
                }
                
                BOOL wasReceivedOnOtherDevice = NO;
				if (isSenderSync) {
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = SyncedMessageStatus;
                    [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
                } else {
                    timestamp = [self parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
                    if (wasTimestampFound) {
                        // Change received timestamp only if the message was read already
                        [self parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-received" wasFound:&wasTimestampFound];
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
                    [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
                    
                    if (createReadStatusLog) {
                        timestamp = [self parseAtTimeFromExtraHeader:sipMessage.extraHeaders name:@"X-opened" wasFound:&wasTimestampFound];
                        if (wasTimestampFound) {
                            newMessage.readAt = timestamp;
                            wereMessageTimesModified = YES;
                        }
                        statusLog.timestamp = newMessage.readAt;
                        statusLog.status = ReadMessageStatus;
                        [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
                    }
                }
                
                if (wasReceivedOnOtherDevice) {
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = ReceivedMessageStatus;
                    [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
                }
                
                if (wereMessageTimesModified) {
                    [chatMessageService saveMessage:newMessage inConversation:conversation];                    
                }
				
				if (newMessage.messageId == 0)
				{
					// TODO: Handle the error appropriately.
					//DDLogSupport(@"sendMessage error %d", newMsgId);
					DDLogError(@"Error inserting new message %d", newMsgId);
				}
			}
			
			// Optimization for a case when we are already chatting with the sender.
			// The view will call our method saveMessageAsRead,
			// in this method we will mark this message as read so we will push this field
			// in the first push to qliqStor
			justReceivedMessage = newMessage;
			if(!conversation.archived && !conversation.deleted)
			{
                NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          sipMessage.fromUri, @"FromUri",
                                          sipMessage.messageText, @"Message", nil];
                
                [NSNotificationCenter postNotificationToMainThread:SIPChatNotification userInfo:userinfo];
                
				[self notifyNewChatMessagesWithConversation:conversation inDB:database];

                if (!isSenderSync && [newMessage isNormalChatMessage]) {
                    NSString *noSoundString = [sipMessage.extraHeaders objectForKey:@"X-nosound"];
                    BOOL noSound = noSoundString && [noSoundString compare:@"yes" options:NSCaseInsensitiveSearch] == NSOrderedSame;
                    [[UserNotifications getInstance] notifyIncomingChatMessage:newMessage withoutSound:noSound];
                }
				
				if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
				{
					NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
					[defaults setObject:[NSNumber numberWithInt:newMessage.conversationId] forKey:@"lastActiveConversationId"];
					[defaults synchronize];
				}
			} else {
                DDLogError(@"Not notifying about new message because conversation is archived:%d or deleted:%d", conversation.archived, conversation.deleted);
            }
			
			justReceivedMessage = nil;
		}
        else
        {
            BOOL isDuplicate = ([fromContact.qliqId isEqualToString:existingMsg.fromQliqId] &&
                                [existingMsg.subject isEqualToString:sipMessage.subject] &&
                                [existingMsg.text isEqualToString:sipMessage.messageText]);
            if (isDuplicate) {
                DDLogSupport(@"Ignoring incoming chat message duplicate, uuid: %@, from: %@", sipMessage.messageId, fromContact.qliqId);
            } else {
                DDLogError(@"Received a different message with an existing uuid: %@, new from: %@, exsting from: %@", sipMessage.messageId, fromContact.qliqId, existingMsg.fromQliqId);
            }
        }
    
	});
}

-(BOOL) saveMessageAsRead:(NSInteger)messageId inDB:(FMDatabase*)database
{
    NSTimeInterval readAt = [[NSDate date] timeIntervalSince1970];
    ChatMessage *msg = [DBHelperConversation getMessage:messageId inDB:database];
    if (msg) {
        [self sendOpenedStatus:msg];
    }
    return [self saveMessageAsRead:messageId at:readAt inDB:database];
}

-(BOOL) saveMessageAsRead:(NSInteger)messageId at:(NSTimeInterval)readAt inDB:(FMDatabase*)database
{
    BOOL ret = [ChatMessage saveMessageAsRead:messageId at:readAt andRevisionDirty:NO inDB:database]; // the recipient doesn't push to qliqStor
    if(ret){
		// Save the status message
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = messageId;
        statusLog.timestamp = readAt;
        statusLog.status = ReadMessageStatus;
        [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
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
        [[UserNotifications getInstance] notifyAckGotForMessage:message];
    }    
}

-(void) sendMessage:(NSString *)messageText toUser:(Contact *)userContact subject:(NSString *)subject ackRequired:(BOOL)ack priority:(ChatMessagePriority)aPriority type:(ChatMessageType)aType
{
    QliqUserDBService * userService = [[QliqUserDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
    QliqUser * user = [userService getUserForContact:userContact];
    
    Recipients * recipients = [[Recipients alloc] init];
    [recipients addRecipient:user];
    
    Conversation *conv = [self newConversationWithRecipients:recipients subject:subject];
    [self sendMessage:messageText toQliqId:[userContact qliqId] inConversation:conv acknowledgeRequired:ack priority:aPriority type:aType];
    
}


- (void) saveStatus:(MessageStatus)status forMessage:(ChatMessage *) message{
    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
    statusLog.messageId = message.messageId;
    statusLog.timestamp = message.lastSentAt;
    statusLog.status = status;
    [statusLogDbService saveMessageStatusLog:statusLog inDB:[DBUtil sharedDBConnection]];
}


- (void) sendMessage:(ChatMessage*)chatMessage completition:(CompletionBlock)completeBlock{
    
    chatMessage.deliveryStatus = 0; //Set 'Sending' status
    
    BOOL messageExists = [chatMessageService messageExists:chatMessage];
    
    if([chatMessageService saveMessage:chatMessage]){
        // If message was inserted - then save status as Created
        if (!messageExists) [self saveStatus:CreatedMessageStatus forMessage:chatMessage];
    }else{
        DDLogError(@"Cant save message: %@",chatMessage);
    }
    
    /* Cancel if no qliqId */
    if (chatMessage.toQliqId.length == 0){
        DDLogWarn(@"%@, qliqId = %@. Will cancel sending message for now..",chatMessage, chatMessage.toQliqId);
        return;
    }
    
    
    if([[chatMessage attachments] count] > 0){
		[attachmentApiService uploadAllAttachmentsForMessage:chatMessage completition:^(CompletitionStatus status, id result, NSError *error) {
            switch (status) {
                case CompletitionStatusSuccess:
                    [self sipSendMessage:chatMessage];
                    break;
                case CompletitionStatusCancel:
                    chatMessage.deliveryStatus = MessageStatusAttachmentUploadCancelled;   //Set 'Canceled' status
                    [chatMessageService saveMessage:chatMessage];
                    break;
                case CompletitionStatusError:
                {
                    if ([error code] == 103) {
                        chatMessage.deliveryStatus = MessageStatusAttachmentUploadAttachmentNotFound;
                    } else {
                        chatMessage.deliveryStatus = MessageStatusCannotUploadAttachment;   //Set 'Error uploading' status
                    }

                    // Save the status message
                    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
                    statusLog.messageId = chatMessage.messageId;
                    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
                    statusLog.status = chatMessage.deliveryStatus;
                    [statusLogDbService saveMessageStatusLog:statusLog];
                    
                    [chatMessageService saveMessage:chatMessage];
                    break;
                }
            }
            
            if (completeBlock) completeBlock(status,chatMessage,error);
        }];
	}else{
        [self sipSendMessage:chatMessage];
        if (completeBlock) completeBlock(CompletitionStatusSuccess,chatMessage,nil);
    }
    
}

- (void) sendMessage:(ChatMessage*)chatMessage{
    [self sendMessage:chatMessage completition:nil];
}

-(ChatMessage*)sendMessage:(NSString *)messageText toQliqId:(NSString *)toQliqId inConversation:(Conversation *)conversation acknowledgeRequired:(BOOL)ack priority:(ChatMessagePriority)aPriority type:(ChatMessageType)aType
{
	return [self sendMessage:messageText toQliqId:toQliqId inConversation:conversation acknowledgeRequired:ack priority:aPriority type:aType inDB:[DBUtil sharedDBConnection]];
}
-(ChatMessage*)sendMessage:(NSString *)messageText toQliqId:(NSString *)toQliqId inConversation:(Conversation *)conversation acknowledgeRequired:(BOOL)ack priority:(ChatMessagePriority)aPriority type:(ChatMessageType)aType inDB:(FMDatabase *)database
{
    
    Buddy *toBuddy = [BuddyList getBuddyByQliqId:toQliqId inDB:database];
    if (!toBuddy)
    {
        DDLogError(@"Cannot find buddy for user id: %@", toQliqId);
        
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
    newMessage.lastSentAt = newMessage.timestamp;
	newMessage.ackRequired = ack;
    newMessage.priority = aPriority;
    newMessage.type = aType;
    newMessage.subject = conversation.subject;
    newMessage.metadata = [Metadata createNew];
    newMessage.metadata.isRevisionDirty = YES;
    
	[self sendMessage:newMessage];
    return newMessage;
}
- (void) sipSendMessage: (ChatMessage *)message
{
	[self sipSendMessage:message inDB:[DBUtil sharedDBConnection]];
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
    
    attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_SIZE] = [attachment fileSizeString];
    
    NSString *thumbnailBase64String = [attachment thumbnailBase64Encoded];
    if (thumbnailBase64String.length > 0) {
        attachmentDictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_THUMBNAIL] = thumbnailBase64String;
    } else {
        attachment.status = AttachmentStatusDeclined;
        [attachment save];
        *error = [NSError errorWithCode:0 description:[NSString stringWithFormat:@"Can't generate thumbnail for attachment: %@",attachment]];
        return nil;
    }
    
    return attachmentDictionary;
}

- (NSDictionary *) dictionaryRepresentationFromMessage:(ChatMessage *)message conversationUuid:(NSString *)conversationUuid error:(NSError **)error
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

- (void) sipSendMessage: (ChatMessage *)message inDB:(FMDatabase *)database
{
    
	AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
	BOOL isReachable = [app isReachable];
	if (!isReachable){
        DDLogError(@"Internet is not reachable during sending message. In old implmentation it should be marked as network error..but now we'll try to send it anyway");
//		message.deliveryStatus = 491;
//		[chatMessageService saveMessage:message];
//        return;
	}
    
    //Check if current thread is not main then switch to main thread because PJSip registered on main thread only
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(sipSendMessage:) withObject:message waitUntilDone:YES];
        return;
    }
    
    
    //    NSLog(@"SIP Notification: sending message (%d: \"%@\") to qliq_id: %@",message.messageId, message.text, message.toQliqId);
    
    //Check if message already sending
    for (ChatMessage * _tmpMessage in sentChatMessages){
        if (_tmpMessage.messageId == message.messageId && _tmpMessage.deliveryStatus == 0){
            //            NSLog(@"SIP Notification: message already in sending process. Aborting retrying.");
            return;
        }
    }
    //Mark message as sending
    message.deliveryStatus = 0;
    
    SipContactDBService * sipContactService = [[SipContactDBService alloc] initWithDatabase:database];
    SipContact * toContact = [sipContactService sipContactForQliqId:message.toQliqId];
    
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
    
    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInt:message.conversationId]];
    if (conversation.uuid.length == 0) {
        // Generate uuid for old conversation
        conversation.uuid = [Metadata generateUuid];
        DDLogSupport(@"Generated uuid for old conversation id: %d, uuid: %@", conversation.conversationId, conversation.uuid);
        
        if (![[ConversationDBService sharedService] saveConversation:conversation]) {
            // Shouldn't ever happen
            conversation.uuid = nil;
            DDLogError(@"Cannot save conversation");
        }
    }
    
    NSError *messageCreationError = nil;
    NSDictionary *messageData = [self dictionaryRepresentationFromMessage:message conversationUuid:conversation.uuid error:&messageCreationError];
    
    if (messageCreationError) {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Error" message:[messageCreationError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert showWithDissmissBlock:NULL];
        return;
    }
    
    NSString *messageJsonString = [self jsonStringFromExtendedMessageData:messageData];
    
    if (![sentChatMessages containsObject:message])
    {
        [sentChatMessages addObject:message];
    }
    
    // The time will be saved in db when message's status changes. //Why not saving this time inside saveMessageStatusLog: method? or create method for it..
	message.lastSentAt = [[NSDate date] timeIntervalSince1970];
	
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
    

    NSMutableDictionary *extraHeaders = [[NSMutableDictionary alloc] init];
    NSTimeInterval createdAt = [[QliqSip sharedQliqSip] adjustTimeForNetwork:message.timestamp];
    [extraHeaders setObject:[NSString stringWithFormat:@"at=%lu;", (unsigned long)createdAt] forKey:@"X-created"];
    if ([conversation.uuid length] > 0) {
        [extraHeaders setObject:conversation.uuid forKey:@"X-conversation-uuid"];
    }
    
    NSString *myDisplayName = [[UserSessionService currentUserSession].user displayName];
    [[QliqSip sharedQliqSip] sendMessage:messageJsonString to:toContact.sipUri withContext:message offlineMode:YES pushNotify:!isSelfSync withDisplayName:myDisplayName withCallId:message.metadata.uuid withPriority:message.priority alsoNotify:qliqStorIds extraHeaders:extraHeaders withMessageStatusChangedBlock:nil inDB:nil];
}

- (void) sendOpenedStatus: (ChatMessage *)msg
{
    if ([[QliqSip sharedQliqSip] isMultiDeviceSupported] && !msg.isOpenedSent && ![msg isSentByUser]) {
        
        //Check if current thread is not main then switch to main thread because PJSip registered on main thread only
        if (![NSThread isMainThread]) {
            [self performSelectorOnMainThread:@selector(sendOpenedStatus:) withObject:msg waitUntilDone:YES];
            return;
        }
        
        SipContactDBService * sipContactService = [[SipContactDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
        SipContact *fromContact = [sipContactService sipContactForQliqId:msg.fromQliqId];
        if ([fromContact.sipUri length] == 0) {
            DDLogError(@"Cannot send opened status: cannot get sip uri for qliq id: %@", msg.fromQliqId);
            msg.isOpenedSent = YES;
            [[ChatMessageService sharedService] saveMessage:msg];
        } else {
            [[QliqSip sharedQliqSip] sendOpenedStatus:fromContact.sipUri callId:msg.metadata.uuid serverContext:msg.serverContext];
        }
    }
}

+ (QliqConnectModule *) sharedQliqConnectModule
{
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

- (void) processMessageStatusNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    int status = [userInfo[@"Status"] intValue];
    NSString *aCallId = userInfo[@"CallId"];
    id context = userInfo[@"context"];
    
    if ([self isChatMessageNotification:notification])
    {
        if ([sentChatMessages count] > 0 || [sentAcks count] > 0) {
            ChatMessage *changedMessage = context;
            [self processMessageStatus:changedMessage status:status callId:aCallId qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
        }
    }
    else if ([self isOpenedStatusMessageNotification:notification]) {
        [self processMessageStatus:nil status:status callId:aCallId qliqId:nil deliveredRecipientCount:0 totalRecipientCount:0 deliveredAt:0];
    }
    
    // These two statuses are passed to the application only if pjproject contains our patch.
    // Normally pjproject resends the message with authorization header by itself.
    if (status == 401 || status == 407) {
        // If no authorization for the message (of any type) then trigger re-registration        
        [[QliqSip sharedQliqSip] setRegistered:YES];
    }
}

-(void) processOpenedMessageStatusNotification:(NSNotification *)notification
{
    NSString *aCallId = [[notification userInfo] objectForKey:@"CallId"];
    NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
    NSNumber *aOpenedRecipientCount = [[notification userInfo] objectForKey:@"OpenedRecipientCount"];
    DDLogSupport(@"aTotalRecipientCount = %@, OpenedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
    NSNumber *aOpenedAt = [[notification userInfo] objectForKey:@"OpenedAt"];
    ChatMessage *msg = [DBHelperConversation getMessageWithGuid:aCallId];
    if (msg) {
        NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
        if ([aQliqId isEqualToString:myQliqId]) {
            if (msg.readAt == 0 && ![msg.fromQliqId isEqualToString:myQliqId]) {
                msg.isOpenedSent = YES;
                [[ChatMessageService sharedService] saveMessage:msg];

                [self saveMessageAsRead:msg.messageId at:[aOpenedAt longValue] inDB:[DBUtil sharedDBConnection]];
                
                // Post a notification for recents view (ConversationListViewController)
                // to clear the conversation unread badge
                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInt:msg.conversationId]];
                NSDictionary * info = [[NSDictionary alloc] initWithObjectsAndKeys:conversation,@"Conversation", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:DBHelperConversationDidReadMessages object:nil userInfo:info];
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
                msg.readAt = [aOpenedAt longValue];
            }
            [[ChatMessageService sharedService] saveMessage:msg];
            [self notifyChatMessageStatus:msg];

            // Save the status message
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = msg.messageId;
            statusLog.timestamp = [aOpenedAt longValue];
            statusLog.status = ReadMessageStatus;
            statusLog.qliqId = aQliqId;
            [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog inDB:[DBUtil sharedDBConnection]];
        }
    }
}

-(void) processAckedMessageStatusNotification:(NSNotification *)notification
{
    NSString *aCallId = [[notification userInfo] objectForKey:@"CallId"];
    NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
    NSNumber *aOpenedRecipientCount = [[notification userInfo] objectForKey:@"AckedRecipientCount"];
    DDLogSupport(@"aTotalRecipientCount = %@, AckedRecipientCount = %@", aTotalRecipientCount, aOpenedRecipientCount);
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
            [statusLogDbService saveMessageStatusLog:statusLog];
            
            [self notifyChatAck:msg withSound:NO];
            
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
            [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog inDB:[DBUtil sharedDBConnection]];
            
            if (msg.ackedRecipientCount == msg.totalRecipientCount && msg.totalRecipientCount > 0) {
                msg.ackReceivedAt = [aOpenedAt longValue];
                
                if (msg.totalRecipientCount > 1) {
                    // Insert 'Acked by all' marker
                    statusLog.qliqId = nil;
                    [[[MessageStatusLogDBService alloc] init] saveMessageStatusLog:statusLog inDB:[DBUtil sharedDBConnection]];
                }
            }
            [[ChatMessageService sharedService] saveMessage:msg];
            
            [self notifyChatAck:msg withSound:YES];
        }
    }
}

- (void)processPendingMessageStatusNotification:(NSNotification *)notification
{
	int status = [[[notification userInfo ] objectForKey: @"Status"] intValue];
    NSString *aCallId = [[notification userInfo] objectForKey:@"CallId"];
    NSString *aQliqId = [[notification userInfo] objectForKey:@"QliqId"];
    NSNumber *aTotalRecipientCount = [[notification userInfo] objectForKey:@"TotalRecipientCount"];
    NSNumber *aDeliveredRecipientCount = [[notification userInfo] objectForKey:@"DeliveredRecipientCount"];
    NSNumber *aDeliveredAt = [[notification userInfo] objectForKey:@"DeliveredAt"];
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
        // In future version we will drop the message.call_id column.
        msg = [DBHelperConversation getMessageWithCallId:aCallId];
        if (!msg) {
            // New code uses uuid for call id. It is possible that app crashed before
            // message's status changed so we didn't save the call id,
            // but we can still get the message by uuid column.
            msg = [DBHelperConversation getMessageWithGuid:aCallId];
        }
    }
    
    if (msg) {
        if (isAck == NO && msg.deliveryStatus == 200) {
            DDLogError(@"Ignoring NOTIFY with status: %d for already delivered message uuid: %@", status, msg.metadata.uuid);
        } else {
            NSMutableSet *sentSet = (isAck ? sentAcks : sentChatMessages);
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
            
            [self processMessageStatus:msg status:status callId:aCallId qliqId:aQliqId deliveredRecipientCount:[aDeliveredRecipientCount intValue] totalRecipientCount:[aTotalRecipientCount intValue] deliveredAt:[aDeliveredAt longValue]];
        }
    } else {
        DDLogError(@"Cannot find message for NOTIFY with status: %d, call-id: %@", status, aCallId);
    }
}


- (void)processMessageStatus:(ChatMessage *)msgArg status:(int)statusArg callId:(NSString *)aCallId qliqId:(NSString *)aQliqId deliveredRecipientCount:(int)aDeliveredRecipientCount totalRecipientCount:(int)aTotalRecipientCount deliveredAt:(long)aDeliveredAt
{
    dispatch_async(self.qliqConnectDispatchQueue, ^{
        BOOL wasDeliveredNow = NO;
        BOOL isValidMessageObject = NO;
        // Copies for the block
        ChatMessage *msg = msgArg;
        int status = statusArg;
        
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        if (status == 200 && aDeliveredAt != 0) {
            timeStamp = aDeliveredAt;
        }
        
        if ([sentChatMessages containsObject:msg])
        {
            isValidMessageObject = YES;
            
            if (resendingMessageId == msg.messageId) {
                resendingMessageId = 0;
            }
            
            if (msg.selfDeliveryStatus / 100 != 2) {
                msg.selfDeliveryStatus = status;
                [[ChatMessageService sharedService] saveMessage:msg];
                [sentChatMessages removeObject:msg];
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
            else
                msg.failedAttempts = msg.failedAttempts + 1;
            
            // Save the status message
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = msg.messageId;
            statusLog.timestamp = timeStamp;
            statusLog.status = status;
            statusLog.qliqId = aQliqId;
            [statusLogDbService saveMessageStatusLog:statusLog];
            
            if (!wasDeliveredNow && msg.failedAttempts > maximumRetryCount) {
                status = MessageStatusTooManyRetries;
                statusLog.status = status;
                [statusLogDbService saveMessageStatusLog:statusLog];
            }
            
            if (status == 200) {
                // Delete
                if (msg.totalRecipientCount > 1) {
                    // Change status to Delivered only if delivered to all recipients
                    if (aDeliveredRecipientCount == aTotalRecipientCount) {
                        msg.deliveryStatus = status;

                        if ([aQliqId length] > 0) {
                            // Insert 'Delivered to all' marker
                            statusLog = [[MessageStatusLog alloc] init];
                            statusLog.messageId = msg.messageId;
                            statusLog.timestamp = timeStamp;
                            statusLog.status = status;
                            statusLog.qliqId = nil;
                            [statusLogDbService saveMessageStatusLog:statusLog];
                        }
                    } else if (msg.deliveryStatus == 299) {
                        // For synced MP messages change status to 202
                        msg.deliveryStatus = 202;
                    }
                } else {
                    // If a SP message then always changes status to 200
                    msg.deliveryStatus = status;
                }
            } else {
                msg.deliveryStatus = status;
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
            [sentChatMessages removeObject:msg];

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
        else if ([sentAcks containsObject:msg])
        {
            isValidMessageObject = YES;
            NSInteger statusLogStatus = status;
            
            if (resendingMessageId == msg.messageId) {
                resendingMessageId = 0;
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
                [sentAcks removeObject:msg];
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
                msg.failedAttempts = msg.failedAttempts + 1;
            }
            
            // Save the status message
            MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
            statusLog.messageId = msg.messageId;
            statusLog.timestamp = timeStamp;
            statusLog.status = statusLogStatus;
            [statusLogDbService saveMessageStatusLog:statusLog];
            
            if (!wasDeliveredNow && msg.failedAttempts > maximumRetryCount) {
                msg.ackSentToServerAt = -1;
                statusLog.status = MessageStatusTooManyRetries;
                [statusLogDbService saveMessageStatusLog:statusLog];
            }
            [[ChatMessageService sharedService] saveMessage:msg];
            
            [self notifyChatMessageStatus:msg];
           
            [sentAcks removeObject:msg];
            
            if (status == SIP_UNDECIPHERABLE_STATUS) {
                [self sendAck:msg];
            }        
        }
        else if (status == 220 && !msg) {
            msg = [DBHelperConversation getMessageWithGuid:aCallId];
            if (msg) {
                if (resendingMessageId == msg.messageId) {
                    resendingMessageId = 0;
                }
                
                msg.isOpenedSent = YES;
                if (![[ChatMessageService sharedService] saveMessage:msg]) {
                    DDLogError(@"Cannot save message after sending opened status, uuid: %@", aCallId);
                }
            } else {
                DDLogError(@"Cannot find message for opened status confirmation (220) call-id: %@", aCallId);
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
            //[self resendUndeliveredMessagesAndAcksForQliqId:toQliqId];
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
    });
}

- (void) processPermanentErrorMessageStatus:(NSInteger)status toQliqId:(NSString *)toQliqId
{
    FMDatabase *database = [DBUtil sharedDBConnection];
    
    MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
    statusLog.timestamp = [[NSDate date] timeIntervalSince1970];
    statusLog.status = status;
    
    NSArray *messages = [DBHelperConversation getUndeliveredMessagesWithStatusNotIn:permanentFailureStatusSet toQliqId:toQliqId limit:10000 offset:0 inDB:database];

    for (ChatMessage *msg in messages) {
        // Save the status message
        statusLog.messageId = msg.messageId;
        [statusLogDbService saveMessageStatusLog:statusLog];

        msg.deliveryStatus = status;
        // Message needs push if its a new one or if delivery status changes
        msg.metadata.isRevisionDirty = YES;
        msg.metadata.author = [Helper getMyQliqId];
        [[ChatMessageService sharedService] saveMessage:msg];
#ifndef QLIQSTOR_NOTIFY_IMPLEMENTATION
        [PushMessageToQliqStorHelper setMessageUnpushedToAllQliqStors:msg];
#endif

        for (ChatMessage *sentMsg in sentChatMessages) {
            if (sentMsg.messageId == msg.messageId) {
                [sentChatMessages removeObject:sentMsg];
                break;
            }
        }
        
        [self notifyChatMessageStatus:msg];
    }
    
    // Process undelivered acks
    messages = [DBHelperConversation getUndeliveredAcksToQliqId:toQliqId limit:10000 offset:0 inDB:database];
    
    for (ChatMessage *msg in messages) {
        // Save the status message
        statusLog.messageId = msg.messageId;
        [statusLogDbService saveMessageStatusLog:statusLog];
        
        msg.ackSentToServerAt = -1;
        [[ChatMessageService sharedService] saveMessage:msg];
        
        for (ChatMessage *sentMsg in sentAcks) {
            if (sentMsg.messageId == msg.messageId) {
                [sentAcks removeObject:sentMsg];
                break;
            }
        }
        
        [self notifyChatMessageStatus:msg];
    }
}

- (void) notifyChatMessageStatus:(ChatMessage *)message
{
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:message forKey:@"Message"];
    [NSNotificationCenter postNotificationToMainThread:ChatMessageStatusNotification userInfo:userinfo];
}

- (void) notifyChatMessageAttachmentStatus:(MessageAttachment *)attachment
{
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:attachment forKey:@"Attachment"];
    [NSNotificationCenter postNotificationToMainThread:ChatMessageStatusNotification userInfo:userinfo];
}

- (void) notifyNewChatMessages
{
    
    [ChatMessage updateUnreadCountInDb:[DBUtil sharedDBConnection]];
    [NSNotificationCenter postNotificationToMainThread:NewChatMessagesNotification];
    
}

- (void) notifyNewChatMessagesWithConversation:(Conversation *) conversation inDB:(FMDatabase*) database
{
    [ChatMessage updateUnreadCountInDb:database];
    [NSNotificationCenter postNotificationToMainThread:NewChatMessagesNotification withObject:conversation];
}

- (void) pushMessageToDataServer:(ChatMessage *)msg
{
#ifdef OLD_PUSHING_CODE_ENABLED
    
	if(msg != nil){
		if (![DataServerClient sharedDataServerClient].qliqStorUser)
		{
			DDLogError(@"Cannot push chat message: no qliqStor configured.");
            
			return;
		}
		
		if (pushedMessage)
		{
			DDLogVerbose(@"There is already an outstanding chat-message push to qliqStor, skipping");
            
			return;
		}
		
		DDLogVerbose(@"Pushing message %@ to QliqStor", [msg uuid]);
		
		NSString *timeStr = nil;
		
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
										[msg uuid], CHAT_MESSAGE_MESSAGE_ID,
										[NSNumber numberWithBool:msg.ackRequired], CHAT_MESSAGE_REQUIRES_ACK,
										msg.subject ? msg.subject : @"", CHAT_MESSAGE_SUBJECT,
										mdDict, @"metadata",
										nil];
		
		if ([msg isSentByUser])
		{
			timeStr = [Helper intervalToISO8601DateTimeString:msg.timestamp];
			[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_CREATED_AT];
			
			timeStr = [Helper intervalToISO8601DateTimeString:msg.lastSentAt];
			[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_LAST_SENT_AT];
			[chatDoc setObject:@"iPhone" forKey:CHAT_MESSAGE_SENT_FROM_DEVICE];
			
			[chatDoc setObject:[msg deliveryStatusToString] forKey:CHAT_MESSAGE_DELIVERY_STATUS];
			
			if (msg.failedAttempts > 0)
				[chatDoc setObject:[NSNumber numberWithInt:msg.failedAttempts] forKey:CHAT_MESSAGE_FAILED_ATTEMPTS];
			
			if (msg.ackRequired && msg.ackReceivedAt)
			{
				timeStr = [Helper intervalToISO8601DateTimeString:msg.ackReceivedAt];
				[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_ACK_RECEIVED_AT];
			}
		}
		else
		{
			// Add lastSentAt that is actuall createAt from extended chat message.
			// Tkt #708
			if (msg.lastSentAt > 0)
			{
				timeStr = [Helper intervalToISO8601DateTimeString:msg.lastSentAt];
				[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_LAST_SENT_AT];
			}
			
			timeStr = [Helper intervalToISO8601DateTimeString:msg.receivedAt];
			[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_RECEIVED_AT];
			[chatDoc setObject:@"iPhone" forKey:CHAT_MESSAGE_RECEIVED_ON_DEVICE];
			
			if (msg.ackRequired && msg.ackSentAt)
			{
				timeStr = [Helper intervalToISO8601DateTimeString:msg.ackSentAt];
				[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_ACK_SENT_AT];
			}
			
			if (msg.readAt)
			{
				timeStr = [Helper intervalToISO8601DateTimeString:msg.readAt];
				[chatDoc setObject:timeStr forKey:CHAT_MESSAGE_READ_AT];
			}
		}
		
		// Attachments
        MessageAttachmentDBService *attachmentDb = [MessageAttachmentDBService sharedService];
        NSArray *attachments = [attachmentDb getAttachmentsForMessage: msg];
        if ([attachments count] > 0)
        {
            NSMutableArray *attachmentsJsonArray = [[NSMutableArray alloc] init];
            
            for (ChatMessageAttachment *a in attachments)
            {
                NSMutableDictionary *attachDict = [[NSMutableDictionary alloc] init];
                [attachDict setObject:a.url forKey:CHAT_MESSAGE_ATTACHMENT_URL];
                [attachDict setObject:a.mediaFile.fileName forKey:CHAT_MESSAGE_ATTACHMENT_FILE_NAME];
                [attachDict setObject:a.mediaFile.mimeType forKey:CHAT_MESSAGE_ATTACHMENT_MIME];
                
                [attachDict setObject:[NSNumber numberWithInt:1] forKey:CHAT_MESSAGE_ATTACHMENT_ENCRYPTION_METHOD];
                [attachDict setObject:a.mediaFile.encryptionKey forKey:CHAT_MESSAGE_ATTACHMENT_KEY];
                
                NSString *thumb = [UIImagePNGRepresentation([a thumbnailStyled:NO]) base64EncodedString];
                [attachDict setObject:thumb forKey:CHAT_MESSAGE_ATTACHMENT_THUMBNAIL];
                
                [attachmentsJsonArray addObject:attachDict];
            }
			
            [chatDoc setObject:attachmentsJsonArray forKey:CHAT_MESSAGE_ATTACHMENTS];
        }
        
		pushedMessage = msg;
		NSString *requestId = [[DataServerClient sharedDataServerClient] sendUpdate:chatDoc forUuid:msg.metadata.uuid forSubject:@"chat-message" delegate:self requireResponse:NO];
		if (requestId == nil)
		{
			pushedMessage = nil;
		}
	}
    else
    {
		DDLogError(@"msg is nil, do not need to send to dataserver.");
	}
#endif
}
-(void) sendAck:(ChatMessage *)message
{
	[self sendAck:message inDB:[DBUtil sharedDBConnection]];
}
-(void) sendAck:(ChatMessage *)message inDB:(FMDatabase *)database
{
    //Check if message already sending
    for (ChatMessage * _tmpMessage in sentAcks){
        if (_tmpMessage.messageId == message.messageId && _tmpMessage.deliveryStatus == 0){
            //            NSLog(@"SIP Notification: ack already in sending process. Aborting retrying.");
            return;
        }
    }
    //mark message as sending
    //message.deliveryStatus = 0;
    
    NSNumber *convNumber = [NSNumber numberWithInt:message.conversationId];
    Conversation *conv = [[ConversationDBService sharedService] getConversationWithId:convNumber];
    NSString *qliqId = conv.recipients.qliqId;
    SipContactDBService *sipContactService = [[SipContactDBService alloc] initWithDatabase:database];
    SipContact *toContact = [sipContactService sipContactForQliqId:qliqId];
    if ([toContact.sipUri length] == 0) {
        DDLogError(@"Cannot send message ack: Cannot find SIP URI for qliq id: %@", qliqId);
        return;
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
#endif
    
    if (![[QliqSip sharedQliqSip] isMultiDeviceSupported] || isSenderSync) {
        // Save the status message
        MessageStatusLog *statusLog = [[MessageStatusLog alloc] init];
        statusLog.messageId = message.messageId;
        statusLog.timestamp = message.ackSentAt;
        statusLog.status = SendingAckMessageStatus;
        [statusLogDbService saveMessageStatusLog:statusLog inDB:database];
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
    
    [sentAcks addObject:message];
    NSString *myDisplayName = [[UserSessionService currentUserSession].user displayName];
    NSString *callId = [@"ac-" stringByAppendingString:message.metadata.uuid];

    NSMutableDictionary *extraHeaders = [[NSMutableDictionary alloc] init];
    if (!isSenderSync) {
        [extraHeaders setObject:@"acked" forKey:@"X-status"];
        [extraHeaders setObject:message.serverContext forKey:@"X-server-context"];
    }

    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInt:message.conversationId]];
    if ([conversation.uuid length] > 0) {
        [extraHeaders setObject:conversation.uuid forKey:@"X-conversation-uuid"];
    }
    
    [[QliqSip sharedQliqSip] sendMessage: [jsonDict JSONString] to:toContact.sipUri withContext:message offlineMode:YES pushNotify:NO withDisplayName:myDisplayName withCallId:callId withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:extraHeaders withMessageStatusChangedBlock:nil inDB:nil];
}

-(BOOL) processChatMessageFromDataServer:(NSDictionary *)chatMessageDict
{
    
    NSString *uuid = [chatMessageDict objectForKey:CHAT_MESSAGE_UUID];
    if ([uuid length] == 0)
    {
        DDLogError(@"Invalid chat message received from Data Server: no message id");
        
        return NO;
    }
    
    Metadata *serverMd = [Metadata metadataFromDict:[chatMessageDict objectForKey:CHAT_MESSAGE_METADATA]];
    
    ChatMessage *msg = [DBHelperConversation getMessageWithGuid:uuid];
    NSString *theOtherQliqId = nil;
    NSInteger existingMessageId = 0;
    BOOL wasRevisionDirty = NO;
    BOOL wasDelivered = NO;
    BOOL wasAcked = NO;
    
    if (msg)
    {
        if ([msg.metadata.rev length] > 0 && ([msg.metadata.rev compare:serverMd.rev] == NSOrderedSame))
        {
            // We already have this message
            DDLogVerbose(@"We already have this message with GUID : %@, rev: %@", uuid, msg.metadata.rev);
            return YES;
        }
        
        existingMessageId = msg.messageId;
        //theOtherQliqId = [msg isSentByUser] ? msg.toQliqId : msg.fromQliqId;
        wasRevisionDirty = msg.metadata.isRevisionDirty;
        wasDelivered = (msg.readAt != 0);
        wasAcked = msg.isAcked;
    }
    else
    {
        NSString *subject = [chatMessageDict objectForKey:CHAT_MESSAGE_SUBJECT];
        NSString *fromQliqId = [chatMessageDict objectForKey:CHAT_MESSAGE_FROM_USER_ID];
        NSString *toQliqId = [chatMessageDict objectForKey:CHAT_MESSAGE_TO_USER_ID];
        
        msg = [[ChatMessage alloc] initWithPrimaryKey:0];
        msg.fromQliqId = fromQliqId;
        msg.toQliqId = toQliqId;
        msg.text = [chatMessageDict objectForKey:CHAT_MESSAGE_TEXT];
        msg.ackRequired = [[chatMessageDict objectForKey:CHAT_MESSAGE_REQUIRES_ACK] boolValue];
		
        theOtherQliqId = [msg isSentByUser] ? toQliqId : fromQliqId;
        
        NSInteger conversationId = [DBHelperConversation getConversationId:theOtherQliqId andSubject:subject];
        if (conversationId == 0)
			//replace this with ConversationService saveConversion: method
            //conversationId = [DBHelperConversation addConversation:theOtherQliqId andSubject:subject];
			msg.conversationId = conversationId;
        
        NSString *readAtStr = [chatMessageDict objectForKey:CHAT_MESSAGE_READ_AT];
        if (readAtStr)
            msg.readAt = [Helper strDateTimeISO8601ToInterval:readAtStr];
        
        NSString *timeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_CREATED_AT];
        if ([timeStr length] > 0)
            msg.timestamp = [Helper strDateTimeISO8601ToInterval: timeStr];
    }
    
    msg.metadata = [Metadata metadataFromDict:[chatMessageDict objectForKey:CHAT_MESSAGE_METADATA]];
    msg.metadata.isRevisionDirty = wasRevisionDirty;
	
    NSTimeInterval receivedTime = 0;
    NSString *receivedTimeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_RECEIVED_AT];
    if ([receivedTimeStr length] > 0)
    {
        receivedTime = [Helper strDateTimeISO8601ToInterval: receivedTimeStr];
        msg.receivedAt = receivedTime;
        
        if (existingMessageId == 0)
        {
            // Delivery status has been already pushed
            wasDelivered = YES;
        }
        
        // if received then delivered too
        msg.deliveryStatus = 200;
    }
    
    
    if ([msg isSentByUser])
    {
        if (msg.timestamp == 0)
        {
            NSString *timeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_CREATED_AT];
            if ([timeStr length] > 0)
                msg.timestamp = [Helper strDateTimeISO8601ToInterval: timeStr];
			
            if (msg.timestamp == 0)
            {
                // This can happen if the message wasn't pushed by the sender,
                // but only by the recipient.
                // Use received time as an aproximation for sent time or current time as a fall back.
                msg.timestamp = receivedTime ? receivedTime : [[NSDate date] timeIntervalSince1970];
                msg.metadata.isRevisionDirty = YES;
            }
        }
        
        // Own message is always read
        msg.readAt = msg.timestamp;
        
        if (!wasDelivered && receivedTime)
        {
            // Previously we didn't know that the message was delivered
            msg.receivedAt = receivedTime;
            msg.metadata.isRevisionDirty = YES;
        }
        else
        {
            wasDelivered = YES;
        }
        
        if (msg.ackRequired)
        {
            NSString *ackReceivedTimeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_ACK_RECEIVED_AT];
			
            if ([ackReceivedTimeStr length] == 0)
            {
                ackReceivedTimeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_ACK_SENT_AT];
            }
            
            if ([ackReceivedTimeStr length] > 0)
            {
                msg.ackReceivedAt = [Helper strDateTimeISO8601ToInterval: ackReceivedTimeStr];
            }
        }
    }
    else
    {
        // The status is only local
        msg.deliveryStatus = 200;
        
        if (receivedTime == 0)
        {
            // First time received by the recipient
            //msg.isRead = NO;
            receivedTime = [[NSDate date] timeIntervalSince1970];
            msg.metadata.isRevisionDirty = YES;
        }
        msg.receivedAt = receivedTime;
        
        if (msg.ackRequired)
        {
            NSString *ackSentTimeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_ACK_SENT_AT];
            NSString *ackReceivedTimeStr = [chatMessageDict objectForKey:CHAT_MESSAGE_ACK_RECEIVED_AT];
            
            if ([ackSentTimeStr length] == 0)
                ackSentTimeStr = ackReceivedTimeStr;
            
            if ([ackSentTimeStr length] > 0)
                msg.ackSentAt = [Helper strDateTimeISO8601ToInterval: ackSentTimeStr];
			
            if ([ackReceivedTimeStr length] > 0)
                msg.ackReceivedAt = [Helper strDateTimeISO8601ToInterval: ackReceivedTimeStr];
        }
    }
	
    if (msg.metadata.isRevisionDirty)
        msg.metadata.author = [Helper getMyQliqId];
    
    NSInteger newMessageId = 0;
    
    if (existingMessageId > 0)
    {
        newMessageId = existingMessageId;
        [[ChatMessageService sharedService] saveMessage:msg];
    }
    else
    {
		[[ChatMessageService sharedService] saveMessage:msg];
        newMessageId = msg.messageId;
    }
    
    if ([msg isSentByUser])
    {
        if (!wasDelivered && ((msg.deliveryStatus / 100 == 2) || msg.deliveryStatus != 0))
        {
            // Simulate delivery
            [self notifyChatMessageStatus:msg];
        }
        
        if (existingMessageId && !wasAcked && [msg isAcked])
        {
            // Simulate ack message
            [self notifyChatAck:msg withSound:NO];
        }
    }
    
    if (existingMessageId == 0)
    {
        pulledNewMessagesCount++;
    }
    
    
    
    return newMessageId > 0;
}

- (void) onBuddyStatusChanged:(NSNotification *)notification
{
    
    Buddy *buddy = [[notification userInfo] objectForKey: @"Buddy"];
    if (buddy && (buddy.status == 1) && ([buddy.buddyQliqId compare:[Helper getMyQliqId]] != NSOrderedSame))
    {
        [self resendUndeliveredMessagesAndAcksForQliqId:buddy.buddyQliqId];
    }
    
}
/*
 - (void) resendUndeliveredMessagesAndAcks
 {
 
 NSString *meUserid = [Helper getMyQliqId];
 NSArray *allBuddies = [BuddyList getAllBuddies];
 for (Buddy *buddy in allBuddies)
 {
 if ([meUserid compare:buddy.buddyQliqId] != NSOrderedSame)
 {
 [self resendUndeliveredMessagesForQliqId:buddy.buddyQliqId];
 [self resendUndeliveredAcksForQliqId:buddy.buddyQliqId];
 }
 }
 
 }
 */

- (void) resendUndeliveredMessagesAndAcksForQliqId:(NSString *)qliqId
{
	[self resendUndeliveredMessagesAndAcksForQliqId:qliqId inDB:[DBUtil sharedDBConnection]];
}

- (void) resendUndeliveredMessagesAndAcksForQliqId:(NSString *)qliqId inDB:(FMDatabase *)database
{
    
    [self resendUndeliveredMessagesForQliqId:qliqId inDB:database];
    [self resendUndeliveredAcksForQliqId:qliqId inDB:database];
    
}

- (void) resendUndeliveredMessagesForQliqId: (NSString *)buddyQliqId
{
	[self resendUndeliveredMessagesForQliqId:buddyQliqId inDB:[DBUtil sharedDBConnection]];
}

- (void) resendOneUndeliveredMessage
{
    if (resendingMessageId != 0) {
        // Already waiting for status change for a previous resent message
        return;
    }
    
    if ([[QliqSip sharedQliqSip] pendingMessagesAndNotifiesCount] > 0) {
        DDLogSupport(@"Not resending messages because message dump is in progress");
        return;
    }
    
    FMDatabase *database = [DBUtil sharedDBConnection];
    int offset = 0;
    
    while (true) {
        NSArray *messages = [DBHelperConversation getUndeliveredMessagesWithStatusNotIn:permanentFailureStatusSet toQliqId:nil limit:1 offset:offset inDB:database];
        if ([messages count] == 0) {
            DDLogSupport(@"No (more) messages to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        
        if ([msg.toQliqId length] == 0) {
            DDLogSupport(@"Skipping undelivered message because to qliq id is empty (%d, %@)", msg.messageId, msg.metadata.uuid);
            offset++;
            msg = nil;
            continue;
        }
        
        for (ChatMessage *sentMsg in sentChatMessages) {
            if (sentMsg.messageId == msg.messageId) {
                DDLogSupport(@"Skipping undelivered message because it is already being sent (%d, %@)", msg.messageId, msg.metadata.uuid);
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
            DDLogSupport(@"Resending message to: %@, id: %d, call-id: %@", msg.toQliqId, msg.messageId, msg.metadata.uuid);
            resendingMessageId = msg.messageId;
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
        NSArray *messages = [DBHelperConversation getUndeliveredAcksFromQliqId:nil limit:1 offset:offset inDB:database];
        if ([messages count] == 0) {
            DDLogSupport(@"No (more) acks to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        for (ChatMessage *sentAck in sentAcks) {
            if (sentAck.messageId == msg.messageId) {
                DDLogSupport(@"Skipping undelivered ack because it is already being sent (%d, ac-%@)", msg.messageId, msg.metadata.uuid);
                offset++;
                msg = nil;
                break;
            }
        }
        if (msg != nil) {
            DDLogSupport(@"Resending ack to: %@, id: %d, call-id: ac-%@", msg.toQliqId, msg.messageId, msg.metadata.uuid);
            resendingMessageId = msg.messageId;
//            [self sipSendMessage:msg inDB:database];
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
        NSArray *messages = [DBHelperConversation getUndeliveredOpenedStatusWithLimit:1 offset:offset inDB:database];
        if ([messages count] == 0) {
            DDLogSupport(@"No (more) opened status to resend, offset: %d", offset);
            break;
        }
        
        ChatMessage *msg = [messages objectAtIndex:0];
        if (msg != nil) {
            DDLogSupport(@"Resending opened status call-id: %@", msg.metadata.uuid);
            resendingMessageId = msg.messageId;
            [self sendOpenedStatus:msg];
            break;
        }
    }
}

- (void) resendUndeliveredMessagesForQliqId: (NSString *)buddyQliqId inDB:(FMDatabase *)database
{
    //    NSLog(@"Resending all undelivered messages...");
    
    
    // Don't resend to self
    NSString *meUserid = [Helper getMyQliqId];
    if ([meUserid compare: buddyQliqId] == NSOrderedSame)
        return;
    
    // This array contains the messages to resend for this particular user
    NSMutableArray *messagesToResend = [[NSMutableArray alloc] init];
    
    //    NSLog(@"Messages in memory:");
    // First add undelivered message from memory
    NSMutableSet *sentSet = [[NSMutableSet alloc] init];
    for (ChatMessage *m in sentChatMessages)
    {
        NSString * mStr = [NSString stringWithFormat:@"id: %d, text: %@, status: %d",m.messageId, m.text, m.deliveryStatus];
        printf("%s",[mStr cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if ([m.toQliqId compare:buddyQliqId] == NSOrderedSame)
        {
            // Don't skip messages with status 0 (sending) because then
            // we would load them from DB in the next step and we don't want it.
            [sentSet addObject:[NSNumber numberWithInt:m.messageId]];
            
            if (m.deliveryStatus != 0){
                [messagesToResend addObject:m];
                printf(" - will resend");
            }
            printf("\n");
            
        }
    }
    //	NSLog(@"Messages in database:");
    // Now add messages from db (tried to send in previous sesssion)
    NSArray *idsFromDB = [DBHelperConversation getUndeliveredMessageIdsForQliqId:buddyQliqId limit:0 inDB:database];
    for (NSNumber *messageId in idsFromDB)
    {
        printf("id: %d ",[messageId intValue]);
        
        if (![sentSet containsObject:messageId])
        {
            // This message was sent in a previous sesssion we need to load it from db
            ChatMessage *msg = [DBHelperConversation getMessage:[messageId intValue] inDB:database];
            if(!msg || msg.deliveryStatus != 1002) continue; //if message not exist or canceled
            [messagesToResend addObject:msg];
            printf(" - will resend");
        }
        printf("\n");
    }
    
    // Sort messages by timestamp (creation date)
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDesc];
    NSArray *sortedMessagesToResend = [messagesToResend sortedArrayUsingDescriptors:sortDescriptors];
    
    int count = [sortedMessagesToResend count];
    if (count > 0)
        DDLogSupport(@"Resending messages (%d) to user: %@", count, buddyQliqId);
    
    
    for (ChatMessage *m in sortedMessagesToResend){
        [self sendMessage:m];
    }
    
}

- (void) resendUndeliveredAcksForQliqId: (NSString *)buddyQliqId
{
	[self resendUndeliveredAcksForQliqId:buddyQliqId inDB:[DBUtil sharedDBConnection]];
}
- (void) resendUndeliveredAcksForQliqId: (NSString *)buddyQliqId inDB:(FMDatabase *)database
{
    
    // Don't resend to self
    NSString *meUserid = [Helper getMyQliqId];
    if ([meUserid compare: buddyQliqId] == NSOrderedSame)
        return;
    
    NSArray *messageIds = [DBHelperConversation getUndeliveredAckMessageIdsForQliqId:buddyQliqId limit:0 inDB:database];
    
    int count = [messageIds count];
    if (count > 0)
        DDLogSupport(@"Resending message acks (%d) to user: %@", count, buddyQliqId);
    
    for (NSNumber *messageId in messageIds)
    {
        ChatMessage *message = [DBHelperConversation getMessage:[messageId intValue] inDB:database];
        [self sendAck:message inDB:database];
        
        // Send notification to UI
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message.metadata.uuid forKey:@"messageGuid"];
        [NSNotificationCenter postNotificationToMainThread:SIPChatMessageAckNotification userInfo:userInfo];
    }
    
}

- (void) processChatUpdateResponseMessage:(QliqSipMessage *) message
{
    
    const int ObsoleteRevisionError = 2;
    
    Buddy *superNode = [[QliqSip sharedQliqSip] superNode];
    if (!superNode)
    {
        DDLogSupport(@"No supernode");
        
        return;
    }
    
    NSDictionary *response = message.data;
    
    NSDictionary *metadataDict = [[response objectForKey:@"result"] objectForKey:@"metadata"];
    
    NSDictionary *errorDict = [response objectForKey:@"error"];
    if (errorDict)
    {
        NSNumber *errorCode = [errorDict objectForKey:@"code"];
        if ([errorCode intValue] != ObsoleteRevisionError)
        {
            return;
        }
        else
        {
            metadataDict = [[errorDict objectForKey:@"currentDoc"] objectForKey:@"metadata"];
        }
    }
    
    if (metadataDict)
    {
        DDLogVerbose(@"md dic: uuid: %@, rev: %@, seq: %@", [metadataDict objectForKey:@"uuid"], [metadataDict objectForKey:@"rev"], [metadataDict objectForKey:@"seq"]);
        Metadata *md = [Metadata metadataFromDict:metadataDict];
        ChatMessage *msg = [DBHelperConversation getMessageWithGuid:md.uuid];
        
        if (msg)
        {
            md.isRevisionDirty = NO;
            [[DBPersist instance] updateTableMetadata:@"message" forRowId:msg.messageId withMetadata:md];
        }
    }
    
}

- (void) onUpdateSuccessful: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid metadata:(Metadata *)md
{
    
    DDLogVerbose(@"Update for %@ uuid %@ was successful", subject, uuid);
	
    if (pushedMessage && [pushedMessage.metadata.uuid compare:uuid] == NSOrderedSame)
    {
#ifdef QLIQ_STOR_SENDS_UPDATE_RESPONSE
        md.isRevisionDirty = NO;
        [[DBPersist instance] updateTableMetadata:@"message" forRowId:pushedMessage.messageId withMetadata:md];
#else
        [DBHelperConversation setRevisionDirtyForUuid:uuid dirty:NO];
#endif
    }
    
}

- (void) onUpdateFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid errorCode:(int)anErrorCode errorMessage:(NSString *)anErrorMessage
{
    DDLogVerbose(@"Update for %@ uuid %@ failed with error %d (%@)", subject, uuid, anErrorCode, anErrorMessage);
}

- (void) onUpdateSendingFailed: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid
{
    DDLogVerbose(@"Update for %@ uuid %@ failed to sent", subject, uuid);
}
- (void) onUpdateFinished: (NSString *)qliqId forSubject:(NSString *)subject forRequestId:(NSString *)requestId forUuid:(NSString *)uuid withStatus:(int)status
{
    
    DDLogVerbose(@"Update for %@ uuid %@ finished", subject, uuid);
    
    if (pushedMessage && [pushedMessage.metadata.uuid compare:uuid] == NSOrderedSame)
    {
        pushedMessage = nil;
        
//        if (status == CompletedRequestStatus)
//            [self pushJustOneUnpushedMessageToDataServer];
    }
}

- (void) initiateResendingOfUndeliveredMessages
{
    
    
    // Try to resend 1 message or 1 ack to every user.
    // If it succeeds then msg status change handler will resend the rest of the messages.
    
    for (Buddy *buddy in [BuddyList getAllBuddies])
    {
        NSArray *ids = [DBHelperConversation getUndeliveredMessageIdsForQliqId: buddy.buddyQliqId limit: 1];
        if ([ids count] > 0)
        {
            NSNumber *idNum = [ids objectAtIndex:0];
            ChatMessage *msg = [DBHelperConversation getMessage: [idNum intValue]];
            if (msg)
            {
                [self sendMessage:msg];
            }
        }
        else
        {
            ids = [DBHelperConversation getUndeliveredAckMessageIdsForQliqId: buddy.buddyQliqId limit: 1];
            if ([ids count] > 0)
            {
                NSNumber *idNum = [ids objectAtIndex:0];
                ChatMessage *msg = [DBHelperConversation getMessage: [idNum intValue]];
                if (msg)
                {
                    [self sendAck: msg];
                }
            }
        }
    }
}

- (void) recreateFailedMultiparties
{
    /* Re-create multiparties */
    ConversationDBService * conversationDBService = [[ConversationDBService alloc]initWithDatabase:[DBUtil sharedDBConnection]];
    NSArray * undeliveredMPConversations = [conversationDBService getConversationsWithoutQliqId];
    for (Conversation * mpConversation in undeliveredMPConversations){
        [self createMultiPartyForConversation:mpConversation];
    }    
}

- (BOOL) processPublicKey:(NSDictionary *)dataDict
{
    
	BOOL userFound = NO;
    
	return userFound;
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

-(void) processInvitation:(NSDictionary *)data
{
    //NSString *uuid = [data objectForKey:INVITATION_DATA_INVITATION_UUID];
    NSDictionary *userInfoDict = [data objectForKey:INVITATION_DATA_SENDER_INFO];
    QliqUser *user = [QliqUser userFromDict:userInfoDict];
	
    Invitation * invitation = [[Invitation alloc] init];
    
    invitation.uuid = [data objectForKey:INVITATION_DATA_INVITATION_UUID];
    invitation.invitedAt = [NSDate timeIntervalSinceReferenceDate];
    invitation.status = InvitationStatusNew;
    invitation.operation = InvitationOperationReceived;
    invitation.url = [data objectForKey:INVITATION_DATA_INVITATION_URL];
	
    [self getQliqUserForID:user.qliqId
                  andEmail:user.email
              completition:^(QliqUser *user) {
                  
                  invitation.contact = user;
                  invitation.contact.contactStatus = ContactStatusInvitationInProcess;
                  
                  if ([[data objectForKey:INVITATION_DATA_ACTION] isEqualToString:INVITATION_DATA_ACTION_INVITE]){
                      if ([[InvitationService sharedService] isInvitationExists:invitation]){
                          UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"%@ remind you about invitation",[user nameDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                          [alert showWithDissmissBlock:NULL];
                      }
                      [[InvitationService sharedService] saveInvitation:invitation];
                  }else if ([[data objectForKey:INVITATION_DATA_ACTION] isEqualToString:INVITATION_DATA_ACTION_CANCEL]) {
                      [[InvitationService sharedService] deleteInvitation:invitation];
                  }
                  
              }];
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
            
            [dataDict setObject:action forKey:INVITATION_DATA_ACTION];
            
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
			
            SipContactDBService * sipContactDBService = [[SipContactDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
            SipContact * recipientContact = [sipContactDBService sipContactForQliqId:recipient.qliqId];
            
			BOOL success = [[QliqSip sharedQliqSip] sendMessage: [jsonDict JSONString] to:recipientContact.sipUri withContext:nil offlineMode:YES pushNotify:NO withDisplayName:myDisplayName withCallId:nil withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:nil withMessageStatusChangedBlock:nil inDB:nil];
            
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

- (void) processApplicationChangeNotification:(NSString *)version
{
}

- (void) processSipConfigChange
{
    DDLogSupport(@"SIP server config change detected (change notification) trying to restart SIP");
    [[QliqSip sharedQliqSip] handleNetworkUp];
}

- (void) processUserChangeNotification:(NSString *)qliqId{
    
    DDLogInfo(@"Processing user change notification, for qliqId: %@",qliqId);
    
    if ([[Helper getMyQliqId] compare: qliqId] == NSOrderedSame) {
        [[GetUserConfigService sharedService] getUserConfig:YES withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            switch (status) {
                case CompletitionStatusSuccess:
                {
                    NSDictionary  *dict = (NSDictionary *)result;
                    BOOL hasSipServerFqdnChanged = [[dict objectForKey:SipServerFqdnChangedKey] boolValue];
                    BOOL hasSipServerConfigChanged = [[dict objectForKey:SipServerConfigChangedKey] boolValue];
                    if (hasSipServerFqdnChanged) {
                        DDLogSupport(@"SIP server fqdn change detected (change notification) will call get_all_contacts");
                        [[GetAllContacts sharedService] getAllContactsWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                            if (status == CompletitionStatusSuccess && hasSipServerConfigChanged) {
                                // After contacts are refreshed restart SIP
                               [self processSipConfigChange];
                            }
                        }];

                    } else if (hasSipServerConfigChanged) {
                        // If SIP server didn't change (just port or transport) then restart immediately
                        [self processSipConfigChange];
                    }
                }
                    break;
                default:
                    break;
            }
        }];
    } else {
        [[GetContactInfoService sharedService] getContactInfo: qliqId];
    }
}

- (void) processGroupChangeNotification:(NSString *)qliqId
{
    
    [[GetGroupInfoService sharedService] getGroupInfo: qliqId];
    
}

- (void) processLoginCredentialsNotification:(NSString *)qliqId{
    DDLogSupport(@"'login_credentials' received for '%@'",qliqId);
    if ([[Helper getMyQliqId] compare: qliqId] == NSOrderedSame) {
        /*Clear login credentials and logout*/
        [[KeychainService sharedService] clearUserData];
        [[Crypto instance] deleteKeysForUser: [UserSessionService currentUserSession].sipAccountSettings.username];
        UserSessionService * sessionService = [[UserSessionService alloc] init];
        [sessionService logoutWithCompletition:nil];
    }
}

- (void) notifyMultipartyWithQliqId:(NSString *) qliqId{
    
    NSDictionary * userInfo = nil;
    if (qliqId) {
        userInfo = @{
        @"qliq_id" : qliqId
        };
    }
    
    [NSNotificationCenter postNotificationToMainThread:RecipientsChangedNotification userInfo:userInfo];
}

- (void) processMultiPartyChangeNotification:(NSString *)qliqId
{
    DDLogSupport(@"change notification 'multiparty' received for '%@'", qliqId);
    [self getMultipartyFromWebservice:qliqId];
}

- (void) getMultipartyFromWebservice:(NSString *)qliqId
{
    // This one method handles all 3 cases when we need to call get_multiparty service
    // 1. Sender sync message to MP
    // 2. First message received of new MP
    // 3. MP change notification
    
    if (![GetMultiPartyService hasOutstandingRequestForMultipartyQliqId:qliqId]) {
        GetMultiPartyService *getMp = [[GetMultiPartyService alloc] initWithQliqId: qliqId];
        [getMp callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess) {
                SipContactDBService * sipContactService = [[SipContactDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
                SipContact *contact = [sipContactService sipContactForQliqId:qliqId];

                if ([contact.sipUri length] > 0) {
                    // Now we have the contact
                    
                    // 1. Handle GetMP call for sender sync to a MP
                    NSMutableArray *array = [messagesToUnknownUsersByQliqId objectForKey:qliqId];
                    if ([array count] > 0) {
                        NSArray *arrayCopy = [array copy];
                        [array removeAllObjects];
                        
                        for (QliqSipExtendedChatMessage *msg in arrayCopy) {
                            [self processExtendedChatMessage:msg];
                        }
                    }
                    
                    // 2. This is GetMP for regular received new MP messages
                    if ([contact.privateKey length] > 0) {
                        [[QliqSip sharedQliqSip] onPrivateKeyReceived:contact.privateKey sipUri:contact.sipUri];
                    } else {
                        DDLogError(@"Cannot retrieve private key for SIP URI: %@", contact.sipUri);
                    }
                    
                    // 3. Notify UI about participants change (will work for CN)
                    [self notifyMultipartyWithQliqId:qliqId];
                    
                } else {
                    DDLogError(@"GetMultiPartyService finished with sucess but cannot retrieve contact for qliq id: %@", qliqId);
                }
            }
        }];
    }
}

- (void) processPresenceChangeNotification:(NSString *)qliqId
{
    DDLogSupport(@"change notification 'presence' received for '%@'", qliqId);
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
    if (user) {
        GetPresenceStatusService *getPresence = [[GetPresenceStatusService alloc] initWithQliqId: qliqId];
        [getPresence callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            [NSNotificationCenter postNotificationToMainThread:PresenceChangeStatusNotification];
        }];
    } else {
        [[GetContactInfoService sharedService] getContactInfo: qliqId];        
    }
}

- (void) processQuickMessagesChangeNotification:(NSString *)qliqId;
{
    DDLogSupport(@"change notification 'quick_message' received for '%@'", qliqId);
    GetQuickMessagesService *getQuickMessages = [[GetQuickMessagesService alloc] initWithQliqId: qliqId];
    [getQuickMessages callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
    }];
}

- (void) processInvitationResponse:(NSDictionary *)invitationResponse {
    
    if (NSOrderedSame == [invitationResponse[INVITATION_SENDER_INFO_CONNECTION_STATE] compare:@"accepted" options:NSCaseInsensitiveSearch]) {
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
    } else if (NSOrderedSame == [invitationResponse[INVITATION_SENDER_INFO_CONNECTION_STATE] compare:@"declined" options:NSCaseInsensitiveSearch]) {
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

- (void)processInvitationRequest:(NSDictionary *)invitationRequest {
    
    [[GetContactInfoService sharedService] getContactInfo:invitationRequest[@"qliq_id"] completitionBlock:^(QliqUser *contact, NSError *error) {
        
        if (nil == error) {
            
            contact.contactStatus = ContactStatusInvitationInProcess;
            
            Invitation *invitation = [[Invitation alloc] init];
            invitation.uuid = invitationRequest[@"invitation_guid"];
            invitation.operation = InvitationOperationReceived;
            invitation.status = InvitationStatusNew;
            invitation.url = invitationRequest[INVITATION_DATA_INVITATION_URL];
            invitation.invitedAt = [invitationRequest[INVITATION_DATA_INVITED_AT] doubleValue];
            invitation.contact = contact;
            
            [[InvitationService sharedService] saveInvitation:invitation];
        }
        
    }];
}

- (void) processSecuritySettingsNotification:(NSString *)deviceUuid
{
    DDLogSupport(@"change notification 'security_settings' received for '%@'", [Helper getMyQliqId]);
    GetSecuritySettingsService *geSecuritySettings = [[GetSecuritySettingsService alloc] initWithDeviceUuid:deviceUuid];
    [geSecuritySettings callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        //if we need to raise an alert, we do here
        //[NSNotificationCenter postNotificationToMainThread:@"<......>" withObject:nil userInfo:nil andWait:YES];
        
    }];
}

- (void) processDeviceChangeNotification:(NSString *)uuid{
    DDLogSupport(@"'device' received for '%@'",uuid);
    if ([[[UIDevice currentDevice] uuid] compare:uuid] == NSOrderedSame) {
        [appDelegate.currentDeviceStatusController refreshRemoteStatus];
    }
}

+ (BOOL) wipeMediafiles{
    
    return [[MediaFileService getInstance] wipeMediafiles];
}

+ (BOOL) wipeData
{
    BOOL wipeSuccess = YES;
    
    FMDatabase *db = [DBUtil sharedDBConnection];
    wipeSuccess &= [DBHelperConversation deleteAllAttachments:db];
    wipeSuccess &= [DBHelperConversation deleteAllMessages:db];
    wipeSuccess &= [DBHelperConversation deleteAllConversations:db];
    wipeSuccess &= [self wipeMediafiles];
    
    return wipeSuccess;
}

- (NSInteger) numberOfDaysBetweenDates :(NSDate *)d1 : (NSDate *)d2
{
    const NSInteger secondsPerMinute = 60;
    const NSInteger minutePerHour = 60;
     
    NSInteger timeInterval = [d2 timeIntervalSinceDate:d1];
    return abs(timeInterval / (secondsPerMinute * minutePerHour));
}

- (void) onPrivateKeyNeeded:(NSNotification *)notification
{
    NSString *sipUri = [[notification userInfo] objectForKey:@"SipUri"];
    NSRange range = [sipUri rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"]];
    NSString *qliqId = [sipUri substringToIndex:range.location];
    QliqGroup *group = [[QliqGroupDBService sharedService] getGroupWithId:qliqId];
    if (group) {
        GetGroupKeyPair *getGKP = [[GetGroupKeyPair alloc] init];
        [getGKP getGroupKeyPairCompletitionBlock:qliqId completionBlock:^(CompletitionStatus status, id result, NSError *error) {
            SipContact *contact = nil;
            if (status == CompletitionStatusSuccess) {
                SipContactDBService *sipContactDBService = [[SipContactDBService alloc] initWithDatabase:[DBUtil sharedDBConnection]];
                contact = [sipContactDBService sipContactForQliqId:qliqId];
            }
            
            if ([contact.privateKey length] > 0) {
                [[QliqSip sharedQliqSip] onPrivateKeyReceived:contact.privateKey sipUri:sipUri];
            } else {
                DDLogError(@"Cannot retrieve group key pair for: %@", qliqId);
            }
        }];

    } else {
        [self getMultipartyFromWebservice:qliqId];
    }
}
- (void) sendParticipantsChangedEventMessageForConversation:(Conversation *)aConversation withNewRecipients:(Recipients *) newRecipients{

    NSString *text = [ChatEventHelper participantsChangedEventFromRecipients:aConversation.recipients toRecipients:newRecipients];
    
    /* Prefer to use MP qliq_id to norify deleted recipients about deletion */

    NSString * toQliqId = aConversation.recipients.qliqId;
    
    if ([newRecipients isMultiparty]){
        toQliqId = newRecipients.qliqId;
    }
    
    [self sendMessage:text toQliqId:toQliqId inConversation:aConversation acknowledgeRequired:NO priority:ChatMessagePriorityNormal type:ChatMessageTypeEvent inDB:[DBUtil sharedDBConnection]];

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

- (void) deleteOldMessages
{
    if (messageRetentionPeriod <= 0)
        return;
    
    DDLogSupport(@"Deleting old messages");

    NSDate *dt = [[NSDate date] dateByAddingTimeInterval:-messageRetentionPeriod];
    NSTimeInterval timestamp = [dt timeIntervalSince1970];
  
    FMDatabase *db = [DBUtil sharedDBConnection];
    [db beginTransaction];
    
    // Delete orphaned media files
    [[MediaFileDBService sharedService] deleteMediaFilesWithoutAttachments];
    
    // This is lower level table/concept but so far there is no better place to call it.
    [EncryptedSipMessageDBService deleteOlderThen:timestamp];
 

    // Get ids of the messages that are old enough and not dirty (are pushed to qliqStor)
    NSArray *messageIds = [DBHelperConversation getMessageIdsOlderThenAndNotDirty:timestamp inDB:nil];
    for (NSNumber *messageIdNum in messageIds) {
        int messageId = [messageIdNum intValue];
        NSString *uuid = [[ChatMessageService sharedService] uuidForMessageId:messageId];

         // 1. First delete attachments
        NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMessageUuid:uuid];
        
        for (MessageAttachment *attachment in attachments) {
            [[MessageAttachmentDBService sharedService] deleteAttachment:attachment];
        }
        
         // 2. Delete status log for that message
        [[MessageStatusLogDBService sharedService] deleteWithMessageId:messageId inDB:db];
        
        // 3. Delete message's qliqstor status (it shouldn't exist for the message, but just in case)
        [MessageQliqStorStatusDBService deleteRowsForMessageId:messageId inDB:db];
        
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
        [[ConversationDBService sharedService] setDeleteFlag:YES forConversationId:conv.conversationId];
        
        // Notify the UI if by any chance this conversation is displayed
        [self notifyConversationDeleted:conv.conversationId];
    }
    
    [db commit];
    
    // Update unread badge since unread messages could be just deleted
    [ChatMessage updateUnreadCountInDb:db];
}

- (void) notifyConversationDeleted:(int)conversationId
{
    NSDictionary *userInfo = @{@"conversationId": [NSNumber numberWithInt:conversationId]};
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

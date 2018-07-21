//
//  QliqSip.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QliqSipProtocols.h"
#import "VoiceCallsController.h"
#import "CallInitiationResult.h"
#import "CallStateChangeInfo.h"
#import "SipAccountSettings.h"
#import "GetPublicKeys.h"
#import "ChatMessage.h"
#import "SipMessage.h"

// 9/8/2014 - Krishna Changed to
//
// Changed to 600 from 1800
// #define SIP_KEEP_ALIVE_INTERVAL 1800
//
#define SIP_KEEP_ALIVE_INTERVAL 600

// Notification Center keys
extern NSString *SIPMessageNotification;
extern NSString *SIPMessageStatusNotification;
extern NSString *SIPPendingMessageStatusNotification;
extern NSString *SIPOpenedMessageStatusNotification;
extern NSString *SIPDeletedMessageStatusNotification;
extern NSString *SIPRecalledMessageStatusNotification;
extern NSString *SIPAckedMessageStatusNotification;
extern NSString *SIPChatMessageAckNotification;
extern NSString *SIPNewCensusNotification;
extern NSString *SIPRegistrationStatusNotification;
extern NSString *SIPUnregistrationStatusNotification;
extern NSString *SIPRegInfoReceivedNotification;
extern NSString *SipMessageDumpFinishedNotification;
extern NSString *SIPRegistrationActionNotification;
extern NSString *SIPMessageDeliveredNotification;
extern NSString *SIPPrivateKeyNeededNotification;
extern NSString *SIPRecipientStatusNotification;
extern NSString *SIPMessageSendingFailedNotification;

typedef enum {
    SipReasonCodeBusyHere   = 486,
    SipReasonCodeDecline    = 603,
    SipReasonNetworkError   = 491
}SipReasonCode;

enum SipError {
	SuccessSipError,
	OfflineSipError,
	EncryptionSipError,
	DecryptionSipError,
	UnknownSipError
};

// Possible registration actions to report to the Settings View
enum SipRegistrationAction {
    NoSipRegistrationAction,
    RegisteringSipRegistrationAction,
    UnregisteringSipRegistrationAction
};

struct QliqSipPrivate;

@interface QliqSip : NSObject <GetPublicKeysDelegate>
{
	struct QliqSipPrivate *d;
	SipAccountSettings *accountSettings;
    VoiceCallsController *voiceCallsController;
}

@property (nonatomic, retain) SipAccountSettings *accountSettings;
@property (nonatomic, assign) id<QliqSipVoiceCallsDelegate> voiceCallsDelegate;
@property (nonatomic, assign) VoiceCallsController* voiceCallsController;
@property (nonatomic, assign) NSInteger lastRegistrationResponseCode;
@property (nonatomic, assign) NSInteger registration5XXErrorCount;
@property (nonatomic, assign) NSInteger currentRegistrationAction;
@property (nonatomic, assign) BOOL transportUp;


- (BOOL)start UNAVAILABLE_ATTRIBUTE;
- (BOOL)registerUser UNAVAILABLE_ATTRIBUTE;
- (BOOL)registerUserWithAccountSettings:(SipAccountSettings *)accountSettings;
- (void)logout;

/* Send Message
 */
- (BOOL)sendMessage:(SipMessage *)msg;

- (BOOL)sendPlainTextMessage:(SipMessage *)msg;

- (BOOL)sendMessage:(NSString *)json
           toQliqId:(NSString *)qliqId;

- (BOOL)sendMessage:(NSString *)json
           toQliqId:(NSString *)qliqId
        withContext:(id)context;

- (BOOL) sendMessage:(NSString *)json
            toQliqId:(NSString *)qliqId
            withUUId:(NSString*)UUId
         withContext:(id)context
         offlineMode:(BOOL)offlineOn
          pushNotify:(BOOL)pushNotify;

- (BOOL)sendMessage:(NSString *)json
           toQliqId:(NSString *)qliqId
        withContext:(id)context
        offlineMode:(BOOL)offlineOn
         pushNotify:(BOOL)pushNotify
    withDisplayName:(NSString *)displayName;

- (BOOL)sendMessage:(NSString *)json
           toQliqId:(NSString *)qliqId
        withContext:(id)context
        offlineMode:(BOOL)offlineOn
         pushNotify:(BOOL)pushNotify
    withDisplayName:(NSString *)displayName
         withCallId:(NSString *)callId
       withPriority:(ChatMessagePriority)priority
         alsoNotify:(NSString *)notifyQliqIds
       extraHeaders:(NSMutableDictionary *)headers withMessageStatusChangedBlock:(MessageStatusChangedBlock)block;

- (SipMessage *)toSipMessage:(NSString *)json
           toQliqId:(NSString *)qliqId
        withContext:(id)context
        offlineMode:(BOOL)offlineOn
         pushNotify:(BOOL)pushNotify
    withDisplayName:(NSString *)displayName
         withCallId:(NSString *)callId
       withPriority:(ChatMessagePriority)priority
         alsoNotify:(NSString *)notifyQliqIds
       extraHeaders:(NSMutableDictionary *)headers withMessageStatusChangedBlock:(MessageStatusChangedBlock)block;


/* Send Status
 */
- (BOOL)sendOpenedStatus:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext;
- (BOOL)sendDeletedStatus:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext;
- (BOOL)sendRecalledStatus:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext alsoNotify:(NSString *)notifyQliqIds;

/* Error
 */
- (int)lastError;
- (NSString *)lastErrorMessage;

- (NSInteger)setRegistered:(BOOL)value;
- (void) setRegistrationTimeout: (BOOL)shortTime;

- (void) registerOrPingInBackground;
- (void) handleNetworkDown;
- (void) handleNetworkUp;
- (void) handleAppDidBecomeActive;
- (void) handleAppDidBecomeInactive;
- (void) keepAliveInBackground;

- (BOOL) isConfigured;
- (BOOL) isRegistered;
- (BOOL) isRegistrationInProgress;
- (BOOL) isTransportUp;
- (BOOL) isMultiDeviceSupported;
- (long) serverTimeDelta;
- (NSTimeInterval) adjustedTimeFromNetwork:(NSTimeInterval)time;
- (NSTimeInterval) adjustTimeForNetwork:(NSTimeInterval)time;

- (int) pendingMessagesCount;
- (int) receivedMessagesCount;

- (void) onPublicKeyReceived: (NSString *)qliqId;
- (void) onPrivateKeyReceived: (NSString *)privateKey qliqId:(NSString *)qliqId;

// Low level method called when a raw SIP message is received. It is made public because we call it when message is sent as remote PUSH notification payload
- (void) onMessageReceived: (NSString *)body fromQliqId:(NSString *)fromQliqId toQliqId:(NSString *)toQliqId mime:(NSString *)mime rxdata:(void *)rdata extraHeaders:(NSDictionary *)extraHeaders;

// protocol GetPublicKeysDelegate
-(void) getPublicKeysSuccess:(NSString *)qliqId;
-(void) didFailToGetPublicKeysWithReason:(NSString *)qliqId withReason:(NSString*)reason withServiceErrorCode:(NSInteger)serviceErrorCode;

+ (id) instance;
+ (QliqSip *) sharedQliqSip;
- (NSString *) findPublicKeyForQliqId: (NSString *)qliqId;
+ (NSString *) privateKeyForQliqId: (NSString *)qliqId;
+ (NSString *) captureRegExp:(NSString *)text withPattern:(NSString *)pattern;
+ (BOOL) haveCredentialsChanged:(NSString *)qliqId email:(NSString *)email pubkeyMd5:(NSString *)pubkeyMd5;

-(BOOL) sipStart;
-(void) sipStop;
- (BOOL) isStarted;

- (NSString *) getLastSentMessagePlainTextBody:(NSString *)callId;

#pragma mark *** Voice calls ***

- (void)setVoiceCodecPriorities;

+ (Contact *)contactForCallId:(NSNumber *)callId;

/* Call
 */
- (CallInitiationResult *)makeCall:(NSString *)qliqId; //returns new call id or -1 on error
- (void)answerCall:(int)call_id;
- (void)declineCall:(int)call_id reasonCode:(SipReasonCode)reasonCode;
- (void)endCall:(int)call_id;
- (void)endAllCalls;

- (void)muteMicForCallWithId:(int)call_id;
- (void)unMuteMicForCallWithId:(int)call_id;

- (void)start_ring:(int)call_id;
- (void)start_ringback;
- (void)stop_ring;
- (void)stop_ringback;
- (void)setPJLogLevel;
- (void)logReconfig;
- (BOOL)shutdownTransport;
- (BOOL)pingServer;
- (void)dualNetworkSetup;

@end

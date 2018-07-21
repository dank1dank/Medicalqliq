//
//  QliqSip.m
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#include <pjlib.h>
#include <pjlib-util.h>
#include <pjmedia.h>
#include <pjmedia-codec.h>
#include <pjsip.h>
#include <pjsip_simple.h>
#include <pjsip_ua.h>
#include <pjsua-lib/pjsua.h>
#import "QliqSip.h"
#import "Crypto.h"
#import "NotificationUtils.h"
#import "PublickeyChangedNotificationSchema.h"
#import "Log.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "KeychainService.h"
#import "Helper.h"
#import "JSONKit.h"
#import "JSONSchemaValidator.h"
#import "MessageSchema.h"
#import "QliqUserDBService.h"
#import "AppDelegate.h"
#import "DBUtil.h"
#import "EncryptedSipMessageDBService.h"
#import "SipContactDBService.h"
#import "GetGroupKeyPair.h"
#import "QliqAPIService.h"
#import "ChatMessage.h"
#import "GetContactInfoService.h"
#import "UpdateSipCredentials.h"
#import "SipMessage.h"
#import "SipServerInfo.h"
#import "BlocksAdditions.h"
#import "SetDeviceStatus.h"
#import "GetDeviceStatus.h"
#import "ReceivedPushNotificationDBService.h"
#import "ChangeNotificationSchema.h"
#import "QxPlatfromIOS.h"

#ifdef DEBUG
//#define DONT_SEND_SIP_MESSAGE_BUT_FAKE_SUCCESS
#endif

#define MIME_TEXT_PLAIN "text/plain"
#define MIME_TEXT_HTML "text/html"
#define MIME_TEXT_BASE64 "application/octet-stream"
#define AT_MIME_TEXT_PLAIN @"text/plain"
#define AT_MIME_TEXT_BASE64 @"application/octet-stream"
#define USER_AGENT "QliqiPhone"
#define USER_AGENT_VERSION "1.0.0"
#define REGISTRATION_RETRY_INTERVAL 15
#define AUTHENTICATION_ERROR_INTERVAL 300

extern NSString *DEFAULT_GROUP_KEY_PASSWORD;

// Configure nameserver if DNS SRV is to be used with both SIP
// or STUN (for STUN see other settings below)
//
#define NAMESERVER      NULL
//#define NAMESERVER    "192.168.0.2"

//
// STUN server
#if 1
// Use this to have the STUN server resolved normally
#   define STUN_DOMAIN  NULL
#   define STUN_SERVER  "stun.pjsip.org"
#elif 0
// Use this to have the STUN server resolved with DNS SRV
#   define STUN_DOMAIN  "pjsip.org"
#   define STUN_SERVER  NULL
#else
// Use this to disable STUN
#   define STUN_DOMAIN  NULL
#   define STUN_SERVER  NULL
#endif

/* Ringtones                US	       UK  */
#define RINGBACK_FREQ1	    440	    /* 400 */
#define RINGBACK_FREQ2	    480	    /* 450 */
#define RINGBACK_ON         2000    /* 400 */
#define RINGBACK_OFF        4000    /* 200 */
#define RINGBACK_CNT        1       /* 2   */
#define RINGBACK_INTERVAL   4000    /* 2000 */

#define RING_FREQ1	  800
#define RING_FREQ2	  640
#define RING_ON		    200
#define RING_OFF	    100
#define RING_CNT	    3
#define RING_INTERVAL	2000

#define RING_FILE 0

#define PJPROJECT_MAKE_SW_NAME(a,b,c,d)     "" #a "." #b "." #c d
#define PJPROJECT_MAKE_SW_NAME2(a,b,c,d)    PJPROJECT_MAKE_SW_NAME(a,b,c,d)
#define PJPROJECT_SOFTWARE_NAME        PJPROJECT_MAKE_SW_NAME2( \
PJ_VERSION_NUM_MAJOR, \
PJ_VERSION_NUM_MINOR, \
PJ_VERSION_NUM_REV, \
PJ_VERSION_NUM_EXTRA)

static const pjsip_method ping_method =
{
	PJSIP_OTHER_METHOD,
	{"PING", 4}
};

NSString *SIPMessageNotification            = @"GeneralMessage";
NSString *SIPMessageStatusNotification      = @"GeneralMessageStatus";
NSString *SIPPendingMessageStatusNotification = @"PendingMessageStatus";
NSString *SIPOpenedMessageStatusNotification = @"SipOpenedMessageStatusNotification";
NSString *SIPDeletedMessageStatusNotification = @"SipDeletedMessageStatusNotification";
NSString *SIPRecalledMessageStatusNotification = @"SIPRecalledMessageStatusNotification";
NSString *SIPAckedMessageStatusNotification = @"SipAckedMessageStatusNotification";
NSString *SIPChatMessageAckNotification     = @"ChatMessageAck";
NSString *SIPNewCensusNotification          = @"NewCensusNotification";
NSString *SIPRegistrationStatusNotification = @"RegistrationStatusNotification";
NSString *SIPUnregistrationStatusNotification = @"UnregistrationStatusNotification";
NSString *SIPRegInfoReceivedNotification    = @"RegInfoReceivedNotification";
NSString *SipMessageDumpFinishedNotification = @"SipMessageDumpFinishedNotification";
NSString *SIPRegistrationActionNotification = @"SipRegistrationActionNotification";
NSString *SIPMessageDeliveredNotification  = @"SIPMessageDeliveredNotification";
NSString *SIPPrivateKeyNeededNotification = @"SIPPrivateKeyNeededNotification";
NSString *SIPRecipientStatusNotification = @"SIPRecipientStatusNotification";
NSString *SIPMessageSendingFailedNotification = @"SIPMessageSendingFailedNotification";

static void on_pager2_cb(pjsua_call_id call_id, const pj_str_t *from,
						const pj_str_t *to, const pj_str_t *contact,
						const pj_str_t *mime_type, const pj_str_t *body,
                        pjsip_rx_data *rdata, pjsua_acc_id acc_id);
static void on_pager_status2_cb(pjsua_call_id call_id,
								const pj_str_t *to,
								const pj_str_t *body,
								void *user_data,
								pjsip_status_code status,
								const pj_str_t *reason,
								pjsip_tx_data *tdata,
								pjsip_rx_data *rdata,
								pjsua_acc_id acc_id);
static void on_reg_state_cb(pjsua_acc_id acc_id);
static void logger_cb(int level, const char *data, int len);
static void on_transport_state_cb(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info);
static NSString *pjstrToNSString(const pj_str_t *pjstr);

#pragma mark -
#pragma mark Voice calls callbacks forward declaration

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_nat_detect_cb(const pj_stun_nat_detect_result *res);
static void on_ice_transport_error(int index, pj_ice_strans_op op,
                                   pj_status_t status, void *param);

#pragma mark -

// Implemented in QxSipLogModule.cpp
pjsip_module *qx_mod_log_handler();
// Implemented in QxSipModules.cpp
pjsip_module *qx_mod_filter_handler();
extern pjsip_module mod_default_handler;
extern pjsip_module mod_encryption_handler;
#ifndef NDEBUG
extern pjsip_module mod_file_logger_handler;
static FILE *s_sipLogFile = NULL;
static int *s_sipLogSocket = -1;
#endif

// Used by mod_encryption_handler to test for encryption errors.
static Crypto *s_crypto;

// Used by background networking code
static pj_thread_desc a_thread_desc;
static pj_thread_t *a_thread;

struct QliqSipPrivate
{
	BOOL sipStarted;
    BOOL sipTransportUp;
	NSMutableDictionary *sentMessages;
    NSMutableDictionary *messagesToResend;
    NSMutableSet *publicKeyRequestsInProgress;
    NSMutableDictionary *messagesFromUnknownUsersByQliqId;
	int lastError;
    BOOL isOnlineSet;
    BOOL wasRegistered;
    BOOL isDoingReRegistration;
    BOOL isRegistrationInProgress;
    int previousRegistrationStatusCode;
	GetPublicKeys *getPublicKeys;
    GetGroupKeyPair *getGroupKeyPairService;
    NSTimeInterval lastRegistrationRequestTimeInterval;
    int serverTimeDelta;
    int pendingMessagesCount;
    int receivedMessagesCount;
    NSTimeInterval timeSinceLastMessageOrNotify;
    NSTimer *messageDumpTimeoutTimer;
    
    pjsua_config cfg;
    pjsua_logging_config log_cfg;
    pjsua_media_config media_cfg;
    pjsua_transport_config transport_cfg;
    pjsua_transport_config rtp_cfg;
    pjsua_acc_config acc_cfg;
    pjsua_acc_id acc_id;
    pj_pool_t *pool;
	pjsip_generic_string_hdr *devKeyHeader;
    pjsip_generic_string_hdr *hashHeader;
    
    pj_bool_t		    ringback_on;
    pj_bool_t		    ring_on;
    int           ringback_slot;
    int           ringback_cnt;
    pjmedia_port *ringback_port;
#if !RING_FILE
    int           ring_slot;
    int           ring_cnt;
    pjmedia_port *ring_port;
#else
    int               ring_cnt;
    SystemSoundID     ring_id;
    CFRunLoopTimerRef ring_timer;
#endif
    // Do we need to really keep those after registration?
    /* pointers to char for account settings */
    char *caor, *creguri, *cdomain, *cusername, *cpassword, *cstun, *coutbound, *creg_instance_id;
    int transport_type;
    pjsua_transport_id transport_id;
    pj_sockaddr server_sock;
    int sockaddr_len;
    
    // For IPv6
    int transport_type6;
    pjsua_transport_id transport_id6;
    pj_sockaddr server_sock6;
    int sockaddr_len6;
};

static QliqSip *_instance;
static pj_str_t *s_userAgent;
static BOOL s_ignoreSipTraffic;

@interface QliqSip()

-(void) accountCfg:(BOOL)useRtpProxy;
-(void) uaCfg:(BOOL)useRtpProxy;
-(void) destroyConnections;

-(int) nextMessageSequence;
- (void) onTransportState: (BOOL)connected;
- (void) onNotify: (NSString *)callId status:(int)aStatus qliqId:(NSString *)aQliqId deliveredRecipientCount:(int)aDeliveredRecipientCount totalRecipientCount:(int)aTotalRecipientCount deliveredAt:(long)aDeliveredAt;
- (void) onOpenedNotify: (NSString *)callId qliqId:(NSString *)aQliqId openedRecipientCount:(int)aOpenedRecipientCount totalRecipientCount:(int)aTotalRecipientCount openedAt:(long)aOpenedAt;
- (void) onRegInfoNotify:(long)serverTimeDelta: (int)pendingMessages;
- (BOOL) sendMessageEncrypt: (SipMessage *)msg;
- (BOOL) pjSendMessage:(SipMessage *)msg mime:(NSString *)mime;
- (void) onPagerStatus: (SipMessage *)md status:(int)status callId:(NSString *)aCallId;
- (void) scheduleMessageResend:(SipMessage *)msg;
- (void) cancelSendingMessages;
- (void) turnRegistrationRetries: (BOOL)on;
- (void) setCurrentRegistrationAction: (NSInteger)action;
- (void) sendLogoutRequest;
- (void) increaseReceivedMessagesCount;
- (void) onMessageDumpTimedOut:(NSTimer *)theTimer;

-(void) sip_ring_init;
-(void) sip_ring_close;
-(void) sip_ring_start;
-(void) sip_ringback_start;
-(void) sip_ringback_stop;
-(void) sip_ring_stop;

- (void) sipThreadMainMethod;
- (void) runOnSipThreadWait:(BOOL)wait block:(BasicBlock)aBlock;

+ (NSString *) captureRegExp:(NSString *)text withPattern:(NSString *)pattern;

@property (nonatomic, retain) NSNumber *activeCallId;
@property (nonatomic, assign) BOOL calling;
@property (nonatomic, retain) NSThread *sipThread;
@property (nonatomic, assign) BOOL shouldStopSipThread;
@property (nonatomic, assign) BOOL areTransportsShutdown;
@property (nonatomic, strong) NSDate *timeAuthenticationError;
@property (nonatomic, strong) NSString *lastSentMessagePlainTextBody;
@property (nonatomic, strong) NSString *lastSentMessageCallId;

@end

@implementation QliqSip

@synthesize accountSettings;
@synthesize voiceCallsDelegate;
@synthesize activeCallId;
@synthesize calling;
@synthesize voiceCallsController;
@synthesize lastRegistrationResponseCode;
@synthesize registration5XXErrorCount;
@synthesize currentRegistrationAction;
@synthesize transportUp;
@synthesize lastSentMessagePlainTextBody;
@synthesize lastSentMessageCallId;

- (id) init
{
	if (self = [super init]) {
		int size = sizeof(struct QliqSipPrivate);
		d = malloc(size);
		memset(d, 0, size);
        
		d->acc_id = -1;
        d->transport_type = PJSIP_TRANSPORT_UNSPECIFIED;
        d->transport_type6 = PJSIP_TRANSPORT_UNSPECIFIED;
        d->transport_id = -1;
        d->transport_id6 = -1;
		d->sentMessages = [[NSMutableDictionary alloc] init];
        d->messagesToResend = [[NSMutableDictionary alloc] init];
        d->publicKeyRequestsInProgress = [[NSMutableSet alloc] init];
        d->messagesFromUnknownUsersByQliqId = [[NSMutableDictionary alloc] init];
		d->lastError = SuccessSipError;
        d->devKeyHeader = NULL;


        d->hashHeader = NULL;
        
        self.activeCallId = [NSNumber numberWithInt:PJSUA_INVALID_ID];
        
        self.areTransportsShutdown = false;
        
        
        voiceCallsController = [[VoiceCallsController alloc] init];
        self.voiceCallsController = voiceCallsController;
		/*register logger before phsua_init()*/
		pj_log_set_log_func(&logger_cb);
        d->sipStarted = NO;
        d->sipTransportUp = NO;
        d->sockaddr_len = 0;
        
        self.sipThread = [[NSThread alloc] initWithTarget:self selector:@selector(sipThreadMainMethod) object:nil];
        [self.sipThread setName:@"QliqSip Thread"];
        [self.sipThread start];
	}
	return self;
}

- (void) dealloc
{
    DDLogSupport(@"SIP dealloc called");
	[self sipStop];
    [self stopSipThread];
	[accountSettings release];
	[d->sentMessages release];
	[d->messagesToResend release];
    [d->messagesFromUnknownUsersByQliqId release];
    [d->publicKeyRequestsInProgress release];
    [d->getPublicKeys release];
    [d->getGroupKeyPairService release];
    free(d->caor);
    free(d->creguri);
    free(d->cdomain);
    free(d->cusername);
    free(d->cpassword);
    free(d->coutbound);
    free(d->creg_instance_id);
	free(d);
    [activeCallId release];
    [voiceCallsController release];
	[super dealloc];
	_instance = nil;
}

+ (QliqSip *) sharedQliqSip
{
    /*
     @synchronized(self) {
     if(_instance == nil)
     _instance = [[super allocWithZone:NULL] init];
     }
     return _instance;*/
    
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[QliqSip alloc] init];
        
    });
    return shared;
}

+ (id) instance
{
	return [self sharedQliqSip];
}

- (void) sipThreadMainMethod
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //A runloop with no sources returns immediately from runMode:beforeDate:
    //That will wake up the loop and chew CPU. Add a dummy source to prevent
    //it.
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    NSMachPort *dummyPort = [[NSMachPort alloc] init];
    [runLoop addPort:dummyPort forMode:NSDefaultRunLoopMode];
    [dummyPort release];
    [pool release];
    
    while (!self.shouldStopSipThread)
    {
//        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        @autoreleasepool {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
//        [loopPool drain];
//        [loopPool release];
    }
    
    return;
}

- (void) stopSipThread
{
    if (self.sipThread) {
        [self runOnSipThreadWait:YES block:^{
            self.shouldStopSipThread = YES;
        }];
        self.sipThread = nil;
    }
}

- (void) runOnSipThreadWait:(BOOL)wait block:(BasicBlock)aBlock
{
    RunOnThread(self.sipThread, wait, aBlock);
}

- (void) sipStop
{
    DDLogSupport(@"!!! SIP stop called");
	if (d->sipStarted)
    {
        d->sipStarted = NO;
        [self runOnSipThreadWait:YES block: ^{
    #ifndef DEBUG // I don't need to see this dump - Adam
            pjsua_dump(1);
    #endif
            
            [self cancelSendingMessages];
            [d->sentMessages removeAllObjects];
            [d->messagesToResend removeAllObjects];
            [d->messagesFromUnknownUsersByQliqId removeAllObjects];
            
            self.sip_ring_close;
            
            pj_status_t status = PJ_SUCCESS;
            
            if (d->acc_id != -1)
            {
                status = pjsua_acc_del(d->acc_id);
                if (status == PJ_SUCCESS) {
                    d->acc_id = -1;
                } else {
                    DDLogError(@"Cannot delete SIP account, status: %d", status);
                }
            }
            
            // 8/12/2014 - Krishna
            // No need of closing transports.
            // Transports are shutdown already
            //
            //unsigned int count = 10;
            //pjsua_transport_id tids[count];
            //pjsua_enum_transports(tids, &count);
            //for (unsigned int i = 0; i < count; ++i) {
            //    status = pjsua_transport_close(tids[i], PJ_FALSE);
            //    if (status != PJ_SUCCESS) {
            //        DDLogError(@"Cannot close pjproject's %d-nth transport, status: %d", i, status);
            //    }
            //}
            
            pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), qx_mod_log_handler());
            pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), qx_mod_filter_handler());
            pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), &mod_default_handler);
            pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), &mod_encryption_handler);
#ifndef NDEBUG
            pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), &mod_file_logger_handler);
            if (s_sipLogFile) {
                fclose(s_sipLogFile);
                s_sipLogFile = NULL;
            }
#endif
            
            if (d->devKeyHeader)
            {
                pj_list_erase(d->devKeyHeader);
                d->devKeyHeader = NULL;
            }
            

            
            if (d->hashHeader)
            {
                pj_list_erase(d->hashHeader);
                d->hashHeader = NULL;
            }
            pjsua_destroy2(PJSUA_DESTROY_NO_NETWORK);
            // TODO Crashing here when logging out
            // pj_pool_release(d->pool);
            d->pool = NULL;
            d->acc_id = -1;
            d->transport_id = -1;
            d->transport_id6 = -1;
            d->isOnlineSet = NO;
            d->sipTransportUp = NO;
            d->wasRegistered = NO;
        }];
	}    
}

- (BOOL) isStarted
{
    return d->sipStarted;
}

- (NSString *) getLastSentMessagePlainTextBody:(NSString *)callId
{
    if ([callId length] == 0 || [callId isEqualToString:self.lastSentMessageCallId]) {
        return self.lastSentMessagePlainTextBody;
    } else {
        return nil;
    }
}

- (BOOL)registerUserWithAccountSettings:(SipAccountSettings *)accountSettings {
    
    DDLogSupport(@"registerUserWithAccountSettings called");

    // Stop if SIP is already started
    if (d->sipStarted) {
        [self sipStop];
    }
    
    self.accountSettings = accountSettings;
    
	if (accountSettings == nil) {
		DDLogError(@"No sip account settings configured");
		return NO;
	}
	
    NSString *sipUri = accountSettings.sipUri;
	NSInteger location = [sipUri rangeOfString:@"@"].location;
	if (nil == sipUri || location == NSNotFound) {
		DDLogError(@"Cannot find '@' in user sip uri: %@", sipUri);
		return NO;
	}
    
    if (![QxPlatfromIOS isUserSessionStarted]) {
        DDLogWarn(@"Attempting to start SIP but qxlib session not started. Starting now");
        [QxPlatfromIOS onUserSessionStarted];
    }
    
    NSString *username = [sipUri substringToIndex:location];
	
    //accountSettings.serverInfo.fqdn = @"[2001:2:0:1baa::4514:3760]";
    
    NSString *domain = [[accountSettings serverInfo] fqdn];
	NSString *passwordMd5 = [[KeychainService sharedService] base64ToMd5:[accountSettings password]];
	//NSLog(@"password md5: %@",passwordMd5);
    
	// Truncate password to 25 chars due to server bug
    NSString *password = [[passwordMd5 substringToIndex:25] lowercaseString];
    NSString *outbound = nil; // "sips.qliqsoft.net;lr;transport=tcp"

    NSString *transportStr = [[accountSettings serverInfo] transport];
    int port = [[accountSettings serverInfo] port];

    
//    accountSettings.serverInfo.transport = @"TLS6";
    free(d->cdomain);
    d->cdomain = strdup([domain UTF8String]);
    
    // Dual Network Setup
    [self dualNetworkSetup];
    
    NSString *sipAoR = [NSString stringWithFormat:@"sip:%@@%@", username, domain];
    NSString *regUri = [NSString stringWithFormat:@"sip:%@", domain];
	NSString *outboundUri = nil;
	
    if ([outbound length] > 0) {
        outboundUri = [NSString stringWithFormat:@"sip:%@", outbound];
    } else {
        /* if no explicit OBP use the domain as OBP (to send requests always via home proxy) */
        outboundUri = [NSString stringWithFormat:@"sip:%@:%d;lr", domain, port];
        if ([transportStr isEqualToString:@"UDP"] )  {
            outboundUri = [outboundUri stringByAppendingString:@";transport=udp"];
        } else if ( [transportStr isEqualToString:@"TCP"] )  {
            outboundUri = [outboundUri stringByAppendingString:@";transport=tcp"];
        } else if ([transportStr isEqualToString:@"TLS"] )  {
            outboundUri = [outboundUri stringByAppendingString:@";transport=tls"];
        }
    }
    DDLogVerbose(@"outbound: %@", outboundUri);
	
    free(d->caor);
    free(d->creguri);
    free(d->cusername);
    free(d->cpassword);
    free(d->coutbound);
	
	d->caor = strdup([sipAoR UTF8String]);
	d->creguri = strdup([regUri UTF8String]);
	d->cusername = strdup([username UTF8String]);
	d->cpassword = strdup([password UTF8String]);
	d->coutbound = strdup([outboundUri UTF8String]);
    
    
        /* Create Media Transport for SIP */
    //pjsua_transport_config_default(&d->rtp_cfg);
    //d->rtp_cfg.port = 4000;
    //d->rtp_cfg.qos_type = PJ_QOS_TYPE_VOICE;
    //status = pjsua_media_transports_create(&d->rtp_cfg);
    
    //if (status != PJ_SUCCESS) {
    //    DDLogError(@"Error creating media transports, %d", status);
    //    pjsua_destroy();
    //    return NO;
    //}
    
    return [self sipStart];
}

- (BOOL)dualNetworkSetup {
    DDLogSupport(@"dualNetworkSetup");
    SipAccountSettings *accountSettings = [UserSessionService currentUserSession].sipAccountSettings;
    NSString *domain = [[accountSettings serverInfo] fqdn];
    pj_str_t domainip;
    domainip.ptr = d->cdomain;              // May be we need to do gethostbyname() in case the ip is domain name
    domainip.slen = strlen(d->cdomain);
    NSString *transportStr = [[accountSettings serverInfo] transport];
    int port = [[accountSettings serverInfo] port];
    pj_status_t status;
    
    d->transport_type = PJSIP_TRANSPORT_UNSPECIFIED;
    
    //    NSString *transportStr = @"UDP";
    //
    if ([transportStr isEqualToString:@"TCP"]) {
        d->transport_type = PJSIP_TRANSPORT_TCP;
        d->transport_type6 = PJSIP_TRANSPORT_TCP6;
    } else if ([transportStr isEqualToString:@"UDP"]) {
        d->transport_type = PJSIP_TRANSPORT_UDP;
        d->transport_type6 = PJSIP_TRANSPORT_UDP6;
    } else if ([transportStr isEqualToString:@"TLS"]) {
        d->transport_type = PJSIP_TRANSPORT_TLS;
        d->transport_type6 = PJSIP_TRANSPORT_TLS6;
        d->transport_cfg.tls_setting.method = PJSIP_TLSV1_2_METHOD;
    }
    
    // Initialize for IPv4
    //
    pj_bzero(&d->server_sock, sizeof(d->server_sock));
    d->sockaddr_len = sizeof(pj_sockaddr_in);
    d->server_sock.addr.sa_family = pj_AF_INET();
    status = pj_sockaddr_init(d->server_sock.addr.sa_family,&d->server_sock,&domainip, port);
    
    if (status != PJ_SUCCESS) {
        DDLogError(@"Failed to init server_sock for family %@, status=%d", (d->server_sock.addr.sa_family == pj_AF_INET() ? @"IPv4" : @"IPv6"), status);
    }
    
    // Initialize for IPv6
    //
    pj_bzero(&d->server_sock6, sizeof(d->server_sock6));
    d->sockaddr_len6 = sizeof(pj_sockaddr_in6);
    d->server_sock6.addr.sa_family = pj_AF_INET6();
    status = pj_sockaddr_init(d->server_sock6.addr.sa_family,&d->server_sock6,&domainip, port);
    
    if (status != PJ_SUCCESS) {
        DDLogError(@"Failed to init server_sock6 for family %@, status=%d", (d->server_sock6.addr.sa_family == pj_AF_INET() ? @"IPv4" : @"IPv6"), status);
    }
    
}

- (BOOL)sipStart {
    DDLogSupport(@"!!! SIP start called");
   
	BOOL useRtpProxy = YES;
    
    Crypto *crypto = [Crypto instance];
    NSString *pubKey = [crypto publicKeyString];
    if ([pubKey length] == 0) {
        DDLogError(@"Cannot start SIP because keys are not open");
        return NO;
    }
	
    // We loose the BOOL return value of the below block but we want this to be async to avoid UI thread blocking
    [self runOnSipThreadWait:NO block:^{
        if (d->pool != NULL) {
            DDLogError(@"sipStart called while already started");
            return;
        }
        
        pj_status_t status = pjsua_create();
        if (status != PJ_SUCCESS) {
            DDLogError(@"Error in pjsua_create(): %d", status);
            pjsua_destroy2(PJSUA_DESTROY_NO_NETWORK);
            
            return /*NO*/;
        }
    
        // Create pool for application
        d->pool = pjsua_pool_create(USER_AGENT, 1000, 1000);
        
        pjsua_config_default(&d->cfg);
        [self uaCfg:useRtpProxy];

        NSString * deviceName = [[UIDevice currentDevice] name];
        deviceName = [deviceName stringByAppendingFormat:@" (%@)", [[UIDevice currentDevice] platformString]];
        
        // For unknown reason it sometimes crashes inside pj_ansi_snprintf()
        char tmp[256];
        pj_ansi_snprintf(tmp, sizeof(tmp), "%s (iOS %s) pjproject %s", [deviceName UTF8String], [[AppDelegate currentBuildVersion] UTF8String], PJPROJECT_SOFTWARE_NAME);
        pj_strdup2_with_null(d->pool, &(d->cfg.user_agent), tmp);
        s_userAgent = &(d->cfg.user_agent);
        
        status = pjsua_init(&d->cfg, &d->log_cfg, &d->media_cfg);
        
        if (status != PJ_SUCCESS) {
            DDLogError(@"SIPUA failed to Init. Error in pjsua_init(): %d", status);
            pjsua_destroy2(PJSUA_DESTROY_NO_NETWORK);
            
            return /*NO*/;
        }
        
        // qxlib logdb module
        pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                    qx_mod_log_handler());
        
        pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                    qx_mod_filter_handler());
        
        // Initialize our module to handle otherwise unhandled request
        pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                             &mod_default_handler);
        
        // Initialize our module to handle undeciperable messages
        pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                             &mod_encryption_handler);
        
#ifndef NDEBUG
        pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                    &mod_file_logger_handler);
        BOOL disabled = YES;
        if (!disabled && !s_sipLogFile) {
            NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *filePath = [docsPath stringByAppendingPathComponent:@"sip_log.txt"];
            s_sipLogFile = fopen([filePath UTF8String], "w");
            
//            s_sipLogSocket = socket(PF_INET, SOCK_STREAM, 0);
//            if (s_sipLogSocket > -1) {
//                // Bind to a specific network interface (and optionally a specific local port)
//                struct sockaddr_in localaddr;
//                localaddr.sin_family = AF_INET;
//                localaddr.sin_addr.s_addr = "";
//                localaddr.sin_port = 0;  // Any local port will do
//                bind(s_sipLogSocket, (struct sockaddr *)&localaddr, sizeof(localaddr));
//                
//                // Connect to the remote server
//                struct sockaddr_in remoteaddr;
//                remoteaddr.sin_family = AF_INET;
//                remoteaddr.sin_addr.s_addr = inet_addr(SIP_LOG_SERVER_IP);
//                remoteaddr.sin_port = htons(SIP_LOG_SERVER_PORT);
//                connect(s_sipLogSocket, (struct sockaddr *)&remoteaddr, sizeof(remoteaddr));
//            }
        }
#endif
        
        // Register support for our custom LOGOUT request.
        const pj_str_t logout_tag = {"LOGOUT", 6};
        pjsip_endpt_add_capability(pjsua_get_pjsip_endpt(), &mod_encryption_handler, PJSIP_H_ALLOW, NULL, 1, &logout_tag);
        
        /* add transport to pjsua */
        pjsua_transport_config_default(&d->transport_cfg);
        /* Create Signaling Transort for SIP */
        
        pjsua_transport_config transport_cfg;
        
        pjsua_transport_config_default(&transport_cfg);
        transport_cfg.tls_setting.method = PJSIP_TLSV1_2_METHOD;
        status = pjsua_transport_create(d->transport_type, &transport_cfg, &d->transport_id);
        
        if (status != PJ_SUCCESS) {
            DDLogError(@"Failed to create transport for IPv4: status=%d", status);
        }
        
        pjsua_transport_config_default(&transport_cfg);
        transport_cfg.tls_setting.method = PJSIP_TLSV1_2_METHOD;
        status = pjsua_transport_create(d->transport_type6, &transport_cfg, &d->transport_id6);
        
        if (status != PJ_SUCCESS) {
            DDLogError(@"Failed to create transport for IPv6: status=%d", status);
        }
        
        /*
        status = pjsua_transport_create(d->transport_type, &d->transport_cfg, &d->transport_id);
        
        if (status != PJ_SUCCESS) {
            DDLogError(@"Error creating transport: %d", status);
            pjsua_destroy2(PJSUA_DESTROY_NO_NETWORK);
            
            return;
        }
        */
        status = pjsua_start();
        if (status != PJ_SUCCESS) {
            DDLogError(@"Error starting pjsua: %d", status);
            pjsua_destroy2(PJSUA_DESTROY_NO_NETWORK);
            return;
        }
        
        /* Configure the account */
        [self accountCfg:useRtpProxy];
        
        d->isRegistrationInProgress = YES;
        [self setCurrentRegistrationAction:RegisteringSipRegistrationAction];
        status = pjsua_acc_add(&d->acc_cfg, PJ_TRUE, &d->acc_id);
        if (status != PJ_SUCCESS) {
            d->isRegistrationInProgress = NO;
            [self setCurrentRegistrationAction:NoSipRegistrationAction];

            DDLogError(@"Failure adding the account! Inspect the debug window");
            
            return /*NO*/;
        }
        
        
        // Set codec priorities
        self.setVoiceCodecPriorities;
        
        //	pjsua_pres_dump(PJ_TRUE);
        //status = pjsua_acc_set_online_status(d->acc_id, PJ_TRUE);
        //if (status != PJ_SUCCESS)
        //	DDLogSupport(@"Cannot set SIP status to online: %d", status);
        
        
        /* tell the applicaton that the SIP stack is ready now */
        //d->status = Private::Online;
        

        s_ignoreSipTraffic = NO;
        
        [self sip_ring_init];
        DDLogInfo(@"SIP startup successful");
        d->sipStarted = YES;
    }];
    
    return YES;
}

- (void) uaCfg:(BOOL)useRtpProxy
{
    
    // pjsua_config_default(&d->cfg);
	
    /* Configure the Name Servers */
    /* We try to fetch the nameservers from the OS, because
	 pjsip supports SRV lookups only with the own resolver */
    d->cfg.nameserver_count = 0;
    for (int count = 0; count < 4; count++) {
        if (d->cfg.nameserver[count].ptr) {
            free(d->cfg.nameserver[count].ptr);
            d->cfg.nameserver[count].ptr = 0;
            d->cfg.nameserver[count].slen = 0;
        }
    }
	
    /* Configure how PJSIP routes */
    d->cfg.force_lr = PJ_TRUE;
	
    /* initialize pjsua callbacks */
	
    d->cfg.cb.on_pager2 = on_pager2_cb;
    d->cfg.cb.on_pager_status2 = on_pager_status2_cb;
    d->cfg.cb.on_reg_state = on_reg_state_cb;
    d->cfg.cb.on_incoming_call = on_incoming_call;
    d->cfg.cb.on_call_media_state = on_call_media_state;
    d->cfg.cb.on_call_state = on_call_state;
    d->cfg.cb.on_transport_state = on_transport_state_cb;
    
    
    d->cfg.use_timer = PJSUA_SIP_TIMER_ALWAYS;
    
    /* configure STUN server (activates NAT traversal)*/
	//    if (!d->stun.isEmpty()) {
	//        d->cfg.stun_srv_cnt=1;
	//        d->cfg.stun_srv[0] = pj_str(d->stun.toLatin1().data());
	//        //ui.natTypeEdit->setText("NAT detection in progress ...");
	//    }
    
    if (useRtpProxy == NO)
    {
        if (NAMESERVER) {
            d->cfg.nameserver_count = 1;
            d->cfg.nameserver[0] = pj_str(NAMESERVER);
        }
        
        if (NAMESERVER && STUN_DOMAIN) {
            d->cfg.stun_domain = pj_str(STUN_DOMAIN);
        } else if (STUN_SERVER) {
            d->cfg.stun_host = pj_str(STUN_SERVER);
        }
    }
    
    d->cfg.cb.on_nat_detect = on_nat_detect_cb;
	
    // Logging
    pjsua_logging_config_default(&d->log_cfg);
	
	[self setPJLogLevel];
	
	d->log_cfg.cb = &logger_cb;
    d->log_cfg.decor = d->log_cfg.decor & ~PJ_LOG_HAS_NEWLINE & ~PJ_LOG_HAS_TIME &~PJ_LOG_HAS_MICRO_SEC;
	
    pjsua_media_config_default(&d->media_cfg);
    
    /* Media quality settings */
    d->media_cfg.no_vad = PJ_TRUE;
    d->media_cfg.clock_rate = 8000;
    d->media_cfg.audio_frame_ptime = 40;
    d->media_cfg.ec_tail_len = 0;
    d->media_cfg.quality = 3;
    d->media_cfg.thread_cnt = 2;
    d->media_cfg.snd_auto_close_time  = 0;
    d->media_cfg.ilbc_mode = 30;
    
    d->media_cfg.jb_init = 200;
    d->media_cfg.jb_min_pre = 80;
    d->media_cfg.jb_max_pre = 330;
    d->media_cfg.jb_max = 400;
    
    /* ICE settings */
    
    if (useRtpProxy == NO)
    {
        d->media_cfg.enable_ice = PJ_TRUE;
        d->media_cfg.ice_max_host_cands = 2;
        d->media_cfg.ice_no_rtcp = PJ_TRUE;
    }
    
}

- (void) accountCfg:(BOOL)useRtpProxy
{
    /* register Account */
    pjsua_acc_config_default(&d->acc_cfg);
	
	
    d->acc_cfg.id = pj_str(d->caor);
    d->acc_cfg.reg_uri = pj_str(d->creguri);
	
    d->acc_cfg.cred_count = 1;
    d->acc_cfg.cred_info[0].realm = pj_str(d->cdomain);
    d->acc_cfg.cred_info[0].scheme = pj_str("digest");
    d->acc_cfg.cred_info[0].username = pj_str(d->cusername);
    d->acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    d->acc_cfg.cred_info[0].data = pj_str(d->cpassword);
    /* do not specify the transport id as this will cause pjsip to open
	 * a new TCP connection for every request. IMO this is a bug. See also
	 * http://lists.pjsip.org/pipermail/pjsip_lists.pjsip.org/2009-July/008183.html
	 */
    
    d->acc_cfg.proxy_cnt = 1;
    d->acc_cfg.proxy[0] = pj_str(d->coutbound);
	d->acc_cfg.publish_enabled = PJ_FALSE;
	
    /* SRTP account settings */
	d->acc_cfg.use_srtp = PJMEDIA_SRTP_DISABLED; // PJMEDIA_SRTP_OPTIONAL, PJMEDIA_SRTP_MANDATORY
	d->acc_cfg.srtp_secure_signaling = 0; // none, tls=1, sips=2
	
    /* Registration Retry when there is a failure */
    d->acc_cfg.reg_retry_interval = REGISTRATION_RETRY_INTERVAL;    /* seconds */
    d->acc_cfg.reg_first_retry_interval = REGISTRATION_RETRY_INTERVAL;
    
	/* d->acc_cfg.reg_timeout = 60 * 5; */
	
	/* Disable Contact Rewrite since NAT is supported on the Server */
	/* Krishna 10/2/11 */
    d->acc_cfg.allow_contact_rewrite = 0;
	
	/* 600 sec (10 mins) is the background timer's interval, so
	 * we add extra 2 mins here to make sure we can register within this time
	 */
	// Make it 6 times the KEEP_ALIVE so that we do not need to register while
	// Going into background mode
	d->acc_cfg.reg_timeout = 6*SIP_KEEP_ALIVE_INTERVAL + 60 ;
        // Don't wait for unregistration response
        d->acc_cfg.unreg_timeout = 1;
    
    /* Keep-Alive PING PONG Data CRLFCRLF the server return CRLF*/
    d->acc_cfg.ka_data.ptr = "\r\n\r\n";
    d->acc_cfg.ka_data.slen = 4;
    // Disable keep alive
    d->acc_cfg.ka_interval = 0;
    
    /* drop all calls if the registration fails */
    d->acc_cfg.drop_calls_on_reg_fail = 1;
    
    // KK 9/24/2015
    // turn off using source port so that gethostbyname() is not called
    //
    d->acc_cfg.contact_use_src_port = 0;
    
    
    Crypto *crypto = [Crypto instance];
    NSString *pubKey = [crypto publicKeyString];
    if ([pubKey length] > 0) {
        NSString *pubKeyHash = [pubKey md5];
        //    char *contact_params = strdup([[NSString stringWithFormat:@";X-hash=%@", pubKeyHash] UTF8String]);
        //    NSLog(@"contact_params: %s", contact_params);
        //    d->acc_cfg.contact_params = pj_str(contact_params);
        if ([pubKeyHash length] > 0)
        {
            
            pj_str_t hname = pj_str("X-hash");
            pj_str_t hvalue = pj_str([pubKeyHash UTF8String]);
            d->hashHeader = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
            pj_list_push_back(&d->acc_cfg.reg_hdr_list, d->hashHeader);
            DDLogInfo(@"Sending our X-hash: %@", pubKeyHash);
        }
    } else {
        DDLogError(@"The public key is empty (keys are not available)");
    }
    
    {
        // Sound profile
        SoundSettings *soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
        NSString *priorities = @[NotificationPriorityNormal, NotificationPriorityUrgent, NotificationPriorityASAP, NotificationPriorityFYI];
        NSString *headers[] = {@"X-normal", @"X-urgent", @"X-asap", @"X-fyi"};
        int i= 0;
        for (NSString *priority in priorities) {
            NotificationsSettings *notificationSettings = [soundSettings notificationsSettingsForPriority:priority];
            Ringtone *ringtone = [notificationSettings ringtoneForType:NotificationTypeIncoming];
            int interval = notificationSettings.reminderChimeInterval;
            NSString *fileName = [ringtone filename];
            NSString *value = [NSString stringWithFormat:@"repeat=%d; sound=\"%@\"", (interval * 60), fileName];
            //NSLog(@"%@: %@", headers[i], value);
            
            pj_str_t hname = pj_str([headers[i] UTF8String]);
            pj_str_t hvalue = pj_str([value UTF8String]);
            pjsip_generic_string_hdr *str_hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
            pj_list_push_back(&d->acc_cfg.reg_hdr_list, str_hdr);
            
            ++i;
        }
    }
    
    NSString *deviceKey = [QliqStorage sharedInstance].deviceToken;
    if ([deviceKey length] > 0)
	{
        pj_str_t hname = pj_str("X-devkey");
        pj_str_t hvalue = pj_str([deviceKey UTF8String]);
        d->devKeyHeader = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
        pj_list_push_back(&d->acc_cfg.reg_hdr_list, d->devKeyHeader);
        hname = pj_str("X-wakeup-app");
        hvalue = pj_str("yes");
        pjsip_generic_string_hdr *str_hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
        pj_list_push_back(&d->acc_cfg.reg_hdr_list, str_hdr);
    }
    else
    {
        DDLogSupport(@"Push Notification is not enabled!");
        d->devKeyHeader = nil;
    }
    
    NSString *voipDeviceKey = [QliqStorage sharedInstance].voipDeviceToken;
    if ([voipDeviceKey length] > 0)
    {
        pj_str_t hname = pj_str("X-voip-devkey");
        pj_str_t hvalue = pj_str([voipDeviceKey UTF8String]);
        pj_list_push_back(&d->acc_cfg.reg_hdr_list, pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue));
    }
    else
    {
        DDLogSupport(@"VoiP Push Notification is not enabled!");
    }
    
#if DEBUG
    {
        pj_str_t hname = pj_str("X-sandbox");
        pj_str_t hvalue = pj_str("yes");
        pjsip_generic_string_hdr *str_hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
        pj_list_push_back(&d->acc_cfg.reg_hdr_list, str_hdr);
    }
#endif
    
    // The app supports processing of bulk-cn
    //
    pj_str_t hname = pj_str("X-bulk-cn-supported");
    pj_str_t hvalue = pj_str("yes");
    pjsip_generic_string_hdr *str_hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
    pj_list_push_back(&d->acc_cfg.reg_hdr_list, str_hdr);
    
    // Add X-send-all-messages when the DB is empty
    // Krishna 6/5/2015
    // Removed this. Instead we add in get_user_config
    //
    //if ([[DBUtil sharedInstance] isNewDatabase]) {
    //    DDLogSupport(@"X-send-all-messages is added to REGISTER!");
    //    pj_str_t hname = pj_str("X-send-all-messages");
    //    pj_str_t hvalue = pj_str("yes");
    //    pjsip_generic_string_hdr *str_hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
    //    pj_list_push_back(&d->acc_cfg.reg_hdr_list, str_hdr);
    //}
    
    NSString *deviceUuid = [[UIDevice currentDevice] qliqUUID];
    if (deviceUuid.length > 0) {
        free(d->creg_instance_id);
        NSString *regid = [NSString stringWithFormat:@"<urn:uuid:%@>", deviceUuid];
        d->creg_instance_id = strdup([regid UTF8String]);
        d->acc_cfg.rfc5626_instance_id = pj_str(d->creg_instance_id);
        d->acc_cfg.use_rfc5626 = 1;
    } else {
        DDLogError(@"Cannot retrieve device uuid for registration request");
    }

}


- (void) logout
{

    DDLogInfo(@"SIP: logout called");
    
    if (d->sipStarted)
    {
        
        [self sendLogoutRequest];
        
        // Krishna 4/5/2017
        // Do not send Account Setting to NIL here. It may crash the App
        // self.accountSettings = nil;

        //[self unsubscribeAllBudies];
        d->isDoingReRegistration = FALSE;
        d->previousRegistrationStatusCode = 0;
        DDLogSupport(@"SIP: Doing unregistration at logout");
        //pjsua_acc_set_registration(d->acc_id, PJ_FALSE);
        [self setRegistered:NO];
    }
    
}

- (BOOL) sendMessage: (NSString *)json toQliqId:(NSString *)qliqId
{
    
    return [self sendMessage:json toQliqId:qliqId withContext:nil];
    
}

- (BOOL) sendMessage: (NSString *)json toQliqId:(NSString *)qliqId withContext:(id)context
{
    
    return [self sendMessage:json toQliqId:qliqId withContext:context offlineMode:NO pushNotify:NO];
    
}

- (BOOL) sendMessage: (NSString *)json toQliqId:(NSString *)qliqId withUUId:(NSString*)callId withContext:(id)context offlineMode:(BOOL)offlineOn pushNotify:(BOOL)pushNotify
{
    
    return [self sendMessage:json toQliqId:qliqId withContext:context offlineMode:offlineOn pushNotify:pushNotify withDisplayName:nil withCallId:callId withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:nil withMessageStatusChangedBlock:nil];
    
}

- (BOOL) sendMessage: (NSString *)json toQliqId:(NSString *)qliqId withContext:(id)context offlineMode:(BOOL)offlineOn pushNotify:(BOOL)pushNotify withDisplayName:(NSString *)displayName
{
    
    return [self sendMessage:json toQliqId:qliqId withContext:context offlineMode:offlineOn pushNotify:pushNotify withDisplayName:displayName withCallId:nil withPriority:ChatMessagePriorityUnknown alsoNotify:nil extraHeaders:nil withMessageStatusChangedBlock:nil];
    
}

- (SipMessage *) toSipMessage: (NSString *)json toQliqId:(NSString *)qliqId withContext:(id)userData offlineMode:(BOOL)offlineOn pushNotify:(BOOL)pushNotify withDisplayName:(NSString *)displayName withCallId:(NSString *)callId withPriority:(ChatMessagePriority)priority alsoNotify:(NSString *)notifyQliqIds extraHeaders:(NSMutableDictionary *)headers  withMessageStatusChangedBlock:(MessageStatusChangedBlock)block
{
    SipMessage *md = [[[SipMessage alloc] init] autorelease];
    md.seq = [self nextMessageSequence];
    md.toQliqId = qliqId;
    md.plainText = json;
    md.publicKey = @"";
    md.context = userData;
    md.offlineMode = offlineOn;
    md.pushNotify = pushNotify;
    md.displayName = displayName;
    md.statusChangedBlock = block;
    md.callId = callId;
    md.priority = priority;
    BOOL multiparty;
    BOOL group;
    md.publicKey = [self findPublicKeyForQliqId:md.toQliqId isMultiParty:&multiparty isGroup:&group];
    md.multiparty = multiparty;
    md.groupMessage = group;
    md.alsoNotify = notifyQliqIds;
    md.extraHeaders = headers;
    return md;
}

- (BOOL) sendMessage: (NSString *)json toQliqId:(NSString *)qliqId withContext:(id)userData offlineMode:(BOOL)offlineOn pushNotify:(BOOL)pushNotify withDisplayName:(NSString *)displayName withCallId:(NSString *)callId withPriority:(ChatMessagePriority)priority alsoNotify:(NSString *)notifyQliqIds extraHeaders:(NSMutableDictionary *)headers  withMessageStatusChangedBlock:(MessageStatusChangedBlock)block
{
    SipMessage *md = [[[SipMessage alloc] init] autorelease];
    md.seq = [self nextMessageSequence];
    md.toQliqId = qliqId;
    md.plainText = json;
    md.publicKey = @"";
    md.context = userData;
    md.offlineMode = offlineOn;
    md.pushNotify = pushNotify;
    md.displayName = displayName;
    md.statusChangedBlock = block;
    md.callId = callId;
    md.priority = priority;
    BOOL multiparty;
    BOOL group;
	md.publicKey = [self findPublicKeyForQliqId:md.toQliqId isMultiParty:&multiparty isGroup:&group];
    md.multiparty = multiparty;
    md.groupMessage = group;
    md.alsoNotify = notifyQliqIds;
    md.extraHeaders = headers;
    
    DDLogSupport(@"Sending message to: %@ (seq: %d, call-id: %@)", md.toQliqId, md.seq, md.callId);
	
	if ([md.publicKey length] > 0)
    {
        
		return [self sendMessageEncrypt: md];
	}
    else
    {
        DDLogSupport(@"Cannot send a message to: %@ because there's no pk, trying to download", md.toQliqId);
        [self scheduleMessageResend: md];
	}
}

- (BOOL)sendMessage:(SipMessage *)msg
{
    DDLogSupport(@"Sending message to: %@ (seq:%d, call-id:%@, conversation-id:%@)", msg.toQliqId, msg.seq, msg.callId, msg.conversationUuid);
    
    if (msg.pagerInfo.length > 0) {
        return [self sendPlainTextMessage: msg];
    } else if ([msg.publicKey length] > 0) {
        return [self sendMessageEncrypt: msg];
    } else {
        DDLogSupport(@"Cannot send a message to: %@ because there's no pk, trying to download", msg.toQliqId);
        [self scheduleMessageResend: msg];
    }
}

- (BOOL)sendPlainTextMessage:(SipMessage *)msg
{
    if (msg.text.length == 0) {
        msg.text = msg.plainText;
    }
    return [self pjSendMessage:msg mime:AT_MIME_TEXT_PLAIN];
}

- (BOOL) sendMessageEncrypt: (SipMessage *)md
{
    NSString *encryptedJson = [Crypto encryptToBase64: md.plainText: md.publicKey];
	if (encryptedJson == nil)
    {
		d->lastError = EncryptionSipError;
		DDLogError(@"Cannot encrypt message to %@ (call-id: %@) with key: %@", md.toQliqId, md.callId, md.publicKey);
        
		return NO;
	}
    else
    {
        md.text = encryptedJson;
        return [self pjSendMessage:md mime:AT_MIME_TEXT_BASE64];
	}
}

+ (SipContact *) sipContactForQliqId:(NSString *) qliqId{
    SipContactDBService * dbService = [[SipContactDBService alloc] init];
    SipContact * contact = [dbService sipContactForQliqId:qliqId];
    [dbService release];
    return contact;
}



-(void) getPublicKeysSuccess:(NSString *)qliqId
{
    
    NSMutableArray *array = [d->messagesToResend objectForKey:qliqId];
    NSArray *messages = [array copy];
    [array removeAllObjects];
    
    DDLogInfo(@"getPublicKeysSuccess qliqId: %@", qliqId);
    NSString *publicKey = [QliqSip sipContactForQliqId:qliqId].publicKey;
    for (SipMessage *md in messages)
    {
        if ([publicKey length] > 0 && [publicKey isEqualToString:md.publicKey])
        {
            DDLogError(@"Updated public key is the same as the old one. I won't resend the message (%@)", qliqId);
            // [array addObject:md];
            // continue;
        }
        else
        {
            DDLogInfo(@"b.publicKey: %@", publicKey);
            md.publicKey = publicKey;
            [self sendMessageEncrypt:md];
            md.plainText = @""; // mark as resent
        }
    }
	
    // For messages that failed to resent propagate the status as 493
    for (SipMessage *md in messages)
    {
        if ([md.plainText length] > 0)
        {
            [self onPagerStatus:md status:1001 callId:nil];
        }
    }
    
    [messages release];
    [d->publicKeyRequestsInProgress removeObject:qliqId];
}

-(void) didFailToGetPublicKeysWithReason:(NSString *)qliqId withReason:(NSString*)reason withServiceErrorCode:(NSInteger)serviceErrorCode
{
    NSArray *messages = [d->messagesToResend objectForKey:qliqId];
    for (SipMessage *md in messages)
    {
        int status = 0;
        if (serviceErrorCode == ErrorCodeNotContact) {
            status = MessageStatusNotContact;
        } else if (serviceErrorCode == ErrorCodeNotMemberOfGroup) {
            status = MessageStatusNotMemberOfGroup;
        } else if (serviceErrorCode == ErrorCodePublicKeyNotSet) {
            status = MessageStatusPublicKeyNotSet;
        } else if (serviceErrorCode == ErrorCodeCantDetermineContactType) {
            status = MessageStatusCantDetermineContactType;
        } else {
            
            BOOL isReachable = [[QliqReachability sharedInstance] isReachable];
            if (!isReachable) {
                status = 408;
            } else {
                status = MessageStatusCannotGetPublicKey;
            }
        }

        [self onPagerStatus:md status:status callId:nil];
    }
    [d->messagesToResend removeObjectForKey:qliqId];
    [d->publicKeyRequestsInProgress removeObject:qliqId];
}

// Sometimes SIP formats the URI like <sip:user@domain.com>
// We remove the < > chars if they exist
+ (NSString *) removeSipUriDecorator:(NSString *)sipUri
{
    
    NSString *ret = [sipUri stringByReplacingOccurrencesOfString:@"<" withString:@""];
	ret = [ret stringByReplacingOccurrencesOfString:@">" withString:@""];
    
	if ([ret hasPrefix:@"sip:"])
		ret = [ret substringFromIndex:4];
    
    return ret;
}

// Supports URIs lile: <sip:nnn@host>, sip:nn@host and nn@host
+ (NSString *) qliqIdFromSipUri:(NSString *)sipUri
{
    NSRange	range = [sipUri rangeOfString:@"@"];
    if (range.location == NSNotFound) {
        DDLogError(@"BUG: Cannot find '@' in SIP URI: %@", sipUri);
        return sipUri;
    }
    
    NSString *ret = [sipUri substringToIndex:range.location];
    
    if ([ret characterAtIndex:0] == '<') {
        ret = [ret substringFromIndex:1];
    }
    
    if ([ret hasPrefix:@"sip:"]) {
        ret = [ret substringFromIndex:4];
    }
    
    return ret;
}

- (NSString *) sipUriFromQliqId:(NSString *)qliqId
{
    return [qliqId stringByAppendingFormat:@"@%@", [self mySipHost]];
}

- (BOOL) pjSendMessage:(SipMessage *)msg mime:(NSString *)mime
{
	if (!d->sipStarted)
    {
		d->lastError = OfflineSipError;
		DDLogError(@"Cannot send message to %@ because SIP stack isn't initialized", msg.toQliqId);
        
        [self onPagerStatus:msg status:MessageStatusSipNotStarted callId:nil];
		return NO;
	}
	
	if (d->acc_id == -1)
    {
		d->lastError = OfflineSipError;
		DDLogError(@"Cannot send message to %@ because SIP account isn't registered", msg.toQliqId);
        
        [self onPagerStatus:msg status:MessageStatusSipNotStarted callId:nil];
		return NO;
	}
	
    // Compute the To URI based on qliq id and our own SIP host
    NSString *sipUri = [self sipUriFromQliqId:msg.toQliqId];
	
	if (![sipUri hasPrefix:@"sip:"])
		sipUri = [@"sip:" stringByAppendingString:sipUri];
	
	pj_str_t pjto, pjtext, pjmime;
    pj_cstr(&pjto, [sipUri UTF8String]);
    pj_cstr(&pjtext, [msg.text UTF8String]);
    pj_cstr(&pjmime, [mime UTF8String]);
    
    pjsua_msg_data msg_data;
    pjsua_msg_data *msg_data_ptr = nil;

    NSMutableDictionary *extraHeaders = msg.extraHeaders;
    if (extraHeaders == nil) {
        extraHeaders = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    NSString *deviceUuid = [[UIDevice currentDevice] qliqUUID];
    if (deviceUuid.length > 0) {
        NSString *regid = [NSString stringWithFormat:@"<urn:uuid:%@>", deviceUuid];
        [extraHeaders setObject:regid forKey:@"X-instance"];
    } else {
        DDLogError(@"Cannot retrieve device uuid for message");
    }
    
    // Add extra headers
    if (msg.text.length > 0) {
        NSString *checksum = [msg.text md5];
        [extraHeaders setObject:checksum forKey:@"X-checksum"];
    }
    
    if (msg.offlineMode) {
        [extraHeaders setObject:@"yes" forKey:@"X-offline"];
    }
    
    if (msg.publicKey.length > 0) {
        [extraHeaders setObject:[msg.publicKey md5] forKey:@"X-hash"];
    }
    
    if (msg.pushNotify) {
        [extraHeaders setObject:@"yes" forKey:@"X-pushnotify"];
    }
    
    if (msg.multiparty) {
        [extraHeaders setObject:[self sipUriFromQliqId:msg.toQliqId] forKey:@"X-multiparty"];
        
        NSString *value = @"no";
        if (msg.groupMessage) {
            value = @"yes";
        }
        [extraHeaders setObject:value forKey:@"X-groupmessage"];
        
        // TODO: implement X-recipient-scope for OnCall group messages
    }
    
    if ([msg.displayName length] > 0) {
        [extraHeaders setObject:msg.displayName forKey:@"X-sendername"];
    }
    
    if (msg.priority != ChatMessagePriorityUnknown) {
        [extraHeaders setObject:[ChatMessage priorityToString:msg.priority] forKey:@"X-priority"];
    }
    
    if ([msg.alsoNotify length] > 0) {
        [extraHeaders setObject:msg.alsoNotify forKey:@"X-also-notify"];
    }
    
    if (msg.createdAt != 0) {
        [extraHeaders setObject:[NSString stringWithFormat:@"at=%lu;", (unsigned long)msg.createdAt] forKey:@"X-created"];
    }
    
    if (msg.conversationUuid.length > 0) {
        [extraHeaders setObject:msg.conversationUuid forKey:@"X-conversation-uuid"];
    }
    
    if (msg.isBroadcast) {
        [extraHeaders setObject:@"yes" forKey:@"X-group-broadcast"];
    }
    
    if (msg.pagerInfo.length > 0) {
        [extraHeaders setObject:msg.pagerInfo forKey:@"X-send-pager"];
    }
    
    // Does pjproject strcpy the strings?
    // Do we need to free msg_data?
    if ([extraHeaders count] > 0)
    {
        pjsua_msg_data_init(&msg_data);
        
        for (NSString *key in extraHeaders)
        {
            NSString *value = [extraHeaders objectForKey:key];
            pj_str_t hname = pj_str([key UTF8String]);
            pj_str_t hvalue = pj_str([value UTF8String]);
            pjsip_generic_string_hdr *hdr = pjsip_generic_string_hdr_create(d->pool, &hname, &hvalue);
            pj_list_push_back(&msg_data.hdr_list, hdr);
        }
        msg_data_ptr = &msg_data;
    }
    
    [d->sentMessages setObject:msg forKey:[NSNumber numberWithInt:msg.seq]];
    
    pj_str_t pjcallId;
    pj_str_t *callIdPtr = nil;
    if ([msg.callId length] > 0) {
        pj_cstr(&pjcallId, [msg.callId UTF8String]);
        callIdPtr = &pjcallId;
    }
    
    __block pj_status_t status;
    [self runOnSipThreadWait:YES block: ^{
        self.lastSentMessagePlainTextBody = msg.plainText;
        self.lastSentMessageCallId = msg.callId;
#ifdef DONT_SEND_SIP_MESSAGE_BUT_FAKE_SUCCESS
        // Code used for debugging
        DDLogWarn(@"Sending is disabled by debug code, returning PJ_SUCCESS");
        status = PJ_SUCCESS;
#else
        status = pjsua_im_send_with_call_id(d->acc_id, &pjto, &pjmime, &pjtext, msg_data_ptr, msg.seq, callIdPtr);
#endif
    }];
	
    if (status != PJ_SUCCESS)
    {
		d->lastError = UnknownSipError;
        
        [self onPagerStatus:msg status:MessageStatusSipNotStarted callId:nil];
        
        DDLogError(@"Error sending message to %@ (call-id: %@), status: %d", msg.toQliqId, msg.callId, status);
        
		return NO;
	}
    else
    {
		d->lastError = SuccessSipError;
		DDLogInfo(@"Sent message to %@ (call-id: %@), mime: %@", msg.toQliqId, msg.callId, mime);
        
		return YES;
	}
}

- (BOOL) sendStatus:(NSString *)status toQliqId:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext alsoNotify:(NSString *)aAlsoNotify
{
    SipMessage *md = [[[SipMessage alloc] init] autorelease];
    md.seq = [self nextMessageSequence];
    md.toQliqId = qliqId;
    md.plainText = @"";
    md.publicKey = @"";
    md.context = nil;
    md.offlineMode = NO;
    md.pushNotify = NO;
    md.displayName = nil;
    md.statusChangedBlock = nil;
    md.callId = aCallId;
    md.priority = ChatMessagePriorityUnknown;
	md.publicKey = nil;
    md.multiparty = NO;
    md.alsoNotify = aAlsoNotify;
    
    md.extraHeaders = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         status, @"X-status",
                         aServerContext, @"X-server-context",
                         nil] autorelease];

    DDLogSupport(@"Sending message status: '%@' call-id: '%@' server-context: '%@'", status, aCallId, aServerContext);
    return [self pjSendMessage:md mime:@"text/plain"];
}

- (BOOL) sendOpenedStatus:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext
{
    return [self sendStatus:@"opened" toQliqId:qliqId callId:aCallId serverContext:aServerContext alsoNotify:nil];
}

- (BOOL) sendDeletedStatus:(NSString *)unusedQliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext
{
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    return [self sendStatus:@"deleted; reason=user" toQliqId:myQliqId callId:aCallId serverContext:aServerContext alsoNotify:nil];
}

- (BOOL) sendRecalledStatus:(NSString *)qliqId callId:(NSString *)aCallId serverContext:(NSString *)aServerContext alsoNotify:(NSString *)notifyQliqIds
{
    return [self sendStatus:@"deleted; reason=recall" toQliqId:qliqId callId:aCallId serverContext:aServerContext alsoNotify:notifyQliqIds];
}

- (int) nextMessageSequence
{
    static int seq = 0;
    return ++seq;
}

- (NSString *) findPublicKeyForQliqId: (NSString *)qliqId isMultiParty:(BOOL *)multiparty isGroup:(BOOL *)group
{
    if ([qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
        *multiparty = NO;
        *group = NO;
        return [[Crypto instance] publicKeyString];
    } else {
        SipContact * sipContact = [QliqSip sipContactForQliqId:qliqId];
        NSString * publicKey = sipContact.publicKey; //AIIII has not Public key when refresh app and send new message in old conversation
        *multiparty = (sipContact.sipContactType != SipContactTypeUser);
        *group = (sipContact.sipContactType == SipContactTypeGroup);
        
        if ([publicKey length] == 0)
            DDLogSupport(@"Public key not found for: %@", qliqId);
        
        return publicKey;
    }
}

+ (NSString *) privateKeyForQliqId: (NSString *)qliqId
{
    NSString *privateKey = [QliqSip sipContactForQliqId:qliqId].privateKey;
    if ([privateKey length] == 0) {
        DDLogError(@"Cannot find SipContact for qliq id: %@", qliqId);
    }
    return privateKey;
}

- (NSInteger) setRegistered: (BOOL)value
{
    NSString *regUri = [NSString stringWithFormat:@"%s",d->creguri];
    
	if (d->acc_id == -1 || d->sipStarted == NO)
    {
		DDLogError(@"Eithe SIP is not started OR No SIP account added");
        
		return PJSIP_ENOTINITIALIZED;
	}
    
	if (value)
    {
        DDLogSupport(@"Registering with %s",d->creguri);

        // 10/11/2016 Krishna
        // If iOS 10, make the regitration shortTime in BG so that the server
        // will relinquish the connection after shortTime
        //
        if (is_ios_greater_or_equal_10()) {
            BOOL shortTime = [AppDelegate applicationState] == UIApplicationStateBackground;
            [self setRegistrationTimeout:shortTime];
        }
    }
    else
    {
        DDLogSupport(@"Unregistering...");
	}
    
    d->isRegistrationInProgress = value;
    [self setCurrentRegistrationAction: (value ? RegisteringSipRegistrationAction : UnregisteringSipRegistrationAction)];

    __block pj_status_t status;
    [self runOnSipThreadWait:YES block: ^{
        status = pjsua_acc_set_registration(d->acc_id, value);
    }];
    if (status == PJSIP_EBUSY)
    {
        if (!value) {
            d->isRegistrationInProgress = NO;
            [self setCurrentRegistrationAction: NoSipRegistrationAction];
        } else {
            DDLogError(@"SIP stack is busy during registration, restarting the stack");
            [self handleNetworkUp];
        }
    } else if (status != 0) {
        d->isRegistrationInProgress = NO;
        DDLogError(@"Cannot send registration request, error: %d", status);
    } else {
        d->lastRegistrationRequestTimeInterval = [[NSDate date] timeIntervalSince1970];
    }
    
    return status;
}

/* In IOS, the account goes into a state where, it needs to be reset. */
- (BOOL) shutdownTransport
{
    if (d->sipStarted)
    {
        [self runOnSipThreadWait:YES block: ^{
// Krishna 2/11/2017
            if (self.areTransportsShutdown == false) {
                pjsip_endpoint *endpt = pjsua_get_pjsip_endpt();
                pjsip_tpmgr *tpmgr = pjsip_endpt_get_tpmgr(endpt);
                DDLogSupport(@"Shuting down all SIP transports");
                self.areTransportsShutdown = true;
                pjsip_tpmgr_shutdown_all_transports(tpmgr);
                DDLogSupport(@"SIP transports are shutdown");
            } else {
                DDLogSupport(@"SIP transports were previously SHUTDOWN. Nothing to do");
            }
        }];
    } else {
        DDLogSupport(@"SIP is not started. Cannot SHUTDOWN SIP tranport.");
        return FALSE;
    }
    // All Good.
    return TRUE;
}

// Krishna - 9/5/2014
// Created this method so that the App can ping the server
// When the app goes to FG. Sometimes the transport is getting silently
// Dropped and the App thinks that it is still Registered. This causes
// App to not receive messages until next registration time which could be
// 20 minutes. Pinging Server would get rid of stale connection and REGISTER
// immediately and receive messages.
//
- (BOOL) pingServer
{
    __block BOOL ping_status = true;
    if (d->sipStarted)
    {
        [self runOnSipThreadWait:YES block: ^{
            if (self.areTransportsShutdown == false) {
                pjsip_endpoint *endpt = pjsua_get_pjsip_endpt();
                pjsip_tpmgr *tpmgr = pjsip_endpt_get_tpmgr(endpt);
                /* Send raw packet */
                //  Try on IPv4 transport
                pj_status_t status = pjsip_tpmgr_send_raw(tpmgr,
                                              d->transport_type, NULL,
                                              NULL, (void *)d->acc_cfg.ka_data.ptr,
                                              d->acc_cfg.ka_data.slen,
                                              &d->server_sock, d->sockaddr_len,
                                              NULL, NULL);
                if (status != PJ_SUCCESS){
                    // Now Try on IPv6 transport
                    status = pjsip_tpmgr_send_raw(tpmgr,
                                                  d->transport_type6, NULL,
                                                  NULL, (void *)d->acc_cfg.ka_data.ptr,
                                                  d->acc_cfg.ka_data.slen,
                                                  &d->server_sock6, d->sockaddr_len6,
                                                  NULL, NULL);
                    if (status != PJ_SUCCESS){
                        DDLogSupport(@"Sent Keepalive packet to PING the server. Ping Failed");
                        ping_status = false;
                    } else {
                        DDLogSupport(@"Server Ping Success on IPv6");
                    }
                } else {
                    DDLogSupport(@"Server Ping Success on IPv4");
                }
            } else {
                DDLogSupport(@"SIP transports were previously shutdown. Nothing to do");
            }
        }];
    } else {
        DDLogSupport(@"SIP is not started. No pinging.");
    }
    
    return ping_status;
}

- (void) handleAppDidBecomeInactive
{
    
 
    DDLogSupport(@"Application went to bg, disabling registration retries");
    [self turnRegistrationRetries:NO];

    
}

- (void) handleAppDidBecomeActive
{
    
    DDLogSupport(@"Application went to fg, enabling registration retries");
    [self turnRegistrationRetries:YES];
    
}

- (void) handleNetworkDown
{
    
    DDLogSupport(@"handleNetworkDown.");
    
    //[self sipStop];
    
    // When the network is down, we no longer need to
    // hang onto connections that were created.
    //[self destroyConnections];
    [self endAllCalls];
    
    DDLogSupport(@"The network is down, disabling registration retries");    
    [self turnRegistrationRetries:NO];
    
    d->isDoingReRegistration = NO;
    d->wasRegistered = NO;
    d->previousRegistrationStatusCode = 0;
    
    [self cancelSendingMessages];

    // Notify the UI we are offline
    [self notifyRegistration: NO status:491 reregistered:NO];
}

- (void) handleNetworkUp
{
    
    DDLogSupport(@"handleNetworkUp");
    //if (d->sipStarted == NO)
    //{
    //    [self sipStart];
    //}
    //    [self setRegistered:TRUE];
    
    if (self.accountSettings != nil)
    {
        [self cancelSendingMessages];
        [self registerUserWithAccountSettings:self.accountSettings];
    }
}

- (void) cancelSendingMessages
{
    
    DDLogSupport(@"Cancelling sending of messages (changing status to 491)");
                 
    // Change status of message waiting for a public key
    for (NSString *qliqId in d->messagesToResend)
    {
        NSArray *messages = [d->messagesToResend objectForKey:qliqId];
        for (SipMessage *md in messages)
        {
            [self onPagerStatus:md status:491 callId:nil];
        }
    }
    [d->messagesToResend removeAllObjects];
    [d->publicKeyRequestsInProgress removeAllObjects];

    // Change status of 'Sending...' messages to 'Pendng. Network error'
    NSDictionary *sentMessages = [d->sentMessages copy];
    for (NSNumber *seq in sentMessages)
    {
        SipMessage *m = [sentMessages objectForKey:seq];
        [self onPagerStatus:m status:491 callId:nil];
    }
    [sentMessages release];
    
    
}

- (void) turnRegistrationRetries: (BOOL)on
{
    
    
    if (d->acc_id != -1)
    {
        [self runOnSipThreadWait:YES block: ^{
            int interval = on ? REGISTRATION_RETRY_INTERVAL : 0;
            d->acc_cfg.reg_retry_interval = interval;
            //d->acc_cfg.ka_interval = on ? 90 : 0;
            
            pj_status_t status = pjsua_acc_modify(d->acc_id, &d->acc_cfg);
            if (status != 0)
                DDLogError(@"Cannot switch registration retries, error: %d", status);
        }];
    }
    else
    {
        DDLogError(@"No SIP account configured");
    }
}

- (void) setRegistrationTimeout: (BOOL)shortTime
{
    if (d->acc_id != -1) {
        [self runOnSipThreadWait:YES block: ^{
            d->acc_cfg.reg_timeout = shortTime ? 30 : (d->acc_cfg.reg_timeout = 6*SIP_KEEP_ALIVE_INTERVAL + 60) ;
            DDLogSupport(@"Changing RegistrationTimeout %d Seconds", d->acc_cfg.reg_timeout);
            pj_status_t status = pjsua_acc_modify(d->acc_id, &d->acc_cfg);
            if (status != 0)
                DDLogError(@"Cannot change RegistrationTimeout, error: %d", status);
        }];
    }
    else
    {
        DDLogError(@"No SIP account configured");
    }
}

- (void) setCurrentRegistrationAction: (NSInteger)action
{
    
    
    if (currentRegistrationAction != action)
    {
        currentRegistrationAction = action;
    
        NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:currentRegistrationAction], @"action", nil];
        
        [NSNotificationCenter postNotificationToMainThread:SIPRegistrationActionNotification withObject:nil userInfo:userInfo needWait:NO];
    }
    
    
}

// Not used
- (void) destroyConnections
{
    [self runOnSipThreadWait:YES block: ^{
        /* Get the count of tranports; */
        pjsip_tpmgr *tpmgr;
        pjsip_endpoint *endpt = pjsua_get_pjsip_endpt();
        
        if (endpt == NULL)
            return;
        
        tpmgr = pjsip_endpt_get_tpmgr(endpt);
        
        unsigned int tpcount = pjsip_tpmgr_get_transport_count(tpmgr);
        
        DDLogSupport(@"%d connections are being destroyed", tpcount);
        
        pjsip_transport *tp = NULL;
        pj_status_t status = PJSIP_EUNSUPTRANSPORT;
        
        while (tpcount)
        {
            // Look for IPv4 connections
            //
            status = pjsip_tpmgr_acquire_transport(tpmgr, d->transport_type, &d->server_sock,
                                                   d->sockaddr_len, NULL, &tp);
            
            
            if (status == PJ_SUCCESS) {
                DDLogInfo(@"0x%x IPv4 IPv4 connection is being destroyed", tp);
                pjsip_transport_shutdown(tp);
            }
            else
            {
                // Look for IPv6 connections
                status = pjsip_tpmgr_acquire_transport(tpmgr, d->transport_type6, &d->server_sock6,
                                                       d->sockaddr_len6, NULL, &tp);
                if (status == PJ_SUCCESS) {
                    DDLogInfo(@"0x%x IPv6 transport is being destroyed", tp);
                    pjsip_transport_shutdown(tp);
                } else {
                    DDLogSupport(@"Transport is neither IPV4 or V6 Status = %d", status);
                }
            }
            tpcount--;
        }
        d->sipTransportUp = NO;
    }];
}


- (BOOL) isConfigured {
    return (d->acc_id != -1);
}

- (BOOL) isRegistered
{
    
    __block BOOL ret = NO;
    if (d->acc_id != -1)
    {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_acc_info info;
            pj_status_t status = pjsua_acc_get_info(d->acc_id, &info);
            if (status == PJ_SUCCESS)
            {
                ret = (info.expires != -1)  && (info.status / 100 == 2);
            }
        }];
    }
    
    return ret;
}

- (BOOL) isRegistrationInProgress
{
    return d->isRegistrationInProgress;
}

- (BOOL) isTransportUp
{
    return d->sipTransportUp;
}

- (BOOL) isMultiDeviceSupported
{
    return accountSettings.serverInfo.multiDevice;
}

- (int) lastError
{
    
    
	return d->lastError;
}

- (NSString *) lastErrorMessage
{
    
    NSString *rez = nil;
	switch (d->lastError)
    {
		case SuccessSipError:
        {
			rez = @"Success";
			break;
        }
		case OfflineSipError:
        {
			rez = @"Offline";
			break;
        }
		case EncryptionSipError:
        {
			rez = @"Encryption error";
			break;
        }
		case DecryptionSipError:
        {
			rez = @"Decryption error";
			break;
        }
		case UnknownSipError:
		default:
        {
			rez =  @"Unknown error";
			break;
        }
	}
    
    return rez;
}

- (void) registerOrPingInBackground
{
    // SIP transaction timer so that it will expire before
    // Apple kicks the app out.
    //
    //pjsip_cfg()->tsx.td = 10000;       // 10 seconds

	// Since we use dispatch queue, no need to register bg thread
	if (!pj_thread_is_registered()) {
		pj_thread_register("qliqiphone", a_thread_desc, &a_thread);
    }
    
	if (d->acc_id != -1)
    {
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval diff = currentTimeInterval - d->lastRegistrationRequestTimeInterval;
        
        // In bg send registration not more often then every 20 mins
        if (diff >= 6*SIP_KEEP_ALIVE_INTERVAL ) {
         	DDLogSupport(@"Registration triggered in Background for %d", d->acc_id);
            d->isRegistrationInProgress = YES;
            __block pj_status_t status;
            [self runOnSipThreadWait:YES block: ^{
                status = pjsua_acc_set_registration(d->acc_id, PJ_TRUE);
            }];
            if (status == PJSIP_EBUSY)
            {
                //d->isRegistrationInProgress = NO;
                DDLogError(@"SIP stack is busy during registration in background, restarting the stack");
                [self handleNetworkUp];
            } else if (status != 0) {
                d->isRegistrationInProgress = NO;
                DDLogError(@"Cannot send registration request in bg, error: %d", status);
            } else {
                d->lastRegistrationRequestTimeInterval = currentTimeInterval;
            }
        } else {
          	DDLogSupport(@"Registration is deferred. Pinging in the BG");
            if ([self pingServer] == false)
            {
                DDLogSupport(@"PING Failed. Fresh Registration again");
                [self setRegistered:TRUE];
            }
        }
    }
}

- (void)keepAliveInBackground
{
    
    DDLogSupport(@"Keep alive called in the BG. Transport state %d", d->sipTransportUp);
    
    if (d->sipTransportUp)
    {
        [self registerOrPingInBackground];
    }
    
}

- (void) onPagerStatus: (int)status to:(NSString *)to body:(NSString *)body reason:(NSString *)reason userData:(void *)userData callId:(NSString *)aCallId
{
    SipMessage *md = [d->sentMessages objectForKey:[NSNumber numberWithInt:(int)userData]];
    if (md == nil) {
        DDLogError(@"Cannot find sent message with seq: %d", (int)userData);
        return;
    }
    
    [self onPagerStatus:md status:status callId:aCallId];
}

- (NSDictionary *)userInfoForMessage:(SipMessage *)message status:(int)status callId:(NSString *)callId
{
    if (!callId) {
        callId = @"";
    }
    
    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary new];
    
    mutableUserInfo[@"Status"] = @(status);
    mutableUserInfo[@"Reason"] = @"";
    mutableUserInfo[@"CallId"] = callId;
    if (message.plainText) {
        mutableUserInfo[@"Body"] = message.plainText;
    } 
    if (message.toQliqId) {
        mutableUserInfo[@"ToQliqId"] = message.toQliqId;
    }
    if (message.context) {
        mutableUserInfo[@"context"] = message.context;
    }
    
    return [mutableUserInfo autorelease];
}

- (void) onPagerStatus: (SipMessage *)md status:(int)status callId:(NSString *)aCallId
{
    [md retain];
	
    DDLogSupport(@"Status changed to: %d for message to: %@ (seq: %d, call-id: %@ conversation-id: %@)", status, md.toQliqId, md.seq, md.callId, md.conversationUuid);
    
    if (status == PJSIP_SC_UNDECIPHERABLE)
    {
        DDLogError(@"The other party: %@ cannot decrypt our message. Will download new public key and resend.", md.toQliqId);
        [self scheduleMessageResend:md];
    }
    else
    {
        if (md.statusChangedBlock != nil) {
            md.statusChangedBlock(md.context, status);
        }
        
        NSDictionary *userInfo = [self userInfoForMessage:md status:status callId:aCallId];
        
        [NSNotificationCenter postNotificationToMainThread:SIPMessageStatusNotification withObject:nil userInfo:userInfo needWait:NO];
        
        BOOL messageSent = YES;
        if (status == PJSIP_SC_REQUEST_TIMEOUT ||
            status == PJSIP_SC_INTERNAL_SERVER_ERROR ||
            status == PJSIP_SC_BAD_GATEWAY ||
            status == PJSIP_SC_SERVICE_UNAVAILABLE) // todo: include status >= 600?
        {
            messageSent = NO;
            if (d->isRegistrationInProgress == NO)
            {
                DDLogSupport(@"Message sending failed (status: %d), trying to re-register", status);
                [self setRegistered:YES];
            }
            
            NSDictionary *userInfo = [self userInfoForMessage:md status:status callId:aCallId];
            [NSNotificationCenter postNotificationToMainThread:SIPMessageSendingFailedNotification withObject:nil userInfo:userInfo needWait:NO];
        }
        
        NSDictionary * notificationInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:messageSent],@"delivered", nil];
        
        [NSNotificationCenter postNotificationToMainThread:SIPMessageDeliveredNotification withObject:nil userInfo:notificationInfo needWait:NO];
    }
    
    [d->sentMessages removeObjectForKey:[NSNumber numberWithInt:md.seq]];
    [md release];
}

- (void) scheduleMessageResend:(SipMessage *)msg
{
    NSMutableArray *array = [d->messagesToResend objectForKey:msg.toQliqId];
    if (!array)
    {
        array = [[NSMutableArray alloc] init];
        [d->messagesToResend setObject:array forKey:msg.toQliqId];
        [array release];
    }
    [array addObject:msg];
    
    if ([d->publicKeyRequestsInProgress containsObject:msg.toQliqId] == NO)
    {
        [d->publicKeyRequestsInProgress addObject:msg.toQliqId];
        
        SipContact *contact = [QliqSip sipContactForQliqId:msg.toQliqId];
        if (contact.sipContactType == SipContactTypeUser) {
            if (d->getPublicKeys == nil) {
                d->getPublicKeys = [[GetPublicKeys alloc] init];
                d->getPublicKeys.delegate = self;
            }

            [d->getPublicKeys getPublicKeys:msg.toQliqId];
        } else if (contact.sipContactType == SipContactTypeGroup) {
            if (d->getGroupKeyPairService == nil) {
                d->getGroupKeyPairService = [[GetGroupKeyPair alloc] init];
            }
            [d->getGroupKeyPairService getGroupKeyPairCompletitionBlock:msg.toQliqId completionBlock:^(CompletitionStatus status, id result, NSError *error) {
                DDLogSupport(@"GetGroupKeyPair finished");
                if (status == CompletitionStatusSuccess) {
                    [self getPublicKeysSuccess:msg.toQliqId];
                } else {
                    [self didFailToGetPublicKeysWithReason:msg.toQliqId withReason:[error localizedDescription] withServiceErrorCode:[error code]];
                }
            }];
        } else {
            DDLogError(@"Cannot determine contact type for this qliq id: %@", msg.toQliqId);
            [self didFailToGetPublicKeysWithReason:msg.toQliqId withReason:@"Cannot determine contact type for this qliq id" withServiceErrorCode:ErrorCodeCantDetermineContactType];
        }
    }
}

- (void) notifyRegistration: (BOOL) registered status:(NSInteger)status reregistered:(BOOL)reregistered
{
    NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:registered], @"isRegistered",
                              [NSNumber numberWithInt:status], @"status",
                              [NSNumber numberWithBool:reregistered], @"isReRegistration",
                              nil];
    
    [NSNotificationCenter postNotificationToMainThread:SIPRegistrationStatusNotification withObject:nil userInfo:userInfo needWait:NO];
}

- (void) onRegistration: (BOOL) registered status: (int)status
{
    lastRegistrationResponseCode = status;
    
    if (status/100 == 5) {
        registration5XXErrorCount++;
    } else if (status == 200) {
        registration5XXErrorCount = 0;
    }
    
    [self setCurrentRegistrationAction:NoSipRegistrationAction];
    
    BOOL isReRegistration = NO;
    if (d->wasRegistered != registered)
    {
        d->wasRegistered = registered;
    }
    else if (d->wasRegistered)
    {
        isReRegistration = YES;
    }
    d->isRegistrationInProgress = NO;
    
    int prevStatus = d->previousRegistrationStatusCode;
    d->previousRegistrationStatusCode = status;
    
    if (status == 401) {
        if (prevStatus != 401) {
            DDLogError(@"Got 401 SIP registration status, calling update_sip_credentials service");
            UpdateSipCredentialsService *service = [[UpdateSipCredentialsService alloc] init];
            [service update:^(NSError *error) {
                if (error == nil) {
                    double delayInSeconds = 3.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        DDLogSupport(@"Delayed registration after update_sip_credentials");
                        [self setRegistered:YES];
                    });
                } else {
                    DDLogError(@"Call to update_sip_credentials failed");
                    [self notifyRegistration:registered status:status reregistered:isReRegistration];
                }
            }];
            
            // 'Hide' the first 401 status from other parts of the app
            return;
        } else {
            DDLogError(@"Got another 401 SIP registration status, giving up");
            
            BOOL showAlert = YES;
            if (self.timeAuthenticationError && [[NSDate date] timeIntervalSinceDate:self.timeAuthenticationError] < AUTHENTICATION_ERROR_INTERVAL) {
                showAlert = NO;
            }
            
            if (showAlert) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1023-TextError")
                                                                                  message:QliqLocalizedString(@"1173-TextCannotRefisterForMessages")
                                                                                 delegate:nil
                                                                        cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                                        otherButtonTitles: nil];
                    [[alert autorelease] showWithDissmissBlock:NULL];
                });
                self.timeAuthenticationError = [NSDate date];
            }
        }
    }
    
    [self notifyRegistration: registered status:status reregistered:isReRegistration];
    
    if (d->isDoingReRegistration) // && !registered) // && status / 100 == 2)
    {
        if (!registered && status / 100 == 2)
            DDLogSupport(@"Trying to re-register after succesful unregistration after network up");
        else
            DDLogSupport(@"Trying to re-register after unsuccesful unregistration after network up (status: %d)", status);
        
        d->isDoingReRegistration = FALSE;
        d->isRegistrationInProgress = YES;
        //status = pjsua_acc_set_registration(d->acc_id, PJ_TRUE);
        __block status = [self setRegistered:YES];
        if (status != PJ_SUCCESS)
        {
            d->isRegistrationInProgress = NO;
            DDLogError(@"Error (%d) while trying to re-register after network event", status);
        }
    }
}

- (void) onUnRegistration: (int)status
{
    DDLogSupport(@"On Un-Registration Callback: Status=%d", status);
    if (status/100 == 5) {
        registration5XXErrorCount++;
    } else if (status == 200) {
        registration5XXErrorCount = 0;
    }
    
    NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:status], @"status",
                              nil];
    
    [NSNotificationCenter postNotificationToMainThread:SIPUnregistrationStatusNotification withObject:nil userInfo:userInfo needWait:NO];
    
}

- (void) onOpenedNotify: (NSString *)callId qliqId:(NSString *)aQliqId openedRecipientCount:(int)aOpenedRecipientCount totalRecipientCount:(int)aTotalRecipientCount openedAt:(long)aOpenedAt
{
    if ([aQliqId length] > 0 && [callId length] > 0) {
        NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         callId, @"CallId",
                                         aQliqId, @"QliqId",
                                         [NSNumber numberWithInt: aTotalRecipientCount], @"TotalRecipientCount",
                                         [NSNumber numberWithInt: aOpenedRecipientCount], @"OpenedRecipientCount",
                                         [NSNumber numberWithLong: aOpenedAt], @"OpenedAt",
                                         nil];
        
        [NSNotificationCenter postNotificationToMainThread:SIPOpenedMessageStatusNotification withObject:nil userInfo:userinfo needWait:NO];
    }
}

- (void) onAckedNotify: (NSString *)callId qliqId:(NSString *)aQliqId ackedRecipientCount:(int)aOpenedRecipientCount totalRecipientCount:(int)aTotalRecipientCount openedAt:(long)aOpenedAt
{
    if ([aQliqId length] > 0 && [callId length] > 0) {
        NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         callId, @"CallId",
                                         aQliqId, @"QliqId",
                                         [NSNumber numberWithInt: aTotalRecipientCount], @"TotalRecipientCount",
                                         [NSNumber numberWithInt: aOpenedRecipientCount], @"AckedRecipientCount",
                                         [NSNumber numberWithLong: aOpenedAt], @"AckedAt",
                                         nil];
        
        [NSNotificationCenter postNotificationToMainThread:SIPAckedMessageStatusNotification withObject:nil userInfo:userinfo needWait:NO];
    }
}

- (void) onDeletedNotify: (NSString *)callId
{
    NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     callId, @"CallId",
                                     nil];
    
    [NSNotificationCenter postNotificationToMainThread:SIPDeletedMessageStatusNotification withObject:nil userInfo:userinfo needWait:NO];
}

- (void) onRecalledNotify: (NSString *)callId qliqId:(NSString *)aQliqId recalledAt:(long)aRecalledAt
{
    NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     callId, @"CallId",
                                     aQliqId, @"QliqId",
                                     [NSNumber numberWithLong: aRecalledAt], @"RecalledAt",
                                     nil];
    
    [NSNotificationCenter postNotificationToMainThread:SIPRecalledMessageStatusNotification withObject:nil userInfo:userinfo needWait:NO];
}

- (void) onRecipientStatusNotify: (NSString *)callId qliqId:(NSString *)aQliqId statusText:(NSString *)aStatusText statusCode:(int)aStatusCode at:(long)aAt recipientCount:(int)aRecipientCount
{
    if ([aQliqId length] > 0 && [callId length] > 0) {
        NSDictionary *userInfo = @{
            @"CallId": callId,
            @"QliqId": aQliqId,
            @"StatusText": aStatusText,
            @"StatusCode": [NSNumber numberWithInt:aStatusCode],
            @"At": [NSNumber numberWithLong:aAt],
            @"RecipientCount": [NSNumber numberWithInt:aRecipientCount]
        };
   
        [NSNotificationCenter postNotificationToMainThread:SIPRecipientStatusNotification withObject:nil userInfo:userInfo needWait:NO];
    }
}

- (void) onRegInfoNotify:(long)serverTimeDelta: (int)pendingMessages
{
    if (pendingMessages <= 0) {
        pendingMessages = 0;
    } else {
        // Wait 30 secs for a message or notify from the server
        // if the connection is broken before we receive all messages the timer will handle this
        dispatch_async(dispatch_get_main_queue(), ^{
            if (d->messageDumpTimeoutTimer) {
                [d->messageDumpTimeoutTimer invalidate];
            }
            d->messageDumpTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(onMessageDumpTimedOut:) userInfo:nil repeats:YES];
        });
    }
    d->serverTimeDelta = serverTimeDelta;
    d->timeSinceLastMessageOrNotify = [[NSDate date] timeIntervalSince1970];
    d->pendingMessagesCount = pendingMessages;
    
//    NSDictionary *userInfo = @{@"timeDelta": [NSNumber numberWithLong:serverTimeDelta],
//                               @"pendingMessages": [NSNumber numberWithInt:pendingMessages]};

    [NSNotificationCenter postNotificationToMainThread:SIPRegInfoReceivedNotification withObject:nil userInfo:nil needWait:NO];
}

- (void) onNotify: (NSString *)callId status:(int)status qliqId:(NSString *)aQliqId deliveredRecipientCount:(int)aDeliveredRecipientCount totalRecipientCount:(int)aTotalRecipientCount deliveredAt:(long)aDeliveredAt
{
    
    if (status > 0)
    {
        NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt: status], @"Status",
                                  callId, @"CallId",
                                  [NSNumber numberWithInt: aTotalRecipientCount], @"TotalRecipientCount",
                                         [NSNumber numberWithInt: aDeliveredRecipientCount], @"DeliveredRecipientCount",
                                    [NSNumber numberWithLong: aDeliveredAt], @"DeliveredAt",
                                  nil];
        if ([aQliqId length] > 0) {
            [userinfo setObject:aQliqId forKey:@"QliqId"];
        }
        
        [NSNotificationCenter postNotificationToMainThread:SIPPendingMessageStatusNotification withObject:nil userInfo:userinfo needWait:NO];
    }
    
}

- (void) onTransportState: (BOOL)connected
{
    
	DDLogSupport(@"On transport state: %d", connected);
    d->sipTransportUp = connected;
    
    if (!connected)
    {
        self.areTransportsShutdown = true;
        d->wasRegistered = NO;
    } else {
        self.areTransportsShutdown = false;
    }
//    if (d->wasRegistered && !connected)
//    {
//        DDLogSupport(@"Transport went down, trying to re-register");
//        [self setRegistered:YES];
//    }
    
}

- (void) onPrivateKeyReceived: (NSString *)privateKey qliqId:(NSString *)qliqId
{
    DDLogSupport(@"Received private key for %@ will try to process pending messages", qliqId);
    NSArray *encryptedMessages = [[EncryptedSipMessageDBService sharedService] messagesWithToQliqId:qliqId limit:0];
    for (EncryptedSipMessage *msg in encryptedMessages) {
        BOOL ok = NO;
        NSString *decrypted = [Crypto decryptFromBase64:msg.body privateKey:privateKey password:DEFAULT_GROUP_KEY_PASSWORD wasOk:&ok];
        
        if (ok) {
            [self onMessageReceived:decrypted fromQliqId:msg.fromQliqId toQliqId:msg.toQliqId mime:AT_MIME_TEXT_PLAIN rxdata:NULL extraHeaders:msg.extraHeaders];
        } else {
            DDLogError(@"Cannot decrypt message to %@ using new key", qliqId);
        }
        [[EncryptedSipMessageDBService sharedService] delete_:msg.messageId];
    }
}

#pragma mark - Voice calling methods -

+ (Contact *)contactForCallId:(NSNumber *)callId {
    pjsua_call_info ci;
    pjsua_call_get_info([callId intValue], &ci);

    NSString *userUri = pjstrToNSString(&ci.remote_info);
	NSString *qliqId = [QliqSip qliqIdFromSipUri:userUri];
    
    Contact * rez = [[QliqUserDBService sharedService] getUserWithId:qliqId];
	return rez;
}


- (void)answerCall:(int)call_id {
    DDLogSupport(@"*** User answered call: %d", call_id);
    
    //pjsip_cfg()->tsx.td = 32000; // Set to 30 seconds
    [self runOnSipThreadWait:YES block: ^{
        pjsua_call_answer(call_id, 200, NULL, NULL);
    }];
}

- (CallInitiationResult*)makeCall:(NSString *)qliqId {
    
    __block CallInitiationResult *rez;
    [self runOnSipThreadWait:YES block: ^{
        NSString *userUri = [self sipUriFromQliqId:qliqId];
        NSString *sipUri = [@"sip:" stringByAppendingFormat:@"%@", userUri];
    
        pj_status_t status;
        pj_str_t pjto;
        pj_cstr(&pjto, [sipUri UTF8String]);
        
        DDLogSupport(@"* User initiated a call to %@", userUri);
        
        //pjsip_cfg()->tsx.td = 32000; // Set to 30 seconds
        
        rez = [[CallInitiationResult alloc] init];
        
        int tmp;
        status = pjsua_call_make_call(d->acc_id, &pjto, 0, NULL, NULL, &tmp);
        
        if (status != PJ_SUCCESS) {
            char buf[1024];
            pj_str_t error = pj_strerror (status, &buf, 1024);
            NSString *errorStr = pjstrToNSString(&error);
            rez.call_id = -1;
            rez.error = errorStr;
        }
        else {
            rez.call_id = tmp;
        }
    }];
    return [rez autorelease];
}

- (void)declineCall:(int)call_id reasonCode:(SipReasonCode)reasonCode {
    DDLogSupport(@"*** declineCall %d", call_id);
    
    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_answer(call_id, reasonCode, nil, nil);
        }];
    }
}

- (void)endCall:(int)call_id {
    
    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_info ci;
            pjsua_call_get_info(call_id, &ci);
            
            DDLogSupport(@"* endCall with @%", pjstrToNSString(&ci.remote_info));
            pjsua_call_hangup(call_id, 0, nil, nil);
        }];
    }
}

- (void)endAllCalls {
    DDLogSupport(@"*** endAllCalls");
    
    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_hangup_all();
        }];
    }
}

- (void)muteMicForCallWithId:(int)call_id {

    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_info ci;
            pjsua_call_get_info(call_id, &ci);
            
            DDLogSupport(@"*** Call is muted: %d", call_id);
            pjsua_conf_disconnect(0, ci.conf_slot);
        }];
    }
}

- (void)unMuteMicForCallWithId:(int)call_id {

    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_info ci;
            pjsua_call_get_info(call_id, &ci);

            DDLogSupport(@"*** Call is un-muted: %d", call_id);
            pjsua_conf_connect(0, ci.conf_slot);
        }];
    }
}

- (void)start_ring:(int)call_id {
    DDLogSupport(@"*** start_ring %d", call_id);
    
    if (d->sipStarted) {
        [self runOnSipThreadWait:YES block: ^{
            pjsua_call_answer(call_id, 180, NULL, NULL);
        }];
        
        [self sip_ring_start];
    }
}

- (void)start_ringback {
    DDLogSupport(@"*** start_ringback");
    
    if (d->sipStarted) {
        [self sip_ringback_start];
    }
}

- (void)stop_ringback {
    DDLogSupport(@"*** stop_ringback");
    
    if (d->sipStarted) {
        [self sip_ringback_stop];
    }
}

- (void)stop_ring {
    DDLogSupport(@"*** stop_ring");
    if (d->sipStarted)
    {
        [self sip_ring_stop];
    }
}

#pragma mark Private

- (void)sip_ring_init {
    unsigned i;
    unsigned samples_per_frame;
	pjmedia_tone_desc tone[RING_CNT + RINGBACK_CNT];
	pj_str_t name;
    pj_status_t status;
    
    d->ringback_slot = PJSUA_INVALID_ID;
#if !RING_FILE
    d->ring_slot = PJSUA_INVALID_ID;
#else
    d->ring_timer = NULL;
#endif
    
	samples_per_frame = d->media_cfg.audio_frame_ptime * d->media_cfg.clock_rate * d->media_cfg.channel_count / 1000;
    
	/* Ringback tone (call is ringing) */
	name = pj_str("ringback");
	status = pjmedia_tonegen_create2(d->pool, &name,
                                     d->media_cfg.clock_rate,
                                     d->media_cfg.channel_count,
                                     samples_per_frame,
                                     16, PJMEDIA_TONEGEN_LOOP,
                                     &d->ringback_port);
	if (status != PJ_SUCCESS)
        //goto on_error;
        return; // FIXME
    
	pj_bzero(&tone, sizeof(tone));
	for (i=0; i<RINGBACK_CNT; ++i)
    {
        tone[i].freq1 = RINGBACK_FREQ1;
        tone[i].freq2 = RINGBACK_FREQ2;
        tone[i].on_msec = RINGBACK_ON;
        tone[i].off_msec = RINGBACK_OFF;
	}
	tone[RINGBACK_CNT-1].off_msec = RINGBACK_INTERVAL;
    
	pjmedia_tonegen_play(d->ringback_port, RINGBACK_CNT, tone,
                         PJMEDIA_TONEGEN_LOOP);
    
	status = pjsua_conf_add_port(d->pool, d->ringback_port, &d->ringback_slot);
    
	if (status != PJ_SUCCESS)
        //goto on_error;
        return; // FIXME
    
	/* Ring (to alert incoming call) */
#if !RING_FILE
	name = pj_str("ring");
	status = pjmedia_tonegen_create2(d->pool, &name,
                                     d->media_cfg.clock_rate,
                                     d->media_cfg.channel_count,
                                     samples_per_frame,
                                     16, PJMEDIA_TONEGEN_LOOP,
                                     &d->ring_port);
	if (status != PJ_SUCCESS)
        //goto on_error;
        return; // FIXME
    
	for (i=0; i<RING_CNT; ++i)
    {
        tone[i].freq1 = RING_FREQ1;
        tone[i].freq2 = RING_FREQ2;
        tone[i].on_msec = RING_ON;
        tone[i].off_msec = RING_OFF;
	}
	tone[RING_CNT-1].off_msec = RING_INTERVAL;
    
	pjmedia_tonegen_play(d->ring_port, RING_CNT, tone,
                         PJMEDIA_TONEGEN_LOOP);
    
	status = pjsua_conf_add_port(d->pool, d->ring_port,
                                 &d->ring_slot);
	if (status != PJ_SUCCESS)
        //goto on_error;
        return; // FIXME
#else
    /* It is easier to use pjsua_player_create/pjsua_player_destroy
     * but it is not possible to know if the user has configured the Settings
     * application to vibrate on ring or not.
     */
    CFURLRef soundFileURLRef;
    SystemSoundID aSoundID;
    OSStatus oStatus;
    // Get the main bundle for the app
	CFBundleRef mainBundle = CFBundleGetMainBundle ();
    // Get the URL to the sound file to play
	soundFileURLRef  =	CFBundleCopyResourceURL (mainBundle, CFSTR ("phone"),
                                                 CFSTR ("caf"), NULL);
    oStatus = AudioServicesCreateSystemSoundID (soundFileURLRef, &aSoundID);
    if (oStatus == kAudioServicesNoError)
        d->ring_id = aSoundID;
    else
        d->ring_id = kSystemSoundID_Vibrate;
    CFRelease(soundFileURLRef);
    
#endif
}


- (void)sip_ring_close {
    
    self.sip_ring_stop;
    
#if !RING_FILE
    if (d->ring_port != NULL) {
        pjmedia_port_destroy(d->ring_port);
        d->ring_port = NULL;
    }
    if (d->ring_slot != PJSUA_INVALID_ID) {
        pjsua_conf_remove_port(d->ring_slot);
        d->ring_slot = PJSUA_INVALID_ID;
    }
#endif
    
    if (d->ringback_slot != PJSUA_INVALID_ID) {
        pjsua_conf_remove_port(d->ringback_slot);
        d->ringback_slot = PJSUA_INVALID_ID;
    }
    if (d->ringback_port != NULL) {
        pjmedia_port_destroy(d->ringback_port);
        d->ringback_port = NULL;
    }
}

- (void)sip_ring_start {
    
    if (d->ring_on)
        return;
    
    d->ring_on = PJ_TRUE;
    
#if !RING_FILE
    if (++d->ring_cnt == 1 && d->ring_slot != PJSUA_INVALID_ID) {
        UInt32 route = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                                 sizeof(route), &route);
        pjsua_conf_connect(d->ring_slot, 0);
    }
#else
    if (++app_config->ring_cnt == 1) {
        CFRunLoopTimerContext context = {0, (void *)app_config, NULL, NULL, NULL};
        d->ring_timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
											 CFAbsoluteTimeGetCurrent(),
											 2.,
											 0, 0, sip_ring_callback,
											 &context);
        CFRunLoopAddTimer(CFRunLoopGetMain(), d->ring_timer, kCFRunLoopCommonModes);
    }
#endif
}

- (void)sip_ringback_start {
    
    if (d->ringback_on)
        return;
    d->ringback_on = PJ_TRUE;
    
    
    if (++d->ringback_cnt == 1 &&
        d->ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_connect(d->ringback_slot, 0);
    }
}

- (void)remote_ringback_start:(int)call_id {

    if (d->ringback_slot != PJSUA_INVALID_ID) {
        pjsua_conf_connect(d->ringback_slot, call_id);
    }
}

- (void)sip_ringback_stop {
    
    if (d->ringback_on) {
        //  app_config.call_data[call_id].ringback_on = PJ_FALSE;
        d->ringback_on = PJ_FALSE;
        
        pj_assert(d->ringback_cnt>0);
        if (--d->ringback_cnt == 0 && d->ringback_slot != PJSUA_INVALID_ID) {
            pjsua_conf_disconnect(d->ringback_slot, 0);
            pjmedia_tonegen_rewind(d->ringback_port);
        }
    }
}

- (void)sip_ring_stop {
    
    //if (app_config.call_data[call_id].ring_on)
    if (d->ring_on) {
        d->ring_on = PJ_FALSE;
        
        pj_assert(d->ring_cnt>0);
        
#if !RING_FILE
        if (--d->ring_cnt == 0 && d->ring_slot != PJSUA_INVALID_ID) {
            pjsua_conf_disconnect(d->ring_slot, 0);
            UInt32 route = kAudioSessionOverrideAudioRoute_None;
            AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                                     sizeof(route), &route);
            pjmedia_tonegen_rewind(d->ring_port);
        }
#else
        if (--app_config->ring_cnt == 0) {
            // UInt32 route = kAudioSessionOverrideAudioRoute_None;
            // AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
            //                          sizeof(route), &route);
            CFRunLoopTimerInvalidate(d->ring_timer);
            CFRelease(d->ring_timer);
            d->ring_timer = NULL;
        }
#endif
    }
}

- (void)setVoiceCodecPriorities {
    
    const pj_str_t ID_ALL = {"*", 1};
    pj_status_t status;
    pj_str_t codec = {NULL, 0};
    
    // Disable all codecs
    pjsua_codec_set_priority(&ID_ALL, PJMEDIA_CODEC_PRIO_DISABLED);
    
    // Make iLBC highest priority codec
    codec = pj_str("ILBC");
    status = pjsua_codec_set_priority(&codec,
                                      PJMEDIA_CODEC_PRIO_HIGHEST);
    if (status == PJ_SUCCESS)
        DDLogSupport(@"Code %s activated", codec.ptr);
    
    // Make PCMU & PCMA next highest priority codec
    codec = pj_str("PCMU");
    status = pjsua_codec_set_priority(&codec,
                                      PJMEDIA_CODEC_PRIO_NEXT_HIGHER);
    if (status == PJ_SUCCESS)
        DDLogSupport(@"Code %s activated", codec.ptr);
    
    // Make PCMU & PCMA next highest priority codec
    codec = pj_str("PCMA");
    status = pjsua_codec_set_priority(&codec,
                                      PJMEDIA_CODEC_PRIO_NEXT_HIGHER);
    if (status == PJ_SUCCESS)
        DDLogSupport(@"Code %s activated", codec.ptr);
    
}

- (void)setPJLogLevel {
    
#if DEBUG
    d->log_cfg.console_level = 6;
    d->log_cfg.level = 6;
    d->log_cfg.msg_logging = PJ_FALSE; // PJ_TRUE;
#else
	switch (ddLogLevel)
    {
		case LOG_LEVEL_INFO:
			d->log_cfg.console_level = 3;
			d->log_cfg.level = 3;
            d->log_cfg.msg_logging = PJ_FALSE; // PJ_TRUE;
			break;
		case LOG_LEVEL_VERBOSE:
			d->log_cfg.console_level = 6;
			d->log_cfg.level = 6;
            d->log_cfg.msg_logging = PJ_FALSE; // PJ_TRUE;
			break;
		default:
			d->log_cfg.console_level = 2;
			d->log_cfg.level = 2;
            d->log_cfg.msg_logging = PJ_FALSE;
			break;
	}
#endif
}

- (void)logReconfig {
	pjsua_reconfigure_logging(&d->log_cfg);
}

- (void)onMessageReceived:(NSString *)messageText fromQliqId:(NSString *)fromQliqId toQliqId:(NSString *)toQliqId mime:(NSString *)mime rxdata:(void *)rdata extraHeaders:(NSDictionary *)extraHeaders
{
    if (rdata != NULL) {
        pjsip_msg *msg = ((pjsip_rx_data *)rdata)->msg_info.msg;

        NSString *callIdStr = nil;
        pjsip_cid_hdr *h_cid = pjsip_msg_find_hdr(msg, PJSIP_H_CALL_ID, NULL);
        if (h_cid) {
            callIdStr = pjstrToNSString(&h_cid->id);
        }
        // If method called from pjproject then log this message
        DDLogSupport(@"SIP MESSAGE received from: %@, to: %@  calll-id: %@ (before any processing)", fromQliqId, toQliqId, callIdStr);
        
        extraHeaders = [[[NSMutableDictionary alloc] init] autorelease];
        const pj_str_t STR_X_MINUS = {"X-", 2};
        const pjsip_hdr *hdr = msg->hdr.next, *end = &msg->hdr;
        for (; hdr!=end; hdr = hdr->next) {
            if (pj_strncmp(&hdr->name, &STR_X_MINUS, STR_X_MINUS.slen) == 0) {
                NSString *headerName = pjstrToNSString(&hdr->name);
                pjsip_generic_string_hdr *str_hdr = (pjsip_generic_string_hdr *)hdr;
                NSString *headerValue = pjstrToNSString(&str_hdr->hvalue);
                [extraHeaders setObject:headerValue forKey:headerName];
            }
        }
    }
    
    NSString *senderQliqId = [extraHeaders objectForKey:@"X-sender"];
    if (senderQliqId.length > 0) {
        NSString *orgFromQliqId = fromQliqId;
        fromQliqId = senderQliqId;
        DDLogSupport(@"Changing from qliq id for impersonated message, org. from: %@, impersonated: %@", orgFromQliqId, fromQliqId);
    }
    
    if (![fromQliqId isEqualToString:@"notifier"])
    {
        QliqUser *fromUser = [[QliqUserDBService sharedService] getUserWithId:fromQliqId];
        if (fromUser == nil) {
            DDLogError(@"Received a message from unknown qliq id: %@", fromQliqId);
            
            bool hadOutstandingRequest = [d->messagesFromUnknownUsersByQliqId objectForKey:fromQliqId] != nil;
            
            EncryptedSipMessage *msg = [[EncryptedSipMessage alloc] init];
            msg.fromQliqId = fromQliqId;
            msg.toQliqId = toQliqId;
            msg.body = messageText;
            msg.mime = mime;
            msg.extraHeaders = extraHeaders;
            
            NSMutableArray *array = [d->messagesFromUnknownUsersByQliqId objectForKey:fromQliqId];
            if (!array)
            {
                array = [[NSMutableArray alloc] init];
                [d->messagesFromUnknownUsersByQliqId setObject:array forKey:fromQliqId];
                [array release];
            }
            [array addObject:msg];
            [msg release];
            
            if (!hadOutstandingRequest) {
                [[GetContactInfoService sharedService] getContactInfo:fromQliqId completitionBlock:^(QliqUser *notUsed, NSError *error) {
                    if (!error){
                        DDLogSupport(@"Got contact information for recevied message from: %@", fromQliqId);
                        NSArray *messages = [[[d->messagesFromUnknownUsersByQliqId objectForKey:fromQliqId] copy] autorelease];
                        for (EncryptedSipMessage *msg in messages) {
                            // We don't pass the rdata argument because it will be already freed by pjproject at this point
                            [self onMessageReceived:msg.body fromQliqId:msg.fromQliqId toQliqId:msg.toQliqId mime:msg.mime rxdata:NULL extraHeaders:msg.extraHeaders];
                        }
                    } else {
                        if (error.code == ErrorCodeStaleData || error.code == ErrorCodeNotContact) {
                            DDLogSupport(@"Received a message from an user that is no longer a contact: %@", fromQliqId);
                        }
                    }
                    [d->messagesFromUnknownUsersByQliqId removeObjectForKey:fromQliqId];
                }];
            }
            
            return;
        }
    }
    
    SipContact * mySipContact = [UserSessionService currentUserSession].sipContact;

    if ([AT_MIME_TEXT_BASE64 isEqualToString:mime]) {
        if ([mySipContact.qliqId isEqualToString:toQliqId]) {
            DDLogError(@"To user message remains encrypted here");
            return;
        } else {
            BOOL needToDownloadKey = NO;
            NSString *privateKey = [QliqSip privateKeyForQliqId: toQliqId];
            if ([privateKey length] == 0) {
                needToDownloadKey = YES;
                DDLogSupport(@"Cannot find private key for qliq id: %@", toQliqId);
            } else {
                BOOL ok = NO;
                NSString *decrypted = [Crypto decryptFromBase64:messageText privateKey:privateKey password:DEFAULT_GROUP_KEY_PASSWORD wasOk:&ok];
                
                if (ok) {
                    messageText = decrypted;
                } else {
                    needToDownloadKey = YES;
                    DDLogError(@"Cannot decrypt message to %@ using existing key", toQliqId);
                }
            }
            
            if (needToDownloadKey) {
                EncryptedSipMessage *msg = [[EncryptedSipMessage alloc] init];
                msg.fromQliqId = fromQliqId;
                msg.toQliqId = toQliqId;
                msg.body = messageText;
                msg.timestamp = [[NSDate date] timeIntervalSince1970];
                msg.mime = mime;
                msg.extraHeaders = extraHeaders;
                [[EncryptedSipMessageDBService sharedService] insert:msg];
                [msg release];
                
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          toQliqId, @"QliqId",
                                          extraHeaders, @"ExtraHeaders",
                                          nil];
                [NSNotificationCenter postNotificationToMainThread:SIPPrivateKeyNeededNotification withObject:nil userInfo:userinfo needWait:NO];

                return;
            }
        }
    }
    
    SipContact *fromContact  = [[[SipContactDBService alloc] init] autorelease];
    [fromContact sipContactForQliqId:fromQliqId];
    
    BOOL allowMessagesFromUnknownBuddies = YES; // for invitation message
    
    if (!fromContact && !allowMessagesFromUnknownBuddies)
    {
        DDLogSupport(@"Recevied message from unkown contact: %@", fromQliqId);
    }
    else
    {   
        if (ddLogLevel == LOG_LEVEL_VERBOSE)
            DDLogVerbose(@"Message received from %@: '%@'", fromQliqId, messageText);
        else
            DDLogSupport(@"Message received from %@", fromQliqId);

        NSMutableDictionary *userinfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  fromQliqId, @"FromQliqId",
                                  toQliqId, @"ToQliqId",
                                  messageText, @"Message",
                                  nil];
        if ([extraHeaders count] > 0) {
            [userinfo setObject:extraHeaders forKey:@"ExtraHeaders"];
        }
        
        [NSNotificationCenter postNotificationToMainThread:SIPMessageNotification withObject:nil userInfo:userinfo needWait:NO];
    }
}

-(void) sendLogoutRequest
{
    [self runOnSipThreadWait:YES block: ^{
        pjsip_method method;
        pjsip_tx_data *tdata;
        pj_status_t status;
        pjsua_acc_info info;
        
        status = pjsua_acc_get_info(d->acc_id, &info);
        if (status == PJ_SUCCESS) {
            const pj_str_t str_method;
            pj_cstr(&str_method, "LOGOUT");
            pjsip_method_init_np(&method, &str_method);
            
            pjsua_acc_create_request(d->acc_id, &method, &info.acc_uri, &tdata);

            // Add contact header
            pj_str_t str_contact;
            pjsua_acc_create_uac_contact(tdata->pool, &str_contact, d->acc_id, &info.acc_uri);
            pjsip_contact_hdr *contact = pjsip_contact_hdr_create(tdata->pool);
            contact->uri = pjsip_parse_uri(tdata->pool, str_contact.ptr, str_contact.slen, PJSIP_PARSE_URI_AS_NAMEADDR);
            pjsip_msg_add_hdr(tdata->msg, (pjsip_hdr *) contact);
            
            // Add X-devkey header
            if (d->devKeyHeader) {
                pjsip_msg_add_hdr(tdata->msg, (pjsip_hdr *) d->devKeyHeader);
            }
            
            NSString *regid = nil;
            pjsip_param instance_param;

            NSString *deviceUuid = [[UIDevice currentDevice] qliqUUID];
            if (deviceUuid.length > 0) {
                regid = [NSString stringWithFormat:@"\"<urn:uuid:%@>\"", deviceUuid];
                instance_param.prev = 0;
                instance_param.next = 0;
                pj_cstr(&instance_param.name, "+sip.instance");
                pj_cstr(&instance_param.value, [regid UTF8String]);
                pj_list_push_back(&contact->other_param, &instance_param);
            } else {
                DDLogError(@"Cannot retrieve device uuid for logout request");
            }
            
            
            status = pjsip_endpt_send_request(pjsua_get_pjsip_endpt(), tdata, -1, NULL, NULL);
            if (status != PJ_SUCCESS) {
                pjsua_perror(THIS_FILE, "Unable to send request", status);
                return;
            }
        }
    }];
}

- (void) increaseReceivedMessagesCount
{
    d->receivedMessagesCount++;
    d->timeSinceLastMessageOrNotify = [[NSDate date] timeIntervalSince1970];
    
    if (d->pendingMessagesCount > 0 && d->receivedMessagesCount >= d->pendingMessagesCount) {
        [self onMessageDumpFinished:NO];
    }
}

- (void) onMessageDumpFinished:(BOOL)error
{
    DDLogSupport(@"onMessageDumpFinished. Status: %d", error);
    int receivedCount = d->receivedMessagesCount;
    d->receivedMessagesCount = 0;
    d->pendingMessagesCount = 0;
    
    if (d->messageDumpTimeoutTimer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [d->messageDumpTimeoutTimer invalidate];
            d->messageDumpTimeoutTimer = nil;
        });
    }
    
    NSDictionary *userInfo = @{@"error": [NSNumber numberWithBool:error],
                               @"receivedMessagesCount": [NSNumber numberWithInteger: receivedCount]};
    [NSNotificationCenter postNotificationToMainThread:SipMessageDumpFinishedNotification withObject:nil userInfo:userInfo needWait:NO];
}

- (void) onMessageDumpTimedOut:(NSTimer *)theTimer
{
    NSTimeInterval timeDiff = [[NSDate date] timeIntervalSince1970] - d->timeSinceLastMessageOrNotify;
    if (d->pendingMessagesCount > 0 && timeDiff > 60) {
        [self onMessageDumpFinished:YES];
    }
}

+ (NSString *) captureRegExp:(NSString *)text withPattern:(NSString *)pattern
{
    NSString *ret = nil;
    NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionSearch error:nil];
    
    NSArray *matches = [rx matchesInString:text
                                         options:0
                                           range:NSMakeRange(0, [text length])];
    if ([matches count] > 0) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSRange matchRange = [match rangeAtIndex:1];
        ret = [text substringWithRange:matchRange];
    }
    return ret;
}



- (long) serverTimeDelta
{
    return d->serverTimeDelta;
}

- (NSString *) mySipHost
{
    NSRange range = [self.accountSettings.sipUri rangeOfString:@"@"];
    return [self.accountSettings.sipUri substringFromIndex:range.location + 1];
}

- (NSTimeInterval) adjustedTimeFromNetwork:(NSTimeInterval)time
{
    return time + d->serverTimeDelta;
}

- (NSTimeInterval) adjustTimeForNetwork:(NSTimeInterval)time
{
    return time - d->serverTimeDelta;
}

- (int) pendingMessagesCount
{
    return d->pendingMessagesCount;
}

- (int) receivedMessagesCount
{
    return d->receivedMessagesCount;
}

+ (BOOL) haveCredentialsChanged:(NSString *)qliqId email:(NSString *)email pubkeyMd5:(NSString *)pubkeyMd5
{
    BOOL ret = NO;
    
    if ([[UserSessionService currentUserSession].user.qliqId isEqualToString: qliqId]) {
        
        if (![[UserSessionService currentUserSession].user.email isEqualToString:email]) {
            DDLogSupport(@"User's email has changed, need to logout (old: %@, new: %@)", [UserSessionService currentUserSession].user.email, email);
            ret = YES;
        } else {
            if (![[[[Crypto instance] publicKeyString] md5] isMd5Equal:pubkeyMd5]) {
                DDLogSupport(@"User's pubkey md5 has changed, need to logout");
                ret = YES;
            }
        }
    }
    return ret;
}

- (BOOL) specialCaseProcessLoginCredentialsChangedNotification:(NSString *)jsonString
{
    BOOL ret = false;
    NSError *error = nil;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE_MESSAGE];
    NSString *subject = [message objectForKey:MESSAGE_MESSAGE_SUBJECT];
    if ([@"login_credentials" isEqualToString:subject]) {
        NSDictionary *dataDict = [message objectForKey:MESSAGE_MESSAGE_DATA];
        NSString *qliqId = [dataDict objectForKey:@"qliq_id"];
        NSString *email = [dataDict objectForKey:@"email"];
        NSString *pubkeyMd5 = [dataDict objectForKey:@"pubkey_md5"];
        if ([QliqSip haveCredentialsChanged:qliqId email:email pubkeyMd5:pubkeyMd5]) {
            DDLogSupport(@"User's credentials have changed, ignoring other SIP message until logout");
            // Here just trigger ignoring SIP traffic, the actual processing of this CN happens in QliqConnect
            // on main thread after this method finishes
            s_ignoreSipTraffic = YES;
        }
    }
    return ret;
}

@end


/**
 * Notify application on incoming pager (i.e. MESSAGE request).
 * Argument call_id will be -1 if MESSAGE request is not related to an
 * existing call.
 *
 * See also \a on_pager2() callback for the version with \a pjsip_rx_data
 * passed as one of the argument.
 *
 * @param call_id	    Containts the ID of the call where the IM was
 *			    sent, or PJSUA_INVALID_ID if the IM was sent
 *			    outside call context.
 * @param from	    URI of the sender.
 * @param to	    URI of the destination message.
 * @param contact	    The Contact URI of the sender, if present.
 * @param mime_type	    MIME type of the message.
 * @param body	    The message content.
 */
static void on_pager2_cb(pjsua_call_id call_id, const pj_str_t *from,
						const pj_str_t *to, const pj_str_t *contact,
						const pj_str_t *mime_type, const pj_str_t *body,
                        pjsip_rx_data *rdata, pjsua_acc_id acc_id)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
	
    @autoreleasepool {
        
        NSString *toUri = [QliqSip removeSipUriDecorator: pjstrToNSString(to)];
        NSString *fromUri = [QliqSip removeSipUriDecorator: pjstrToNSString(from)];
        NSString *toQliqId = [QliqSip qliqIdFromSipUri:toUri];
        NSString *fromQliqId = [QliqSip qliqIdFromSipUri:fromUri];
        NSString *messageText = pjstrToNSString(body);
        NSString *mime = pjstrToNSString(mime_type);
        
        [[QliqSip sharedQliqSip] onMessageReceived:messageText fromQliqId:fromQliqId toQliqId:toQliqId mime:mime rxdata:rdata extraHeaders:nil];
        
        DDLogVerbose(@"ENDOF: %s ", __func__);
    }
}

static void on_pager_status2_cb(pjsua_call_id call_id,
								const pj_str_t *to,
								const pj_str_t *body,
								void *user_data,
								pjsip_status_code status,
								const pj_str_t *reason,
								pjsip_tx_data *tdata,
								pjsip_rx_data *rdata,
								pjsua_acc_id acc_id)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
	
    @autoreleasepool {
        
        NSString *bodyStr = pjstrToNSString(body);
        NSString *toStr = pjstrToNSString(to);
        NSString *reasonStr = pjstrToNSString(reason);
        NSString *callIdStr = nil;
        
        pjsip_cid_hdr *h_cid = pjsip_msg_find_hdr(tdata->msg, PJSIP_H_CALL_ID, NULL);
        if (h_cid)
        {
            callIdStr = pjstrToNSString(&h_cid->id);
        }
        
        UIApplicationState state = [AppDelegate applicationState];
        DDLogSupport(@"Message status, on_pager_status2_cb called when app state is: %ld", state);
        
        [[QliqSip sharedQliqSip] onPagerStatus: status
                                            to: toStr
                                          body: bodyStr
                                        reason: reasonStr
                                      userData: user_data
                                        callId: callIdStr];
        
        
        DDLogVerbose(@"ENDOF: %s ", __func__);
    }
}

static void logger_cb(int level, const char *data, int len)
{
#ifndef NDEBUG
    NSLog(@"SIP: %*.s", len, data);
#endif
    
//    DDLogVerbose(@"STARTOF: %s ", __func__);
    @autoreleasepool {
        
        switch (level) {
            case 1:
                DDLogError([NSString stringWithUTF8String:data]);
                break;
            case 2:
                DDLogWarn([NSString stringWithUTF8String:data]);
                break;
            case 3:
                DDLogSupport([NSString stringWithUTF8String:data]);
                break;
            case 4:
                DDLogInfo([NSString stringWithUTF8String:data]);
                break;
            default:
                DDLogVerbose([NSString stringWithUTF8String:data]);
                break;
                
        }
        //    DDLogVerbose(@"ENDOF: %s ", __func__);
    }
}

static void on_reg_state_cb(pjsua_acc_id acc_id)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
    
	pjsua_acc_info info;
    info.status = 0;
	pj_status_t ret = pjsua_acc_get_info(acc_id, &info);
    
	@autoreleasepool {
        
        DDLogSupport(@"ret: %d, has_reg: %d, status: %d, expires: %d", ret, info.has_registration, info.status, info.expires);
        
        if (ret != PJ_SUCCESS)
            DDLogSupport(@"SIP (un)registration FAILED due to get_account error to ret=%d", ret);
        
        // Krishna 8/5/2014 - Seperated Registration and Unregistration callback handling
        // To make it less confusing.
        //
        if ([[QliqSip sharedQliqSip] isRegistrationInProgress] == YES || info.expires != -1)
        {
            BOOL registered = (info.status == 200);
            [[QliqSip sharedQliqSip] onRegistration: registered status: info.status];
        } else {
            [[QliqSip sharedQliqSip] onUnRegistration: info.status];
        }
        
        DDLogVerbose(@"ENDOF: %s ", __func__);
    }
}

static void on_transport_state_cb(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
    BOOL connected = NO;
    
    switch (state) {
        case PJSIP_TP_STATE_CONNECTED:
            connected = YES;
            break;
			
        case PJSIP_TP_STATE_DISCONNECTED:
            DDLogSupport(@">>> SIP transport disconnected");
            connected = NO;
            break;
            
        default:
            break;
    }
    
    @autoreleasepool {
        dispatch_async_main(^{
            [QliqSip sharedQliqSip].transportUp = connected;
            
            [[QliqSip sharedQliqSip] onTransportState: connected];
            DDLogVerbose(@"ENDOF: %s ", __func__);
        });
    }
}

/* NAT detection result */
static void on_nat_detect_cb(const pj_stun_nat_detect_result *res)
{
    if (res->status != PJ_SUCCESS) {
        DDLogError(@"NAT detection failed. %d", res->status);
    } else {
        DDLogInfo(@"NAT detected as %s", res->nat_type_name);
    }
}

/*
 * Notification on ICE error.
 */
static void on_ice_transport_error(int index, pj_ice_strans_op op,
                                   pj_status_t status, void *param)
{
    PJ_UNUSED_ARG(op);
    PJ_UNUSED_ARG(param);
    DDLogError(@"ICE keep alive failure for transport %d, status %d", index, status);
}

static void send_generic_respoonse(pjsip_rx_data *rdata, pjsip_status_code status_code)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
    pjsip_tx_data *tdata;
    pjsip_status_code status = pjsip_endpt_create_response(pjsua_get_pjsip_endpt(), rdata,
														   status_code, NULL, &tdata);
	if (status != PJ_SUCCESS) {
        DDLogSupport(@"Unable to create response: %d", status);
		return;
	}
	
	/* Add Allow if we're responding with 405 */
	if (status_code == PJSIP_SC_METHOD_NOT_ALLOWED) {
		const pjsip_hdr *cap_hdr;
		cap_hdr = pjsip_endpt_get_capability(pjsua_get_pjsip_endpt(),
											 PJSIP_H_ALLOW, NULL);
		if (cap_hdr) {
			pjsip_msg_add_hdr(tdata->msg, (pjsip_hdr*)pjsip_hdr_clone(tdata->pool, cap_hdr));
		}
	}
	
	/* Add User-Agent header */
	{
/*
		pj_str_t user_agent;
		char tmp[255];
		const pj_str_t USER_AGENT_HDR = {"User-Agent", 10};
		pjsip_hdr *h;
		
		pj_ansi_snprintf(tmp, sizeof(tmp), USER_AGENT " " USER_AGENT_VERSION);
		pj_strdup2_with_null(tdata->pool, &user_agent, tmp);
		
		h = (pjsip_hdr*) pjsip_generic_string_hdr_create(tdata->pool,
														 &USER_AGENT_HDR,
														 &user_agent);
*/
		const pj_str_t USER_AGENT_HDR = {"User-Agent", 10};
		pjsip_hdr *h;
        
		h = (pjsip_hdr*) pjsip_generic_string_hdr_create(tdata->pool,
														 &USER_AGENT_HDR,
														 s_userAgent);
        
		pjsip_msg_add_hdr(tdata->msg, h);
	}
	
	pjsip_endpt_send_response2(pjsua_get_pjsip_endpt(), rdata, tdata, NULL,
							   NULL);
    DDLogVerbose(@"ENDOF: %s ", __func__);
	return;
}

/* Notification on incoming request
 * Handle requests which are unhandled by pjsua, eg. incoming
 * PUBLISH, NOTIFY w/o SUBSCRIBE, PING...
 */
static pj_bool_t default_mod_on_rx_request(pjsip_rx_data *rdata)
{
    pjsip_msg *msg = rdata->msg_info.msg;
    
    /* Only want to handle NOTIFY requests. */
    if (pjsip_method_cmp(&msg->line.req.method, &pjsip_notify_method) == 0)
    {
        @autoreleasepool {
            
            NSString *callIdStr = pjstrToNSString(&rdata->msg_info.cid->id);
            NSString *statusStr = nil;
            NSString *deliveredToQliqId = nil;
            int totalRecipientCount = 0;
            int deliveredRecipientCount = 0;
            long deliveredAt = 0;
            
            const pj_str_t STR_EVENT = {"Event", 5};
            pjsip_generic_string_hdr *event_hdr = (pjsip_generic_string_hdr *) pjsip_msg_find_hdr_by_name(msg, &STR_EVENT, NULL);
            if (event_hdr != NULL) {
                callIdStr = pjstrToNSString(&rdata->msg_info.cid->id);
                statusStr = pjstrToNSString(&event_hdr->hvalue);
            }
            
            BOOL dontCountThisNotify = NO;
            const pj_str_t STR_XEVENT = {"X-Event", 7};
            pjsip_generic_string_hdr *xevent_hdr = (pjsip_generic_string_hdr *) pjsip_msg_find_hdr_by_name(msg, &STR_XEVENT, NULL);
            if (xevent_hdr != NULL) {
                NSString *xeventValue = pjstrToNSString(&xevent_hdr->hvalue);
                xeventValue = [xeventValue stringByAppendingString:@";"];
                
                NSString *caputre = [QliqSip captureRegExp:xeventValue withPattern:@"id=(.+?);"];
                DDLogSupport(@"SIP NOTIFY received with id: '%@' value: '%@' for call-id: %@", caputre, xeventValue, callIdStr);
                
                if ([@"m-status" isEqualToString:caputre]) {
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@"dcount=(\\d+);"];
                    deliveredRecipientCount = [caputre intValue];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@"rcount=(\\d+);"];
                    totalRecipientCount = [caputre intValue];
                    deliveredToQliqId = [QliqSip captureRegExp:xeventValue withPattern:@"delivered-to=(.+?);"];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@"delivered-at=(\\d+);"];
                    deliveredAt = (long)[caputre longLongValue];
                    deliveredAt += [[QliqSip sharedQliqSip] serverTimeDelta];
                    
                    if ([statusStr length] > 0 && [statusStr intValue] > 0)  {
                        [[QliqSip sharedQliqSip] onNotify:callIdStr status:[statusStr intValue] qliqId:deliveredToQliqId deliveredRecipientCount:deliveredRecipientCount totalRecipientCount:totalRecipientCount deliveredAt:deliveredAt];
                    }
                } else if ([@"recipient-status" isEqualToString:caputre]) {
                    NSString *recipientQliqId = [QliqSip captureRegExp:xeventValue withPattern:@"recipient-id=(.+?);"];
                    NSString *statusText = [QliqSip captureRegExp:xeventValue withPattern:@" status=(.+?);"];
                    int statusCode = [[QliqSip captureRegExp:xeventValue withPattern:@" status-code=(\\d+);"] intValue];
                    long at = [[QliqSip captureRegExp:xeventValue withPattern:@" at=(\\d+);"] longValue];
                    at += [[QliqSip sharedQliqSip] serverTimeDelta];
                    int recipientCount = [[QliqSip captureRegExp:xeventValue withPattern:@" rcount=(\\d+);"] intValue];
                    
                    [[QliqSip sharedQliqSip] onRecipientStatusNotify:callIdStr qliqId:recipientQliqId statusText:statusText statusCode:statusCode at:at recipientCount:recipientCount];
                    
                } else if ([@"opened" isEqualToString:caputre]) {
                    NSString *openedByQliqId = nil;
                    int totalRecipientCount = 0;
                    int openedRecipientCount = 0;
                    long openedAt = 0;
                    
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" count=(\\d+);"];
                    openedRecipientCount = [caputre intValue];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" rcount=(\\d+);"];
                    totalRecipientCount = [caputre intValue];
                    openedByQliqId = [QliqSip captureRegExp:xeventValue withPattern:@" by=(.+?);"];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" at=(\\d+);"];
                    openedAt = (long) [caputre longLongValue];
                    openedAt += [[QliqSip sharedQliqSip] serverTimeDelta];
                    
                    [[QliqSip sharedQliqSip] onOpenedNotify:callIdStr qliqId:openedByQliqId openedRecipientCount:openedRecipientCount totalRecipientCount:totalRecipientCount openedAt:openedAt];
                    
                } else if ([@"acked" isEqualToString:caputre]) {
                    NSString *openedByQliqId = nil;
                    int totalRecipientCount = 0;
                    int ackedRecipientCount = 0;
                    long openedAt = 0;
                    
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" count=(\\d+);"];
                    ackedRecipientCount = [caputre intValue];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" rcount=(\\d+);"];
                    totalRecipientCount = [caputre intValue];
                    openedByQliqId = [QliqSip captureRegExp:xeventValue withPattern:@" by=(.+?);"];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" at=(\\d+);"];
                    openedAt = (long) [caputre longLongValue];
                    openedAt += [[QliqSip sharedQliqSip] serverTimeDelta];
                    
                    [[QliqSip sharedQliqSip] onAckedNotify:callIdStr qliqId:openedByQliqId ackedRecipientCount:ackedRecipientCount totalRecipientCount:totalRecipientCount openedAt:openedAt];

                } else if ([@"deleted" isEqualToString:caputre]) {
                    
                    NSString *byQliqId = nil;
                    long at = 0;
                    BOOL isRecall = NO;
                    
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" reason=(.+?);"];
                    if ([@"recall" isEqualToString:caputre]) {
                        isRecall = YES;
                    }
                    byQliqId = [QliqSip captureRegExp:xeventValue withPattern:@" by=(.+?);"];
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" at=(\\d+);"];
                    at = (long) [caputre longLongValue];
                    at += [[QliqSip sharedQliqSip] serverTimeDelta];
                    
                    if (isRecall) {
                        [[QliqSip sharedQliqSip] onRecalledNotify:callIdStr qliqId:byQliqId recalledAt:at];                        
                    } else {
                        [[QliqSip sharedQliqSip] onDeletedNotify:callIdStr];
                    }
                    
                } else if ([@"reginfo" isEqualToString:caputre]) {
                    dontCountThisNotify = YES;
                    long serverTime = 0;
                    int pendingMessages = 0;
                    
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" tse=(\\d+);"];
                    serverTime = (long) [caputre longLongValue];
                    
                    caputre = [QliqSip captureRegExp:xeventValue withPattern:@" pending-messages=(\\d+);"];
                    pendingMessages = [caputre intValue];
                    
                    long localTime = time(NULL);
                    long serverTimeDelta = localTime - serverTime;
                    DDLogSupport(@"serverTime: %ld, localTime: %ld, delta: %ld", serverTime, localTime, serverTimeDelta);
                    [[QliqSip sharedQliqSip] onRegInfoNotify:(long)serverTimeDelta: pendingMessages];
                    
                    // WHen there are no pending messages in reginfo, we can raise the onMessageDumpFinished
                    //
                    if (pendingMessages <= 0) {
                        [[QliqSip sharedQliqSip] onMessageDumpFinished:NO];
                    }
                } else if ([@"message-end" isEqualToString:caputre]) {
                    [[QliqSip sharedQliqSip] onMessageDumpFinished:NO];
                }
            }
            
            send_generic_respoonse(rdata, PJSIP_SC_OK);
        }
        
        return PJ_TRUE;
    }
    
    return PJ_FALSE;
}

#ifndef NDEBUG

static pj_bool_t sip_log_message(BOOL isRx, BOOL isRequest, int len, const char *data)
{
    if (s_sipLogFile) {
        const char *header = (isRx ? "Incoming" : " Outgoing");
        fwrite(header, 1, strlen(header), s_sipLogFile);
        
        header = (isRequest ? " Request\n" : " Response\n");
        fwrite(header, 1, strlen(header), s_sipLogFile);
        
        fwrite(data, 1, len, s_sipLogFile);
        fwrite("\n", 1, 1, s_sipLogFile);
        fflush(s_sipLogFile);
    }
    
    if (s_sipLogSocket != -1) {
        int totalLen = len + 1 + 1 + 1;
        totalLen = htonl(totalLen);
        send(s_sipLogSocket, &totalLen, sizeof(totalLen), 0);
        
        char messageType = 1;
        send(s_sipLogSocket, &messageType, sizeof(messageType), 0);
        send(s_sipLogSocket, &isRx, sizeof(isRx), 0);
        send(s_sipLogSocket, &isRequest, sizeof(isRequest), 0);
        send(s_sipLogSocket, data, len, 0);
    }
}

static pj_bool_t file_logger_mod_on_rx_message(pjsip_rx_data *rdata, BOOL isRequest)
{
    int len = rdata->msg_info.len;
    const char *data = rdata->msg_info.msg_buf;
    
    sip_log_message(YES, isRequest, len, data);
    return PJ_FALSE;
}

static pj_bool_t file_logger_mod_on_tx_message(pjsip_tx_data *tdata, BOOL isRequest)
{
    int len = (tdata->buf.cur - tdata->buf.start);
    const char *data = tdata->buf.start;
    
    sip_log_message(NO, isRequest, len, data);
    return PJ_FALSE;
}

static pj_bool_t file_logger_mod_on_rx_request(pjsip_rx_data *rdata)
{
    return file_logger_mod_on_rx_message(rdata, YES);
}

static pj_bool_t file_logger_mod_on_rx_response(pjsip_rx_data *rdata)
{
    return file_logger_mod_on_rx_message(rdata, NO);
}

static pj_bool_t file_logger_mod_on_tx_request(pjsip_tx_data *tdata)
{
    return file_logger_mod_on_tx_message(tdata, YES);
}

static pj_bool_t file_logger_mod_on_tx_response(pjsip_tx_data *tdata)
{
    return file_logger_mod_on_tx_message(tdata, NO);
}

#endif // #ifndef NDEBUG

static pj_bool_t encryption_mod_on_rx_request(pjsip_rx_data *rdata)
{
    DDLogVerbose(@"STARTOF: %s ", __func__);
    pj_bool_t ret = PJ_FALSE;
    pj_str_t from, to;
    pjsip_msg *msg;

    if (s_ignoreSipTraffic) {
        pjsip_endpt_respond(pjsua_get_pjsip_endpt(), NULL, rdata, PJSIP_AC_AMBIGUOUS, NULL,
                            NULL, NULL, NULL);
        DDLogVerbose(@"ENDOF: %s (ignore SIP traffic) ", __func__);
        return PJ_TRUE;
    }
    
    msg = rdata->msg_info.msg;
    
    /* Only want to handle MESSAGE requests. */
    if (pjsip_method_cmp(&msg->line.req.method, &pjsip_message_method) != 0) {
        return PJ_FALSE;
    }
    
    
    /* Should not have any transaction attached to rdata. */
    PJ_ASSERT_RETURN(pjsip_rdata_get_tsx(rdata)==NULL, PJ_FALSE);
    
    /* Should not have any dialog attached to rdata. */
    PJ_ASSERT_RETURN(pjsip_rdata_get_dlg(rdata)==NULL, PJ_FALSE);
    
    
    /* For the source URI, we use Contact header if present, since
     * Contact header contains the port number information. If this is
     * not available, then use From header.
     */
    from.ptr = (char*)pj_pool_alloc(rdata->tp_info.pool, PJSIP_MAX_URL_SIZE);
    from.slen = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR,
                                rdata->msg_info.from->uri,
                                from.ptr, PJSIP_MAX_URL_SIZE);
    if (from.slen < 1)
        from = pj_str("<--URI is too long-->");

    to.ptr = (char*)pj_pool_alloc(rdata->tp_info.pool, PJSIP_MAX_URL_SIZE);
    to.slen = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR,
                                rdata->msg_info.to->uri,
                                to.ptr, PJSIP_MAX_URL_SIZE);
    if (to.slen < 1)
        to = pj_str("<--URI is too long-->");
    
    pjsip_msg_body *body = rdata->msg_info.msg->body;
    pj_str_t mime_type;
    char buf[256];
    pjsip_media_type *m;
    pj_str_t text_body;
    
    /* Save text body */
    if (body) {
        text_body.ptr = (char*)rdata->msg_info.msg->body->data;
        text_body.slen = rdata->msg_info.msg->body->len;
        
        /* Get mime type */
        m = &rdata->msg_info.msg->body->content_type;
        mime_type.ptr = buf;
        mime_type.slen = pj_ansi_snprintf(buf, sizeof(buf),
                                          "%.*s/%.*s",
                                          (int)m->type.slen,
                                          m->type.ptr,
                                          (int)m->subtype.slen,
                                          m->subtype.ptr);
        if (mime_type.slen < 1)
            mime_type.slen = 0;
        
        
    } else {
        text_body.ptr = mime_type.ptr = "";
        text_body.slen = mime_type.slen = 0;
    }
    
    Crypto *s_crypto = [Crypto instance];
    
    if (s_crypto && text_body.slen > 0 && !strncmp(mime_type.ptr, MIME_TEXT_BASE64, mime_type.slen))
    {
        // This is an encrypted message.
        @autoreleasepool {
            
            NSString *toUri = [QliqSip removeSipUriDecorator: pjstrToNSString(&to)];
            NSString *toQliqId = [QliqSip qliqIdFromSipUri:toUri];
            
            // Try to decrypt only messages to the current user
            if ([[UserSessionService currentUserSession].user.qliqId isEqualToString:toQliqId]) {
                BOOL ok;
                NSString *clearText = [s_crypto decryptFromBase64: pjstrToNSString(&text_body) wasOk:&ok];
                
                if (ok) {
                    // Allocate memory and replace the encrypted text body with clear text
                    unsigned int clearTextLen = [clearText length];
                    rdata->msg_info.msg->body->len = clearTextLen;
                    rdata->msg_info.msg->body->data = pj_pool_alloc(rdata->tp_info.pool, clearTextLen);
                    memcpy(rdata->msg_info.msg->body->data, [clearText UTF8String], clearTextLen);
                    
                    // Replace mime type
                    static const pj_str_t STR_MIME_TYPE = {"text", 4};
                    static const pj_str_t STR_MIME_SUBTYPE = {"plain", 5};
                    pjsip_media_type *mime_type = &rdata->msg_info.msg->body->content_type;
                    mime_type->type = STR_MIME_TYPE;
                    mime_type->subtype = STR_MIME_SUBTYPE;
                } else {
                    DDLogError(@"Cannot decrypt message from: %@", pjstrToNSString(&from));
                    
                    //[[SetPublicKeyService sharedService] setPublicKey:[s_crypto publicKeyString]];
                    
                    // Inform the remote that we cannot decrypt the message.
                    // The other party should update our public key and retransmit the message.
                    pjsip_endpt_respond(pjsua_get_pjsip_endpt(), NULL, rdata, PJSIP_SC_UNDECIPHERABLE, NULL,
                                        NULL, NULL, NULL);
                    ret = PJ_TRUE;
                }
            }
            
            [[QliqSip sharedQliqSip] increaseReceivedMessagesCount];
        }
    } else {
        
        @autoreleasepool {
            // If this is a message from 'notifier@qliqsoft.com' and Call-ID starts with 'login_credentials-'
            if (strncmp(from.ptr, "<sip:notifier@qliqsoft.com>", from.slen) == 0) {
                pjsip_cid_hdr *h_cid = pjsip_msg_find_hdr(msg, PJSIP_H_CALL_ID, NULL);
                if (h_cid) {
                    if (strnstr(h_cid->id.ptr, "login_credentials-", h_cid->id.slen) == h_cid->id.ptr) {
                        [[QliqSip sharedQliqSip] specialCaseProcessLoginCredentialsChangedNotification:pjstrToNSString(&text_body)];
                    }
                }
            
                // If app is in background
                if ([AppDelegate applicationState] == UIApplicationStateBackground) {
                    // Content-Type: text/html makes no sense at all but that is what webserver sends
                    if (strncmp(mime_type.ptr, MIME_TEXT_PLAIN, mime_type.slen) == 0 ||
                        strncmp(mime_type.ptr, MIME_TEXT_HTML, mime_type.slen) == 0) {
                        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
                        NSStringEncoding dataEncoding = stringEncoding;
                        NSError *error=nil;
                        NSString *text = pjstrToNSString(&text_body);
                        NSData *jsonData = [text dataUsingEncoding:dataEncoding];
                        
                        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
                        NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE_MESSAGE];
                        // And we receive a change notification
                        
                        // Krishna 1/14/2017
                        // Do not send 480 for Bulk notifications
                        // Let all the change notification come through
                        // Only send 480 if it is individual CN
                        if ([message[MESSAGE_MESSAGE_COMMAND] isEqualToString:CHANGE_NOTIFICATION_MESSAGE_COMMAND_PATTERN]  &&
                            [message[MESSAGE_MESSAGE_TYPE] isEqualToString:CHANGE_NOTIFICATION_MESSAGE_TYPE_PATTERN]) {
                            // Then we respond with special code PJSIP_SC_TEMPORARILY_UNAVAILABLE (480)
                            pjsip_endpt_respond(pjsua_get_pjsip_endpt(), NULL, rdata, PJSIP_SC_TEMPORARILY_UNAVAILABLE, NULL,
                                                NULL, NULL, NULL);
                            ret = PJ_TRUE;
                        }
                    }
                }
            }
            
            [[QliqSip sharedQliqSip] increaseReceivedMessagesCount];
        }
    }
    DDLogVerbose(@"ENDOF: %s ", __func__);
    return ret;
}

pjsip_module mod_default_handler =
{
    NULL, NULL,				/* prev, next.		*/
    { "mod-default-handler", 19 },	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_APPLICATION,	/* Priority	        */
    NULL,				/* load()		*/
    NULL,				/* start()		*/
    NULL,				/* stop()		*/
    NULL,				/* unload()		*/
    default_mod_on_rx_request,		/* on_rx_request()	*/
    NULL,               /* on_rx_response()	*/
    NULL,				/* on_tx_request.	*/
    NULL,				/* on_tx_response()	*/
    NULL,				/* on_tsx_state()	*/
};

pjsip_module mod_encryption_handler =
{
    NULL, NULL,				/* prev, next.		*/
    { "mod-encryption-handler", 22 },	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_APPLICATION-1,	/* Priority	        */
    NULL,				/* load()		*/
    NULL,				/* start()		*/
    NULL,				/* stop()		*/
    NULL,				/* unload()		*/
    encryption_mod_on_rx_request,	/* on_rx_request()	*/
    NULL,				/* on_rx_response()	*/
    NULL,				/* on_tx_request.	*/
    NULL,				/* on_tx_response()	*/
    NULL,				/* on_tsx_state()	*/
};

pjsip_module mod_file_logger_handler =
{
    NULL, NULL,				/* prev, next.		*/
    { "mod-file-logger", 15 },	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_TRANSPORT_LAYER-1,	/* Priority	        */
    NULL,				/* load()		*/
    NULL,				/* start()		*/
    NULL,				/* stop()		*/
    NULL,				/* unload()		*/
    file_logger_mod_on_rx_request,	/* on_rx_request()	*/
    file_logger_mod_on_rx_response,				/* on_rx_response()	*/
    file_logger_mod_on_tx_request,				/* on_tx_request.	*/
    file_logger_mod_on_tx_response,				/* on_tx_response()	*/
    NULL,				/* on_tsx_state()	*/
};
#pragma mark -
#pragma mark Voice calls pjsip callbacks

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    @autoreleasepool {
        
        pjsua_call_info ci;
        
        PJ_UNUSED_ARG(acc_id);
        PJ_UNUSED_ARG(rdata);
        
        pjsua_call_get_info(call_id, &ci);
        
        DDLogSupport(@"*** Incoming Call received from %@", pjstrToNSString(&ci.remote_info));
        
        
        NSNumber *callId = [NSNumber numberWithInt:call_id];
        [[[QliqSip sharedQliqSip] voiceCallsController] performSelectorOnMainThread:@selector(incomingCall:) withObject:callId waitUntilDone:NO];
    }
}

/* Callback called by the library when call's state has changed */
static bool calling = FALSE;
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    @autoreleasepool {
        
        pjsua_call_info ci;
        
        PJ_UNUSED_ARG(e);
        
        
        pjsua_call_get_info(call_id, &ci);
        
        DDLogSupport(@"*** call state changed state: %d  status: %d %@", ci.state, ci.last_status, pjstrToNSString(&ci.last_status_text));
        CallStateChangeInfo *info = [[CallStateChangeInfo alloc] init];
        info.call_id = [NSNumber numberWithInt:call_id];
        info.state = [NSNumber numberWithInt:ci.state];
        info.lastReasonCode = [NSNumber numberWithInt:ci.last_status];
        [[[QliqSip instance] voiceCallsController] performSelectorOnMainThread:@selector(callStateChanged:)withObject:info waitUntilDone:NO];
        [info release];
    }
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    @autoreleasepool {
        
        pjsua_call_info ci;
        
        pjsua_call_get_info(call_id, &ci);
        
        DDLogVerbose(@"*** media state changed status: %d", ci.media_status);
        
        if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE)
        {
            // When media is active, connect call to sound device.
            pjsua_conf_connect(ci.conf_slot, 0);
            pjsua_conf_connect(0, ci.conf_slot);
            pjsua_conf_adjust_tx_level(0, 1.5);
            pjsua_conf_adjust_rx_level(0, 1.5);
            // Now set Echo cancellation...
            pjsua_set_ec (PJSUA_DEFAULT_EC_TAIL_LEN,0);
        }
        
        switch (ci.media_status)
        {
            case PJSUA_CALL_MEDIA_NONE:
            {
                DDLogSupport(@"Call media NONE");
            }break;
            case PJSUA_CALL_MEDIA_ACTIVE:
            {
                DDLogSupport(@"Call media ACIVE");
            }break;
            case PJSUA_CALL_MEDIA_LOCAL_HOLD:
            {
                DDLogSupport(@"Call media LOCAL HOLD");
            }break;
            case PJSUA_CALL_MEDIA_REMOTE_HOLD:
            {
                DDLogSupport(@"Call media REMOTE HOLD");
            }break;
            case PJSUA_CALL_MEDIA_ERROR:
            {
                DDLogSupport(@"*** Call media ERROR");
                pj_str_t reason = pj_str("ICE negotiation failed");
                pjsua_call_hangup(call_id, 500, &reason, NULL);
            }break;
            default:
                break;
        }
    }
}

/*
 * Print log of call states. Since call states may be too long for logger,
 * printing it is a bit tricky, it should be printed part by part as long
 * as the logger can accept.
 */
static void log_call_dump(int call_id)
{
#define SOME_BUF_SIZE        (1024 * 10)
	static char some_buf[SOME_BUF_SIZE];
    
    unsigned call_dump_len;
    unsigned part_len;
    unsigned part_idx;
    unsigned log_decor;
    
    pjsua_call_dump(call_id, PJ_FALSE, some_buf,
                    sizeof(some_buf), "  ");
    //call_dump_len = strlen(some_buf);
    DDLogVerbose(@"*** Call Dump : %s", some_buf);
    
}

#pragma mark -

static NSString *pjstrToNSString(const pj_str_t *pjstr)
{
    char *copy = (char *)malloc(pjstr->slen);
    strncpy(copy, pjstr->ptr, pjstr->slen);
    
    NSString *string = [[[NSString alloc] initWithBytes:copy
                                                 length:pjstr->slen
                                               encoding:NSASCIIStringEncoding] autorelease];
    free(copy);
    return string;
}



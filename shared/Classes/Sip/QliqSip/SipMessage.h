//
//  SipMessage.h
//  qliq
//
//  Created by Aleksey Garbarev on 05.08.13.
//
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"

typedef void(^MessageStatusChangedBlock)(id context, int status);

// Used to resend a message when the other party returns encryption error
@interface SipMessage : NSObject

@property (nonatomic) int seq;
@property (nonatomic, strong) NSString *toQliqId;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *plainText;
@property (nonatomic, strong) NSString *publicKey;
@property (nonatomic, strong) id context;
@property (nonatomic, readwrite) BOOL offlineMode;
@property (nonatomic, readwrite) BOOL multiparty;
@property (nonatomic, readwrite) BOOL groupMessage;
@property (nonatomic, readwrite) BOOL pushNotify;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *callId;
@property (nonatomic) ChatMessagePriority priority;
@property (nonatomic, strong) NSString *alsoNotify;
@property (nonatomic, readwrite) NSTimeInterval createdAt;
@property (nonatomic, strong) NSString *conversationUuid;
@property (nonatomic, readwrite) BOOL isBroadcast;
@property (nonatomic, strong) NSString *pagerInfo;
@property (nonatomic, strong) MessageStatusChangedBlock statusChangedBlock;
@property (nonatomic, strong) NSMutableDictionary *extraHeaders;

@end
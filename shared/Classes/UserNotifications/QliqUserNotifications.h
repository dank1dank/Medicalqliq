//
//  UserNotifications.h
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UserNotifications/UserNotifications.h>

#import "TimerNotifier.h"

#define kKeyUserQliqId @"userQliqId"
#define kKeyMessageID  @"messageID"
#define kKeyConversationID  @"conversationID"
#define kKeyLocalNotificationID  @"notificationId"
#define kKeyMessage @"message"

#define OpenDelayedPushNotification @"openDelayedPushNotification"
#define StopNotifyingAboutPushMessage @"stopNotifyingAboutPushMessage"

#define OpenConversationAfterLoginNotification @"openConversationAfterLoginNotification"

#define kValueDelayForOpeningPushInSec  10.0
#define kValueDelayForLogin  60.0

@class ChatMessage;
@class Call;
@class Ringtone;

@interface QliqUserNotifications : NSObject

@property (nonatomic, assign) BOOL canVibrate;
@property (nonatomic, assign) BOOL isConversationOpeningInProgress;
@property (nonatomic, assign, readonly) NSTimeInterval delayStartPoint;

@property (nonatomic, readonly, strong) NSOperationQueue *qliqNotificationsOperationQueue;

+ (QliqUserNotifications *)getInstance;

- (void)handleLocalNotification:(id)localNotification;
- (void)showConversationFor:(id)localNotification inNavigationController:(UINavigationController *)nav;

- (void)notifyUserAppDidNotProcessRemoteNotificaiton:(NSDictionary *)aps;
- (void)notifyUserAboutLogoutWithReason:(NSString *)reason;
- (NSInteger)parseBadgeNumberFromPayload:(NSDictionary *)aps;

- (void)notifyIncomingChatMessage:(ChatMessage *)message forCareChannel:(BOOL)isCareChannel withoutSound:(BOOL)noSound;
- (void)notifyAckGotForMessage:(ChatMessage *)message;
- (void)notifyNewAdmition;
- (void)notifyIncomingCall:(Call *)call;

- (void)cancelChimeNotifications:(BOOL)force;

- (void)cancelChimeNotificationsForMessageWithID:(NSUInteger)messageID;
- (void)rescheduleChimeNotificationsForMessage:(ChatMessage *)message;

- (BOOL)isLocalNotificationChimed:(NSString *)notificationId;

- (void)refreshAppBadge:(NSInteger)badge;

- (void)clearLaunchedPushData;
- (void)addRemoteNotificationToChimed:(NSString *)notificationId callId:(NSString *)callId;
- (BOOL)isRemoteNotificationChimed:(NSString *)notificationId callId:(NSString *)callId;
- (BOOL)isRemoteNotificationChimedCallId:(NSString *)callId;
- (BOOL)openConversationForRemoteNotificationWith:(UINavigationController *)nav callId:(NSString *)callId;

@end

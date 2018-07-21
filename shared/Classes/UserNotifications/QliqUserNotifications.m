//
//  UserNotifications.m
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqUserNotifications.h"
#import "ChatMessage.h"
#import "Conversation.h"
#import "Call.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "QliqUser.h"
#import "ConversationDBService.h"
#import "ChatMessageService.h"
#import "QliqUserDBService.h"
#import "ConversationViewController.h"
#import "DBHelperConversation.h"
#import "SoundSettings.h"
#import "QliqNotificationView.h"
#import "MainViewController.h"
#import "QliqSip.h"
#import "UIDevice-Hardware.h"

#define NotificationIdString4(fmt, qliqId, conversationId, messageId, notificationNumber) [NSString stringWithFormat:fmt, qliqId, conversationId, messageId, notificationNumber]

#define kKeyChimedLocalNotifications  @"chimedLocalNotifications"
#define kKeyChimedRemoteNotifications @"chimedRemoteNotifications"

#define kRescheduleChimeNotifications @"RescheduleChimeNotifications"

@interface QliqUserNotifications()

@property (nonatomic, assign) BOOL chimeScheduled;

@property (nonatomic, readonly, unsafe_unretained) SoundSettings *soundSettings;

@property (nonatomic, strong) NSMutableSet *chimedLocalNotificationsSet;
@property (nonatomic, strong) NSMutableSet *chimedRemoteNotificationsSet;

@property (nonatomic, copy) NSString *launchedPushCallId;
@property (nonatomic, copy) NSString *openAfterLoginPushCallId;
@property (nonatomic, copy) NSString *openAfterLoginLocalNotification;

@property (nonatomic, strong) NSMutableArray *showedNotifications;

@property (nonatomic, assign) NSTimeInterval delayStartPoint;

@property (nonatomic, readwrite, strong) NSOperationQueue *qliqNotificationsOperationQueue;

@property (nonatomic, strong) NSMutableArray *failedMessages;

@end


@implementation QliqUserNotifications

@synthesize canVibrate;

#pragma mark - LifeCycle

+ (QliqUserNotifications *)getInstance {
    static QliqUserNotifications *instance = nil;
    @synchronized(self) {
        if (!instance) {
            instance = [[QliqUserNotifications alloc] init];
        }
    }
    return instance;
}

- (id)init {
    
    self = [super init];
    if(self)
    {
        self.showedNotifications = [[NSMutableArray alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChatBadgeValueChanged:) name:ChatBadgeValueNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChatBadgeValueChanged:) name:@"ChatBadgeValueZero" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rescheduleChimeNotificationsWithPresenceChange:) name:kRescheduleChimeNotifications object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatMessageFailedStatus:) name:@"SIPMessageSendingFailedNotification" object:nil];
        
        self.chimedRemoteNotificationsSet = [self getChimedRemoteNotificationsFromUserDefaults];
        self.isConversationOpeningInProgress = NO;
        self.delayStartPoint = 0;
        
        //        if (!is_ios_greater_or_equal_10()) {
        self.chimedLocalNotificationsSet = [self getChimedLocalNotificationsFromUserDefaults];
        //        }
        
        self.qliqNotificationsOperationQueue = [[NSOperationQueue alloc] init];
        self.qliqNotificationsOperationQueue.name = @"com.Qliq.qliqNotificationsQueue";
        self.qliqNotificationsOperationQueue.maxConcurrentOperationCount = 1;
        
        self.chimeScheduled = NO;
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.qliqNotificationsOperationQueue cancelAllOperations];
    [self.qliqNotificationsOperationQueue waitUntilAllOperationsAreFinished];
    self.qliqNotificationsOperationQueue = nil;
    
    [self.chimedLocalNotificationsSet removeAllObjects];
    self.chimedLocalNotificationsSet = nil;
}


#pragma mark - Notifications Scheduling Management

-(void) showLocalUserNotificationWithBody:(NSString *)body
                                  message:(ChatMessage *)message
                                 ringtone:(Ringtone *)ringtone
                                    badge:(NSInteger)badge
                                andAction:(NSString *)action
{
    DDLogSupport(@"showLocalUserNotificationWithBody: %@, "
                 "soundName: %@, "
                 "badge: %ld, "
                 "failedToDecryptMessages: %ld, "
                 "action: %@ "
                 "for Conversation: %lu "
                 "message: %lu",
                 body,
                 [ringtone filename],
                 (long)badge,
                 (long)appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt,
                 action,
                 (long)message.conversationId,
                 (long)message.messageId);
    
    NSString *notificationId = NotificationIdString4(@"%@-%lu-%lu-%d", [UserSessionService currentUserSession].user.qliqId, (long)message.messageId, (long)message.conversationId, 0);
    
    NSDictionary *userInfo = @{
                               LocalNotificationType : LocalNotificationTypeChime,
                               LocalNotificationAlertBody: body,
                               LocalNotificationRingtoneType: ringtone.type ? ringtone.type : @"",
                               LocalNotificationRingtonePriority: ringtone.priority ? ringtone.priority : @"",
                               LocalNotificationInterval : [NSNumber numberWithInteger:0],
                               kKeyUserQliqId: [UserSessionService currentUserSession].user.qliqId,
                               kKeyMessageID: [NSNumber numberWithUnsignedInteger:message.messageId],
                               kKeyConversationID: [NSNumber numberWithUnsignedInteger:message.conversationId],
                               kKeyLocalNotificationID: notificationId
                               };
    NSInteger appIconBadgeValue = badge + appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt;
    //    if (is_ios_greater_or_equal_10())
    //    {
    UILocalNotification * alert = [[UILocalNotification alloc] init];
    if (alert)
    {
        dispatch_async_main(^{
            alert.repeatInterval = 0;
            alert.alertBody = body;
            alert.alertAction = action;
            alert.hasAction = YES;
            alert.soundName = [ringtone filename];
            [UIApplication sharedApplication].applicationIconBadgeNumber  = appIconBadgeValue;
            alert.userInfo = userInfo;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
        });

        DDLogSupport(@"<-- Refresh App Badge with value: %ld, "
                     "unreadMsgs: %ld, "
                     "failedToDecryptMsgs: %ld -->",
                     (long)appIconBadgeValue,
                     (long)badge,
                     (long)appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt);
    }
    //    }
    //    else
    //    {
    //        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    //        content.title = @"";
    //        content.body = body;
    //        content.sound = [UNNotificationSound soundNamed:[ringtone filename]];
    //        content.badge = [NSNumber numberWithInteger:badge];
    //        content.userInfo = userInfo;
    //
    //        //
    //        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.15
    //                                                                                                        repeats:NO];
    //        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:notificationId
    //                                                                              content:content
    //                                                                              trigger:trigger];
    //
    //        // Schedule the notification.
    //        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    //        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    //            if (error) {
    //                DDLogError(@"%@", [error localizedDescription]);
    //            }
    //        }];
    //    }
}

/* sheduling UILocalNotifications with special inverval in minutes*/

- (void)scheduleChimeNotificationWithRingtone:(Ringtone *)ringtone
                                    messageID:(NSNumber *)messageID
                     conversationIDForMessage:(NSNumber *)conversationID
                               chimesInterval:(NSUInteger)minutesBetweenChimes
                              messagePriority:(NSUInteger)priority
                                    alertBody:(NSString *)alertBodyStr
{
    if (minutesBetweenChimes < 1)
    {
        DDLogSupport(@"scheduleChimeNotificationWithRingtone: Ignoring because minutesBetweenChimes: %lu for Conversation: %@ message: %@", (unsigned long)minutesBetweenChimes, conversationID, messageID);
        return;
    }
    /* if ringtone is OFF*/
    if (![ringtone isVibrateEnabled] && ![ringtone isSoundEnabled])
    {
        DDLogSupport(@"scheduleChimeNotification witout sound, because isVibrateEnabled: NO isSoundEnabled: NO for Conversation: %ld message: %ld", (long)conversationID, (long)messageID);
    }
    /* Create new chime notification and shedule */
    NSCalendarUnit notificationsIntervalUnit;
    NSInteger minutesInIntervalUnit = 1;
    if (minutesBetweenChimes == 1)
    {
        notificationsIntervalUnit = NSCalendarUnitMinute;
        minutesInIntervalUnit = 60;
    }
    else if (minutesBetweenChimes > 1 && minutesBetweenChimes < 60)
    {
        notificationsIntervalUnit = NSCalendarUnitHour;
        minutesInIntervalUnit = 60;
    }
    else
    {
        notificationsIntervalUnit = NSCalendarUnitDay;
        minutesInIntervalUnit = 60 * 24;
    }
    NSUInteger chimesToShedule = minutesInIntervalUnit / (int)minutesBetweenChimes;
    DDLogSupport(@"scheduleChimeNotificationWithRingtone: interval: %lu count: %d for Conversation: %lu message: %lu", (unsigned long)minutesBetweenChimes, (unsigned int)chimesToShedule, (long)[conversationID unsignedIntegerValue], (long)[messageID unsignedIntegerValue]);
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
    for (int i = 0; i < chimesToShedule; i++)
    {
        // Moved chimeAlert here as per suggestion in this forum post
        // https://forums.developer.apple.com/thread/9226
        NSInteger unreadMessageCount = [ChatMessage unreadMessagesCount];
        NSString *notificationId = NotificationIdString4(@"%@-%lu-%lu-%d", [UserSessionService currentUserSession].user.qliqId, (long)[messageID unsignedIntegerValue], (long)[conversationID unsignedIntegerValue], i + 1);
        
        NSDictionary *userInfo = @{LocalNotificationType : LocalNotificationTypeScheduledChime,
                                   LocalNotificationRingtoneType : ringtone.type,
                                   LocalNotificationRingtonePriority : ringtone.priority,
                                   LocalNotificationInterval : [NSNumber numberWithInteger:minutesBetweenChimes],
                                   LocalNotificationMessagePriority : [NSNumber numberWithInteger: priority],
                                   LocalNotificationAlertBody : alertBodyStr,
                                   kKeyUserQliqId: qliqId,
                                   kKeyMessageID: messageID ? : [NSNumber numberWithInt:0],
                                   kKeyConversationID: conversationID ? : [NSNumber numberWithInt:0],
                                   kKeyLocalNotificationID: notificationId
                                   };
        
        NSTimeInterval scheduleTime =  (i + 1) * minutesBetweenChimes * 60;
        /*
         Test schedule time
         */
        //        NSTimeInterval scheduleTime =  (i + 1) * 0.2 * 60;
        
        //        if (!is_ios_greater_or_equal_10())
        //        {
        UILocalNotification *chimeAlert = [[UILocalNotification alloc] init];
        if (chimeAlert && unreadMessageCount > 0)
        {
            /* We are sheduling chime alert after one minutesBetweenChimes to avoid playing 2 sounds at same time */
            chimeAlert.fireDate = [NSDate dateWithTimeIntervalSinceNow:scheduleTime];
            chimeAlert.timeZone = [NSTimeZone defaultTimeZone];
            chimeAlert.soundName = [ringtone filename];
            chimeAlert.repeatInterval = 0;
            chimeAlert.alertBody = alertBodyStr;
            chimeAlert.alertAction = QliqLocalizedString(@"2145-TitleView");
            chimeAlert.hasAction = YES;
            chimeAlert.userInfo = userInfo;
            dispatch_async_main(^{
                [[UIApplication sharedApplication] scheduleLocalNotification:chimeAlert];
            });
        }
        //        }
        //        else
        //        {
        //            UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        //            content.title = @"";
        //            content.body = alertBodyStr;
        //            content.sound = [UNNotificationSound soundNamed:[ringtone filename]];
        //            content.userInfo = userInfo;
        //
        //            UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:scheduleTime
        //                                                                                                            repeats:NO];
        //            UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:notificationId
        //                                                                                  content:content
        //                                                                                  trigger:trigger];
        //
        //            // Schedule the notification.
        //            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        //            [center addNotificationRequest:request  withCompletionHandler:^(NSError * _Nullable error) {
        //                if (error) {
        //                    DDLogError(@"%@", [error localizedDescription]);
        //                }
        //            }];
        //        }
    }
    self.chimeScheduled = YES;
    DDLogSupport(@"scheduleChimeNotificationWithRingtone and forConversation: %lu message: %lu", (long)[conversationID unsignedIntegerValue], (long)[messageID unsignedIntegerValue]);
}

- (void)scheduleFailedChimeNotificationWithRingtone:(Ringtone *)ringtone
                                    messageID:(NSNumber *)messageID
                     conversationIDForMessage:(NSNumber *)conversationID
                               chimesInterval:(NSUInteger)minutesBetweenChimes
                              messagePriority:(NSUInteger)priority
                                    alertBody:(NSString *)alertBodyStr
{
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
     NSString *notificationId = NotificationIdString4(@"%@-%lu-%lu-%d", [UserSessionService currentUserSession].user.qliqId, (long)[messageID unsignedIntegerValue], (long)[conversationID unsignedIntegerValue], 1);
    
    NSDictionary *userInfo = @{LocalNotificationType : LocalNotificationTypeScheduledChime,
                               LocalNotificationRingtoneType : ringtone.type,
                               LocalNotificationRingtonePriority : ringtone.priority,
                               LocalNotificationInterval : [NSNumber numberWithInteger:minutesBetweenChimes],
                               LocalNotificationMessagePriority : [NSNumber numberWithInteger: priority],
                               LocalNotificationAlertBody : alertBodyStr,
                               kKeyUserQliqId: qliqId,
                               kKeyMessageID: messageID ? : [NSNumber numberWithInt:0],
                               kKeyConversationID: conversationID ? : [NSNumber numberWithInt:0],
                               kKeyLocalNotificationID: notificationId
                               };
    
    UILocalNotification *chimeAlert = [[UILocalNotification alloc] init];
    if (chimeAlert) {
        chimeAlert.timeZone = [NSTimeZone defaultTimeZone];
        chimeAlert.soundName = [ringtone filename];
        chimeAlert.repeatInterval = 0;
        chimeAlert.alertBody = alertBodyStr;
        chimeAlert.alertAction = QliqLocalizedString(@"2145-TitleView");
        chimeAlert.hasAction = YES;
        chimeAlert.userInfo = userInfo;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:chimeAlert];
    }
}

- (void)rescheduleChimeNotificationsForMessage:(ChatMessage *)message {
    __weak __block typeof(self) welf = self;
    [self.qliqNotificationsOperationQueue addOperationWithBlock:^{
        DDLogSupport(@"rescheduleChimeNotifications for Conversation: %lu message: %lu", (long)message.conversationId, (long)message.messageId);
        SoundSettings * soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
        NotificationsSettings *notificationSettings = [soundSettings notificationsSettingsForPriority:[message priorityString]];
        Ringtone *ringtone = [notificationSettings ringtoneForType:NotificationTypeIncoming];
        
        QliqUser *user = nil;
        NSString *legUserName = nil;
        NSString *alertBodyStr = nil;
        
        if (message.deliveredRecipientCount < 0) {
            user = [[QliqUserDBService sharedService] getUserWithId:message.fromQliqId];
            legUserName = [user displayName];
            alertBodyStr = QliqFormatLocalizedString1(@"2381-TitleMessageReceivedFrom{Sender}", legUserName);
        }
        else {
            user = [[QliqUserDBService sharedService] getUserWithId:message.toQliqId];
            legUserName = [user displayName];
            alertBodyStr = QliqLocalizedString(@"2432-TitleSendingMessageFailed");
            alertBodyStr = [NSString stringWithFormat:@"%@ to %@", alertBodyStr, legUserName];
        }
        
        if (!user)
        {
            DDLogError(@"reschedule Cannot find qliq user for qliq id: %@", message.fromQliqId);
            return;
        }
        //        NSString *legUserName = [user displayName];
        
        if ([legUserName length] <= 0)
        {
            DDLogError(@"reschedule Cannot get user's display name for qliq id: %@", message.fromQliqId);
            return;
        }
        
        //        NSString *alertBodyStr = QliqFormatLocalizedString1(@"2381-TitleMessageReceivedFrom{Sender}", legUserName);
        BOOL shouldScheduled = [welf cancelScheduledNotificationsFor:message.conversationId withRingtone:ringtone];
        
        if (shouldScheduled && message.deliveredRecipientCount > 0) {
            [welf scheduleChimeNotificationWithRingtone:ringtone
                                              messageID:[NSNumber numberWithUnsignedInteger:message.messageId]
                               conversationIDForMessage:[NSNumber numberWithUnsignedInteger:message.conversationId]
                                         chimesInterval:notificationSettings.reminderChimeInterval
                                        messagePriority:[message priority]
                                              alertBody:alertBodyStr];
        }
        else {
            if (appDelegate.appInBackground) {
                [welf scheduleFailedChimeNotificationWithRingtone:ringtone
                                                        messageID:[NSNumber numberWithUnsignedInteger:message.messageId]
                                         conversationIDForMessage:[NSNumber numberWithUnsignedInteger:message.conversationId]
                                                   chimesInterval:0.45
                                                  messagePriority:[message priority]
                                                        alertBody:alertBodyStr];
            }
            else {
                [self showBannerForSendingFailedMessage:message];
                [ringtone play];
            }
        }
    }];
}

// 5/21/2018
- (void)rescheduleChimeNotificationsWithPresenceChange:(NSNotification *)notification {
    NSString *prevPresenceType = [UserSessionService currentUserSession].userSettings.presenceSettings.prevPresenceType;
    NSString *currentPresenceType = [UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType;
    NSArray *scheduledNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    // 5/21/2018 Krishna Kurapati
    // Bad Code.
    // THis cancels chimes even if the presence status is online and previous presence status is online.
    // scheduledForPrecence will be nil when the App is started in the BG. And it always
    // Cancels the CHIMEs Eventhough it is not suppose to.
    //
    
    // Only Cancel CHIMEs if the Presence Type is Not Onlne
    // This code is bad too
    if (![prevPresenceType isEqualToString:currentPresenceType] && ![currentPresenceType isEqualToString: PresenceTypeOnline])
    {
        NSInteger snapBadgeCount = [UIApplication sharedApplication].applicationIconBadgeNumber;
        __weak __block typeof(self) welf = self;
        if (scheduledNotifications.count > 0)
        {
            [self.qliqNotificationsOperationQueue addOperationWithBlock:^{
                DDLogSupport(@"rescheduleChimeNotifications for Presence status: prev=%@ curr=%@", prevPresenceType, currentPresenceType);
                [welf cancelChimeNotifications:YES];
                // Refresh the Badge count.
                [[QliqUserNotifications getInstance] refreshAppBadge:snapBadgeCount];
            }];
        }
    }
}

- (void)rescheduleChimeNotificationsForFailedMessages:(NSMutableArray *)failedMessages {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        for (int index = 0; index < self.failedMessages.count; index++ ) {
            NSInteger messageID = [self.failedMessages[index] integerValue];
            ChatMessage *existingMsg = [ChatMessageService getMessage:messageID];
            
            if (existingMsg.deliveredRecipientCount == 0) {
                [self rescheduleChimeNotificationsForMessage:existingMsg];
            }
        }
        [self.failedMessages removeAllObjects];
    });
}

- (void)chatMessageFailedStatus:(NSNotification *)notification {
    
    if (self.failedMessages == nil) {
        self.failedMessages = [[NSMutableArray alloc] init];
    }
    
    ChatMessage *message = nil;
    
    if (notification != nil) {
        
        id item = [[notification userInfo] objectForKey:@"context"];
        
        if ([item isKindOfClass:[ChatMessage class]]) {
            
            message = ((ChatMessage *)item);
        }
    }
    
    if (message) {
        
        if (message.messageId) {
            
            if (![self.failedMessages containsObject:[NSNumber numberWithInteger:message.messageId]]) {
                [self.failedMessages addObject:[NSNumber numberWithInteger:message.messageId]];
                [self showBannerForSendingFailedMessage:message];
                [self rescheduleChimeNotificationsForFailedMessages:self.failedMessages];
            }
        }
    }
    else
    {
        DDLogSupport(@"Nil message received with sratus notification");
    }
}

- (void)showBannerForSendingFailedMessage:(ChatMessage *)message {
    
    QliqUserDBService *userService = [[QliqUserDBService alloc] init];
    QliqUser *user = [userService getUserWithId:message.toQliqId];
    
    NSString *recipientName = user.displayName;
    if (!recipientName)
    {
        QliqGroupDBService *groupService = [[QliqGroupDBService alloc] init];
        QliqGroup *group = [groupService getGroupWithId:message.toQliqId];
        if (group)
            recipientName = [group name];
    }

    dispatch_async_main(^{
    QliqNotificationView *banner = [[QliqNotificationView alloc] init];
    banner.converationId = message.conversationId;
    banner.titleLabel.text = QliqLocalizedString(@"2432-TitleSendingMessageFailed");
        isIPhoneX {
            banner.titleLabel.font = [UIFont systemFontOfSize:19.0];
            banner.descriptionLabel.font = [UIFont systemFontOfSize:17.0];
        }
    banner.descriptionLabel.text = [NSString stringWithFormat:@"To: %@", recipientName];
    banner.avatarImageView.layer.cornerRadius = banner.avatarImageView.bounds.size.height / 2;
    banner.avatarImageView.clipsToBounds = YES;
    banner.avatarImageView.image = (user.avatar ? user.avatar : [[UIImage alloc] initWithContentsOfFile:user.avatarFilePath]);
        [banner presentSendingMessageFailed];
    });
}

#pragma mark - Notifications Canceling

- (void)cancelChimeNotificationsForMessageWithID:(NSUInteger)messageID {
    __weak __block typeof(self) welf = self;
    void (^cancelChimeNotificationsForMessageWithIDBlock)(void) = ^(void){
        dispatch_async_main(^{
            DDLogSupport(@"cancelChimeNotifications for message with ID %lu", (long)messageID);
            ChatMessage * message = [ChatMessageService getMessage:messageID];
            if ([message.callId isEqualToString:welf.launchedPushCallId]) {
                @synchronized (welf) {
                    welf.launchedPushCallId = nil;
                }
            }
            //        if (!is_ios_greater_or_equal_10())
            //        {
            BOOL oneFinded = NO;
            //Cancel scheduled Notifications for this message
            UIApplication* app = [UIApplication sharedApplication];
            NSMutableArray * allNotifications = [NSMutableArray arrayWithArray:[app scheduledLocalNotifications]];
            for (UILocalNotification * localNotification in allNotifications)
            {
                NSUInteger notificatioMessageID = [(NSNumber *)[localNotification.userInfo objectForKey:kKeyMessageID] unsignedIntegerValue];
                if (notificatioMessageID == messageID)
                {
                    [app cancelLocalNotification:localNotification];
                    oneFinded = YES;
                }
            }
            if (oneFinded)
            {
                //Save scheduled notifications for other messages
                allNotifications = nil;
                allNotifications = [NSMutableArray arrayWithArray:[app scheduledLocalNotifications]];
                //Cancel all Notifications
                dispatch_async_main(^{
                    [app cancelAllLocalNotifications];
                });
                //Cleare only Local Notifications
                [welf clearChimedLocalNotifications];
                
                //Reschedule Notifications for other messages
                for (UILocalNotification * localNotification in allNotifications)
                {
                    if (localNotification.fireDate.timeIntervalSince1970 > [[NSDate date] timeIntervalSince1970])
                        [app scheduleLocalNotification:localNotification];
                }
                
                //Update badge number
                NSInteger ureadMessagesCount = [ChatMessage unreadMessagesCount];
                [welf refreshAppBadge:ureadMessagesCount];
            }
            //        }
            //        else
            //        {
            //            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            //
            //            NSMutableArray *identifiersToRemove = [NSMutableArray new];
            //            [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
            //                for (UNNotificationRequest *request in requests) {
            //                    NSUInteger scheduledNotificatioMessageID = [(NSNumber *)[request.content.userInfo objectForKey:kKeyMessageID] unsignedIntegerValue];
            //                    if (scheduledNotificatioMessageID == messageID){
            //                        [identifiersToRemove addObject:request.identifier];
            //                    }
            //                }
            //            }];
            //            [center removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
            //
            //            [identifiersToRemove removeAllObjects];
            //
            //            [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
            //                for (UNNotification *notification in notifications) {
            //                    NSUInteger deliveredNotificatioMessageID = [(NSNumber *)[notification.request.content.userInfo objectForKey:kKeyMessageID] unsignedIntegerValue];
            //                    if (deliveredNotificatioMessageID == messageID){
            //                        [identifiersToRemove addObject:notification.request.identifier];
            //                    }
            //                }
            //            }];
            //
            //            [center removeDeliveredNotificationsWithIdentifiers:identifiersToRemove];
            //
            //            [self removeRemoteNotificationFromChimedWithCallId:message.callId];
            //
            //            //Update badge number
            //            NSInteger ureadMessagesCount = [ChatMessage unreadMessagesCount];
            //            [self refreshAppBadge:ureadMessagesCount];
            //        }
        });
    };
    
    if ([NSOperationQueue currentQueue] != self.qliqNotificationsOperationQueue)
        [self.qliqNotificationsOperationQueue addOperationWithBlock:cancelChimeNotificationsForMessageWithIDBlock];
    else
        cancelChimeNotificationsForMessageWithIDBlock();
}

- (BOOL)cancelScheduledNotificationsFor:(NSUInteger)conversationID withRingtone:(Ringtone *)ringtone{
    DDLogSupport(@"Cancel Scheduled Notifications For conversationID: %lu - %@ ", (long)conversationID, [ringtone.priority isEqualToString:NotificationPriorityUrgent] ? @"ALL" : @"ALL EXCEPT Urgent");
    BOOL urgentNotificaitonWasScheduled = NO;
    //    if (!is_ios_greater_or_equal_10())
    //    {
    BOOL oneFinded = NO;
    //Cancel scheduled Notifications for this message
    UIApplication* app = [UIApplication sharedApplication];
    
    __block NSMutableArray * allNotifications;
    dispatch_sync_main(^{
        allNotifications = [NSMutableArray arrayWithArray:[app scheduledLocalNotifications]];
    });
//    NSMutableArray *allNotifications = [NSMutableArray arrayWithArray:[app scheduledLocalNotifications]];
    for (UILocalNotification * scheduledNotification in allNotifications)
    {
        NSUInteger scheduledNotificatioConversationID = [(NSNumber *)[scheduledNotification.userInfo objectForKey:kKeyConversationID] unsignedIntegerValue];
        if (scheduledNotificatioConversationID == conversationID)
        {
            NSString *scheduledNotificationPriotity = scheduledNotification.userInfo[LocalNotificationRingtonePriority];
            if (![scheduledNotificationPriotity isEqualToString:NotificationPriorityUrgent] || [ringtone.priority isEqualToString:NotificationPriorityUrgent])
            {
                dispatch_async_main(^{
                    [app cancelLocalNotification:scheduledNotification];
                });
                oneFinded = YES;
            }
            else
                urgentNotificaitonWasScheduled = YES;
        }
    }
    
    if ([ringtone.priority isEqualToString:NotificationPriorityUrgent])
        urgentNotificaitonWasScheduled = NO;
    
    if (oneFinded)
    {
        //Save scheduled notifications for other messages
        allNotifications = nil;
        dispatch_sync_main(^{
            allNotifications = [NSMutableArray arrayWithArray:[app scheduledLocalNotifications]];
        });
        
        //Cancel all Notifications
        dispatch_async_main(^{
            [app cancelAllLocalNotifications];
        });
        
        //Cleare only Local Notifications
        [self clearChimedLocalNotifications];
        
        //Reschedule Notifications for other messages
        for (UILocalNotification * localNotification in allNotifications) {
            if (localNotification.fireDate.timeIntervalSince1970 > [[NSDate date] timeIntervalSince1970])
                [app scheduleLocalNotification:localNotification];
        }
        
        //Update badge number
        NSInteger ureadMessagesCount = [ChatMessage unreadMessagesCount];
        [self refreshAppBadge:ureadMessagesCount];
    }
    //    }
    //    else
    //    {
    //        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //
    //        NSMutableArray *identifiersToRemove = [NSMutableArray new];
    //        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
    //            for (UNNotificationRequest *request in requests) {
    //                NSUInteger scheduledNotificatioConversationID = [(NSNumber *)[request.content.userInfo objectForKey:kKeyConversationID] unsignedIntegerValue];
    //                if (scheduledNotificatioConversationID == conversationID){
    //                    NSString *scheduledNotificationPriotity = request.content.userInfo[LocalNotificationRingtonePriority];
    //                    if (![scheduledNotificationPriotity isEqualToString:NotificationPriorityUrgent] || [ringtone.priority isEqualToString:NotificationPriorityUrgent])
    //                        [identifiersToRemove addObject:request.identifier];
    //                    else
    //                        urgentNotificaitonWasScheduled = YES;
    //                }
    //            }
    //        }];
    //        if ([ringtone.priority isEqualToString:NotificationPriorityUrgent])
    //              urgentNotificaitonWasScheduled = NO;
    //
    //        [center removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
    //
    //        [identifiersToRemove removeAllObjects];
    //
    //        [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
    //            for (UNNotification *notification in notifications) {
    //                NSUInteger deliveredNotificatioConversationID = [(NSNumber *)[notification.request.content.userInfo objectForKey:kKeyConversationID] unsignedIntegerValue];
    //                if (deliveredNotificatioConversationID == conversationID){
    //                    [identifiersToRemove addObject:notification.request.identifier];
    //                }
    //            }
    //        }];
    //        [center removeDeliveredNotificationsWithIdentifiers:identifiersToRemove];
    //
    //        //Update badge number
    //        NSInteger ureadMessagesCount = [ChatMessage unreadMessagesCount];
    //        [welf refreshAppBadge:ureadMessagesCount];
    //    }
    
    if (urgentNotificaitonWasScheduled)
        DDLogSupport(@"Notifications for New message will not be scheduled, because Urgent notifications were already scheduled for conversation: %lu", (long)conversationID);
    
    return !urgentNotificaitonWasScheduled;
}

- (void)cancelChimeNotifications:(BOOL)force {
    
    __weak __block typeof(self) welf = self;
    void (^cancelChimeNotificationsBlock)(void) = ^(void){
        
        if (welf.chimeScheduled == NO && force == NO)
            return;
        
        DDLogSupport(@"cancel All Chime Notifications. chimeScheduled = %d, force = %d", self.chimeScheduled, force);
        
        //        if (is_ios_greater_or_equal_10())
        //        {
        //            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //            [center removeAllPendingNotificationRequests];
        //            [center removeAllDeliveredNotifications];
        //            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        //        }
        //        else
        {
            dispatch_async_main(^{
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            });
        }
        
        appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt = 0;
        
        DDLogSupport(@"<-- Refresh App Badge with value: 0, "
                     "unreadMsgs: 0, "
                     "failedToDecryptMsgs: 0 -->");
        
        [welf clearChimedNotifications];
        appDelegate.unProcessedLocalNotifications = nil;
        welf.chimeScheduled = NO;
    };
    
    if ([NSOperationQueue currentQueue] != self.qliqNotificationsOperationQueue)
        [self.qliqNotificationsOperationQueue addOperationWithBlock:cancelChimeNotificationsBlock];
    else
        cancelChimeNotificationsBlock();
}

#pragma mark - Notifications Handling

- (void)handleLocalNotification:(id)localNotification {
    __weak __block typeof(self) welf = self;
    [self.qliqNotificationsOperationQueue addOperationWithBlock:^{
        [welf handle:localNotification];
    }];
}

- (void)showConversationFor:(id)localNotification inNavigationController:(UINavigationController *)nav {
    __weak __block typeof(self) welf = self;
    [self.qliqNotificationsOperationQueue addOperationWithBlock:^{
        [welf show:localNotification inNavController:nav];
    }];
}


- (void)show:(id)tappedNotification inNavController:(UINavigationController *)nav {
    if (tappedNotification)
    {
        //If chime notification
        if (nav)
        {
            if ([appDelegate isMainViewControllerRoot])
            {
                [self openConversationForLocalNotification:tappedNotification withNavController:nav];
            }
            else
            {
                DDLogSupport(@"Trying to show Conversation, but MainViewController is not root. Looks like user is logged out. Skip showing.");
                
                self.delayStartPoint = [[NSDate date] timeIntervalSince1970];
                self.openAfterLoginLocalNotification = tappedNotification;
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(openConversationAfterLogin:)
                                                             name:OpenConversationAfterLoginNotification
                                                           object:nil];
            }
        }
    }
}

- (void)handle:(id)receivedNotification {
    
    DDLogSupport(@"handleLocalNotification: %@",receivedNotification);
    
    if (receivedNotification)
    {
        //If chime notification
        
        // 8/7/2014 - Krishna
        // Cancel all chimes if there are no
        // Unread messages.
        //
        if ([ChatMessage unreadMessagesCount] == 0) {
            DDLogSupport(@"Calling Cancel Chime while handling Local Notfication");
            [[QliqUserNotifications getInstance] cancelChimeNotifications:YES];
            return;
        }
        
        NSDictionary *userInfo = nil;
        //        if (is_ios_greater_or_equal_10() && [receivedNotification isKindOfClass:[UNNotification class]]) {
        //            userInfo = ((UNNotification *)receivedNotification).request.content.userInfo;
        //        }
        //        else if ([receivedNotification isKindOfClass:[UILocalNotification class]])
        {
            userInfo = ((UILocalNotification *)receivedNotification).userInfo;
        }
        
        NSString * priority = [userInfo objectForKey:LocalNotificationRingtonePriority];
        NSString * type = [userInfo objectForKey:LocalNotificationRingtoneType];
        Ringtone * ringtone = [self.soundSettings ringtoneForPriority:priority andType:type];
        
        if ([[userInfo objectForKey:LocalNotificationType] isEqual:LocalNotificationTypeChime]){
            Ringtone * ringtone = [self.soundSettings ringtoneForPriority:priority andType:type];
            [ringtone play];
        } else if ([[userInfo objectForKey:LocalNotificationType] isEqual:LocalNotificationTypeScheduledChime]){
            NSString * alertBody = [userInfo objectForKey:LocalNotificationAlertBody];
            [ringtone play];
            /* if notification interval changed - reshedule notifications*/
            NSInteger interval = [[userInfo objectForKey:LocalNotificationInterval] integerValue];
            if (interval != [self.soundSettings notificationsSettingsForPriority:priority].reminderChimeInterval){
                /* Cancel old chime notifications */
                interval = [self.soundSettings notificationsSettingsForPriority:priority].reminderChimeInterval;
                
                if (userInfo[kKeyLocalNotificationID])
                {
                    NSUInteger conversationId = [userInfo[kKeyConversationID] unsignedIntegerValue];
                    
                    BOOL shouldScheduled = [self cancelScheduledNotificationsFor:conversationId withRingtone:ringtone];
                    if (shouldScheduled)
                        [self scheduleChimeNotificationWithRingtone:ringtone
                                                          messageID:userInfo[kKeyMessageID]
                                           conversationIDForMessage:userInfo[kKeyConversationID]
                                                     chimesInterval:interval
                                                    messagePriority:userInfo[LocalNotificationMessagePriority]
                                                          alertBody:alertBody];
                }
                else
                {
                    DDLogSupport(@"Handled Old Local Notfication");
                }
            }
        }
        
        //        if (!is_ios_greater_or_equal_10()) {
        [self addLocalNotificationToChimed:userInfo[kKeyLocalNotificationID]];
        //        }
    }
}

#pragma mark - Notifiying

- (void)notifyIncomingChatMessage:(ChatMessage *)message forCareChannel:(BOOL)isCareChannel withoutSound:(BOOL)noSound
{
    __weak __block typeof(self) welf = self;
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        SoundSettings * soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
        NotificationsSettings *notificationSettings = [soundSettings notificationsSettingsForPriority: isCareChannel ? [message priorityStringCareChannel] : [message priorityString]];
        Ringtone *ringtone = [notificationSettings ringtoneForType:isCareChannel ? NotificationTypeIncomingCareChannel : NotificationTypeIncoming];
        NSInteger unReadCount = [ChatMessage unreadMessagesCount];
        
        DDLogSupport(@"notifyIncomingChatMessage: With sound=%@ isCareChannel=%@", noSound ? @"NO" : @"YES", isCareChannel ? @"YES" : @"NO");
        
        // add local notifications
        if (!noSound && [message isNormalChatMessage] && ![message isRead])
        {
            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:message.fromQliqId];
            
            if ([user.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                
                DDLogSupport(@"Message from user with qliq id:%@ to current user", user.qliqId);
                user = nil;
            }
            
            if (!user)
            {
                DDLogError(@"Cannot find qliq user for qliq id: %@", message.fromQliqId);
                return;
            }
            
            NSString *legUserName = [user displayName];
            if ([legUserName length] <= 0)
            {
                DDLogError(@"Cannot get user's display name for qliq id: %@", message.fromQliqId);
                return;
            }
            
            //Cancel previous scheduled notifications for this conversations
            BOOL shouldScheduled = [welf cancelScheduledNotificationsFor:message.conversationId withRingtone:ringtone];
            
            NSString *alertBodyStr = QliqFormatLocalizedString1(@"2381-TitleMessageReceivedFrom{Sender}", legUserName);
            
            // Show Local Notification to notify user about new message and play sound if needed.
            // And if app was not launch with PUSH notification
            if(!message.callId)
            {
                message.callId = message.metadata.uuid;
            }
            
            if (![welf.launchedPushCallId isEqualToString:message.callId] && ![welf isRemoteNotificationChimedCallId:message.callId] && ![welf.showedNotifications containsObject:message.callId])
            {
                [welf showLocalUserNotificationWithBody:alertBodyStr message:message ringtone:ringtone badge:unReadCount andAction:QliqLocalizedString(@"2145-TitleView")];
                
                // Show a custom visual alert if the app is in ACTIVE state.
                // In BG, the iOS will show the notification alert
                if ([AppDelegate applicationState] == UIApplicationStateActive && ![appDelegate.idleController lockedIdle])
                {
                    
                    NSString *bannerSubtitle = QliqLocalizedString(@"2382-TitleMessageReceived");
                    dispatch_async_main(^{
                        QliqNotificationView *banner = [QliqNotificationView new];
                        banner.converationId = message.conversationId;
                        banner.titleLabel.text = legUserName;
                        banner.descriptionLabel.text = bannerSubtitle;
                        isIPhoneX {
                            banner.titleLabel.font = [UIFont systemFontOfSize:19.0];
                            banner.descriptionLabel.font = [UIFont systemFontOfSize:17.0];
                        }
                        banner.avatarImageView.layer.cornerRadius = banner.avatarImageView.bounds.size.height / 2;
                        banner.avatarImageView.clipsToBounds = YES;
                        banner.avatarImageView.image = (user.avatar ? user.avatar : [[UIImage alloc] initWithContentsOfFile:user.avatarFilePath]);
                        [banner present];
                    });
                }
            }
            else
            {
                [welf removeRemoteNotificationFromChimedWithCallId:message.callId];
                [self.showedNotifications removeObject:message.callId];
                shouldScheduled = NO;
            }
            
            //Schedule Local Notifications to remind the user about unread message
            if (shouldScheduled)
                [welf scheduleChimeNotificationWithRingtone:ringtone
                                                  messageID:[NSNumber numberWithUnsignedInteger:message.messageId]
                                   conversationIDForMessage:[NSNumber numberWithUnsignedInteger:message.conversationId]
                                             chimesInterval:notificationSettings.reminderChimeInterval
                                            messagePriority:[message priority]
                                                  alertBody:alertBodyStr];
        }
        //just update badge
        else
        {
            DDLogSupport(@"No sound is set. returning");
            // Update the badge count, if needed.
            if (unReadCount > 0)
                [welf refreshAppBadge:unReadCount];
        }
    }];
    
    operation.queuePriority = NSOperationQueuePriorityVeryHigh;
    
    [self.qliqNotificationsOperationQueue addOperation:operation];
}

- (void) notifyAckGotForMessage:(ChatMessage *)message{
    Ringtone * ringtone = [self.soundSettings ringtoneForPriority:[message priorityString] andType:NotificationTypeAck];
    [ringtone play];
}

-(void) notifyNewAdmition
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        DDLogSupport(@"notifyNewAdmition");
        [self showLocalUserNotificationWithBody:QliqLocalizedString(@"2387-TitleNewPatientAdmition")
                                        message:nil
                                       ringtone:nil
                                          badge:[ChatMessage unreadMessagesCount]
                                      andAction:QliqLocalizedString(@"2386-TitleShow")];
    }
}



-(void) notifyIncomingCall:(Call *)call
{
    //    if (is_ios_greater_or_equal_10())
    //        DDLogSupport(@"Feature didn't supported");
    //    else
    {
        UIApplication *app = [UIApplication sharedApplication];
        if (!(app.applicationState == UIApplicationStateActive))
        {
            dispatch_async_main(^{
                [app cancelAllLocalNotifications];
            });
            UILocalNotification *alarm = [[UILocalNotification alloc] init];
            if (alarm)
            {
                //alarm.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
                //alarm.soundName = [[AKSIPUserAgent sharedUserAgent] ringtoneFile];
                alarm.alertBody = [NSString stringWithFormat:@"%@ %@", @"Incoming call from:\n", [call.contact nameDescription]];
                alarm.alertAction = NSLocalizedString(@"2020-TitleAnswer", @"Answer to incoming call");
                alarm.alertLaunchImage = @"Default";
                alarm.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  LocalNotificationTypeCall, LocalNotificationType,
                                  nil];
                [app presentLocalNotificationNow:alarm];
            }
        }
    }
}

- (void)notifyUserAppDidNotProcessRemoteNotificaiton:(NSDictionary *)aps
{
    if (aps[@"alert"] == nil || aps[@"alert"][@"body"] == nil) {
        DDLogSupport(@"alert or alert-body is empty. Cannot show this spurious notification to the user");
        return;
    }
    
    DDLogSupport(@"Show local notification since the App failed to Process the Payload of the message, with alert: %@", aps[@"alert"][@"body"]);
    
    UILocalNotification * alert = [[UILocalNotification alloc] init];
    if (alert)
    {
        NSInteger parsedValue = [self parseBadgeNumberFromPayload:aps];
        if (parsedValue <= 0) {
            parsedValue = [ChatMessage unreadMessagesCount];
        }
        NSInteger appIconBadgeValue = parsedValue + appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt;
        
        alert.repeatInterval = 0;
        alert.alertBody = aps[@"alert"][@"body"];
        alert.soundName = aps[@"sound"];
        alert.applicationIconBadgeNumber = appIconBadgeValue;
        alert.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                          LocalNotificationTypeNotify, LocalNotificationType,
                          nil];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
        
        [self.showedNotifications addObject:aps[@"call_id"]];
        
        DDLogSupport(@"<-- Refresh App Badge with value: %ld, "
                     "unreadMsgs: %ld, "
                     "failedToDecryptMsgs: %ld -->",
                     (long)appIconBadgeValue,
                     (long)parsedValue,
                     (long)appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt);
    }
}

- (NSInteger)parseBadgeNumberFromPayload:(NSDictionary *)aps {
    DDLogSupport(@"->> parseBadgeNumberFromPayload - %@", aps[@"badge"]);
    if (aps[@"badge"])
    {
        if ([aps[@"badge"] isKindOfClass:[NSString class]])
        {
            NSString *badgeString = aps[@"badge"];
            badgeString = [[badgeString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
            if (badgeString.length > 0)
                return [badgeString integerValue];
        }
        else if ([aps[@"badge"] isKindOfClass:[NSNull class]])
        {
            return 0;
        }
        return aps[@"badge"];
    }
    return 0;
}


- (void)notifyUserAboutLogoutWithReason:(NSString *)reason
{
    if (!reason || reason.length <= 0) {
        DDLogSupport(@"notifyUserAboutLogoutWithReason: reason is nil");
        return;
    }
    
    DDLogSupport(@"Show local notification since the user was logged out with reason: %@", reason);
    
    UILocalNotification * alert = [[UILocalNotification alloc] init];
    if (alert)
    {
        alert.repeatInterval = 0;
        alert.alertBody = reason;
        alert.soundName = UILocalNotificationDefaultSoundName;
        alert.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                          LocalNotificationTypeNotify, LocalNotificationType,
                          nil];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
    }
}

#pragma mark - App Badge

- (void)refreshAppBadge:(NSInteger)badge
{
    NSInteger appIconBadgeValue = badge + appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt;
    DDLogSupport(@"<-- Refresh App Badge with value: %ld, "
                 "unreadMsgs: %ld, "
                 "failedToDecryptMsgs: %ld -->",
                 (long)appIconBadgeValue,
                 (long)badge,
                 (long)appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt);
    
    performBlockInMainThread(^{
        [UIApplication sharedApplication].applicationIconBadgeNumber = appIconBadgeValue;
    });
}

#pragma mark - Chimed Local Notifications

- (void)clearChimedNotifications {
    [self clearChimedLocalNotifications];
    [self clearChimedRemoteNotifications];
}


#pragma mark * Chimed Local Notifications

- (NSMutableSet *)getChimedLocalNotificationsFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableSet *chimedLocalNotifications = [NSMutableSet setWithArray:[defaults objectForKey:kKeyChimedLocalNotifications]];
    
    if (!chimedLocalNotifications) {
        chimedLocalNotifications = [NSMutableSet set];
    }
    return chimedLocalNotifications;
}



- (void)updateChimedLocalNotifications {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.chimedLocalNotificationsSet.allObjects forKey:kKeyChimedLocalNotifications];
    [defaults synchronize];
}


- (void)addLocalNotificationToChimed:(NSString *)notificationId {
    if (notificationId) {
        @synchronized (self) {
            [self.chimedLocalNotificationsSet addObject:notificationId];
        }
        [self updateChimedLocalNotifications];
    }
}



- (void)removeLocalNotificationFromChimed:(NSString *)notificationId {
    if ([self.chimedLocalNotificationsSet containsObject:notificationId]) {
        @synchronized (self) {
            [self.chimedLocalNotificationsSet removeObject:notificationId];
        }
    }
    [self updateChimedLocalNotifications];
}




- (void)clearChimedLocalNotifications {
    @synchronized (self) {
        [self.chimedLocalNotificationsSet removeAllObjects];
    }
    [self updateChimedLocalNotifications];
}



- (BOOL)isLocalNotificationChimed:(NSString *)notificationId {
    __block BOOL isChimed = NO;
    //    if (is_ios_greater_or_equal_10()) {
    //        [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
    //            for (UNNotification *notification in notifications) {
    //                if ([notification.request.identifier isEqualToString:notificationId]) {
    //                    isChimed = YES;
    //                    break;
    //                }
    //            }
    //        }];
    //    }
    //    else
    {
        @synchronized (self) {
            isChimed = [self.chimedLocalNotificationsSet containsObject:notificationId];
        }
    }
    return isChimed;
}



#pragma mark * Chimed Remote Notifications

- (NSMutableSet *)getChimedRemoteNotificationsFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableSet *chimedRemoteNotifications = [NSMutableSet setWithArray:[defaults objectForKey:kKeyChimedRemoteNotifications]];
    
    if (!chimedRemoteNotifications) {
        chimedRemoteNotifications = [NSMutableSet set];
    }
    return chimedRemoteNotifications;
}

- (void)updateChimedRemoteNotifications {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.chimedRemoteNotificationsSet.allObjects forKey:kKeyChimedRemoteNotifications];
    [defaults synchronize];
}

- (void)addRemoteNotificationToChimed:(NSString *)notificationId callId:(NSString *)callId {
    if (notificationId && callId)
    {
        NSDictionary *pushDictionary = [NSDictionary dictionaryWithObjectsAndKeys:notificationId,@"push_Id",
                                        callId,@"call_Id",
                                        nil];
        __weak __block typeof(self) welf = self;
        void (^addRemoteNotificationToChimedBlock)(void) = ^(void){
            
            @synchronized (self) {
                [welf.chimedRemoteNotificationsSet addObject:pushDictionary];
            }
            [welf updateChimedRemoteNotifications];
        };
        
        if ([NSOperationQueue currentQueue] != self.qliqNotificationsOperationQueue)
            [self.qliqNotificationsOperationQueue addOperationWithBlock:addRemoteNotificationToChimedBlock];
        else
            addRemoteNotificationToChimedBlock();
    }
}

- (void)removeRemoteNotificationFromChimed:(NSString *)notificationId callId:(NSString *)callId {
    
    NSDictionary *pushDictionary = [NSDictionary dictionaryWithObjectsAndKeys:notificationId,@"push_Id",
                                    callId,@"call_Id",
                                    nil];
    
    
    if ([self.chimedRemoteNotificationsSet containsObject:pushDictionary]) {
        @synchronized (self) {
            [self.chimedRemoteNotificationsSet removeObject:pushDictionary];
        }
    }
    [self updateChimedRemoteNotifications];
}
- (void)removeRemoteNotificationFromChimedWithCallId:(NSString *)callId {
    
    NSMutableArray *array = [NSMutableArray new];
    
    for (NSDictionary *pushDictionary in self.chimedRemoteNotificationsSet) {
        NSString *value = [pushDictionary valueForKey:@"call_Id"];
        if ([value isEqualToString:callId]) {
            [array addObject:pushDictionary];
        }
    }
    
    for (NSDictionary *pushDictionary in array) {
        @synchronized (self) {
            [self.chimedRemoteNotificationsSet removeObject:pushDictionary];
        }
    }
    
    [self updateChimedRemoteNotifications];
}

- (void)clearChimedRemoteNotifications {
    @synchronized (self) {
        [self.chimedRemoteNotificationsSet removeAllObjects];
    }
    [self updateChimedRemoteNotifications];
}

- (BOOL)isRemoteNotificationChimed:(NSString *)notificationId callId:(NSString *)callId {
    
    NSDictionary *pushDictionary = [NSDictionary dictionaryWithObjectsAndKeys:notificationId,@"push_Id",
                                    callId,@"call_Id",
                                    nil];
    BOOL isChimed = NO;
    @synchronized (self) {
        isChimed = [self.chimedRemoteNotificationsSet containsObject:pushDictionary];
    }
    return isChimed;
}

- (BOOL)isRemoteNotificationChimedCallId:(NSString *)callId
{
    BOOL isChimed = NO;
    for (NSDictionary *pushDictionary in self.chimedRemoteNotificationsSet) {
        NSString *value = [pushDictionary valueForKey:@"call_Id"];
        if ([value isEqualToString:callId]) {
            return YES;
            break;
        }
    }
    return isChimed;
}

#pragma mark - Remote Notifications

- (void)openDelayedPUSH:(NSNotification *)notification {
    DDLogSupport(@"Try to open Delayed PUSH with notification:%@", notification);
    ChatMessage *message = notification.userInfo[kKeyMessage];
    UINavigationController *nav = notification.object;
    NSNumber *conversationId = [NSNumber numberWithInteger:message.conversationId];
    Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:conversationId];
    if (conversation)
    {
        [QliqUserNotifications openConversationViewControllerIn:nav withConversation:conversation];
        [self removeRemoteNotificationFromChimed:appDelegate.pushNotificationId callId:appDelegate.pushNotificationCallId];
    }
    else
    {
        DDLogSupport(@"Cannot find Conversation for PUSH with callId:%@", message.callId);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:StopNotifyingAboutPushMessage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OpenDelayedPushNotification object:nil];
}

- (void)clearLaunchedPushData {
    
    self.delayStartPoint = 0;
    
    if (appDelegate.wasLaunchedDueToRemoteNotificationiOS7) {
        appDelegate.wasLaunchedDueToRemoteNotificationiOS7 = NO;
    }
    if (appDelegate.pushNotificationCallId) {
        appDelegate.pushNotificationCallId = nil;
    }
    if (appDelegate.pushNotificationToUser) {
        appDelegate.pushNotificationToUser = nil;
    }
    if (appDelegate.pushNotificationId) {
        appDelegate.pushNotificationId = nil;
    }
}

- (BOOL)openConversationForRemoteNotificationWith:(UINavigationController *)nav callId:(NSString *)callId{
    
    if ([appDelegate isMainViewControllerRoot])
    {
        DDLogSupport(@"Open Conversation for PUSH with call ID: %@", callId);
        
        ChatMessage *message = [ChatMessageService getMessageWithUuid:callId];
        if (message)
        {
            if (!message.isRead)
            {
                NSNumber *conversationId = [NSNumber numberWithInteger:message.conversationId];
                Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:conversationId];
                
                if (conversation)
                {
                    [QliqUserNotifications openConversationViewControllerIn:nav withConversation:conversation];
                }
                else
                {
                    DDLogSupport(@"Cannot find Conversation for PUSH with callId:%@", callId);
                }
            }
            [self removeRemoteNotificationFromChimed:appDelegate.pushNotificationId callId:appDelegate.pushNotificationCallId];
            return YES;
        }
        else
        {
            DDLogSupport(@"Cannot find Message for PUSH with callId:%@", callId);
            
            self.delayStartPoint = [[NSDate date] timeIntervalSince1970];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openDelayedPUSH:) name:OpenDelayedPushNotification object:nil];
            
            @synchronized (self) {
                self.launchedPushCallId = [appDelegate.pushNotificationCallId copy];
            }
            return NO;
        }
    }
    else
    {
        DDLogSupport(@"Trying to show Conversation, but MainViewController is not root. Looks like user is logged out. Open conversation if ");
        
        self.delayStartPoint = [[NSDate date] timeIntervalSince1970];
        self.openAfterLoginPushCallId = callId;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(openConversationAfterLogin:)
                                                     name:OpenConversationAfterLoginNotification
                                                   object:nil];
    }
    
    return NO;
}

#pragma mark - Private

- (void)openConversationAfterLogin:(NSNotification *)notification {
    NSTimeInterval delta = [[NSDate date] timeIntervalSince1970] - self.delayStartPoint;
    DDLogSupport(@"Try to open Conversation for notification After Login. Time after scheduling: %f", delta);
    if (self.delayStartPoint > 0.0 && delta < kValueDelayForLogin)
    {
        self.delayStartPoint = 0.0;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:OpenConversationAfterLoginNotification object:nil];
        UINavigationController *nav = notification.object;
        if (self.openAfterLoginPushCallId)
        {
            [self openConversationForRemoteNotificationWith:nav callId:self.openAfterLoginPushCallId];
            self.openAfterLoginPushCallId = nil;
        }
        else if (self.openAfterLoginLocalNotification)
        {
            [self openConversationForLocalNotification:self.openAfterLoginLocalNotification withNavController:nav];
            self.openAfterLoginLocalNotification = nil;
        }
    }
    else
    {
        DDLogSupport(@"Time for opening Local Notification after login is expired");
        self.delayStartPoint = 0.0;
        self.openAfterLoginLocalNotification = nil;
        self.openAfterLoginPushCallId = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:OpenConversationAfterLoginNotification object:nil];
    }
}


- (void)openConversationForLocalNotification:(id)localNotification withNavController:(UINavigationController *)nav
{
    self.isConversationOpeningInProgress = YES;
    DDLogSupport(@"Open Conversation for tappedNotification: %@",localNotification);
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    NSDictionary *userInfo = nil;
    //            if (is_ios_greater_or_equal_10() && [tappedNotification isKindOfClass:[UNNotification class]]) {
    //                userInfo = ((UNNotification *)tappedNotification).request.content.userInfo;
    //            }
    //            else if ([tappedNotification isKindOfClass:[UILocalNotification class]])
    {
        userInfo = ((UILocalNotification *)localNotification).userInfo;
    }
    
    
    NSString *qliqIdFromReceivedNotification = userInfo[kKeyUserQliqId];
    if (user && [user.qliqId isEqualToString:qliqIdFromReceivedNotification] && ![appDelegate.idleController lockedIdle])
    {
        NSNumber *conversationId = userInfo[kKeyConversationID];
        Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:conversationId];
        if (conversation)
        {
            NSNumber *messageId = userInfo[kKeyMessageID];
            if (![ChatMessageService getMessage:[messageId integerValue]].isRead)
                [QliqUserNotifications openConversationViewControllerIn:nav withConversation:conversation];
        }
    }
    
    //            if (!is_ios_greater_or_equal_10()) {
    [self removeLocalNotificationFromChimed:userInfo[kKeyLocalNotificationID]];
    //            }
    
    appDelegate.unProcessedLocalNotifications = nil;
    
    self.isConversationOpeningInProgress = NO;
}

- (SoundSettings *)soundSettings{
    return [UserSessionService currentUserSession].userSettings.soundSettings;
}

- (void) onChatBadgeValueChanged:(NSNotification *)notif
{
    NSNumber *newBadgeValue = notif.userInfo[@"newBadgeValue"];
    DDLogSupport(@"onChatBadgeValueChanged --> New Badge Value: %@", newBadgeValue);
    NSInteger badge = [newBadgeValue integerValue];
    [self refreshAppBadge:badge];
    if (badge == 0 && [[UIApplication sharedApplication] scheduledLocalNotifications].count != 0) {
        [self cancelChimeNotifications:YES];
    }
}

- (NSInteger) highestChatMessagePriorityForExistingChimeNotifications
{
    NSInteger priority = -1;
    
    UIApplication* app = [UIApplication sharedApplication];
    NSArray * allNotifications = [app scheduledLocalNotifications];
    for (UILocalNotification * localNotification in allNotifications){
        int prio = [[localNotification.userInfo objectForKey:LocalNotificationMessagePriority] intValue];
        if (prio > priority) {
            priority = prio;
        }
    }
    return priority;
}

+ (void)openConversationViewControllerIn:(UINavigationController *)navigationController withConversation:(Conversation *)conversation
{
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.conversation = conversation;
    NSArray *controllers = [navigationController viewControllers];
    if ([controllers.lastObject isKindOfClass:[ConversationViewController class]])
    {
        ConversationViewController *presentedController = (ConversationViewController *)controllers.lastObject;
        if (presentedController.conversation.conversationId != conversation.conversationId)
        {
            dispatch_async_main(^{
                [navigationController pushViewController:controller animated:YES];
            });
        }
    }
    else
    {
        dispatch_async_main(^{
            [navigationController pushViewController:controller animated:YES];
        });
    }
}

@end

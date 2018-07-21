//
//  MessageStatusLog.h
//  qliq
//
//  Created by Ravi Ada on 05/23/12.
//  Copyright (c) 2012 qliqSoft Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

typedef enum {
    CreatedMessageStatus                 = 1,
    SendingMessageStatus                 = 2,
    ReceivedMessageStatus                = 3,
    SendingAckMessageStatus              = 4,
    AckReceivedMessageStatus             = 5,
    ReadMessageStatus                    = 6,
    AckDeliveredMessageStatus            = 7,
    AckPendingMessageStatus              = 8,
    AckSyncedStatus                      = 9,
    SentMessageStatus                    = 10,
    ReceivedByAnotherDeviceMessageStatus = 11,
    RecalledMessageStatus                = 12,
    PushNotificationReceivedMessageStatus = 13,
    PushNotificationSentByServerStatus   = 14,
    SentToQliqStorMessageStatus          = 15, // on desktop this is 13
    PendingForQliqStorMessageStatus      = 16,
    PermanentQliqStorFailureMessageStatus = 17,
    DeliveredMessageStatus               = 200,
    PendingMessageStatus                 = 202,
    SyncedMessageStatus                  = 299
} MessageStatus;

@interface MessageStatusLog : NSObject

@property (nonatomic, assign) NSInteger messageId;
@property (nonatomic, readwrite) NSTimeInterval timestamp;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, retain) NSString *statusText;
@property (nonatomic, retain) NSString *qliqId;

- (NSString*)statusMsg:(NSInteger)recipientCount showQliqUserName:(BOOL)showQliqUserName;

+ (NSString  *) statusMessage: (NSInteger) status;

@end

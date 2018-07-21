//
//  MessageStatusLog.m
//  qliq
//
//  Created by Ravi Ada on 05/23/12.
//  Copyright (c) 2012 qliqSoft Inc.. All rights reserved.
//

#import "MessageStatusLog.h"
#import "ChatMessage.h"
#import "QliqUserDBService.h"

@implementation MessageStatusLog

@synthesize messageId;
@synthesize timestamp;
@synthesize status;
@synthesize statusText;
@synthesize qliqId;

- (void) dealloc
{
    [super dealloc];
}

- (NSString*)statusMsg:(NSInteger)recipientCount showQliqUserName:(BOOL)showQliqUserName
{
    NSString *text = [MessageStatusLog statusMessage:status];

    if ([qliqId length] > 0 && showQliqUserName)
    {
        QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
        
        if (user)
        {
            if (statusText.length > 0)
            {
                text = [user.displayName stringByAppendingFormat:@": %@ (%ld)", statusText, (long)status];
            }
            else
            {
                NSString *displayName = [user displayName];
                NSString *preposition = @"to";
                if (self.status == ReadMessageStatus || self.status == RecalledMessageStatus)
                {
                    preposition =  @"by";
                }
                else if (self.status == AckReceivedMessageStatus)
                {
                    preposition = @"from";
                }
                else if (self.status == SentToQliqStorMessageStatus || self.status == PendingForQliqStorMessageStatus)
                {
                    preposition = @"";
                    // For qliqStor we want to see qliq id
                    displayName = user.qliqId;
                }
                
                if (displayName.length == 0) {
                    // Error fallback (not duplicate with qliqStor condition)
                    displayName = user.qliqId;
                }
                text = [text stringByAppendingFormat:@" %@ %@", preposition, displayName];
            }
        }
        else
        {
            text = [text stringByAppendingFormat:@" to contact %@", qliqId];
        }
    }
    else if ([qliqId length] > 0 && !showQliqUserName)
    {
        if (statusText.length > 0) {
            text = [statusText stringByAppendingFormat:@" (%ld)", (long)status];
        }
    }
    else if (status == DeliveredMessageStatus && recipientCount > 1)
    {
        text = [text stringByAppendingString:@" to all"];
    }
    else if (status == AckReceivedMessageStatus && recipientCount > 1)
    {
        text = @"Acknowledged by all";
    }
    else if (statusText.length > 0) {
        text = [statusText stringByAppendingFormat:@" (%ld)", (long)status];
    }
    
    return text;
}

+ (NSString*)statusMessage:(NSInteger)status
{
    switch (status) {
        case CreatedMessageStatus:
            return @"Created";
        case SendingMessageStatus:
            return @"Sending...";
        case ReceivedMessageStatus:
            return @"Received (by this device)";
        case SendingAckMessageStatus:
            return @"Sending Ack...";
        case AckPendingMessageStatus:
            return @"Ack Sent";
        case AckDeliveredMessageStatus:
            return @"Ack Delivered";
        case AckReceivedMessageStatus:
            return @"Ack Received";
        case AckSyncedStatus:
            return @"Ack Synced";
        case ReadMessageStatus:
            return @"Read";
        case SentMessageStatus:
            return @"Sent";
        case ReceivedByAnotherDeviceMessageStatus:
            return @"Received (by another device)";
        case RecalledMessageStatus:
            return @"Recalled";
        case PushNotificationReceivedMessageStatus:
            return @"Push Notification Received";
        case PushNotificationSentByServerStatus:
            return @"Push Notification Sent";
        case SentToQliqStorMessageStatus:
            return @"Sent to QliqSTOR";
        case PendingForQliqStorMessageStatus:
            return @"Pending for QliqSTOR";
        case PermanentQliqStorFailureMessageStatus:
            return @"Permanent QliqSTOR Failure";
        default:
            return [ChatMessage deliveryStatusToString:status includeCode:NO];            
    }
}

@end

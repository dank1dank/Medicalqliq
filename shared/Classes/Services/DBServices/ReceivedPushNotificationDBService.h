//
//  ReceivedPushNotificationDBService.h
//  qliq
//
//  Created by Adam on 01/07/15.
//
//

#import <Foundation/Foundation.h>
#import "ReceivedPushNotification.h"

@interface ReceivedPushNotificationDBService : NSObject

+ (BOOL) insert:(NSString *)callId;
+ (BOOL) saveAsSentToServer:(NSString *)callId;
+ (BOOL) remove:(NSString *)callId;
+ (BOOL) deleteOlderThen:(NSTimeInterval)timestamp;
+ (NSArray *) selectNoSentToServer;
+ (ReceivedPushNotification *) selectWithCallId:(NSString *)callId;

@end

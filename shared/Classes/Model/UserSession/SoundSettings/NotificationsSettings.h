//
//  NotificationsSettings.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import <Foundation/Foundation.h>
#import "Ringtone.h"

@interface NotificationsSettings : NSObject

@property (nonatomic, readwrite) NSUInteger reminderChimeInterval;
@property (nonatomic, readonly, strong) NSString * priority;

extern NSString * NotificationTypeIncoming;
extern NSString * NotificationTypeSend;
extern NSString * NotificationTypeAck;
extern NSString * NotificationTypeRinger;

- (NSArray *) types;

- (Ringtone *) ringtoneForType:(NSString *) type;

- (id) initWithPriority:(NSString *) priority;

@end

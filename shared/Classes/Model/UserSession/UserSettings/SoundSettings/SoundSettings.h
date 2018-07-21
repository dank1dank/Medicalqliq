//
//  SoundSettings.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import <Foundation/Foundation.h>
#import "NotificationsSettings.h"

extern NSString * NotificationPriorityNormal;
extern NSString * NotificationPriorityUrgent;
extern NSString * NotificationPriorityASAP;
extern NSString * NotificationPriorityFYI;
extern NSString * NotificationPriorityNormalCareChannel;
extern NSString * NotificationPriorityUrgentCareChannel;
extern NSString * NotificationPriorityASAPCareChannel;
extern NSString * NotificationPriorityFYICareChannel;

extern NSDictionary * soundDefaults;

@interface SoundSettings : NSObject

- (NSArray *) priorities;
- (NSArray *) prioritiesCareChannel;

- (NotificationsSettings *) notificationsSettingsForPriority:(NSString *) priority;

- (Ringtone *) ringtoneForPriority:(NSString *) priority andType:(NSString *)type;

- (void) resetToDefaults;

@end

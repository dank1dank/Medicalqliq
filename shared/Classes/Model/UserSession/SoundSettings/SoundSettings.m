//
//  SoundSettings.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import "SoundSettings.h"

#import "NotificationsSettings.h"

@implementation SoundSettings{
    NSDictionary * notificationSettings;
}

NSString * NotificationPriorityNormal = @"Normal Message";
NSString * NotificationPriorityUrgent = @"Urgent Message";
NSString * NotificationPriorityASAP = @"ASAP Message";
NSString * NotificationPriorityFYI = @"FYI Message";

NSDictionary * soundDefaults;

+ (NSDictionary *) defaultSettings{
    
    soundDefaults = @{
        NotificationPriorityNormal : @{
            @"reminderChimeInterval" : @5,
            NotificationTypeIncoming : @{
                @"dictionaryName" : @"qliqChime", /*name from Sounds.plist*/
                @"vibrateEnabled" : @YES,
                @"soundEnabled": @YES,
                @"volume": @1
            },
            NotificationTypeSend : @{
                @"dictionaryName" : @"Send",
                @"vibrateEnabled" : @NO,
                @"soundEnabled": @YES,
                @"volume": @1
            },
            NotificationTypeAck : @{
                @"dictionaryName" : @"Acknowledge",
                @"vibrateEnabled" : @YES,
                @"soundEnabled": @YES,
                @"volume": @1
            },
            NotificationTypeRinger : @{
                @"dictionaryName" : @"Ringer",
                @"vibrateEnabled" : @YES,
                @"soundEnabled": @YES,
                @"volume": @1
            }
        },
        NotificationPriorityUrgent : @{
            @"reminderChimeInterval" : @1,
            NotificationTypeIncoming : @{
                @"dictionaryName" : @"qliqChime",
                @"vibrateEnabled" : @YES,
                @"soundEnabled": @YES,
                @"volume": @2
            }
        },
        NotificationPriorityASAP : @{
            @"reminderChimeInterval" : @3,
            NotificationTypeIncoming : @{
                @"dictionaryName" : @"qliqChime",
                @"vibrateEnabled" : @YES,
                @"soundEnabled": @YES,
                @"volume": @2
            }
        },
        NotificationPriorityFYI : @{
            @"reminderChimeInterval" : @5,
            NotificationTypeIncoming : @{
                @"dictionaryName" : @"qliqChime",
                @"vibrateEnabled" : @NO,
                @"soundEnabled": @NO,
                @"volume": @1
            }
        }
    };
    
    NSMutableDictionary * settings = [NSMutableDictionary new];
    
    NotificationsSettings * urgent = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityUrgent];
    NotificationsSettings * asap = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityASAP];
    NotificationsSettings * fyi = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityFYI];
    NotificationsSettings * normal = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityNormal];
    
    [settings setObject:urgent forKey:NotificationPriorityUrgent];
    [settings setObject:asap forKey:NotificationPriorityASAP];
    [settings setObject:fyi forKey:NotificationPriorityFYI];
    [settings setObject:normal forKey:NotificationPriorityNormal];
    
    return settings;
}


- (NSArray *)priorities{
    return [NSArray arrayWithObjects:NotificationPriorityNormal, NotificationPriorityUrgent, NotificationPriorityASAP, NotificationPriorityFYI, nil];
}

- (NotificationsSettings *)notificationsSettingsForPriority:(NSString *)priority{
    return [notificationSettings objectForKey:priority];
}

- (Ringtone *) ringtoneForPriority:(NSString *) priority andType:(NSString *)type{
    return [[self notificationsSettingsForPriority:priority] ringtoneForType:type];
}

- (id) init{
    self = [super init];
    if (self) {
        notificationSettings = [SoundSettings defaultSettings];
    }
    return self;
}

- (void) resetToDefaults{
    notificationSettings = [SoundSettings defaultSettings];
}


- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        notificationSettings = [aDecoder decodeObjectForKey:@"notificationSettings"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:notificationSettings forKey:@"notificationSettings"];
}


@end

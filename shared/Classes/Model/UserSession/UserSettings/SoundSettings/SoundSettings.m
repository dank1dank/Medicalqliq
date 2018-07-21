//
//  SoundSettings.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import "SoundSettings.h"

#import "NotificationsSettings.h"

#define kneedUpdateSound @"RescheduleChimeNotifications"

@implementation SoundSettings{
    NSDictionary * notificationSettings;
}

NSString * NotificationPriorityNormal = @"Normal Message";
NSString * NotificationPriorityUrgent = @"Urgent Message";
NSString * NotificationPriorityASAP   = @"ASAP Message";
NSString * NotificationPriorityFYI    = @"FYI Message";
NSString * NotificationPriorityNormalCareChannel = @"Normal Message Care Channel";
NSString * NotificationPriorityUrgentCareChannel = @"Urgent Message Care Channel";
NSString * NotificationPriorityASAPCareChannel   = @"ASAP Message Care Channel";
NSString * NotificationPriorityFYICareChannel    = @"FYI Message Care Channel";

NSDictionary * soundDefaults;

+ (NSDictionary *) defaultSettings{

    soundDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SoundsDefaults" ofType:@"plist"]];
    NSMutableDictionary * settings = [NSMutableDictionary new];
    
    NotificationsSettings * urgent = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityUrgent];
    NotificationsSettings * asap =   [[NotificationsSettings alloc] initWithPriority:NotificationPriorityASAP];
    NotificationsSettings * fyi =    [[NotificationsSettings alloc] initWithPriority:NotificationPriorityFYI];
    NotificationsSettings * normal = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityNormal];

    [settings setObject:urgent forKey:NotificationPriorityUrgent];
    [settings setObject:asap   forKey:NotificationPriorityASAP];
    [settings setObject:fyi    forKey:NotificationPriorityFYI];
    [settings setObject:normal forKey:NotificationPriorityNormal];
    
    return settings;
}

- (BOOL)wasUpdatedCareCannelSoundSettings{
    if ([notificationSettings valueForKey:NotificationPriorityNormalCareChannel]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateCareChannelSoundSettings{
    
    DDLogSupport(@"updateCareChannelSoundSettings called");
    
    soundDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SoundsDefaults" ofType:@"plist"]];
    
    NotificationsSettings * urgentCareChannel = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityUrgentCareChannel];
    NotificationsSettings * asapCareChannel =   [[NotificationsSettings alloc] initWithPriority:NotificationPriorityASAPCareChannel];
    NotificationsSettings * fyiCareChannel =    [[NotificationsSettings alloc] initWithPriority:NotificationPriorityFYICareChannel];
    NotificationsSettings * normalCareChannel = [[NotificationsSettings alloc] initWithPriority:NotificationPriorityNormalCareChannel];
    
    [notificationSettings setValue:urgentCareChannel forKey:NotificationPriorityUrgentCareChannel];
    [notificationSettings setValue:asapCareChannel   forKey:NotificationPriorityASAPCareChannel];
    [notificationSettings setValue:fyiCareChannel    forKey:NotificationPriorityFYICareChannel];
    [notificationSettings setValue:normalCareChannel forKey:NotificationPriorityNormalCareChannel];
}
     
- (NSArray *)priorities{
    return [NSArray arrayWithObjects:NotificationPriorityNormal,
                                    NotificationPriorityUrgent,
                                    NotificationPriorityASAP,
                                    NotificationPriorityFYI, nil];
}

- (NSArray *)prioritiesCareChannel {
    
    return [NSArray arrayWithObjects: NotificationPriorityNormalCareChannel,
                                    NotificationPriorityUrgentCareChannel,
                                    NotificationPriorityASAPCareChannel,
                                    NotificationPriorityFYICareChannel, nil];
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
        if (![self wasUpdatedCareCannelSoundSettings]) {
            DDLogSupport(@"need to update sound settings");
            [self updateCareChannelSoundSettings];
        }
    }

    return self;
}

- (void) resetToDefaults{
    notificationSettings = [SoundSettings defaultSettings];
    if (![self wasUpdatedCareCannelSoundSettings]) {
        DDLogSupport(@"need to update sound settings");
        [self updateCareChannelSoundSettings];
    }
}


- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        notificationSettings = [aDecoder decodeObjectForKey:@"notificationSettings"];
        if (![self wasUpdatedCareCannelSoundSettings]) {
            DDLogSupport(@"need to update sound settings");
            [self updateCareChannelSoundSettings];
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:notificationSettings forKey:@"notificationSettings"];
}

@end

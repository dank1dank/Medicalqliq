//
//  NotificationsSettings.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import "NotificationsSettings.h"
#import "SoundSettings.h"

@implementation NotificationsSettings{
    NSDictionary * ringtones;
}
@synthesize priority;

NSString * NotificationTypeIncoming = @"Incoming Message";
NSString * NotificationTypeSend = @"Send Message";
NSString * NotificationTypeAck = @"Ack Message";
NSString * NotificationTypeRinger = @"Ringer";

@synthesize reminderChimeInterval;



- (id) initWithPriority:(NSString *) _priority{
    self = [super init];
    if (self) {
        priority = _priority;

        NSDictionary * currentPriorityDict = [soundDefaults objectForKey:_priority];
        
        self.reminderChimeInterval = [[currentPriorityDict objectForKey:@"reminderChimeInterval"] integerValue];
        
         NSMutableDictionary * newRingtones = [NSMutableDictionary new];
        
        [currentPriorityDict enumerateKeysAndObjectsUsingBlock:^(NSString * ringtoneType, NSDictionary * ringtoneSettings, BOOL *stop) {
            if ([ringtoneSettings isKindOfClass:[NSDictionary class]]){
                Ringtone * ringtone = [[Ringtone alloc] initWithDictionary:[Ringtone soundDictionaryForName:[ringtoneSettings objectForKey:@"dictionaryName"]]
                                                                      type:ringtoneType
                                                                  priority:priority];
                ringtone.vibrateEnabled = [[ringtoneSettings objectForKey:@"vibrateEnabled"] boolValue];
                ringtone.soundEnabled = [[ringtoneSettings objectForKey:@"soundEnabled"] boolValue];
                ringtone.volume = [[ringtoneSettings objectForKey:@"volume"] intValue];
                [newRingtones setValue:ringtone forKey:ringtoneType];
            }
        }];
        ringtones = newRingtones;
    }
    return self;
}



- (NSArray *) types{
    return [NSArray arrayWithObjects:NotificationTypeIncoming, NotificationTypeSend, NotificationTypeAck, NotificationTypeRinger, nil];
}

- (Ringtone *) ringtoneForType:(NSString *) type{
    return [ringtones objectForKey:type];
}

- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        reminderChimeInterval = [aDecoder decodeIntegerForKey:@"reminderChimeInterval"];
        ringtones = [aDecoder decodeObjectForKey:@"ringtones"];
        priority = [aDecoder decodeObjectForKey:@"priority"];

        if (reminderChimeInterval == 0 && priority)
            reminderChimeInterval = [[[soundDefaults objectForKey:priority] objectForKey:@"reminderChimeInterval"] integerValue];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:ringtones forKey:@"ringtones"];
    [aCoder encodeObject:priority forKey:@"priority"];
    [aCoder encodeInteger:reminderChimeInterval forKey:@"reminderChimeInterval"];
}

@end

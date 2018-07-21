//
//  Ringtone.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import "Ringtone.h"
#import <AudioToolbox/AudioToolbox.h>

#import "Presence.h"
#import "PresenceSettings.h"
#import "UserSessionService.h"
#import "UserSettings.h"

@implementation Ringtone{
    NSDictionary * ringtoneDictionary;
}

static NSDictionary * soundIDs;

@synthesize volume, vibrateEnabled, soundEnabled;
@synthesize priority, type;
@synthesize hidden;

#pragma mark - Class methods

+ (NSDictionary *) soundDictionaryForName:(NSString *) soundName{
    NSArray * allSounds = [self arrayOfSoundsDictionariesWithCategory:nil];
    for (NSDictionary * dict in allSounds){
        if ([[dict objectForKey:@"name"] isEqual:soundName]){
            return dict;
        }
    }
    return nil;
}

+ (NSArray *) arrayOfSoundsDictionariesWithCategory:(NSString *) category{
    NSDictionary * dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sounds" ofType:@"plist"]];
    NSArray * soundsArray;
    if (category){
        soundsArray = [[dictionary objectForKey:@"Categories"] objectForKey:category];
    }else{
        NSMutableArray * allSounds = [[NSMutableArray alloc] init];
        for (NSString * categoryKey in [[dictionary objectForKey:@"Categories"] allKeys]){
            [allSounds addObjectsFromArray:[[dictionary objectForKey:@"Categories"] objectForKey:categoryKey]];
        }
        soundsArray = allSounds;
    }
    return soundsArray;
}

#pragma mark - Instance methods

- (BOOL) isEqual:(NSDictionary *) dict{
    return [ringtoneDictionary isEqual:dict];
}

- (void) setRingtoneDictionary: (NSDictionary *) dict{
    ringtoneDictionary = dict;
}

- (id) initWithDictionary:(NSDictionary *) dict type:(NSString *) _type priority:(NSString *) _priority{
    self = [super init];
    if (self){
        [self setRingtoneDictionary:dict];
        type = _type;
        priority = _priority;
    }
    return self;
}

- (void)dealloc{
    
    [self deallocSoundIDs];
}

- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        ringtoneDictionary = [aDecoder decodeObjectForKey:@"ringtoneDictionary"];
        volume = [aDecoder decodeIntForKey:@"volume"];
        vibrateEnabled = [aDecoder decodeBoolForKey:@"vibrate"];
        soundEnabled = [aDecoder decodeBoolForKey:@"soundEnabled"];
        type = [aDecoder decodeObjectForKey:@"type"];
        priority = [aDecoder decodeObjectForKey:@"priority"];
        
        if ([aDecoder containsValueForKey:@"hidden"]){
            hidden = [aDecoder decodeBoolForKey:@"hidden"];
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:ringtoneDictionary forKey:@"ringtoneDictionary"];
    [aCoder encodeInt:volume forKey:@"volume"];
    [aCoder encodeBool:vibrateEnabled forKey:@"vibrate"];
    [aCoder encodeBool:soundEnabled forKey:@"soundEnabled"];
    [aCoder encodeObject:type forKey:@"type"];
    [aCoder encodeObject:priority forKey:@"priority"];
    [aCoder encodeBool:hidden forKey:@"hidden"];
}


- (NSString *) name{
    return  soundEnabled ? [ringtoneDictionary objectForKey:@"name"] : vibrateEnabled ? @"Vibrate only" : @"Off";
}


- (NSString *) filenameKey{
    NSString * key = nil;
    switch (self.volume) {
        case RingtoneVolumeHight:
            key = @"high";
            break;
        case RingtoneVolumeMedium:
            key = @"medium";
            break;
        case RingtoneVolumeLow:
            key = @"low";
            break;
    }
    return key;
}

- (BOOL)isDND{
    BOOL isDND = NO;
    PresenceSettings * presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
    isDND = [presenceSettings.currentPresenceType isEqualToString:PresenceTypeDoNotDisturb];
    return isDND;
}

- (BOOL)isAway{
    BOOL isAway = NO;
    PresenceSettings * presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
    isAway = [presenceSettings.currentPresenceType isEqualToString:PresenceTypeAway];
    return isAway;
}

- (NSString *) filename {
    //Need set default value as 'nil' for noSound local notifications
    NSString *fileName = nil;
   
    if ([self isDND] || [self isAway] || !soundEnabled)
        return fileName;
    
    fileName = [[ringtoneDictionary objectForKey:@"filename"] objectForKey:[self filenameKey]];
    
    return fileName ? fileName : @"";
}

- (void) vibrateOnly{
    if (vibrateEnabled && ![self isDND]){
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void) playOnly{
    if (soundEnabled && ![self isDND]){
        SystemSoundID ringtoneSoundID = [[[self soundIDs] objectForKey:[self filename]] unsignedIntValue];
        AudioServicesPlaySystemSound(ringtoneSoundID);
    }
}

- (void) play{
    __weak __block typeof(self) welf = self;
    performBlockInMainThread(^{
        [welf playOnly];
        [welf vibrateOnly];
    });
}

#pragma mark - private methods

- (NSDictionary *) soundIDs{
    if (!soundIDs){
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        
        NSArray * allSounds = [Ringtone arrayOfSoundsDictionariesWithCategory:nil];
        for (NSDictionary * dict in allSounds){
            SystemSoundID ringtoneSoundID = 0;
            NSDictionary * filenames = [dict objectForKey:@"filename"];
            for (NSString * filename in [filenames allValues]){
                if (![[dictionary allKeys] containsObject:filenames]){
                    NSString * soundPath = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
                    
                    if (soundPath.length > 0){
                        CFURLRef baseURL = (__bridge CFURLRef)[NSURL fileURLWithPath:soundPath];
                        AudioServicesCreateSystemSoundID(baseURL, &ringtoneSoundID);
                        if (ringtoneSoundID == 0){
                            DDLogSupport(@"ringtone \"%@\" haven't SystemSoundID. Check that file (%@) exist and less than 30 sec.",[dict objectForKey:@"name"],filename);
                        }
                        [dictionary setObject:[NSNumber numberWithUnsignedInt:ringtoneSoundID] forKey:filename];
                    }else{
                        DDLogSupport(@"ringtone \"%@\" not exist. Check that file (%@) exist",[dict objectForKey:@"name"],filename);
                    }
                }
            }
        }
        soundIDs = dictionary;
        DDLogSupport(@"SoundIDs created");
    }
    return soundIDs;
}

- (void) deallocSoundIDs{
    
    if (soundIDs){
        [soundIDs enumerateKeysAndObjectsUsingBlock:^(NSString * filename, NSNumber * soundID, BOOL *stop) {
            SystemSoundID systemSoundID = [soundID unsignedIntValue];
            AudioServicesDisposeSystemSoundID(systemSoundID);
        }];
        soundIDs = nil;
        DDLogSupport(@"SoundIDs dealloced");
    }
}

@end

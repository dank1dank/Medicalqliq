//
//  Ringtone.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/1/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {RingtoneVolumeLow = 0, RingtoneVolumeMedium = 1, RingtoneVolumeHight = 2} RingtoneVolume;

@interface Ringtone : NSObject

@property (nonatomic, readwrite, getter = isVibrateEnabled) BOOL vibrateEnabled;
@property (nonatomic, readwrite, getter = isSoundEnabled) BOOL soundEnabled;
@property (nonatomic, readwrite) RingtoneVolume volume;

@property (nonatomic, readonly, strong) NSString * priority;
@property (nonatomic, readonly, strong) NSString * type;

+ (NSDictionary *) soundDictionaryForName:(NSString *) soundName;
+ (NSArray *) arrayOfSoundsDictionariesWithCategory:(NSString *) category;

- (BOOL) isEqual:(NSDictionary *) dict;

- (id) initWithType:(NSString *) type priority:(NSString *) priority;
- (id) initWithDictionary:(NSDictionary *) dict type:(NSString *) type priority:(NSString *) priority;
- (void) setRingtoneDictionary: (NSDictionary *) dict;

- (NSString *) name;
- (NSString *) filename;


//TODO: think about better method names
- (void) play;
- (void) vibrateOnly;
- (void) playOnly;

@end

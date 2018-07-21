//
//  PresenceSettings.h
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import <Foundation/Foundation.h>
#import "Presence.h"

extern NSString * PresenceTypeOnline;
extern NSString * PresenceTypeAway;
extern NSString * PresenceTypeDoNotDisturb;

@interface PresenceSettings : NSObject<NSCoding>

@property (nonatomic, strong) NSString * currentPresenceType;
@property (nonatomic, strong) NSString * prevPresenceType;

- (NSString *) displayStringForType:(NSString *) type;

- (NSString *)convertPresenceStatusForSubjectType:(NSString *)subjectType;

- (NSArray *) types;

- (Presence *) presenceForType:(NSString *) type;

- (void) setPresence:(Presence *) presence forType:(NSString *) type UNAVAILABLE_ATTRIBUTE;

@end

//
//  PresenceSettings.m
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import "PresenceSettings.h"

NSString * PresenceTypeOnline = @"online";
NSString * PresenceTypeAway = @"away";
NSString * PresenceTypeDoNotDisturb = @"dnd";

@implementation PresenceSettings{
    NSDictionary * presencesDictionary;
    
    NSDictionary * displayString;
}

@synthesize currentPresenceType;
@synthesize prevPresenceType;

- (void) loadDefaults{
    
    Presence * presenceAway   = [[Presence alloc] initWithType:PresenceTypeAway];
    Presence * presenceOnline   = [[Presence alloc] initWithType:PresenceTypeOnline];
    Presence * presenceDND   = [[Presence alloc] initWithType:PresenceTypeDoNotDisturb];
    
    presenceDND.allowEditMessage = presenceOnline.allowEditMessage = NO;
    presenceAway.allowEditMessage = YES;
    
    presencesDictionary = @{
        PresenceTypeAway : presenceAway,
        PresenceTypeDoNotDisturb :presenceDND,
        PresenceTypeOnline : presenceOnline
    };
    
    displayString = @{
        @"online" : @"Online",
        @"dnd"    : @"Do Not Disturb",
        @"away"   : @"Away"
    };
    
}

//Init with default settings
- (instancetype)init{
    self = [super init];
    if (self) {
        [self loadDefaults];
    }
    return self;
}

- (NSString *) displayStringForType:(NSString *) type{
    return displayString[type];
}

- (NSString *)convertPresenceStatusForSubjectType:(NSString *)subjectType {
    
    NSString *presenseStatusText = nil;
    
    NSMutableCharacterSet * set = [NSMutableCharacterSet punctuationCharacterSet];
    [set addCharactersInString:@" "];
    
    NSArray * wordsArray = [subjectType componentsSeparatedByCharactersInSet:set];
    
    if ([wordsArray.firstObject isEqualToString:@"Presence"]) {
        
        NSString *presenceType = wordsArray.lastObject;
        
        NSString *presenseStatus = @"";
        
        if ([presenceType isEqualToString:@"0"]) {
            presenseStatus = @"online";
        }
        if ([presenceType isEqualToString:@"1"]) {
            presenseStatus = @"dnd";
        }
        if ([presenceType isEqualToString:@"2"]) {
            presenseStatus = @"away";
        }
        
        presenseStatusText = [NSString stringWithFormat:@"Presence Status: %@", presenseStatus];
    }
    
    return presenseStatusText;
}

- (NSArray *) types{
    return @[PresenceTypeOnline, PresenceTypeDoNotDisturb, PresenceTypeAway];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        presencesDictionary = [aDecoder decodeObjectForKey:@"presencesDictionary"];
        self.currentPresenceType = [aDecoder decodeObjectForKey:@"currentPresenceType"];
        self.prevPresenceType = [aDecoder decodeObjectForKey:@"prevPresenceType"];
        if (!self.currentPresenceType) self.currentPresenceType = PresenceTypeOnline;
        
        presencesDictionary = [presencesDictionary mutableCopy];
        
        displayString = @{
            @"online" : @"Online",
            @"dnd"    : @"Do Not Disturb",
            @"away"   : @"Away"
        };
        
        if ([[presencesDictionary allKeys] count] < 3){
             [self loadDefaults];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:presencesDictionary forKey:@"presencesDictionary"];
    [aCoder encodeObject:self.currentPresenceType forKey:@"currentPresenceType"];
    [aCoder encodeObject:self.prevPresenceType forKey:@"prevPresenceType"];
}

- (Presence *)presenceForType:(NSString *)type{
    return [presencesDictionary objectForKey:type];
}

- (void) setPresence:(Presence *) presence forType:(NSString *) type{
    NSMutableDictionary * mutablePresence = [presencesDictionary mutableCopy];
    mutablePresence[type] = presence;
    presencesDictionary = mutablePresence;
}


@end

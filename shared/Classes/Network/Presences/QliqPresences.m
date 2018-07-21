//
//  Presences.m
//  qliq
//
//  Created by Aleksey Garbarev on 19.12.12.
//
//

#import "QliqPresences.h"

#import "QliqUser.h"
#import "Presence.h"

@implementation QliqPresences{
    NSMutableDictionary * presences;
}

- (id)init{
    self = [super init];
    if (self) {
        presences = [NSMutableDictionary new];
    }
    return self;
}


- (void) setPresence:(Presence *) presence forUser:(QliqUser *) user{
    [presences setObject:presence forKey:user.qliqId];
}

- (Presence *) presenceForUser:(QliqUser *) user{
    return [presences objectForKey:user.qliqId];
}

- (Presence *) presenceForQliqId:(NSString *)qliqId{
    return [presences objectForKey:qliqId];
}

@end

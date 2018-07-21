//
//  Presences.h
//  qliq
//
//  Created by Aleksey Garbarev on 19.12.12.
//
//

#import <Foundation/Foundation.h>

@class Presence, QliqUser;

@interface QliqPresences : NSObject

- (void) setPresence:(Presence *) presence forUser:(QliqUser *) user;

- (Presence *) presenceForUser:(QliqUser *) user;

- (Presence *) presenceForQliqId:(NSString *)qliqId;
@end

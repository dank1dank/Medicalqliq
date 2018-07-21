//
//  SetPresenceStatus.h
//  qliq
//
//  Created by Ravi Ada on 12/10/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface SetPresenceStatusService : QliqAPIService

- (id) initWithPresence:(Presence *) presence ofType:(NSString *)presenceType;
- (id) initWithPresence:(QliqUser *) user;


@end

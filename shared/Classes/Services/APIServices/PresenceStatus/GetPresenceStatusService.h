//
//  GetPresenceStatus.h
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

#define kPresenceChangeStatusNotification @"PresenceChangeStatusNotification"
#define kPresenceChangeRequestSuccessNotification @"PresenceChangeRequestSuccessNotification"


@interface GetPresenceStatusService : QliqAPIService

@property (nonatomic, strong) NSString * reason;

- (id) initWithQliqId:(NSString *) qliqId;

+ (void) handlePayload:(NSDictionary *)payloadDict;

@end

//
//  QliqInvitationGroup.m
//  qliq
//
//  Created by Aleksey Garbarev on 18.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqInvitationGroup.h"

#import "InvitationService.h"

#import "UserSessionService.h"
#import "UserSession.h"


@implementation QliqInvitationGroup


- (NSString *)name{
    return @"Pending Invitations";
}

- (NSArray *)getSentInvitations{
    return [[InvitationService sharedService] getSentInvitations];
}

- (NSArray *)getReceivedInvitations{
    return [[InvitationService sharedService] getReceivedInvitations];
}

- (NSUInteger) getPendingCount{
    return [[InvitationService sharedService] getPendingInvitationCount];
}

@end

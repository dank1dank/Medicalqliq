//
//  InvitationService.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "Invitation.h"
#import "QliqUser.h"

extern NSString * InvitationServiceInvitationsChangedNotification;


@interface InvitationService : NSObject 

+ (InvitationService *) sharedService;

-(Invitation*) getInvitationWithUuid:(NSString *)invitationUuid;
-(NSArray*) getReceivedInvitations;
-(NSArray*) getSentInvitations;
-(int) getPendingInvitationCount;
-(BOOL) isInvitationExists:(Invitation*)invitation;

-(BOOL) saveInvitation:(Invitation*)invitation;
- (BOOL) deleteInvitation:(Invitation *) invitation;

@end

//
//  CreateInvitation.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqUser.h"

@class Invitation;

@protocol CreateInvitationDelegate <NSObject>


@end
//TODO: reimplement to use QliqAPIService
@interface InvitationAPIService : NSOperation
{
}

+ (InvitationAPIService *) sharedService;
+ (QliqUser *) createAndSaveInvitatedUserFromDict:(NSDictionary *) dataDict andContact:(Contact*)recipient;

- (void) inviteUser:(Contact *) recipient withReason:(NSString *)reason complete:(void (^)(NSError * error,Invitation * result))completeBlock;
- (void) inviteUser:(Contact *) recipient complete:(void(^)(NSError * error, Invitation * result))completeBlock;

- (void) acceptInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock;
- (void) declineInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock;
- (void) cancelInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock;
- (void) remindInvitation:(Invitation *) invitation complete:(void(^)(NSError * error))completeBlock;


@property (nonatomic, assign) id<CreateInvitationDelegate> delegate;

@end

//
//  InviteController.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Contact;
@class Invitation;

typedef enum {
    InvitationIsNotInPendingState = 103
} InviteErrorCode;

typedef NS_ENUM(NSInteger, InviteControllerState) {
    InviteControllerStateSuccess,
    InviteControllerStateCancelled,
    InviteControllerStateError,
    InviteControllerStateProgressChanged,
    InviteControllerStateProvideEmail,
    InviteControllerStateAlreadyInvited
};

@interface InviteController : NSObject

- (id)initFromViewController:(UIViewController *)viewController;
+ (id)inviteControllerFromViewController:(UIViewController *)viewController;

+ (NSString *)getInviteText;

- (void)inviteContact:(Contact *)contact withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error, Invitation *invitation))completeBlock;
- (void)inviteContact:(Contact *)contact withReason:(NSString *)invitationReason withCompletitionBlock:(void (^)(InviteControllerState, NSError *, Invitation *))completeBlock;

- (void)cancelInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error))completeBlock;
- (void)remindInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error))completeBlock;
- (void)acceptInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error))completeBlock;
- (void)declineInvitation:(Invitation *)invitation withCompletitionBlock:(void(^)(InviteControllerState state, NSError *error))completeBlock;

@end

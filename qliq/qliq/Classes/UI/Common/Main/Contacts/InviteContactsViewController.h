//
//  InviteContactsViewController.h
//  qliq
//
//  Created by Valeriy Lider on 11.11.14.
//
//

#import <UIKit/UIKit.h>

#define kInviteControllerDidInvitedContactNotificationName  @"InviteControllerDidInvitedContactNotification"

typedef enum {
    CanNotBeInvitedDefaultReason = 0,
    CanNotBeInvitedAsUserCancelledAction,
    CanNotBeInvitedAsContactIsAlreadyInvited,
    CanNotBeInvitedAsContactIsAlreadyAContact,
    CanNotBeInvitedAsContactRecordIncomplete,
    CanNotBeInvitedDueToDeviceCapabilities,
    CanBeInvited = 10
} CanNotBeInvitedReason;

@class Invitation;
@class Contact;

@interface InviteContactsViewController : UIViewController

//UI
@property (weak, nonatomic) IBOutlet UITextField *inputField;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

/*
 * initForViewController should be called when we calling invitation from other controllers without showing InviteViewController
 */
- (instancetype)initForViewController:(UIViewController *)controller;

/*
 * Calling this method will initiate all necessary checks and only if passed then creates invitation
 */
- (void)inviteContact:(Contact *)contact isAddressBookContact:(BOOL)checkAddressBook completionBlock:(void (^)(Invitation *invitation, NSError *error))completionBlock;

@end

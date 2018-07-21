//
//  LoginViewController.h
//  qliq
//
//  Created by Paul Bar on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "UserSessionService.h"
#import "QliqLoginViewControllerDelegate.h"
#import "PinEnteringViewController.h"
#import "SetUpNewPinQuestionViewController.h"
#import "LoginWithPasswordViewController.h"
#import "PasswordChangeViewController.h"
#import "FailedAttemptsController.h"

@interface LoginViewController : QliqBaseViewController

@property (nonatomic, weak) id<QliqLoginViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL changesRightNavigationItem;
@property (nonatomic, assign) BOOL shouldCheckForLocking;
@property (nonatomic, assign) BOOL shouldSkipAutoLogin;
@property (nonatomic, strong) LoginWithPasswordViewController *loginWithPasswordViewController;
@property (nonatomic, strong) PinEnteringViewController *pinEnteringViewController;
@property (nonatomic, strong) PasswordChangeViewController *passwordChangeViewController;
@property (nonatomic, strong) FailedAttemptsController * failedAttemptsController;

- (void)processLoginForUser:(NSString *)username withPassword:(NSString *)password isAutoLogin:(BOOL)isAutoLogin forceLocalLogin:(BOOL)forceLocal;

// Made public for LockViewController
- (void)loginFailedWithInvalidCredentials;

@end

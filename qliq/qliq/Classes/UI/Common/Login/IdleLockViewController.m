//
//  IdleLockViewController.m
//  qliq
//
//  Created by Valerii Lider on 01/10/15.
//
//

#import "IdleLockViewController.h"

#import "EnterPassContainerView.h"
#import "EnterPinContainerView.h"

#import "Login.h"
#import "AppDelegate.h"
#import "IdleEventController.h"

#import "KeychainService.h"
#import "UIDevice-Hardware.h"

#import <LocalAuthentication/LocalAuthentication.h>
#import <AudioToolbox/AudioServices.h>

#import "ChatMessage.h"
#import "ResizeBadge.h"

#define kBadgeMargin 2.f

@interface IdleLockViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *enterPasswordContainerView;
@property (weak, nonatomic) IBOutlet UIView *enterPinContainerView;

@property (weak, nonatomic) EnterPassContainerView *enterPasswordVc;
@property (weak, nonatomic) EnterPinContainerView *enterPinViewVc;

@property (assign, nonatomic) StartViewType currentStartViewType;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterPinViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterPasswordViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterPinViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterPasswordViewBottomConstraint;


@end

@implementation IdleLockViewController

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.enterPinViewVc = nil;
    self.enterPasswordVc = nil;
    self.enterPasswordContainerView = nil;
    self.enterPinContainerView = nil;
    self.currentStartViewType = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.enterPinViewTopConstraint.constant = weakSelf.enterPinViewTopConstraint.constant - 44.0f;
            weakSelf.enterPinViewBottomConstraint.constant = weakSelf.enterPinViewBottomConstraint.constant - 35.0f;
            weakSelf.enterPasswordViewTopConstraint.constant = weakSelf.enterPasswordViewTopConstraint.constant - 44.0f;
            weakSelf.enterPasswordViewBottomConstraint.constant = weakSelf.enterPasswordViewBottomConstraint.constant - 35.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });
    
    //Get Controllers from childViewControllers and configure
    [self configureChildViewControllers];
    
    //Which view should show
    [self chooseContainerView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateChatBadgeNumber:)
                                                 name:ChatBadgeValueNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboardWithSSLAlert:)
                                                 name:kHideKeyboardOnIdleLockWithSSLAlertNotificaiton
                                               object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    StartViewType type = [[Login sharedService] showStartViewForIdleLock];
    
    if (type == StartViewTypeEnterPin && ![[Login sharedService] shouldAutoLogin]) {
        [self touchIdVerification];
    }
}

- (void)willEnterForeground {
    StartViewType type = [[Login sharedService] showStartViewForIdleLock];
    if (type == StartViewTypeEnterPin) {
        [self touchIdVerification];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private -

- (void)configureChildViewControllers
{
    
    for (UIViewController *controller in self.childViewControllers)
    {
        if ([controller isKindOfClass:[EnterPassContainerView class]]) {
            
            self.enterPasswordVc = (EnterPassContainerView *)controller;
            self.enterPasswordVc.emailTextField.delegate = self;
            self.enterPasswordVc.passTextField.delegate = self;
            self.enterPasswordVc.typeLabel.text = QliqLocalizedString(@"2317-TitleIdleLock");
            
            [self.enterPasswordVc updateTypeLableSize];
            
            [self.enterPasswordVc.signInButton addTarget:self
                                                  action:@selector(onLoginEnterPassword)
                                        forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPasswordVc.createAccountButton addTarget:self
                                                         action:@selector(onRegister)
                                               forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPasswordVc.forgotPasswordButton addTarget:self
                                                          action:@selector(onForgotPassword)
                                                forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPasswordVc.switchUserButton addTarget:self
                                                      action:@selector(onSwitchUser)
                                            forControlEvents:UIControlEventTouchUpInside];
        }
        else if ([controller isKindOfClass:[EnterPinContainerView class]])
        {
            
            self.enterPinViewVc = (EnterPinContainerView *)controller;
            self.enterPinViewVc.typeLabel.text = QliqLocalizedString(@"2317-TitleIdleLock");
            [self.enterPinViewVc updateTypeLableSize];
                    
            [self.enterPinViewVc.switchUserButton addTarget:self
                                                     action:@selector(onSwitchUser)
                                           forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)chooseContainerView
{
    self.currentStartViewType = [[Login sharedService] showStartViewForIdleLock];
    
    [self updateChatBadgeNumber:nil];
    
    self.enterPasswordContainerView.hidden = !(self.currentStartViewType == StartViewTypeEnterPassword);
    self.enterPinContainerView.hidden = !(self.currentStartViewType == StartViewTypeEnterPin);
    
    
    if (self.currentStartViewType == StartViewTypeEnterPassword) {
        [self.enterPasswordVc configureHeaderWithUser:[Login sharedService].lastLoggedUser
                                             andGroup:[Login sharedService].lastLoggedUserGroup];
        
        self.enterPasswordVc.emailTextField.text = [Login sharedService].lastLoggedUser.email;
        [self.enterPasswordVc.passTextField becomeFirstResponder];
    }
    else if (self.currentStartViewType == StartViewTypeEnterPin) {
        
        [self.enterPinViewVc showHeaderWithContact:[Login sharedService].lastLoggedUser
                                          andGroup:[Login sharedService].lastLoggedUserGroup];
    }
    else {
        [self.enterPasswordVc configureHeaderWithUser:[Login sharedService].lastLoggedUser
                                             andGroup:[Login sharedService].lastLoggedUserGroup];
        
        self.enterPasswordVc.emailTextField.text = [Login sharedService].lastLoggedUser.email;
        [self.enterPasswordVc.passTextField becomeFirstResponder];
    }
}

- (void)alertWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                        otherButtonTitles: nil];
    [alert showWithDissmissBlock:NULL];
}

#pragma mark * Private EnterPassword

- (void)resignEnterPasswordAllFirstResponders
{
    [self.enterPasswordVc.emailTextField resignFirstResponder];
    [self.enterPasswordVc.passTextField resignFirstResponder];
}

- (void)maskPassword:(BOOL)isMasked
{
    self.enterPasswordVc.passTextField.secureTextEntry = isMasked;
}

- (void)resetFields
{
    [self.enterPasswordVc.emailTextField becomeFirstResponder];
    self.enterPasswordVc.passTextField.text = @"";
}

- (void)focusPassword
{
    [self.enterPasswordVc.passTextField becomeFirstResponder];
}

- (void)alertFailLogInWithReason:(NSString *)reason
{
    [[[UIAlertView_Blocks alloc] initWithTitle:nil
                                       message:reason
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                             otherButtonTitles:nil]
     showWithDissmissBlock:^(NSInteger buttonIndex){
         
         [self resetFields];
         [self maskPassword:NO];
     }];
}

#pragma mark * Private EnterPin

- (void)touchIdVerification
{
    [Login touchIdVerification:^(BOOL success, NSError *error) {
        if (success) {
            performBlockInMainThread(^{
                DDLogSupport(@"User is authenticated by Touch ID successfully");
                
                [[Login sharedService].failedAttemptsController clear];
                
                [appDelegate.idleController unlockIdle];
            });
        }
    }];
}

- (void)didEnterWrongPin
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [self resetPinView];
}

- (void)resetPinView
{
    [self.enterPinViewVc resetPinView];
}

- (void)enterPin:(NSString *)pin
{
    //check pin
    NSString *enteredPin_b64 = [[KeychainService sharedService] stringToBase64:pin];
    
    if([enteredPin_b64 isEqualToString:[[KeychainService sharedService] getPin]])
    {
        if ([[Login sharedService].failedAttemptsController isLocked]) {
            [self logoutWithStartViewType:StartViewTypeNone];
        }
        else {
            [[Login sharedService].failedAttemptsController clear];
            [appDelegate.idleController unlockIdle];
        }
    }
    else
    {
        [[Login sharedService] loginFailedWithInvalidCredentials];
        if (![[Login sharedService].failedAttemptsController isLocked]) {
            
            [self didEnterWrongPin];
            
            QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:YES];
            [alertView setContainerViewWithImage:nil
                                       withTitle:NSLocalizedString(@"1090-TextAskForgotPIN", nil)
                                        withText:NSLocalizedString(@"1091-TextTryLoggingWithPassword", nil)
                                    withDelegate:nil
                                useMotionEffects:YES];
            [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"19-ButtonTryPassword", nil), NSLocalizedString(@"20-ButtonRetryPIN", nil), nil]];
            [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
                
                if (buttonIndex == 0) {
                    [self tryPassword];
                }
                else if (buttonIndex == 1) {
                    if ([Login sharedService].failedAttemptsController.countFailedAttempts > 1) {
                        [self logoutWithStartViewType:StartViewTypeNone];
                    }
                }
            }];
            [alertView show];
        }
        else {
            [self logoutWithStartViewType:StartViewTypeNone];
        }
    }
}

#pragma mark - Actions -

- (void)hideKeyboardWithSSLAlert:(NSNotification *)notification
{
    if (!self.enterPasswordVc.view.hidden)
    {
        [self.enterPasswordVc.passTextField resignFirstResponder];
        [self.enterPasswordVc.emailTextField resignFirstResponder];
    }
}

- (void)updateChatBadgeNumber:(NSNotification *)notif {
    
    __block NSInteger unreadMessageCount = 0;
    __weak __block typeof(self) welf = self;
    
    void (^updateBadgeBlock)(void) = ^{
        
        void (^configureBadge)(UILabel *badgeLabel, CGFloat totalFreeSpace, NSLayoutConstraint *widthConstraint, NSLayoutConstraint *shiftConstraint) = ^(UILabel *badgeLabel, CGFloat totalFreeSpace, NSLayoutConstraint *widthConstraint, NSLayoutConstraint *shiftConstraint){
            
            badgeLabel.text    = [NSString stringWithFormat:@"%ld", (long)unreadMessageCount];
            badgeLabel.hidden  = unreadMessageCount == 0 ? YES : NO;
            
            if (!badgeLabel.hidden)
            {
                //Configure badge with for new text (calculating width badge, changing value of `badgeLabel.text` if needed).
                [ResizeBadge resizeBadge:badgeLabel
                          totalFreeSpace:totalFreeSpace
                         canTextBeScaled:NO
                 setBadgeWidthCompletion:^(CGFloat calculatedWidth) {
                    //Method for setting width of badge and calculating shift and badgeLabel.
                    [welf setBadgeWidth:calculatedWidth forBadgeLabel:badgeLabel configureWidthConstraint:widthConstraint configureShiftConstraint:shiftConstraint];
                }];
            }
            DDLogSupport(@"Recents Badge Value: %ld", (long)unreadMessageCount);
        };
        
        if (self.currentStartViewType == StartViewTypeEnterPassword)
        {
            configureBadge(self.enterPasswordVc.badgeLabel, self.enterPasswordVc.totalFreeSpaceForBadgeLabel,  self.enterPasswordVc.badgeLabelWidthConstraint, self.enterPasswordVc.badgeLabelLeadingConstraint);
        }
        else if (self.currentStartViewType == StartViewTypeEnterPin)
        {
            configureBadge(self.enterPinViewVc.badgeLabel, self.enterPinViewVc.totalFreeSpaceForBadgeLabel, self.enterPinViewVc.badgeLabelWidthConstraint, self.enterPinViewVc.badgeLabelLeadingConstraint);
        }
        else
        {
            self.enterPasswordVc.badgeLabel.hidden = YES;
            self.enterPinViewVc.badgeLabel.hidden = YES;
        }
    };
    
    if (notif.userInfo[@"newBadgeValue"])
    {
        unreadMessageCount = [notif.userInfo[@"newBadgeValue"] integerValue];
        updateBadgeBlock();
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            unreadMessageCount = [ChatMessage unreadMessagesCount];
            dispatch_async_main(^{
                updateBadgeBlock();
            });
        });
    }
}

- (void)setBadgeWidth:(CGFloat)calculatedWidth
                 forBadgeLabel:(UILabel *)badgeLabel
            configureWidthConstraint:(NSLayoutConstraint *)widthConstraint
            configureShiftConstraint:(NSLayoutConstraint *)shiftConstraint
{
    [UIView animateWithDuration:0.25f animations:^{
        widthConstraint.constant = calculatedWidth;
        shiftConstraint.constant = kBadgeMargin;
        [badgeLabel.superview layoutSubviews];
    }];
}

- (void)onLoginEnterPassword
{
    [self resignEnterPasswordAllFirstResponders];
    
    NSString *email = self.enterPasswordVc.emailTextField.text;
    NSString *password = self.enterPasswordVc.passTextField.text;
    
    if (!email.length) {
        [self alertFailLogInWithReason:NSLocalizedString(@"1087-TextEmailCannotBeEmpty", nil)];
        return;
    }
    else if (!isValidEmail(email))
    {
        [self alertFailLogInWithReason:NSLocalizedString(@"1088-TextIsNotValidEmailAddress", nil)];
        return;
    }
    else if (!password.length) {
        [self alertFailLogInWithReason:NSLocalizedString(@"1089-TextPasswordCannotBeEmpty", nil)];
        return;
    }
    
    NSString *sessionUsername = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *storedPassword_b64 = [[KeychainService sharedService] getPassword];
    NSString *enteredPassword_b64 = [[KeychainService sharedService] stringToBase64:password];
    
    if([email isEqualToString:sessionUsername] &&
       [enteredPassword_b64 isEqualToString:storedPassword_b64])
    {
        if ([[Login sharedService].failedAttemptsController isLocked]) {
            [self logoutWithStartViewType:StartViewTypeNone];
        }
        else {
            [[Login sharedService].failedAttemptsController clear];
            [self maskPassword:YES];
            [appDelegate.idleController unlockIdle];
        }
    }
    else
    {
        [[Login sharedService] loginFailedWithInvalidCredentials];
        if (![[Login sharedService].failedAttemptsController isLocked]) {
           
            [self maskPassword:NO];
            [self focusPassword];

            UIAlertView_Blocks *alert =
            [[UIAlertView_Blocks alloc]
             initWithTitle:NSLocalizedString(@"1092-TextCan'tUnlockApp", nil)
             message:NSLocalizedString(@"1093-TextInvalidEmail/Password", nil)
             delegate:nil
             cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
             otherButtonTitles: nil];
            
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                if ([Login sharedService].failedAttemptsController.countFailedAttempts > 1) {
                    [self logoutWithStartViewType:StartViewTypeNone];
                }
            }];
        }
        else {
            [self logoutWithStartViewType:StartViewTypeNone];
        }
    }
}

- (void)tryPassword {
    [self logoutWithStartViewType:StartViewTypeEnterPassword];
}

- (void)onRegister {
    [self logoutWithStartViewType:StartViewTypeCreateAccount];
}

- (void)onForgotPassword {
    [self logoutWithStartViewType:StartViewTypeForgotPassword];
}

- (void)onSwitchUser {
    [self logoutWithStartViewType:StartViewTypeSwitchUser];
}

- (void)logoutWithStartViewType:(StartViewType)type
{
    [Login sharedService].shouldStartView = type;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[Login sharedService] startLogoutWithCompletition:nil];
    });
}

#pragma mark - Textfied Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onLoginEnterPassword];
    return YES;
}

@end

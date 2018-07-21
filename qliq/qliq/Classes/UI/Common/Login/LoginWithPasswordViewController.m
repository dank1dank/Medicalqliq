//
//  LoginViewController.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "LoginWithPasswordViewController.h"

#import "LoginWithPinViewController.h"
#import "RegisterUserWebViewViewController.h"
#import "SwitchUserViewController.h"

#import "EnterPassContainerView.h"
#import "SetNewPassContainerView.h"
#import "SetupNewPinQuestionViewController.h"
#import "ResetPasswordController.h"
#import "UIDevice-Hardware.h"
#import "AlertController.h"

#import "Login.h"
#import "QliqGroup.h"

#import "IdleEventController.h"

#import "KeychainService.h"

typedef NS_ENUM (NSInteger, PassMode) {
    PassModeNew,
    PassModeEnter
};

@interface LoginWithPasswordViewController () <LoginDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *setNewPassView;
@property (weak, nonatomic) IBOutlet UIView *enterPassView;
@property (weak, nonatomic) SetNewPassContainerView *setNewPassContainer;
@property (weak, nonatomic) EnterPassContainerView *enterPassContainer;

@property (nonatomic, assign) PassMode currentPassMode;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;

@end

@implementation LoginWithPasswordViewController

- (void)dealloc
{
    self.enterPassView = nil;
    self.enterPassContainer = nil;
    self.setNewPassView = nil;
    self.setNewPassContainer = nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.backgroundViewBottomConstraint.constant = weakSelf.backgroundViewBottomConstraint.constant -35.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });

    for (UIViewController *item in self.childViewControllers)
    {
        //SetNewPassContainerView
        if ([item isKindOfClass:[SetNewPassContainerView class]])
        {
            self.setNewPassContainer = (SetNewPassContainerView*)item;
            self.setNewPassContainer.emailTextField.delegate = self;
            self.setNewPassContainer.passTextField.delegate = self;
            
            [self.setNewPassContainer.signInButton addTarget:self
                                                      action:@selector(onLoginButton:)
                                            forControlEvents:UIControlEventTouchUpInside];
            
            [self.setNewPassContainer.createAccountButton addTarget:self
                                                             action:@selector(onRegisterButton:)
                                                   forControlEvents:UIControlEventTouchUpInside];
            
            [self.setNewPassContainer.forgotPasswordButton addTarget:self
                                                              action:@selector(onForgotPasswordButton:)
                                                    forControlEvents:UIControlEventTouchUpInside];
        }
        
        //EnterPassContainerView
        if ([item isKindOfClass:[EnterPassContainerView class]])
        {
            self.enterPassContainer = (EnterPassContainerView*)item;
            self.enterPassContainer.emailTextField.delegate = self;
            self.enterPassContainer.passTextField.delegate = self;
            self.enterPassContainer.typeLabel.text = QliqLocalizedString(@"2303-TitleLogin");
            
            self.enterPassContainer.badgeLabel.hidden = YES;
            
            [self.enterPassContainer.signInButton addTarget:self
                                                     action:@selector(onLoginButton:)
                                           forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPassContainer.createAccountButton addTarget:self
                                                            action:@selector(onRegisterButton:)
                                                  forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPassContainer.forgotPasswordButton addTarget:self
                                                             action:@selector(onForgotPasswordButton:)
                                                   forControlEvents:UIControlEventTouchUpInside];
            
            [self.enterPassContainer.switchUserButton addTarget:self
                                                         action:@selector(onSwitchUser:)
                                               forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    
    switch (self.startType) {
        case StartLoginWithPasswordWithCreateAccount: {
            
            RegisterUserWebViewViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([RegisterUserWebViewViewController class])];
            [self.navigationController pushViewController:controller animated:NO];
            
            break;
        }
        case StartLoginWithPasswordWithForgotPassword: {
            
            ResetPasswordController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ResetPasswordController class])];
            controller.email = [Login sharedService].lastLoggedUser.email;
            [self.navigationController pushViewController:controller animated:NO];
            
            break;
        }
        case StartLoginWithPasswordNone:
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //Setup Controller
    [self.navigationController setToolbarHidden:YES];

    
    [Login sharedService].delegate = self;
    
    if ([Login sharedService].lastLoggedUser)
    {
        self.enterPassView.hidden = NO;
        self.setNewPassView.hidden = YES;
        
        [self.enterPassContainer configureHeaderWithUser:[Login sharedService].lastLoggedUser
                                                andGroup:[Login sharedService].lastLoggedUserGroup];
        
        self.enterPassContainer.emailTextField.text = [Login sharedService].lastLoggedUser.email;
        [self.enterPassContainer.passTextField becomeFirstResponder];
    }
    else
    {
        self.enterPassView.hidden = YES;
        self.setNewPassView.hidden = NO;
        
        [self.setNewPassContainer.emailTextField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self resignAllFirstResponders];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Getters

- (PassMode)currentPassMode {
    return self.setNewPassView.hidden ? PassModeEnter : PassModeNew;
}

#pragma mark - Private

- (void)resetFields
{
    switch (self.currentPassMode) {
        case PassModeNew: {
            self.setNewPassContainer.passTextField.text = @"";
            [self.setNewPassContainer.emailTextField becomeFirstResponder];
            break;
        }
        case PassModeEnter: {
            self.enterPassContainer.passTextField.text = @"";
            [self.enterPassContainer.emailTextField becomeFirstResponder];
            break;
        }
        default:
            break;
    }
}

- (void)focusPassword
{
    switch (self.currentPassMode)
    {
        case PassModeNew: {
            [self.setNewPassContainer.passTextField becomeFirstResponder];
            break;
        }
        case PassModeEnter: {
            [self.enterPassContainer.passTextField becomeFirstResponder];
            break;
        }
        default:
            break;
    }
}

- (void)maskPassword:(BOOL)isMasked
{
    switch (self.currentPassMode)
    {
        case PassModeNew: {
            self.setNewPassContainer.passTextField.secureTextEntry = isMasked;
            break;
        }
        case PassModeEnter: {
            self.enterPassContainer.passTextField.secureTextEntry = isMasked;
            break;
        }
        default:
            break;
    }
}

- (void)resignAllFirstResponders
{
    [self.enterPassContainer.emailTextField resignFirstResponder];
    [self.enterPassContainer.passTextField resignFirstResponder];
    [self.setNewPassContainer.emailTextField resignFirstResponder];
    [self.setNewPassContainer.passTextField resignFirstResponder];
}

#pragma mark -

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notifications {
    if (appDelegate.appLaunchedWithVoIPPush)
    {
        appDelegate.appLaunchedWithVoIPPush = NO;
        DDLogSupport(@"appLaunchedWithVoIPPush --> handleApplicationDidBecomeActive --> Try to Autologin");
        [[Login sharedService] tryAutologinOrPreopenDB];
    }
}


#pragma mark - Alerts

- (void)alertInvalidLogin:(NSString*)title message:(NSString*)message email:(NSString*) email
{
    UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                   message:message
                                                                  delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"28-ButtonRetry", nil)
                                                         otherButtonTitles:NSLocalizedString(@"29-ButtonForgotPassword", nil), nil];
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        // code to take action depending on the value of buttonIndex
        if (buttonIndex != alert.cancelButtonIndex)
        {
            NSLog(@"Forgot password pressed: %ld",(long)buttonIndex);
            
            ResetPasswordController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ResetPasswordController class])];
            controller.email = email;
            [self.navigationController pushViewController:controller animated:YES];
        }
        else {
            [self maskPassword:NO];
        }
    }];
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

#pragma mark - Action -
/*
 manual login
 */
- (void)onLoginButton:(id)sender
{
    [self resignAllFirstResponders];
    
    NSString *email = @"";
    NSString *pass = @"";
    
    switch (self.currentPassMode)
    {
        case PassModeNew: {
            email = self.setNewPassContainer.emailTextField.text;
            pass = self.setNewPassContainer.passTextField.text;
            break;
        }
        case PassModeEnter: {
            email = self.enterPassContainer.emailTextField.text;
            pass = self.enterPassContainer.passTextField.text;
            break;
        }
        default:
            break;
    }
    
    BOOL emailEmpty = !email.length;
    BOOL passEmpty = !pass.length;
    
    if (emailEmpty) {
        [self alertFailLogInWithReason:NSLocalizedString(@"1087-TextEmailCannotBeEmpty", nil)];
        return;
    }
    
    if (!isValidEmail(email))
    {
        if (isValidPhone(email) && email.length >= 10) {
            email = [email stringByAppendingString:@"@qliq.com"];
        } else {
            [self alertFailLogInWithReason:NSLocalizedString(@"1088-TextIsNotValidEmailAddress", nil)];
            return;
        }
    }
    
    if (passEmpty) {
        [self alertFailLogInWithReason:NSLocalizedString(@"1089-TextPasswordCannotBeEmpty", nil)];
        return;
    }
    
    [[Login sharedService] startManualLoginWithUsername:email password:pass];
}

- (void)onRegisterButton:(UIButton *)button
{
    RegisterUserWebViewViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([RegisterUserWebViewViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)onForgotPasswordButton:(id)sender
{
    ResetPasswordController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ResetPasswordController class])];
    
    NSString *email = nil;
    
    if (self.currentPassMode == PassModeNew) {
        email = self.setNewPassContainer.emailTextField.text;
    }
    else if (self.currentPassMode == PassModeEnter) {
        email = self.enterPassContainer.emailTextField.text;
    }
    
    if (email == nil || email.length == 0) {
        [self alertFailLogInWithReason:NSLocalizedString(@"1087-TextEmailCannotBeEmpty", nil)];
        return;
    }
    
    if (!isValidEmail(email))
    {
        if (isValidPhone(email) && email.length >= 10) {
            email = [email stringByAppendingString:@"@qliq.com"];
        } else {
            [self alertFailLogInWithReason:NSLocalizedString(@"1088-TextIsNotValidEmailAddress", nil)];
            return;
        }
        
    }
    
    controller.email = email;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)onSwitchUser:(id)sender
{
    SwitchUserViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SwitchUserViewController class])];
    controller.hiddeBackButton = NO;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Delegates -

#pragma mark * Login Delegate

- (void)loginWithPin
{
    LoginWithPinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPinViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)loginNewPinQuestion
{
    SetupNewPinQuestionViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SetupNewPinQuestionViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)loginIsSuccessful:(id)result
{
    
    
    //check for temp_password field. If =1 then present password change view
    NSNumber *isTempPassword = result[kLoginResponseShowResetPasswordAlertKey];
    
    if (isTempPassword && [isTempPassword isKindOfClass:[NSNumber class]] && ([isTempPassword boolValue]))
    {
        DDLogSupport(@"Logged in with Temporary Password");
        
        [SVProgressHUD dismiss];
        
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1121-TextLoggedTemporaryPassword", nil)
                                                                      message:NSLocalizedString(@"1122-TextYouLoggedWithAdminPassword", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"30-ButtonSetNewPassword", nil)
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
//            SetupNewPinQuestionViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SetupNewPinQuestionViewController class])];
//            [self.navigationController pushViewController:controller animated:YES];
//
        }];
        return;
    }
}

- (void)loginError:(NSError *)error title:(NSString *)title message:(NSString *)message
{
    DDLogSupport(@"login request error: %@",error);
    [SVProgressHUD dismiss];
    [Login sharedService].isLoginRunning = NO;
    [self resetFields];
    
    if((title.length || message.length) && !error.code)
    {
        [AlertController showAlertWithTitle:title
                                    message:message
                                buttonTitle:nil
                          cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                 completion:nil];
        return;
    }
    else if (!error && !title && !message)
        return;


    switch (error.code)
    {
        case ErrorCodeInvalidRequest: {
            
            // Incompatable: upgrade, cancel
            UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1123-TextVersionIncompatibility", nil)
                                                                           message:NSLocalizedString(@"1124-TextPleaseUpgradeApp", nil)
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                                 otherButtonTitles:NSLocalizedString(@"31-ButtonUpgrade", nil), nil];
            
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                if (alert.cancelButtonIndex != buttonIndex)
                    [appDelegate getNewVersion];
            }];
            
            break;
        }
        case ErrorCodeAccessDenied: {
            DDLogSupport(@"Login failed because Access denied from this device");
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1125-TextAccessBlocked")
                                        message:[error localizedDescription]
                                    buttonTitle:nil
                              cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                     completion:nil];
            
            break;
        }
        case ErrorCodeLoginInvalidCredentials: {
            DDLogSupport(@"Login (or idle unlock) failed because password or pin is wrong");
            
            //APIN
            [[Login sharedService] loginFailedWithInvalidCredentials];
            
            NSString *email = self.setNewPassView.hidden ? self.enterPassContainer.emailTextField.text
                                                         : self.setNewPassContainer.emailTextField.text;
            
            if (![[Login sharedService].failedAttemptsController isLocked]) {
                [self alertInvalidLogin:QliqLocalizedString(@"1126-TextLoginFailed")
                                message:QliqFormatLocalizedString1(@"3041-TextFrom{Email}incorrectEmailOrPassword", email)
                                  email:email];
            }
            else {
                
                [self.navigationController popToRootViewControllerAnimated:YES];
            } 
            break;
        }
        case ErrorCodeLoginClientHasOldVersion: {
            
            UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1127-TextUnsupportedVersion", nil)
                                                                           message:NSLocalizedString(@"1128-TextAppVersionNotSupported", nil)
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"32-ButtonUpgradeNow", nil)
                                                                 otherButtonTitles:nil];
            
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                [appDelegate getNewVersion];
            }];
            
            break;
        }
        case ErrorCodeLoginServerSideProblem: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1129-TextServerError")
                                        message:QliqLocalizedString(@"1130-TextPleaseContactqliqSOFT")
                                    buttonTitle:nil
                              cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                     completion:nil];
            break;
        }
        case ErrorCodeLoginServerIsBeingUpgraded: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1131-TextServerUpgrade")
                                        message:QliqLocalizedString(@"1132-TextQliqSOFTCloudServerUpgraded")
                                    buttonTitle:nil
                              cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                     completion:nil];
            break;
        }
        case 123123: {
            
            __weak __block typeof(self) welf = self;
            
            dispatch_async_main(^{
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"2355-TitleDBCannotBeOpened")
                                            message:nil
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:^(NSUInteger buttonIndex) {
                                             [welf.navigationController popToRootViewControllerAnimated:NO];
                                         }];
            });
            
            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            break;
        }
        default: {
            
             if (isSSLErrorCode(error.code))
             {
                 [AlertController showAlertWithTitle:QliqLocalizedString(@"1134-TextSSLConnectionError")
                                             message:QliqLocalizedString(@"1133-TextInstructionInternetConnection")
                                         buttonTitle:nil
                                   cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                          completion:nil];
            }
            else if (isNetworkErrorCode(error.code))
            {
                NSString *email = self.setNewPassView.hidden ? self.enterPassContainer.emailTextField.text
                                                             : self.setNewPassContainer.emailTextField.text;
                NSString *pass = self.setNewPassView.hidden ? self.enterPassContainer.passTextField.text
                                                            : self.setNewPassContainer.passTextField.text;
                
                if (![[Login sharedService] localLogin:email password:pass error:&error]) {
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1135-TextLoginError")
                                                message:[error localizedDescription]
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:nil];
                }
            }
            else
            {
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1136-TextGeneralError")
                                            message:[error localizedDescription]
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:nil];
            }
            
            break;
        }
    }
}

#pragma mark * TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onLoginButton:nil];
    return YES;
}

@end

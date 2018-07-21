//
//  SwitchUserViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/28/14.
//
//

#import "SwitchUserViewController.h"

#import "LoginWithPinViewController.h"
#import "SetupNewPinQuestionViewController.h"
#import "ResetPasswordController.h"
#import "Login.h"
#import "KeychainService.h"
#import "UIDevice-Hardware.h"
#import "AlertController.h"

#import "IdleEventController.h"

#define kValueBackArrowWidthConstraint 13.f

@interface SwitchUserViewController () <UITextFieldDelegate, LoginDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *avatar1ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *avatar2ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *avatar3ImageView;

@property (nonatomic, weak) IBOutlet UIImageView *avatarBorder1ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *avatarBorder2ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *avatarBorder3ImageView;

@property (nonatomic, weak) IBOutlet UILabel *username1ImageView;
@property (nonatomic, weak) IBOutlet UILabel *username2ImageView;
@property (nonatomic, weak) IBOutlet UILabel *username3ImageView;

@property (nonatomic, weak) IBOutlet UILabel *noAvatar1Label;
@property (nonatomic, weak) IBOutlet UILabel *noAvatar2Label;
@property (nonatomic, weak) IBOutlet UILabel *noAvatar3Label;

@property (nonatomic, weak) IBOutlet UIImageView *loginBorderImageView;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *passTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backArrowWidthConstraint;
/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;


@end

@implementation SwitchUserViewController

- (void)dealloc
{
    self.avatar1ImageView = nil;
    self.avatar2ImageView = nil;
    self.avatar3ImageView = nil;
    self.avatarBorder1ImageView = nil;
    self.avatarBorder2ImageView = nil;
    self.avatarBorder3ImageView = nil;
    self.username1ImageView = nil;
    self.username2ImageView = nil;
    self.username3ImageView = nil;
    self.loginBorderImageView = nil;
    self.emailTextField = nil;
    self.passTextField = nil;
    self.backButton = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)configureDefaultText {
    self.emailTextField.placeholder = QliqLocalizedString(@"2304-TitleEmailPlaceholder");
    self.passTextField.placeholder = QliqLocalizedString(@"2305-TitlePasswordPlaceholder");
    [self.loginButton setTitle:QliqLocalizedString(@"2303-TitleLogin") forState:UIControlStateNormal];
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
    
    [self.view setNeedsLayout];
    
    [Login sharedService].delegate = self;
    
    self.backArrowWidthConstraint.constant = self.hiddeBackButton ? 0.f : kValueBackArrowWidthConstraint;
    self.backButton.hidden = self.hiddeBackButton;
    
    [self.emailTextField setTintColor:[UIColor whiteColor]];
    [self.passTextField setTintColor:[UIColor whiteColor]];
    
    NSMutableArray *lastUSers = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LAST_USERS"] mutableCopy];

    if (lastUSers.count >= 1)
    {
        self.username1ImageView.text    = lastUSers[0][@"name"];
        self.emailTextField.text        = lastUSers[0][@"email"];
        
        if (lastUSers[0][@"avatar"])
        {
            self.avatar1ImageView.image = [NSKeyedUnarchiver unarchiveObjectWithData:lastUSers[0][@"avatar"]];
            self.noAvatar1Label.text = @"";
        }
        else if (self.username1ImageView.text.length)
        {
            NSString *firstCharacter = [self.username1ImageView.text substringToIndex:1];
            self.noAvatar1Label.text                = firstCharacter;
            self.noAvatar1Label.layer.borderWidth   = 1.;
            self.noAvatar1Label.layer.borderColor   = [UIColor whiteColor].CGColor;
            
            self.avatar1ImageView.image = nil;
        }
    }
    
    if (lastUSers.count >= 2 )
    {
        self.username2ImageView.text    = lastUSers[1][@"name"];
//        self.emailTextField.text        = lastUSers[1][@"email"];
        
        if (lastUSers[1][@"avatar"])
        {
            self.avatar2ImageView.image = [NSKeyedUnarchiver unarchiveObjectWithData:lastUSers[1][@"avatar"]];
            self.noAvatar2Label.text = @"";
        }
        else if (self.username2ImageView.text.length)
        {
            NSString *firstCharacter = [self.username2ImageView.text substringToIndex:1];
            self.noAvatar2Label.text                = firstCharacter;
            self.noAvatar2Label.layer.borderWidth   = 1.;
            self.noAvatar2Label.layer.borderColor   = [UIColor whiteColor].CGColor;

            self.avatar2ImageView.image = nil;
        }
    }
    
    if (lastUSers.count >= 3 )
    {
        self.username3ImageView.text    = lastUSers[2][@"name"];
//        self.emailTextField.text        = lastUSers[2][@"email"];
        
        if (lastUSers[2][@"avatar"])
        {
            self.avatar3ImageView.image = [NSKeyedUnarchiver unarchiveObjectWithData:lastUSers[2][@"avatar"]];
            self.noAvatar3Label.text = @"";
        }
        else if (self.username3ImageView.text.length)
        {
            NSString *firstCharacter = [self.username3ImageView.text substringToIndex:1];
            self.noAvatar3Label.text                = firstCharacter;
            self.noAvatar3Label.layer.borderWidth   = 1.;
            self.noAvatar3Label.layer.borderColor   = [UIColor whiteColor].CGColor;
            
            self.avatar3ImageView.image = nil;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark * Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private -

- (void)resetFields
{
    self.passTextField.text = @"";
    [self.emailTextField becomeFirstResponder];
}

- (void)resignAllFirstResponders
{
    [self.emailTextField resignFirstResponder];
    [self.passTextField resignFirstResponder];
}

- (void)maskPassword:(BOOL)isMask {
    self.passTextField.secureTextEntry = isMask;
}

- (void)focusPassword {
    [self.passTextField becomeFirstResponder];
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSelectUser:(UIButton*)button
{
    NSMutableArray *lastUSers = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LAST_USERS"] mutableCopy];
    
    NSInteger index = MAX(0, button.tag - 1);
    NSString *email = lastUSers.count >= button.tag ? lastUSers[index][@"email"] : @"";
    self.emailTextField.text = email;
    
    UIImage *imageBorder = [UIImage imageNamed:@"SwitchUserBorder"];
    UIImage *imageBorderSelected = [UIImage imageNamed:@"SwitchUserBorderSelected"];
    self.loginBorderImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"SwitchUserSelectedLoginPass%ld", (long)button.tag]];
    
    switch (button.tag)
    {
        case 1: {

            self.avatarBorder1ImageView.image = imageBorderSelected;
            self.avatarBorder2ImageView.image = imageBorder;
            self.avatarBorder3ImageView.image = imageBorder;
    
            break;
        }
        case 2: {
            
            self.avatarBorder1ImageView.image = imageBorder;
            self.avatarBorder2ImageView.image = imageBorderSelected;
            self.avatarBorder3ImageView.image = imageBorder;
            
            break;
        }
        case 3: {
            
            self.avatarBorder1ImageView.image = imageBorder;
            self.avatarBorder2ImageView.image = imageBorder;
            self.avatarBorder3ImageView.image = imageBorderSelected;

            break;
        }
        default:
            break;
    }
}

- (IBAction)onLoginButton:(id)sender
{
    [self resignAllFirstResponders];
    
    NSString *email = self.emailTextField.text;
    NSString *pass = self.passTextField.text;
    
    BOOL emailEmpty = !email.length;
    BOOL passEmpty = !pass.length;
    
    if (emailEmpty) {
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1087-TextEmailCannotBeEmpty")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==1) {
                                         [self resetFields];
                                         self.passTextField.secureTextEntry = NO;
                                     }
                                 }];
        return;
    }
    
    if (!isValidEmail(email))
    {
        if (isValidPhone(email) && email.length == 10) {
            email = [email stringByAppendingString:@"@qliq.com"];
        } else {
            
            [AlertController showAlertWithTitle:nil
                                        message:QliqLocalizedString(@"1088-TextIsNotValidEmailAddress")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex==1) {
                                             [self resetFields];
                                             self.passTextField.secureTextEntry = NO;
                                         }
                                     }];
            return;
        }
    }
    
    if (passEmpty) {
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1089-TextPasswordCannotBeEmpty")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==1) {
                                         [self resetFields];
                                         self.passTextField.secureTextEntry = NO;
                                     }
                                 }];
        return;
    }
    
    [[Login sharedService] startManualLoginWithUsername:email password:pass];
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
        [SVProgressHUD dismiss];
        DDLogSupport(@"Logged in with Temporary Password");
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1121-TextLoggedTemporaryPassword")
                                    message:QliqLocalizedString(@"1122-TextYouLoggedWithAdminPassword")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"30-ButtonSetNewPassword")
                                 completion:nil];
        
        //            SetupNewPinQuestionViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SetupNewPinQuestionViewController class])];
        //            [self.navigationController pushViewController:controller animated:YES];
        return;
    }
}

- (void)loginError:(NSError *)error title:(NSString *)title message:(NSString *)message
{
    [SVProgressHUD dismiss];
    [Login sharedService].isLoginRunning = NO;
    [self resetFields];
    
    if((title.length|| message.length) && !error.code) {
        
        [AlertController showAlertWithTitle:title
                                    message:message
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return;
    } else if (!error && !title && !message)
        return;
    DDLogSupport(@"login request error: %@",error);
    [SVProgressHUD dismiss];
    
    switch (error.code) {
            
        case ErrorCodeInvalidRequest: {
            
            // Incompatable: upgrade, cancel
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1123-TextVersionIncompatibility")
                                        message:QliqLocalizedString(@"1124-TextPleaseUpgradeApp")
                               withTitleButtons:@[QliqLocalizedString(@"31-ButtonUpgrade")]
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex==0) {
                                             [appDelegate getNewVersion];
                                         }
                                     }];
            break;
        }
        case ErrorCodeAccessDenied: {
            DDLogSupport(@"Login failed because Access denied from this device");
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1125-TextAccessBlocked")
                                        message:[error localizedDescription]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
            break;
        }
        case ErrorCodeLoginInvalidCredentials: {
            DDLogSupport(@"Login (or idle unlock) failed because password or pin is wrong");
            
            [[Login sharedService] loginFailedWithInvalidCredentials];
            
            if (![[Login sharedService].failedAttemptsController isLocked]) {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1126-TextLoginFailed")
                                            message:QliqFormatLocalizedString1(@"3041-TextFrom{Email}incorrectEmailOrPassword", self.emailTextField.text)
                                   withTitleButtons:@[QliqLocalizedString(@"29-ButtonForgotPassword")]
                                  cancelButtonTitle:QliqLocalizedString(@"28-ButtonRetry")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex==0) {
                                                 DDLogSupport(@"forgot password pressed: %ld",(long)buttonIndex);
                                                 
                                                 ResetPasswordController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ResetPasswordController class])];
                                                 controller.email = self.emailTextField.text;
                                                 [self.navigationController pushViewController:controller animated:YES];
                                             } else {
                                                 self.passTextField.secureTextEntry = NO;
                                             }
                                         }];
                
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            break;
        }
        case ErrorCodeLoginClientHasOldVersion: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1127-TextUnsupportedVersion")
                                        message:QliqLocalizedString(@"1128-TextAppVersionNotSupported")
                                    buttonTitle:QliqLocalizedString(@"32-ButtonUpgradeNow")
                              cancelButtonTitle:nil
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex==0) {
                                             [appDelegate getNewVersion];
                                         }
                                     }];
            break;
        }
        case ErrorCodeLoginServerSideProblem: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1129-TextServerError")
                                        message:QliqLocalizedString(@"1130-TextPleaseContactqliqSOFT")
                                    buttonTitle:QliqLocalizedString(@"1-ButtonOK")
                              cancelButtonTitle:nil
                                     completion:nil];
            break;
        }
        case ErrorCodeLoginServerIsBeingUpgraded: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1131-TextServerUpgrade")
                                        message:QliqLocalizedString(@"1132-TextQliqSOFTCloudServerUpgraded")
                                    buttonTitle:QliqLocalizedString(@"1-ButtonOK")
                              cancelButtonTitle:nil
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
                                             if (buttonIndex == 1) {
                                                 [welf.navigationController popToRootViewControllerAnimated:NO];
                                             }
                                         }];
            });
            
            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            break;
        }
            
        default: {
            
            if (isSSLErrorCode(error.code)) {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1134-TextSSLConnectionError")
                                            message:QliqLocalizedString(@"1133-TextInstructionInternetConnection")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];

            } else if (isNetworkErrorCode(error.code)) {
                
                NSString *email = self.emailTextField.text;
                NSString *pass = self.passTextField.text;
                if (![[Login sharedService] localLogin:email password:pass error:&error])
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1135-TextLoginError")
                                                message:[error localizedDescription]
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:nil];
                
            } else if (error.code == 502) {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1131-TextServerUpgrade")
                                            message:QliqLocalizedString(@"1132-TextQliqSOFTCloudServerUpgraded")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            } else {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1136-TextGeneralError")
                                            message:[error localizedDescription]
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            }
            break;
        }
    }
}

#pragma mark * TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [textField resignFirstResponder];
    [self onLoginButton:nil];
    return YES;
}

@end

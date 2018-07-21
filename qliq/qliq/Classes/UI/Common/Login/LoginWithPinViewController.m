//
//  PinViewController.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "LoginWithPinViewController.h"

#import "LoginWithPasswordViewController.h"
#import "KeychainService.h"

#import "Login.h"
#import "UIDevice-Hardware.h"
#import "UserSession.h"

#import "SetNewPinContainerView.h"
#import "EnterPinContainerView.h"
#import "SwitchUserViewController.h"

/// Touch ID
#import <LocalAuthentication/LocalAuthentication.h>
#import <AudioToolbox/AudioServices.h>

@interface LoginWithPinViewController () <LoginDelegate>


@property (weak, nonatomic) IBOutlet UIView *setNewPinView;
@property (weak, nonatomic) IBOutlet UIView *enterPinView;

@property (weak, nonatomic) SetNewPinContainerView *setNewPinContainer;
@property (weak, nonatomic) EnterPinContainerView *enterPinContainer;

@property (nonatomic, strong) LoginService *loginService;
@property (nonatomic, assign) id<UserSessionServiceDelegate> delegate;

@property (strong, nonatomic) NSString *enteredPin;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;


@end

@implementation LoginWithPinViewController

- (void)dealloc {
    self.setNewPinView = nil;
    self.enterPinView = nil;
    self.setNewPinContainer = nil;
    self.enterPinContainer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.backgroundViewBottomConstraint.constant = weakSelf.backgroundViewBottomConstraint.constant -35.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });
    
    [self configureChildViewControllers];
    [self addObsevers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [Login sharedService].delegate = self;

    [self configureControllerForAction];
    
    // Show Touch ID verification if it is not Setting UP PIN or AutoLogin is not ON
    if (self.setNewPinView.hidden == YES && ![[Login sharedService] shouldAutoLogin]) {
        [self touchIdVerification];
    }
}

- (void)willEnterForeground {
    if ([[KeychainService sharedService] pinAvailable] && [self.navigationController.viewControllers lastObject] == self && ![[Login sharedService] shouldAutoLogin]) {
        [self touchIdVerification];
    }
}

#pragma mark * Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Setters -

- (void)setAction:(ActionTipePin)action {
    _action = action;
 
    if ([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self configureControllerForAction];
        }];
    } else {
        
        [self configureControllerForAction];
    }
}

#pragma mark - Private -

- (void)configureControllerForAction {
    
    [self resetPinView];
    
    switch (self.action) {
            
        case ActionTipePinSet: {
            self.setNewPinView.hidden = NO;
            self.enterPinView.hidden = YES;
            self.setNewPinContainer.enterPinLabel.text = QliqLocalizedString(@"2308-TitleSetupYourPIN");
            break;
        }
        case ActionTipePinConfirm: {
            
            self.setNewPinView.hidden = NO;
            self.enterPinView.hidden = YES;
            self.setNewPinContainer.enterPinLabel.text = QliqLocalizedString(@"2309-TitleConfirmYourPIN");
            break;
        }
        case ActionTipePinEnter: {
            
            self.setNewPinView.hidden = YES;
            self.enterPinView.hidden = NO;
            
            [self.enterPinContainer showHeaderWithContact:[[Login sharedService].userSessionService getLastLoggedInUser] andGroup:(QliqGroup *)[[Login sharedService].userSessionService getLastLoggedInUserGroup]];
            break;
        }
        default:
            break;
    }
}

- (void)configureChildViewControllers {
    for (UIViewController *item in self.childViewControllers)
    {
        //new pin container view
        if ([item isKindOfClass:[SetNewPinContainerView class]])
        {
            self.setNewPinContainer = (SetNewPinContainerView*)item;
            self.setNewPinContainer.backButtonView.hidden = YES;
            [self.setNewPinContainer.switchButton addTarget:self action:@selector(onSwitchToEnterPassButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        //enter pin container view
        if ([item isKindOfClass:[EnterPinContainerView class]])
        {
            self.enterPinContainer = (EnterPinContainerView*)item;
            self.enterPinContainer.typeLabel.text = QliqLocalizedString(@"2303-TitleLogin");
            self.enterPinContainer.badgeLabel.hidden = YES;
            [self.enterPinContainer.switchUserButton addTarget:self action:@selector(onSwitchUser:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)addObsevers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

}

- (void)touchIdVerification
{
    [Login touchIdVerification:^(BOOL success, NSError *error) {
        if (success) {
            performBlockInMainThread(^{
                DDLogSupport(@"User is authenticated by Touch ID successfully");
                [[Login sharedService].failedAttemptsController clear];
                [Login sharedService].loginWithPin = YES;
                
                //Touch ID
                NSString *storedUn          = [[KeychainService sharedService] getUsername];
                NSString *storedPassword    = [[KeychainService sharedService] getPassword];
                [[Login sharedService] startLoginWithUsername:storedUn password:storedPassword autoLogin:NO forceLocalLogin:NO];
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
    [self.enterPinContainer resetPinView];
    [self.setNewPinContainer resetPinView];
}

- (NSString *)pin
{
    if (!self.enterPinView.hidden) {
        return self.enterPinContainer.pin;
    }
    else {
        return self.setNewPinContainer.pin;
    }
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notifications {
    if (appDelegate.appLaunchedWithVoIPPush)
    {
        appDelegate.appLaunchedWithVoIPPush = NO;
         DDLogSupport(@"appLaunchedWithVoIPPush --> handleApplicationDidBecomeActive --> Try to Autologin");
        [[Login sharedService] tryAutologinOrPreopenDB];
    }
}

#pragma mark -

- (void)enterPin:(NSString *)pin
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        switch (self.action)
        {
            case ActionTipePinSet: {
                
                if ([[KeychainService sharedService] pinAlreadyUsed:pin])
                {
                    dispatch_async_main(^{
                        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1215-TextPINHasBeenUsedPreviously")
                                                                                      message:QliqLocalizedString(@"1216-TextChooseDifferentPIN")
                                                                                     delegate:nil
                                                                            cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                            otherButtonTitles: nil];
                        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                            DDLogSupport(@"PIN retry");
                            [self resetPinView];
                            
                        }];
                        
                    });
                }
                else {
                    _enteredPin = pin;
                    self.action = ActionTipePinConfirm;
                }
                
                break;
            }
            case ActionTipePinConfirm: {
                
                __block __weak typeof(self) weakSelf = self;
                
                [[Login sharedService] confirmNewPin:self.enteredPin andConfirmedNewPin:pin withBlock:^(BOOL confirmed, NSError *error) {
                    
                    _enteredPin = nil;
                    
                    if (confirmed) {
                        
                        dispatch_async_main(^{
                            if (![SVProgressHUD isVisible])
                                [SVProgressHUD showWithStatus:NSLocalizedString(@"1913-StatusLogin", @"Login")
                                                     maskType:SVProgressHUDMaskTypeBlack
                                           dismissButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)];
                        });
                        
                        if(_setupPinFromSettings) {
                            [[KeychainService sharedService] savePin:pin];
                        } else {
                            
                            [[Login sharedService] saveNewPin:pin];
                            [Login sharedService].loginWithPin = YES;
                            [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:kLoginWithPin];
                            
                            
                            NSString *storedUn = [[KeychainService sharedService] getUsername];
                            NSString *storedPassword = [[KeychainService sharedService] getPassword];
                            
                            self.loginService = [[LoginService alloc] initWithUsername:storedUn andPassword:storedPassword];
                            
                            [self.loginService callServiceWithCompletition:^(CompletitionStatus statusOfServiceResponse, NSDictionary *dictOfServiceResponse, NSError *errorOfServiceResponse) {
                                
                                if (statusOfServiceResponse == CompletitionStatusSuccess) {
                                    
                                    if (dictOfServiceResponse) {
                                
                                        /*
                                         saving server responce dictionary for LoginWithNewPin login way
                                         !IMPORTANT!
                                         */
                                        [UserSessionService currentUserSession].loggedInDictionary = dictOfServiceResponse;
                                        
                                        
                                        [[Login sharedService] continueLoginWithResponseFromServerWithCompletion:^(CompletitionStatus status, id result, NSError *error) {
                                            
                                            if (error) {
                                                DDLogSupport(@"login request error: %@",error);
                                                dispatch_async_main(^{
                                                    [SVProgressHUD dismiss];
                                                });
                                                [Login sharedService].isLoginRunning = NO;
                                                
                                                __weak __block typeof(self) welf = self;
                                                switch (error.code)
                                                {
                                                    case 123123: {
                                                        
//                                                        NSString *alertString = QliqLocalizedString(@"2355-TitleDBCannotBeOpened");
                                                        
                                                        dispatch_async_main(^{
                                                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"2355-TitleDBCannotBeOpened")
                                                                                                  message:nil
                                                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                            
                                                            UIAlertAction *okAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                                                               style:UIAlertActionStyleCancel
                                                                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                                                                 [welf.navigationController popToRootViewControllerAnimated:NO];
                                                                                                             }];
                                                            [alertController addAction:okAction];
                                                            [welf.navigationController presentViewController:alertController animated:YES completion:nil];
                                                        });
                                                        
                                                        [[Login sharedService] settingShouldSkipAutoLogin:YES];
                                                        break;
                                                    }
                                                    default: {
                                                        dispatch_async_main(^{
                                                            [welf.navigationController popToRootViewControllerAnimated:NO];
                                                        });
                                                        break;
                                                    }
                                                }
                                            }
                                        }];
                                    }
                                } else if (statusOfServiceResponse == CompletitionStatusError) {
                                    
                                    DDLogSupport(@"Error status of service response");
                                    [weakSelf.delegate didFailLogInWithReason:[errorOfServiceResponse localizedDescription]];
                                    
                                }
                            }];
                        }
                    } else {
                        if (error) {
                            switch (error.code) {
                                case LoginWithPinErrorCodePin1NotEqualPin2: {
                                    
                                    dispatch_async_main(^{
                                        
                                        weakSelf.action = ActionTipePinSet;
                                        
                                        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1137-TextIncorrectPinConfirmation", nil)
                                                                                                      message:NSLocalizedString(@"1138-TextPleaseTryAgain", nil)
                                                                                                     delegate:nil
                                                                                            cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                                            otherButtonTitles: nil];
                                        [alert showWithDissmissBlock:nil];
                                    });
                                    
                                    break;
                                }
                                default:
                                    break;
                            }
                        }
                    }
                }];
                break;
            }
            case ActionTipePinEnter:{
                
                __block __weak typeof(self) weakSelf = self;
                
                [[Login sharedService] startLoginWithPin:pin withCompletionBlock:^(BOOL loginStarted, NSError *error) {
                    if (loginStarted) {
                        DDLogSupport(@"Login was started...");
                    }
                    else {
                        if (error) {
                            __block __weak typeof(self) strongSelf = weakSelf;
                            dispatch_async_main(^{
                                switch (error.code) {
                                    case LoginWithPinErrorCodePinExpired: {
                                        
                                        __block __weak typeof(self) strongStrongSelf = strongSelf;
                                        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1217-TextPinExpired")
                                                                                                      message: QliqLocalizedString(@"1218-TextPleaseSetupNewPIN")
                                                                                                     delegate:nil
                                                                                            cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                                            otherButtonTitles:nil, nil];
                                        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                                            strongStrongSelf.action = ActionTipePinSet;
                                        }];
                                        
                                        break;
                                    }
                                    case LoginWithPinErrorCodePinBlocked: {
                                        [strongSelf.navigationController popToRootViewControllerAnimated:NO];
                                        break;
                                    }
                                    case LoginWithPinErrorCodeEnteredWrongPin: {
                                        
                                        [strongSelf didEnterWrongPin];
                                        __block __weak typeof(self) strongStrongSelf = strongSelf;
                                        QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:YES];
                                        
                                        [alertView setContainerViewWithImage:nil
                                                                   withTitle:NSLocalizedString(@"1090-TextAskForgotPIN", nil)
                                                                    withText:NSLocalizedString(@"1091-TextTryLoggingWithPassword", nil)
                                                                withDelegate:nil
                                                            useMotionEffects:YES];
                                        
                                        [alertView setButtonTitles:@[NSLocalizedString(@"19-ButtonTryPassword", nil), NSLocalizedString(@"20-ButtonRetryPIN", nil)]];
                                        
                                        
                                        [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
                                            
                                            if (buttonIndex == 0) {
                                                LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
                                                [strongStrongSelf.navigationController pushViewController:controller animated:YES];
                                            }
                                        }];
                                        [alertView show];
                                        
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            });
                        }
                    }
                }];

                break;
            }
            default:
                break;
        }
    });
}

#pragma mark - Alerts -

- (void)alertWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                        otherButtonTitles: nil];
    [alert showWithDissmissBlock:NULL];
}

#pragma mark - Actions -

- (void)onSwitchToEnterPassButton:(id)sender {
    LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)onSwitchUser:(id)sender {
    SwitchUserViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SwitchUserViewController class])];
    controller.hiddeBackButton = NO;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Delegates -

#pragma mark * Login Delegate

- (void)loginIsSuccessful:(id)result {
    [SVProgressHUD dismiss];
}

- (void)loginError:(NSError *)error title:(NSString *)title message:(NSString *)message
{
    [Login sharedService].isLoginRunning = NO;
    [self resetPinView];
    if((title.length|| message.length) && !error.code)
    {
        [self alertWithTitle:title message:message];
        return;
    }
    else if (!error && !title && !message)
        return;
    
    DDLogSupport(@"login request error: %@",error);
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible])
            [SVProgressHUD dismiss];
    });
    
    switch (error.code)
    {
        case ErrorCodeInvalidRequest: {
            
            // Incompatable: upgrade, cancel
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1123-TextVersionIncompatibility", nil)
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
        case ErrorCodeLoginInvalidCredentials: {
            DDLogSupport(@"Login (or idle unlock) failed because password or pin is wrong");
            
            //APIN
            [[Login sharedService] loginFailedWithInvalidCredentials];
            
            if (![[Login sharedService].failedAttemptsController isLocked]) {

                if (error.code == 100 && [[KeychainService sharedService] pinAvailable]) {
                    
                   UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1126-TextLoginFailed", nil)
                                                                                 message:[error localizedDescription]
                                                                                delegate:nil
                                                                       cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                       otherButtonTitles:nil];
                    
               
                    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                        DDLogSupport(@"Clearing PIN with server respose: Wrong pass");
                        [[KeychainService sharedService] clearPin];
                        [self.navigationController popToRootViewControllerAnimated:NO];
                    }];
                    
                } else {
                    
                    [self alertWithTitle:NSLocalizedString(@"1126-TextLoginFailed", nil) message:[error localizedDescription]];
                
                }
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
                [appDelegate getNewVersion];}];
            break;
        }
        case ErrorCodeLoginServerSideProblem: {
            
            [self alertWithTitle:NSLocalizedString(@"1129-TextServerError", nil)
                         message:NSLocalizedString(@"1130-TextPleaseContactqliqSOFT", nil)];
            break;
        }
        case ErrorCodeLoginServerIsBeingUpgraded: {
            
            [self alertWithTitle:NSLocalizedString(@"1131-TextServerUpgrade", nil)
                         message:NSLocalizedString(@"1132-TextQliqSOFTCloudServerUpgraded", nil)];
            break;
        }
        case 123123: {
            
            NSString *alertString = QliqLocalizedString(@"2355-TitleDBCannotBeOpened");
            
            __weak __block typeof(self) welf = self;
            
            dispatch_async_main(^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertString
                                                                                         message:nil
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     [welf.navigationController popToRootViewControllerAnimated:NO];
                                                                 }];
                [alertController addAction:okAction];
                [self.navigationController presentViewController:alertController animated:YES completion:nil];
            });
            
            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            break;
        }
        default:{
            
            if (isSSLErrorCode(error.code))
            {
                NSString *message = NSLocalizedString(@"1133-TextInstructionInternetConnection", nil) ;
                [self alertWithTitle:NSLocalizedString(@"1134-TextSSLConnectionError", nil) message:message];
            }
            else if (error.code == 502)
            {
                [self alertWithTitle:NSLocalizedString(@"1131-TextServerUpgrade", nil)
                             message:NSLocalizedString(@"1132-TextQliqSOFTCloudServerUpgraded", nil)];
            }
            else
            {
                [self alertWithTitle:NSLocalizedString(@"1136-TextGeneralError", nil) message:[error localizedDescription]];
            }
            break;
        }
    }
}


@end

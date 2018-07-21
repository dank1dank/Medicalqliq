//
//  FirstLaunchViewController.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "FirstLaunchViewController.h"

#import "LoginWithPinViewController.h"
#import "RegisterUserWebViewViewController.h"
#import "FailedAttemptsController.h"

#import "LoginWithPasswordViewController.h"
#import "SwitchUserViewController.h"
#import "MainViewController.h"

#import "UIDevice-Hardware.h"
#import "Login.h"

#import "AttemptsLockContainerView.h"
#import "FirstLaunchContainerView.h"
#import "WipedContainerView.h"
#import "LockContainerView.h"
#import "KeychainService.h"

#import "GetDeviceStatus.h"

#define kLinkQliqStartRegistration @"https://qliqsoft.com/register"

@interface FirstLaunchViewController () <LoginDelegate>

@property (weak, nonatomic) IBOutlet UIView *firstLaunchView;
@property (weak, nonatomic) IBOutlet UIView *lockView;
@property (weak, nonatomic) IBOutlet UIView *wipeView;
@property (weak, nonatomic) IBOutlet UIView *attemptsLockView;

@property (weak, nonatomic) FirstLaunchContainerView  *firstLaunchContainer;
@property (weak, nonatomic) WipedContainerView *wipedContainer;
@property (weak, nonatomic) LockContainerView *lockContainer;
@property (weak, nonatomic) AttemptsLockContainerView *attemptsLockContainer;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewTopConstraint;

@end

@implementation FirstLaunchViewController

- (void)dealloc {
    self.firstLaunchView = nil;
    self.lockView = nil;
    self.wipeView = nil;
    self.attemptsLockView = nil;
    
    self.firstLaunchContainer = nil;
    self.lockContainer = nil;
    self.wipedContainer = nil;
    self.attemptsLockContainer = nil;
    
    self.viewType = nil;
    
    _unlockBlock = nil;
    _runLoginBlock = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    /*Change constraint for iPhone X*/
    __block __weak typeof(self) meakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            meakSelf.backgroundViewBottomConstraint.constant = meakSelf.backgroundViewBottomConstraint.constant -35.0f;
            meakSelf.backgroundViewTopConstraint.constant = meakSelf.backgroundViewTopConstraint.constant -64.0f;
            [meakSelf.view layoutIfNeeded];
        }
    });
    
    /*
     set up completion block for unlocking
     */
    __weak __block FirstLaunchViewController *weakSelf = self;
    [[Login sharedService].failedAttemptsController setDidLockBlock:^(BOOL isLocked) {
        [weakSelf reloadController];
    }];
    
    [Login sharedService].delegate = self;

    [self configureChildControllers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadController];
}

- (void)reloadController {
    
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.toolbarHidden = YES;
    
    [Login sharedService].delegate = self;
    
    //Choose StartView
    [self chooseFirstLaunchWay];
}

#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private -

- (void)configureChildControllers
{
    for (UIViewController *controller in self.childViewControllers)
    {
        //register container view
        if ([controller isKindOfClass:[FirstLaunchContainerView class]]) {
            
            self.firstLaunchContainer = (FirstLaunchContainerView *)controller;
            
            [self.firstLaunchContainer.signInButton addTarget:self action:@selector(onSignIn) forControlEvents:UIControlEventTouchUpInside];
            [self.firstLaunchContainer.registerButton addTarget:self action:@selector(onRegister) forControlEvents:UIControlEventTouchUpInside];
        }
        
        //lock container view
        else if ([controller isKindOfClass:[LockContainerView class]]) {
            
            self.lockContainer = (LockContainerView *)controller;
            
            [self.lockContainer.unlockButton addTarget:self action:@selector(onContactAdminButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.lockContainer.visitWebsiteButton addTarget:self action:@selector(onVisitWebsiteButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        //wiped container view
        else if ([controller isKindOfClass:[WipedContainerView class]]) {
            
            self.wipedContainer = (WipedContainerView *)controller;
            
            [self.wipedContainer.continueToLogInButton addTarget:self action:@selector(onSignIn) forControlEvents:UIControlEventTouchUpInside];
            [self.wipedContainer.visitWebsiteButton addTarget:self action:@selector(onVisitWebsiteButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        //attempts lock container view
        else if ([controller isKindOfClass:[AttemptsLockContainerView class]]) {
            
            self.attemptsLockContainer = (AttemptsLockContainerView *)controller;
            
            [self.attemptsLockContainer.unlockButton addTarget:self action:@selector(onContactAdminButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.attemptsLockContainer.visitWebsiteButton addTarget:self action:@selector(onVisitWebsiteButton:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

/**
 This method for determine wich controller should be showed
 */
- (void)chooseFirstLaunchWay
{
    StartViewType viewType = StartViewTypeNone;
    
    //If app is Locked
    if (appDelegate.currentDeviceStatusController.isLocked) {
        viewType = StartViewTypeLock;
    }
    //If app is Wiped
    else if (appDelegate.currentDeviceStatusController.isWiped) {
        viewType = StartViewTypeWipe;
    }
    
    //If app is Blocked
    if ([[Login sharedService].failedAttemptsController isLocked]) {
        viewType = StartViewTypeAttemptsLock;
    }
    
    //If on Locked Screen did press Button "Start Registration/Forgot Password/Switch User/ ..."
    if ([Login sharedService].shouldStartView != StartViewTypeNone && viewType == StartViewTypeNone) {
        
        viewType = [Login sharedService].shouldStartView;
        
        [Login sharedService].shouldStartView = StartViewTypeNone;
    }
    
    if (viewType == StartViewTypeNone)
    {
        //If its first launch
        if ([Login sharedService].lastLoggedUser == nil) {
            viewType = StartViewTypeFirstLaunch;
        }
    }
    
    [self setViewType:viewType animated:YES withCompletition:NO];
}

#pragma mark - Sub Methods

- (void)setViewType:(StartViewType)viewType animated:(BOOL)animated withCompletition:(void(^)(void))completition {
    
    _viewType = viewType;
    __weak __block FirstLaunchViewController *weakSelf = self;
    
    self.firstLaunchView.hidden = YES;
    self.lockView.hidden = YES;
    self.wipeView.hidden = YES;
    self.attemptsLockView.hidden = YES;

    switch (viewType)
    {
        case StartViewTypeFirstLaunch:{
            self.firstLaunchView.hidden = NO;
            // 10/13/2015 KK
            // Now Ask the server about first launch configuration here
            [appDelegate getFirstLaunchInfo];
            break;
        }
        case StartViewTypeLock:{
            self.lockView.hidden = NO;
            break;
        }
        case StartViewTypeWipe:{
            self.wipeView.hidden = NO;
            // Once we show the Wipe State, we should clear the state so that
            // We don't show it again.
            [[KeychainService sharedService] saveWipeState:GetDeviceStatusNone];
            break;
        }
        case StartViewTypeAttemptsLock:{
            self.attemptsLockView.hidden = NO;
            
            __block FailedAttemptsController *failedAttemptsController = [Login sharedService].failedAttemptsController;
            
//            NSUInteger maxAttemps = [failedAttemptsController maxAttempts];
            NSTimeInterval time = [failedAttemptsController timeIntervalToUnlock];

            //Need to show only Lock Interval
            self.attemptsLockContainer.attemptsLockMessageLabel.text = QliqFormatLocalizedString1(@"2452-TitleAttemptsLock{LockInterval}", [self timeStringForTimeInterval:time]);

//            self.attemptsLockContainer.attemptsLockMessageLabel.text = QliqFormatLocalizedString2(@"2302-TitleAttemptsLock{AttemptCount}{LockInterval}", (unsigned long)maxAttemps, [self timeStringForTimeInterval:time]);
            /** 
             Reaload Controller
             */
            void(^didUnlockBlockLocal)(void) = ^{
                [failedAttemptsController unlockWithCompletion:^{
                   
                    [weakSelf reloadController];
 
                }];
            };
           
            [failedAttemptsController setCountdownBlock:^(NSTimeInterval invervalToUnlock) {
                
                if (invervalToUnlock >= 0)
                {
                    //Need to show only Lock Interval
                    weakSelf.attemptsLockContainer.attemptsLockMessageLabel.text = QliqFormatLocalizedString1(@"2452-TitleAttemptsLock{LockInterval}", [self timeStringForTimeInterval:invervalToUnlock]);

//                    weakSelf.attemptsLockContainer.attemptsLockMessageLabel.text = QliqFormatLocalizedString2(@"2302-TitleAttemptsLock{AttemptCount}{LockInterval}", (unsigned long)maxAttemps, [weakSelf timeStringForTimeInterval:invervalToUnlock]);
                }
                else
                {
                    weakSelf.attemptsLockContainer.attemptsLockMessageLabel.text = @"";

                    if (didUnlockBlockLocal) {
                        didUnlockBlockLocal();
                    }
                }
            }];

            failedAttemptsController = nil;
            break;
        }
        case StartViewTypeEnterPassword: {
            
            LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
            [self.navigationController pushViewController:controller animated:NO];
            break;
        }
        case StartViewTypeEnterPin: {
            
            LoginWithPinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPinViewController class])];
            controller.action = ActionTipePinEnter;
            [self.navigationController pushViewController:controller animated:NO];
            break;
        }
        case StartViewTypeSwitchUser: {
            
            SwitchUserViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SwitchUserViewController class])];
            controller.hiddeBackButton = YES;
            [self.navigationController pushViewController:controller animated:NO];
            break;
        }
        case StartViewTypeForgotPassword: {
            
            LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
            controller.startType = StartLoginWithPasswordWithForgotPassword;
            [self.navigationController pushViewController:controller animated:NO];
            break;
        }
        case StartViewTypeCreateAccount: {
            
            LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
            controller.startType = StartLoginWithPasswordWithCreateAccount;
            [self.navigationController pushViewController:controller animated:NO];
            
            break;
        }
        case StartViewTypeMainView: {
            
            MainViewController *mainController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MainViewController class])];
            [self.navigationController pushViewController:mainController animated:YES];
            
            break;
        }
        default:
        case StartViewTypeNone:{
            
            if ([Login sharedService].lastLoggedUser)
            {
                if ([[KeychainService sharedService] pinAvailable])
                {
                    LoginWithPinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPinViewController class])];
                    controller.action = ActionTipePinEnter;
                    [self.navigationController pushViewController:controller animated:NO];
                }
                else
                {
                    LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
                    [self.navigationController pushViewController:controller animated:NO];
                }
            }
            
            [[Login sharedService] tryAutologinOrPreopenDB];
            
            break;
        }
    }
    
    void(^beginLoginBlock)(void) = ^{
        DDLogSupport(@"beginLoginBlock called");
        
        //[[Login sharedService] didLogin];
        [[Login sharedService] beginLogin];
        
    };
    
    void(^didUnlockBlock)(void) = ^{
        DDLogSupport(@"setUnlockBlock called");
        
        [SVProgressHUD showWithStatus:QliqLocalizedString(@"1945-StatusUnlocking") maskType:SVProgressHUDMaskTypeBlack];
        [appDelegate.currentDeviceStatusController refreshRemoteStatusWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            [SVProgressHUD dismiss];
            if (!error) {
                
                if ([appDelegate.currentDeviceStatusController isLocked]) {
                    
                    UIAlertView_Blocks * alertView = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1084-TextLocked")
                                                                                       message:QliqLocalizedString(@"1085-TextPleaseUnlockApp")
                                                                                      delegate:nil
                                                                             cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                                             otherButtonTitles: nil];
                    [alertView showWithDissmissBlock:nil];
                } else {
                    
                    [weakSelf reloadController];
                    
                    beginLoginBlock();
                }
            } else {
                
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1086-TextCan'tUnlockDevice", nil)
                                                                              message:[error localizedDescription]
                                                                             delegate:nil
                                                                    cancelButtonTitle:NSLocalizedString(@"1-ButtonOk", nil)
                                                                    otherButtonTitles: nil];
                [alert showWithDissmissBlock:NULL];
            }
        }];
    };
    
    _unlockBlock = didUnlockBlock;
    
    if (completition) {
        completition();
    }
}

- (NSString *)timeStringForTimeInterval:(NSTimeInterval)timeInterval
{
    NSUInteger minutes = timeInterval/60;
    NSUInteger secunds = timeInterval - minutes * 60;
    BOOL showMinutes = minutes > 0;
    BOOL showSeconds = (int)timeInterval % 60 != 0;
    NSString * minutesString = showMinutes ? [NSString stringWithFormat:@"%lu minutes",(unsigned long)minutes] : @"";
    NSString * secondsString = showSeconds ? [NSString stringWithFormat:@"%lu seconds",(unsigned long)secunds]  : @"";
    
    return [NSString stringWithFormat:@"%@%@%@",minutesString,showMinutes&&showSeconds?@" ":@"",secondsString];
}

#pragma mark - Actions -

- (void)onSignIn {
    DDLogSupport(@"Start Log In");
        
    [[Login sharedService] beginLogin];
}

- (void)onRegister {
    DDLogSupport(@"Start registration");
    
    RegisterUserWebViewViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([RegisterUserWebViewViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)onContactAdminButton:(UIButton *)button {
    if (_unlockBlock) {
        _unlockBlock();
    }
}

- (void)onVisitWebsiteButton:(UIButton *)button {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://vimeo.com/46937303"]];
}

- (void)onInfoButton:(UIButton *)button {
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

#pragma mark * Login Delegate

- (void)loginWithPin
{
    LoginWithPinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPinViewController class])];
    controller.action = ActionTipePinEnter;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)loginWithPassword
{
    LoginWithPasswordViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPasswordViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

@end

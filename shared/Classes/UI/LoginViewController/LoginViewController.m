//
//  LoginViewController.m
//  qliq
//
//  Created by Paul Bar on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "SVProgressHUD.h"
#import "ResetPasswordController.h"
#import "KeychainService.h"
#import "PinEnteringViewController.h"
#import "SetUpNewPinQuestionViewController.h"
#import "LoginWithPasswordViewController.h"
#import "PasswordChangeViewController.h"
#import "UserSession.h"
#import "LoginView.h"
#import "UserHeaderView.h"
#import "QliqUserDBService.h"
#import "Helper.h"
#import "StringMd5.h"
#import "QliqSip.h"
#import "UserSettingsService.h"
#import "AppDelegate.h"
#import "ThumbnailService.h"
#import "StartView.h"
#import "Crypto.h"
#import "NetworkStatusDBService.h"
#import "DBUtil.h"
#import "LoginService.h"
#import "UIAlertView_Blocks.h"
#import "UserSessionService.h"
#import "GetKeyPair.h"
#import "NSString+Base64.h"
#import "NSString+extensions.h"
#import "DemoViewController.h"
#import "UserSettingsService.h"
#import "FeedbackViewController.h"
#import "RegisterUserViewController.h"
#import "NotificationUtils.h"
#import "CustomBackButtonView.h"
#import "QliqModulesController.h"
#import "QliqModuleProtocol.h"
#import "PasswordChangeViewController.h"
#import "BusyAlertController.h"
#import "SipServerInfo.h"
#import "UserNotifications.h"


@interface OnlyPortraitController : UIViewController
@end

@implementation OnlyPortraitController
-(NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#define ShowErrorReport 0

@interface LoginViewController () <LoginWithPasswordViewControllerDelegate, UserSessionServiceDelegate, PinEnteringViewControllerDelegate, SetUpNewPinQuestionViewControllerDelegate, PasswordChangeViewControllerDelegate>

@property (nonatomic, strong) LoginView *loginView;
@property (nonatomic, strong) UserHeaderView *userHeaderView;
@property (nonatomic, strong) UserSessionService *userSessionService;
@property (nonatomic, strong) QliqUserDBService *qliqUserService;
@property (nonatomic, strong) KeychainService *keychainService;
@property (nonatomic, assign) BOOL wasAutoLoginTried;
@property (nonatomic, assign) BOOL loginWithPin;
@property (nonatomic, assign) BOOL manualLogin;
@property (nonatomic, assign) BOOL loginWithAutoLogin;
@property (nonatomic, strong) QliqUser* lastLoggedUser;
@property (nonatomic, strong) Group* lastLoggedUserGroup;
@property (nonatomic, strong) StartView *startView;
@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, assign) BOOL viewDidAppear;
@property (nonatomic, assign) dispatch_semaphore_t preopenDbSemaphore;
@property (nonatomic, assign) BOOL firstTimeLaunch;

//- (void)showPasswordView;
//- (void)showPinView;
//- (void)showSetUpNewPinQuestion;
//- (void)processLocalLoginForUser:(NSString*)username withPassword:(NSString*)password;
//- (BOOL)doLocalLoginIfPossible:(NSString *)username withPassword:(NSString *)password withError:(NSError **)error;
//- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
//- (void)showInvalidLoginAlert:(NSString*)title message:(NSString*)message email:(NSString*) email;
//- (void)notifyLoginFail:(NSString*)reason;
//- (void)changeRightNavigationItemTitle:(NSString*)title;
//- (void)openCrypto;
//- (void)closeKeyboard;

@end

@implementation LoginViewController/*{
    NSTimer * timer;
    BOOL viewDidAppear;
}

@synthesize delegate;
@synthesize loginWithPin;
@synthesize loginWithAutoLogin;
@synthesize lastLoggedUser;
@synthesize lastLoggedUserGroup;
@synthesize changesRightNavigationItem;
@synthesize startView;
@synthesize shouldCheckForLocking;
@synthesize shouldSkipAutoLogin;
@synthesize failedAttemptsController;
*/
//#define USE_LOCAL_LOGIN_ONLY

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    DDLogSupport(@"initWithNibName");
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        //qliqUserService = [[QliqUserService alloc] init];
        self.failedAttemptsController = [[FailedAttemptsController alloc] init];
        
        __weak LoginViewController *weakSelf = self;
        [self.failedAttemptsController setDidLockBlock:^(BOOL isLocked) {
            
            [weakSelf viewWillAppear:YES];
        }];
        
        self.userSessionService = [[UserSessionService alloc] init];
        self.userSessionService.delegate = self;
        
        self.loginWithPasswordViewController = [[LoginWithPasswordViewController alloc] init];
        self.loginWithPasswordViewController.delegate = self;
        
        self.pinEnteringViewController = [[PinEnteringViewController alloc] init];
        self.pinEnteringViewController.delegate = self;
        
        self.passwordChangeViewController = [[PasswordChangeViewController alloc] init];
        self.passwordChangeViewController.delegate = self;
        
        self.changesRightNavigationItem = YES;
        
        self.shouldCheckForLocking = YES;
        self.firstTimeLaunch = YES;
        
        ((AppDelegate *)[UIApplication sharedApplication].delegate).shouldStartCommunicationModule = YES;
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.startView removeFromSuperview];
    self.startView = nil;
    
    [self.timer invalidate];
    self.timer = nil;
    
    self.loginView = nil;
    self.userHeaderView = nil;
    self.loginWithPasswordViewController = nil;
    self.pinEnteringViewController = nil;
    self.passwordChangeViewController = nil;
    self.userSessionService = nil;
    self.qliqUserService = nil;
    self.keychainService = nil;
    self.lastLoggedUser = nil;
    self.lastLoggedUserGroup = nil;
    self.failedAttemptsController = nil;
    
}

- (void)didReceiveMemoryWarning {
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    
    [[ThumbnailService sharedService] emptyCache];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    CGFloat y = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? -self.loginView.headerView.height : 0.0f;
    
    __weak LoginViewController *weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        
        weakSelf.loginView.headerView.y = y;
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    // Must be called first
    
    DDLogSupport(@"viewWillAppear");
    
    [self loadSettings];
    [super viewWillAppear:animated];
    //[self setupUI];
    [self insertStartView];
    [self updateUIForDeviceLocked:appDelegate.currentDeviceStatusController.isLocked
                            wiped:appDelegate.currentDeviceStatusController.isWiped];
    [self forceRotateToPortraitIfNeeded];
    self.viewDidAppear = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    
    DDLogSupport(@"viewDidAppear");
    
    [super viewDidAppear:animated];
    self.viewDidAppear = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onProgressHoodCancelLoginButtonPressedNotification:)
                                                 name:SVProgressHUDDidDismissButtonTappedEventNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SVProgressHUDDidDismissButtonTappedEventNotification
                                                  object:nil];
}


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
     DDLogSupport(@"LoginViewController: viewDidLoad");
     self.loginView = [[LoginView alloc] initWithFrame:self.view.bounds];
     self.loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
     //loginView.autoresizesSubviews = YES;
     [self.loginView.contentView addSubview:self.loginWithPasswordViewController.view];
     [self.loginView.contentView addSubview:self.pinEnteringViewController.view];
     [self.loginView.contentView addSubview:self.passwordChangeViewController.view];
     
     self.userHeaderView = [[UserHeaderView alloc] init];
     self.loginView.headerView = self.userHeaderView;
     [self.view addSubview:self.loginView];
     
     UIView * parent = [[UIApplication sharedApplication] keyWindow];
     
     self.startView = [[StartView alloc] initWithFrame:parent.bounds];
     self.startView.shouldHideStatusBar = YES;
     
     [super viewDidLoad];
 }


- (void)viewDidUnload {
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (self.startView.superview == nil && self.viewDidAppear) {
        
        return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    } else {
        
        return interfaceOrientation == UIInterfaceOrientationPortrait;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    
    if (self.startView.superview == nil && self.viewDidAppear) {
        
        return UIInterfaceOrientationMaskAll;
    } else {
        
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark -
#pragma mark PasswordChangeViewControllerDelegate

- (void)passwordChangeControllerNeedsRelogin {
    
    [self showPasswordView];
    [self.loginWithPasswordViewController clearPassword];
    [self.loginWithPasswordViewController focusPassword];
}

#pragma mark -
#pragma mark LoginWithPasswordViewControllerDelegate

- (void)loginWithUsername:(NSString *)_username andPassword:(NSString *)_password {
    
#ifdef USE_LOCAL_LOGIN_ONLY
    [self processLocalLoginForUser:[_username lowercaseString] withPassword:[[KeychainService sharedService] stringToBase64:_password]];
#else
    //if ([_password length] == 0)  _password = TEST_ACCOUNT_PASSWORD;
    
	if ([_username length] <= 0) {
        
		[self didFailLogInWithReason:@"Email cannot be empty"];
	} else if([_password length] <= 0) {
        
		[self didFailLogInWithReason:@"Password cannot be empty"];
	} else {
        
		self.loginWithPin = NO;
        // User Manually Logged in
        self.manualLogin = YES;
        ((AppDelegate *)[UIApplication sharedApplication].delegate).shouldStartCommunicationModule = YES;
        [self processLoginForUser:[_username lowercaseString] withPassword:[[KeychainService sharedService] stringToBase64:_password] isAutoLogin:NO forceLocalLogin:NO];
	}
    
#endif
}

- (void)retrievePassword {
    
    ResetPasswordController *ctrl = [[ResetPasswordController alloc] init];
    ctrl.previousControllerTitle = @"Back";
    [self.navigationController pushViewController:ctrl animated:YES];
}

#pragma mark -
#pragma mark NSNotification observing

- (void)onProgressHoodCancelLoginButtonPressedNotification:(NSNotification *)notification {
    
    ((AppDelegate *)[UIApplication sharedApplication].delegate).shouldStartCommunicationModule = NO;
    
    self.userSessionService.shouldStopSyncFlag = YES;
    
    [SVProgressHUD showErrorWithStatus:@"Login cancelled"];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        
        if ([self.lastLoggedUser email]) {
            [self.loginWithPasswordViewController prefillUsername:[self.lastLoggedUser email]];
        }
        [self.loginWithPasswordViewController focusPassword];
    });
}

#pragma mark -
#pragma mark UserSessiomServiceDelegate

-(void)didLogIn {
    
    [self openCrypto];
}

- (void)openCrypto {
    
    NSString *userName = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *clearTextPassword = [[UserSessionService currentUserSession].sipAccountSettings.password base64DecodedString];
    NSString *publicKeyMd5FromWebServer = [UserSessionService currentUserSession].publicKeyMd5FromWebServer;
    
    BOOL needToDownloadKeyPair = NO;
    Crypto *crypto = [Crypto instance];
    
    if ([crypto openForUser: userName: clearTextPassword] == NO) {
        
        DDLogError(@"Cannot open existing key pair");
        needToDownloadKeyPair = YES;
    } else {
        
        if ([publicKeyMd5FromWebServer length] > 0) {
            
            NSString *pubKeyMd5 = [[crypto publicKeyString] md5];
            if ([publicKeyMd5FromWebServer compare:pubKeyMd5] != NSOrderedSame) {
                
                DDLogError(@"The web server has a different key pair then I do");
                needToDownloadKeyPair = YES;
            } else {
                
                DDLogSupport(@"My public key's MD5 matches value from web server: %@", publicKeyMd5FromWebServer);
            }
        } else {
            
            DDLogError(@"PUBKEY_MD5 from web server is empty!");
        }
    }
    
    if (needToDownloadKeyPair) {
        
        DDLogSupport(@"Trying to download key pair from web server");
        [[GetKeyPair sharedService] getKeyPairCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess) {
                
                NSString *pubKeyMd5 = [[[Crypto instance] publicKeyString] md5];
                DDLogSupport(@"Downloaded new key pair. Public key's MD5: %@", pubKeyMd5);
                [self performLogin];
            } else {
                
                [SVProgressHUD dismiss];
                [self showAlertWithTitle:@"Cannot login" message:[error localizedDescription]];
                [self didFailLogInWithReason:[error localizedDescription]];
            }
        }];
    } else {
        
        [self performLogin];
    }
}

- (void)performLogin {

        SipAccountSettings *sipAccountSettings = [UserSessionService currentUserSession].sipAccountSettings;
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
    });*/


    //after successful login, purge any network status message older than 7 days
    DDLogSupport(@"Purging network logs older than 7 days");
    [[NetworkStatusDBService sharedService] purgeNetworkStatusMsgs];
    
    NSString *prevUserName = [[[KeychainService sharedService] getUsername] copy];
    NSLog(@"sipAccountSettings.username: %@", sipAccountSettings.username);
    NSLog(@"prevUserName: %@", prevUserName);
    if (![sipAccountSettings.username isEqualToString:prevUserName]) {
        
        // The user has switched to a different account, erase old pin
        DDLogSupport(@"User has switched accounts, erasing PIN. Old account: '%@', new: '%@'", prevUserName, sipAccountSettings.username);
        [[KeychainService sharedService] clearPin];
        [[KeychainService sharedService] clearArchivedPins];
    }

    [[KeychainService sharedService] saveUsername:sipAccountSettings.username];
    [[KeychainService sharedService] savePassword:sipAccountSettings.password];
    
	
    QliqUser *user = [UserSessionService currentUserSession].user;
    [self.userSessionService saveLastLoggedInUser:user];

    [self.userSessionService saveLastUserSession:[UserSessionService currentUserSession]];

    if ([[KeychainService sharedService] pinAvaliable] && !self.loginWithPin && !self.loginWithAutoLogin) {
        
        DDLogSupport(@"User logged in with password instead of PIN, claring old PIN");
        [[KeychainService sharedService] clearPin];
        [self unskipPinSetUp];
//        [self.delegate userDidLogin];
    }
    
    if (![UserSessionService currentUserSession].userSettings.securitySettings.rememberPassword && !self.loginWithPin && self.manualLogin) {
        
        [self showSetUpNewPinQuestion];
    }
    else {
        
        [self.delegate userDidLogin];
    }
    [self.loginWithPasswordViewController clearPassword];

    [self.failedAttemptsController clear];
    
    [appDelegate.busyAlertController sendSipRegisterIfNeeded];
}

-(void)didStartProcessingGroupInfo {
    
    [SVProgressHUD setStatus:@"Processing group info"];
}

-(void)didFailLogInWithReason:(NSString *)reason {
    
    [self notifyLoginFail:reason];
    if(self.loginWithPin) {
        
        [self.pinEnteringViewController reset:NO];
    } else {
        
        [self.loginWithPasswordViewController focusPassword];
    }
}

- (void)didMigrateDBWithResult:(BOOL)result {
    
    if (!result)
        [self showAlertWithTitle:@"Migration" message:result ? @"success" : @"failed"];
}

#pragma mark - Login Methods

- (BOOL)doLocalLoginIfPossible:(NSString *)username withPassword:(NSString *)password withError:(NSError **)error {
    
    BOOL usernameMatches = [[[KeychainService sharedService] getUsername] isEqualToString:username];
    BOOL canLocalLogin = self.lastLoggedUser != nil;
    
    if (!canLocalLogin) {
        
        if (error != nil) {
            
            *error = [NSError errorWithCode:0 description:@"Cannot login without internet connection: No previous saved session"];
        }
    } else if (!usernameMatches) {
        
        canLocalLogin = NO;
        if (error != nil) {
            
            *error = [NSError errorWithCode:0 description:@"Cannot login without internet connection as a different user"];
        }
    }
    
    if (canLocalLogin) {
        
        NSString *clearTextPassword = [password base64DecodedString];
        Crypto *crypto = [Crypto instance];
        if ([crypto openForUser:username: clearTextPassword] == NO) {
            
            canLocalLogin = NO;
            DDLogError(@"Cannot open existing key pair before local login");
            if (error != nil) {
                
                *error = [NSError errorWithCode:0 description:@"Cannot open local key pair"];
            }
        } else {
            NSString *storedUsername = [[KeychainService sharedService] getUsername];
            NSString *storedPassword = [[KeychainService sharedService] getPassword];
            
            if ([storedUsername isEqualToString:username] && [storedPassword isEqualToString:password]) {
                [self.userSessionService loadLastUserSession];
                [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
                if ([[QliqUserDBService sharedService] getAllOtherUsersCount] == 0) {
                    DDLogSupport(@"Skipping local login because DB is empty");
                    canLocalLogin = NO;
                    if (error) {
                        *error = nil;
                    }
                }
            }
        }
    }
    
    if (canLocalLogin) {
        dispatch_async_main(^{
           [self processLocalLoginForUser:username withPassword:password];
        });
        return YES;
    } else {
        
        if (error && *error) {
            [self showAlertWithTitle:@"Login failed" message:[*error localizedDescription]];
        }
        
        return NO;
    }
}

- (void)processLoginForUser:(NSString *)username withPassword:(NSString *)password isAutoLogin:(BOOL)isAutoLogin forceLocalLogin:(BOOL)forceLocal {
    
    DDLogSupport(@"Login with '%@:[BLOCKED]' isAutoLogin:%d forceLocal:%d", username, isAutoLogin, forceLocal);
    
    if (self.preopenDbSemaphore != nil) {
        DDLogSupport(@"Waiting for db preopening in bg thread");
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 5LL * NSEC_PER_SEC); // 5 sec in the future
        if (dispatch_semaphore_wait(self.preopenDbSemaphore, timeout) == 0) {
            DDLogSupport(@"Finished waiting for db preopening in bg thread");
        } else {
            DDLogError(@"Waiting for db preopening timed out");
        }
        self.preopenDbSemaphore = nil;
        
        // DB preloading code loads previous session. If user changed email on the login screen
        // we need to update it so we call the right webserver
        [UserSessionService currentUserSession].user.email = username;
    }

    self.loginWithAutoLogin = isAutoLogin;
    [UIView setAnimationsEnabled:NO];
    NSString *statusTitle;
    
    if (isAutoLogin) {
        statusTitle = NSLocalizedString(@"Auto Login", @"Auto Login");
    } else {
        
        statusTitle = NSLocalizedString(@"Login", @"Login");
    }
    
    [SVProgressHUD showWithStatus:statusTitle maskType:SVProgressHUDMaskTypeBlack dismissButtonTitle:@"Cancel"];
    
    BOOL usernameMatches = [[[KeychainService sharedService] getUsername] isEqualToString:username];
    if (usernameMatches) {
        
        NSDate *lastLoggedInDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastLoggedIn];
        if (NSOrderedDescending == [lastLoggedInDate compare:[NSDate dateWithTimeIntervalSinceNow:-24*60*60]]) {
            
            //Do fast sync. local login
            forceLocal = YES;
        }

    }
    
    if (forceLocal) {
        DDLogSupport(@"Trying to do fast (local) login");
        NSError *error;
        if ([self doLocalLoginIfPossible:username withPassword:password withError:&error]) {
            [UIView setAnimationsEnabled:YES];
            [self.userSessionService resumePagedContactsIfNeeded];
            return;
        }
        DDLogError(@"Couldn't do fast (local) login");
    }
    
    DDLogSupport(@"Doing regular (network) login");
    [self.userSessionService logInWithUsername:username andPassword:password completitionBlock:^(CompletitionStatus status, id result, NSError *error) {
        
        if (error) {
            
            DDLogSupport(@"login request error: %@",error);
            [SVProgressHUD dismiss];
            
            switch (error.code) {
                    
                case ErrorCodeInvalidRequest: {
                    
                    // Incompatable: upgrade, cancel
                    UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Version Incompatibility" message:@"Please upgrade and try again" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upgrade", nil];
                    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                        
                        if (alert.cancelButtonIndex != buttonIndex) {
                            
                            [appDelegate getNewVersion];
                        }
                    }];
                    break;
                }
                case ErrorCodeLoginInvalidCredentials: {
                    
                    [self loginFailedWithInvalidCredentials];
                    if (![self.failedAttemptsController isLocked]) {
                        NSDictionary *errorDict = (NSDictionary *)result;
                        BOOL isRemoteAuth = NO;
                        NSString *actionUrl = (NSString *)[errorDict objectForKey:@"action_url"];
                        NSString *actionTitle = (NSString *)[errorDict objectForKey:@"action_label"];
                        if ([errorDict objectForKey:@"remote_auth_error"] != nil) {
                            isRemoteAuth = YES;
                        }
                        [self showInvalidLoginAlert:@"Login failed" message:[error localizedDescription] email:username isRemoteAuth:isRemoteAuth actionTitle:actionTitle actionUrl:actionUrl];
                    }
                    break;
                }
                case ErrorCodeLoginClientHasOldVersion: {
                    
                    UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Unsupported Version" message:@"This app version is not supported, please upgrade and try again" delegate:nil cancelButtonTitle:@"Upgrade Now" otherButtonTitles:nil];
                    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                        
                        [appDelegate getNewVersion];
                    }];
                    break;
                }
                case ErrorCodeLoginServerSideProblem: {
                    
                    [self showAlertWithTitle:@"Server Error" message:@"Please contact qliqSOFT suppport@qliqsoft.com"];
                    break;
                }
                case ErrorCodeLoginServerIsBeingUpgraded: {
                    
                    [self showAlertWithTitle:@"Server Upgrade" message:@"qliqSOFT Cloud server is being upgraded. Please try later. Thanks for your support"];
                    break;
                }
                default:{
                    if (isSSLErrorCode(error.code)) {
                        
                        NSString *message = @"Please perform Device Settings -> General -> Reset -> Reset Network Settings and try to Login again.\nIf the problem persists, you may be connecting through a wi-fi network that contains a firewall.\nPlease try connecting through a connection other than wi-fi to see if this resolves the issue.";
                        [self showAlertWithTitle:@"SSL Connection Error" message:message];
                    } else if (isNetworkErrorCode(error.code)) {
                        
                        [self doLocalLoginIfPossible:username withPassword:password withError:&
                         error];
                    } else {
                        
                        [self showAlertWithTitle:@"General Error" message:[error localizedDescription]];
                    }
                    break;
                }
            }
        } else {
            
            [self.loginWithPasswordViewController maskPassword];
            
            //check for temp_password field. If =1 then present password change view
            NSNumber *isTempPassword = result[kLoginResponseShowResetPasswordAlertKey];
            if (isTempPassword && [isTempPassword isKindOfClass:[NSNumber class]] && (YES == [isTempPassword boolValue])) {
                
                [SVProgressHUD dismiss];
                DDLogSupport(@"Logged in with Temporary Password");
                
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Logged in with Temporary Password!"
                                                                              message:@"You logged in with password created by Admin. You now need to setup your own password to use the App."
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"Set new password"
                                                                    otherButtonTitles:nil];
                [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                    
                    [self showPasswordChangeView];
                }];
                
            }
        }
    }];
    [UIView setAnimationsEnabled:YES];
}

- (void)processLocalLoginForUser:(NSString *)username withPassword:(NSString *)password {

    if (!appDelegate.currentDeviceStatusController.isLocked) {
        
        DDLogSupport(@"Offline Login with '%@:[BLOCKED]",username);
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Offline Login", @"Offline Login") maskType:SVProgressHUDMaskTypeBlack];
        
        NSString *storedUsername = [[KeychainService sharedService] getUsername];
        NSString *storedPassword = [[KeychainService sharedService] getPassword];
        
        if ([storedUsername isEqualToString:username] && [storedPassword isEqualToString:password]) {
            
            [self.userSessionService loadLastUserSession];
            
            //prepareDBForUserSession should be called before getUserConfigFromDB for successfuly read userConfig from previous session
            [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
            
            [[GetUserConfigService sharedService] getUserConfigFromDB];
            
            [self performLogin];
        } else {
            
            if (!storedUsername || !storedUsername) {
                
                [self showAlertWithTitle:@"Login failed" message:@"Can't process local login. No stored session"];
            } else {
                
                [self showAlertWithTitle:@"Login failed" message:@"Can't process local login. Invalid username/password"];
                [self loginFailedWithInvalidCredentials];
            }
        }
        
        [UserSessionService currentUserSession].local = YES;
        
    } else {
        
        [self showAlertWithTitle:@"Login failed" message:@"This device is locked"];
    }
}

#pragma mark -
#pragma mark Private

- (void)loginFailedWithInvalidCredentials {
    
    DDLogSupport(@"Login (or idle unlock) failed because password or pin is wrong");
    [self.failedAttemptsController increment];
    
    if ([self.failedAttemptsController shouldLock] == YES) {
        [self.view endEditing:YES];
        [self.failedAttemptsController lock];
    }
}

- (void)showPasswordView {
    
    [self changeRightNavigationItemTitle:@"Login"];
    [self.loginView.contentView bringSubviewToFront:self.loginWithPasswordViewController.view];
}

- (void)showPinView {
    
    [self changeRightNavigationItemTitle:@"Enter pin"];
	[self.loginView.contentView bringSubviewToFront:self.pinEnteringViewController.view];
}

- (void)showPasswordChangeView {
    
    [self changeRightNavigationItemTitle:@"Update password"];
    [self.loginView.contentView bringSubviewToFront:self.passwordChangeViewController.view];
    [self.passwordChangeViewController focusOnPasswordField];
}

- (void)setCustomBackItemWithTitle:(NSString *)title {
    
    CustomBackButtonView *backView = [[CustomBackButtonView alloc] initWithFrame:CGRectMake(0, 0, 320 / 2.0, 40)];
	backView.accessibilityLabel = @"CustomBackNavButton";
    
    if ([title length] > 0) {
        
        [backView addTarget:self withAction:@selector(goBack)];
        [backView setTitle:title];
    } else {
        
        UIImage *logoImage = [[[QliqModulesController instance] getPresentedModule] moduleLogo];
        if(!logoImage) logoImage = [UIImage imageNamed:@"qliq_logo.png"];
        [backView setImage:logoImage];
        [backView addTarget:self withAction:@selector(presentFeedback:)];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backView];
	self.navigationItem.leftBarButtonItem.accessibilityLabel= @"CustomBackButton";
    self.navigationItem.leftBarButtonItem.width = 170;
	
    [self performSelector:@selector(setBackButtonView:) withObject:backView];
    [self performSelector:@selector(updateNetworkIndicator)];
}

- (void)presentFeedback:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

- (void)changeRightNavigationItemTitle:(NSString *)title {
    
    if (self.changesRightNavigationItem) {
        
        self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:title buttonImage:nil buttonAction:nil];
#if ShowErrorReport
        QliqButton *reportButton = [[QliqButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30) style:QliqButtonStyleRoundedBlue];
        [reportButton setTitle:@"Report" forState:UIControlStateNormal];
        [reportButton addTarget:self action:@selector(didReportErrorPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem  = [self itemWithTitle:nil button:reportButton];
#endif
    }
}

#if ShowErrorReport
- (void)didReportErrorPressed:(QliqButton *) button {
    
    FeedbackViewController * feedbackVC = [[FeedbackViewController alloc] initWithReportType:ReportTypeError];
    feedbackVC.previousControllerTitle = @"Support";
    [self.navigationController pushViewController:feedbackVC animated:YES];
}
#endif

- (void)showSetUpNewPinQuestion {
    
	NSString *str = [NSString stringWithFormat:@"%@-%@", [UserSessionService currentUserSession].sipAccountSettings.username, @"SkippedPinSetUp"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:str] == nil) {
        
		SetUpNewPinQuestionViewController *tmpVc = [[SetUpNewPinQuestionViewController alloc] init];
		tmpVc.delegate = self;
		[self.navigationController pushViewController:tmpVc animated:YES];
    } else {
        
		[self.delegate userDidLogin];
	}
}

- (void)showInvalidLoginAlert:(NSString *)title message:(NSString *)message {
    
    [self showAlertWithTitle:title message:message];
}

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message {
    
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert showWithDissmissBlock:NULL];
}

- (void)showInvalidLoginAlert:(NSString*)title message:(NSString*)message email:(NSString*) email isRemoteAuth:(BOOL)isRemoteAuth actionTitle:(NSString *)actionTitle actionUrl:(NSString *)actionUrl {
    NSString *secondButtonTitle = actionTitle;
    
    if ([secondButtonTitle length] == 0 && !isRemoteAuth) {
        secondButtonTitle = @"Forgot Password";
    }
    
    UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Retry" otherButtonTitles:secondButtonTitle, nil];
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        // code to take action depending on the value of buttonIndex
        if (buttonIndex != alert.cancelButtonIndex) {
            if ([actionUrl length] > 0) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionUrl]];
            } else {
                NSLog(@"forgot password pressed: %d",buttonIndex);
                ResetPasswordController *ctrl = [[ResetPasswordController alloc] init];
                ctrl.previousControllerTitle = @"Back";
                ctrl.email = email;
                [self.navigationController pushViewController:ctrl animated:YES];
            }
        } else {
            
            [self.loginWithPasswordViewController unmaskPassword];
            NSLog(@"Cancel pressed: %d",buttonIndex);
        }
    }];
}



- (void)notifyLoginFail:(NSString*)reason {
    
    [SVProgressHUD dismiss];
}

- (void)presentSettings:(id)sender {
}

- (BOOL)showNetworkIndicator {
    
    return [appDelegate.network.reachability restReachable];
}

- (void)setupUI {
    
    [self.view endEditing:YES];
    [self closeKeyboard];
    
    self.loginWithPasswordViewController.view.frame = self.view.bounds;
    self.pinEnteringViewController.view.frame = self.view.bounds;
    self.passwordChangeViewController.view.frame = self.view.bounds;
    
    if (self.lastLoggedUser == nil) {
        
        self.userHeaderView.hidden = YES;
    } else {
        
        self.userHeaderView.hidden = NO;
        [self.userHeaderView fillWithContact:self.lastLoggedUser andGroup:(QliqGroup *)self.lastLoggedUserGroup];
    }
    
    if (self.lastLoggedUser != nil && [[KeychainService sharedService] pinAvaliable]) {
        
        [self showPinView];
    } else {
        
        [self showPasswordView];
    }
    
    [self.loginView setNeedsLayout];
}

- (void)closeKeyboard {
    
    [self.pinEnteringViewController closeKeyboard];
    [self.loginWithPasswordViewController closeKeyboard];
    [self.passwordChangeViewController closeKeyboard];
}

typedef enum {EnterModePin, EnterModePassword, EnterModeChangePassword} EnterMode;

- (void)updateFocusForEnterMode:(EnterMode)mode {
    
    switch (mode) {
        case EnterModeChangePassword:
            
            [self.passwordChangeViewController reset];
            break;
        case EnterModePin:
            
            [self.pinEnteringViewController reset:NO];
            break;
        case EnterModePassword:
            
            if (!self.lastLoggedUser) {
                
                [self.loginWithPasswordViewController focusUsername];
            } else {
                
                [self.loginWithPasswordViewController prefillUsername:[self.lastLoggedUser email]];
                
                NSString *storedPassword = [[KeychainService sharedService] getPassword];
                BOOL rememberPassword = [UserSessionService currentUserSession].userSettings.securitySettings.rememberPassword;
                if (rememberPassword && [storedPassword length] > 0) {
                    
                    storedPassword = [storedPassword base64DecodedString];
                    [self.loginWithPasswordViewController prefillPassword:storedPassword];
                } else {
                    
#ifndef DEBUG
                    [self.loginWithPasswordViewController clearPassword];
#endif
                }
                [self.loginWithPasswordViewController focusPassword];
            }
            break;
        default:
            break;
    }
}

- (void)openKeyboard {
    
    EnterMode mode = [[KeychainService sharedService] pinAvaliable] ? EnterModePin : EnterModePassword;
    [self updateFocusForEnterMode:mode];
}

/**
 Call 'openKeyboard' method only if app is in active state.
 If app is inactive, then wait and call when app become active
 */
- (BOOL)isApplicationNotActive {
    
    return [[UIApplication sharedApplication]applicationState] != UIApplicationStateActive;
}

- (void)wantOpenKeyboard {

    void (^localBlock)() = ^(){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self openKeyboard];
        });
    };
    
    if ([self isApplicationNotActive]) {
        
        [NSNotificationCenter notifyOnceForNotification:UIApplicationDidBecomeActiveNotification usingBlock:^(NSNotification *note) {
            
            localBlock();
        }];
    } else {
        
        localBlock();
    }
}

- (void)updateUIForDeviceLocked:(BOOL)locked wiped:(BOOL)wiped {
    
    StartViewType type = [self.startView type];
    
    DDLogSupport(@"isDeviceLocked return locked = %d, wiped = %d",locked,wiped);
    
    if ([self.delegate respondsToSelector:@selector(shouldAppearStartView)] && [self.delegate shouldAppearStartView]) {
        
        type = StartViewTypeFirstLaunch;
    }
    
    if (locked) {
        
        type = StartViewTypeLock;
    } else if (wiped) {
        
        type = StartViewTypeWipe;
    }
    
    if ([self.failedAttemptsController isLocked]) {
        
        type = StartViewTypeAttemptsLock;
    }
    
    void(^didLoginBlock)(void) = ^{
        
        DDLogSupport(@"didLoginBlock called");
        
        [self setupUI];
        [self.startView removeFromSuperviewAnimation:^{
            
            [self.navigationController.view layoutSubviews];
        } complete:nil];
        
        [self.failedAttemptsController clear];
        
        NSString *storedUn = [[KeychainService sharedService] getUsername];
        NSString *storedPassword = [[KeychainService sharedService] getPassword];
        BOOL rememberPassword = [UserSessionService currentUserSession].userSettings.securitySettings.rememberPassword;
        BOOL enforcePin = [UserSessionService currentUserSession].userSettings.securitySettings.enforcePinLogin;
        if (!rememberPassword && !enforcePin && [[KeychainService sharedService] isDeviceLockEnabled]) {
            rememberPassword = YES;
        }
        if (rememberPassword && self.shouldSkipAutoLogin) {
            DDLogSupport(@"Not doing autologin becuase shouldSkipAutoLogin is true");
            rememberPassword = NO;
        }
        
        if (!self.wasAutoLoginTried && rememberPassword && [storedUn length] > 0 && [storedPassword length] > 0) {
            self.wasAutoLoginTried = YES;
            DDLogSupport(@"Doing autologin");
            [self processLoginForUser:storedUn withPassword:storedPassword isAutoLogin:YES forceLocalLogin:NO];
        } else {

            if ([self.userSessionService loadLastUserSession]) {
                if (self.preopenDbSemaphore == nil) {
                    self.preopenDbSemaphore = dispatch_semaphore_create(0);
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // (pre)open db now so there is no delay when user enters PIN
                    DDLogSupport(@"Preopening database on the login screen");
                    //prepareDBForUserSession should be called before getUserConfigFromDB for successfuly read userConfig from previous session
                    [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
                    DDLogSupport(@"Signaling db preopening finished");
                    dispatch_semaphore_signal(self.preopenDbSemaphore);
                });
            }
            
            [self wantOpenKeyboard];
        }
    };
    
    void(^didFirstRunLoginBlock)(void) = ^{
        
        DDLogSupport(@"didFirstRunLoginBlock called");

        [self setupUI];
        [self.startView removeFromSuperviewAnimation:^{
            
            [self.navigationController.view layoutSubviews];
        } complete:nil];
        
        [self wantOpenKeyboard];
    };
    
    //if wiped, locked or first time launching - show splash screen
    if ( type != StartViewTypeNone ){
        
        [self.startView setType:type animated:YES];
        
        [self.startView setDidDemoBlock:^{
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://vimeo.com/46937303"]];
        }];
        
        __weak LoginViewController *weakSelf = self;
        [self.startView setDidRegisterBlock:^{
            
            [weakSelf.startView removeFromSuperviewAnimation:^{
                
                [weakSelf.navigationController.view layoutSubviews];
            } complete:nil];
            
            
            RegisterUserViewController *registerVC = [[RegisterUserViewController alloc] init];
            registerVC.previousControllerTitle = @"Cancel";
            [registerVC setDidRegisterBlock:^(QliqUser *user){
                
                weakSelf.lastLoggedUser = user;
                didLoginBlock();
            }];
            [weakSelf.navigationController pushViewController:registerVC animated:YES];
            
        }];
        
        [self.startView setUnlockBlock:^{
            DDLogSupport(@"setUnlockBlock called");

            [SVProgressHUD showWithStatus:@"Unlocking" maskType:SVProgressHUDMaskTypeBlack];
            [appDelegate.currentDeviceStatusController refreshRemoteStatusWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                
                [SVProgressHUD dismiss];
                if (!error) {
                    
                    if ([appDelegate.currentDeviceStatusController isLocked]) {
                        
                        UIAlertView_Blocks * alertView = [[UIAlertView_Blocks alloc] initWithTitle:@"Locked" message:@"Please unlock the App from the Cloud by logging into your account at qliqsoft.com." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
                        [alertView showWithDissmissBlock:NULL];
                    } else {
                        
                        didLoginBlock();
                    }
                } else {
                    
                    [weakSelf showAlertWithTitle:@"Can't unlock device" message:[error localizedDescription]];
                }
            }];
        }];
        
        [self.startView setDidLoginBlock:didFirstRunLoginBlock];
        
    } else {
        
        didLoginBlock();
    }
    
}

- (void)loadSettings {
    
    self.lastLoggedUser = [self.userSessionService getLastLoggedInUser];
    self.lastLoggedUserGroup = [self.userSessionService getLastLoggedInUserGroup];
    [UserSessionService currentUserSession].userSettings = [[[UserSettingsService alloc] init] getSettingsForUser: self.lastLoggedUser];
}

- (void)insertStartView {
    
    UIView * parent = self.navigationController.view;
    self.startView.frame = parent.bounds;
    [parent addSubview:self.startView];
    [self.startView setType:StartViewTypeNone animated:NO];
}

- (BOOL)isCurrentlyInLandscape {
    
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

- (BOOL) isPinExpired {
    NSDate *lastPinSetDate = [KeychainService sharedService].getPinLastSetTime;
    NSDate *now = [NSDate date];
    NSTimeInterval expirePinAfter = [UserSessionService currentUserSession].userSettings.securitySettings.expirePinAfter;
    
    if (expirePinAfter <= 0)
        return NO;
    
    NSDate *expirePinDate = [lastPinSetDate dateByAddingTimeInterval:expirePinAfter];
    
    if ([expirePinDate compare:now] == NSOrderedAscending)
    {
        DDLogSupport(@"PIN Expired. (%@ < %@)", expirePinDate, now);
        return YES;
    } else {
        return NO;
    }
}

- (void)forceRotateToPortraitIfNeeded {
    
//    BOOL supportLandscape = [self supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscape;
//    BOOL needRotateToPortrait = [self isCurrentlyInLandscape] && !supportLandscape;
//    
//    if (needRotateToPortrait) {
//        OnlyPortraitController *controller = [OnlyPortraitController new];
//        [self dismissViewControllerAnimated:NO completion:nil];
//    }
}

#pragma mark -
#pragma mark PinEnteringViewControllerDelegate

- (void)pinEnteringViewController:(PinEnteringViewController *)ctrl didEnterPin:(NSString *)pin {
    
    NSString *enteredPin = [[KeychainService sharedService] stringToBase64:pin];
    if ([[[KeychainService sharedService] getPin] isEqualToString:enteredPin]) {
        
        
        if (self.isPinExpired == YES)
        {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"PIN expired!"
                                                                          message: @"Please setup a new PIN"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil, nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
              
                PinEnteringViewController *pinSetUpController = [[PinEnteringViewController alloc] init];
                pinSetUpController.setupNewPin = YES;
                pinSetUpController.setupPinFromSettings = NO;
                pinSetUpController.delegate = self;
                [self.navigationController pushViewController:pinSetUpController animated:YES];
                
            }];
        } else {
            NSString *storedUn = [[KeychainService sharedService] getUsername];
            NSString *storedPassword = [[KeychainService sharedService] getPassword];

            self.loginWithPin = YES;
            ((AppDelegate *)[UIApplication sharedApplication].delegate).shouldStartCommunicationModule = YES;
            [self processLoginForUser:storedUn withPassword:storedPassword isAutoLogin:NO forceLocalLogin:NO];
        }
    } else {
        
        [self loginFailedWithInvalidCredentials];
        if (![self.failedAttemptsController isLocked]) {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Forgot PIN?"
                                                                          message: @"Try login with password to setup a new PIN"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Try Password"
                                                                otherButtonTitles:@"Retry PIN", nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                if (alert.cancelButtonIndex == buttonIndex) {
                    [self switchToPasswordLogin];
                } else {
                    [self.pinEnteringViewController reset:NO];
                }
            }];
        }
    }
}

- (void)didSetUpNewPin:(NSString *)pin {
    
    [[KeychainService sharedService] saveUsername:[UserSessionService currentUserSession].sipAccountSettings.username];
    [[KeychainService sharedService] savePassword:[UserSessionService currentUserSession].sipAccountSettings.password];
    [[KeychainService sharedService] savePin: pin];
    
    [self.navigationController popViewControllerAnimated:NO];
//    [self.delegate userDidLogin];
}

- (void)switchToPasswordLogin {
    
    [self showPasswordView];
    [self updateFocusForEnterMode:EnterModePassword];
}

- (void)willConfirmPin {
    
    [self changeRightNavigationItemTitle:@"Confirm PIN"];
}

- (void)didFailedToConfirmPin {
    
    [self changeRightNavigationItemTitle:@"Enter PIN"];
}


#pragma mark -
#pragma mark SetUpNewPinQuestionViewControllerDelegate

- (BOOL)shouldEnforcePin {
    
    return [[[[UserSessionService currentUserSession] userSettings] securitySettings] enforcePinLogin];
}

- (void)setUpNewPin {
    
    [self.navigationController popViewControllerAnimated:NO];
    PinEnteringViewController *pinSetUpController = [[PinEnteringViewController alloc] init];
    pinSetUpController.setupNewPin = YES;
	pinSetUpController.setupPinFromSettings = NO;
    pinSetUpController.delegate = self;
    [self.navigationController pushViewController:pinSetUpController animated:YES];
}

- (void)skipPinSetUp {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *str = [NSString stringWithFormat:@"%@-%@",[UserSessionService currentUserSession].sipAccountSettings.username,@"SkippedPinSetUp"]; 
    [userDefaults setObject:[NSNumber numberWithInt:1] forKey:str];
    [userDefaults synchronize];
    [self.navigationController popViewControllerAnimated:NO];
    [self.delegate userDidLogin];
}

- (void)unskipPinSetUp {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *str = [NSString stringWithFormat:@"%@-%@",[UserSessionService currentUserSession].sipAccountSettings.username,@"SkippedPinSetUp"];
    [userDefaults removeObjectForKey:str];
    [userDefaults synchronize];
}

@end
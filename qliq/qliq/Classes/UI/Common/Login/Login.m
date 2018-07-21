//
//  Login.m
//  qliq
//
//  Created by Valerii Lider on 5/28/14.
//
//

#import "Login.h"

#import "LoginWithPasswordViewController.h"
#import "LoginWithPinViewController.h"
#import "AttemptsLockContainerView.h"
#import "FailedAttemptsController.h"

#import "NSString+MKNetworkKitAdditions.h"
#import "FailedAttemptsController.h"
#import "RegisterAccountService.h"
#import "UserSettingsService.h"
#import "BusyAlertController.h"
#import "NSString+Base64.h"
#import "KeychainService.h"
#import "GetKeyPair.h"
#import "Crypto.h"
#import "DBUtil.h"
#import "OnCallGroup.h"
#import "GetAllOnCallGroupsService.h"
#import "ReportIncidentService.h"

#import "FirstLaunchViewController.h"

#import "QliqUserDBService.h"
#import "QliqModulesController.h"

#import "MainViewController.h"
#import "qxlib/platform/ios/QxPlatfromIOS.h"

#define errorDomainLoginWithPin @"com.qliq.LoginWithPin"

@interface Login () <UserSessionServiceDelegate>

//view controllers
@property (weak, nonatomic) LoginWithPasswordViewController *loginViewController;
@property (weak, nonatomic) LoginWithPinViewController *pinViewController;

//user
@property (strong, nonatomic) dispatch_semaphore_t preopenDbSemaphore;

//@property (nonatomic, assign) BOOL loginWithAutoLogin;

@property (nonatomic, assign) BOOL wasAutoLoginTried;

@end

@implementation Login

+ (Login *)sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[Login alloc] init];
        
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //init failed attempts controller
        self.failedAttemptsController = [[FailedAttemptsController alloc] init];
        
        //init user session
        self.userSessionService = [[UserSessionService alloc] init];
        self.userSessionService.delegate = self;
        self.wasAutoLoginTried = NO;
        
        [self loadSettings];
        
        //        if ([_userSessionService loadLastUserSession]) {
        //            if (!_preopenDbSemaphore)
        //                _preopenDbSemaphore = dispatch_semaphore_create(0);
        //
        //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //                // (pre)open db now so there is no delay when user enters PIN
        //                DDLogSupport(@"Preopening database on the login screen");
        //                //prepareDBForUserSession should be called before getUserConfigFromDB for successfuly read userConfig from previous session
        //                [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
        //                DDLogSupport(@"Signaling db preopening finished");
        //                dispatch  _semaphore_signal(self.preopenDbSemaphore);
        //            });
        //        }
    }
    return self;
}

#pragma mark - Getters

- (QliqUser*)lastLoggedUser {
    return _lastLoggedUser = [self.userSessionService getLastLoggedInUser];
}

- (QliqGroup *)lastLoggedUserGroup {
    return _lastLoggedUserGroup = [self.userSessionService getLastLoggedInUserGroup];
}

#pragma mark - Private

- (void)loadSettings
{
    self.lastLoggedUser = [self.userSessionService getLastLoggedInUser];
    self.lastLoggedUserGroup = [self.userSessionService getLastLoggedInUserGroup];
    
    UserSettingsService *userSettingsService = [[UserSettingsService alloc] init];
    [UserSessionService currentUserSession].userSettings = [userSettingsService getSettingsForUser:self.lastLoggedUser];
}

#pragma mark - Determine Login Way

- (StartViewType)showStartViewForIdleLock
{
    StartViewType type = StartViewTypeEnterPassword;
    
    if ([[KeychainService sharedService] pinAvailable]) {
        type = StartViewTypeEnterPin;
    }
    
    //    if (appDelegate.currentDeviceStatusController.isLocked) {
    //        type = StartViewTypeLock;
    //    }
    //    else if (appDelegate.currentDeviceStatusController.isWiped) {
    //        type = StartViewTypeWipe;
    //    }
    //
    //    if ([self.failedAttemptsController isLocked]) {
    //        type = StartViewTypeAttemptsLock;
    //    }
    //
    //    if (type == StartViewTypeNone && ![self shouldAutoLogin]) {
    //
    //        if (self.lastLoggedUser && [[KeychainService sharedService] pinAvailable]) {
    //            type = StartViewTypeEnterPin;
    //        }
    //        else {
    //            type = StartViewTypeEnterPassword;
    //        }
    //    }
    
    return type;
}

+(void)touchIdVerification:(void(^)(BOOL success, NSError * error))completion {
    
    DDLogSupport(@"Try authenticated by Touch ID");
    
    //Touch ID
    NSString *storedUn          = [[KeychainService sharedService] getUsername];
    NSString *storedPassword    = [[KeychainService sharedService] getPassword];
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    
    LAContext *authenticationContext = [[LAContext alloc] init];
    authenticationContext.localizedFallbackTitle = @"";
    
    NSError *error = nil;
    
    BOOL haveUn = storedUn.length > 0;
    BOOL havePass = storedPassword.length > 0;
    BOOL touchIDEnabled = userSettings.isTouchIdEnabled;
    BOOL canEvaluatePolicy = [authenticationContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    // Check if biometrics are available and is the user enabled it
    if (haveUn && havePass && touchIDEnabled && canEvaluatePolicy) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFirstTouchID"];
        
        // Authenticate User
        [authenticationContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:QliqLocalizedString(@"2390-TextTouchIDAuthorization") reply:^(BOOL success, NSError *error) {
            
            if (error) {
                switch (error.code)
                {
                    case LAErrorSystemCancel: {
                        DDLogSupport(@"System canceled auth request due to app coming to foreground or background.");
                        break;
                    }
                    case LAErrorAuthenticationFailed: {
                        DDLogSupport(@"Authentication by Touch ID Failed");
                        break;
                    }
                    case LAErrorUserCancel: {
                        DDLogSupport(@"User pressed Cancel button in Touch ID");
                        break;
                    }
                    case LAErrorUserFallback: {
                        DDLogSupport(@"User pressed Enter Password in Touch ID");
                        break;
                    }
                    default: {
                        DDLogSupport(@"Touch ID is not configured %ld", (long)error.code);
                        break;
                    }
                }
                DDLogSupport(@"Authentication by Touch ID Failed");
                
            }
            
            if (completion) {
                completion(success, error);
            }
        }];
    }
    else
    {
        switch (error.code)
        {
            case LAErrorTouchIDNotEnrolled: {
                DDLogSupport(@"No Touch ID fingers enrolled.");
                break;
            }
            case LAErrorTouchIDNotAvailable: {
                DDLogSupport(@"Touch ID not available on the device.");
                break;
            }
            case LAErrorPasscodeNotSet: {
                DDLogSupport(@"Need a passcode set to use Touch ID.");
                break;
            }
            default: {
                DDLogSupport(@"! Touch ID is not configured %ld", (long)error.code);
                break;
            }
        }
        
        if (completion) {
            completion(NO, error);
        }
    }
}

#pragma mark -
#pragma mark REGISTER


- (void)registerUserWithFirstName:(NSString*)firstName middleName:(NSString*)middleName email:(NSString*)email
                         lastName:(NSString*)lastName phone:(NSString*)phone profession:(NSString*)profession
                     organization:(NSString*)organization website:(NSString*)website block:(void(^)(NSError *error))block
{
    QliqUser *newContact = [[QliqUser alloc] init];
    newContact.firstName = firstName;
    newContact.middleName = middleName;
    newContact.lastName = lastName;
    newContact.phone = phone;
    newContact.email = email;
    newContact.profession = profession;
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"1907-StatusSending", nil) maskType:SVProgressHUDMaskTypeGradient];
    
    QliqAPIService *service = [[RegisterAccountService alloc] initWithUser:newContact andOrganization:organization andWebsite:website];
    
    [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        if (block) block(error);
    }];
}

#pragma mark -
#pragma mark - LOGOUT

- (void)startLogoutWithCompletition:(void(^)(void))logoutCompletition {
    
    /*
     Only in main thread!
     */
    
    DDLogSupport(@"Start Logout...");
    [QxPlatfromIOS onUserSessionFinishing];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"1074-TextLogout", @"Logout") maskType:SVProgressHUDMaskTypeGradient];
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    /*
     updating last loggedIn users info
     */
    [appDelegate updateLastUsers];
    
    [self.userSessionService logoutSessionWithCompletition:^{
        
        dispatch_async_main(^{
            
            /*
             return firstLaunchViewController like rootViewController to appDelegate.navigationController
             see appDelegate '(void)userDidLogin;'
             */
            //[appDelegate.navigationController popToRootViewControllerAnimated:NO];
            
            FirstLaunchViewController *firstLaunchViewController = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FirstLaunchViewController class])];
            [appDelegate.navigationController setViewControllers:@[firstLaunchViewController] animated:NO];

            StartViewType *startView = StartViewTypeNone;
            
            if (appDelegate.currentDeviceStatusController.isLocked){
                //If device is locked need to open StarLockView
                startView = StartViewTypeLock;
            }
            [firstLaunchViewController setViewType:startView animated:NO withCompletition:^{
                if (logoutCompletition) {
                    logoutCompletition();
                }
                [SVProgressHUD dismiss];
            }];
        });
    }];
    //    });
}

#pragma mark -
#pragma mark - LOGIN

- (void)beginLogin {
    
    BOOL isLoginWithPin = NO;
    
    if (self.lastLoggedUser && [[KeychainService sharedService] pinAvailable]) {
        isLoginWithPin = YES;
    }
    
    if (isLoginWithPin) {
        if(_delegate) {
            [_delegate loginWithPin];
        }
    }
    else {
        if(_delegate) {
            [_delegate loginWithPassword];
        }
    }
    
    //didSecondLogin
    [self tryAutologinOrPreopenDB];
}

- (BOOL)shouldAutoLogin {
    
    BOOL shouldDoAutoLogin = NO;
    
    BOOL rememberPassword = [UserSessionService currentUserSession].userSettings.securitySettings.rememberPassword;
    BOOL enforcePin = [UserSessionService currentUserSession].userSettings.securitySettings.enforcePinLogin;
    BOOL expiredTime = [IdleEventController checkIdleTimeExpired];
    BOOL appLaunchedWithVoipPush = appDelegate.appLaunchedWithVoIPPush;
    BOOL loginCredentialsChanged = [QliqStorage sharedInstance].wasLoginCredentintialsChanged || [QliqStorage sharedInstance].failedToDecryptPushPayload;
    
    // If remember password is set
    shouldDoAutoLogin |= rememberPassword;
    // If the enforce PIN not set and device passcode is enabled
    shouldDoAutoLogin |= enforcePin == NO && [[KeychainService sharedService] isDeviceLockEnabled];
    // Idle timer has not expired
    shouldDoAutoLogin |= expiredTime == NO;

    shouldDoAutoLogin = shouldDoAutoLogin && ![self gettingShouldSkipAutoLogin] && !appLaunchedWithVoipPush && !loginCredentialsChanged;
    DDLogSupport(@"Should autologin - %d,"
                 "\n\t\t\t\t\t rememberPassword - %d,"
                 "\n\t\t\t\t\tenforcePin - %d,"
                 "\n\t\t\t\t\t isDeviceLockEnabled - %d,"
                 "\n\t\t\t\t\t expiredTime - %d,"
                 "\n\t\t\t\t\t appLaunchedWithVoipPush - %d,"
                 "\n\t\t\t\t\t loginCredentialsChanged - %d \n",
                 shouldDoAutoLogin,
                 rememberPassword,
                 enforcePin,
                 [[KeychainService sharedService] isDeviceLockEnabled],
                 expiredTime,
                 appLaunchedWithVoipPush,
                 loginCredentialsChanged);
    
    return shouldDoAutoLogin;
}

//- (void)didSecondLogin
- (void)tryAutologinOrPreopenDB
{
    __weak __block typeof(self) welf = self;
    void (^tryAutologinOrPreopenDBBlock)(void) = ^{
        [welf.failedAttemptsController clear];
        NSString *storedUn = [[KeychainService sharedService] getUsername];
        NSString *storedPassword = [[KeychainService sharedService] getPassword];
        /*
         Checking for autologging
         */
        DDLogSupport(@"Was autologin tried - %d, StoredUN - %@, StoredPass - %@", welf.wasAutoLoginTried, storedUn, storedPassword ? @"[BLOCKED]" : @"nil");
        
        if (!welf.wasAutoLoginTried && [welf shouldAutoLogin] && storedUn.length > 0 && storedPassword.length > 0)
        {
            welf.wasAutoLoginTried = YES;
            DDLogSupport(@"<------ AUTOLOGIN -------->");
            [welf startLoginWithUsername:storedUn password:storedPassword autoLogin:YES forceLocalLogin:NO];
            
            //CHECK FOR CRASH
            if ([appDelegate appWasCrashed] && [appDelegate appShouldSendCrashReport])
            {
                [appDelegate sendAutomaticCrashReport];
            }
        }
        /*
         trying to preopen DB
         */
        else
        {
            DDLogSupport(@"<------ NOT AUTOLOGIN -------->");
            
            if ([welf.userSessionService loadLastUserSession])
            {
                if (welf.preopenDbSemaphore == nil)
                {
                    welf.preopenDbSemaphore = dispatch_semaphore_create(0);
                }
                // (pre)open db now so there is no delay when user enters PIN
                DDLogSupport(@"Preopening database on the login screen");
                //prepareDBForUserSession should be called before getUserConfigFromDB for successfuly read userConfig from previous session
                [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
                DDLogSupport(@"Signaling db preopening finished");
                dispatch_semaphore_signal(welf.preopenDbSemaphore);
            }
            
            //CHECK FOR CRASH
            //Show alert with crash if sending of report was delayed, but user is not autologin
            if ([appDelegate appWasCrashed] && [appDelegate appShouldSendCrashReport])
            {
                performBlockInMainThreadSync(^{
                    [appDelegate showAlertWithCrash];
                });
            }
        }
    };
    
    // check if the app was launched with VoIP PUSH
    if ([AppDelegate applicationState] == UIApplicationStateBackground)
    {
        performBlockInMainThread(^{
            tryAutologinOrPreopenDBBlock();
        });
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tryAutologinOrPreopenDBBlock();
        });
    }
}

- (BOOL)startLoginInResponseToRemotePush {
    
    NSString *storedUn = [[KeychainService sharedService] getUsername];
    NSString *storedPassword = [[KeychainService sharedService] getPassword];
    
    if (storedUn.length > 0 && storedPassword.length > 0) {
        if ([[Login sharedService] isLoginRunning]) {
            DDLogSupport(@"Cannot do login in response to Remote Push Notification because login is already in progress");
        } else {
            if (![appDelegate.navigationController.topViewController isKindOfClass:[LoginWithPasswordViewController class]] && ![appDelegate.navigationController.topViewController isKindOfClass:[LoginWithPinViewController class]]) {
                DDLogError(@"Cannot do login in response to Remote Push Notification because top controller isn't LoginViewController but %@", NSStringFromClass([appDelegate.navigationController.topViewController class]));
                return NO;
            }
            
            DDLogSupport(@"Doing login in response to Remote Push Notification");
            
            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            [self startLoginWithUsername:storedUn password:storedPassword autoLogin:YES forceLocalLogin:YES];
        }

        return YES;
    }
    else {      
        DDLogError(@"Cannot do login in response to Remote Push Notification because there is no saved username and password");
    }
    
    return NO;
}


- (void)startManualLoginWithUsername:(NSString *)username password:(NSString *)password {
    
    DDLogSupport(@"startManualLoginWithUsername: %@ password: [BLOCKED]", username);
    
    self.loginWithPin = NO;
    self.manualLogin = YES;
    [self startLoginWithUsername:[username lowercaseString]
                        password:[[KeychainService sharedService] stringToBase64:password]
                       autoLogin:!self.manualLogin
                 forceLocalLogin:NO];
}

- (void)startLoginWithUsername:(NSString *)username
                      password:(NSString *)password
                     autoLogin:(BOOL)isAutoLogin
               forceLocalLogin:(BOOL)forceLocal
{
    if (!self.isLoginRunning)
    {
        self.isLoginRunning = YES;
        
        DDLogSupport(@"Login with '%@:[BLOCKED]' isAutoLogin:%d forceLocal:%d", username, isAutoLogin, forceLocal);
        
        NSString *statusTitle;
        
        if (isAutoLogin)
            statusTitle = NSLocalizedString(@"1912-StatusAutoLogin", @"Auto Login");
        else
            statusTitle = NSLocalizedString(@"1913-StatusLogin", @"Login");
        
        performBlockInMainThreadSync(^{
            if ([SVProgressHUD isVisible])
                [SVProgressHUD dismiss];
            
            [SVProgressHUD showWithStatus:statusTitle
                                 maskType:SVProgressHUDMaskTypeBlack
                       dismissButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)];
        });
        
        //self.loginWithAutoLogin = isAutoLogin;
        self.manualLogin = !isAutoLogin;
        
        if (_preopenDbSemaphore) {
            DDLogSupport(@"Waiting for db preopening in bg thread");
            
            dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 2LL * NSEC_PER_SEC); // 2 sec in the future
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
        
        BOOL usernameMatches = [[[KeychainService sharedService] getUsername] isEqualToString:username];
        BOOL passwordMatches = [[[KeychainService sharedService] getPassword] isEqualToString:password];
        if (usernameMatches && passwordMatches)
        {
            NSDate *lastLoggedInDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastLoggedIn];
            NSNumber *loginWithPin = [[NSUserDefaults standardUserDefaults] valueForKey:kLoginWithPin];

            if (NSOrderedDescending == [lastLoggedInDate compare:[NSDate dateWithTimeIntervalSinceNow:-24*60*60]] && ![loginWithPin boolValue])
            {
//                            if (NSOrderedDescending == [lastLoggedInDate compare:[NSDate dateWithTimeIntervalSinceNow:-10]])
//                            {
                
                //Do fast sync. local login
                forceLocal = YES;
            }
        }
        
        if (forceLocal)
        {
            DDLogSupport(@"Trying to do fast (local) login");
            NSError *error;
            if ([self localLogin:username password:password error:&error])
            {
                [UIView setAnimationsEnabled:YES];
                return;
            }
            DDLogError(@"Couldn't do fast (local) login with error: %@", [error localizedDescription]);
        }
        
        if ([AppDelegate applicationState] == UIApplicationStateBackground)
        {
            DDLogSupport(@"Trying to do regular (network) login on BACKGROUND. SKIP IT.");
            self.isLoginRunning = NO;
            performBlockInMainThreadSync(^{
                if ([SVProgressHUD isVisible])
                    [SVProgressHUD dismiss];
            });
            return;
        }
        
        __weak __block typeof(self) welf = self;
        DDLogSupport(@"Doing regular (network) login");
        [self.userSessionService logInWithUsername:username andPassword:password completitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            
            if (error && welf.delegate && [welf.delegate respondsToSelector:@selector(loginError:title:message:)])
                [welf.delegate loginError:error title:nil message:nil];
            else if (welf.delegate && [welf.delegate respondsToSelector:@selector(loginIsSuccessful:)])
            {
                [welf.failedAttemptsController clear];
                [welf.delegate loginIsSuccessful:result];
            }
        }];
    }
    else
    {
        DDLogSupport(@"Cannot run another login session. Login is already running...");
    }
}

- (void)localLogin:(NSString *)username password:(NSString *)password {
    
    if (!appDelegate.currentDeviceStatusController.isLocked) {
        
        DDLogSupport(@"Local Login with '%@:[BLOCKED]",username);
        
        // KK 9/24/2015
        // Do not show Busy for localLogin
        // [SVProgressHUD showWithStatus:NSLocalizedString(@"Local Login", @"Local Login") maskType:SVProgressHUDMaskTypeBlack];
        
        //        NSString *storedUsername = [[KeychainService sharedService] getUsername];
        //        NSString *storedPassword = [[KeychainService sharedService] getPassword];
        
        //        if ([storedUsername isEqualToString:username] && [storedPassword isEqualToString:password]) {
        //
        //            [self.userSessionService loadLastUserSession];
        //
        //            //prepareDBForUserSession should be called before getUserConfigFromDB for successfuly read userConfig from previous session
        //            [[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]];
        //
//                    [[GetUserConfigService sharedService] getUserConfigFromDB];
        
        [self performLogin];
        
        //        }
        
        [UserSessionService currentUserSession].local = YES;
        
    } else if (_delegate) {
        [_delegate loginError:nil title:QliqLocalizedString(@"1126-TextLoginFailed") message:QliqLocalizedString(@"1214-TextDeviceIsLocked")];
    }
}

- (BOOL)localLogin:(NSString *)username password:(NSString *)password error:(NSError **)error {
    
    if ([self canLocalLogin:username password:password error:error]) {
        dispatch_async_main(^{
            [self localLogin:username password:password];
        });
        return YES;
    }
    
    return NO;
}

- (void)loadLoginObjectsForLastUserWithCompletion:(void (^)(BOOL success))completion
{
    NSString *username = [[KeychainService sharedService] getUsername];
    NSString *password = [[KeychainService sharedService] getPassword];
    if (username == nil || password == nil || self.lastLoggedUser == nil)
    {
        DDLogSupport(@"Cannot Load Login Objects when username or password or no lastLoggedUser is empty");
        if (completion)
            completion(NO);
    }
   
    [self.userSessionService loadLastUserSession];
    
    if ([[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]] == NO)
    {
        DDLogSupport(@"Cannot Load DB");
        if (completion)
            completion(NO);
    }
 
    void (^activateModulesFromSubscriprionsBlock)(void) = ^{
        [[QliqModulesController sharedInstance] activateModulesFromSubscriprions:[UserSessionService currentUserSession].subscriprion];
        if (completion)
            completion(YES);
    };

    
    void (^downloadMD5PublicKeyBlock)(void) = ^{
        DDLogSupport(@"Trying to download key pair from web server");
        [[GetKeyPair sharedService] getKeyPairCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            if (status == CompletitionStatusSuccess)
            {
                NSString *pubKeyMd5 = [[[Crypto instance] publicKeyString] md5];
                DDLogSupport(@"Downloaded new key pair. Public key's MD5: %@", pubKeyMd5);
                activateModulesFromSubscriprionsBlock();
            }
            else if(error)
            {
                DDLogError(@"Download of key pair from web server is failed. Error: %@", [error localizedDescription]);
                if (completion)
                    completion(NO);
            }
        }];
    };
    
    NSString *clearTextPassword = [password base64DecodedString];
    Crypto *crypto = [Crypto instance];
    NSString *publicKeyMd5FromWebServer = [UserSessionService currentUserSession].publicKeyMd5FromWebServer;
    if ([crypto openForUser:username withPassword:clearTextPassword] == NO)
    {
        DDLogError(@"Cannot open existing key pair");
        downloadMD5PublicKeyBlock();
    }
    else
    {
        if ([publicKeyMd5FromWebServer length] > 0)
        {
            NSString *pubKeyMd5 = [[crypto publicKeyString] md5];
            if ([publicKeyMd5FromWebServer isEqualToString:pubKeyMd5])
            {
                DDLogSupport(@"My public key's MD5 matches value from web server: %@", publicKeyMd5FromWebServer);
                activateModulesFromSubscriprionsBlock();
            }
            else
            {
                DDLogError(@"The web server has a different key pair then I do");
                downloadMD5PublicKeyBlock();
            }
        }
        else
        {
            DDLogError(@"PUBKEY_MD5 from web server is empty!");
            downloadMD5PublicKeyBlock();
        }
    }
    
    DDLogSupport(@"Starting qxlib session for loaded last user's login objects");
    [QxPlatfromIOS onUserSessionStarted];
}

- (BOOL)canLocalLogin:(NSString *)username password:(NSString *)password error:(NSError **)error {
    
    BOOL usernameMatches = [[[KeychainService sharedService] getUsername] isEqualToString:username];
    BOOL canLocalLogin = self.lastLoggedUser != nil;
    
    if (!canLocalLogin)
    {
        if (error)
            *error = [NSError errorWithCode:0 description:@"Cannot login without internet connection: No previous saved session"];
    }
    else if (!usernameMatches)
    {
        canLocalLogin = NO;
        if (error)
            *error = [NSError errorWithCode:0 description:@"Cannot login without internet connection as a different user"];
    }
    
    if (canLocalLogin)
    {
        NSString *clearTextPassword = [password base64DecodedString];
        Crypto *crypto = [Crypto instance];
        if ([crypto openForUser:username withPassword:clearTextPassword] == NO)
        {
            canLocalLogin = NO;
            DDLogError(@"Cannot open existing key pair before local login");
            if (error)
                *error = [NSError errorWithCode:0 description:@"Failed to login. Your password might have changed or expired. Please login with a valid Password"];
        }
        else
        {
            NSString *storedUsername = [[KeychainService sharedService] getUsername];
            NSString *storedPassword = [[KeychainService sharedService] getPassword];
            
            if ([storedUsername isEqualToString:username] && [storedPassword isEqualToString:password])
            {
                [self.userSessionService loadLastUserSession];
                if ([[DBUtil sharedInstance]  prepareDBForUserSession:[UserSessionService currentUserSession]] == NO)
                {
                    DDLogSupport(@"Skipping local login because cannot open DB");
                    canLocalLogin = NO;
                    if (error)
                        *error = nil;
                }
                
                if ([[QliqUserDBService sharedService] getAllOtherUsersCount] == 0)
                {
                    DDLogSupport(@"Skipping local login because DB is empty");
                    canLocalLogin = NO;
                    if (error)
                        *error = nil;
                }
            }
            else
            {
                if (!storedUsername || !storedPassword)
                {
                    if (_delegate)
                        [_delegate loginError:nil title:QliqLocalizedString(@"1126-TextLoginFailed") message:QliqLocalizedString(@"1212-TextNoStoredSession")];
                }
                else
                {
                    if (_delegate)
                        [_delegate loginError:nil title:QliqLocalizedString(@"1126-TextLoginFailed") message:QliqLocalizedString(@"1213-TextInvalidUsername/Password")];
                    [self.failedAttemptsController increment];
                }
            }
        }
    }
    
    return canLocalLogin;
}

/*
 It is prefinished point of login. This method perform last logging operations.
 */
- (void)performLogin {
    DDLogSupport(@"PerformLoging");
    
    dispatch_async_main(^{
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
            //Need to start PUSH Notifications
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    });
    
    SipAccountSettings *sipAccountSettings = [UserSessionService currentUserSession].sipAccountSettings;
    
    NSString *prevUserName = [[[KeychainService sharedService] getUsername] copy];
    DDLogSupport(@"sipAccountSettings.username: %@", sipAccountSettings.username);
    DDLogSupport(@"prevUserName: %@", prevUserName);
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
    
    BOOL isAutologin = !self.manualLogin;
    
    if ([[KeychainService sharedService] pinAvailable] && !self.loginWithPin && !isAutologin) {
        DDLogSupport(@"User logged in with password instead of PIN, claring old PIN");
        [[KeychainService sharedService] clearPin];
        [self unskipPinSetUp];
    }
    
    [UserSessionService currentUserSession].isLoginSeqeuenceFinished = YES;
    
    /*
     show main screen for current user
     */
    dispatch_sync_main(^{
        [appDelegate userDidLogin];
    });
    
    [self.failedAttemptsController clear];
    [appDelegate.busyAlertController sendSipRegisterIfNeeded];
    
    [self.userSessionService resumePagedContactsIfNeeded];
    if (![OnCallGroup hasConfigInDatabase]) {
        dispatch_async_background(^{
            [[[GetAllOnCallGroupsService alloc] init] getWithCompletionBlock:nil];
        });
    }
}

- (void)settingShouldSkipAutoLogin:(BOOL)shouldSkipAutoLogin {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *str = [NSString stringWithFormat:@"%@-%@", @"Qliq", @"shouldSkipAutoLogin"];
    
    [userDefaults setObject:[NSNumber numberWithBool:shouldSkipAutoLogin] forKey:str];
    
    [userDefaults synchronize];
    
    self.shouldSkipAutoLogin = shouldSkipAutoLogin;
}

- (BOOL)gettingShouldSkipAutoLogin {
    
    BOOL shouldSkipAutoLogin = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [NSString stringWithFormat:@"%@-%@", @"Qliq", @"shouldSkipAutoLogin"];
    
    
    if ([userDefaults objectForKey:str]) {
        shouldSkipAutoLogin = [[userDefaults objectForKey:str] boolValue];
    }
    
    return shouldSkipAutoLogin;
}


#pragma mark UserSessiomServiceDelegate

- (void)didLogIn {
    [self openCrypto:YES];
}

- (void)didStartProcessingGroupInfo {
    
    [SVProgressHUD setStatus:NSLocalizedString(@"1914-StatusProcessingGroupInfo", nil)];
}

- (void)didFailLogInWithReason:(NSString *)reason {
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
    //    if(_delegate)
    //        [_delegate loginError:nil title:nil message:nil];
}

- (BOOL)showNewPinQuestion {
    
    BOOL isNewPinQuestionShowed = NO;
    
    if (![UserSessionService currentUserSession].userSettings.securitySettings.rememberPassword && !self.loginWithPin && self.manualLogin) {
        
        dispatch_async_main(^{
            [self.delegate loginNewPinQuestion];
            [SVProgressHUD dismiss];
        });
        
        isNewPinQuestionShowed = YES;
    }
    return isNewPinQuestionShowed;
}

#pragma mark Crypto

- (void)openCrypto:(BOOL)login {
    
    NSString *userName = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *clearTextPassword = [[UserSessionService currentUserSession].sipAccountSettings.password base64DecodedString];
    NSString *publicKeyMd5FromWebServer = [UserSessionService currentUserSession].publicKeyMd5FromWebServer;
    
    BOOL needToDownloadKeyPair = NO;
    Crypto *crypto = [Crypto instance];
    
    if ([crypto openForUser:userName withPassword:clearTextPassword] == NO) {
        
        DDLogError(@"Cannot open existing key pair");
        needToDownloadKeyPair = YES;
    }
    else {
        
        if ([publicKeyMd5FromWebServer length] > 0) {
            
            NSString *pubKeyMd5 = [[crypto publicKeyString] md5];
            if ([publicKeyMd5FromWebServer isEqualToString:pubKeyMd5]) {
                DDLogSupport(@"My public key's MD5 matches value from web server: %@", publicKeyMd5FromWebServer);
            } else {
                DDLogError(@"The web server has a different key pair then I do");
                needToDownloadKeyPair = YES;
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
                
            } else if(_delegate) {
                
                [_delegate loginError:error title:nil message:nil];
            }
        }];
    } else if (login == YES){
        // Krishna 10/3/2016
        // When the App is launched in the BG due to VoIP PUSH, the App should only open the crypto
        // And not login
        //
        [self performLogin];
    }
}

#pragma mark - Work with PIN

- (BOOL)isPinExpired {
    
    NSTimeInterval expirePinAfterInterval = [UserSessionService currentUserSession].userSettings.securitySettings.expirePinAfter;
    
    if (expirePinAfterInterval <= 0) {
        return NO;
    }
    
    NSDate *lastPinSetDate = [KeychainService sharedService].getPinLastSetTime;
    NSDate *expirePinDate = [lastPinSetDate dateByAddingTimeInterval:expirePinAfterInterval];
    NSDate *nowDate = [NSDate date];
    
    if ([expirePinDate compare:nowDate] == NSOrderedAscending) {
        DDLogSupport(@"PIN Expired. (%@ < %@)", expirePinDate, nowDate);
        return YES;
    }
    
    return NO;
}

- (BOOL)pinConfirmed:(NSString *)pin {
    NSString *enteredPin = [[KeychainService sharedService] stringToBase64:pin];
    if ([[[KeychainService sharedService] getPin] isEqualToString:enteredPin]) {
        DDLogSupport(@"Pin Confirmed");
        return YES;
    }
    
    return NO;
}

- (BOOL)continueLoginWithResponseFromServerWithCompletion:(CompletionBlock)completion {
    
    BOOL success = [self.userSessionService loggedInWithDictionary:[UserSessionService currentUserSession].loggedInDictionary
                                                    withCompletion:^(CompletitionStatus status, id result, NSError *error) {
                                                        if (completion) {
                                                            completion(status, result, error);
                                                        }
                                                    }];
    return success;
}

- (void)saveNewPin:(NSString *)pin {
    [[KeychainService sharedService] saveUsername:[UserSessionService currentUserSession].sipAccountSettings.username];
    [[KeychainService sharedService] savePassword:[UserSessionService currentUserSession].sipAccountSettings.password];
    [[KeychainService sharedService] savePin:pin];
}

- (void)setPinLater{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [NSString stringWithFormat:@"%@-%@", [UserSessionService currentUserSession].sipAccountSettings.username, @"SkippedPinSetUp"];
    [userDefaults setObject:[NSNumber numberWithInt:1] forKey:str];
    [userDefaults synchronize];
    
    __weak __block typeof(self) welf = self;
    [self continueLoginWithResponseFromServerWithCompletion:^(CompletitionStatus status, id result, NSError *error) {
        if (error.code == [dbCanNotBeOpenErrorCode integerValue]) {
            if (welf.delegate && [welf.delegate respondsToSelector:@selector(loginError:title:message:)]) {
                [welf.delegate loginError:error title:nil message:nil];
            }
        }
    }];
}

- (void)unskipPinSetUp {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [NSString stringWithFormat:@"%@-%@", [UserSessionService currentUserSession].sipAccountSettings.username, @"SkippedPinSetUp"];
    [userDefaults removeObjectForKey:str];
    [userDefaults synchronize];
}

- (void)showSetUpNewPinQuestion {
    
    NSString *str = [NSString stringWithFormat:@"%@-%@", [UserSessionService currentUserSession].sipAccountSettings.username, @"SkippedPinSetUp"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:str] == nil) {
        [_delegate loginNewPinQuestion];
    }
    else {
        [appDelegate userDidLogin];
    }
}

- (void)confirmNewPin:(NSString *)newPin andConfirmedNewPin:(NSString *)confirmedNewPin withBlock:(ConfirmationBlock)confirmationBlock {
    BOOL confirmed = NO;
    NSError *error = nil;
    
    if ([newPin isEqualToString:confirmedNewPin]) {
        confirmed = YES;
    }
    else {
        error = [NSError errorWithDomain:errorDomainLoginWithPin
                                    code:LoginWithPinErrorCodePin1NotEqualPin2
                                userInfo:userInfoWithDescription(@"Pin 1 is not equal pin 2")];
    }
    
    if (confirmationBlock) {
        confirmationBlock (confirmed, error);
    }
}

- (void)startLoginWithPin:(NSString *)pin withCompletionBlock:(LoginWithPinCompletionBlock)compleationBlock {
    
    NSError *error = nil;
    
    if ([self isPinExpired]) {
        error = [NSError errorWithDomain:errorDomainLoginWithPin
                                    code:LoginWithPinErrorCodePinExpired
                                userInfo:userInfoWithDescription(@"Login with Pin: Pin has expired. Should set new pin")];
        if (compleationBlock) {
            compleationBlock(NO, error);
        }
        return;
    }
    
    if ([self pinConfirmed:pin]) {
        
        self.loginWithPin = YES;
        
        NSString *storedUn = [[KeychainService sharedService] getUsername];
        NSString *storedPassword = [[KeychainService sharedService] getPassword];
        DDLogSupport(@"----> Pin Confirmed -> LOGIN");
        [self startLoginWithUsername:storedUn password:storedPassword autoLogin:NO forceLocalLogin:NO];
        
        compleationBlock (YES, nil);
    }
    else {
        //If enterd wrong pin we should increment it for blockin app
        [self loginFailedWithInvalidCredentials];
        
        if ([self.failedAttemptsController isLocked]) {
            error = [NSError errorWithDomain:errorDomainLoginWithPin
                                        code:LoginWithPinErrorCodePinBlocked
                                    userInfo:userInfoWithDescription(@"Login with Pin: Failed Attempts enter pin")];
        }
        
        if (error == nil) {
            error = [NSError errorWithDomain:errorDomainLoginWithPin
                                        code:LoginWithPinErrorCodeEnteredWrongPin
                                    userInfo:userInfoWithDescription(@"Login with Pin: Wrong Pin")];
        }
        
        if (compleationBlock) {
            compleationBlock(NO, error);
        }
    }
}

#pragma mark - FailedAttemptsController

- (void)loginFailedWithInvalidCredentials {
    DDLogSupport(@"Login (or idle unlock) failed because password or pin is wrong");
    
    [self.failedAttemptsController increment];
    
    if ([self.failedAttemptsController shouldLock]) {
        dispatch_sync_main(^{
            [self.failedAttemptsController lock];
        });
    }
}

- (NSString *)timeStringForTimeInterval:(NSTimeInterval)timeInterval {
    
    NSUInteger minutes = timeInterval/60;
    NSUInteger secunds = timeInterval - minutes * 60;
    BOOL showMinutes = minutes > 0;
    BOOL showSeconds = (int)timeInterval % 60 != 0;
    NSString * minutesString = showMinutes ? [NSString stringWithFormat:@"%lu minutes",(unsigned long)minutes] : @"";
    NSString * secondsString = showSeconds ? [NSString stringWithFormat:@"%lu seconds",(unsigned long)secunds]  : @"";
    
    return [NSString stringWithFormat:@"%@%@%@",minutesString,showMinutes&&showSeconds?@" ":@"",secondsString];
}

@end

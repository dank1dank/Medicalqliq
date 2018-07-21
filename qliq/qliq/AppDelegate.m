//
//  AppDelegate.m
//  qliq
//
//  Created by Paul Bar on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <PushKit/PushKit.h>

#import "EnviromentInfo.h"
#import "DeviceInfo.h"
#import "DDTTYLogger.h"
#import "QliqLogFormatter.h"
#import "FileLoggerManager.h"
#import "MediaFileService.h"
#import "MKLocalNotificationsScheduler.h"
#import "IdleEventController.h"
#import "DCIntrospect.h"
#import "QliqSip.h"

#import "QliqModulesController.h"
#import "CallViewController.h"
#import "KeychainService.h"
#import "QliqUserNotifications.h"
#import "ConversationDBService.h"
#import "UIDevice+UUID.h"
#import "UIDevice-Hardware.h"
#import "ReportIncidentService.h"
#import "NSDate+Helper.h"
#import "NotificationUtils.h"
#import "QliqConnectModule.h"

#import "BusyAlertController.h"
#import "MediaGroupsListViewController.h"
#import "MessageAttachment.h"
#import "NavBarInCallStateView.h"
#import "Login.h"
#import "MainViewController.h"
#import "SetDeviceStatus.h"
#import "ReceivedPushNotificationDBService.h"
#import "GetAllOnCallGroupsService.h"
#import "qxlib/platform/ios/QxPlatfromIOS.h"

#import "AlertController.h"
/*
 Login
 */
#import "FirstLaunchViewController.h"
#import "LoginWithPasswordViewController.h"
#import "LoginWithPinViewController.h"
#import "EnterPinContainerView.h"
#import "SwitchUserViewController.h"
#import "ResetPasswordController.h"
#import "SetupNewPinQuestionViewController.h"
#import "IdleLockViewController.h"
#import "ChangePinViewController.h"

#import "DetailOnCallViewController.h"
#import "ConversationViewController.h"
#import "ChatMessageService.h"

#import "GetAppFirstLaunchWebService.h"
#import "GetDeviceStatus.h"
#import "DispatchCancelableBlock.h"

#import "EMRUploadViewController.h"

/*
 SSL Redirect
 */
#import "SSLRedirectNavigationController.h"
#import "SSLRedirectWebViewController.h"
#import "SSLRedirect_AlertView.h"
#import "RestClient.h"

typedef void (^qliqRemoteNotificationCallback)(UIBackgroundFetchResult);

DDLogLevel ddLogLevel = LOG_LEVEL_SUPPORT;
static UIApplicationState s_lastApplicationState = UIApplicationStateInactive;

#pragma mark - UIApplication -

@interface UIApplication (QliqAdditions)
- (NSString *) applicationStateString;
@end

@implementation UIApplication (QliqAdditions)

- (NSString *) applicationStateString {
    NSString * state = nil;
    switch (self.applicationState) {
        case UIApplicationStateActive:
            state=@"Active";
            break;
        case UIApplicationStateInactive:
            state=@"Inactive";
            break;
        case UIApplicationStateBackground:
            state=@"Background";
            break;
        default:
            state=@"";
            break;
    }
    return state;
}

@end

#pragma mark - AppDelegate -

@interface AppDelegate ()
<
QliqSipVoiceCallsDelegate,
InCallStateViewDelegate,
CallViewControllerDelegate,
UNUserNotificationCenterDelegate,
PKPushRegistryDelegate
>

@property (nonatomic, strong) IdleEventController *idleController;
@property (nonatomic, strong) CallViewController *callViewController;
@property (nonatomic, strong) DeviceStatusController *currentDeviceStatusController;
@property (nonatomic, strong) DDFileLogger *fileLogger;
@property (nonatomic, strong) NavBarInCallStateView *inCallStateView;
@property (nonatomic, strong) BusyAlertController *busyAlertController;
@property (nonatomic, strong) QliqNetwork *network;

@property (nonatomic, copy) qliqRemoteNotificationCallback didReceiveRemoteNotificationCompletionHandler;

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, assign) NetworkStatus currentReachabilityStatus;


@property (nonatomic, strong) MediaFile *pendingMediaFile;

/* App Conditions
 */
@property (nonatomic, assign) BOOL appInBackground;
@property (nonatomic, assign) BOOL resigningFromBackground;
@property (nonatomic, assign) BOOL appInitialized;
@property (nonatomic, assign) BOOL firstInstallLaunch;
@property (nonatomic, assign) BOOL waitingForUserPermission;
@property (nonatomic, assign) BOOL isRedirectionInProgress;

@property (nonatomic, assign) int  unProcessedRemoteNotifcations;
@property (nonatomic, strong) NSDate *lastSipShutdownDate;
//@property (strong, nonatomic, readwrite) QliqSign *qliqSignObj;

// Krishna 2/20/2017
//
@property (nonatomic, assign) BOOL shutdownRestartSIPInProgress;

@end

@implementation AppDelegate

@synthesize qliqSignObj = _qliqSignObj;

AppDelegate *appDelegate = nil;
CGFloat systemVersion = -1;
NSUncaughtExceptionHandler *exceptionHandler;

void uncaughtExceptionHandler(NSException *exception);
void signalHandler(int sig);

- (void)dealloc {
    
    self.inCallStateView = nil;
    self.callViewController = nil;
    self.window = nil;
    self.navigationController = nil;
    self.currentDeviceStatusController = nil;
    self.availableVersion = nil;
    
    [QliqNetwork setSharedInstance:nil];
    self.network = nil;
    self.idleController = nil;
    self.busyAlertController = nil;
    self.shutdownRestartSIPInProgress = FALSE;
}

#pragma mark - UIApplicationDelegate Methods -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //Initial Value
    {
        appDelegate = self;
        self.appInitialized = NO;
        self.waitingForUserPermission = NO;
        self.resigningFromBackground = NO;
        self.isRedirectionInProgress = NO;
        
        //Should show avialable for user sign up new account
        [QliqHelper shouldShowSignUpButton:NO];
        
        //Check if the App is launched first time after the bran new install on a new device
        self.firstInstallLaunch = ![[UIDevice currentDevice] isAvailableInKeychain];
        
        //When app is launched set this to Zero
        self.unProcessedRemoteNotifcations = 0;
        self.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt = 0;
        
        self.shutdownRestartSIPInProgress = FALSE;
        
        // Initialise Raedee PDF Editor License object
        // Krishna 5/5/2017 moved to after login
        // _qliqSignObj = [[QliqSign alloc] initWithName:"com.qliqsoft.cciphoneapp" company:"QliqSOFT, Inc" mail:"ravi@qliqsoft.com" serial:"V2LFLB-AW8NTO-VM8O6Y-GHOTML-WR63V5-HOFE82"];
    }
    
    systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    self.bgTask = UIBackgroundTaskInvalid;
    
    //setting hooks for NSNotificationCenter methods reduces problems with observing same event by one instance multiple times
    //    [NSNotificationCenter disallowToObserveMethodsMultipleTimesBySameInstance];
    
    self.window.backgroundColor = [UIColor whiteColor];
    self.navigationController = (QliqNavigationController*)self.window.rootViewController;
    
    [self setupDirectories];
    [self setupLogSystem];
    [self printStartupMessageWithLaunchOptions:launchOptions];
    [self setupBusyAlertController];
    [self installSignalHandlers];
    [self installExceptionHandlers];
    
    // Register for VOIP PUSH for iOS 9 and beyond for now.
    // We may need to test more on  iOS 8 before we can
    // Enable for those.
    
    // register voip push for iOS 9 and above but only terminate connection to SIP server in the background for iOS 10+
    // since it is deprecated in the version. Keeping connection in the background is delaying the delivery of messages.
    // Server timing out on sending message on a connection that is cloaked by iOS in background and then it send
    // VoIP push
    if (is_ios_greater_or_equal_9() && ![self isSimulator]) {
        [self voipRegistration];
    }
    
    // Do handle first run after registering for voipRegistration
    //
    [self handleFirstRun];
    
    [self handlePushNotificationOnLaunch:[launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
    
    [self setupDeviceStatusController];
    [self handleLocalNotificationOnLaunch:[launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]];
    //    [self handleOpenURL:[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]];
    [self setupNetwork];
    [self setupCalls];
    [self checkForCrash];
    
#if TARGET_IPHONE_SIMULATOR
    [[DCIntrospect sharedIntrospector] start];
#endif
    
    [self addNotificationsObservingToAppDelegate];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //    if (is_ios_greater_or_equal_10()) {
    //        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //        center.delegate = self;
    //    }
    
    self.appInitialized = YES;
    
    // Krishna 5/7/2018
    // If the App is Launched in the BG, Only VoIP Push will launch it. There is no reason otherwise
    //
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        DDLogSupport(@"App Started in Background/Inactive. Must be due to VoIP PUSH");
        self.appLaunchedWithVoIPPush = YES;
    } else {
        self.appLaunchedWithVoIPPush = NO;
    }
    
    [self configurationBeforeLogin];
    [self measureTimeForActiveAppInFG:YES];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (![self isSimulator]) {
        [application  registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    self.waitingForUserPermission = NO;
    
    NSString *deviceTokenStr = [[[[deviceToken description]
                                  stringByReplacingOccurrencesOfString:@"<" withString:@""]
                                 stringByReplacingOccurrencesOfString:@">" withString:@""]
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    DDLogSupport(@"Device Token As String: %@", deviceTokenStr);
    
    [QliqStorage sharedInstance].deviceToken = deviceTokenStr;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    self.waitingForUserPermission = NO;
    
    NSString *failureMessage = error.localizedDescription;
    
    DDLogSupport(@"Remote Notification Registration Failed, error: %@", failureMessage);
    
    if (![self isSimulator]) {
        
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1000-TextFailRegisterPush")
                                                                      message:failureMessage
                                                                     delegate:nil
                                                            cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            if (alert.cancelButtonIndex != buttonIndex) {
                DDLogSupport(@"User chose not to remind about notifications are OFF");
                
                [self setDontShowAlertsOffPopup];
            }
        }];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if (self.appInBackground == YES) {
        DDLogSupport(@"Received remote notification (iOS<7) while running in BG. %@", userInfo);
        [self.busyAlertController sendSipRegisterWhenApplicationActive];
    }
    else if (([AppDelegate applicationState] == UIApplicationStateActive) && [[QliqSip sharedQliqSip] isConfigured]) {
        DDLogSupport(@"Received remote notification (iOS<7) while running in FG. %@", userInfo);
        [self shutdownReconnectSIP];
    }
    else {
        DDLogSupport(@"Received remote notification (iOS<7) whila App is initializing. Doing nothing...");
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    self.didReceiveRemoteNotificationCompletionHandler = completionHandler;
    
    if (self.appInBackground == YES) {
        DDLogSupport(@">>>> Received remote notification while App is in BG");
        [self receiveRemoteNotificationInBG:userInfo isVoip:NO];
    }
    else if (([AppDelegate applicationState] == UIApplicationStateActive) && [[QliqSip sharedQliqSip] isConfigured]) {
        DDLogSupport(@">>>> Received remote notification while App is Active");
        [self receiveRemoteNotificationWithActiveStateSIPConfigured:userInfo isVoip:NO];
    }
    else if (([AppDelegate applicationState] == UIApplicationStateInactive)) {
        DDLogSupport(@">>>> Received remote notification while App is Inactive");
        [self receiveRemoteNotificationWithInactiveState:userInfo isVoip:NO];
    }
    else if ([AppDelegate applicationState] == UIApplicationStateBackground) {
        DDLogSupport(@">>>>  Received remote notification while App is started in BG");
        [self receiveRemoteNotificationInBG:userInfo isVoip:NO];
    }
    else {
        DDLogSupport(@">>>> Received remote notification while App is initializing. Doing nothing...");
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    DDLogSupport(@">>>> App did Receive Local Notification");
    
    NSString *notificationType = notification.userInfo[LocalNotificationType];
    if([notificationType isEqualToString:LocalNotificationTypeCall])
    {
        [self.callViewController answerCall];
        return;
    }
    else if ([notificationType isEqualToString:LocalNotificationTypeNotify])
    {
        return;
    }
    
    NSString *notificationID = notification.userInfo[kKeyLocalNotificationID];
    
    // Check if the app is in Inactive state
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive && notificationID && notificationID.length > 0)
    {
        BOOL isChimed = [[QliqUserNotifications getInstance] isLocalNotificationChimed:notificationID];
        
        //Check if notification was already handled erlier or handled, while the app going from BG,
        //so it is opening conversation for related message with users tap.
        BOOL shouldShow = (self.resigningFromBackground || isChimed) && ![QliqUserNotifications getInstance].isConversationOpeningInProgress;
        
        if (shouldShow)
        {
            [appDelegate.idleController handleApplicationDidBecomeActive];
            //Open conversation for message from notification
            [[QliqUserNotifications getInstance] showConversationFor:notification inNavigationController:self.navigationController];
        }
        //Notification was just handled first time, while the app was in Inactive state.
        else
        {
            //Wake up app. Don't show conversation for message from notification
            [[QliqUserNotifications getInstance] handleLocalNotification:notification];
        }
    }
    //App is Active, or it is Old Notificaiton
    else
    {
        [[QliqUserNotifications getInstance] handleLocalNotification:notification];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    DDLogSupport(@"\n==============================================================\n"
                 ">>>>>> Qliq App is RESIGNING FROM ACTIVE state\n"
                 "==============================================================");
    s_lastApplicationState = UIApplicationStateInactive;
    self.resigningFromBackground = NO;
    
    if (self.idleController != nil) {
        [self.idleController handleApplicationWillResignActive];
    }
    
    QliqSip *sip = [QliqSip instance];
    [sip handleAppDidBecomeInactive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    DDLogSupport(@"\n==============================================================\n"
                 ">>>>>> Qliq App is ACTIVE\n"
                 "==============================================================");
    s_lastApplicationState = UIApplicationStateActive;
    self.resigningFromBackground = NO;
    
    if ([QliqStorage sharedInstance].wasLoginCredentintialsChanged || [QliqStorage sharedInstance].failedToDecryptPushPayload)
        return;
    
    if (self.idleController != nil) {
        [self.idleController handleApplicationDidBecomeActive];
    }
    
    if (![self isUserLoggedOut] && [UserSessionService currentUserSession].user) {
        BOOL needToRestartSip = NO;
        
        [self showPushNotificationsAlertIfTurnedOff];
        if (self.wasLaunchedDueToRemoteNotificationiOS7)
        {
            SecuritySettings *securitySettings = [UserSessionService currentUserSession].userSettings.securitySettings;
            
            if (!securitySettings.rememberPassword) {
                // We logged in the user locally because or Remote Notification but Auto Login is not set
                // let's lock the app for security reasons.
                DDLogSupport(@"Idle Lock app. We logged in the user locally because or Remote Notification but Auto Login is not set");
                [self.idleController lockIdle];
            }
            if ([self.pushNotificationCallId isKindOfClass:[NSString class]]) {
                if(self.pushNotificationCallId.length > 0) {
                    DDLogSupport(@"Insert notification %@", self.pushNotificationCallId);
                    [ReceivedPushNotificationDBService insert:self.pushNotificationCallId];
                    //                    self.pushNotificationCallId = nil;
                }
            }
            //            self.wasLaunchedDueToRemoteNotificationiOS7 = NO;
        }
        else if (![[QliqSip sharedQliqSip] isRegistered]) {
            DDLogSupport(@"Registration not active when App was in BG. Re-registering");
            // Krishna 8/5/2014
            // Check if SIP is not registered and register here
            needToRestartSip = YES;
        } else if ([self.network hasIPAddressChanged:TRUE]) {
            DDLogSupport(@"Registration not active when App was in BG. Re-registering");
            needToRestartSip = YES;
        } else if ([[QliqSip sharedQliqSip] pingServer] == false){
            DDLogSupport(@"Server Pinging Failed. Re-registering");
            needToRestartSip = YES;
        }
        
        UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
        if (userSettings.isBatterySavingModeEnabled == NO && ![IdleEventController checkIdleTimeExpired]) {
            DDLogSupport(@"Calling set_device status because app become active");
            dispatch_async_background(^{
                [SetDeviceStatus setDeviceStatusCurrentAppStateWithCompletion:^(BOOL success, NSError *error) {
                    DDLogSupport(@"set_device_status, success? %d", success);
                }];
            });
        }
        
        // KK 9/28/2015
        // Do not wait for set_device_status to be successful.
        // If for some reason, webserver is slow or down, we don't
        // want to too long to register. If we do so, it might cause
        // Delay in message delivery. The worse thing that could happen is
        // that we may not get queued up Change Notifications when the app is
        // in the background.
        //
        if (needToRestartSip) {
            // 2/15/2017 - Krishna
            [self shutdownReconnectSIP];
        }
        
        [self showUpgradeAlertIfNeeded:NO];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     
     */
    
    DDLogSupport(@"\n==============================================================\n"
                 ">>>>>> Qliq App will enter to FG\n"
                 "==============================================================");
    
    [self measureTimeForActiveAppInFG:YES];
    
    if ([self tryToLogoutIfCredentialsChangedOrDecryptionOfPushPayloadFailed])
        return;
    
    self.resigningFromBackground = YES;
    if (self.appInitialized == NO)
    {
        DDLogSupport(@"Ignoring applicationWillEnterForeground since the app is not imitialized yet");
        return;
    }
    
    QliqSip *sip = [QliqSip instance];
    
    if ([UserSessionService isOfflineDueToBatterySavingMode] == NO) {
        [sip handleAppDidBecomeActive];
    }
    
    self.appInBackground = NO;
    
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    if (userSettings.isBatterySavingModeEnabled)
    {
        [application clearKeepAliveTimeout];
        if (![self isUserLoggedOut])
        {
            DDLogSupport(@"App will enter fg in battery saving mode on >= iOS 8.x, resuming network");
                // Restore notifications
                [self.network.reachability startNotifications];
                [UserSessionService setIsOfflineDueToBatterySavingMode:NO];
                [self shutdownReconnectSIP];
            
        }
        else
        {
            DDLogSupport(@"App will enter fg in battery saving mode but user is not logged in");
        }
    }
    
    //    #warning Calling this service here is not nessesary and drains user battery. Check device status only when receive SIP notification to check
    //    [[GetDeviceStatus sharedService] isDeviceLockedCompletition:^(BOOL lock, BOOL wipeData, NSError * error) {
    //        if (lock) [self logoutSessionWithCompletition:nil];
    //    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    DDLogSupport(@"\n==============================================================\n"
                 ">>>>>> Qliq App going into BG\n"
                 "==============================================================");
    s_lastApplicationState = UIApplicationStateBackground;
    [self measureTimeForActiveAppInFG:NO];
    [self calculateFGTime];
    self.resigningFromBackground = NO;
    
    QliqSip *sip = [QliqSip sharedQliqSip];
    
    
    //Nil ViewControllers
    //    [self purgeUI]; //AIIII
    
    if ([sip isConfigured] && ![self isUserLoggedOut])
    {
        // We will re-register every 10 mins, however if the last re-registration was ex. 8 mins ago
        // then from server's perspective the interval between registration will be 18 mins.
        // This is why we were calling registration here to reset registration timer on the server before we go to the background.
        //
        
        //        UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
        
        // For IOS 9 and above, the VOIP PUSH notifications will wake up the app.
        // 9/18/2016 = Krishna
        // Only iOS 10 does not keep connection in the BG.
        if (is_ios_greater_or_equal_10()) {
            [application clearKeepAliveTimeout];
            if (![self isUserLoggedOut]) {
                DDLogSupport(@"iOS 10, shuting down network while goind to background");
                [self.network.reachability stopNotifications];
                [self disconnectShutdownSIP];
            } else {
                DDLogSupport(@"iOS 10, App will enter bg  user is not logged in");
            }
        } else {
            DDLogSupport(@">>>>>> starting keepalive in background.");
//            [sip performSelectorOnMainThread:@selector(keepAliveInBackground) withObject:nil waitUntilDone:YES];
            
            [application setKeepAliveTimeout:SIP_KEEP_ALIVE_INTERVAL handler: ^{
                [[QliqSip sharedQliqSip] performSelectorOnMainThread:@selector(keepAliveInBackground) withObject:nil waitUntilDone:YES];
            }];
        }
    } else {
        DDLogSupport(@"Either SIP is not configured or User Logged out, skipping normal logic");
    }
    
    // Cancel chime if there are no Unread messages and App was not in BG before.
    if (self.appInBackground == NO && [ChatMessage unreadMessagesCount] == 0){
        DDLogSupport(@"Calling Cancel Chime while going into Background");
        if ([[UIApplication sharedApplication] scheduledLocalNotifications].count != 0) {
            [[QliqUserNotifications getInstance] cancelChimeNotifications:YES];
        }
        
        // 08-19-2014 Krishna
        // Update the Badge count.
        //
        if ([UIApplication sharedApplication].applicationIconBadgeNumber != 0) {
            [[QliqUserNotifications getInstance] refreshAppBadge:0];
        }
    }
    
    // 07-01-2015 Krishna
    // Set the appInBackground flag
    self.appInBackground = YES;
    
    if (self.bgTask == UIBackgroundTaskInvalid) {
        self.bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }];
        
        // KK - 9/23/2015
        // Moved this block from dispatch_after to here.
        // Because IOS does not allow me to send a message to server
        // in dispatach_after. I am noticing this in
        // iOS 8.4 and above.
        // We had it in dispatch_after so that we don't send the background
        // status as soon as app goes into backgroud. However, we do not
        // a choice now with iOS change.
        // No longer needed as it is handled in CN message response with 480 error code
        // Which will make server mark the app as in BG and will not send any CNs
        // UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
        //if (userSettings.isBatterySavingModeEnabled == NO) {
        //    DDLogSupport(@"Calling set_device_status because app is in bg");
        //    [SetDeviceStatus setDeviceStatusCurrentAppStateWithCompletion:nil];
        //} else {
        //    DDLogSupport(@"Not calling set_device_status because app is in bg with battery saving mode");
        //}
        
        // Execute block in 10 secs
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            DDLogSupport(@"BG task fired");
            // If user returns to the app before the timeout this block can be executed in fg
            if ([AppDelegate applicationState] == UIApplicationStateBackground) {
                [self.idleController appBackgroundTimerFired:[[KeychainService sharedService] isDeviceLockEnabled]];
                
                // KK 12-21-2013: Do not stop SIP
                // if (shouldStopSip) {
                //    DDLogSupport(@"Stopping SIP");
                //    [[QliqSip sharedQliqSip] sipStop];
                // }
                
            }
            
            // Finished
            if (self.bgTask != UIBackgroundTaskInvalid) {
                [application endBackgroundTask:self.bgTask];
                self.bgTask = UIBackgroundTaskInvalid;
            }
        });
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    DDLogSupport(@"\n\n\n==============================================================\n"
                 "---> Application Will Terminate ---> Qliq app will be STOPPED\n"
                 "==============================================================\n\n");
    
    [[QliqSip instance] setRegistered:NO];
    DDLogSupport(@"\n\n\n==============================================================\n"
                 "---> Application Will Terminate ---> Qliq app is STOPPED\n"
                 "==============================================================");
    [DDLog flushLog];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
    DDLogSupport(@"\n==============================================================\n"
                 ">>>>>> Qliq App Receive Memory Warning !"
                 "==============================================================");
    
    [[QliqStorage sharedInstance] storeAppMemoryWarningEvent];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    [self handleOpenURL:url];
    
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    id lastObject = self.navigationController.viewControllers.lastObject;
    
    id presentedController = self.navigationController.presentedViewController;
    if (presentedController && [presentedController isKindOfClass:[UINavigationController class]]) {
        lastObject = ((UINavigationController *)presentedController).viewControllers.lastObject;
    }
    
    if ([lastObject isKindOfClass: [LoginWithPinViewController class]]          ||
        [lastObject isKindOfClass: [LoginWithPasswordViewController class]]     ||
        [lastObject isKindOfClass: [FirstLaunchViewController class]]           ||
        [lastObject isKindOfClass: [SwitchUserViewController class]]            ||
        [lastObject isKindOfClass: [ResetPasswordController class]]             ||
        [lastObject isKindOfClass: [SetupNewPinQuestionViewController class]]   ||
        [lastObject isKindOfClass: [IdleLockViewController class]]              ||
        [lastObject isKindOfClass: [ChangePinViewController class]]             ||
        [lastObject isKindOfClass: [EMRUploadViewController class]]             ||
        [lastObject isKindOfClass: [DetailOnCallViewController class]] )
    {
        return UIInterfaceOrientationMaskPortrait;
    }
//    else  if ([[[UIDevice currentDevice] model] isEqualToString:@"iPad"] && UIDeviceOrientationIsLandscape(application.statusBarOrientation)){
//        return UIInterfaceOrientationMaskPortrait;
//    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

#pragma mark -
#pragma mark User Notification Center Delegate Methods
#pragma mark -

//- (void)userNotificationCenter:(UNUserNotificationCenter *)center
//       willPresentNotification:(UNNotification *)notification
//         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
//{
//    if (notification.request.content.userInfo[kKeyConversationID])
//    //Local Notificaitons
//    {
//        DDLogSupport(@"didReceiveLocalNotificaiton");
//
//        [[QliqUserNotifications getInstance] handleLocalNotification:notification];
//
//        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
//            completionHandler(UNNotificationPresentationOptionBadge);
//        }
//        else
//        {
//            completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
//        }
//    }
//    else
//    //PUSH Notifications
//    {
//        DDLogSupport(@"didReceiveRemoteNotification");
//        NSDictionary *userInfo = notification.request.content.userInfo;
//
//        UIApplication *app = [UIApplication sharedApplication];
//
//        if (self.appInBackground == YES) {
//            [self receiveRemoteNotificationInBG:userInfo];
//            completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
//        }
//        else if ((app.applicationState == UIApplicationStateActive) && [[QliqSip sharedQliqSip] isConfigured]) {
//            [self receiveRemoteNotificationWithActiveStateSIPConfigured:userInfo];
////            completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
//             completionHandler(UNNotificationPresentationOptionNone);
//        }
//        else
//        {
//            completionHandler(UNNotificationPresentationOptionNone);
//            DDLogSupport(@"Received remote notification while App is initializing. Doing nothing...");
//        }
//    }
//}
//
//- (void)userNotificationCenter:(UNUserNotificationCenter *)center
//didReceiveNotificationResponse:(UNNotificationResponse *)response
//         withCompletionHandler:(void (^)())completionHandler
//{
//    DDLogSupport(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
//
//    if (response.notification.request.content.userInfo[kKeyConversationID])
//        //Local Notificaitons
//    {
//        [appDelegate.idleController handleApplicationDidBecomeActive];
//        //Open conversation for message from notification
//        [[QliqUserNotifications getInstance] showConversationFor:response.notification inNavigationController:self.navigationController];
//
//    }
//    else
//        //PUSH Notifications
//    {
////        if (([AppDelegate applicationState] == UIApplicationStateInactive)) {
//            NSDictionary *aps = response.notification.request.content.userInfo[@"aps"];
//            NSString *callId = aps[@"call_id"];
//            [[QliqUserNotifications getInstance] openConversationForRemoteNotificationWith:self.navigationController callId:callId];
////        }
////        else
////        {
////            DDLogSupport(@"Received remote notification while App is initializing. Doing nothing...");
////        }
//    }
//
//    completionHandler();
//}


#pragma mark -
#pragma mark Crash handling
#pragma mark -

void uncaughtExceptionHandler(NSException *exception) {
    
    NSString* buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];//[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CWBuildNumber"];
    DDLogError(@"Build Number: %@", buildNumber);
    
    DDLogError(@"CRASH: %@", exception);
    DDLogSupport(@"Stack Trace: %@", [exception callStackSymbols]);
    
    if (exceptionHandler != NULL)
        exceptionHandler(exception);
    
    @synchronized([DBUtil sharedDBConnection]) {
        
        [[DBUtil sharedDBConnection] close];
    }
    
    [appDelegate storeAppCrashEventWithStackTrace:[NSString stringWithFormat:@"%@",[exception callStackSymbols]]];
}

void signalHandler(int sig) {
    static int previousSignal = 0;
    if (previousSignal != sig) {
        previousSignal = sig;
        DDLogError(@"Signal: %d",sig);
        DDLogSupport(@"Stack Trace: %@", [NSThread callStackSymbols]);
        
        @synchronized([DBUtil sharedDBConnection]) {
            
            [[DBUtil sharedDBConnection] close];
        }
        
        [appDelegate storeAppCrashEventWithStackTrace:[NSString stringWithFormat:@"%@",[NSThread callStackSymbols]]];
    }
}

- (void) installSignalHandlers {
    
    struct sigaction newSignalAction;
    memset(&newSignalAction, 0, sizeof(newSignalAction));
    newSignalAction.sa_handler = &signalHandler;
    sigaction(SIGABRT, &newSignalAction, NULL);
    sigaction(SIGILL, &newSignalAction, NULL);
    sigaction(SIGBUS, &newSignalAction, NULL);
    sigaction(SIGSEGV, &newSignalAction, NULL);
    sigaction(SIGTRAP, &newSignalAction, NULL);
    sigaction(SIGPIPE, &newSignalAction, NULL);
    sigaction(SIGFPE, &newSignalAction, NULL);
}

- (void) installExceptionHandlers {
    
    exceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

- (void)showAlertWithCrash
{
    UIAlertView_Blocks *crashAlert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1018-TextCrash")
                                                                       message:QliqLocalizedString(@"1019-TextAskCrashReport")
                                                                      delegate:nil
                                                             cancelButtonTitle:QliqLocalizedString(@"12-ButtonDontSend")
                                                             otherButtonTitles:QliqLocalizedString(@"10-ButtonSend"), QliqLocalizedString(@"11-ButtonSendWithDB"), nil];
    [crashAlert showWithDissmissBlock:^(NSInteger buttonIndex)
    {
        if (buttonIndex != crashAlert.cancelButtonIndex)
        {
            NSString *message = @"Here is application log from my device";
            NSMutableArray *filePaths = [[NSMutableArray alloc] initWithArray:[appDelegate logFilesPaths]];
            [filePaths addObject:[appDelegate stackTraceFilepath]];
            
            UserSessionService *userSessionService = [[UserSessionService alloc] init];
            NSString *recentQliqId = [userSessionService getLastLoggedInUser].qliqId;
            
            NSString *tempDbKeyFileName = nil;
            if (buttonIndex == 2 && [recentQliqId length] > 0) {
                NSString *dbPath = [DBUtil databasePathForQliqId:recentQliqId];
                [filePaths addObject:dbPath];
                [filePaths addObject:[dbPath stringByAppendingString:@"-shm"]];
                [filePaths addObject:[dbPath stringByAppendingString:@"-wal"]];
                NSString *dbKey = [[DBUtil sharedInstance] dbKey];
                if ([dbKey length] > 0) {
                    message = [message stringByAppendingFormat:@"\nDB key: %@\n", dbKey];
                    
                    tempDbKeyFileName = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"dbkey_%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"txt"]];
                    NSString *content = [NSString stringWithFormat:@"PRAGMA key = '%@'", dbKey];
                    [content writeToFile:tempDbKeyFileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
                    [filePaths addObject:tempDbKeyFileName];
                }
            }
            NSString *zipFile = [ReportIncidentService compressFilesToTempFile:filePaths];
            if (tempDbKeyFileName != nil)
            {
                [[NSFileManager defaultManager] removeItemAtPath:tempDbKeyFileName error:nil];
            }
            
            NSData *logData = [NSData dataWithContentsOfFile:zipFile];
            //Open email.
            MFMailComposeViewController_Blocks *controller = [[MFMailComposeViewController_Blocks alloc] init];
            NSString* buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            [controller setSubject:[@"Device Log " stringByAppendingString:buildNumber]];
            [controller setToRecipients:[NSArray arrayWithObject:@"support@qliqsoft.com"]];
            [controller setMessageBody:message isHTML:NO];
            [controller addAttachmentData:logData mimeType:@"application/zip" fileName:[zipFile lastPathComponent]];
            __block typeof(self) weakSelf = self;
            [controller presentFromViewController:self.navigationController animated:YES finish:^(MFMailComposeResult result, NSError *error) {
                [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                [[NSFileManager defaultManager]removeItemAtPath:zipFile error:nil];
                
                if (MFMailComposeResultSent == result)
                {
                    UIAlertView_Blocks *crashAlert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1007-TextEmailWithLogSent", nil)
                                                                                       message:nil
                                                                                      delegate:nil
                                                                             cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                             otherButtonTitles:nil];
                    [crashAlert showWithDissmissBlock:NULL];
                }
            }];
        }
    }];
    
    [self restoreAppCrashEventIfNeeded];
}

- (void)checkForCrash
{
    if ([self appWasCrashed] && [self appShouldSendCrashReport])
    {
        if ([self showUpgradeAlertIfNeeded:YES])
        {
            DDLogSupport(@"checkForCrash: Ignoring for older version of the App.");
            [self restoreAppCrashEventIfNeeded];
        }
        else
        {
            NSString *storedUn = [[KeychainService sharedService] getUsername];
            NSString *storedPassword = [[KeychainService sharedService] getPassword];
            if (storedUn.length > 0 && storedPassword.length > 0)
            {
                [self sendAutomaticCrashReport];
            }
//Krishna 8/13/2017
//Sometimes crash happens and the Credentials are missing
//Don't show this alert to the user in production.
// When user sees report crash, s/he thinks the app is not stable.
#ifdef DEBUG
            else
            {
                DDLogSupport(@"Show alert to ask about crash report sending");
                [self showAlertWithCrash];
            }
#endif
        }
    }
}

- (NSArray *) logFilesPaths
{
    return [self.fileLogger.logFileManager unsortedLogFilePaths];
}

- (NSString *)stackTraceFilepath {
    
    DDLogFileInfo *fileInfo = [self.fileLogger currentLogFileInfo];
    NSString *logDirPath = [FileLoggerManager defaultLogsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"stackTrace - %@", fileInfo.fileName];
    NSString *stackTracePath = [NSString stringWithFormat:@"%@/%@",logDirPath, fileName];
    
    return stackTracePath;
}

#pragma mark -
#pragma mark App Initialization
#pragma mark -

- (void)setupDirectories {
    
    [[NSFileManager defaultManager] createDirectoryAtPath:kDecryptedDirectory withIntermediateDirectories:YES attributes:nil error:nil];
}


//FIXME: Check for resolve issue of logs duplication iOS 10
- (void)setupLogSystem {
    
    // Previous versions of the app didn't remove the zipped log files when
    // incidents were send. Later the log engine was opening the .zip file as log file.
    // Here we remove all .zip files to fix this problem.
    NSString *logDirPath = [FileLoggerManager defaultLogsDirectory];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:logDirPath error:nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.zip'"];
    NSArray *onlyZIPs = [dirContents filteredArrayUsingPredicate:filter];
    for (NSString *zipFile in onlyZIPs) {
        [fm removeItemAtPath:[logDirPath stringByAppendingPathComponent:zipFile] error:nil];
    }
    
    QliqLogFormatter * fileFormatter = [[QliqLogFormatter alloc] init];
    FileLoggerManager * loggerManager = [[FileLoggerManager alloc]init];
    self.fileLogger = [[DDFileLogger alloc] initWithLogFileManager:loggerManager];
    [self.fileLogger setLogFormatter:fileFormatter];
    self.fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:self.fileLogger];
    
    if ([self appWasCrashed]) {
        
        NSArray *bufferedCrashes = [[QliqStorage sharedInstance] bufferedAppCrashes];
        for (NSDictionary *infoDictionary in bufferedCrashes) {
            NSString *stackTrace =  [[QliqStorage sharedInstance] appStackTraceForCrashInfoDictionary:infoDictionary];
            if (stackTrace) {
                NSString *newSavedPath = [appDelegate stackTraceFilepath];
                [stackTrace writeToFile:newSavedPath atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
            }
        }
    }
    
    /*
     Current solution is from here https://github.com/CocoaLumberjack/CocoaLumberjack/issues/765
     */
    {
        BOOL needSetFormatter = NO;
        if (!is_ios_greater_or_equal_10() || [self isSimulator])
        {
            QliqLogFormatter * ttyFormatter = [[QliqLogFormatter alloc] init];
            ttyFormatter.insertNewLine = NO;
            DDTTYLogger * ttyLogger = [DDTTYLogger sharedInstance];
            [ttyLogger setColorsEnabled:YES];
            [ttyLogger setLogFormatter:ttyFormatter];
            [DDLog addLogger:ttyLogger];
            needSetFormatter = YES;
        }
        
        
        QliqLogFormatter * aslFormatter = [[QliqLogFormatter alloc] init];
        aslFormatter.isAslFormatter = YES;
        
        //If iOS greater 10 need to use DDOSLogger instead DDASLLogger
        if (is_ios_greater_or_equal_10) {
            DDOSLogger *oslLogger = [DDOSLogger sharedInstance];
            [oslLogger setLogFormatter:aslFormatter];
            [DDLog addLogger:oslLogger];
        } else {
            DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
            [aslLogger setLogFormatter:aslFormatter];
            [DDLog addLogger:aslLogger];
        }
    }
    
    //One more solution. Doesn't get System logs.
    /*{
     QliqLogFormatter * ttyFormatter = [[QliqLogFormatter alloc] init];
     ttyFormatter.insertNewLine = NO;
     DDTTYLogger * ttyLogger = [DDTTYLogger sharedInstance];
     [ttyLogger setColorsEnabled:YES];
     [ttyLogger setLogFormatter:ttyFormatter];
     [DDLog addLogger:ttyLogger];
     
     if (!is_ios_greater_or_equal_10() || [self isSimulator])
     {
     [DDLog addLogger:[DDASLLogger sharedInstance]];
     }
     }*/
    
#ifdef DEBUG
    ddLogLevel = LOG_LEVEL_INFO;
#else
    ddLogLevel = LOG_LEVEL_SUPPORT;
#endif
}

- (void)handleFirstRun
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(![userDefaults objectForKey:@"FirstRun"])
    {
        DDLogSupport(@"First run detected, clearing keychain and User Defaults");
        [[KeychainService sharedService] clearUserData];
        [userDefaults setObject:[NSNumber numberWithInt:1] forKey:@"FirstRun"];
        [userDefaults setBool:NO forKey:kShowSoundSettings];
        [userDefaults setBool:YES forKey:kShowCreateNewConversation];
        [userDefaults setBool:YES forKey:kShowEnableNotificationsAlert];
        // Krishna 8/12/2017
        // Set this true. Per Customer request:
        [userDefaults setBool:YES forKey:kUploadToQliqSTORKey];
    }
    else
    {
        DDLogSupport(@"Not first run detected");
        if ([[userDefaults valueForKey:kShowEnableNotificationsAlert] boolValue] == NO) {
            [self setupAppNotifications];
        }
        
        if ([userDefaults objectForKey:kShowInviteAlertOnceLoggedInKey])
        {
            if ([[userDefaults objectForKey:kShowInviteAlertOnceLoggedInKey] boolValue] == NO)
            {
                [userDefaults setBool:YES forKey:kShowInviteAlertOnceLoggedInKey];
            }
        }
    }
    
    if ([QliqStorage sharedInstance].deleteMediaUponExpiryKey == nil) {
        [QliqStorage sharedInstance].deleteMediaUponExpiryKey = [NSNumber numberWithBool:YES];
    }
    
    [userDefaults synchronize];
}

- (void) getFirstLaunchInfo
{
    dispatch_async_background(^{
        GetAppFirstLaunchWebService *serv = [[GetAppFirstLaunchWebService alloc] init];
        [serv callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if ([result isKindOfClass:[NSNumber class]]) {
                NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
                NSInteger currentVersion = [build integerValue];
                NSInteger releasedVersion = [(NSNumber *)result integerValue];

#ifdef DEBUG
                [QliqHelper shouldShowSignUpButton:YES];
#else

                if (currentVersion <= releasedVersion) {
                    // if (TRUE) { // For testing SignUP process
                    [QliqHelper shouldShowSignUpButton:YES];
                }
                else {
                    [QliqHelper shouldShowSignUpButton:NO];
                }
#endif
                
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ConfigureSignUpButton" object:nil];
            }
        }];
    });
    
    [QliqHelper shouldShowSignUpButton:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConfigureSignUpButton" object:nil];
}

- (void)setupCalls {
    
    self.inCallStateView = [[NavBarInCallStateView alloc] init];
    self.inCallStateView.delegate = self;
    
    [[QliqSip instance] voiceCallsController].voiceCallsDelegate = self;
}

- (void)setupNetwork {
    
    self.network = [[QliqNetwork alloc] init];
    [QliqNetwork setSharedInstance:self.network];
}

- (void)setupDeviceStatusController {
    
    self.currentDeviceStatusController = [[DeviceStatusController alloc] init];
    self.currentDeviceStatusController.delegate = self;
}


#pragma mark - Notification -

- (void)addNotificationsObservingToAppDelegate {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNeedSendLog:)
                                                 name:SVProgressHUDDidReceiveTouchEventNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNeedShowProgressHUDNotificationName:)
                                                 name:kShowProgressHUDNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNeedHideProgressHUDNotificationName:)
                                                 name:kHideProgressHUDNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAllSIPMessages:)
                                                 name:SipMessageDumpFinishedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenShotTaken:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sslRedirectDetected:)
                                                 name:RestClientCertificateForAnotherDomainDetectedNotification
                                               object:nil];

}

#pragma mark * Observing

- (void)sslRedirectDetected:(NSNotification *)notification
{
    NSString *redirectUrlString = [NSString stringWithFormat:@"http://%@", notification.userInfo[@"domain"]];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground && !self.appInBackground)
    {
        DDLogSupport(@"SSL Redirect detected. Redirect URL: %@", redirectUrlString);
        if (!self.isRedirectionInProgress)
        {
            self.isRedirectionInProgress = YES;
            __weak __block typeof(self) welf = self;
            if (redirectUrlString)
//            if (YES)
            {
                /* Get top presented NC */
                UIViewController *previousPresentedController = nil;
                __block UIViewController *parentNavigationController = self.navigationController;
                while (parentNavigationController.presentedViewController)
                {
                    UIViewController *presentedController = parentNavigationController.presentedViewController;
                    if (presentedController && [presentedController isKindOfClass:[UINavigationController class]] && ![presentedController isKindOfClass:[SSLRedirectNavigationController class]])
                    {
                        parentNavigationController = (UINavigationController *)presentedController;
                    }
                    else if (presentedController && [presentedController isKindOfClass:[UINavigationController class]] && [presentedController isKindOfClass:[SSLRedirectNavigationController class]])
                    {
                        DDLogError(@"<< App tries to present one more SSLRedirect Controller while redirection is going. Should not happens!>>");
                        return;
                    }
                    else if([presentedController isKindOfClass:[UIAlertController class]] || [presentedController isKindOfClass:[UIImagePickerController class]])
                    {
                        previousPresentedController = presentedController;
                        if ([presentedController isKindOfClass:[UIAlertController class]] && [((UIAlertController *)presentedController).message isEqualToString:QliqLocalizedString(@"2395-TextSSLRedirectMessage")])
                        {
                            DDLogError(@"<< SSL Redirect Alert is Already shown. Should not happens!>>");
                            return;
                        }
                        [parentNavigationController dismissViewControllerAnimated:YES completion:nil];
                        break;
                    }
                    else
                        break;
                }
                
                VoidBlock onRedirectBlock = ^{
                    SSLRedirectWebViewController *sslRedirectWebViewController  = [kDefaultStoryboard instantiateViewControllerWithIdentifier:@"SSLRedirectWebViewController"];
                    sslRedirectWebViewController.redirectUrlString = redirectUrlString;
                    
                    sslRedirectWebViewController.onBackBlock = ^{
                        [parentNavigationController dismissViewControllerAnimated:YES completion:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kSSLRedirectControllerStatusChangedNotificationName
                                                                                object:nil
                                                                              userInfo:@{@"presented":@(NO),
                                                                                         @"locked":@(appDelegate.idleController.lockedIdle)}];
                            welf.isRedirectionInProgress = NO;
                            if (previousPresentedController)
                            {
                                [parentNavigationController presentViewController:previousPresentedController animated:YES completion:nil];
                            }
                        }];
                    };
                    
                    SSLRedirectNavigationController *sslRedirectNavController = [[SSLRedirectNavigationController alloc] initWithRootViewController:sslRedirectWebViewController];
                    sslRedirectNavController.modalInPopover = YES;
                    sslRedirectNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    sslRedirectNavController.modalPresentationStyle = UIModalPresentationFullScreen;
                    [parentNavigationController presentViewController:sslRedirectNavController animated:YES completion:nil];
                };
                
                /* It is iOS => 8. Use UIAlertController */
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                         message:QliqLocalizedString(@"2395-TextSSLRedirectMessage")
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *turnoffWifi = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2413-TitleTurnOffWifi")
                                                                      style:UIAlertActionStyleCancel
                                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                                        if (alertController.presentingViewController && ![alertController.presentingViewController isEqual:parentNavigationController])
                                                                            parentNavigationController = alertController.presentingViewController;
                                                                        
                                                                        if (previousPresentedController)
                                                                            [parentNavigationController presentViewController:previousPresentedController animated:YES completion:nil];
                                                                        
                                                                        [[NSNotificationCenter defaultCenter]
                                                                         postNotificationName:kSSLRedirectControllerStatusChangedNotificationName
                                                                         object:nil
                                                                         userInfo:@{@"presented":@(NO),
                                                                                    @"locked":@(appDelegate.idleController.lockedIdle)}];
                                                                        
                                                                        welf.isRedirectionInProgress = NO;
                                                                        
                                                                        UIAlertController *wifiAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                                                                                     message:QliqLocalizedString(@"23955-TextDisconnectWiFi")
                                                                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                                        
                                                                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                                                                                               style:UIAlertActionStyleCancel
                                                                                                                             handler:nil];
                                                                        
                                                                        [wifiAlertController addAction:cancelAction];
                                                                        
                                                                        [parentNavigationController presentViewController:wifiAlertController animated:YES completion:nil];
                                                                        
                                                                    }];
                
                
                UIAlertAction *redirect = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2394-TitleRedirect")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     
                                                                     if (alertController.presentingViewController && ![alertController.presentingViewController isEqual:parentNavigationController])
                                                                         parentNavigationController = alertController.presentingViewController;
                                                                     
                                                                     onRedirectBlock();
                                                                 }];
                
                [alertController addAction:turnoffWifi];
                [alertController addAction:redirect];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kSSLRedirectControllerStatusChangedNotificationName
                                                                    object:nil
                                                                  userInfo:@{@"presented":@(YES),
                                                                             @"locked":@(appDelegate.idleController.lockedIdle)}];
                dispatch_async_main(^{
                    [parentNavigationController presentViewController:alertController animated:YES completion:nil];
                });
            }
            else
            {
                self.isRedirectionInProgress = NO;
                DDLogSupport(@"sslRedirectDetected: Nil redirect URL - %@", redirectUrlString);
            }
        }
        else
        {
            DDLogSupport(@"Redirection is already in progress");
        }
    }
    else
    {
        DDLogSupport(@"Redirection in BG -> redirect URL: %@", redirectUrlString);
    }
}

- (void)onNeedShowProgressHUDNotificationName:(NSNotification *)notification {
    
    NSString *title = notification.userInfo[@"title"];
    if (title) {
        [SVProgressHUD showProgress:-1 status:title maskType:SVProgressHUDMaskTypeBlack];
    } else {
        [SVProgressHUD showProgress:-1];
    }
}

- (void)onNeedHideProgressHUDNotificationName:(NSNotification *)notification {
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
}

- (void)screenShotTaken:(NSNotification *)notification {
    DDLogSupport(@"Screenshot of Qliq App is Taken");
    
    SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
    if (sSettings.blockScreenshots) {
        [[[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1947-TitleSecurityWarning")
                                           message:QliqLocalizedString(@"1946-TitleNotTakingScreenshoot")
                                          delegate:nil
                                 cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 otherButtonTitles:nil] show];
    }
}

- (void)onNeedSendLog:(NSNotification *)notification {
    
    //    if (![self.navigationController.topViewController isKindOfClass:[LoginViewController class]]) {
    //        return;
    //    }
    
    static BOOL alreadyPresented = NO;
    if (!alreadyPresented) {
        alreadyPresented = YES;
        
        [SVProgressHUD dismiss];
        
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1005-TextReportError", nil)
                                                                      message:NSLocalizedString(@"1006-TextAskSendErrorReport", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                                                            otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            if (alert.cancelButtonIndex == buttonIndex) {
                
                alreadyPresented = NO;
                return;
            }
            
            NSString *message = @"Here is application log from my device";
            NSMutableArray *filePaths = [[NSMutableArray alloc] initWithArray:[appDelegate logFilesPaths]];
            
            UserSessionService *userSessionService = [[UserSessionService alloc] init];
            NSString *recentQliqId = [userSessionService getLastLoggedInUser].qliqId;
            
            [filePaths addObject:[DBUtil databasePathForQliqId:recentQliqId]];
            NSString *tempDbKeyFileName = nil;
            NSString *dbKey = [[DBUtil sharedInstance] dbKey];
            if ([dbKey length] > 0) {
                message = [message stringByAppendingFormat:@"\nDB key: %@\n", dbKey];
                
                tempDbKeyFileName = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"dbkey_%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"txt"]];
                NSString *content = [NSString stringWithFormat:@"PRAGMA key = '%@'", dbKey];
                [content writeToFile:tempDbKeyFileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
                [filePaths addObject:tempDbKeyFileName];
            }
            NSString *zipFile = [ReportIncidentService compressFilesToTempFile:filePaths];
            if (tempDbKeyFileName != nil) {
                [[NSFileManager defaultManager] removeItemAtPath:tempDbKeyFileName error:nil];
            }
            
            NSData *logData = [NSData dataWithContentsOfFile:zipFile];
            //Open email.
            MFMailComposeViewController_Blocks *controller = [[MFMailComposeViewController_Blocks alloc] init];
            [controller setSubject:@"iOS Device Log while logging in"];
            [controller setToRecipients:[NSArray arrayWithObject:@"support@qliqsoft.com"]];
            [controller setMessageBody:message isHTML:NO];
            [controller addAttachmentData:logData mimeType:@"application/zip" fileName:[zipFile lastPathComponent]];
            __block typeof(self) weakSelf = self;
            [controller presentFromViewController:self.navigationController animated:YES finish:^(MFMailComposeResult result, NSError *error) {
                [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                BOOL success = [[NSFileManager defaultManager]removeItemAtPath:zipFile error:nil];
                
                if (!success) {
                    DDLogError(@"///---- Error on removing zip file at path: \n%@\n Error:\n %@", zipFile, [error localizedDescription]);
                }
                
                if (MFMailComposeResultSent == result)
                {
                    UIAlertView_Blocks *crashAlert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1007-TextEmailWithLogSent", nil)
                                                                                       message:nil
                                                                                      delegate:nil
                                                                             cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                             otherButtonTitles:nil];
                    [crashAlert showWithDissmissBlock:NULL];
                }
                
                alreadyPresented = NO;
            }];
        }];
    }
}

- (void)didReceiveAllSIPMessages:(NSNotification *)notification {
    
    BOOL condition = NO;
    
    if (self.isSimulator)
        condition = YES;
    else
        condition = (self.didReceiveRemoteNotificationCompletionHandler != nil);
    
    NSNumber *error = notification.userInfo[@"error"];
    
    if ([error boolValue] == NO) {
        self.unProcessedRemoteNotifcations = 0;
        self.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt = 0;
        performBlockInMainThreadSync(^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onNeedHideProgressHUDNotificationName:) object:nil];
            [self performSelector:@selector(onNeedHideProgressHUDNotificationName:) withObject:nil afterDelay:0.f];
        });
    }
    
    if (condition) {
        
        NSNumber *error = notification.userInfo[@"error"];
        /*
         NSNumber *count = notification.userInfo[@"receivedMessagesCount"];
         NSUInteger result = UIBackgroundFetchResultFailed;
         
         if ([count integerValue] > 0) {
         result = UIBackgroundFetchResultNewData;
         } else if ([error boolValue] == YES) {
         result = UIBackgroundFetchResultFailed;
         } else {
         result = UIBackgroundFetchResultNoData;
         }
         */
        
        if ([error boolValue] == NO) {
            self.unProcessedRemoteNotifcations = 0;
            self.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt = 0;
        }
        
        //        UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
        
        // We cannot rely on applicationState. Since application state can remain in BG
        // for as long as the App is still initializating and changes after App becomes active.
        // Instead we should rely on appInBackground variable.
        //
        //if ([AppDelegate applicationState] == UIApplicationStateBackground) {
        if (self.appInBackground == YES) {
            // If all the message were received, reset the counter.
            // Only unregister if the App is in the BG state and it's iOS 10 and above
            // Since iOS 10 does not keep the connection in the BG
            if (is_ios_greater_or_equal_10()) {
                [[UIApplication sharedApplication] clearKeepAliveTimeout];
                DDLogSupport(@"iOS 9. Downloaded all messages in response to Remote Push, shuting down network");
                [self.network.reachability stopNotifications];
                [self disconnectShutdownSIP];
            }
            // 8/20/2014 - Krishna
            // If App is in the BG, wait 2 seconds before callind doneProcessingRemoteNotification
            // to give time for alert played, DB & badge count updated.
            // Happens when the didFinsh is called before the alert is played and badge is updated
            //
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                DDLogSupport(@"doneProcessingRemoteNotification is called after 4 seconds");
                // If user returns to the app before the timeout this block can be executed in fg
                [self doneProcessingRemoteNotification];
            });
        } else {
            // 8/20/2014 - Krishna
            // If the app is not in the BG, call done processing.
            DDLogSupport(@"doneProcessingRemoteNotification is called immediately");
            [self doneProcessingRemoteNotification];
        }
        
    } else if (([AppDelegate applicationState] == UIApplicationStateBackground || self.appInBackground == YES) && is_ios_greater_or_equal_10()){
        DDLogSupport(@"Received all SIP messages due to VoIP Push. Unregister so that it will not register again in BG");
        [[UIApplication sharedApplication] clearKeepAliveTimeout];
        [self.network.reachability stopNotifications];
        //[[QliqSip sharedQliqSip] setRegistered:NO];
        //[[QliqSip sharedQliqSip] shutdownTransport];
    } else {
        DDLogSupport(@"Received all SIP messages not due to PUSH notifications");
    }
    
}


- (void) doneProcessingRemoteNotification
{
    if (!self.isSimulator && self.didReceiveRemoteNotificationCompletionHandler != nil)
    {
        
        DDLogSupport(@"doneProcessingRemoteNotification");
        
        [[QliqUserNotifications getInstance] refreshAppBadge:[ChatMessage unreadMessagesCount]];
        
        self.didReceiveRemoteNotificationCompletionHandler(UIBackgroundFetchResultNewData);
        self.didReceiveRemoteNotificationCompletionHandler = nil;
    }
}

- (void)setupBusyAlertController {
    self.busyAlertController = [[BusyAlertController alloc] init];
}

- (void)showPushNotificationsAlertIfTurnedOff
{
    if (self.isSimulator) {
        DDLogSupport(@"This is simulator. No need to show any popups");
        return;
    }
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:kShowEnableNotificationsAlert] boolValue] == YES) {
        DDLogSupport(@"Waiting for User to say OK to Enable Notifications Popup.");
        return;
    }
    
    if (self.waitingForUserPermission == YES) {
        DDLogSupport(@"Waiting for User to respond to iOS Push Notifications Popup.");
        return;
    }
    
    if ([[QliqStorage sharedInstance].dontShowAlertsOffPopup boolValue] == YES) {
        DDLogSupport(@"User chose not to see Popup for Notifications turned off. Nothing to do");
        return;
    }
    
    NSString *alertTitle = nil;
    NSString *alertMessage = nil;
    
    
    NSString *pushOFF = QliqLocalizedString(@"1008-TextPushOFF");
    NSString *alertsOFF = QliqLocalizedString(@"1009-TextAlertsOFF");
    NSString *badgeAndSoundOFF = QliqLocalizedString(@"1010-TextBadgeAndSoundOFF");
    NSString *soundOFF = QliqLocalizedString(@"1011-TextSoundsOFF");
    NSString *badgeOFF = QliqLocalizedString(@"1012-TextBadgeOFF");
    
    NSString *instructionOnNotifications = QliqLocalizedString(@"1013-TextInstructionOnNotifications");
    NSString *instructionOnAlerts = QliqLocalizedString(@"1014-TextInstructionOnAlerts");
    NSString *instructionOnSoundAndBadge = QliqLocalizedString(@"1015-TextInstructionOnSoundAndBadge");
    NSString *instructionOnSound = QliqLocalizedString(@"1016-TextInstructionOnSound");
    NSString *instructionOnBadge = QliqLocalizedString(@"1017-TextInstructionOnBadge");
    
        
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
            alertTitle = pushOFF;
            alertMessage = instructionOnNotifications;
        }
        
        UIUserNotificationType types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
        
        if (types == UIUserNotificationTypeNone) {
            alertTitle = alertsOFF;
            alertMessage = instructionOnAlerts;
        }
        else if ((types & (UIUserNotificationTypeBadge | UIUserNotificationTypeSound)) == 0) {
            alertTitle = badgeAndSoundOFF;
            alertMessage = instructionOnSoundAndBadge;
        }
        else if ((types & UIUserNotificationTypeSound) == 0) {
            alertTitle = soundOFF;
            alertMessage = instructionOnSound;
        }
        else if ((types & UIUserNotificationTypeBadge) == 0) {
            alertTitle = badgeOFF;
            alertMessage = instructionOnBadge;
        }
    
    if (alertMessage != nil)
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:alertTitle
                                                                      message:alertMessage
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                            otherButtonTitles:NSLocalizedString(@"99-ButtonDontRemindMe", nil), nil];
        
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            if (alert.cancelButtonIndex != buttonIndex) {
                DDLogSupport(@"User chose not to remind about notifications are OFF");
                
                [self setDontShowAlertsOffPopup];
            }
        }];
    }
}


#pragma mark * Handling PUSH/Local Notifications


- (void)handlePushNotificationOnLaunch:(NSDictionary *)userInfo {
    
    NSDictionary *apns = [userInfo valueForKey:@"aps"];
    
    if (apns) {
        DDLogSupport(@"APNS Payload: %@", apns);
        
        self.pushNotificationCallId = [apns valueForKey:@"call_id"];
        self.pushNotificationToUser = [apns valueForKey:@"touser"];
        self.pushNotificationId = [apns valueForKey:@"push_id"];
        
        self.unProcessedRemoteNotifcations = 1;
            self.wasLaunchedDueToRemoteNotificationiOS7 = YES;
    }
}

- (void)handleLocalNotificationOnLaunch:(UILocalNotification *) localNotification {
    
    if (localNotification){
        DDLogInfo(@"Local notification received: %@",[localNotification description]);
        self.unProcessedLocalNotifications = [NSArray arrayWithObject:localNotification];
    }
}

- (void)receiveRemoteNotificationWithInactiveState:(NSDictionary *)userInfo  isVoip:(BOOL)isVoip {
    
    QliqUser *user = [UserSessionService currentUserSession].user;
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    
    DDLogSupport(@"Received remote notification while running in Inactive State, \nPAYLOAD:\n %@", aps);
    if (user && ![self isUserLoggedOut])
    {
        DDLogSupport(@"User LoggedIn. Processing PUSH");
        NSString *pushId = aps[@"push_id"];
        NSString *callId = aps[@"call_id"];
        BOOL isChimed = [[QliqUserNotifications getInstance] isRemoteNotificationChimed:pushId callId:callId];
        if (self.resigningFromBackground || isChimed) {
            
            [[QliqUserNotifications getInstance] openConversationForRemoteNotificationWith:self.navigationController callId:callId];
            }
        else if (isVoip)
        {
            if (![QliqConnectModule processRemoteNotification:aps isVoip:isVoip]) {
                [QliqStorage sharedInstance].failedToDecryptPushPayload = YES;
                [[QliqUserNotifications getInstance] notifyUserAppDidNotProcessRemoteNotificaiton:aps];
                DDLogSupport(@"receiveRemoteNotificationWithInactiveState: App Failed to Decrypt Message in the Inactive --> Notify user, and mark him as should be logged out");
            }
            
            // Krishna 5/7/2018
            // We don't need to do this. Because if the app is inactive state, the app is started in the background
            // The Processing notification bu QliqConnect Module will handle the auto login and register once it is done.
            //
            // [self shutdownReconnectSIP];
        }
        else
        {
            DDLogSupport(@"Received remote notification while App is initializing. Doing nothing...");
        }
    }
    else
    {
        DDLogSupport(@"Received remote notification while App is initializing. Doing nothing...");
    }
}


- (void)receiveRemoteNotificationWithActiveStateSIPConfigured:(NSDictionary *)userInfo isVoip:(BOOL)isVoip {
    DDLogSupport(@"Received remote notification whila App is Active, Restarting SIP transport and Registration | isVoip: %@", isVoip ? @"YES" : @"NO");
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    [QliqConnectModule processRemoteNotification:aps isVoip:isVoip];
    [self shutdownReconnectSIP];
}

- (void)receiveRemoteNotificationInBG:(NSDictionary *)userInfo isVoip:(BOOL)isVoip {
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    NSString *callId = aps[@"call_id"];
    
    DDLogSupport(@"Received remote notification BG isVoIP: %d, appLaunchedWithVoIPPush: %d, unProcessedRemoteNotifcations: %d, \nPAYLOAD:\n %@\n", isVoip, self.appLaunchedWithVoIPPush, self.unProcessedRemoteNotifcations, aps);
    
    //Block for processing of remote notification
    void (^processRemoteNotificationBlock)(void) = ^{
        // Now process Remote Notification
        if ([callId length] > 0)
        {
            // Only store the PUSH notifications that are not silent
            // Non-silent notifications have badge associated with them
            // Otherwise Silient PUSH notification due to Change Notifications are
            // Piling up in DB
            //
            if ([[QliqUserNotifications getInstance] parseBadgeNumberFromPayload:aps] != 0)
            {
                DDLogSupport(@"There is badge. Storing PUSH received. Badge Count: %@", aps[@"badge"]);
                if (![QliqConnectModule processRemoteNotification:aps isVoip:isVoip]) {
                    // Note that the failedToDecryptPushPayload.So when the App goes to FG, Logout the user with
                    // a Message
                    appDelegate.unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt++;
                    [QliqStorage sharedInstance].failedToDecryptPushPayload = YES;
                    [[QliqUserNotifications getInstance] notifyUserAppDidNotProcessRemoteNotificaiton:aps];
                    DDLogSupport(@"receiveRemoteNotificationInBG: App Failed to Decrypt Message in the BG --> Notify user, and mark him as should be logged out");
                    return;
                }
            }
            else
            {
                DDLogSupport(@"There no badge. Check if it is login_credentials");
                // If badge count is not present, it must be non-message related notification such as CN
                // Now check if this is a CN for login_credentials. If it is, we need to logout the user
                if (aps[@"xheaders"] != nil && [aps[@"xheaders"] containsString:@"login_credentials"])
                {
                    [QliqStorage sharedInstance].wasLoginCredentintialsChanged = YES;
                    
                    if (!isVoip)
                    {
                        DDLogSupport(@"receiveRemoteNotificationInBG: Login Credentials were changed in the BG --> Clear Session and Logging out the user");
                        [[QliqConnectModule sharedQliqConnectModule] processLogoutResponseToPush:@"1171-TextAutoLoggedOutBecausePasswordOrEmailChanged" completion:^{
                            [[QliqUserNotifications getInstance] notifyUserAppDidNotProcessRemoteNotificaiton:aps];
                        }];
                    }
                    else
                    {
                        DDLogSupport(@"receiveRemoteNotificationInBG: Login Credentials were changed --> Notify user, and mark him as should be logged out");
                        [[QliqUserNotifications getInstance] notifyUserAppDidNotProcessRemoteNotificaiton:aps];
                    }
                    return;
                }
                
                DDLogSupport(@"There was NOT login_credentials, just try to notify user and reconnect to the server");
                // Show the notification to the user if it has body in alert
                [[QliqUserNotifications getInstance] notifyUserAppDidNotProcessRemoteNotificaiton:aps];
            }
        }
        else
        {
            DDLogSupport(@"There is no CallId in the PUSH Ignoring the PUSH");
        }
        
        if (self.appLaunchedWithVoIPPush == NO)
        {
            DDLogSupport(@"Try to Restart SIP in BG since App is Not in BG due to Restart");
            if (![[QliqSip sharedQliqSip] isConfigured])
            {
                DDLogSupport(@"SIP is not configured. Now doing so and registering...");
                performBlockInMainThread(^{
                    [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
                });
            }
            else
            {
                DDLogSupport(@"SIP is Configured. Now shutting down any stale transport and reregistering...");
                [self shutdownReconnectSIP];
            }
        }
    };
    
    //Check if we have User's session
    QliqUser *user = [UserSessionService currentUserSession].user;
    if (user && [QliqConnectModule sharedQliqConnectModule])
    {
        //If we have configured user session and Qliq Connect Module we can process remote Notification
        dispatch_async_main(^{
            processRemoteNotificationBlock();
        });
        
    }
    else if (user == nil && !isVoip)
    {
        // If there is no user session and it is not VoIP PUSH, Try to Login
        DDLogSupport(@"There is no user for current session Local Login Now.");
        if ([[Login sharedService] startLoginInResponseToRemotePush])
        {
            dispatch_async_main(^{
                processRemoteNotificationBlock();
            });
        }
        else
        {
            DDLogSupport(@"There is no Last User. Dropping the PUSH.");
            return;
        }
    }
    else if (![QliqConnectModule sharedQliqConnectModule] && isVoip)
    {
        //If there is VoIP PUSH, but we haven't configure QliqConnectModule, try to load needed objects for processing notification
        DDLogSupport(@"There is no QliqConnectModule. Loading Login Objects to process PUSH.");
        [[Login sharedService] loadLoginObjectsForLastUserWithCompletion:^(BOOL success) {
            if (success)
                dispatch_async_main(^{
                    processRemoteNotificationBlock();
                });
            else
                DDLogSupport(@"Qliq Connect module is not configured. Dropping the PUSH.");
        }];
    }
    else
    {
        DDLogSupport(@"Received remote notification while App is initializing. Doing nothing...");
    }
}

#pragma mark * Setup Notifications

- (void)setupAppNotifications {
    // 8/24/2014  Krishna
    // Setup Notification must be called everytime the app is launched
    //
    //if ([self getDeviceKey] == nil) {
    DDLogSupport(@"Registering for remote notifications");
    //    if (is_ios_greater_or_equal_10()) {
    //        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
    //                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
    //                                  if (error) {
    //                                      DDLogError(@"%@", [error localizedDescription]);
    //                                  }
    //                                  else
    //                                  {
    //                                      DDLogSupport(@"SUCCES");
    //                                      [[UIApplication sharedApplication] registerForRemoteNotifications];
    //                                  }
    //        }];
    //
    //        UIUserNotificationType types = (UIUserNotificationType) (UIUserNotificationTypeBadge |
    //                                                                 UIUserNotificationTypeSound |
    //                                                                 UIUserNotificationTypeAlert);
    //
    //            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    //    }
    //    else

        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];

    //}
}


- (void) setupFirstInstallPushnotifications {
    DDLogSupport(@"setupFirstInstallPushnotifications: registering for remote notifications");
    self.waitingForUserPermission = YES;
    [self setupAppNotifications];
}

#pragma mark - Processing File Openning -

- (void)processOpenFile:(MediaFile *)mediaFile
{
    if ([mediaFile encrypt])
    {
        NSString *oldPath = mediaFile.decryptedPath;
        mediaFile.decryptedPath = [mediaFile generateFilePathForName:mediaFile.fileName];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:oldPath  toPath:mediaFile.decryptedPath error:&error];
        
        if ([mediaFile save])
        {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1001-TextAskSendFileToContact", nil)
                                                                          message:nil
                                                                         delegate:nil
                                                                cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                                                                otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                if (alert.cancelButtonIndex != buttonIndex)
                {
                    VoidBlock createNewConversation = ^{
                        MessageAttachment *attachment = [[ MessageAttachment alloc ] initWithMediaFile:mediaFile];
                        
                        ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
                        controller.isNewConversation = YES;
                        controller.attachment = attachment;
                        
                        [self.navigationController pushViewController:controller animated:YES];
                    };
                    
                    if (self.navigationController.presentedViewController) {
                        [self.navigationController dismissViewControllerAnimated:NO completion:^{
                            createNewConversation();
                        }];
                    }
                    else {
                        createNewConversation();
                    }
                }
                else
                {
                    
                    //                    Class controllerClassToPush = [MediaGroupsListViewController class];
                    //[self.navigationController switchToViewControllerByClass:controllerClassToPush animated:YES];
                }
            }];
        }
        else
        {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1002-TextUnableSaveFile", nil)
                                                                          message:nil
                                                                         delegate:nil
                                                                cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                otherButtonTitles:nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            }];
        }
    }
    else
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:QliqLocalizedString(@"1003-TextUnableEncryptFile")
                                                                      message:nil
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        }];
    }
}

- (void)handleOpenURL:(NSURL *)openURL
{
    if ([openURL isFileURL])
    {
        MediaFile *mediaFile = [[MediaFile alloc] init];
        mediaFile.fileName = openURL.path.lastPathComponent;
        mediaFile.decryptedPath = openURL.path;
        
        NSString *fileExtension = [mediaFile.decryptedPath pathExtension];
        NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
        NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        
        mediaFile.mimeType = contentType;
        
        if ([[MediaFileService getInstance] fileSupportedWithMimeType:contentType andFileName:mediaFile.fileName])
        {
            if ([UserSessionService currentUserSession].user)
                [self processOpenFile:mediaFile];
            else
                self.pendingMediaFile = mediaFile;
        }
        else
        {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1004-TextUnsupportedFile", nil)
                                                                          message:nil
                                                                         delegate:nil
                                                                cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                otherButtonTitles:nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            }];
        }
    }
}


#pragma mark - Info -

+ (NSString *)currentBuildVersion {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return version;
}

- (NSString *)currentBuildConfigString {
    
    NSString *configString = @"Undefined";
#if DEBUG
    configString = @"Debug";
#else
    configString = @"Release";
#endif
    return configString;
}

- (void) printStartupMessageWithLaunchOptions:(NSDictionary *)launchOptions {
    
    EnviromentInfo *enviroment = [EnviromentInfo sharedInfo];
    DDLogSupport(@"===========================================================================");
    if (self.firstInstallLaunch == YES)
    {
        DDLogSupport(@"                              FIRST INSTALL LAUNCH");
        DDLogSupport(@"===========================================================================");
    }
    DDLogSupport(@"qliq app started. Log Level %ld. Application State: %@ ", (long)ddLogLevel,[[UIApplication sharedApplication] applicationStateString]);
    if ([enviroment hasSourceControlInfo]) {
        DDLogSupport(@"Git branch: %@, commit number: %@, commmit hash: %@", enviroment.branch, enviroment.commitNumber, enviroment.commitHash);
    } else {
        DDLogSupport(@"Git info unavailable");
    }
    DDLogSupport(@"Clang: %@", enviroment.clangVersion);
    DDLogSupport(@"LLVM: %@", enviroment.llvmVersion);
    DDLogSupport(@"Xcode: %@", enviroment.xcodeVersion);
    DDLogSupport(@"Config: %@",[self currentBuildConfigString]);
    DDLogSupport(@"Device: %@",[[DeviceInfo sharedInfo] platform]);
    
    NSString *cpu = @"x32";
    switch ([[DeviceInfo sharedInfo] CPUType]) {
        case CPU_TYPE_ARM:
            cpu = @"ARM32";
            break;
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
        case CPU_TYPE_ARM64:
            cpu = @"ARM64";
            break;
#endif
        case CPU_TYPE_X86:
            cpu = @"X86";
            break;
        case CPU_TYPE_X86_64:
            cpu = @"X86_64";
            break;
    }
    DDLogSupport(@"Processor: physical cores: %d, logical cores: %d, architecture: %@", [[DeviceInfo sharedInfo] numberOfPhisicalCores], [[DeviceInfo sharedInfo] numberOfLogicalCores], cpu);
    DDLogSupport(@"iOS: %@",[[DeviceInfo sharedInfo] iosVersion]);
    DDLogSupport(@"Display Name: %@",[[UIDevice currentDevice] name]);
    DDLogSupport(@"Device UUID: %@", [[UIDevice currentDevice] qliqUUID]);
    DDLogSupport(@"===========================================================================");
    DDLogSupport(@"App version: %@", [AppDelegate currentBuildVersion]);
    DDLogSupport(@"launchOptions: %@",launchOptions);
}

- (BOOL)validDeviceKey {
    // Simulator has no Device Key
    return (self.isSimulator || [QliqStorage sharedInstance].deviceToken);
}

- (BOOL) isSimulator {
    return ([[UIDevice currentDevice] isSimulator] == YES);
}

- (BOOL)isUserLoggedOut {
    DDLogSupport(@"isUserLoggedOut: %@", [QliqStorage sharedInstance].userLoggedOut ? @"YES" : @"NO");
    return [QliqStorage sharedInstance].userLoggedOut;
}

- (BOOL)isMainViewControllerRoot {
    return  [self.navigationController.viewControllers.firstObject isKindOfClass:[MainViewController class]];
}

- (BOOL)shouldAppearStartView {
    NSNumber *firstRun = [[NSUserDefaults standardUserDefaults] valueForKey:@"FirstRun"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"FirstRun"];
    return firstRun.intValue == 1;
}

- (void)measureTimeForActiveAppInFG:(BOOL)isFG {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
//    [userDefaults removeObjectForKey:@"activeApp"];
//    [userDefaults removeObjectForKey:@"memoryWarning"];
//    [userDefaults removeObjectForKey:@"dateMemoryWarning"];
    
    NSMutableArray *activeAppArray = [[userDefaults objectForKey:@"activeApp"] mutableCopy];
    BOOL memoryWarning = [[userDefaults valueForKey:@"warning"] boolValue];
    
    if (!activeAppArray) {
        activeAppArray = [[NSMutableArray alloc] init];
    }

    if (memoryWarning && activeAppArray && activeAppArray.count > 0) {
        
        NSDictionary *firstState = [activeAppArray lastObject];
        BOOL toFG = [firstState[@"goingToFG"] boolValue];
        
        if (toFG) {
            
            NSDate *dateMemoryWarning = [userDefaults objectForKey:@"dateWarning"];
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:dateMemoryWarning, @"date", @(NO), @"goingToFG",nil];
            [activeAppArray addObject:dict];
        }
        
        [[QliqStorage sharedInstance] restoreAppMemoryWarning];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"date", @(isFG), @"goingToFG",nil];
    [activeAppArray addObject:dict];
    [userDefaults setObject:activeAppArray forKey:@"activeApp"];
}

- (void)calculateFGTime {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *activeAppArray = [[userDefaults objectForKey:@"activeApp"] mutableCopy];
    
    double timeOfDay = 0;
    double timeOfSevenDays = 0;
    
    if (activeAppArray.count > 1) {
        for (int i = 0; i < activeAppArray.count - 1; i++) {
            NSDictionary *firstState = activeAppArray[i];
            BOOL toFG = [firstState[@"goingToFG"] boolValue];
            
            if (!toFG)
                continue;
            
            NSDate *toFGTime = firstState[@"date"];
            
            NSMutableDictionary *secondState = activeAppArray[i+1];
            NSDate *toBGTime = secondState[@"date"];
            
            double ti = fabs([toBGTime timeIntervalSinceNow]);
            int day = 3600 * 24;
            
            if (ti > day * 7) {
                [activeAppArray removeObjectsInRange:NSMakeRange(i, activeAppArray.count - i)];
                break;
            }
            
            ti = fabs([toFGTime timeIntervalSinceNow]);
            
            if (ti > day * 7) {
                double t = ti - day * 7;
                toFGTime = [toFGTime dateByAddingTimeInterval:t];
            }
            
            double activeTime = fabs([toFGTime timeIntervalSinceDate:toBGTime]);
            timeOfSevenDays += activeTime;
            
            if (ti > day) {
                continue;
            }
            
            ti = fabs([toFGTime timeIntervalSinceNow]);
            
            if (ti > day) {
                double t = ti - day;
                toFGTime = [toFGTime dateByAddingTimeInterval:t];
            }
            
            activeTime = fabs([toFGTime timeIntervalSinceDate:toBGTime]);
            timeOfDay += activeTime;
        }
    }
}

- (BOOL)appWasCrashed {
    return [[QliqStorage sharedInstance] appWasCrashed];;
};

- (BOOL)appShouldSendCrashReport {
    
    BOOL shouldSendReport = NO;
    
    if ([self appWasCrashed]) {
        NSArray *bufferedCrashes = [[QliqStorage sharedInstance] bufferedAppCrashes];
        //Get buffered crashes and to try send the crash report for more than one buffered crash
        if (bufferedCrashes && bufferedCrashes.count >= 1) {
            //Try to get the last date of crash
            NSDate *lastCrashDate = [[QliqStorage sharedInstance] dateInLastAppCrash:YES];
            NSDate *firstCrashDate = [[QliqStorage sharedInstance] dateInLastAppCrash:NO];
            if (lastCrashDate && firstCrashDate) {
                NSDate *currentDate = [NSDate date];
                NSDate *perHourLastCrashDate = [NSDate dateWithTimeInterval:currentDate.timeIntervalSinceNow sinceDate:lastCrashDate];
                NSDate *perHourFirstCrashDate = [NSDate dateWithTimeInterval:currentDate.timeIntervalSinceNow sinceDate:firstCrashDate];
                double lastCrashSeconds = fabs([perHourLastCrashDate timeIntervalSinceNow]);
                double firstCrashSeconds = fabs([perHourFirstCrashDate timeIntervalSinceNow]);
                int hour = 60 * 60;
                
                // If first crash report or last last crash report happened more
                // than an hour ago, report sendCrashReport
                if (lastCrashSeconds >= hour || firstCrashSeconds >= hour) {
                    //No need to send report several times in 1 hour
                    DDLogSupport(@"Reporting Crash Log. Last Crash Seconds: %f, First Crash Seconds: %f",lastCrashSeconds, firstCrashSeconds);
                    shouldSendReport = YES;
                } else {
                    DDLogSupport(@"Skipping Crash Log. Last Crash Seconds: %f, First Crash Seconds: %f",lastCrashSeconds, firstCrashSeconds);
                }
            }
        }
    } else {
        DDLogSupport(@"Skipping Crash Log. No crashes buffered");
    }
    return shouldSendReport;
}

- (void)storeAppCrashEventWithStackTrace:(NSString *)stackTrace {
    [[QliqStorage sharedInstance] storeAppCrashEventWithStackTrace:stackTrace];
}

- (void)restoreAppCrashEventIfNeeded {
    
    NSArray *bufferedCrashes = [[QliqStorage sharedInstance] bufferedAppCrashes];
    if (bufferedCrashes && bufferedCrashes.count > 0) {
        [[QliqStorage sharedInstance] restoreAppCrashEvent];
    }
}

#pragma mark - Reachability -

- (NSString *)currentReachabilityString {
    return [self.network.reachability restReachabilityString];
}

- (BOOL)isReachable {
    
    return [self.network.reachability isReachable];
}

#pragma mark - Utility/Helpers -


- (void)getNewVersion {
    
    NSURL *url = [NSURL URLWithString:@"http://itunes.apple.com/us/app/qliq/id439811557?mt=8"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)purgeUI {
    
    for (UIViewController * viewController in [self.navigationController viewControllers]){
        if (viewController != self.navigationController.visibleViewController){
            viewController.view = nil;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
}


- (void)presentLandingPage {
    DDLogSupport(@"Preparing to present the landing page");
    
    ApplicationsSubscription *subscription = [UserSessionService  currentUserSession].subscriprion;
    
    if ([subscription subscriptionContains:ApplicationsSubscriptionQliqCharge]) {
        //[[QliqModulesController instance] setPresentedModuleWithName:QliqChargeModuleName];
        //[self.qliqChargeController startChargeModuleWithTab:0];
    }
    else if ([subscription subscriptionContains:ApplicationsSubscriptionQliqCare]) {
        //[[QliqModulesController instance] setPresentedModuleWithName:QliqCareModuleName];
        //start qliqCare module here
    }
    else {
        [[QliqModulesController sharedInstance] setPresentedModuleWithName:QliqConnectModuleName];
        //        Class controllerClassToPush = [ConversationListViewController class];
        //[self.navigationController switchToViewControllerByClass:controllerClassToPush animated:YES];
    }
    
    [self showUpgradeAlertIfNeeded:NO];
}

- (void)userLoggedout {
    [QliqStorage sharedInstance].userLoggedOut = YES;
    [QxPlatfromIOS onUserSessionFinished];
    [self.idleController clearTimeExpired];
}



#pragma mark - Calls -

- (void)showCallInProgressView {
    
    self.inCallStateView.alpha = 0.0;
    [self.window addSubview:self.inCallStateView];
    self.inCallStateView.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x,
                                            self.navigationController.navigationBar.frame.origin.y,
                                            self.navigationController.navigationBar.frame.size.width,
                                            20.0);
    [UIView beginAnimations:@"inCallViewAppear" context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self.inCallStateView];
    [UIView setAnimationDidStopSelector:@selector(startPulsing)];
    self.inCallStateView.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)callInProgressViewDidDisappear {
    
    [self.inCallStateView removeFromSuperview];
    [self.inCallStateView stopPulsing];
}

- (void)hideCallInProgressView {
    
    [UIView beginAnimations:@"inCallViewDisappear" context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(callInProgressViewDidDisappear)];
    self.inCallStateView.alpha = 0.0;
    [UIView commitAnimations];
}

#pragma mark - Alerts -

- (void)setDontShowAlertsOffPopup {
    [QliqStorage sharedInstance].dontShowAlertsOffPopup = [NSNumber numberWithBool:YES];
}

- (BOOL)showUpgradeAlertIfNeeded:(BOOL)force {
    
    NSInteger appStoreVersionInt = [[NSUserDefaults standardUserDefaults] integerForKey:@"AppStoreVersion"];
    DDLogSupport(@"appStoreVersion: %ld", (long)appStoreVersionInt);
    
    int currentVersionInt = [[AppDelegate currentBuildVersion] intValue];
    
    NSDate *lastUpgradeAlertDate = [UserSessionService currentUserSession].userSettings.lastUpgradeAlertDate;
    
    int daysSinceLastAlert = (lastUpgradeAlertDate == nil || [lastUpgradeAlertDate differenceInDaysTo:[NSDate date]]);
    
    if (daysSinceLastAlert <= 0 && force == NO) {
        return FALSE;
    }
    
    if (currentVersionInt < appStoreVersionInt) {
        
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1020-TextNewVersionAvailable!", nil)
                                                                      message:NSLocalizedString(@"1021-TextDownloadNewVersion", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"13-ButtonLater", nil)
                                                            otherButtonTitles:NSLocalizedString(@"14-ButtonDownloadNow", nil), nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            if (buttonIndex != alert.cancelButtonIndex)
                [self getNewVersion];
        }];
        
        [UserSessionService currentUserSession].userSettings.lastUpgradeAlertDate = [NSDate date];
        [[UserSessionService currentUserSession].userSettings write];
        return TRUE;
    }
    
    return FALSE;
}

// Called by security settings processing code
- (void)configureInactivityLock {
    
    SecuritySettings *securitySettings = [UserSessionService currentUserSession].userSettings.securitySettings;
    NSTimeInterval inactivityInterval = securitySettings.maxInactivityTime;
    DDLogSupport(@"configureInactivityLock: DeviceLockEnabled: %d, EnforcePin: %d, InactivityLock: %d, RememberPassword: %d", [[KeychainService sharedService] isDeviceLockEnabled] , securitySettings.enforcePinLogin, securitySettings.inactivityLock, securitySettings.rememberPassword);
    
    if (!securitySettings.inactivityLock || securitySettings.rememberPassword) {
        inactivityInterval = 0;
    }
    
    if (inactivityInterval > 0) {
        DDLogSupport(@"idleController.idleTimeInterval: %g", inactivityInterval);
    }
    else {
        DDLogSupport(@"inactivity_lock is set to false, not starting the idle timer");
    }
    
    self.idleController.idleTimeInterval = inactivityInterval; //VERN
    
    if (inactivityInterval == 0 && [self.idleController lockedIdle]) {
        [self.idleController unlockIdle];
    }
    
    self.idleController.isConfigured = YES;
}

- (IdleEventController *)idleController {
    
    if (nil == _idleController) {
        _idleController = [[IdleEventController alloc] initWithWindow:self.window andNavigationController:self.navigationController];
    }
    
    return _idleController;
}

#pragma mark - Login -

- (void)configurationBeforeLogin {
    //    if (self.wasLaunchedDueToRemoteNotificationiOS7) {
    //        [[Login sharedService] settingShouldSkipAutoLogin:self.wasLaunchedDueToRemoteNotificationiOS7];
    //    }
    
    if(![Login sharedService].lastLoggedUser || [QliqStorage sharedInstance].userLoggedOut) {
        [[QliqUserNotifications getInstance] refreshAppBadge:0];
        dispatch_async_main(^{
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
        });
    }
}

/**
 This method finished login and show MainViewControler
 */
- (void)userDidLogin {
    
    // Krishna 5/5/207
    // Moved this from launch so that we may not see app close immediately after launching
    //
    
    // Initialise Raedee PDF Editor License object
    if (_qliqSignObj == nil) {
        DDLogSupport(@"initializing QliqSign Framwork");
        _qliqSignObj = [[QliqSign alloc] initWithName:"com.qliqsoft.cciphoneapp" company:"QliqSOFT, Inc" mail:"ravi@qliqsoft.com" serial:"V2LFLB-AW8NTO-VM8O6Y-GHOTML-WR63V5-HOFE82"];
    }
    
    [QliqStorage sharedInstance].userLoggedOut = NO;
    [QliqStorage sharedInstance].failedToDecryptPushPayload = NO;
    [QliqStorage sharedInstance].wasLoginCredentintialsChanged = NO;
    
    [QxPlatfromIOS onUserSessionStarted];
    
    [[Login sharedService] settingShouldSkipAutoLogin:NO];
    
    MainViewController *mainController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MainViewController class])];
    [self.navigationController setViewControllers:@[mainController] animated:YES];
    
    
    [[QliqModulesController sharedInstance] activateModulesFromSubscriprions:[UserSessionService currentUserSession].subscriprion];
    
    [self configureInactivityLock];
    
    [self.idleController updateTimeExpired];
    
    [self presentLandingPage];
    
    [self.network.reachability startNotifications];
    
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    if (userSettings.isBatterySavingModeEnabled) {
        DDLogSupport(@"Battery Saving Mode is enabled");
    }
    
    if ((s_lastApplicationState != UIApplicationStateBackground) || [[ReceivedPushNotificationDBService selectNoSentToServer] count] > 0) {
        {
            DDLogSupport(@"Sending request to set_device_status before configuring QliqSip");
            // If app is in fg then always call set_device_status before starting SIP
            // in case bg state was enabled by previous run of the app
            dispatch_async_background(^{
                [SetDeviceStatus setDeviceStatusCurrentAppStateWithCompletion:^(BOOL success, NSError *error) {
                    DDLogSupport(@"set_device_status, success? %d", success);
                }];
            });
        }
    }

    // KK 9/28/2015
    // Do not wait for set_device_status to be successful.
    // If for some reason, webserver is slow or down, we don't
    // want to too long to register. If we do so, it might cause
    // Delay in message delivery. The worse thing that could happen is
    // that we may not get queued up Change Notifications when the app is
    // in the background.
    //
    
    DDLogSupport(@"Configuring QliqSip directly, without waiting for set_device_status");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
    });
    
    if (self.pendingMediaFile)
    {
        [self processOpenFile:self.pendingMediaFile];
        self.pendingMediaFile = nil;
    }
    
    [self updateLastUsers];
    
    [Login sharedService].isLoginRunning = NO;
    
    // Process pending push notifications received before/during login (intialization) process
    [[QliqConnectModule sharedQliqConnectModule] processPendingRemoteNotifications];
    
    //only on main thread
    __weak __block typeof(self) welf = self;
    performBlockInMainThreadSync(^{
        [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(onNeedHideProgressHUDNotificationName:) object:nil];
        [welf performSelector:@selector(onNeedHideProgressHUDNotificationName:) withObject:nil afterDelay:30.f];
    });
}

- (void)updateLastUsers
{
    NSMutableArray *lastUsers = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LAST_USERS"] mutableCopy];
    if (!lastUsers) {
        lastUsers = [NSMutableArray array];
    }
    
    QliqUser *user  = [[Login sharedService].userSessionService getLastLoggedInUser];
    NSString *email = [user email] ? [user email] : @"";
    NSString *name  = [user firstName] ? [user firstName] : @"";
    UIImage *avatar = [user avatar];
    
    NSData *avatarImage = [NSKeyedArchiver archivedDataWithRootObject:avatar];
    
    if ([[lastUsers valueForKey:@"email"] containsObject:email]) {
        NSInteger index = [[lastUsers valueForKey:@"email"] indexOfObject:email];
        [lastUsers removeObjectAtIndex:index];
    }
    
    if (avatar) {
        [lastUsers insertObject:@{@"email" : email, @"name" : name, @"avatar" : avatarImage} atIndex:0];
    }
    else {
        [lastUsers insertObject:@{@"email" : email, @"name" : name} atIndex:0];
    }
    
    if (lastUsers.count > 3) {
        [lastUsers removeObjectsInRange:NSMakeRange(3, lastUsers.count - 3)];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:lastUsers forKeyPath:@"LAST_USERS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAppLaunchedWithVoIPPush:(BOOL)appLaunchedWithVoIPPush {
    _appLaunchedWithVoIPPush = appLaunchedWithVoIPPush;
    DDLogSupport(@"setAppLaunchedWithVoIPPush - %d", appLaunchedWithVoIPPush);
}

- (BOOL)tryToLogoutIfCredentialsChangedOrDecryptionOfPushPayloadFailed
{
    if (![self isUserLoggedOut] || [UserSessionService currentUserSession].user)
    {
        if ([QliqStorage sharedInstance].wasLoginCredentintialsChanged)
        {
            DDLogSupport(@"Login Credentials were changed in the BG. Clear Session and Logging out the user");
            [[QliqConnectModule sharedQliqConnectModule] processLogoutResponseToPush:@"1171-TextAutoLoggedOutBecausePasswordOrEmailChanged" completion:^{
                [[QliqUserNotifications getInstance] notifyUserAboutLogoutWithReason:QliqLocalizedString(@"1171-TextAutoLoggedOutBecausePasswordOrEmailChanged")];
            }];
            return YES;
        }
        
        if ([QliqStorage sharedInstance].failedToDecryptPushPayload)
        {
            DDLogSupport(@"App Failed to Decrypt Message in the BG. Clear Session and Logging out the user");
            [[QliqConnectModule sharedQliqConnectModule] processLogoutResponseToPush:@"30222-LoginWithPassword" completion:^{
                [[QliqUserNotifications getInstance] notifyUserAboutLogoutWithReason:QliqLocalizedString(@"30222-LoginWithPassword")];
            }];
            return YES;
        }
    } else {
        performBlockInMainThreadSync(^{
            NSString *reason = [QliqStorage sharedInstance].wasLoginCredentintialsChanged ? QliqLocalizedString(@"1171-TextAutoLoggedOutBecausePasswordOrEmailChanged") : [QliqStorage sharedInstance].failedToDecryptPushPayload ? QliqLocalizedString(@"3022-LoginWithNewPasswordToRetrieveMessage") : nil;
            if (reason) {
                
                [AlertController showAlertWithTitle:nil
                                            message:reason
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            }
        });
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark DeviceStatusController Delegate
#pragma mark Lock/Unlock
#pragma mark -

- (void)deviceStatusController:(DeviceStatusController *)controller performLockWithCompletition:(CompletionBlock)complete
{
    dispatch_async_main(^{
        [[Login sharedService] startLogoutWithCompletition:^{
            complete(CompletitionStatusSuccess, nil, nil);
        }];
    });
}

- (void)deviceStatusController:(DeviceStatusController *)controller performWipeWithCompletition:(CompletionBlock)complete {
    BOOL success = [QliqConnectModule wipeData];
    
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshDBConversations" object:nil];
    }
    
    CompletitionStatus status = success ? CompletitionStatusSuccess : CompletitionStatusError;
    [[KeychainService sharedService] saveWipeState:(status == CompletitionStatusSuccess) ? GetDeviceStatusWiped : GetDeviceStatusWipeFailed];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveAllMediaFilesNotification" object:nil];
    
    complete(status, nil, nil);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Login sharedService] startLogoutWithCompletition:nil];
    });
    //    [self.idleController lock];
}

#pragma mark -
#pragma mark CallViewControllerDelegate
#pragma mark -

- (void)callViewControllerWillEnteredBackground:(CallViewController *)callViewController {
    
    if([self.callViewController callInProgress]) {
        
        [self showCallInProgressView];
    }
    else {
        
        [self hideCallInProgressView];
    }
}

#pragma mark -
#pragma mark InCallStateViewDelegate
#pragma mark -

- (void)inCallStateViewPressed {
    
    [self pushCallViewControllerAnimated:YES];
    [self hideCallInProgressView];
}

- (void)presentContacts {
    
}



#pragma mark -
#pragma mark QliqSipVoiceCallsDelegate methods
#pragma mark -

- (void)incomingCall:(Call *)call {
    
    [self pushCallViewControllerAnimated:YES];
    [self.callViewController incomingCall:call];
    self.callViewController.callInProgress = YES;
}

- (void)callFailedWithError:(NSString *)error {
    
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1022-TextCallError", nil)
                                                                  message:error
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                        otherButtonTitles: nil];
    [alert showWithDissmissBlock:NULL];
    self.callViewController.callInProgress = NO;
}

- (void)initiatingCall:(Call *)call {
    
    [self pushCallViewControllerAnimated:YES];
    [self.callViewController initiatingCall:call];
    self.callViewController.callInProgress = YES;
}

- (void)callEnded {
    
    [self hideCallInProgressView];
    self.callViewController.callInProgress = NO;
    [self popCallViewControllerAnimated:YES];
}

- (void)callStarted {
    
    [self.callViewController callStarted];
    self.callViewController.callInProgress = YES;
}

- (void)callFailedWithReason:(NSString *)reason {
    
    [self.callViewController callFailedWithReason:reason];
    self.callViewController.callInProgress = NO;
}

#pragma mark -
#pragma mark VoiceCallDelegate
#pragma mark -

- (void)pushCallViewControllerAnimated:(BOOL)animated
{
    //    [self.navigationController switchToViewControllerByClass:[CallViewController class] animated:animated initializationBlock:^UIViewController *{
    //        if (!self.callViewController) {
    //            self.callViewController = [[CallViewController alloc] init];
    //            self.callViewController.delegate = self;
    //        }
    //        return self.callViewController;
    //    }];
    [self hideCallInProgressView];
}

- (void)popCallViewControllerAnimated:(BOOL)animated
{
    if([[self.navigationController topViewController] isEqual:self.callViewController]) {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

#pragma mark -
#pragma mark VoIP Push
#pragma mark -

// Register for VoIP notifications
- (void) voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    
    NSString *voipDeviceTokenStr = [self stringWithDeviceToken:credentials.token];
    DDLogSupport(@"VOIP PUSH token: %@, for Type: %@", voipDeviceTokenStr, type);
    [QliqStorage sharedInstance].voipDeviceToken = voipDeviceTokenStr;
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    NSDictionary *userInfo = payload.dictionaryPayload;
    
    // Regardless of further processing save it first to logdb (or queue)
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    [QxPlatfromIOS savePushNotificationToLogDatabase:aps];
    
    // 4/4/2017 - Krishna
    // Do not Process PUSH Notification when the user is logged off
    // This might cause pjsip to crash
    //
    if ([self isUserLoggedOut]) {
        DDLogSupport(@"Received VoIP PUSH when the user is logged off. Do nothing");
        return;
    }
    
    // The below code is just copied from method that handles regular push notification
    // I don't know if we need to have a different logic for this, probably not
    if (self.appInBackground == YES ) {
        DDLogSupport(@"Received VoIP PUSH and App is in BG mode to process the PUSH");
        // Remote Notification Received and the App is already in BG.
        //
        self.appLaunchedWithVoIPPush = NO;
        [self receiveRemoteNotificationInBG:userInfo isVoip:YES];
    }
    else if (([AppDelegate applicationState] == UIApplicationStateActive) && [[QliqSip sharedQliqSip] isConfigured]) {
        DDLogSupport(@"Received VoIP PUSH and App is in Active Mode.");
        [self receiveRemoteNotificationWithActiveStateSIPConfigured:userInfo isVoip:YES];
    }
    else if ([AppDelegate applicationState] == UIApplicationStateBackground){
        // Krishna 10/2/2016
        // When App is terminated in the BG and App receives VoIP PUSH, the iOS starts the App in BG
        // App needs to process this PUSH. We are going to treat this same as App is Inactive
        DDLogSupport(@"Received VoIP PUSH and App is Started in BG mode");
        self.appLaunchedWithVoIPPush = YES;
        // Mark that App is in BG. So that Next time if the PUSH comes, it will not mark as appLaunchedWithVoIPPush
        //
        self.appInBackground = YES;
        [self receiveRemoteNotificationInBG:userInfo isVoip:YES];
    } else if ([AppDelegate applicationState] == UIApplicationStateInactive){
        DDLogSupport(@"Received VoIP PUSH and App is Started in Inactive or suspended");
        [self receiveRemoteNotificationWithInactiveState:userInfo isVoip:YES];
    } else {
        // Adam Sowa: I used invocation of receiveRemoteNotificationWithInactiveState to test remote push at login screen
//#ifdef DEBUG
//        [self receiveRemoteNotificationWithInactiveState:userInfo isVoip:YES];
//#endif
        DDLogSupport(@"Received VoIP PUSH and App is in unknown state. Dropping it.");
    }
}

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    return [token copy];
}

- (void) shutdownReconnectSIP
{
    // THis is to avoid repeated calling of the same method
    //
    if (self.shutdownRestartSIPInProgress == TRUE) {
        DDLogSupport(@"shutdownReconnectSIP already in progress. Nothing to do.");
        return;
    }
    if ([[QliqSip sharedQliqSip] isStarted] == NO) {
        DDLogSupport(@"Skipping shutdownReconnectSIP because SIP is not started yet");
        return;
    }
    if ([UserSessionService isLogoutInProgress]) {
        DDLogSupport(@"Skipping shutdownReconnectSIP because logout is in progress");
        return;
    }
    
    if (self.lastSipShutdownDate) {
        NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.lastSipShutdownDate];
        DDLogSupport(@"shutdownReconnectSIP was executed %g sec ago", seconds);
        // Krishna 5/20/2018
        // Commeting the code below to avoid regression with Silent PUSH notifications
        // for updating Message Status when the App is in BG and the IP address has
        // changed, When App goes into BG to FG within 30 seconds, we still would like to
        // Shutdown and Restart
        // if (seconds <= 30) {
        //    DDLogSupport(@"Skipping shutdownReconnectSIP because it was executed %g sec ago", seconds);
        //    return;
        // }
    }
    
    self.lastSipShutdownDate = [NSDate date];
    
    DDLogSupport(@"shutdownReconnectSIP");
    self.shutdownRestartSIPInProgress = TRUE;
    BOOL shutdownSuccess = [[QliqSip sharedQliqSip] shutdownTransport];
    if (shutdownSuccess) {
        // Try to setup network again
        [[QliqSip sharedQliqSip] dualNetworkSetup];
        [[QliqSip sharedQliqSip] setRegistered:YES];
        self.shutdownRestartSIPInProgress = FALSE;
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
            weakSelf.shutdownRestartSIPInProgress = FALSE;
        });
    }
}

- (void) disconnectShutdownSIP
{
    DDLogSupport(@"disconnectShutdownSIP");
    [[QliqSip sharedQliqSip] setRegistered:NO];
    [[QliqSip sharedQliqSip] shutdownTransport];
}

- (void) sendAutomaticCrashReport
{
    //Crash report will be send automatically, because user is autologin
    DDLogSupport(@"Crash report will be send automatically");
#ifndef DEBUG
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Crash report does not include database neither log database
        QliqAPIService * service = [[ReportIncidentService alloc] initWithDefaultFilesAndDatabase:NO andLogDatabase:NO andMessage:@"Crash Report" andSubject:@"Crash Report" isNotifyUser:NO];
        [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            DDLogSupport(@"Crash report sending is ended with status: %d, error: %@",status, error);
        }];
    });
    
    [self restoreAppCrashEventIfNeeded];
#else
    performBlockInMainThreadSync(^{
        [self showAlertWithCrash];
    });
#endif
}

+ (UIApplicationState) applicationState
{
    return s_lastApplicationState;
}

+ (AppDelegate *) sharedInstance
{
    return appDelegate;
}

@end

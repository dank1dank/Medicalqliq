//
//  KSDidleController.m
//
//  Created by Brian King on 4/13/10. Fully refactored by Aleksey Garbarev 7.06.12
//  Copyright 2010 King Software Designs. All rights reserved.
//
// Based off: 
//  http://stackoverflow.com/questions/273450/iphone-detecting-user-inactivity-idle-time-since-last-screen-touch
//

#import "IdleEventController.h"
//#import "LockViewController.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "KeychainService.h"
#import "SetDeviceStatus.h"
#import "Login.h"
#import "QliqStorage.h"
#import "SSLRedirectNavigationController.h"

#import "MainViewController.h"

@interface IdleEventController ()<UIGestureRecognizerDelegate>

@property (nonatomic, unsafe_unretained) UINavigationController * navigationController;

@property (nonatomic, strong) UINavigationController *idleLockNavigationController;
@property (nonatomic, strong) UIViewController *previouslyPresentedVC;


@property (nonatomic, strong) NSTimer *idleTimer;
@property (nonatomic, strong) NSDate *lastBackgroundTime;

@property (nonatomic, assign) BOOL isLocked;

@end

@implementation IdleEventController{
    NSTimeInterval idleTimeInterval;
}

@synthesize idleTimer;
@synthesize idleTimeInterval;
@synthesize navigationController;

+ (BOOL)checkIdleTimeExpired {
    
    BOOL expired = YES;
    
    if ([QliqStorage sharedInstance].lastUserTouchTime != nil) {
        NSTimeInterval expiredTimeInterval = [[QliqStorage sharedInstance].lastUserTouchTime timeIntervalSince1970];
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];

        expired = expiredTimeInterval < nowTimeInterval;
    }
    DDLogSupport(@"checkIdleTimeExpired: %@", expired ? @"YES" : @"NO");
    return expired;
}

- (void)updateTimeExpired {
    NSDate *expiredDate = [NSDate dateWithTimeInterval:self.idleTimeInterval sinceDate:[NSDate date]];
    [QliqStorage sharedInstance].lastUserTouchTime = expiredDate;
}

- (void)clearTimeExpired {
    [QliqStorage sharedInstance].lastUserTouchTime = nil;
}

- (void)dealloc {
    if (self.idleTimer) {
        [self.idleTimer invalidate];
        self.idleTimer = nil;
    }
    
    self.previouslyPresentedVC = nil;
    self.idleLockNavigationController = nil;
    self.lastBackgroundTime = nil;
    self.sslAlert = nil;
}


//Init with window that will handle touches events and navigationController that will contains LockViewController
- (id)initWithWindow:(UIWindow *)window andNavigationController:(UINavigationController *)navController
{
    self = [super init];

    if (self) {
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(windowDidTouched:)];
        [tapGesture setCancelsTouchesInView:NO];
        tapGesture.delegate = self;
        [window addGestureRecognizer:tapGesture];
        self.navigationController = navController;
        self.idleTimeInterval = 0;
        self.isConfigured = NO;
        self.sslAlert = nil;
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Setters

- (void)setIdleTimeInterval:(NSTimeInterval)_idleTimeInterval {
//    _idleTimeInterval = 60;
    
    DDLogSupport(@"setIdleTimeInterval: %.02f isLocked: %d", _idleTimeInterval, self.isLocked);
    
    idleTimeInterval = _idleTimeInterval;
    
    if (!self.isLocked) {
        [self updateScheduledTimer:idleTimeInterval];
    }
}

#pragma mark - Activity Timer

- (void)onIdleTimerTimedout {
    DDLogSupport(@"Idle timer fired, isLocked: %d", self.isLocked);
    
    [self lockIdle];
}

- (void)updateScheduledTimer:(NSTimeInterval)interval
{
    [self invalidateTimer];

    if (interval != 0 && !self.isLocked) {
        DDLogSupport(@"Idle timer scheduled. Interval: %f", interval);
        self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(onIdleTimerTimedout)
                                                        userInfo:nil
                                                         repeats:NO];
    }
    // If we come here
    self.lastBackgroundTime = nil;
}

- (void)invalidateTimer
{
    if (idleTimer) {
        if ([idleTimer isValid]) {
            [idleTimer invalidate];
            self.idleTimer = nil;
        }
    }
}

#pragma mark - Public
- (BOOL) shouldLock
{
    if (![appDelegate isMainViewControllerRoot])
    {
        DDLogSupport(@"ShouldLock: NO - Because, looks like user is still not logged in");
        return NO;
    }
    
    BOOL shouldLock = NO;
    SecuritySettings *ss = [UserSessionService currentUserSession].userSettings.securitySettings;
   
    BOOL shouldLockForSecuritySettings = !ss.rememberPassword && (ss.enforcePinLogin || ![[KeychainService sharedService] isDeviceLockEnabled]);
    BOOL shouldLockForLoggedInUser = ![appDelegate isUserLoggedOut] && [UserSessionService currentUserSession].user;
    
    DDLogSupport(@"ShouldLock: %d, rememberPassword: %d, enforcePinLogin: %d, isDeviceLockEnabled: %d, isUserLoggedOut: %d, userSessionUser: %@", shouldLock, ss.rememberPassword, ss.enforcePinLogin, [[KeychainService sharedService] isDeviceLockEnabled], [appDelegate isUserLoggedOut], [UserSessionService currentUserSession].user ? @"YES" : @"NO");

    shouldLock = shouldLockForSecuritySettings && shouldLockForLoggedInUser;
    
    return shouldLock;
}


- (void)lockIdleAfterSSLRedirectNavControllerDismiss:(NSNotification *)notification {
    if (![notification.userInfo[@"presented"] boolValue])
    {
        if (self.previouslyPresentedVC)
        {
            self.idleLockNavigationController = [kDefaultStoryboard instantiateViewControllerWithIdentifier:@"IdleLockNavigationController"];
            __weak __block typeof(self) welf = self;
            [self.previouslyPresentedVC presentViewController:self.idleLockNavigationController animated:NO completion:^{
                welf.previouslyPresentedVC = nil;
            }];
        }
    }
}

- (void)lockIdle {
    DDLogSupport(@"Idle time fired. lock called. isLocked: %d", self.isLocked);
    if (!self.isLocked)
    {
        if ([self shouldLock])
        {
            if ([UserSessionService currentUserSession].sipAccountSettings.username)
            {
                DDLogSupport(@"The app locked");
                
                self.isLocked = YES;
                [self invalidateTimer];
                
                BOOL needToPresentIdleLockNC = YES;
                __block BOOL needToShowSSLRedirectAlert = NO;
                self.previouslyPresentedVC = nil;
                UINavigationController *parentNavigationController = self.navigationController;
                while (parentNavigationController.presentedViewController)
                {
                    UIViewController *presentedController = parentNavigationController.presentedViewController;
                    if ([presentedController isKindOfClass:[UINavigationController class]] && ![presentedController isKindOfClass:[SSLRedirectNavigationController class]])
                    {
                        parentNavigationController = (UINavigationController *)presentedController;
                    }
                    else if ([presentedController isKindOfClass:[UINavigationController class]] && [presentedController isKindOfClass:[SSLRedirectNavigationController class]])
                    {
                        DDLogSupport(@"<-- Idle Lock was started, while SSL Redirect navigation controller is presented. "
                                     "Strat observing, when it will be dismissed to present IdleLock screen."
                                     " Do not show IdleLock screen NOW -->");
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(lockIdleAfterSSLRedirectNavControllerDismiss:)
                                                                     name:kSSLRedirectControllerStatusChangedNotificationName
                                                                   object:nil];
                        self.previouslyPresentedVC = presentedController.presentingViewController;
                        needToPresentIdleLockNC = NO;
                        break;
                    }
                    else if([presentedController isKindOfClass:[UIAlertController class]] || [presentedController isKindOfClass:[UIImagePickerController class]])
                    {
                        self.previouslyPresentedVC = presentedController;
                        if ([presentedController isKindOfClass:[UIAlertController class]] && [((UIAlertController *)presentedController).message isEqualToString:QliqLocalizedString(@"2395-TextSSLRedirectMessage")])
                        {
                            needToShowSSLRedirectAlert = YES;
                        }
                        [parentNavigationController dismissViewControllerAnimated:YES completion:nil];
                        break;
                    }
                    else
                        break;
                }
                
                if (needToPresentIdleLockNC)
                {
                    self.idleLockNavigationController = [kDefaultStoryboard instantiateViewControllerWithIdentifier:@"IdleLockNavigationController"];
                    
                    if(self.sslAlert)
                        self.sslAlert.sslPresentingController = self.idleLockNavigationController;
                    
                    __weak __block typeof(self) welf = self;
                    [parentNavigationController presentViewController:self.idleLockNavigationController animated:NO completion:^{
                        if (needToShowSSLRedirectAlert && welf.previouslyPresentedVC)
                        {
                            [welf.idleLockNavigationController presentViewController:welf.previouslyPresentedVC animated:YES completion:^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kHideKeyboardOnIdleLockWithSSLAlertNotificaiton
                                                                                    object:nil];
                                if(welf.sslAlert)
                                    welf.sslAlert.sslPresentingController = welf.previouslyPresentedVC;
                                welf.previouslyPresentedVC = nil;
                            }];
                        }
                        else if (needToShowSSLRedirectAlert)
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kIdleLockViewControllerPresentedWithSSLAlert
                                                                                object:self.sslAlert];
                        }
                    }];
                }
                
                /*
                 Set values for Loging in after launching, if app was idle Locked and than killed
                 */
                //                [QliqStorage sharedInstance].appIdleLockedState = YES;
                //                [[Login sharedService] settingShouldSkipAutoLogin:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceLockStatusChangedNotificationName
                                                                    object:self.sslAlert
                                                                  userInfo:@{@"locked":@(self.isLocked),
                                                                             @"needToShowSSLRedirectAlert":@(needToShowSSLRedirectAlert)}];
                
               
            }
        }
    }
    else
    {
        DDLogSupport(@"The app is already locked");
    }
}

- (void)unlockIdle{
    DDLogSupport(@"Try to unlock app");
    
    if (self.isLocked)
    {
        self.isLocked = NO;
        __weak __block typeof(self) welf = self;
        
        UIViewController * presenting = self.idleLockNavigationController.presentingViewController;
        [presenting dismissViewControllerAnimated:NO completion:^{
            if (welf.previouslyPresentedVC)
            {
                [presenting presentViewController:welf.previouslyPresentedVC animated:YES completion:^{
                    welf.idleLockNavigationController = nil;
                    welf.previouslyPresentedVC = nil;
                }];
            }
            else
            {
                welf.idleLockNavigationController = nil;
            }
        }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceLockStatusChangedNotificationName
                                                            object:self.sslAlert
                                                          userInfo:@{@"locked":@(self.isLocked)}];
        
        /*
         Set values for AutoLoging after launching, if app was idle unLocked and than killed
         */
//        [QliqStorage sharedInstance].appIdleLockedState = NO;
//        [[Login sharedService] settingShouldSkipAutoLogin:NO];
        
        [self updateScheduledTimer:idleTimeInterval];
        
        dispatch_async_background(^{
            [SetDeviceStatus setDeviceStatusCurrentAppStateWithCompletion:^(BOOL success, NSError *error) {
                DDLogSupport(@"set_device_status, success? %d", success);
            }];
        });
        
        DDLogSupport(@"The app unlocked");
    }
}

- (BOOL)lockedIdle {
    return self.isLocked;
}

- (void)handleApplicationDidBecomeActive
{
    NSTimeInterval secs = - 1.0;
    BOOL shouldTryToLock = NO;
    if (self.idleTimeInterval > 0 && self.lastBackgroundTime)
    {
        shouldTryToLock = YES;
        secs = [[NSDate date] timeIntervalSinceDate:self.lastBackgroundTime];
        secs = MAX(0, self.idleTimeInterval - secs);
    }
    
    DDLogSupport(@"IdleEventController handleApplicationDidBecomeActive, secs until lock: %.02f", secs);
    
    if (self.isConfigured && shouldTryToLock && secs == 0.0)
    {
      [self lockIdle];
    }
    else
    {
        //If no need to lock immediately then restart timer (will do nothing if interval is 0)
        [self updateScheduledTimer:self.idleTimeInterval];
    }
}

- (void)handleApplicationWillResignActive {
    // Krishna - 4/15/2015 App resigns from Active even if there is a new phone call or
    // or user swipes up the settings
    // Let's mark the lastBackgroudTime nil
    // If it is really due to app going into backgroup, the appBackgroundTImerFired will
    // trigger.
    self.lastBackgroundTime = nil;
}

- (void)appBackgroundTimerFired:(BOOL)isDeviceLockEnabled
{
    SecuritySettings *ss = [UserSessionService currentUserSession].userSettings.securitySettings;
    
    self.lastBackgroundTime = nil;
    
    DDLogSupport(@"IdleEventController appBackgroundTimerFired, AppLocked: %d, DeviceLocked: %d", [self lockedIdle], isDeviceLockEnabled);
    
    if (ss.rememberPassword)
    {
        DDLogSupport(@"IdleEventController appBackgroundTimerFired. Will not lock when App becomes Active after idleTime Interval: %f", self.idleTimeInterval);
        return;
    }
    
    if (self.idleTimeInterval > 0 && ![self lockedIdle]) {
        // if lock enabled but not locked then start counting from now
        self.lastBackgroundTime = [NSDate date];
        DDLogSupport(@"IdleEventController appBackgroundTimerFired. Will Lock in %@+%f sec", self.lastBackgroundTime, self.idleTimeInterval );
    }
    
    // Invalidate old timer which should not run in background mode
    [self invalidateTimer];
}

#pragma mark - Actions

- (void)windowDidTouched:(UITapGestureRecognizer *)tapGesture
{
    if (!self.isLocked) {
        [self updateScheduledTimer:idleTimeInterval];
        [self updateTimeExpired];
    }
}

#pragma mark - LockViewControllerDelegate

- (void)unlockApp {
    DDLogSupport(@"Unlock App called");
    [self unlockIdle];
}

@end

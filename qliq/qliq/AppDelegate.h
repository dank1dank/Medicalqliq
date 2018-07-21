//
//  AppDelegate.h
//  qliq
//
//  Created by Paul Bar on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QliqSign/QliqSign.h>

#import "DeviceStatusController.h"
#import "QliqNetwork.h"
#import "IdleEventController.h"

@class DDFileLogger;
@class UserSessionService;
@class QliqNavigationController;
@class BusyAlertController;

extern CGFloat systemVersion;

@interface AppDelegate : UIResponder <UIApplicationDelegate, DeviceStatusControllerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;

@property (nonatomic, readonly, strong) IdleEventController *idleController;
@property (nonatomic, readonly, strong) BusyAlertController *busyAlertController;
@property (nonatomic, readonly, strong) DeviceStatusController *currentDeviceStatusController;

@property (nonatomic, copy) NSString *pushNotificationCallId;
@property (nonatomic, strong) NSString *pushNotificationToUser;
@property (nonatomic, strong) NSString *pushNotificationId;
@property (nonatomic, strong) NSString *availableVersion;

@property (nonatomic, readonly, strong) QliqNetwork *network;

/* App Conditions
 */
@property (nonatomic, readonly, assign) BOOL appInBackground;
@property (nonatomic, readonly, assign) BOOL firstInstallLaunch;
@property (nonatomic, assign) BOOL appLaunchedWithVoIPPush;

@property (nonatomic, readonly, assign) int unProcessedRemoteNotifcations;
@property (nonatomic, assign) int unProcessedRemoteNotifcationsWithMessagesFailedToDecrypt;
@property (nonatomic, strong) NSArray *unProcessedLocalNotifications;

@property (strong, nonatomic, readonly) QliqSign *qliqSignObj;


@property (nonatomic, assign) BOOL wasLaunchedDueToRemoteNotificationiOS7;

- (void) setupAppNotifications;
- (void) setupFirstInstallPushnotifications;
- (void) showCallInProgressView;
- (void) hideCallInProgressView;
- (NSArray *) logFilesPaths;
- (NSString *) stackTraceFilepath;
- (void) restoreAppCrashEventIfNeeded;
- (void) getNewVersion;
- (BOOL) isReachable;
- (void) configureInactivityLock;
- (BOOL) validDeviceKey;
- (void) showPushNotificationsAlertIfTurnedOff;
- (void) userLoggedout;
- (void) doneProcessingRemoteNotification;
- (void) userDidLogin;
- (void)updateLastUsers;
- (void)showAlertWithCrash;


- (BOOL)tryToLogoutIfCredentialsChangedOrDecryptionOfPushPayloadFailed;
- (BOOL) isUserLoggedOut;
- (BOOL)isMainViewControllerRoot;
- (void) getFirstLaunchInfo;
- (void) shutdownReconnectSIP;
- (void) disconnectShutdownSIP;

- (void) sendAutomaticCrashReport;

- (BOOL)appWasCrashed;
- (BOOL)appShouldSendCrashReport;

/* App information
 */
+ (NSString *) currentBuildVersion;
// We query app state in many background methods but UIApplication can be accessed on the main thread only
// for this reason we cache the last know app state here
+ (UIApplicationState) applicationState;
// Access to AppDelegate for background threads that will NOT use any UI API
// It is safe to read or write properites and our logic only functions
+ (AppDelegate *) sharedInstance;

@end

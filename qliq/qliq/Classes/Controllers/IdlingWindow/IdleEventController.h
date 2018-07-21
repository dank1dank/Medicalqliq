//
//  KSDidleController.h
//
//  Created by Brian King on 4/13/10. Fully refactored by Aleksey Garbarev 7.06.12
//  Copyright 2010 King Software Designs. All rights reserved.
//
// Based off: 
//  http://stackoverflow.com/questions/273450/iphone-detecting-user-inactivity-idle-time-since-last-screen-touch
//

#import <UIKit/UIKit.h>
#import "SSLRedirect_AlertView.h"
#define kHideKeyboardOnIdleLockWithSSLAlertNotificaiton    @"HideKeyboardOnIdleLockWithSSLAlertNotificaiton"

@interface IdleEventController : NSObject

@property (nonatomic, assign) BOOL isConfigured;
@property (nonatomic) NSTimeInterval idleTimeInterval;
@property (nonatomic, strong) SSLRedirect_AlertView *sslAlert;

- (id)initWithWindow:(UIWindow *)window andNavigationController:(UINavigationController *)navController;

- (void)lockIdle;
- (void)unlockIdle;
- (BOOL)lockedIdle;

- (void)appBackgroundTimerFired:(BOOL)isDeviceLockEnabled;

- (void)handleApplicationDidBecomeActive;
- (void)handleApplicationWillResignActive;

+ (BOOL)checkIdleTimeExpired;
- (void)updateTimeExpired;
- (void)clearTimeExpired;

@end

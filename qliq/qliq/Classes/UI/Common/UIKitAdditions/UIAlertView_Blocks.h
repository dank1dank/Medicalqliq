//
//  UIAlertView_Blocks.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSSLRedirectControllerStatusChangedNotificationName    @"SSLRedirectControllerStatusChangedNotificationName"
#define kHideKeyboardOnIdleLockWithSSLAlertNotificaiton    @"HideKeyboardOnIdleLockWithSSLAlertNotificaiton"
#define kIdleLockViewControllerPresentedWithSSLAlert   @"IdleLockViewControllerPresentedWithSSLAlert"

@interface UIAlertView_Blocks : UIAlertView

- (void) showWithDissmissBlock:(void(^)(NSInteger buttonIndex))block;

@end


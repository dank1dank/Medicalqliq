//
//  BusyAlertController.m
//  qliq
//
//  Created by Aleksey Garbarev on 08.08.13.
//
//

#import "BusyAlertController.h"
#import "QliqSip.h"
#import "SVProgressHUD.h"
#import "QliqConnectModule.h"
#import "NotificationUtils.h"


@implementation BusyAlertController {
    BOOL needSipRigster;
}

- (void) setNeedSipRegister
{
    needSipRigster = YES;
}

- (void) sendSipRegisterIfNeeded
{
    if (needSipRigster) {
        DDLogSupport(@"needSipRegister");
        [self sendSipRegister];
        needSipRigster = NO;
    }
}

- (void) sendSipRegisterWhenApplicationActive
{
    DDLogSupport(@"Will send sip register on active");
    [self performWhenApplicationActive:^{
        [self sendSipRegister];
    }];
}

- (void) sendSipRegister
{
    DDLogSupport(@"Sending sip register..");
    [[QliqSip sharedQliqSip] setRegistered:YES];
   /* if (![SVProgressHUD isVisible]) {
        [self showBusyAlert];
        [self registerForRegistrationStatus];
    }*/
}


- (void) performWhenApplicationActive:(dispatch_block_t)block
{
    dispatch_group_t application_state_group = nil;
    
    if ([[UIApplication sharedApplication]applicationState] != UIApplicationStateActive){
        application_state_group = dispatch_group_create();
        dispatch_group_enter(application_state_group);
        
        [NSNotificationCenter  notifyOnceForNotification:UIApplicationDidBecomeActiveNotification usingBlock:^(NSNotification *note) {
            if (application_state_group){
                dispatch_group_leave(application_state_group);
            }
        }];
    }
    
    if (application_state_group){
        dispatch_group_notify(application_state_group, dispatch_get_main_queue(), block);
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - 

- (void)showBusyAlert {
    DDLogSupport(@"Showing busy alert");
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"1901-TextDownloadingMessages", nil)];
}

- (void) dismissBusyAlert
{
    DDLogSupport(@"DismissBusy alert");
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
}

- (void) dismissBusyWithErrorMessage:(NSString *)errorMessage
{
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD showErrorWithStatus:errorMessage];
        }
    });
}

- (void) registerForRegistrationStatus
{
    [NSNotificationCenter notifyOnceForNotification:SIPRegistrationStatusNotification usingBlock:^(NSNotification *note) {
        [self didRecieveRegistrationStatus:note];
    }];
}

- (void) didRecieveRegistrationStatus:(NSNotification *)notification
{
    NSNumber *isRegistered = [notification userInfo][@"isRegistered"];
    if ([isRegistered boolValue]) {
        [self registerToReceiveMessage];
    } else {
        [self dismissBusyWithErrorMessage:@"Could not Connect to Message server"];
    }
}

- (void) registerToReceiveMessage
{
    [self registerForTimeout];
    [NSNotificationCenter notifyOnceForNotification:NewChatMessagesNotification usingBlock:^(NSNotification *note) {
        [self didReceiveMessage];
    }];
}

- (void) registerForTimeout
{
    dispatch_async_main_after(5.0, ^{
        [self dismissBusyAlert];
    });
}

- (void) didReceiveMessage
{
    [self dismissBusyAlert];
}

@end

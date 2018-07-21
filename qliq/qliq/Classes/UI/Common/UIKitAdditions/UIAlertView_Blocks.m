//
//  UIAlertView_Blocks.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIAlertView_Blocks.h"

@interface UIAlertView_Blocks ()<UIAlertViewDelegate>
@end

@implementation UIAlertView_Blocks{
    void(^action_block)(NSInteger buttonIndex);
    UITextField * textField;
}

- (void)dealloc{
    
    action_block = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) showWithDissmissBlock:(void(^)(NSInteger buttonIndex))block{
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        weakSelf.delegate = weakSelf;
        action_block = block;
        [weakSelf show];
        
        [weakSelf addNotifications];
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (kUIAlertViewHideButtonIndex == buttonIndex)
        return;

    if (action_block)
        action_block(buttonIndex);
    
    [self removeNotifications];
    
    action_block = nil;
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceLockStatusChangedNotification:)
                                                 name:kDeviceLockStatusChangedNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sslRedirectControllerStatusChaged:)
                                                 name:kSSLRedirectControllerStatusChangedNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(idleLockViewControllerPresentedWithSSLAlert:)
                                                 name:kIdleLockViewControllerPresentedWithSSLAlert
                                               object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSSLRedirectControllerStatusChangedNotificationName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDeviceLockStatusChangedNotificationName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kIdleLockViewControllerPresentedWithSSLAlert
                                                  object:nil];
}

#pragma mark -
#pragma mark NSNotification observing
#pragma mark -

- (void)onDeviceLockStatusChangedNotification:(NSNotification *)notification {
    
    
    if ([notification.userInfo[@"locked"] boolValue])
    {
        if(!(notification.userInfo[@"needToShowSSLRedirectAlert"] && [self isEqual:notification.object]))
            [self dismissWithClickedButtonIndex:kUIAlertViewHideButtonIndex animated:NO];
    }
    else
    {
        [self show];
    }
}

- (void)sslRedirectControllerStatusChaged:(NSNotification *)notification {
    
    if ([notification.userInfo[@"presented"] boolValue])
    {
            [self dismissWithClickedButtonIndex:kUIAlertViewHideButtonIndex animated:NO];
    }
    else
    {
        if (![notification.userInfo[@"locked"] boolValue] && ![self isEqual:notification.object])
        {
            [self show];
        }
    }
}

- (void)idleLockViewControllerPresentedWithSSLAlert:(NSNotification *)notification
{
    if (notification.object && [notification.object isEqual:self]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHideKeyboardOnIdleLockWithSSLAlertNotificaiton object:self];
    }
}

@end

//
//  PatientHeaderView.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import "QliqAlertViewDelegate.h"

@implementation QliqAlertViewDelegate
@synthesize callback;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}

+ (void)showAlertView:(UIAlertView *)alertView
         withCallback:(AlertViewCompletionBlock)callback {
    __block QliqAlertViewDelegate *delegate = [[QliqAlertViewDelegate alloc] init];
    alertView.delegate = delegate;
    delegate.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        delegate = nil;
    };
    [alertView show];
}

@end
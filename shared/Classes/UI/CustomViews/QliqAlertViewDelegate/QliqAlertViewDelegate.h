//
//  QliqAlertViewDelegate.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/28/2012
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
@interface QliqAlertViewDelegate : NSObject<UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong,nonatomic) AlertViewCompletionBlock callback;

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;

@end
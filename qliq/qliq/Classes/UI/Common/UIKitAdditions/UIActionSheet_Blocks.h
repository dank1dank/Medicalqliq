//
//  UIActionSheet_Blocks.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIActionSheet_Blocks : UIActionSheet

typedef enum {UIActionSheetActionWillDissmiss, UIActionSheetActionDidDissmiss, UIActionSheetActionDidClicked} UIActionSheetAction;

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles;
- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
- (void)showInView:(UIView *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex)) dissmissBlock;
- (void)showFromTabBar:(UITabBar *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock;
- (void)showFromToolbar:(UIToolbar *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock;

@end

//
//  UIActionSheet_Blocks.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIActionSheet_Blocks.h"

@interface  UIActionSheet_Blocks()<UIActionSheetDelegate>

@end 

@implementation UIActionSheet_Blocks{
    void(^block)(UIActionSheetAction action, NSUInteger buttonIndex);
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles{
    
    
    self = [super initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    int argc = 0;
    for (NSString * title in otherButtonTitles){
        [self addButtonWithTitle:title];
        argc++;
    }
    if (cancelButtonTitle){
        [self addButtonWithTitle:cancelButtonTitle];
        self.cancelButtonIndex = argc++;
    }
    
    
    return self;
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...{

    
    self = [super initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];


    int argc = 0;
    va_list args;
    va_start(args, otherButtonTitles);
    for (NSString * title = otherButtonTitles; title != nil; title = va_arg(args, NSString *)){
        [self addButtonWithTitle:title];
        argc++;
    }
    va_end(args);
    if (cancelButtonTitle){
        [self addButtonWithTitle:cancelButtonTitle];
        self.cancelButtonIndex = argc++;
    }
    if (destructiveButtonTitle){
        [self addButtonWithTitle:destructiveButtonTitle];
        self.destructiveButtonIndex = argc++;
    }

    
    return self;
}



- (void)showInView:(UIView *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock{
    block = dissmissBlock;
 
    self.delegate = self;
    @try {
        [self showInView:view];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
}

- (void)showFromTabBar:(UITabBar *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock{
    block = dissmissBlock;
    
    self.delegate = self;
    [self showFromTabBar:view];
}

- (void)showFromToolbar:(UIToolbar *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock{
    block = dissmissBlock;
    
    self.delegate = self;
    [self showFromToolbar:view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (block) block(UIActionSheetActionWillDissmiss,buttonIndex);
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (block) block(UIActionSheetActionDidClicked,buttonIndex);
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (block) block(UIActionSheetActionDidDissmiss,buttonIndex);
}

@end

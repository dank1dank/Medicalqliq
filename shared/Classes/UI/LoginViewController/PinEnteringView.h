//
//  PinEnteringView.h
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StretchableButton;

@protocol PinEnteringViewDelegate <NSObject>

-(void) didEnterPin:(NSString*)pin;
-(void) didCanelEnteringPin;
-(void) switchToPasswordButtonPressed;

@end

@interface PinEnteringView : UIScrollView <UITextFieldDelegate,QliqTextfieldDelegate>
{
    StretchableButton *switchToPasswordButton;
    UILabel *enterPinLabel;
    NSMutableArray *backgrounds;
    NSMutableArray *fields;
}

-(void) reset;
-(void) hideKeyboard;

-(void) setHiddenForPasswordButton:(BOOL)hidden;

@property(nonatomic, readonly) UILabel *enterPinLabel;
@property(nonatomic, assign) id<PinEnteringViewDelegate> pinEnteringDelegate;

@end

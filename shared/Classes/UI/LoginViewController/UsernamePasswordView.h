//
//  LoginView.h
//  qliq
//
//  Created by Paul Bar on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RoundedLightGreyGradientView;
@class StretchableButton;
@class QliqButton;

@protocol UsernamePasswordViewDelegate <NSObject>

-(void) loginWithUsername:(NSString*)username andPassword:(NSString*)password;
-(void) forgotPasswordButtonPressed;

@end

@interface UsernamePasswordView : UIScrollView <UITextFieldDelegate>
{
    RoundedLightGreyGradientView *usernameTextfieldBackground;
    UITextField *usernameTextField;
    
    RoundedLightGreyGradientView *passwordTextfieldBackground;
    UITextField *passwordTextField;
    
    StretchableButton *forgotPasswordButton;
}

-(void) focusUsername;
-(void) focusPassword;

-(void) clearPassword;
-(void) prefillUsername:(NSString*)username;
-(void) prefillPassword:(NSString *)password;
-(void) unmaskPassword;
-(void) maskPassword;

- (void) closeKeyboard;

@property (nonatomic, assign) id<UsernamePasswordViewDelegate> up_delegate;

@end

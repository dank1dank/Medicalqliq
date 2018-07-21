//
//  LoginView.m
//  qliq
//
//  Created by Paul Bar on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsernamePasswordView.h"
#import "RoundedLightGreyGradientView.h"
#import "StretchableButton.h"

#define HEADER_HEIGHT 57.0

@interface UsernamePasswordView()

-(void) forgotPasswordButtonPressed;

@end


@implementation UsernamePasswordView {
    BOOL alreadyInEditing;
}

@synthesize up_delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        usernameTextfieldBackground = [[RoundedLightGreyGradientView alloc] init];
        [self addSubview:usernameTextfieldBackground];
        
        usernameTextField = [[UITextField alloc] init];
        usernameTextField.borderStyle = UITextBorderStyleNone;
        usernameTextField.textAlignment = UITextAlignmentCenter;
        usernameTextField.returnKeyType = UIReturnKeyDefault;
        usernameTextField.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
        usernameTextField.adjustsFontSizeToFitWidth = YES;
        usernameTextField.placeholder = @"Email";
        usernameTextField.delegate = self;
		usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        usernameTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
        [self addSubview:usernameTextField];
        
        passwordTextfieldBackground = [[RoundedLightGreyGradientView alloc] init];
        [self addSubview:passwordTextfieldBackground];
        
        passwordTextField = [[UITextField alloc] init];
        passwordTextField.borderStyle = UITextBorderStyleNone;
        passwordTextField.textAlignment = UITextAlignmentCenter;
        passwordTextField.returnKeyType = UIReturnKeyDefault;
        passwordTextField.secureTextEntry = YES;
        passwordTextField.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
        passwordTextField.adjustsFontSizeToFitWidth = YES;
        passwordTextField.returnKeyType = UIReturnKeyDone;
		passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		passwordTextField.keyboardType = UIKeyboardTypeDefault;
        passwordTextField.placeholder = @"Password";
#ifdef TEST_ACCOUNT_PASSWORD
        DDLogSupport(@"Filling the password view with debug password");
        passwordTextField.text = TEST_ACCOUNT_PASSWORD;
#endif
        passwordTextField.delegate = self;
        [self addSubview:passwordTextField];
        
        /*forgotPasswordButton = [[StretchableButton alloc] init];
        forgotPasswordButton.btnType = StretchableButton25;
        [forgotPasswordButton setTitle:NSLocalizedString(@"Forgot password", @"Forgot password") forState:UIControlStateNormal];
        forgotPasswordButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        [forgotPasswordButton addTarget:self action:@selector(forgotPasswordButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:forgotPasswordButton];*/
        
        self.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotateFromInterfaceOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];

    }
    return self;
}

-(void) dealloc
{
    [usernameTextfieldBackground release];
    [usernameTextField release];
    [passwordTextfieldBackground release];
    [passwordTextField release];
    [forgotPasswordButton release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat viewsOffset = 10.0;
    CGFloat yOffset = viewsOffset + HEADER_HEIGHT;
    
    usernameTextfieldBackground.frame = CGRectMake(viewsOffset,
                                                   yOffset,
                                                   self.frame.size.width - (2.0 * viewsOffset),
                                                   35.0);
    
    usernameTextField.frame = CGRectMake(viewsOffset,
                                         yOffset + 5.0,
                                         usernameTextfieldBackground.frame.size.width,
                                         32.0);
    
    yOffset += usernameTextfieldBackground.frame.size.height;
    yOffset += viewsOffset;
    
    passwordTextfieldBackground.frame = CGRectMake(viewsOffset,
                                                   yOffset,
                                                   self.frame.size.width - (2.0 * viewsOffset),
                                                   35.0);
    
    passwordTextField.frame = CGRectMake(viewsOffset,
                                         yOffset + 5.0,
                                         passwordTextfieldBackground.frame.size.width,
                                         32.0);
    
    yOffset += passwordTextfieldBackground.frame.size.height;
    yOffset += viewsOffset;
    
    forgotPasswordButton.frame = CGRectMake(viewsOffset,
                                            yOffset,
                                            self.frame.size.width - (2.0*viewsOffset),
                                            44.0);

}

-(void) focusUsername
{
    [usernameTextField becomeFirstResponder];
}

-(void) focusPassword
{
    [passwordTextField becomeFirstResponder];
}

-(void) clearPassword
{
    passwordTextField.text = @"";
}

-(void) unmaskPassword
{
    passwordTextField.secureTextEntry = NO;
}

-(void) maskPassword
{
    passwordTextField.secureTextEntry = YES;
}

-(void) prefillUsername:(NSString *)username
{
    usernameTextField.text = username;
}

-(void) prefillPassword:(NSString *)password
{
    passwordTextField.text = password;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void) closeKeyboard{
    [passwordTextField resignFirstResponder];
    [usernameTextField resignFirstResponder];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    CGRect frame = [self convertRect:passwordTextField.frame fromView:[passwordTextField superview]];
    
    insets.top = MIN( (self.frame.size.height - kKeyboardHeight) - CGRectGetMaxY(frame) - 10, 0);
    insets.bottom = frame.size.height;
    
    
    if (alreadyInEditing) {
        [self setContentInset:insets];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self setContentInset:insets];
        }];
        alreadyInEditing = YES;
    }
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        [self setContentInset:UIEdgeInsetsZero];
    }];
    
    if(textField == usernameTextField && !isValidEmail(usernameTextField.text))
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:usernameTextField.text
                                                                      message:@"is not a valid email address"
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles: nil];
        [[alert autorelease] showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            [usernameTextField becomeFirstResponder];
        }];
    }
    
}

- (void) didRotateFromInterfaceOrientation
{
    [UIView animateWithDuration:0.3 animations:^{
        [self textFieldDidBeginEditing:passwordTextField];
    }];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if(textField == usernameTextField)
    {
        if(!isValidEmail(usernameTextField.text))
        {
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:usernameTextField.text
                                                                          message:@"is not a valid email address"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Ok"
                                                                otherButtonTitles: nil];
            [[alert autorelease] showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                [usernameTextField becomeFirstResponder];
            }];
        } else {
            [passwordTextField becomeFirstResponder];
        }
    }
    if(textField == passwordTextField)
    {
        [passwordTextField resignFirstResponder];
        [self.up_delegate loginWithUsername:usernameTextField.text andPassword:passwordTextField.text];
    }
    return YES;
}

#pragma mark -
#pragma mark Private

-(void) forgotPasswordButtonPressed
{
    [self.up_delegate forgotPasswordButtonPressed];
}

@end

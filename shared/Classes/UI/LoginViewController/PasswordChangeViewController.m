//
//  PasswordChangeViewController.m
//  qliq
//
//  Created by Developer on 14.11.13.
//
//

#import "PasswordChangeViewController.h"
#import "UserHeaderView.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "RoundedLightGreyGradientView.h"
#import "UpdatePasswordService.h"
#import "Logout.h"
#import "SVProgressHUD.h"
#import "SipAccountSettings.h"
#import "KeychainService.h"

@interface PasswordChangeViewController () < UITextFieldDelegate >
@property (nonatomic, strong) UITextField *setPasswordField;
@property (nonatomic, strong) UITextField *confirmPasswordField;
@property (nonatomic, strong) QliqButton *sendButton;
@property (nonatomic, strong) UserHeaderView *userHeaderView;
@property (nonatomic, strong) UserSessionService *sessionService;
@end

@implementation PasswordChangeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];
    
    self.userHeaderView = [[UserHeaderView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 57.f)];
    [self.view addSubview:self.userHeaderView];
    
    self.sessionService = [[UserSessionService alloc] init];
    QliqUser *lastLoggedUser = [self.sessionService getLastLoggedInUser];
    QliqGroup *lastLoggedGroup = (QliqGroup *)[self.sessionService getLastLoggedInUserGroup];
    if (lastLoggedUser == nil){
        self.userHeaderView.hidden = YES;
    } else {
        self.userHeaderView.hidden = NO;
        [self.userHeaderView fillWithContact:lastLoggedUser andGroup:(QliqGroup *)lastLoggedGroup];
    }
    
    RoundedLightGreyGradientView *background = [[RoundedLightGreyGradientView alloc] initWithFrame:CGRectMake(10.f, self.userHeaderView.frame.size.height + 10.f, self.view.frame.size.width - 20.f, 35.f)];
    [self.view addSubview:background];
    
    self.setPasswordField = [[UITextField alloc] initWithFrame:background.frame];
    self.setPasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.setPasswordField.textAlignment = UITextAlignmentLeft;
    self.setPasswordField.placeholder = @"Set new password";
    self.setPasswordField.delegate = self;
    self.setPasswordField.secureTextEntry = YES;
    self.setPasswordField.borderStyle = UITextBorderStyleNone;
    self.setPasswordField.textAlignment = UITextAlignmentCenter;
    self.setPasswordField.returnKeyType = UIReturnKeyDefault;
    self.setPasswordField.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
    self.setPasswordField.adjustsFontSizeToFitWidth = YES;
    self.setPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.setPasswordField];
    
    background = [[RoundedLightGreyGradientView alloc] initWithFrame:CGRectMake(10.f, background.frame.origin.y + background.frame.size.height + 10.f, self.view.frame.size.width - 20.f, 35.f)];
    [self.view addSubview:background];
    
    self.confirmPasswordField = [[UITextField alloc] initWithFrame:background.frame];
    self.confirmPasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.confirmPasswordField.textAlignment = UITextAlignmentLeft;
    self.confirmPasswordField.placeholder = @"Confirm password";
    self.confirmPasswordField.secureTextEntry = YES;
    self.confirmPasswordField.delegate = self;
    self.confirmPasswordField.borderStyle = UITextBorderStyleNone;
    self.confirmPasswordField.textAlignment = UITextAlignmentCenter;
    self.confirmPasswordField.returnKeyType = UIReturnKeyDone;

    self.confirmPasswordField.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
    self.confirmPasswordField.adjustsFontSizeToFitWidth = YES;
    self.confirmPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.confirmPasswordField];
    
    self.sendButton = [[QliqButton alloc] initWithFrame:CGRectMake(10.f, background.frame.origin.y + background.frame.size.height + 10.f, self.view.frame.size.width - 20.f, 40.f) style:QliqButtonStyleBlue];
    [self.sendButton addTarget:self action:@selector(onSendButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitle:@"Create password" forState:UIControlStateNormal];
    [self.view addSubview:self.sendButton];
    
//    [self.sendButton setEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark public methods
#pragma mark -

- (void)closeKeyboard {
    [self.view endEditing:YES];
}

- (void)reset {
    
    self.setPasswordField.text = @"";
    self.confirmPasswordField.text = @"";
}

- (void)focusOnPasswordField {

    [self.setPasswordField becomeFirstResponder];
}

#pragma mark -
#pragma mark IBAction methods
#pragma mark -

- (void)onSendButton:(id)notused {
    [self tryCreatePassword];
}

- (BOOL)verifyPasswordStrength {
    
    if ([self.setPasswordField.text length] == 0)
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Set Password"
                                                                      message:@"You must set the password first."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            [self reset];
            [self focusOnPasswordField];
        }];
        return FALSE;
    } else if ([self.setPasswordField.text length] < 6)
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Weak Password"
                                                                  message:@"Password should be at least six characters long."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            [self reset];
            [self focusOnPasswordField];
        }];
        return FALSE;
    } else {
        UserSession *currentSession = [UserSessionService currentUserSession];
        NSString *password = currentSession.sipAccountSettings.password;
        NSString * encodedPassword = [[KeychainService sharedService] stringToBase64:self.setPasswordField.text];
        
        if (password && [password isEqualToString:encodedPassword]) {
            
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"New Password cannot be temporary Password"
                                                                          message:@"For security reasons please choose another password"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Ok"
                                                                otherButtonTitles:nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                [self reset];
                [self focusOnPasswordField];
            }];
            
            return FALSE;
        }

    }
    return TRUE;
}


- (void)tryCreatePassword
{
    if (self.setPasswordField.text.length && self.confirmPasswordField.text.length && [self.setPasswordField.text isEqualToString:self.confirmPasswordField.text]) {
        
        
        [self closeKeyboard];
        
        [SVProgressHUD showWithStatus:@"Updating Password" maskType:SVProgressHUDMaskTypeBlack];
        
        UpdatePasswordService *service = [UpdatePasswordService sharedService];
        [service setNewPassword:self.setPasswordField.text withCompletion:^(NSError *error) {
            
            [SVProgressHUD dismiss];
            
            if (error) {
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Password update failed."
                                                                              message:@"Please re-type and try again"
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"Ok"
                                                                    otherButtonTitles:nil];
                [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                    
                    [self reset];
                    [self focusOnPasswordField];
                }];
                
                return;
            }
            
            UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Password update succeeded."
                                                                          message:@"Now you need to relogin with new credentials"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Relogin"
                                                                otherButtonTitles:nil];
            [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                
                [SVProgressHUD showWithStatus:@"Logging out…" maskType:SVProgressHUDMaskTypeBlack];
                [self.sessionService logoutWithCompletition:^{
                    
                    [self.delegate passwordChangeControllerNeedsRelogin];
                    [SVProgressHUD dismiss];
                }];
            }];
            
        }];
    } else {
        
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"New and confirmed passwords do not match"
                                                                      message:@"Please re-type"
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            [self reset];
            [self focusOnPasswordField];
        }];
        
        return;
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate methods
#pragma mark -

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    if(textField == self.confirmPasswordField)
    {
        [self verifyPasswordStrength];
    }
    return TRUE;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.setPasswordField) {
        [self verifyPasswordStrength];
    }
    else if(textField == self.confirmPasswordField)
    {
        [self tryCreatePassword];
    }
    return TRUE;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
//    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
//
//    NSString *text1 = nil;
//    NSString *text2 = nil;
//    if (textField == self.setPasswordField) {
//        
//        text1 = text;
//        text2 = self.confirmPasswordField.text;
//    } else {
//        
//        text1 = self.setPasswordField.text;
//        text2 = text;
//    }
    
//    [self.sendButton setEnabled:(text1.length || text2.length) && [text1 isEqualToString:text2]];
    
    return YES;
}

@end

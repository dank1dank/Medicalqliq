//
//  SetNewPassContainerView.m
//  qliq
//
//  Created by Valerii Lider on 7/23/14.
//
//

#import "SetNewPassContainerView.h"

@interface SetNewPassContainerView ()

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation SetNewPassContainerView

- (void)dealloc
{
    self.emailTextField = nil;
    self.passTextField = nil;
    self.createAccountButton = nil;
    self.forgotPasswordButton = nil;
    self.signInButton = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
    }
    return self;
}

- (void)configureDefaultText {
  
    [self.backButton setTitle:QliqLocalizedString(@"64-ButtonBactToSignIn") forState:UIControlStateNormal];
    
    self.emailTextField.placeholder = QliqLocalizedString(@"2304-TitleEmailPlaceholder");
    
    self.passTextField.placeholder = QliqLocalizedString(@"2305-TitlePasswordPlaceholder");
    
    [self.signInButton setTitle:QliqLocalizedString(@"57-ButtonSignIn") forState:UIControlStateNormal];
    
    [self.createAccountButton setTitle:QliqLocalizedString(@"62-ButtonCreateAccout") forState:UIControlStateNormal];
    
    [self.forgotPasswordButton setTitle:QliqLocalizedString(@"63-ButtonForgotPassword") forState:UIControlStateNormal];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    [self.emailTextField setTintColor:[UIColor whiteColor]];
    [self.passTextField setTintColor:[UIColor whiteColor]];
    
    [self configureSignUpButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureSignUpButton)
                                                 name:@"ConfigureSignUpButton" object:nil];
}

- (void)configureSignUpButton {
    BOOL hide = ![[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyShowSignUpButton];
    self.createAccountButton.hidden = hide;
} 

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onInfo:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

@end

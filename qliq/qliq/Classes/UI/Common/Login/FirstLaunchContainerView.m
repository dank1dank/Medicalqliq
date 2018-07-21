//
//  FirstLaunchContainerView.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "FirstLaunchContainerView.h"

@implementation FirstLaunchContainerView

- (void)dealloc {
    self.signInButton = nil;
    self.registerButton = nil;
}

- (void)configureDefaultText {
    
    [self.signInButton setTitle:QliqLocalizedString(@"57-ButtonSignIn") forState:UIControlStateNormal];
    [self.registerButton setTitle:QliqLocalizedString(@"58-ButtonSignUp") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    //Configure SignUpButton
    self.registerButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.registerButton.layer.borderWidth = 1.f;


    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSignUpButton)
                                                 name:@"ConfigureSignUpButton" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    dispatch_async_main(^{
        [self showSignUpButton];
    });
}

#pragma mark - Private

- (void)showSignUpButton {
    BOOL hide = ![[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyShowSignUpButton];
    self.registerButton.hidden = hide;
}

@end


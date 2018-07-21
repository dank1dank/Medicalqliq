//
//  LoginWithPasswordViewController.m
//  qliq
//
//  Created by Paul Bar on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginWithPasswordViewController.h"
#import "RetrievePasswordViewController.h"

@implementation LoginWithPasswordViewController
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    DDLogSupport(@"LoginWithPasswordViewController: viewDidLoad");
    loginView = [[UsernamePasswordView alloc] initWithFrame:self.view.bounds];
    loginView.up_delegate = self;
    loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:loginView];
    [loginView release];
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

AUTOROTATE_METHOD

- (void) closeKeyboard{
    [loginView closeKeyboard];
}


-(void) focusUsername
{
    [loginView focusUsername];
}

-(void) focusPassword
{
    [loginView focusPassword];
}

-(void) clearPassword
{
    [loginView clearPassword];
}

-(void) prefillUsername:(NSString*)username
{
    [loginView prefillUsername:username];
}

-(void) prefillPassword:(NSString*)password
{
    [loginView prefillPassword:password];
}

-(void) unmaskPassword
{
    [loginView unmaskPassword];
}

-(void) maskPassword
{
    [loginView maskPassword];
}

#pragma mark -
#pragma mark LoginViewDelegate

-(void) loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
    DDLogSupport(@"LoginWithPasswordViewController: loginWithUsername");
    [self.delegate loginWithUsername:username andPassword:password];
}

-(void) forgotPasswordButtonPressed
{
    [self.delegate retrievePassword];
}
@end

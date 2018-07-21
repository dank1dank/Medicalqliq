//
//  PinEnteringViewController.m
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinEnteringViewController.h"
#import "KeychainService.h"

#define HEADER_HEIGHT 55.0

@interface PinEnteringViewController()
@property (nonatomic,retain) NSString *enteredPin;
@end

@implementation PinEnteringViewController

@synthesize delegate;
@synthesize setupNewPin;
@synthesize enteredPin;
@synthesize setupPinFromSettings;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.setupNewPin = NO;
    }
    return self;
}

-(void) dealloc
{
    [enteredPin release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
//- (void)loadView
//{
////    pinEnteringView = [[PinEnteringView alloc] init];
////    pinEnteringView.delegate = self;
////    self.view = pinEnteringView;
////    [pinEnteringView release];
//}

- (void)viewDidLoad
{
    pinEnteringView = [[PinEnteringView alloc] initWithFrame:self.view.bounds];
    pinEnteringView.pinEnteringDelegate = self;
    pinEnteringView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:pinEnteringView];
    [pinEnteringView release];
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [pinEnteringView setHiddenForPasswordButton:self.setupNewPin];
    pinEnteringView.enterPinLabel.text = @"Enter 4 digit PIN";
    [self reset:YES];
}
/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


AUTOROTATE_METHOD

- (void) closeKeyboard{
    [pinEnteringView hideKeyboard];
}

-(void) reset:(BOOL)newPin
{
    self.enteredPin = nil;
    [pinEnteringView reset];
    
    NSString *title = nil;
    
    self.setupNewPin = newPin;
    
    if(self.setupNewPin)
    {
        title = @"Setup PIN";
    }
    else
    {
        title = @"Enter PIN";
    }
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:title buttonImage:nil buttonAction:nil];
}

#pragma mark -
#pragma mark PinEnteringViewDelegate

-(void) didEnterPin:(NSString *)pin
{
    if(self.setupNewPin)
    {
        if(self.enteredPin == nil)
        {
            if ([[KeychainService sharedService] pinAlreadyUsed: pin] == YES)
            {
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"PIN has been used previously"
                                                                              message:@"Choose a different PIN"
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles: nil];
                [[alert autorelease] showWithDissmissBlock:^(NSInteger buttonIndex) {
                    DDLogSupport(@"PIN retry");
                    [pinEnteringView reset];
                    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Setup PIN" buttonImage:nil buttonAction:nil];
                    pinEnteringView.enterPinLabel.text = @"Enter 4 digit PIN";
                }];
            } else {
                self.enteredPin = pin;
                [pinEnteringView reset];
                [self.delegate willConfirmPin];
                self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Confirm PIN" buttonImage:nil buttonAction:nil];
                pinEnteringView.enterPinLabel.text = @"Confirm your PIN";
            }
        }
        else
        {
            if([pin isEqualToString:self.enteredPin])
            {
                [pinEnteringView hideKeyboard];
				if(self.setupPinFromSettings)
				{
					DDLogSupport(@"PIN set up complete, going back to settings");
					[[KeychainService sharedService] savePin: pin];
					[self.navigationController popViewControllerAnimated:YES];
				}else{
					DDLogSupport(@"PIN set up complete, going to landing page");
					[self.delegate didSetUpNewPin:enteredPin];
				}
            }
            else
            {
                //retry
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:@"PIN confirmation failed"
                                                                message:@"Please try again" 
                                                               delegate:nil 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles: nil];
                [[alert autorelease] showWithDissmissBlock:^(NSInteger buttonIndex) {
                    DDLogSupport(@"PIN retry");
                    [pinEnteringView reset];
                    [self.delegate didFailedToConfirmPin];
                    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Setup PIN" buttonImage:nil buttonAction:nil];
                    pinEnteringView.enterPinLabel.text = @"Enter 4 digit PIN";
                }];
            }  
            self.enteredPin = nil;
        }
    }
    
    else
    {
        DDLogInfo(@"Entered pin: %@",pin);
        [pinEnteringView hideKeyboard];
        [self.delegate pinEnteringViewController:self didEnterPin:pin];
    }
}

-(void) didCanelEnteringPin
{
    NSLog(@"Canceled entering pin");
}

-(void) switchToPasswordButtonPressed
{
    [self.delegate switchToPasswordLogin];
}
@end

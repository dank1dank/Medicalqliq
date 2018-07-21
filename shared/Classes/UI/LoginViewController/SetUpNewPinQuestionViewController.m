//
//  SetUpNewPinQuestionViewController.m
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SetUpNewPinQuestionViewController.h"

@implementation SetUpNewPinQuestionViewController
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


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    newPinView = [[SetUpNewPinQuestionView alloc] init];
    self.view = newPinView;
    newPinView.delegate = self;
    [newPinView release];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [SVProgressHUD dismiss];
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

AUTOROTATE_METHOD

- (void) updateChatBadge
{
    
}

#pragma mark -
#pragma mark ViewDelegate

-(void) setUpPin
{
    [self.delegate setUpNewPin];
}

- (BOOL) shouldEnforcePin{
    return [self.delegate shouldEnforcePin];
}

-(void) skipPinSetUp
{
    [self.delegate skipPinSetUp];
}

@end

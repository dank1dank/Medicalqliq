//
//  FacilityViewController.m
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilityViewController.h"
#import "Facility.h"

@interface FacilityViewController()
@property (nonatomic, readonly) Facility* facility;
@end

@implementation FacilityViewController

@synthesize facility;

-(id) initWithFacility:(Facility *)_facility
{
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        facility = [_facility retain];
    }
    return self;
}
-(void) dealloc
{
    [facility release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
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
    FacilityView *facilityView = [[FacilityView alloc] init];
    self.view = facilityView;
    [facilityView release];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

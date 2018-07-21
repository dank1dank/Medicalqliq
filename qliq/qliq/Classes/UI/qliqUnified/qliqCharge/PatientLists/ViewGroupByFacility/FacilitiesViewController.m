//
//  FacilitiesViewController.m
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilitiesViewController.h"
#import "FacilitiesView.h"
#import "FacilityService.h"
#import "Facility.h"
#import "GroupService.h"
#import "Group.h"
#import "GroupCensusesFactory.h"
#import "EncountersForDateViewController.h"
#import "TableSectionHeaderWithLabel.h"
#import "Floor.h"
#import "FloorCensusesFactory.h"
#import "FacilityCensusesFactory.h"
#import "RightNavigationViewWithSlider.h"
#import "LabelSliderViewItem.h"
#import "FacilityViewController.h"

#define FACILITY_KEY @"facility"
#define GROUPS_KEY @"groups"
#define FLOORS_KEY @"floors"

@interface FacilitiesViewController()

@property(nonatomic, retain) NSArray *facilitiesArray;
@property(nonatomic, retain) FacilityService *facilityService;

-(void) refresh;

@end

@implementation FacilitiesViewController
@synthesize facilitiesArray;
@synthesize facilityService;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.facilityService = [[FacilityService alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) dealloc
{
    [self.facilityService release];
    [facilitiesView release];
    [super dealloc];
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    facilitiesView = [[FacilitiesView alloc] init];
    facilitiesView.tableView.delegate = self;
    facilitiesView.tableView.dataSource = self;
    facilitiesView.tableView.separatorColor = [UIColor blackColor];
    facilitiesView.tableView.backgroundColor = [UIColor blackColor];
    facilitiesView.tableView.showsVerticalScrollIndicator = NO;
    self.view = facilitiesView;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/
-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RightNavigationViewWithSlider *rightNavView = [[RightNavigationViewWithSlider alloc] init];
    LabelSliderViewItem *labelSliderItem1 = [[LabelSliderViewItem alloc] init];
    labelSliderItem1.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem1.label.text = @"Hospital";
    labelSliderItem1.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem1.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    
    LabelSliderViewItem *labelSliderItem2 = [[LabelSliderViewItem alloc] init];
    labelSliderItem2.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem2.label.text = @"Nursing";
    labelSliderItem2.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem2.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    NSArray *sliderItems = [NSArray arrayWithObjects:labelSliderItem1,labelSliderItem2, nil];
    [rightNavView.sliderView setItems:sliderItems];
    
    rightNavView.sliderView.delegate = self;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightNavView];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    rightNavView.frame = CGRectMake(rightNavView.frame.origin.x,
                                    rightNavView.frame.origin.y,
                                    [[UIScreen mainScreen] bounds].size.width / 2.0,
                                    self.navigationController.navigationBar.frame.size.height);
    [rightNavView release];
    [barButtonItem release];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh];
}

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

#pragma mark -
#pragma mark UITableView delegate/data source

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [facilitiesArray count];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.0;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.facilitiesArray count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"FacilityCellReuseId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header-Sub-Row.png"]] autorelease];
        cell.accessoryView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 7.0, 12.0)]autorelease];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor whiteColor];
    }
    
    Facility *facility = [self.facilitiesArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [facility name];
    
    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*NSDictionary *dict = [self.facilitiesArray objectAtIndex:indexPath.section];
    NSArray *groups = [dict objectForKey:GROUPS_KEY];
    NSArray *floors = [dict objectForKey:FLOORS_KEY];
    int numOfFloors = [floors count];
    id<CensusFactoryProtocol> factory;
    NSString *filterDescription;
    
    if(indexPath.row < numOfFloors)
    {
        Floor *floor = [floors objectAtIndex:indexPath.row];
        FloorCensusesFactory *floorCensusesFactory = [[FloorCensusesFactory alloc] init];
        floorCensusesFactory.floor = floor;
        filterDescription = [NSString stringWithString:floor.name];
        factory = floorCensusesFactory;
    }
    else
    {
        Group *group = [groups objectAtIndex:indexPath.row - numOfFloors];
        GroupCensusesFactory *groupCensusesFactory = [[GroupCensusesFactory alloc] init];
        groupCensusesFactory.group = group;
        filterDescription = [NSString stringWithFormat: @"%@ · All Patients", group.name];
        factory = groupCensusesFactory;
    }
    
    EncountersForDateViewController *encounterViewController = [[EncountersForDateViewController alloc] init];
    encounterViewController.censusesFactory = factory;
    encounterViewController.previousControllerTitle = @"Facilities";
    encounterViewController.tabView = self.tabView;
    encounterViewController.filterDescription =filterDescription;
    
    [self.navigationController pushViewController:encounterViewController animated:YES];
    [encounterViewController release];
    [factory release];*/
    
    FacilityViewController *facilityViewController = [[FacilityViewController alloc] initWithFacility:[self.facilitiesArray objectAtIndex:indexPath.row]];
    facilityViewController.previousControllerTitle = @"Facilities";
    [self.navigationController pushViewController:facilityViewController animated:YES];
    [facilityViewController release];
}

#pragma mark -
#pragma mark SliderViewDelegate

-(void) sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    
}

#pragma mark -
#pragma mark Private

-(void) refresh
{
    self.facilitiesArray = [[self.facilityService getFacilities] retain];
    [facilitiesView.tableView reloadData];
}

@end

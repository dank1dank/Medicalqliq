//
//  FloorListViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorListViewController.h"
#import "Facility_old.h"

@interface FloorListViewController()
-(void) logOutButtonPressed;
-(void) refreshData;
@end

@implementation FloorListViewController
@synthesize userObj=_userObj;

-(id) init
{
    self = [super init];
    if(self)
    {
        floorArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [floorArray release];
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
    floorListView = [[FloorListView alloc] init];
    floorListView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    floorListView.autoresizesSubviews = YES;
    floorListView.tabView.delegate = self;
    floorListView.floorTable.delegate = self;
    floorListView.floorTable.dataSource = self;
    self.view = floorListView;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self refreshData];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onFacilityInfoReceived:)
												 name:FacilityInfoNotification
											   object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(removeNotificationObserver) 
                                                 name:@"RemoveNotifications" object:nil];
}
 - (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];

}
-(void) onFacilityInfoReceived:(NSNotification *)notification
{
    [self refreshData];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:FacilityInfoNotification
												  object:nil];    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) refreshData
{
    //TIP: select floors from db
    [floorArray removeAllObjects];
    [floorArray addObjectsFromArray:[Floor_old getFloors:self.userObj.facilityNpi]];
    [floorListView.floorTable reloadData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:nil buttonImage:[UIImage imageNamed:@"logout.png"] buttonAction:@selector(logOutButtonPressed)];
    //self.navigationItem.leftBarButtonItem = [self leftLogoItem];
    //[self setLeftLogoItem];
    floorListView.hospitalName = self.userObj.facilityName;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //TIP:
    return [floorArray count];
    //return 10;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"FloorTableViewCell";
    FloorListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[FloorListTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
    }
    
     //TIP:
     Floor_old *floorObj = [floorArray objectAtIndex: indexPath.row];
     cell.textLabel.text = floorObj.name;
     
    //cell.textLabel.text = [NSString stringWithFormat:@"Floor %d", indexPath.row];
    cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"white-chevron"]] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FloorViewController *ctrl = [[FloorViewController alloc] init];
    ctrl.previousControllerTitle = @"Floors";
    //TIP:
    ctrl.floor = [floorArray objectAtIndex: indexPath.row];
    [self.navigationController pushViewController:ctrl animated:YES];
    [ctrl release];
}

#pragma mark -
#pragma mark NurseTabViewDelegate

-(void) alertButtonPressed
{
    AlertsViewController *ctrl = [[[AlertsViewController alloc] init] autorelease];
    ctrl.previousControllerTitle = @"Back";
    [self.navigationController pushViewController:ctrl animated:YES];
}

-(void) chatButtonPressed
{
    [self showChat];
}

#pragma mark -
#pragma mark Private

-(void) logOutButtonPressed
{
    DDLogInfo(@"TODO: handle log out");
    [[self navigationController] popViewControllerAnimated:YES];
}

@end

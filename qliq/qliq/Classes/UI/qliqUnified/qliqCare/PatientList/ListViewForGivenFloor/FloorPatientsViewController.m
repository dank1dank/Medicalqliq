//
//  FloorPatientsViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorPatientsViewController.h"
#import "Census_old.h"

@interface FloorPatientsViewController()

-(void) addPatientButtonPressed;
-(void) refreshData;

@end

@implementation FloorPatientsViewController
@synthesize floor=floor_;

-(id) init
{
    self = [super init];
    if(self)
    {
        patientsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    //TIP:
    [floor_ release];
    [patientsArray release];
    [super dealloc];
}

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
    floorPatientsView = [[FloorPatientsView alloc] init];
    floorPatientsView.patientsTable.delegate = self;
    floorPatientsView.patientsTable.dataSource = self;
    floorPatientsView.tabView.delegate = self;
    floorPatientsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    floorPatientsView.autoresizesSubviews = YES;
    self.view = floorPatientsView;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/
-(void) refreshData
{
    //TIP:
    [patientsArray removeAllObjects];
    [patientsArray addObjectsFromArray:[Floor_old getPatientsOnFloor:self.floor.floorId]];
    [floorPatientsView.patientsTable reloadData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Patient List", @"Patient List") 
                                                          buttonImage:[UIImage imageNamed:@"btn-add"] 
                                                         buttonAction:@selector(addPatientButtonPressed)];
    if(self.previousControllerTitle == nil || [self.previousControllerTitle length] == 0)
    {
      //  self.navigationItem.leftBarButtonItem = [self leftLogoItem];
        //[self setLeftLogoItem];
    }
    
    //TIP:
	Facility_old *facilityObj = [Facility_old getFacility:[self.floor.facilityNpi doubleValue]];
    floorPatientsView.hospitalName = facilityObj.name;
    
    [self refreshData];
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
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //TIP:
    return [patientsArray count];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"FloorTableViewCell";
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[PatientTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
    }
    
    // TIP:
	Patient_old *patientObj = [patientsArray objectAtIndex:indexPath.row];
	Census_old *censusObj = [Census_old getCensusObject:patientObj.censusId];
	
    cell.lblPatientName.text = patientObj.fullName;
	cell.lblPatientAgeGenderRace.text = [Helper getRaceGenderAgeStringForCensus:censusObj];
    cell.lblPhysicianName.text=censusObj.physicianInitials;
	cell.lblFacilityAbbreviation.text = censusObj.room==nil ? @"":censusObj.room;
		
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    FloorPatientsTableSectionHeader *header = [[FloorPatientsTableSectionHeader alloc] init];
    //TIP:
    header.titleLabel.text = self.floor.name;
    return [header autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	CareTeamViewController *ctrl = [[[CareTeamViewController alloc] init] autorelease];
    ctrl.previousControllerTitle = @"Rooms";
	Patient_old *patientObj = [patientsArray objectAtIndex:indexPath.row];
	ctrl.patient = patientObj;
    [self.navigationController pushViewController:ctrl animated:YES];

}

#pragma mark -
#pragma mark NurseTabViewDelegate

-(void) roomsButtonPressed
{
    FloorViewController *ctrl = [[FloorViewController alloc] init];
    ctrl.previousControllerTitle = self.previousControllerTitle;
    //TIP:
    ctrl.floor = self.floor;
    NSArray *controllers = [self.navigationController viewControllers];
    [self.navigationController popViewControllerAnimated:NO];
    if([controllers count] >= 1)
    {
        UIViewController *prevCtrl = [controllers objectAtIndex:[controllers count] - 2];
        [prevCtrl.navigationController pushViewController:ctrl animated:NO];
    }
    [ctrl release];
}

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

-(void) addPatientButtonPressed
{
    DDLogInfo(@"TODO: handle add patient");
    //[[self navigationController] popViewControllerAnimated:YES];
}


@end

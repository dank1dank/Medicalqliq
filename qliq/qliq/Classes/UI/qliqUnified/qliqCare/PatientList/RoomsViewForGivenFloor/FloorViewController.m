//
//  FloorViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorViewController.h"

@interface FloorViewController()
-(void) addPatientButtonPressed;
-(void) refreshData;
@end

@implementation FloorViewController
@synthesize floor=floor_;

-(id) init
{
    self = [super init];
    if(self)
    {
        roomsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    //TIP:
    //[floor_ release];
    [roomsArray release];
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
    floorView = [[FloorView alloc] init];
    floorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    floorView.autoresizesSubviews = YES;
    floorView.floorTable.delegate = self;
    floorView.floorTable.dataSource = self;
    floorView.tabView.delegate = self;
    self.view = floorView;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self refreshData];
}  
  
-(void) refreshData
{
    [roomsArray removeAllObjects];
    //TIP:
    [roomsArray addObjectsFromArray:[Floor_old getRooms:self.floor.floorId]];
    [floorView.floorTable reloadData];
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
    floorView.floorName = self.floor.name;
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
#pragma mark Private

-(void) addPatientButtonPressed
{
    DDLogInfo(@"TODO: handle add patient");
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    //TIP:
    return [roomsArray count];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //TIP:
    Room *roomObj = [roomsArray objectAtIndex:section];
    //NSInteger patients = [[Room getPatients:roomObj.room] count];
    NSInteger rez = roomObj.numberOfBeds / 3.0;
    if(roomObj.numberOfBeds % 3 != 0.0)
    {
        rez ++;
    }
    
    return rez;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"FloorTableViewCell";
    FloorRoomsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[FloorRoomsTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
        cell.delegate = self;
    }
    
    //TIP:
    //here we need to get patients for room ([roomsArray objectAtIndex:indexPath.section])
    //and then fill the cell with patients data (3 patients per cell)
    //don't forget to set roomPlace.empty to NO
    Room *roomObj = [roomsArray objectAtIndex:indexPath.section];
	NSMutableArray *patients = [Room getPatientsInRoom:roomObj.room];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    int numberOfSections = roomObj.numberOfBeds - (indexPath.row * 3);
    cell.numOfSections = numberOfSections;
    
	for(int i=0; i<3; i++)
    {
        RoomPlaceView *roomPlace = [cell roomPlaceViewWithIndex:i];

		if([patients count]>0 && i<[patients count])
        {
			Patient_old *patient = [patients objectAtIndex:i];
			roomPlace.patient = patient;
			roomPlace.patientName = patient.lastName;
			roomPlace.nurseName = patient.middleName;
			roomPlace.empty = NO;
		}
        else
        {
			roomPlace.empty=YES;
		}
	}
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
    FloorTableSectionHeader *header = [[FloorTableSectionHeader alloc] init];
    //TIP:
    Room *roomObj = [roomsArray objectAtIndex: section];
    header.titleLabel.text = [NSString stringWithFormat:@"Room %@",roomObj.room];
    header.sectionIndex = section;
    return [header autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark NurseTabViewDelegate

-(void) patientsButtonPressed
{
    FloorPatientsViewController *ctrl = [[FloorPatientsViewController alloc] init];
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
    ctrl.previousControllerTitle = @"Rooms";
    [self.navigationController pushViewController:ctrl animated:YES];
}

-(void) chatButtonPressed
{
    [self showChat];
}

#pragma mark - 
#pragma mark FloorRoomsTableViewCellDelegate

-(void) floorRoomsTableViewCell:(FloorRoomsTableViewCell *)cell didSelectRoomPlaceAtIndex:(NSInteger)index
{
    CareTeamViewController *ctrl = [[[CareTeamViewController alloc] init] autorelease];
    ctrl.previousControllerTitle = @"Rooms";
	RoomPlaceView *roomPlace = [cell roomPlaceViewWithIndex:index];
	ctrl.patient = roomPlace.patient;
    [self.navigationController pushViewController:ctrl animated:YES];
}

@end

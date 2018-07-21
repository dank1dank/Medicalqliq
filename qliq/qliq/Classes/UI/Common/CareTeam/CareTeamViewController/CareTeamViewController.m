//
//  CareTeamViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamViewController.h"
#import "CareTeamMember_old.h"
#import "Helper.h"

@implementation CareTeamViewController
@synthesize patient = patient_;

-(id) init
{
    self = [super init];
    if(self)
    {
		careTeamTypesArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    //TIP:
    [patient_ release];
	[careTeamTypesArray release];
	[careTeamDict release];
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
    careTeamView = [[CareTeamView alloc] init];
    careTeamView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    careTeamView.autoresizesSubviews = YES;
    careTeamView.infoTable.delegate = self;
    careTeamView.infoTable.dataSource = self;
    careTeamView.tabView.delegate = self;
    careTeamView.delegate = self;
    self.view = careTeamView;
}


-(void) refreshData
{
    //TIP:
	careTeamDict = [[Patient_old getCareTeamForCensus:self.patient.censusId] retain];
	[careTeamTypesArray removeAllObjects];
	[careTeamTypesArray addObjectsFromArray:[careTeamDict allKeys]];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self refreshData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Care Team" buttonImage:nil buttonAction:nil];
    
    careTeamView.patientName = self.patient.fullName;
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
    return [careTeamTypesArray count];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger rowCount = 0;
    //TIP:
	NSString *careTeamType = [careTeamTypesArray objectAtIndex:section];
	NSMutableArray *memberArray = [careTeamDict objectForKey:careTeamType];
	if (memberArray!=nil) {
		rowCount = [memberArray count];
	}
	return rowCount;
	/*
    switch (section)
    {
        case 0: return [[careTeamDict objectForKey:@"Nurse"] count]; break;
        case 1: return [[careTeamDict objectForKey:@"Admitting Physician"] count]; break;
        case 2: return [[careTeamDict objectForKey:@"Attending Physician"] count]; break;
        case 3: return [[careTeamDict objectForKey:@"Consulting Physician"] count]; break;
        default: return 0;
    }*/
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"infoTableViewCell";
    CareTeamInfoTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[CareTeamInfoTableCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
        cell.delegate = self;
    }
	NSString *careTeamType = [careTeamTypesArray objectAtIndex:indexPath.section];
	NSMutableArray *teamMemberArray = [careTeamDict objectForKey:careTeamType];
	CareTeamMember_old *careTeamMember = [teamMemberArray objectAtIndex:indexPath.row];
	
    cell.textLabel.text = careTeamMember.name;
    cell.detailTextLabel.text = careTeamMember.specialty;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableSectionHeaderWithLabel *header = [[TableSectionHeaderWithLabel alloc] init];
    header.sectionIndex = section;
    header.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    header.textLabel.backgroundColor = [UIColor clearColor];
    header.textLabel.textColor = [UIColor whiteColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:10.0];

	header.textLabel.text = [careTeamTypesArray objectAtIndex:section];
	/*
    switch (section) 
    {
        case 0: header.textLabel.text = @"Nurse"; break;
        case 1: header.textLabel.text = @"Attending Physician"; break;
        case 2: header.textLabel.text = @"Consulting Physicians"; break;
        case 3: header.textLabel.text = @"Care Team History";break;
        default:
            break;
    }*/
    return [header autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
#pragma mark CareTeamViewDelegate

-(void) headerSelected
{
    PatientDemographicsViewController *ctrl = [[[PatientDemographicsViewController alloc] init] autorelease];
	ctrl.patient = self.patient;
    ctrl.previousControllerTitle = @"Care Team";
    [self.navigationController pushViewController:ctrl animated:YES];
}


#pragma mark -
#pragma mark CareTeamTableViewCellDelegate

-(void) selectedCell:(CareTeamInfoTableCell *)cell
{
    CareTeamMemberDetailsViewController *ctrl = [[CareTeamMemberDetailsViewController alloc] init];
	NSIndexPath *indexPath = [(UITableView *)cell.superview indexPathForCell: cell];
	NSString *careTeamType = [careTeamTypesArray objectAtIndex:indexPath.section];
	NSMutableArray *teamMemberArray = [careTeamDict objectForKey:careTeamType];
	CareTeamMember_old *careTeamMember = [teamMemberArray objectAtIndex:indexPath.row];
	ctrl.careTeamMember = careTeamMember;
    ctrl.previousControllerTitle = @"Care Team";
    [self.navigationController pushViewController:ctrl animated:YES];
    [ctrl release];
}


@end

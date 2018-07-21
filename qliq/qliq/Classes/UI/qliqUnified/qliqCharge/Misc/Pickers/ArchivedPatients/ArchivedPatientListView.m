// Created by Developer Toy
//ArchivedPatientListView.m
#import "ArchivedPatientListView.h"
#import "AVFoundation/AVFoundation.h"
#import "RoundViewController.h"
#import "Patient_old.h"
#import "AppointmentViewController.h"
#import "Appointment.h"
#import "PatientTableViewCell.h"
#import "AddTableViewCell.h"
#import "Facility_old.h"
//#import "PatientViewController.h"

@implementation ArchivedPatientListView
@synthesize physicianNpi,admitDate,adding;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	
	//Get the data from the database
	patientPickerList = [[Patient_old getAllPatientsToDisplay] retain];
    searchPickerList = [[NSMutableArray alloc] initWithArray:patientPickerList];
	
	self.view.backgroundColor=[UIColor whiteColor];
	
	
	tblPatientList=[[UITableView alloc] initWithFrame:CGRectMake(0,44,320,372) style:0];
	tblPatientList.editing=NO;
	tblPatientList.delegate=self;
	tblPatientList.dataSource=self;
	tblPatientList.separatorColor=[UIColor lightGrayColor];
	tblPatientList.separatorStyle=1;
	tblPatientList.rowHeight=40;
	tblPatientList.tag=0;
	tblPatientList.backgroundColor=[UIColor whiteColor];
	tblPatientList.clipsToBounds=YES;
	[self.view addSubview:tblPatientList];
	
	
	searchbarPatients=[[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,44)];
	searchbarPatients.placeholder = @"Lastname Firstname";
	searchbarPatients.barStyle=0;
	searchbarPatients.translucent=NO;
	searchbarPatients.autocapitalizationType=0;
	searchbarPatients.showsScopeBar=NO;
	searchbarPatients.tag=2;
	searchbarPatients.backgroundColor=[UIColor whiteColor];
    searchbarPatients.delegate = self;
	[self.view addSubview:searchbarPatients];
	
	/*
	 self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Patients", @"Patients") 
	 buttonImage:[UIImage imageNamed:@"btn-add"] 
	 buttonAction:@selector(clickAddPatient:)];
	 */
	self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Patients",@"Patients") buttonImage:nil buttonAction:nil];	
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardDidShowNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardDidHideNotification
												  object:nil];
    
}

#pragma mark -
#pragma mark Actions

-(IBAction)clickAddPatient:(id)sender {
	if([adding isEqualToString:@"rounds"]){
		
		NSString *patientNameSearchString = searchbarPatients.text;
		NSArray *chunks = [patientNameSearchString componentsSeparatedByString: @" "];
		
		NSString *lastName = nil;
		NSString *firstName = nil;
		
		if(chunks != nil && [chunks count]==2){
			lastName = [chunks objectAtIndex:0];
			firstName = [chunks objectAtIndex:1];
		}else if(chunks != nil && [chunks count]==1){
			lastName = [chunks objectAtIndex:0];
		}
		
		Patient_old *patientObj = [[Patient_old alloc] initWithPrimaryKey:0];
		patientObj.firstName = firstName;
		patientObj.lastName = lastName;
		
		Census_old *censusObj = [[Census_old alloc] initWithPrimaryKey:0];
		censusObj.physicianNpi = physicianNpi;
		censusObj.activePhysicianNpi = physicianNpi;
		censusObj.admitDate = [Helper conevrtDosToTimeInterval:admitDate];
		censusObj.patientId=0;
        
		PhysicianPref *physicianPref = [PhysicianPref getPhysicianPrefs:physicianNpi];
		
		RoundViewController *tempController = [[RoundViewController alloc] init];
		tempController.previousControllerTitle = NSLocalizedString(@"Patients", @"Patients");
		tempController.census=censusObj;
		tempController.patient = patientObj;
		tempController.physicianPref = physicianPref;
		tempController.currentViewMode=QliqModelViewModeAdd;
		[censusObj release];
        [patientObj release];
		
		[self.navigationController pushViewController:tempController animated:YES];
		[tempController autorelease];
	}
    else if([adding isEqualToString:@"appts"]){
	}
}

-(IBAction)clickSelectPatientDone:(id)sender{
	NSIndexPath *indexPath = sender;
	NSArray *controllers =self.navigationController.viewControllers;
	int level = [controllers count]-2;
    NSLog(@"%@", adding);
 	if (level >= 0) {
		if([adding isEqualToString:@"appts"]) {
			UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
			//if ([last isKindOfClass:[AddApptView class]]) {
            if (_isSearching) {
                ((AppointmentViewController *)last).appointment.patientId = ((Patient_old *)[searchPickerList objectAtIndex:indexPath.row]).patientId;
                ((AppointmentViewController *)last).appointment.patientName = ((Patient_old *)[searchPickerList objectAtIndex:indexPath.row]).fullName;
            }
            else {
                ((AppointmentViewController *)last).appointment.patientId = ((Patient_old *)[patientPickerList objectAtIndex:indexPath.row]).patientId;
                ((AppointmentViewController *)last).appointment.patientName = ((Patient_old *)[patientPickerList objectAtIndex:indexPath.row]).fullName;
            }
			
			[last.navigationController popViewControllerAnimated:YES];
        }else if([adding isEqualToString:@"rounds"]){
			Census_old *censusObj = [[Census_old alloc] initWithPrimaryKey:0];
	        if (_isSearching) {
				if(indexPath.row < [searchPickerList count]){
					censusObj.patientId = ((Patient_old *)[searchPickerList objectAtIndex:indexPath.row]).patientId;
					censusObj.patientName = ((Patient_old *)[searchPickerList objectAtIndex:indexPath.row]).fullName;
				}
            }
            else {
				if(indexPath.row < [patientPickerList count]){
					censusObj.patientId  = ((Patient_old *)[patientPickerList objectAtIndex:indexPath.row]).patientId;
					censusObj.patientName = ((Patient_old *)[patientPickerList objectAtIndex:indexPath.row]).fullName;
				}
            }
			censusObj.physicianNpi = physicianNpi;
			censusObj.activePhysicianNpi = physicianNpi;
			censusObj.admitDate = [Helper conevrtDosToTimeInterval:admitDate];
			PhysicianPref *physicianPref = [PhysicianPref getPhysicianPrefs:physicianNpi];

			RoundViewController *tempController = [[RoundViewController alloc] init];
			tempController.previousControllerTitle = NSLocalizedString(@"Patients", @"Patients");
			tempController.census = censusObj;
			tempController.physicianPref = physicianPref;
			tempController.currentViewMode=QliqModelViewModeSelectedEdit;
			[censusObj release];
			[self.navigationController pushViewController:tempController animated:YES];
			[tempController autorelease];
			
		}
	}
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count;
	if (_isSearching) {
		count = [searchPickerList count];
		/*
		 // MZ: if there is no results, present "add patient" row
		 if (count == 0) count = 1;
		 return count;*/
	}else {
		count = [patientPickerList count];
	}
    return count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"PatientCell";
	PatientTableViewCell *cell = (PatientTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[PatientTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    Patient_old *patObj = nil;
	NSInteger patientCount=0;
    if (_isSearching) {
        if ([searchPickerList count] > 0) {
			patientCount=[searchPickerList count];
			if(indexPath.row < patientCount)
				patObj = [searchPickerList objectAtIndex:indexPath.row];
        }
    }
    else {
		patientCount = [patientPickerList count];
		if(indexPath.row < patientCount)
			patObj = [patientPickerList objectAtIndex:indexPath.row];
    }
	
	if (indexPath.row < patientCount) {
		if(patObj != nil)
		{
			cell.lblPatientName.text = patObj.fullName;
			NSString *datestr = [Helper convertIntervalToDateString: patObj.dateOfBirth :@"MM/dd/yyyy"];
			if(datestr==nil)
				cell.lblPatientAgeGenderRace.text = [NSString stringWithFormat:@"%@",[Helper getRaceGenderAgeStringForPatient:patObj]];
			else
				cell.lblPatientAgeGenderRace.text = [NSString stringWithFormat:@"%@ • %@",datestr,[Helper getRaceGenderAgeStringForPatient:patObj]];
		}
	}
    else {
        cell = (PatientTableViewCell*)[[[AddTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddPatientCell"] autorelease];
        cell.textLabel.text = NSLocalizedString(@"Add new patient.", @"");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger patientCount = 0;
	if (_isSearching)
		patientCount = [searchPickerList count];
	else 
		patientCount = [patientPickerList count];
	
    if (indexPath.row == patientCount) {
        [self clickAddPatient:nil];
    }
    else {
        [self clickSelectPatientDone:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return DEFAULT_ROW_HEIGHT_CENSUS;
}

- (void)viewDidUnload {
}
- (void)dealloc {
    [patientPickerList release];
	[searchPickerList release];
	[super dealloc];
}

#pragma mark -
#pragma mark UISearchBarField

- (void)doSearch:(NSString *)searchText {
    if ([searchText length] > 0) {
		NSString *patientNameSearchString = searchbarPatients.text;
		NSArray *chunks = [patientNameSearchString componentsSeparatedByString: @" "];
		
		NSString *lastName = nil;
		NSString *firstName = nil;
		
		if(chunks != nil && [chunks count]==2){
			lastName = [chunks objectAtIndex:0];
			firstName = [chunks objectAtIndex:1];
		}else if(chunks != nil && [chunks count]==1){
			lastName = [chunks objectAtIndex:0];
		}
		
        _isSearching = YES;
        [searchPickerList removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastName contains [c] %@ OR firstName contains [c] %@ OR fullName contains [c] %@ OR email contains [c] %@", 
								  lastName, firstName, searchText, searchText];
        [searchPickerList addObjectsFromArray:patientPickerList];
        [searchPickerList filterUsingPredicate:predicate];
    }
    else {
        _isSearching = NO;
    }
    [tblPatientList reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

@end

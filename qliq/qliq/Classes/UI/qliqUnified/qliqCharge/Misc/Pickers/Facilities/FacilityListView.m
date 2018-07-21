// Created by Developer Toy
//FacilityListView.m
#import "FacilityListView.h"
#import "FacilityViewController_old.h"
#import "Facility_old.h"
#import "AppointmentViewController.h"
#import "Appointment.h"
#import "GenericTableViewCell.h"
#import "AddTableViewCell.h"
#import "RoundViewController.h"
#import "Helper.h"

@implementation FacilityListView
- (void)viewDidLoad {
	[super viewDidLoad];
	//NSString *username = [Helper getUsername];
	//Physician *physicianObj = [Physician getPhysician:username];
	//Get the data to populate the tableview
	facilitiesArray = [[Facility_old getFacilitiesToDisplay:@"Me"] retain];
    searchArray = [[NSMutableArray alloc] initWithCapacity:facilitiesArray.count];

	self.view.backgroundColor=[UIColor whiteColor];
	
	_tableView=[[UITableView alloc] initWithFrame:CGRectMake(0,44,320,372) style:0];
	_tableView.editing=NO;
	_tableView.delegate=self;
	_tableView.dataSource=self;
	_tableView.separatorColor=[UIColor lightGrayColor];
	_tableView.separatorStyle=1;
	_tableView.rowHeight=40;
	_tableView.tag=1;
	_tableView.backgroundColor=[UIColor whiteColor];
	_tableView.clipsToBounds=YES;
	[self.view addSubview:_tableView];
	
	_searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,44)];
	_searchBar.barStyle=0;
	_searchBar.translucent=NO;
	_searchBar.autocapitalizationType=0;
	_searchBar.showsScopeBar=NO;
	_searchBar.tag=2;
	_searchBar.backgroundColor=[UIColor whiteColor];
    _searchBar.delegate = self;
	[self.view addSubview:_searchBar];

    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Facility List", @"Facility List") 
                                                          buttonImage:nil
                                                         buttonAction:nil];

}

-(IBAction)clickAddFacility:(id)sender{
	FacilityViewController_old *tempController=[[FacilityViewController_old alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Facility List", @"Facility List");
	Facility_old *facObj = [[Facility_old alloc] initFacilityWithPrimaryKey:0];
	tempController.facility = facObj;
	tempController.currentViewMode = QliqModelViewModeAdd;
	[facObj release];
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}

-(IBAction)clickSelectFacilityDone:(id)sender {
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	NSIndexPath *indexPath = sender;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
        if ([last isKindOfClass:[AppointmentViewController class]]) {
            if (_isSearching) {
                ((AppointmentViewController *)last).appointment.facilityNpi = ((Facility_old *)[searchArray objectAtIndex:indexPath.row]).facilityNpi;
                ((AppointmentViewController *)last).appointment.facilityName = ((Facility_old *)[searchArray objectAtIndex:indexPath.row]).name;
            }
            else {
                ((AppointmentViewController *)last).appointment.facilityNpi = ((Facility_old *)[facilitiesArray objectAtIndex:indexPath.row]).facilityNpi;
                ((AppointmentViewController *)last).appointment.facilityName = ((Facility_old *)[facilitiesArray objectAtIndex:indexPath.row]).name;
            }
			//RA: Otherwise check if it is rounds, then set the facilityNpi and name
        }else if ([last isKindOfClass:[RoundViewController class]]) {
            if (_isSearching) {
                ((RoundViewController *)last).selectedFacilityId = ((Facility_old *)[searchArray objectAtIndex:indexPath.row]).facilityNpi;
                ((RoundViewController *)last).selectedFacilityName = ((Facility_old *)[searchArray objectAtIndex:indexPath.row]).name;
            }
            else {
                ((RoundViewController *)last).selectedFacilityId = ((Facility_old *)[facilitiesArray objectAtIndex:indexPath.row]).facilityNpi;
                ((RoundViewController *)last).selectedFacilityName = ((Facility_old *)[facilitiesArray objectAtIndex:indexPath.row]).name;
            }
		}

		[last.navigationController popViewControllerAnimated:YES];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearching) {
        int count = [searchArray count];
        // MZ: if there is no results, present "add" row
        if (count == 0) count = 1;
        return count;
    }

	return [facilitiesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"FacilityCell";
	GenericTableViewCell *cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GenericTableViewCell alloc] initWithStyle:3 reuseIdentifier:CellIdentifier] autorelease];
    }
    Facility_old *facObj = nil;
    if (_isSearching) {
        if ([searchArray count] > 0) {
            facObj = [searchArray objectAtIndex:indexPath.row];
        }
    }
    else {
        facObj = [facilitiesArray objectAtIndex:indexPath.row];
    }
    
    if (facObj != nil) {
		cell.textLabel.text = facObj.name;
        cell.detailTextLabel.text=[facObj.facilityType stringByAppendingFormat:@" • %@",facObj.facilityTypeClassification];
        cell.accessoryType=0;
        cell.editingAccessoryType=0;
        cell.selectionStyle=1;
    }/*
    else {
        cell = [[[AddTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddPatientCell"] autorelease];
        cell.textLabel.text = NSLocalizedString(@"No matches. Add new facility.", @"");
    }*/


	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isSearching && [searchArray count] == 0) {
        [self clickAddFacility:nil];
    }
    else {
        [self clickSelectFacilityDone:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 50;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (void)viewDidUnload {
}
- (void)dealloc {
    [facilitiesArray release];
	[searchArray release];
	[super dealloc];
}

#pragma mark -
#pragma mark UISearchBarField

- (void)doSearch:(NSString *)searchText {
    if ([searchText length] > 0) {
        _isSearching = YES;
        [searchArray removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains [c] %@ OR address contains [c] %@ OR "
                                  " city contains [c] %@ OR state contains [c] %@ OR "
                                  " zip contains [c] %@ OR county contains [c] %@ OR facilityType contains [c] %@", 
                                  searchText, searchText, searchText, searchText, searchText, searchText, searchText];
        [searchArray addObjectsFromArray:facilitiesArray];
        [searchArray filterUsingPredicate:predicate];
    }
    else {
        _isSearching = NO;
    }
    [_tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}


@end

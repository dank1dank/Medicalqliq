// Created by Developer Toy
//ReferralListView.m
#import "ReferralListView.h"
#import "AVFoundation/AVFoundation.h"
//#import "ProviderViewController.h"
#import "Appointment.h"
#import "AppointmentViewController.h"
#import "GenericTableViewCell.h"
#import "AddTableViewCell.h"
#import "RoundViewController.h"
#import "ReferringPhysician.h"

@implementation ReferralListView

- (void)viewDidLoad {
    [super viewDidLoad];
    
	//get the data to display
	rphArray = [[ReferringPhysician getReferralPhysiciansToDisplay] retain];
    searchArray = [[NSMutableArray alloc] initWithCapacity:rphArray.count];
    
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
    
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Referral List", @"Referral List") 
                                                          buttonImage:[UIImage imageNamed:@"btn-add"]
                                                         buttonAction:@selector(clickAddReferral:)];
	
}

/*
-(IBAction)clickAddReferral:(id)sender{
	ProviderViewController *tempController=[[ProviderViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Referral List", @"Referral List");
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController autorelease];
}
*/
-(IBAction)clickSelectReferralDone:(id)sender{
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
        if ([last isKindOfClass:[AppointmentViewController class]]) {
            NSIndexPath *indexPath = sender;
            if (_isSearching) {
                ((AppointmentViewController *)last).appointment.referringPhysicianNpi = ((ReferringPhysician *)[searchArray objectAtIndex:indexPath.row]).referringPhysicianNpi;
                ((AppointmentViewController *)last).appointment.referringPhysicianName = ((ReferringPhysician *)[searchArray objectAtIndex:indexPath.row]).name;
            }
            else {
                ((AppointmentViewController *)last).appointment.referringPhysicianNpi = ((ReferringPhysician *)[rphArray objectAtIndex:indexPath.row]).referringPhysicianNpi;
                ((AppointmentViewController *)last).appointment.referringPhysicianName = ((ReferringPhysician *)[rphArray objectAtIndex:indexPath.row]).name;
            }
        }else if ([last isKindOfClass:[RoundViewController class]]) {
            NSIndexPath *indexPath = sender;
            if (_isSearching) {
                ((RoundViewController *)last).selectedReferringPhysicianId = ((ReferringPhysician *)[searchArray objectAtIndex:indexPath.row]).referringPhysicianNpi;
                ((RoundViewController *)last).selectedReferringPhysicianName = ((ReferringPhysician *)[searchArray objectAtIndex:indexPath.row]).name;
            }
            else {
                ((RoundViewController *)last).selectedReferringPhysicianId = ((ReferringPhysician *)[rphArray objectAtIndex:indexPath.row]).referringPhysicianNpi;
                ((RoundViewController *)last).selectedReferringPhysicianName = ((ReferringPhysician *)[rphArray objectAtIndex:indexPath.row]).name;
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
    
	return [rphArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"ReferalCell";
	GenericTableViewCell *cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GenericTableViewCell alloc] initWithStyle:3 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    ReferringPhysician *rphObj = nil;
    if (_isSearching) {
        if ([searchArray count] > 0) {
            rphObj = [searchArray objectAtIndex:indexPath.row];
        }
    }
    else {
        rphObj = [rphArray objectAtIndex:indexPath.row];
    }
    
    if (rphObj != nil) {
        cell.textLabel.text=rphObj.name;
        cell.detailTextLabel.text=[NSString  stringWithFormat:@"%d",rphObj.referringPhysicianNpi];
        cell.accessoryType=0;
        cell.editingAccessoryType=0;
        cell.selectionStyle=1;
    }
    else {
        cell = (GenericTableViewCell *) [[[AddTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddPatientCell"] autorelease];
        cell.textLabel.text = NSLocalizedString(@"No matches. Add new physician.", @"");
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isSearching && [searchArray count] == 0) {
        [self clickAddReferral:nil];
    }
    else {
		[self clickSelectReferralDone:indexPath];
	}
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 50;
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [rphArray release];
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
                                  " city contains [c] %@ OR state contains [c] %@ OR email contains [c] %@ OR "
                                  " zip contains [c] %@ OR npi contains [c] %@ OR specialty contains [c] %@", 
                                  searchText, searchText, searchText, searchText, searchText, searchText, searchText, searchText];
        [searchArray addObjectsFromArray:rphArray];
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

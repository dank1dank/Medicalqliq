//
//  ICDListViewController.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "ObjectListViewController.h"
#import "EncounterIcd.h"
#import "IcdDetailsView.h"
#import "ICDTableViewCell.h"
#import "Icd.h"
#import "Cpt.h"
#import "DBPersist.h"

@implementation ObjectListViewController

@synthesize searchBar, encounterCptId, physicianNpi, listOfIcdCodes, isPrimary, selectedObj,selectedObjArray;
@synthesize delegate = _delegate, showingCPTs;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    [super loadView];
	
    //---display the searchbar---
	searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,44)];
	searchBar.delegate=self;
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.showsCancelButton=YES;
    searchBar.barStyle = UIBarStyleBlackOpaque;
	[self.view addSubview:searchBar];
	
    tblIcdCodes = [[UITableView alloc] initWithFrame:CGRectMake(0,44,320,276) style:UITableViewStylePlain];
	tblIcdCodes.editing = NO;
    tblIcdCodes.showsVerticalScrollIndicator = NO;
	tblIcdCodes.delegate=self;
	tblIcdCodes.dataSource=self;
	tblIcdCodes.separatorColor=[UIColor lightGrayColor];
	tblIcdCodes.separatorStyle=1;
	tblIcdCodes.rowHeight=40;
	tblIcdCodes.tag=2;
	tblIcdCodes.backgroundColor=[UIColor whiteColor];
	tblIcdCodes.clipsToBounds=YES;
	[self.view addSubview:tblIcdCodes];
	
    searchResult = [[NSMutableArray alloc] init];
	selectedCount = 0;
	selectedObjArray = [[NSMutableArray alloc] init];
}

- (void) viewDidLoad
{
    [self searchIcdTableView];
	
}

-(void)reloadTableData {
	//if([listOfIcdCodes count] > 0){
	[searchResult removeAllObjects];
	[searchResult addObjectsFromArray:listOfIcdCodes];
	//}
	[tblIcdCodes reloadData];
	if(selectedObj != nil){
		[tblIcdCodes selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] animated:NO scrollPosition:0];
	}
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
    [searchBar resignFirstResponder];
}


//---done with the searching---
- (void) doneSearching:(id)sender {
	//---hides the keyboard---
	[searchBar resignFirstResponder];
}

//---fired when the user types something into the searchbar---
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	[self searchIcdTableView];
}

//---performs the searching using the array of codes---
- (void) loadNextResultSet
{
    if (!fmSearchResult)
        return;
    
    int i = 20;
    while (i != 0)
    {
        if ([fmSearchResult next])
        {
            if (self.isShowingCPTs) {
				
                Cpt *cptObj = [[Cpt alloc] init];
				cptObj.code = [fmSearchResult stringForColumn:@"code"];
                cptObj.shortDescription = [fmSearchResult stringForColumn:@"short_description"];
                cptObj.longDescription = [fmSearchResult stringForColumn:@"long_description"];
                cptObj.masterCptPft  = [fmSearchResult stringForColumn:@"master_pft"];
                cptObj.physicianCptPft  = [fmSearchResult stringForColumn:@"physician_pft"];
                [searchResult addObject:cptObj];
                [cptObj release];
            }
            else {
                Icd *icdObj = [[Icd alloc] init];
                icdObj.code = [fmSearchResult stringForColumn:@"code"];
                icdObj.shortDescription = [fmSearchResult stringForColumn:@"short_description"];
                icdObj.longDescription = [fmSearchResult stringForColumn:@"long_description"];
                icdObj.masterIcdPft  = [fmSearchResult stringForColumn:@"master_pft"];
                icdObj.physicianIcdPft  = [fmSearchResult stringForColumn:@"physician_pft"];
                [searchResult addObject:icdObj];
                [icdObj release];
            }
            
            i--;
        }
        else
        {
            i = 0;
            [fmSearchResult close];
            fmSearchResult = nil;
        }
    }
    [tblIcdCodes performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO];
}


- (void) searchIcdTableView {
	[searchResult removeAllObjects];
	
	if([listOfIcdCodes count]>0){
		[searchResult addObjectsFromArray:listOfIcdCodes];
	}else {
		if (fmSearchResult)
		{
			[fmSearchResult close];
			fmSearchResult = nil;
		}
		NSString* searchedText;
		if (searchBar.text == nil)
			searchedText = @"";
		else
			searchedText = searchBar.text;
		
		if (self.isShowingCPTs) {
			fmSearchResult = [[Cpt ftsWithQuery:searchedText] retain];
		}
		else {
			fmSearchResult = [[Icd ftsWithQuery:searchedText] retain];
		}
		[self loadNextResultSet];
		tblIcdCodes.contentOffset = CGPointZero;
	}
}

//---fired when the user taps the Search button on the keyboard---
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	[self searchIcdTableView];
	//---hides the keyboard---
	[searchBar resignFirstResponder];	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchResult count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[ICDTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
    
    UIButton *accessoryButton = [self icdCellChevronWithTag:indexPath.row width:32 height:39];
    [accessoryButton addTarget:self action:@selector(presentIcdDetails:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = accessoryButton;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
    id cellValue = [searchResult objectAtIndex:indexPath.row];
    
    if (indexPath.row >= [searchResult count] - 10)
    {
        [self loadNextResultSet];
    }
    
	NSString *desc = nil;
	desc = [cellValue shortDescription];
	
	
    NSString *textString = [[desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] capitalizedString];
	
	
	/*
	 if (self.isShowingCPTs && [textString length] == 0) {
	 textString = [[cellValue longDescription] capitalizedString];
	 }*/
	
    cell.textLabel.text = textString;
	if(self.isShowingCPTs)
		cell.detailTextLabel.text = ((Cpt*)cellValue).code;
	else
		cell.detailTextLabel.text = ((Icd*)cellValue).code;
	
    ((ICDTableViewCell *)cell).visibledIndicators = YES;
    ((ICDTableViewCell *)cell).favorite = [cellValue isInFavorites];
    
	// Configure the cell.
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	selectedRow = indexPath.row;
	tableSelection = indexPath;
    selectedObj = [searchResult objectAtIndex:indexPath.row];
	[selectedObj retain];
	
	tapCount++;
	
	switch (tapCount)
	{
		case 1: //single tap
			[self performSelector:@selector(singleTap) withObject: nil afterDelay: .4];
			break;
		case 2: //double tap
			//only for ICDs
			if(!self.showingCPTs){
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTap) object:nil];
				[self performSelector:@selector(doubleTap) withObject: nil];
			}
			break;
		default:
			break;
	}
	[tblIcdCodes deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Table Tap/multiTap
- (void)singleTap
{
	if(self.showingCPTs)
		[_delegate didSelectObj:nil];
	tapCount = 0;
}

- (void)doubleTap
{
	UITableViewCell *selectedCell = [tblIcdCodes cellForRowAtIndexPath:tableSelection];
	((ICDTableViewCell *)selectedCell).selected=TRUE;
	[selectedObjArray addObject:selectedObj];
	[_delegate didSelectObj:nil];
	tapCount = 0;
}

- (void)presentIcdDetails:(id)sender {
	UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)button.superview;
    NSIndexPath *indexPath = [tblIcdCodes indexPathForCell:cell];
	
	if([searchResult count]>0 && [searchResult count] >= indexPath.row){
		if (_delegate != nil) {
			id obj = nil;
			obj = [searchResult objectAtIndex:indexPath.row];
			selectedRow = indexPath.row;
			
			[_delegate shouldPresentDetails:obj];
		}
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[tblIcdCodes release];
	[toolbarIcdList release];
	[searchBar release];
	[listOfIcdCodes release];
	[searchResult release];
	[shortList release];
	[selectedObj release];
	[selectedObjArray release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

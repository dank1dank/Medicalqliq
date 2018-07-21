//
//  EncountersForDateViewController.m
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncountersForDateViewController.h"
#import "EncountersForDateView.h"
#import "Helper.h"
#import "PatientVisit.h"
#import "Patient.h"
#import "NSDate+Helper.h"
#import "PlainListCensusesFactory.h"
#import "Census.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "PatientTableViewCell.h"
#import "Facility.h"
#import "TableSectionHeaderWithLabel.h"
#import "RightNavigationViewWithSlider.h"
#import "ImageSliderItem.h"
#import "SliderView.h"
#import "LabelSliderViewItem.h"
#import "EncountersTableSearchView.h"
#import "CodesViewController.h"

#define CENSUS_TYPE_APPOINTMENT @"Appointment"
#define CENSUS_TYPE_ROUND @"Round"

@interface EncountersForDateViewController()

-(void) refresh;
-(NSArray*)filterCensusesArray:(NSArray*)array withPredicate:(NSString*)predicate;

@property (nonatomic, retain) NSDate *selectedDate;
@property (nonatomic, retain) NSArray *censusesArray;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSString *censusType;
@property (nonatomic, retain) UISearchDisplayController *searchDisplay;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSArray *filtredCensusesArray;

@end

@implementation EncountersForDateViewController

@synthesize filterDescription;
@synthesize futureDaysToShow;
@synthesize pastDaysToShow;
@synthesize selectedDate;
@synthesize censusesArray;
@synthesize dateFormatter;
@synthesize censusesFactory;
@synthesize censusType;
@synthesize searchDisplay;
@synthesize searchBar;
@synthesize filtredCensusesArray;

-(id) init
{
    self = [super init];
    if(self)
    {
        self.futureDaysToShow = 7;
        self.pastDaysToShow = 30;
        
        pickerViewArray = [[NSMutableArray alloc] init];
        [pickerViewArray addObjectsFromArray:[Helper getFutureDates:self.futureDaysToShow]];
        NSDate *today = [NSDate dateWithoutTime];
        [pickerViewArray addObject:today];
        self.selectedDate = today;
        [pickerViewArray addObjectsFromArray:[Helper getPastDates:self.pastDaysToShow]];
        
        horizontalPickerView = [[HorizontalPickerView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320, 55)];
        horizontalPickerView.rowWidth = 90.0;
        horizontalPickerView.delegate = self;
        horizontalPickerView.dividerView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"picker-selector"]] autorelease];
        horizontalPickerView.dividerView.userInteractionEnabled = NO;
        
        self.censusType = CENSUS_TYPE_ROUND;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yy"];
        
        self.censusesFactory = [[PlainListCensusesFactory alloc] init];
        
        self.filterDescription = nil;
        
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 45.0)];
        self.searchBar.tintColor = [UIColor grayColor];
        
        UISearchDisplayController *_searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        _searchDisplay.delegate = self;
        _searchDisplay.searchResultsDataSource = self;
        _searchDisplay.searchResultsDelegate = self;
        self.searchDisplay = _searchDisplay;
        [searchDisplay release];
    }
    return self;
}

-(void) loadView
{
    encountersView = [[EncountersForDateView alloc] init];
    encountersView.tableView.delegate = self;
    encountersView.tableView.dataSource = self;
    encountersView.tableView.rowHeight = 50.0;
    encountersView.tableView.showsVerticalScrollIndicator = NO;
    //encountersView.tableView.tableHeaderView = [[[EncountersTableSearchView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 45.0)] autorelease];
    encountersView.tableView.tableHeaderView = self.searchBar;
    encountersView.tableView.contentOffset = CGPointMake(0.0, 45.0);
    self.view = encountersView;
    
}

-(void) viewDidLoad
{
    [self.view addSubview:horizontalPickerView];
}

-(void) dealloc
{
    [self.filtredCensusesArray release];
    [self.searchBar release];
    [self.searchDisplay release];
    [self.filterDescription release];
    [self.censusesFactory release];
    [self.dateFormatter release];
    [self.censusesArray release];
    [self.selectedDate release];
    [horizontalPickerView release];
    [encountersView release];
    [pickerViewArray release];
    [super dealloc];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    RightNavigationViewWithSlider *rightNavView = [[RightNavigationViewWithSlider alloc] init];
    LabelSliderViewItem *labelSliderItem1 = [[LabelSliderViewItem alloc] init];
    labelSliderItem1.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem1.label.text = @"Rounds";
    labelSliderItem1.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem1.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];

    LabelSliderViewItem *labelSliderItem2 = [[LabelSliderViewItem alloc] init];
    labelSliderItem2.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem2.label.text = @"Appts";
    labelSliderItem2.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem2.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    NSArray *sliderItems = [NSArray arrayWithObjects:labelSliderItem1,labelSliderItem2, nil];
    [labelSliderItem1 release];
    [labelSliderItem2 release];
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
    
    [horizontalPickerView reload];
    [horizontalPickerView selectRow:self.futureDaysToShow animated:NO];
    [self refresh];
}

#pragma mark - 
#pragma mark HorisontalPickerViewDelegate

- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                        dateForRow: (NSInteger) row
{
    return [self.dateFormatter stringFromDate:[pickerViewArray objectAtIndex:row]];
}


- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                         dayForRow: (NSInteger) row
{
    NSString* result;
    
    NSDateFormatter *tmpdateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSDate *date = [pickerViewArray objectAtIndex:row];
    
    if (date != nil) 
    {
        [tmpdateFormatter setDoesRelativeDateFormatting:YES];
        [tmpdateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [tmpdateFormatter setDateStyle:NSDateFormatterShortStyle];
        NSDate *today = [NSDate dateWithoutTime];
        NSString *str = nil;
        if (![date isEqualToDate:today])
        {
            [tmpdateFormatter setDoesRelativeDateFormatting:NO];
            [tmpdateFormatter setDateFormat:@"EE"];
            str = [tmpdateFormatter stringFromDate:date];
            str = [str uppercaseString];
        }
        else
        {
            str = [tmpdateFormatter stringFromDate:date];
        }
        result = str;
    }
    else 
    {
        result = NSLocalizedString(@"ALL", @"ALL");
    }
    return result;
}


- (NSInteger) horizontalPickerViewNumberOfRows: (HorizontalPickerView*) pickerView
{
    return [pickerViewArray count];
}

- (void) horizontalPickerView: (HorizontalPickerView*) pickerView
                 didSelectRow: (NSInteger) row
{
    self.selectedDate = [pickerViewArray objectAtIndex:row];
    self.searchBar.text = @"";
    [self refresh];
}

#pragma mark -
#pragma mark UITableView delegate / data source

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == encountersView.tableView)
    {
        return [self.censusesArray count];
    }
    else
    {
        return [self.filtredCensusesArray count];
    }
}


-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseID = @"encountersTableViewCellReuseID";
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    
    if(cell == nil)
    {
        cell = [[[PatientTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    Census *census = nil;
    if(tableView == encountersView.tableView)
    {
        census = [self.censusesArray objectAtIndex:indexPath.row];
    }
	else
    {
        census = [self.filtredCensusesArray objectAtIndex:indexPath.row];
    }
    [cell fillWithCensus:census];
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(self.filterDescription)
    {
        return 25.0;
    }
    else
    {
        return 0.0;
    }
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *rez = nil;
    if(self.filterDescription)
    {
        TableSectionHeaderWithLabel *header = [[TableSectionHeaderWithLabel alloc] init];
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"header-row-pattern-25pts.png"]];
        header.backgroundView = backgroundView;
        [backgroundView release];
        header.textLabel.backgroundColor = [UIColor clearColor];
        header.textLabel.text = self.filterDescription;
        header.textLabel.textColor = [UIColor whiteColor];
        header.textLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:14];
        rez = header;
    }
    return [rez autorelease];
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Census *census = [self.censusesArray objectAtIndex:indexPath.row];
    CodesViewController *cvc = [[CodesViewController alloc] init];
    cvc.previousControllerTitle = @"Back";
    [self.navigationController pushViewController:cvc animated:YES];
    [cvc release];
}

#pragma mark -
#pragma SliderViewDelegate

-(void) sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    if(index == 0)
    {
        self.censusType = CENSUS_TYPE_ROUND;
    }
    else
    {
        self.censusType = CENSUS_TYPE_APPOINTMENT;
    }
    [self refresh];
}

#pragma mark -
#pragma mark Private

-(void) refresh
{
    self.censusesArray = [self.censusesFactory getCensuesOfUser:[UserSessionService currentUserSession].user forDate:self.selectedDate withCensusType:self.censusType];
    [encountersView.tableView reloadData];
    encountersView.tableView.contentOffset = CGPointMake(0.0, 45.0);
}

-(NSArray*) filterCensusesArray:(NSArray *)array withPredicate :(NSString *)predicate
{
    NSMutableArray *mutableFiltredArray = [[NSMutableArray alloc] init];
    
    NSInteger searchOptions = NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch;
    
    for(Census *census in array)
    {
        if([census.patient.firstName compare:predicate options:searchOptions range:NSMakeRange(0, [predicate length])] == NSOrderedSame
           ||[census.patient.lastName compare:predicate options:searchOptions range:NSMakeRange(0, [predicate length])] == NSOrderedSame)
        {
            [mutableFiltredArray addObject:census];
        }
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableFiltredArray];
    return rez;
}

#pragma mark -
#pragma mark SearchDisplayDelegate

-(BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.filtredCensusesArray = [self filterCensusesArray:self.censusesArray withPredicate:searchString];
    return YES;
}

@end

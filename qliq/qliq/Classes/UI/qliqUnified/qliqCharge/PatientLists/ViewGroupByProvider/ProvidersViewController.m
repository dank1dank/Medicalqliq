//
//  ProvidersViewController.m
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProvidersViewController.h"
#import "GroupService.h"
#import "ProvidersView.h"
#import "TableSectionHeaderWithLabel.h"
#import "EncountersForDateViewController.h"
#import "ProviderCensusesFactory.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "GroupCensusesFactory.h"
#import "RightNavigationViewWithSlider.h"
#import "LabelSliderViewItem.h"

#define GROUP_KEY @"group"
#define PROVIDERS_KEY @"providers"

@interface ProvidersViewController()

// array of dicts:
// "group" -> Group object
// "users" -> NSArray of QliqUser objects
@property (nonatomic, retain) NSArray *providersArray;

@property (nonatomic, retain) GroupService *groupService;

-(void) refresh;

@end

@implementation ProvidersViewController

@synthesize providersArray;
@synthesize groupService;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.groupService = [[GroupService alloc] init];
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
    [self.groupService release];
    [self.providersArray release];
    [providersView release];
    [super dealloc];
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    providersView = [[ProvidersView alloc] init];
    providersView.tableView.delegate = self;
    providersView.tableView.dataSource = self;
    providersView.tableView.separatorColor = [UIColor blackColor];
    providersView.tableView.backgroundColor = [UIColor blackColor];
    providersView.tableView.showsVerticalScrollIndicator = NO;
    self.view = providersView;
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
    labelSliderItem1.label.text = @"Group";
    labelSliderItem1.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem1.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    
    LabelSliderViewItem *labelSliderItem2 = [[LabelSliderViewItem alloc] init];
    labelSliderItem2.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem2.label.text = @"Referrals";
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
    return [self.providersArray count];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.0;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = [self.providersArray objectAtIndex:section];
    Group *group = [dict objectForKey:GROUP_KEY];
    TableSectionHeaderWithLabel *header = [[TableSectionHeaderWithLabel alloc] init];
    header.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header-Row.png"]] autorelease];
    header.textLabel.backgroundColor = [UIColor clearColor];
    header.textLabel.text = group.name;
    header.textLabel.textColor = [UIColor whiteColor];
    header.textLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:14];
    header.tag = section;
    header.delegate = self;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0,
                                                                           0.0,
                                                                           7.0,
                                                                           12.0)];
    imageView.image = [UIImage imageNamed:@"white-chevron"];
    header.accessoryView = imageView;
    return [header autorelease];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *dict = [self.providersArray objectAtIndex:section];
    NSArray *providers = [dict objectForKey:PROVIDERS_KEY];
    return [providers count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"ProvidersCellReuseId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header-Sub-Row.png"]] autorelease];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor whiteColor];
    }
    
    NSDictionary *dict = [self.providersArray objectAtIndex:indexPath.section];
    NSArray *providers = [dict objectForKey:PROVIDERS_KEY];
    QliqUser *user = [providers objectAtIndex:indexPath.row];
    QliqUser *me = [UserSessionService currentUserSession].user;
    if([user.email isEqualToString:me.email])
    {
        cell.textLabel.text = @"My Patients";
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@,%@", user.lastName, user.firstName];
    }
    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [self.providersArray objectAtIndex:indexPath.section];
    NSArray *providers = [dict objectForKey:PROVIDERS_KEY];
    QliqUser *provider = [providers objectAtIndex:indexPath.row];
    
    id<CensusFactoryProtocol> factory;
    NSString *filterDescription;
    
    ProviderCensusesFactory *providerCensusFactory = [[ProviderCensusesFactory alloc] init];
    providerCensusFactory.provider = provider;
    factory = providerCensusFactory;
    
    filterDescription = [NSString stringWithFormat:@"%@, %@ %@", provider.lastName, provider.firstName, provider.middleName !=nil? provider.middleName:@"" ];
    
    EncountersForDateViewController *encounterViewController = [[EncountersForDateViewController alloc] init];
    encounterViewController.censusesFactory = factory;
    encounterViewController.previousControllerTitle = @"Facilities";
    encounterViewController.tabView = self.tabView;
    encounterViewController.filterDescription = filterDescription;
    
    [self.navigationController pushViewController:encounterViewController animated:YES];
    [encounterViewController release];
    [factory release];
}

#pragma mark -
#pragma mark SectionHeaderViewDelegate

-(void) selectedTableSectionHeader:(TableSectionHeader *)header
{
    NSDictionary *dict = [self.providersArray objectAtIndex:header.tag];
    Group *group = [dict objectForKey: GROUP_KEY];
    
    id<CensusFactoryProtocol> factory;
    NSString *filterDescription;
    
    GroupCensusesFactory *groupCensusesFactory = [[GroupCensusesFactory alloc] init];
    groupCensusesFactory.group = group;
    factory = groupCensusesFactory;
    
    filterDescription = [group name];
    
    EncountersForDateViewController *encounterViewController = [[EncountersForDateViewController alloc] init];
    encounterViewController.censusesFactory = factory;
    encounterViewController.previousControllerTitle = @"Facilities";
    encounterViewController.tabView = self.tabView;
    encounterViewController.filterDescription =filterDescription;
    
    [self.navigationController pushViewController:encounterViewController animated:YES];
    [encounterViewController release];
    [factory release]; 
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
    NSMutableArray *newProvidersArray = [[NSMutableArray alloc] init];
    QliqUser *me = [UserSessionService currentUserSession].user;
    NSArray *groups = [self.groupService getGroupsOfUser:me];
    for(Group *group in groups)
    {
        NSMutableArray *providersToShow = [[NSMutableArray alloc] init];
        [providersToShow addObject:me];
        [providersToShow addObjectsFromArray:[groupService getGroupmatesOfUser:me inGroup:group]];
        NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              group,GROUP_KEY,
                              [NSArray arrayWithArray:providersToShow], PROVIDERS_KEY,
                              nil];
        [newProvidersArray addObject:dict];
        [dict release];
        [providersToShow release];
    }
    self.providersArray = [NSArray arrayWithArray:newProvidersArray];
    [newProvidersArray release];
    [providersView.tableView reloadData];
}

@end

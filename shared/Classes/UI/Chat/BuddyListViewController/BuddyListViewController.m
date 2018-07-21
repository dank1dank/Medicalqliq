// Created by Developer Toy
//BuddyListView.m
#import "BuddyListViewController.h"
#import "AVFoundation/AVFoundation.h"
#import "BuddyTableViewCell.h"
#import "Helper.h"
#import "QliqSip.h"

@interface BuddyListViewController ()

- (void) navigateToBuddy: (Buddy*) aBuddy;

@end

@implementation BuddyListViewController

//@synthesize patient = _patient;
//@synthesize censusObj = _censusObj;
//@synthesize dateOfService = _dateOfService;
//@synthesize delegate = _delegate;

#pragma mark -
#pragma mark View lifecycle

- (void)loadView 
{
//    [super loadView];
    
    buddyListView = [[BuddyListView alloc] init];
    buddyListView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    buddyListView.autoresizesSubviews = YES;
    buddyListView.tableView.delegate = self;
    buddyListView.tableView.dataSource = self;
    buddyListView.searchBar.delegate = self;
    self.view = buddyListView;
}

- (void)viewDidLoad
{
//	self.view.backgroundColor=[UIColor whiteColor];
	buddyList = [[BuddyList getAllBuddies] retain];
    searchList = [[NSMutableArray alloc] initWithCapacity:[buddyList count]];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(processNewChatMessage:)
												 name:SIPChatNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeNotificationObserver) name:@"RemoveNotifications" object:nil];

    _isContentInset = NO;
    _isSearching = NO;
}

- (void)removeNotificationsObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [buddyListView release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[buddyList release];
	[searchList release];
//	[_censusObj release];	 
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarBackgroundImage];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Chat List", @"Chat List") 
                                                          buttonImage:nil
                                                         buttonAction:nil];
    [buddyListView.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void)viewDidUnload
{
    [self removeNotificationsObserver];    
}

#pragma mark -
#pragma mark Actions

- (void) clickDoneButton:(id) sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)processNewChatMessage:(NSNotification *)notification
{
    if (self.navigationController.topViewController == self)
    {    
        NSString *fromUri = [[notification userInfo] objectForKey: @"FromUri"];
        fromUri = [fromUri stringByReplacingOccurrencesOfString: @"sip:" withString: @""];

        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
        fromUri = [fromUri stringByTrimmingCharactersInSet:charSet];
        
        Buddy* buddy = [BuddyList getBuddyBySipUri:fromUri];

        if (buddy)
            [self navigateToBuddy: buddy];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Buddy List count: %d", [buddyList count]);

    if (_isSearching)
        return [searchList count];
    else
        return [buddyList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"BuddyListCell";
	BuddyTableViewCell *cell = (BuddyTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[BuddyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    Buddy *thisBuddy = nil;
    if (_isSearching) {
        thisBuddy = [searchList objectAtIndex:indexPath.row];
    }
    else {
        thisBuddy = [buddyList objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = thisBuddy.displayName;
    
    if (thisBuddy.unread > 0)
    {
        cell.accessoryView = [Helper badgeWithNumber:thisBuddy.unread];
    }
    else 
    {
        cell.accessoryView = nil;
    }


    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Buddy *selectedBuddy = nil;
    if (_isSearching) {
        selectedBuddy = [searchList objectAtIndex:indexPath.row];
    }
    else {
        selectedBuddy = [buddyList objectAtIndex:indexPath.row];
    }
    
    if (selectedBuddy)
        [self navigateToBuddy: selectedBuddy];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) navigateToBuddy: (Buddy*) aBuddy
{
    [self.delegate selectedBuddy:aBuddy];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

	return 40;
}



#pragma mark -
#pragma mark UISearchBarField

- (void)doSearch:(NSString *)searchText {
    if ([searchText length] > 0) {
        _isSearching = YES;
        [searchList removeAllObjects];
        for (Buddy *buddy in buddyList) {
            NSRange dnRange = [buddy.displayName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange suRange = [buddy.sipUri rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange uiRange = [buddy.qliqId rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (dnRange.location != NSNotFound || suRange.location != NSNotFound || uiRange.location != NSNotFound) {
                [searchList addObject:buddy];
            }
        }
    }
    else {
        _isSearching = NO;
    }
    [buddyListView.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark Keyboard notifications handling

- (void)keyboardOn:(id)sender {
	if (self.isKeyboardOn) {
		return;
	}
    
    NSNotification *notification = sender;
    CGRect keyboardFrame;
    [[[notification userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
	CGRect rect = buddyListView.tableView.frame;
	rect.size.height = buddyListView.tableView.bounds.size.height - keyboardFrame.size.height;
	buddyListView.tableView.frame = rect;
	
	self.keyboardOn = YES;
}

- (void)keyboardOff:(id)sender {
	if (!self.isKeyboardOn) {
		return;
	}
    
    NSNotification *notification = sender;
    CGRect keyboardFrame;
    [[[notification userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
	CGRect rect = buddyListView.tableView.frame;
	rect.size.height = buddyListView.tableView.bounds.size.height + keyboardFrame.size.height;
	buddyListView.tableView.frame = rect;

	
	self.keyboardOn = NO;
}

@end

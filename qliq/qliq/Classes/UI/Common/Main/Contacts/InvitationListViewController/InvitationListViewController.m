//
//  InvitationListViewController.m
//  qliq
//
//  Created by Valerii Lider on 3/17/15.
//
//

#import "InvitationListViewController.h"
#import "InvitationListCell.h"
#import "InvitationService.h"
#import "Invitation.h"

#import "QliqContactsProvider.h"
#import "QliqModelServiceFactory.h"
#import "QliqUserDBService.h"

#import "DetailContactInfoViewController.h"

#define kValueCellHeight 44.f

@interface InvitationListViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
UISearchBarDelegate,
InvitationListCellDelegate
>

//IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *titleNavigationBarLabel;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//Data
@property (nonatomic, assign) BOOL isSearch;

@property (nonatomic, strong) NSArray           *sendInvitations;
@property (nonatomic, strong) NSArray           *receivedInvitations;
@property (nonatomic, strong) NSMutableArray    *searchResultSendInvitations;
@property (nonatomic, strong) NSMutableArray    *searchResultReceivedInvitations;
@property (nonatomic, strong) NSMutableArray    *content;

@property (nonatomic, strong) Invitation * showingInvitation;
@property (nonatomic, strong) QliqContactsProvider *contactsProvider;

@end

@implementation InvitationListViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contactsProvider = [QliqModelServiceFactory contactsProviderForObject:self];
    
    //Notifications
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invitationCountChanged:) name:InvitationServiceInvitationsChangedNotification object:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Title
    {
        switch (self.invitationType)
        {
            case InvitationTypeSend:
                self.titleNavigationBarLabel.text = QliqLocalizedString(@"2112-TitleSentInvitations");
                break;
            case InvitationTypeReceived:
                self.titleNavigationBarLabel.text = QliqLocalizedString(@"2113-TitleReceivedInvitations");
                break;
            case InvitationTypeAll:
            default:
                self.titleNavigationBarLabel.text = QliqLocalizedString(@"2141-TitleInvitations");
                break;
        }
    }
    
    //TableView
    {
        self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
    }
    
    //GestureRecognizer
    {
        UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(downSwipe:)];
        [swipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionDown];
        [self.view addGestureRecognizer:swipeRecognizerLeft];
    }
    
    //SearchBar
    {
        self.isSearch = ![self.searchBar.text isEqualToString:@""];
        self.searchBar.delegate = self;
        [self.searchBar showsCancelButton];
    }
    
    //Init
    {
        self.searchResultSendInvitations        = [[NSMutableArray alloc] init];
        self.searchResultReceivedInvitations    = [[NSMutableArray alloc] init];
        self.content                = [[NSMutableArray alloc] init];
        self.receivedInvitations    = [[NSMutableArray alloc] init];
        self.sendInvitations        = [[NSMutableArray alloc] init];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    self.showingInvitation      = nil;
    
    [self invitationCountChanged:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    [self.view endEditing:YES];
    self.view.window.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Notifications -

- (void)invitationCountChanged:(NSNotification *)notification
{
    self.sendInvitations        = [self.group getSentInvitations];
    self.receivedInvitations    = [self.group getReceivedInvitations];
    [self doSearchWithSearchString:self.searchBar.text];
    
    [self.tableView reloadData];
}

#pragma mark - Private Methods -

- (Invitation *)invitationForIndexPath:(NSIndexPath *)indexPath
{
    Invitation *currentInvitation = nil;
    NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
    
    switch (contentType)
    {
        case InvitationTypeSend: {
            currentInvitation = self.isSearch ?
            [self.searchResultSendInvitations objectAtIndex:indexPath.row] :
            [self.sendInvitations objectAtIndex:indexPath.row];
            break;
        }
        case InvitationTypeReceived: {
            currentInvitation = self.isSearch ?
            [self.searchResultReceivedInvitations objectAtIndex:indexPath.row] :
            [self.receivedInvitations objectAtIndex:indexPath.row];
            break;
        }
    }
    
    return currentInvitation;
}

- (void)doSearchWithSearchString:(NSString*)searchString
{
    self.isSearch = ![searchString isEqualToString:@""];
 
    if (self.isSearch)
    {
        self.searchResultSendInvitations = [NSMutableArray arrayWithArray:[[ QliqAvatar sharedInstance ] reloadContactswithInvitations:self.sendInvitations andWithSearchString:searchString] ];

        
        self.searchResultReceivedInvitations = [NSMutableArray arrayWithArray:[[ QliqAvatar sharedInstance ] reloadContactswithInvitations:self.receivedInvitations andWithSearchString:searchString] ];
    }
    else
    {
        [self.searchResultSendInvitations removeAllObjects];
        [self.searchResultReceivedInvitations removeAllObjects];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delegates -

#pragma mark * UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    [self.content removeAllObjects];
    
    if (self.invitationType == InvitationTypeAll) {
        [self.content addObject:@(InvitationTypeSend)];
        [self.content addObject:@(InvitationTypeReceived)];
    }
    else if (self.invitationType == InvitationTypeSend) {
        [self.content addObject:@(InvitationTypeSend)];
    }
    else if (self.invitationType == InvitationTypeReceived) {
        [self.content addObject:@(InvitationTypeReceived)];
    }

    count = self.content.count;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
    
    switch (contentType)
    {
        case InvitationTypeSend:
            count = self.isSearch ? self.searchResultSendInvitations.count : self.sendInvitations.count;            break;
        case InvitationTypeReceived:
            count = self.isSearch ? self.searchResultReceivedInvitations.count : self.receivedInvitations.count;    break;
        default: break;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kValueCellHeight;
}

/*
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
 */


/*
 - (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 return nil;
 }
 */

/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
 */

/*
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}
 */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseId = @"InviteContactCell_ID";
    InvitationListCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.delegate = self;
    
    [cell setCellInvitation:[self invitationForIndexPath:indexPath]];

    return cell;
}

#pragma mark - - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
}

#pragma mark - - InvitationCellList Delegate

- (void)invitationListCell:(InvitationListCell *)cell viewDidTappedWithInvitation:(Invitation *)invitation
{
    DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
    controller.contact = invitation;   
    [self.navigationController pushViewController:controller animated:YES];
    
    if (invitation.operation == InvitationOperationReceived)
    {
        invitation.status = InvitationStatusRead;
        [[InvitationService sharedService] saveInvitation:invitation];
    }
    
    self.showingInvitation = invitation;
}

#pragma mark - - UISerachBar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearchWithSearchString:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearchWithSearchString:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end

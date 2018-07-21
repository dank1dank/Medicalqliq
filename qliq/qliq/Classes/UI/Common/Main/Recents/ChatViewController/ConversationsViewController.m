//
//  ConversationsViewController.m
//  qliq
//
//  Created by Valerii Lider on 3/12/15.
//
//

#import "ConversationsViewController.h"

/**
 Controllers
 */
#import "ConversationViewController.h"
#import "ConversationsListViewController.h"
/**
 Cells
 */
#import "RecentTableViewCell.h"

#import "ConversationViewController.h"
#import "ConversationDBService.h"
#import "ChatMessageService.h"
#import "QliqConnectModule.h"
#import "Conversation.h"
#import "MainSettingsViewController.h"
#import "InviteContactsViewController.h"
#import "SelectContactsViewController.h"
#import "ProfileViewController.h"
#import "SettingsSoundViewController.h"

#import "MessageAttachment.h"

#import "QliqSip.h"

#import "UIDevice-Hardware.h"

#define kValueSearchBarHeight 44.f

typedef enum {
    ConversationArray,
    SearchArray
} ConversationArrayType;

@interface ConversationsViewController ()
<
UISearchBarDelegate,
UITableViewDataSource,
UITableViewDelegate,
UIScrollViewDelegate,
UINavigationControllerDelegate,
RecentCellDelegate,
ConversationViewControllerDelegate
>

/**
 IBOutlet
 */
/* NavigationBar */
@property (weak, nonatomic) IBOutlet UILabel *titleLabelNavigationBar;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/* Constraint */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;

/**
 UI
 */
@property (nonatomic, strong) UIRefreshControl *refreshControl;

/**
 Data
 */
@property (nonatomic, assign) BOOL notReadOnce;
@property (nonatomic, assign) BOOL isForegroundView;
@property (nonatomic, assign) BOOL isSearching;

@property (nonatomic, assign) int registration5XXErrorCount;

@property (nonatomic, strong) NSArray *archivedConversations;
@property (nonatomic, strong) NSMutableArray *searchConversations;

@property (nonatomic, retain) dispatch_queue_t refreshQueue;

@property (nonatomic, strong) Conversation *selectedConversation;

@end

@implementation ConversationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //refreshQueue
    {
        self.refreshQueue = dispatch_queue_create("handle_new_message_conversationlist", NULL);
    }
    
    //Set title
    {
        if (self.isArchivedConversations)
            self.titleLabelNavigationBar.text = QliqLocalizedString(@"2106-TitleArchivedConversations");
        else
            self.titleLabelNavigationBar.text = @"";
    }
    
    // SearchBar
    {
        self.searchBar.placeholder              = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate                 = self;
        self.searchBar.autocorrectionType       = UITextAutocorrectionTypeYes;
        self.searchBar.spellCheckingType        = UITextSpellCheckingTypeYes;
        self.searchBar.autocapitalizationType   = UITextAutocapitalizationTypeNone;
        self.searchBar.keyboardType             = UIKeyboardTypeAlphabet;
    }
    
    //RefreshControl
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(onPullToRefresh:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
    
    //TableView
    {
        self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
        [self.tableView reloadData];
    }
    
    //Notifications
    [self addNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    
    DDLogSupport(@"Conversation Refresh Called from viewWillAppear during initialization");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf refreshView:YES loadFromDb:YES];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    {
        self.isForegroundView = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLockScreenShowed:) name:kDeviceLockStatusChangedNotificationName object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    {
        [self.navigationController setNavigationBarHidden:YES];
        [self.view endEditing:YES];
        self.view.window.backgroundColor = [UIColor whiteColor];
    }
    
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceLockStatusChangedNotificationName object:nil];
        self.isForegroundView = NO;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)eraseSelectedConversation {
    if (self.selectedConversation) {
        self.selectedConversation = nil;
        [self.tableView reloadData];
    }
}

#pragma mark - Conversation -

- (Conversation*)getConversationFromIndexPath:(NSIndexPath*)indexPath
{
    Conversation * conversation = nil;
    
    if (self.isSearching) {
        conversation = [self.searchConversations objectAtIndex:indexPath.row];
    }
    else {
        conversation = [self.conversations objectAtIndex:indexPath.row];
    }
    
    return conversation;
}

- (NSArray *)loadConversations
{
    @synchronized(self) {
        self.conversations = [[ConversationDBService sharedService] getConversationsForRecentsViewArchived:self.isArchivedConversations careChannel:self.isCareChannelsMode];
        return self.conversations;
    }
}

- (void)refreshViewAsync:(BOOL)force loadFromDb:(BOOL)load //√
{
    DDLogSupport(@"Dispatching async serial queue force = %d", force);
    
    NSAssert(NULL != self.refreshQueue, @"refreshQueue MUST be initialized before this method get called");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.refreshQueue, ^{
        [weakSelf refreshView:force loadFromDb:load];
    });
}

- (void)refreshView:(BOOL)force loadFromDb:(BOOL)load //√
{
    static BOOL performingNow = NO;
    
    if ([AppDelegate applicationState] == UIApplicationStateBackground)
    {
        // We should try to refresh in the BG also. Because if the App is launched, it takes a while
        // for the app to become active.
        DDLogSupport(@"Refresh called in the BG.");
    }
    
    @synchronized(self) {
        
        if (!performingNow || force)
        {
            performingNow = YES;
            
            NSArray * conversations;
            
            if (load)
            {
                DDLogSupport(@"Loading all conversaions from DB");
                conversations = [self loadConversations];
            }
            
            
            
            
            DDLogSupport(@"Reloading table data");
            
            if (load)
                self.conversations = [NSMutableArray arrayWithArray:conversations];
            
            __block __weak typeof(self) weakSelf = self;
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                [weakSelf.tableView reloadData];
                
                if(weakSelf.isSearching) {
                    DDLogSupport(@"Restoring search filter");
                    
                    [weakSelf doSearch:weakSelf.searchBar.text];
                }
                performingNow = NO;
            });
        }
        else
        {
            DDLogSupport(@"Already performing reload conversations");
        }
    }
}

#pragma mark * Managing Conversation Array

- (void)sortConversations //√
{
    self.conversations          = [NSMutableArray arrayWithArray:[self.conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)] ];
    self.searchConversations    = [NSMutableArray arrayWithArray:[self.searchConversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)] ];
}

- (NSIndexPath *)updateConversationArray:(ConversationArrayType)arrayType withConversation:(Conversation *)_conversation //√
{
    NSArray *_array = (arrayType == ConversationArray ? self.conversations : self.searchConversations);
    
    NSIndexPath * indexPath = nil;
    for (Conversation *oldConv in _array)
    {
        if (oldConv.conversationId == _conversation.conversationId)
        {
            indexPath = [NSIndexPath indexPathForRow:[_array indexOfObject:oldConv] inSection:0];
            
            if (_conversation.lastMsg)
            {
                oldConv.lastMsg     = _conversation.lastMsg;
                oldConv.lastUpdated = _conversation.lastUpdated;
                oldConv.isRead      = _conversation.isRead;
            }
            else
            {
                // This conv was deleted
                NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[_array count] -  1];
                [newArray addObjectsFromArray:_array];
                [newArray removeObject:oldConv];
                
                if (arrayType == ConversationArray)
                    self.conversations = newArray;
                else
                    self.searchConversations = newArray;
            }
            break;
        }
    }
    return indexPath;
}

- (void)updateConversationsArrayWithConversation:(Conversation *)_conversation //√
{
    if (!_conversation)
    {
        DDLogError(@"UpdateConversationsArrayWithConversation called with nil conversation arg");
        return;
    }
    
    DDLogSupport(@"Conversation Refresh Called from updateConversationsArrayWithConversation");
    
    if (_conversation.lastMsg == nil)
    {
        ChatMessage *lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:_conversation.conversationId];
        _conversation.lastMsg = lastMessage.text;
        _conversation.lastUpdated = lastMessage.createdAt;
    }
    
    NSIndexPath * searchIndexPath   = [self updateConversationArray:SearchArray withConversation:_conversation];
    NSIndexPath * allIndexPath      = [self updateConversationArray:ConversationArray withConversation:_conversation];
    
    if (allIndexPath == nil)
        [self.conversations addObject:_conversation];
    
    if (searchIndexPath == nil)
        [self.searchConversations addObject:_conversation];
    
    [self sortConversations];
    [self refreshView:YES loadFromDb:YES];
}

#pragma mark - User Actions

- (void)onPullToRefresh:(UIRefreshControl *)refreshControl
{
    DDLogSupport(@"Conversation Refresh Called from onPullToRefresh");
    
    [self.refreshControl endRefreshing];
    [self refreshViewAsync:YES loadFromDb:YES];
}

#pragma mark - Notifications

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationWillResignActiveNotification:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Now register for Active Notification. When the App goes frm BG to FG, we need to refresh the UI
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    // Register for conversation change notifications here
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReadMessages:)
                                                 name:ConversationDidReadMessagesNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessage:)
                                                 name:DBHelperConversationDidAddMessage
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDeleteMessagesInConversation:)
                                                 name:QliqConnectDidDeleteMessagesInConversationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRecipientsChangedNotification:)
                                                 name:RecipientsChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshController)
                                                 name:kConversationsListDidPressActionButtonNotification
                                               object:nil];
}

- (void)refreshController
{
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf refreshView:YES loadFromDb:YES];
    });
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *) notification
{
    DDLogSupport(@"handleApplicationWillResignActiveNotification");
    
    self.isForegroundView = NO;
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            DDLogSupport(@"Dismissing connecting progress indicator");
            [SVProgressHUD dismiss];
        }
    });
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    if ([appDelegate unProcessedRemoteNotifcations] > 0)
    {
        dispatch_async_main(^{
            DDLogSupport(@"Checking for Messages ProgressHUD. Started");
            [SVProgressHUD showWithStatus:NSLocalizedString(@"1903-TextCheckingForMessages", nil)];
        });
    }
    
    DDLogSupport(@"Conversation Refresh Called from handleApplicationDidBecomeActiveNotification");
    
    self.isForegroundView = YES;
    [self refreshViewAsync:YES loadFromDb:NO];
}

- (void)didReadMessages:(NSNotification *)notification
{
    DDLogSupport(@"didReadMessages notification, dispatching refresh");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.refreshQueue, ^{
        [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    });
    
    self.notReadOnce = NO;
}

- (void)didReceiveMessage:(NSNotification *)notification
{
    DDLogSupport(@"didReceiveMessage notification, dispatching refresh");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.refreshQueue, ^{
        [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    });
}

- (void)didDeleteMessagesInConversation:(NSNotification *)notification
{
    DDLogSupport(@"didDeleteMessages notification, dispatching refresh");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.refreshQueue, ^{
        [weakSelf updateConversationsArrayWithConversation:[[notification userInfo] objectForKey:@"Conversation"]];
    });
}

- (void)handleRecipientsChangedNotification:(NSNotification *)notification
{
    DDLogSupport(@"Conversation Refresh Called from handleRecipientsChangedNotification");
    
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.refreshQueue, ^{
        [weakSelf updateConversationsArrayWithConversation:notification.object];
    });
}

- (void)onLockScreenShowed:(NSNotification *)notification
{
    if (appDelegate.currentDeviceStatusController.isWiped)
        [self refreshView:YES loadFromDb:YES];
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)onBack:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delegates -

#pragma mark * UITableView  Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.conversations.count;
    
    if (self.isSearching)
        count = [self.searchConversations count];
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kValueHeightRecentCell;
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RecentTableViewCell_ID";
    
    RecentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell) {
        
        UINib *nib = [UINib nibWithNibName:@"RecentTableViewCell" bundle:nil];
        
        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
    }
    
    cell.delegate = self;
    [cell configureCellWithConversation:[self getConversationFromIndexPath:indexPath] withSelectedCell:self.selectedConversation];
    [cell configureBackroundColor:RGBa(239.f, 239.f, 239.f, 1.f)];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation * conversation = [self getConversationFromIndexPath:indexPath];
    
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.conversation = conversation;
    controller.delegate     = self;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark * RecentCell Delegate

- (void)cellLeftSwipe:(Conversation *)conversation {
    self.selectedConversation = conversation;
    [self.tableView reloadData];
}

- (void)cellRightSwipe {
    [self eraseSelectedConversation];
}

- (void)pressCallButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from Call User");
    
    [self eraseSelectedConversation];
}

- (void)pressFlagButton:(Conversation *)conversation {
    DDLogSupport(@"Flag button pressed!");
    
    [self eraseSelectedConversation];
}

- (void)pressSaveButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from restoreConversations");
    
    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    controller.conversations = self.conversations;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionRestore;
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)pressDeleteButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from deleteConversations");

    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    controller.conversations = self.conversations;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionDelete;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - - ConversationViewController Delegate

- (void)conversationSavePressed:(Conversation *)conversation {
    [self pressSaveButton:conversation];
}

- (void)conversationDeletePressed:(Conversation *)conversation {
    [self pressDeleteButton:conversation];
}

#pragma mark - - UIScrollView Delegate

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self eraseSelectedConversation];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self eraseSelectedConversation];
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - - UISearchBarField Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)doSearch:(NSString *)searchText
{
    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithCapacity:self.conversations.count];
    [tmpArr addObjectsFromArray:self.conversations];
    
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:tmpArr andSearchString:searchText withPrioritizedAlphabetically:NO];
    self.searchConversations = [NSMutableArray arrayWithArray:[operation search]];
    
    self.isSearching = (operation != nil);
    
    [self.tableView reloadData];
}

@end

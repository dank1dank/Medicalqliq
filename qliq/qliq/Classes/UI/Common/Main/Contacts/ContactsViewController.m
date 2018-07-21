//
//  ContactsViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "ContactsViewController.h"

#import "QliqGroup.h"
#import "OnCallGroup.h"
#import "GetOnCallUpdatesService.h"

#import "QliqContactsGroup.h"
#import "ContactDBService.h"
#import "QliqModelServiceFactory.h"
#import "QliqContactsProvider.h"
#import "ContactAvatarService.h"
#import "QliqAddressBookContactGroup.h"
#import "InviteContactsViewController.h"
#import "SelectContactsViewController.h"
#import "CreateListViewController.h"

#import "QliqFavoritesContactGroup.h"

#import "DetailContactInfoViewController.h"
#import "DetailOnCallViewController.h"

#import "MainSettingsViewController.h"
#import "ConversationViewController.h"
#import "Recipients.h"
#import "ContactListPopover.h"

#import "ContactTableCell.h"
#import "Login.h"

#import "QliqSip.h"

#import "UIDevice-Hardware.h"
#import "AlertController.h"

//////
#import "GetContactsPaged.h"
#import "QliqJsonSchemaHeader.h"
/////

#import "GetPresenceStatusService.h"
#import "UpdateGroupMembershipService.h"

/**
 Controllers
 */
#import "FavoriteContactsViewController.h"
#import "InvitationListViewController.h"
#import "CollectionFavoritesViewController.h"

/**
 Services
 */
#import "QliqUserDBService.h"
#import "QliqListService.h"
#import "SearchContactsService.h"
#import "QliqAvatar.h"

#import "ACPDownloadView.h"
#import "ACPStaticImagesAlternative.h"

#define kKeySectionTitle    @"SectionTitle"
#define kKeyRecipients      @"Recipients"

#define kValueSearchBarHeight 44.f

#define kPresenceCNForMySelf [notification.userInfo[@"isForMyself"] boolValue] == NO
typedef NS_ENUM(NSInteger, ContactMenu) {
    ContactMenuUsers,
    ContactMenuGroups,
    ContactMenuFavorites
};

@interface ContactsViewController ()
<
ContactListPopoverDelegate,
GroupListPopoverDelegate,
ContactsCellDelegate,
SearchOperationDelegate,
UISearchBarDelegate,
UITableViewDataSource,
UITableViewDelegate
>

/**
 IBOutlet
 */
//ContactsView
@property (weak, nonatomic) IBOutlet UIView *contactListView;
@property (weak, nonatomic) IBOutlet UIView *selectionView1;
@property (weak, nonatomic) IBOutlet UIButton *commonSectionButton;
@property (weak, nonatomic) IBOutlet UIButton *arrowContactListButton;
@property (weak, nonatomic) IBOutlet ContactListPopover *contactListPopover;

//GroupsView
@property (weak, nonatomic) IBOutlet UIView *groupListView;
@property (weak, nonatomic) IBOutlet UIView *selectionView2;
@property (weak, nonatomic) IBOutlet UIButton *groupsSectionButton;


//FavoriteView
@property (weak, nonatomic) IBOutlet UIView *favoritesListView;
@property (weak, nonatomic) IBOutlet UIView *selectionView3;
@property (weak, nonatomic) IBOutlet UIButton *favoritesSectionButton;

//Header
@property (weak, nonatomic) IBOutlet UIView     *headerView;
@property (weak, nonatomic) IBOutlet UIView     *invitationsView;
@property (weak, nonatomic) IBOutlet UIView     *sendInvitations;
@property (weak, nonatomic) IBOutlet UIButton *sendInvitationButton;
@property (weak, nonatomic) IBOutlet UILabel    *sendInvitationCountLabel;
@property (weak, nonatomic) IBOutlet UIView     *receivedInvitations;
@property (weak, nonatomic) IBOutlet UILabel    *receovedInvitationCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *receivedInvitationsButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *favoritesView;

//ActionBar
@property (weak, nonatomic) IBOutlet UIButton *searchFavoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactListHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsViewWeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsListWeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupListHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

//Header
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *invitationsViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendInvitationsHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *receivedInvitationsHeight;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarBackgroundBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopConstraint;

/** UI */
@property (strong, nonatomic) CollectionFavoritesViewController *collectionViewFavorites;

/** Data */
@property (nonatomic, assign) BOOL isBlockScrollViewDelegate;
@property (nonatomic, assign) BOOL canReloadContacts;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL isOnCallGroups;

@property (nonatomic, assign) BOOL searchBarWasEmpty;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL searchOperationDone;

@property (nonatomic, assign) CGFloat tableViewIndexSectionOffset;

@property (nonatomic, assign) ContactMenu selectedMenu;

@property (nonatomic, strong) NSArray *onlyNewContacts;

@property (nonatomic, assign) BOOL isSelectedForDetailsContact;

//array with data fetched from DB
@property (nonatomic, strong) NSMutableArray *contactsArray;
//array for search results
@property (nonatomic, strong) NSMutableArray *searchArray;

//presorted array
@property (nonatomic, strong) NSMutableArray *contactsSortedArray;

//array for tableView data
@property (nonatomic, strong) NSMutableArray *dataSourceSortedArray;

@property (nonatomic, strong) NSMutableArray *presenceCNArray;

//Prorerty for adjustment of count of presence-CN which can be processed without full reloading of controller from DB
@property (nonatomic, assign) NSInteger countOfPresenceCNForReloadFromDB;

@property (nonatomic, strong) QliqContactsProvider *contactsProvider;
@property (nonatomic, strong) QliqFavoritesContactGroup *favoritesContactGroup;
@property (nonatomic, strong) id<ContactGroup> contactGroup;

/** Refresh Queue */
@property (nonatomic, strong) NSOperationQueue *refreshContactsOperationQueue;
@property (nonatomic, strong) NSOperationQueue *searchOperationsQueue;

//Banner View
@property (nonatomic, strong)UIView *bannerView;
@property (nonatomic, strong) ACPDownloadView *activityView;

@end

/** General issue for ContactsViewController
 */
///TODO: need hide popover when selected Favorites.

@implementation ContactsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadingWithNotification) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onCallUpdate:) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePresence) object:nil];
    
    [self.refreshContactsOperationQueue cancelAllOperations];
    [self.refreshContactsOperationQueue waitUntilAllOperationsAreFinished];
    self.refreshContactsOperationQueue = nil;
    
    [self.searchOperationsQueue  cancelAllOperations];
    [self.searchOperationsQueue waitUntilAllOperationsAreFinished];
    self.searchOperationsQueue  = nil;
    
    self.dataSourceSortedArray = nil;
    self.contactsSortedArray = nil;
    
    self.favoritesContactGroup  = nil;
    self.searchArray            = nil;
    self.contactsProvider       = nil;
    self.contactsArray          = nil;
    self.contactGroup           = nil;
    
    self.contactListView = nil;
    self.selectionView1 = nil;
    self.commonSectionButton  = nil;
    self.arrowContactListButton  = nil;
    self.contactListPopover  = nil;
    
    //GroupsView
    self.groupListView  = nil;
    self.selectionView2  = nil;
    self.groupsSectionButton  = nil;
    
    //FavoriteView
    self.favoritesListView  = nil;
    self.selectionView3  = nil;
    self.favoritesSectionButton  = nil;
    
    //Header
    self.headerView  = nil;
    self.invitationsView  = nil;
    self.sendInvitations  = nil;
    self.sendInvitationButton  = nil;
    self.sendInvitationCountLabel  = nil;
    self.receivedInvitations  = nil;
    self.receovedInvitationCountLabel  = nil;
    self.receivedInvitationsButton  = nil;
    self.searchBar  = nil;
    
    self.tableView  = nil;
    self.favoritesView  = nil;
    
    //ActionBar
    self.searchFavoriteButton  = nil;
    self.settingsButton  = nil;
    
    self.contactListHeightConstraint  = nil;
    self.groupsViewWeightConstraint  = nil;
    self.groupsListWeightConstraint  = nil;
    self.groupListHeightConstraint  = nil;
    
    self.invitationsViewHeightConstraint  = nil;
    self.sendInvitationsHeightConstraint  = nil;
    self.receivedInvitationsHeight  = nil;
    
    self.collectionViewFavorites  = nil;
    self.searchText  = nil;
    self.onlyNewContacts  = nil;
    self.presenceCNArray  = nil;
}

- (void)configureDefaultText {
    [self.sendInvitationButton setTitle:QliqLocalizedString(@"2112-TitleSentInvitations") forState:UIControlStateNormal];
    [self.receivedInvitationsButton setTitle:QliqLocalizedString(@"2113-TitleReceivedInvitations") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isIPhoneX {
        /*Change constraints for iPhone X*/
        __block __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            weakSelf.containerTopConstraint.constant = weakSelf.containerTopConstraint.constant + 4.f;
            weakSelf.tabBarBackgroundBottomConstraint.constant = weakSelf.tabBarBackgroundBottomConstraint.constant -35.0f;
            [weakSelf.view layoutIfNeeded];
        });
    }
    
    [self configureDefaultText];
    
    self.isHide = YES;
    self.canReloadContacts = NO;
    self.searchBarWasEmpty = NO;
    
    self.isSelectedForDetailsContact = NO;
    
    self.searchText = @"";
    
    //CollectionView Container
    {
        for (UIViewController *controller in self.childViewControllers)
        {
            if ([controller isKindOfClass:[CollectionFavoritesViewController class]])
                self.collectionViewFavorites = (id)controller;
        }
    }
    
    //HeaderView
    {
        [self showInvitationView:NO withAnimation:NO];
        self.sendInvitationCountLabel.text      = @"(0)";
        self.receovedInvitationCountLabel.text  = @"(0)";
    }
    
    //Init
    {
        self.contactsArray = [NSMutableArray new];
        self.searchArray = [NSMutableArray new];
        self.contactsSortedArray = [NSMutableArray new];
        self.dataSourceSortedArray = [NSMutableArray new];
        self.presenceCNArray = [NSMutableArray new];
    }
    
    //SetValue
    {
        self.isSearching = NO;
    }
    
    //selectedMenu
    {
        self.selectedMenu = ContactMenuUsers;
        [self updateButtonsFor:self.selectedMenu];
        [self.view sendSubviewToBack:self.favoritesView];
        self.favoritesView.hidden = NO;
    }
    
    // Added in order to hide the search bar
    {
        self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate = self;
        [self changeFrameHeaderView];
    }
    
    self.contactsProvider = [QliqModelServiceFactory contactsProviderForObject:self];
    self.favoritesContactGroup = [[QliqFavoritesContactGroup alloc] init];
    self.searchOperationsQueue = [[NSOperationQueue alloc] init];
    self.searchOperationsQueue.maxConcurrentOperationCount = 1;
    
    //Popover
    {
        //Contact
        self.commonSectionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.contactListHeightConstraint.constant = 0;
        self.contactListPopover.delegate = self;
        
        //Group
        self.groupsSectionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.groupListHeightConstraint.constant = 0;
        self.groupListPopover.delegate = self;
        
        //Favorites
        self.favoritesSectionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    //TableView
    {
        self.tableView.accessibilityLabel = @"ContactTableView";
        self.tableView.sectionIndexColor = kColorAvatarBackground;
        if ([self respondsToSelector:@selector(sectionIndexBackgroundColor)])
            self.tableView.sectionIndexBackgroundColor = [UIColor whiteColor];
    }
    
    //Register Nib of Cell
    {
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([ContactTableCell class]) bundle:nil];
        [self.tableView registerNib:nib forCellReuseIdentifier:ContactTableCellId];
    }
    
    //Notification
    {
        [self addNotifications];
    }
    
    //Operation Queue
    self.refreshContactsOperationQueue = [[NSOperationQueue alloc] init];
    self.refreshContactsOperationQueue.name = @"qliqContacts.operationQueue";
    self.refreshContactsOperationQueue.maxConcurrentOperationCount = 1;
    
    //Presence
    //   Prorerty for adjustment of count of presence-CN which can be processed without full reloading of controller from DB
    self.countOfPresenceCNForReloadFromDB = 2;
    
    [self prepareInformation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    if (self.selectedMenu == ContactMenuGroups) {
        if (self.isOnCallGroups) {
            __weak __block typeof(self) welf = self;
            [welf updateActivityView];
        }
    }
    
    self.isSelectedForDetailsContact = NO;
    
    [self manageInviteAlert];
 
    //No need to check count of contacts from DB every time when this view controller will appear, because lag switching.
    //Valerii Lider 07/06/17
//    //Need to check count of contacts from DB. In case, if count of contacts from DB was updated - need to reload contactsArray.
//    //Valerii Lider 05/16/17
//    if (self.contactsArray.count < [self.contactGroup getOnlyContacts].count) {
//        [self refreshControllerReloadFromDB:YES sort:YES];
//    }
//    else {
//        [self refreshControllerReloadFromDB:NO sort:NO];
//    }
    
    if (!self.canReloadContacts) {
        self.canReloadContacts = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [self prepareViewControllerForDisappearing];
    [self markNewContactsAsViewed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [self.refreshContactsOperationQueue cancelAllOperations];
    [self.refreshContactsOperationQueue waitUntilAllOperationsAreFinished];
    [self.searchOperationsQueue  cancelAllOperations];
    [self.searchOperationsQueue waitUntilAllOperationsAreFinished];
    
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue addOperationWithBlock:^{
        [welf.contactsSortedArray removeAllObjects];
        [welf.searchArray removeAllObjects];
        [welf.contactsArray removeAllObjects];
        
        [welf reloadContactsFromDB];
        [welf startSearchWithText:self.searchBar.text];
    }];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    CGSize size = CGSizeForUIInterfaceOrientation(toInterfaceOrientation);
    [self setContactTypeButtonConstraintsWithSize:size];
    
    [self updateBannerFrameForSize:size];
}

#pragma mark - Alerts -

- (void)showInviteColeaguesAlert
{
    QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:NO];
    [alertView setContainerViewWithImage:[UIImage imageNamed:@"AlertImageInviteColleagues"]
                               withTitle:NSLocalizedString(@"1029-TextInviteColleagues", nil)
                                withText:NSLocalizedString(@"1030-TextInviteColleaguesDescription", nil)
                            withDelegate:nil
                        useMotionEffects:YES];
    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"13-ButtonLater", nil), NSLocalizedString(@"15-ButtonInvite", nil), nil]];
    __block __weak typeof(self) weakSelf = self;
    [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
        
        if (buttonIndex != 0)
        {
            InviteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([InviteContactsViewController class])];
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }
    }];
    
    performBlockInMainThreadSync(^{
        [alertView show];
    });
}

- (void)showInviteContactsAlert
{
    SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
    
    if (!sSettings.personalContacts) {
        return;
    }
    
    QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:NO];
    [alertView setContainerViewWithImage:[UIImage imageNamed:@"AlertImageInviteColleagues"]
                               withTitle:NSLocalizedString(@"1029-TextInviteColleagues", nil)
                                withText:NSLocalizedString(@"1030-TextInviteColleaguesDescription", nil)
                            withDelegate:nil
                        useMotionEffects:YES];
    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"13-ButtonLater", nil), NSLocalizedString(@"15-ButtonInvite", nil), nil]];
    __block __weak typeof(self) weakSelf = self;
    [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
        
        if (buttonIndex != 0)
        {
            SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }
    }];
    performBlockInMainThreadSync(^{
        [alertView show];
    });
}

- (void)manageInviteAlert
{
    CGSize size = CGSizeForUIInterfaceOrientation([[UIApplication sharedApplication] statusBarOrientation]);
    [self setContactTypeButtonConstraintsWithSize:size];
    
    //Alert
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults objectForKey:kShowInviteAlertOnceLoggedInKey])
        {
            if ([[defaults objectForKey:kShowInviteAlertOnceLoggedInKey] boolValue] == YES)
            {
                [defaults removeObjectForKey:kShowInviteAlertOnceLoggedInKey];
                [defaults synchronize];
                
                [self showInviteAlerts];
            }
        }
    }
}

- (void)showInviteAlerts
{
    if (is_ios_greater_or_equal_9() && [CNContactStore class]) {
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        CNEntityType entityType = CNEntityTypeContacts;
        if([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
        {
            __block __weak typeof(self) welf = self;
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error)
             {
                 if(granted)
                     [welf showInviteContactsAlert];
                 else
                 {
                     DDLogSupport(@"CNContactStore requestAccessForEntityType: Not Granted");
                     if (error)
                     {
                         DDLogError(@"%@", [error localizedDescription]);
                     }
                     [welf showInviteColeaguesAlert];
                 }
             }];
        }
        else if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusAuthorized)
        {
            [self showInviteContactsAlert];
        }
        else
        {
            if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusDenied)
                DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusDenied");
            else if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusRestricted)
                DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusRestricted");
            
            [self showInviteColeaguesAlert];
        }
        
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            __block __weak typeof(self) welf = self;
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    [welf showInviteContactsAlert];
                } else {
                    [welf showInviteColeaguesAlert];
                }
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            [self showInviteContactsAlert];
        }
        else {
            [self showInviteColeaguesAlert];
        }
        
        if (addressBook) {
            CFRelease(addressBook);
        }
    }
}

#pragma mark - Notifications -

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userConfigurationDidChanged:)
                                                 name:UserConfigDidRefreshedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUpdateContactsListNotification:)
                                                 name:kUpdateContactsListNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setSelectedSettingsButton:)
                                                 name:kDidShowedCurtainViewNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewContactNotification:)
                                                 name:ContactServiceNewContactNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayedReloadingWithNotification)
                                                 name:@"ReloadFavoritesCollectionViewControllerNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOnCallGroupsChanged:)
                                                 name:kOnCallGroupsChangedNotification
                                               object:nil];
}

- (void)onUpdateContactsListNotification:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadingWithNotification) object:nil];
    [self performSelector:@selector(delayedReloadingWithNotification) withObject:nil afterDelay:0.5];
}


- (void)handleNewContactNotification:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadingWithNotification) object:nil];
    [self performSelector:@selector(delayedReloadingWithNotification) withObject:nil afterDelay:0.5];
}

- (void)userConfigurationDidChanged:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedReloadingWithNotification) object:nil];
    [self performSelector:@selector(delayedReloadingWithNotification) withObject:nil afterDelay:0.5];
}

- (void)delayedReloadingWithNotification {
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue cancelAllOperations];
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        
        [welf reloadContactsFromDB];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [welf startSearchWithText:self.searchBar.text];
        });
    }];
}

- (void)setSelectedSettingsButton:(NSNotification *)notification {
    NSNumber *info = [notification object];
    
    if (info) {
        self.settingsButton.selected = [info boolValue];
    }
}

#pragma mark * OnCall

- (void)handleOnCallGroupsChanged:(NSNotification *)notification {
    
    DDLogSupport(@"handleOnCallGroupsChanged called");
    if (self.selectedMenu == ContactMenuGroups && self.groupListPopover.currentGroup == GroupListOnCallGroups) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onCallGroupsChanged:) object:nil];
        // Krishna 3/8/2017 Delay in calling selector will prohibit the IOS from calling the
        // selector when the App is in the Background. WHich will make the Data Inconsistent.
        // Works in FG and not when app goes from BG to FG
        [self performSelector:@selector(onCallGroupsChanged:) withObject:notification];
    }
}

- (void)onCallGroupsChanged:(NSNotification *)notification {
    
    DDLogSupport(@"onCallGroupsChanged called");
        
        [self.refreshContactsOperationQueue cancelAllOperations];
        [self.refreshContactsOperationQueue addOperationWithBlock: ^{
            // TODO Krishna Should we reload the Data from the notification? Otherwise DB opetation could
            // complete after loading from from DB below. Which will be older data
            //
            __weak __block typeof(self) weakself = self;
            dispatch_async_main(^{
                [weakself reloadContactsFromDB];
                [weakself startSearchWithText:weakself.searchBar.text];
            });
        }];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    
    if (self.selectedMenu == ContactMenuGroups) {
        if (self.isOnCallGroups) {
            __weak __block typeof(self) welf = self;
            [welf showOnCallUpdatesView:YES];
        }
    }
}

#pragma mark * Presence

/*
 Method perfom handling of every presence change notification received by ContactsViewController
 
 If controller is receiving CNs one by one without delay,
 all of them will be written to array and processed together
 instead of processing of each single CN.
 */
- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePresence) object:nil];
    
    [self.presenceCNArray addObject:[notification copy]];
    
    [self performSelector:@selector(updatePresence) withObject:nil afterDelay:0.5];
}

/*
 Method for choosing way of processing presence-CNs
 */
- (void)updatePresence {
    
    __weak __block typeof(self) welf = self;
    
    /*
     Clear array of presence CN's for next handling
     */
    __block NSMutableArray *presenceNotificationsArray = [self.presenceCNArray mutableCopy];
    
    [self.presenceCNArray removeAllObjects];
    
    /*
     If count of handled presence-CNs more than count
     allowed by 'countOfPresenceCNForReloadFromDB',
     starts full update of controller from DB (Takes more time and blocks DB). Else perform
     processing of each single notification.
     */
    
    if (presenceNotificationsArray.count > welf.countOfPresenceCNForReloadFromDB)  {
        
        [self.refreshContactsOperationQueue cancelAllOperations];
        [self.refreshContactsOperationQueue addOperationWithBlock: ^{
            DDLogSupport(@"Update presence with loading from DB");
            
            if(welf.isSearching) {
                
                [welf reloadContactsFromDB];
                [welf startSearchWithText:self.searchBar.text];
                
            } else {
                
                [welf refreshControllerReloadFromDB:YES sort:YES];
            }
        }];
        
    } else {
        
        [self.refreshContactsOperationQueue addOperationWithBlock: ^{
            
            [welf updatePresenceForEachNotificationInArray:presenceNotificationsArray];
        }];
    }
}

/*
 Method for processing presence-CN in single mode (without long DB access)
 */
- (void)updatePresenceForEachNotificationInArray:(NSMutableArray *)presenceNotificationsArray {
    DDLogSupport(@"Update presence for each presence CN notification for current sort menu");
    /*
     Init of required values for CNs processing
     */
    //flag sets, even if one object in contactsArray or searchArray was changed
    __block BOOL needToReload = NO;
    //contains processed notification object, wich has to be removed at the end of iteration
    __block NSNotification *notificationToRemove = nil;
    __weak __block typeof(self) welf = self;
    /*
     Block which perform replacing of user's object
     in contactsArray(searchArray) with actual
     user's object, or remove user's object from array,
     depending on the validation with current type of sort
     ('All','Availiable', 'DnD', 'Away')
     See explanation for 'isValidForCurrentSortMenuPresenceStatus:'.
     */
    void (^updateContactObjectWithPresenceBlock)(QliqUser *, NSNotification *, NSMutableArray *, NSInteger) = ^(QliqUser *user, NSNotification *notification, NSMutableArray *array, NSInteger index)
    {
        PresenceStatus presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
        user.presenceStatus = presenceStatus;
        user.presenceMessage = notification.userInfo[@"presenceMessage"];
        if ([self isValidForCurrentSortMenuPresenceStatus:user.presenceStatus]) {
            DDLogSupport(@"Replace user with presence-CN, %@", welf.isSearching ? @"while searching" : @"not searching");
            if (index < array.count) {
                [array replaceObjectAtIndex:index withObject:user];
            } else {
                DDLogSupport(@"index more than array count,  - %lu, array.count - %lu", (long)index, (unsigned long)array.count);
            }
        } else {
            DDLogSupport(@"Remove user with presence-CN, %@", welf.isSearching ? @"while searching" : @"not searching");
            [array removeObjectAtIndex:index];
        }
        needToReload = YES;
        if (notification) {
            if (!notificationToRemove) {
                notificationToRemove = [notification copy];
            }
        } else {
            DDLogSupport(@"'nil' notification in 'updateContactObjectWithPresenceBlock'");
        }
    };
    
    // Block for determine the correspondence between presence-CN and contact object in searchArray
    void (^searchArrayEnumerationBlock)(id , NSNotification *, NSInteger, NSString *, BOOL *) = ^(id contact, NSNotification *notification, NSInteger idx, NSString *qliqId, BOOL *stopped){
        if ([contact isKindOfClass:[QliqUser class]]) {
            QliqUser *user = contact;
            /*
             if qliqId related to CN is equal to user object's qliqId &
             CN addressed not "isForMyself",
             update user object in searchArray
             */
            if ([user.qliqId isEqualToString:qliqId]) {
                updateContactObjectWithPresenceBlock(user, notification, welf.searchArray, idx);
                *stopped = YES;
            }
        } else if ([contact isKindOfClass:[Contact class]]) {
            Contact *searchItem = contact;
            /*
             if qliqId related to CN is equal to contact object's qliqId &
             CN addressed not "isForMyself",
             try to transform contact object to QliqUser object
             */
            if ([searchItem.qliqId isEqualToString:qliqId]) {
                id item = [[QliqAvatar sharedInstance] contactIsQliqUser:searchItem];
                if ([item isKindOfClass:[QliqUser class]]) {
                    QliqUser *user = item;
                    /*
                     if Qliq user for contact object exists,
                     update contact object in contactArray with user's object
                     */
                    updateContactObjectWithPresenceBlock(user, notification, welf.searchArray, idx);
                    *stopped = YES;
                }
            }
        }
    };
    
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        if (welf.selectedMenu == ContactMenuUsers || welf.selectedMenu == ContactMenuFavorites) {
            if (welf.contactsArray.count != 0) {
                // Enumeration of contactsArray for current sort type('All','Availiable', 'DnD', 'Away')
                [welf.contactsArray enumerateObjectsUsingBlock:^(id contact, NSUInteger idx, BOOL *stop) {
                    if ([contact isKindOfClass:[QliqUser class]])
                    {
                        QliqUser *user = contact;
                        /*
                         Check correspondence between presence-CN and
                         user object in contactsArray for each CN.
                         */
                        for (NSNotification *notification in presenceNotificationsArray) {
                            NSString *qliqId = notification.userInfo[@"qliqId"];
                            if ([user.qliqId isEqualToString:qliqId] && kPresenceCNForMySelf) {
                                /*
                                 if qliqId related to CN is equal to user object's qliqId &
                                 CN addressed not "isForMyself",
                                 update user object in contactArray
                                 */
                                updateContactObjectWithPresenceBlock(user, notification, welf.contactsArray, idx);
                                if (welf.isSearching && welf.searchArray.count != 0) {
                                    /*
                                     if currently controller searching & searchArray is not empty,
                                     check if searchArray contains contact object with qliqId equal to CN's qliqId
                                     */
                                    [welf.searchArray enumerateObjectsUsingBlock:^(id contact, NSUInteger idx, BOOL *stopped)
                                     {
                                         searchArrayEnumerationBlock(contact, notification, idx, qliqId, stopped);
                                     }];
                                }
                                break;
                            }
                        }
                    }
                    else if ([contact isKindOfClass:[Contact class]])
                    {
                        Contact *contactItem = contact;
                        /*
                         The checking correspondence between presence-CN and
                         contact object in contactsArray for each CN.
                         */
                        for (NSNotification *notification in presenceNotificationsArray) {
                            NSString *qliqId = notification.userInfo[@"qliqId"];
                            /*
                             if qliqId related to CN is equal to contact object's qliqId &
                             CN addressed not "isForMyself",
                             try to transform contact object to QliqUser object
                             */
                            if ([contactItem.qliqId isEqualToString:qliqId] && kPresenceCNForMySelf) {
                                id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contactItem];
                                if ([item isKindOfClass:[QliqUser class]]) {
                                    QliqUser *user = item;
                                    /*
                                     if Qliq user for contact oject exists,
                                     update contact object in contactArray with user's object
                                     */
                                    updateContactObjectWithPresenceBlock(user, notification, welf.contactsArray, idx);
                                    if (welf.isSearching && welf.searchArray.count != 0) {
                                        /*
                                         if currently controller is searching & searchArray is not empty,
                                         check if searchArray contains contact object with qliqId equal to CN's qliqId
                                         */
                                        [welf.searchArray enumerateObjectsUsingBlock:^(id contact, NSUInteger idx, BOOL *stopped)
                                         {
                                             searchArrayEnumerationBlock(contact, notification, idx, qliqId, stopped);
                                         }];
                                    }
                                }
                                break;
                            }
                        }
                    }
                    /*
                     if notification was processed on current iterration of enumeration,
                     remove it from CN's array
                     */
                    if (notificationToRemove) {
                        [presenceNotificationsArray removeObject:notificationToRemove];
                        notificationToRemove = nil;
                    }
                    /*
                     if CN's array becomes empty, no need to cotinue enumeration
                     */
                    if (presenceNotificationsArray.count == 0) {
                        *stop = YES;
                    }
                }];
                /*
                 if enumeration was end, but CN's array is not empty,
                 try to add user objects, which corresponding to notifications in presenceNotificationsArray,
                 to current contactsArray if them valid for current sorting type by presence
                 status.('All','Availiable', 'DnD', 'Away')
                 */
                if (presenceNotificationsArray.count != 0 && welf.contactListPopover.currentContactList != ContactListOnlyQliq && welf.contactListPopover.currentContactList != ContactListIphoneContact)
                {
                    NSMutableArray *addWithPresenceUsers = [NSMutableArray new];
                    for (NSNotification *notification in presenceNotificationsArray) {
                        NSString *qliqId = notification.userInfo[@"qliqId"];
                        PresenceStatus presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                        if([self isValidForCurrentSortMenuPresenceStatus:presenceStatus] && ![self arrayOfUsers:addWithPresenceUsers isAlreadyContainsUserWithId:qliqId]){
                            QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
                            if (user) {
                                [addWithPresenceUsers addObject:user];
                            }
                            DDLogSupport(@"Add user with presence-CN, %@", welf.isSearching ? @"while searching" : @"not searching");
                        }
                    }
                    [welf.contactsArray addObjectsFromArray:addWithPresenceUsers];
                    [welf.contactsArray sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"lastName"
                                                                                           ascending:YES
                                                                                            selector:@selector(localizedCaseInsensitiveCompare:)],
                                                               [[NSSortDescriptor alloc] initWithKey:@"firstName"
                                                                                           ascending:YES
                                                                                            selector:@selector(localizedCaseInsensitiveCompare:)]]];
                    
                    if(welf.isSearching) {
                        [welf startSearchWithText:welf.searchBar.text];
                    } else {
                        needToReload = YES;
                    }
                }
                //Update after all preparations if need it
                if (needToReload) {
                    [welf refreshControllerReloadFromDB:NO sort:YES];
                }
            }
        }
    }];
}

- (BOOL)arrayOfUsers:(NSMutableArray *)array isAlreadyContainsUserWithId:(NSString *)qliqId {
    BOOL isContainsUser = NO;
    
    if (array && array.count != 0) {
        for (Contact *contact in array) {
            if ([contact.qliqId isEqualToString:qliqId]) {
                isContainsUser = YES;
                break;
            }
        }
    }
    
    return isContainsUser;
}

/*
 Method which perform validation of received 'presenceStatus'
 regarding to current sorting type of ContactViewController
 ('All','Availiable', 'DnD', 'Away')
 */
- (BOOL)isValidForCurrentSortMenuPresenceStatus:(PresenceStatus)presenceStatus {
    BOOL valid = NO;
    
    if(self.selectedMenu != ContactMenuGroups) {
        
        switch (presenceStatus){
            case OfflinePresenceStatus:
            {
                if(self.contactListPopover.currentContactList == ContactListOnlyQliq || self.selectedMenu == ContactMenuFavorites)
                {
                    valid = YES;
                }
                break;
            }
            case OnlinePresenceStatus:
            {
                if(self.contactListPopover.currentContactList == ContactListOnlyQliq || self.contactListPopover.currentContactList == ContactListAvialable || self.selectedMenu == ContactMenuFavorites)
                {
                    valid = YES;
                }
                break;
            }
            case AwayPresenceStatus:
            {
                if(self.contactListPopover.currentContactList == ContactListOnlyQliq || self.contactListPopover.currentContactList == ContactListAway || self.selectedMenu == ContactMenuFavorites)
                {
                    valid = YES;
                }
                break;
            }
            case DoNotDisturbPresenceStatus:
            {
                if(self.contactListPopover.currentContactList == ContactListOnlyQliq || self.contactListPopover.currentContactList == ContactListDoNotDistrub || self.selectedMenu == ContactMenuFavorites)
                {
                    valid = YES;
                }
                break;
            }
            default:
            {
                valid = YES;
                break;
            }
        }
    }
    
    return valid;
}

#pragma mark - Setters -

- (void)setSelectedMenu:(ContactMenu)selectedMenu
{
    _selectedMenu = selectedMenu;
}

- (void)setSearchOperationDone:(BOOL)searchOperationDone {
    @synchronized (self) {
        _searchOperationDone = searchOperationDone;
    }
}

#pragma mark - Reloading of Controller -

- (void)refreshControllerReloadFromDB:(BOOL)reloadingFromDB sort:(BOOL)sort {
    
    if (self.selectedMenu != ContactMenuFavorites)
    {
        if (reloadingFromDB) {
            
            [self reloadContactsFromDB];
        }
        if (sort) {
            
            [self sortContactsFortableView];
        }
        
        if (!self.isHide) {
            __weak __block typeof(self) welf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                if(sort) {
                    self.dataSourceSortedArray = nil;
                    self.dataSourceSortedArray = [self.contactsSortedArray copy];
                }
                [welf.tableView reloadData];
            });
        } else {
            if(sort) {
                self.dataSourceSortedArray = nil;
                self.dataSourceSortedArray = [self.contactsSortedArray copy];
            }
        }
    }
    else
    {
        if (reloadingFromDB) {
            [self reloadContactsFromDB];
        }
        
        self.collectionViewFavorites.contactsArray = self.contactsArray;
        
        if (!self.isHide) {
            __weak __block typeof(self) welf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [welf.collectionViewFavorites.collectionView reloadData];
            });
        }
    }
}

#pragma mark * Data

- (void)prepareInformation
{
    switch (self.selectedMenu)
    {
        case ContactMenuUsers:      [self pressedSortOption:self.contactListPopover.currentContactList];    break;
        case ContactMenuGroups:     [self pressedGroupSortOption:self.groupListPopover.currentGroup];       break;
        case ContactMenuFavorites:  [self onFavoritesList:nil];                                             break;
        default: break;
    }
}

- (void)reloadContactsFromDB {
    DDLogSupport(@"Reload Contacts for selectedMenu %ld", (long)self.selectedMenu);
    
    switch (self.selectedMenu)
    {
        case ContactMenuUsers:
        case ContactMenuFavorites: {
            
            NSArray *contacts = [NSArray new];
            
            //GetData
            if ([self.contactGroup respondsToSelector:@selector(getOnlyContacts)]) {
                contacts = [self.contactGroup getOnlyContacts];
            }
            else {
                contacts = [self.contactGroup getVisibleContacts];
            }
            
            //GetNewContacts
            self.onlyNewContacts = [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"contactStatus = %d", ContactStatusNew]];
            
            self.contactsArray = nil;
            self.contactsArray = [contacts mutableCopy];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self markNewContactsAsViewed];
            });
            
            break;
        }
        case ContactMenuGroups: {
            GroupList selectedGroupType = self.groupListPopover.currentGroup;
            
            switch (selectedGroupType) {
                case GroupListQrgGroups: {
                    NSArray *contacts = [self.contactsProvider getUserGroups];
                    
                    self.contactsArray = [contacts mutableCopy];
                    
                    break;
                }
                case GroupListMyGroups: {
                    NSArray *contacts = [self.contactsProvider getUserLists];
                    
                    self.contactsArray = [contacts mutableCopy];
                    
                    break;
                }
                case GroupListOnCallGroups: {
                    DDLogSupport(@"ReloadOnCallGroup called");
                    NSArray *contacts = [self.contactsProvider getOnCallGroups];
                    
                    self.contactsArray = [contacts mutableCopy];
                    
                    break;
                }
                default:
                    break;
            }
        }
        default:
            break;
    }
}

- (void)sortContactsFortableView {
    if (self.selectedMenu == ContactMenuUsers || self.selectedMenu == ContactMenuGroups) {
        if (self.isSearching) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self sortContentForTableView:self.searchArray withFilterString:self.searchBar.text];
            });
        }
        else {
            [self sortContentForTableView:self.contactsArray withFilterString:nil];
        }
    }
}

- (void)sortContentForTableView:(NSMutableArray *)contactsArray withFilterString:(NSString *)filterString
{
    NSArray *recipients = [contactsArray copy];
    
    if (recipients.count > 0)
    {
        __block NSMutableArray *prepareSortedArray = [NSMutableArray new];
        __block NSString *sectionIndexTitle = @"";
        __block NSInteger firstIndexOfCurrentSection = 0;
        __block NSInteger firstIndexOfNextSection = 0;
        
        //copy array to section array
        void (^sortingBlock)(void) = ^{
            NSMutableArray *recipientsInSection = [NSMutableArray new];
            
            if (firstIndexOfCurrentSection <= firstIndexOfNextSection) {
                
                NSUInteger count = firstIndexOfNextSection - firstIndexOfCurrentSection;
                NSRange range = NSMakeRange(firstIndexOfCurrentSection, count);
                
                if (count == 0) {
                    recipientsInSection = [NSMutableArray arrayWithObject:[recipients objectAtIndex:firstIndexOfNextSection]];
                } else {
                    recipientsInSection = [NSMutableArray arrayWithArray:[recipients subarrayWithRange:range]];
                }
            } else {
                DDLogError(@"\n\n\n\nERROR firstSectionIndex > lastSectionIndex\n\n\n\n");
            }
            
            NSMutableDictionary *section = [@{kKeySectionTitle : sectionIndexTitle,
                                              kKeyRecipients : recipientsInSection} mutableCopy];
            
            [prepareSortedArray addObject:section];
            
        };
        
        __block NSString *sectionIndexTitleForObject = @"?";
        //Prepare for tableView
        [recipients enumerateObjectsUsingBlock:^(id contact, NSUInteger idx, BOOL *stop) {
            //Get sectionIndexTitle
            switch ([[QliqAvatar sharedInstance]returnRecipientType:contact]) {
                case RecipientTypeQliqGroup: {
                    
                    sectionIndexTitleForObject = @"GR";
                    
                    break;
                }
                case RecipientTypeOnCallGroup: {
                    
                    NSString *title = ((OnCallGroup *)contact).name;
                    NSInteger nessesaryLength = 1;
                    if (title.length >= nessesaryLength) {
                        sectionIndexTitleForObject = [[title substringToIndex:nessesaryLength] uppercaseString];
                    }
                    
                    break;
                }
                case RecipientTypePersonalGroup: {
                    
                    NSString *title = ((ContactList *)contact).name;
                    NSInteger nessesaryLength = 1;
                    if (title.length >= nessesaryLength) {
                        sectionIndexTitleForObject = [[title substringToIndex:nessesaryLength] uppercaseString];
                    }
                    
                    break;
                }
                case RecipientTypeQliqUser:
                case RecipientTypeContact: {
                    
                    QliqUser *user = contact;
                    
                    //If not searching
                    if (!filterString)
                    {
                        NSString *title = nil;
                        if (user.lastName && user.lastName.length > 0) {
                            title = user.lastName;
                        }
                        else if (user.firstName) {
                            title = user.firstName;
                        }
                        
                        NSInteger nessesaryLength = 1;
                        if (title.length >= nessesaryLength) {
                            sectionIndexTitleForObject = [[title substringToIndex:nessesaryLength] uppercaseString];
                        }
                    }
                    
                    //Prepare content by priority if searching
                    else {
                        
                        NSString *firstName = user.firstName ? user.firstName : @"";
                        NSString *lastName = user.lastName ? user.lastName : @"";
                        
                        if ([firstName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == 0 &&
                            [lastName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == 0) {
                            sectionIndexTitleForObject = @"0";
                        }
                        else if ([firstName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == 0) {
                            sectionIndexTitleForObject = @"2";
                        }
                        else if ([lastName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == 0) {
                            sectionIndexTitleForObject = @"1";
                        }
                        else {
                            sectionIndexTitleForObject = @"3";
                        }
                    }
                    break;
                }
                default: {
                    return;
                    break;
                }
            }
            
            //Add contact to Sorted content
            if (![sectionIndexTitleForObject isEqualToString:sectionIndexTitle]) {
                if (idx != 0) {
                    firstIndexOfNextSection = idx;
                    
                    sortingBlock();
                    
                    //reseting of next section range
                    firstIndexOfCurrentSection = idx ;
                    sectionIndexTitle = sectionIndexTitleForObject;
                } else {
                    firstIndexOfCurrentSection = idx;
                    sectionIndexTitle = sectionIndexTitleForObject;
                }
            }
            
            if ((recipients.count - 1) == idx) {
                firstIndexOfNextSection = recipients.count;
                sortingBlock();
            }
        }];
        
        if (filterString) {
            
            NSSortDescriptor *sortDeskriptorBySecurityTitle = [NSSortDescriptor sortDescriptorWithKey:kKeySectionTitle ascending:YES];
            prepareSortedArray = [[prepareSortedArray sortedArrayUsingDescriptors:@[sortDeskriptorBySecurityTitle]] mutableCopy];
            
        }
        
        self.contactsSortedArray = nil;
        self.contactsSortedArray = [prepareSortedArray mutableCopy];
        
    } else {
        self.contactsSortedArray = nil;
    }
}

- (void)replaceContactWithOrinaItem:(id)originalItem andReplacedItem:(id)replacedItem
{
    if (!originalItem || !replacedItem) {
        DDLogError(@"New Item is empty");
        return;
    }
    
    {
        NSInteger index = 0;
        if ([self.contactsArray containsObject:originalItem])
        {
            index = [self.contactsArray indexOfObject:originalItem];
            [self.contactsArray replaceObjectAtIndex:index withObject:replacedItem];
        }
    }
    
    if (self.isSearching)
    {
        NSInteger index = 0;
        if ([self.searchArray containsObject:originalItem])
        {
            index = [self.searchArray indexOfObject:originalItem];
            [self.searchArray replaceObjectAtIndex:index withObject:replacedItem];
        }
    }
}

- (id)tryToReplaceQliqUserWithContact:(id)contact {
    
    if ([contact isKindOfClass:[Contact class]])
    {
        Contact *contactItem = (Contact *)contact;
        if (contactItem.contactType == ContactTypeQliqUser)
        {
            QliqUserDBService *userDBService = [[QliqUserDBService alloc] init];
            QliqUser *qliqUser = [userDBService getUserMinInfoWithContactId:((Contact*)contact).contactId];
            if (qliqUser) {
                contact = qliqUser;
            }
        }
    }
    return contact;
}
#pragma mark * Search Methods

- (void)startSearchWithText:(NSString *)searchText
{
    [self.searchOperationsQueue cancelAllOperations];
    
    NSArray *tempSearchArray = [NSArray new];
    if (self.searchText.length < searchText.length && searchText.length != 1 && self.searchOperationDone) {
        
        tempSearchArray = [self.searchArray copy];
        
    } else {
        tempSearchArray = [self.contactsArray copy];
    }
    
    self.searchOperationDone = NO;
    
    self.searchText = searchText;
    
    SearchOperation *searchContactsOperation = [[SearchOperation alloc] initWithArray:tempSearchArray andSearchString:searchText withPrioritizedAlphabetically:self.isOnCallGroups];
    searchContactsOperation.delegate = self;
    searchContactsOperation.batchSize = 0;
    
    self.isSearching = searchContactsOperation.isPredicateCorrect;
    
    //for reloading tableView if searchBar become empty
    if (!self.isSearching) {
        __weak __block typeof(self) weakSelf = self;
        
        [self.refreshContactsOperationQueue addOperationWithBlock: ^{
            [weakSelf.searchArray removeAllObjects];
        }];
        
        [self refreshControllerReloadFromDB:NO sort:YES];
        
        dispatch_async_main(^{
            [weakSelf.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            //[weakSelf.searchBar resignFirstResponder];
        });
    } else {
        [self.searchOperationsQueue addOperation:searchContactsOperation];
    }
}

- (void)receivedResultFromSearch:(NSArray *)results
{
    [self.searchArray removeAllObjects];
    [self.searchArray addObjectsFromArray:results];
    
    self.searchOperationDone = YES;
    
    if (results.count == 0) {
        /*
         Searching if sychronization is not finished.
         Calls once with every filter(searchText) instance *see deeper by methods call stack*
         */
        __weak __block typeof(self) weakSelf = self;
        [SearchContactsService searchContactsIfNeeded:self.searchText count:30 completion:^(CompletitionStatus status, id result, NSError *error) {
            if (status == CompletitionStatusSuccess) {
                NSArray *users = (NSArray *)result;
                if (users.count > 0) {
                    [weakSelf.refreshContactsOperationQueue cancelAllOperations];
                    [weakSelf.refreshContactsOperationQueue addOperationWithBlock: ^{
                        [weakSelf reloadContactsFromDB];
                        [weakSelf startSearchWithText:weakSelf.searchText];
                    }];
                }
            }
        }];
    }
    
    [self refreshControllerReloadFromDB:NO sort:YES];
    dispatch_async_main(^{
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    });
    
}



#pragma mark - Public Methods -

- (void)prepareViewControllerForDisappearing
{
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
    
    [self hideKeyboard];
    
    [self showContactListPopover:NO];
    [self showGroupListPopover:NO];
}


#pragma mark - Private Methods -

#pragma mark * UI

- (void)hideAllPanels {
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
    
    [self hideKeyboard];
    
    [self showContactListPopover:NO];
    [self showGroupListPopover:NO];
}

- (void)setContactTypeButtonConstraintsWithSize:(CGSize)size
{
    float weightGroupView = size.width/3;
    float weightTwoLines = 2.f;
    self.groupsListWeightConstraint.constant = weightGroupView - weightTwoLines;
    self.groupsViewWeightConstraint.constant = weightGroupView;
}

- (void)hideKeyboard
{
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
    
    if ([self.collectionViewFavorites.searchBar isFirstResponder])
        [self.collectionViewFavorites.searchBar resignFirstResponder];
}

- (BOOL)headerViewIsShow
{
    BOOL isShow = self.headerView.frame.size.height > 0;
    return isShow;
}

- (void)setTableViewContentOffsetY:(CGFloat)offset withAnimation:(BOOL)animated
{
    if (animated)
    {
        __weak __typeof(self)welf = self;
        dispatch_async_main(^{
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                welf.tableView.contentOffset = CGPointMake(welf.tableView.contentOffset.x, offset);
                [welf.view layoutIfNeeded];
            } completion:nil];
        });
    }
    else
    {
        dispatch_async_main(^{
            self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, offset);
        });
    }
}

- (void)updateBannerFrameForSize:(CGSize)size {
    
    UILabel *lbl = nil;
    CGFloat height = 32.f;
    CGFloat maxY = CGRectGetMaxY(self.searchBar.frame);
    
    if (!self.bannerView) {
        self.bannerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, maxY, size.width, height)];
        [self.view addSubview:self.bannerView];
        lbl = [[UILabel alloc] initWithFrame:self.bannerView.bounds];
        lbl.tag = 123;
        lbl.textAlignment = NSTextAlignmentCenter;
        self.bannerView.backgroundColor = [UIColor whiteColor];
        [self.bannerView addSubview:lbl];
    } else {
        self.bannerView.frame = CGRectMake(0.f, maxY, size.width, height);
        lbl = [self.bannerView viewWithTag:123];
        lbl.frame = self.bannerView.bounds;
    }
    
    lbl.text = QliqLocalizedString(@"2427-TitleCheckingForUpdates");
    lbl.textColor = [UIColor grayColor];
    
    //Update Top tableView Constraint
    if (self.isOnCallGroups) {
        self.tableViewTopConstraint.constant = self.bannerView.frame.size.height;
    }
}

- (void)updateActivityView {
    
    if (!self.activityView) {
        self.activityView = [ACPDownloadView new];
    }
    else {
        [self.activityView setIndicatorStatus:ACPDownloadStatusNone];
    }
    
    CGFloat activityViewSize = 28.f;
    CGFloat positionX = self.bannerView.frame.size.width - activityViewSize - 20.f;
    CGFloat positionY = (self.bannerView.frame.size.height - activityViewSize)/2;
    [self.activityView setFrameOriginX:positionX];
    [self.activityView setFrameOriginY:positionY];
    [self.activityView setWidth:activityViewSize];
    [self.activityView setHeight:activityViewSize];
    
    self.activityView.hidden = NO;
    self.activityView.backgroundColor = [UIColor clearColor];
    self.activityView.clearsContextBeforeDrawing = YES;
    [self.activityView setTintColor:RGBa(24.f, 122.f, 181.f, 0.75)];
    
    ACPStaticImagesAlternative * myOwnImages = [ACPStaticImagesAlternative new];
    [myOwnImages setStrokeColor:[UIColor whiteColor]];
    [self.activityView setImages:myOwnImages];
    
    //Status by default.
    [self.activityView setIndicatorStatus:ACPDownloadStatusIndeterminate];
    [self.bannerView addSubview:self.activityView];
}

- (void)showOnCallUpdatesView:(BOOL)show {
    
    __weak __typeof(self)welf = self;
    VoidBlock hiddenOnCallUpdatesView = ^{
        [UIView animateWithDuration:0.15 delay:0.0f
             usingSpringWithDamping:0.05f
              initialSpringVelocity:0.1f
                            options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                welf.bannerView.hidden = YES;
                                //Update Top tableView Constraint
                                welf.tableViewTopConstraint.constant = 0.f;
                            } completion:nil];
    };
    
    self.bannerView.hidden = !show;
    self.isOnCallGroups = show;
    
    if (show && self.isOnCallGroups) {
        __weak __typeof(self)welf = self;
        [welf updateBannerFrameForSize:[UIScreen mainScreen].bounds.size];
        [welf updateActivityView];
        [[GetOnCallUpdatesService new] getWithCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {
            dispatch_async_main(^{
                UILabel *lbl = [welf.bannerView viewWithTag:123];
                float time = 0;
                if (status != CompletitionStatusSuccess || error != nil) {
                    lbl.text = QliqLocalizedString(@"2428-TitleCheckingForUpdatesFailed");
                    lbl.textColor = [UIColor redColor];
                } else {
                    time = 2.f;
                    lbl.text = QliqLocalizedString(@"2427-TitleCheckingForUpdates");
                    lbl.textColor = [UIColor grayColor];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    hiddenOnCallUpdatesView();
                });
            });
        }];
    }
    else {
        hiddenOnCallUpdatesView();
    }
}

///TODO: need add refreshing Invitations count after updating Invitations
- (void)showInvitationView:(BOOL)show withAnimation:(BOOL)animated
{
    //Invitations
    NSObject<InvitationGroup> *invitationsGroup = (NSObject<InvitationGroup> *)[self.contactsProvider getInvitationGroup];
    self.sendInvitationCountLabel.text      = [NSString stringWithFormat:@"(%ld)", (unsigned long)[invitationsGroup getSentInvitations].count];
    self.receovedInvitationCountLabel.text  = [NSString stringWithFormat:@"(%ld)", (unsigned long)[invitationsGroup getReceivedInvitations].count];
    
    BOOL isShowSend     = show; //[self.invitationsGroup getSentInvitations].count      ? show : NO;
    BOOL isShowReceived = show; //[self.invitationsGroup getReceivedInvitations].count  ? show : NO;
    
    [self showSendView:isShowSend withAnimation:animated];
    [self showReceivedView:isShowReceived withAnimation:animated];
    
    float constant = show ? self.sendInvitationsHeightConstraint.constant + self.receivedInvitationsHeight.constant : 0.f;
    
    if (constant != self.invitationsViewHeightConstraint.constant)
    {
        if (animated)
        {
            __weak __typeof(self)welf = self;
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                welf.invitationsViewHeightConstraint.constant = constant;
                welf.invitationsView.hidden = !show;
                [welf changeFrameHeaderView];
                [welf.view layoutIfNeeded];
            } completion:nil];
        }
        else
        {
            dispatch_async_main(^{
                self.invitationsViewHeightConstraint.constant = constant;
                [self changeFrameHeaderView];
                self.invitationsView.hidden = !show;
            });
        }
    }
}

- (void)showSendView:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kValueSearchBarHeight : 0.f;
    
    if (constant != self.sendInvitationsHeightConstraint.constant)
    {
        if (animated)
        {
            __weak __typeof(self)welf = self;
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                welf.sendInvitationsHeightConstraint.constant = constant;
                welf.sendInvitations.hidden = !show;
                
                [welf.view layoutIfNeeded];
            } completion:nil];
        }
        else
        {
            dispatch_async_main(^{
                self.sendInvitationsHeightConstraint.constant = constant;
                self.sendInvitations.hidden = !show;
            });
        }
    }
}

- (void)showReceivedView:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kValueSearchBarHeight : 0.f;
    
    if (constant != self.receivedInvitationsHeight.constant)
    {
        if (animated)
        {
            __weak __typeof(self)welf = self;
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                welf.receivedInvitationsHeight.constant = constant;
                welf.receivedInvitations.hidden = !show;
                [welf.view layoutIfNeeded];
                
            } completion:nil];
        }
        else
        {
            dispatch_async_main(^{
                self.receivedInvitationsHeight.constant = constant;
                self.receivedInvitations.hidden = !show;
            });
        }
    }
}

- (void)changeFrameHeaderView
{
    CGRect frame = self.headerView.frame;
    frame.size.height = self.sendInvitationsHeightConstraint.constant + self.receivedInvitationsHeight.constant;
    self.headerView.frame = frame;
    [self.tableView setTableHeaderView:self.headerView];
}

- (void)updateButtonsFor:(ContactMenu)section
{
    switch (section)
    {
        case ContactMenuUsers: {
            
            [self.contactListView setBackgroundColor:[UIColor whiteColor]];
            [self.groupListView setBackgroundColor:[UIColor clearColor]];
            [self.favoritesListView setBackgroundColor:[UIColor clearColor]];
            
            self.selectionView1.hidden = NO;
            self.selectionView2.hidden = YES;
            self.selectionView3.hidden = YES;
            break;
        }
        case ContactMenuGroups: {
            [self.contactListView setBackgroundColor:[UIColor clearColor]];
            [self.groupListView setBackgroundColor:[UIColor whiteColor]];
            [self.favoritesListView setBackgroundColor:[UIColor clearColor]];
            
            self.selectionView1.hidden = YES;
            self.selectionView2.hidden = NO;
            self.selectionView3.hidden = YES;
            break;
        }
        case ContactMenuFavorites: {
            [self.contactListView setBackgroundColor:[UIColor clearColor]];
            [self.groupListView setBackgroundColor:[UIColor clearColor]];
            [self.favoritesListView setBackgroundColor:[UIColor whiteColor]];
            
            self.selectionView1.hidden = YES;
            self.selectionView2.hidden = YES;
            self.selectionView3.hidden = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark * Update Users

- (void)markNewContactsAsViewed
{
    for (Contact *contact in self.onlyNewContacts)
    {
        if (contact.contactStatus == ContactStatusNew) {
            contact.contactStatus = ContactStatusDefault;
            
            [[ContactDBService sharedService] saveContact:contact];
        }
    }
}

#pragma mark * Utilities/Helpers

- (void)startConversationWithRecipients:(id)selectedContact isBroadcastConversation:(BOOL)isBroadcast
{
    RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:selectedContact];
    switch (type) {
        case RecipientTypeQliqGroup:
        case RecipientTypePersonalGroup:
        case RecipientTypeQliqUser: {
            
            Recipients *recipients = [[Recipients alloc] init];
            
            if (type == RecipientTypePersonalGroup) {
                
                NSArray *contacts = [(ContactList*)selectedContact getOnlyContacts];
                
                for (id contact in contacts) {
                    [recipients addRecipientsFromArray:[[QliqAvatar sharedInstance] contactIsQliqUser:contact]];
                }
            }
            else {
                [recipients addRecipient:selectedContact];
            }
            
            ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
            controller.isNewConversation = YES;
            controller.recipients = recipients;
            controller.isBroadcastConversation = isBroadcast;
            
            [self.navigationController pushViewController:controller animated:YES];
            
            break;
        }
        default: {
            break;
        }
    }
}

- (void)makeCall:(NSString *)phoneNumber
{
    if (!phoneNumber) {
        DDLogError(@"Phone number is empty");
        return;
    }
    
    NSString *phoneUrl = [NSString stringWithFormat:@"tel://%@", phoneNumber];
    phoneUrl = [phoneUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:phoneUrl];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)rotated:(NSNotification*)notification {
    
    /*If iPhoneX rotated*/
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        
        self.sendInvitationButton.contentEdgeInsets = UIEdgeInsetsMake(0, 50, 0, 0);
        self.receivedInvitationsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 50, 0, 0);
    }  else {
        
        self.sendInvitationButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        self.receivedInvitationsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    }
}

#pragma mark - Popover -

- (CGFloat)getHeightForContactListPopover:(BOOL)isShow
{
    CGFloat height = 0;
    
    if (isShow)
        height = self.contactListPopover.heightForRow * self.contactListPopover.content.count;
    
    return height;
}

- (CGFloat)getHeightForGroupListPopover:(BOOL)isShow
{
    CGFloat height = 0;
    
    if (isShow)
        height = self.groupListPopover.heightForRow * self.groupListPopover.content.count;
    
    return height;
}

- (void)menuWasChanged
{
    [self updateButtonsFor:self.selectedMenu];
    [self hideKeyboard];
    
    //Start Search
    [self startSearchWithText:self.searchBar.text];
}

- (void)showContactListPopover:(BOOL)show
{
    if ((show && self.contactListHeightConstraint.constant != 0) ||
        (!show && self.contactListHeightConstraint.constant == 0)) {
        return;
    }
    
    __weak __typeof(self)welf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            
            welf.contactListHeightConstraint.constant = [welf getHeightForContactListPopover:show];
            [welf.contactListPopover layoutIfNeeded];
        } completion:nil];
    });
}

- (void)showGroupListPopover:(BOOL)show
{
    if ((show && self.groupListHeightConstraint.constant != 0) ||
        (!show && self.groupListHeightConstraint.constant == 0)) {
        return;
    }
    
    __weak __typeof(self)welf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            
            welf.groupListHeightConstraint.constant = [welf getHeightForGroupListPopover:show];
            [welf.groupListPopover layoutIfNeeded];
        } completion:nil];
    });
}

#pragma mark - Actions -

#pragma mark * Top IBActions

- (IBAction)onContactsList:(UIButton*)sender {
    DDLogSupport(@"On Contact");
    
    
    [self showOnCallUpdatesView:NO];
    [self showGroupListPopover:NO];
    
    BOOL isPopoverHidden = self.contactListHeightConstraint.constant == 0.f;
    if (!isPopoverHidden)
        
        [self pressedSortOption:self.contactListPopover.currentContactList];
    
    [self showContactListPopover:isPopoverHidden];
    
    [self.view bringSubviewToFront:self.contactListPopover];
}

- (IBAction)onContactListArrowButton:(id)sender {
    [self showGroupListPopover:NO];
    
    BOOL isPopoverHidden = self.contactListHeightConstraint.constant == 0.f;
    [self showContactListPopover:isPopoverHidden];
    
    [self.view bringSubviewToFront:self.contactListPopover];
}

- (IBAction)onGroupsList:(UIButton*)sender {
    DDLogSupport(@"On Group");
    
    [self showContactListPopover:NO];
    
    BOOL isPopoverHidden = self.groupListHeightConstraint.constant == 0.f;
    if (!isPopoverHidden)
        [self pressedGroupSortOption:self.groupListPopover.currentGroup];
    
    [self showGroupListPopover:isPopoverHidden];
    
    [self.view bringSubviewToFront:self.groupListPopover];
}

- (IBAction)onGroupListArrowButton:(id)sender {
    
    [self showContactListPopover:NO];
    
    BOOL isPopoverHidden = self.groupListHeightConstraint.constant == 0.f;
    [self showGroupListPopover:isPopoverHidden];
    
    [self.view bringSubviewToFront:self.groupListPopover];
}

- (IBAction)onFavoritesList:(id)sender {
    DDLogSupport(@"On Favorites");
    
    self.selectedMenu = ContactMenuFavorites;
    
    [self showOnCallUpdatesView:NO];
    [self showContactListPopover:NO];
    [self showGroupListPopover:NO];
    
    self.contactGroup = self.favoritesContactGroup;
    [self reloadContactsFromDB];
    
    self.collectionViewFavorites.contactsArray = self.contactsArray;
    
    
    [self.collectionViewFavorites.collectionView reloadData];
    
    [self.view bringSubviewToFront:self.favoritesView];
    [self menuWasChanged];
    
}

#pragma mark * Header IBActions

- (IBAction)onSendInvitations:(id)sender
{
    InvitationListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([InvitationListViewController class])];
    controller.group = (NSObject<InvitationGroup> *)[self.contactsProvider getInvitationGroup];
    controller.invitationType = InvitationTypeSend;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onReceivedInvitations:(id)sender
{
    InvitationListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([InvitationListViewController class])];
    controller.group = (NSObject<InvitationGroup> *)[self.contactsProvider getInvitationGroup];
    controller.invitationType = InvitationTypeReceived;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark * Bottom IBActions

- (IBAction)onSearch:(id)sender
{
    FavoriteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FavoriteContactsViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
    controller = nil;
}

- (IBAction)onAddNewContact:(id)sender {
    
    SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
    if (!sSettings.personalContacts) {
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1031-TextAddNewContactOFF")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return;
    }
    
    NSString *deviceType = NSStringFromUIDeviceFamily([UIDevice currentDevice].deviceFamily);
    NSString *fromiPhoneContacts = QliqFormatLocalizedString1(@"1032-TextFrom{DeviceName}Contacts", deviceType);
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1029-TextInviteColleagues")
                                message:nil
                       withTitleButtons:@[fromiPhoneContacts,QliqLocalizedString(@"1033-TextInviteBy")]
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 switch (buttonIndex) {
                                     case 0: {
                                         SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
                                         controller.typeController = STForInviting;
                                         [self.navigationController pushViewController:controller animated:YES];
                                     }
                                         break;
                                     case 1:{
                                         InviteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([InviteContactsViewController class])];
                                         [self.navigationController pushViewController:controller animated:YES];
                                     }
                                     case 2:{
                                         [self dismissViewControllerAnimated:YES completion:nil];
                                     }
                                     default:
                                         break;
                                 }
                             }];
}

- (IBAction)onAddNewGroup:(id)sender
{
    CreateListViewController *addToListVC = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([CreateListViewController class])];
    addToListVC.isPersonalGroup = YES;
    [self.navigationController pushViewController:addToListVC animated:YES];
}

- (IBAction)onSettings:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowCurtainViewNotification object:nil];
}

#pragma mark * User Actions

///TODO: Need place inside Cell
- (void)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
    
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
            
            ContactTableCell *cell = (ContactTableCell*)sender.view;
            
            cell.optionsView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width -
                                                cell.optionsView.bounds.size.width -
                                                weakSelf.tableViewIndexSectionOffset,
                                                cell.optionsView.frame.origin.y,
                                                cell.optionsView.bounds.size.width,
                                                cell.optionsView.bounds.size.height);
            
            if (!isiPad) {
                cell.contactInfoView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width -
                                                        cell.optionsView.bounds.size.width * 2 -
                                                        weakSelf.tableViewIndexSectionOffset,
                                                        cell.optionsView.frame.origin.y,
                                                        cell.optionsView.bounds.size.width,
                                                        cell.optionsView.bounds.size.height);
            }
            [cell layoutIfNeeded];
        } completion:NULL];
    }
}

#pragma mark - Delegates -

#pragma mark * PopoverDelegate

- (void)pressedSortOption:(ContactLists)option
{
    self.selectedMenu = ContactMenuUsers;
    [self.view sendSubviewToBack:self.favoritesView];
    
    switch (option)
    {
        case ContactListAll: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getAllContactsGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2114-TitleAll") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = NO;
            break;
        }
            
        case ContactListAvialable: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getOnlineQliqUsersGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2115-TitleAvailable") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = NO;
            break;
        }
            
        case ContactListDoNotDistrub: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getDndQliqUsersGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2116-TitleDND") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = NO;
            break;
        }
            
        case ContactListAway: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getAwayQliqUsersGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2117-TitleAway") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = NO;
            break;
        }
            
        case ContactListOnlyQliq: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getOnlyQliqUsersGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2118-TitleMyQliqNetwork") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = YES;
            break;
        }
            
        case ContactListIphoneContact: {
            self.contactGroup = (NSObject<ContactGroup>*) [self.contactsProvider getIPhoneContactsGroup];
            [self.commonSectionButton setTitle:QliqLocalizedString(@"2119-TitleiPhoneContacts") forState:UIControlStateNormal];
            self.arrowContactListButton.hidden = YES;
            break;
        }
        default:
            break;
    }
    
    [self.refreshContactsOperationQueue cancelAllOperations];
    
    [self reloadContactsFromDB];
    [self showContactListPopover:NO];
    [self menuWasChanged];
}

- (void)pressedGroup:(GroupList)option {
    [self pressedGroupSortOption:option];
}

- (void)pressedGroupSortOption:(GroupList)option
{
    self.selectedMenu = ContactMenuGroups;
    [self.view sendSubviewToBack:self.favoritesView];
    
    switch (option) {
        case GroupListQrgGroups: {
            [self.groupsSectionButton setTitle:QliqLocalizedString(@"2120-TitleOrgGroups") forState:UIControlStateNormal];
            [self showOnCallUpdatesView:NO];
            break;
        }
        case GroupListMyGroups: {
            [self.groupsSectionButton setTitle:QliqLocalizedString(@"2121-TitleMyGroups") forState:UIControlStateNormal];
            [self showOnCallUpdatesView:NO];
            break;
        }
        case GroupListOnCallGroups: {
            
            BOOL isOnCallGroupsAllowed = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isOnCallGroupsAllowed;
            if (isOnCallGroupsAllowed) {
                
                [self.groupsSectionButton setTitle:QliqLocalizedString(@"2122-TitleOnCall") forState:UIControlStateNormal];
                
                dispatch_async_main(^{
                    
                    self.isOnCallGroups = YES;
                    [self showOnCallUpdatesView:YES];
                });
                
            } else {
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1220-TextOnCallGroupsNotAllowed")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex == 1) {
                                                 [self hideAllPanels];
                                             }
                                         }];
                
                return;
            }
            break;
        }
        default:
            break;
    }
    
    [self.refreshContactsOperationQueue cancelAllOperations];
    [self reloadContactsFromDB];
    
    [self showGroupListPopover:NO];
    [self menuWasChanged];
}

#pragma mark * UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 1;
    
    if (self.selectedMenu == ContactMenuUsers || self.selectedMenu == ContactMenuGroups) {
        count = self.dataSourceSortedArray.count;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    NSDictionary *infoForSection = self.dataSourceSortedArray[section];
    NSArray *recipients = infoForSection[kKeyRecipients];
    count = recipients.count;
    
    return count;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *indexes = [NSMutableArray new];
    
    NSMutableArray *copyDataSourceArray = [NSMutableArray new];
    
    copyDataSourceArray = self.dataSourceSortedArray;
    
    for (NSDictionary *infoForSection in copyDataSourceArray)
    {
        NSString *sectionIndexTitle = [infoForSection objectForKey:kKeySectionTitle];
        
        if (sectionIndexTitle) {
            if (![sectionIndexTitle isEqualToString:@"GR"] && !self.isSearching) {
                [indexes addObject:sectionIndexTitle];
            }
        }
    }
    
    self.tableViewIndexSectionOffset = indexes.count > 0 ? 15.f : 0.f;
    
    return indexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return  index;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactTableCellId];
    cell.delegate = self;
    [cell configureBackroundColor:RGBa(239.f, 239.f, 239.f, 1.f)];
    
    //Add GestureRecognizer
    {
        //Need placed this code inside cell class
        UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        [swipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
        [cell addGestureRecognizer:swipeRecognizerLeft];
        
        UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        [swipeRecognizerRight setDirection:UISwipeGestureRecognizerDirectionRight];
        [cell addGestureRecognizer:swipeRecognizerRight];
    }
    
    if (self.selectedMenu == ContactMenuUsers || self.selectedMenu == ContactMenuGroups) {
        
        NSMutableDictionary *section = [NSMutableDictionary new];
        section = self.dataSourceSortedArray[indexPath.section];
        NSMutableArray *recipientsInSection = [section valueForKey:kKeyRecipients];
        
        id contact = recipientsInSection[indexPath.row];
        
        //        Need check and Update if Contact is QliqUser
        if (self.selectedMenu != ContactMenuGroups) {
            id originalContact = contact;
            contact = [self tryToReplaceQliqUserWithContact:contact];
            
            if ([contact isKindOfClass:[QliqUser class]]) {
                [recipientsInSection replaceObjectAtIndex:indexPath.row withObject:contact];
                
                __weak __block typeof(self) welf = self;
                [self.refreshContactsOperationQueue addOperationWithBlock:^{
                    [welf replaceContactWithOrinaItem:originalContact andReplacedItem:contact];
                }];
            }
        }
        //        ConfigureCell
        [cell setCell:contact];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((self.selectedMenu == ContactMenuUsers || self.selectedMenu == ContactMenuGroups) && !self.isSelectedForDetailsContact)
    {
        self.isSelectedForDetailsContact = YES;
        
        NSDictionary *section = [NSDictionary new];
        
        @synchronized(self) {
            section = self.dataSourceSortedArray[indexPath.section];
        }
        NSArray *recipientsInSection = [section valueForKey:kKeyRecipients];
        
        id contact = recipientsInSection[indexPath.row];
        
        //Need check and get if contact is QliqUser
        if (self.selectedMenu == ContactMenuUsers) {
            contact = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
        }
        
        RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:contact];
        switch (type) {
            case RecipientTypeOnCallGroup: {
                
                DetailOnCallViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailOnCallViewController class])];
                controller.onCallGroup = (OnCallGroup *)contact;
                controller.backButtonTitleString = QliqLocalizedString(@"2122-TitleOnCall");
                
                [self.navigationController pushViewController:controller animated:YES];
                
                break;
            }
            case RecipientTypeQliqGroup:
            case RecipientTypePersonalGroup:
            case RecipientTypeQliqUser:
            case RecipientTypeContact: {
                
                DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
                
                if (type != RecipientTypeQliqUser) {
                    controller.contact = contact;
                } else {
                    controller.contact = [[QliqUserDBService sharedService] getUserForContact:contact];
                }
                
                
                if (type == RecipientTypeQliqGroup) {
                    controller.backButtonTitleString = QliqLocalizedString(@"2120-TitleOrgGroups");
                }
                else if (type == RecipientTypePersonalGroup) {
                    controller.backButtonTitleString = QliqLocalizedString(@"2121-TitleMyGroups");
                }
                
                [self.navigationController pushViewController:controller animated:YES];
                controller = nil;
                
                break;
            }
            default: {
                DDLogError(@"Did select unknownType");
                break;
            }
        }
    }
}

///TODO: need to review workflow UIScrollView Delegate methods
#pragma mark * UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    scrollView.scrollEnabled = YES;
    if (scrollView.contentOffset.y <= -40)
    {
        if (!scrollView.isDecelerating) {
            [self showInvitationView:YES withAnimation:YES];
        }
    }
    else if (scrollView.contentOffset.y > self.headerView.frame.size.height)
    {
        if ( (0 != self.invitationsViewHeightConstraint.constant) & !self.isBlockScrollViewDelegate)
        {
            CGFloat offset = 0 != self.invitationsViewHeightConstraint.constant ? self.invitationsView.frame.size.height : 0;
            
            [self setTableViewContentOffsetY:self.tableView.contentOffset.y - offset withAnimation:NO];
            [self showInvitationView:NO withAnimation:NO];
        }
    }
    
    if (scrollView.contentOffset.y <= 0)
        self.isBlockScrollViewDelegate = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    scrollView.scrollEnabled = YES;
    if (scrollView.contentOffset.y >= 20 && scrollView.contentOffset.y < self.headerView.frame.size.height)
    {
        if ([self headerViewIsShow])
        {
            [self showInvitationView:NO withAnimation:YES];
            
            [self setTableViewContentOffsetY:self.headerView.frame.size.height withAnimation:YES];
        }
    }
    else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < 20)
    {
        if ([self headerViewIsShow]){
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
    
    [self showContactListPopover:NO];
    [self showGroupListPopover:NO];
    
    [self hideKeyboard];
}

#pragma mark * UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self showContactListPopover:NO];
    [self showGroupListPopover:NO];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        if(!welf.searchBarWasEmpty || ![searchText isEqualToString:@""]){
            
            if ([searchText isEqualToString:@""]) {
                welf.searchBarWasEmpty = YES;
            } else {
                welf.searchBarWasEmpty = NO;
            }
            [welf startSearchWithText:searchText];
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        dispatch_async_main(^{
            [welf startSearchWithText:searchBar.text];
        });
    }];
}

#pragma mark * SearchContactsOperationDelegate

- (void)searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array {
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        [welf receivedResultFromSearch:array];
    }];
}

- (void)foundResultsPart:(NSArray *)results {
    __weak __block typeof(self) welf = self;
    [self.refreshContactsOperationQueue addOperationWithBlock: ^{
        [welf receivedResultFromSearch:results];
    }];
}

#pragma mark * ContactsCellDelegate

- (void)pressRightButton:(QliqGroup *)group {
    DDLogSupport(@"Pressed Join/Leave button");
    
    __block __weak typeof(self) weakSelf = self;
    
    void (^UpdateGroup)(NSString *) = ^(NSString *operation) {
        
        dispatch_async_main(^{
            [SVProgressHUD show];
        });
        
        NSMutableArray *groupArrayToSend = [[NSMutableArray alloc] init];
        NSMutableDictionary *groupToSendDict = [[NSMutableDictionary alloc] init];
        
        [groupToSendDict setObject:group.qliqId forKey:QLIQ_ID];
        [groupToSendDict setObject:operation forKey:OPERATION];
        
        [groupArrayToSend addObject:groupToSendDict];
        
        UpdateGroupMembershipService *updateGroupMembershipService = [[UpdateGroupMembershipService alloc] initWithGroups:groupArrayToSend];
        [updateGroupMembershipService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            dispatch_async_main(^{
                [SVProgressHUD dismiss];
            });
            
            if (status == CompletitionStatusSuccess) {
                DDLogSupport(@"Updated groups with join/leave status");
                
                NSString *successMessage;
                BOOL belongs = NO;
                if([operation isEqualToString:@"join"])
                {
                    belongs = YES;
                    
                    successMessage = [NSString stringWithFormat:NSLocalizedString(@"1200-TextSuccessfullyJoined{GroupName}", @"Successfully joined \n{Group Name}"), group.name];
                }
                else if([operation isEqualToString:@"leave"])
                {
                    belongs = NO;
                    
                    successMessage = [NSString stringWithFormat:NSLocalizedString(@"1201-TextSuccessfullyLeft{GroupName}", @"Successfully left \n{Group Name}"), group.name];
                }
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1202-TextInfo")
                                            message:successMessage
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
                
                /**
                 *  Update TableView with changed belongs group
                 */
                if (weakSelf.selectedMenu == ContactMenuGroups) {
                    
                    [self.refreshContactsOperationQueue addOperationWithBlock:^{
                        
                        if (weakSelf.contactsArray.count != 0) {
                            for (NSUInteger index = 0; index < weakSelf.contactsArray.count; index++)
                            {
                                
                                QliqGroup *groupLocal = [weakSelf.contactsArray objectAtIndex:index];
                                
                                if ([group.qliqId isEqualToString:groupLocal.qliqId]) {
                                    
                                    groupLocal.belongs = belongs;
                                    [weakSelf.contactsArray replaceObjectAtIndex:index withObject:groupLocal];
                                    
                                    break;
                                }
                            }
                        }
                        
                        if (weakSelf.isSearching) {
                            if (weakSelf.searchArray.count == 0) {
                                for (NSUInteger index = 0; index < weakSelf.searchArray.count; index++)
                                {
                                    QliqGroup *groupLocal = [weakSelf.searchArray objectAtIndex:index];
                                    
                                    if ([group.qliqId isEqualToString:groupLocal.qliqId]) {
                                        
                                        groupLocal.belongs = belongs;
                                        [weakSelf.searchArray replaceObjectAtIndex:index withObject:groupLocal];
                                        
                                        break;
                                    }
                                }
                            }
                        }
                        
                        [weakSelf refreshControllerReloadFromDB:NO sort:NO];
                    }];
                }
            }
            else if (status == CompletitionStatusError) {
                DDLogError(@"Error updateding groups with join/leave status: %@",error);
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                            message:[error localizedDescription]
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:nil];
            }
        }];
    };
    
    if (group.belongs) {
        [AlertController showAlertWithTitle:nil
                                    message:QliqFormatLocalizedString1(@"1210-TextLeave{QliqGroup}Description", group.name)
                                buttonTitle:QliqLocalizedString(@"48-ButtonLeave")
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex == 0) {
                                         UpdateGroup(@"leave");
                                     }
                                 }];
    } else {
        [AlertController showAlertWithTitle:nil
                                    message:QliqFormatLocalizedString1(@"1211-TextJoin{QliqGroup}Description", group.name)
                                buttonTitle:QliqLocalizedString(@"47-ButtonJoin")
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex == 0) {
                                         UpdateGroup(@"join");
                                     }
                                 }];
    }
}

- (void)pressMessageButton:(id)contact {
    
    BOOL isGroup = NO;
    
    if ([contact isKindOfClass:[QliqGroup class]] || [contact isKindOfClass:[ContactList class]])
        isGroup = YES;
    
    NSString *message = isGroup ? QliqLocalizedString(@"1040-TextOpenConversationWithGroup") : QliqLocalizedString(@"1041-TextOpenConversationWithUser");
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1039-TextMessage")
                                message:message
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     
                                     DDLogSupport(@"Pressed Message Contact Button");
                                     
                                     [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
                                     
                                     if (!contact) {
                                         DDLogSupport(@"Try start conversation with empty contact");
                                         return;
                                     }
                                     
                                     switch ([[QliqAvatar sharedInstance]returnRecipientType:contact]) {
                                         case RecipientTypeQliqGroup: {
                                             
                                             __block __weak typeof(self) weakSelf = self;
                                             [AlertController showAlertWithTitle:QliqLocalizedString(@"1035-TextChooseConversationType")
                                                                         message:QliqLocalizedString(@"1036-TextConversationsDescription")
                                                                withTitleButtons:@[QliqLocalizedString(@"16-ButtonConversationGroup"), QliqLocalizedString(@"17-ButtonConversationBroadcast")]
                                                               cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                                      completion:^(NSUInteger buttonIndex) {
                                                                          switch (buttonIndex) {
                                                                              case 0: {
                                                                                  [weakSelf startConversationWithRecipients:contact isBroadcastConversation:NO];
                                                                              }
                                                                                  break;
                                                                              case 1: {
                                                                                  [weakSelf startConversationWithRecipients:contact isBroadcastConversation:YES];
                                                                              }
                                                                                  break;
                                                                              case 2:
                                                                                  break;
                                                                                  
                                                                              default:
                                                                                  break;
                                                                          }
                                                                      }];
                                             break;
                                         }
                                         case RecipientTypePersonalGroup: {
                                             
                                             ///TODO:Need to implement start Group/Broadcast Conversation with Personal Group
                                             //            [self startConversationWithRecipients:contact isBroadcastConversation:NO];
                                             
                                             break;
                                         }
                                         case RecipientTypeQliqUser: {
                                             __block __weak typeof(self) weakSelf = self;
                                             [Presence askForwardingIfNeededForRecipient:(QliqUser *)contact completeBlock:^(id<Recipient> selectedRecipient) {
                                                 
                                                 if ([selectedRecipient isRecipientEnabled]) {
                                                     [weakSelf startConversationWithRecipients:selectedRecipient isBroadcastConversation:NO];
                                                 } else {
                                                     [AlertController showAlertWithTitle:nil
                                                                                 message:QliqLocalizedString(@"1037-TextContactNotactivatedQliqAccount")
                                                                             buttonTitle:QliqLocalizedString(@"10-ButtonSend")
                                                                       cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:^(NSUInteger buttonIndex) {
                                                                           if (buttonIndex == 0) {
                                                                               [weakSelf startConversationWithRecipients:selectedRecipient isBroadcastConversation:NO];
                                                                           }
                                                                       }];
                                                 }
                                             }];
                                             
                                             break;
                                         }
                                         default: {
                                             DDLogError(@"Can't chat with unknown type");
                                             break;
                                         }
                                     }
                                 }
                             }];
}

- (void)pressPhoneButton:(id)contact {
    DDLogSupport(@"Pressed Phone Contact Button");
    
    [AlertController showAlertWithTitle:NSLocalizedString(@"1042-TextCall", @"Call phone number")
                                message:NSLocalizedString(@"1043-TextMakeCall", @"Make a call phone number")
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     
                                     [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
                                     
                                     if (!contact) {
                                         DDLogError(@"Try call to empty contact");
                                         return;
                                     }
                                     
                                     RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:contact];
                                     switch (type) {
                                         case RecipientTypeQliqUser:
                                         case RecipientTypeContact: {
                                             
                                             QliqUser *user = contact;
                                             
                                             if (type == RecipientTypeQliqUser) {
                                                 if(![user isActive]) {
                                                     DDLogSupport(@"Cannot make a call because this user did not activate their qliq account yet");
                                                     
                                                     [AlertController showAlertWithTitle:nil
                                                                                 message:QliqLocalizedString(@"1038-TextCannotMakeCall")
                                                                             buttonTitle:nil
                                                                       cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                              completion:nil];
                                                     return;
                                                 }
                                             }
                                             
                                             //TODO: Think need rework this code. Should add choose phone number like for Chat
                                             if (user.mobile.length || user.phone.length) {
                                                 [self makeCall:[user mobile] ? [user mobile] : [user phone]];
                                             }
                                             else {
                                                 [[[QliqSip instance] voiceCallsController] callUser:contact];
                                             }
                                             
                                             break;
                                         }
                                         default: {
                                             DDLogError(@"Can't call to unknown type");
                                             break;
                                         }
                                     }
                                 }
                             }];
}

- (void)pressFavoriteButton:(id)contact {
    DDLogSupport(@"Pressed Favorite Contact Button");
    
    [AlertController showAlertWithTitle:NSLocalizedString(@"1044-TextFavorites", @"Favorites  contacts")
                                message:QliqLocalizedString(@"1045-TextAddToFavorites")
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     
                                     [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
                                     
                                     if (!contact) {
                                         DDLogError(@"Try add to favorites empty contact");
                                         return;
                                     }
                                     
                                     if ([contact isKindOfClass:[QliqUser class]]) {
                                         [self.favoritesContactGroup addContact:contact];
                                     } else {
                                         DDLogError(@"Try add to favorites non Qliq User");
                                     }
                                 }
                             }];
}

- (void)pressDeleteButton:(id)contact{
    DDLogSupport(@"Pressed Delete Contact Button");
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1046-TextDelete")
                                message:QliqLocalizedString(@"1047-TextAskDeleteContact")
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     
                                     
                                     [self.tableView.visibleCells makeObjectsPerformSelector:@selector(hideOptions)];
                                     
                                     if (!contact) {
                                         DDLogError(@"Try delete empty contact");
                                         return;
                                     }
                                     
                                     RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:contact];
                                     switch (type) {
                                         case RecipientTypeQliqUser:
                                         case RecipientTypeContact:
                                         case RecipientTypePersonalGroup: {
                                             
                                             @synchronized(self) {
                                                 [self.contactsArray removeObject:contact];
                                                 [self.searchArray removeObject:contact];
                                             }
                                             
                                             if (type == RecipientTypeQliqUser) {
                                                 [[QliqUserDBService sharedService] setUserDeleted:contact];
                                             }
                                             else if (type == RecipientTypeContact) {
                                                 [[ContactDBService sharedService] deleteContact:contact];
                                             }
                                             else if (type == RecipientTypePersonalGroup) {
                                                 [[QliqListService sharedService] removeList:contact];
                                             }
                                             
                                             [self refreshControllerReloadFromDB:NO sort:YES];
                                             
                                             break;
                                         }
                                         default: {
                                             DDLogError(@"Can't delete unknown type");
                                             break;
                                         }
                                     }
                                 }
                             }];
}

@end

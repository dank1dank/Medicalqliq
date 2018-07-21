//
//  RecentsViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "RecentsViewController.h"
#import "RecentTableViewCell.h"

#import <MobileCoreServices/MobileCoreServices.h>

//ViewControllers
#import "MainViewController.h"
#import "ConversationViewController.h"
#import "ConversationsViewController.h"
#import "ConversationsListViewController.h"
#import "FavoriteContactsViewController.h"
#import "MainSettingsViewController.h"
#import "InviteContactsViewController.h"
#import "SelectContactsViewController.h"
#import "SettingsSoundViewController.h"
#import "ProfileViewController.h"
#import "FeedBackSupportViewController.h"

//Helpers
#import "ConversationDBService.h"
#import "ChatMessagesProvider.h"
#import "ChatMessageService.h"
#import "QliqConnectModule.h"
#import "QliqSip.h"
#import "UIDevice-Hardware.h"
#import "Login.h"
#import "QliqUserNotifications.h"
#import "NSArray+RangeCheck.h"
#import "NSString+Filesize.h"
#import "AlertController.h"

//Objects
#import "Conversation.h"
#import "MessageAttachment.h"

#import "ResizeBadge.h"

#import <AVFoundation/AVFoundation.h>

#define kValueSearchBarHeight 44.f
#define kButtonContentMargin  5.f
#define kUnreadBadgeLeading  2.f
#define kMinBadgeWidth 14.f
#define kTabBarBottomConstraint -35.f
#define kTabBarBottomConstraintDefault 0.f
#define kContainerTopConstraint 7.f
#define kContainerTopConstraintDefault 0.f

typedef NS_ENUM(NSInteger, RecentsMenu) {
    RecentsMenuConversations,
    RecentsMenuCareChannels
};

@interface RecentsViewController ()
<
UISearchBarDelegate,
UITableViewDataSource,
UITableViewDelegate,
UIScrollViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
RecentCellDelegate
>

/** IBOutlet */
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *recentsTopBarMenu;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *additionalView; //View for review Archived Conversationz

@property (weak, nonatomic) IBOutlet UIButton *archivedConversationsButton;
@property (weak, nonatomic) IBOutlet UILabel *archivedLabel;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

/*
 Conversations menu
 */
@property (weak, nonatomic) IBOutlet UIView *conversationsBarItemView;
@property (weak, nonatomic) IBOutlet UIView *conversationsSelectionView;
@property (weak, nonatomic) IBOutlet UIButton *conversationsButton;
@property (weak, nonatomic) IBOutlet UIView *conversationsContentButtonView;
@property (weak, nonatomic) IBOutlet UILabel *conversationsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversationsUnreadBadge;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *conversationsTitleLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *conversationsUnreadBadgeWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *conversationsUnreadBadgeLeading;

/*
 Care channels menu
 */
@property (weak, nonatomic) IBOutlet UIView *careChannelsBarItemView;
@property (weak, nonatomic) IBOutlet UIView *careChannelsSelectionView;
@property (weak, nonatomic) IBOutlet UIButton *careChannelsButton;
@property (weak, nonatomic) IBOutlet UIView *careChannelsContentButtonView;
@property (weak, nonatomic) IBOutlet UILabel *careChannelsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *careChannelsUnreadBadge;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *careChannelsTitleLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *careChannelsUnreadBadgeWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *careChannelsUnreadBadgeLeading;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *additionalViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBarHeightConstraint;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarBackgroundBottomConstraint;

/** UI */
@property (nonatomic, strong) UIAlertView_Blocks *connectionErrorAlert;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL isForegroundView;


/** Data */
@property (nonatomic, assign) BOOL notReadOnce;

@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL isNewConversation;

@property (nonatomic, assign) int registration5XXErrorCount;

@property (nonatomic, strong) Conversation *selectedForOptionsConversation;
@property (nonatomic, assign) BOOL *isSelectedForChatConversation;

@property (nonatomic, assign) BOOL needNotifyAboutPushMessage;

//presorted array
@property (atomic, strong) NSMutableArray *conversationsArray;
@property (atomic, strong) NSMutableArray *careChannelsArray;
@property (atomic, strong) NSMutableArray *searchConversationsArray;

@property (nonatomic, assign) RecentsMenu selectedMenu;
@property (nonatomic, assign) NSInteger *archivedLabelCount;
@property (nonatomic, assign) NSInteger *dbConversationsCount;

/** Refresh Queue */
@property (nonatomic, strong) NSOperationQueue *refreshRecentsOperationQueue;

@property (nonatomic, assign) CGFloat conversationsTitleWidth;
@property (nonatomic, assign) CGFloat careChannelsTitleWidth;

@end

@implementation RecentsViewController

#pragma mark - Life Cycle -

- (void)dealloc
{
    //Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.refreshRecentsOperationQueue cancelAllOperations];
    [self.refreshRecentsOperationQueue waitUntilAllOperationsAreFinished];
    self.refreshRecentsOperationQueue = nil;
 
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.tableView = nil;
    self.headerView = nil;
    self.additionalView = nil;
    self.archivedLabel = nil;
    self.searchBar = nil;
    self.archivedConversationsButton = nil;
    self.settingsButton = nil;
    self.searchBarHeightConstraint = nil;
    self.additionalViewHeightConstraint = nil;
    self.connectionErrorAlert = nil;
    self.refreshControl = nil;
    self.selectedForOptionsConversation = nil;
    self.conversationsArray = nil;
    self.careChannelsArray = nil;
    self.searchConversationsArray = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {}
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //    /*Change constraint for iPhone X*/
    isIPhoneX {
        self.containerTopConstraint.constant = kContainerTopConstraint;
        self.tabBarBackgroundBottomConstraint.constant = kTabBarBottomConstraint;
        [self.view layoutIfNeeded];
    }
    
    self.selectedMenu = RecentsMenuConversations;
    [self configureDefaultText];
    
    //Badges
    {
        //Configure textTitleLabel in contentButtonView
        [self.conversationsTitleLabel setUserInteractionEnabled:YES];
        [self.careChannelsTitleLabel setUserInteractionEnabled:YES];
        
        __weak __block typeof(self) welf = self;
        [self setTitleDefaultText:QliqLocalizedString(@"3023-TitleConversations") forTitleLabel:self.conversationsTitleLabel calculateLabelWidthWithCompletion:^(CGFloat calculatedWidth) {
            welf.conversationsTitleWidth = calculatedWidth;
        }];
        
        [self setTitleDefaultText:QliqLocalizedString(@"3024-TitleCareChannels") forTitleLabel:self.careChannelsTitleLabel calculateLabelWidthWithCompletion:^(CGFloat calculatedWidth) {
            welf.careChannelsTitleWidth = calculatedWidth;
        }];
        
        //Configure titleLabels width Constraint
        self.conversationsTitleLabelWidth.constant = self.conversationsTitleWidth;
        self.careChannelsTitleLabelWidth.constant = self.careChannelsTitleWidth;
        
        //Configure UnreadBadge constraints
        //ConversationsUnreadBadge
        self.conversationsUnreadBadgeLeading.constant = 0.f;
        self.conversationsUnreadBadgeWidth.constant = 0.f;
        //CareChannelsUnreadBadge
        self.careChannelsUnreadBadgeLeading.constant = 0.f;
        self.careChannelsUnreadBadgeWidth.constant = 0.f;
        
        //GestureRecognizer for titleLabel in ContentButtonView
        UITapGestureRecognizer *tapGestureConversationsTitle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureConversationsTitle:)];
        UITapGestureRecognizer *tapGestureCareChannelsTitle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureCareChannelsTitle:)];
        
        [self.conversationsTitleLabel addGestureRecognizer:tapGestureConversationsTitle];
        [self.careChannelsTitleLabel addGestureRecognizer:tapGestureCareChannelsTitle];
        
        self.conversationsUnreadBadge.layer.cornerRadius = 7.f;
        self.careChannelsUnreadBadge.layer.cornerRadius = 7.f;
    }
    
    self.needNotifyAboutPushMessage = NO;
    
    self.conversationsArray = [[NSMutableArray alloc] init];
    self.careChannelsArray = [[NSMutableArray alloc] init];
    self.searchConversationsArray = [[NSMutableArray alloc] init];
    
    
    //SearchBar
    self.searchBarHeightConstraint.constant = 0.f;
    self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
    self.searchBar.delegate = self;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
    self.searchBar.spellCheckingType = UITextSpellCheckingTypeYes;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
    
    //HeaderView
    [self showAdditionalView:NO withAnimation:NO];
    
    //initializing refreshQueue
    
    self.refreshRecentsOperationQueue = [[NSOperationQueue alloc] init];
    self.refreshRecentsOperationQueue.name = @"com.qliq.recents.refreshOperationQueue";
    self.refreshRecentsOperationQueue.maxConcurrentOperationCount = 1;
    
    //add refresh controil to the table view
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    //Registered 'nib' for tableViewCell
    UINib *nib = [UINib nibWithNibName:@"RecentTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"RecentTableViewCell_ID"];
    
    DDLogSupport(@"Conversation Refresh Called from viewDidLoad during initialization");
    [self pressedSortOption];
    
    if (appDelegate.unProcessedRemoteNotifcations > 0) {
        DDLogSupport(@"Checking for Messages ProgressHUD. Started");
        [SVProgressHUD showWithStatus:NSLocalizedString(@"1903-TextCheckingForMessages", nil)];
    }
    
    //Notifications
    [self addGeneralNotifications];
    [self addCommonConversationsNotifications];
    [self configureTopBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
        /*Change constraint for iPhone X*/
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    /*
     Need for resolving issue of conversation double opening
     */
    self.isSelectedForChatConversation = NO;
    
    self.isForegroundView = YES;
    
    if (self.containerSelected && self.isForegroundView) {
        [self reloadTableView:YES];
    }
    
    //Check for lauching the app with Notification
    [self checkForLaunchingWithNotification];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self managedAlerts];
    
    //Notify QliqUserNotifications object about RecentsViewController appearing
    if ([QliqUserNotifications getInstance].delayStartPoint > 0.0)
        [[NSNotificationCenter defaultCenter] postNotificationName:OpenConversationAfterLoginNotification object:self.navigationController];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.isForegroundView = NO;
    
    /*Change constraint for iPhone X*/
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    [self skipProgressHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
    if (self.containerSelected && self.isForegroundView) {
        performBlockInMainThread(^{
            __block __weak typeof(self) weakSelf = self;
            [weakSelf.tableView reloadData];
            
        });
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)tapGestureConversationsTitle:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self onConversationsMenu:self.conversationsButton];
}

- (void)tapGestureCareChannelsTitle:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self onCareChannelsMenu:self.careChannelsButton];
}

#pragma mark - SVProgressHUD -

- (void)showProgressHUD
{
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        if (![SVProgressHUD isVisible] && welf.containerSelected && welf.isForegroundView)
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    });
}

- (void)scheduleProgressHUD
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showProgressHUD) object:nil];
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        if (![SVProgressHUD isVisible] && welf.containerSelected && welf.isForegroundView)
            [welf performSelector:@selector(showProgressHUD) withObject:nil afterDelay:0.4];
    });
}

- (void)skipProgressHUD
{
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible])
            [SVProgressHUD dismiss];
        else
            [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(showProgressHUD) object:nil];
    });
}

#pragma mark - Preload Configuting UI -

- (void)configureDefaultText {
    
    switch (self.selectedMenu)
    {
        case RecentsMenuConversations: {
            
            [self.archivedConversationsButton setTitle:QliqLocalizedString(@"2106-TitleArchivedConversations") forState:UIControlStateNormal];
            break;
        }
        case RecentsMenuCareChannels: {
            
            [self.archivedConversationsButton setTitle:QliqLocalizedString(@"2326-TitleArchivedCareChannels") forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
}

- (void)setTitleDefaultText:(NSString *)text
              forTitleLabel:(UILabel *)titleLabel
calculateLabelWidthWithCompletion:(void(^)(CGFloat calculatedWidth))completion
{
    titleLabel.text = text;
    CGSize suggestedSize = [titleLabel.text sizeWithAttributes:@{NSFontAttributeName:titleLabel.font}];
    
    if (completion)
        completion(suggestedSize.width + 1.f);
}

#pragma mark - Table View -

#pragma mark -- Full reload of table view for selected menu --

- (void)pressedSortOption
{
    if (isCurrentThreadMain())
        [self scheduleProgressHUD];
    
    __weak __block typeof(self) welf = self;
    performBlockInMainThread(^{
        [welf updateTopBarButtonsFor:self.selectedMenu];
        [welf configureDefaultText];
    });

    [self reloadObjectsFromDB];
    [self reloadTableView:NO];
    
    performBlockInMainThreadSync(^{
        [welf skipProgressHUD];
    });
    
}

#pragma mark -- Data --

#pragma mark * Global Data Reload

- (void)reloadObjectsFromDB {
    
    switch (self.selectedMenu) {
        case RecentsMenuCareChannels:
        {
            self.archivedLabelCount = [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:YES careChannel:YES];
            [self loadCareChannels];
            break;
        }
        case RecentsMenuConversations:
        {
            self.archivedLabelCount = [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:YES careChannel:NO];
            [self loadConversations];
            break;
        }
        default:
            break;
    }
}

- (NSArray *)loadCareChannels {
    
    @synchronized(self) {
        
        if (self.careChannelsArray.count == 0) {
            DDLogSupport(@"Start Load Care Channels");
            self.careChannelsArray = [[ConversationDBService sharedService] getConversationsForRecentsViewArchived:NO careChannel:YES];
        }
        DDLogSupport(@"careChannelsArray: %lu", (unsigned long)self.careChannelsArray.count);
        return self.careChannelsArray;
    }
}

#define LOO_MEASURE_TIME(__message) \
for (CFAbsoluteTime startTime##__LINE__ = CFAbsoluteTimeGetCurrent(), endTime##__LINE__ = 0.0; endTime##__LINE__ == 0.0; \
NSLog(@"'%@' took %.6fs", (__message), (endTime##__LINE__ = CFAbsoluteTimeGetCurrent()) - startTime##__LINE__))

/**
 Get All Conversation From DB
 */
- (NSArray *)loadConversations {
    
    @synchronized(self) {
        if (self.conversationsArray.count == 0) {
            DDLogSupport(@"Start Load Conversations");
            NSUInteger count = 0;
            LOO_MEASURE_TIME(@"get conversations new code") {
                self.conversationsArray = [[ConversationDBService sharedService] getConversationsForRecentsViewArchived:NO careChannel:NO];
            }
            LOO_MEASURE_TIME(@"count conversations new code") {
                // TODO: Remove. New code but for performance test only
                count = [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:NO careChannel:NO];
            }
            // TODO: remove once this code is tested by testers
            DDLogSupport(@"Loaded %d conversations in array, count from db: %d", (int)self.conversationsArray.count, (int)count);
        }
        return self.conversationsArray;
    }
}

#pragma mark * Single Data Reload (Only for common conversations)

- (void)updateConversationsArrayWithConversation:(Conversation *)conversation
{
    if (!conversation) {
        DDLogError(@"UpdateConversationsArrayWithConversation called with nil conversation arg");
        return;
    }
    
    conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:conversation.conversationId]];
    
    if (conversation) {
        DDLogSupport(@"Conversation Refresh Called from updateConversationsArrayWithConversation");
        
        if (conversation.lastMsg == nil) {
            ChatMessage *lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:conversation.conversationId];
            conversation.lastMsg = lastMessage.text;
            conversation.lastUpdated = lastMessage.createdAt;
        }
        
        NSIndexPath *allIndexPath = [self updateConversationsIsSearchArray:NO withConversation:conversation];
        if (allIndexPath == nil && !conversation.deleted && !conversation.archived) {
            
            self.isNewConversation = YES;
            
            if (!conversation.isCareChannel) {
                NSArray *conversations = [self.conversationsArray arrayByAddingObject:conversation];
                [self.conversationsArray removeAllObjects];
                [self.conversationsArray addObjectsFromArray:[conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
            }
            else {
                NSArray *conversations = [self.careChannelsArray arrayByAddingObject:conversation];
                [self.careChannelsArray removeAllObjects];
                [self.careChannelsArray addObjectsFromArray:[conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
            }
            /*
            NSArray *conversations = [self.conversationsArray arrayByAddingObject:conversation];
            self.isNewConversation = YES;
            [self.conversationsArray removeAllObjects];
            [self.conversationsArray addObjectsFromArray:[conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
             */
        }
        
        if (self.isSearching) {
            NSIndexPath *searchIndexPath = [self updateConversationsIsSearchArray:YES withConversation:conversation];
            if (searchIndexPath == nil && !conversation.deleted && !conversation.archived) {
                self.isNewConversation = YES;
                NSArray *conversations = [self.searchConversationsArray arrayByAddingObject:conversation];
                [self.searchConversationsArray removeAllObjects];
                [self.searchConversationsArray addObjectsFromArray:[conversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
            }
        }
        
        [self reloadTableView:NO];
    }
}

- (NSIndexPath *)updateConversationsIsSearchArray:(BOOL)isSearchConversations withConversation:(Conversation *)conversation
{
    
//    NSMutableArray *arrayConversations = isSearchConversations ? [self.searchConversationsArray mutableCopy] : [self.conversationsArray mutableCopy];
    NSMutableArray *arrayConversations = isSearchConversations ? [self.searchConversationsArray mutableCopy] : !conversation.isCareChannel ? [self.conversationsArray mutableCopy] : [self.careChannelsArray mutableCopy];
    
    NSIndexPath * indexPath = nil;
    
    for (Conversation *oldConverstion in arrayConversations)
    {
        if (oldConverstion.conversationId == conversation.conversationId)
        {
            indexPath = [NSIndexPath indexPathForRow:[arrayConversations indexOfObject:oldConverstion] inSection:0];
            break;
        }
    }
    
    if (indexPath) {
        
        if (conversation.lastMsg && !conversation.archived && !conversation.deleted) {
            
            [arrayConversations replaceObjectAtIndex:indexPath.row withObject:conversation];
            
            if (isSearchConversations) {
                [self.searchConversationsArray replaceObjectsInRange:NSMakeRange(0, self.searchConversationsArray.count)
                                                withObjectsFromArray:[arrayConversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
                
            } else if (!conversation.isCareChannel){
                [self.conversationsArray replaceObjectsInRange:NSMakeRange(0, self.conversationsArray.count)
                                          withObjectsFromArray:[arrayConversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
            }
            else {
                [self.careChannelsArray replaceObjectsInRange:NSMakeRange(0, self.careChannelsArray.count)
                                          withObjectsFromArray:[arrayConversations sortedArrayUsingSelector:@selector(lastMsgTimestampAsc:)]];
            }
        }
        else
        {
            //Conversation was deleted
            [arrayConversations removeObjectAtIndex:indexPath.row];
            
            if (isSearchConversations) {
                [self.searchConversationsArray replaceObjectsInRange:NSMakeRange(0, self.searchConversationsArray.count)
                                                withObjectsFromArray:arrayConversations];
            }
            else if (!conversation.isCareChannel) {
                [self.conversationsArray replaceObjectsInRange:NSMakeRange(0, self.conversationsArray.count)
                                          withObjectsFromArray:arrayConversations];
            }
            else {
                [self.careChannelsArray replaceObjectsInRange:NSMakeRange(0, self.careChannelsArray.count)
                                          withObjectsFromArray:arrayConversations];
            }
        }
    }
    
    return indexPath;
}

#pragma mark -- Reloading Table View UI --

- (void)reloadTableView:(BOOL)async {
    
    if(self.isSearching) {
        DDLogSupport(@"Restoring search filter");
        [self doSearch:self.searchBar.text];
        return;
    }
    
    __block __weak typeof(self) weakSelf = self;
//    if (self.containerSelected && self.isForegroundView) {
//    if (async) {
//        dispatch_async(dispatch_get_main_queue(),^{
//            weakSelf.archivedLabel.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)self.archivedLabelCount];
//            [weakSelf.tableView reloadData];
//            DDLogSupport(@"After Reloading table data");
//        });
//    } else {
        performBlockInMainThread(^{
            weakSelf.archivedLabel.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)weakSelf.archivedLabelCount];
            [weakSelf.tableView reloadData];
            DDLogSupport(@"After Reloading table data");
        });
//    }
//    }
}

- (void)reloadVisibleRowsTableViewForRecentsMunu:(NSInteger)recentsMenu {
    
    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
    
    NSMutableArray *toReload = [NSMutableArray array];
    
    if (recentsMenu == RecentsMenuConversations) {
        for (NSIndexPath *indexPath in indexes) {
            if ([self.conversationsArray containsIndex:indexPath.row]) {
                [toReload addObject:indexPath];
            }
        }
    }
    
    if (recentsMenu == RecentsMenuCareChannels) {
        for (NSIndexPath *indexPath in indexes) {
            if ([self.careChannelsArray containsIndex:indexPath.row]) {
                [toReload addObject:indexPath];
            }
        }
    }
    
    //No need to reload every row in tableView, need to reload all visible rows in tableView only once
    if (toReload.count != 0) {
        dispatch_async_main(^{
            [self.tableView reloadRowsAtIndexPaths:toReload withRowAnimation:UITableViewRowAnimationNone];
        });
    }
    
    /*
    for (NSIndexPath *indexPath in indexes) {
        
        VoidBlock reloadRows = ^{
            
            dispatch_async_main(^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
        };
        
        if (indexPath && [self.conversationsArray containsIndex:indexPath.row] && recentsMenu == RecentsMenuConversations) {
            reloadRows();
        }
        else if (indexPath && [self.careChannelsArray containsIndex:indexPath.row] && recentsMenu == RecentsMenuCareChannels) {
            reloadRows();
        }
    }
     */
}

#pragma mark -- Managing Conversations --

- (id)getConversationFromIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self) {
        
        id conversation = nil;
        
        if (self.isSearching) {
            if (self.searchConversationsArray.count > indexPath.row) {
                conversation = self.searchConversationsArray[indexPath.row];
            }
        }
        else {
            
            switch (self.selectedMenu) {
                case RecentsMenuConversations: {
                    if (self.conversationsArray.count > indexPath.row) {
                        conversation = self.conversationsArray[indexPath.row];
                    }
                    break;
                }
                case RecentsMenuCareChannels: {
                    if (self.careChannelsArray.count > indexPath.row) {
                        conversation = self.careChannelsArray[indexPath.row];
                    }
                    break;
                }
                default:
                    break;
            }
            
//            if (self.conversationsArray.count > indexPath.row) {
//                conversation = self.conversationsArray[indexPath.row];
//            }
        }
        return conversation;
    }
}

- (BOOL)isExistConversationToUserWithQliqID:(NSString *)qliqID {
    BOOL isExists = NO;
    for (Conversation *conv in self.conversationsArray) {
        if(conv.recipients && [[[conv.recipients recipient] recipientQliqId] isEqualToString:qliqID]) {
            isExists = YES;
            break;
        }
    }
    
    if (!isExists) {
        //In case, if the user is not exist in conversations, researching in Care Channels
        for (Conversation *conv in self.careChannelsArray) {
            if(conv.recipients && [[[conv.recipients recipient] recipientQliqId] isEqualToString:qliqID]) {
                isExists = YES;
                break;
            }
        }
    }

    return isExists;
}

#pragma mark -- UITableView --

- (void)setTableViewContentOffsetY:(CGFloat)offset withAnimation:(BOOL)animated
{
    void (^changeContentOffsetBlock)(void) = ^ {
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, offset);
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            changeContentOffsetBlock();
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    else {
        changeContentOffsetBlock();
    }
}

#pragma mark -- UITableView HeaderView --

/**
 Check HeaderView for TableView isShowing
 */
- (BOOL)headerViewIsShow {
    return self.headerView.frame.size.height > 0;
}

/**
 The ability to show or hide the AditionalView (Archived Items) in Header View
 */
- (void)showAdditionalView:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kValueSearchBarHeight : 0.f;
    
    void (^changeAdditionalViewBlock)(void) = ^ {
        __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            weakSelf.additionalViewHeightConstraint.constant = constant;
            weakSelf.additionalView.hidden = !show;
            [weakSelf changeFrameHeaderView];
        });
    };
    
    if (constant != self.additionalViewHeightConstraint.constant)
    {
        if (animated) {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                changeAdditionalViewBlock();
                [self.view layoutIfNeeded];
            } completion:nil];
        }
        else {
            changeAdditionalViewBlock();
        }
    }
}

/**
 The ability to show or hide the SearchBar in Header View
 */
- (void)showSearchBar:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kValueSearchBarHeight : 0.f;
    
    void (^changeSearchBarViewBlock)(void) = ^ {
        __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            weakSelf.searchBarHeightConstraint.constant = constant;
            [weakSelf changeFrameHeaderView];
        });
    };
    
    if (constant != self.searchBarHeightConstraint.constant)
    {
        if (animated) {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                changeSearchBarViewBlock();
                [self.view layoutIfNeeded];
                
            } completion:nil];
        }
        else {
            changeSearchBarViewBlock();
        }
    }
}

- (void)changeFrameHeaderView
{
    CGRect frame = self.headerView.frame;
    frame.size.height = self.searchBarHeightConstraint.constant + self.additionalViewHeightConstraint.constant;
    self.headerView.frame = frame;
    
    [self.tableView setTableHeaderView:self.headerView];
}



#pragma mark - Top Bar -

- (void)configureTopBar {
    /*
     Conversations
     */
    
    //Conversations Unread Badge
    {
        self.conversationsUnreadBadge.layer.cornerRadius = 7.f;
        self.conversationsUnreadBadge.clipsToBounds = YES;
        self.conversationsUnreadBadge.hidden = YES;
    }
    
    /*
     Care Channels
     */
    
    //Care Channels Unread Badge
    {
        self.careChannelsUnreadBadge.layer.cornerRadius = 7.f;
        self.careChannelsUnreadBadge.clipsToBounds = YES;
        self.careChannelsUnreadBadge.hidden = YES;
    }
    
    self.recentsTopBarMenu.hidden = YES;
    
    self.topBarTopConstraint.constant = - self.topBarHeightConstraint.constant;
    [self.recentsTopBarMenu setNeedsLayout];
    
    
    BOOL topBarWillShown = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isCareChannelsIntegrated;
    
    [self topBarShow:topBarWillShown force:YES];
    
    [self updateConversationsUreadBadgeCount:nil];
}

- (void)topBarShow:(BOOL)show force:(BOOL)force {
    
    BOOL willShown = show;
    
    if ((show && self.topBarTopConstraint.constant == 0.0) && (!willShown && self.topBarTopConstraint.constant != 0.0)) {
        return;
    }
    
    if(force) {
        
        self.recentsTopBarMenu.hidden = !show;
        self.topBarTopConstraint.constant = show ? 0.0f : - self.topBarHeightConstraint.constant;
        
        // As it is leaking about 32 bytes per call.
//        [self.view layoutIfNeeded];

    } else {
        
        if (show) {
            self.recentsTopBarMenu.hidden = !show;
        }
        __weak __block typeof(self) welf = self;
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            
            welf.topBarTopConstraint.constant = show ? 0.0f : - self.topBarHeightConstraint.constant;
            [welf.view layoutIfNeeded];
            
        } completion:^(BOOL completed) {
            if (!show) {
                welf.recentsTopBarMenu.hidden = !show;
            }
        }];
        
    }
    
    [self updateTopBarButtonsFor:self.selectedMenu];
}

- (void)updateTopBarButtonsFor:(RecentsMenu)selectedMenu {
    
    
    switch (selectedMenu)
    {
        case RecentsMenuConversations: {
            
            [self.careChannelsBarItemView setBackgroundColor:[UIColor clearColor]];
            [self.conversationsBarItemView setBackgroundColor:[UIColor whiteColor]];
            
            self.careChannelsSelectionView.hidden = YES;
            self.conversationsSelectionView.hidden = NO;
            
            break;
        }
        case RecentsMenuCareChannels: {
            
            [self.careChannelsBarItemView setBackgroundColor:[UIColor whiteColor]];
            [self.conversationsBarItemView setBackgroundColor:[UIColor clearColor]];
            
            self.careChannelsSelectionView.hidden = NO;
            self.conversationsSelectionView.hidden = YES;
            
            break;
        }
        default:
            break;
    }
}

#pragma mark * Unread Badges
- (void)updateConversationsUreadBadgeCount:(NSNotification *)notif {
    
    __block NSInteger unreadConversationsMessageCount = 0;
    __block NSInteger unreadCareChannelMessageCount = 0;
    
    __weak __block typeof(self) welf = self;
    void (^updateBadgeBlock)(void) = ^{
        [UIView animateWithDuration:0.25f animations:^{
            welf.conversationsUnreadBadge.text    = [NSString stringWithFormat:@"%ld", (long)unreadConversationsMessageCount];
            welf.conversationsUnreadBadge.hidden  = unreadConversationsMessageCount == 0 ? YES : NO;
            welf.careChannelsUnreadBadge.text    = [NSString stringWithFormat:@"%ld", (long)unreadCareChannelMessageCount];
            welf.careChannelsUnreadBadge.hidden  = unreadCareChannelMessageCount == 0 ? YES : NO;
            
            if (!self.conversationsUnreadBadge.hidden)
            {
                [welf configureContentViewForButton:welf.conversationsButton
                                     withTitleLabel:welf.conversationsTitleLabel
                                     withBadgeLabel:welf.conversationsUnreadBadge
                                withTitleLabelWidth:welf.conversationsTitleWidth
                           withBadgeWidthConstraint:welf.conversationsUnreadBadgeWidth
                         withBadgeLeadingConstraint:welf.conversationsUnreadBadgeLeading];
            }
            else
            {
                welf.conversationsUnreadBadgeLeading.constant = 0.f;
                welf.conversationsUnreadBadgeWidth.constant = 0.f;
            }
            [welf.conversationsUnreadBadge.superview layoutIfNeeded];
            
            if (!welf.careChannelsUnreadBadge.hidden)
            {
                [welf configureContentViewForButton:welf.careChannelsButton
                                     withTitleLabel:welf.careChannelsTitleLabel
                                     withBadgeLabel:welf.careChannelsUnreadBadge
                                withTitleLabelWidth:welf.careChannelsTitleWidth
                           withBadgeWidthConstraint:welf.careChannelsUnreadBadgeWidth
                         withBadgeLeadingConstraint:welf.careChannelsUnreadBadgeLeading];
            }
            else
            {
                welf.careChannelsUnreadBadgeLeading.constant = 0.f;
                welf.careChannelsUnreadBadgeWidth.constant = 0.f;
            }
            [welf.careChannelsUnreadBadge.superview layoutIfNeeded];
        }];
    };
    
    if (notif.userInfo[@"newBadgeValue"])
    {
        unreadConversationsMessageCount = [notif.userInfo[@"newConversationBadgeValue"] integerValue];
        unreadCareChannelMessageCount = [notif.userInfo[@"newCareChannelBadgeValue"] integerValue];
        updateBadgeBlock();
    }
    else
    {
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            unreadConversationsMessageCount = [ChatMessage unreadConversationMessagesCount];
            unreadCareChannelMessageCount = [ChatMessage unreadCareChannelMessagesCount];
            performBlockInMainThread (^{
                updateBadgeBlock();
            });
        }];
    }
}

- (void)configureContentViewForButton:(UIButton *)button
                       withTitleLabel:(UILabel *)titleLabel
                       withBadgeLabel:(UILabel *)badgeLabel
                  withTitleLabelWidth:(CGFloat)titleLabelWidth
             withBadgeWidthConstraint:(NSLayoutConstraint *)widthConstraint
           withBadgeLeadingConstraint:(NSLayoutConstraint *)badgeLeadingConstraint
{
    CGFloat neededWidthBadgeText = [ResizeBadge calculatingNeededWidthForBadge:badgeLabel.text rangeLength:badgeLabel.text.length font:badgeLabel.font];
    neededWidthBadgeText += 2.f;
    
    CGFloat maxWidthButtonContentView = button.frame.size.width - 2 * kButtonContentMargin;
    CGFloat neededWidthButtonContentView = titleLabelWidth + neededWidthBadgeText + kUnreadBadgeLeading;
    
    if (neededWidthButtonContentView > maxWidthButtonContentView)
    {
        //Calculating the totalFreeSpace for width of badge
        CGFloat totalFreeSpaceForBadge = maxWidthButtonContentView - titleLabelWidth - kUnreadBadgeLeading;
        
        //Configure badge with for new text (calculating width badge, changing value of `badgeValue.text` if needed).
        [ResizeBadge resizeBadge:badgeLabel
                  totalFreeSpace:totalFreeSpaceForBadge
                 canTextBeScaled:NO
         setBadgeWidthCompletion:^(CGFloat calculatedWidth) {
             [self configureConstraintsForBadgeWidth:calculatedWidth
                                badgeWidthConstraint:widthConstraint
                              badgeLeadingConstraint:badgeLeadingConstraint];
         }];
    }
    else
    {
        [self configureConstraintsForBadgeWidth:neededWidthBadgeText badgeWidthConstraint:widthConstraint badgeLeadingConstraint:badgeLeadingConstraint];
    }
}

- (void)configureConstraintsForBadgeWidth:(CGFloat)calculatedWidthBadge
                     badgeWidthConstraint:(NSLayoutConstraint *)badgeWidthConstraint
                   badgeLeadingConstraint:(NSLayoutConstraint *)badgeLeadingConstraint
{
    if (calculatedWidthBadge < kMinBadgeWidth && calculatedWidthBadge != 0)
    {
        calculatedWidthBadge = kMinBadgeWidth;
    }
    badgeWidthConstraint.constant = calculatedWidthBadge;
    badgeLeadingConstraint.constant = kUnreadBadgeLeading;
}

#pragma mark - Private -

- (void)eraseSelectedConversation {
    if (self.selectedForOptionsConversation) {
        self.selectedForOptionsConversation = nil;
        
        __weak __block typeof(self) weakSelf = self;
        performBlockInMainThread(^{
            [weakSelf.tableView reloadData];
        });
    }
}

- (MessageAttachment *)attachmentFromImage:(UIImage *)image scale:(CGFloat)scale
{
    __block NSDate * date = [NSDate date];
    
    MessageAttachment * attachment = [[MessageAttachment alloc] initWithImage:image scale:scale saved:^{
        
        DDLogInfo(@"Image saved for %g",-[date timeIntervalSinceNow]);
        date = [NSDate date];
        
    } encrypted:^{
        DDLogInfo(@"Image encrypted for %g",-[date timeIntervalSinceNow]);
    }];
    
    return attachment;
}

- (void)checkForLaunchingWithNotification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Check for if app was launched with local Notification
        if (appDelegate.unProcessedLocalNotifications && appDelegate.unProcessedLocalNotifications.count > 0) {
            [[QliqUserNotifications getInstance] showConversationFor:appDelegate.unProcessedLocalNotifications.firstObject inNavigationController:self.navigationController];
        }
        //Check for if app was launched with Remote Notification
        else if (appDelegate.unProcessedRemoteNotifcations > 0 &&
                 appDelegate.wasLaunchedDueToRemoteNotificationiOS7 &&
                 appDelegate.pushNotificationCallId &&
                 appDelegate.pushNotificationCallId.length > 0 &&
                 appDelegate.pushNotificationToUser &&
                 appDelegate.pushNotificationToUser.length > 0 &&
                 appDelegate.pushNotificationId &&
                 appDelegate.pushNotificationId.length > 0)
        {
            if (![[QliqUserNotifications getInstance] openConversationForRemoteNotificationWith:self.navigationController callId:appDelegate.pushNotificationCallId]) {
                dispatch_async_main(^{
                    DDLogSupport(@"Checking for Messages ProgressHUD. Started");
                    [SVProgressHUD showWithStatus:NSLocalizedString(@"1903-TextCheckingForMessages", nil)];
                });
                self.needNotifyAboutPushMessage = YES;
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopNotifingAboutPushMessage:) name:StopNotifyingAboutPushMessage object:nil];
            }
        }
        else
        {
            appDelegate.pushNotificationCallId = nil;
            appDelegate.pushNotificationToUser = nil;
            appDelegate.wasLaunchedDueToRemoteNotificationiOS7 = NO;
        }
    });
}

- (void)rotated:(NSNotification*)notification {
    
    /*If iPhoneX rotated*/
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        
        self.archivedConversationsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 50, 0, 0);
    }  else {
        
        self.archivedConversationsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    }
}

#pragma mark - Alerts -

- (void)managedAlerts {
    DDLogSupport(@"ManagedAlerts");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ( [[defaults valueForKey:kShowEnableNotificationsAlert] boolValue] == YES )
    {
        QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:NO];
        
        [alertView setContainerViewWithImage:[UIImage imageNamed:@"AlertImageEnabelNotifications"]
                                   withTitle:NSLocalizedString(@"1174-TextEnableNotifications", nil)
                                    withText:NSLocalizedString(@"1175-TextEnableNotificationsDescription", nil)
                                withDelegate:self
                            useMotionEffects:YES];
        
        [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"1-ButtonOK", nil), nil]];
        [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowEnableNotificationsAlert];
            [appDelegate setupFirstInstallPushnotifications];
        }];
        [alertView show];
    }
    
    
    if ([defaults objectForKey:kShowResendInvitationsAlertOnceLoggedIn]) {
        [defaults removeObjectForKey:kShowResendInvitationsAlertOnceLoggedIn];
        [defaults synchronize];
        [self showResendInvitationsAlert];
    }
    else if ([defaults objectForKey:kShowEditProfileAlertOnceLoggedIn]) {
        [defaults removeObjectForKey:kShowEditProfileAlertOnceLoggedIn];
        [defaults synchronize];
        [self showEditProfileAlert];
    }
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
}

- (BOOL)showResendInvitationsAlert {
    return YES;
}

- (void)showEditProfileAlert
{
    NSString *title = NSLocalizedString(@"1176-TextAskUpdateProfile", nil);
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                  message:nil
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"13-ButtonLater", nil)
                                                        otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
    __block __weak typeof(self) weakSelf = self;
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        if (alert.cancelButtonIndex != buttonIndex)
        {
            MainSettingsViewController *mainController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MainSettingsViewController class])];
            [weakSelf.navigationController pushViewController:mainController animated:NO];
            
            ProfileViewController *profileController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
            [weakSelf.navigationController pushViewController:profileController animated:YES];
        }
    }];
}

- (void)showSoundSettingsAlert
{
    NSString *title = NSLocalizedString(@"1177-TextAskCustomizeAlerts", nil);
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                  message:nil
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"13-ButtonLater", nil)
                                                        otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
    
    __block __weak typeof(self) weakSelf = self;
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        if (alert.cancelButtonIndex != buttonIndex)
        {
            UserSettings * userSettings = [UserSessionService currentUserSession].userSettings;
            
            MainSettingsViewController *mainController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MainSettingsViewController class])];
            [weakSelf.navigationController pushViewController:mainController animated:YES];
            
            SettingsSoundViewController *soundsController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsSoundViewController class])];
            soundsController.soundSettings = userSettings.soundSettings;
            [weakSelf.navigationController pushViewController:soundsController animated:YES];
        }
    }];
}

#pragma mark - Notifications -

- (void)addGeneralNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setSelectedSettingsButton:)
                                                 name:kDidShowedCurtainViewNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationWillResignActiveNotification:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector:@selector(didReceiveAllSIPMessages:)
                                                 name:SipMessageDumpFinishedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sipRegistrationChanged:)
                                                 name:SIPRegistrationStatusNotification
                                               object:nil];
    
    // Now register for Active Notification. When the App goes frm BG to FG, we need to refresh the UI
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadControllerAfterAction:)
                                                 name:kConversationsListDidPressActionButtonNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadControllerAfterDeleteAction:)
                                                 name:kConversationsListDidPressDeleteButtonNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pressedSortOption)
                                                 name:@"AllContactsAreSyncedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLockScreenShowed:)
                                                 name:kDeviceLockStatusChangedNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConversationsUreadBadgeCount:)
                                                 name:ChatBadgeValueNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCareChannelIntegrationChange:)
                                                 name:@"IsCareChannelIntegrated"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkUpdateDBConversation:)
                                                 name:@"RefreshDBConversations"
                                               object:nil];
}

- (void)checkUpdateDBConversation:(NSNotification *)notification {
    DDLogSupport(@"Check update all conversations in DB");
    
    __weak __block typeof(self) welf = self;
    dispatch_async_background(^{
        if (welf.conversationsArray.count != [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:NO careChannel:NO]) {
            
            [welf.conversationsArray removeAllObjects];
        }
        
        if (welf.careChannelsArray.count != [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:NO careChannel:YES]) {
            
            [welf.careChannelsArray removeAllObjects];
        }
        
        [welf pressedSortOption];
    });
}

- (void)handleCareChannelIntegrationChange:(NSNotification *)notification {
    BOOL isTopBarWillShown = NO;
    id obj = notification.object;
    if ([obj isKindOfClass:[NSNumber class]]) {
        isTopBarWillShown = [(NSNumber *)obj boolValue];
    }
    
    [self topBarShow:isTopBarWillShown force:NO];
    
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification {
    DDLogSupport(@"handleApplicationWillResignActiveNotification");
    
    self.isForegroundView = NO;
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            DDLogSupport(@"Dismissing connecting progress indicator");
            [SVProgressHUD dismiss];
        }
    });
}

- (void)didReceiveAllSIPMessages:(NSNotification *)notification {
    DDLogSupport(@"Checking for messages is done");
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
}

- (void)showConnectionAlertIfNeeded
{
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        __strong typeof(self) strongSelf = weakSelf;
        
        NSInteger status = [[QliqSip sharedQliqSip] lastRegistrationResponseCode];
        
        if (status == 200) {
            strongSelf.registration5XXErrorCount = 0;
        }
        if (!strongSelf.isForegroundView) {
            return;
        }
        if (status == 200)
        {
            if (strongSelf.connectionErrorAlert)
            {
                [strongSelf.connectionErrorAlert dismissWithClickedButtonIndex:strongSelf.connectionErrorAlert.cancelButtonIndex animated:NO];
                strongSelf.connectionErrorAlert = nil;
            }
        }
        else
        {
            [SVProgressHUD dismiss];
            
            if (strongSelf.connectionErrorAlert == nil)
            {
                if (status >= 500)
                {
                    BOOL retry = NO;
                    NSString *button;
                    NSString *title;
                    
                    AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
                    BOOL isReachable = [app isReachable];
                    
                    if (isReachable) {
                        title = NSLocalizedString(@"1178-TextTheServerIsTemporarilyUnavailable", nil);
                    }
                    else {
                        title = NSLocalizedString(@"1179-TextNetworkConnectionDown", nil);
                    }
                    
                    strongSelf.registration5XXErrorCount++;
                    
                    DDLogSupport(@"Showing Popup: %@. registration5XXErrorCount: %d", title, strongSelf.registration5XXErrorCount);

                    
                    if (strongSelf.registration5XXErrorCount == 1) {
                        // 11/23/2016 Krishna
                        // First time, restart the SIP automatically.
                        //
                        performBlockInMainThread(^{
                            [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
                        });
                        // Return from here
                        return;
                    }
                    else if (strongSelf.registration5XXErrorCount == 2)
                    {
                        // 11/23/2016 Krishna
                        // Second time, Show to user so that user can retry
                        //
                        retry = YES;
                        button = NSLocalizedString(@"28-ButtonRetry", nil) ;
                    }
                    else if (strongSelf.registration5XXErrorCount > 2)
                    {
                        // 11/23/2016 Krishna
                        // Third time, Show to error.
                        //
                        retry = NO;
                        
                        if (isReachable)
                            button = NSLocalizedString(@"1005-TextReportError", nil);
                        else
                            button = nil;
                        
                    }
                    else
                    {// Don't spam user with this error anymore
                        return;
                    }
                    
                    strongSelf.connectionErrorAlert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                                        message:nil
                                                                                       delegate:nil
                                                                              cancelButtonTitle:NSLocalizedString(@"41-ButtonIgnore", nil)
                                                                              otherButtonTitles:button, nil];
                    
                    [strongSelf.connectionErrorAlert showWithDissmissBlock:^(NSInteger buttonIndex) {
                        
                        if (strongSelf.connectionErrorAlert.cancelButtonIndex != buttonIndex)
                        {
                            if (retry)
                            {
                                // 10/28/2016 Krishna
                                // Restarting SIP is the safe here instead of just registering
                                // As it could be because of it switched from IPv4 to IPv6
                                // Or DNS resolution module is stuck or some other error
                                //
                                performBlockInMainThread(^{
                                    [[QliqSip instance] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
                                });
                            }
                            else
                            {
                                FeedBackSupportViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FeedBackSupportViewController class])];
                                controller.reportType = ReportTypeError;
                                [self.navigationController pushViewController:controller animated:YES];
                            }
                        }
                        else
                        {
                            strongSelf.registration5XXErrorCount = 3;
                        }
                        
                        strongSelf.connectionErrorAlert = nil;
                    }];
                }
            }
        }
    });
}

- (void)sipRegistrationChanged:(NSNotification *)notification {
    [self showConnectionAlertIfNeeded];
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
    
//    [self.refreshRecentsOperationQueue addOperationWithBlock:^{
//        [self pressedSortOption];
//    }];
    
    if (self.isNewConversation) {
        self.isNewConversation = NO;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [self reloadTableView:NO];
        }];
    }
    else {
        [self reloadVisibleRowsTableViewForRecentsMunu: (self.selectedMenu == RecentsMenuConversations) ? RecentsMenuConversations : RecentsMenuCareChannels];
    }
}

- (void)onLockScreenShowed:(NSNotification *)notification
{
    if (appDelegate.currentDeviceStatusController.isWiped)
    {
        [self pressedSortOption];
    }
}

- (void)setSelectedSettingsButton:(NSNotification *)notification {
    NSNumber *info = [notification object];
    
    if (info) {
        self.settingsButton.selected = [info boolValue];
    }
}

- (void)stopNotifingAboutPushMessage:(NSNotification *)notification {
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
    self.needNotifyAboutPushMessage = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopNotifyingAboutPushMessage object:nil];
    
    [[QliqUserNotifications getInstance] clearLaunchedPushData];
}

#pragma mark * Common Conversation Notifications

- (void)addCommonConversationsNotifications {
    
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
                                             selector:@selector(userHasChangeAvatar:)
                                                 name:@"UserHasChangeAvatar"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didPerformArchiveActionOnConversation:)
                                                 name:@"ConversationArchiveAction"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMuteConversationNotification:)
                                                 name:ConversationMutedChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConversationForRecalledChatMessage:)
                                                 name:ChatMessageRecalledInConversationNotification
                                               object:nil];
}

- (void)removeCommonConversationsNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ConversationDidReadMessagesNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DBHelperConversationDidAddMessage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:QliqConnectDidDeleteMessagesInConversationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RecipientsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UserHasChangeAvatar" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ConversationArchiveAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ConversationMutedChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ChatMessageRecalledInConversationNotification object:nil];
}

- (void)updateConversationForRecalledChatMessage:(NSNotification *)notification
{
    DDLogSupport(@"Update conversation for recalled chat message");
    Conversation *conversation = notification.userInfo[@"Conversation"];
    if (conversation)
    {
        //Need to update all conversations, not only the all careChannel conversations
//        BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//        if (conversation.isCareChannel == isShowingCareChannels)
        {
            __block __weak typeof(self) weakSelf = self;
            [self.refreshRecentsOperationQueue addOperationWithBlock:^{
                [weakSelf updateConversationsArrayWithConversation:conversation];
            }];
        }
    }
}

- (void)handleMuteConversationNotification:(NSNotification *)notification {
    
    id item = notification.object;
    if (item && [item isKindOfClass:[Conversation class]])
    {
        Conversation *conversation = (Conversation *)item;
        
        //Need to update all conversations, not only the all careChannel conversations
//        BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//        if (conversation.isCareChannel == isShowingCareChannels)
        {
            __block __weak typeof(self) weakSelf = self;
            [self.refreshRecentsOperationQueue addOperationWithBlock:^{
                [weakSelf updateConversationsArrayWithConversation:conversation];
            }];
        }
    }
}

- (void)handleRecipientsChangedNotification:(NSNotification *)notification {
    DDLogSupport(@"Conversation Refresh Called from handleRecipientsChangedNotification");
    Conversation *conversation = notification.object;
    
    //Need to update all conversations, not only the all careChannel conversations
//    BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//    if (conversation.isCareChannel == isShowingCareChannels)
    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:conversation];
        }];
    }
}

- (void)didReadMessages:(NSNotification *)notification {
    DDLogSupport(@"didReadMessages notification, dispatching refresh");
    Conversation *conversation =[[notification userInfo] objectForKey:@"Conversation"];
    
    //Need to update all conversations, not only the all careChannel conversations
//    BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//    if (conversation.isCareChannel == isShowingCareChannels)
//    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:conversation];
        }];
        self.notReadOnce = NO;
//    }
}

- (void)didReceiveMessage:(NSNotification *)notification {
    DDLogSupport(@"didReceiveMessage notification, dispatching refresh");
    
    Conversation *conversation = [[notification userInfo] objectForKey:@"Conversation"];
    
    //Need to update all conversations, not only the all careChannel conversations
//    BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//    if (conversation.isCareChannel == isShowingCareChannels) {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:conversation];
        }];
//    }
    
    //Checking for for message for Delayed PUSH
    if (self.needNotifyAboutPushMessage)
    {
        if ([QliqUserNotifications getInstance].delayStartPoint != 0 && ([[NSDate date] timeIntervalSince1970] - [QliqUserNotifications getInstance].delayStartPoint) < kValueDelayForOpeningPushInSec)
        {
            ChatMessage *msg = [ChatMessageService getMessageWithUuid:appDelegate.pushNotificationCallId];
            if (msg && msg.conversationId == conversation.conversationId)
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:msg, kKeyMessage, nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:OpenDelayedPushNotification object:self.navigationController userInfo:userInfo];
            }
        }
        else
        {
            [self stopNotifingAboutPushMessage:nil];
        }
    }
}

- (void)didDeleteMessagesInConversation:(NSNotification *)notification
{
    DDLogSupport(@"didDeleteMessages notification, dispatching refresh");
    
    Conversation *conversation =[[notification userInfo] objectForKey:@"Conversation"];
    //Need to update all conversations, not only the all careChannel conversations
//    BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//    if (conversation.isCareChannel == isShowingCareChannels)
    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:conversation];
        }];
    }
}

- (void)didPerformArchiveActionOnConversation:(NSNotification *)notification {
    DDLogSupport(@"didPerformArchiveActionOnConversation notification, dispatching refresh");
    
    Conversation *conversation =[[notification userInfo] objectForKey:@"Conversation"];
    //Need to update all conversations, not only the all careChannel conversations
//    BOOL isShowingCareChannels = (self.selectedMenu == RecentsMenuCareChannels);
//    if (conversation.isCareChannel == isShowingCareChannels)
    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshRecentsOperationQueue addOperationWithBlock:^{
            [weakSelf updateConversationsArrayWithConversation:conversation];

            //Need to update archived count too
            weakSelf.archivedLabelCount = [[ConversationDBService sharedService] countConversationsForRecentsViewArchived:YES careChannel:conversation.isCareChannel];
        }];
    }
}

- (void)userHasChangeAvatar:(NSNotification *)notification
{
    __weak __block typeof(self) welf = self;
    Contact *contact = [[notification userInfo] objectForKey:@"contact"];
    if ([welf isExistConversationToUserWithQliqID:contact.qliqId])
    {
        if (self.containerSelected && self.isForegroundView)
        {
            [self.refreshRecentsOperationQueue addOperationWithBlock:^{
                performBlockInMainThread(^{
                    [welf.tableView reloadData];
                });
            }];
        }
    }
}

- (void)reloadControllerAfterAction:(NSNotification *)notification {
    __weak __block typeof(self) welf = self;
    
    [self scheduleProgressHUD];
    
    [self.refreshRecentsOperationQueue addOperationWithBlock:^{
        [welf pressedSortOption];
    }];
}

- (void)reloadControllerAfterDeleteAction:(NSNotification *)notification {
    
    [self scheduleProgressHUD];
    
    NSArray *deletedConversations = [[notification userInfo] objectForKey:@"DeletedConversations"];
    
    for (Conversation *deletedConv in deletedConversations) {
        if (deletedConv.isCareChannel) {
            
            for (Conversation *conv in self.careChannelsArray) {
                
                if (deletedConv.conversationId == conv.conversationId) {
                    [self.careChannelsArray removeObject:conv];
                    break;
                }
            }
        }
        else {
            
            for (Conversation *conv in self.conversationsArray) {
                if (deletedConv.conversationId == conv.conversationId) {
                    [self.conversationsArray removeObject:conv];
                    break;
                }
            }
        }
    }
    
    __weak __block typeof(self) welf = self;
    [welf.refreshRecentsOperationQueue addOperationWithBlock:^{
        [welf reloadTableView:NO];
    }];
}


#pragma mark - Actions -

#pragma mark * Top Bar IBActions

- (IBAction)onConversationsMenu:(id)sender
{
    self.selectedMenu = RecentsMenuConversations;
    [self handleSortButtonPressed];
}

- (IBAction)onCareChannelsMenu:(id)sender
{
    self.selectedMenu = RecentsMenuCareChannels;
    [self handleSortButtonPressed];
}

- (void)handleSortButtonPressed
{
    [self scheduleProgressHUD];
    
    [self.refreshRecentsOperationQueue cancelAllOperations];
    [self.refreshRecentsOperationQueue waitUntilAllOperationsAreFinished];
    
    //reload data from DB
    [self pressedSortOption];
}

#pragma mark * AdditionalView Actions

- (IBAction)onArchivedChats:(UIButton *)sender {
    DDLogSupport(@"On Archived Chats");
    
    
    ConversationsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsViewController class])];
    controller.isArchivedConversations = YES;
    controller.isCareChannelsMode = self.selectedMenu == RecentsMenuCareChannels;
    
    [self.navigationController pushViewController:controller animated:YES];
    
}

#pragma mark * Bottom Bar Actions

- (IBAction)onSearch:(id)sender {
    DDLogSupport(@"On Favorites");
    
    //    NSString *str = QliqFormatLocalizedString1(@"9000-Test%@x", @"1");
    //    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:str
    //                                                                  message:nil
    //                                                                 delegate:nil
    //                                                        cancelButtonTitle:NSLocalizedString(@"Later", nil)
    //                                                        otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    //    [alert showWithDissmissBlock:NULL];
    //    return;
    
    FavoriteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FavoriteContactsViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onCreateConversation:(id)sender {
    DDLogSupport(@"Create Conversation");
    
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.isNewConversation = YES;
    [self.navigationController pushViewController:controller animated:YES];
    controller = nil;
}

- (IBAction)onCreateConversationWithAttachment:(id)sender {
    DDLogSupport(@"on Create Conversation with attachment");
    
    __block __weak typeof(self) weakSelf = self;
    [QliqHelper getPickerForMode:PickerModePhotoAndVideo forViewController:self returnPicker:^(UIImagePickerController *picker, NSError *error) {
        
        if (error) {
            [AlertController showAlertWithTitle:nil
                                        message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:NULL];
        } else if (picker) {
            [weakSelf.navigationController presentViewController:picker animated:YES completion:nil];
        }
    }];
}

- (IBAction)onSettings:(id)sender {
    DDLogSupport(@"On Settings");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowCurtainViewNotification object:nil];
}

#pragma mark * User Actions

- (void)onPullToRefresh:(UIRefreshControl *)refreshControl {
    DDLogSupport(@"Conversation Refresh Called from onPullToRefresh");
    
    [self.refreshControl endRefreshing];
    
    __weak __block typeof(self) welf = self;
    [self.refreshRecentsOperationQueue addOperationWithBlock:^{
        [welf pressedSortOption];
    }];
}


#pragma mark - Delegates -

#pragma mark * RecentCellDelegate

- (void)cellLeftSwipe:(Conversation *)conversation {
    self.selectedForOptionsConversation = conversation;
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
    DDLogSupport(@"Conversation Refresh Called from archiveConversations");
    
    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    
    if (!conversation.isCareChannel) {
        controller.conversations = self.conversationsArray;
    }
    else {
       controller.conversations = self.careChannelsArray;
    }
//    controller.conversations = self.conversationsArray;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionArchive;
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)pressDeleteButton:(Conversation *)conversation {
    DDLogSupport(@"Conversation Refresh Called from deleteConversations");
    
    [self eraseSelectedConversation];
    
    ConversationsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationsListViewController class])];
    
    if (!conversation.isCareChannel) {
        controller.conversations = self.conversationsArray;
    }
    else {
        controller.conversations = self.careChannelsArray;
    }
//    controller.conversations = self.conversationsArray;
    controller.selectedConversations = [NSMutableSet setWithObject:conversation];
    controller.currentConversationsAction = ConversationsActionDelete;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark * TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DDLogSupport(@"Reload TableView");
    NSInteger count = 0;
    
    if (self.isSearching)
        count = self.searchConversationsArray.count;
    else
        
        switch (self.selectedMenu) {
            case RecentsMenuConversations: {
                count = self.conversationsArray.count;
                break;
            }
            case RecentsMenuCareChannels: {
                count = self.careChannelsArray.count;
                break;
            }
            default:
                break;
        }
//        count = self.conversationsArray.count;
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RecentTableViewCell_ID";
    
    RecentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //Registered 'nib' in ViewDidLoad
    /*
     if(!cell) {
     UINib *nib = [UINib nibWithNibName:@"RecentTableViewCell" bundle:nil];
     
     [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
     
     cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
     }
     */
    
    cell.delegate = self;
    
    [cell configureCellWithConversation:[self getConversationFromIndexPath:indexPath]
                       withSelectedCell:self.selectedForOptionsConversation];
    [cell configureBackroundColor:RGBa(239.f, 239.f, 239.f, 1.f)];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isSelectedForChatConversation) {
        
        id conversation = [self getConversationFromIndexPath:indexPath];
        
        self.isSelectedForChatConversation = YES;
        
        [self eraseSelectedConversation];
        
        ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
        controller.conversation = conversation;
        controller.isCareChannelMode = (self.selectedMenu == RecentsMenuCareChannels);
        
        [self.navigationController pushViewController:controller animated:YES];
        controller = nil;
    }
}

#pragma mark * UIScroll Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Show Header View Items
    if (scrollView.contentOffset.y <= -40)
    {
        if (!scrollView.isDecelerating && ![self headerViewIsShow])
        {
            //            if (!self.isSearching)
            //                [self onSearch:nil];
            [self showSearchBar:YES withAnimation:YES];
            [self showAdditionalView:YES withAnimation:YES];
        }
        
    }
    
    //Hide HeaderViewItems
    else if (scrollView.contentOffset.y > self.headerView.frame.size.height)
    {
        /* If must hidden only additionalView
         if (0 != self.additionalViewHeightConstraint.constant)
         {
         [self setTableViewContentOffsetY:self.tableView.contentOffset.y - kValueSearchBarHeight withAnimation:NO];
         [self showAdditionalView:NO withAnimation:NO];
         }
         */
        
        if (0 != self.additionalViewHeightConstraint.constant || 0 != self.searchBarHeightConstraint.constant)
        {
            //CGFloat offset = 0 != self.additionalViewHeightConstraint.constant ? kValueSearchBarHeight : 0;
            //offset = 0 != self.searchBarHeightConstraint.constant ? offset + kValueSearchBarHeight : offset;
            
            [self setTableViewContentOffsetY:self.tableView.contentOffset.y - self.headerView.frame.size.height withAnimation:NO];
            [self showSearchBar:NO withAnimation:NO];
            [self showAdditionalView:NO withAnimation:NO];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self headerViewIsShow])
    {
        if (scrollView.contentOffset.y >= 20 && scrollView.contentOffset.y < self.headerView.frame.size.height)
        {
            [self showSearchBar:NO withAnimation:YES];
            [self showAdditionalView:NO withAnimation:YES];
            
            [self setTableViewContentOffsetY:self.headerView.frame.size.height withAnimation:YES];
        }
        else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < 20)
        {
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self eraseSelectedConversation];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self eraseSelectedConversation];
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark * UISearchBarField Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)doSearch:(NSString *)searchText {
    DDLogSupport(@"Start Search Conversation with searchText: %@", searchText);
    
    [self.searchConversationsArray removeAllObjects];
    if (self.selectedForOptionsConversation)
        self.selectedForOptionsConversation = nil;
    
    
    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithCapacity: (self.selectedMenu == RecentsMenuConversations) ? self.conversationsArray.count : self.careChannelsArray.count];
    [tmpArr addObjectsFromArray:(self.selectedMenu == RecentsMenuConversations) ? self.conversationsArray : self.careChannelsArray];
    
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:tmpArr andSearchString:searchText withPrioritizedAlphabetically:NO];
    
    self.isSearching = (operation != nil);
    
    __block __weak typeof(self) weakSelf = self;
    VoidBlock updateTableBlock = ^{
        performBlockInMainThread(^{
            weakSelf.archivedLabel.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)weakSelf.archivedLabelCount];
            [weakSelf.tableView reloadData];
        });
    };
    
    if (self.isSearching)
    {
        [self.searchConversationsArray addObjectsFromArray:[operation search]];
        if (self.containerSelected && self.isSearching && self.isForegroundView) {
            updateTableBlock();
        }
    }
    else if (self.containerSelected && self.isForegroundView)
    {
        updateTableBlock();
    }
}

#pragma mark * UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DDLogSupport(@"didFinishPickingMedia");
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:QliqLocalizedString(@"1115-TextProcessing")];
    });
    __block __weak typeof(self) weakSelf = self;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        __strong typeof(self) strongSelf = weakSelf;
        
        void (^startNewConversation)(MessageAttachment*) = ^(MessageAttachment *attachment){
            ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
            controller.isNewConversation = YES;
            controller.attachment = attachment;
            
            [strongSelf.navigationController pushViewController:controller animated:YES];
        };
        
        CFStringRef type = (__bridge CFStringRef)[info objectForKey:UIImagePickerControllerMediaType];
        
        if (UTTypeEqual(type, kUTTypeImage)) {
            
            UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            dispatch_async_main(^{
                if ([SVProgressHUD isVisible]) {
                    [SVProgressHUD dismiss];
                }
            });
            [weakSelf chooseQualityForImage:pickedImage attachment:YES withCompletitionBlock:^(ImageQuality quality) {
                
                
                CGFloat scale = [[QliqAvatar sharedInstance] scaleForQuality:quality];
                
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    MessageAttachment *attachment = [strongSelf attachmentFromImage:pickedImage scale:scale];
                    if (attachment) {
                        startNewConversation(attachment);
                    } else {
                        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                    message:QliqLocalizedString(@"11522-TextCannotCreateMessageAttachment")
                                                buttonTitle:nil
                                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                 completion:nil];
                    }
                    dispatch_async_main(^{
                        if ([SVProgressHUD isVisible]) {
                            [SVProgressHUD dismiss];
                        }
                    });
                });
            }];
        }
        else if (UTTypeEqual(type, kUTTypeMovie)) {
            
            [[QliqAvatar sharedInstance] convertVideo:info[UIImagePickerControllerMediaURL] usingBlock:^(NSURL *convertedVideoUrl, BOOL completed, RemoveBlock block) {
                
                if (completed) {
                    MessageAttachment *attachment = [[MessageAttachment alloc] initWithVideoAtURL:convertedVideoUrl];
                    startNewConversation(attachment);
                }
                block();
            }];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    DDLogSupport(@"imagePicker didCancel");
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)chooseQualityForImage:(UIImage *)image attachment:(BOOL)isAttachment withCompletitionBlock:(void(^)(ImageQuality quality))completeBlock {
    
    NSUInteger estimatedSmall, estimatedMedium, estimatedLarge, estimatedActual;
    
    estimatedActual = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityOriginal attachment:isAttachment];
    estimatedSmall  = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityLow      attachment:isAttachment];
    estimatedMedium = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityMedium   attachment:isAttachment];
    estimatedLarge  = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityHight    attachment:isAttachment];
    
    NSString * originalTitle = [NSString stringWithFormat:@"%@ (%@)", QliqLocalizedString(@"2016-TitleActualSize"),[NSString fileSizeFromBytes:estimatedActual]];
    
    NSString * mediumTitle =   [NSString stringWithFormat:@"%@ (%@)", QliqLocalizedString(@"2017-TitleMedium"),    [NSString fileSizeFromBytes:estimatedMedium]];
    
    NSString * largeTitle =    [NSString stringWithFormat:@"%@ (%@)", QliqLocalizedString(@"2018-TitleLarge"),     [NSString fileSizeFromBytes:estimatedLarge]];
    
    NSString * smallTitle =    [NSString stringWithFormat:@"%@ (%@)", QliqLocalizedString(@"2019-TitleSmall"),     [NSString fileSizeFromBytes:estimatedSmall]];
    
    [AlertController showActionSheetAlertWithTitle:QliqLocalizedString(@"1168-TextChooseImageQuality")
                                           message:nil
                                  withTitleButtons:@[smallTitle,mediumTitle,largeTitle,originalTitle]
                                 cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                        completion:^(NSUInteger buttonIndex) {
                                            dispatch_async_main(^{
                                                [SVProgressHUD showWithStatus:QliqLocalizedString(@"1115-TextProcessing")];
                                            });
                                            switch (buttonIndex) {
                                                case 0:
                                                    completeBlock(0);
                                                    break;
                                                case 1:
                                                    completeBlock(1);
                                                    break;
                                                case 2:
                                                    completeBlock(2);
                                                    break;
                                                case 3:
                                                    completeBlock(3);
                                                    break;
                                                    
                                                default:
                                                    break;
                                            }
                                        }];
}

@end

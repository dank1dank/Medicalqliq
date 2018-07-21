//
//  ConversationViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/30/14.
//
//

#import "ConversationViewController.h"
#import "QuickMessageViewController.h"
#import "MessageTimestampViewController.h"
#import "SelectContactsViewController.h"

#import "AudioAttachmentViewController.h"
#import "DocumentAttachmentViewController.h"
#import "ImageAttachmentViewController.h"
#import "VideoAttachmentViewController.h"

#import "DBHelperConversation.h"
#import "KeyboardAccessoryViewController.h"
#import "ConversationTableViewCell.h"
#import "EditTableViewCell.h"
#import "EventMessageCell.h"
#import "QliqConnectModule.h"
#import "Conversation.h"
#import "ChatMessage.h"
#import "QliqSip.h"
#import "Helper.h"
#import "NSDate+Format.h"
#import "MessageAttachment.h"
#import "MediaFileService.h"
#import "QliqUserDBService.h"

#import "QliqDBService.h"
#import "Constants.h"
#import "QliqGroup.h"
#import "QliqUser.h"
#import "FhirResources.h"

#import "ConversationDBService.h"
#import "QliqListService.h"
#import "ContactListConversationsDBService.h"
#import "ChatMessageService.h"

#import "EGORefreshTableHeaderView.h"

#import "UITableView+visibleCells.h"
#import "NSArray+RangeCheck.h"

#import "THContactPickerView.h"
#import "THContactPicker+Additions.h"
#import "ChatMessagesProvider.h"
#import "MessageAttachment.h"

#import "ContactsActionSheet.h"
#import "DetailContactInfoViewController.h"

#import "CallAlertService.h"
#import "FhirEncounterUpdateService.h"
#import "Multiparty.h"

#import "SearchPatientsViewController.h"
#import "UploadToEmrService.h"
#import "GetContactInfoService.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "GetPresenceStatusService.h"

#import "AlertController.h"

#import "UIDevice-Hardware.h"

#define kRefreshHeaderHeight 100.0f
#define PopOverAttachmentTag 100

#define kValueEditViewHeightWithKiteworks 201.f
#define kValueEditViewHeightWithoutKiteworks 170.f

//Keyboard Accessory View Constraints for iPhone X
#define kKeyboardAccessoryConstraintPortrait 0.f
#define kKeyboardAccessoryConstraintLandscape 35.f
#define kSubjectViewConstraintPortrait 15.f
#define kSubjectViewConstraintLandscape 35.f

//Contact Picker Constraints
#define kDefaultContactPickerHeightConstraint   30.f
#define kDefaultContactPickerTrallingConstraint 15.f
#define kDefaultContactPickerTopConstraint      10.f
#define kDefaultContactPickerLeadingConstraint  15.f

//Subject View Constraints
#define kDefaultSubjectViewHeightConstraint     30.f
#define kDefaultSubjectViewTrallingConstraint   15.f
#define kDefaultSubjectViewLeadingConstraint    15.f
#define kDefaultSubjectViewTopConstraint        10.f

#define kMinHeightOfChatsTable                                  80.f
#define kValueMinimumHeightKeyboardAccessoryView                36.f
#define kValueMinimumHeightKeyboardAccessoryViewWithAttachment  80.f
#define kMinimumHeightKeyboardAccessoryViewWithSelectAttachment 80.f
#define kValueMarginFromSubjectView                             20.f

#define kMaxHeightOfKeyboardAccessoryViewResignedFirstResponder 100.f

#define kValueEditViewCellHeight 30.f
#define kMessageAttachmentHeight 60.f
#define kValueDelayForMarkAsRead 0.5f
//Many time for marking messages as read 4/14/17
//#define kValueDelayForMarkAsRead 3.0f

typedef void (^BroadcastAskBlock)(void);

static NSString * kEventMessageIdentifier = @"EventMessageCell";

@interface THContactPickerView (hidden)

@property (nonatomic, strong) THContactTextField *textView;

@end

@interface ConversationViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
UIScrollViewDelegate,
UIAlertViewDelegate,
UITextViewDelegate,
ContactsActionSheetDelegate,
THContactPickerDelegate,
EGORefreshTableHeaderDelegate,
KeyboardAccessoryViewControllerDelegate,
QuickMessageDelegate,
ConversationCellDelegate,
SelectContactsViewControllerDelegate,
DetailContactInfoDelegate
>

/**
 IBOutlet
 */
@property (nonatomic, weak) IBOutlet UITableView *chatsTable;
@property (nonatomic, weak) IBOutlet UIView *editPopoverView;
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *editOptionButton;
@property (weak, nonatomic) IBOutlet UIView *navBarRightOptionView;
@property (weak, nonatomic) IBOutlet UIButton *phoneButton;
@property (nonatomic, weak) IBOutlet UIView *startConversationView;
@property (nonatomic, weak) IBOutlet UIView *keyboardAccessoryView;
@property (nonatomic, weak) IBOutlet UILabel *titleBackBtn;
@property (nonatomic, weak) IBOutlet UILabel *lastTimeBtn;
@property (nonatomic, weak) IBOutlet UIView *indicator;

@property (weak, nonatomic) IBOutlet UIView *navigationRightView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

//Start ConversationView
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (nonatomic, strong) IBOutlet THContactPickerView *contactPickerView;
@property (weak, nonatomic) IBOutlet UIView *subjectView;

@property (weak, nonatomic) IBOutlet UITextView *subjectTextView;

//Edit Table View
@property (weak, nonatomic) IBOutlet UITableView *editViewTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editPopoverHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editTableTopConstraint;

@property (strong, nonatomic) NSMutableArray *editViewTableContent;
@property (assign, nonatomic) CGFloat editViewTableContentHeight;

//BottomBar
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;

//Costraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatsTableBottomToAccessoryViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startConvViewBotToAccessoryViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accessoryViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightAccessoryViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightHeaderTitleNameLabelContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleBackWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;

//Contact Picker Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerTrallingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerLeadingConstraint;

@property (assign, nonatomic) CGFloat defaultContactPickerHeightConstraint;
@property (assign, nonatomic) CGFloat defaultContactPickerTrallingConstraint;
@property (assign, nonatomic) CGFloat defaultContactPickerTopConstraint;
@property (assign, nonatomic) CGFloat defaultContactPickerLeadingConstraint;

//Subject View Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectViewTrallingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectViewTopConstraint;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAccessoryLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAccessoryTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAccessoryBottomConstraint;

//UI
@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizerKeyboard;
@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;


@property (nonatomic, weak) KeyboardAccessoryViewController *downView;
@property (nonatomic, strong) ContactsActionSheet *sheet;
@property (nonatomic, strong) SelectContactsViewController *selectContactsViewController;
@property (weak, nonatomic) IBOutlet UIButton *navigationBarRightOptionalButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navBarRightOptionalButtonWidth;

@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGFloat lastKeyBoardShiftDelta;
@property (nonatomic, assign) CGFloat chatsTableBotToContentSizeHeightDelta;

//Data
@property (nonatomic, assign) BOOL isNotFirstReloadController;
@property (nonatomic, assign) BOOL isDeleteMode;
@property (nonatomic, assign) BOOL isForward;
@property (nonatomic, assign) BOOL isPagerMode;
@property (nonatomic, assign) BOOL isForeground;
@property (nonatomic, assign) BOOL isSingleFieldMode;

@property (nonatomic, assign) BOOL shouldSkipMarkAsRead;

@property (nonatomic, readwrite) NSUInteger pageSize;
@property (nonatomic, readwrite) NSUInteger pagesToLoad;

@property (nonatomic, strong) NSMutableArray *messagesArray;
@property (nonatomic, strong) NSMutableArray *selectedMessages;

@property (nonatomic, strong) NSString *selectedMessageUUID;

@property (nonatomic, assign) CGFloat keyboardAccessoryViewHeight;
@property (nonatomic, assign) CGFloat tableViewBottom;


/** Refresh Queue */
@property (nonatomic, strong) NSOperationQueue *refreshConversationOperationQueue;

@property (strong, nonatomic) CallAlertService *callAlertService;

//Services
@property (nonatomic, strong) ChatMessagesProvider *messagesProvider;


//Broadcasting
@property (nonatomic, copy) BroadcastAskBlock broadcastAskBlock;

@property (nonatomic, assign) BOOL needToAskAboutBroadcast;
@property (nonatomic, assign) BOOL shouldReaskAboutBroadcast;
@property (nonatomic, assign) BOOL needNotifyAboutFirstReplyToGroup;

@end

@implementation ConversationViewController

#pragma mark - Life Cycle -

- (void)dealloc
{
    //Remove Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAppNotifications];
    [self removeKeyboardNotifications];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self.refreshConversationOperationQueue];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self.refreshConversationOperationQueue cancelAllOperations];
    [self.refreshConversationOperationQueue waitUntilAllOperationsAreFinished];
    self.refreshConversationOperationQueue = nil;
    
    self.callAlertService = nil;
    self.phoneButton = nil;
    self.chatsTable.dataSource = nil;
    self.chatsTable.delegate = nil;
    self.chatsTable = nil;
    
    //UI
    self.gestureRecognizerKeyboard = nil;
    self.refreshHeaderView = nil;
    self.contactPickerView = nil;
    self.downView = nil;
    self.sheet = nil;
    
    self.pageSize = nil;
    self.pagesToLoad = nil;
    
    self.messagesArray = nil;
    self.selectedMessages = nil;
    self.selectedMessageUUID = nil;
    
    self.messagesProvider = nil;
    
    self.editViewTableContent = nil;
    self.broadcastAskBlock = nil;
}

- (void)configureDefaultText {
    
    //StartConversationView
    self.subjectLabel.text = [NSString stringWithFormat:@"%@ :", QliqLocalizedString(@"2032-TitleSubject")];
    //Bottom Bar
    [self.forwardButton setTitle:QliqLocalizedString(@"1108-TextForward")];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setInitialValues];
    
    {
        self.view.backgroundColor = [UIColor whiteColor];
//        self.view.backgroundColor = RGBa(224, 224, 224, 1);
        [self.navigationController.navigationBar setTranslucent:NO];
        
        self.needToAskAboutBroadcast = NO;
        self.shouldReaskAboutBroadcast = YES;
        self.shouldSkipMarkAsRead = NO;
        
        self.navigationBarRightOptionalButton.titleLabel.numberOfLines = 1;
        self.navigationBarRightOptionalButton.titleLabel.minimumScaleFactor = 10.f / self.navigationBarRightOptionalButton.titleLabel.font.pointSize;
        self.navigationBarRightOptionalButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    //EditView
    {
        self.editViewTableContent = [NSMutableArray new];
        [self updateEditView];
    }
    //Gesture
    {
        self.gestureRecognizerKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismisKeyboard:)];
        self.gestureRecognizerKeyboard.numberOfTapsRequired = 1;
    }
    //ChildView
    {
        for (UIViewController *controller in self.childViewControllers)
        {
            if ([controller isKindOfClass:[KeyboardAccessoryViewController class]])
                self.downView = (id)controller;
        }
        
        self.downView.delegate = self;
        self.accessoryViewBottomConstraint.constant = 0.f;
        self.downView.textView.maxHeight = [self getMaxHeightForKeyboardAccessoryView];
    }
    
    //Configure constraints for iPhone X
    {
        isIPhoneX {
            __weak typeof(self) weakSelf = self;
            dispatch_async_main(^{
                [weakSelf rotated:nil];
                [weakSelf.view layoutIfNeeded];
            });
        }
    }
    
    //RefreshHeaderView
    {
        self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0, -kRefreshHeaderHeight, self.chatsTable.bounds.size.width, kRefreshHeaderHeight)];
        self.refreshHeaderView.backgroundColor  = self.chatsTable.backgroundColor;
        self.refreshHeaderView.delegate         = self;
    }
    //TableView
    {
        self.chatsTable.delegate = self;
        self.chatsTable.dataSource = self;
        [self.chatsTable addSubview:self.refreshHeaderView];
        [self registerCells];
    }
    //StartConversationView
    {
        [self setConversationSettingsIsNewConversation:self.isNewConversation];
    }
    
    //RefreshQUEUE for handling new messages and changing messages status to isRead
    self.refreshConversationOperationQueue = [[NSOperationQueue alloc] init];
    self.refreshConversationOperationQueue.name = @"com.qliq.conversationViewController.refreshOperationQueue";
    self.refreshConversationOperationQueue.maxConcurrentOperationCount = 1;
    
    //Convesation
    {
        if (!self.isNewConversation)
        {
            if (self.isCareChannelMode)
            {
                if (!self.conversation.encounter)
                {
                    self.conversation.encounter = [FhirEncounterDao findOneWithUuid:self.conversation.uuid];
                }
            }
            else
            {
                Conversation *conversationFromDB = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:self.conversation.conversationId]];
                self.conversation = nil;
                self.conversation = conversationFromDB;
            }
            
            [self checkIfNeedToNotifyAboutFirstReplyInGroupConversation];
            
            [self reloadControllerAsync:YES];
        }
        else
        {
            self.contactPickerView.delegate = self;
            
            THBubbleStyle *style = [[THBubbleStyle alloc] initWithTextColor:kColorText
                                                                gradientTop:kColorGradientTop
                                                             gradientBottom:kColorGradientBottom
                                                                borderColor:kColorBorder
                                                                borderWidth:kDefaultBorderWidth
                                                         cornerRadiusFactor:kDefaultCornerRadiusFactor];
            
            THBubbleStyle *selectedStyle = [[THBubbleStyle alloc] initWithTextColor:kColorSelectedText
                                                                        gradientTop:kColorSelectedGradientTop
                                                                     gradientBottom:kColorSelectedGradientBottom
                                                                        borderColor:kColorSelectedBorder
                                                                        borderWidth:kDefaultBorderWidth
                                                                 cornerRadiusFactor:kDefaultCornerRadiusFactor];
            
            
            [self.contactPickerView setBubbleStyle:style selectedStyle:selectedStyle];
            self.contactPickerView.textView.tintColor = kQliqBlueColor;
            [self.contactPickerView setPromptLabelText:NSLocalizedString(@"2000-TitleTo:", nil)];
            [self.contactPickerView setPlaceholderLabelText:NSLocalizedString(@"2001-TitleWhoWouldYouLikeToText?", nil)];
            [self.contactPickerView setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.f]];
            
            self.subjectTextView.delegate = self;
            self.subjectTextView.textContainer.widthTracksTextView = YES;
            self.subjectTextView.textContainer.heightTracksTextView = YES;
            [self configureScrollingForSubjectView];
            if (self.subjectForNewConversation)
                self.subjectTextView.text = self.subjectForNewConversation;
            
            //Need ask about broadcast
            if ([self.recipients isGroup])
            {
                [self checkIfNeedToAskAboutBroadcast];
                self.shouldReaskAboutBroadcast = NO;
            }
        }
        
        if (self.messageForNewConversation) {
            self.downView.textView.text = self.messageForNewConversation;
        }
    }
    
    //Add attachment
    {
        if (self.attachment)
            [self.downView addAttachment:self.attachment];
    }
    
    //Notification
    [self addAppNotifications];
    [self addKeyboardNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContactsActionSheetDismissed:)
                                                 name:@"ContactsActionSheetDismissed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
    
    [self addMuteConversationNotification];
    [self addMessagesNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    /*Change constraint for iPhone X*/
    isIPhoneX {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [[[Presence alloc] init] setShouldAsk:self.isNewConversation ? NO : YES];
    
    self.isForeground = YES;

    if (self.navigationController.navigationBarHidden)
        [self.navigationController setNavigationBarHidden:NO];
    
    [self updateContactPickerView];
    [self configureController];
    
    [self updatePresenceStatusForAllParticipants];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //All notifications should be handled only after controller appears
    if(appDelegate.appInBackground)
        DDLogSupport(@"viewDidAppear called in BG. Do Nothing...");
    else
    {
        DDLogSupport(@"viewDidAppear called in FG. Marking as Read");
        if (!self.isNewConversation) {
            [self markMessagesAsReadWithDelay:YES];
        }
    }
    
    if (!self.isNotFirstReloadController)
    {
        self.isNotFirstReloadController = YES;
        //Put to input TextView unsent message from last time
        BOOL paste = [self pasteUnsentMessage];
        //Need For showing last message when controller viewDidLoad
        if (!self.isNewConversation)
        {
            if (paste) {
                // Need to wait until messagepasting animation will be finished, see KeyboardAccessoryView
                // 'growingTextView:willChangeHeight:' method
                __weak __block typeof(self) welf = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [welf scrollTableViewToBottomWithAnimation:YES];
                });
            }
            else {
                __weak __block typeof(self) welf = self;
                dispatch_async_main(^{
                    [welf scrollTableViewToBottomWithAnimation:YES];
                });
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //    [self.downView beginAppearanceTransition:NO animated:animated];
    
    //Self
    {
        [self.navigationController setNavigationBarHidden:YES];
        [self.view endEditing:YES];
        self.view.window.backgroundColor = [UIColor whiteColor]; //To avoid the black color in navigationbar
    }
    
    isIPhoneX {
        //Remove Notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [QliqConnectModule sharedQliqConnectModule].attachmentDelegate = nil;
    
    if (self.conversation)
    {
        [[NSUserDefaults standardUserDefaults] setValue:[self.downView currentMessage] forKey:[NSString stringWithFormat:@"%ld", (long)self.conversation.conversationId]];
    }
    
    [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:0.4f];
    //Mark Message as read
    [self markMessagesAsReadWithDelay:NO];
    
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        if (![SVProgressHUD isVisible])
            [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(showProgressHUD) object:nil];
        else
            [SVProgressHUD dismiss];
    });
    self.isForeground = NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (self.pagesToLoad > 1)
        self.pagesToLoad = 1;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (!self.isNewConversation)
        [self.chatsTable reloadData];
    [self configureNavigationTitleWidthWithOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (!self.isNewConversation)
        [self.chatsTable reloadData];
    else
        [self updateContactPickerView];
    
    [self updateEditView];
}

#pragma mark - Configure Methods -

- (void)setInitialValues {
    
    self.keyboardAccessoryViewHeight = self.heightAccessoryViewConstraint.constant;
    self.keyboardHeight = 0.f;
    self.tableViewBottom = 0.f;
    
    self.selectAllBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    
    self.selectedMessages = [NSMutableArray new];
    self.messagesArray = [NSMutableArray new];
}

- (void)updatePresenceStatusForAllParticipants {

    NSMutableArray *participants = self.conversation.recipients.recipientsArray;
    NSString *currentUserQliqID = [UserSessionService currentUserSession].user.qliqId;

    for (NSInteger index = 0; index < participants.count; index++) {

        QliqUser *user = participants[index];
        if (![user.qliqId isEqualToString:currentUserQliqID]) {

            dispatch_async_background(^{
                GetPresenceStatusService *getPresence = [[GetPresenceStatusService alloc] initWithQliqId: user.qliqId];
                getPresence.reason = @"conversation view";
                [getPresence callServiceWithCompletition:nil];
            });
        }
    }
}

#pragma mark - Notifications -

- (void)appWillResignActive:(NSNotification*)note
{
    [self.downView.view endEditing:YES];
}

#pragma mark * Managing Notifications *

- (void)addKeyboardNotifications
{
    DDLogSupport(@"Adding Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)removeKeyboardNotifications
{
    DDLogSupport(@"Removing Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

- (void)addNewChatNotification
{
    DDLogSupport(@"Adding new chat notification");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewChatMessagesNotification:)
                                                 name:NewChatMessagesNotification
                                               object:nil];
}

- (void)removeNewChatNotification
{
    DDLogSupport(@"Removing new chat notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NewChatMessagesNotification
                                                  object:nil];
}


- (void)addMuteConversationNotification
{
    DDLogSupport(@"Adding Mute Conversation notification");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMuteConversationNotification:)
                                                 name:ConversationMutedChangedNotification
                                               object:nil];
}

- (void)removeMuteConversationNotification
{
    DDLogSupport(@"Removing Mute Conversation notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ConversationMutedChangedNotification
                                                  object:nil];
}

- (void)addAppNotifications
{
    DDLogSupport(@"Adding app notifications");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationWillResignActiveNotification:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
}

- (void)removeAppNotifications
{
    DDLogSupport(@"Removing app notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
}

- (void)addMessagesNotifications
{
    DDLogSupport(@"Adding message notifications");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewChatMessagesNotification:)
                                                 name:NewChatMessagesNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRecipientsChangedNotification:)
                                                 name:RecipientsChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSipChatMessageAckNotification:)
                                                 name:SIPChatMessageAckNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleChatMessageStatus:)
                                                 name:ChatMessageStatusNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidDeleteMessageInConversationNotification:)
                                                 name:QliqConnectDidDeleteMessagesInConversationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadChatMessagesAfterMarkedAsRead:)
                                                 name:kMessagesSavedAsRead
                                               object:nil];
}

- (void)removeMessagesNotifications
{
    DDLogSupport(@"Removing message notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NewChatMessagesNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SIPChatMessageAckNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ChatMessageStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:QliqConnectDidDeleteMessagesInConversationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RecipientsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMessagesSavedAsRead object:nil];
}

#pragma mark * Handle Notifications *

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    if ([notification.userInfo[@"isForMyself"] boolValue] == NO)
    {
        __block __weak typeof(self) weakSelf = self;
        [self.refreshConversationOperationQueue addOperationWithBlock:^{
            NSString *qliqId = notification.userInfo[@"qliqId"];
            if ([weakSelf.conversation.recipients isSingleUser])
            {
                QliqUser *user = [weakSelf.conversation.recipients.recipientsArray lastObject];
                if ([user.qliqId isEqualToString:qliqId])
                {
                    user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                    performBlockInMainThread(^{
                        [weakSelf configureNavigationBar];
                    });
                }
            } else {

                NSMutableArray *participants = self.conversation.recipients.recipientsArray;
                for (NSInteger index = 0; index < participants.count; index++) {

                    QliqUser *user = participants[index];
                    if ([user.qliqId isEqualToString:qliqId]) {
                        user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];

                        [participants replaceObjectAtIndex:index withObject:user];
                        self.conversation.recipients.recipientsArray = participants;
                        break;
                    }
                }
            }
        }];
    }
}

- (void)onContactsActionSheetDismissed:(NSNotification *)note {
    if (note.object == self.sheet) {
        self.sheet = nil;
    }
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification
{
    DDLogSupport(@"handle Application Will Resign Active Notification");
    
    self.isForeground = NO;
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible])
        {
            DDLogSupport(@"Dismissing connecting progress indicator");
            [SVProgressHUD dismiss];
        }
    });
}

- (void)handleApplicationDidBecomeActiveNotification
{
    DDLogSupport(@"handle Application Did Become Active Notification");
    if (self.navigationController.topViewController == self && self.conversation && ![[ConversationDBService sharedService] isRead:self.conversation]) //Mark as read only when this viewcontroller is visible
    {
        __weak __block typeof(self) welf = self;
        VoidBlock markAsReadBlock = ^(void) {
            if (welf)
            {
                 [welf markAllMessagesAsReadAndRefresh];
            }
        };
        [self.refreshConversationOperationQueue performSelector:@selector(addOperationWithBlock:)
                                                     withObject:markAsReadBlock
                                                     afterDelay:kValueDelayForMarkAsRead];
    }

    [self reloadChatsTableAsync:YES force:NO completion:nil];
}

// Calls when new message are received
- (void)handleNewChatMessagesNotification:(NSNotification *)notification
{
    {
        Conversation * aConversation = (Conversation *) notification.object;
        if (aConversation.conversationId == self.conversation.conversationId)
        {
            __block __weak typeof(self) welf = self;
            if (([[ UIApplication sharedApplication ] applicationState] == UIApplicationStateActive) && (self.navigationController.topViewController == self))
            {
                if (![[ConversationDBService sharedService] isRead:self.conversation])
                {
                    VoidBlock markAsReadBlock =  ^(void) {
                        if (welf)
                        {
                            DDLogSupport(@"handleNewChatMessagesNotification: Marking as Read");
                            [welf markAllMessagesAsReadAndRefresh];
                        }
                    };
                    [self.refreshConversationOperationQueue performSelector:@selector(addOperationWithBlock:)
                                                                 withObject:markAsReadBlock
                                                                 afterDelay:kValueDelayForMarkAsRead];   
                }
            }
            
            [self reloadChatsTableAsync:YES force:NO completion:^{
                [welf scrollTableViewToBottomWithAnimation:YES];
            }];
        }
    }
}

- (void)handleMuteConversationNotification:(NSNotification *)notification {
    
    id item = notification.object;
    
    if (item && [item isKindOfClass:[Conversation class]]) {
        self.conversation.isMuted = ((Conversation *)item).isMuted;
        [self updateEditView];
    }
}

- (void)handleSipChatMessageAckNotification:(NSNotification *)notification
{
    NSDictionary *dictionary = [notification userInfo];
    NSString *uuid = [dictionary objectForKey:@"messageGuid"];
    __weak __block typeof(self) welf = self;
    [self.refreshConversationOperationQueue addOperationWithBlock:^{
        [welf editCellWithMessageUUID:uuid editBlock:^(ChatMessage *message) {
//            if (message)
//            {
//                NSInteger addTime = 1; //For ackedView. //AII
//                message.ackReceivedAt = message.ackReceivedAt +  addTime;
//            }
        }];
    }];
}

- (void)handleChatMessageStatus:(NSNotification *)notification
{
    ChatMessage *updatedMessage = [[notification userInfo] objectForKey:@"Message"];
    if (updatedMessage)
    {
        [self updateCellForMessage:updatedMessage];
    }
    else
    {
        DDLogSupport(@"Nil message received with sratus notification");
    }
}

- (void)handleRecipientsChangedNotification:(NSNotification *)notification
{
    Conversation *notificationConversation = notification.object;
    if (notificationConversation)
    {
        if (notificationConversation.conversationId == self.conversation.conversationId)
        {
            __weak __block typeof(self) welf = self;
            [self.refreshConversationOperationQueue addOperationWithBlock:^{
                Recipients * oldRecipients = welf.conversation.recipients;
                welf.conversation = [[ConversationDBService sharedService] getConversationWithId:[NSNumber numberWithInteger:self.conversation.conversationId]];
                
                if (!welf.conversation.encounter && [welf.conversation isCareChannel])
                    welf.conversation.encounter = [FhirEncounterDao findOneWithUuid:self.conversation.uuid];
                
                if (welf.conversation)
                {
                    if ([oldRecipients containsRecipient:[UserSessionService currentUserSession].user])
                    {
                        if (![welf isSelfUserRecipientElseShowAlert])
                            return;
                    }
                    else
                    {
                        if (welf.conversation.deleted)
                        {
                            performBlockInMainThread(^{
                                [welf onBack:nil];
                            });
                            return;
                        }
                    }
                    [welf reloadControllerAsync:YES];
                }
            }];
        }
    }
}

- (void)handleDidDeleteMessageInConversationNotification:(NSNotification *)notification
{
    Conversation *conv = [[notification userInfo] objectForKey:@"Conversation"];
    NSNumber *isRemoteDelete = [[notification userInfo] objectForKey:@"RemoteDelete"];
    
    if (conv.conversationId == self.conversation.conversationId)
    {
        QliqDBService * dbService = [[QliqDBService alloc] init];
        
        self.conversation = [dbService reloadObject:self.conversation];
        
        if (self.conversation.deleted) {
            
            __block __weak typeof(self) weakSelf = self;
            dispatch_async_main(^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
                NSString *text = NSLocalizedString(@"1050-TextConversationWasDeleted", nil);
                
                if ([isRemoteDelete boolValue] == YES) {
                    
                    text = [text stringByAppendingString:NSLocalizedString(@"1051-TextFromAnotherDevice", @"{The conversation was deleted}  from another device")];
                }
                
                [AlertController showAlertWithTitle:nil
                                            message:text
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex==1) {
                                                 [weakSelf onBack:nil];
                                             }
                                         }];
            });
        }
        
        self.messagesProvider = [[ChatMessagesProvider alloc] initWithConversationId:self.conversation.conversationId];
        __block __weak typeof(self) welf = self;
        [self getPages:self.pagesToLoad loadAsync:NO completionBlock:^(NSArray *newMessages) {
            [welf updateChatsTableForce:NO withMessages:newMessages completion:nil];
        }];
    }
}

#pragma mark * Keyboard Notification *

- (void)keyboardWillBeShown:(NSNotification*)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat offset = keyboardSize.height;
    
    isIPhoneX {
        offset = offset-30;
    }
    self.keyboardHeight = offset;
    
    if (![self.contactPickerView isContactPickerFirstResponder] && ![self.subjectTextView isFirstResponder])
        [self.downView showFlagView:YES pagerMode:self.isPagerMode withDuration:duration delay:0.0 options:options withCompletion:nil];
    else
        [self.downView showFlagView:NO pagerMode:self.isPagerMode withDuration:duration delay:0.0 options:options withCompletion:nil];
    
    if (!self.isSingleFieldMode) {
        __weak __block typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            weakSelf.accessoryViewBottomConstraint.constant = offset;
            [weakSelf.view layoutIfNeeded];
        } completion:nil];
    }
    
    [self updateEditView];
}

- (void)keyboardWasShown:(NSNotification*)notification
{

    if (self.isNewConversation)
        [self.startConversationView addGestureRecognizer:self.gestureRecognizerKeyboard];
    else
    {
        [self.chatsTable addGestureRecognizer:self.gestureRecognizerKeyboard];
        
        self.lastKeyBoardShiftDelta = self.keyboardHeight + (self.keyboardAccessoryViewHeight - 36.f);
        self.chatsTableBotToContentSizeHeightDelta = self.chatsTable.contentSize.height - self.chatsTable.contentOffset.y - self.chatsTable.frame.size.height;
        CGFloat offset = self.chatsTableBotToContentSizeHeightDelta < self.lastKeyBoardShiftDelta ? self.chatsTableBotToContentSizeHeightDelta : self.lastKeyBoardShiftDelta;
        [self scrollUpChatTableDown:YES offset:offset isSentMessage:NO animated:YES];
        self.chatsTableBotToContentSizeHeightDelta = 0.f;
    }
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat offset = keyboardSize.height;
    
    self.keyboardHeight = offset;
    
    [self updateEditView];
    
    /*
     post notification that keyboard was shown to the EGOTextView
     need for correct work of UIMenuController in EGOTextView
     24_02_16
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showTextViewMenuNotification" object:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    if (self.isNewConversation)
    {
        [self.startConversationView removeGestureRecognizer:self.gestureRecognizerKeyboard];
    }
    else
    {
        [self.chatsTable removeGestureRecognizer:self.gestureRecognizerKeyboard];
        self.chatsTableBotToContentSizeHeightDelta = self.chatsTable.contentSize.height - self.chatsTable.contentOffset.y - self.chatsTable.frame.size.height;
    }
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.keyboardHeight = 0.f;
    
    if (self.isDeleteMode)
    {
        self.accessoryViewBottomConstraint.constant = 0.f;
        [self.view layoutIfNeeded];
    }
    else
    {
        __weak __block typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
            weakSelf.accessoryViewBottomConstraint.constant = 0.f;
            [weakSelf.view layoutIfNeeded];
        } completion:nil];
    }
    
    [self.downView showFlagView:NO pagerMode:self.isPagerMode withDuration:duration delay:0.0 options:options withCompletion:nil];
    
}

- (void)keyboardWasHidden:(NSNotification*)notification
{
    if (!self.isNewConversation)
    {
        CGFloat offset = self.chatsTableBotToContentSizeHeightDelta < self.lastKeyBoardShiftDelta ? self.chatsTableBotToContentSizeHeightDelta : self.lastKeyBoardShiftDelta;
        [self scrollUpChatTableDown:NO offset:offset isSentMessage:NO animated:YES];
        self.chatsTableBotToContentSizeHeightDelta = 0.f;
    }
    
    self.keyboardHeight = 0.f;
    
    self.chatsTableBotToContentSizeHeightDelta = 0.f;
    
    [self updateEditView];
    
    /*
     post notification that keyboard was shown to the EGOTextView
     need for correct work of UIMenuController in EGOTextView
     24_02_16
     */
    
    if (self.isNewConversation) {
        if (self.subjectTextView.text.length > 0 && self.subjectTextView.contentOffset.y != 0.f)
        {
            [self.subjectTextView setContentOffset:CGPointZero animated:YES];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showTextViewMenuNotification" object:nil];
}

#pragma mark - Getters -

- (Recipients *)recipients {
    if (_recipients == nil) {
        _recipients = [[Recipients alloc] init];
    }
    
    return _recipients;
}

- (CallAlertService *)getCallAlertService {
    
    if (!_callAlertService) {
        _callAlertService = [[CallAlertService alloc] initWithPresenterViewController:self.navigationController];
    }
    
    return _callAlertService;
}

- (SelectContactsViewController *)selectContactsViewController {
    if (!_selectContactsViewController) {
        _selectContactsViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
        _selectContactsViewController.delegate = self;
        _selectContactsViewController.typeController = STForNewConversation;
    }
    return _selectContactsViewController;
}

#pragma mark - Setters -

- (void)setConversation:(Conversation *)conversation
{
    _conversation = conversation;
    self.isNewConversation = NO;
}

- (void)setNeedAskBroadcast:(BOOL)needAskBroadcast {
    __weak __block typeof(self) welf = self;
    self.broadcastAskBlock = ^(void){
        welf.needToAskAboutBroadcast = needAskBroadcast;
    };
}
#pragma mark - *
#pragma mark - Private -

- (void)rotated:(NSNotification*)notification {
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        
        self.subjectTextView.textContainerInset = UIEdgeInsetsMake(50.f, 20.f, 5.f, 0.f);
        self.contactPickerLeadingConstraint.constant = kSubjectViewConstraintLandscape;
        self.subjectViewLeadingConstraint.constant = kSubjectViewConstraintLandscape;
        self.keyboardAccessoryLeadingConstraint.constant = kKeyboardAccessoryConstraintLandscape;
        self.keyboardAccessoryTrailingConstraint.constant = kKeyboardAccessoryConstraintLandscape;
    } else {
        self.subjectTextView.textContainerInset = UIEdgeInsetsMake(5.f, 0.f, 5.f, 0.f);
        self.contactPickerLeadingConstraint.constant = kSubjectViewConstraintPortrait;
        self.subjectViewLeadingConstraint.constant = kSubjectViewConstraintPortrait;
        self.keyboardAccessoryLeadingConstraint.constant = kKeyboardAccessoryConstraintPortrait;
        self.keyboardAccessoryTrailingConstraint.constant = kKeyboardAccessoryConstraintPortrait;
    }
}

#pragma mark * -

#pragma mark Messages Table -

#pragma mark * Data Source *

typedef void(^UpdateTableBlock)(void);

- (void)getPages:(NSUInteger)numberPages loadAsync:(BOOL)async completionBlock:(void(^)(NSArray *newMessages))completion {
    
    NSRange rangeToLoad = NSMakeRange(0, 0);
    __block BOOL addToExisting = NO;
    
    /* Calc range to load */
    if (numberPages > self.pagesToLoad)
    {
        rangeToLoad.location = self.pagesToLoad * self.pageSize;
        rangeToLoad.length = (numberPages - self.pagesToLoad) * self.pageSize;
        addToExisting = YES;
    }
    else if (numberPages <= self.pagesToLoad)
    {
        rangeToLoad.location = 0;
        rangeToLoad.length = numberPages * self.pageSize;
    }
    else if (self.pagesToLoad == 0 && numberPages == 0)
    {
        return;
    }
    
    if (rangeToLoad.length > 0)
    {
        __weak __block typeof(self) welf = self;
        [self fetchMessagesInRange:rangeToLoad async:async completion:^(NSArray *newMessages) {
            if (addToExisting)
                newMessages = [newMessages arrayByAddingObjectsFromArray:welf.messagesArray];
            
            if (completion)
                completion(newMessages);
        }];
        self.pagesToLoad = numberPages;
    }
}

- (void)fetchMessagesInRange:(NSRange)rangeToLoad async:(BOOL)async completion:(void(^)(NSArray *newMessages))completion
{
    __block __weak typeof(self) welf = self;
    VoidBlock fetchMessagesBlock = ^{
        [welf.messagesProvider fetchMessagesInRange:rangeToLoad async:NO complete:^(NSArray *messages) {
            if (completion)
                completion(messages);
        }];
    };
    
    if (async)
    {
        performBlockOnQueue(!async, welf.refreshConversationOperationQueue, fetchMessagesBlock);
    }
    else
    {
        fetchMessagesBlock();
    }
}

#pragma mark * Update TableView

- (void)reloadChatsTableAsync:(BOOL)async force:(BOOL)force completion:(VoidBlock)completion
{
    NSRange rangeToLoad = { .location = 0, .length = self.pageSize * self.pagesToLoad };
    __weak __block typeof(self) welf = self;
    [self fetchMessagesInRange:rangeToLoad async:async completion:^(NSArray *newMessages) {
        [welf updateChatsTableForce:force withMessages:newMessages completion:completion];
    }];
}

- (void)updateChatsTableForce:(BOOL)force withMessages:(NSArray *)newMessages completion:(VoidBlock)completion
{
    __weak __block typeof(self) welf = self;
    if (force)
    {
        self.messagesArray = [NSMutableArray arrayWithArray:newMessages];
        dispatch_async_main(^{
            [welf.chatsTable reloadData];
        });
        if (completion)
            completion();
    }
    else
    {
        [self updateTableViewRowAnimatedWithNewMessages:newMessages];
        if (completion)
            completion();
    }
    [self configureController];
}

- (void)updateTableViewRowAnimatedWithNewMessages:(NSArray *)newMessages
{
    /* Calc rows changes for animating */
    NSMutableArray *indexesToRemove = [[NSMutableArray alloc] init];
    NSMutableArray *indexesToAdd = [[NSMutableArray alloc] init];
    
    NSMutableSet *dataSourceMessagesSet = [NSMutableSet setWithArray:self.messagesArray];
    NSMutableSet *newMessagesSet = [NSMutableSet setWithArray:newMessages];
    
    __block __weak typeof(self) weakSelf = self;
    [dataSourceMessagesSet enumerateObjectsUsingBlock:^(ChatMessage *message, BOOL *stop) {
        if (![newMessagesSet containsObject:message])
            [indexesToRemove addObject:[NSIndexPath indexPathForRow:[weakSelf.messagesArray indexOfObject:message] inSection:0]];
    }];
    
    [newMessagesSet enumerateObjectsUsingBlock:^(ChatMessage *message, BOOL *stop) {
        if (![dataSourceMessagesSet containsObject:message])
            [indexesToAdd addObject:[NSIndexPath indexPathForRow:[newMessages indexOfObject:message] inSection:0]];
    }];
    
    performBlockInMainThreadSync(^{
        
        weakSelf.messagesArray = [NSMutableArray arrayWithArray:newMessages];
        
        /* Update table */
//        @try {
            [weakSelf.chatsTable beginUpdates];
            [weakSelf.chatsTable deleteRowsAtIndexPaths:indexesToRemove withRowAnimation:UITableViewRowAnimationBottom];
            [weakSelf.chatsTable insertRowsAtIndexPaths:indexesToAdd withRowAnimation:UITableViewRowAnimationTop];
            [weakSelf.chatsTable endUpdates];
//        } @catch (NSException *exception) {
//            DDLogError(@"exception during updating table: %@",[exception reason]);
//            [weakSelf.chatsTable reloadData];
//        }
        
        [weakSelf configureSelectAllButtonTitle];
    });
}

#pragma mark * Update TableViewCell

static __inline__ void ReloadCellsInTable(UITableView *tableView, NSArray *indeciesToReload, UITableViewRowAnimation animation)
{
        if (indeciesToReload.count > 0)
            [tableView reloadRowsAtIndexPaths:indeciesToReload withRowAnimation:animation];
}

- (void)updateCellForMessage:(ChatMessage *)message {
    [self updateCellForMessage:message animation:UITableViewRowAnimationNone];
}

- (void)updateCellForMessage:(ChatMessage *)message animation:(UITableViewRowAnimation)animation {
    NSIndexPath *indexPath = [self indexPathMessage:message];
    
    if (indexPath && [self.messagesArray containsIndex:indexPath.row])
    {
        __weak __block typeof(self) welf = self;
        dispatch_async_main(^{
            [welf.messagesArray replaceObjectAtIndex:indexPath.row withObject:message];
            ReloadCellsInTable(welf.chatsTable, @[indexPath], animation);
        });
    }
    else
    {
        [self reloadChatsTableAsync:YES force:YES completion:^{
            [self scrollTableViewToBottomWithAnimation:YES];
        }];
    }
}

- (void)updateCellForAttachment:(MessageAttachment *)attachment {
    
    NSIndexPath *indexPath = [self indexPathForMessageUUID:attachment.messageUuid];
    
    ConversationTableViewCell *cell = (ConversationTableViewCell *)[self.chatsTable visibleCellAtIndexPath:indexPath];
    if (cell) {
        [cell.attachmentImage setAttachment:attachment];
    }
    
    if(indexPath && [self.messagesArray containsIndex:indexPath.row]){
        ReloadCellsInTable(self.chatsTable, @[indexPath], UITableViewRowAnimationNone);
    }
}

- (void)updateTableWithReplacingMessages:(NSArray *)messages animation:(UITableViewRowAnimation)animation
{
    __block NSMutableArray *indexPathsToReload = [NSMutableArray array];
    __block NSMutableArray *messagesToReplace = [NSMutableArray arrayWithArray:messages];
    __block NSMutableArray *replaceIndexes = [NSMutableArray array];
    
    [self.messagesArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ChatMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        
        ChatMessage *removeMsg = nil;
        
        for (ChatMessage *replaceMessage in messagesToReplace) {
            if ([message.callId isEqualToString:replaceMessage.callId])
            {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                [replaceIndexes addObject:replaceMessage];
                removeMsg = replaceMessage;
                break;
            }
        }
        
        if (removeMsg)
            [messagesToReplace removeObject:removeMsg];
        
        if (messagesToReplace.count == 0)
            *stop = YES;
    }];
    
    if (indexPathsToReload.count > 0) {
        
        __weak __block typeof(self) welf = self;
        dispatch_async_main(^{
            for (NSIndexPath *idxPth in indexPathsToReload)
            {
                [welf.messagesArray replaceObjectAtIndex:idxPth.row withObject:[replaceIndexes objectAtIndex:[indexPathsToReload indexOfObject:idxPth]]];
            }
            ReloadCellsInTable(welf.chatsTable, indexPathsToReload, animation);
        });
    } else {
        [self updateCellForMessage:messages.lastObject];
    }
}

- (void)editCellWithMessageUUID:(NSString *)uuid editBlock:(void(^)(ChatMessage *message))editBlock
{
    __block ChatMessage *message = [self messageWithUUID:uuid];
    if (!message)
    {
        /* If haven't visible message with requested UUID - don't do anything */
        return;
    }
    
    NSIndexPath *indexPath = [self indexPathMessage:message];
    ChatMessage * dbMessage = [ChatMessageService getMessageWithUuid:message.callId];
    if (dbMessage)
        message = dbMessage;
    else
        DDLogSupport(@"No message with call_id - %@ in DB", message.callId);
    
    if (indexPath)
    {
        if (editBlock) {
            editBlock(message);
        }
        
        __weak typeof(self) weakSelf = self;
        dispatch_async_main(^{
            if ([weakSelf.messagesArray containsIndex:indexPath.row]) {
                [weakSelf.messagesArray replaceObjectAtIndex:indexPath.row withObject:message];
            }
            ReloadCellsInTable(weakSelf.chatsTable, @[indexPath], UITableViewRowAnimationNone);
        });
    }
    else
    {
        [self reloadChatsTableAsync:YES force:YES completion:nil];
    }
}

- (void)changeSelectionOfItemAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    ChatMessage *message = self.messagesArray[indexPath.row];
    NSSet *selectedMessagesSet = [NSSet setWithArray:self.selectedMessages];
    
    if ([selectedMessagesSet containsObject:message])
        [self.selectedMessages removeObject:message];
    else
    {
        if (self.isForward)
        {
            [self.selectedMessages removeAllObjects];
            [self.selectedMessages addObject:message];
        }
        else
            [self.selectedMessages addObject:message];
    }
    
    [self configureSelectAllButtonTitle];
    [self.chatsTable reloadData];
}

#pragma mark * Marking messages as read *

- (void)reloadChatMessagesAfterMarkedAsRead:(NSNotification *)notification {
    self.conversation.isRead = [[ConversationDBService sharedService] isRead:self.conversation];
    [self reloadChatsTableAsync:YES force:YES completion:nil];
}

- (void)markMessagesAsReadWithDelay:(BOOL)withDelay
{
    if (self.conversation && ![[ConversationDBService sharedService] isRead:self.conversation])
    {
        DDLogInfo(@"Marked messages as read");
        if (withDelay)
        {
            __weak __block typeof(self) weakSelf = self;
            VoidBlock markAsReadBlock = ^(void) {
                if (weakSelf)
                {
                    [weakSelf markAllMessagesAsReadAndRefresh];
                }
            };
            
            [self.refreshConversationOperationQueue performSelector:@selector(addOperationWithBlock:)
                                                         withObject:markAsReadBlock
                                                         afterDelay:kValueDelayForMarkAsRead];
        }
        else
        {
            @synchronized (self) {
                self.shouldSkipMarkAsRead = YES;
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self.refreshConversationOperationQueue];
//            [self.refreshConversationOperationQueue cancelAllOperations];
//            [self.refreshConversationOperationQueue waitUntilAllOperationsAreFinished];
            [[ConversationDBService sharedService] markAllMessagesAsRead:self.conversation];
        }
    }
}

- (void)showProgressHUD
{
    [SVProgressHUD show];
}

- (void)markAllMessagesAsReadAndRefresh {
    BOOL shouldSkip = NO;
    @synchronized (self) {
        shouldSkip =  self.shouldSkipMarkAsRead;
    }
    if (!shouldSkip)
    {
        [[ConversationDBService sharedService] markAllMessagesAsRead:self.conversation];
        [self reloadChatsTableAsync:NO force:YES completion:nil];
    } else {
        DDLogSupport(@"markAllMessagesAsReadAndRefresh: Skipping");
    }
}

#pragma mark * Helpers

- (NSIndexPath *)indexPathMessage:(ChatMessage *)message {
    NSUInteger row = [self.messagesArray indexOfObject:message];
    if ([self.messagesArray containsIndex:row])
         return [NSIndexPath indexPathForRow:row inSection:0];
    
    return nil;
}

- (NSIndexPath *)indexPathForMessageUUID:(NSString *)messageUUID
{
    __block NSIndexPath *resultIndex = nil;
    [self.messagesArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ChatMessage *message, NSUInteger row, BOOL *stop) {
        if ([message.uuid isEqualToString:messageUUID])
        {
            resultIndex = [NSIndexPath indexPathForRow:row inSection:0];
            *stop = YES;
        }
    }];
    
    return resultIndex;
}

- (ChatMessage *)messageWithUUID:(NSString *)uuid
{
    __block ChatMessage *returnMessage = nil;
    [self.messagesArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ChatMessage *message, NSUInteger row, BOOL *stop) {
        if ([message.uuid isEqualToString:uuid])
        {
            returnMessage = message;
            *stop = YES;
        }
    }];
    
    return returnMessage;
}

#pragma mark * Chats methods (from ChatView)
- (void)reloadToShowMessage:(ChatMessage *)message async:(BOOL)async
{
    }

- (void)reloadCellWithNotificationMessageUUID:(NSNotification *)notification
{
    NSString *uuid = [[notification userInfo] objectForKey:@"messageUuid"];
    [self reloadCellWithMessageUUID:uuid];
}

#pragma mark -

- (void)checkIfNeedToNotifyAboutFirstReplyInGroupConversation
{
    BOOL needNotify = NO;
    
    if (self.conversation.recipients && !self.isNewConversation) {
        if ([self.conversation.recipients isGroup]) {
            if (!(self.conversation.isBroadcast && [self.conversation isReceivedBroadcast])) {
                needNotify = ![DBHelperConversation hasUserWithId:[UserSessionService currentUserSession].user.qliqId alreadySentMessageForConversation:self.conversation.conversationId];
            }
        }
    }
    else if (self.recipients)
    {
        //Should be checked in updateContactPickerView
        //        if ([self.recipients isGroup]) {
        needNotify = YES;
        //        }
    }
    self.needNotifyAboutFirstReplyToGroup = needNotify;
}

- (void)checkIfNeedToAskAboutBroadcast
{
    if (self.broadcastAskBlock)
    {
        self.broadcastAskBlock();
    }
    else
    {
        self.needToAskAboutBroadcast = YES;
    }
}


- (BOOL)isSelfUserRecipientElseShowAlert
{
    BOOL isRecipient = NO;
    
    if ([self.conversation.recipients isMultiparty]) {
        isRecipient = [self.conversation.recipients containsRecipient:[UserSessionService currentUserSession].user];
    }
    else
    {
        isRecipient = YES;
    }
    
    if (!isRecipient && self.isForeground) {
        performBlockInMainThread(^{
            __block __weak typeof(self) weakSelf = self;
            NSString *message = nil;
            
            if (self.conversation.subject == nil || [self.conversation.subject length] == 0) {
                message = QliqLocalizedString(@"10491-TextYouDeletedFromConversation");
            } else {
                message = QliqFormatLocalizedString1(@"1049-TextYouDeletedFromConversation{ConversationName}", self.conversation.subject);
            }
            
            [AlertController showAlertWithTitle:nil
                                        message:message
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex==1) {
                                             dispatch_async_main(^{
                                                 [weakSelf onBack:nil];
                                             });
                                         }
                                     }];
        });
    }
    
    return isRecipient;
}

- (BOOL)checkConversationForPagerOnlyUsers {
    BOOL isPagerMode = NO;
    
    BOOL isBroadcast = self.conversation ? self.conversation.isBroadcast : self.isBroadcastConversation;
    BOOL isGroup = self.conversation.recipients ? self.conversation.recipients.isGroup : self.recipients.isGroup;
    BOOL isMultiparty = self.conversation.recipients ? self.conversation.recipients.isMultiparty:self.recipients.isMultiparty;
    BOOL isSingleUser = self.conversation.recipients ? self.conversation.recipients.isSingleUser:self.recipients.isSingleUser;
    
    if (isGroup)
    {
        if (self.conversation)
        {
            // For existing conversation we keep the already present state
            isPagerMode = (self.conversation.broadcastType == PlainTextBroadcastType);
        }
        else
        {
            QliqGroup *group = self.conversation.recipients ? (QliqGroup *)self.conversation.recipients.recipient : (QliqGroup *)self.recipients.recipient;
            BOOL hasPagerUsers = [group hasPagerUsers];
            
            if (hasPagerUsers) {
                if (isBroadcast) {
                    isPagerMode = hasPagerUsers;
                } else {
                    
                    [AlertController showAlertWithTitle:nil
                                                message:QliqLocalizedString(@"2373-GroupMessagesForPagerUsers")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:^(NSUInteger buttonIndex) {
                                                 if (buttonIndex ==1) {
                                                     [self onBack:nil];
                                                 }
                                             }];
                }
            }
        }
    } else if (isMultiparty) {
        
        NSArray *recipients = self.conversation.recipients ? [self.conversation.recipients allRecipients] : [self.recipients allRecipients];
        
        for (id item in recipients) {
            if ([item isKindOfClass:[QliqUser class]]) {
                if (((QliqUser*)item).isPagerUser){
                    isPagerMode = YES;
                    break;
                }
            }
        }
        
    }
    else if (isSingleUser)
    {
        QliqUser *user = self.conversation.recipients ? (QliqUser *)self.conversation.recipients.recipient : (QliqUser *)self.recipients.recipient;
        isPagerMode = user.isPagerUser;
    }
    
    self.isPagerMode = isPagerMode;
    [self.downView hiddenPagerOnlyView:!self.isPagerMode];
    
    if (self.isPagerMode)
    {
        if ([self.downView.textView.internalTextView isFirstResponder])
            [self.downView showFlagView:YES pagerMode:self.isPagerMode withDuration:0.25 delay:0.0 options:nil withCompletion:nil];
        else
            [self.downView showFlagView:NO pagerMode:self.isPagerMode withDuration:0.25 delay:0.0 options:nil withCompletion:nil];
    }
    
    return isPagerMode;
}

- (void)saveUnsentMessage:(NSString *)message {
    if (self.conversation) {
        NSString *key = [NSString stringWithFormat:@"%ld", (long)self.conversation.conversationId];
        
        [[NSUserDefaults standardUserDefaults] setObject:message forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)pasteUnsentMessage {
    if (self.conversation) {
        NSString *key = [NSString stringWithFormat:@"%ld", (long)self.conversation.conversationId];
        NSString *message = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        
        if (message && ![message isEqualToString:@""]) {
            __weak __block typeof(self) welf = self;
//            [self.downView clearMessageTextWithCompletion:^{
                [welf.downView appendMessageText:message];
//            }];
            return YES;
        }
    }
    return NO;
}

- (void)reloadControllerAsync:(BOOL)async
{
    [self configureController];
    
    //MessageProvider
    if (!self.isNewConversation)
    {
         [self setupMessageProvider];
        __weak __block typeof(self) welf = self;
        [self getPages:self.pagesToLoad loadAsync:async completionBlock:^(NSArray *messages) {
            [welf updateChatsTableForce:NO withMessages:messages completion:^{
                performBlockInMainThread(^{
                    [welf scrollTableViewToBottomWithAnimation:YES];
                });
            }];
        }];
    }
}

- (void)setupMessageProvider {
    if (!self.messagesProvider) {
        self.messagesProvider = [[ChatMessagesProvider alloc] initWithConversationId:self.conversation.conversationId];
    }
    self.pageSize = 10;  // count of messages loads with conversation opening
    self.pagesToLoad = 1;
}

- (void)configureController
{
    __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [weakSelf checkConversationForPagerOnlyUsers];
        [weakSelf configureNavigationBar];
        [weakSelf setConversationSettingsIsNewConversation:self.isNewConversation];
        [weakSelf showToolbar:weakSelf.isDeleteMode];
    });
}

- (void)updateContactPickerView {
    if (!self.isNewConversation) {
        return;
    }
    
    [self.contactPickerView removeAllContacts];
    
    NSArray *allRecipients = [self.recipients allRecipientsWithoutCurrentUser];
    
    for (id contact in allRecipients)
    {
        if ([contact isKindOfClass:[QliqGroup class]])
        {
            QliqGroup *group = contact;
            [self.contactPickerView addContact:contact withName:group.name];
        }
        else if([contact isKindOfClass:[QliqUser class]])
        {
            QliqUser *user = contact;
            NSString *name = [NSString stringWithFormat:@"%@, %@",user.lastName, user.firstName];
            [self.contactPickerView addContact:contact withName:name];
        }
    }
    
    if ([self.recipients isGroup]) {
        [self checkIfNeedToNotifyAboutFirstReplyInGroupConversation];
        if (self.shouldReaskAboutBroadcast)
        {
            self.broadcastAskBlock = nil;
            self.needToAskAboutBroadcast = YES;
        }
        self.shouldReaskAboutBroadcast = YES;
    }
    else
    {
        self.needNotifyAboutFirstReplyToGroup = NO;
        self.needToAskAboutBroadcast = NO;
    }
    
    if (!self.isNotFirstReloadController)
    {
        self.defaultContactPickerHeightConstraint = self.contactPickerHeightConstraint.constant;
        self.defaultContactPickerTrallingConstraint = self.contactPickerTrallingConstraint.constant;
        self.defaultContactPickerTopConstraint = self.contactPickerTopConstraint.constant;
        self.defaultContactPickerLeadingConstraint = self.contactPickerLeadingConstraint.constant;
    }
}

- (void)setConversationSettingsIsNewConversation:(BOOL)isNewConversation
{
    if (isNewConversation)
    {
        self.startConversationView.hidden   = NO;
        self.chatsTable.hidden = YES;
        self.keyboardAccessoryView.hidden   = NO;
        self.toolbar.hidden                 = YES;
        self.navigationRightView.hidden     = YES;
        CGFloat heightWhenCreateConversation = 33.f;
        self.heightHeaderTitleNameLabelContraint.constant = heightWhenCreateConversation;
        
        [self checkViewforGestureRecognizer:self.startConversationView];
    }
    else
    {
        self.startConversationView.hidden   = YES;
        self.chatsTable.hidden = NO;
        self.keyboardAccessoryView.hidden   = NO;
        self.toolbar.hidden                 = YES;
        self.navigationRightView.hidden     = NO;
        CGFloat defaultHeight = 21.f;
        self.heightHeaderTitleNameLabelContraint.constant = defaultHeight;
        
        if ([[self.startConversationView gestureRecognizers] containsObject:self.gestureRecognizerKeyboard])
            [self.startConversationView removeGestureRecognizer:self.gestureRecognizerKeyboard];
        
        [self checkViewforGestureRecognizer:self.chatsTable];
    }
}

- (void)checkViewforGestureRecognizer:(UIView *)view
{
    if (self.gestureRecognizerKeyboard)
    {
        if ([self.downView.textView.internalTextView isFirstResponder])
        {
            if(![[view gestureRecognizers] containsObject:self.gestureRecognizerKeyboard])
                [view addGestureRecognizer:self.gestureRecognizerKeyboard];
        }
        else
        {
            if([[view gestureRecognizers] containsObject:self.gestureRecognizerKeyboard])
                [view removeGestureRecognizer:self.gestureRecognizerKeyboard];
        }
    }
}

- (BOOL)isGroupOrMultiplyConversation {
    return self.conversation.recipients.isGroup || [self.conversation.recipients isMultipartyWithoutCurrentUser];
}

- (void)startNewConversationWithRecipients:(Recipients *)recipients
                           withMessageText:(NSString *)messageText
                           withSubjectText:(NSString *)subjectText
                     withMessageAttachment:(MessageAttachment *)messageAttachment
                             broadcastType:(BroadcastType)broadcastType
{
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.delegate = self.delegate;
    controller.isNewConversation = YES;
    if (broadcastType != NotBroadcastType) {
        controller.isBroadcastConversation = YES;
        if (broadcastType == PlainTextBroadcastType) {
            controller.isPagerMode = YES;
        }
    }
    if (messageText) {
        controller.messageForNewConversation = messageText;
    }
    if (subjectText) {
        controller.subjectForNewConversation = subjectText;
    }
    if (messageAttachment) {
        controller.attachment = messageAttachment;
    }
    if (recipients) {
        controller.recipients = recipients;
    }
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)updateCurrentConversationWithRecipients:(Recipients *)recipients
                                withSubjectText:(NSString *)subjectText
                                      withRoles:(NSDictionary *)participantsRoles
{
    if (!self.conversation) {
        DDLogError(@"Current conversation can not be empty");
    }
    if (!recipients) {
        DDLogError(@"Recipients for modify conversation can not be empty");
    }
    
    NSAssert(self.conversation, @"Current conversation can not be empty");
    NSAssert(recipients, @"Recipients for modify conversation can not be empty");
    
    __block BOOL done = NO;
    __block BOOL progressHUDShowed = NO;
    
    //check if all recipients are valid QliqUser objects - qliqId should not be nil. If not valid - remove them from recipients list.
    __block NSMutableArray *nonQliqUsers = [@[] mutableCopy];
    [recipients.allRecipients enumerateObjectsUsingBlock:^(QliqUser *obj, NSUInteger idx, BOOL *stop) {
        
        if (0 == obj.qliqId.length) {
            [nonQliqUsers addObject:obj];
        }
    }];
    
    if (nonQliqUsers.count) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1052-TextUnableModifyConversation")
                                    message:QliqLocalizedString(@"1053-TextCannotAddNon-qliqUser")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
        return;
    }
    
    dispatch_async_main(^{
        if (!done) {
            progressHUDShowed = YES;
            NSString *title = @"";
            
            if ([self.conversation isCareChannel]) {
                title = QliqLocalizedString(@"2368-TextModifyingCareChannel");
            } else {
                title = NSLocalizedString(@"1904-TextModifyingConversation", nil);
            }
            
            [SVProgressHUD showWithStatus:title];
        }
    });
    
    __block __weak typeof(self) weakSelf = self;
    if (self.conversation.isCareChannel)
    {
        NSMutableSet<FhirParticipant *> *participants = [NSMutableSet new];
        [recipients.allRecipients enumerateObjectsUsingBlock:^(QliqUser *u, NSUInteger idx, BOOL *stop) {
            
            if (u.qliqId.length > 0) {
                FhirPractitioner *doctor = [FhirPractitioner new];
                doctor.qliqId = u.qliqId;
                doctor.uuid = doctor.qliqId;
                doctor.firstName = u.firstName;
                doctor.middleName = u.middleName;
                doctor.lastName = u.lastName;
                
                NSString *role = @"";
                
                if (participantsRoles) {
                    if ([participantsRoles valueForKey:doctor.qliqId]) {
                        role = participantsRoles[doctor.qliqId];
                    }
                }
                
                FhirParticipant *participant = [[FhirParticipant alloc] initWithPractitioner:doctor andTypeText:role];
                [participants addObject:participant];
            }
        }];
        
        FhirEncounter *encounter = [FhirEncounterDao findOneWithUuid:self.conversation.uuid];
        NSString *json = [encounter rawJsonWithReplacedParticipants:participants];
        FhirEncounterUpdateService *webService = [[FhirEncounterUpdateService alloc] initWithId:encounter.uuid andJson:json];
        [webService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            dispatch_async_main(^{
                if (progressHUDShowed) {
                    [SVProgressHUD dismiss];
                }
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf reloadChatsTableAsync:YES force:YES completion:nil];
                if (status != CompletitionStatusSuccess) {
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                message:[error localizedDescription]
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:nil];
                }
            });
        }];
        
    } else {
        
        [[QliqConnectModule sharedQliqConnectModule] modifyConversation:self.conversation byRecipients:recipients andSubject:subjectText complete:^(CompletitionStatus status, Conversation * modifiedConversation, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                DDLogSupport(@"block preempted");
            } else {
                BOOL conversationChanged = (strongSelf.conversation != modifiedConversation);
                performBlockInMainThread(^{
                    done = YES;
                    if (progressHUDShowed) {
                        [SVProgressHUD dismiss];
                    }
                    
                    if (error) {
                        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                    message:[error localizedDescription]
                                                buttonTitle:nil
                                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                 completion:nil];
                    } else {
                        strongSelf.conversation = modifiedConversation;
                        if (conversationChanged) {
                            [strongSelf reloadChatsTableAsync:YES force:YES completion:nil];
                        }
                    }
                });
            }
        }];
    }
}

- (void)configureScrollingForSubjectView {
    
    CGSize neededSizeForTextView = [self.subjectTextView sizeThatFits:CGSizeMake(self.subjectTextView.frame.size.width, CGFLOAT_MAX)];
    
    if (neededSizeForTextView.height > self.subjectTextView.frame.size.height && !self.subjectTextView.scrollEnabled)
    {
        self.subjectTextView.scrollEnabled = YES;
        [self.subjectTextView flashScrollIndicators];
        
    }
    else if (neededSizeForTextView.height <= self.subjectTextView.frame.size.height && self.subjectTextView.scrollEnabled)
    {
        self.subjectTextView.scrollEnabled = NO;
    }
}

- (void)showContactPickerViewInSingleMode {
    DDLogSupport(@"Show ContactPicker in the Single View Mode");
    if (![self.contactPickerView isContactPickerFirstResponder]) {
        [self.contactPickerView becomeFirstResponder];
    }
    
    if ([self.downView needToTurnOffSingleFieldMode])
    {
        [self.view endEditing:YES];
        [self.contactPickerView becomeFirstResponder];
    }
    else
    {
        [self configureNavBarRightOptionButtonTitle:QliqLocalizedString(@"2393-TitleEditSubject")];
        
        self.contactPickerTopConstraint.constant = 0.f;
        self.contactPickerHeightConstraint.constant = self.view.frame.size.height - self.keyboardHeight;
        self.accessoryViewBottomConstraint.constant = 0.f;
        
        self.contactPickerView.hidden = NO;
        self.subjectView.hidden = YES;
        self.keyboardAccessoryView.hidden = YES;
    }
}

- (void)showSubjectViewInSingleMode {
    
    DDLogSupport(@"Show SubjectView in the Single View Mode");
    
    if (![self.subjectTextView isFirstResponder])
        [self.subjectTextView becomeFirstResponder];
    
    if ([self.downView needToTurnOffSingleFieldMode])
    {
        [self.view endEditing:YES];
        [self.subjectTextView becomeFirstResponder];
    }
    else
    {
        [self configureNavBarRightOptionButtonTitle:QliqLocalizedString(@"2392-TitleEditMessage")];
        
        self.contactPickerTopConstraint.constant = - self.contactPickerHeightConstraint.constant - self.subjectViewTopConstraint.constant;
        self.subjectViewHeightConstraint.constant = self.view.frame.size.height - self.keyboardHeight;
        self.accessoryViewBottomConstraint.constant = 0.f;
        
        self.subjectView.hidden = NO;
        self.contactPickerView.hidden = YES;
        self.keyboardAccessoryView.hidden = YES;
        
        [self configureScrollingForSubjectView];
    }
}

- (void)showKeyboardAccessoryViewInSingleMode {
    
    DDLogSupport(@"Show KeyboardAccessoryView in the Single View Mode");
    
    if (![self.downView.textView.internalTextView isFirstResponder])
        [self.downView.textView.internalTextView becomeFirstResponder];
    
    if ([self.downView needToTurnOffSingleFieldMode])
    {
        [self.view endEditing:YES];
        [self.downView.textView.internalTextView becomeFirstResponder];
    }
    else
    {
        
        [self configureNavBarRightOptionButtonTitle:QliqLocalizedString(@"2186-TitleEditParticipants")];
        
        CGFloat freeSpace = self.view.frame.size.height - self.keyboardHeight;
        self.contactPickerTopConstraint.constant = - self.contactPickerHeightConstraint.constant - self.subjectViewTopConstraint.constant - self.subjectViewHeightConstraint.constant;
        self.accessoryViewBottomConstraint.constant = self.keyboardHeight;
        [self.downView setupKAVForSingleFieldModeWithFreeSpace:freeSpace];
        
        self.keyboardAccessoryView.hidden = NO;
        self.subjectView.hidden = YES;
        self.contactPickerView.hidden = YES;
    }
}

- (void)showUploadOptionsForConversation:(Conversation *)conversation {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allMessages = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2433-TitleUploadAllMessages")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *particularMessages = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2434-TitleUploadParticularMessages")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
//    UIAlertAction *media = [UIAlertAction actionWithTitle:NSLocalizedString(@"2433-TitleUploadMedia", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        
//    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                     style:UIAlertActionStyleDestructive
                                                   handler:nil];
    
    [alert addAction:allMessages];
    [alert addAction:particularMessages];
//    [alert addAction:media];
    [alert addAction:cancel];
    
    alert.preferredContentSize = CGSizeMake(450, 350);
    alert.popoverPresentationController.sourceView =self.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds)-50, 0, 0);
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark * NavigationBar *

- (void)configureNavBarRightOptionButtonTitle:(NSString *)title
{
    performBlockInMainThread(^{
        if (self.isSingleFieldMode)
            self.navBarRightOptionalButtonWidth.constant = 120.f;
        else
            self.navBarRightOptionalButtonWidth.constant = 70.f;
        
        [self.navigationController.navigationBar layoutSubviews];
        
        [self.navigationBarRightOptionalButton setTitle:title forState:UIControlStateNormal];
        [self.navigationBarRightOptionalButton setTitle:title forState:UIControlStateHighlighted];
        
        [self.navigationBarRightOptionalButton.titleLabel sizeToFit];
    });
}

- (void)configureNavigationBar
{
    FhirEncounter *encounter = nil;
    if (self.isCareChannelMode) {
        encounter = [FhirEncounterDao findOneWithUuid:self.conversation.uuid];
    }
    
    if (self.isSingleFieldMode && self.isNewConversation) {
        
        self.titleBackBtn.text = QliqLocalizedString(@"49-ButtonBack");
        
        self.lastTimeBtn.hidden = YES;
        [self showIndicatorIfNeeded];
        
        self.navBarRightOptionView.hidden = YES;
        self.navigationRightView.hidden   = NO;
        
        self.navigationBarRightOptionalButton.hidden = !self.isNewConversation;
        
    } else {
        self.navigationBarRightOptionalButton.hidden = YES;
        self.navBarRightOptionView.hidden = self.isNewConversation;
        //PresenceIndicator
        {
            id firstRecipient = [[self.conversation.recipients allRecipientsWithoutCurrentUser] lastObject];
            if ([firstRecipient isKindOfClass:[QliqUser class]]) {
                self.indicator.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:[[[self.conversation.recipients allRecipients] lastObject] presenceStatus]];
            }
            
            [self showIndicatorIfNeeded];
        }
        
        //Tittle Back
        {
            BOOL isBroadcast    = self.isBroadcastConversation;
            BOOL isGroup        = [self.recipients isGroup];
            
            if ([self.conversation.recipients allRecipientsWithoutCurrentUser].count > 0) {
                id item = [[self.conversation.recipients allRecipientsWithoutCurrentUser] firstObject];
                isGroup = [item isKindOfClass:[QliqGroup class]];
            }
            
            self.phoneButton.hidden = isGroup && !self.isDeleteMode ? isGroup:self.isDeleteMode;
            
            if (!isGroup)
            {
                isBroadcast = NO;
            }
            
            self.isBroadcastConversation = isBroadcast;
            
            NSString *title = @"";
            
            if (self.isNewConversation) {
                title = isGroup ? (isBroadcast ? QliqLocalizedString(@"2190-TitleBroadcastConversation") : QliqLocalizedString(@"2191-TitleGroupConversation")) : QliqLocalizedString(@"2192-TitleNewConversation");
            } else {
                
                if (encounter) {
                    title = encounter.patient.displayName;
                } else {
                    NSArray *recipients = [self.conversation.recipients allRecipientsWithoutCurrentUser];
                    id user = [recipients lastObject];
                    
                    if ([user isKindOfClass:[QliqGroup class]]) {
                        title = ((QliqGroup*)user).name;
                    }
                    else if ([user isKindOfClass:[QliqUser class]] && [self.conversation.recipients isMultipartyWithoutCurrentUser] ) {
                        //                    NSArray *users = [self.conversation.recipients allRecipients];
                        title = [[recipients valueForKeyPath:@"firstName"] componentsJoinedByString:@", "];
#ifdef DEBUG
                        // Adam Sowa: I prefer to view participants by last name to identify MP
                        title = [[recipients valueForKeyPath:@"lastName"] componentsJoinedByString:@"; "];
#endif
                    }
                    else if ([user isKindOfClass:[QliqUser class]] ) {
                        title = [[recipients lastObject] recipientTitle];
                    }
                }
            }
            
            if ([title isEqualToString:@""] || !title) {
                title = @"<null>";
            }
        
            title = [title stringByReplacingOccurrencesOfString:@"<null>" withString:QliqLocalizedString(@"2391-TitleUnknownContact")];
            self.titleBackBtn.text = title;
            self.titleBackBtn.hidden = !(self.titleBackBtn.text.length > 0) && !self.isDeleteMode ? !(self.titleBackBtn.text.length > 0):self.isDeleteMode;
            /**
             Constraints calculating
             */
            {
                [self configureNavigationTitleWidthWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
            }
        }
        
        //Set Conversation Subject
        {
            NSString *subjectText = @"";
            
            if (self.conversation)
            {
                if (self.conversation.isBroadcast)
                {
                    subjectText = [NSString stringWithFormat:@"[%@]", QliqLocalizedString(@"2108-TitleBroadcast")];
                    
                    if ([self.conversation.subject length] != 0) {
                        
                        subjectText = [subjectText stringByAppendingString:[NSString stringWithFormat:@" %@", self.conversation.subject]];
                    }
                }
                else
                {
                    if (encounter) {
                        NSArray *users = [self.conversation.recipients allRecipients];
                        subjectText = [[users valueForKeyPath:@"firstName"] componentsJoinedByString:@", "];
#ifdef DEBUG
                        // Adam Sowa: I prefer to view participants by last name to identify MP
                        subjectText = [[users valueForKeyPath:@"lastName"] componentsJoinedByString:@"; "];
#endif
                    } else {
                        if (self.conversation.subject && [self.conversation.subject length] > 0) {
                            
                            NSString *presenseStatusText = [[UserSessionService currentUserSession].userSettings.presenceSettings convertPresenceStatusForSubjectType:self.conversation.subject];
                            if (presenseStatusText) {
                                subjectText = presenseStatusText;
                            }
                            else {
                                subjectText = self.conversation.subject;
                            }
                        }
                        else {
                            
                            NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:self.conversation.lastUpdated];
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            formatter.timeStyle = NSDateFormatterShortStyle;
                            formatter.dateStyle = NSDateFormatterMediumStyle;
                            formatter.doesRelativeDateFormatting = YES;
                            
                            subjectText = [formatter stringFromDate:messageDate];
                        }
                    }
                }
            }
            
            self.lastTimeBtn.text = subjectText;
            self.lastTimeBtn.hidden = !(self.lastTimeBtn.text.length > 0) && !self.isDeleteMode ? !(self.lastTimeBtn.text.length > 0):self.isDeleteMode;
            
            if (self.isDeleteMode)
            {
                self.indicator.hidden               = YES;
                self.backButton.hidden              = YES;
                self.editOptionButton.hidden        = YES;
                
                self.navigationBarRightOptionalButton.hidden    = NO;
            }
            else
            {
                self.backButton.hidden = NO;
                self.editOptionButton.hidden = NO;
                self.selectAllBtn.hidden = YES;
                //SelectAllBtn
                [self.selectAllBtn setTitle:QliqLocalizedString(@"51-ButtonSelectAll") forState:UIControlStateNormal];
            }
        }
    }
}

- (void)showIndicatorIfNeeded {
    if (self.isNewConversation) {
        self.indicator.hidden = YES;
    }
    else {
        self.indicator.hidden = [self isGroupOrMultiplyConversation] || [self.conversation isCareChannel] || self.isSingleFieldMode;
    }
}

- (void)configureNavigationTitleWidthWithOrientation:(UIInterfaceOrientation)orientation {
    /**
     Constraints calculating
     */
    {
        CGSize titleBackLabellSize = CGSizeZero;
        
        if ([self.titleBackBtn.text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
        {
            titleBackLabellSize = [self.titleBackBtn.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.titleBackBtn.bounds.size.height)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                    attributes:@{NSFontAttributeName:self.titleBackBtn.font}
                                                                       context:nil].size;
        }
        
        CGRect rect = [UIScreen mainScreen].bounds;
        
        if (UIInterfaceOrientationIsLandscape(orientation) ) {
            rect = CGRectMake(0, 0, MAX(rect.size.height, rect.size.width), MIN(rect.size.height, rect.size.width) );
        }
        else {
            rect = CGRectMake(0, 0, MIN(rect.size.height, rect.size.width), MAX(rect.size.height, rect.size.width) );
        }
        rect.size.width = rect.size.width - 135.f;
        
        CGFloat minWidth = self.isNewConversation ? 200.f : rect.size.width;
        self.titleBackWidthConstraint.constant = MIN(minWidth, titleBackLabellSize.width + 5);
    }
}

- (void)configureSelectAllButtonTitle
{
    if (self.isDeleteMode)
    {
        __block BOOL isSelectAll = YES;
        if (self.selectedMessages.count == self.messagesArray.count)
        {
            isSelectAll = NO;
            NSSet *selectedMessagesSet = [NSSet setWithArray:self.selectedMessages];
            [self.messagesArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![selectedMessagesSet containsObject:obj])
                {
                    isSelectAll = YES;
                    *stop = YES;
                }
            }];
        }
        
        if (isSelectAll)
        {
            [self.selectAllBtn setTitle:QliqLocalizedString(@"51-ButtonSelectAll") forState:UIControlStateNormal];
        }
        else
        {
            [self.selectAllBtn setTitle:QliqLocalizedString(@"52-ButtonDeselectAll") forState:UIControlStateNormal];
        }
    }
}


#pragma mark * EditView *

- (void)setEditViewTableContent {
    
    [self.editViewTableContent removeAllObjects];
    
    [self.editViewTableContent addObject:@(EditParticipants)];
    
    if (self.isCareChannelMode)
        [self.editViewTableContent addObjectsFromArray:@[@(PatientInfo), @(CareChannelInfo)]];
    
    [self.editViewTableContent addObjectsFromArray:@[@(ForwardMessage), @(DeleteMessages), @(DeleteConversation)]];
    
    if (self.conversation.isMuted) {
        [self.editViewTableContent addObject:@(UnMuteConversation)];
    } else {
        [self.editViewTableContent addObject:@(MuteConversation)];
    }
    
    if (self.conversation.archived) {
        [self.editViewTableContent addObject:@(RestoreConversation)];
    } else {
        [self.editViewTableContent addObject:@(ArchiveConversation)];
    }
    
    [self.editViewTableContent addObject:@(UploadToEMR)];
    
    BOOL isKiteworksIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isKiteworksIntegrated;
    if (isKiteworksIntegrated) {
        [self.editViewTableContent addObject:@(UploadToKiteworks)];
    }
}

- (void)updateEditView
{
    [self setEditViewTableContent];
    
    [self.editViewTable reloadData];
    
    CGFloat valueEditViewHeight = [self.editViewTableContent count] * kValueEditViewCellHeight + self.editTableTopConstraint.constant;
    
    __weak __block typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
        
        CGFloat value = 0;
        CGFloat heightContent = weakSelf.chatsTable.frame.size.height + weakSelf.keyboardAccessoryView.frame.size.height;
        
        if (heightContent < valueEditViewHeight) {
            value = heightContent - 5.f;
            weakSelf.editViewTable.scrollEnabled = YES;
        } else {
            value = valueEditViewHeight;
            weakSelf.editViewTable.scrollEnabled = NO;
        }
        
        self.editPopoverHeightConstraint.constant = value;
        
        [self.view layoutSubviews];
    }completion:nil];
}

- (UITableViewCell *)setCellForEditTableView:(UITableView *)editTableView forIndexPath:(NSIndexPath *)indexPath{
    
    EditTableViewCell *cell = nil;
    
    cell = [editTableView dequeueReusableCellWithIdentifier:@"EditViewReusableCell" forIndexPath:indexPath];
    
    NSNumber *tableTitle = self.editViewTableContent[indexPath.row];
    
    [cell setCellForTitleType:tableTitle.integerValue isCareChannel:self.conversation.isCareChannel];
    
    return cell;
}

- (void)didSelectEditTable:(UITableView *)editTable rowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber *titleNumber = self.editViewTableContent[indexPath.row];
    EditTableTitle title = titleNumber.integerValue;
    
    switch (title) {
            
        case EditParticipants:
        {
            if (self.isCareChannelMode) {
                [self onEditCareTeam];
            } else {
                [self onEditParticipantsModal:NO];
            }
            break;
        }
        case ForwardMessage:
        {
            [self onForwardMessage];
            break;
        }
        case DeleteMessages:
        {
            [self onDeleteMessages];
            break;
        }
        case DeleteConversation:
        {
            [self onDeleteConversation];
            break;
        }
        case RestoreConversation:
        case ArchiveConversation:
        {
            [self onSaveConversation];
            break;
        }
        case UploadToEMR:
        {
            [self uploadToEMR];
            break;
        }
        case UploadToKiteworks:
        {
            [self uploadToKiteworks];
            break;
        }
        case PatientInfo:
        {
            [self onPatientInfo];
            break;
        }
        case CareChannelInfo:
        {
            [self onCareChannelInfo];
            break;
        }
        case MuteConversation:
        case UnMuteConversation:
        {
            [self onMuteConversation];
            break;
        }
            
        default:
            break;
    }
    
    [editTable deselectRowAtIndexPath:indexPath animated:NO];
    self.editPopoverView.hidden = YES;
}

#pragma mark - TableView -

- (void)registerCells {
    
    UINib *nib1 = [UINib nibWithNibName:@"ConversationMyCell" bundle:nil];
    [self.chatsTable registerNib:nib1 forCellReuseIdentifier:ConversationMyCellId];
    
    UINib *nib2 = [UINib nibWithNibName:@"ConversationWithAttachmentMyCell" bundle:nil];
    [self.chatsTable registerNib:nib2 forCellReuseIdentifier:ConversationWithAttachmentMyCellId];
    
    UINib *nib3 = [UINib nibWithNibName:@"ConversationContactCell" bundle:nil];
    [self.chatsTable registerNib:nib3 forCellReuseIdentifier:ConversationContactCellId];
    
    UINib *nib4 = [UINib nibWithNibName:@"ConversationWithAttachmentContactCell" bundle:nil];
    [self.chatsTable registerNib:nib4 forCellReuseIdentifier:ConversationWithAttachmentContactCellId];
}

- (void)changeHeightAccessoryViewTo:(CGFloat)height
{
    if (self.keyboardAccessoryViewHeight != height)
    {
        self.keyboardAccessoryViewHeight = height;
        self.heightAccessoryViewConstraint.constant = height;
    }
}

- (void)changeBottomTableview:(CGFloat)height
{
    if (self.tableViewBottom != height)
    {
        self.tableViewBottom = height;
        self.chatsTableBottomToAccessoryViewTopConstraint.constant = self.tableViewBottom;
    }
}

- (void)scrollTableViewToBottomWithAnimation:(BOOL)animated
{
    dispatch_async_main(^{
        NSInteger numberOfRows = [self.chatsTable numberOfRowsInSection:0];
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0] ;
        
        if (lastIndexPath.row >= 0 && lastIndexPath.row < numberOfRows) {
            [self.chatsTable scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    });
}

- (void)setContentOffsetChatsTableToBottomAnimated:(NSNumber *)animated {
    if (self.chatsTable.contentSize.height > self.chatsTable.frame.size.height)
    {
        CGPoint bottomOffset = CGPointMake(0, self.chatsTable.contentSize.height - self.chatsTable.bounds.size.height);
        [self.chatsTable setContentOffset:bottomOffset animated:[animated boolValue]];
    }
}

- (void)presentAttachment:(MessageAttachment *)attachment fromCell:(ConversationTableViewCell *)cell
{
    if (![attachment.mediaFile fileExists]) {
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1054-TextAttachmentDeletedFrom")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return;
    }
    
    MediaFileService *sharedService = [MediaFileService getInstance];
    BaseAttachmentViewController *mediaViewer = nil;
    
    MediaFileType attachmentType = [sharedService typeNameForMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath];

    switch (attachmentType) {
            
        case MediaFileTypeDocument:{
            mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
        }
            break;
        case MediaFileTypeAudio:{
            mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([AudioAttachmentViewController class])];
        }
            break;
        case MediaFileTypeVideo:{
            mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([VideoAttachmentViewController class])];
        }
            break;
        case MediaFileTypeImage:{
            mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ImageAttachmentViewController class])];
        }
            break;
        case MediaFileTypeUnknown:{
            DDLogSupport(@"Unknown attachment type - %@, file name - %@", attachment.mediaFile.mimeType, attachment.mediaFile.encryptedPath);
            
        }
            break;
            
        default:
            break;
    }
    
    if (mediaViewer) {
        mediaViewer.mediaFile = attachment.mediaFile;
        mediaViewer.shouldShowDeleteButton = NO;
        mediaViewer.viewMode = cell ? ViewModeForConversation : ViewModeForPresentAttachment;
        [self.navigationController pushViewController:mediaViewer animated:YES];
    }
    else {
        DDLogSupport(@"Can't open attachment media file, mime type - %@, encryptedPath - %@", attachment.mediaFile.mimeType, attachment.mediaFile.encryptedPath);
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"3044-TextCanNotOpenMediaFile")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

#pragma mark ToolBar

- (void)showToolbar:(BOOL)show {
    if (self.isNotFirstReloadController && self.toolbar.hidden == show) {
        self.chatsTableBotToContentSizeHeightDelta = self.chatsTable.contentSize.height - self.chatsTable.contentOffset.y - self.chatsTable.frame.size.height;
        __weak __block typeof(self) welf = self;
        [UIView animateWithDuration:0.25 animations:^{
            if (show)
            {
                welf.toolbar.hidden = !show;
                //need to shift toolbar Up
                welf.toolbarBottomConstraint.constant = 0.f;
                //need to shift keyboardAccessoryView Down
                welf.accessoryViewBottomConstraint.constant = - welf.keyboardAccessoryViewHeight;
                //need to change table bottom
                [welf changeBottomTableview: - welf.toolBarHeightConstraint.constant];
            }
            else
            {
                welf.keyboardAccessoryView.hidden = show;
                //need to shift toolbar Down
                welf.toolbarBottomConstraint.constant = - welf.toolBarHeightConstraint.constant;
                //need to shift keyboardAccessoryView Up
                welf.accessoryViewBottomConstraint.constant = 0.f;
                //need to change table bottom
                [welf changeBottomTableview:0.f];
            }
            [welf.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            CGFloat offset = welf.toolBarHeightConstraint.constant - welf.keyboardAccessoryViewHeight;
            if (show)
            {
                welf.keyboardAccessoryView.hidden = show;
                [welf scrollUpChatTableDown:YES offset:offset isSentMessage:NO animated:YES];
            }
            else
            {
                welf.toolbar.hidden = !show;
                offset = self.chatsTableBotToContentSizeHeightDelta < offset ? self.chatsTableBotToContentSizeHeightDelta : offset;
                [welf scrollUpChatTableDown:NO offset:offset isSentMessage:NO animated:YES];
            }
        }];
    }
}

#pragma mark - Update Content -

- (void)checkForForwardingWithCompletion:(void(^)(BOOL isForwarded))completion
{
    if ([self.conversation.recipients isSingleUser])
    {
        __block __weak typeof(self) weakSelf = self;
        
        [Presence askForwardingIfNeededForRecipient:[self.conversation.recipients recipient] completeBlock:^(id<Recipient> selectedRecipient) {
            [[[Presence alloc] init] setShouldAsk:NO];
            
            __strong typeof(self) strongSelf = weakSelf;
            
            if (!strongSelf) {
                DDLogSupport(@"block is preempted");
            }
            else {
                
                if ([strongSelf.conversation.recipients recipient] != selectedRecipient) {
                    [strongSelf forwardMessageToRecipient:selectedRecipient];
                    completion(YES);
                }
                else {
                    completion(NO);
                }
            }
        }];
    }
    else {
        completion(NO);
    }
}

- (void)forwardMessageToRecipient:(id<Recipient>)recipient {
    Recipients *forwardRecipients = [[Recipients alloc] init];
    [forwardRecipients setRecipient:recipient];
    
    NSString *message = [self.downView currentMessage];
    
    NSString *messageText = [NSString stringWithFormat:@"%@ %@\n%@", QliqLocalizedString(@"2193-TitleOriginalTextFrom"),  [[[self.conversation allRecipients] lastObject] recipientTitle], message];
    
    NSString *subjectText = [NSString stringWithFormat:@"Fwd: %@", self.conversation.subject];
    
    MessageAttachment *attachment = [[[self.downView attachments] lastObject] copy];
    
    [self startNewConversationWithRecipients:forwardRecipients
                             withMessageText:messageText
                             withSubjectText:subjectText
                       withMessageAttachment:attachment
                               broadcastType:NotBroadcastType];
}


- (void)createNewConversation {
    
    //Conversation must have selected Recipients
    if (self.recipients.count == 0) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1064-TextSelectRecipient")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
        
    } else {
        //Create Conversation
        BroadcastType broadcastType = NotBroadcastType;
        if (self.isBroadcastConversation) {
            if (self.isPagerMode) {
                broadcastType = PlainTextBroadcastType;
            } else {
                broadcastType = EncryptedBroadcastType;
            }
        }
        self.conversation = [[QliqConnectModule sharedQliqConnectModule] createConversationWithRecipients:self.recipients
                                                                                                  subject:self.subjectTextView.text
                                                                                            broadcastType:broadcastType
                                                                                                     uuid:nil];
        
        self.contactPickerView.delegate = nil;
        
        //Configure Controller
        [self configureController];
        [self setupMessageProvider];
    }
}

- (BOOL)checkRecipientsRoles:(NSDictionary *)roles {
    
    for (QliqUser * recipient in self.conversation.recipients.recipientsArray) {
        NSString *role = @"";
        Multiparty *mp = [MultipartyDao selectOneWithQliqId:self.conversation.recipients.qliqId];
        if (mp) {
            role = [mp roleForQliqId:recipient.qliqId];
            if (role) {
                if ([roles valueForKey:recipient.qliqId]) {
                    if (![role isEqualToString:roles[recipient.qliqId]]) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

#pragma mark * Conversation Validation

- (void)validateConversationWithCompletionBlock:(void(^)(BOOL isValid))block{
    
    __block BOOL isValidConversation = YES;
    Recipients *recipients = self.isNewConversation ? self.recipients : self.conversation.recipients;
    BOOL isBroadcast = self.isNewConversation ? self.isBroadcastConversation : self.conversation.isBroadcast;
    
    
    __weak __block typeof(self) welf = self;
    void (^checkGroupBlock)(void) = ^{
        
        // Check if we can still send to this group, this could change in the middle of the conversation
        // 12/20/2016
        // User can reply to broadcast even if user cannotBroadcast to the group
        //
        QliqGroup *recipientGroup = [[QliqGroupDBService sharedService] getGroupWithId:recipients.qliqId];
        

        if (recipientGroup && recipientGroup.isDeleted) {
            DDLogSupport(@"Cannot sent mesage to this groupId - %@, with conversationId - %ld, because group was deleted", recipients.qliqId, self.isNewConversation ? 000000 : (long)welf.conversation.conversationId);
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1065-TextCannotSendMessage")
                                        message:QliqLocalizedString(@"3025-TextCannotSentMessageToThisGroup")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
            isValidConversation = NO;
        // Krishna 6/12/2018
        // Only for new conversations, that are broadcast, the user cannot originate. for existing broadcast messages,
        // User can reply back to sender even if the broadcast flag is not ON. For Group Messaging it should be ON for
        // New conversations and replies.
        //
        } else if (recipientGroup && ((self.isNewConversation && isBroadcast && ![recipientGroup canBroadcast]) || (!isBroadcast &&![recipientGroup canMessage]))) {
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                            message:QliqFormatLocalizedString2(@"3028-TextAdminBlocked{groupConversationType}Conversation{groupName}",
                                                                               isBroadcast ? QliqLocalizedString(@"17-ButtonConversationBroadcast") : QliqLocalizedString(@"16-ButtonConversationGroup"),
                                                                               recipientGroup.name)
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            isValidConversation = NO;
        }
        if (block) {
            block(isValidConversation);
        }
    };
    
    /** Check if the open conversation isn't to a deleted user */
    
    QliqUser *recipientUser = [[QliqUserDBService sharedService] getUserWithId:recipients.qliqId];
    
    __block BOOL isDeletedUser = NO;
    if (recipientUser && [recipientUser.status isEqualToString:@"deleted"] && recipientUser.contact.contactStatus == ContactStatusDeleted) {
        
        [SVProgressHUD showWithStatus:@"Loading..."];
        
        dispatch_async_background(^{
            
            //Check up to date status for user
            [[GetContactInfoService sharedService] getInfoForContact:recipientUser.contact withReason:nil conpletionBlock:^(QliqUser *user, NSError *error) {
                
                if (([user.status isEqualToString:@"deleted"] && user.status.length) || (error && error.code == ErrorCodeNotContact)) {
                    
                    DDLogSupport(@"Recipient <%@> is no longer a contact", user.qliqId);
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1065-TextCannotSendMessage")
                                                message:QliqLocalizedString(@"1066-TextRecipientNoLongerContact")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:nil];
                    isDeletedUser = YES;
                    
                }
                dispatch_async_main(^{
                    if ([SVProgressHUD isVisible]) {
                        [SVProgressHUD dismiss];
                    }
                });
                
                if (isDeletedUser) {
                    if (block) {
                        block(isValidConversation);
                    }
                } else {
                    checkGroupBlock();
                }
            }];
        });
    } else {
        checkGroupBlock();
    }
}

- (BOOL)validateConversationParticipants {
    
    BOOL ret = NO;
    BOOL containsGroup = NO;
    BOOL containsUser = NO;
    //    BOOL isSelfUserRecipient = NO;
    
    NSArray *allRecipients = [self.conversation allRecipients];
    for (Recipients *recipient in allRecipients)
    {
        if ([recipient isKindOfClass:[QliqUser class]]) {
            containsUser = YES;
        }
        else if ([recipient isKindOfClass:[QliqGroup class]]) {
            containsGroup = YES;
        }
    }
    
    //    isSelfUserRecipient = [self isSelfUserRecipientShowAlert];
    
    //#warning need to test with groups
    //    if (isSelfUserRecipient) {
    NSString *alert = nil;
    
    if (containsGroup && containsUser) {
        alert = QliqLocalizedString(@"1055-TextRecipientListCannotContainGroupAndUserAtSameTime");
        
    } else if (containsGroup && allRecipients.count > 1) {
        alert = QliqLocalizedString(@"1056-TextRecipientListCannotContainMoreThenOneGroupAtSameTime");
        
    } else if ([self.conversation.recipients allRecipientsWithoutCurrentUser].count == 0){
        alert = QliqLocalizedString(@"1058-TextRecipientCannotSentMessageToYourSelf");
        
    } else {
        if (allRecipients != nil) {
            ret = YES;
        }
    }
    
    if (alert) {
        [AlertController showAlertWithTitle:nil
                                    message:alert
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
    return ret;
}

#pragma mark * Message sending

- (void)handleSendButtonPressed {
    
    //1. Create Conversation if its NewConversation
    if (self.isNewConversation)
    {
        if (![self.downView.textView.internalTextView isFirstResponder])
            [self.downView.textView.internalTextView becomeFirstResponder];
        
        __weak __block typeof(self) welf = self;
        void (^createConversationBlock)(void) = ^(void){
            welf.needToAskAboutBroadcast = NO;
            [welf configureNavigationBar];
            if (welf.needNotifyAboutFirstReplyToGroup) {
                
                [welf validateConversationWithCompletionBlock:^(BOOL isValid) {
                    if (isValid) {
                        [welf showAlertAboutFirstReplyToGroupConverastionWithBlock:^{
                            welf.needNotifyAboutFirstReplyToGroup = NO;
                            [welf createNewConversation];
                            
                            if (![welf validateConversationParticipants])
                                return;
                            
                            [welf checkForwardingAndTryToSendMessage];
                        }];
                    }
                    else
                        return;
                }];
                
            }
            else
            {
                [welf createNewConversation];
                if ([welf canTryToSendMessage])
                    [welf checkForwardingAndTryToSendMessage];
            }
        };
        
        if (self.needToAskAboutBroadcast)
        {
            [self showAlertForChoosingGroupConversationTypeWithBlock:createConversationBlock];
        }
        else
        {
            createConversationBlock();
        }
    }
    else
    {
        if (![self isSelfUserRecipientElseShowAlert]) {
            return;
        }
        
        if ([self canTryToSendMessage])
        {
            //            if (![self isActive]) {
            //                return;
            //            }
            if (self.needNotifyAboutFirstReplyToGroup)
            {
                __weak __block typeof(self) welf = self;
                [self showAlertAboutFirstReplyToGroupConverastionWithBlock:^{
                    welf.needNotifyAboutFirstReplyToGroup = NO;
                    [welf checkForwardingAndTryToSendMessage];
                }];
            }
            else
                [self checkForwardingAndTryToSendMessage];
        }
    }
}

- (BOOL)canTryToSendMessage
{
    //2. Check for validate conversation
    if (![self validateConversationParticipants])
        return NO;
    
    __block BOOL canSendMessage = NO;
    [self validateConversationWithCompletionBlock:^(BOOL isValid) {
        if (isValid) {
            canSendMessage = YES;
        }
    }];
    
    if (canSendMessage) {
        return YES;
    } else {
        return NO;
    }
}

- (void)checkForwardingAndTryToSendMessage {
    
    __weak __block typeof(self) welf = self;
    //3. Send Message
    [self checkForForwardingWithCompletion:^(BOOL isForwarded) {
        if (!isForwarded) {
            [welf tryToCreateAndSendMessage];
        }
    }];
}

- (void)showAlertForChoosingGroupConversationTypeWithBlock:(VoidBlock)block {
    
    [self.downView.view endEditing:YES];
    __weak __block typeof(self) welf = self;
    [AlertController showAlertWithTitle:QliqLocalizedString(@"2388-TitleChooseTheConversationType")
                                message:QliqLocalizedString(@"2389-TextSendBroadcastMessageStartGroupChat")
                       withTitleButtons:@[QliqLocalizedString(@"17-ButtonConversationBroadcast"), QliqLocalizedString(@"16-ButtonConversationGroup")]
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 switch (buttonIndex) {
                                     case 0: {
                                         welf.isBroadcastConversation = YES;
                                         if (block)
                                             block();
                                     }
                                         break;
                                     case 1:{
                                         welf.isBroadcastConversation = NO;
                                         if (block)
                                             block();
                                     }
                                         break;
                                     case 2:
                                         break;
                                         
                                         
                                     default:
                                         break;
                                 }
                             }];
}

- (void)showAlertAboutFirstReplyToGroupConverastionWithBlock:(VoidBlock)block
{
    NSInteger count = self.conversation.recipients ? [((QliqGroup *)self.conversation.recipients.recipient) getOnlyContacts].count : self.recipients && self.recipients.recipientsArray.count == 1 ? [[QliqGroupDBService sharedService] getOnlyUsersOfGroup:self.recipients.recipientsArray.firstObject].count : self.recipients ? [((QliqGroup *)self.recipients.recipient) countOfParticipants] : 0;
    
    DDLogSupport(@"<-- First reply of user: %@, in conversation: %@, in QliqGroup: %@, count of recipients: %ld -->", [UserSessionService currentUserSession].user.qliqId, self.conversation, ((QliqGroup *)self.conversation.recipients.recipient).qliqId, (long)count);
    
    UIAlertController *controller = [UIAlertController new];
    if (count != 0) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:[NSString stringWithFormat:@"You are about to send a message to a group with %lu recipients. Are you sure?", (long)count]
                                buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                          cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==0) {
                                         if (block)
                                             block();
                                     }
                                 }];
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:QliqLocalizedString(@"2435-CannotStartConversation")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==1) {
                                         [controller dismissViewControllerAnimated:YES completion:nil];
                                     }
                                 }];
    }
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (ChatMessage *)createMessageForConversation:(Conversation *)aConversation
{
    BOOL conversationIsInvalid = aConversation.conversationId == 0;
    BOOL messageIsEmpty = [self.downView currentMessage].length == 0 && [[self.downView attachments] count] == 0;
    
    //NSString *string = [self.downView currentMessage];
    
    if (conversationIsInvalid || messageIsEmpty)
    {
        if (messageIsEmpty)
            DDLogSupport(@"Message is empty! Text: %@, Attachments: %@",[self.downView currentMessage], [self.downView attachments]);
        
        if (conversationIsInvalid)
            DDLogSupport(@"Conversation is invalid! Conversation: %@", aConversation);
        
        return nil;
    }
    
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    NSString *toQliqId = aConversation.recipients.qliqId;
    
    DDLogSupport(@"New message to: %lu users", (unsigned long)aConversation.recipients.count);
    
    ChatMessage *newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
    newMessage.conversationId   = aConversation.conversationId;
    newMessage.fromQliqId       = myQliqId;
    newMessage.toQliqId         = toQliqId;
    newMessage.text             = [self.downView currentMessage];
    [newMessage calculateHeight];
    newMessage.timestamp        = [[NSDate date] timeIntervalSince1970];
    newMessage.readAt           = newMessage.timestamp;
    newMessage.createdAt        = newMessage.timestamp;
    newMessage.ackRequired      = [self.downView needsAck];
    newMessage.subject          = self.conversation.subject;
    newMessage.metadata         = [Metadata createNew];
    newMessage.metadata.isRevisionDirty = YES;
    newMessage.attachments      = [self.downView attachments];
    newMessage.priority         = [self.downView messagePriority];
    if (newMessage.priority == ChatMessagePriorityUrgen)
        newMessage.ackRequired = YES;
    
    /*
     if ([newMessage.attachments count] > 0 && newMessage.text.length == 0)
     {
     MessageAttachment * attachment = [newMessage.attachments lastObject];
     newMessage.text = [[MediaFileService getInstance] typeNameForMime:attachment.mediaFile.mimeType FileName:[attachment.mediaFile.encryptedPath lastPathComponent]];
     }
     */
    
    return newMessage;
}

- (void)sendMessage:(ChatMessage *)chatMessage {
    [self sendMessage:chatMessage reloadAsync:YES];
}

- (void)sendMessage:(ChatMessage *)chatMessage reloadAsync:(BOOL)async {
    
    [self updateConversationByMessage:chatMessage];
    
    //send message
    [[QliqConnectModule sharedQliqConnectModule] sendMessage:chatMessage];
    
    //play sound
    SoundSettings * soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
    Ringtone * ringtone = [[soundSettings notificationsSettingsForPriority:NotificationPriorityNormal] ringtoneForType:NotificationTypeSend];
    [ringtone play];
    
    //reload table to show new message
    {
        if (![self.messagesArray containsObject:chatMessage])
        {
            [self.messagesArray addObject:chatMessage];
            [self.chatsTable reloadData];
            
            [self performSelector:@selector(setContentOffsetChatsTableToBottomAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.25];
        }
        else
        {
            [self updateCellForMessage:chatMessage];
        }
    }
}

- (void)tryToCreateAndSendMessage {
    
    __block __weak typeof(self) weakSelf = self;
    if (!self.conversation) {
        
        [self.view endEditing:YES];
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1068-TextUnableCreateConversationWithSelectedUsers")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:^(NSUInteger buttonIndex) {
                              if (buttonIndex == 1) {
                                  [self.navigationController popViewControllerAnimated:NO];
                              }
                          }];
        return;
    } else {
        //Create Message
        ChatMessage *newChatMessage = [self createMessageForConversation:self.conversation];
        if (newChatMessage) {
            
            //refresh inputAccessoryView
            self.downView.isMessageSent = YES;
            [self.downView clearAllWithCompletion:^{
                MessageAttachment *attachment = [newChatMessage.attachments lastObject];
                if (attachment && attachment.progressGroup) {
                    
                    dispatch_group_notify(attachment.progressGroup, dispatch_get_main_queue(), ^{
                        [weakSelf sendMessage:newChatMessage];
                    });
                } else
                    [weakSelf sendMessage:newChatMessage];
            }];
        }
        else
        {
            DDLogError(@"Error while creating message");
        }
    }
}

- (void) sendMessageInNewConversation:(NSString *)text toRecipients:(Recipients *)recipients withSubject:(NSString *)subjectText conversationUuuid:(NSString *)conversationUuid messageUuid:(NSString *)messageUuid
{
    DDLogSupport(@"Sending message in new Conversation");
    
    self.recipients = recipients;
    self.conversation = [[QliqConnectModule sharedQliqConnectModule] createConversationWithRecipients:recipients
                                                                                              subject:subjectText
                                                                                        broadcastType:NotBroadcastType
                                                                                                 uuid:conversationUuid];
    self.isNewConversation = NO;
    [self setupMessageProvider];
    [self configureController];
    
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    NSString *toQliqId = self.conversation.recipients.qliqId;
    
    DDLogSupport(@"New message to %lu users:", (unsigned long)self.conversation.recipients.count);

    ChatMessage *newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
    newMessage.conversationId   = self.conversation.conversationId;
    newMessage.fromQliqId       = myQliqId;
    newMessage.toQliqId         = toQliqId;
    newMessage.text             = text;
    [newMessage calculateHeight];
    newMessage.timestamp        = [[NSDate date] timeIntervalSince1970];
    newMessage.readAt           = newMessage.timestamp;
    newMessage.createdAt        = newMessage.timestamp;
    newMessage.ackRequired      = NO;
    newMessage.subject          = self.conversation.subject;
    newMessage.metadata         = [Metadata createNew];
    newMessage.metadata.isRevisionDirty = YES;
    newMessage.attachments      = nil;
    newMessage.priority         = ChatMessagePriorityNormal;
    newMessage.ackRequired = NO;
    if (messageUuid.length > 0) {
        newMessage.metadata.uuid = messageUuid;
    }
    [self sendMessage:newMessage reloadAsync:NO];
}


#pragma mark * Conversation update *

- (void)updateConversationByMessage:(ChatMessage *)message
{
    self.conversation.lastMsg = message.text;
    self.conversation.lastUpdated = message.timestamp;
    self.conversation.subject = message.subject;
    self.conversation.isRead = [[ConversationDBService sharedService] isRead:self.conversation];
}

#pragma mark - Actions -

#pragma mark * GestureRecognizers Actions

- (void)onDismisKeyboard:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

#pragma mark * Navigation Actions

- (IBAction)onBack:(id)sender {
    DDLogSupport(@"didPressOnBack");
    if (self.isSingleFieldMode)
    {
        [self.view endEditing:YES];
    }
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)onEdit:(id)sender {
    
    if ([self isSelfUserRecipientElseShowAlert])
    {
        self.editPopoverView.hidden = !self.editPopoverView.hidden;
        
        if (!self.editPopoverView.hidden) {
            [self.view bringSubviewToFront:self.editPopoverView];
        }
    }
}

- (IBAction)onCall:(id)sender
{
    if (nil != self.sheet) {
        return;
    }
    //As it is leaking about 9 bytes per call.
    //NSMutableArray *recipientsWithNumbersArray = [NSMutableArray array];
    NSMutableArray *recipientsWithNumbersArray = [[NSMutableArray alloc] init];
    
    for (Contact *item in self.conversation.recipients.allRecipients)
    {
        QliqUser *user = [[QliqUserDBService sharedService] getUserWithContactId:item.contactId];
        if (user != nil && ![user.qliqId isEqualToString:[Helper getMyQliqId]]) {
            [recipientsWithNumbersArray addObject:user];
        }
    }
  
    self.sheet = [[ContactsActionSheet alloc] initWithContacts:recipientsWithNumbersArray];
    self.sheet.delegate = self;
    [self.view endEditing:YES];
    __weak __block typeof(self) welf = self;
    [self.sheet presentInView:self.view animated:YES withErrorHandler:^(BOOL success, NSError *error) {
        
        if (!success) {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1042-TextCall")
                                        message:QliqLocalizedString(@"1057-TextPhoneNumberMissing")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
            welf.sheet = nil;
        }
    }];
}

- (void)onUpperArrowView {
    
    if ([self.conversation isCareChannel]) {
        [self onCareChannelInfo];
    } else {
        [self onEditParticipantsModal:YES];
    }
    
}

#pragma mark * EditPopover Actions


- (void)showDetailContactViewControllerForConversation:(Conversation *)conversation modal:(BOOL)modal {
    
    if ([self isSelfUserRecipientElseShowAlert])
    {
        DetailContactInfoViewController *infoViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
        infoViewController.delegate = self;
        infoViewController.contact = self.conversation;
        
        if (modal)
        {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:infoViewController];
            nav.modalInPopover = YES;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
        else
        {
            [self.navigationController pushViewController:infoViewController animated:YES];
        }
    }
}

- (void)onEditCareTeam
{
    [self showDetailContactViewControllerForConversation:self.conversation modal:YES];
}

- (void)onEditParticipantsModal:(BOOL)modal
{
    QliqGroup *recipientGroup = [[QliqGroupDBService sharedService] getGroupWithId:self.conversation.recipients.qliqId];
    if (recipientGroup && !recipientGroup.canMessage && !recipientGroup.canBroadcast && recipientGroup.isDeleted) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"3026-CannotEditParticipants")
                                    message:QliqLocalizedString(@"3027-TextCannotEditParticipants")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        
    } else {
        [self showDetailContactViewControllerForConversation:self.conversation modal:modal];
    }
}

- (void)onForwardMessage
{
    self.isForward = YES;
    [self moreActions];
}

- (void)onDeleteMessages
{
    self.isForward = NO;
    [self moreActions];
}

- (void)onSaveConversation
{
    if (self.conversation == nil) {
        DDLogSupport(@"Cannot conversation");
        return;
    }
    
    if (self.conversation.archived)
    {
        [[ConversationDBService sharedService] restoreConversations:@[self.conversation]];
        DDLogSupport(@"Conversation Refresh Called from restoreConversations");
    }
    else
    {
        DDLogSupport(@"Conversation Refresh Called from archiveConversations");
        [[ConversationDBService sharedService] archiveConversations:@[self.conversation]];
    }
    
    //    self.conversation = [[ConversationDBService sharedService] getConversationWithId:@(self.conversation.conversationId)];
    self.conversation.archived = !self.conversation.archived;
    
    NSDictionary *userInfo = @{@"Conversation":self.conversation};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConversationArchiveAction" object:nil userInfo:userInfo];
    
    [self updateEditView];
}

- (void)onDeleteConversation {
    DDLogInfo(@"On Delete Conversation");
    
    [self.delegate conversationDeletePressed:self.conversation];
    
    [[ConversationDBService sharedService] deleteConversations:@[self.conversation]];
    
    //Need to send Notification with deleted conversations and update conversations array in Recents Menu
    NSDictionary *info = @{@"DeletedConversations": @[self.conversation].copy};
    [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressDeleteButtonNotification object:nil userInfo:info];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kConversationsListDidPressActionButtonNotification object:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)uploadToEMR {
    
    // Make this 1 when you are testing locally
#if 0
    BOOL isEMRIntegrated = YES;
#else
    BOOL isEMRIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isEMRIntegated;
#endif
    if (isEMRIntegrated) {
        
        SearchPatientsViewController *searchPetientsController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"SearchPatientsViewController"];
        
        if (self.isCareChannelMode) {
            if (self.conversation.encounter.patient) {
                // Since the UI to select messages is not ready yet, we always upload complete conversation
                // [self showUploadOptionsForPatient:patient];
                [searchPetientsController uploadCareChannelConversation:self.conversation];
            }
        }
        else {
            searchPetientsController.conversation = self.conversation;
            [self.navigationController pushViewController:searchPetientsController animated:YES];
        }
    } else {
        DDLogSupport(@"\n\nEMR Integration Not Activated...\n\n");
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1111-TextEMRNotActivate")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

- (void)uploadToKiteworks {
    
    BOOL isKiteworksIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isKiteworksIntegrated;
    if (isKiteworksIntegrated) {
        DDLogSupport(@"\n\nKiteworks still not integrated...\n\n");
    } else {
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1221-TextKiteworksConnectivityNotActivated")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

- (void)onPatientInfo {
    if (self.conversation.encounter.patient) {
        DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
        controller.contact = self.conversation.encounter.patient;
        controller.backButtonTitleString = QliqLocalizedString(@"2347-TitleCareChannel");
        
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        
        DDLogSupport(@"\n\n\nonPatientInfo: Patient is nil\n\n\n");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:QliqLocalizedString(@"3035-TextNoInfoAboutThePatient") preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"4-ButtonCancel", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onCareChannelInfo {
    
    if (self.conversation.encounter.patient) {
        [self showDetailContactViewControllerForConversation:self.conversation modal:YES];
    } else {
        DDLogSupport(@"\n\n\nonPatientInfo: Patient is nil\n\n\n");
    }
}

- (void)onMuteConversation
{
    if (self.conversation == nil) {
        DDLogSupport(@"Cannot conversation");
        return;
    }
    
    if (self.conversation.isMuted)
    {
        DDLogSupport(@"Conversation Refresh Called with 'unMute' Conversation");
    }
    else
    {
        DDLogSupport(@"Conversation Refresh Called  with 'mute' Conversation");
    }
    
    BOOL isMuted = !self.conversation.isMuted;
    
    [QliqConnectModule setConversationMuted:self.conversation.conversationId
                                   withUuid:self.conversation.uuid
                                  withMuted:isMuted
                         withCallWebService:YES];
    
    //    [self updateEditView];
}

#pragma mark * EditDeleteMode Actions

- (IBAction)onNavBarRightOptionalButton:(id)sender
{
    if (self.isDeleteMode) {
        self.isDeleteMode = NO;
        [self.selectedMessages removeAllObjects];
        self.selectedMessageUUID = nil;
        [self showToolbar:self.isDeleteMode];
        [self configureNavigationBar];
        self.chatsTable.allowsMultipleSelection = NO;
        [self.chatsTable reloadData];
    }
    else if (self.isSingleFieldMode)
    {
        if ([self.contactPickerView isContactPickerFirstResponder])
        {
            [self showSubjectViewInSingleMode];
        }
        else if ([self.subjectTextView isFirstResponder])
        {
            [self showKeyboardAccessoryViewInSingleMode];
        }
        else if ([self.downView.textView.internalTextView isFirstResponder])
        {
            [self showContactPickerViewInSingleMode];
        }
        [self.view layoutSubviews];
    }
}

- (IBAction)onDeleteAll:(id)sender
{
    BOOL wasSelectAll = [self.selectAllBtn.titleLabel.text isEqualToString:QliqLocalizedString(@"51-ButtonSelectAll")];
    
    if (wasSelectAll)
    {
        [self.selectedMessages removeAllObjects];
        [self.selectedMessages addObjectsFromArray:self.messagesArray];
    }
    else
    {
        [self.selectedMessages removeAllObjects];
    }
    
    [self configureSelectAllButtonTitle];
    [self.chatsTable reloadData];
}

- (IBAction)onDeleteMessage:(id)sender
{
    if (self.selectedMessages.count > 0) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1059-TextAskDeleteMessages")
                                    message:QliqLocalizedString(@"1060-TextItWillBeStillVisibleToRecipient")
                                buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                          cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==0) {
                                         if (self.selectedMessages.count > 0)
                                         {
                                             for (ChatMessage *message in self.selectedMessages)
                                             {
                                                 [[QliqConnectModule sharedQliqConnectModule] sendDeletedStatus:message];
                                             }
                                         }
                                         //Cancel
                                         [self onNavBarRightOptionalButton:nil];
                                     }
                                 }];
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:QliqLocalizedString(@"2411-TitleCanNotDeleteMessages")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
    }
         
}

- (IBAction)onRecallMessage:(id)sender
{
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1061-TextAskRecallMessages")
                                message:nil
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex==0) {
                                     if (self.selectedMessages.count != 0)
                                     {
                                         for (ChatMessage *message in self.selectedMessages)
                                         {
                                             BOOL isMyMessage = [[Helper getMyQliqId] isEqualToString:[message fromQliqId]];
                                             if (isMyMessage) {
                                                 [[QliqConnectModule sharedQliqConnectModule] sendRecalledStatus:message];
                                             }
                                         }
                                     }
                                     //Cancel
                                     [self onNavBarRightOptionalButton:nil];
                                 }
                             }];
}

- (IBAction)onResendMessage:(id)sender
{
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1062-TextAskResendMessages")
                                message:nil
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     if (self.selectedMessages.count > 0)
                                     {
                                         [self.refreshConversationOperationQueue addOperationWithBlock:^{
                                             for (ChatMessage *message in self.selectedMessages)
                                             {
                                                 BOOL isMyMessage = [[Helper getMyQliqId] isEqualToString:[message fromQliqId]];
                                                 if (isMyMessage) {
                                                     [self editCellWithMessageUUID:message.uuid editBlock:^(ChatMessage *message) {
                                                         
                                                         message.deliveryStatus  = 0;
                                                         message.receivedAt      = 0;
                                                         if (message.toQliqId.length == 0) {
                                                             message.toQliqId = self.conversation.recipients.qliqId;
                                                         }
                                                         [[QliqConnectModule sharedQliqConnectModule] sendMessage:message];
                                                     }];
                                                 }
                                             }
                                         }];
                                     }
                                     //Cancel
                                     [self onNavBarRightOptionalButton:nil];
                                 }
                             }];
}

- (NSString *)getForwardStringForMessage:(ChatMessage *)message
{
    NSString * autorString = [[[QliqUserDBService sharedService] getUserWithId:message.fromQliqId] displayName];
   
    NSTimeInterval time = message.createdAt;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.doesRelativeDateFormatting = NO;
    NSString * dateString = [formatter stringFromDate:messageDate];
    
    NSString * textString = message.text;
    NSString * seperatorString = @"---";
    
    return [NSString stringWithFormat:@">\n%@, %@:\n%@\n%@", autorString, dateString, textString, seperatorString];
}

- (IBAction)onForwardMessage:(id)sender
{
    ChatMessage *message = self.selectedMessages.lastObject;
    //Cancel
    [self onNavBarRightOptionalButton:nil];
    if (message) {
        
        NSString *messageText = [NSString stringWithFormat:@"%@ %@\n%@", QliqLocalizedString(@"2193-TitleOriginalTextFrom"),  [[[self.conversation.recipients allRecipients] lastObject] recipientTitle], message.text];
        NSString *subjectText = [NSString stringWithFormat:@"Fwd: %@", self.conversation.subject];
        MessageAttachment *attachment = [[message.attachments lastObject] copy];
        
        [self startNewConversationWithRecipients:nil
                                 withMessageText:messageText
                                 withSubjectText:subjectText
                           withMessageAttachment:attachment
                                   broadcastType:NotBroadcastType];
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:QliqLocalizedString(@"2412-TitleCanNotForwardMessages")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
    }
}

#pragma mark * UIMenuController

- (void)copyText:(id)sender
{
    [UIPasteboard generalPasteboard].string = @"";
    
    ChatMessage *message = [self messageWithUUID:self.selectedMessageUUID];
    
    MessageAttachment *messageAttachment = [message.attachments firstObject];
    if (messageAttachment) {
        [QliqAvatar sharedInstance].mediaFile = messageAttachment.mediaFile;
    }
    else {
        [QliqAvatar sharedInstance].mediaFile = nil;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES];
    
    if (message && pasteboard && [message isKindOfClass:[ChatMessage class]] && [pasteboard isKindOfClass:[UIPasteboard class]]) {
        pasteboard.string = message.text;
    }
    
    self.selectedMessageUUID = nil;
}

- (void)timestampMessage:(id)sender
{
    ChatMessage *message = [self messageWithUUID:self.selectedMessageUUID];
    
    MessageTimestampViewController *timestampMessageController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MessageTimestampViewController class])];
    timestampMessageController.message = message;
    timestampMessageController.isGroupMessage = [self isGroupOrMultiplyConversation];
    [self.navigationController pushViewController:timestampMessageController animated:YES];
    
    self.selectedMessageUUID = nil;
}

- (void)moreActions
{
    self.isDeleteMode = YES;
    [self.view endEditing:YES]; //for dismiss a keyboard if visible
    
    
    ChatMessage *message = [self messageWithUUID:self.selectedMessageUUID];
    if (message)
        [self.selectedMessages addObject:message];
    
    [self showToolbar:self.isDeleteMode];
    [self configureNavBarRightOptionButtonTitle:QliqLocalizedString(@"4-ButtonCancel")];
    
    self.titleBackBtn.hidden            = YES;
    self.lastTimeBtn.hidden             = YES;
    self.indicator.hidden               = YES;
    self.backButton.hidden              = YES;
    self.phoneButton.hidden             = YES;
    self.editOptionButton.hidden        = YES;
    self.navigationBarRightOptionalButton.hidden        = NO;
    self.selectAllBtn.hidden                            = self.isForward;
    
    NSMutableArray<UIBarButtonItem *> *toolBarButtons = [self.toolbar.items mutableCopy];
    [toolBarButtons removeAllObjects];
    [toolBarButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    if (self.isForward)
    {
        UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [forwardButton setTitle:QliqLocalizedString(@"1108-TextForward") forState:UIControlStateNormal];
        [forwardButton setTitleColor:RGBa(0, 120, 174, 1) forState:UIControlStateNormal];
        [forwardButton setFrame:CGRectMake(0, 0, 80, 30)];
        [forwardButton addTarget:self action:@selector(onForwardMessage:) forControlEvents:UIControlEventTouchDown];
        
        UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
        [toolBarButtons addObject:forwardItem];
    }
    else
    {
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setFrame:CGRectMake(0, 0, 20, 25)];
        NSLayoutConstraint *widthConstraint = [deleteButton.widthAnchor constraintEqualToConstant:20];
        NSLayoutConstraint *heightConstraint = [deleteButton.heightAnchor constraintEqualToConstant:25];
        [widthConstraint setActive:YES];
        [heightConstraint setActive:YES];
        [deleteButton setImage:[UIImage imageNamed:@"DeleteChat"] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(onDeleteMessage:) forControlEvents:UIControlEventTouchDown];
        
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithCustomView:deleteButton];
        [toolBarButtons addObject:deleteItem];
    }
    
    [toolBarButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [self.toolbar setItems:[toolBarButtons copy] animated:YES];
    self.chatsTable.allowsMultipleSelection = YES;
    [self.chatsTable reloadData];
}

- (void)recallAction:(id)sender {
    ChatMessage *message = [self messageWithUUID:self.selectedMessageUUID];
    self.selectedMessageUUID = nil;
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1061-TextAskRecallMessages")
                                message:nil
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     if (message.recalledStatus == NotRecalledStatus && message.isMyMessage && !message.isDeletedSent) {
                                         [[QliqConnectModule sharedQliqConnectModule] sendRecalledStatus:message];
                                     }
                                 }
                             }];
}

- (void)resendAction:(id)sender {
    ChatMessage *message = [self messageWithUUID:self.selectedMessageUUID];
    self.selectedMessageUUID = nil;
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1062-TextAskResendMessages")
                                message:nil
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     if (message.isMyMessage && !message.isDeletedSent)
                                     {
                                         [self.refreshConversationOperationQueue addOperationWithBlock:^{
                                             [self editCellWithMessageUUID:message.uuid editBlock:^(ChatMessage *message) {
                                                 message.deliveryStatus = 0;
                                                 message.receivedAt = 0;
                                                 if (message.toQliqId.length == 0)
                                                     message.toQliqId = self.conversation.recipients.qliqId;
                                                 [[QliqConnectModule sharedQliqConnectModule] sendMessage:message];
                                             }];
                                         }];
                                     }
                                 }
                             }];
}

#pragma mark - Delegates -

#pragma mark * TableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 0;
    
    if ([tableView isEqual:self.chatsTable]) {
        numberOfRows = self.messagesArray.count;
    } else if ([tableView isEqual:self.editViewTable]){
        numberOfRows = [self.editViewTableContent count];
    }
    
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat heightCell = 0.f;
    
    if ([tableView isEqual:self.chatsTable]) {
        
        if (indexPath.row < self.messagesArray.count) {

            ChatMessage *message = self.messagesArray[indexPath.row];
            
            if (message.type == ChatMessageTypeNormal) {
                heightCell = [ConversationTableViewCell getCellHeightWithMessage:message
                                                                      withBounds:self.chatsTable.bounds
                                                          itsForMessageTimestamp:NO];
            }
            else if (message.type == ChatMessageTypeEvent) {
                heightCell = [EventMessageCell heightForRowWithMessage:message];
            }
        } else {
            heightCell = kValueEditViewCellHeight;
        }
    } else if ([tableView isEqual:self.editViewTable]){
        heightCell = kValueEditViewCellHeight;
    }
    
    return heightCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if ([tableView isEqual:self.editViewTable]) {
        
        cell = [self setCellForEditTableView:tableView forIndexPath:indexPath];
        
    } else if ([tableView isEqual:self.chatsTable]){
        
        ChatMessage *message = self.messagesArray[indexPath.row];
        
        switch (message.type) {
            default:
            case ChatMessageTypeNormal: {
                
                ConversationTableViewCell *conversationCell = nil;
                
                if ([message isMyMessage])
                {
                    if (!message.hasAttachment) {
                        conversationCell = [tableView dequeueReusableCellWithIdentifier:ConversationMyCellId];
                    }
                    else {
                        conversationCell = [tableView dequeueReusableCellWithIdentifier:ConversationWithAttachmentMyCellId];
                    }
                }
                else
                {
                    if (!message.hasAttachment) {
                        conversationCell = [tableView dequeueReusableCellWithIdentifier:ConversationContactCellId];
                    }
                    else {
                        conversationCell = [tableView dequeueReusableCellWithIdentifier:ConversationWithAttachmentContactCellId];
                    }
                }
                
                conversationCell.delegate = self;
                conversationCell.tag = indexPath.row;
                
                //SetCellSettings
                [conversationCell setCellMessage:message ofUser:[message isMyMessage] isGroupConversation:[self isGroupOrMultiplyConversation] broadcastType:self.conversation.broadcastType itsForMessageTimestamp:NO];
                [conversationCell showDeletingMode:self.isDeleteMode messageIsChecked:[self.selectedMessages containsObject:message]];
                
                cell = conversationCell;
                break;
            }
            case ChatMessageTypeEvent:
            {
                
                EventMessageCell *eventMessageCell = nil;
                eventMessageCell = [tableView dequeueReusableCellWithIdentifier:kEventMessageIdentifier];
                eventMessageCell.message = message;
                
                eventMessageCell.tag = indexPath.row;
                
                cell =  eventMessageCell;
                break;
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.chatsTable]) {
        if (self.isDeleteMode) {
            [self changeSelectionOfItemAtIndexPath:indexPath tableView:tableView];
        }
    } else if ([tableView isEqual:self.editViewTable]){
        [self didSelectEditTable:tableView rowAtIndexPath:indexPath];
    }
}

#pragma mark * UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView isEqual:self.subjectTextView])
    {
        [self configureScrollingForSubjectView];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView isEqual:self.subjectTextView] && textView.text.length > 0)
    {
        CGPoint offsetPoint = CGPointZero;
        [textView setContentOffset:offsetPoint animated:YES];
    }
}

#pragma mark * UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.chatsTable]) {
        if (!self.editPopoverView.hidden) {
            self.editPopoverView.hidden = YES;
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark * EGORefreshTableViewHeaderView Delegate

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
    
    __block __weak typeof(self) weakSelf = self;
    [self getPages:self.pagesToLoad + 1 loadAsync:YES completionBlock:^(NSArray *messages) {
        performBlockInMainThreadSync(^{
            [view egoRefreshScrollViewDataSourceDidFinishedLoading:weakSelf.chatsTable completion:^{
                CGFloat tableContenSizeHeightBeforeReload = weakSelf.chatsTable.contentSize.height;
                [weakSelf updateChatsTableForce:YES withMessages:messages completion:^{
                    CGFloat tableContenSizeHeightAfterReload = weakSelf.chatsTable.contentSize.height;
                    if(tableContenSizeHeightBeforeReload != tableContenSizeHeightAfterReload)
                    {
                         CGPoint contentOffset =  CGPointMake(weakSelf.chatsTable.contentOffset.x, tableContenSizeHeightAfterReload - tableContenSizeHeightBeforeReload);
                        [weakSelf.chatsTable setContentOffset:contentOffset animated:NO];
                        [weakSelf.chatsTable setContentOffset:CGPointMake(weakSelf.chatsTable.contentOffset.x, weakSelf.chatsTable.contentOffset.y - 20.0) animated:YES];
                    }
                }];
            }];
        });
    }];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
    return NO;
}

#pragma mark * ConversationCell Delegate

- (void)reloadCellWithMessageUUID:(NSString *)uuid
{
    ChatMessage *updatedMessage = [self.messagesProvider fetchMessageWithUUID:uuid];
    if (updatedMessage)
    {
        __weak __block typeof(self) welf = self;
        [self.refreshConversationOperationQueue addOperationWithBlock:^{
            [welf updateTableWithReplacingMessages:@[updatedMessage] animation:UITableViewRowAnimationNone];
        }];
    }
    else
    {
        DDLogSupport(@"Nil message fetched from DB for UUID: %@", uuid);
    }
}

- (BOOL)ackGotForConversationTableViewCell:(ConversationTableViewCell *)cell {
    return [[QliqConnectModule sharedQliqConnectModule] sendAck:cell.chatMessage];
}

- (void)conversationTableViewCell:(ConversationTableViewCell *)cell didChangedAttachmentState:(ProgressState)state
{
    MessageAttachment *attachment = cell.chatMessage.attachments[0];
    
    __block __weak typeof(self) weakSelf = self;
    if (attachment.status == AttachmentStatusDownloaded) //if downloaded succefull
    {
        [attachment.mediaFile decrypt];
        dispatch_async_main(^{
            
            __strong typeof(self) strongSelf = weakSelf;
            
            if (!strongSelf)
                DDLogSupport(@"block preempted");
            else
                [strongSelf presentAttachment:attachment fromCell:cell];
        });
    }
}

- (void)downloadAttachments:(MessageAttachment *)attachment
{
    if ([[MediaFileService getInstance] fileSupportedWithMimeType:attachment.mediaFile.mimeType andFileName:attachment.mediaFile.fileName])
    {
        switch (attachment.status)
        {
            case AttachmentStatusDownloadFailed: break;
            case AttachmentStatusToBeDownloaded: {
                
                [[QliqConnectModule sharedQliqConnectModule] downloadAttachment:attachment completion:^(CompletitionStatus status, id result, NSError * error)
                 {
                     
                     if (error)
                     {
                         dispatch_async_main(^{
                             
                             [AlertController showAlertWithTitle:QliqLocalizedString(@"1063-TextFailedDownload")
                                                         message:[error localizedDescription]
                                                     buttonTitle:nil
                                               cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                      completion:nil];
                         });
                     }
                 }];
                
                break;
            }
            case AttachmentStatusUploading:
            case AttachmentStatusDownloading:
            case AttachmentStatusUploadFailed:
            case AttachmentStatusDeclined: break;
            default: break;
        }
    }
}

- (void)conversationTableViewCell:(ConversationTableViewCell *)cell didTappedAttachment:(MessageAttachment *)attachment
{
    //    DocumentAttachmentViewController *mediaViewer =  [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
    //    mediaViewer.mediaFile               = attachment.mediaFile;
    //    mediaViewer.shouldShowDeleteButton  = NO;
    //    [self.navigationController pushViewController:mediaViewer animated:YES];
    
    if ([[MediaFileService getInstance] fileSupportedWithMimeType:attachment.mediaFile.mimeType andFileName:attachment.mediaFile.fileName])
    {
        switch (attachment.status)
        {
            case AttachmentStatusDownloadFailed:
            case AttachmentStatusToBeDownloaded: {
                
                [[QliqConnectModule sharedQliqConnectModule] downloadAttachment:attachment completion:^(CompletitionStatus status, id result, NSError *error) {
                    
                    if (error)
                    {
                        DDLogError(@"%@", [error localizedDescription]);
                    }
                }];
                
                [self updateCellForAttachment:attachment];
                
                break;
            }
            case AttachmentStatusUploading:
            case AttachmentStatusDownloading: {
                
                [AlertController showAlertWithTitle:nil
                                            message:nil
                                        buttonTitle:QliqLocalizedString(@"18-ButtonStopTransfer")
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex == 0) {
                                                 NSDictionary * context = @{ @"target" : @PopOverAttachmentTag,
                                                                             @"progressHandlerKey" : [NSString stringWithFormat:@"%ld",(long)cell.attachmentImage.attachment.attachmentId] };
                                                 
                                                 ProgressHandler * progressHandler = [appDelegate.network.progressHandlers progressHandlerForKey:[context valueForKey:@"progressHandlerKey"]];
                                                 [progressHandler cancel];
                                             }
                                         }];
                break;
            }
            case AttachmentStatusUploadFailed:
            case AttachmentStatusDeclined: {
                
                for (MessageAttachment * attachment in cell.chatMessage.attachments)
                    attachment.status = AttachmentStatusToBeUploaded;
                [self sendMessage:cell.chatMessage];
                
                break;
            }
            default: {
                
                [self presentAttachment:attachment fromCell:cell];
                break;
            }
        }
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1004-TextUnsupportedFile")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
}

- (void)conversationTableViewCellNeedUpdate:(ConversationTableViewCell *)cell
{
    NSIndexPath *indexpath = [self.chatsTable indexPathForCell:cell];
    if ([self.messagesArray containsIndex:indexpath.row])
    {
        ChatMessage *message = self.messagesArray[indexpath.row];
        if ([cell.chatMessage isRead] && ![message isRead])
            [self.messagesArray replaceObjectAtIndex:indexpath.row withObject:cell.chatMessage];
        
        [self.chatsTable reloadData];
    }
    else
    {
        DDLogError(@"Wrong index on try to update cell");
    }
}

- (void)conversationTableViewCellWasLongPressed:(ConversationTableViewCell *)cell
{
    if (!self.isDeleteMode) {
        //Hide keyboard for inputTextView
        [self.keyboardAccessoryView endEditing:YES];
        
        //remeber choosen ChatMessage
        self.selectedMessageUUID = cell.chatMessage.uuid;
        
        //
        UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"2004-TitleCopy#message", nil) action:@selector(copyText:)];
        UIMenuItem *timestampItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"2005-TitleDetails#message", nil) action:@selector(timestampMessage:)];
        UIMenuItem *recallItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"2006-TitleRecall#message", nil) action:@selector(recallAction:)];
        UIMenuItem *resendItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"2007-TitleResend#message", nil) action:@selector(resendAction:)];
        UIMenuItem *forwardItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"1108-TextForward", nil) action:@selector(onForwardMessage)];
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"1046-TextDelete", nil) action:@selector(onDeleteMessages)];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        
        NSMutableArray *itemsArray = [NSMutableArray new];
        [itemsArray addObject:copyItem];
        [itemsArray addObject:timestampItem];
        
        if (!cell.chatMessage.isDeletedSent &&
            cell.chatMessage.isMyMessage &&
            cell.chatMessage.recalledStatus == NotRecalledStatus) {
            [itemsArray addObject:recallItem];
            [itemsArray addObject:resendItem];
        }
        [itemsArray addObject:forwardItem];
        [itemsArray addObject:deleteItem];
        
        if (![self isFirstResponder]) {
            [self becomeFirstResponder];
        }
        
        menuController.menuItems = itemsArray;
        [menuController setTargetRect:cell.messageTextView.frame inView:cell.messageTextView.superview];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)resendMessage:(ChatMessage *)message
{
    if (!self.isDeleteMode)
    {
        QliqConnectModule *qliqConnect = [QliqConnectModule sharedQliqConnectModule];
        __weak __block typeof(self) welf = self;
        [self.refreshConversationOperationQueue addOperationWithBlock:^{
            [welf editCellWithMessageUUID:message.uuid editBlock:^(ChatMessage *message) {
                message.deliveryStatus  = 0;
                message.receivedAt      = 0;
                if (!message.toQliqId) {
                    message.toQliqId = self.conversation.recipients.qliqId;
                }
                [qliqConnect sendMessage:message];
            }];
        }];
    }
}

- (void)phoneNumberWasPressedInCell:(ConversationTableViewCell *)cell andPhoneNumber:(NSString *)calleePhoneNumber {
    
    DDLogSupport(@"phoneNumberWasPressedInCell called");
    
    CallAlertService *callAlertService = [self getCallAlertService];
    
    __weak __block typeof(self) welf = self;
    
    [callAlertService setCustomAlertsPreShowBlock:^{
        [welf.downView.view endEditing:YES];
        [welf removeKeyboardNotifications];
    }];
    
    [callAlertService setCustomAlertsAfterDismissBlock:^{
        [welf addKeyboardNotifications];
    }];
    
    [callAlertService phoneNumberWasSelectedForAction:calleePhoneNumber];
    
}

- (void)cell:(ConversationTableViewCell *)cell qliqAssistedViewWasTappedWithPhoneNumbers:(NSMutableArray *)phoneNumbers {
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"2325-TitleChoosePhoneNumber")
                                message:nil
                       withTitleButtons:phoneNumbers
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex != phoneNumbers.count) {
                                     [self phoneNumberWasPressedInCell:cell andPhoneNumber:[phoneNumbers objectAtIndex:buttonIndex]];
                                 }
                             }];
    
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"2325-TitleChoosePhoneNumber")
//                                                                                 message:nil
//                                                                          preferredStyle:UIAlertControllerStyleAlert];
//        for (NSString *phoneNumber in phoneNumbers) {
//            UIAlertAction *phoneAction = [UIAlertAction actionWithTitle:phoneNumber
//                                                                  style:UIAlertActionStyleDefault
//                                                                handler:^(UIAlertAction * _Nonnull action) {
//                                                                    //Qliq Assisted
//                                                                    [self phoneNumberWasPressedInCell:cell andPhoneNumber:phoneNumber];
//                                                                }];
//
//            [alertController addAction:phoneAction];
//        }
//
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
//                                                               style:UIAlertActionStyleCancel
//                                                             handler:nil];
//        [alertController addAction:cancelAction];
//        [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark * ContactsActionSheetDelegate

- (void)actionSheet:(ContactsActionSheet *)actionSheet onDirectCallTo:(NSString *)calleePhoneNumber {
    
    [[self getCallAlertService] onDirectCallTo:calleePhoneNumber];
}

- (void)actionSheet:(ContactsActionSheet *)actionSheet onQliqAssistedCallTo:(NSString *)calleePhoneNumber {
    
    CallAlertService *callAlertService = [self getCallAlertService];
    
    __weak __block typeof(self) welf = self;
    
    [callAlertService setCustomAlertsPreShowBlock:^{
        [welf.downView.view endEditing:YES];
        [welf removeKeyboardNotifications];
    }];
    
    [callAlertService setCustomAlertsAfterDismissBlock:^{
        [welf addKeyboardNotifications];
    }];
    
    [callAlertService onQliqAssistedCallTo:calleePhoneNumber];
}

#pragma mark * KeyboardAccessoryView Delegate

- (void)keyboardInputAccessoryViewSendPressed:(KeyboardAccessoryViewController *)inputView {
    [self handleSendButtonPressed];
}

- (void)keyboardInputAccessoryViewQuickMessagePressed:(KeyboardAccessoryViewController *)inputView
{
    QuickMessageViewController *quickMessageController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([QuickMessageViewController class])];
    quickMessageController.delegate = self;
    [self.navigationController pushViewController:quickMessageController animated:YES];
}

- (void)keyboardInputAccessoryView:(KeyboardAccessoryViewController *)inputView didPressAttachment:(MessageAttachment *)attachment {
    [self presentAttachment:attachment fromCell:nil];
}

- (void)showAlert:(UIAlertView_Blocks *)alert withBlock:(void (^)(NSInteger))block {
    
    if (block) {
        [alert showWithDissmissBlock:block];
    } else {
        [alert showWithDissmissBlock:nil];
    }
}

- (NSString *)getPagerNumber {
    
    NSString *pagerInfo = @"";
    
    if (self.isPagerMode) {
        if (self.conversation.recipients && self.conversation.recipients.isSingleUser) {
            pagerInfo = ((QliqUser *)self.conversation.recipients.recipient).pagerInfo;
        } else if (self.recipients && self.recipients.isSingleUser) {
            pagerInfo = ((QliqUser *)self.recipients.recipient).pagerInfo;
        }
        
        
        
        if (pagerInfo.length > 0) {
            pagerInfo = [pagerInfo stringByReplacingOccurrencesOfString:@"<" withString:@""];
            pagerInfo = [pagerInfo stringByReplacingOccurrencesOfString:@">" withString:@""];
            if (pagerInfo.length > 5) {
                pagerInfo = [pagerInfo substringFromIndex:5];
                
                NSArray *stringsArray = [pagerInfo componentsSeparatedByString:@"@"];
                NSString *numberPart = stringsArray.firstObject;
                
                NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                if ([numberPart rangeOfCharacterFromSet:notDigits].location == NSNotFound)
                {
                    pagerInfo = numberPart;
                }
            }
        }
    }
    return pagerInfo;
}

- (CGFloat)getMaxHeightForKeyboardAccessoryView {
    __block CGFloat maxHeight = 0.f;
    CGFloat freeSpace = self.view.frame.size.height;
    if (self.isNewConversation)
    {
        CGFloat enterFieldsHeight = 0.f;
        
        if (self.isSingleFieldMode) {
            enterFieldsHeight = kDefaultContactPickerTopConstraint +
            kDefaultContactPickerHeightConstraint +
            kDefaultSubjectViewTopConstraint +
            kDefaultSubjectViewHeightConstraint;
        }
        else
        {
            enterFieldsHeight = self.contactPickerTopConstraint.constant +
            self.contactPickerHeightConstraint.constant +
            self.subjectViewTopConstraint.constant +
            self.subjectViewHeightConstraint.constant;
        }
        
        maxHeight = freeSpace - enterFieldsHeight - self.keyboardHeight - kValueMarginFromSubjectView;
    }
    else
    {
        void (^selectionBlock)(void) = ^{
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            {
                maxHeight = kMaxHeightOfKeyboardAccessoryViewResignedFirstResponder;
            }
            else
            {
                maxHeight = kMinimumHeightKeyboardAccessoryViewWithSelectAttachment;
            }
        };
        
        if (self.downView.textViewWillResignFirstResponder)
        {
            selectionBlock();
        }
        else if ([self.downView.textView.internalTextView isFirstResponder])
        {
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            {
                maxHeight = freeSpace - self.keyboardHeight - kMinHeightOfChatsTable;
            }
            else
            {
                maxHeight = kMinimumHeightKeyboardAccessoryViewWithSelectAttachment;
            }
        }
        else
        {
            selectionBlock();
        }
    }
    return maxHeight;
}

- (void)scrollUpChatTableDown:(BOOL)scrollDown offset:(CGFloat)offset isSentMessage:(BOOL)isSentMessage animated:(BOOL)animated {
    if (!self.isNewConversation && !isSentMessage)
    {
        CGFloat delta = scrollDown ? offset : (self.chatsTable.contentOffset.y == 0.f || self.chatsTable.contentOffset.y < offset) ? self.chatsTable.contentOffset.y : offset;

        if (delta != 0.f && self.chatsTable.contentSize.height > self.chatsTable.frame.size.height)
        {
            if (self.downView.attachmentsList.count) {
                //if message contains attachment
                delta = fabs(delta) + kMessageAttachmentHeight;
            }

            CGPoint tableOffset = CGPointMake(0.f, [self.chatsTable contentOffset].y + fabs(delta));
            [self.chatsTable setContentOffset:tableOffset animated:YES];
        }
    }
}

- (BOOL)isSingleFieldModeSetup
{
    return self.isSingleFieldMode;
}

- (BOOL)turnOnSingleFieldMode:(BOOL)isSingleFieldMode {
    
    if (self.isSingleFieldMode != isSingleFieldMode)
    {
        self.isSingleFieldMode = isSingleFieldMode;
        if (self.isNewConversation)
        {
            if (isSingleFieldMode)
            {
                self.contactPickerLeadingConstraint.constant = 0.f;
                self.contactPickerTrallingConstraint.constant = 0.f;
                self.contactPickerTopConstraint.constant = 0.f;
                
                self.subjectViewTopConstraint.constant = 0.f;
                self.subjectViewLeadingConstraint.constant = 0.f;
                self.subjectViewTrallingConstraint.constant = 0.f;
                
                if ([self.contactPickerView isContactPickerFirstResponder])
                    [self showContactPickerViewInSingleMode];
                else if ([self.subjectTextView  isFirstResponder])
                    [self showSubjectViewInSingleMode];
                else if ([self.downView.textView.internalTextView isFirstResponder])
                    [self showKeyboardAccessoryViewInSingleMode];
                
                DDLogSupport(@"SingleField mode is ON");
            }
            else
            {
                self.contactPickerHeightConstraint.constant = self.defaultContactPickerHeightConstraint;
                self.contactPickerLeadingConstraint.constant = self.defaultContactPickerLeadingConstraint;
                self.contactPickerTrallingConstraint.constant = self.defaultContactPickerTrallingConstraint;
                self.contactPickerTopConstraint.constant = self.defaultContactPickerTopConstraint;
                
                self.subjectViewHeightConstraint.constant = kDefaultSubjectViewHeightConstraint;
                self.subjectViewTopConstraint.constant = kDefaultSubjectViewTopConstraint;
                self.subjectViewLeadingConstraint.constant = kDefaultSubjectViewLeadingConstraint;
                self.subjectViewTrallingConstraint.constant = kDefaultSubjectViewTrallingConstraint;
                self.subjectViewTopConstraint.constant = kDefaultSubjectViewTopConstraint;
                
                self.subjectView.hidden = NO;
                self.contactPickerView.hidden = NO;
                self.keyboardAccessoryView.hidden = NO;
                
                DDLogSupport(@"SingleField mode is OFF");
            }
            
            [self configureNavigationBar];
            
            return YES;
        }
        else
        {
            DDLogSupport(@"Is not new conversation");
        }
        
    }
    else
    {
        DDLogSupport(@"SingleField mode is already - %@", self.isSingleFieldMode ? @"ON" : @"OFF");
        return YES;
    }
    return NO;
}

#pragma mark * THContactPickerTextView Delegate

- (void)contactPickerTextViewDidChange:(NSString *)textViewText
{
    if (self.isNewConversation)
    {
        // SelectParticipants
        {
            self.recipients.name = @"";
            self.recipients.isPersonalGroup = NO;
            self.selectContactsViewController.participants = [self.recipients.recipientsArray mutableCopy];
            self.selectContactsViewController.firstFilterCharacter = textViewText;
            [self.navigationController pushViewController:self.selectContactsViewController animated:YES];
        }
        
        [self.contactPickerView resignFirstResponder];
        
        __weak __block typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            [weakSelf.view layoutSubviews];
        } completion:nil];
    }
}

- (void)contactPickerDidResize:(THContactPickerView *)contactPickerView {
    self.defaultContactPickerHeightConstraint = contactPickerView.frame.size.height;
    self.contactPickerHeightConstraint.constant = contactPickerView.frame.size.height;
    [self.view layoutSubviews];
}

- (void)contactPickerDidRemoveContact:(id)contact
{
    self.recipients.name = @"";
    self.recipients.isPersonalGroup = NO;
    
    [self.recipients removeRecipient:contact];
}

- (CGFloat)getContactPickerWidth
{
    CGFloat width = 0.f;
    CGRect rect = CGRectZero;
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
    }
    else if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
    {
        rect = CGRectMake(0, 0, MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
    }
    
    width = rect.size.width - self.contactPickerLeadingConstraint.constant - self.contactPickerTrallingConstraint.constant;
    
    return width;
}

#pragma mark * QuickMessageListViewDelegate

- (void)quickMessageSelected:(NSString *)quickMessageText {
    
    [self saveUnsentMessage:@""];
    
    [self.downView appendMessageText:quickMessageText];
}

#pragma mark * SelectContactsViewDelegate

- (void)didSelectedParticipants:(NSMutableArray *)participants {
    
    [self.recipients.recipientsArray removeAllObjects];
    [self.recipients.recipientsArray addObjectsFromArray:participants];
    
}

#pragma mark - Edit Participants Delegates

- (void)editDoneWithEditedParticipants:(NSMutableArray *)participants withSubject:(NSString *)subject withRoles:(NSDictionary *)participantsRoles withCompletion:(void (^)())completion
{
    NSAssert(self.conversation, @"Must be conversations");
    
    if (self.conversation) {
        
        Recipients *newRecipients = [[Recipients alloc] init];
        newRecipients.name = self.conversation.recipients.name;
        for (id <Recipient> recipient in participants) {
            [newRecipients addRecipient:recipient];
        }
        
        BOOL recipientsChanged = ![newRecipients isEqual:self.conversation.recipients];
        BOOL subjectChanged = ![subject isEqualToString:self.conversation.subject];
        BOOL recipientsRolesChanged = NO;
        BOOL recipientsIsGroup = newRecipients.isGroup;
        BOOL recipientsWasGroup = self.conversation.recipients.isGroup;
        
        
        if ([self.conversation isCareChannel]) {
            recipientsRolesChanged = [self checkRecipientsRoles:participantsRoles];
        }
        
        /* If subject changed - create new conversation */
        if (subjectChanged || recipientsIsGroup || (recipientsWasGroup && !recipientsIsGroup)) {
            
            __block __weak typeof(self) weakSelf = self;
            [AlertController showActionSheetAlertWithTitle:nil
                                                   message:nil
                                          withTitleButtons:@[NSLocalizedString(@"1113-TextCreateConversation", nil)]
                                         cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil) completion:^(NSUInteger buttonIndex) {
                                             
                                             if (completion) {
                                                 completion();
                                             }
                                             
                                             if (buttonIndex == 0) {
                                                 [weakSelf startNewConversationWithRecipients:newRecipients
                                                                              withMessageText:nil
                                                                              withSubjectText:subject
                                                                        withMessageAttachment:nil
                                                                                broadcastType:weakSelf.conversation.broadcastType];
                                             }
                                         }];
        }
        /* If only recipients changed - ask for action */
        else if (recipientsChanged) {
            __block __weak typeof(self) weakSelf = self;
            [AlertController showAlertWithTitle:nil
                                        message:nil
                               withTitleButtons:@[NSLocalizedString(@"1113-TextCreateConversation", nil), NSLocalizedString(@"1114-TextContinueConversation", nil)]
                              cancelButtonTitle:nil completion:^(NSUInteger buttonIndex) {
                                  
                                  if (completion) {
                                      completion();
                                  }
                                  
                                  if (buttonIndex == 0) {
                                      [weakSelf startNewConversationWithRecipients:newRecipients
                                                               withMessageText:nil
                                                               withSubjectText:subject
                                                         withMessageAttachment:nil
                                                                 broadcastType:self.conversation.broadcastType];
                                  } else {
                                      [weakSelf updateCurrentConversationWithRecipients:newRecipients
                                                                    withSubjectText:subject
                                                                          withRoles:participantsRoles];
                                      [weakSelf.navigationController popToViewController:self animated:YES];
                                  }
                              }];
        } else if (recipientsRolesChanged && self.conversation.isCareChannel) {
            [self updateCurrentConversationWithRecipients:newRecipients
                                          withSubjectText:subject
                                                withRoles:participantsRoles];
        }
    }
}

#pragma mark * DetailContacInfoDelegate

- (void)editDoneFromCareChannelInfo:(NSMutableArray *)careTeam withRoles:(NSDictionary *)participantsRoles withCompletion:(void (^)())completion {
    [self editDoneWithEditedParticipants:careTeam withSubject:self.conversation.subject withRoles:participantsRoles withCompletion:completion];
}

- (void)editDoneFromConversationInfo:(NSMutableArray *)participants withSubject:(NSString *)subject withCompletion:(void (^)())completion {
    [self editDoneWithEditedParticipants:participants withSubject:subject withRoles:nil withCompletion:completion];
}

@end

//
//  MainViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "MainViewController.h"

#import "RecentsViewController.h"
#import "ContactsViewController.h"
#import "MediaViewController.h"
#import "CurtainMenuViewController.h"
#import "ReceivedPushNotificationDBService.h"
#import "QliqConnectModule.h"
#import "UIDevice-Hardware.h"

#import "MediaFileUploadDBService.h"

#import "ResizeBadge.h"

#define kMinBadgeWidth 14.f
#define kRecentsButtonContentMargin  5.f
#define kBadgeValueLeading  3.f
#define kMainSegmentTopConstraintPortrait 35.f
#define kMainSegmentTopConstraintLandscape 0.f

#define kUpdateMediaBadgeNumberNotification @"UpdateMediaBadgeNumberNotification"

typedef NS_ENUM(NSInteger, ContentType) {
    ContentTypeRecents = 1,
    ContentTypeContacts,
    ContentTypeMedia
};

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIView *mainSegmentControlView;
@property (weak, nonatomic) IBOutlet UILabel *badgeValue;

@property (weak, nonatomic) IBOutlet UIButton *recentsButton;
@property (weak, nonatomic) IBOutlet UIButton *contactsButton;
@property (weak, nonatomic) IBOutlet UIButton *mediaButton;

@property (weak, nonatomic) IBOutlet UIView *recentsView;
@property (weak, nonatomic) IBOutlet UILabel *recentsTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *recentsButtonContentView;

@property (weak, nonatomic) IBOutlet UIView *mediaContentButtonView;
@property (weak, nonatomic) IBOutlet UILabel *mediaTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *mediaBadgeValue;

@property (weak, nonatomic) RecentsViewController *recentsViewController;

@property (weak, nonatomic) IBOutlet UIView *contactsView;
@property (weak, nonatomic) ContactsViewController *contactsViewController;

@property (weak, nonatomic) IBOutlet UIView *mediaView;
@property (weak, nonatomic) MediaViewController *mediaViewController;

@property (weak, nonatomic) IBOutlet UIView *curtainMenu;
@property (weak, nonatomic) CurtainMenuViewController *curtainMenuViewController;

@property (nonatomic, assign) ContactType currentContentType;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *curtainViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightCurtainConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentsTitleLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeValueLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeValueWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaBadgeLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaBadgeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaTitleLabelWidthConstraint;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainSegmentControlTopConstraint;

@property (nonatomic, assign) CGFloat recentsTitleLabelWidth;
@property (nonatomic, assign) CGFloat mediaTitleLabelWidth;

@end

@implementation MainViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverForCountUnreadMessages];
    [self removeObserverForCountFailedUploadingMedia];
    
    self.badgeValue = nil;
    self.recentsButton = nil;
    self.contactsButton = nil;
    self.mediaButton = nil;
    self.mediaContentButtonView = nil;
    self.mediaBadgeValue = nil;
    self.mediaTitleLabel = nil;
    self.mainSegmentControlView = nil;
    self.recentsView = nil;
    self.contactsView = nil;
    self.mediaView = nil;
    self.recentsViewController = nil;
    self.contactsViewController = nil;
    self.mediaViewController = nil;
    self.curtainMenu = nil;
    self.curtainMenuViewController = nil;
    self.currentContentType = nil;
    self.curtainViewWidthConstraint = nil;
    self.rightCurtainConstraint = nil;
    self.mediaBadgeWidthConstraint = nil;
    self.mediaBadgeLeadingConstraint = nil;
    self.mediaTitleLabelWidthConstraint = nil;
    [self.contactsView removeFromSuperview];
    [self.view removeFromSuperview];
}

- (void)configureDefaultText {
    [self setTitleRecentsText:QliqLocalizedString(@"2096-TitleRecents")];
    [self.contactsButton setTitle:QliqLocalizedString(@"2097-TitleContacts") forState:UIControlStateNormal];
    [self setTitleMediaText:QliqLocalizedString(@"2098-TitleMedia")];
//    [self.mediaButton setTitle:QliqLocalizedString(@"2098-TitleMedia") forState:UIControlStateNormal];
}

- (void)setTitleRecentsText:(NSString *)text
{
    self.recentsTitleLabel.text = text;
    
    CGSize suggestedSize = [self.recentsTitleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.recentsTitleLabel.font}];
    
    self.recentsTitleLabelWidth = suggestedSize.width + 2.f;
}

- (void)setTitleMediaText:(NSString *)text
{
    self.mediaTitleLabel.text = text;

    CGSize suggestedSize = [self.mediaTitleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.mediaTitleLabel.font}];

    self.mediaTitleLabelWidth = suggestedSize.width + 2.f;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
        isIPhoneX {
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
        }

    [self configureDefaultText];
    
    UITapGestureRecognizer *tapGestureRecentsTitle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecentsTitle:)];
    //Configure recentsTitleLabel
    {
        [self.recentsTitleLabel setUserInteractionEnabled:YES];
        [self.recentsTitleLabel addGestureRecognizer:tapGestureRecentsTitle];
        self.recentsTitleLabelWidthConstraint.constant = self.recentsTitleLabelWidth;
    }

    UITapGestureRecognizer *tapGestureMediaTitle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureMediaTitle:)];
    //Configure recentsTitleLabel
    {
        [self.mediaTitleLabel setUserInteractionEnabled:YES];
        [self.mediaTitleLabel addGestureRecognizer:tapGestureMediaTitle];
        self.mediaTitleLabelWidthConstraint.constant = self.mediaTitleLabelWidth;
    }
    
    //Recents Badge
    {
        self.badgeValue.layer.cornerRadius = 7.f;
        self.badgeValue.clipsToBounds = YES;
        self.badgeValue.hidden = YES;
        self.badgeValue.numberOfLines = 1;
        self.badgeValue.minimumScaleFactor = 5.f / self.badgeValue.font.pointSize;
        self.badgeValueWidthConstraint.constant = 0.f;
        self.badgeValueLeadingConstraint.constant = 0.f;
    }

    //Media Badge
    {
        self.mediaBadgeValue.layer.cornerRadius = 7.f;
        self.mediaBadgeValue.clipsToBounds = YES;
        self.mediaBadgeValue.hidden = YES;
        self.mediaBadgeValue.numberOfLines = 1;
        self.mediaBadgeValue.minimumScaleFactor = 5.f / self.mediaBadgeValue.font.pointSize;
        self.mediaBadgeWidthConstraint.constant = 0.f;
        self.mediaBadgeLeadingConstraint.constant = 0.f;
    }
    
    [self showCurtainView:NO];
    

    //Get Child view controllers
    for (UIViewController *viewController in self.childViewControllers)
    {
        if ([viewController isKindOfClass:[CurtainMenuViewController class]]) {
            self.curtainMenuViewController = (CurtainMenuViewController *)viewController;
        }
        
        if ([viewController isKindOfClass:[RecentsViewController class]]) {
            self.recentsViewController = (RecentsViewController *)viewController;
        }
        
        if ([viewController isKindOfClass:[ContactsViewController class]]) {
            self.contactsViewController = (ContactsViewController *)viewController;
        }
        
        if ([viewController isKindOfClass:[MediaViewController class]]) {
            self.mediaViewController = (MediaViewController *)viewController;
        }
    }
    
    //Notifications
    {
        /* //Delte Later
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLockScreenShowed:)
                                                     name:kDeviceLockStatusChangedNotificationName object:nil];
        */
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showCurtainViewPressed:)
                                                     name:kShowCurtainViewNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(chooseOnCallGroups:)
                                                     name:kShowOnCallGroupsNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(openMedia:)
                                                     name:OpenMediaControllerNotification
                                                   object:nil];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(openPDFInMedia:)
//                                                     name:OpenPDFInMediaControllerNotification
//                                                   object:nil];
    }
    
    [self.view bringSubviewToFront:self.recentsView];
    self.currentContentType = ContentTypeRecents;
    self.recentsViewController.containerSelected = YES;

    [self.contactsView removeFromSuperview];
    [self.mediaView removeFromSuperview];
    
    [self addObserverForCountUnreadMessages];
    [self addObserverForCountFailedUploadingMedia];
    [self updateRecentsUnreadBadgeNumber:nil];
    [self updateMediaBadgeNumber:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            [weakSelf rotated:nil];
            [weakSelf.view layoutIfNeeded];
        }
    });
    self.navigationController.navigationBarHidden = YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Private -

- (void)showCurtainView:(BOOL)show
{
    
    if (show) {
        [self.curtainMenuViewController configureProfileView];
        [self.view bringSubviewToFront:self.curtainMenu];
    }
    
    if ((show && self.rightCurtainConstraint.constant == 0) ||
        (!show && self.rightCurtainConstraint.constant != 0)) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidShowedCurtainViewNotification object:[NSNumber numberWithBool:show]];
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            welf.rightCurtainConstraint.constant = show ? 0.0f : -welf.curtainViewWidthConstraint.constant;
            [welf.view layoutIfNeeded];
        } completion:nil];
    });
    
}

- (void)removeMenuView:(ContentType)type {
   
    UIColor *selectedColor = RGBa(49.f, 79.f, 116.f, 1.f);

    switch (type)
    {
        case ContentTypeRecents: {
            
            DDLogSupport(@"removeMenuView \"Recents\"");
         
            [self.recentsButton     setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlLeftUp"] forState:UIControlStateNormal];
            [self.recentsTitleLabel setTextColor:selectedColor];
            self.recentsViewController.containerSelected = NO;
            
            [self.recentsView removeFromSuperview];
            
            break;
        }
        case ContentTypeContacts: {
            DDLogSupport(@"removeMenuView \"Contacts\"");
            
            [self.contactsButton    setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlCenterUp"] forState:UIControlStateNormal];
            
            [self.contactsButton    setTitleColor:selectedColor forState:UIControlStateNormal];
            
            self.contactsViewController.isHide = YES;
            
            [self.contactsView removeFromSuperview];
            
            break;
        }
        case ContentTypeMedia: {
            
            DDLogSupport(@"removeMenuView \"Media\"");
            
            [self.mediaButton       setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlRightUp"] forState:UIControlStateNormal];
            [self.mediaTitleLabel setTextColor:selectedColor];

//            [self.mediaButton       setTitleColor:selectedColor forState:UIControlStateNormal];

            self.mediaViewController.isHide = YES;
            
            [self.mediaView removeFromSuperview];
      
            break;
        }
        default:
            break;
    }
}

- (void)changeCurrentMenuWithSelected:(ContentType)type
{
    [self removeMenuView:self.currentContentType];
    
    self.currentContentType = type;

    UIColor *deselectedColor = [UIColor whiteColor];
    
    switch (type)
    {
        case ContentTypeRecents: {
            
            DDLogSupport(@"SelectMenuItem \"Recents\"");
            
            [self.recentsButton setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlLeftDown"] forState:UIControlStateNormal];
            [self.recentsTitleLabel setTextColor:deselectedColor];

            self.recentsViewController.containerSelected = YES;
            
            [self.recentsView removeFromSuperview];
            [self.view addSubview:self.recentsView];
            
            [self addConstraintForView:type];
            
            break;
        }
        case ContentTypeContacts: {
            DDLogSupport(@"SelectMenuItem \"Contacts\"");
            
            [self.contactsButton setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlCenterDown"] forState:UIControlStateNormal];

            [self.contactsButton setTitleColor:deselectedColor forState:UIControlStateNormal];
            
            self.contactsViewController.isHide = NO;
            [self.contactsView removeFromSuperview];
            [self.view addSubview:self.contactsView];

            
            [self addConstraintForView:type];
        
            break;
        }
        case ContentTypeMedia: {
            
            DDLogSupport(@"SelectMenuItem \"Media\"");
            
            [self.mediaButton setBackgroundImage:[UIImage imageNamed:@"MainSegmCtrlRightDown"] forState:UIControlStateNormal];
            [self.mediaTitleLabel setTextColor:deselectedColor];
//            [self.mediaButton setTitleColor:deselectedColor forState:UIControlStateNormal];

            self.mediaViewController.isHide = NO;
            
            [self.mediaView removeFromSuperview];
            [self.view addSubview:self.mediaView];
            
            [self addConstraintForView:type];
             
            break;
        }
        default:
            break;
    }
    
        [self showCurtainView:NO];
    
}

- (void)addConstraintForView:(ContentType)type
{
    switch (type)
    {
        case ContentTypeRecents: {
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.recentsView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.mainSegmentControlView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.recentsView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.bottomLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.recentsView
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.recentsView
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1
                                                                   constant:0]];
            break;
        }
        case ContentTypeContacts: {
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contactsView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.mainSegmentControlView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contactsView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.bottomLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contactsView
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contactsView
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1
                                                                   constant:0]];
            break;
        }
        case ContentTypeMedia: {
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.mainSegmentControlView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.bottomLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaView
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1
                                                                   constant:0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaView
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1
                                                                   constant:0]];
            break;
        }
        default:
            break;
    }
}

- (void)tapGestureRecentsTitle:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self onSelectMenuItem:self.recentsButton];
}

- (void)tapGestureMediaTitle:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self onSelectMenuItem:self.mediaButton];
}

- (void)rotated:(NSNotification*)notification {
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            
            weakSelf.mainSegmentControlTopConstraint.constant = kMainSegmentTopConstraintLandscape;
            
        }  else {
            
            weakSelf.mainSegmentControlTopConstraint.constant = kMainSegmentTopConstraintPortrait;
        }
    });
}

#pragma mark - Notifications

- (void)chooseOnCallGroups:(NSNotification *)notification {
    [self changeCurrentMenuWithSelected:ContentTypeContacts];
    
    self.contactsViewController.groupListPopover.currentGroup = GroupListOnCallGroups;
    [self.contactsViewController pressedGroup:GroupListOnCallGroups];
}

- (void)openPDFInMedia:(NSNotification *)notification
{
    self.mediaViewController.reloadOnAppering = YES;
    [self changeCurrentMenuWithSelected:ContentTypeMedia];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOpenPDFNotification object:notification.object];
}

- (void)openMedia:(NSNotification *)notification
{
    self.mediaViewController.reloadOnAppering = YES;
    [self changeCurrentMenuWithSelected:ContentTypeMedia];
}

- (void)showCurtainViewPressed:(NSNotification *)notification {
    DDLogSupport(@"DidPressShowCurtainView");
    
    NSNumber *info = [notification object];
    
    if (info) {
        [self showCurtainView:[info boolValue]];
        return;
    }
    
    [self showCurtainView:self.rightCurtainConstraint.constant != 0];
}

#pragma mark - Unread Messages Badge

- (void)addObserverForCountUnreadMessages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRecentsUnreadBadgeNumber:) name:ChatBadgeValueNotification object:nil];
}

- (void)removeObserverForCountUnreadMessages {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ChatBadgeValueNotification object:nil];
}

- (void)updateRecentsUnreadBadgeNumber:(NSNotification *)notif {
    
    __block NSInteger unreadBadgeCount = 0;

    self.badgeValue.adjustsFontSizeToFitWidth = NO;
    
    __weak __block typeof(self) welf = self;
    void(^updateBadgeBlock)(void) = ^{
        
        [UIView animateWithDuration:0.25f animations:^{
            welf.badgeValue.text = [NSString stringWithFormat:@"%ld", (long)unreadBadgeCount];
            welf.badgeValue.hidden  = unreadBadgeCount == 0 ? YES : NO;
            
            if (!welf.badgeValue.hidden)
            {
                CGFloat neededWidthBadgeText = [ResizeBadge calculatingNeededWidthForBadge:welf.badgeValue.text rangeLength:welf.badgeValue.text.length font:welf.badgeValue.font];
                neededWidthBadgeText += 2.f;
                
                CGFloat maxWidthRecentsButtonContentView = welf.recentsButton.frame.size.width - 2 * kRecentsButtonContentMargin;
                CGFloat neededWidthRecentsButtonContentView = welf.recentsTitleLabelWidth + neededWidthBadgeText + kBadgeValueLeading;

                if (neededWidthRecentsButtonContentView > maxWidthRecentsButtonContentView)
                {
                    //Calculating the totalFreeSpace for width of badge
                    CGFloat totalFreeSpaceForBadge = maxWidthRecentsButtonContentView - welf.recentsTitleLabelWidthConstraint.constant - kBadgeValueLeading;

                    //Configure badge with for new text (calculating width badge, changing value of `badgeValue.text` if needed).
                    [ResizeBadge resizeBadge:welf.badgeValue
                              totalFreeSpace:totalFreeSpaceForBadge
                             canTextBeScaled:YES
                     setBadgeWidthCompletion:^(CGFloat calculatedWidth) {
                         [welf configureConstraintsForRecentsBadgeWidth:calculatedWidth];
                     }];
                }
                else
                {
                    [welf configureConstraintsForRecentsBadgeWidth:neededWidthBadgeText];
                }
            }
            else
            {
                welf.badgeValueLeadingConstraint.constant = 0.f;
                welf.badgeValueWidthConstraint.constant = 0.f;
            }
            [welf.badgeValue layoutSubviews];
        }];
    };
    
    if (notif.userInfo[@"newBadgeValue"])
    {
        unreadBadgeCount = [notif.userInfo[@"newBadgeValue"] integerValue];
        updateBadgeBlock();
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            unreadBadgeCount = [ChatMessage unreadMessagesCount];
            dispatch_async_main(^{
                updateBadgeBlock();
            });
        });
    }
}

- (void)configureConstraintsForRecentsBadgeWidth:(CGFloat)calculatedWidthBadge
{
    if (calculatedWidthBadge < kMinBadgeWidth && calculatedWidthBadge != 0)
    {
        calculatedWidthBadge = kMinBadgeWidth;
    }
    
    self.badgeValueWidthConstraint.constant = calculatedWidthBadge;
    self.badgeValueLeadingConstraint.constant = kBadgeValueLeading;
}

#pragma mark - Failed Uploading Files Badge

- (void)addObserverForCountFailedUploadingMedia {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMediaBadgeNumber:) name:UpdateMediaBadgeNumberNotification object:nil];
}

- (void)removeObserverForCountFailedUploadingMedia {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpdateMediaBadgeNumberNotification object:nil];
}

- (void)updateMediaBadgeNumber:(NSNotification *)notif {

    __block NSInteger failedUploadingBadgeCount = 0;

    self.mediaBadgeValue.adjustsFontSizeToFitWidth = NO;

    __weak __block typeof(self) welf = self;
    void(^failedUploadingBadgeBlock)(void) = ^{

        [UIView animateWithDuration:0.25f animations:^{
            welf.mediaBadgeValue.text = [NSString stringWithFormat:@"%ld", (long)failedUploadingBadgeCount];
            welf.mediaBadgeValue.hidden  = failedUploadingBadgeCount == 0 ? YES : NO;

            if (!welf.mediaBadgeValue.hidden)
            {
                CGFloat neededWidthBadgeText = [ResizeBadge calculatingNeededWidthForBadge:welf.mediaBadgeValue.text rangeLength:welf.mediaBadgeValue.text.length font:welf.mediaBadgeValue.font];
                neededWidthBadgeText += 2.f;

                CGFloat maxWidthMediaButtonContentView = welf.mediaButton.frame.size.width - 2 * kRecentsButtonContentMargin;
                CGFloat neededWidthMediaButtonContentView = welf.mediaTitleLabelWidth + neededWidthBadgeText + kBadgeValueLeading;

                if (neededWidthMediaButtonContentView > maxWidthMediaButtonContentView)
                {
                    //Calculating the totalFreeSpace for width of badge
                    CGFloat totalFreeSpaceForBadge = maxWidthMediaButtonContentView - welf.mediaTitleLabelWidthConstraint.constant - kBadgeValueLeading;

                    //Configure badge with for new text (calculating width badge, changing value of `badgeValue.text` if needed).
                    [ResizeBadge resizeBadge:welf.badgeValue
                              totalFreeSpace:totalFreeSpaceForBadge
                             canTextBeScaled:YES
                     setBadgeWidthCompletion:^(CGFloat calculatedWidth) {
                         [welf configureConstraintsForMediaBadgeWidth:calculatedWidth];
                     }];
                }
                else
                {
                    [welf configureConstraintsForMediaBadgeWidth:neededWidthBadgeText];
                }
            }
            else
            {
                welf.mediaBadgeLeadingConstraint.constant = 0.f;
                welf.mediaBadgeWidthConstraint.constant = 0.f;
            }
            [welf.mediaBadgeValue layoutSubviews];
        }];
    };

    if (notif.userInfo[@"newBadgeValue"])
    {
        failedUploadingBadgeCount = [notif.userInfo[@"newBadgeValue"] integerValue];
        failedUploadingBadgeBlock();
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Update Media Failed Badge Count from db
            failedUploadingBadgeCount = [MediaFileUploadDBService countWithShareType:UnknownMediaFileUploadShareType];
            dispatch_async_main(^{
                failedUploadingBadgeBlock();
            });
        });
    }
}

- (void)configureConstraintsForMediaBadgeWidth:(CGFloat)calculatedWidthBadge
{
    if (calculatedWidthBadge < kMinBadgeWidth && calculatedWidthBadge != 0)
    {
        calculatedWidthBadge = kMinBadgeWidth;
    }

    self.mediaBadgeWidthConstraint.constant = calculatedWidthBadge;
    self.mediaBadgeLeadingConstraint.constant = kBadgeValueLeading;
}

#pragma mark - Button Actions

- (IBAction)onSelectMenuItem:(UIButton*)button
{
    [self changeCurrentMenuWithSelected:button.tag];
}

@end

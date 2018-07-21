//
//  DetailOnCallViewController.m
//  qliq
//
//  Created by Valerii Lider on 07/09/15.
//
//

#import "DetailOnCallViewController.h"
#import "DetailOnCallTableViewCell.h"

#import "ProfileViewController.h"
#import "DetailContactInfoViewController.h"

#import "JTCalendar.h"

#import "OnCallGroup.h"
#import "GetOnCallGroupService.h"
#import "QliqNotificationView.h"

#import "UIDevice-Hardware.h"

#define kDefaultCellHeight 70.f
#define kDefaultHeaderSectionHeight 25.f

@interface DetailOnCallViewController () <UITableViewDataSource, UITableViewDelegate, JTCalendarDelegate, DetailOnCallTableViewCellDelegate>
{
    NSMutableDictionary *_eventsByDate;

    NSDate *_dateSelected;
}

@property (weak, nonatomic) IBOutlet UILabel *backButtonTitle;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarView;
@property (weak, nonatomic) IBOutlet UIButton *todayButton;


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSDate *todayDate;
@property (strong, nonatomic) JTCalendarManager *calendarManager;

@property (nonatomic, strong) OnCallShift *currentShift;
@property (nonatomic, strong) NSArray *currentDayNotes;
@property (nonatomic, strong) NSMutableArray *onCallUsersWithHours;
@property (nonatomic, assign) BOOL isOnCallInCurrentTime;

@property (nonatomic, strong) dispatch_queue_t refreshQueue;


@end

@implementation DetailOnCallViewController

- (void)dealloc {
    self.onCallGroup = nil;
    self.currentShift = nil;
    self.currentDayNotes = nil;
    self.onCallUsersWithHours = nil;
    self.calendarManager = nil;
    
    self.titleLabel = nil;
    self.calendarMenuView = nil;
    self.calendarView = nil;
    self.tableView = nil;

    self.refreshQueue = nil;
}

- (void)configureDefaultText {
    [self.todayButton setTitle:QliqLocalizedString(@"301-ValueToday") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshQueue = dispatch_queue_create("com.Qliq.detailOnCallViewController.dispatch_refresh_queue", DISPATCH_QUEUE_SERIAL);
    
    [self configureDefaultText];
    
    if (self.backButtonTitleString) {
        self.backButtonTitle.text = self.backButtonTitleString;
    }
        
    //Set GroupName
    self.titleLabel.text = self.onCallGroup.name;
    
    _dateSelected = [self todayDate];

    
    //Configure CalendarManager
    self.calendarManager = [JTCalendarManager new];
    self.calendarManager.delegate = self;
    
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    if ([currentLocale.localeIdentifier isEqualToString:@"es"]) {
        self.calendarManager.dateHelper.calendar.locale = [NSLocale localeWithLocaleIdentifier:@"es"];
    }
    else {
        self.calendarManager.dateHelper.calendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    }
    
    // 3/7/2017 Krishna - Move it before CalendarManager so that the DOTS on days
    // are shown correctly when shifts are loaded from shifts_json
    
    //Need get info from server. If server return CompletitionStatusCancel (Error.code = 110) - app has latest shifts
    //Valerii Lider 6/8/2018
    
    // Prepare OnCall coming to in the View Did Load
    [self prepareOnCall];
    
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:@"Updating"];
    });
    
    __weak __block typeof(self) welf = self;
    [[[GetOnCallGroupService alloc] init] get:self.onCallGroup.qliqId reason:ViewRequestReason withCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {
        
        // Reload OnCall only if the request is successful. This will ensure that if there is a network error or other reasons, the oncall in
        // not loaded.
        if (status == CompletitionStatusSuccess) {
            [welf prepareOnCall];
            [welf.calendarManager reload];
        }
        
        dispatch_async_main(^{
            if ([SVProgressHUD isVisible]) {
                [SVProgressHUD dismiss];
            }
        });
    }];
    
    [self.calendarManager setMenuView:self.calendarMenuView];
    [self.calendarManager setContentView:self.calendarView];
    [self.calendarManager setDate:[self todayDate]];
    [self.calendarManager reload];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCallUpdate:)
                                                 name:kOnCallGroupsChangedNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - notifications -

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    if (self.onCallUsersWithHours.count > 0) {
        @synchronized(self) {
            __block __weak typeof(self) welf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSString *qliqId = notification.userInfo[@"qliqId"];
                for (NSUInteger index = 0; index < welf.onCallUsersWithHours.count; index++)
                {
                    QliqUserWithOnCallHours *quwh = [welf.onCallUsersWithHours objectAtIndex:index];
                    if ([quwh.user.qliqId isEqualToString:qliqId]) {
                        quwh.user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                        [welf.onCallUsersWithHours replaceObjectAtIndex:index withObject:quwh];
                        break;
                    }
                }
                dispatch_async_main(^{
                    [welf.tableView reloadData];
                });
            });
        }
    }
}

- (void) checkForDeleting:(NSNotification *)notification
{
    for (NSString *qliqId in notification.userInfo[kKeyOnCallDeletedIds]) {
        if ([self.onCallGroup.qliqId isEqualToString:qliqId]) {
            dispatch_async_main(^{
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1223-TextOnCallGroupWasDeleted", nil)
                                                                               message:nil
                                                                             delegate:nil
                                                                    cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                    otherButtonTitles:nil];
                [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
                                                                           [self onBack:nil];
                                                                       }];
            });
            break;
        }
    }
}

- (void)onCallUpdate:(NSNotification *)notification {
    
    // Step 1: check for update
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"qliqId == %@", self.onCallGroup.qliqId];
    NSArray *filteredArray = [notification.userInfo[kKeyOnCallChangedGroups] filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        OnCallGroup *updatedGroup = filteredArray[0];
        
        dispatch_async(self.refreshQueue, ^{
            self.onCallGroup = updatedGroup;
            _eventsByDate = nil;
            
            dispatch_async_main(^{
                [self prepareOnCall];
                [self.calendarManager reload];
                
            });
        });
    } else {
        // Step 2: check for deletion
        [self checkForDeleting:notification];
    }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    
    __weak __block typeof(self) welf = self;
    [welf showOnCallGroupBanner];
}

#pragma mark - Getters -

- (NSDate *)todayDate {
    return [NSDate date];
}

- (NSMutableArray *)onCallUsersWithHours {
    if (_onCallUsersWithHours == nil) {
        _onCallUsersWithHours = [[NSMutableArray alloc] init];
    }
    return _onCallUsersWithHours;
}

#pragma mark - Private -

- (void)showOnCallGroupBanner {
    
    if (![appDelegate.idleController lockedIdle]) {
        dispatch_async_main(^{
            
            NSString *bannerSubtitle = QliqLocalizedString(@"2427-TitleCheckingForUpdates");
            
            QliqNotificationView *banner = [QliqNotificationView new];
            banner.converationId = self.onCallGroup.qliqId;
            isIPhoneX {
                banner.titleLabel.font = [UIFont systemFontOfSize:19.0];
                banner.descriptionLabel.font = [UIFont systemFontOfSize:17.0];
            }
            banner.titleLabel.text = self.titleLabel.text;
            banner.descriptionLabel.text = bannerSubtitle;
            banner.backgroundColor = [UIColor whiteColor];
            banner.titleLabel.textColor = [UIColor grayColor];
            banner.descriptionLabel.textColor = [UIColor grayColor];
            banner.avatarImageView.layer.cornerRadius = banner.avatarImageView.bounds.size.height / 2;
            banner.avatarImageView.clipsToBounds = YES;
            banner.avatarImageView.image = [[ QliqAvatar sharedInstance] getAvatarForItem:self.onCallGroup withTitle:nil];
            banner.closeButton.titleLabel.text = nil;
            [banner presentForOnCall];
            
            __weak __block typeof(self) welf = self;
            [[[GetOnCallGroupService alloc] init] get:self.onCallGroup.qliqId reason:ViewRequestReason withCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {
                if (status != CompletitionStatusSuccess) {
                    banner.descriptionLabel.text = QliqLocalizedString(@"2428-TitleCheckingForUpdatesFailed");
                    banner.descriptionLabel.textColor = [UIColor redColor];
                } else if (status == CompletitionStatusSuccess) {
                    [welf prepareOnCall];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [banner removeNotificationView];
                });
            }];
        });
    }
}

- (void)prepareOnCall {
    
    DDLogSupport(@"prepareOnCall Called");
    
    // Krishna 3/7/2017
    // Try loading Shifts If they are not loaded already
    //
    [self.onCallGroup loadOnCallShiftsFromJson];
    
    self.currentShift = [self.onCallGroup shiftForDate:_dateSelected withCalendar:self.calendarManager.dateHelper.calendar];
    
    [self.onCallUsersWithHours removeAllObjects];
    
    self.onCallUsersWithHours = [[self.onCallGroup membersWithHoursForDate:_dateSelected withCalendar:self.calendarManager.dateHelper.calendar] mutableCopy];
    
    self.currentDayNotes = nil;
    self.currentDayNotes = [self.onCallGroup notesForDate:_dateSelected];
    
    if (![[NSCalendar currentCalendar] isDateInToday:_dateSelected])
        self.isOnCallInCurrentTime = YES;
    else
      [self onCallUsersInCurrentTime];
    
    if (!self.isOnCallInCurrentTime && self.onCallUsersWithHours.count > 0) {
        for (int i = 0; i < self.onCallUsersWithHours.count; i++) {
            QliqUserWithOnCallHours *a =self.onCallUsersWithHours[i];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"hh:mma"];
            
            NSString *str = [formatter  stringFromDate:[self todayDate]];
            NSDate *date = [formatter dateFromString:str];
            if ([a.startTime compare:date] == NSOrderedDescending) {
                NSArray *temp = [self.onCallUsersWithHours subarrayWithRange:NSMakeRange(i, self.onCallUsersWithHours.count - i)];
                [self.onCallUsersWithHours removeObjectsInRange:NSMakeRange(i, self.onCallUsersWithHours.count - i)];
                for (NSInteger j = temp.count - 1; j >= 0; j--) {
                    QliqUserWithOnCallHours *b = temp[j];
                    [self.onCallUsersWithHours insertObject:b atIndex:0];
                }
                break;
            }
        }
    }
    [self.tableView reloadData];
}

- (BOOL)haveEventForDay:(NSDate *)date
{
    BOOL hasEvent = NO;
    
    NSString *key = [[self dateFormatter] stringFromDate:date];
    
    if (!_eventsByDate) {
        _eventsByDate = [NSMutableDictionary new];
    }
    
    if(_eventsByDate[key]) {
        hasEvent = [_eventsByDate[key] boolValue];
    }
    else {
        
        if ([self.onCallGroup shiftForDate:date withCalendar:self.calendarManager.dateHelper.calendar]) {
            NSNumber *n = [NSNumber numberWithBool:YES];
            [_eventsByDate setObject:n forKey:key];
            hasEvent = YES;
        }
    }
    return hasEvent;
}

- (BOOL) date:(NSDate*)date isBetweenDate:(NSDate*)beginDate endDate:(NSDate*)endDate {
    return (([date compare:beginDate] != NSOrderedAscending) && ([date compare:endDate] != NSOrderedDescending));
}

- (void)onCallUsersInCurrentTime {
    
    self.isOnCallInCurrentTime = NO;
    
    if (self.onCallUsersWithHours.count > 0) {
        for (QliqUserWithOnCallHours *qliqUser in self.onCallUsersWithHours) {
            if ([qliqUser isActiveOnDate:[self todayDate]]) {
                self.isOnCallInCurrentTime = YES;
                break;
            }
        }
    }
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (NSString *)convertDateToOnCallString:(NSDate *)date isShort:(BOOL)isShort{
    NSString *onCallString = @"";
    
    NSString *weekDay = @"";
    NSString *day = @"";
    NSString *month = @"";
    NSString *year = @"";
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = self.calendarManager.dateHelper.calendar.locale;
    dateFormatter.timeZone = self.calendarManager.dateHelper.calendar.timeZone;
    
    dateFormatter.dateFormat = @"YYYY";
    year = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = isShort ? @"MMM" : @"MMMM";
    month = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = @"dd";
    day = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = isShort ? @"EE" : @"EEEE";
    weekDay = [dateFormatter stringFromDate:date];
    
    if (isShort) {
        if([self.calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:date]) {
            
            onCallString = [NSString stringWithFormat:@"%@, %@ %@, %@", QliqLocalizedString(@"301-ValueToday"), month, day, year];
        }
        else {
            onCallString = [NSString stringWithFormat:@"%@, %@ %@, %@", weekDay, month, day, year];
        }
        
    } else {
        if([self.calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:date]) {
            onCallString = [NSString stringWithFormat:@"%@, %@ %@, %@", QliqLocalizedString(@"2134-TitleOnCallToday"), month, day, year];
        }
        else {
            onCallString = [NSString stringWithFormat:@"%@ %@, %@ %@, %@", QliqLocalizedString(@"2135-TitleOnCallOn"), weekDay, month, day, year];
        }
    }
    
    return onCallString;
}

- (void)setupPerDayNotesButton:(UIButton *)button inHeaderView:(UIView *)headerView {
    
    button.frame = CGRectMake(self.tableView.frame.size.width - 60.f, 2.5f, 50.f, kDefaultHeaderSectionHeight - 5.0f);
    button.backgroundColor = [UIColor clearColor];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
    [button setTitle:QliqLocalizedString(@"2354-TitleNotes") forState:UIControlStateNormal];
    [button setTitle:QliqLocalizedString(@"2354-TitleNotes") forState:UIControlStateHighlighted];
    [button setTitleColor:kColorDarkBlue forState:UIControlStateNormal];
    [button setTitleColor:kColorLightBlue forState:UIControlStateHighlighted];
    button.layer.borderWidth = 1.f;
    button.layer.borderColor = [kColorDarkBlue CGColor];
    button.layer.cornerRadius = 5.f;
    [button addTarget:self action:@selector(onDayNotes) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button];
}

- (void)setupLabelForHeader:(UIView *)headerView withButton:(UIButton *)button {
   
    NSString *titleHeader = [self convertDateToOnCallString:_dateSelected isShort:NO];
    UIFont *titleHeaderFont    = [UIFont systemFontOfSize:14.f];
  
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.textColor       = RGBa(3, 120, 173, 1);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font            = titleHeaderFont;
    headerLabel.text            = titleHeader;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    [headerLabel setMinimumScaleFactor: 12.f / [UIFont labelFontSize]];
    headerLabel.numberOfLines = 1;
    headerLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    if (button)
    {
        CGFloat maxLabelWidth = button.frame.origin.x - 20.f;
        headerLabel.textAlignment   = NSTextAlignmentLeft;
        [headerLabel sizeToFit];
        headerLabel.frame = CGRectMake(10.f, 0, headerLabel.frame.size.width, kDefaultHeaderSectionHeight);
       [self scaleLabelFont:headerLabel withMaxWidth:maxLabelWidth firstCall:YES];
        
    }
    else
    {
        CGFloat offset             = 20.f;
        headerLabel.frame = CGRectMake(offset/2, 0, self.tableView.bounds.size.width - offset, kDefaultHeaderSectionHeight);
        headerLabel.textAlignment   = NSTextAlignmentCenter;
    }
    
    [headerView addSubview:headerLabel];
}

- (void)scaleLabelFont:(UILabel *)label withMaxWidth:(CGFloat)maxWidth firstCall:(BOOL)firstCall {
    
    while (label.frame.size.width > maxWidth && label.font.pointSize >= 12.0) {
        label.font = [UIFont systemFontOfSize:label.font.pointSize-1];
        [label sizeToFit];
        label.frame = CGRectMake(10.0, 0.0, label.frame.size.width, kDefaultHeaderSectionHeight);
    }
    
    if (label.frame.size.width > maxWidth && firstCall) {
        label.font = [UIFont systemFontOfSize:14.f];
        label.text = [self convertDateToOnCallString:_dateSelected isShort:firstCall];
        [self scaleLabelFont:label withMaxWidth:maxWidth firstCall:!firstCall];
    }
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onToday:(id)sender {
    _dateSelected = [self todayDate];
    [self prepareOnCall];
    [self.calendarManager setDate:[self todayDate]];
}

- (IBAction)onPreviousMonth:(id)sender {
    [self.calendarView loadPreviousPageWithAnimation];
    [self.calendarManager reload];
}

- (IBAction)onNextMonth:(id)sender {
    [self.calendarView loadNextPageWithAnimation];
    [self.calendarManager reload];
}

- (void)onDayNotes {
    NSLog(@"onDayNotes");
    
    DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
    controller.contact = self.currentDayNotes;
    controller.backButtonTitleString = self.onCallGroup.name;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.modalInPopover = YES;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Delegates -

#pragma mark * UITableViewDataSource\UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 1;
    
    if (self.onCallUsersWithHours.count > 0) {
        if (self.isOnCallInCurrentTime && _dateSelected != [self todayDate]) {
            numberOfRows = self.onCallUsersWithHours.count;
        }
        else {
            numberOfRows = self.onCallUsersWithHours.count + numberOfRows;
        }
    }
    else {
        numberOfRows = 1;
    }
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.onCallUsersWithHours.count > 0) {
        if (self.isOnCallInCurrentTime) {
            return kDefaultCellHeight;
        }
        else {
            if (indexPath.row == 0) {
                return 35.f;
            }
        }
    }
    else {
        return 35.f;
    }

    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kDefaultHeaderSectionHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = RGBa(235, 235, 235, 1.0f);
    
    if (self.currentDayNotes && self.currentDayNotes.count > 0)
    {
        UIButton *button = [[UIButton alloc] init];
        
        [self setupPerDayNotesButton:button inHeaderView:headerView];
        
        [self setupLabelForHeader:headerView withButton:button];
    }
    else
    {
        [self setupLabelForHeader:headerView withButton:nil];
    }
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"DetailOnCallTableViewCell";
    
    DetailOnCallTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell) {
        
        UINib *nib = [UINib nibWithNibName:@"DetailOnCallTableViewCell" bundle:nil];
        
        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }
    
    QliqUserWithOnCallHours *uh = nil;

    if (self.onCallUsersWithHours.count > 0) {
        if (self.isOnCallInCurrentTime) {
            uh = self.onCallUsersWithHours[indexPath.row];
            cell.userInteractionEnabled = YES;
        }
        else {
            if(indexPath.row != 0) {
                uh = self.onCallUsersWithHours[indexPath.row - 1];
                cell.userInteractionEnabled = YES;
            }
            else {
                cell.userInteractionEnabled = NO;
            }
            
        }
        [cell configureCellWithQliqUserWithHours:uh
                                   withTodayDate:[self todayDate]
                                withSelectedDate:_dateSelected
                                       withNotes:[self.onCallGroup getNotesForUser:uh.user] isOnCallUsersWithHours:YES];
    }
    else {
        cell.userInteractionEnabled = NO;
        [cell configureCellWithQliqUserWithHours:uh
                                   withTodayDate:[self todayDate]
                                withSelectedDate:_dateSelected
                                       withNotes:[self.onCallGroup getNotesForUser:uh.user] isOnCallUsersWithHours:NO];
    }
    cell.delegate = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //    QliqUserWithOnCallHours *uh = (QliqUserWithOnCallHours *)self.onCallUsersWithHours[indexPath.row];
    
    QliqUserWithOnCallHours *uh = nil;
    if (!self.isOnCallInCurrentTime && indexPath.row == 0)
        return;
    
    if (self.onCallUsersWithHours.count > 0) {
        if (self.isOnCallInCurrentTime)
            uh = self.onCallUsersWithHours[indexPath.row];
        else
           uh = self.onCallUsersWithHours[indexPath.row - 1];
        
        QliqUser *user = uh.user;
        
        if ([user.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
            
            ProfileViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
            [self.navigationController pushViewController:controller animated:YES];
            
        } else {
            
            DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
            controller.contact = user;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}


#pragma mark * DetailOnCallTableVIewCellDelegate

- (void)onNotesButtonPressedInCell:(id)cell{
    
    DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
    
    QliqUserWithOnCallHours *uh = nil;
    if (!self.isOnCallInCurrentTime && [self.tableView indexPathForCell:cell].row == 0)
        return;
    
    if (self.onCallUsersWithHours.count > 0) {
        if (self.isOnCallInCurrentTime)
            uh = (QliqUserWithOnCallHours *)self.onCallUsersWithHours[[self.tableView indexPathForCell:cell].row];
        else
            uh = (QliqUserWithOnCallHours *)self.onCallUsersWithHours[[self.tableView indexPathForCell:cell].row - 1];
    }
    
    controller.contact = [self.onCallGroup getNotesForUser:uh.user];
    controller.backButtonTitleString = self.onCallGroup.name;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.modalInPopover = YES;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark * JTCalendarDelegate

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
    dayView.hidden = NO;
    dayView.dotRatio = 0.125;
    
    // Test if the dayView is from another month than the page
    // Use only in month mode for indicate the day of the previous or next month
    if([dayView isFromAnotherMonth]){
//        dayView.hidden = YES;
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [UIColor blackColor];
        dayView.textLabel.textColor = [UIColor lightGrayColor];
    }
    // Today
    else if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = kColorDarkBlue;
        dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Selected date
    else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = kColorLightBlue;
        dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Another day of the current month
    else{
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [UIColor lightGrayColor];
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    
    // Your method to test if a date have an event for example
    if([self haveEventForDay:dayView.date]){
        dayView.dotView.hidden = NO;
    }
    else{
        dayView.dotView.hidden = YES;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView
{
    _dateSelected = dayView.date;
    [self prepareOnCall];
    
    // Animation for the circleView
    dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
    [UIView transitionWithView:dayView
                      duration:.3
                       options:0
                    animations:^{
                        dayView.circleView.transform = CGAffineTransformIdentity;
                        [_calendarManager reload];
                    } completion:nil];
    
    
    // Load the previous or next page if touch a day from another month
    
    if(![self.calendarManager.dateHelper date:self.calendarView.date isTheSameMonthThan:dayView.date]) {
        if([self.calendarView.date compare:dayView.date] == NSOrderedAscending){
            [self.calendarView loadNextPageWithAnimation];
        }
        else {
            [self.calendarView loadPreviousPageWithAnimation];
        }
    }
}

#pragma mark * * View Customization

- (UIView<JTCalendarWeekDay> *)calendarBuildWeekDayView:(JTCalendarManager *)calendar
{
    JTCalendarWeekDayView *view = [JTCalendarWeekDayView new];
    
    for(UILabel *label in view.dayViews){
        label.textColor = kColorLightBlue;
    }
    
    return view;
}

- (void)calendar:(JTCalendarManager *)calendar prepareMenuItemView:(UILabel *)menuItemView date:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"MMMM yyyy";
        
        dateFormatter.locale = self.calendarManager.dateHelper.calendar.locale;
        dateFormatter.timeZone = self.calendarManager.dateHelper.calendar.timeZone;
    }
    menuItemView.textColor = RGBa(3, 120, 173, 1);
    menuItemView.text = [dateFormatter stringFromDate:date];
}

@end
